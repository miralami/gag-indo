--!strict
-- ModelMapSubuhR8: pure data for the OFF-BY-DEFAULT "subuh_r8" LookDev candidate (WORK_QUEUE
-- section N item 121). A dawn preset spanning 04:30-06:00: cool blue ColorShift eases to peach,
-- low mist thins, a first warm lamp glow ramps in at 05:00 and is gone by 06:00. No Sound is
-- staged: while this candidate is active the off-by-default sounds bed cannot play, so birds are
-- silent before 06:00. birdsAudible(clock) records that boundary for checks; no bird asset id is
-- invented and no Sound instance is created by the applier.
--
-- Pure module: no engine APIs, no instances, no asset IDs. Colours are plain byte triples
-- { r, g, b } converted to Color3 by the client applier. Values are clamped to the intersection
-- of the documented DayCycle / grade / rain safe bands (DAWN_SAFE). The four phase clocks are
-- strict steps; colour and brightness change only at those endpoints and the applier eases the
-- write over the documented 20-40 s DayCycle tween window (TWEEN_SECONDS is inside that window).
--
-- Documented numeric limits:
--   monotonic = top.R, (top.R - top.B)/255 and Rec.709 luminance/255 each strictly increase;
--   maxJump = largest top.R step / 255 over the three adjacent pairs;
--   limit = JUMP_FACTOR * BASE_JUMP where BASE_JUMP is the shipping DayCycle subuh->pagi top.R
--   step (76 -> 235, i.e. 159/255) and JUMP_FACTOR is 1.25. BASE_JUMP > 0 makes the limit
--   non-vacuous. DAWN_SAFE bands are listed in safeRanges and are never wider than their sources.

local ModelMapSubuhR8 = {}

ModelMapSubuhR8.id = "subuh_r8"
ModelMapSubuhR8.FOLDER = "LookDevSubuhR8Lamps"
ModelMapSubuhR8.CLOCK_START = 4.5
ModelMapSubuhR8.CLOCK_END = 6
ModelMapSubuhR8.BIRDS_START = 6
ModelMapSubuhR8.TWEEN_SECONDS = 30
ModelMapSubuhR8.SHADOW_SOFTNESS = 0.3
ModelMapSubuhR8.JUMP_FACTOR = 1.25
ModelMapSubuhR8.BASE_JUMP = 159 / 255
ModelMapSubuhR8.MAX_JUMP = ModelMapSubuhR8.JUMP_FACTOR * ModelMapSubuhR8.BASE_JUMP

-- ponytail: float32 endpoint tolerance for Roblox numeric properties (an authored band endpoint
-- can read back a few float32 steps low). Keep at 1e-4; if a property ever stores float64, drop
-- this to 0 rather than widening any band further.
ModelMapSubuhR8.BAND_EPSILON = 1e-4

local function rgb(r: number, g: number, b: number): { r: number, g: number, b: number }
	return { r = r, g = g, b = b }
end

-- The shipped subuh->pagi endpoints are preserved exactly at 04:30 and 06:00; the two middle
-- rows are intermediate warm-up steps, not new gameplay phases. Top.B rises rather than falls, so
-- monotonicity is measured on R, R-B and luminance, never on B alone.
ModelMapSubuhR8.PHASES = {
	{
		id = "subuh_0430",
		clock = 4.5,
		brightness = 1.2,
		fogEnd = 1200,
		fogColor = rgb(190, 205, 230),
		ambient = rgb(66, 70, 108),
		outdoorAmbient = rgb(88, 88, 122),
		colorShiftTop = rgb(76, 66, 112),
		colorShiftBottom = rgb(92, 80, 96),
		tint = rgb(220, 216, 240),
		tintColor = rgb(0.94, 0.97, 1.04),
		saturation = 0.02,
		contrast = 0,
		bloom = 0.1,
		sunRays = 0.04,
		atmosphereDensity = 0.3,
		atmosphereHaze = 1.4,
		atmosphereColor = rgb(236, 232, 220),
		cloudCover = 0.55,
	},
	{
		id = "subuh_0500",
		clock = 5,
		brightness = 1.4,
		fogEnd = 1366,
		fogColor = rgb(206, 211, 221),
		ambient = rgb(79, 79, 104),
		outdoorAmbient = rgb(106, 101, 122),
		colorShiftTop = rgb(120, 104, 126),
		colorShiftBottom = rgb(99, 85, 94),
		tint = rgb(229, 224, 235),
		tintColor = rgb(0.97, 0.98, 1.02),
		saturation = 0.05,
		contrast = 0.01,
		bloom = 0.12,
		sunRays = 0.08,
		atmosphereDensity = 0.28,
		atmosphereHaze = 1.3,
		atmosphereColor = rgb(239, 234, 218),
		cloudCover = 0.52,
	},
	{
		id = "subuh_0530",
		clock = 5.5,
		brightness = 1.6,
		fogEnd = 1533,
		fogColor = rgb(223, 218, 212),
		ambient = rgb(92, 87, 100),
		outdoorAmbient = rgb(124, 114, 122),
		colorShiftTop = rgb(178, 154, 138),
		colorShiftBottom = rgb(106, 91, 91),
		tint = rgb(238, 232, 229),
		tintColor = rgb(1.01, 1, 0.99),
		saturation = 0.08,
		contrast = 0.02,
		bloom = 0.15,
		sunRays = 0.14,
		atmosphereDensity = 0.25,
		atmosphereHaze = 1.2,
		atmosphereColor = rgb(242, 236, 214),
		cloudCover = 0.46,
	},
	{
		id = "pagi_0600",
		clock = 6,
		brightness = 1.8,
		fogEnd = 1700,
		fogColor = rgb(240, 224, 204),
		ambient = rgb(104, 96, 96),
		outdoorAmbient = rgb(142, 128, 122),
		colorShiftTop = rgb(235, 198, 152),
		colorShiftBottom = rgb(112, 96, 88),
		tint = rgb(248, 240, 224),
		tintColor = rgb(1.04, 1.01, 0.96),
		saturation = 0.12,
		contrast = 0.03,
		bloom = 0.18,
		sunRays = 0.2,
		atmosphereDensity = 0.22,
		atmosphereHaze = 1.1,
		atmosphereColor = rgb(245, 238, 210),
		cloudCover = 0.4,
	},
}

-- Light-blue decay and a modest glare are held constant; they are inside the grade band and are
-- part of the exact LIFO snapshot so a disable puts the pre-candidate sky back.
ModelMapSubuhR8.ATMOSPHERE_DECAY = rgb(150, 190, 220)
ModelMapSubuhR8.ATMOSPHERE_GLARE = 1.2

-- Rendah-style lamp ceiling: at most six non-shadow lights, 14-stud reach, 0.45 peak brightness.
-- The ramp is 0 -> 0.45 over 05:00-05:30, then back to 0 by 06:00.
ModelMapSubuhR8.LAMP = {
	maxLights = 6,
	range = 14,
	brightnessMax = 0.45,
	shadows = false,
	rampStart = 5,
	rampEnd = 5.5,
	offAt = 6,
}

-- DAWN_SAFE bands. Every range is the intersection of its source band, never wider:
-- brightness is inside 1.2..3.2; fogEnd inside 40..4000; byte channels 0..255;
-- Density 0.22..0.35 and Haze 1.0..2.4 (grade); Cover 0.35..0.60 (DayCycle);
-- grade bands verbatim for ColorCorrection, Bloom and SunRays; lamp ceilings 14 / 0.45.
-- Engine property classification. The applier uses these names to build real engine colours:
-- byte triples are 0..255 channel data, fractional triples are already 0..1 (near-white tint).
-- This module stays pure: it only returns normalized plain triples, never an engine value.
ModelMapSubuhR8.BYTE_COLOR_PROPS = {
	ColorShift_Top = true,
	ColorShift_Bottom = true,
	FogColor = true,
	Ambient = true,
	OutdoorAmbient = true,
	Color = true,
	Decay = true,
}
ModelMapSubuhR8.FRACTION_COLOR_PROPS = { TintColor = true }

local byte = { min = 0, max = 255 }
local channels = { R = byte, G = byte, B = byte }
local tintBand = {
	R = { min = 0.9, max = 1.1 },
	G = { min = 0.9, max = 1.1 },
	B = { min = 0.9, max = 1.1 },
}

ModelMapSubuhR8.safeRanges = {
	Lighting = {
		Brightness = { min = 1.2, max = 3.2 },
		FogEnd = { min = 40, max = 4000 },
		FogColor = channels,
		Ambient = channels,
		OutdoorAmbient = channels,
		ColorShift_Top = channels,
		ColorShift_Bottom = channels,
	},
	Atmosphere = {
		Density = { min = 0.22, max = 0.35 },
		Haze = { min = 1, max = 2.4 },
		Color = channels,
		Decay = channels,
		Glare = { min = 0.8, max = 1.5 },
	},
	Clouds = {
		Cover = { min = 0.35, max = 0.6 },
	},
	ColorCorrectionEffect = {
		Saturation = { min = 0, max = 0.2 },
		Contrast = { min = -0.02, max = 0.08 },
		TintColor = tintBand,
	},
	BloomEffect = {
		Intensity = { min = 0, max = 0.25 },
	},
	SunRaysEffect = {
		Intensity = { min = 0, max = 0.3 },
	},
	Lamps = {
		Shadows = false,
		Range = { min = 0, max = 30 },
		Brightness = { min = 0, max = 3 },
	},
}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

-- Duck-typed so a real Roblox Color3 (userdata) and this module's byte triple both work.
local function channel(color: any, name: string): number?
	if color == nil then
		return nil
	end
	local okUpper, upper = pcall(function()
		return color[string.upper(name)]
	end)
	if okUpper and finite(upper) then
		return upper
	end
	local okLower, lower = pcall(function()
		return color[string.lower(name)]
	end)
	if okLower and finite(lower) then
		return lower
	end
	return nil
end

-- Pure conversion: returns a normalized plain triple for a known colour prop, or nil. The client
-- applier feeds this into the engine colour constructor; no engine API is called here.
function ModelMapSubuhR8.normalizedColor(prop: string, triple: any): { r: number, g: number, b: number }?
	local scale = nil
	if ModelMapSubuhR8.BYTE_COLOR_PROPS[prop] then
		scale = 1 / 255
	elseif ModelMapSubuhR8.FRACTION_COLOR_PROPS[prop] then
		scale = 1
	end
	if scale == nil then
		return nil
	end
	local r, g, b = channel(triple, "R"), channel(triple, "G"), channel(triple, "B")
	if r == nil or g == nil or b == nil then
		return nil
	end
	return { r = r * scale, g = g * scale, b = b * scale }
end

local function lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

local function lerpColor(a: any, b: any, alpha: number)
	return rgb(lerp(a.r, b.r, alpha), lerp(a.g, b.g, alpha), lerp(a.b, b.b, alpha))
end

function ModelMapSubuhR8.phaseCount(): number
	return #ModelMapSubuhR8.PHASES
end

-- No clock override may make a bird bed audible before the 06:00 boundary. Silence is staged by
-- omission: this candidate never creates a Sound and never starts the sounds_r8 bed.
function ModelMapSubuhR8.birdsAudible(clock: any): boolean
	return finite(clock) and clock >= ModelMapSubuhR8.BIRDS_START
end

local function lampValue(clock: any): number
	if not finite(clock) then
		return 0
	end
	local lamp = ModelMapSubuhR8.LAMP
	if clock < lamp.rampStart or clock >= lamp.offAt then
		return 0
	end
	if clock <= lamp.rampEnd then
		return lamp.brightnessMax * clamp01((clock - lamp.rampStart) / (lamp.rampEnd - lamp.rampStart))
	end
	return lamp.brightnessMax * clamp01((lamp.offAt - clock) / (lamp.offAt - lamp.rampEnd))
end

ModelMapSubuhR8.lampBrightness = lampValue

-- Fresh interpolated preset for the clock. Outside the dawn window the nearest endpoint is used,
-- so a stray live clock cannot push any value outside DAWN_SAFE.
function ModelMapSubuhR8.presetFor(clock: any): any
	local phases = ModelMapSubuhR8.PHASES
	local from, to, alpha = phases[1], phases[1], 0
	if finite(clock) then
		if clock <= phases[1].clock then
			from, to = phases[1], phases[1]
		elseif clock >= phases[#phases].clock then
			from, to = phases[#phases], phases[#phases]
		else
			for index = 1, #phases - 1 do
				if clock >= phases[index].clock and clock <= phases[index + 1].clock then
					from, to = phases[index], phases[index + 1]
					alpha = clamp01((clock - from.clock) / (to.clock - from.clock))
					break
				end
			end
		end
	end
	local mix = function(field: string): number
		return lerp(from[field], to[field], alpha)
	end
	return {
		clockTime = if finite(clock) then clock else ModelMapSubuhR8.CLOCK_START,
		brightness = mix("brightness"),
		fogEnd = mix("fogEnd"),
		fogColor = lerpColor(from.fogColor, to.fogColor, alpha),
		ambient = lerpColor(from.ambient, to.ambient, alpha),
		outdoorAmbient = lerpColor(from.outdoorAmbient, to.outdoorAmbient, alpha),
		colorShiftTop = lerpColor(from.colorShiftTop, to.colorShiftTop, alpha),
		colorShiftBottom = lerpColor(from.colorShiftBottom, to.colorShiftBottom, alpha),
		tint = lerpColor(from.tint, to.tint, alpha),
		tintColor = lerpColor(from.tintColor, to.tintColor, alpha),
		saturation = mix("saturation"),
		contrast = mix("contrast"),
		bloom = mix("bloom"),
		sunRays = mix("sunRays"),
		atmosphereDensity = mix("atmosphereDensity"),
		atmosphereHaze = mix("atmosphereHaze"),
		atmosphereColor = lerpColor(from.atmosphereColor, to.atmosphereColor, alpha),
		cloudCover = mix("cloudCover"),
		lampBrightness = lampValue(if finite(clock) then clock else ModelMapSubuhR8.CLOCK_START),
		phaseId = if alpha < 0.5 then from.id else to.id,
	}
end

function ModelMapSubuhR8.phaseAt(clock: any): string
	return ModelMapSubuhR8.presetFor(clock).phaseId
end

-- DAWN_PHASES_MONOTONIC proof: three strict steps on three independent channels plus a bounded
-- per-step jump. maxJump is normalized by 255 and measured on top.R; baseJump comes from the
-- shipping DayCycle subuh->pagi top.R delta and is strictly positive.
function ModelMapSubuhR8.monotonic(): any
	local clocks, top, warmth, luminance = {}, {}, {}, {}
	for _, phase in ipairs(ModelMapSubuhR8.PHASES) do
		local r = channel(phase.colorShiftTop, "R") or 0
		local g = channel(phase.colorShiftTop, "G") or 0
		local b = channel(phase.colorShiftTop, "B") or 0
		clocks[#clocks + 1] = phase.clock
		top[#top + 1] = r
		warmth[#warmth + 1] = (r - b) / 255
		luminance[#luminance + 1] = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
	end
	local steps, maxJump, strictlyRising = 0, 0, true
	for index = 2, #top do
		steps += 1
		if
			not (top[index] > top[index - 1])
			or not (warmth[index] > warmth[index - 1])
			or not (luminance[index] > luminance[index - 1])
		then
			strictlyRising = false
		end
		maxJump = math.max(maxJump, math.abs(top[index] - top[index - 1]) / 255)
	end
	local pass = strictlyRising and steps == 3 and ModelMapSubuhR8.BASE_JUMP > 0 and maxJump <= ModelMapSubuhR8.MAX_JUMP
	return {
		pass = pass,
		steps = steps,
		clocks = clocks,
		top = top,
		warmth = warmth,
		luminance = luminance,
		maxJump = maxJump,
		limit = ModelMapSubuhR8.MAX_JUMP,
		baseJump = ModelMapSubuhR8.BASE_JUMP,
		factor = ModelMapSubuhR8.JUMP_FACTOR,
	}
end

local function bandFailure(band: any, value: any): string?
	if type(band) == "boolean" then
		return if value == band then nil else "expected " .. tostring(band)
	end
	if type(band) ~= "table" then
		return "missing band"
	end
	if band.R ~= nil then
		for _, name in ipairs({ "R", "G", "B" }) do
			local number = channel(value, name)
			local inner = band[name]
			if number == nil or type(inner) ~= "table" then
				return name .. " unreadable"
			end
			if
				number < inner.min - ModelMapSubuhR8.BAND_EPSILON
				or number > inner.max + ModelMapSubuhR8.BAND_EPSILON
			then
				return name .. " outside " .. tostring(inner.min) .. ".." .. tostring(inner.max)
			end
		end
		return nil
	end
	if not finite(value) or type(band.min) ~= "number" or type(band.max) ~= "number" then
		return "bad value or band"
	end
	if value < band.min - ModelMapSubuhR8.BAND_EPSILON or value > band.max + ModelMapSubuhR8.BAND_EPSILON then
		return "outside " .. tostring(band.min) .. ".." .. tostring(band.max)
	end
	return nil
end

-- Given a readings table shaped like safeRanges (the applier's safeReadings() is), return every
-- DAWN_SAFE violation. An empty list means the reading is in band; no vacuous success on nil.
function ModelMapSubuhR8.checkReadings(readings: any): { string }
	local failures: { string } = {}
	if type(readings) ~= "table" then
		failures[1] = "readings missing"
		return failures
	end
	for group, fields in pairs(ModelMapSubuhR8.safeRanges) do
		if type(readings[group]) ~= "table" then
			failures[#failures + 1] = group .. ":missing"
		else
			for field, band in pairs(fields) do
				local reason = bandFailure(band, readings[group][field])
				if reason then
					failures[#failures + 1] = group .. "." .. field .. ":" .. reason
				end
			end
		end
	end
	return failures
end

-- Every authored phase, including its lamp recipe, must already sit inside DAWN_SAFE. The harness
-- reads the LIVE properties too; this pure pass is the deterministic guard on the data itself.
function ModelMapSubuhR8.phasesInBands(): boolean
	for _, phase in ipairs(ModelMapSubuhR8.PHASES) do
		local lamp = ModelMapSubuhR8.LAMP
		local readings = {
			Lighting = {
				Brightness = phase.brightness,
				FogEnd = phase.fogEnd,
				FogColor = phase.fogColor,
				Ambient = phase.ambient,
				OutdoorAmbient = phase.outdoorAmbient,
				ColorShift_Top = phase.colorShiftTop,
				ColorShift_Bottom = phase.colorShiftBottom,
			},
			Atmosphere = {
				Density = phase.atmosphereDensity,
				Haze = phase.atmosphereHaze,
				Color = phase.atmosphereColor,
				Decay = ModelMapSubuhR8.ATMOSPHERE_DECAY,
				Glare = ModelMapSubuhR8.ATMOSPHERE_GLARE,
			},
			Clouds = { Cover = phase.cloudCover },
			ColorCorrectionEffect = {
				Saturation = phase.saturation,
				Contrast = phase.contrast,
				TintColor = phase.tintColor,
			},
			BloomEffect = { Intensity = phase.bloom },
			SunRaysEffect = { Intensity = phase.sunRays },
			Lamps = {
				Shadows = lamp.shadows,
				Range = lamp.range,
				Brightness = ModelMapSubuhR8.lampBrightness(phase.clock),
			},
		}
		if #ModelMapSubuhR8.checkReadings(readings) > 0 then
			return false
		end
	end
	return true
end

return ModelMapSubuhR8
