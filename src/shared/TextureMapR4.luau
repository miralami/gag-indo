--!strict
-- TextureMapR4: real CC0 1K PBR sets for the OFF-BY-DEFAULT "textures_r4"
-- LookDev candidate (WORK_QUEUE item 29). All 36 IDs were returned by completed
-- ROBLOX_API_KEY -> Open Cloud POST /assets/v1/assets operations and recorded in
-- docs/v2/visual/art/textures_r4/upload_manifest.json + MANIFEST.md. None is
-- approved or shipped on by default.
--
-- Pure data: no Roblox API is touched at load. The applier reads ids only through
-- assetUrl(), so no asset ID literal appears in LookDev or its adapter. One
-- MaterialVariant per built-in base material; normal maps are OpenGL (nor_gl /
-- NormalGL), colour is Diffuse / Color, roughness is Rough / Roughness.

local TextureMapR4 = {}

TextureMapR4.ids = {
	withered_grass_diff = 99291006551629,
	withered_grass_nor = 94138101324824,
	withered_grass_rough = 99517618599796,
	red_laterite_soil_stones_diff = 118381151358037,
	red_laterite_soil_stones_nor = 80566522516796,
	red_laterite_soil_stones_rough = 121928219739643,
	Ground026_diff = 140414409206785,
	Ground026_nor = 134530197365596,
	Ground026_rough = 138244821682090,
	cobblestone_floor_04_diff = 116548637306757,
	cobblestone_floor_04_nor = 114728267211735,
	cobblestone_floor_04_rough = 126631905530342,
	weathered_planks_diff = 86925714541020,
	weathered_planks_nor = 139064505550988,
	weathered_planks_rough = 79209250273792,
	bamboo_wall_02_diff = 104761377140093,
	bamboo_wall_02_nor = 75163422713451,
	bamboo_wall_02_rough = 137065390077687,
	worn_brick_wall_diff = 101964656212261,
	worn_brick_wall_nor = 74037970278315,
	worn_brick_wall_rough = 79001558852046,
	blue_plaster_weathered_diff = 139342078063430,
	blue_plaster_weathered_nor = 111912632127012,
	blue_plaster_weathered_rough = 125017038971785,
	clay_roof_tiles_03_diff = 103194041286294,
	clay_roof_tiles_03_nor = 139690368710650,
	clay_roof_tiles_03_rough = 128237078059309,
	worn_corrugated_iron_diff = 107744112435438,
	worn_corrugated_iron_nor = 75878137977040,
	worn_corrugated_iron_rough = 134767952365897,
	river_small_rocks_diff = 71678382965592,
	river_small_rocks_nor = 114207741022691,
	river_small_rocks_rough = 95462609294102,
	stony_dirt_path_diff = 103913932243276,
	stony_dirt_path_nor = 117613154248787,
	stony_dirt_path_rough = 86757243435143,
}

-- One variant per base material so MaterialService:SetBaseMaterialOverride can
-- install all twelve without a collision. studsPerTile drives the tile scale.
TextureMapR4.variants = {
	dry_grass = {
		name = "R4_DryGrass",
		baseMaterial = "Grass",
		surface = "dry / withered grass",
		diff = "withered_grass_diff",
		nor = "withered_grass_nor",
		rough = "withered_grass_rough",
		studsPerTile = 10,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/withered_grass",
	},
	laterite = {
		name = "R4_Laterite",
		baseMaterial = "Ground",
		surface = "laterite red dirt",
		diff = "red_laterite_soil_stones_diff",
		nor = "red_laterite_soil_stones_nor",
		rough = "red_laterite_soil_stones_rough",
		studsPerTile = 10,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/red_laterite_soil_stones",
	},
	paddy_mud = {
		name = "R4_PaddyMud",
		baseMaterial = "Mud",
		surface = "rice-paddy mud / wet clay",
		diff = "Ground026_diff",
		nor = "Ground026_nor",
		rough = "Ground026_rough",
		studsPerTile = 8,
		source = "ambientCG",
		sourcePage = "https://ambientcg.com/a/Ground026",
	},
	cobblestone = {
		name = "R4_Cobblestone",
		baseMaterial = "Cobblestone",
		surface = "cobblestone path",
		diff = "cobblestone_floor_04_diff",
		nor = "cobblestone_floor_04_nor",
		rough = "cobblestone_floor_04_rough",
		studsPerTile = 6,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/cobblestone_floor_04",
	},
	weathered_planks = {
		name = "R4_WeatheredPlanks",
		baseMaterial = "WoodPlanks",
		surface = "weathered planks",
		diff = "weathered_planks_diff",
		nor = "weathered_planks_nor",
		rough = "weathered_planks_rough",
		studsPerTile = 8,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/weathered_planks",
	},
	bilik = {
		name = "R4_Bilik",
		baseMaterial = "Wood",
		surface = "woven bamboo / bilik",
		diff = "bamboo_wall_02_diff",
		nor = "bamboo_wall_02_nor",
		rough = "bamboo_wall_02_rough",
		studsPerTile = 6,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/bamboo_wall_02",
	},
	brick = {
		name = "R4_BrickWall",
		baseMaterial = "Brick",
		surface = "weathered brick wall",
		diff = "worn_brick_wall_diff",
		nor = "worn_brick_wall_nor",
		rough = "worn_brick_wall_rough",
		studsPerTile = 6,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/worn_brick_wall",
	},
	plaster = {
		name = "R4_PlasterWall",
		baseMaterial = "Concrete",
		surface = "weathered plaster wall",
		diff = "blue_plaster_weathered_diff",
		nor = "blue_plaster_weathered_nor",
		rough = "blue_plaster_weathered_rough",
		studsPerTile = 8,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/blue_plaster_weathered",
	},
	clay_tile = {
		name = "R4_ClayTile",
		baseMaterial = "Slate",
		surface = "clay roof tile",
		diff = "clay_roof_tiles_03_diff",
		nor = "clay_roof_tiles_03_nor",
		rough = "clay_roof_tiles_03_rough",
		studsPerTile = 8,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/clay_roof_tiles_03",
	},
	corrugated_metal = {
		name = "R4_CorrugatedMetal",
		baseMaterial = "Metal",
		surface = "corrugated seng",
		diff = "worn_corrugated_iron_diff",
		nor = "worn_corrugated_iron_nor",
		rough = "worn_corrugated_iron_rough",
		studsPerTile = 8,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/worn_corrugated_iron",
	},
	riverbank = {
		name = "R4_RiverBank",
		baseMaterial = "Rock",
		surface = "riverbank stones",
		diff = "river_small_rocks_diff",
		nor = "river_small_rocks_nor",
		rough = "river_small_rocks_rough",
		studsPerTile = 12,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/river_small_rocks",
	},
	sand_path = {
		name = "R4_SandPath",
		baseMaterial = "Sand",
		surface = "sandy dirt path",
		diff = "stony_dirt_path_diff",
		nor = "stony_dirt_path_nor",
		rough = "stony_dirt_path_rough",
		studsPerTile = 8,
		source = "Poly Haven",
		sourcePage = "https://polyhaven.com/a/stony_dirt_path",
	},
}

-- Built-in base material -> variant slot. Terrain and every Part with one of
-- these materials is changed by the global override; no name matching is used.
TextureMapR4.baseMaterials = {
	Grass = "dry_grass",
	Ground = "laterite",
	Mud = "paddy_mud",
	Cobblestone = "cobblestone",
	WoodPlanks = "weathered_planks",
	Wood = "bilik",
	Brick = "brick",
	Concrete = "plaster",
	Slate = "clay_tile",
	Metal = "corrugated_metal",
	Rock = "riverbank",
	Sand = "sand_path",
}

-- Named village surface -> variant slot, including the r4 additions.
TextureMapR4.surfaces = {
	grass = "dry_grass",
	dry_grass = "dry_grass",
	ground = "laterite",
	laterite = "laterite",
	mud = "paddy_mud",
	paddy_mud = "paddy_mud",
	cobblestone = "cobblestone",
	wood = "bilik",
	weathered_planks = "weathered_planks",
	brick = "brick",
	plaster = "plaster",
	slate = "clay_tile",
	clay_tile = "clay_tile",
	corrugated_metal = "corrugated_metal",
	bilik = "bilik",
	riverbank = "riverbank",
	sand = "sand_path",
}

function TextureMapR4.slotCount(): number
	local n = 0
	for _ in TextureMapR4.variants do
		n += 1
	end
	return n
end

function TextureMapR4.mapCount(): number
	local n = 0
	for _ in TextureMapR4.ids do
		n += 1
	end
	return n
end

function TextureMapR4.assetUrl(key: string): string?
	local id = TextureMapR4.ids[key]
	return if id then "rbxassetid://" .. id else nil
end

return TextureMapR4
