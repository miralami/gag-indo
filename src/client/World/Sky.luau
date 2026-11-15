-- Sky: the client half of seasons/weather (v2 PLAN §3.3). Reads the Musim/Cuaca attributes
-- LiveConfig publishes on ReplicatedStorage and tweens Lighting, Atmosphere and Clouds to the
-- preset in Config/Seasons. Purely visual: the server owns the season and the growth numbers.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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

-- Roblox only renders Clouds parented under workspace.Terrain. Migrate any legacy Clouds
-- left under Lighting and wait briefly for Terrain to replicate; return nil if it never does.
local function clouds(): Clouds?
	local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace:WaitForChild("Terrain", 10)
	if not terrain then
		return nil
	end

	local found = terrain:FindFirstChildOfClass("Clouds")
	if not found then
		local legacy = Lighting:FindFirstChildOfClass("Clouds")
		if legacy then
			legacy.Parent = terrain
			found = legacy
		end
	end
	if not found then
		found = Instance.new("Clouds")
		found.Parent = terrain
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

local function skyInstance(): Sky
	local found = Lighting:FindFirstChildOfClass("Sky")
	if not found then
		found = Instance.new("Sky")
		found.Parent = Lighting
	end
	found.SkyboxBk = "rbxassetid://156042307"
	found.SkyboxDn = "rbxassetid://155440478"
	found.SkyboxFt = "rbxassetid://156042328"
	found.SkyboxLf = "rbxassetid://156042348"
	found.SkyboxRt = "rbxassetid://156042292"
	found.SkyboxUp = "rbxassetid://156042384"
	found.CelestialBodiesShown = true
	return found :: Sky
end

-- Fixed look values. Lighting.Technology (Future) cannot be set from a script: it is saved in the
-- place file (Studio > Lighting > Technology), see docs/v2/TECH.md.
local function configureStatic()
	skyInstance()
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.ExposureCompensation = 0.08

	local bloom = effect("BloomEffect")
	bloom.Size = 28
	bloom.Threshold = 1.6

	effect("SunRaysEffect").Spread = 0.6
end

local function apply()
	local musim = ReplicatedStorage:GetAttribute("Musim")
	local cuaca = ReplicatedStorage:GetAttribute("Cuaca")
	local preset = Seasons.skyFor(musim, cuaca)

	Lighting.ExposureCompensation = 0.08

	TweenService:Create(Lighting, TWEEN, {
		ClockTime = preset.clockTime,
		Brightness = preset.brightness,
		FogEnd = preset.fogEnd,
		FogStart = preset.fogStart or math.min(40, preset.fogEnd * 0.1),
		FogColor = preset.fogColor,
		Ambient = preset.ambient,
		OutdoorAmbient = preset.outdoorAmbient,
		ColorShift_Top = preset.colorShiftTop,
		ColorShift_Bottom = preset.colorShiftBottom,
	}):Play()

	TweenService:Create(atmosphere(), TWEEN, {
		Density = preset.atmosphereDensity or 0.35,
		Haze = preset.atmosphereHaze or 1,
		Color = preset.atmosphereColor,
		Decay = preset.atmosphereDecay,
		Glare = preset.atmosphereGlare or 0.3,
	}):Play()

	TweenService:Create(effect("ColorCorrectionEffect"), TWEEN, {
		TintColor = preset.tint,
		Saturation = preset.saturation,
		Contrast = preset.contrast,
	}):Play()

	TweenService:Create(effect("BloomEffect"), TWEEN, { Intensity = preset.bloom }):Play()
	TweenService:Create(effect("SunRaysEffect"), TWEEN, { Intensity = preset.sunRays }):Play()

	local cloud = clouds()
	if cloud then
		TweenService:Create(cloud, TWEEN, {
			Cover = preset.cloudCover,
		}):Play()
	end
end

function Sky.mount()
	configureStatic()
	ReplicatedStorage:GetAttributeChangedSignal("Musim"):Connect(apply)
	ReplicatedStorage:GetAttributeChangedSignal("Cuaca"):Connect(apply)
	apply()
end

return Sky
