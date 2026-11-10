-- Crop balance table (GDD §3.2, v2 PLAN §3.2). Edit numbers here to rebalance.
--
--   family     palawija (fast, one harvest) · kebun (slow, re-harvests) · perkebunan (permit)
--   rank       minimum rank needed to buy/plant this crop
--   regrowSeconds / maxHarvests
--              kebun and perkebunan keep producing after the first harvest; nil = one-shot
--   permit     true means the Balai Desa must issue a permit first (M2 wires the check)
--
-- `order` is sorted by growSeconds ascending: config_spec checks that display order matches
-- grow time, and the seed bar reads it left to right.

export type Crop = {
	seedCost: number,
	growSeconds: number,
	sellPrice: number,
	rank: string,
	color: Color3,
	family: string,
	regrowSeconds: number?,
	maxHarvests: number?,
	permit: boolean?,
}

local Crops = {}

Crops.order = {
	"padi",
	"singkong",
	"jagung",
	"bawang",
	"cabai",
	"tembakau",
	"kopi",
	"tebu",
	"kakao",
	"cengkeh",
	"durian",
	"sawit",
}

Crops.list = {
	padi = {
		seedCost = 10,
		growSeconds = 60,
		sellPrice = 18,
		rank = "gurem",
		color = Color3.fromRGB(214, 196, 92),
		family = "palawija",
	},
	singkong = {
		seedCost = 16,
		growSeconds = 90,
		sellPrice = 30,
		rank = "gurem",
		color = Color3.fromRGB(180, 150, 96),
		family = "palawija",
	},
	jagung = {
		seedCost = 25,
		growSeconds = 120,
		sellPrice = 50,
		rank = "petani",
		color = Color3.fromRGB(240, 200, 40),
		family = "palawija",
	},
	bawang = {
		seedCost = 35,
		growSeconds = 150,
		sellPrice = 72,
		rank = "petani",
		color = Color3.fromRGB(196, 120, 160),
		family = "palawija",
	},
	cabai = {
		seedCost = 60,
		growSeconds = 240,
		sellPrice = 140,
		rank = "petani",
		color = Color3.fromRGB(210, 40, 30),
		family = "palawija",
	},
	tembakau = {
		seedCost = 80,
		growSeconds = 480,
		sellPrice = 200,
		rank = "petani",
		color = Color3.fromRGB(150, 110, 50),
		family = "kebun",
		regrowSeconds = 240,
		maxHarvests = 3,
	},
	kopi = {
		seedCost = 110,
		growSeconds = 600,
		sellPrice = 280,
		rank = "petani",
		color = Color3.fromRGB(110, 70, 40),
		family = "kebun",
		regrowSeconds = 300,
		maxHarvests = 4,
	},
	tebu = {
		seedCost = 150,
		growSeconds = 720,
		sellPrice = 380,
		rank = "juragan",
		color = Color3.fromRGB(160, 190, 90),
		family = "perkebunan",
		regrowSeconds = 360,
		maxHarvests = 3,
		permit = true,
	},
	kakao = {
		seedCost = 180,
		growSeconds = 780,
		sellPrice = 460,
		rank = "juragan",
		color = Color3.fromRGB(120, 80, 50),
		family = "kebun",
		regrowSeconds = 390,
		maxHarvests = 3,
	},
	cengkeh = {
		seedCost = 220,
		growSeconds = 840,
		sellPrice = 560,
		rank = "juragan",
		color = Color3.fromRGB(140, 90, 120),
		family = "kebun",
		regrowSeconds = 420,
		maxHarvests = 3,
	},
	durian = {
		seedCost = 300,
		growSeconds = 900,
		sellPrice = 900,
		rank = "juragan",
		color = Color3.fromRGB(120, 140, 40),
		family = "kebun",
		regrowSeconds = 450,
		maxHarvests = 3,
	},
	sawit = {
		seedCost = 420,
		growSeconds = 1200,
		sellPrice = 1300,
		rank = "juragan",
		color = Color3.fromRGB(200, 90, 30),
		family = "perkebunan",
		regrowSeconds = 600,
		maxHarvests = 4,
		permit = true,
	},
} :: { [string]: Crop }

-- Family membership, derived from `list` so there is one source of truth.
Crops.families = { palawija = {}, kebun = {}, perkebunan = {} }
for cropId, crop in Crops.list do
	local family = Crops.families[crop.family]
	if family then
		table.insert(family, cropId)
	end
end
for _, crops in Crops.families do
	table.sort(crops)
end

Crops.familyOrder = { "palawija", "kebun", "perkebunan" }

function Crops.exists(cropId: any): boolean
	return type(cropId) == "string" and Crops.list[cropId] ~= nil
end

function Crops.isRegrow(crop: Crop): boolean
	return crop.regrowSeconds ~= nil
end

return Crops
