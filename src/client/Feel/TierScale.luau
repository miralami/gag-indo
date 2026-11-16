-- TierScale: pure math that turns a FidelityTier settings table into particle counts, particle
-- lifetimes and foliage sway weights (VISUAL_MASTER_PLAN section 6). No Roblox services, so it runs
-- under Lune. Every function accepts nil or malformed settings and falls back to the Sedang table.

local FidelityTier = require(script.Parent.FidelityTier)

local TierScale = {}

local FADE_START = 0.6 -- sway is full strength inside this fraction of the range, then fades out

local function clean(settings: any)
	if type(settings) == "table" then
		return settings
	end
	return FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
end

local function number(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

-- Burst size for Emit(n): base * particleRate, rounded, never below 1 so a Biasa burst and a Sultan
-- burst both stay visible on Rendah.
function TierScale.emitCount(base: any, settings: any): number
	local defaults = FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
	local rate = number(clean(settings).particleRate, defaults.particleRate)
	if rate < 0 then
		rate = 0
	end
	local scaled = math.floor(number(base, 1) * rate + 0.5)
	return math.max(1, scaled)
end

-- Emitter Rate (particles per second) scaled by the tier. Rate 0 stays 0; a positive rate stays positive.
function TierScale.rate(base: any, settings: any): number
	local defaults = FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
	local rate = math.max(0, number(clean(settings).particleRate, defaults.particleRate))
	local b = math.max(0, number(base, 0))
	return b * rate
end

-- Particle lifetime range scaled by particleLifeScale. Returns min, max (numbers, min <= max, > 0).
function TierScale.lifetime(minLife: any, maxLife: any, settings: any): (number, number)
	local defaults = FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
	local scale = number(clean(settings).particleLifeScale, defaults.particleLifeScale)
	if scale <= 0 then
		scale = defaults.particleLifeScale
	end
	local lo = math.max(0.05, number(minLife, 0.3))
	local hi = math.max(lo, number(maxLife, lo))
	return lo * scale, hi * scale
end

-- Foliage sway weight 0..1 for a part `distance` studs from the camera. 1 up to FADE_START of the
-- tier's foliageSwayRange, a linear fade to 0 at the range, 0 beyond it. Bad distance means 0.
function TierScale.swayWeight(distance: any, settings: any): number
	local defaults = FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
	local range = number(clean(settings).foliageSwayRange, defaults.foliageSwayRange)
	if range <= 0 then
		return 0
	end
	if type(distance) ~= "number" or distance ~= distance then
		return 0
	end
	local d = math.max(0, distance)
	local fadeFrom = range * FADE_START
	if d <= fadeFrom then
		return 1
	end
	if d >= range then
		return 0
	end
	return 1 - (d - fadeFrom) / (range - fadeFrom)
end

-- The sway range itself (studs), for callers that want a cheap cull before measuring.
function TierScale.swayRange(settings: any): number
	local defaults = FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
	return math.max(0, number(clean(settings).foliageSwayRange, defaults.foliageSwayRange))
end

return TierScale
