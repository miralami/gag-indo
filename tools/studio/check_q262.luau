--!nocheck
-- check_q262: WORK_QUEUE item 262, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play Server session. Stages ONLY road_fence_r10 with LookDevReview,
-- measures the live DataModel, prints verbatim CHECK lines plus SUMMARY_Q262, then restores on every
-- path. No harness require, no client, no place save, no visual verdict.
--
--   MODEL_USED   >=6 fence groups with >=2 staged baked-model parts each (asset-id signature)
--   LANE_CLEAR   0 hub-door path rays blocked by staged fence parts (8 studs per door)
--   GATE_CLEAR   0 staged fence parts inside the r=144 junction or r=152 plot-gate corridors
--
-- CALIBRATION ANCHORS (each forces a FAIL the same measure must catch, then restores LIFO):
--   CAL_MODEL_USED_FAIL   strip RoadFenceAssetId from every live fence part -> 0 model groups
--   CAL_LANE_CLEAR_FAIL   inject one tagged fence block across the first hub-door ray -> 1 blocked

local CANDIDATE_ID = "road_fence_r10"
local ASSET_ID = 1158365955 -- pick 2, baked by main session; pick 1 was an all-red OOF placeholder; recorded in ASSET_MANIFEST.md
local ASSET_ATTR = "RoadFenceAssetId"
local GROUP_ATTR = "RoadFenceGroup"
local STAGE_ATTR = "LookDevStage"
local GROUP_TARGET = 6
local GROUP_MIN_PARTS = 2
local GAP_MIN = 8
local JUNCTION_RADIUS, GATE_RADIUS = 144, 152
local DOOR_RAY_LENGTH, DOOR_RAY_Y = 8, 1.5

local CHECK_NAMES = {
	"MODEL_USED",
	"LANE_CLEAR",
	"GATE_CLEAR",
	"CAL_MODEL_USED_FAIL",
	"CAL_LANE_CLEAR_FAIL",
}
local targets = {
	MODEL_USED = GROUP_TARGET,
	LANE_CLEAR = 0,
	GATE_CLEAR = 0,
	CAL_MODEL_USED_FAIL = 1,
	CAL_LANE_CLEAR_FAIL = 1,
}

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

local function printSummary()
	local mainPass, calPass = 0, 0
	for index, name in ipairs(CHECK_NAMES) do
		local entry = results.byName[name]
		if entry and entry.passed then
			if index <= 3 then
				mainPass += 1
			else
				calPass += 1
			end
		end
	end
	print(
		string.format(
			"SUMMARY_Q262 MODEL_USED %d/%d LANE_CLEAR %d/0 GATE_CLEAR %d/0 CAL %d/2",
			results.byName.MODEL_USED and results.byName.MODEL_USED.measured or 0,
			GROUP_TARGET,
			results.byName.LANE_CLEAR and results.byName.LANE_CLEAR.measured or 0,
			results.byName.GATE_CLEAR and results.byName.GATE_CLEAR.measured or 0,
			calPass
		)
	)
end

-- Junction and plot-gate centres. Any staged fence part inside GAP_MIN of one is a violation.
local CORRIDORS = {}
for _, angle in ipairs({ 0, 90, 180, 270 }) do
	local radians = math.rad(angle)
	local dx, dz = math.cos(radians), math.sin(radians)
	CORRIDORS[#CORRIDORS + 1] = { x = dx * JUNCTION_RADIUS, z = dz * JUNCTION_RADIUS }
	CORRIDORS[#CORRIDORS + 1] = { x = dx * GATE_RADIUS, z = dz * GATE_RADIUS }
end

-- Hub door origins and outward normals copied from server World.MapSpec (server-only module).
local DOORS = {
	{ key = "pasar", x = -64, z = -64, yaw = 0, depth = 52 },
	{ key = "gelap", x = -80, z = -120, yaw = 0, depth = 28 },
	{ key = "warung", x = 68, z = -68, yaw = 0, depth = 44 },
	{ key = "ronda", x = -108, z = 0, yaw = 90, depth = 40 },
	{ key = "polisi", x = -68, z = 68, yaw = 180, depth = 44 },
	{ key = "pakrt", x = 68, z = 68, yaw = 180, depth = 34 },
}

local function doorRay(index)
	local door = DOORS[index]
	local radians = math.rad(door.yaw)
	local nx, nz = math.sin(radians), math.cos(radians)
	local origin = Vector3.new(door.x + nx * (door.depth / 2 + 2), DOOR_RAY_Y, door.z + nz * (door.depth / 2 + 2))
	return origin, Vector3.new(nx, 0, nz) * DOOR_RAY_LENGTH
end

local review, Data = nil, nil
local injected = {}
local temporary = {}

-- Save exact prior values before every live mutation; restore LIFO on every path.
local function recordAttr(target, prop, value)
	local okRead, old = pcall(function()
		return target:GetAttribute(prop)
	end)
	if not okRead then
		return false
	end
	injected[#injected + 1] = { target = target, prop = prop, value = old }
	local okWrite, why = pcall(function()
		target:SetAttribute(prop, value)
	end)
	if not okWrite then
		warn("[check_q262] could not inject " .. prop .. ": " .. tostring(why))
	end
	return okWrite
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		pcall(function()
			entry.target:SetAttribute(entry.prop, entry.value)
		end)
		injected[index] = nil
	end
	for index = #temporary, 1, -1 do
		pcall(function()
			temporary[index]:Destroy()
		end)
		temporary[index] = nil
	end
end

local function stagedParts()
	local found = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			pcall(function()
				if
					instance:IsA("BasePart")
					and instance:GetAttribute(STAGE_ATTR) == CANDIDATE_ID
					and instance:GetAttribute(ASSET_ATTR) == ASSET_ID
				then
					found[#found + 1] = instance
				end
			end)
		end
	end
	return found
end

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local groups, partCount, gateHits, rayErrors, blocked = {}, 0, 0, 0, 0
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		rayErrors += 1
		descendants = {}
	end

	for _, instance in ipairs(descendants) do
		pcall(function()
			if
				instance:IsA("BasePart")
				and instance:GetAttribute(STAGE_ATTR) == CANDIDATE_ID
				and instance:GetAttribute(ASSET_ATTR) == ASSET_ID
			then
				partCount += 1
				local group = instance:GetAttribute(GROUP_ATTR)
				if type(group) == "string" and group ~= "" then
					if not groups[group] then
						groups[group] = 0
					end
					groups[group] += 1
				end
				local position = instance.Position
				for _, corridor in ipairs(CORRIDORS) do
					local dx, dz = position.X - corridor.x, position.Z - corridor.z
					if dx * dx + dz * dz < GAP_MIN * GAP_MIN then
						gateHits += 1
					end
				end
			end
		end)
	end

	local qualified = 0
	for _, count in pairs(groups) do
		if count >= GROUP_MIN_PARTS then
			qualified += 1
		end
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
	if not okParams then
		rayErrors += 1
	else
		for index = 1, #DOORS do
			local origin, direction = doorRay(index)
			local okRay, hit = pcall(function()
				return workspace:Raycast(origin, direction, params)
			end)
			if not okRay then
				rayErrors += 1
			elseif hit and hit.Instance then
				pcall(function()
					if
						hit.Instance:GetAttribute(STAGE_ATTR) == CANDIDATE_ID
						and hit.Instance:GetAttribute(ASSET_ATTR) == ASSET_ID
					then
						blocked += 1
					end
				end)
			end
		end
	end

	return {
		groups = qualified,
		parts = partCount,
		gateHits = gateHits,
		blocked = blocked,
		rayErrors = rayErrors,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapRoadFenceR10"))
	local failures = require(shared:WaitForChild("LookDevFailures"))

	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview.enableAdditive API missing")
	end
	if type(Data) ~= "table" or type(Data.parts) ~= "function" then
		error("ModelMapRoadFenceR10 API missing")
	end

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local live = measure()
	local loadFailures = 0
	pcall(function()
		local count = failures.get(CANDIDATE_ID)
		if type(count) == "number" then
			loadFailures = count
		end
	end)

	emit("MODEL_USED", reason == nil and live.groups >= GROUP_TARGET and live.parts > 0, live.groups, GROUP_TARGET, {
		assetId = ASSET_ID,
		stagedParts = live.parts,
		groupMinParts = GROUP_MIN_PARTS,
		loadFailures = loadFailures,
		reason = reason,
	})
	emit("LANE_CLEAR", reason == nil and live.blocked == 0 and live.rayErrors == 0, live.blocked, 0, {
		doors = #DOORS,
		rayLength = DOOR_RAY_LENGTH,
		rayErrors = live.rayErrors,
		reason = reason,
	})
	emit("GATE_CLEAR", reason == nil and live.gateHits == 0, live.gateHits, 0, {
		junctionRadius = JUNCTION_RADIUS,
		gateRadius = GATE_RADIUS,
		gapStuds = GAP_MIN,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (MODEL_USED FAIL): without the baked-asset signature no group qualifies.
	local victims = stagedParts()
	local stripped = 0
	for _, part in ipairs(victims) do
		if recordAttr(part, ASSET_ATTR, nil) then
			stripped += 1
		end
	end
	local calModel = measure()
	local modelFailed = stripped > 0 and calModel.groups < GROUP_TARGET
	emit("CAL_MODEL_USED_FAIL", modelFailed, modelFailed and 1 or 0, 1, {
		stripped = stripped,
		groups = calModel.groups,
		parts = calModel.parts,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (LANE_CLEAR FAIL): one tagged block across the first door ray must be hit.
	local origin, direction = doorRay(1)
	local block = Instance.new("Part")
	block.Name = "Q262_Calibration_Block"
	block.Size = Vector3.new(2, 2, 2)
	block.CFrame = CFrame.new(origin + direction * 0.5)
	block.Anchored = true
	block.CanCollide = false
	block.CanQuery = true
	block:SetAttribute(STAGE_ATTR, CANDIDATE_ID)
	block:SetAttribute(ASSET_ATTR, ASSET_ID)
	block:SetAttribute(GROUP_ATTR, "CAL_LANE_CLEAR_FAIL")
	block.Parent = workspace
	temporary[#temporary + 1] = block
	local calLane = measure()
	local laneFailed = calLane.blocked > 0
	emit("CAL_LANE_CLEAR_FAIL", laneFailed, laneFailed and 1 or 0, 1, {
		blocked = calLane.blocked,
		door = DOORS[1].key,
		rayErrors = calLane.rayErrors,
	})
	restoreInjected()
end)

-- Restore injected attributes, temporary parts and every staged candidate on every path.
restoreInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 262 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, targets[name], reason)
	end
end

printSummary()

return results
