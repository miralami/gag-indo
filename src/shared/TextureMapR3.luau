--!strict
-- TextureMapR3: real CC0 Poly Haven PBR sets for the OFF-BY-DEFAULT "textures_r3"
-- LookDev candidate (WORK_QUEUE round 3 items 20/21). All 27 IDs were returned by
-- ROBLOX_API_KEY -> Open Cloud POST /assets/v1/assets and recorded in
-- docs/v2/visual/art/textures_r3/upload_manifest.json + ASSET_MANIFEST.md. None is
-- approved or shipped on by default. The IDs live here, not in LookDev or its
-- adapter, so the "no asset IDs in LookDev" guard still holds.
--
-- Colour is OpenGL tangent-space normal (nor_gl), roughness is the Poly Haven Rough
-- map. Every source file is 1024x1024 and CC0 with author recorded in the manifest.

local TextureMapR3 = {}

TextureMapR3.ids = {
	cobblestone_floor_01_diff = 74744016196476,
	cobblestone_floor_01_nor = 110226485663162,
	cobblestone_floor_01_rough = 138531745001215,
	stony_dirt_path_diff = 80034871262278,
	stony_dirt_path_nor = 78151682245075,
	stony_dirt_path_rough = 136294167944729,
	brown_mud_03_diff = 118458951573479,
	brown_mud_03_nor = 114355009654625,
	brown_mud_03_rough = 128285016910005,
	farm_furrows_diff = 73024027131833,
	farm_furrows_nor = 83316497417973,
	farm_furrows_rough = 70948754520311,
	river_small_rocks_diff = 71705724488696,
	river_small_rocks_nor = 131394824179214,
	river_small_rocks_rough = 121037425917541,
	bamboo_wall_diff = 129038060876960,
	bamboo_wall_nor = 136304309254898,
	bamboo_wall_rough = 138535778061241,
	clay_roof_tiles_02_diff = 83414482593923,
	clay_roof_tiles_02_nor = 109796656706355,
	clay_roof_tiles_02_rough = 105143056428348,
	corrugated_iron_diff = 92821229855906,
	corrugated_iron_nor = 126844497648318,
	corrugated_iron_rough = 113205619789050,
	wood_planks_diff = 71303695104901,
	wood_planks_nor = 116521049280771,
	wood_planks_rough = 107767666486100,
}

-- Nine MaterialVariants, each backed by three real maps. BaseMaterial is a built-in
-- Roblox material name so LookDev's no-asset-material guard still holds.
TextureMapR3.variants = {
	paving = {
		name = "R3_Cobblestone",
		baseMaterial = "Cobblestone",
		diff = "cobblestone_floor_01_diff",
		nor = "cobblestone_floor_01_nor",
		rough = "cobblestone_floor_01_rough",
	},
	tanah = {
		name = "R3_DirtPath",
		baseMaterial = "Ground",
		diff = "stony_dirt_path_diff",
		nor = "stony_dirt_path_nor",
		rough = "stony_dirt_path_rough",
	},
	sawah = {
		name = "R3_SawahMud",
		baseMaterial = "Grass",
		diff = "brown_mud_03_diff",
		nor = "brown_mud_03_nor",
		rough = "brown_mud_03_rough",
	},
	pematang = {
		name = "R3_Pematang",
		baseMaterial = "Mud",
		diff = "farm_furrows_diff",
		nor = "farm_furrows_nor",
		rough = "farm_furrows_rough",
	},
	river_bank = {
		name = "R3_RiverBank",
		baseMaterial = "Rock",
		diff = "river_small_rocks_diff",
		nor = "river_small_rocks_nor",
		rough = "river_small_rocks_rough",
	},
	bambu = {
		name = "R3_Bamboo",
		baseMaterial = "Wood",
		diff = "bamboo_wall_diff",
		nor = "bamboo_wall_nor",
		rough = "bamboo_wall_rough",
	},
	genteng = {
		name = "R3_ClayRoof",
		baseMaterial = "Slate",
		diff = "clay_roof_tiles_02_diff",
		nor = "clay_roof_tiles_02_nor",
		rough = "clay_roof_tiles_02_rough",
	},
	seng = {
		name = "R3_CorrugatedIron",
		baseMaterial = "Metal",
		diff = "corrugated_iron_diff",
		nor = "corrugated_iron_nor",
		rough = "corrugated_iron_rough",
	},
	wood = {
		name = "R3_WoodPlanks",
		baseMaterial = "WoodPlanks",
		diff = "wood_planks_diff",
		nor = "wood_planks_nor",
		rough = "wood_planks_rough",
	},
}

-- Part-name keyword -> variant slot. Deliberately conservative: unknown MeshParts
-- keep their shipping material while the candidate is enabled.
TextureMapR3.categorySlots = {
	river = "river_bank",
	pematang = "pematang",
	road = "paving",
	ground = "tanah",
	field = "sawah",
	bamboo = "bambu",
	roof = "genteng",
	metal = "seng",
	wood = "wood",
}

function TextureMapR3.slotCount(): number
	local n = 0
	for _ in TextureMapR3.variants do
		n += 1
	end
	return n
end

function TextureMapR3.assetUrl(key: string): string?
	local id = TextureMapR3.ids[key]
	return if id then "rbxassetid://" .. id else nil
end

return TextureMapR3
