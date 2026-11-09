-- Crop balance table (GDD §3.2). Edit numbers here to rebalance.
-- rank = minimum rank needed to buy/plant this crop.

export type Crop = {
	seedCost: number,
	growSeconds: number,
	sellPrice: number,
	rank: string,
	color: Color3,
}

local Crops = {}

Crops.order = { "padi", "jagung", "cabai", "durian" }

Crops.list = {
	padi = {
		seedCost = 10,
		growSeconds = 60,
		sellPrice = 18,
		rank = "gurem",
		color = Color3.fromRGB(214, 196, 92),
	},
	jagung = {
		seedCost = 25,
		growSeconds = 120,
		sellPrice = 50,
		rank = "petani",
		color = Color3.fromRGB(240, 200, 40),
	},
	cabai = {
		seedCost = 60,
		growSeconds = 240,
		sellPrice = 140,
		rank = "petani",
		color = Color3.fromRGB(210, 40, 30),
	},
	durian = {
		seedCost = 300,
		growSeconds = 900,
		sellPrice = 900,
		rank = "juragan",
		color = Color3.fromRGB(120, 140, 40),
	},
} :: { [string]: Crop }

return Crops
