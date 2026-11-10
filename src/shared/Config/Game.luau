-- Global game tuning (GDD §3, §7). Shared so the client can show prices.

local Game = {}

Game.startCash = 50
Game.startSeeds = { padi = 5 }
Game.startTiles = 6
Game.maxTiles = 12 -- without the Extra Plot pass
Game.maxTilesWithPass = 16 -- Extra Plot pass (4 more)
Game.tileColumns = 4
Game.tilesBuilt = 16 -- every plot model is built for the max, pass or not

Game.plotCount = 10
Game.plotRadius = 90 -- studs from village center

Game.interactDistance = 16 -- server-side distance check for tiles/NPCs
Game.npcDistance = 18 -- Pak RT / Pos Polisi
Game.autoQuality = 0.9

-- Minigames (GDD §3.3, TECH.md §5)
Game.minigameMinSeconds = 0.8 -- a Farm_Complete faster than this is ignored (3 quick taps are OK)
Game.minigameMaxSeconds = 30
Game.autoRatePerSecond = 2

-- Price of the NEXT tile when you already own `owned` tiles.
function Game.tilePrice(owned: number): number
	return 100 * 2 ^ math.max(0, owned - Game.startTiles)
end

-- Ranks, in order. Requirements are checked by RankService.
Game.rankOrder = { "gurem", "petani", "juragan" }
Game.rankIndex = { gurem = 1, petani = 2, juragan = 3 }
Game.rankRequirements = {
	petani = { lifetimeEarned = 1000, tilesOwned = 0 },
	juragan = { lifetimeEarned = 10000, tilesOwned = 12 },
}

Game.maxSeedBuy = 50 -- max seeds per purchase click

-- Storage (v2 PLAN §3.4). The sack is carried; the gudang is the big store.
Game.gudangBaseCapacity = 40
Game.gudangPassCapacity = 120

-- Replicated structured state (v2 PLAN §7.1): section patches are coalesced this often.
Game.statePatchInterval = 0.25

-- Rarity (v2 PLAN §3.2): minigame quality nudges the roll. Each point of quality above
-- zero adds this much weight to the rare tiers (super and up); 1.0 roughly doubles them.
Game.rarityQualityBoost = 1

-- Harga Cabai Meroket (GDD §3.2): cabai sells x3 for a few minutes, on a loop.
-- Short values keep it testable in Studio; raise them before publishing.
Game.cabaiEventFirstDelay = 240 -- seconds after the servers starts
Game.cabaiEventInterval = 600 -- between the start of one event and the next
Game.cabaiEventDuration = 300 -- how long the multiplier lasts
Game.cabaiEventMultiplier = 3

return Game
