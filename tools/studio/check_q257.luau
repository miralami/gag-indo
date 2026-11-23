--!nocheck
-- check_q257: WORK_QUEUE item 257, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. Stages ONLY signposts_r10 with LookDevReview, measures
-- the live DataModel, prints verbatim CHECK lines and SUMMARY_Q257, then restores on every path.
--
--   SIGN_PLATES   max staged plates on one sign >= 5, and 4 signs
--   PLATE_TEXT    every staged plate has a SurfaceGui TextLabel with non-empty text (all >= 5 per sign)
--   POLE_COLOR    every staged steel pole is green (g clearly above r and b), square, not Wood
--
-- CALIBRATION ANCHORS (each forces a FAIL the same measure must catch, then restores LIFO):
--   CAL_SIGN_PLATES_FAIL  unflag every staged plate, on every sign
--   CAL_PLATE_TEXT_FAIL   blank every staged plate label text
--   CAL_POLE_COLOR_FAIL   repaint every staged pole red

local CANDIDATE_ID = "signposts_r10"
local STAGE_ATTR = "LookDevStage"
local PLATE_TARGET = 5

local CHECK_NAMES = {
	"SIGN_PLATES",
	"PLATE_TEXT",
	"POLE_COLOR",
	"CAL_SIGN_PLATES_FAIL",
	"CAL_PLATE_TEXT_FAIL",
	"CAL_POLE_COLOR_FAIL",
}
local targets = {
	SIGN_PLATES = PLATE_TARGET,
	PLATE_TEXT = PLATE_TARGET,
	POLE_COLOR = 4,
	CAL_SIGN_PLATES_FAIL = 1,
	CAL_PLATE_TEXT_FAIL = 1,
	CAL_POLE_COLOR_FAIL = 1,
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

local review, Data
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

local function isGreen(color)
	return color.G > color.R + 0.15 and color.G > color.B + 0.15
end

-- Every value below comes from the live DataModel.
local function measure()
	local groups, plates, poles, labels, textLabels, greenPoles = {}, {}, {}, {}, 0, 0
	local plateTexts, platesWithText, readErrors, woodPoles, nonSquare = 0, 0, 0, 0, 0
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
			if instance:GetAttribute("SignpostPlate") == true and instance:IsA("BasePart") then
				local signIndex = instance:GetAttribute("sign")
				if type(signIndex) == "number" then
					groups[signIndex] = (groups[signIndex] or 0) + 1
					plates[#plates + 1] = instance
					local text = nil
					for _, child in ipairs(instance:GetDescendants()) do
						if child:IsA("TextLabel") then
							text = child
							break
						end
					end
					local hasGui = instance:FindFirstChildWhichIsA("SurfaceGui") ~= nil
					if hasGui and text and type(text.Text) == "string" and #text.Text > 0 then
						platesWithText += 1
					end
				else
					readErrors += 1
				end
			end
			if instance:GetAttribute("SignpostPole") == true and instance:IsA("BasePart") then
				poles[#poles + 1] = instance
				if isGreen(instance.Color) then
					greenPoles += 1
				end
				if instance.Material == Enum.Material.Wood then
					woodPoles += 1
				end
				if math.abs(instance.Size.X - instance.Size.Z) > 0.001 then
					nonSquare += 1
				end
			end
		end)
	end
	local maxPlates, signCount = 0, 0
	for _, count in pairs(groups) do
		signCount += 1
		maxPlates = math.max(maxPlates, count)
	end
	return {
		maxPlates = maxPlates,
		signCount = signCount,
		plates = plates,
		poles = poles,
		platesWithText = platesWithText,
		greenPoles = greenPoles,
		woodPoles = woodPoles,
		nonSquare = nonSquare,
		readErrors = readErrors,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapSignpostsR10"))
	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview API missing")
	end
	if type(Data) ~= "table" or type(Data.SIGNS) ~= "table" then
		error("ModelMapSignpostsR10 API missing")
	end
	local signsExpected = #Data.SIGNS
	local platesExpected = signsExpected * Data.PLATE_COUNT
	targets.PLATE_TEXT = platesExpected
	targets.POLE_COLOR = signsExpected

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local stageReason = nil
	if not enableOk or not enabled then
		stageReason = "enableAdditive failed: " .. tostring(why)
	end
	local ready = stageReason == nil

	local live = measure()
	emit(
		"SIGN_PLATES",
		ready and live.signCount == signsExpected and live.maxPlates >= PLATE_TARGET and live.readErrors == 0,
		live.maxPlates,
		PLATE_TARGET,
		{ signs = live.signCount, expectedSigns = signsExpected, readErrors = live.readErrors, reason = stageReason }
	)
	emit(
		"PLATE_TEXT",
		ready and live.platesWithText == platesExpected and #live.plates == platesExpected,
		live.platesWithText,
		platesExpected,
		{ plates = #live.plates, reason = stageReason }
	)
	emit(
		"POLE_COLOR",
		ready
			and #live.poles == signsExpected
			and live.greenPoles == signsExpected
			and live.woodPoles == 0
			and live.nonSquare == 0,
		live.greenPoles,
		signsExpected,
		{ poles = #live.poles, wood = live.woodPoles, nonSquare = live.nonSquare, reason = stageReason }
	)

	-- CALIBRATION ANCHOR (SIGN_PLATES FAIL): unflag every staged plate.
	local plateInjected = 0
	for _, plate in ipairs(live.plates) do
		if recordSet(plate, "SignpostPlate", false, true) then
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

	-- CALIBRATION ANCHOR (PLATE_TEXT FAIL): blank every plate label.
	local textInjected = 0
	for _, plate in ipairs(live.plates) do
		pcall(function()
			for _, child in ipairs(plate:GetDescendants()) do
				if child:IsA("TextLabel") and recordSet(child, "Text", "", false) then
					textInjected += 1
				end
			end
		end)
	end
	local calText = measure()
	local textFailed = textInjected > 0 and calText.platesWithText < platesExpected
	emit("CAL_PLATE_TEXT_FAIL", textFailed, textFailed and 1 or 0, 1, {
		injected = textInjected,
		withTextBefore = live.platesWithText,
		withTextAfter = calText.platesWithText,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (POLE_COLOR FAIL): repaint every pole red.
	local poleInjected = 0
	for _, pole in ipairs(live.poles) do
		if recordSet(pole, "Color", Color3.fromRGB(200, 40, 40), false) then
			poleInjected += 1
		end
	end
	local calPole = measure()
	local poleFailed = poleInjected > 0 and calPole.greenPoles < signsExpected
	emit("CAL_POLE_COLOR_FAIL", poleFailed, poleFailed and 1 or 0, 1, {
		injected = poleInjected,
		greenBefore = live.greenPoles,
		greenAfter = calPole.greenPoles,
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
