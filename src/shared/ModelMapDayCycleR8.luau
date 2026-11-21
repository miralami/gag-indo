--!strict
-- ModelMapDayCycleR8: pure data for the OFF-BY-DEFAULT "day_cycle_r8" LookDev candidate
-- (WORK_QUEUE section M item 89). It owns a full copy of DayCycle.PHASES with ONLY the Sore
-- phase tuned: warmer/brighter ColorShift_Top, darker Ambient (more sun-vs-ambient contrast),
-- a lower-sun clock cue and a bit more ShadowSoftness. Every other phase, especially Maghrib,
-- stays identical to the shipping table.
--
-- Pure module: no services, no instances, Lune-callable. Numeric quantities are documented in
-- docs/v2/visual/DAY_CYCLE.md ("Documented numeric limits (item 89)"):
--   luminance = Rec.709 0.2126*R + 0.7152*G + 0.0722*B on 0-255 channel values;
--   sun-vs-ambient ratio = luminance(colorShiftTop) / luminance(ambient);
--   documented phase-jump limit = PHASE_JUMP_FACTOR (1.25) * the original table's own maximum
--   normalized adjacent-channel jump. Colour channels are 0..255/255; multipliers and deltas
--   are used as-is. Adjacent pairs include the malam -> dini_hari wrap.

local DayCycle = require(script.Parent.World.DayCycle)

local ModelMapDayCycleR8 = {}

ModelMapDayCycleR8.id = "day_cycle_r8"
ModelMapDayCycleR8.BASE_PHASES = DayCycle.PHASES
ModelMapDayCycleR8.PHASE_JUMP_FACTOR = 1.25
ModelMapDayCycleR8.BASE_SHADOW_SOFTNESS = 0.3
ModelMapDayCycleR8.TUNED_SHADOW_SOFTNESS = 0.45
ModelMapDayCycleR8.COLOR_FIELDS = { "ambient", "outdoorAmbient", "colorShiftTop", "colorShiftBottom", "tint" }
ModelMapDayCycleR8.SCALAR_FIELDS = {
	"brightnessMultiplier",
	"fogEndMultiplier",
	"saturationDelta",
	"sunRaysDelta",
	"lampLevel",
}

-- Copy every phase field-for-field. Color3 is a value type on Roblox and a plain {R,G,B} table
-- under Lune, so clone it explicitly either way before touching the Sore entry.
local function clonePhase(phase: any): any
	local out = table.clone(phase)
	for _, field in ipairs(ModelMapDayCycleR8.COLOR_FIELDS) do
		local c = phase[field]
		out[field] = Color3.new(c.R, c.G, c.B)
	end
	return out
end

local PHASES = {}
for index, phase in ipairs(DayCycle.PHASES) do
	local copy = clonePhase(phase)
	if phase.id == "sore" then
		-- 15:00-17:00: warmer/lower sun, darker ambient, softer shadows. Ratio check:
		-- base 2.16 -> tuned 2.71 (~25% uplift); maghrib and all other phases untouched.
		copy.colorShiftTop = Color3.fromRGB(255, 190, 96)
		copy.ambient = Color3.fromRGB(84, 70, 68)
		copy.shadowSoftness = ModelMapDayCycleR8.TUNED_SHADOW_SOFTNESS
		copy.sunClockOffset = -0.75 -- lower sun: 16:00 reads as 15:15 at spawn
	end
	PHASES[index] = copy
end
ModelMapDayCycleR8.PHASES = PHASES

local BY_ID: { [string]: any } = {}
for _, phase in ipairs(PHASES) do
	BY_ID[phase.id] = phase
end

-- A real Roblox Color3 is userdata (type() ~= "table"); Lune's test double is a plain table. Read
-- channels through pcall so BOTH forms work — without this, luminance silently returned 0 in Studio
-- and the 16:00 contrast check emitted a vacuous 0 >= 0 PASS. channel255 maps normalized 0..1 or
-- literal 0..255 bytes onto one 0..255 scale. Rec.709 coefficients.
local function channel255(value: number): number
	return if value > 1 then value else value * 255
end

local function colorChannels(rgb: any): (number?, number?, number?)
	if rgb == nil then
		return nil, nil, nil
	end
	local okUpper, ur, ug, ub = pcall(function()
		return rgb.R, rgb.G, rgb.B
	end)
	if okUpper and type(ur) == "number" and type(ug) == "number" and type(ub) == "number" then
		return ur, ug, ub
	end
	local okLower, lr, lg, lb = pcall(function()
		return rgb.r, rgb.g, rgb.b
	end)
	if okLower and type(lr) == "number" and type(lg) == "number" and type(lb) == "number" then
		return lr, lg, lb
	end
	return nil, nil, nil
end

function ModelMapDayCycleR8.luminance(rgb: any): number
	local r, g, b = colorChannels(rgb)
	if r == nil or g == nil or b == nil then
		return 0
	end
	return 0.2126 * channel255(r) + 0.7152 * channel255(g) + 0.0722 * channel255(b)
end

function ModelMapDayCycleR8.contrastRatio(phase: any): number
	if type(phase) ~= "table" then
		return 0
	end
	local ambient = ModelMapDayCycleR8.luminance(phase.ambient)
	if ambient <= 0 then
		return 0
	end
	return ModelMapDayCycleR8.luminance(phase.colorShiftTop) / ambient
end

-- At 16:00 (DayCycle.START_CLOCK) the spawn sits inside Sore with alpha 0: pure phase values.
function ModelMapDayCycleR8.contrastAt1600(phases: { any }): number
	for _, phase in ipairs(phases) do
		if DayCycle.START_CLOCK >= phase.start and DayCycle.START_CLOCK <= phase.finish then
			return ModelMapDayCycleR8.contrastRatio(phase)
		end
	end
	return 0
end

local function delta(a: number, b: number): number
	return math.abs(a - b)
end

-- Largest normalized channel/multiplier delta over adjacent phases, including the midnight wrap.
function ModelMapDayCycleR8.adjacentJumps(phases: { any }): number
	local maxJump = 0
	for index, from in ipairs(phases) do
		local to = phases[if index == #phases then 1 else index + 1]
		for _, field in ipairs(ModelMapDayCycleR8.COLOR_FIELDS) do
			-- Duck-typed via colorChannels: a real Roblox Color3 is userdata, not a table, so a
			-- type()-based colour gate skipped every colour in Studio and made the jump check
			-- vacuous (0 <= limit). Lune's table double is handled the same way.
			local ar, ag, ab = colorChannels(from[field])
			local br, bg, bb = colorChannels(to[field])
			if ar and ag and ab and br and bg and bb then
				maxJump = math.max(maxJump, delta(channel255(ar), channel255(br)) / 255)
				maxJump = math.max(maxJump, delta(channel255(ag), channel255(bg)) / 255)
				maxJump = math.max(maxJump, delta(channel255(ab), channel255(bb)) / 255)
			end
		end
		for _, field in ipairs(ModelMapDayCycleR8.SCALAR_FIELDS) do
			if type(from[field]) == "number" and type(to[field]) == "number" then
				maxJump = math.max(maxJump, delta(from[field], to[field]))
			end
		end
	end
	return maxJump
end

ModelMapDayCycleR8.maxAdjacentJump = ModelMapDayCycleR8.adjacentJumps
ModelMapDayCycleR8.documentedLimit = ModelMapDayCycleR8.PHASE_JUMP_FACTOR
	* ModelMapDayCycleR8.adjacentJumps(ModelMapDayCycleR8.BASE_PHASES)

local function sameValue(a: any, b: any): boolean
	if type(a) == "table" and type(b) == "table" then
		if (a.R ~= nil) ~= (b.R ~= nil) then
			return false
		end
		if a.R ~= nil then
			return a.R == b.R and a.G == b.G and a.B == b.B
		end
		for key in pairs(a) do
			if not sameValue(a[key], b[key]) then
				return false
			end
		end
		for key in pairs(b) do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	return a == b
end

local function maghribOf(phases: { any }): any
	for _, phase in ipairs(phases) do
		if phase.id == "maghrib" then
			return phase
		end
	end
	return nil
end

-- Field-for-field deep compare: every scalar and every RGB channel must match.
function ModelMapDayCycleR8.maghribUnchanged(): boolean
	local base, tuned = maghribOf(ModelMapDayCycleR8.BASE_PHASES), maghribOf(PHASES)
	if type(base) ~= "table" or type(tuned) ~= "table" then
		return false
	end
	for key, value in pairs(base) do
		if not sameValue(value, tuned[key]) then
			return false
		end
	end
	for key in pairs(tuned) do
		if base[key] == nil then
			return false
		end
	end
	return true
end

-- Changed fields of Maghrib, for a harness detail line (empty when unchanged).
function ModelMapDayCycleR8.maghribChanges(): { string }
	local base, tuned = maghribOf(ModelMapDayCycleR8.BASE_PHASES), maghribOf(PHASES)
	local out = {}
	if type(base) ~= "table" or type(tuned) ~= "table" then
		return { "maghrib phase missing" }
	end
	local keys = {}
	for key in pairs(base) do
		keys[key] = true
	end
	for key in pairs(tuned) do
		keys[key] = true
	end
	for key in pairs(keys) do
		if not sameValue(base[key], tuned[key]) then
			out[#out + 1] = key
		end
	end
	table.sort(out)
	return out
end

local function lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

local function lerpColor(a: any, b: any, alpha: number): any
	return Color3.new(lerp(a.R, b.R, alpha), lerp(a.G, b.G, alpha), lerp(a.B, b.B, alpha))
end

-- Same season/weather grade path as DayCycle.presetFor, but reads the TUNED phases. Segment IDs
-- and alpha are unchanged (start/finish are identical), so the grade still eases over 20-40 s.
function ModelMapDayCycleR8.presetFor(elapsedSeconds: any, seasonPreset: any, tier: any): any
	local preset = DayCycle.presetFor(elapsedSeconds, seasonPreset, tier)
	local segment = DayCycle.segmentAt(elapsedSeconds)
	local from, to = BY_ID[segment.from], BY_ID[segment.to]
	if not from or not to then
		return preset
	end
	for _, field in ipairs(ModelMapDayCycleR8.COLOR_FIELDS) do
		preset[field] = lerpColor(from[field], to[field], segment.alpha)
	end
	preset.shadowSoftness = lerp(
		from.shadowSoftness or ModelMapDayCycleR8.BASE_SHADOW_SOFTNESS,
		to.shadowSoftness or ModelMapDayCycleR8.BASE_SHADOW_SOFTNESS,
		segment.alpha
	)
	preset.clockTime += lerp(from.sunClockOffset or 0, to.sunClockOffset or 0, segment.alpha)
	return preset
end

return ModelMapDayCycleR8
