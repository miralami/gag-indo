--!nocheck
-- check_q202: WORK_QUEUE item 202, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live place BEFORE and AFTER staging
-- lamps_r10 with enableAdditive, exercises the night-only light rule at ClockTime 21 and 13,
-- prints verbatim CHECK lines, then restores with disableAll() and restores ClockTime in the
-- same call. No harness require, no place save, no visual verdict.
--
--   LAMPS             >=12 distinct StreetLamp groups in the live workspace after staging
--   LIGHT_COST        0 live PointLights with Range > ModelMapLampsR10.LIGHT_RANGE (16)
--   LAMP_NIGHT_ONLY   >=12 staged lights Enabled at ClockTime 21, 0 Enabled at ClockTime 13
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

local CHECK_NAMES = { "LAMPS", "LIGHT_COST", "LAMP_NIGHT_ONLY" }
local CANDIDATE_ID = "lamps_r10"

local review, Data, Failures = nil, nil, nil
local originalClock = nil

local function setClock(clock)
	return pcall(function()
		game:GetService("Lighting").ClockTime = clock
	end)
end

local function readClock()
	local ok, clock = pcall(function()
		return game:GetService("Lighting").ClockTime
	end)
	if ok and type(clock) == "number" then
		return clock
	end
	return nil
end

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local seen, groups = {}, 0
	local violations, enabled, lightCount = 0, 0, 0

	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			local okTag, tagged = pcall(function()
				return instance:GetAttribute("StreetLamp") == true
			end)
			if okTag and tagged then
				local okIndex, index = pcall(function()
					return instance:GetAttribute("lamp")
				end)
				local key = "lamp:" .. tostring(index)
				if not seen[key] then
					seen[key] = true
					groups += 1
				end
			end

			local okLight, isLight = pcall(function()
				return instance:IsA("PointLight")
			end)
			if okLight and isLight then
				lightCount += 1
				local okRange, range = pcall(function()
					return instance.Range
				end)
				if okRange and type(range) == "number" and range > (Data and Data.LIGHT_RANGE or 16) then
					violations += 1
				end
				local okParent, parent = pcall(function()
					return instance.Parent
				end)
				local okStaged, staged = pcall(function()
					return parent ~= nil and parent:GetAttribute("StreetLamp") == true
				end)
				if okStaged and staged then
					local okEnabled, value = pcall(function()
						return instance.Enabled
					end)
					if okEnabled and value == true then
						enabled += 1
					end
				end
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
		groups = groups,
		violations = violations,
		enabled = enabled,
		lightCount = lightCount,
		loadFailures = loadFailures,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapLampsR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))

	if type(Data) ~= "table" or type(Data.lamps) ~= "function" then
		error("ModelMapLampsR10 API missing")
	end
	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview API missing")
	end

	originalClock = readClock()

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local okNightClock = setClock(21)
	local nightEnableOk, nightEnabled, nightWhy = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not okNightClock then
		enableReason = "could not set ClockTime 21"
	elseif not nightEnableOk or not nightEnabled then
		enableReason = "enableAdditive failed: " .. tostring(nightWhy)
	end

	-- CALIBRATION ANCHOR (AFTER). Measured on the live staged place at ClockTime 21.
	local after = measure()
	local nightOn = after.enabled

	pcall(review.disableAll)
	setClock(13)
	local dayEnableOk, dayEnabled, dayWhy = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local day = measure()
	local dayOn = day.enabled
	if not dayEnableOk or not dayEnabled then
		enableReason = (enableReason and enableReason .. "; " or "") .. "day restage failed: " .. tostring(dayWhy)
	end

	emit("LAMPS", after.groups >= 12, after.groups, 12, {
		beforeGroups = before.groups,
		afterGroups = after.groups,
		loadFailures = after.loadFailures,
		reason = enableReason,
	})
	emit("LIGHT_COST", after.violations == 0, after.violations, "0 violations", {
		beforeViolations = before.violations,
		afterViolations = after.violations,
		totalLights = after.lightCount,
		lightRange = Data.LIGHT_RANGE,
		reason = enableReason,
	})
	emit("LAMP_NIGHT_ONLY", nightOn >= 12 and dayOn == 0, nightOn, 12, {
		nightClock = 21,
		dayClock = 13,
		nightOn = nightOn,
		dayOn = dayOn,
		beforeEnabled = before.enabled,
		reason = enableReason,
	})

	pcall(review.disableAll())
end)

-- Restore every additively staged candidate and the clock, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
if originalClock ~= nil then
	setClock(originalClock)
end

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "LAMPS" then 12 elseif name == "LIGHT_COST" then "0 violations" else 12
		emitOnce(name, false, 0, target, reason)
	end
end

return results
