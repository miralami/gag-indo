--!nocheck
-- SubjectCoverage: engine-backed visible screen fraction for a LookDev candidate and a review camera.
-- WORK_QUEUE item 239. PURE AT LOAD: no game/Instance/Vector3/CFrame lookup until measure() runs.
--
-- measure(candidateId, cameraName, viewportSize?, deps?) -> {
--   fraction, sampleCount, hitCount, partCount, rectCount, rects, camera, viewport, candidateId,
--   ok, reason
-- }
-- `deps` is optional in Studio (engine globals are resolved lazily). Lune specs inject fake engine
-- objects: game (GetService("Workspace")), Instance.new("Camera"), Vector2/Vector3/CFrame,
-- RaycastParams, Enum.RaycastFilterType.Exclude, workspace (GetDescendants/Raycast) and/or
-- reviewCameras.get(name). No place save; the temporary Camera is never parented.
--
-- Projection: each candidate BasePart's 8 world AABB corners go through Camera:WorldToViewportPoint;
-- the min/max screen rect is clipped to the viewport. A shared 64x36 grid over the viewport visits
-- each cell at most once (overlap dedup), and a ray through each covered cell counts only when the
-- first opaque hit belongs to a candidate part. Transparent non-candidate hits are excluded and the
-- ray retried up to 3 times.

local SubjectCoverage = {}

SubjectCoverage.VIEWPORT = { 1375, 753 }
SubjectCoverage.GRID = { 64, 36 }
SubjectCoverage.MAX_RAY = 1200
SubjectCoverage.OPAQUE_LIMIT = 0.9

local function engineDeps()
	local ok, deps = pcall(function()
		return {
			game = game,
			Instance = Instance,
			Vector2 = Vector2,
			Vector3 = Vector3,
			CFrame = CFrame,
			RaycastParams = RaycastParams,
			Enum = Enum,
		}
	end)
	if ok and type(deps) == "table" then
		return deps
	end
	return {}
end

local function viewportOf(size)
	local width, height = SubjectCoverage.VIEWPORT[1], SubjectCoverage.VIEWPORT[2]
	if type(size) == "table" then
		width = tonumber(size[1] or size.width or size.X) or width
		height = tonumber(size[2] or size.height or size.Y) or height
	end
	if width == nil or width <= 0 then
		width = SubjectCoverage.VIEWPORT[1]
	end
	if height == nil or height <= 0 then
		height = SubjectCoverage.VIEWPORT[2]
	end
	return { width, height }
end

local function emptyResult(id, cameraName, viewport, reason)
	return {
		fraction = 0,
		sampleCount = 0,
		hitCount = 0,
		partCount = 0,
		rectCount = 0,
		rects = {},
		camera = cameraName,
		viewport = { width = viewport[1], height = viewport[2] },
		candidateId = id,
		ok = false,
		reason = reason,
	}
end

local function resolveCamera(deps, name)
	if type(deps.reviewCameras) == "table" and type(deps.reviewCameras.get) == "function" then
		local ok, entry = pcall(function()
			return deps.reviewCameras.get(name)
		end)
		if ok and type(entry) == "table" then
			return entry
		end
		return nil, "reviewCameras.get(" .. tostring(name) .. ") failed"
	end
	local okShared, shared = pcall(function()
		return deps.game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	end)
	if not okShared or not shared then
		return nil, "Shared container unavailable"
	end
	local okRegistry, registry = pcall(function()
		return require(shared:WaitForChild("ReviewCameras"))
	end)
	if not okRegistry or type(registry) ~= "table" or type(registry.get) ~= "function" then
		return nil, "ReviewCameras registry unavailable"
	end
	local okEntry, entry = pcall(function()
		return registry.get(name)
	end)
	if not okEntry or type(entry) ~= "table" then
		return nil, "unknown camera " .. tostring(name)
	end
	return entry
end

local function resolveWorkspace(deps)
	if deps.workspace then
		return deps.workspace
	end
	local ok, ws = pcall(function()
		return deps.game:GetService("Workspace")
	end)
	if ok then
		return ws
	end
	return nil
end

local function collectParts(id, workspace)
	local parts = {}
	if not workspace or type(workspace.GetDescendants) ~= "function" then
		return parts
	end
	local ok, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return parts
	end
	for _, instance in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart then
			local okTag, tag = pcall(function()
				return instance:GetAttribute("LookDevStage")
			end)
			if okTag and tag == id then
				parts[#parts + 1] = instance
			end
		end
	end
	return parts
end

local function projectRects(parts, camera, deps, viewport, scaleX, scaleY, offsetX, offsetY)
	local rects = {}
	local V3 = deps.Vector3
	if not V3 or type(V3.new) ~= "function" then
		return rects
	end
	for _, part in ipairs(parts) do
		local okSize, size = pcall(function()
			return part.Size
		end)
		local okFrame, frame = pcall(function()
			return part.CFrame
		end)
		if okSize and okFrame and (type(size) == "vector" or type(size) == "userdata" or type(size) == "table") then
			local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local hx, hy, hz = sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2
						local okWorld, world = pcall(function()
							return V3.new(
								frame.Position.X + frame.XVector.X * hx + frame.YVector.X * hy + frame.ZVector.X * hz,
								frame.Position.Y + frame.XVector.Y * hx + frame.YVector.Y * hy + frame.ZVector.Y * hz,
								frame.Position.Z + frame.XVector.Z * hx + frame.YVector.Z * hy + frame.ZVector.Z * hz
							)
						end)
						if okWorld and world then
							local okScreen, screen = pcall(function()
								return camera:WorldToViewportPoint(world)
							end)
							if okScreen and screen and type(screen.Z) == "number" and screen.Z > 0 then
								local px = offsetX + screen.X * scaleX
								local py = offsetY + screen.Y * scaleY
								minX = math.min(minX, px)
								minY = math.min(minY, py)
								maxX = math.max(maxX, px)
								maxY = math.max(maxY, py)
							end
						end
					end
				end
			end
			if minX ~= math.huge then
				local x0 = math.max(0, minX)
				local y0 = math.max(0, minY)
				local x1 = math.min(viewport[1], maxX)
				local y1 = math.min(viewport[2], maxY)
				if x1 > x0 and y1 > y0 then
					rects[#rects + 1] = { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
				end
			end
		end
	end
	return rects
end

-- Pure sampling core. One visit per grid cell deduplicates overlapping part rects. isVisible is a
-- function(screenX, screenY) -> boolean; callers supply projection or raycast logic.
function SubjectCoverage.sample(viewport, rects, isVisible)
	local width, height = viewport[1], viewport[2]
	local cellWidth = width / SubjectCoverage.GRID[1]
	local cellHeight = height / SubjectCoverage.GRID[2]
	local sampleCount, hitCount = 0, 0
	for iy = 0, SubjectCoverage.GRID[2] - 1 do
		local y = (iy + 0.5) * cellHeight
		for ix = 0, SubjectCoverage.GRID[1] - 1 do
			local x = (ix + 0.5) * cellWidth
			local inside = false
			for _, rect in ipairs(rects) do
				if x >= rect.x0 and x < rect.x1 and y >= rect.y0 and y < rect.y1 then
					inside = true
					break
				end
			end
			if inside then
				sampleCount += 1
				local ok, visible = pcall(isVisible, x, y)
				if ok and visible then
					hitCount += 1
				end
			end
		end
	end
	return {
		fraction = if sampleCount > 0 then hitCount / sampleCount else 0,
		sampleCount = sampleCount,
		hitCount = hitCount,
		visited = sampleCount,
		rectCount = #rects,
	}
end

local function makeVisibility(camera, workspace, deps, candidateSet, scaleX, scaleY, offsetX, offsetY)
	return function(x, y)
		local okRay, ray = pcall(function()
			return camera:ViewportPointToRay((x - offsetX) / scaleX, (y - offsetY) / scaleY)
		end)
		if not okRay or not ray or not ray.Direction then
			return false
		end
		local excluded = {}
		for _ = 1, 4 do
			local params = nil
			if deps.RaycastParams and type(deps.RaycastParams.new) == "function" then
				local okParams, made = pcall(function()
					return deps.RaycastParams.new()
				end)
				if okParams and made then
					params = made
					pcall(function()
						if deps.Enum and deps.Enum.RaycastFilterType then
							made.FilterType = deps.Enum.RaycastFilterType.Exclude
						end
						made.FilterDescendantsInstances = excluded
					end)
				end
			end
			local direction = ray.Direction
			local far = deps.Vector3.new(
				direction.X * SubjectCoverage.MAX_RAY,
				direction.Y * SubjectCoverage.MAX_RAY,
				direction.Z * SubjectCoverage.MAX_RAY
			)
			local okHit, hit
			if params then
				okHit, hit = pcall(function()
					return workspace:Raycast(ray.Origin, far, params)
				end)
			else
				okHit, hit = pcall(function()
					return workspace:Raycast(ray.Origin, far)
				end)
			end
			if not okHit or not hit then
				return false
			end
			local instance = hit.Instance
			if candidateSet[instance] then
				return true
			end
			local okTransparency, transparency = pcall(function()
				return instance.Transparency
			end)
			if okTransparency and type(transparency) == "number" and transparency >= SubjectCoverage.OPAQUE_LIMIT then
				excluded[#excluded + 1] = instance
			else
				return false
			end
		end
		return false
	end
end

local function measureImpl(id, cameraName, viewportSize, deps)
	local viewport = viewportOf(viewportSize)
	local entry, why = resolveCamera(deps, cameraName)
	if not entry or type(entry.position) ~= "table" or type(entry.lookAt) ~= "table" then
		return emptyResult(id, cameraName, viewport, why or "camera entry missing")
	end
	if not deps.Instance or type(deps.Instance.new) ~= "function" or not deps.CFrame or not deps.Vector2 then
		return emptyResult(id, cameraName, viewport, "engine camera types unavailable")
	end
	local workspace = resolveWorkspace(deps)
	if not workspace or type(workspace.Raycast) ~= "function" then
		return emptyResult(id, cameraName, viewport, "workspace raycast unavailable")
	end

	local okCamera, camera = pcall(function()
		local eye = deps.Vector3.new(entry.position[1], entry.position[2], entry.position[3])
		local look = deps.Vector3.new(entry.lookAt[1], entry.lookAt[2], entry.lookAt[3])
		local made = deps.Instance.new("Camera")
		made.CFrame = deps.CFrame.lookAt(eye, look)
		return made
	end)
	if not okCamera or not camera then
		return emptyResult(id, cameraName, viewport, "camera setup failed: " .. tostring(camera))
	end

	-- Camera.ViewportSize is engine-owned (read-only); a fresh Server-VM Camera reports (1,1) and
	-- WorldToViewportPoint returns aspect-corrected normalised [0,1] coordinates. Map those into the
	-- requested pixel viewport: X depends on the camera aspect (vx/vy), Y does not. Lune fakes with a
	-- nil ViewportSize already return pixel coordinates, so they use the identity transform.
	local scaleX, scaleY, offsetX, offsetY = 1, 1, 0, 0
	local okVP, camVP = pcall(function()
		return camera.ViewportSize
	end)
	if okVP and camVP then
		local vx = tonumber(camVP.X)
		local vy = tonumber(camVP.Y)
		if vx and vy and vx > 0 and vy > 0 then
			local aspect = vx / vy
			scaleX = viewport[2] * aspect
			scaleY = viewport[2]
			offsetX = viewport[1] / 2 - 0.5 * scaleX
			offsetY = 0
		end
	end

	local parts = collectParts(id, workspace)
	if #parts == 0 then
		return emptyResult(id, cameraName, viewport, "no candidate parts for " .. tostring(id))
	end
	local candidateSet = {}
	for _, part in ipairs(parts) do
		candidateSet[part] = true
	end
	local rects = projectRects(parts, camera, deps, viewport, scaleX, scaleY, offsetX, offsetY)
	if #rects == 0 then
		local result = emptyResult(id, cameraName, viewport, "no projected rects")
		result.partCount = #parts
		return result
	end
	local sampled = SubjectCoverage.sample(
		viewport,
		rects,
		makeVisibility(camera, workspace, deps, candidateSet, scaleX, scaleY, offsetX, offsetY)
	)
	return {
		fraction = sampled.fraction,
		sampleCount = sampled.sampleCount,
		hitCount = sampled.hitCount,
		partCount = #parts,
		rectCount = #rects,
		rects = rects,
		camera = cameraName,
		viewport = { width = viewport[1], height = viewport[2] },
		candidateId = id,
		ok = true,
		reason = nil,
	}
end

function SubjectCoverage.measure(candidateId, cameraName, viewportSize, deps)
	local viewport = viewportOf(viewportSize)
	local ok, result = pcall(measureImpl, candidateId, cameraName, viewport, deps or engineDeps())
	if not ok or type(result) ~= "table" then
		return emptyResult(candidateId, cameraName, viewport, "measure failed: " .. tostring(result))
	end
	return result
end

-- Synthetic-data self-probe through the same sampling core used by measure().
function SubjectCoverage.probe()
	local viewport = { 200, 150 }
	local rects = { { x0 = 20, y0 = 20, x1 = 80, y1 = 80 } }
	local full = SubjectCoverage.sample(viewport, rects, function()
		return true
	end)
	local occluded = SubjectCoverage.sample(viewport, rects, function(x)
		return x < 50
	end)
	local empty = SubjectCoverage.sample(viewport, {}, function()
		return true
	end)
	return full.fraction > 0.9
		and occluded.fraction > 0
		and occluded.fraction < full.fraction
		and empty.fraction == 0
		and empty.sampleCount == 0
end

return SubjectCoverage
