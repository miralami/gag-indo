--!nocheck
-- check_q247: WORK_QUEUE item 247, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a fresh Play session. Stages crop_stages_r10, sets ClockTime from
-- crop_stages_golden.clockTime (16.5), measures the three stage checks plus SubjectCoverage from the
-- golden camera, proves every check can FAIL by injection, then restores with disableAll().
--
--   CROP_STAGE_HEIGHT                  staged Parts exist AND 0 violations of bibit < tumbuh < siap
--   CROP_STAGE_COLOR                   staged Parts exist AND 0 siap/bibit canopy pairs closer than 0.15
--   SUBJECT_COVERAGE_CROP_GOLDEN       staged fraction >= 0.2 from crop_stages_golden
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate lines.
--   CAL_CROP_STAGE_HEIGHT_FAIL      lower one siap Part height below tumbuh, re-measure, restore it.
--   CAL_CROP_STAGE_COLOR_FAIL       retint a siap canopy to bibit colour, re-measure, restore it.
--   CAL_SUBJECT_COVERAGE_CROP_GOLDEN_FAIL  measure with horizon_north (wrong camera), target 0.2.

local results = { checks = {}, byName = {} }

local CANDIDATE_ID = "crop_stages_r10"
local CAMERA_NAME = "crop_stages_golden"
local MIN_HUE_DISTANCE = 0.15
local CHECK_NAMES = {
	"CROP_STAGE_HEIGHT",
	"CROP_STAGE_COLOR",
	"SUBJECT_COVERAGE_CROP_GOLDEN",
	"CAL_CROP_STAGE_HEIGHT_FAIL",
	"CAL_CROP_STAGE_COLOR_FAIL",
	"CAL_SUBJECT_COVERAGE_CROP_GOLDEN_FAIL",
}
local CHECK_TARGETS = {
	CROP_STAGE_HEIGHT = 0,
	CROP_STAGE_COLOR = 0,
	SUBJECT_COVERAGE_CROP_GOLDEN = "0.2",
	CAL_CROP_STAGE_HEIGHT_FAIL = 1,
	CAL_CROP_STAGE_COLOR_FAIL = 1,
	CAL_SUBJECT_COVERAGE_CROP_GOLDEN_FAIL = 1,
}

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

local review, Data, savedClock, mutated = nil, nil, nil, {}
local Lighting = nil

local function measure()
	local heights, canopies = {}, {}
	local staged, errors = 0, 0
	local okDescendants, all = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(all) ~= "table" then
		errors += 1
	else
		for _, instance in ipairs(all) do
			local okTag, tagged = pcall(function()
				return instance:GetAttribute("CropStage") == true
			end)
			if okTag and tagged then
				staged += 1
				local okRead, read = pcall(function()
					return {
						stage = instance:GetAttribute("stage"),
						height = instance:GetAttribute("height"),
						role = instance:GetAttribute("CropStageRole"),
						crop = instance:GetAttribute("crop"),
						color = instance.Color,
					}
				end)
				if not okRead or type(read) ~= "table" then
					errors += 1
				elseif type(read.stage) ~= "string" or type(read.height) ~= "number" then
					errors += 1
				else
					local cropKey = read.crop or Data.REFERENCE_CROP
					heights[cropKey] = heights[cropKey] or {}
					heights[cropKey][read.stage] = read.height
					if read.role == "canopy" then
						canopies[cropKey] = canopies[cropKey] or {}
						canopies[cropKey][read.stage] = read.color
					end
				end
			end
		end
	end

	local heightViolations, colorViolations = 0, 0
	for _, stages in pairs(heights) do
		local bibit, tumbuh, siap = stages.bibit, stages.tumbuh, stages.siap
		if
			type(bibit) ~= "number"
			or type(tumbuh) ~= "number"
			or type(siap) ~= "number"
			or not (bibit < tumbuh and tumbuh < siap)
		then
			heightViolations += 1
		end
	end
	for _, stages in pairs(canopies) do
		local bibit, siap = stages.bibit, stages.siap
		if not bibit or not siap then
			colorViolations += 1
		else
			local okDistance, distance = pcall(Data.hueDistance, {
				r = bibit.R * 255,
				g = bibit.G * 255,
				b = bibit.B * 255,
			}, { r = siap.R * 255, g = siap.G * 255, b = siap.B * 255 })
			if not okDistance or type(distance) ~= "number" or distance < MIN_HUE_DISTANCE then
				colorViolations += 1
			end
		end
	end
	return {
		staged = staged,
		errors = errors,
		heightViolations = heightViolations,
		colorViolations = colorViolations,
	}
end

local function restoreMutated()
	for index = #mutated, 1, -1 do
		local entry = mutated[index]
		pcall(function()
			if entry.color then
				entry.part.Color = entry.color
			else
				entry.part:SetAttribute("height", entry.height)
			end
		end)
		mutated[index] = nil
	end
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapCropStagesR10"))
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	if
		type(Data) ~= "table"
		or type(Data.hueDistance) ~= "function"
		or type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
	then
		error("crop stage data / coverage / staging / camera API missing")
	end

	local camera = Cameras.get(CAMERA_NAME)
	if type(camera) ~= "table" or type(camera.clockTime) ~= "number" then
		error("crop_stages_golden clockTime missing")
	end
	Lighting = game:GetService("Lighting")
	local okClock, priorClock = pcall(function()
		return Lighting.ClockTime
	end)
	if okClock then
		savedClock = { value = priorClock }
		pcall(function()
			Lighting.ClockTime = camera.clockTime
		end)
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()
	local staged, why = review.enableAdditive(CANDIDATE_ID, game)
	local after = measure()
	local enabled = staged == true and after.staged > 0

	local heightMeasured = if enabled and after.heightViolations == 0 then 0 else after.heightViolations
	emit("CROP_STAGE_HEIGHT", enabled and after.heightViolations == 0, heightMeasured, 0, {
		beforeViolations = before.heightViolations,
		afterViolations = after.heightViolations,
		beforeStaged = before.staged,
		afterStaged = after.staged,
		readErrors = after.errors,
		reason = why,
	})

	local colorMeasured = if enabled and after.colorViolations == 0 then 0 else after.colorViolations
	emit("CROP_STAGE_COLOR", enabled and after.colorViolations == 0, colorMeasured, 0, {
		beforeViolations = before.colorViolations,
		afterViolations = after.colorViolations,
		minDistance = MIN_HUE_DISTANCE,
		readErrors = after.errors,
		reason = why,
	})

	local measured = coverage.measure(CANDIDATE_ID, CAMERA_NAME)
	emit("SUBJECT_COVERAGE_CROP_GOLDEN", measured.ok == true and measured.fraction >= 0.2, shown(measured.fraction), "0.2", {
		fraction = measured.fraction,
		camera = CAMERA_NAME,
		clockTime = camera.clockTime,
		detail = measured,
		reason = why,
	})

	-- CALIBRATION ANCHOR (HEIGHT FAIL): lower EVERY siap part below tumbuh, then restore all exact values.
	-- measure() groups by crop only, so one mutated part gets masked by a later unmutated sibling.
	local okParts, parts = pcall(function()
		return workspace:GetDescendants()
	end)
	if okParts and type(parts) == "table" then
		local siapParts, tumbuhHeight = {}, nil
		for _, instance in ipairs(parts) do
			local okRead, stage, height = pcall(function()
				return instance:GetAttribute("stage"), instance:GetAttribute("height")
			end)
			if okRead and stage == "tumbuh" and type(height) == "number" and not tumbuhHeight then
				tumbuhHeight = height
			end
			if okRead and stage == "siap" and type(height) == "number" then
				siapParts[#siapParts + 1] = instance
			end
		end
		if #siapParts > 0 and tumbuhHeight then
			local fromHeight = siapParts[1]:GetAttribute("height")
			for _, part in ipairs(siapParts) do
				mutated[#mutated + 1] = { part = part, height = part:GetAttribute("height") }
				part:SetAttribute("height", tumbuhHeight - 0.1)
			end
			local calHeight = measure()
			local failed = calHeight.heightViolations > 0
			emit("CAL_CROP_STAGE_HEIGHT_FAIL", failed, failed and 1 or 0, 1, {
				violations = calHeight.heightViolations,
				mutatedCount = #siapParts,
				fromHeight = fromHeight,
				toHeight = tumbuhHeight - 0.1,
			})
			restoreMutated()
		else
			emit("CAL_CROP_STAGE_HEIGHT_FAIL", false, 0, 1, { reason = "no staged siap/tumbuh pair" })
		end

		-- CALIBRATION ANCHOR (COLOR FAIL): recolour EVERY siap canopy to bibit; one is masked by siblings.
		local siapCanopies, bibitColor = {}, nil
		for _, instance in ipairs(parts) do
			local okRead, stage, role = pcall(function()
				return instance:GetAttribute("stage"), instance:GetAttribute("CropStageRole")
			end)
			if okRead and role == "canopy" then
				if stage == "siap" then
					siapCanopies[#siapCanopies + 1] = instance
				elseif stage == "bibit" and not bibitColor then
					bibitColor = instance.Color
				end
			end
		end
		if #siapCanopies > 0 and bibitColor then
			for _, canopy in ipairs(siapCanopies) do
				mutated[#mutated + 1] = { part = canopy, color = canopy.Color }
				canopy.Color = bibitColor
			end
			local calColor = measure()
			local failed = calColor.colorViolations > 0
			emit("CAL_CROP_STAGE_COLOR_FAIL", failed, failed and 1 or 0, 1, {
				violations = calColor.colorViolations,
				mutatedCount = #siapCanopies,
				minDistance = MIN_HUE_DISTANCE,
			})
			restoreMutated()
		else
			emit("CAL_CROP_STAGE_COLOR_FAIL", false, 0, 1, { reason = "no staged siap/bibit canopy pair" })
		end
	else
		emit("CAL_CROP_STAGE_HEIGHT_FAIL", false, 0, 1, { reason = "workspace read failed" })
		emit("CAL_CROP_STAGE_COLOR_FAIL", false, 0, 1, { reason = "workspace read failed" })
	end

	-- CALIBRATION ANCHOR (COVERAGE FAIL): point away while the candidate is still staged.
	local away = coverage.measure(CANDIDATE_ID, "horizon_north")
	local coverageFailed = not (away.ok == true and away.fraction >= 0.2)
	emit("CAL_SUBJECT_COVERAGE_CROP_GOLDEN_FAIL", coverageFailed, coverageFailed and 1 or 0, 1, {
		camera = "horizon_north",
		fraction = away.fraction,
		reason = away.reason,
	})
end)

pcall(restoreMutated)
pcall(function()
	if review then
		review.disableAll()
	end
end)
if savedClock and Lighting then
	pcall(function()
		Lighting.ClockTime = savedClock.value
	end)
	savedClock = nil
end

if not ok then
	local reason = { reason = "item 247 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
