--!nocheck
-- check_q245: WORK_QUEUE item 245, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY bamboo_bridge_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores with disableAll() on every path. No harness require, no place save, no visual verdict.
--
--   BRIDGE_WALKABLE  same unobstructed downward rays over the 6-stud lane after staging (delta 0)
--   BRIDGE_RAILS     both rail roles present among BambooBridge-tagged parts (count 2)
--   BRIDGE_BAMBOO    >=0.80 of staged deck/rail parts are Cylinder or bamboo-model parts
--
-- BRIDGE_WALKABLE and BRIDGE_RAILS keep check_q204's live logic and CHECK lines verbatim. Node
-- rings are excluded from the BRIDGE_BAMBOO denominator (they are Cylinder anyway).
--
-- CALIBRATION ANCHORS: inject eight Block "deck" parts tagged BambooBridge -> fraction drops
-- below 0.80 -> `CHECK CAL_BRIDGE_BAMBOO_FAIL PASS 1 1`; destroy the injection. For walkability,
-- re-measure with measure(true), which empties the Include filter so all 15 lane rays miss ->
-- blocked 15 > 0 -> `CHECK CAL_BRIDGE_WALKABLE_FAIL PASS 1 1`. No world mutation for that anchor.
-- The measure() moments are separate single lines.

local CANDIDATE_ID = "bamboo_bridge_r10"
local CHECK_NAMES = {
	"BRIDGE_WALKABLE",
	"BRIDGE_RAILS",
	"BRIDGE_BAMBOO",
	"CAL_BRIDGE_WALKABLE_FAIL",
	"CAL_BRIDGE_BAMBOO_FAIL",
}
local CHECK_TARGETS = {
	BRIDGE_WALKABLE = 0,
	BRIDGE_RAILS = 2,
	BRIDGE_BAMBOO = "0.80",
	CAL_BRIDGE_WALKABLE_FAIL = 1,
	CAL_BRIDGE_BAMBOO_FAIL = 1,
}
local LANE_OFFSETS = { -2.5, -1.25, 0, 1.25, 2.5 }
local BAMBOO_ROLES = { deck = true, rail_left = true, rail_right = true }

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

local review, Data = nil, nil
local injected = {}

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list, 0
	end
	return {}, 1
end

-- Every reading comes from the live DataModel, never from the pure data alone.
-- ignoreWalkables empties the Include filter for the CAL_BRIDGE_WALKABLE_FAIL anchor: the same
-- 15 rays then miss and `blocked` rises, proving the check can fail without mutating the world.
local function measure(ignoreWalkables)
	local all, readErrors = descendants()
	local staged, walkables = {}, {}
	for _, instance in ipairs(all) do
		pcall(function()
			if instance:GetAttribute("BambooBridge") == true then
				staged[#staged + 1] = instance
			elseif instance:IsA("BasePart") and instance.CanCollide == true then
				walkables[#walkables + 1] = instance
			end
		end)
	end

	local params = nil
	local filter = if ignoreWalkables then {} else walkables
	local okParams, made = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = filter
		p.IgnoreWater = true
		return p
	end)
	if okParams and made then
		params = made
	else
		readErrors += 1
	end

	local blocked, samples = 0, 0
	if Data and params then
		local start, finish = Data.BRIDGE_START, Data.BRIDGE_END
		local zSamples = { start.z + 8, (start.z + finish.z) / 2, finish.z - 8 }
		for _, z in ipairs(zSamples) do
			for _, x in ipairs(LANE_OFFSETS) do
				local okRay, hit = pcall(function()
					return workspace:Raycast(Vector3.new(x, start.y + 16, z), Vector3.new(0, -64, 0), params)
				end)
				samples += 1
				if not okRay then
					readErrors += 1
				end
				if not okRay or not hit then
					blocked += 1
				end
			end
		end
	else
		readErrors += 1
		blocked = #LANE_OFFSETS * 3
	end

	-- BRIDGE_BAMBOO denominator: staged parts whose role is deck / rail_left / rail_right only.
	-- Compare the Enum item directly (tostring gives "Enum.PartType.Cylinder", not "Cylinder").
	local bambooTotal, bambooCulms, bambooMarked = 0, 0, 0
	local railRoles = {}
	for _, instance in ipairs(staged) do
		local okRole, role = pcall(function()
			return instance:GetAttribute("role")
		end)
		if okRole and type(role) == "string" and string.sub(role, 1, 5) == "rail_" then
			railRoles[role] = true
		end
		if okRole and BAMBOO_ROLES[role] then
			bambooTotal += 1
			local okShape, shape = pcall(function()
				return instance.Shape
			end)
			local okMarker, marker = pcall(function()
				return instance:GetAttribute("BambooModel")
			end)
			local cylinder = okShape and shape == Enum.PartType.Cylinder
			local marked = okMarker and marker == true
			if cylinder or marked then
				bambooCulms += 1
				if not cylinder and marked then
					bambooMarked += 1
				end
			end
		end
	end
	local railCount = 0
	for _ in pairs(railRoles) do
		railCount += 1
	end

	local fraction = 0
	if bambooTotal > 0 then
		fraction = bambooCulms / bambooTotal
	end

	return {
		blocked = blocked,
		samples = samples,
		bambooTotal = bambooTotal,
		bambooCulms = bambooCulms,
		bambooMarked = bambooMarked,
		fraction = fraction,
		railCount = railCount,
		railLeft = railRoles.rail_left == true,
		railRight = railRoles.rail_right == true,
		staged = #staged,
		readErrors = readErrors,
	}
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectBambooFailBlocks()
	for index = 1, 8 do
		local part = Instance.new("Part")
		part.Name = "Q245_BAMBOO_CALIBRATION_" .. index
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(2, 0.5, 2)
		part.CFrame = CFrame.new(0, 1.25, 278 + index * 2)
		part.Color = Color3.fromRGB(186, 168, 96)
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part:SetAttribute("BambooBridge", true)
		part:SetAttribute("role", "deck")
		part:SetAttribute("LookDevStage", CANDIDATE_ID)
		part.Parent = workspace
		injected[#injected + 1] = part
	end
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapBambooBridgeR10"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" then
		error("ModelMapBambooBridgeR10 API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE): a mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local walkDelta = math.max(0, after.blocked - before.blocked)
	-- Guard against a vacuous PASS: no staged BambooBridge parts means the lane was never restyled.
	local stagedEnough = after.staged > 0
	local walkMeasured = if stagedEnough then walkDelta else 0
	emit(
		"BRIDGE_WALKABLE",
		stagedEnough and walkDelta == 0 and after.readErrors == 0 and after.samples > 0,
		walkMeasured,
		0,
		{
			beforeBlocked = before.blocked,
			afterBlocked = after.blocked,
			samples = after.samples,
			staged = after.staged,
			readErrors = after.readErrors,
			reason = reason,
		}
	)

	emit("BRIDGE_RAILS", after.railLeft and after.railRight and after.railCount == 2, after.railCount, 2, {
		railLeft = after.railLeft,
		railRight = after.railRight,
		beforeRailCount = before.railCount,
		staged = after.staged,
		reason = reason,
	})

	emit(
		"BRIDGE_BAMBOO",
		after.bambooTotal > 0 and after.fraction >= 0.80,
		string.format("%.4f", after.fraction),
		"0.80",
		{
			deckAndRailParts = after.bambooTotal,
			culmShaped = after.bambooCulms,
			markerOnly = after.bambooMarked,
			staged = after.staged,
			readErrors = after.readErrors,
			reason = reason,
		}
	)

	-- CALIBRATION ANCHOR (BRIDGE_BAMBOO FAIL): eight Block decks must push the fraction below 0.80.
	injectBambooFailBlocks()
	local calBamboo = measure()
	local bambooFailed = calBamboo.fraction < 0.80
	emit("CAL_BRIDGE_BAMBOO_FAIL", bambooFailed, bambooFailed and 1 or 0, 1, {
		fraction = string.format("%.4f", calBamboo.fraction),
		deckAndRailParts = calBamboo.bambooTotal,
		culmShaped = calBamboo.bambooCulms,
		injectedBlocks = 8,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (BRIDGE_WALKABLE FAIL): re-measure with an empty Include filter. The
	-- same 15 rays miss every walkable surface, so `blocked` rises without touching the world.
	local calWalk = measure(true)
	local calDelta = math.max(0, calWalk.blocked - after.blocked)
	local walkFailed = calDelta > 0
	emit("CAL_BRIDGE_WALKABLE_FAIL", walkFailed, walkFailed and 1 or 0, 1, {
		stagedBlocked = after.blocked,
		blockedWithoutWalkables = calWalk.blocked,
		delta = calDelta,
		samples = calWalk.samples,
	})
end)

-- Restore every additively staged candidate and every injection, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
destroyInjected()

if not ok then
	local reason = { reason = "item 245 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
