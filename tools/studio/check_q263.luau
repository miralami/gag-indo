--!nocheck
-- check_q263: WORK_QUEUE item 263, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY furrows_r10, crop_stages_r10 and
-- ditch_water_r10 via LookDevReview.enableAdditive, measures the live DataModel, prints verbatim
-- CHECK lines plus SUMMARY_Q263, then restores with disableAll() on every path. No harness require,
-- no place save, no visual verdict. Every reading comes from the SERVER DataModel only.
--
--   CROP_STAGE_HEIGHT  staged CropStage parts exist; each plot's bibit/tumbuh/siap heights are
--                      exactly 1.2 / 2.6 / 4.2 and strictly increasing
--   CROP_STAGE_COLOR   every plot's bibit/siap canopy colours are >= 0.15 apart in Data.hueDistance
--   CROP_STAGE_WIDTH   every (plot, stage) cluster's widest live part >= 1.5 studs (30 clusters)
--   FURROW_RELIEF      every live Furrow row's top is >= 0.3 studs above the soil AND CastShadow
--   DITCH_VISIBLE      every live DitchWater strip is >= 2 studs wide and above the soil line
--
-- CALIBRATION ANCHORS (each must FAIL its condition, then restore):
--   CAL_FURROW_RELIEF_FAIL  inject one flat Furrow-tagged row -> min relief drops below 0.3
--   CAL_DITCH_VISIBLE_FAIL  inject one 1-stud DitchWater-tagged strip -> min width drops below 2
-- Injections are destroyed immediately after their anchor line; the measure() calls are separate
-- single lines so a mismatch can be injected between them.

local CANDIDATE_IDS = { "furrows_r10", "crop_stages_r10", "ditch_water_r10" }

local CHECK_NAMES = {
	"CROP_STAGE_HEIGHT",
	"CROP_STAGE_COLOR",
	"CROP_STAGE_WIDTH",
	"FURROW_RELIEF",
	"DITCH_VISIBLE",
	"CAL_FURROW_RELIEF_FAIL",
	"CAL_DITCH_VISIBLE_FAIL",
}
local CHECK_TARGETS = {
	CROP_STAGE_HEIGHT = 0,
	CROP_STAGE_COLOR = 0,
	CROP_STAGE_WIDTH = "1.5",
	FURROW_RELIEF = "0.3",
	DITCH_VISIBLE = "2/0.5",
	CAL_FURROW_RELIEF_FAIL = 1,
	CAL_DITCH_VISIBLE_FAIL = 1,
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

local review, CropData, FurrowData, DitchData, Workspace = nil, nil, nil, nil, nil
local injected = {}
local reason = nil

local function colourDistance(first, second)
	return CropData.hueDistance({ r = first.R * 255, g = first.G * 255, b = first.B * 255 }, {
		r = second.R * 255,
		g = second.G * 255,
		b = second.B * 255,
	})
end

-- Every reading comes from live workspace descendants carrying the candidate's own tag attribute.
local function measure()
	local stages = {}
	for _, stage in ipairs(CropData.STAGES) do
		stages[#stages + 1] = stage.stage
	end
	local expectedHeights = {}
	for _, stage in ipairs(CropData.STAGES) do
		expectedHeights[stage.stage] = stage.height
	end

	local heights, canopies, widths, furrowPlots, ditchPlots = {}, {}, {}, {}, {}
	local cropParts, modelParts, furrowParts, ditchParts = 0, 0, 0, 0
	local shadowViolations, belowSoil = 0, 0
	local minWidth, minRelief, minDitchWidth, minDitchY = math.huge, math.huge, math.huge, math.huge
	local errors = 0

	local okDescendants, descendants = pcall(function()
		return Workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		descendants, errors = {}, errors + 1
	end

	for _, instance in ipairs(descendants) do
		pcall(function()
			local isCrop = instance:GetAttribute("CropStage") == true
			local isFurrow = instance:GetAttribute("Furrow") == true
			local isDitch = instance:GetAttribute("DitchWater") == true
			if not (isCrop or isFurrow or isDitch) or not instance:IsA("BasePart") then
				return
			end
			local position, size = instance.Position, instance.Size
			if not position or not size then
				errors += 1
				return
			end

			if isCrop then
				cropParts += 1
				local stage = instance:GetAttribute("stage")
				local height = instance:GetAttribute("height")
				local role = instance:GetAttribute("CropStageRole")
				local plot = instance:GetAttribute("plot")
				local color = instance.Color
				local valid = false
				for _, name in ipairs(stages) do
					if name == stage then
						valid = true
					end
				end
				if not valid or type(height) ~= "number" or type(plot) ~= "number" or not color then
					errors += 1
				else
					heights[plot] = heights[plot] or {}
					heights[plot][stage] = height
					if role == "canopy" then
						canopies[plot] = canopies[plot] or {}
						canopies[plot][stage] = color
					end
					if role == "model" and instance:GetAttribute("ModelAssetId") == 13286158859 then
						modelParts += 1
					end
					local key = tostring(plot) .. ":" .. tostring(stage)
					local width = math.max(size.X, size.Z)
					if width > (widths[key] or 0) then
						widths[key] = width
					end
				end
			end

			if isFurrow then
				furrowParts += 1
				local plot = instance:GetAttribute("plot")
				if type(plot) == "number" then
					furrowPlots[plot] = (furrowPlots[plot] or 0) + 1
				end
				local relief = position.Y + size.Y / 2 - FurrowData.GROUND_Y
				if relief < minRelief then
					minRelief = relief
				end
				if instance.CastShadow ~= true then
					shadowViolations += 1
				end
			end

			if isDitch then
				ditchParts += 1
				local plot = instance:GetAttribute("plot")
				if type(plot) == "number" then
					ditchPlots[plot] = (ditchPlots[plot] or 0) + 1
				end
				if size.Z < minDitchWidth then
					minDitchWidth = size.Z
				end
				if position.Y < minDitchY then
					minDitchY = position.Y
				end
				if position.Y <= DitchData.SOIL_Y then
					belowSoil += 1
				end
			end
		end)
	end

	local heightViolations, plotCount = 0, 0
	for _, byStage in pairs(heights) do
		plotCount += 1
		local first, second, third = byStage[stages[1]], byStage[stages[2]], byStage[stages[3]]
		local correct = type(first) == "number"
			and type(second) == "number"
			and type(third) == "number"
			and first < second
			and second < third
			and math.abs(first - expectedHeights[stages[1]]) < 1e-6
			and math.abs(second - expectedHeights[stages[2]]) < 1e-6
			and math.abs(third - expectedHeights[stages[3]]) < 1e-6
		if not correct then
			heightViolations += 1
		end
	end

	local colorViolations, colorPlots = 0, 0
	for _, byStage in pairs(canopies) do
		colorPlots += 1
		local first, third = byStage[stages[1]], byStage[stages[3]]
		local okDistance, distance = pcall(colourDistance, first, third)
		if not okDistance or type(distance) ~= "number" or distance < CropData.MIN_HUE_DISTANCE then
			colorViolations += 1
		end
	end

	local clusterCount = 0
	for _, width in pairs(widths) do
		clusterCount += 1
		if width < minWidth then
			minWidth = width
		end
	end
	if clusterCount == 0 then
		minWidth = 0
	end

	local furrowPlotCount = 0
	for _ in pairs(furrowPlots) do
		furrowPlotCount += 1
	end
	local ditchPlotCount = 0
	for _ in pairs(ditchPlots) do
		ditchPlotCount += 1
	end
	if furrowParts == 0 then
		minRelief = 0
	end
	if ditchParts == 0 then
		minDitchWidth, minDitchY = 0, 0
	end

	return {
		cropParts = cropParts,
		modelParts = modelParts,
		heightViolations = heightViolations,
		plotCount = plotCount,
		colorViolations = colorViolations,
		colorPlots = colorPlots,
		minWidth = minWidth,
		clusterCount = clusterCount,
		furrowParts = furrowParts,
		furrowPlotCount = furrowPlotCount,
		minRelief = minRelief,
		shadowViolations = shadowViolations,
		ditchParts = ditchParts,
		ditchPlotCount = ditchPlotCount,
		minDitchWidth = minDitchWidth,
		minDitchY = minDitchY,
		belowSoil = belowSoil,
		errors = errors,
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

local function injectPart(name, size, y, attrs)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(size[1], size[2], size[3])
	part.CFrame = CFrame.new(0, y, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = true
	for key, value in pairs(attrs) do
		part:SetAttribute(key, value)
	end
	part.Parent = Workspace
	injected[#injected + 1] = part
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	CropData = require(shared:WaitForChild("ModelMapCropStagesR10"))
	FurrowData = require(shared:WaitForChild("ModelMapFurrowsR10"))
	DitchData = require(shared:WaitForChild("ModelMapDitchWaterR10"))
	Workspace = game:GetService("Workspace")

	if
		type(CropData) ~= "table"
		or type(CropData.hueDistance) ~= "function"
		or type(FurrowData) ~= "table"
		or type(DitchData) ~= "table"
	then
		error("item 263 pure-data API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE): a mismatch can be injected between the two measure calls.
	local before = measure()

	for _, id in ipairs(CANDIDATE_IDS) do
		local enableOk, enabled, why = pcall(review.enableAdditive, id, game)
		if not enableOk or not enabled then
			reason = (reason and reason .. "; " or "") .. id .. ": " .. tostring(why or enabled)
		end
	end

	-- CALIBRATION ANCHOR (AFTER).
	local after = measure()
	local details = { before = before, after = after, reason = reason }

	local heightPass = reason == nil
		and after.errors == 0
		and after.cropParts > 0
		and after.plotCount == FurrowData.PLOT_COUNT
		and after.heightViolations == 0
	emit("CROP_STAGE_HEIGHT", heightPass, after.heightViolations, 0, details)

	local colorPass = reason == nil
		and after.errors == 0
		and after.cropParts > 0
		and after.colorPlots == FurrowData.PLOT_COUNT
		and after.colorViolations == 0
	emit("CROP_STAGE_COLOR", colorPass, after.colorViolations, 0, details)

	local expectedClusters = FurrowData.PLOT_COUNT * #CropData.STAGES
	local widthPass = reason == nil
		and after.errors == 0
		and after.cropParts > 0
		and after.clusterCount == expectedClusters
		and after.minWidth >= CropData.MIN_STAGE_WIDTH
	emit("CROP_STAGE_WIDTH", widthPass, string.format("%.2f", after.minWidth), "1.5", {
		after = after,
		expectedClusters = expectedClusters,
		modelParts = after.modelParts, -- logged, not gated: no MODEL_USED name in item 263
		reason = reason,
	})

	local reliefPass = reason == nil
		and after.errors == 0
		and after.furrowParts > 0
		and after.furrowPlotCount == FurrowData.PLOT_COUNT
		and after.minRelief >= FurrowData.MIN_RELIEF
		and after.shadowViolations == 0
	emit("FURROW_RELIEF", reliefPass, string.format("%.2f", after.minRelief), "0.3", {
		after = after,
		soilY = FurrowData.GROUND_Y,
		minRelief = FurrowData.MIN_RELIEF,
		reason = reason,
	})

	local ditchPass = reason == nil
		and after.errors == 0
		and after.ditchParts > 0
		and after.ditchPlotCount == DitchData.PLOT_COUNT
		and after.minDitchWidth >= DitchData.MIN_WATER_WIDTH
		and after.belowSoil == 0
	emit(
		"DITCH_VISIBLE",
		ditchPass,
		string.format("%.2f/%.2f", after.minDitchWidth, after.minDitchY),
		"2/0.5",
		{ after = after, minWidth = DitchData.MIN_WATER_WIDTH, soilY = DitchData.SOIL_Y, reason = reason }
	)

	-- CALIBRATION ANCHOR (FURROW_RELIEF FAIL): one flat shadow-casting row drops the minimum.
	injectPart(
		"Q263_FURROW_RELIEF_CALIBRATION",
		{ FurrowData.STRIP_WIDTH, 0.1, FurrowData.STRIP_LENGTH },
		FurrowData.GROUND_Y + 0.05,
		{ Furrow = true, plot = 9999, LookDevStage = "furrows_r10" }
	)
	local calFurrow = measure()
	local reliefFailed = calFurrow.minRelief < FurrowData.MIN_RELIEF
	emit("CAL_FURROW_RELIEF_FAIL", reliefFailed, reliefFailed and 1 or 0, 1, {
		minRelief = string.format("%.2f", calFurrow.minRelief),
		furrowParts = calFurrow.furrowParts,
		injectedParts = #injected,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (DITCH_VISIBLE FAIL): one 1-stud water strip drops the minimum width.
	injectPart(
		"Q263_DITCH_VISIBLE_CALIBRATION",
		{ 8, DitchData.STRIP_THICKNESS, DitchData.MIN_WATER_WIDTH - 1 },
		DitchData.WATER_Y,
		{ DitchWater = true, plot = 9998, LookDevStage = "ditch_water_r10" }
	)
	local calDitch = measure()
	local ditchFailed = calDitch.minDitchWidth < DitchData.MIN_WATER_WIDTH
	emit("CAL_DITCH_VISIBLE_FAIL", ditchFailed, ditchFailed and 1 or 0, 1, {
		minDitchWidth = string.format("%.2f", calDitch.minDitchWidth),
		ditchParts = calDitch.ditchParts,
		injectedParts = #injected,
	})
end)

-- Restore every staged candidate and every injection, even when a measurement threw.
destroyInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local auditReason = { reason = "item 263 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], auditReason)
	end
end

local checkPass, checkTotal, calPass, calTotal = 0, 0, 0, 0
for _, name in ipairs(CHECK_NAMES) do
	local entry = results.byName[name]
	if string.sub(name, 1, 4) == "CAL_" then
		calTotal += 1
		if entry and entry.passed then
			calPass += 1
		end
	else
		checkTotal += 1
		if entry and entry.passed then
			checkPass += 1
		end
	end
end
print(string.format("SUMMARY_Q263 CHECKS %d/%d CAL %d/%d", checkPass, checkTotal, calPass, calTotal))

return results
