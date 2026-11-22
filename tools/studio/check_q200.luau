--!nocheck
-- check_q200: WORK_QUEUE item 200, self-contained SERVER-VM Studio check. Paste this whole file into
-- execute_luau in a fresh Play session. It measures the live place BEFORE and AFTER staging
-- kampung_r10 with enableAdditive, prints verbatim CHECK lines, then restores with disableAll() in
-- the same call. No harness require, no place save, no visual verdict.
--
--   KAMPUNG_HOUSES  12 distinct staged "house" groups
--   LANE_CLEAR      0 staged parts overlapping the four main road arms
--   PATH_REACH      blocked hub-door rays after == before (6 rays, 8 studs each)
--   PLOT_CLEAR      0 staged part footprints within 20 studs of a plot centre
--   NOT_INTERACTIVE 0 staged parts carrying a ProximityPrompt or ClickDetector
--   PERF_BUDGET     <=500 BasePart centres inside the 100-stud proxy radius
--
-- CALIBRATION: each emit has a single-line FAIL injection note. `local before = measure()` and
-- `local after = measure()` are separate single lines so a mismatch can be injected between them.

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

local CHECK_NAMES = { "KAMPUNG_HOUSES", "LANE_CLEAR", "PATH_REACH", "PLOT_CLEAR", "NOT_INTERACTIVE", "PERF_BUDGET" }
local CANDIDATE_ID = "kampung_r10"
local ROAD_HALF, ROAD_REACH = 14, 150
local PLOT_CLEARANCE, PLOT_RADIUS, PLOT_COUNT = 20, 192, 10
local RAY_LENGTH, RAY_Y = 8, 6
local PERF_RADIUS, PERF_TARGET = 100, 500
-- Mirrors MapSpec.HUBS: six local +Z door fronts. MapSpec is preferred when available.
local HUB_DOORS = {
	{ x = -64, z = -64, yaw = 0, depth = 52 },
	{ x = -80, z = -120, yaw = 0, depth = 28 },
	{ x = 68, z = -68, yaw = 0, depth = 44 },
	{ x = -108, z = 0, yaw = 90, depth = 40 },
	{ x = -68, z = 68, yaw = 180, depth = 44 },
	{ x = 68, z = 68, yaw = 180, depth = 34 },
}

local review, Data, Game, Failures = nil, nil, nil, nil

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	if ok then
		return value
	end
	return nil
end

local function plotCentres()
	local centres = {}
	for index = 1, PLOT_COUNT do
		local ok, x, z = pcall(function()
			return Game.plotCenter(index)
		end)
		if ok and type(x) == "number" and type(z) == "number" then
			centres[#centres + 1] = { x = x, z = z }
		else
			local angle = (index - 3) / PLOT_COUNT * math.pi * 2
			centres[#centres + 1] = { x = math.cos(angle) * PLOT_RADIUS, z = math.sin(angle) * PLOT_RADIUS }
		end
	end
	return centres
end

local function hubDoors()
	local doors = {}
	local okMap, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	end)
	if okMap and type(MapSpec) == "table" and type(MapSpec.hub) == "function" then
		for _, key in ipairs(MapSpec.HUB_ORDER) do
			local okHub, hub = pcall(MapSpec.hub, key)
			if okHub and hub then
				doors[#doors + 1] = hub
			end
		end
	end
	if #doors == 0 then
		return HUB_DOORS
	end
	return doors
end

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local houses, laneViolations, plotViolations, interactive = {}, 0, 0, 0
	local staged, perfParts, perfErrors = 0, 0, 0
	local centres = plotCentres()
	local doors = hubDoors()

	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		perfErrors += 1
		descendants = {}
	end

	for _, instance in ipairs(descendants) do
		if attr(instance, Data.tagAttribute) == true then
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				staged += 1
				local role = attr(instance, "role")
				local index = attr(instance, "house")
				if role == "house" and type(index) == "number" then
					houses[index] = true
				end

				local okGeom, position, size = pcall(function()
					return instance.CFrame.Position, instance.Size
				end)
				if okGeom and position and size then
					local hx, hz = size.X / 2, size.Z / 2
					local xMin, xMax = position.X - hx, position.X + hx
					local zMin, zMax = position.Z - hz, position.Z + hz
					local nearZAxis = xMax > -ROAD_HALF
						and xMin < ROAD_HALF
						and zMax > -ROAD_REACH
						and zMin < ROAD_REACH
					local nearXAxis = zMax > -ROAD_HALF
						and zMin < ROAD_HALF
						and xMax > -ROAD_REACH
						and xMin < ROAD_REACH
					if nearZAxis or nearXAxis then
						laneViolations += 1
					end
					local footprint = math.max(hx, hz)
					for _, centre in ipairs(centres) do
						local dx, dz = position.X - centre.x, position.Z - centre.z
						if math.sqrt(dx * dx + dz * dz) - footprint < PLOT_CLEARANCE then
							plotViolations += 1
							break
						end
					end
				end

				local okPrompt, prompt = pcall(function()
					return instance:FindFirstChildOfClass("ProximityPrompt")
				end)
				local okClick, click = pcall(function()
					return instance:FindFirstChildOfClass("ClickDetector")
				end)
				if (okPrompt and prompt) or (okClick and click) then
					interactive += 1
				end
			end
		end

		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okBase and isBase then
			local okPosition, position = pcall(function()
				return instance.CFrame.Position
			end)
			if not okPosition or not position then
				okPosition, position = pcall(function()
					return instance.Position
				end)
			end
			if not okPosition or not position then
				perfErrors += 1
			else
				local x, y, z = position.X, position.Y, position.Z
				if type(x) == "number" and type(y) == "number" and type(z) == "number" then
					if x * x + y * y + z * z <= PERF_RADIUS * PERF_RADIUS then
						perfParts += 1
					end
				else
					perfErrors += 1
				end
			end
		end
	end

	local houseCount = 0
	for _ in pairs(houses) do
		houseCount += 1
	end

	local blocked = 0
	local okParams, params = pcall(function()
		local q = RaycastParams.new()
		q.IgnoreWater = false
		return q
	end)
	if okParams then
		for _, hub in ipairs(doors) do
			local a = math.rad(hub.yaw or 0)
			local depth = hub.depth or 40
			local ox = hub.x + math.sin(a) * (depth / 2 + 1)
			local oz = hub.z + math.cos(a) * (depth / 2 + 1)
			local okRay, hit = pcall(function()
				local origin = Vector3.new(ox, RAY_Y, oz)
				local direction = Vector3.new(math.sin(a), 0, math.cos(a)) * RAY_LENGTH
				return workspace:Raycast(origin, direction, params)
			end)
			if okRay and hit and hit.Instance then
				local okTerrain, isTerrain = pcall(function()
					return hit.Instance:IsA("Terrain")
				end)
				local isStaged = attr(hit.Instance, Data.tagAttribute) == true
				if isStaged or not (okTerrain and isTerrain) then
					blocked += 1
				end
			end
		end
	end

	local loadFailures = 0
	if Failures and type(Failures.get) == "function" then
		local okFailures, count = pcall(Failures.get, CANDIDATE_ID)
		if okFailures and type(count) == "number" then
			loadFailures = count
		end
	end

	return {
		houses = houseCount,
		staged = staged,
		laneViolations = laneViolations,
		plotViolations = plotViolations,
		interactive = interactive,
		blocked = blocked,
		perfParts = perfParts,
		perfErrors = perfErrors,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapKampungR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))
	local okGame, loadedGame = pcall(function()
		return require(shared:WaitForChild("Config"):WaitForChild("Game"))
	end)
	if okGame then
		Game = loadedGame
	end

	if type(Data) ~= "table" or type(Data.houses) ~= "function" or type(Data.tagAttribute) ~= "string" then
		error("ModelMapKampungR10 API missing")
	end
	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview.enableAdditive missing")
	end

	-- Wiring lanes may add this path to Shared.LookDevReview. The harness stays self-contained if not.
	pcall(function()
		if type(review.paths) == "table" and review.paths[CANDIDATE_ID] == nil then
			review.paths[CANDIDATE_ID] = { datamodel = "server", path = { "World", "LookDevKampungR10" } }
		end
	end)

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	-- FAIL injection: destroy one staged body Part -> 11 house groups.
	emit("KAMPUNG_HOUSES", after.houses >= 10 and after.houses <= 14, after.houses, 12, {
		before = before.houses,
		stagedParts = after.staged,
		loadFailures = after.loadFailures,
		reason = enableReason,
	})
	-- FAIL injection: move one staged Part to x=0, z=160 -> LANE_CLEAR violation.
	emit("LANE_CLEAR", after.laneViolations == 0, after.laneViolations, 0, {
		before = before.laneViolations,
		laneHalf = ROAD_HALF,
		radius = ROAD_REACH,
	})
	-- FAIL injection: move one staged Part into a hub door's 8-stud ray -> after > before.
	emit("PATH_REACH", after.blocked == before.blocked, after.blocked, before.blocked, {
		before = before.blocked,
		rays = 6,
		length = RAY_LENGTH,
	})
	-- FAIL injection: move one staged Part onto plot 3 at (192, 0) -> PLOT_CLEAR violation.
	emit("PLOT_CLEAR", after.plotViolations == 0, after.plotViolations, 0, {
		before = before.plotViolations,
		clearance = PLOT_CLEARANCE,
		centres = #plotCentres(),
	})
	-- FAIL injection: add a ProximityPrompt to one staged Part -> 1 interactive part.
	emit("NOT_INTERACTIVE", after.interactive == 0, after.interactive, 0, {
		before = before.interactive,
		stagedParts = after.staged,
	})
	-- FAIL injection: stage 600 extra BaseParts at the origin -> over budget.
	emit("PERF_BUDGET", after.perfErrors == 0 and after.perfParts <= PERF_TARGET, after.perfParts, PERF_TARGET, {
		before = before.perfParts,
		readErrors = after.perfErrors,
		radius = PERF_RADIUS,
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
	local targets = {
		KAMPUNG_HOUSES = 12,
		LANE_CLEAR = 0,
		PATH_REACH = 0,
		PLOT_CLEAR = 0,
		NOT_INTERACTIVE = 0,
		PERF_BUDGET = PERF_TARGET,
	}
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, targets[name], reason)
	end
end

return results
