--!strict
-- ModelMapSoundsR8: PURE data for WORK_QUEUE section M item 92 (`sounds_r8`, ambient sound beds).
-- Six real FREE Creator Store audio assets, verified loading in both Client and Server Play VMs on
-- 2026-11-21 and recorded in docs/v2/visual/art/ASSET_MANIFEST.md. No engine API, no Instance,
-- no Enum, no asset URL string: the applier builds SoundId from each numeric id at apply time.
--
-- Time slots: jangkrik is a NIGHT bed; ayam and birds are DAY beds; river and wind play ALWAYS.
-- kentongan is an occasional event bed (looped, so the designer can audition it while enabled).
-- Every volume is <= 0.5 and every rollOffMax <= 80: never full volume, never an unbounded bed.
-- The harness SOUND_LOADED check waits at most LOAD_TIMEOUT_S seconds for every IsLoaded flag;
-- Roblox exposes no "not authorized" signal, so a bed that never loads is the only available proxy.

local Data = {}

Data.id = "sounds_r8"
Data.lookDevId = "sounds_r8"
Data.folder = "LookDevSoundsR8_sounds_r8"
Data.groupName = "JD_sounds_r8"

Data.MAX_VOLUME = 0.5
Data.MAX_ROLLOFF = 80
Data.LOAD_TIMEOUT_S = 10
Data.ROLLOFF_MIN = 4

Data.BEDS = {
	{
		key = "jangkrik",
		id = 9114894498,
		name = "Jungle Insects 1 (SFX)",
		creator = "ProSoundEffects",
		timeSlot = "night",
		volume = 0.3,
		rollOffMax = 60,
		position = { x = -100, y = 2.5, z = -24 },
		looped = true,
	},
	{
		key = "ayam",
		id = 9114370190,
		name = "Farm Animals Dog Barking Rooster Crows 2 (SFX)",
		creator = "ProSoundEffects",
		timeSlot = "day",
		volume = 0.28,
		rollOffMax = 40,
		position = { x = 84, y = 2.5, z = -44 },
		looped = true,
	},
	{
		key = "birds",
		id = 9112750044,
		name = "Birds Quiet And Tranquil 1 (SFX)",
		creator = "ProSoundEffects",
		timeSlot = "day",
		volume = 0.22,
		rollOffMax = 72,
		position = { x = -40, y = 2.5, z = -92 },
		looped = true,
	},
	{
		key = "river",
		id = 9118187543,
		name = "River Water 1 (SFX)",
		creator = "ProSoundEffects",
		timeSlot = "always",
		volume = 0.4,
		rollOffMax = 80,
		position = { x = 0, y = 2.5, z = 304 },
		looped = true,
	},
	{
		key = "wind",
		id = 116565742544806,
		name = "The Wind (Ambience Version)",
		creator = "APMOfficial",
		timeSlot = "always",
		volume = 0.24,
		rollOffMax = 80,
		position = { x = 120, y = 2.5, z = 120 },
		looped = true,
	},
	{
		key = "kentongan",
		id = 9046655769,
		name = "Oriental Gong 4 - Remastered",
		creator = "APMOfficial",
		timeSlot = "always",
		volume = 0.35,
		rollOffMax = 48,
		position = { x = -108, y = 2.5, z = 12 },
		looped = true,
	},
}

Data.bedOrder = { "jangkrik", "ayam", "birds", "river", "wind", "kentongan" }

function Data.bedFor(key: string): any?
	for _, bed in ipairs(Data.BEDS) do
		if bed.key == key then
			return bed
		end
	end
	return nil
end

function Data.idFor(key: string): number?
	local bed = Data.bedFor(key)
	return if bed then bed.id else nil
end

return Data
