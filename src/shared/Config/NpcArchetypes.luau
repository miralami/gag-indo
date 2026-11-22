--!strict
-- NPC archetypes from docs/v2/visual/art/npcs.md (caricature design cards).
-- Logic/data only: no assets, no audio files. Palette tokens are from Config/Visuals.

local NpcArchetypes = {}

NpcArchetypes.palette = { "tinta", "bambu", "kunyit", "malam", "genteng", "padi", "kertas", "indigo" }

NpcArchetypes.order = { "pakrt", "tengkulak", "polisi" }

NpcArchetypes.list = {
	pakrt = {
		id = "pakrt",
		displayName = "Pak RT",
		silhouette = "Broad torso, tall peci",
		exaggeratedFeature = "Large moustache",
		accessory = "Peci + clipboard",
		outfit = { "bambu", "kunyit", "tinta" },
		voice = "Warm, procedural, nosy",
	},
	tengkulak = {
		id = "tengkulak",
		displayName = "Tengkulak",
		silhouette = "Forward-leaning, narrow shoulders",
		exaggeratedFeature = "Heavy brow",
		accessory = "Sling pouch",
		outfit = { "tinta", "genteng", "bambu" },
		voice = "Quiet, bargaining cadence",
	},
	polisi = {
		id = "polisi",
		displayName = "Polisi Desa",
		silhouette = "Upright, squared stance",
		exaggeratedFeature = "Oversized cap",
		accessory = "Fictional dark-blue badge",
		outfit = { "malam", "indigo", "kertas" },
		voice = "Formal, generic fictional authority",
	},
}

function NpcArchetypes.get(id: string)
	return NpcArchetypes.list[id]
end

function NpcArchetypes.isFictionalCaricature(id: string): boolean
	return NpcArchetypes.list[id] ~= nil
end

return NpcArchetypes
