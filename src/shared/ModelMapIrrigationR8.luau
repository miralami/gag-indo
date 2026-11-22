--!strict
-- ModelMapIrrigationR8: pure data for the OFF-BY-DEFAULT "irrigation_r8" LookDev candidate
-- (WORK_QUEUE section N item 113). Two orang-orangan sawah with a woven hat and a ragged shirt,
-- two bamboo irrigation channels with a thin water sheet each, a bamboo clapper bird-scarer and a
-- small stack of padi sheaves. All geometry is ORIGINAL PARTS staged by
-- src/server/World/LookDevIrrigationR8.luau: plain RGB colours, real built-in material tokens only,
-- no asset IDs, no brand, no terrain edit and no engine API in this module.
--
-- SITE derivation: terrace tops/bands mirror MapSpec.TERRACES. Every water sheet is centred
-- WATER_CENTRE_OFFSET above its terrace top with WATER_THICKNESS thickness, so its top surface is
-- terrace.top + WATER_TOP_DELTA (0.25 studs), inside the 0.3-stud item-113 tolerance. Each recipe
-- carries the owning 1..4 Terrace index; the harness resolves the live top from MapSpec.TERRACES,
-- with a z-band fallback. SAWAH_TOPS stays READ-ONLY and BYTE-IDENTICAL: this data never touches it.
-- Visual/designer verdict stays pending.

local Data = {}

Data.id = "irrigation_r8"
Data.familyId = "irrigation_r8"
Data.folderName = "LookDevIrrigationR8_irrigation_r8"

Data.stageAttribute = "LookDevIrrigationR8"
Data.kindAttribute = "IrrigationKind"
Data.terraceAttribute = "Terrace"

Data.KIND = {
	scarecpole = "scarecpole",
	crossbar = "crossbar",
	shirt = "shirt",
	head = "head",
	hat = "hat",
	flume = "flume",
	watersheet = "watersheet",
	clapper = "clapper",
	sheaf = "sheaf",
}
Data.KINDS = {
	"scarecpole",
	"crossbar",
	"shirt",
	"head",
	"hat",
	"flume",
	"watersheet",
	"clapper",
	"sheaf",
}
Data.WATERSHEET_KIND = "watersheet"
Data.MIN_PARTS = 40
Data.WATER_TOL = 0.3

-- Mirrors MapSpec.TERRACES (READ-ONLY). Kept pure so specs need no require.
Data.TERRACE_TOPS = { 4.5, 8.5, 12.5, 16.5 }
Data.TERRACE_BANDS = {
	{ z0 = -328, z1 = -312 },
	{ z0 = -344, z1 = -328 },
	{ z0 = -360, z1 = -344 },
	{ z0 = -376, z1 = -360 },
}
Data.WATER_CENTRE_OFFSET = 0.2
Data.WATER_THICKNESS = 0.1
Data.WATER_TOP_DELTA = Data.WATER_CENTRE_OFFSET + Data.WATER_THICKNESS / 2

function Data.terraceTop(index: number): number?
	return Data.TERRACE_TOPS[index]
end

-- Terrace centres of the four bands; used for the site z coordinates below.
Data.SITES = {
	{ key = "scarecrow_a", x = -120, z = -320, terrace = 1 },
	{ key = "scarecrow_b", x = 140, z = -352, terrace = 3 },
	{ key = "channel_a", x = -170, z = -336, terrace = 2 },
	{ key = "channel_b", x = 170, z = -368, terrace = 4 },
	{ key = "clapper", x = 120, z = -320, terrace = 1 },
	{ key = "sheaves", x = -150, z = -352, terrace = 3 },
}

function Data.siteByKey(key: string): any?
	for _, site in ipairs(Data.SITES) do
		if site.key == key then
			return site
		end
	end
	return nil
end

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Material tokens name REAL built-in
-- materials only: the two stale non-engine tokens are not used, green/brown comes from colour.
Data.COLOURS = {
	pole = { 104, 84, 52 },
	bamboo = { 146, 158, 84 },
	bambooDark = { 108, 118, 62 },
	cloth = { 176, 72, 64 },
	clothAlt = { 196, 164, 132 },
	skin = { 214, 176, 132 },
	straw = { 206, 182, 112 },
	strawDark = { 166, 140, 80 },
	water = { 86, 104, 52 },
	rope = { 204, 190, 150 },
}
Data.MATERIALS = {
	pole = "Wood",
	bamboo = "WoodPlanks",
	bambooDark = "Wood",
	cloth = "Fabric",
	clothAlt = "Fabric",
	skin = "SmoothPlastic",
	straw = "Cardboard",
	strawDark = "Cardboard",
	water = "Water",
	rope = "Fabric",
}

-- lx/lz are site-local offsets, ly is a centre height above the owning terrace top. `shape` may
-- name a flattened cylinder for the woven hat; `roll` is a Z-axis tilt in degrees for sheaves.
local function part(
	name: string,
	kind: string,
	lx: number,
	ly: number,
	lz: number,
	size: { number },
	colour: string,
	material: string,
	shape: string?,
	roll: number?
): any
	return {
		name = name,
		kind = kind,
		lx = lx,
		ly = ly,
		lz = lz,
		size = size,
		colour = colour,
		material = material,
		shape = shape,
		roll = roll or 0,
	}
end

-- Orang-orangan sawah: bamboo pole, crossbar, five thin ragged-shirt pieces, a head and a three
-- layer flattened woven hat. Eleven original Parts per scarecrow.
local scarecrowKit = {
	part("pole", "scarecpole", 0, 2.5, 0, { 0.35, 5, 0.35 }, "pole", "pole"),
	part("crossbar", "crossbar", 0, 3.5, 0, { 4, 0.25, 0.25 }, "bamboo", "bamboo"),
	part("shirt_torso", "shirt", 0, 3.2, 0, { 1.8, 2, 0.5 }, "cloth", "cloth"),
	part("shirt_sleeve_l", "shirt", -1.2, 3.6, 0, { 1.1, 0.3, 0.3 }, "clothAlt", "clothAlt"),
	part("shirt_sleeve_r", "shirt", 1.2, 3.6, 0, { 1.1, 0.3, 0.3 }, "clothAlt", "clothAlt"),
	part("shirt_tail_l", "shirt", -0.5, 2.2, 0, { 0.45, 0.9, 0.18 }, "cloth", "cloth"),
	part("shirt_tail_r", "shirt", 0.5, 2.4, 0, { 0.45, 0.7, 0.18 }, "cloth", "cloth"),
	part("head", "head", 0, 5.3, 0, { 0.9, 0.9, 0.9 }, "skin", "skin"),
	part("hat_brim", "hat", 0, 5.85, 0, { 2.4, 0.12, 2.4 }, "straw", "straw", "cylinder"),
	part("hat_mid", "hat", 0, 6.05, 0, { 1.7, 0.18, 1.7 }, "strawDark", "strawDark", "cylinder"),
	part("hat_top", "hat", 0, 6.2, 0, { 1, 0.2, 1 }, "straw", "straw", "cylinder"),
}

-- Bamboo flume: a thin trough floor, two side walls, three ribs and one translucent water sheet.
-- The sheet centre is exactly WATER_CENTRE_OFFSET above the terrace top so its top face lands at
-- terrace.top + WATER_TOP_DELTA = 0.25 studs.
local channelKit = {
	part("flume_floor", "flume", 0, 0.05, 0, { 10, 0.1, 1.6 }, "bambooDark", "bambooDark"),
	part("flume_wall_n", "flume", 0, 0.4, -0.8, { 10, 0.7, 0.18 }, "bamboo", "bamboo"),
	part("flume_wall_s", "flume", 0, 0.4, 0.8, { 10, 0.7, 0.18 }, "bamboo", "bamboo"),
	part("flume_rib_a", "flume", -4.6, 0.35, 0, { 0.25, 0.6, 1.9 }, "bambooDark", "bambooDark"),
	part("flume_rib_b", "flume", 0, 0.35, 0, { 0.25, 0.6, 1.9 }, "bambooDark", "bambooDark"),
	part("flume_rib_c", "flume", 4.6, 0.35, 0, { 0.25, 0.6, 1.9 }, "bambooDark", "bambooDark"),
	part(
		"watersheet",
		"watersheet",
		0,
		Data.WATER_CENTRE_OFFSET,
		0,
		{ 9.6, Data.WATER_THICKNESS, 1.2 },
		"water",
		"water"
	),
}

-- Bamboo clapper bird-scarer: foot, pivot, crosspiece, swinging arm, clapper blade and pull cord.
local clapperKit = {
	part("foot", "clapper", 0, 0.2, 0, { 0.7, 0.4, 0.7 }, "bambooDark", "bambooDark"),
	part("pivot", "clapper", 0, 2, 0, { 0.3, 4, 0.3 }, "bamboo", "bamboo"),
	part("crosspiece", "clapper", 0, 3.6, 0, { 0.25, 0.25, 2.4 }, "bambooDark", "bambooDark"),
	part("arm", "clapper", 0, 3.8, 0, { 2.4, 0.3, 0.25 }, "bamboo", "bamboo"),
	part("blade", "clapper", 1.4, 3.8, 0, { 0.9, 0.55, 0.2 }, "bambooDark", "bambooDark"),
	part("cord", "clapper", 0, 2.7, 0, { 0.1, 1.4, 0.1 }, "rope", "rope"),
}

-- A small pyramid stack of six tapered/thin yellow padi bundles plus two tie bands.
local sheafKit = {
	part("sheaf_1", "sheaf", -2.3, 0.3, 0, { 2.1, 0.55, 0.9 }, "straw", "straw"),
	part("sheaf_2", "sheaf", 0, 0.3, 0, { 2.1, 0.55, 0.9 }, "strawDark", "strawDark"),
	part("sheaf_3", "sheaf", 2.3, 0.3, 0, { 2.1, 0.55, 0.9 }, "straw", "straw"),
	part("sheaf_4", "sheaf", -1.15, 0.9, 0, { 2.1, 0.55, 0.9 }, "strawDark", "strawDark", nil, 3),
	part("sheaf_5", "sheaf", 1.15, 0.9, 0, { 2.1, 0.55, 0.9 }, "straw", "straw", nil, -3),
	part("sheaf_6", "sheaf", 0, 1.5, 0, { 2.1, 0.55, 0.9 }, "strawDark", "strawDark"),
	part("tie_low", "sheaf", 0, 0.6, 0.5, { 6.8, 0.12, 0.16 }, "rope", "rope"),
	part("tie_high", "sheaf", 0, 1.2, 0.5, { 4.5, 0.12, 0.16 }, "rope", "rope"),
}

local KITS = {
	scarecrow_a = scarecrowKit,
	scarecrow_b = scarecrowKit,
	channel_a = channelKit,
	channel_b = channelKit,
	clapper = clapperKit,
	sheaves = sheafKit,
}

local recipes: { any } = {}
for _, site in ipairs(Data.SITES) do
	for _, recipe in ipairs(KITS[site.key]) do
		recipes[#recipes + 1] = {
			name = site.key .. "_" .. recipe.name,
			kind = recipe.kind,
			site = site.key,
			terrace = site.terrace,
			x = site.x + recipe.lx,
			y = Data.TERRACE_TOPS[site.terrace] + recipe.ly,
			z = site.z + recipe.lz,
			size = recipe.size,
			colour = recipe.colour,
			material = recipe.material,
			shape = recipe.shape,
			roll = recipe.roll,
		}
	end
end

function Data.parts(): { any }
	return table.clone(recipes)
end

function Data.waterSheets(): { any }
	local out = {}
	for _, recipe in ipairs(recipes) do
		if recipe.kind == Data.WATERSHEET_KIND then
			out[#out + 1] = recipe
		end
	end
	return out
end

function Data.counts(): { [string]: number }
	local out: { [string]: number } = {}
	for _, kind in ipairs(Data.KINDS) do
		out[kind] = 0
	end
	for _, recipe in ipairs(recipes) do
		out[recipe.kind] = (out[recipe.kind] or 0) + 1
	end
	out.total = #recipes
	return out
end

return Data
