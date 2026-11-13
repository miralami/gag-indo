-- Sky: the client half of seasons/weather (v2 PLAN §3.3). Reads the Musim/Cuaca attributes
-- LiveConfig publishes on ReplicatedStorage and tweens Lighting, Atmosphere and Clouds to the
-- preset in Config/Seasons. Purely visual: the server owns the season and the growth numbers.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Seasons = require(Shared.Config.Seasons)

local Sky = {}

local TWEEN = TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function atmosphere(): Atmosphere
	local found = Lighting:FindFirstChildOfClass("Atmosphere")
	if not found then
		found = Instance.new("Atmosphere")
		found.Parent = Lighting
	end
	return found :: Atmosphere
end

local function clouds(): Clouds
	local found = Lighting:FindFirstChildOfClass("Clouds")
	if not found then
		found = Instance.new("Clouds")
		found.Parent = Lighting
	end
	return found :: Clouds
end

-- Post-processing the golden-hour look needs (ART.md §5). Created once, tweened per preset.
local function effect(className: string): any
	local found = Lighting:FindFirstChildOfClass(className)
	if not found then
		found = Instance.new(className)
		found.Parent = Lighting
	end
	return found
end

-- Fixed look values. Lighting.Technology (Future) cannot be set from a script: it is saved in the
-- place file (Studio > Lighting > Technology), see docs/v2/TECH.md.
local function configureStatic()
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.ExposureCompensation = 0

	local bloom = effect("BloomEffect")
	bloom.Size = 28
	bloom.Threshold = 1.6

	effect("SunRaysEffect").Spread = 0.6
end

local function apply()
	local musim = ReplicatedStorage:GetAttribute("Musim")
	local cuaca = ReplicatedStorage:GetAttribute("Cuaca")
	local preset = Seasons.skyFor(musim, cuaca)

	TweenService:Create(Lighting, TWEEN, {
		ClockTime = preset.clockTime,
		Brightness = preset.brightness,
		FogEnd = preset.fogEnd,
		FogStart = math.min(40, preset.fogEnd * 0.1),
		FogColor = preset.fogColor,
		Ambient = preset.ambient,
		OutdoorAmbient = preset.outdoorAmbient,
		ColorShift_Top = preset.colorShiftTop,
		ColorShift_Bottom = preset.colorShiftBottom,
	}):Play()

	TweenService:Create(atmosphere(), TWEEN, {
		Density = preset.atmosphereDensity,
		Haze = preset.atmosphereHaze,
		Color = preset.atmosphereColor,
		Decay = preset.atmosphereDecay,
	}):Play()

	TweenService:Create(effect("ColorCorrectionEffect"), TWEEN, {
		TintColor = preset.tint,
		Saturation = preset.saturation,
		Contrast = preset.contrast,
	}):Play()

	TweenService:Create(effect("BloomEffect"), TWEEN, { Intensity = preset.bloom }):Play()
	TweenService:Create(effect("SunRaysEffect"), TWEEN, { Intensity = preset.sunRays }):Play()

	TweenService:Create(clouds(), TWEEN, {
		Cover = preset.cloudCover,
	}):Play()
end

function Sky.mount()
	configureStatic()
	ReplicatedStorage:GetAttributeChangedSignal("Musim"):Connect(apply)
	ReplicatedStorage:GetAttributeChangedSignal("Cuaca"):Connect(apply)
	apply()
end

return Sky
