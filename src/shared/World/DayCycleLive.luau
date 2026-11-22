--!strict
-- Pure plan for the OFF-BY-DEFAULT "day_cycle" LookDev candidate (WORK_QUEUE round 3 item 25).
-- No Roblox services: the client adapter owns Heartbeat, Tweens and Instances. This module only
-- reuses DayCycle (presetFor / phaseInfo / ADZAN_SETTING_KEY) and never mutates it.

local DayCycle = require(script.Parent.DayCycle)
local AdzanSetting = require(script.Parent.Parent.Settings.AdzanSetting)

local DayCycleLive = {}

DayCycleLive.ID = "day_cycle"
DayCycleLive.MIN_TWEEN_SECONDS = 20
DayCycleLive.MAX_TWEEN_SECONDS = 40

DayCycleLive.SOUND_BEDS = { "ayam", "bedug", "kentongan", "jangkrik", "adzan" }

local BED_SET: { [string]: boolean } = {}
for _, name in ipairs(DayCycleLive.SOUND_BEDS) do
	BED_SET[name] = true
end

function DayCycleLive.isSoundBed(value: any): boolean
	return type(value) == "string" and BED_SET[value] == true
end

-- The five beds are silent until licensed IDs are supplied: their Config/Audio slots use id 0.
-- Phase -> beds is data only; the adapter never invents an asset ID for any of them.
local BEDS_BY_PHASE: { [string]: { [string]: boolean } } = {
	dini_hari = { jangkrik = true },
	subuh = { ayam = true, bedug = true, adzan = true },
	pagi = { ayam = true },
	dhuha = {},
	siang_bolong = {},
	sore = {},
	maghrib = { bedug = true, adzan = true },
	malam = { kentongan = true, jangkrik = true },
}

-- Night is clock 19:00 = 180 s from the 16:00 spawn. Rendah is the ceiling for this candidate.
local NIGHT_ELAPSED = (19 - DayCycle.START_CLOCK) * DayCycle.SECONDS_PER_GAME_HOUR
local RENDAH_PRESET = DayCycle.presetFor(NIGHT_ELAPSED, nil, "Rendah")

local LAMP_POSITIONS = {
	{ -16, 3.2, 24 },
	{ 16, 3.2, 24 },
	{ -16, 3.2, 8 },
	{ 16, 3.2, 8 },
	{ 0, 3.2, 4 },
	{ 0, 3.2, 40 },
}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function whole(value: any, fallback: number): number
	return if finite(value) then math.floor(value) else fallback
end

local function copy3(list: { number }): { number }
	return { list[1], list[2], list[3] }
end

-- 20..40 s, no exceptions: a damaged phase falls back to the lower bound.
function DayCycleLive.tweenSeconds(elapsedSeconds: any): number
	local seconds = DayCycle.phaseInfo(elapsedSeconds).transitionSeconds
	if not finite(seconds) then
		return DayCycleLive.MIN_TWEEN_SECONDS
	end
	return math.clamp(seconds, DayCycleLive.MIN_TWEEN_SECONDS, DayCycleLive.MAX_TWEEN_SECONDS)
end

-- Fresh array in registry order; unknown phases get no beds.
function DayCycleLive.soundBedsFor(elapsedSeconds: any): { string }
	local active = BEDS_BY_PHASE[DayCycle.phaseInfo(elapsedSeconds).id] or {}
	local out: { string } = {}
	for _, name in ipairs(DayCycleLive.SOUND_BEDS) do
		if active[name] then
			table.insert(out, name)
		end
	end
	return out
end

-- Rendah ceiling: at most six non-shadow lights, even if a higher tier is requested.
function DayCycleLive.lampBudget(tier: any): {
	maxLights: number,
	shadowLights: number,
	intensity: number,
	range: number,
}
	local preset = DayCycle.presetFor(NIGHT_ELAPSED, nil, tier)
	return {
		maxLights = math.clamp(whole(preset.maxLights, RENDAH_PRESET.maxLights), 0, RENDAH_PRESET.maxLights),
		shadowLights = math.clamp(
			whole(preset.shadowLights, RENDAH_PRESET.shadowLights),
			0,
			RENDAH_PRESET.shadowLights
		),
		intensity = 0.45,
		range = 14,
	}
end

-- The exact grade the adapter applies: season/weather base, then DayCycle on top.
function DayCycleLive.preset(elapsedSeconds: any, seasonPreset: any, tier: any): any
	return DayCycle.presetFor(elapsedSeconds, seasonPreset, tier)
end

function DayCycleLive.lampPositions(): { { number } }
	local out = {}
	for _, position in ipairs(LAMP_POSITIONS) do
		table.insert(out, copy3(position))
	end
	return out
end

-- Fresh plan per call. The applier ignores the LookDev-supplied plan until main adds the candidate.
function DayCycleLive.plan(): any
	return {
		id = DayCycleLive.ID,
		tweenSeconds = {
			min = DayCycleLive.MIN_TWEEN_SECONDS,
			max = DayCycleLive.MAX_TWEEN_SECONDS,
		},
		soundBeds = table.clone(DayCycleLive.SOUND_BEDS),
		adzan = {
			settingKey = AdzanSetting.KEY,
			defaultOn = AdzanSetting.DEFAULT_ON,
			volume = AdzanSetting.VOLUME,
		},
		lampBudget = DayCycleLive.lampBudget(nil),
		lampPositions = DayCycleLive.lampPositions(),
		reviewCamera = {
			position = { 0, 12, 52 },
			lookAt = { 0, 3, -20 },
		},
	}
end

return DayCycleLive
