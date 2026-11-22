--!nocheck
-- check_q204: WORK_QUEUE item 204 (SPRINT 1), self-contained SERVER-VM Studio check. Paste this
-- whole file into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and
-- AFTER staging bamboo_bridge_r10 with enableAdditive, prints verbatim CHECK lines, then restores
-- with disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   BRIDGE_WALKABLE  the 6-stud lane has the same unobstructed walkable raycasts after staging
--   BRIDGE_MATERIAL  every staged deck plank is near the bamboo or wood RGB palette
--   BRIDGE_RAILS     both rail roles (rail_left and rail_right) are present in the staged set
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them.
--   BRIDGE_WALKABLE FAIL: make a staged overlay collidable across the lane, or delete the original
--     deck Part; after.blocked then exceeds before.blocked.
--   BRIDGE_MATERIAL FAIL: repaint one staged deck Part far from both palettes; violations becomes >0.
--   BRIDGE_RAILS FAIL: delete one staged rail or rename its `role` attribute; railCount becomes <2.

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

local CHECK_NAMES = { "BRIDGE_WALKABLE", "BRIDGE_MATERIAL", "BRIDGE_RAILS" }
local CANDIDATE_ID = "bamboo_bridge_r10"
local LANE_OFFSETS = { -2.5, -1.25, 0, 1.25, 2.5 }
local COLOR_TOLERANCE = 12

local review, Data, Failures = nil, nil, nil

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
local function measure()
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
	local okParams, made = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = walkables
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

	local deckParts, railRoles = {}, {}
	for _, instance in ipairs(staged) do
		local okRole, role = pcall(function()
			return instance:GetAttribute("role")
		end)
		if okRole and role == "deck" then
			deckParts[#deckParts + 1] = instance
		end
		if okRole and type(role) == "string" and string.sub(role, 1, 5) == "rail_" then
			railRoles[role] = true
		end
	end

	local violations = 0
	for _, part in ipairs(deckParts) do
		local okColor, color = pcall(function()
			return part.Color
		end)
		local matched = false
		if okColor and color then
			for _, palette in ipairs({ Data.BAMBOO_COLOR, Data.WOOD_COLOR }) do
				if
					math.abs(color.R * 255 - palette.r) <= COLOR_TOLERANCE
					and math.abs(color.G * 255 - palette.g) <= COLOR_TOLERANCE
					and math.abs(color.B * 255 - palette.b) <= COLOR_TOLERANCE
				then
					matched = true
				end
			end
		end
		if not matched then
			violations += 1
		end
	end

	local railCount = 0
	for _ in pairs(railRoles) do
		railCount += 1
	end

	local loadFailures = 0
	if Failures and type(Failures.get) == "function" then
		local okFailures, count = pcall(Failures.get, CANDIDATE_ID)
		if okFailures and type(count) == "number" then
			loadFailures = count
		end
	end

	return {
		blocked = blocked,
		samples = samples,
		violations = violations,
		deckCount = #deckParts,
		railCount = railCount,
		railLeft = railRoles.rail_left == true,
		railRight = railRoles.rail_right == true,
		staged = #staged,
		readErrors = readErrors,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapBambooBridgeR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" then
		error("ModelMapBambooBridgeR10 API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
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
			loadFailures = after.loadFailures,
			reason = enableReason,
		}
	)

	emit("BRIDGE_MATERIAL", after.deckCount > 0 and after.violations == 0, after.violations, 0, {
		deckCount = after.deckCount,
		tolerance = COLOR_TOLERANCE,
		beforeDeckCount = before.deckCount,
		loadFailures = after.loadFailures,
		reason = enableReason,
	})

	emit("BRIDGE_RAILS", after.railLeft and after.railRight and after.railCount == 2, after.railCount, 2, {
		railLeft = after.railLeft,
		railRight = after.railRight,
		beforeRailCount = before.railCount,
		staged = after.staged,
		loadFailures = after.loadFailures,
		reason = enableReason,
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
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "BRIDGE_RAILS" then 2 else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
