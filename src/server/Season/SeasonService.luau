-- SeasonService: turns the global LiveConfig runtime into farming numbers and client hints.
--
-- Ownership: LiveConfig owns the season/weather document and resolves it (override -> calendar);
-- this service owns nothing but the mapping from that state to growth seconds and attribute
-- mirrors. FarmService asks for growth at plant time; the client reads the attributes and the
-- shared Config/Seasons presets for sky and labels.
--
-- Start order: after LiveConfig, before FarmService's first plant.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local Seasons = require(Shared.Config.Seasons)

local LiveConfig = require(script.Parent.Parent.Live.LiveConfig)

local SeasonService = {}

function SeasonService.runtime(): any
	return LiveConfig.getRuntime()
end

function SeasonService.musim(): string
	return SeasonService.runtime().musim
end

function SeasonService.cuaca(): string
	return SeasonService.runtime().cuaca
end

function SeasonService.anomali(): string
	return SeasonService.runtime().anomali
end

-- Growth multiplier for one family today (season + anomaly).
function SeasonService.growth(family: string?): number
	local runtime = SeasonService.runtime()
	return Seasons.growth(runtime.musim, family, runtime.anomali)
end

-- Real growing time for a crop: the config seconds divided by today's growth multiplier.
-- Never below 5 s, so a stacked buff can't make crops instant.
function SeasonService.growSeconds(baseSeconds: number, family: string?): number
	return math.max(5, math.floor(baseSeconds / SeasonService.growth(family) + 0.5))
end

local function publish(runtime)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	for _, familyId in Crops.familyOrder do
		ReplicatedStorage:SetAttribute(
			"Growth_" .. familyId,
			Seasons.growth(runtime.musim, familyId, runtime.anomali)
		)
	end
end

function SeasonService.start()
	publish(LiveConfig.getRuntime())
	LiveConfig.onChanged(function(_, runtime)
		publish(runtime)
	end)
end

return SeasonService
