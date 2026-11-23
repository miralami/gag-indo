--!nocheck
-- check_q257: WORK_QUEUE item 257, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. Stages ONLY signposts_r10 with LookDevReview, measures
-- the live DataModel, prints verbatim CHECK lines and SUMMARY_Q257, then restores on every path.
--
--   MODEL_USED      >=4 staged baked MeshParts with the restyled signpost's post MeshId
--   SIGN_PLATES     max plates on one staged sign >=5 (data contract stages six)
--   STRINGS_PARITY  all six declared plate keys have non-empty id and en in Shared.Strings.raw
--
-- CALIBRATION ANCHORS (each forces a FAIL the same measure must catch, then restores LIFO):
--   CAL_MODEL_USED_FAIL      strip the staging tag from every restyled post MeshPart
--   CAL_SIGN_PLATES_FAIL     unflag every staged plate, on every sign
--   CAL_STRINGS_PARITY_FAIL  blank one plate key's id/en in the live Strings table

local CANDIDATE_ID = "signposts_r10"
local SIGN_MESH_ID = "rbxassetid://122307668139747"
local STAGE_ATTR = "LookDevStage"
local MODEL_TARGET = 4
local PLATE_TARGET = 5

local CHECK_NAMES = {
	"MODEL_USED",
	"SIGN_PLATES",
	"STRINGS_PARITY",
	"CAL_MODEL_USED_FAIL",
	"CAL_SIGN_PLATES_FAIL",
	"CAL_STRINGS_PARITY_FAIL",
}
local targets = {
	MODEL_USED = MODEL_TARGET,
	SIGN_PLATES = PLATE_TARGET,
	STRINGS_PARITY = 6,
	CAL_MODEL_USED_FAIL = 1,
	CAL_SIGN_PLATES_FAIL = 1,
	CAL_STRINGS_PARITY_FAIL = 1,
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
	local mainPass, mainFail, calPass, calTotal = 0, 0, 0, 0
	for index, name in ipairs(CHECK_NAMES) do
		local entry = results.byName[name]
		if index <= 3 then
			if entry and entry.passed then
				mainPass += 1
			else
				mainFail += 1
			end
		else
			calTotal += 1
			if entry and entry.passed then
				calPass += 1
			end
		end
	end
	print(
		string.format(
			"SUMMARY_Q257 PASS %d/%d FAIL %d/%d CAL %d/%d",
			mainPass,
			mainPass + mainFail,
			mainFail,
			mainPass + mainFail,
			calPass,
			calTotal
		)
	)
end

local review, Data, StringsRaw
local injected = {}

local function recordSet(target, prop, value, isAttribute)
	local okRead, old = pcall(function()
		if isAttribute then
			return target:GetAttribute(prop)
		end
		return target[prop]
	end)
	if not okRead then
		return false
	end
	injected[#injected + 1] = { target = target, prop = prop, value = old, isAttribute = isAttribute }
	local okWrite, why = pcall(function()
		if isAttribute then
			target:SetAttribute(prop, value)
		else
			target[prop] = value
		end
	end)
	if not okWrite then
		warn("[check_q257] could not inject " .. tostring(prop) .. ": " .. tostring(why))
	end
	return okWrite
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		pcall(function()
			if entry.isAttribute then
				entry.target:SetAttribute(entry.prop, entry.value)
			else
				entry.target[entry.prop] = entry.value
			end
		end)
		injected[index] = nil
	end
end

-- Every value below comes from the live DataModel; Data only supplies declared key names.
local function measure()
	local modelParts, groups, plates, readableLabels, readErrors = 0, {}, {}, 0, 0
	local validKeys, stagedKeys = {}, {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		readErrors += 1
		descendants = {}
	end
	for _, instance in ipairs(descendants) do
		pcall(function()
			if instance:GetAttribute(STAGE_ATTR) ~= CANDIDATE_ID then
				return
			end
			if instance:IsA("MeshPart") then
				local meshId = instance.MeshId
				if type(meshId) == "string" and meshId == SIGN_MESH_ID then
					modelParts += 1
				end
			end
			if instance:GetAttribute("SignpostPlate") == true then
				local signIndex = instance:GetAttribute("sign")
				if type(signIndex) == "number" then
					groups[signIndex] = (groups[signIndex] or 0) + 1
					plates[#plates + 1] = { instance = instance, sign = signIndex }
				else
					readErrors += 1
				end
			end
			local key = instance:GetAttribute("textKey")
			if type(key) == "string" and key ~= "" then
				stagedKeys[key] = true
				local entry = type(StringsRaw) == "table" and StringsRaw[key] or nil
				if
					type(entry) == "table"
					and type(entry.id) == "string"
					and #entry.id > 0
					and type(entry.en) == "string"
					and #entry.en > 0
				then
					validKeys[key] = true
				end
			end
			if instance:IsA("TextLabel") then
				local okSize, size = pcall(function()
					return instance.TextSize
				end)
				if okSize and type(size) == "number" and size >= Data.READ_MIN_PX then
					readableLabels += 1
				end
			end
		end)
	end
	local maxPlates, signCount, stagedValid = 0, 0, 0
	for _, count in pairs(groups) do
		signCount += 1
		maxPlates = math.max(maxPlates, count)
	end
	for _, key in ipairs(type(Data) == "table" and Data.STRING_KEYS or {}) do
		if validKeys[key] then
			stagedValid += 1
		end
	end
	local stagedKeyCount = 0
	for _ in pairs(stagedKeys) do
		stagedKeyCount += 1
	end
	return {
		modelParts = modelParts,
		maxPlates = maxPlates,
		signCount = signCount,
		validKeys = stagedValid,
		readableLabels = readableLabels,
		stagedKeyCount = stagedKeyCount,
		plates = plates,
		readErrors = readErrors,
	}
end

local function stagedPostMeshes()
	local found = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return found
	end
	for _, instance in ipairs(descendants) do
		local okMatch, matched = pcall(function()
			return instance:IsA("MeshPart")
				and instance.MeshId == SIGN_MESH_ID
				and instance:GetAttribute(STAGE_ATTR) == CANDIDATE_ID
		end)
		if okMatch and matched then
			found[#found + 1] = instance
		end
	end
	return found
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapSignpostsR10"))
	StringsRaw = require(shared:WaitForChild("Strings")).raw

	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview API missing")
	end
	if type(Data) ~= "table" or type(Data.STRING_KEYS) ~= "table" or #Data.STRING_KEYS ~= 6 then
		error("ModelMapSignpostsR10 API missing")
	end
	if type(Data.READ_MIN_PX) ~= "number" then
		error("ModelMapSignpostsR10.READ_MIN_PX missing")
	end
	if type(StringsRaw) ~= "table" then
		error("Shared.Strings.raw missing")
	end
	targets.STRINGS_PARITY = #Data.STRING_KEYS

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local stageReason = nil
	if not enableOk or not enabled then
		stageReason = "enableAdditive failed: " .. tostring(why)
	end
	local ready = stageReason == nil

	local live = measure()
	local signsExpected = #Data.SIGNS
	emit(
		"MODEL_USED",
		ready and live.modelParts >= MODEL_TARGET and live.readErrors == 0,
		live.modelParts,
		MODEL_TARGET,
		{
			meshId = SIGN_MESH_ID,
			stage = CANDIDATE_ID,
			readErrors = live.readErrors,
			reason = stageReason,
		}
	)
	emit(
		"SIGN_PLATES",
		ready and live.signCount == signsExpected and live.maxPlates >= PLATE_TARGET,
		live.maxPlates,
		PLATE_TARGET,
		{
			signs = live.signCount,
			expectedSigns = signsExpected,
			readableLabels = live.readableLabels,
			readErrors = live.readErrors,
			reason = stageReason,
		}
	)
	emit(
		"STRINGS_PARITY",
		ready and live.validKeys == #Data.STRING_KEYS and live.stagedKeyCount == #Data.STRING_KEYS,
		live.validKeys,
		#Data.STRING_KEYS,
		{
			stagedKeys = live.stagedKeyCount,
			keys = Data.STRING_KEYS,
			reason = stageReason,
		}
	)

	-- CALIBRATION ANCHOR (MODEL_USED FAIL): strip the staging tag from every restyled post so no
	-- staged MeshPart carries the sign mesh id; the measured count must fall below MODEL_TARGET.
	local meshVictims, meshInjected = stagedPostMeshes(), 0
	for _, mesh in ipairs(meshVictims) do
		if recordSet(mesh, STAGE_ATTR, nil, true) then
			meshInjected += 1
		end
	end
	local calMesh = measure()
	local meshFailed = meshInjected > 0 and calMesh.modelParts < MODEL_TARGET
	emit("CAL_MODEL_USED_FAIL", meshFailed, meshFailed and 1 or 0, 1, {
		injected = meshInjected,
		meshPartsBefore = live.modelParts,
		meshPartsAfter = calMesh.modelParts,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (SIGN_PLATES FAIL): unflag every staged plate on every sign so the
	-- maximum plates on any one sign necessarily falls below PLATE_TARGET.
	local plateInjected = 0
	for _, entry in ipairs(live.plates) do
		if recordSet(entry.instance, "SignpostPlate", false, true) then
			plateInjected += 1
		end
	end
	local calPlates = measure()
	local plateFailed = plateInjected > 0 and calPlates.maxPlates < PLATE_TARGET
	emit("CAL_SIGN_PLATES_FAIL", plateFailed, plateFailed and 1 or 0, 1, {
		injected = plateInjected,
		platesBefore = live.maxPlates,
		platesAfter = calPlates.maxPlates,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (STRINGS_PARITY FAIL): blank one live plate key.
	local firstKey = Data.STRING_KEYS[1]
	local keyInjected = recordSet(StringsRaw, firstKey, { id = "", en = "" }, false)
	local calKeys = measure()
	local keyFailed = calKeys.validKeys < #Data.STRING_KEYS
	emit("CAL_STRINGS_PARITY_FAIL", keyFailed, keyFailed and 1 or 0, 1, {
		injected = keyInjected,
		key = firstKey,
		validBefore = live.validKeys,
		validAfter = calKeys.validKeys,
	})
	restoreInjected()
end)

-- Restore injected properties and every staged candidate on every path.
restoreInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 257 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, targets[name], reason)
	end
end

printSummary()

return results
