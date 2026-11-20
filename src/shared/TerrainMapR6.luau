--!strict
-- TerrainMapR6: pure data for the two OFF-BY-DEFAULT "terrain_r6_a/b" client
-- candidates (WORK_QUEUE section J item 46). The round-4 texture candidate read
-- as a red desert with straw grass because its base-material overrides also
-- covered Terrain. These variants drop the Terrain-wide overrides and instead
-- tune the built-in Terrain material colours. CC0 maps stay on parts/meshes only.
--
-- No Roblox API, no engine colour value and no asset ID literal at load. colours
-- are plain {r,g,b} arrays (0-255) converted by the applier. Every map URL is
-- built through TextureMapR4.assetUrl(); no new ID is introduced here.

local TextureMapR4 = require(script.Parent.TextureMapR4)

local TerrainMapR6 = {}

TerrainMapR6.idPrefix = "terrain_r6_"
TerrainMapR6.order = { "a", "b" }

-- Deliberately only the three built-in Terrain materials. Water is untouched,
-- as in textures_r4.
TerrainMapR6.terrainMaterials = { "Grass", "Ground", "Mud" }

-- a: lush tropical green Grass, warm brown Ground, dark wet sawah Mud.
-- b: brighter olive-green Grass, lighter sandy-brown Ground, medium wet Mud.
TerrainMapR6.palettes = {
	a = {
		Grass = { 74, 148, 62 },
		Ground = { 140, 104, 72 },
		Mud = { 72, 60, 44 },
	},
	b = {
		Grass = { 118, 158, 66 },
		Ground = { 176, 148, 106 },
		Mud = { 104, 88, 66 },
	},
}

-- Built-in base material -> TextureMapR4 variant key. This set is parts/meshes
-- only (walls, roofs, wood). Grass/Ground/Mud are NOT here: no CC0 map reaches
-- Terrain, and Cobblestone/Rock/Sand are left alone as well.
TerrainMapR6.partOrder = { "Brick", "Concrete", "Slate", "Metal", "Wood", "WoodPlanks" }
TerrainMapR6.partOverrides = {
	Brick = "brick",
	Concrete = "plaster",
	Slate = "clay_tile",
	Metal = "corrugated_metal",
	Wood = "bilik",
	WoodPlanks = "weathered_planks",
}

-- One saved spawn review camera for before/after shots, copied from
-- docs/v2/visual/SPAWN_DRESSING_R5.md. The applier never moves the camera.
TerrainMapR6.savedCamera = {
	eye = { 0, 20, 72 },
	look = { 0, 5, 14 },
}

local terrainSet = {}
for _, name in ipairs(TerrainMapR6.terrainMaterials) do
	terrainSet[name] = true
end

function TerrainMapR6.isTerrainMaterial(name: any): boolean
	return type(name) == "string" and terrainSet[name] == true
end

function TerrainMapR6.paletteFor(key: string): any?
	return TerrainMapR6.palettes[key]
end

function TerrainMapR6.variantKeyFor(baseName: string): string?
	return TerrainMapR6.partOverrides[baseName]
end

local function variantFor(baseName: string): any?
	local key = TerrainMapR6.partOverrides[baseName]
	return if key then TextureMapR4.variants[key] else nil
end

function TerrainMapR6.variantNameFor(baseName: string): string?
	local variant = variantFor(baseName)
	return if variant then variant.name else nil
end

function TerrainMapR6.studsFor(baseName: string): number?
	local variant = variantFor(baseName)
	return if variant then variant.studsPerTile else nil
end

-- The only route from a TextureMapR4 key to an asset URL. Returns nils for an
-- unknown base material so the applier can skip it without throwing.
function TerrainMapR6.mapsFor(baseName: string): (string?, string?, string?)
	local key = TerrainMapR6.partOverrides[baseName]
	local variant = if key then TextureMapR4.variants[key] else nil
	if not variant then
		return nil, nil, nil
	end
	return TextureMapR4.assetUrl(variant.diff), TextureMapR4.assetUrl(variant.nor), TextureMapR4.assetUrl(variant.rough)
end

return TerrainMapR6
