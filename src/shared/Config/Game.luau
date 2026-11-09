-- Global game tuning (GDD §3, §7). Shared so the client can show prices.

local Game = {}

Game.startCash = 50
Game.startSeeds = { padi = 5 }
Game.startTiles = 6
Game.maxTiles = 12 -- Extra Plot pass (week 5) raises this to 16
Game.tileColumns = 4

Game.plotCount = 10
Game.plotRadius = 90 -- studs from village center

Game.interactDistance = 16 -- server-side distance check for tiles/NPCs
Game.autoQuality = 0.9 -- week 1: everything uses Auto quality (minigames come in week 2)

-- Price of the NEXT tile when you already own `owned` tiles.
function Game.tilePrice(owned: number): number
	return 100 * 2 ^ (owned - Game.startTiles)
end

-- Ranks, in order. Requirements are checked by the server (EconomyService).
Game.rankOrder = { "gurem", "petani", "juragan" }
Game.rankIndex = { gurem = 1, petani = 2, juragan = 3 }
Game.rankRequirements = {
	petani = { lifetimeEarned = 1000, tilesOwned = 0 },
	juragan = { lifetimeEarned = 10000, tilesOwned = 12 },
}

Game.maxSeedBuy = 50 -- max seeds per purchase click

return Game
