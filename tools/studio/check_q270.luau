--!nocheck
-- check_q270: WORK_QUEUE item 270, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a FRESH Play session. Stages ONLY lamps_r10, reads the live DataModel, prints
-- verbatim CHECK lines plus SUMMARY_Q270, proves every check can FAIL by injection, then restores
-- every injected property and calls LookDevReview.disableAll() on every path. No harness require,
-- no place save/publish, no HttpService and no visual verdict.
--
--   LAMP_NIGHT_ONLY  staged lights on at ClockTime >=20 and <=5, off at 19.9 / 13 / 5.1
--   LIGHT_COST       <=12 PointLights under the staged folder (never above the item-246 target)
--   PORCH_BULBS      >=6 staged role="porchBulb" bulbs at data-derived house/Warung/Ronda anchors
--   THICK_POLES      0..4 role="junctionPole" parts, each >=0.6 studs wide with a lamp head above
--   MODEL_USED       every junction pole owns a script-free baked model part (asset 13869743481)
--   NO_SCRIPTS       0 BaseScript instances under the staged folder
--
-- CALIBRATION ANCHORS (each forces a FAIL the same measure must catch, then restores LIFO):
--   CAL_LAMP_NIGHT_FAIL      force one light on at ClockTime 13 -> dayOn > 0
--   CAL_LIGHT_COST_FAIL      add four live PointLights under the staged folder -> over budget
--   CAL_PORCH_BULBS_FAIL     clear role="porchBulb" on every staged bulb -> anchored drops
--   CAL_THICK_POLES_FAIL     shrink every staged pole below MIN_POLE_WIDTH -> violations > 0
--   CAL_MODEL_USED_FAIL      clear the baked-model marker on every staged model part -> 0 groups
--   CAL_NO_SCRIPTS_FAIL      add one empty Script under the staged folder -> scripts > 0

local CANDIDATE_ID = "lamps_r10"
local CAMERA_NAME = "lamp_night"
local NIGHT_FALLBACK = 21
local DAY_CLOCK = 13
local ANCHOR_TOLERANCE = 0.5
local MODEL_ASSET_ID = 13869743481

local CHECK_NAMES = {
	"LAMP_NIGHT_ONLY",
	"LIGHT_COST",
	"PORCH_BULBS",
	"THICK_POLES",
	"MODEL_USED",
	"NO_SCRIPTS",
	"CAL_LAMP_NIGHT_FAIL",
	"CAL_LIGHT_COST_FAIL",
	"CAL_PORCH_BULBS_FAIL",
	"CAL_THICK_POLES_FAIL",
	"CAL_MODEL_USED_FAIL",
	"CAL_NO_SCRIPTS_FAIL",
}
local CHECK_TARGETS = {
	LAMP_NIGHT_ONLY = 9,
	LIGHT_COST = 12,
	PORCH_BULBS = 6,
	THICK_POLES = 4,
	MODEL_USED = 3,
	NO_SCRIPTS = 0,
	CAL_LAMP_NIGHT_FAIL = 1,
	CAL_LIGHT_COST_FAIL = 1,
	CAL_PORCH_BULBS_FAIL = 1,
	CAL_THICK_POLES_FAIL = 1,
	CAL_MODEL_USED_FAIL = 1,
	CAL_NO_SCRIPTS_FAIL = 1,
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

local review, Data, applier, Lighting = nil, nil, nil, nil
local originalClock = nil
local injected = {}

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function setClock(clock)
	local ok, why = pcall(function()
		Lighting.ClockTime = clock
	end)
	return ok, why
end

local function applierClock(clock)
	if type(applier) ~= "table" or type(applier.setClockTime) ~= "function" then
		return false
	end
	local ok, why = pcall(applier.setClockTime, clock)
	if not ok then
		warn("[check_q270] setClockTime failed: " .. tostring(why))
	end
	return ok
end

local function stageRoot()
	if not Data or type(Data.folderName) ~= "string" then
		return nil
	end
	local ok, root = pcall(function()
		return workspace:FindFirstChild(Data.folderName)
	end)
	return ok and root or nil
end

-- Record the exact prior value before every live mutation so every forced FAIL is undone LIFO.
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
		warn("[check_q270] could not inject " .. prop .. ": " .. tostring(why))
	end
	return okWrite
end

local function recordDestroy(instance)
	injected[#injected + 1] = { destroy = instance }
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		pcall(function()
			if entry.destroy then
				entry.destroy:Destroy()
			elseif entry.isAttribute then
				entry.target:SetAttribute(entry.prop, entry.value)
			else
				entry.target[entry.prop] = entry.value
			end
		end)
		injected[index] = nil
	end
end

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

-- Everything below is measured from the live DataModel. Data supplies only the expected anchors,
-- attribute names, night gate and cost ceilings; no number here is a hardcoded world coordinate.
local function measure()
	local root = stageRoot()
	local bulbs, poles, heads, modelParts, scripts, stagedLights = {}, {}, {}, {}, {}, {}
	local allLights, enabled, rangeViolations, readErrors = 0, 0, 0, 0

	for _, instance in ipairs(descendants()) do
		pcall(function()
			local inStage = false
			if root then
				inStage = instance:IsDescendantOf(root)
			end
			if instance:IsA("PointLight") then
				allLights += 1
				if inStage then
					stagedLights[#stagedLights + 1] = instance
					if instance.Enabled == true then
						enabled += 1
					end
					if type(instance.Range) == "number" and instance.Range > Data.LIGHT_RANGE + 1e-6 then
						rangeViolations += 1
					end
				end
			end
			if instance:IsA("BasePart") then
				local role = attr(instance, Data.roleAttribute)
				if role == Data.porchRole then
					bulbs[#bulbs + 1] = instance
				elseif role == Data.poleRole then
					poles[#poles + 1] = instance
				elseif role == Data.headRole then
					heads[#heads + 1] = instance
				end
			end
			if attr(instance, Data.modelAttribute) == MODEL_ASSET_ID then
				modelParts[#modelParts + 1] = instance
			end
			if inStage and instance:IsA("BaseScript") then
				scripts[#scripts + 1] = instance.Name
			end
		end)
	end

	local expectedBulbs = Data.porchBulbs()
	local used, anchored, bulbLights = {}, 0, 0
	for _, bulb in ipairs(bulbs) do
		pcall(function()
			for index, expected in ipairs(expectedBulbs) do
				if not used[index] and attr(bulb, Data.anchorAttribute) == expected.anchor then
					local dx = bulb.Position.X - expected.position.x
					local dy = bulb.Position.Y - expected.position.y
					local dz = bulb.Position.Z - expected.position.z
					if math.sqrt(dx * dx + dy * dy + dz * dz) <= ANCHOR_TOLERANCE then
						used[index] = true
						anchored += 1
						break
					end
				end
			end
			for _, child in ipairs(bulb:GetChildren()) do
				if child:IsA("PointLight") then
					bulbLights += 1
					break
				end
			end
		end)
	end

	local widthViolations, headViolations = 0, 0
	for _, pole in ipairs(poles) do
		pcall(function()
			local size = pole.Size
			if size.X + 1e-6 < Data.MIN_POLE_WIDTH or size.Z + 1e-6 < Data.MIN_POLE_WIDTH then
				widthViolations += 1
			end
			local hasHead = false
			for _, head in ipairs(heads) do
				local dx = head.Position.X - pole.Position.X
				local dz = head.Position.Z - pole.Position.Z
				local above = head.Position.Y > pole.Position.Y + size.Y / 2
				local close = math.sqrt(dx * dx + dz * dz) < size.X + head.Size.X
				if above and close then
					hasHead = true
					break
				end
			end
			if not hasHead then
				headViolations += 1
			end
		end)
	end

	local modelIndices = {}
	for _, part in ipairs(modelParts) do
		local index = attr(part, Data.indexAttribute)
		if type(index) == "number" then
			modelIndices[math.floor(index)] = true
		end
	end
	local modelGroups = 0
	for _ in pairs(modelIndices) do
		modelGroups += 1
	end

	return {
		bulbCount = #bulbs,
		anchored = anchored,
		bulbLights = bulbLights,
		poleCount = #poles,
		widthViolations = widthViolations,
		headViolations = headViolations,
		modelGroups = modelGroups,
		modelParts = #modelParts,
		scripts = scripts,
		stagedLights = #stagedLights,
		allLights = allLights,
		enabled = enabled,
		rangeViolations = rangeViolations,
		readErrors = readErrors,
		lightList = stagedLights,
		bulbList = bulbs,
		poleList = poles,
		modelList = modelParts,
	}
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapLampsR10"))
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	local LookDev = require(shared:WaitForChild("LookDev"))
	Lighting = game:GetService("Lighting")

	if
		type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(Data) ~= "table"
		or type(Data.porchBulbs) ~= "function"
		or type(Data.junctionPoles) ~= "function"
		or type(Data.isNight) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
	then
		error("lamps data / staging / camera API missing")
	end

	local server = game:GetService("ServerScriptService"):WaitForChild("Server")
	local okApplier, loaded = pcall(function()
		return require(server:WaitForChild("World"):WaitForChild("LookDevLampsR10"))
	end)
	if okApplier and type(loaded) == "table" and type(loaded.setClockTime) == "function" then
		applier = loaded
		pcall(LookDev.register, CANDIDATE_ID, applier)
	else
		error("LookDevLampsR10.setClockTime missing")
	end

	local camera = Cameras.get(CAMERA_NAME)
	local cameraClock = type(camera) == "table" and camera.clockTime or nil
	if type(cameraClock) ~= "number" then
		cameraClock = NIGHT_FALLBACK
	end
	local okPrior, priorClock = pcall(function()
		return Lighting.ClockTime
	end)
	if okPrior then
		originalClock = priorClock
	end
	local before = measure()
	local clockOk, clockWhy = setClock(cameraClock)
	local okEnable, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not clockOk then
		reason = "could not set ClockTime " .. tostring(cameraClock) .. ": " .. tostring(clockWhy)
	elseif not okEnable or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local night = measure()
	local stagedExpected = #Data.porchBulbs() + #Data.junctionPoles()

	-- Boundary legs use the applier's real setClockTime path; no candidate is staged twice.
	local clock20 = applierClock(20)
	local at20 = measure()
	local clock199 = applierClock(19.9)
	local at199 = measure()
	local clock5 = applierClock(5)
	local at5 = measure()
	local clock51 = applierClock(5.1)
	local at51 = measure()
	local clockDay = applierClock(DAY_CLOCK)
	local day = measure()

	emit(
		"LAMP_NIGHT_ONLY",
		reason == nil
			and clock20
			and clock199
			and clock5
			and clock51
			and clockDay
			and night.stagedLights > 0
			and night.enabled == night.stagedLights
			and at20.enabled == at20.stagedLights
			and at5.enabled == at5.stagedLights
			and at199.enabled == 0
			and at51.enabled == 0
			and day.enabled == 0,
		night.enabled,
		night.stagedLights,
		{
			camera = CAMERA_NAME,
			nightClock = cameraClock,
			nightOn = night.enabled,
			clock20On = at20.enabled,
			clock199On = at199.enabled,
			clock5On = at5.enabled,
			clock51On = at51.enabled,
			dayClock = DAY_CLOCK,
			dayOn = day.enabled,
			staged = night.stagedLights,
			reason = reason,
		}
	)

	emit(
		"LIGHT_COST",
		reason == nil
			and night.stagedLights == stagedExpected
			and night.stagedLights <= Data.MAX_LIGHTS
			and night.rangeViolations == 0,
		night.stagedLights,
		Data.MAX_LIGHTS,
		{
			beforeLights = before.allLights,
			allLights = night.allLights,
			expected = stagedExpected,
			rangeLimit = Data.LIGHT_RANGE,
			rangeViolations = night.rangeViolations,
			reason = reason,
		}
	)

	emit(
		"PORCH_BULBS",
		reason == nil
			and night.bulbCount >= 6
			and night.anchored == night.bulbCount
			and night.bulbLights == night.bulbCount,
		night.anchored,
		6,
		{
			bulbs = night.bulbCount,
			anchored = night.anchored,
			withLight = night.bulbLights,
			expected = #Data.porchBulbs(),
			tolerance = ANCHOR_TOLERANCE,
			reason = reason,
		}
	)

	emit(
		"THICK_POLES",
		reason == nil
			and night.poleCount >= 0
			and night.poleCount <= Data.MAX_JUNCTIONS
			and night.widthViolations == 0
			and night.headViolations == 0,
		night.poleCount,
		Data.MAX_JUNCTIONS,
		{
			poles = night.poleCount,
			expected = #Data.junctionPoles(),
			minWidth = Data.MIN_POLE_WIDTH,
			widthViolations = night.widthViolations,
			headViolations = night.headViolations,
			reason = reason,
		}
	)

	emit(
		"MODEL_USED",
		reason == nil and night.modelGroups > 0 and night.modelGroups == night.poleCount and night.modelParts > 0,
		night.modelGroups,
		night.poleCount,
		{
			assetId = MODEL_ASSET_ID,
			modelParts = night.modelParts,
			poles = night.poleCount,
			scripts = night.scripts,
			reason = reason,
		}
	)

	emit("NO_SCRIPTS", #night.scripts == 0, #night.scripts, 0, {
		names = night.scripts,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (NIGHT FAIL): a forced-on live light at ClockTime 13 must be counted.
	local dayVictim = day.lightList[1]
	local nightInjected = dayVictim ~= nil and recordSet(dayVictim, "Enabled", true)
	local calNight = measure()
	local nightFailed = calNight.enabled > 0
	emit("CAL_LAMP_NIGHT_FAIL", nightFailed, nightFailed and 1 or 0, 1, {
		injected = nightInjected,
		clock = DAY_CLOCK,
		enabled = calNight.enabled,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (COST FAIL): four extra staged PointLights push the live count past 12.
	local calRoot = stageRoot()
	local costInjected = 0
	if calRoot then
		for index = 1, Data.MAX_LIGHTS - night.stagedLights + 1 do
			local extra = Instance.new("PointLight")
			extra.Name = "CalibrationLight_" .. index
			extra.Enabled = false
			extra.Parent = calRoot
			recordDestroy(extra)
			costInjected += 1
		end
	end
	local calCost = measure()
	local costFailed = calCost.stagedLights > Data.MAX_LIGHTS
	emit("CAL_LIGHT_COST_FAIL", costFailed, costFailed and 1 or 0, 1, {
		injected = costInjected,
		staged = calCost.stagedLights,
		limit = Data.MAX_LIGHTS,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (PORCH FAIL): without the role marker no bulb is an anchored porch bulb.
	local porchInjected = 0
	for _, bulb in ipairs(night.bulbList) do
		if recordSet(bulb, Data.roleAttribute, nil, true) then
			porchInjected += 1
		end
	end
	local calPorch = measure()
	local porchFailed = calPorch.anchored < 6
	emit("CAL_PORCH_BULBS_FAIL", porchFailed, porchFailed and 1 or 0, 1, {
		injected = porchInjected,
		anchored = calPorch.anchored,
		bulbs = calPorch.bulbCount,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (THICK POLES FAIL): shrink every pole below MIN_POLE_WIDTH.
	local poleInjected = 0
	for _, pole in ipairs(night.poleList) do
		local size = pole.Size
		if recordSet(pole, "Size", Vector3.new(Data.MIN_POLE_WIDTH / 2, size.Y, Data.MIN_POLE_WIDTH / 2)) then
			poleInjected += 1
		end
	end
	local calPoles = measure()
	local polesFailed = calPoles.widthViolations > 0
	emit("CAL_THICK_POLES_FAIL", polesFailed, polesFailed and 1 or 0, 1, {
		injected = poleInjected,
		widthViolations = calPoles.widthViolations,
		minWidth = Data.MIN_POLE_WIDTH,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (MODEL USED FAIL): clear the baked-model marker on every staged model part.
	local modelInjected = 0
	for _, part in ipairs(night.modelList) do
		if recordSet(part, Data.modelAttribute, 0, true) then
			modelInjected += 1
		end
	end
	local calModel = measure()
	local modelFailed = calModel.modelGroups == 0
	emit("CAL_MODEL_USED_FAIL", modelFailed, modelFailed and 1 or 0, 1, {
		injected = modelInjected,
		modelGroups = calModel.modelGroups,
	})
	restoreInjected()

	-- CALIBRATION ANCHOR (NO SCRIPTS FAIL): one inert empty Script, destroyed before teardown.
	local calRootScripts = stageRoot()
	local scriptInjected = false
	if calRootScripts then
		local inert = Instance.new("Script")
		inert.Name = "CalibrationScript"
		inert.Parent = calRootScripts
		recordDestroy(inert)
		scriptInjected = true
	end
	local calScripts = measure()
	local scriptsFailed = #calScripts.scripts > 0
	emit("CAL_NO_SCRIPTS_FAIL", scriptsFailed, scriptsFailed and 1 or 0, 1, {
		injected = scriptInjected,
		scripts = calScripts.scripts,
	})
	restoreInjected()
end)

-- Restore injected properties, every staged candidate and the clock on every path.
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
	originalClock = nil
end

if not ok then
	local detail = { reason = "item 270 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], detail)
	end
end

local function measured(name)
	local entry = results.byName[name]
	return type(entry and entry.measured) == "number" and entry.measured or 0
end

local function calPassed()
	local count = 0
	for _, name in ipairs(CHECK_NAMES) do
		if string.sub(name, 1, 4) == "CAL_" and results.byName[name] and results.byName[name].passed then
			count += 1
		end
	end
	return count
end

print(
	string.format(
		"SUMMARY_Q270 LAMP_NIGHT_ONLY %d/%d LIGHT_COST %d/%d PORCH_BULBS %d/6 THICK_POLES %d/%d MODEL_USED %d/%d NO_SCRIPTS %d/0 CAL %d/6",
		measured("LAMP_NIGHT_ONLY"),
		measured("LAMP_NIGHT_ONLY"),
		measured("LIGHT_COST"),
		measured("LIGHT_COST"),
		measured("PORCH_BULBS"),
		measured("THICK_POLES"),
		measured("THICK_POLES"),
		measured("MODEL_USED"),
		measured("MODEL_USED"),
		measured("NO_SCRIPTS"),
		calPassed()
	)
)

return results
