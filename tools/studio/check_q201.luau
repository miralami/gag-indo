--!nocheck
-- check_q201: WORK_QUEUE item 201, self-contained SERVER-VM Studio check. Paste this whole file into
-- execute_luau in a fresh Play session. It reads the live place BEFORE and AFTER staging
-- road_fence_r10 with enableAdditive, prints verbatim CHECK lines, then restores with disableAll()
-- in the same call. No harness require, no place save, no visual verdict.
--
--   ROAD_FENCE     >=6 distinct "stretch" groups among live parts tagged RoadFence
--   JUNCTION_GAPS  0 staged fence parts within 8 studs of the four r=144 road junctions
--   PATH_REACH     no extra blocked ray from the six hub doors after staging (8 studs each)
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a before/after mismatch can be injected between them.

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

local CHECK_NAMES = { "ROAD_FENCE", "JUNCTION_GAPS", "PATH_REACH" }
local CANDIDATE_ID = "road_fence_r10"
local JUNCTION_RADIUS, GAP_MIN = 144, 8
local DOOR_RAY_LENGTH, DOOR_RAY_Y = 8, 1.5

-- Junction points on the ring centreline, angles in degrees (0=east, 90=south, ...).
local JUNCTIONS = {}
for _, angle in ipairs({ 0, 90, 180, 270 }) do
	local radians = math.rad(angle)
	JUNCTIONS[#JUNCTIONS + 1] = {
		x = math.cos(radians) * JUNCTION_RADIUS,
		z = math.sin(radians) * JUNCTION_RADIUS,
	}
end

-- Hub door origins and outward normals copied from server World.MapSpec (server-only, so the shared
-- data module cannot require it). Local +Z faces (sin yaw, cos yaw) in world XZ.
local DOORS = {
	{ key = "pasar", x = -64, z = -64, yaw = 0, depth = 52 },
	{ key = "gelap", x = -80, z = -120, yaw = 0, depth = 28 },
	{ key = "warung", x = 68, z = -68, yaw = 0, depth = 44 },
	{ key = "ronda", x = -108, z = 0, yaw = 90, depth = 40 },
	{ key = "polisi", x = -68, z = 68, yaw = 180, depth = 44 },
	{ key = "pakrt", x = 68, z = 68, yaw = 180, depth = 34 },
}

local review, Data, Failures = nil, nil, nil

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local groups, staged, violations, blocked = {}, 0, 0, 0
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			local okTag, tagged = pcall(function()
				return instance:GetAttribute("RoadFence") == true
			end)
			if okTag and tagged then
				staged += 1
				local okStretch, stretch = pcall(function()
					return instance:GetAttribute("stretch")
				end)
				if okStretch and stretch ~= nil then
					groups[tostring(stretch)] = true
				end
				local okPosition, position = pcall(function()
					return instance.CFrame.Position
				end)
				if not okPosition or not position then
					okPosition, position = pcall(function()
						return instance.Position
					end)
				end
				if okPosition and position then
					for _, junction in ipairs(JUNCTIONS) do
						local dx, dz = position.X - junction.x, position.Z - junction.z
						if dx * dx + dz * dz < GAP_MIN * GAP_MIN then
							violations += 1
						end
					end
				end
			end
		end
	end
	local groupCount = 0
	for _ in pairs(groups) do
		groupCount += 1
	end

	local okParams, params = pcall(function()
		local query = RaycastParams.new()
		query.IgnoreWater = false
		query.FilterType = Enum.RaycastFilterType.Exclude
		local excluded = {}
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			if player.Character then
				excluded[#excluded + 1] = player.Character
			end
		end
		query.FilterDescendantsInstances = excluded
		return query
	end)

	if okParams then
		for _, door in ipairs(DOORS) do
			local radians = math.rad(door.yaw)
			local nx, nz = math.sin(radians), math.cos(radians)
			local origin =
				Vector3.new(door.x + nx * (door.depth / 2 + 2), DOOR_RAY_Y, door.z + nz * (door.depth / 2 + 2))
			local direction = Vector3.new(nx, 0, nz) * DOOR_RAY_LENGTH
			local okRay, hit = pcall(function()
				return workspace:Raycast(origin, direction, params)
			end)
			if okRay and hit and hit.Instance then
				blocked += 1
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
		staged = staged,
		groups = groupCount,
		violations = violations,
		blocked = blocked,
		loadFailures = loadFailures,
		rayErrors = if okParams then 0 else 1,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapRoadFenceR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" then
		error("ModelMapRoadFenceR10 API missing")
	end
	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview.enableAdditive API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local fenceDetail = {
		beforeStaged = before.staged,
		afterStaged = after.staged,
		beforeGroups = before.groups,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	-- CALIBRATION ROAD_FENCE FAIL: rename one staged part's "stretch" attribute so fewer than six
	-- distinct groups survive (or omit the attribute entirely).
	emit("ROAD_FENCE", after.groups >= 6, after.groups, 6, fenceDetail)

	local gapDetail = {
		beforeViolations = before.violations,
		junctionRadius = JUNCTION_RADIUS,
		gapStuds = GAP_MIN,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	-- CALIBRATION JUNCTION_GAPS FAIL: stage one extra tagged fence part centred on (144, 0).
	emit("JUNCTION_GAPS", after.violations == 0, after.violations, 0, gapDetail)

	local reachDetail = {
		beforeBlocked = before.blocked,
		afterBlocked = after.blocked,
		rayLength = DOOR_RAY_LENGTH,
		doors = #DOORS,
		rayErrors = after.rayErrors,
		reason = enableReason,
	}
	-- CALIBRATION PATH_REACH FAIL: stage a tagged blocking part across any hub-door ray.
	emit("PATH_REACH", after.blocked == before.blocked, after.blocked, before.blocked, reachDetail)
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
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "ROAD_FENCE" then 6 else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
