-- LookDevDayCycle: client applier for the OFF-BY-DEFAULT "day_cycle" candidate (WORK_QUEUE
-- round 3 item 25). It drives the same Lighting/Atmosphere/effect objects Sky.luau owns, using
-- DayCycle.presetFor(elapsed, season/weather preset, fidelity tier) instead of the static season
-- preset. It never edits Sky.luau or shipping defaults: every touched property is saved and put
-- back on disable, and every Instance it creates is destroyed on disable.
--
-- The pure plan lives in Shared.World.DayCycleLive. No asset IDs: the five sound-bed slots in
-- Config/Audio are id 0 (silent) until the designer supplies licensed IDs.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local Seasons = require(Shared.Config.Seasons)
local DayCycleLive = require(Shared.World.DayCycleLive)
local FidelityRuntime = require(script.Parent.Parent.Feel.FidelityRuntime)

local LookDevDayCycle = {}

local CONTAINER = "LookDevDayCycleLamps"
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
	local found = Lighting:FindFirstChildOfClass(className)
	if not found then
		found = Instance.new(className)
		found.Parent = Lighting
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
	return DayCycleLive.preset(elapsed, seasonPreset, currentTier())
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
	}, seconds)

	tweenProps(effect("Atmosphere"), {
		Density = preset.atmosphereDensity,
		Haze = preset.atmosphereHaze,
		Color = preset.atmosphereColor,
		Decay = preset.atmosphereDecay,
		Glare = preset.atmosphereGlare,
	}, seconds)

	tweenProps(effect("ColorCorrectionEffect"), {
		TintColor = preset.tint,
		Saturation = preset.saturation,
		Contrast = preset.contrast,
	}, seconds)
	tweenProps(effect("BloomEffect"), { Intensity = preset.bloom }, seconds)
	tweenProps(effect("SunRaysEffect"), { Intensity = preset.sunRays }, seconds)

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	local cloud = terrain and terrain:FindFirstChildOfClass("Clouds") or nil
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
	local container = Instance.new("Folder")
	container.Name = CONTAINER
	container.Parent = Workspace
	table.insert(created, container)

	local positions = DayCycleLive.lampPositions()
	local count = math.min(#positions, lampBudget.maxLights)
	for index = 1, count do
		local position = positions[index]
		local part = Instance.new("Part")
		part.Name = "LookDevDayCycleLamp_" .. index
		part.Size = Vector3.new(0.6, 0.6, 0.6)
		part.CFrame = CFrame.new(position[1], position[2], position[3])
		part.Anchored = true
		part.CanCollide = false
		part.Parent = container
		table.insert(created, part)

		local light = Instance.new("PointLight")
		light.Name = "LampLight"
		light.Shadows = false -- Rendah budget: zero shadow-casting lights
		light.Range = lampBudget.range
		light.Brightness = 0
		light.Parent = part
		table.insert(created, light)
		table.insert(lamps, { light = light, brightness = lampBudget.intensity })
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

local function connect(signal: any, handler: () -> ())
	if not signal then
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
	connect(ReplicatedStorage:GetAttributeChangedSignal("Musim"), onAttributeChanged)
	connect(ReplicatedStorage:GetAttributeChangedSignal("Cuaca"), onAttributeChanged)
	connect(RunService.Heartbeat, function()
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

LookDev.register("day_cycle", { apply = apply, restore = restore })

LookDevDayCycle.apply = apply
LookDevDayCycle.restore = restore
LookDevDayCycle.plan = DayCycleLive.plan

return LookDevDayCycle
