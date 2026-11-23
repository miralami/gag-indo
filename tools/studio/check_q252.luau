--!nocheck
-- check_q252: WORK_QUEUE item 252, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY bamboo_bridge_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores with disableAll() on every path. No harness require, no place save, no visual verdict.
--
--   BRIDGE_SWAP           default Greybox bridge parts (BridgeDeck/Post/Rail/Ramp, matched by name,
--                         never by candidate tag) are Transparency=1 / CanCollide=false while staged
--   BRIDGE_RESTORE        each of those exact instances has its original Transparency/CanCollide back
--   SUBJECT_COVERAGE_252  SubjectCoverage.measure("bamboo_bridge_r10", "bridge_side") >= 0.3
--   BRIDGE_WALKABLE       same lane raycasts before/after staging (delta 0); hidden default parts
--                         stay in the Include filter because their geometry is the walk lane and the
--                         staged bamboo overlay is deliberately non-collidable (no duplicate geometry)
--   BRIDGE_BAMBOO         >=0.80 of staged deck/rail parts are bamboo Cylinders (check_q245 logic)
--   LOOKDEV_LEAK          0 candidate-tagged parts left after disableAll(), with the default
--                         bridge parts back at their exact original values
--
-- CALIBRATION ANCHORS: inject a visible named "BridgeDeck" Part -> swap count drops; aim coverage at
-- horizon_north -> fraction below 0.3; leave a tagged staged Part behind across disableAll ->
-- positive workspace delta. Each injection is destroyed immediately; all paths end in disableAll().

local CANDIDATE_ID = "bamboo_bridge_r10"
local COVERAGE_CAMERA = "bridge_side"
local COVERAGE_AWAY_CAMERA = "horizon_north"
local COVERAGE_TARGET = 0.3
local BAMBOO_TARGET = 0.80
local BAMBOO_TARGET_TEXT = "0.80"
local LANE_OFFSETS = { -2.5, -1.25, 0, 1.25, 2.5 }
local BAMBOO_ROLES = { deck = true, rail_left = true, rail_right = true }
local DEFAULT_BRIDGE_NAMES = {
	BridgeDeck = true,
	BridgePost = true,
	BridgeRail = true,
	BridgeRamp = true,
}

local CHECK_NAMES = {
	"BRIDGE_SWAP",
	"BRIDGE_RESTORE",
	"SUBJECT_COVERAGE_252",
	"BRIDGE_WALKABLE",
	"BRIDGE_BAMBOO",
	"LOOKDEV_LEAK",
	"CAL_BRIDGE_SWAP_FAIL",
	"CAL_COVERAGE_252_FAIL",
	"CAL_LOOKDEV_LEAK_FAIL",
	"CAL_BRIDGE_WALKABLE_FAIL",
	"CAL_BRIDGE_BAMBOO_FAIL",
}
local CHECK_TARGETS = {
	BRIDGE_SWAP = "total",
	BRIDGE_RESTORE = "total",
	SUBJECT_COVERAGE_252 = tostring(COVERAGE_TARGET),
	BRIDGE_WALKABLE = 0,
	BRIDGE_BAMBOO = BAMBOO_TARGET_TEXT,
	LOOKDEV_LEAK = 0,
	CAL_BRIDGE_SWAP_FAIL = 1,
	CAL_COVERAGE_252_FAIL = 1,
	CAL_LOOKDEV_LEAK_FAIL = 1,
	CAL_BRIDGE_WALKABLE_FAIL = 1,
	CAL_BRIDGE_BAMBOO_FAIL = 1,
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

local function shown(value)
	return string.format("%.4f", tonumber(value) or 0)
end

local review = nil
local Data = nil
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

-- Staged candidate parts are SUPPOSED to disappear on unstage, so a raw workspace delta is
-- meaningless (-70 for a 69-part candidate). Count what is actually left behind instead: any
-- descendant still tagged with this candidate id, including an injected calibration leftover.
local function countTaggedLeftovers()
	local list, errors = descendants()
	local leftovers = 0
	for _, instance in ipairs(list) do
		pcall(function()
			if instance:GetAttribute("LookDevStage") == CANDIDATE_ID then
				leftovers += 1
			end
		end)
	end
	return leftovers, errors
end

-- Default bridge parts are identified by the literal names from Greybox.buildBridge. The
-- candidate's own LookDevStage-tagged parts are never part of this set.
local function bridgePartsFrom(list)
	local out = {}
	for _, instance in ipairs(list) do
		local okName, name = pcall(function()
			return instance.Name
		end)
		if okName and type(name) == "string" and DEFAULT_BRIDGE_NAMES[name] then
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

local function defaultBridgeParts()
	local list = descendants()
	return bridgePartsFrom(list)
end

local function snapshotDefaults()
	local all = descendants()
	local snapshot, total, errors = {}, 0, 0
	for _, part in ipairs(bridgePartsFrom(all)) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok then
			snapshot[part] = { transparency = transparency, canCollide = canCollide }
		else
			errors += 1
		end
	end
	return snapshot, total, errors
end

local function measureSwap()
	local hidden, total, errors = 0, 0, 0
	for _, part in ipairs(defaultBridgeParts()) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok and transparency == 1 and canCollide == false then
			hidden += 1
		elseif not ok then
			errors += 1
		end
	end
	return hidden, total, errors
end

local function measureRestore(snapshot)
	local restored, total, errors = 0, 0, 0
	for part, original in pairs(snapshot) do
		total += 1
		local ok, transparency, canCollide = pcall(function()
			return part.Transparency, part.CanCollide
		end)
		if ok and transparency == original.transparency and canCollide == original.canCollide then
			restored += 1
		elseif not ok then
			errors += 1
		end
	end
	for _, part in ipairs(defaultBridgeParts()) do
		if snapshot[part] == nil then
			total += 1 -- an extra default-like Part left behind is not a clean restore
		end
	end
	return restored, total, errors
end

-- One live measurement supplies both BRIDGE_WALKABLE and BRIDGE_BAMBOO (check_q245 logic).
-- ignoreWalkables empties the Include filter for the FAIL calibration: the same lane rays miss.
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

	-- Hidden default bridge Parts are kept in the ray filter: they were the walkable lane before
	-- staging and their geometry is unchanged, while the staged bamboo culms stay non-collidable.
	local known = {}
	for _, instance in ipairs(walkables) do
		known[instance] = true
	end
	for _, instance in ipairs(bridgePartsFrom(all)) do
		if not known[instance] then
			walkables[#walkables + 1] = instance
		end
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

	return {
		blocked = blocked,
		samples = samples,
		staged = #staged,
		bambooTotal = bambooTotal,
		bambooCulms = bambooCulms,
		bambooMarked = bambooMarked,
		fraction = if bambooTotal > 0 then bambooCulms / bambooTotal else 0,
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

local function inject(part)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = workspace
	injected[#injected + 1] = part
	return part
end

local function injectVisibleDefaultBridge()
	local part = Instance.new("Part")
	part.Name = "BridgeDeck"
	part.Size = Vector3.new(6, 0.5, 8)
	part.CFrame = CFrame.new(0, 1.25, 304)
	part.Color = Color3.fromRGB(150, 112, 64)
	part.Transparency = 0
	local created = inject(part)
	created.CanCollide = true
	return created
end

local function injectTaggedLeak()
	local part = Instance.new("Part")
	part.Name = "Q252_LEAK_CALIBRATION"
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(0, 40, 304)
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	part:SetAttribute("BambooBridge", true)
	return inject(part)
end

local function injectBambooFailBlocks()
	for index = 1, 8 do
		local part = Instance.new("Part")
		part.Name = "Q252_BAMBOO_CALIBRATION_" .. index
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(2, 0.5, 2)
		part.CFrame = CFrame.new(0, 1.25, 278 + index * 2)
		part.Color = Color3.fromRGB(186, 168, 96)
		part:SetAttribute("BambooBridge", true)
		part:SetAttribute("role", "deck")
		part:SetAttribute("LookDevStage", CANDIDATE_ID)
		inject(part)
	end
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapBambooBridgeR10"))
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Data) ~= "table"
		or type(Data.BRIDGE_START) ~= "table"
		or type(Data.BRIDGE_END) ~= "table"
	then
		error("SubjectCoverage / LookDevReview / ModelMapBambooBridgeR10 API missing")
	end

	local snapshot, originalTotal, snapshotErrors = snapshotDefaults()
	local walkBefore = measure(false)
	local staged, stageWhy = review.enableAdditive(CANDIDATE_ID, game)
	local reason = if staged == true then nil else "enableAdditive failed: " .. tostring(stageWhy)

	local hidden, swapTotal, swapErrors = measureSwap()
	emit(
		"BRIDGE_SWAP",
		staged == true
			and originalTotal > 0
			and hidden == originalTotal
			and swapTotal == originalTotal
			and swapErrors == 0
			and snapshotErrors == 0,
		hidden .. "/" .. swapTotal,
		originalTotal,
		{
			originalParts = originalTotal,
			hidden = hidden,
			readErrors = swapErrors + snapshotErrors,
			reason = reason,
		}
	)

	pcall(function()
		return review.disableAll()
	end)
	local restored, restoreTotal, restoreErrors = measureRestore(snapshot)
	emit(
		"BRIDGE_RESTORE",
		restored == originalTotal and restoreTotal == originalTotal and restoreErrors == 0,
		restored .. "/" .. restoreTotal,
		originalTotal,
		{
			originalParts = originalTotal,
			restored = restored,
			readErrors = restoreErrors,
		}
	)

	-- Re-stage for the coverage / walkability / bamboo measurements and their calibrations.
	local restaged, restageWhy = review.enableAdditive(CANDIDATE_ID, game)
	if restaged ~= true then
		reason = "re-stage failed: " .. tostring(restageWhy)
	end
	local walkAfter = measure(false)
	local walkDelta = math.max(0, walkAfter.blocked - walkBefore.blocked)
	local stagedEnough = walkAfter.staged > 0
	emit(
		"BRIDGE_WALKABLE",
		stagedEnough
			and walkDelta == 0
			and walkAfter.readErrors == 0
			and walkBefore.readErrors == 0
			and walkAfter.samples > 0,
		walkDelta,
		0,
		{
			beforeBlocked = walkBefore.blocked,
			afterBlocked = walkAfter.blocked,
			samples = walkAfter.samples,
			staged = walkAfter.staged,
			reason = reason,
		}
	)

	local coverageNow = coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)
	emit(
		"SUBJECT_COVERAGE_252",
		coverageNow.ok == true and coverageNow.fraction >= COVERAGE_TARGET,
		shown(coverageNow.fraction),
		tostring(COVERAGE_TARGET),
		{
			candidate = CANDIDATE_ID,
			camera = COVERAGE_CAMERA,
			fraction = coverageNow.fraction,
			sampleCount = coverageNow.sampleCount,
			hitCount = coverageNow.hitCount,
			partCount = coverageNow.partCount,
			ok = coverageNow.ok,
			reason = coverageNow.reason or reason,
		}
	)

	emit(
		"BRIDGE_BAMBOO",
		walkAfter.bambooTotal > 0 and walkAfter.fraction >= BAMBOO_TARGET,
		shown(walkAfter.fraction),
		BAMBOO_TARGET_TEXT,
		{
			deckAndRailParts = walkAfter.bambooTotal,
			culmShaped = walkAfter.bambooCulms,
			markerOnly = walkAfter.bambooMarked,
			staged = walkAfter.staged,
			readErrors = walkAfter.readErrors,
			reason = reason,
		}
	)

	-- CALIBRATION ANCHOR (SWAP FAIL): a visible default-named Part must count as not hidden.
	injectVisibleDefaultBridge()
	local calHidden, calTotal = measureSwap()
	local swapFailed = calHidden < calTotal
	emit("CAL_BRIDGE_SWAP_FAIL", swapFailed, swapFailed and 1 or 0, 1, {
		hidden = calHidden,
		total = calTotal,
		injectedName = "BridgeDeck",
		transparency = 0,
		canCollide = true,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (COVERAGE FAIL): the same staged candidate from a camera looking away.
	local away = coverage.measure(CANDIDATE_ID, COVERAGE_AWAY_CAMERA)
	local coverageFailed = not (away.ok == true and away.fraction >= COVERAGE_TARGET)
	emit("CAL_COVERAGE_252_FAIL", coverageFailed, coverageFailed and 1 or 0, 1, {
		fraction = shown(away.fraction),
		camera = COVERAGE_AWAY_CAMERA,
		ok = away.ok,
		reason = away.reason,
	})

	-- CALIBRATION ANCHOR (WALKABLE FAIL): empty Include filter makes the same 15 lane rays miss.
	local calWalk = measure(true)
	local calDelta = math.max(0, calWalk.blocked - walkAfter.blocked)
	local walkFailed = calDelta > 0
	emit("CAL_BRIDGE_WALKABLE_FAIL", walkFailed, walkFailed and 1 or 0, 1, {
		stagedBlocked = walkAfter.blocked,
		blockedWithoutWalkables = calWalk.blocked,
		delta = calDelta,
		samples = calWalk.samples,
	})

	-- CALIBRATION ANCHOR (BAMBOO FAIL): eight Block "deck" parts push the fraction below 0.80.
	injectBambooFailBlocks()
	local calBamboo = measure(false)
	local bambooFailed = calBamboo.fraction < BAMBOO_TARGET
	emit("CAL_BRIDGE_BAMBOO_FAIL", bambooFailed, bambooFailed and 1 or 0, 1, {
		fraction = shown(calBamboo.fraction),
		deckAndRailParts = calBamboo.bambooTotal,
		culmShaped = calBamboo.bambooCulms,
		injectedBlocks = 8,
	})
	destroyInjected()

	-- LOOKDEV_LEAK: no candidate-tagged descendant may survive disableAll(), and every default
	-- bridge part must be back at its exact original Transparency / CanCollide.
	pcall(function()
		return review.disableAll()
	end)
	local leaked, leakedErrors = countTaggedLeftovers()
	local bridgeRestored, bridgeTotal, bridgeErrors = measureRestore(snapshot)
	local bridgeClean = bridgeRestored == originalTotal and bridgeTotal == originalTotal and bridgeErrors == 0
	emit("LOOKDEV_LEAK", bridgeClean and leaked == 0 and leakedErrors == 0, leaked, 0, {
		taggedLeftovers = leaked,
		defaultBridgeRestored = bridgeRestored,
		defaultBridgeTotal = originalTotal,
		readErrors = leakedErrors + bridgeErrors,
	})

	-- CALIBRATION ANCHOR (LEAK FAIL): one tagged Part left behind survives disableAll().
	review.enableAdditive(CANDIDATE_ID, game)
	injectTaggedLeak()
	pcall(function()
		return review.disableAll()
	end)
	local calLeftovers, calErrors = countTaggedLeftovers()
	local leakFailed = calLeftovers >= 1 and calErrors == 0
	emit("CAL_LOOKDEV_LEAK_FAIL", leakFailed, leakFailed and 1 or 0, 1, {
		taggedLeftovers = calLeftovers,
		injectedName = "Q252_LEAK_CALIBRATION",
		readErrors = calErrors,
	})
	destroyInjected()
end)

-- Restore every staged candidate and every injection, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
destroyInjected()

if not ok then
	local reason = { reason = "item 252 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target = CHECK_TARGETS[name]
		if target == "total" then
			emitOnce(name, false, "0/0", 0, reason)
		else
			emitOnce(name, false, 0, target, reason)
		end
	end
end

return results
