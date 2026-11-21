--!strict
-- ModelMapPerahuR8: pure data for the OFF-BY-DEFAULT "perahu_r8" LookDev candidate
-- (WORK_QUEUE section N item 112). Two small perahu on the river bank, a fishing net on poles, a
-- bamboo landing stage and a stack of baskets. All geometry is ORIGINAL PARTS staged by
-- src/server/World/LookDevPerahuR8.luau: plain RGB colours, real built-in material tokens only,
-- no asset IDs, no brand, no terrain edit and no engine API in this module.
--
-- SITE derivation: the river runs along X with centreline z = 304 + 12 sin(2*pi*x/320), channel
-- half-width 14. Every site sits on a bank shelf at z = riverCentreZ(x) +/- BANK_OFFSET (18), so
-- the nearest part face stays outside the water channel. The bridge crosses the river along Z at
-- x = 0 over a 56-stud span (z0=276, z1=332); its crossing interval on the river's X axis is
-- therefore [x - 28, x + 28]. All sites have |x| >= 52, so their XZ boxes stay clear of that span
-- and the bridge deck/rails are untouched. No new camera: review reuses the existing render path.
-- Visual/designer verdict stays pending.

local Data = {}

Data.id = "perahu_r8"
Data.familyId = "perahu_r8"
Data.folderName = "LookDevPerahuR8_perahu_r8"

Data.stageAttribute = "LookDevPerahuR8"
Data.kindAttribute = "PerahuKind"

Data.KIND = {
	hull = "hull",
	gunwale = "gunwale",
	seat = "seat",
	netframe = "netframe",
	netmesh = "netmesh",
	stageplank = "stageplank",
	stagepile = "stagepile",
	basket = "basket",
}
Data.KINDS = {
	"hull",
	"gunwale",
	"seat",
	"netframe",
	"netmesh",
	"stageplank",
	"stagepile",
	"basket",
}
Data.MIN_PARTS = 35

-- Mirrors MapSpec's river/bridge constants. Kept pure so specs and the data module need no require.
Data.RIVER_CENTRE = 304
Data.RIVER_AMPLITUDE = 12
Data.RIVER_PERIOD = 320
Data.RIVER_HALF = 14
Data.BANK_OFFSET = 18 -- channel half 14 + bank shelf half 4
Data.BRIDGE_X = 0
Data.BRIDGE_Z0 = 276
Data.BRIDGE_Z1 = 332
Data.BRIDGE_SPAN = Data.BRIDGE_Z1 - Data.BRIDGE_Z0
Data.BRIDGE_CROSS_MIN = Data.BRIDGE_X - Data.BRIDGE_SPAN / 2
Data.BRIDGE_CROSS_MAX = Data.BRIDGE_X + Data.BRIDGE_SPAN / 2

function Data.riverCentreZ(x: number): number
	return Data.RIVER_CENTRE + Data.RIVER_AMPLITUDE * math.sin(2 * math.pi * x / Data.RIVER_PERIOD)
end

-- bank = -1 is the south shelf (z below the centreline), +1 the north shelf.
Data.SITES = {
	{ key = "perahu_a", x = -52, bank = -1 },
	{ key = "perahu_b", x = 56, bank = 1 },
	{ key = "net", x = -88, bank = 1 },
	{ key = "stage", x = 88, bank = -1 },
	{ key = "baskets", x = 120, bank = 1 },
}

function Data.siteByKey(key: string): any?
	for _, site in ipairs(Data.SITES) do
		if site.key == key then
			return site
		end
	end
	return nil
end

-- Pure world XZ for a site-local recipe. `lz` grows away from the channel (multiplied by bank).
-- An optional centre function lets the applier use the live MapSpec implementation; the pure
-- mirror is the default and the only one this module ever calls itself.
function Data.worldXZ(site: any, lx: number, lz: number, centreFn: ((number) -> number)?): (number, number)
	local fn = centreFn or Data.riverCentreZ
	return site.x + lx, fn(site.x) + site.bank * (Data.BANK_OFFSET + lz)
end

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Material tokens name REAL built-in
-- materials only: the two stale non-engine tokens are not used, green/brown comes from colour.
Data.COLOURS = {
	hull = { 96, 68, 44 },
	hullDark = { 72, 50, 34 },
	trim = { 136, 104, 62 },
	seat = { 158, 126, 78 },
	rope = { 204, 190, 150 },
	net = { 196, 196, 174 },
	bamboo = { 146, 158, 84 },
	bambooDark = { 108, 118, 62 },
	basket = { 166, 122, 70 },
	basketDark = { 132, 94, 52 },
}
Data.MATERIALS = {
	hull = "Wood",
	hullDark = "Wood",
	trim = "WoodPlanks",
	seat = "WoodPlanks",
	rope = "Fabric",
	net = "Fabric",
	bamboo = "WoodPlanks",
	bambooDark = "Wood",
	basket = "WoodPlanks",
	basketDark = "Wood",
}

-- lx/lz are site-local bank coordinates; ly is a centre height above GROUND_Y. `roll` is a Z-axis
-- tilt in degrees used only by the net's crossing strands; the harness bounds rotated parts with
-- the CFrame axis vectors so its AABB stays exact.
local function part(
	name: string,
	kind: string,
	lx: number,
	ly: number,
	lz: number,
	size: { number },
	colour: string,
	material: string,
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
		roll = roll or 0,
	}
end

local perahuKit = {
	-- Tapered three-block hull, two gunwales and two cross seats.
	part("hull_keel", "hull", 0, 0.45, 0, { 6.4, 0.5, 3.2 }, "hull", "hull"),
	part("hull_bow", "hull", 3.7, 0.5, 0, { 2.4, 0.45, 2.2 }, "hull", "hull"),
	part("hull_stern", "hull", -3.7, 0.5, 0, { 2.4, 0.45, 2.2 }, "hull", "hull"),
	part("gunwale_l", "gunwale", 0, 1, 1.7, { 9, 0.22, 0.28 }, "trim", "trim"),
	part("gunwale_r", "gunwale", 0, 1, -1.7, { 9, 0.22, 0.28 }, "trim", "trim"),
	part("seat_f", "seat", 1.8, 0.95, 0, { 0.45, 0.2, 3 }, "seat", "seat"),
	part("seat_a", "seat", -1.8, 0.95, 0, { 0.45, 0.2, 3 }, "seat", "seat"),
}

local netKit = {
	-- Upright frame: two poles and two cross beams.
	part("net_pole_l", "netframe", -4, 3, 0, { 0.22, 6, 0.22 }, "bambooDark", "bambooDark"),
	part("net_pole_r", "netframe", 4, 3, 0, { 0.22, 6, 0.22 }, "bambooDark", "bambooDark"),
	part("net_beam_top", "netframe", 0, 5.9, 0, { 8.3, 0.2, 0.2 }, "bamboo", "bamboo"),
	part("net_beam_low", "netframe", 0, 0.2, 0, { 8.3, 0.2, 0.2 }, "bamboo", "bamboo"),
	-- Three crossing pairs of thin strands: a criss-cross mesh made from Parts, not an asset.
	part("net_cross_1a", "netmesh", -2.4, 3, 0, { 0.1, 3.4, 0.1 }, "net", "net", 35),
	part("net_cross_1b", "netmesh", -2.4, 3, 0, { 0.1, 3.4, 0.1 }, "net", "net", -35),
	part("net_cross_2a", "netmesh", 0, 3, 0, { 0.1, 3.4, 0.1 }, "rope", "rope", 35),
	part("net_cross_2b", "netmesh", 0, 3, 0, { 0.1, 3.4, 0.1 }, "rope", "rope", -35),
	part("net_cross_3a", "netmesh", 2.4, 3, 0, { 0.1, 3.4, 0.1 }, "net", "net", 35),
	part("net_cross_3b", "netmesh", 2.4, 3, 0, { 0.1, 3.4, 0.1 }, "net", "net", -35),
}

local stageKit = {
	-- Six bamboo deck planks on four pilings, all on the bank shelf.
	part("stage_plank_1", "stageplank", -5, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_plank_2", "stageplank", -3, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_plank_3", "stageplank", -1, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_plank_4", "stageplank", 1, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_plank_5", "stageplank", 3, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_plank_6", "stageplank", 5, 0.9, 0.5, { 1.5, 0.2, 4 }, "bamboo", "bamboo"),
	part("stage_pile_1", "stagepile", -5, -0.1, -2, { 0.35, 2.2, 0.35 }, "bambooDark", "bambooDark"),
	part("stage_pile_2", "stagepile", 5, -0.1, -2, { 0.35, 2.2, 0.35 }, "bambooDark", "bambooDark"),
	part("stage_pile_3", "stagepile", -5, -0.1, 3, { 0.35, 2.2, 0.35 }, "bambooDark", "bambooDark"),
	part("stage_pile_4", "stagepile", 5, -0.1, 3, { 0.35, 2.2, 0.35 }, "bambooDark", "bambooDark"),
}

local basketKit = {
	-- Four baskets in a square plus one on top.
	part("basket_1", "basket", -1.1, 0.7, -1.1, { 2, 1.4, 2 }, "basket", "basket"),
	part("basket_2", "basket", 1.1, 0.7, -1.1, { 2, 1.4, 2 }, "basketDark", "basketDark"),
	part("basket_3", "basket", -1.1, 0.7, 1.1, { 2, 1.4, 2 }, "basketDark", "basketDark"),
	part("basket_4", "basket", 1.1, 0.7, 1.1, { 2, 1.4, 2 }, "basket", "basket"),
	part("basket_5", "basket", 0, 2.1, 0, { 2, 1.4, 2 }, "basket", "basket"),
}

local KITS = {
	perahu_a = perahuKit,
	perahu_b = perahuKit,
	net = netKit,
	stage = stageKit,
	baskets = basketKit,
}

local recipes: { any } = {}
for _, site in ipairs(Data.SITES) do
	for _, recipe in ipairs(KITS[site.key]) do
		recipes[#recipes + 1] = {
			name = site.key .. "_" .. recipe.name,
			kind = recipe.kind,
			site = site.key,
			lx = recipe.lx,
			ly = recipe.ly,
			lz = recipe.lz,
			size = recipe.size,
			colour = recipe.colour,
			material = recipe.material,
			roll = recipe.roll,
		}
	end
end

function Data.parts(): { any }
	return table.clone(recipes)
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
