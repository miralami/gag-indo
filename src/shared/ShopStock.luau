-- ShopStock: the deterministic Toko Bibit shelves (v2 PLAN §3.4).
--
-- Pure module: no Roblox APIs and no `math.random`, so the same (cycle, userId, season) always
-- rolls the same stock. A rejoin or a server restart therefore cannot refresh the shop; only the
-- next restock cycle or a paid Restock can.
--
-- The rng is a Lehmer LCG (48271, 2^31-1). All products stay below 2^53, so double arithmetic is
-- exact on Roblox and in Lune.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local Shop = require(Shared.Config.Shop)

local ShopStock = {}

local MOD = 2147483647

local function nextSeed(seed: number): number
	return (seed * 48271) % MOD
end

-- Which restock window a timestamp belongs to.
function ShopStock.cycle(now: number): number
	return math.floor(now / Shop.restockSeconds)
end

-- When the next window starts (unix seconds).
function ShopStock.restockAt(cycle: number): number
	return (cycle + 1) * Shop.restockSeconds
end

-- Chance that one crop appears this cycle. `always` crops are guaranteed.
function ShopStock.chance(cropId: string, musim: string?): number
	local crop = Crops.list[cropId]
	if not crop then
		return 0
	end
	if Shop.always[cropId] then
		return 1
	end
	local bySeason = Shop.chanceBySeason[musim or ""] or Shop.chanceBySeason.pancaroba
	local base = bySeason[crop.family] or 0
	return math.clamp(base * (Shop.rareChance[cropId] or 1), 0, 1)
end

-- Maximum stack size for one crop, after the family/always scaling.
function ShopStock.maxAmount(cropId: string): number
	local crop = Crops.list[cropId]
	if not crop then
		return Shop.amountMin
	end
	local scale = if Shop.always[cropId] then Shop.alwaysAmount else (Shop.familyAmount[crop.family] or 1)
	return math.max(Shop.amountMin, math.floor(Shop.amountMax * scale + 0.5))
end

-- The shelves for one restock cycle. Returns { [cropId] = amount } with absent = not stocked.
function ShopStock.roll(cycle: number, userId: number, musim: string?): { [string]: number }
	local seed = (cycle * 48271 + math.abs(userId or 0) % MOD) % MOD
	local stock = {}
	for _, cropId in Crops.order do
		seed = nextSeed(seed)
		local chanceRoll = seed / MOD
		seed = nextSeed(seed)
		local amountRoll = seed / MOD

		if chanceRoll < ShopStock.chance(cropId, musim) then
			local min = Shop.amountMin
			local max = ShopStock.maxAmount(cropId)
			stock[cropId] = min + math.floor(amountRoll * (max - min + 1))
		end
	end
	return stock
end

-- True when a saved shop belongs to an earlier cycle and must be rolled again.
function ShopStock.isDue(shop: any, now: number): boolean
	return type(shop) ~= "table" or shop.cycle ~= ShopStock.cycle(now)
end

return ShopStock
