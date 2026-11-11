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
	}):Play()

	TweenService:Create(atmosphere(), TWEEN, {
		Density = preset.atmosphereDensity,
		Haze = preset.atmosphereHaze,
	}):Play()

	TweenService:Create(clouds(), TWEEN, {
		Cover = preset.cloudCover,
	}):Play()
end

function Sky.mount()
	ReplicatedStorage:GetAttributeChangedSignal("Musim"):Connect(apply)
	ReplicatedStorage:GetAttributeChangedSignal("Cuaca"):Connect(apply)
	apply()
end

return Sky
