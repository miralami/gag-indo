-- Sound registry (v2 PLAN §3.1). Every id stays `0` until a licensed asset exists.
--
-- `client/Audio.luau` reads this table, creates a Sound for every entry with `id > 0` and
-- silently skips the rest — so shipping with no audio is a data state, not a code change.
-- Licensing (D8): use Roblox's licensed catalogue, original recordings or generated music whose
-- terms allow commercial use. Do not upload commercial tracks.
--
--   group   music | ambience | ui | sting
--   looped  music and ambience loop; ui and stings play once
--   volume  0..1, multiplied by the group volume

local Audio = {}

Audio.groups = {
	music = 0.45,
	ambience = 0.5,
	ui = 0.7,
	sting = 0.85,
}

Audio.defaultMusic = "music_desa"

-- Music per hub. The client switches when the player enters a `MusicZone`-tagged part that
-- carries a `Music` attribute naming one of these keys.
Audio.areas = {
	desa = "music_desa",
	pasar = "music_pasar",
	sawah = "music_sawah",
	hutan = "music_hutan",
}

-- Ambience follows the `Cuaca` attribute published by SeasonService.
Audio.weather = {
	cerah = "ambience_cerah",
	hujan = "ambience_hujan",
	badai = "ambience_badai",
	kabut = "ambience_kabut",
}

Audio.sounds = {
	-- music
	music_desa = { group = "music", id = 0, looped = true, volume = 0.35 },
	music_pasar = { group = "music", id = 0, looped = true, volume = 0.35 },
	music_sawah = { group = "music", id = 0, looped = true, volume = 0.3 },
	music_hutan = { group = "music", id = 0, looped = true, volume = 0.3 },

	-- ambience
	ambience_cerah = { group = "ambience", id = 0, looped = true, volume = 0.25 },
	ambience_hujan = { group = "ambience", id = 0, looped = true, volume = 0.35 },
	ambience_badai = { group = "ambience", id = 0, looped = true, volume = 0.45 },
	ambience_kabut = { group = "ambience", id = 0, looped = true, volume = 0.2 },

	-- ui
	ui_click = { group = "ui", id = 0, volume = 0.5 },
	ui_open = { group = "ui", id = 0, volume = 0.5 },
	ui_close = { group = "ui", id = 0, volume = 0.5 },
	ui_buy = { group = "ui", id = 0, volume = 0.6 },
	ui_sell = { group = "ui", id = 0, volume = 0.6 },

	-- stings
	sting_rare = { group = "sting", id = 0, volume = 0.7 },
	sting_sultan = { group = "sting", id = 0, volume = 0.9 },
	sting_almanak = { group = "sting", id = 0, volume = 0.7 },
	sting_rankup = { group = "sting", id = 0, volume = 0.8 },
	sting_raid = { group = "sting", id = 0, volume = 1 },
	sting_jail = { group = "sting", id = 0, volume = 0.8 },
}

function Audio.exists(key: any): boolean
	return type(key) == "string" and Audio.sounds[key] ~= nil
end

-- True when at least one entry has a real Roblox asset id.
function Audio.configured(): boolean
	for _, def in Audio.sounds do
		if type(def.id) == "number" and def.id > 0 then
			return true
		end
	end
	return false
end

return Audio
