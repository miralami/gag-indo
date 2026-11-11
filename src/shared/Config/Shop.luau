-- Toko Bibit rotating stock (v2 PLAN §3.4). Values are starting points for the balance sheet.
--
-- Stock is per player and deterministic per restock cycle: `ShopStock.roll(cycle, userId, musim)`
-- always returns the same shelves for the same inputs, so a rejoin or a server restart can never
-- refresh the shop for free. Only time (the next cycle) or a paid Restock changes it.
--
-- `chanceBySeason` is the chance that a family appears at all; `rareChance` scales individual
-- crops inside their family so durian/sawit stay a find. `familyAmount` scales the stack size.

local Shop = {}

Shop.restockSeconds = 180 -- a new shelf every 3 minutes

Shop.amountMin = 2
Shop.amountMax = 7

Shop.chanceBySeason = {
	hujan = { palawija = 1.0, kebun = 0.55, perkebunan = 0.12 },
	kemarau = { palawija = 0.85, kebun = 0.35, perkebunan = 0.08 },
	pancaroba = { palawija = 1.0, kebun = 0.45, perkebunan = 0.10 },
}

Shop.rareChance = {
	durian = 0.2,
	sawit = 0.15,
	cengkeh = 0.55,
	kakao = 0.75,
}

Shop.familyAmount = {
	palawija = 1.0,
	kebun = 0.8,
	perkebunan = 0.5,
}

-- Always on the shelf, so a new player can never be stranded without a seed.
Shop.always = { padi = true }

-- Amount multiplier for the always-on crop (padi fills the shelf).
Shop.alwaysAmount = 1.4

return Shop
