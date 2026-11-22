--!nocheck
-- check_q207: WORK_QUEUE item 207, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and AFTER
-- staging ditch_water_r10 with enableAdditive, prints verbatim CHECK lines, then restores with
-- disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   DITCH_WATER  >=10 plots with >=1 staged strip tagged DitchWater==true
--   DITCH_COLOR  0 staged Parts whose teal is >COLOR_TOLERANCE per channel from variant A
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them. Delete a plot's strips before AFTER =>
-- DITCH_WATER FAIL. Retint one staged part far from variant A (e.g. 255, 0, 0) => DITCH_COLOR FAIL.

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

local CHECK_NAMES = { "DITCH_WATER", "DITCH_COLOR" }
local CANDIDATE_ID = "ditch_water_r10"

local review, Data, Water, Failures = nil, nil, nil, nil

-- Every reading comes from the live DataModel; the reference teal comes from the pure data module
-- that defines shipping variant A, and the tolerance from the staged candidate's pure data module.
local function measure()
	local plotsWithWater, colorViolations, readErrors, stagedParts = 0, 0, 0, 0
	local perPlot = {}
	local tolerance = 12
	local reference = nil

	if Data then
		tolerance = Data.COLOR_TOLERANCE or tolerance
	end
	if Water then
		local okReference, color = pcall(function()
			return Water.variants.a.values.WaterColor
		end)
		if okReference and type(color) == "table" then
			reference = color
		else
			readErrors += 1
		end
	end

	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		readErrors += 1
	else
		for _, instance in ipairs(descendants) do
			local okBase, isBase = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okBase and isBase then
				local okTag, tagged = pcall(function()
					return instance:GetAttribute("DitchWater") == true
				end)
				if okTag and tagged then
					stagedParts += 1
					local okPlot, plot = pcall(function()
						return instance:GetAttribute("plot")
					end)
					if okPlot and type(plot) == "number" then
						perPlot[plot] = (perPlot[plot] or 0) + 1
					else
						readErrors += 1
					end
					local okColor, color = pcall(function()
						return instance.Color
					end)
					if not okColor or not color or reference == nil then
						readErrors += 1
					else
						local channelByte = {
							math.floor(color.R * 255 + 0.5),
							math.floor(color.G * 255 + 0.5),
							math.floor(color.B * 255 + 0.5),
						}
						local sourceByte = { reference.r, reference.g, reference.b }
						for index = 1, 3 do
							if math.abs(channelByte[index] - sourceByte[index]) > tolerance then
								colorViolations += 1
								break
							end
						end
					end
				end
			end
		end
	end

	for _, count in pairs(perPlot) do
		if count >= 1 then
			plotsWithWater += 1
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
		plotsWithWater = plotsWithWater,
		colorViolations = colorViolations,
		stagedParts = stagedParts,
		readErrors = readErrors,
		loadFailures = loadFailures,
		tolerance = tolerance,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapDitchWaterR10"))
	Water = require(shared:WaitForChild("ModelMapWaterR8"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" or type(Data.PLOT_COUNT) ~= "number" then
		error("ModelMapDitchWaterR10 API missing")
	end
	if type(Water) ~= "table" or not Water.variants or not Water.variants.a then
		error("ModelMapWaterR8 variant A missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	local waterDetail = {
		["before.plotsWithWater"] = before.plotsWithWater,
		afterPlotsWithWater = after.plotsWithWater,
		afterStagedParts = after.stagedParts,
		expectedPlots = Data.PLOT_COUNT,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit("DITCH_WATER", after.plotsWithWater >= Data.PLOT_COUNT, after.plotsWithWater, Data.PLOT_COUNT, waterDetail)

	local colorDetail = {
		["before.colorViolations"] = before.colorViolations,
		afterColorViolations = after.colorViolations,
		reference = "ModelMapWaterR8.variants.a.values.WaterColor",
		tolerance = after.tolerance,
		readErrors = after.readErrors,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	local colorPass = after.colorViolations == 0 and after.readErrors == 0 and after.stagedParts > 0
	emit("DITCH_COLOR", colorPass, after.colorViolations, 0, colorDetail)
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
		local target = if name == "DITCH_WATER" then 10 else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
