--!nocheck
-- check_q194: WORK_QUEUE section Q item 194, self-contained SERVER-VM Studio check. Paste this whole
-- file into execute_luau in a fresh Play session. It stages meadow_r10 with enableAdditive in this
-- SAME call, measures live tagged geometry, prints verbatim CHECK lines and restores with disableAll().
-- No harness require, no place save, no visual verdict. Missing folder / tags / reads FAIL.
--
--   MEADOW_PATCHES  >=20 distinct PatchIndex groups of MeadowPlant parts (10..20 items each)
--   MEADOW_OFF_ROAD every meadow item centre clears the roads, the ring, plot rects and plot gates
--   MEADOW_VISIBLE  >=6 patches with >=3 of 5 rays from canonical_overview hitting that patch

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

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local PATCH_MIN = 20
local VISIBLE_MIN = 6
local ITEM_MIN, ITEM_MAX = 10, 20
local RAYS_PER_PATCH, RAY_HIT_MIN = 5, 3
local ROAD_HALF, RING_CENTRE, RING_HALF = 14, 144, 6
local PLOT_RADIUS, PLOT_FRACTION = 192, 1 / 10
local PLOT_COUNT, GATE_CLEAR = 10, 6
local MARGIN = 4

-- Independent conservative predicate: reject the 28-wide X/Z arms out to the ring, the 12-wide
-- connector ring, the 16-wide bridge continuation, every plot footprint and a clear band at each
-- plot gate. Uses live MapSpec.ROAD values where available; no data-module helper is trusted.
local function offRoad(x, z, road)
	local half = (road and road.halfWidth) or ROAD_HALF
	local ring = (road and road.ringCentre) or RING_CENTRE
	local ringHalf = (road and road.ringWidth and road.ringWidth / 2) or RING_HALF
	local r = math.sqrt(x * x + z * z)
	if math.abs(r - ring) <= ringHalf + MARGIN then
		return false, "ring"
	end
	if math.abs(z) <= half + MARGIN and math.abs(x) <= ring + MARGIN then
		return false, "x-arm"
	end
	if math.abs(x) <= half + MARGIN and math.abs(z) <= ring + MARGIN then
		return false, "z-arm"
	end
	if math.abs(x) <= (road and road.linkHalfWidth or 8) + MARGIN and z >= ring and z <= 276 then
		return false, "bridge-link"
	end
	local plotHalf = PLOT_RADIUS * PLOT_FRACTION
	for index = 1, PLOT_COUNT do
		local angle = (index - 3) / PLOT_COUNT * math.pi * 2
		local cx, cz = math.cos(angle) * PLOT_RADIUS, math.sin(angle) * PLOT_RADIUS
		if math.abs(x - cx) <= plotHalf + MARGIN and math.abs(z - cz) <= plotHalf + MARGIN then
			return false, "plot-" .. index
		end
		local dx, dz = x - cx, z - cz
		if dx * dx + dz * dz <= (plotHalf + GATE_CLEAR + MARGIN) ^ 2 then
			return false, "gate-" .. index
		end
	end
	return true, nil
end

local function vec(v)
	if type(v) == "table" and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" then
		return Vector3.new(v[1], v[2], v[3])
	end
	if typeof(v) == "Vector3" then
		return v
	end
	return nil
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local data = require(shared:WaitForChild("ModelMapMeadowR10"))

	local enabled, why = review.enableAdditive("meadow_r10", game)
	if not enabled then
		error("enableAdditive(meadow_r10) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(data.folderName))
	end
	local descendants = folder:GetDescendants()
	if type(descendants) ~= "table" or #descendants == 0 then
		error("staging folder has no descendants")
	end

	local mapOk, mapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	local road = (mapOk and type(mapSpec) == "table" and mapSpec.ROAD) or nil

	-- Gather every staged meadow part and group by PatchIndex / ItemIndex.
	local parts = {}
	for _, instance in ipairs(descendants) do
		if instance:IsA("BasePart") and instance:GetAttribute("MeadowPlant") == true then
			parts[#parts + 1] = instance
		end
	end
	if #parts == 0 then
		error("no MeadowPlant tagged parts under " .. tostring(data.folderName))
	end
	local patchItems = {}
	local patchItemIds = {}
	for _, part in ipairs(parts) do
		local pi = part:GetAttribute("PatchIndex")
		if type(pi) == "number" then
			patchItems[pi] = patchItems[pi] or {}
			patchItems[pi][#patchItems[pi] + 1] = part
			local ii = part:GetAttribute("ItemIndex")
			if type(ii) == "number" then
				patchItemIds[pi] = patchItemIds[pi] or {}
				patchItemIds[pi][ii] = true
			end
		end
	end
	local patchCount = 0
	for _, items in pairs(patchItems) do
		patchCount += 1
	end
	emit("MEADOW_PATCHES", patchCount >= PATCH_MIN, patchCount, PATCH_MIN, {
		parts = #parts,
		itemCounts = (function()
			local t = {}
			for pi, ids in pairs(patchItemIds) do
				local n = 0
				for _ in pairs(ids) do
					n += 1
				end
				t[#t + 1] = pi .. ":" .. n
			end
			table.sort(t)
			return t
		end)(),
	})

	-- Off-road: every item centre (VegX/VegZ, matching the pure layout) clears roads/gates. The
	-- item count per patch is also checked here so a 1-item patch cannot inflate MEADOW_PATCHES.
	local bad, sizeBad, offReason = 0, 0, {}
	for pi, items in pairs(patchItems) do
		local idCount = 0
		for _ in pairs(patchItemIds[pi] or {}) do
			idCount += 1
		end
		if idCount < ITEM_MIN or idCount > ITEM_MAX then
			sizeBad += 1
		end
		for _, part in ipairs(items) do
			local o, x, z = pcall(function()
				local vx, vz = part:GetAttribute("VegX"), part:GetAttribute("VegZ")
				if type(vx) == "number" and type(vz) == "number" then
					return vx, vz
				end
				local p = part.Position
				return p.X, p.Z
			end)
			local clear, reason = true, nil
			if not o or type(x) ~= "number" or type(z) ~= "number" then
				clear, reason = false, "unreadable"
			else
				clear, reason = offRoad(x, z, road)
			end
			if not clear then
				bad += 1
				if #offReason < 12 then
					offReason[#offReason + 1] = "p" .. tostring(pi) .. " " .. tostring(reason)
				end
			end
		end
	end
	emit("MEADOW_OFF_ROAD", bad == 0 and sizeBad == 0, bad + sizeBad, 0, {
		badParts = bad,
		badSizes = sizeBad,
		reasons = offReason,
	})

	-- Visibility from canonical_overview: cast up to 5 rays per patch at its item parts with an
	-- Include filter on the staged folder; a patch is seen when >=3 rays first-hit that same patch.
	local eye = nil
	if mapOk and type(mapSpec) == "table" then
		local camsOk, cams = pcall(function()
			return require(shared:WaitForChild("ReviewCameras"))
		end)
		if camsOk and type(cams) == "table" and type(cams.all) == "function" then
			for _, c in ipairs(cams.all()) do
				if c.name == "canonical_overview" then
					eye = vec(c.position)
					break
				end
			end
		end
	end
	local visible, visErr = 0, nil
	if not eye then
		visErr = "canonical_overview camera missing"
	else
		local okParams, params = pcall(function()
			local q = RaycastParams.new()
			q.FilterType = Enum.RaycastFilterType.Include
			q.FilterDescendantsInstances = { folder }
			q.IgnoreWater = false
			return q
		end)
		if not okParams then
			visErr = "raycast params failed"
		else
			for pi, items in pairs(patchItems) do
				local step = math.max(1, math.floor(#items / RAYS_PER_PATCH))
				local hits, rays = 0, 0
				for i = 1, #items, step do
					if rays >= RAYS_PER_PATCH then
						break
					end
					local part = items[i]
					local o, target = pcall(function()
						return part:IsA("BasePart") and part.CFrame.Position or nil
					end)
					if o and target then
						rays += 1
						local delta = target - eye
						local oray, hit = pcall(function()
							return workspace:Raycast(eye, delta.Unit * (delta.Magnitude + 4), params)
						end)
						if oray and hit and hit.Instance and hit.Instance:GetAttribute("PatchIndex") == pi then
							hits += 1
						end
					end
				end
				if hits >= RAY_HIT_MIN then
					visible += 1
				end
			end
		end
	end
	emit("MEADOW_VISIBLE", visErr == nil and visible >= VISIBLE_MIN, visible, VISIBLE_MIN, {
		reason = visErr,
		raysPerPatch = RAYS_PER_PATCH,
		rayHitMin = RAY_HIT_MIN,
	})
end)

-- Restore every additively staged candidate, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emitOnce("MEADOW_PATCHES", false, 0, PATCH_MIN, reason)
	emitOnce("MEADOW_OFF_ROAD", false, 1, 0, reason)
	emitOnce("MEADOW_VISIBLE", false, 0, VISIBLE_MIN, reason)
end

return results
