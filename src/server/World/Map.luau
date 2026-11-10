-- Map: the contract between the designer's place file and the code (v2 PLAN §3.1).
--
-- The designer builds in Studio and tags things; code finds them here. The greybox builder
-- emits the same tags, so the game runs with or without the real map.
--
--   VillageWorld   the designer's world root (Model or Folder). Presence = real map.
--   PlayerSpawn    the SpawnLocation players should use.
--   PasarPrompt    ProximityPrompt on the Pasar counter.
--   GelapPrompt    ProximityPrompt at the Tengkulak Gelap.
--   PakRTPrompt    ProximityPrompt at Pak RT.
--   PolisiPrompt   ProximityPrompt at the police post.
--   WarungPrompt   ProximityPrompt at the warung.
--   RondaAnchor    BasePart: centre of the guard post cell (jail teleport).
--   PlotAnchor     BasePart with attribute PlotIndex (1..plotCount); -Z faces the entrance.
--   NpcSpawn       Model with attribute Npc = "pakrt" | "tengkulak" | "polisi".
--   Tile           plot tile (PlotService adds this; the client finds tiles by it).
--   GreyboxWorld   marker on a generated world so a Studio re-run can replace it safely.

local CollectionService = game:GetService("CollectionService")

local Map = {}

Map.TAGS = {
	World = "VillageWorld",
	Greybox = "GreyboxWorld",
	PlayerSpawn = "PlayerSpawn",
	Pasar = "PasarPrompt",
	Gelap = "GelapPrompt",
	PakRT = "PakRTPrompt",
	Polisi = "PolisiPrompt",
	Warung = "WarungPrompt",
	Ronda = "RondaAnchor",
	PlotAnchor = "PlotAnchor",
	Npc = "NpcSpawn",
	Tile = "Tile",
}

function Map.all(tag: string): { Instance }
	return CollectionService:GetTagged(tag)
end

function Map.has(tag: string): boolean
	return #CollectionService:GetTagged(tag) > 0
end

function Map.first(tag: string): Instance?
	local tagged = CollectionService:GetTagged(tag)
	return tagged[1]
end

function Map.add(instance: Instance, tag: string)
	CollectionService:AddTag(instance, tag)
end

-- True when the place file already contains a real map (designer world or plot anchors).
function Map.isDesignerWorld(): boolean
	return Map.has(Map.TAGS.World) or Map.has(Map.TAGS.PlotAnchor)
end

return Map
