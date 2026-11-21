--!strict
-- ModelMapLayanganR8: pure data for the OFF-BY-DEFAULT "layangan_r8" LookDev candidate
-- (WORK_QUEUE section N item 116). Four kites fly 60-90 studs over the Lapangan field, each with a
-- diamond sail, a thin tail and a textureless Beam string down to a kid-sized ground anchor. All
-- geometry is ORIGINAL PARTS staged by src/server/World/LookDevLayanganR8.luau: plain RGB colours,
-- real built-in Wood/Fabric material tokens only, no asset IDs, no brand, no decals, no terrain edit
-- and no engine API in this module. One shared Heartbeat loop rocks the four sails with a gentle
-- sine tilt; the Beams carry a solid ColorSequence and no uploaded image of any kind.
--
-- SITE derivation copies MapSpec.LAPANGAN (centre 0,96, footprint 72x56) as pure numbers. Anchors sit
-- at centre offsets (-24,-16), (24,-16), (-24,16), (24,16), i.e. world (-24,80), (24,80), (-24,112),
-- (24,112), all inside field x[-36,36] z[68,124]. Each kite leans 3 studs toward the field centre,
-- so both endpoints and the whole string stay inside the field and >= 44 studs in X from the six
-- hub buildings at x = -68 / 68. Altitudes above MapSpec.GROUND_Y are 64, 72, 80 and 88 studs.
-- No new camera: review reuses the existing render path. Visual/designer verdict stays pending.

local Data = {}

Data.id = "layangan_r8"
Data.familyId = "layangan_r8"
Data.folderName = "LookDevLayanganR8_layangan_r8"

Data.stageAttribute = "LookDevLayanganR8"
Data.kindAttribute = "LayanganKind"
Data.angleAttribute = "KiteAngle"

Data.KIND = {
	kiteroot = "kiteroot",
	spine = "spine",
	spar = "spar",
	sail = "sail",
	tail = "tail",
	anchor = "anchor",
}
Data.KINDS = { "kiteroot", "spine", "spar", "sail", "tail", "anchor" }
Data.ROOT_KIND = "kiteroot"
Data.ANCHOR_KIND = "anchor"
Data.BEAM_KIND = "kitestring"
Data.MIN_PARTS = 40

-- Pure mirrors of MapSpec.LAPANGAN / MapSpec.GROUND_Y (the applier still reads the live MapSpec).
Data.FIELD = { x = 0, z = 96, width = 72, depth = 56 }
Data.halfW = Data.FIELD.width / 2 -- 36
Data.halfD = Data.FIELD.depth / 2 -- 28

-- The six greybox hub Models under workspace.World, used by the string-clear raycast.
Data.HUB_MODELS = {
	"Pasar",
	"TengkulakGelap",
	"Warung",
	"PosRonda",
	"PosPolisi",
	"RumahPakRT",
}

-- Altitude band and deterministic pump parameters. KITE_COST uses N = ceil(SIM_SECONDS / DT).
-- The applier rocks only root/spine/spar/sail Parts (7 per kite, 28 total); tail and anchor Parts
-- stay static so distinct CFrame writes cost ~0.14ms/step, under the 0.2ms budget (all 44 moving
-- Parts measured ~0.235ms/step). Counts and KINDS are unchanged.
Data.KITE_ALT_MIN = 60
Data.KITE_ALT_MAX = 90
Data.SIM_SECONDS = 60
Data.DT = 1 / 60
Data.MAX_STEP_MS = 0.2
Data.ROCK_AMPLITUDE_DEG = 4
Data.ROCK_PERIOD = 8
Data.ROCK_PHASE_STEP = 1.7

-- Four anchor sites; `leanX`/`leanZ` move the kite toward the field centre so the string stays
-- inside the field. Each altitude is inside [KITE_ALT_MIN, KITE_ALT_MAX].
Data.SITES = {
	{ key = "k1", ax = -24, az = 80, leanX = 3, leanZ = 3, altitude = 64 },
	{ key = "k2", ax = 24, az = 80, leanX = -3, leanZ = 3, altitude = 72 },
	{ key = "k3", ax = -24, az = 112, leanX = 3, leanZ = -3, altitude = 80 },
	{ key = "k4", ax = 24, az = 112, leanX = -3, leanZ = -3, altitude = 88 },
}

function Data.anchorXZ(site: any): (number, number)
	return site.ax, site.az
end

function Data.kiteXZ(site: any): (number, number)
	return site.ax + site.leanX, site.az + site.leanZ
end

-- The Beam is built by the applier from this spec: faceColour -> Color (ColorSequence) and
-- width -> Width0/Width1. FaceColor and Width are NOT valid Beam members in this Studio, and
-- the texture property stays unset (empty string) so the Beam renders solid; no image map and no
-- uploaded asset of any kind.
Data.BEAM = {
	faceColour = { 214, 208, 190 },
	width = 0.12,
	segments = 24,
}

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Only real built-in material tokens.
Data.COLOURS = {
	root = { 92, 66, 42 },
	spine = { 104, 76, 48 },
	spar = { 120, 88, 54 },
	sailRed = { 196, 52, 44 },
	sailWhite = { 246, 242, 230 },
	sailBlue = { 58, 110, 165 },
	sailYellow = { 236, 186, 60 },
	tail = { 200, 120, 60 },
	anchor = { 104, 76, 48 },
}
Data.MATERIALS = {
	root = "Wood",
	spine = "Wood",
	spar = "Wood",
	sail = "Fabric",
	tail = "Fabric",
	anchor = "Wood",
}

-- Every recipe is a world XZ offset from the field centre, `ly` above MapSpec.GROUND_Y, and an
-- optional roll about local Z (degrees). The sail panels trace the four edges of a diamond.
local function part(
	name: string,
	kind: string,
	site: number,
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
		site = site,
		lx = lx,
		ly = ly,
		lz = lz,
		size = size,
		colour = colour,
		material = material,
		roll = roll or 0,
	}
end

local DIAMOND_HALF_W = 3.2
local DIAMOND_HALF_H = 4
local EDGE_LEN = math.sqrt(DIAMOND_HALF_W ^ 2 + DIAMOND_HALF_H ^ 2)
local EDGE_DEG = math.deg(math.atan2(DIAMOND_HALF_H, DIAMOND_HALF_W))
local SAIL_COLOURS = { "sailRed", "sailWhite", "sailBlue", "sailYellow" }
local PANELS = {
	{ -DIAMOND_HALF_W / 2, DIAMOND_HALF_H / 2, EDGE_DEG },
	{ DIAMOND_HALF_W / 2, DIAMOND_HALF_H / 2, -EDGE_DEG },
	{ DIAMOND_HALF_W / 2, -DIAMOND_HALF_H / 2, EDGE_DEG },
	{ -DIAMOND_HALF_W / 2, -DIAMOND_HALF_H / 2, -EDGE_DEG },
}

local recipes: { any } = {}
for index, site in ipairs(Data.SITES) do
	local kx, kz = Data.kiteXZ(site)
	local tag = site.key
	recipes[#recipes + 1] =
		part(tag .. "_root", Data.KIND.kiteroot, index, kx, site.altitude, kz, { 1, 1, 1 }, "root", "root")
	recipes[#recipes + 1] = part(
		tag .. "_spine",
		Data.KIND.spine,
		index,
		kx,
		site.altitude,
		kz,
		{ 0.18, 2 * DIAMOND_HALF_H, 0.18 },
		"spine",
		"spine"
	)
	recipes[#recipes + 1] = part(
		tag .. "_spar",
		Data.KIND.spar,
		index,
		kx,
		site.altitude,
		kz,
		{ 2 * DIAMOND_HALF_W, 0.18, 0.18 },
		"spar",
		"spar"
	)
	for panel = 1, #PANELS do
		local p = PANELS[panel]
		recipes[#recipes + 1] = part(
			tag .. "_sail_" .. panel,
			Data.KIND.sail,
			index,
			kx + p[1],
			site.altitude + p[2],
			kz,
			{ EDGE_LEN, 1.6, 0.1 },
			SAIL_COLOURS[panel],
			"sail",
			p[3]
		)
	end
	for tail = 1, 4 do
		recipes[#recipes + 1] = part(
			tag .. "_tail_" .. tail,
			Data.KIND.tail,
			index,
			kx + (tail % 2 == 0 and 0.6 or -0.6),
			site.altitude - (DIAMOND_HALF_H + 1 + (tail - 1) * 1.4),
			kz,
			{ 0.6, 0.9, 0.08 },
			"tail",
			"tail",
			tail % 2 == 0 and 12 or -12
		)
	end
	recipes[#recipes + 1] =
		part(tag .. "_anchor", Data.KIND.anchor, index, site.ax, 0.75, site.az, { 1.5, 1.5, 1.5 }, "anchor", "anchor")
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
