-- Seasons and weather (v2 PLAN §3.3). One global state, read by every server.
-- M0 ships the calendar fallback and the pure helpers; growth/shop effects arrive in M2,
-- and LiveConfig supplies the admin override.
--
-- Source priority: admin override -> live value -> this calendar.
-- (The live weather API hook is a later, optional change behind the same interface.)

local Seasons = {}

Seasons.musimOrder = { "hujan", "kemarau", "pancaroba" }
Seasons.anomaliOrder = { "none", "elNino", "laNina" }
Seasons.cuacaOrder = { "cerah", "hujan", "badai", "kabut" }

-- Growth multipliers per family; used by FarmService (M2). `growth` is the season's base
-- multiplier; `growthByFamily` overrides it per crop family (PLAN §3.3).
Seasons.list = {
	hujan = {
		growth = 1.1,
		growthByFamily = { palawija = 1.25, kebun = 1.1, perkebunan = 1.05 },
		labelKey = "season_hujan",
		rain = true,
	},
	kemarau = {
		growth = 0.9,
		growthByFamily = { palawija = 0.75, kebun = 0.95, perkebunan = 1.0 },
		labelKey = "season_kemarau",
		dry = true,
	},
	pancaroba = {
		growth = 1.0,
		growthByFamily = { palawija = 1.0, kebun = 1.0, perkebunan = 1.0 },
		labelKey = "season_pancaroba",
	},
}

-- Anomalies bend growth on top of the season (El Nino dries, La Nina soaks).
Seasons.anomaliGrowth = {
	none = 1.0,
	elNino = 0.85,
	laNina = 1.1,
}

-- Seasonal risk events (v2 PLAN §3.3). Checked on harvest.
Seasons.risks = {
	banjirChance = 0.08, -- in musim hujan + weather badai/hujan, palawija can drown
	hamaChance = 0.06, -- in musim pancaroba, any crop can get pest-damaged
	elNinoFailChance = 0.08, -- in anomali elNino, crops can fail from drought
}

-- Sky presets (v2 PLAN §3.3, ART.md §5). The client merges the season preset with the weather
-- overlay and tweens Lighting towards it; nothing on the server reads these.
-- Golden-hour look: low warm sun, shadows tinted indigo-brown (never grey or black), warm haze.
-- Colours come from the ART.md palette (senja, padi, genteng, indigo, malam).
Seasons.sky = {
	hujan = {
		clockTime = 16.0,
		brightness = 1.8,
		fogEnd = 360,
		fogColor = Color3.fromRGB(146, 162, 178),
		ambient = Color3.fromRGB(86, 96, 118),
		outdoorAmbient = Color3.fromRGB(122, 136, 158),
		colorShiftTop = Color3.fromRGB(200, 215, 235),
		colorShiftBottom = Color3.fromRGB(96, 104, 130),
		atmosphereDensity = 0.4,
		atmosphereHaze = 2.0,
		atmosphereColor = Color3.fromRGB(150, 165, 185),
		atmosphereDecay = Color3.fromRGB(90, 100, 125),
		cloudCover = 0.75,
		tint = Color3.fromRGB(225, 235, 245),
		saturation = 0.18,
		contrast = 0.08,
		bloom = 0.25,
		sunRays = 0.02,
	},
	kemarau = {
		clockTime = 16.9,
		brightness = 3.0,
		fogEnd = 950,
		fogColor = Color3.fromRGB(240, 200, 140),
		ambient = Color3.fromRGB(120, 98, 84),
		outdoorAmbient = Color3.fromRGB(170, 140, 108),
		colorShiftTop = Color3.fromRGB(255, 214, 150),
		colorShiftBottom = Color3.fromRGB(110, 92, 110),
		atmosphereDensity = 0.3,
		atmosphereHaze = 1.2,
		atmosphereColor = Color3.fromRGB(246, 201, 122),
		atmosphereDecay = Color3.fromRGB(200, 120, 70),
		cloudCover = 0.1,
		tint = Color3.fromRGB(255, 236, 205),
		saturation = 0.22,
		contrast = 0.1,
		bloom = 0.35,
		sunRays = 0.14,
	},
	pancaroba = {
		clockTime = 16.5,
		brightness = 2.4,
		fogEnd = 750,
		fogColor = Color3.fromRGB(230, 205, 160),
		ambient = Color3.fromRGB(104, 100, 104),
		outdoorAmbient = Color3.fromRGB(150, 140, 130),
		colorShiftTop = Color3.fromRGB(255, 226, 180),
		colorShiftBottom = Color3.fromRGB(104, 98, 118),
		atmosphereDensity = 0.34,
		atmosphereHaze = 1.5,
		atmosphereColor = Color3.fromRGB(235, 215, 170),
		atmosphereDecay = Color3.fromRGB(190, 130, 90),
		cloudCover = 0.4,
		tint = Color3.fromRGB(255, 242, 222),
		saturation = 0.2,
		contrast = 0.08,
		bloom = 0.3,
		sunRays = 0.08,
	},
}

-- Weather overlays on top of the season preset. brightness/fogEnd/sunRays are multipliers;
-- cloudCover/atmosphereDensity/atmosphereHaze/saturation are additive and clamped in skyFor.
Seasons.cuacaSky = {
	cerah = { brightness = 1.0, cloudCover = -0.2 },
	hujan = { brightness = 0.75, fogEnd = 0.7, cloudCover = 0.2, saturation = -0.04, sunRays = 0.3 },
	badai = { brightness = 0.55, fogEnd = 0.45, cloudCover = 1, atmosphereDensity = 0.2, saturation = -0.12, sunRays = 0 },
	kabut = { brightness = 0.85, fogEnd = 0.4, atmosphereDensity = 0.25, atmosphereHaze = 2, saturation = -0.08, sunRays = 0.5 },
}

-- Weighted weather table per season. `roll` is a number in [0, 1) — pass math.random()
-- in game, or a fixed value in tests.
Seasons.weatherWeights = {
	hujan = { cerah = 0.22, hujan = 0.58, badai = 0.12, kabut = 0.08 },
	kemarau = { cerah = 0.70, hujan = 0.06, badai = 0.02, kabut = 0.22 },
	pancaroba = { cerah = 0.38, hujan = 0.32, badai = 0.12, kabut = 0.18 },
}

function Seasons.isMusim(value: any): boolean
	return type(value) == "string" and Seasons.list[value] ~= nil
end

function Seasons.isAnomali(value: any): boolean
	return type(value) == "string" and table.find(Seasons.anomaliOrder, value) ~= nil
end

function Seasons.isCuaca(value: any): boolean
	return type(value) == "string" and table.find(Seasons.cuacaOrder, value) ~= nil
end

-- Roughly Nov-Mar hujan, May-Sep kemarau, the rest pancaroba (PLAN §3.3).
function Seasons.forMonth(month: number): string
	if month >= 11 or month <= 3 then
		return "hujan"
	elseif month >= 5 and month <= 9 then
		return "kemarau"
	end
	return "pancaroba"
end

function Seasons.fromUnix(timestamp: number): string
	local ok, date = pcall(function()
		return os.date("*t", timestamp)
	end)
	if ok and type(date) == "table" and type(date.month) == "number" then
		return Seasons.forMonth(date.month)
	end
	return "pancaroba"
end

-- Pure weighted pick: pass `math.random()` (or a fixture) as `roll`.
function Seasons.rollWeather(musim: string, roll: number?): string
	local weights = Seasons.weatherWeights[musim] or Seasons.weatherWeights.pancaroba
	local point = math.clamp(roll or math.random(), 0, 0.999999)
	local total = 0
	for _, cuaca in Seasons.cuacaOrder do
		total += weights[cuaca] or 0
		if point < total then
			return cuaca
		end
	end
	return "cerah"
end

-- Growth multiplier for one crop family. `anomaly` is optional (LiveConfig supplies it).
function Seasons.growth(musim: string?, family: string?, anomaly: string?): number
	local season = Seasons.list[musim or ""] or Seasons.list.pancaroba
	local byFamily = season.growthByFamily
	local base = (byFamily and family and byFamily[family]) or season.growth or 1
	local anomalyMultiplier = Seasons.anomaliGrowth[anomaly or "none"] or 1
	return math.clamp(base * anomalyMultiplier, 0.5, 2)
end

-- Season preset merged with the weather overlay, ready for the client's Lighting tween.
function Seasons.skyFor(musim: string?, cuaca: string?): any
	local base = Seasons.sky[musim or ""] or Seasons.sky.pancaroba
	local overlay = Seasons.cuacaSky[cuaca or ""] or Seasons.cuacaSky.cerah
	local out = {}
	for key, value in base do
		out[key] = value
	end
	out.brightness = (base.brightness or 1) * (overlay.brightness or 1)
	out.fogEnd = math.max(40, (base.fogEnd or 500) * (overlay.fogEnd or 1))
	out.cloudCover = math.clamp((base.cloudCover or 0) + (overlay.cloudCover or 0), 0, 1)
	out.atmosphereDensity = math.clamp((base.atmosphereDensity or 0) + (overlay.atmosphereDensity or 0), 0, 1)
	out.atmosphereHaze = math.clamp((base.atmosphereHaze or 0) + (overlay.atmosphereHaze or 0), 0, 10)
	out.saturation = math.clamp((base.saturation or 0) + (overlay.saturation or 0), -1, 1)
	out.sunRays = math.clamp((base.sunRays or 0) * (overlay.sunRays or 1), 0, 1)
	return out
end

return Seasons
