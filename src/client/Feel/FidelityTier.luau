-- FidelityTier (VISUAL_MASTER_PLAN section 6): one place that picks "Rendah", "Sedang" or "Tinggi"
-- so every visual asks it instead of deciding alone. Client only.
--
-- All the logic is pure: the clock and the frame times are injected, so it runs under Lune with
-- no Roblox services. The live wiring (RunService.Heartbeat -> controller.step(dt), the settings
-- toggle) is a thin caller, not part of this module.
--
-- Rules:
--   * Inputs: saved quality setting (a tier name, or nil/"Otomatis"), a rolling frame-time
--     average, and a manual override (a tier name, or nil/"Otomatis" to clear it).
--   * Down quickly: a short rolling window averaging above DOWN_FRAME_TIME steps down one tier
--     once DOWN_COOLDOWN seconds have passed since the last change.
--   * Up slowly: the average must stay below UP_FRAME_TIME (a gap under the down threshold, so
--     there is no thrash) for UP_SUSTAIN seconds AND UP_COOLDOWN seconds since the last change.
--     Auto never rises above the saved setting.
--   * Never during a hook moment: beginMoment/endMoment keep a counter (nesting is fine). While it
--     is above zero the tier is frozen, override included; a pending change lands on endMoment.
--   * Bad frame times (non-number, NaN, infinite, zero, negative, or over MAX_FRAME_TIME, which
--     means a pause or tab-out and not rendering cost) are ignored.

export type Tier = "Rendah" | "Sedang" | "Tinggi"

local FidelityTier = {}

FidelityTier.TIERS = { "Rendah", "Sedang", "Tinggi" }
FidelityTier.AUTO = "Otomatis"
FidelityTier.DEFAULT_START = "Sedang" -- worst-case assumption when nothing is saved

local WINDOW_SIZE = 30 -- frames in the rolling average
local MIN_SAMPLES = 10 -- frames needed before any decision
local DOWN_FRAME_TIME = 1 / 45 -- average slower than ~45 fps: step down
local UP_FRAME_TIME = 1 / 57 -- average faster than ~57 fps: may step up
local DOWN_COOLDOWN = 2 -- seconds between a change and the next down step
local UP_SUSTAIN = 10 -- seconds of continuously good frames before up
local UP_COOLDOWN = 30 -- seconds between a change and the next up step
local MAX_FRAME_TIME = 2

FidelityTier.DOWN_FRAME_TIME = DOWN_FRAME_TIME
FidelityTier.UP_FRAME_TIME = UP_FRAME_TIME
FidelityTier.DOWN_COOLDOWN = DOWN_COOLDOWN
FidelityTier.UP_SUSTAIN = UP_SUSTAIN
FidelityTier.UP_COOLDOWN = UP_COOLDOWN
FidelityTier.MIN_SAMPLES = MIN_SAMPLES
FidelityTier.WINDOW_SIZE = WINDOW_SIZE

local SETTINGS = {
	Rendah = table.freeze({
		particleRate = 0.4,
		particleLifeScale = 0.6, -- short life
		foliageSwayRange = 25,
		localLights = "none", -- emissive only
		smallPartShadows = "off",
		rain = "sheet", -- camera sheet only
		cameraDoF = false,
		ambientLife = "minimal", -- smoke and wind only
	}),
	Sedang = table.freeze({
		particleRate = 0.7,
		particleLifeScale = 1,
		foliageSwayRange = 50,
		localLights = "key", -- key lights, no shadows
		smallPartShadows = "near", -- off beyond 60 studs
		rain = "splashes",
		cameraDoF = false,
		ambientLife = "half", -- most, half counts
	}),
	Tinggi = table.freeze({
		particleRate = 1.0,
		particleLifeScale = 1,
		foliageSwayRange = 80,
		localLights = "all", -- shadows on heroes
		smallPartShadows = "on",
		rain = "full", -- plus drips, mist, puddles
		cameraDoF = true,
		ambientLife = "full",
	}),
}

local INDEX = { Rendah = 1, Sedang = 2, Tinggi = 3 }

function FidelityTier.isTier(value: any): boolean
	return type(value) == "string" and INDEX[value] ~= nil
end

-- Pure: the settings table for a tier. Unknown names fall back to the default start tier.
function FidelityTier.settingsFor(tier: any)
	local key = tier
	if not FidelityTier.isTier(key) then
		key = FidelityTier.DEFAULT_START
	end
	return SETTINGS[key]
end

-- Pure: a usable frame time (seconds) or nil.
function FidelityTier.cleanFrameTime(dt: any): number?
	if type(dt) ~= "number" or dt ~= dt or dt <= 0 or dt > MAX_FRAME_TIME then
		return nil
	end
	return dt
end

-- opts: { clock: () -> number, setting: string?, override: string? }
function FidelityTier.new(opts: any?)
	opts = opts or {}
	local clock = opts.clock or os.clock

	local self = {}
	local ceiling = INDEX.Tinggi -- highest tier auto may reach (the saved setting)
	local autoTier = INDEX[FidelityTier.DEFAULT_START]
	local override: number? = nil
	local current = autoTier
	local moments = 0
	local samples: { number } = {}
	local sampleSum = 0
	local lastChange = clock()
	local goodSince: number? = nil
	local listeners = {}

	local function applySetting(setting: any)
		if FidelityTier.isTier(setting) then
			ceiling = INDEX[setting]
			autoTier = ceiling
		else
			ceiling = INDEX.Tinggi
			autoTier = INDEX[FidelityTier.DEFAULT_START]
		end
	end

	local function resetWindow()
		samples = {}
		sampleSum = 0
		goodSince = nil
	end

	-- Lands the wanted tier unless a hook moment holds it.
	local function apply()
		if moments > 0 then
			return
		end
		local wanted = override or autoTier
		if wanted == current then
			return
		end
		local old = current
		current = wanted
		lastChange = clock()
		resetWindow()
		local oldName, newName = FidelityTier.TIERS[old], FidelityTier.TIERS[current]
		for _, listener in table.clone(listeners) do
			listener(newName, oldName, SETTINGS[newName])
		end
	end

	applySetting(opts.setting)
	if FidelityTier.isTier(opts.override) then
		override = INDEX[opts.override]
	end
	current = override or autoTier

	function self.get(): Tier
		return FidelityTier.TIERS[current] :: Tier
	end

	function self.settings()
		return SETTINGS[FidelityTier.TIERS[current]]
	end

	-- Fires listener(newTier, oldTier, settings). Returns a disconnect function.
	function self.onChanged(listener: (string, string, any) -> ()): () -> ()
		table.insert(listeners, listener)
		return function()
			local index = table.find(listeners, listener)
			if index then
				table.remove(listeners, index)
			end
		end
	end

	-- Saved quality setting: a tier name caps auto; nil or "Otomatis" removes the cap.
	function self.setSetting(setting: any)
		applySetting(setting)
		resetWindow()
		apply()
	end

	-- Manual override: a tier name forces it; nil or "Otomatis" hands control back to auto.
	function self.setOverride(value: any)
		override = if FidelityTier.isTier(value) then INDEX[value] else nil
		apply()
	end

	function self.getOverride(): string?
		return if override then FidelityTier.TIERS[override] else nil
	end

	function self.beginMoment()
		moments += 1
	end

	function self.endMoment()
		if moments > 0 then
			moments -= 1
		end
		if moments == 0 then
			apply()
		end
	end

	function self.isLocked(): boolean
		return moments > 0
	end

	-- Rolling average of the recent clean frame times, or nil until MIN_SAMPLES.
	function self.average(): number?
		if #samples < MIN_SAMPLES then
			return nil
		end
		return sampleSum / #samples
	end

	-- Feed one frame time (seconds). Bad values are ignored.
	function self.step(dt: any)
		local clean = FidelityTier.cleanFrameTime(dt)
		if not clean then
			return
		end
		table.insert(samples, clean)
		sampleSum += clean
		if #samples > WINDOW_SIZE then
			sampleSum -= table.remove(samples, 1)
		end

		local average = self.average()
		if not average or override or moments > 0 then
			return
		end

		local now = clock()
		if average > DOWN_FRAME_TIME then
			goodSince = nil
			if autoTier > 1 and now - lastChange >= DOWN_COOLDOWN then
				autoTier -= 1
				apply()
			end
		elseif average < UP_FRAME_TIME then
			goodSince = goodSince or now
			if autoTier < ceiling and now - goodSince >= UP_SUSTAIN and now - lastChange >= UP_COOLDOWN then
				autoTier += 1
				apply()
			end
		else
			goodSince = nil -- in the dead band: neither bad nor good
		end
	end

	return self
end

return FidelityTier
