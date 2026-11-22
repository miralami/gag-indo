--!nocheck
-- check_p177: WORK_QUEUE section P item 177, ad-hoc SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It stages pathedge_r8 with enableAdditive in this SAME
-- call, measures the live plants and prints verbatim CHECK lines. No harness require, no place save,
-- no visual verdict. disableAll() runs on every exit path, including a thrown measurement error.
--
-- EDGE_HEIGHT: median world-space height of the tagged plant bodies (stem + blades + petals) >= 1.
-- EDGE_VISIBLE: from the ReviewCameras "spawn" eye, cast 5 rays per in-cone plant with an Include
-- filter on the staged folder; >=60% must hit that plant's own part. Count >= 12.
-- EDGE_OFF_ROAD: each plant's footprint must stay outside its recorded path half-width, and its
-- CFrame must agree with the recorded centreline. Zero offenders. Zero plants staged is a FAIL.

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local HEIGHT_MIN = 1
local VISIBLE_MIN = 12
local RAYS = 5
local RAY_HIT_MIN = 3 -- ceil(0.6 * 5)
local MAX_DISTANCE = 400
local FORWARD_DOT = 0.25 -- ~75-degree half-cone; spawn looks north down the south road
local CENTRE_TOLERANCE = 0.35

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function baseParts(root)
	local parts = {}
	if not root then
		return parts
	end
	local ok, own = pcall(function()
		return root:IsA("BasePart")
	end)
	if ok and own then
		parts[#parts + 1] = root
	end
	local okDesc, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if okDesc and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				parts[#parts + 1] = instance
			end
		end
	end
	return parts
end

-- World AABB from CFrame:VectorToWorldSpace of the absolute half-extents. VectorToWorldVector is
-- deliberately not used; this method exists in every Studio this repo targets.
local function partBounds(part)
	local ok, cf, sz = pcall(function()
		return part.CFrame, part.Size
	end)
	if not ok or not cf or not sz then
		return nil
	end
	local mins, maxs = nil, nil
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz2 in ipairs({ -1, 1 }) do
				local okCorner, corner = pcall(function()
					local ax = cf:VectorToWorldSpace(Vector3.new(sx * sz.X / 2, 0, 0))
					local ay = cf:VectorToWorldSpace(Vector3.new(0, sy * sz.Y / 2, 0))
					local az = cf:VectorToWorldSpace(Vector3.new(0, 0, sz2 * sz.Z / 2))
					return cf.Position + ax + ay + az
				end)
				if okCorner and corner then
					if not mins then
						mins, maxs = corner, corner
					else
						mins = Vector3.new(
							math.min(mins.X, corner.X),
							math.min(mins.Y, corner.Y),
							math.min(mins.Z, corner.Z)
						)
						maxs = Vector3.new(
							math.max(maxs.X, corner.X),
							math.max(maxs.Y, corner.Y),
							math.max(maxs.Z, corner.Z)
						)
					end
				end
			end
		end
	end
	if not mins or not maxs then
		return nil
	end
	return mins, maxs
end

local function plantBounds(plant)
	local mins, maxs = nil, nil
	for _, part in ipairs(baseParts(plant)) do
		local partMin, partMax = partBounds(part)
		if partMin and partMax then
			if not mins then
				mins, maxs = partMin, partMax
			else
				mins =
					Vector3.new(math.min(mins.X, partMin.X), math.min(mins.Y, partMin.Y), math.min(mins.Z, partMin.Z))
				maxs =
					Vector3.new(math.max(maxs.X, partMax.X), math.max(maxs.Y, partMax.Y), math.max(maxs.Z, partMax.Z))
			end
		end
	end
	return mins, maxs
end

local function isOwn(hitInstance, plant)
	local node = hitInstance
	for _ = 1, 8 do
		if not node then
			return false
		end
		if node == plant then
			return true
		end
		node = node.Parent
	end
	return false
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapPathEdgeR8"))

	local enabled, why = review.enableAdditive("pathedge_r8", game)
	if not enabled then
		error("enableAdditive(pathedge_r8) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end

	local plants = {}
	for _, instance in ipairs(folder:GetDescendants()) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart and attr(instance, "PathEdgePlant") == true then
			plants[#plants + 1] = instance
		end
	end

	-- EDGE_HEIGHT -------------------------------------------------------------
	local heights = {}
	local boundsByPlant = {}
	for _, plant in ipairs(plants) do
		local mins, maxs = plantBounds(plant)
		if mins and maxs then
			boundsByPlant[plant] = { mins = mins, maxs = maxs }
			heights[#heights + 1] = maxs.Y - mins.Y
		end
	end
	table.sort(heights)
	local median = 0
	if #heights > 0 then
		local middle = math.floor(#heights / 2)
		median = #heights % 2 == 1 and heights[middle + 1] or (heights[middle] + heights[middle + 1]) / 2
	end
	median = math.floor(median * 100) / 100
	emit("EDGE_HEIGHT", #plants > 0 and median >= HEIGHT_MIN, median, HEIGHT_MIN, {
		plants = #plants,
		measuredHeights = #heights,
		method = "median of world AABB height over stem + blades + petals",
	})

	-- EDGE_VISIBLE ------------------------------------------------------------
	local eye, forward, visible, cameraReason = nil, nil, 0, nil
	local okCam, cameras = pcall(function()
		return require(shared:WaitForChild("ReviewCameras"))
	end)
	if not okCam or type(cameras) ~= "table" then
		cameraReason = "ReviewCameras not readable (Server VM required)"
	else
		for _, camera in ipairs(cameras.all()) do
			if camera.name == "spawn" then
				eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
				local look = Vector3.new(camera.lookAt[1], camera.lookAt[2], camera.lookAt[3])
				forward = (look - eye).Unit
				break
			end
		end
		if not eye then
			cameraReason = "spawn camera missing"
		end
	end
	if eye and forward then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { folder }
		params.IgnoreWater = false
		local raysTried, hitsOnOwn = 0, 0
		for _, plant in ipairs(plants) do
			local bounds = boundsByPlant[plant]
			if bounds then
				local mins, maxs = bounds.mins, bounds.maxs
				local centre = Vector3.new((mins.X + maxs.X) / 2, (mins.Y + maxs.Y) / 2, (mins.Z + maxs.Z) / 2)
				local delta = centre - eye
				local distance = delta.Magnitude
				if distance > 0.5 and distance <= MAX_DISTANCE and delta.Unit:Dot(forward) >= FORWARD_DOT then
					local plantHits = 0
					for rayIndex = 1, RAYS do
						local vertical = ({ 0.3, 0.5, 0.7, 0.5, 0.5 })[rayIndex]
						local lateral = ({ 0, 0, 0, 0.08, -0.08 })[rayIndex]
						local target = Vector3.new(
							mins.X + (maxs.X - mins.X) / 2 + lateral,
							mins.Y + (maxs.Y - mins.Y) * vertical,
							mins.Z + (maxs.Z - mins.Z) / 2 + lateral
						)
						local aim = target - eye
						local okRay, hit = pcall(function()
							return workspace:Raycast(eye, aim.Unit * (aim.Magnitude + 2), params)
						end)
						raysTried += 1
						if okRay and hit and hit.Instance and isOwn(hit.Instance, plant) then
							plantHits += 1
							hitsOnOwn += 1
						end
					end
					if plantHits >= RAY_HIT_MIN then
						visible += 1
					end
				end
			end
		end
		emit("EDGE_VISIBLE", visible >= VISIBLE_MIN, visible, VISIBLE_MIN, {
			camera = "spawn",
			plantsChecked = #plants,
			raysTried = raysTried,
			hitsOnOwn = hitsOnOwn,
			raysPerPlant = RAYS,
			hitsRequired = RAY_HIT_MIN,
			method = "Include staged folder; 5 rays per in-cone plant; >=60% must hit that plant",
		})
	else
		emit("EDGE_VISIBLE", false, 0, VISIBLE_MIN, { reason = cameraReason })
	end

	-- EDGE_OFF_ROAD -----------------------------------------------------------
	local offenders, checked = {}, 0
	for _, plant in ipairs(plants) do
		checked += 1
		local lateral, halfWidth = attr(plant, "Lateral"), attr(plant, "HalfWidth")
		local centreX, centreZ = attr(plant, "CentreX"), attr(plant, "CentreZ")
		local bounds = boundsByPlant[plant]
		local reason = nil
		if
			type(lateral) ~= "number"
			or type(halfWidth) ~= "number"
			or halfWidth <= 0
			or type(centreX) ~= "number"
			or type(centreZ) ~= "number"
			or not bounds
		then
			reason = "missing/non-numeric road-edge attributes"
		else
			local footprint = math.max((bounds.maxs.X - bounds.mins.X) / 2, (bounds.maxs.Z - bounds.mins.Z) / 2)
			if math.abs(lateral) - footprint < halfWidth - 0.05 then
				reason = "footprint enters road surface"
			end
			local okPos, pos = pcall(function()
				return plant.CFrame.Position
			end)
			if okPos and pos then
				local fromCentre = math.sqrt((pos.X - centreX) ^ 2 + (pos.Z - centreZ) ^ 2)
				if math.abs(fromCentre - math.abs(lateral)) > CENTRE_TOLERANCE then
					reason = reason or "CFrame disagrees with Lateral/Centre"
				end
			else
				reason = reason or "unreadable CFrame"
			end
		end
		if reason then
			offenders[#offenders + 1] = tostring(plant.Name) .. ":" .. reason
		end
	end
	local offRoadCount = #offenders
	if checked == 0 then
		offRoadCount = 1 -- no plants is not a vacuous pass
	end
	emit("EDGE_OFF_ROAD", checked > 0 and #offenders == 0, offRoadCount, 0, {
		checked = checked,
		offenders = offenders,
		centreTolerance = CENTRE_TOLERANCE,
	})
end)

-- Restore every additively staged candidate, even when a check threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("EDGE_HEIGHT", false, 0, HEIGHT_MIN, reason)
	emit("EDGE_VISIBLE", false, 0, VISIBLE_MIN, reason)
	emit("EDGE_OFF_ROAD", false, 1, 0, reason)
end

return results
