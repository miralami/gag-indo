-- LookDevDayCycleR8: client applier for the OFF-BY-DEFAULT "day_cycle_r8" candidate
-- (WORK_QUEUE section M item 89). Mirrors LookDevDayCycle but reads the tuned phase table in
-- Shared.ModelMapDayCycleR8: warmer/lower sun, darker Ambient and ShadowSoftness 0.45 at Sore
-- (0.3 elsewhere), still 20-40 s tweens. Maghrib and every other phase are untouched.
--
-- Every touched property is saved and put back on disable, every created Instance is destroyed,
-- and every engine call is pcall-guarded. restore() is exact and idempotent. No asset IDs.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Seasons = require(Shared.Config.Seasons)
local DayCycleLive = require(Shared.World.DayCycleLive)
local ModelMapDayCycleR8 = require(Shared.ModelMapDayCycleR8)
local FidelityRuntime = require(script.Parent.Parent.Feel.FidelityRuntime)

local LookDevDayCycleR8 = {}

local CONTAINER = "LookDevDayCycleR8Lamps"
local TICK_SECONDS = 0.5

local applied = false
local startClock = 0
local lastTick = 0
local lastPhase: string? = nil
local originals: { { target: any, prop: string, value: any } } = {}
local savedKeys: { [string]: boolean } = {}
local created: { Instance } = {}
local tweens: { any } = {}
local connections: { any } = {}
local lamps: { { light: PointLight, brightness: number } } = {}
local lampBudget = DayCycleLive.lampBudget(nil)

local function numberOr(value: any, fallback: number): number
	if type(value) == "number" and value == value and value > -math.huge and value < math.huge then
		return value
	end
	return fallback
end

-- Enum lookups are pcall'd because the restricted Studio MCP VM cannot always resolve them.
local function tweenInfo(seconds: number): TweenInfo?
	local okStyle, style = pcall(function()
		return ((Enum :: any).EasingStyle).Sine
	end)
	local okDirection, direction = pcall(function()
		return ((Enum :: any).EasingDirection).Out
	end)
	if not okStyle or not okDirection or style == nil or direction == nil then
		return nil
	end
	local ok, info = pcall(TweenInfo.new, seconds, style, direction)
	return if ok then info else nil
end

local function saveProp(target: any, prop: string)
	local key = tostring(target) .. ":" .. prop
	if savedKeys[key] then
		return
	end
	local ok, value = pcall(function()
		return target[prop]
	end)
	if ok then
		savedKeys[key] = true
		table.insert(originals, { target = target, prop = prop, value = value })
	end
end

local function setProps(target: any, props: { [string]: any })
	for prop, value in props do
		pcall(function()
			target[prop] = value
		end)
	end
end

local function cancelTweens()
	for _, tween in ipairs(tweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(tweens)
end

local function tweenProps(target: any, props: { [string]: any }, seconds: number)
	for prop in props do
		saveProp(target, prop)
	end
	local info = tweenInfo(seconds)
	if info then
		local ok, tween = pcall(function()
			return TweenService:Create(target, info, props)
		end)
		if ok and tween then
			table.insert(tweens, tween)
			pcall(function()
				tween:Play()
			end)
			return
		end
	end
	-- No TweenInfo in this VM: the grade still lands, just without the phase-long ease.
	setProps(target, props)
end

local function effect(className: string): any
	local found = nil
	local okFind, existing = pcall(function()
		return Lighting:FindFirstChildOfClass(className)
	end)
	if okFind then
		found = existing
	end
	if not found then
		local okNew, instance = pcall(function()
			return Instance.new(className)
		end)
		if not okNew or not instance then
			return nil
		end
		local okParent, parented = pcall(function()
			instance.Parent = Lighting
			return instance.Parent
		end)
		if not okParent or not parented then
			return nil
		end
		found = instance
		table.insert(created, found)
	end
	return found
end

local function currentTier(): string
	local ok, runtime = pcall(function()
		return FidelityRuntime.get()
	end)
	return if ok and type(runtime) == "string" then runtime else "Sedang"
end

local function currentPreset(elapsed: number): any
	local seasonPreset = nil
	local ok, preset = pcall(function()
		return Seasons.skyFor(ReplicatedStorage:GetAttribute("Musim"), ReplicatedStorage:GetAttribute("Cuaca"))
	end)
	if ok then
		seasonPreset = preset
	end
	return ModelMapDayCycleR8.presetFor(elapsed, seasonPreset, currentTier())
end

local function applyGrade(elapsed: number)
	local preset = currentPreset(elapsed)
	local seconds = DayCycleLive.tweenSeconds(elapsed)
	cancelTweens()

	tweenProps(Lighting, {
		ClockTime = preset.clockTime,
		Brightness = preset.brightness,
		FogEnd = preset.fogEnd,
		FogColor = preset.fogColor,
		Ambient = preset.ambient,
		OutdoorAmbient = preset.outdoorAmbient,
		ColorShift_Top = preset.colorShiftTop,
		ColorShift_Bottom = preset.colorShiftBottom,
		ShadowSoftness = preset.shadowSoftness,
	}, seconds)

	local atmo = effect("Atmosphere")
	if atmo then
		tweenProps(atmo, {
			Density = preset.atmosphereDensity,
			Haze = preset.atmosphereHaze,
			Color = preset.atmosphereColor,
			Decay = preset.atmosphereDecay,
			Glare = preset.atmosphereGlare,
		}, seconds)
	end

	local correction = effect("ColorCorrectionEffect")
	if correction then
		tweenProps(correction, {
			TintColor = preset.tint,
			Saturation = preset.saturation,
			Contrast = preset.contrast,
		}, seconds)
	end
	local bloom = effect("BloomEffect")
	if bloom then
		tweenProps(bloom, { Intensity = preset.bloom }, seconds)
	end
	local sunRays = effect("SunRaysEffect")
	if sunRays then
		tweenProps(sunRays, { Intensity = preset.sunRays }, seconds)
	end

	local terrain = nil
	local okTerrain, foundTerrain = pcall(function()
		return Workspace:FindFirstChildOfClass("Terrain")
	end)
	if okTerrain then
		terrain = foundTerrain
	end
	local cloud = nil
	if terrain then
		local okCloud, foundCloud = pcall(function()
			return terrain:FindFirstChildOfClass("Clouds")
		end)
		if okCloud then
			cloud = foundCloud
		end
	end
	if cloud then
		tweenProps(cloud, { Cover = preset.cloudCover }, seconds)
	end
end

local function updateLamps(preset: any)
	local level = math.clamp(numberOr(preset.lampLevel, 0), 0, 1)
	local brightness = lampBudget.intensity * level
	for _, lamp in ipairs(lamps) do
		pcall(function()
			lamp.light.Brightness = brightness
		end)
	end
end

local function buildLamps()
	local okNew, container = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not container then
		return
	end
	local okInit, initialized = pcall(function()
		container.Name = CONTAINER
		container.Parent = Workspace
		return container.Parent
	end)
	if not okInit or not initialized then
		return
	end
	table.insert(created, container)

	local positions = DayCycleLive.lampPositions()
	local count = math.min(#positions, lampBudget.maxLights)
	for index = 1, count do
		local position = positions[index]
		local okBuild, part, light = pcall(function()
			local lampPart = Instance.new("Part")
			lampPart.Name = "LookDevDayCycleR8Lamp_" .. index
			lampPart.Size = Vector3.new(0.6, 0.6, 0.6)
			lampPart.CFrame = CFrame.new(position[1], position[2], position[3])
			lampPart.Anchored = true
			lampPart.CanCollide = false
			lampPart.Parent = container
			local lampLight = Instance.new("PointLight")
			lampLight.Name = "LampLight"
			lampLight.Shadows = false -- Rendah budget: zero shadow-casting lights
			lampLight.Range = lampBudget.range
			lampLight.Brightness = 0
			lampLight.Parent = lampPart
			return lampPart, lampLight
		end)
		if okBuild and part and light then
			table.insert(created, part)
			table.insert(created, light)
			table.insert(lamps, { light = light, brightness = lampBudget.intensity })
		end
	end
end

local function tick()
	local elapsed = os.clock() - startClock
	local preset = currentPreset(elapsed)
	updateLamps(preset)
	if preset.phaseId ~= lastPhase then
		lastPhase = preset.phaseId
		applyGrade(elapsed)
	end
end

local function onAttributeChanged()
	if applied then
		lastPhase = nil
		tick()
	end
end

local function connect(getSignal: () -> any, handler: () -> ())
	local okSignal, signal = pcall(getSignal)
	if not okSignal or not signal then
		return
	end
	local ok, connection = pcall(function()
		return signal:Connect(handler)
	end)
	if ok and connection then
		table.insert(connections, connection)
	end
end

local function apply(_plan: any)
	if applied then
		return
	end
	originals = {}
	savedKeys = {}
	created = {}
	tweens = {}
	connections = {}
	lamps = {}
	lampBudget = DayCycleLive.lampBudget(currentTier())
	startClock = os.clock()
	lastTick = startClock
	lastPhase = nil

	buildLamps()
	tick()

	-- Sky mounts first in Main.client, so these handlers re-apply the grade after Sky's own
	-- season/weather tween rather than letting it overwrite the candidate.
	connect(function()
		return ReplicatedStorage:GetAttributeChangedSignal("Musim")
	end, onAttributeChanged)
	connect(function()
		return ReplicatedStorage:GetAttributeChangedSignal("Cuaca")
	end, onAttributeChanged)
	connect(function()
		return RunService.Heartbeat
	end, function()
		if not applied or os.clock() - lastTick < TICK_SECONDS then
			return
		end
		lastTick = os.clock()
		tick()
	end)

	applied = true
end

local function restore()
	if not applied then
		return
	end
	applied = false

	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)
	cancelTweens()

	for _, entry in ipairs(originals) do
		pcall(function()
			entry.target[entry.prop] = entry.value
		end)
	end
	table.clear(originals)
	table.clear(savedKeys)

	for _, instance in ipairs(created) do
		pcall(function()
			if instance.Parent then
				instance:Destroy()
			end
		end)
	end
	table.clear(created)
	table.clear(lamps)
	lastPhase = nil
end

LookDev.register("day_cycle_r8", { apply = apply, restore = restore })

LookDevDayCycleR8.apply = apply
LookDevDayCycleR8.restore = restore
LookDevDayCycleR8.plan = DayCycleLive.plan

return LookDevDayCycleR8
