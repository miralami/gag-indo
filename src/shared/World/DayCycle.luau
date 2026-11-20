--!strict
-- Pure day-cycle data (DAY_CYCLE.md, V-D2/D19). A server starts at 16:00 golden hour, one
-- in-game hour lasts one real minute, and a full day is 24 real minutes. The eight phases layer
-- a time-of-day grade over the season x weather sky preset from Config/Seasons.luau; season and
-- weather keep fog, atmosphere, cloud cover and their other fields.
--
-- Nothing here touches Roblox services, so the whole cycle runs under Lune. The live wiring
-- (heartbeat, Lighting tween, lamps, sound beds) is a thin caller of presetFor/phaseInfo.

local DayCycle = {}

DayCycle.DAY_SECONDS = 1440
DayCycle.SECONDS_PER_GAME_HOUR = 60
DayCycle.START_CLOCK = 16
DayCycle.ADZAN_SETTING_KEY = "setting_adzan"

type Phase = {
	id: string,
	labelKey: string,
	start: number,
	finish: number,
	brightnessMultiplier: number,
	fogEndMultiplier: number,
	ambient: Color3,
	outdoorAmbient: Color3,
	colorShiftTop: Color3,
	colorShiftBottom: Color3,
	tint: Color3,
	saturationDelta: number,
	sunRaysDelta: number,
	lampLevel: number,
	soundBed: string,
	transitionSeconds: number,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Ordered by game hour. Gaps between `finish` and the next `start` blend; malam wraps to
-- dini_hari across midnight. Night keeps a floor on brightness/fogEnd so paths stay readable.
local PHASES: { Phase } = {
	{
		id = "dini_hari",
		labelKey = "phase_dini_hari",
		start = 1.0,
		finish = 3.5,
		brightnessMultiplier = 0.45,
		fogEndMultiplier = 0.55,
		ambient = rgb(48, 58, 92),
		outdoorAmbient = rgb(64, 74, 110),
		colorShiftTop = rgb(30, 40, 82),
		colorShiftBottom = rgb(58, 62, 86),
		tint = rgb(205, 214, 242),
		saturationDelta = -0.1,
		sunRaysDelta = -0.02,
		lampLevel = 0.6,
		soundBed = "bed_dini_hari",
		transitionSeconds = 30,
	},
	{
		id = "subuh",
		labelKey = "phase_subuh",
		start = 4.0,
		finish = 5.5,
		brightnessMultiplier = 0.55,
		fogEndMultiplier = 0.6,
		ambient = rgb(66, 70, 108),
		outdoorAmbient = rgb(88, 88, 122),
		colorShiftTop = rgb(76, 66, 112),
		colorShiftBottom = rgb(92, 80, 96),
		tint = rgb(220, 216, 240),
		saturationDelta = -0.05,
		sunRaysDelta = 0,
		lampLevel = 0.25,
		soundBed = "bed_subuh",
		transitionSeconds = 30,
	},
	{
		id = "pagi",
		labelKey = "phase_pagi",
		start = 6.0,
		finish = 9.5,
		brightnessMultiplier = 0.9,
		fogEndMultiplier = 0.85,
		ambient = rgb(104, 96, 96),
		outdoorAmbient = rgb(142, 128, 122),
		colorShiftTop = rgb(235, 198, 152),
		colorShiftBottom = rgb(112, 96, 88),
		tint = rgb(248, 240, 224),
		saturationDelta = 0.02,
		sunRaysDelta = 0.02,
		lampLevel = 0,
		soundBed = "bed_pagi",
		transitionSeconds = 25,
	},
	{
		id = "dhuha",
		labelKey = "phase_dhuha",
		start = 10.0,
		finish = 11.5,
		brightnessMultiplier = 1.1,
		fogEndMultiplier = 1.0,
		ambient = rgb(116, 110, 106),
		outdoorAmbient = rgb(156, 146, 138),
		colorShiftTop = rgb(250, 244, 224),
		colorShiftBottom = rgb(126, 116, 106),
		tint = rgb(255, 252, 244),
		saturationDelta = 0,
		sunRaysDelta = 0.02,
		lampLevel = 0,
		soundBed = "bed_dhuha",
		transitionSeconds = 25,
	},
	{
		id = "siang_bolong",
		labelKey = "phase_siang_bolong",
		start = 12.0,
		finish = 14.5,
		brightnessMultiplier = 1.2,
		fogEndMultiplier = 1.05,
		ambient = rgb(122, 116, 110),
		outdoorAmbient = rgb(164, 154, 144),
		colorShiftTop = rgb(255, 250, 238),
		colorShiftBottom = rgb(132, 122, 112),
		tint = rgb(244, 242, 236),
		saturationDelta = -0.08,
		sunRaysDelta = -0.02,
		lampLevel = 0,
		soundBed = "bed_siang",
		transitionSeconds = 35,
	},
	{
		id = "sore",
		labelKey = "phase_sore",
		start = 15.0,
		finish = 17.5,
		brightnessMultiplier = 1.0,
		fogEndMultiplier = 0.95,
		ambient = rgb(112, 94, 92),
		outdoorAmbient = rgb(152, 130, 116),
		colorShiftTop = rgb(255, 206, 132),
		colorShiftBottom = rgb(124, 94, 82),
		tint = rgb(255, 232, 196),
		saturationDelta = 0.06,
		sunRaysDelta = 0.12,
		lampLevel = 0,
		soundBed = "bed_sore",
		transitionSeconds = 30,
	},
	{
		id = "maghrib",
		labelKey = "phase_maghrib",
		start = 17.75,
		finish = 18.5,
		brightnessMultiplier = 0.65,
		fogEndMultiplier = 0.7,
		ambient = rgb(86, 70, 104),
		outdoorAmbient = rgb(118, 94, 122),
		colorShiftTop = rgb(178, 84, 116),
		colorShiftBottom = rgb(112, 74, 98),
		tint = rgb(248, 208, 194),
		saturationDelta = 0.04,
		sunRaysDelta = 0.02,
		lampLevel = 0.5,
		soundBed = "bed_maghrib",
		transitionSeconds = 20,
	},
	{
		id = "malam",
		labelKey = "phase_malam",
		start = 19.0,
		finish = 23.5,
		brightnessMultiplier = 0.5,
		fogEndMultiplier = 0.6,
		ambient = rgb(58, 68, 104),
		outdoorAmbient = rgb(78, 90, 126),
		colorShiftTop = rgb(28, 40, 80),
		colorShiftBottom = rgb(64, 68, 94),
		tint = rgb(210, 220, 248),
		saturationDelta = -0.06,
		sunRaysDelta = -0.02,
		lampLevel = 1,
		soundBed = "bed_malam",
		transitionSeconds = 30,
	},
}

DayCycle.PHASES = PHASES

local BY_ID: { [string]: Phase } = {}
for _, phase in ipairs(DayCycle.PHASES) do
	BY_ID[phase.id] = phase
end

local NIGHT = {
	dini_hari = true,
	subuh = true,
	maghrib = true,
	malam = true,
}

local LIGHT_BUDGET = {
	Rendah = { maxLights = 6, shadowLights = 0 },
	Sedang = { maxLights = 12, shadowLights = 2 },
	Tinggi = { maxLights = 24, shadowLights = 6 },
}

local DEFAULT_BASE = {
	clockTime = DayCycle.START_CLOCK,
	brightness = 2,
	fogEnd = 2000,
	fogColor = rgb(240, 220, 200),
	atmosphereDensity = 0.12,
	atmosphereHaze = 0.5,
	cloudCover = 0.5,
	contrast = 0.05,
	bloom = 0.2,
	saturation = 0.1,
	sunRays = 0.05,
}

local COLOR_FIELDS = { "ambient", "outdoorAmbient", "colorShiftTop", "colorShiftBottom", "tint" }

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function numberOr(value: any, fallback: number): number
	return if finite(value) then value else fallback
end

local function cleanElapsed(value: any): number
	return if finite(value) and value >= 0 then value else 0
end

local function lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

-- Component-wise so this works with the Roblox Color3 and the Lune test double alike.
local function lerpColor(a: Color3, b: Color3, alpha: number): Color3
	return Color3.new(lerp(a.R, b.R, alpha), lerp(a.G, b.G, alpha), lerp(a.B, b.B, alpha))
end

-- 0..24 game hours. Spawn is 16.0; nil/junk/negative values degrade to spawn.
function DayCycle.clockAt(elapsedSeconds: any): number
	return (DayCycle.START_CLOCK + cleanElapsed(elapsedSeconds) / DayCycle.SECONDS_PER_GAME_HOUR) % 24
end

-- The phase containing this instant, or the gap to the next one. `phase` picks the nearer
-- neighbour, which is the one callers should use for lamps, sound and labels.
function DayCycle.segmentAt(elapsedSeconds: any): { from: string, to: string, alpha: number, phase: string }
	local clock = DayCycle.clockAt(elapsedSeconds)
	for _, phase in ipairs(DayCycle.PHASES) do
		if clock >= phase.start and clock <= phase.finish then
			return { from = phase.id, to = phase.id, alpha = 0, phase = phase.id }
		end
	end

	local nextIndex = 1
	for index, phase in ipairs(DayCycle.PHASES) do
		if clock < phase.start then
			nextIndex = index
			break
		end
	end

	local to = DayCycle.PHASES[nextIndex]
	local from = DayCycle.PHASES[if nextIndex == 1 then #DayCycle.PHASES else nextIndex - 1]
	local gapStart = from.finish
	local gapEnd = to.start
	local span = if gapEnd > gapStart then gapEnd - gapStart else gapEnd + 24 - gapStart
	local travelled = if clock >= gapStart then clock - gapStart else clock + 24 - gapStart
	local alpha = math.clamp(span > 0 and travelled / span or 0, 0, 1)
	return {
		from = from.id,
		to = to.id,
		alpha = alpha,
		phase = if alpha < 0.5 then from.id else to.id,
	}
end

function DayCycle.phaseInfo(elapsedSeconds: any): {
	id: string,
	labelKey: string,
	soundBed: string,
	lampLevel: number,
	transitionSeconds: number,
}
	local phase = BY_ID[DayCycle.segmentAt(elapsedSeconds).phase] or DayCycle.PHASES[6]
	return {
		id = phase.id,
		labelKey = phase.labelKey,
		soundBed = phase.soundBed,
		lampLevel = phase.lampLevel,
		transitionSeconds = phase.transitionSeconds,
	}
end

function DayCycle.isNight(elapsedSeconds: any): boolean
	return NIGHT[DayCycle.segmentAt(elapsedSeconds).phase] == true
end

-- Fresh preset: clones the season/weather table, then grades clock, light, colour and lamps.
-- `seasonPreset` is never mutated; a nil/junk preset falls back to a neutral sky.
function DayCycle.presetFor(elapsedSeconds: any, seasonPreset: any, tier: any): any
	local base = if type(seasonPreset) == "table" then seasonPreset else DEFAULT_BASE
	local out = table.clone(base)
	local segment = DayCycle.segmentAt(elapsedSeconds)
	local from = BY_ID[segment.from] or DayCycle.PHASES[6]
	local to = BY_ID[segment.to] or from
	local alpha = segment.alpha
	local nearest = BY_ID[segment.phase] or from

	out.clockTime = DayCycle.clockAt(elapsedSeconds)
	out.brightness = numberOr(base.brightness, DEFAULT_BASE.brightness)
		* lerp(from.brightnessMultiplier, to.brightnessMultiplier, alpha)
	out.fogEnd = math.max(
		40,
		numberOr(base.fogEnd, DEFAULT_BASE.fogEnd) * lerp(from.fogEndMultiplier, to.fogEndMultiplier, alpha)
	)
	out.saturation =
		math.clamp(numberOr(base.saturation, 0) + lerp(from.saturationDelta, to.saturationDelta, alpha), -1, 1)
	out.sunRays = math.clamp(numberOr(base.sunRays, 0) + lerp(from.sunRaysDelta, to.sunRaysDelta, alpha), 0, 1)
	for _, field in ipairs(COLOR_FIELDS) do
		out[field] = lerpColor(from[field], to[field], alpha)
	end

	out.lampLevel = math.clamp(lerp(from.lampLevel, to.lampLevel, alpha), 0, 1)
	out.soundBed = nearest.soundBed
	out.phaseId = nearest.id
	out.transitionSeconds = nearest.transitionSeconds

	local budget = if type(tier) == "string" then LIGHT_BUDGET[tier] or LIGHT_BUDGET.Sedang else LIGHT_BUDGET.Sedang
	out.maxLights = budget.maxLights
	out.shadowLights = budget.shadowLights
	return out
end

return DayCycle
