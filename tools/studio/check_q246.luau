--!nocheck
-- check_q246: WORK_QUEUE item 246, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. Reads ClockTime from ReviewCameras.get("lamp_night")
-- (21), stages ONLY lamps_r10 with LookDevReview.enableAdditive, measures the live DataModel,
-- prints verbatim CHECK lines, then restores every injected PointLight property and the clock on
-- every path and calls LookDevReview.disableAll(). No harness require, no place save, no verdict.
--
--   LAMP_POOL                 >=8 of 12 lamps: road point under the light is inside its Range,
--                              both neighbouring midpoints are outside it
--   LIGHT_COST                0 live PointLights with Range > ModelMapLampsR10.LIGHT_RANGE (16)
--   LAMP_NIGHT_ONLY           12 staged lights Enabled at ClockTime 21, 0 at ClockTime 13
--
-- CALIBRATION ANCHORS (each must FAIL the corresponding condition, then restore):
--   CAL_LIGHT_COST_FAIL       inject one live Range = LIGHT_RANGE + 1 -> violations > 0
--   CAL_LAMP_POOL_FAIL        force every midpoint inside its light Range -> good < 8
--   CAL_LAMP_NIGHT_ONLY_FAIL  at ClockTime 13, force one live light Enabled -> dayOn > 0
-- The measure() calls are separate lines so a before/after mismatch can be injected between them.

local CANDIDATE_ID = "lamps_r10"
local CAMERA_NAME = "lamp_night"
local DAY_CLOCK = 13
local POOL_TARGET = 8

local CHECK_NAMES = {
	"LAMP_POOL",
	"LIGHT_COST",
	"LAMP_NIGHT_ONLY",
	"CAL_LAMP_POOL_FAIL",
	"CAL_LIGHT_COST_FAIL",
	"CAL_LAMP_NIGHT_ONLY_FAIL",
}
local CHECK_TARGETS = {
	LAMP_POOL = POOL_TARGET,
	LIGHT_COST = 0,
	LAMP_NIGHT_ONLY = 12,
	CAL_LAMP_POOL_FAIL = 1,
	CAL_LIGHT_COST_FAIL = 1,
	CAL_LAMP_NIGHT_ONLY_FAIL = 1,
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

local review, Data, Cameras = nil, nil, nil
local originalClock, nightClock = nil, nil
local injected = {}

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

-- Save the exact prior value before every live PointLight mutation; restore LIFO on every path.
local function recordSet(instance, prop, value)
	local okRead, old = pcall(function()
		return instance[prop]
	end)
	if not okRead then
		return false
	end
	injected[#injected + 1] = { instance = instance, prop = prop, value = old }
	local okWrite, why = pcall(function()
		instance[prop] = value
	end)
	if not okWrite then
		warn("[check_q246] could not inject " .. prop .. ": " .. tostring(why))
	end
	return okWrite
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		pcall(function()
			entry.instance[entry.prop] = entry.value
		end)
		injected[index] = nil
	end
end

local function positionOf(instance)
	if not instance then
		return nil
	end
	local ok, point = pcall(function()
		if instance:IsA("BasePart") then
			return instance.Position
		end
		if instance:IsA("Attachment") then
			return instance.WorldPosition
		end
		return nil
	end)
	if ok and point and type(point.X) == "number" and type(point.Y) == "number" and type(point.Z) == "number" then
		return point
	end
	return nil
end

-- Live staged lights, keyed by their tagged lamp index. Everything measured below comes from the
-- DataModel; Data only supplies the target count, ground height and the <=16 range ceiling.
local function stagedLights()
	local found = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return found
	end
	for _, instance in ipairs(descendants) do
		pcall(function()
			if not instance:IsA("PointLight") then
				return
			end
			local parent = instance.Parent
			if parent and parent:GetAttribute("StreetLamp") == true and parent:IsA("BasePart") then
				local index = parent:GetAttribute("lamp")
				if type(index) == "number" then
					found[math.floor(index)] = instance
				end
			end
		end)
	end
	return found
end

local function measure()
	local expected = Data and Data.LAMP_COUNT or 12
	local groundY = Data and Data.GROUND_Y or 0.5
	local ceiling = Data and Data.LIGHT_RANGE or 16

	local seenGroups, found = {}, {}
	local groups, lightCount, stagedCount, violations, enabled = 0, 0, 0, 0, 0
	local readErrors, brightness = 0, nil
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		readErrors += 1
		descendants = {}
	end

	for _, instance in ipairs(descendants) do
		pcall(function()
			if instance:GetAttribute("StreetLamp") == true then
				local index = instance:GetAttribute("lamp")
				if type(index) == "number" then
					local key = math.floor(index)
					if not seenGroups[key] then
						seenGroups[key] = true
						groups += 1
					end
				end
			end
			if instance:IsA("PointLight") then
				lightCount += 1
				local okRange, range = pcall(function()
					return instance.Range
				end)
				if not okRange or type(range) ~= "number" then
					readErrors += 1
				elseif range > ceiling then
					violations += 1
				end
				local parent = instance.Parent
				local okStaged, staged = pcall(function()
					return parent ~= nil and parent:GetAttribute("StreetLamp") == true and parent:IsA("BasePart")
				end)
				if okStaged and staged then
					local index = parent:GetAttribute("lamp")
					if type(index) == "number" then
						local key = math.floor(index)
						if not found[key] then
							stagedCount += 1
						end
						found[key] = instance
						local okEnabled, value = pcall(function()
							return instance.Enabled
						end)
						if okEnabled and value == true then
							enabled += 1
						end
						local okBright, valueBright = pcall(function()
							return instance.Brightness
						end)
						if okBright and brightness == nil then
							brightness = valueBright
						end
					end
				end
			end
		end)
	end

	local good, maxMid, minUnderMargin = 0, 0, math.huge
	local samples = {}
	for index = 1, expected do
		local light = found[index]
		if not light then
			readErrors += 1
		else
			local point = positionOf(light.Parent)
			local okRange, range = pcall(function()
				return light.Range
			end)
			local okEnabled, isOn = pcall(function()
				return light.Enabled
			end)
			local nextLight, prevLight = found[index % expected + 1], found[(index - 2) % expected + 1]
			local nextPoint, prevPoint =
				positionOf(nextLight and nextLight.Parent), positionOf(prevLight and prevLight.Parent)
			if
				not point
				or not nextPoint
				or not prevPoint
				or not okRange
				or not okEnabled
				or type(range) ~= "number"
			then
				readErrors += 1
			else
				local dy = point.Y - groundY
				local underDist = math.abs(dy)
				local function midpointDistance(other)
					local dx = point.X - (point.X + other.X) / 2
					local dz = point.Z - (point.Z + other.Z) / 2
					return math.sqrt(dx * dx + dy * dy + dz * dz)
				end
				local nextDist, prevDist = midpointDistance(nextPoint), midpointDistance(prevPoint)
				maxMid = math.max(maxMid, nextDist, prevDist)
				minUnderMargin = math.min(minUnderMargin, range - underDist)
				local pooled = isOn == true and underDist < range and nextDist > range and prevDist > range
				if pooled then
					good += 1
				end
				samples[#samples + 1] = {
					index = index,
					under = string.format("%.2f", underDist),
					nextMid = string.format("%.2f", nextDist),
					prevMid = string.format("%.2f", prevDist),
					range = range,
					pooled = pooled,
				}
			end
		end
	end

	return {
		groups = groups,
		lightCount = lightCount,
		stagedCount = stagedCount,
		violations = violations,
		enabled = enabled,
		good = good,
		maxMid = maxMid,
		minUnderMargin = minUnderMargin,
		brightness = brightness,
		readErrors = readErrors,
		samples = samples,
		poolValid = stagedCount == expected and groups == expected and readErrors == 0,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapLampsR10"))
	Cameras = require(shared:WaitForChild("ReviewCameras"))

	if type(Data) ~= "table" or type(Data.lamps) ~= "function" then
		error("ModelMapLampsR10 API missing")
	end
	if type(review) ~= "table" or type(review.enableAdditive) ~= "function" then
		error("LookDevReview API missing")
	end
	if type(Cameras) ~= "table" or type(Cameras.get) ~= "function" then
		error("ReviewCameras API missing")
	end

	local camera = Cameras.get(CAMERA_NAME)
	local cameraClock = type(camera) == "table" and camera.clockTime or nil
	if type(cameraClock) ~= "number" then
		error(CAMERA_NAME .. " has no numeric clockTime")
	end
	nightClock = cameraClock
	originalClock = readClock()

	local okNightClock = setClock(nightClock)
	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not okNightClock then
		reason = "could not set ClockTime " .. tostring(nightClock)
	elseif not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local night = measure()

	emit(
		"LAMP_POOL",
		reason == nil and night.poolValid and night.good >= POOL_TARGET,
		night.good .. "/12",
		POOL_TARGET,
		{
			camera = CAMERA_NAME,
			cameraClock = nightClock,
			groups = night.groups,
			lights = night.lightCount,
			stagedLights = night.stagedCount,
			maxMidpointDistance = string.format("%.2f", night.maxMid),
			minUnderMargin = string.format("%.2f", night.minUnderMargin),
			brightness = night.brightness,
			range = Data.LIGHT_RANGE,
			samples = night.samples,
			reason = reason,
		}
	)
	emit("LIGHT_COST", reason == nil and night.violations == 0 and night.lightCount > 0, night.violations, 0, {
		lights = night.lightCount,
		lightRange = Data.LIGHT_RANGE,
		brightness = Data.LIGHT_BRIGHTNESS,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (LIGHT_COST FAIL): one live Range above the ceiling must be counted.
	local costLights = stagedLights()
	local costVictim = costLights[1]
	local costInjected = costVictim ~= nil and recordSet(costVictim, "Range", Data.LIGHT_RANGE + 1)
	local calCost = measure()
	local costFailed = calCost.violations > 0
	emit("CAL_LIGHT_COST_FAIL", costFailed, costFailed and 1 or 0, 1, {
		injected = costInjected,
		injectedRange = Data.LIGHT_RANGE + 1,
		violations = calCost.violations,
		lights = calCost.lightCount,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (LAMP_POOL FAIL): widen every live Range past the measured midpoints.
	local poolRange = math.ceil(night.maxMid + 1)
	local poolLights, poolInjected = stagedLights(), 0
	for _, light in pairs(poolLights) do
		if recordSet(light, "Range", poolRange) then
			poolInjected += 1
		end
	end
	local calPool = measure()
	local poolFailed = calPool.stagedCount == Data.LAMP_COUNT and calPool.good < POOL_TARGET
	emit("CAL_LAMP_POOL_FAIL", poolFailed, poolFailed and 1 or 0, 1, {
		injected = poolInjected,
		injectedRange = poolRange,
		good = calPool.good,
		lights = calPool.lightCount,
		stagedLights = calPool.stagedCount,
		maxMidpointDistance = string.format("%.2f", night.maxMid),
	})
	restoreInjected()

	-- Day leg: re-stage at ClockTime 13 so LAMP_NIGHT_ONLY keeps check_q202's live logic.
	pcall(review.disableAll)
	local okDayClock = setClock(DAY_CLOCK)
	local dayEnableOk, dayEnabled, dayWhy = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local day = measure()
	local nightOn, dayOn = night.enabled, day.enabled
	local dayStaged = dayEnableOk and dayEnabled and day.stagedCount == Data.LAMP_COUNT
	emit(
		"LAMP_NIGHT_ONLY",
		reason == nil and okDayClock and dayStaged and nightOn >= Data.LAMP_COUNT and dayOn == 0,
		nightOn,
		Data.LAMP_COUNT,
		{
			nightClock = nightClock,
			dayClock = DAY_CLOCK,
			nightOn = nightOn,
			dayOn = dayOn,
			dayLights = day.lightCount,
			dayStagedLights = day.stagedCount,
			beforeEnabled = 0,
			dayStageReason = not dayEnableOk and tostring(dayEnabled) or (dayEnabled and nil or tostring(dayWhy)),
			reason = reason,
		}
	)

	-- CALIBRATION ANCHOR (LAMP_NIGHT_ONLY FAIL): a forced-on live light at 13 must be counted.
	local dayLights = stagedLights()
	local dayVictim = dayLights[1]
	local dayInjected = okDayClock and dayVictim ~= nil and recordSet(dayVictim, "Enabled", true)
	local calDay = measure()
	local nightFailed = calDay.enabled > 0
	emit("CAL_LAMP_NIGHT_ONLY_FAIL", nightFailed, nightFailed and 1 or 0, 1, {
		injected = dayInjected,
		clock = DAY_CLOCK,
		enabled = calDay.enabled,
		lights = calDay.lightCount,
	})
	restoreInjected()
end)

-- Restore injected light properties, every staged candidate and the clock on every path.
restoreInjected()
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
	local reason = { reason = "item 246 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
