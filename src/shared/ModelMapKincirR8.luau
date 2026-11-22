--!strict
-- ModelMapKincirR8: pure data for the OFF-BY-DEFAULT "kincir_r8" LookDev candidate
-- (WORK_QUEUE section N item 114). A small wooden waterwheel on the north river bank: one hub,
-- one axle, eight spokes, eight paddle blades and two static support posts around a rotating root.
-- All geometry is ORIGINAL PARTS staged by src/server/World/LookDevKincirR8.luau: plain RGB colours,
-- real built-in Wood/WoodPlanks material tokens only, no asset IDs, no brand, no terrain edit and
-- no engine API in this module.
--
-- SITE derivation: the river mirrors MapSpec (runs along X, centreline z = 304 + 12 sin(2*pi*x/320),
-- half-width 14). The single site sits at x = -68 on the +1 (north) bank shelf, z = centreline + 18.
-- Its largest local Z half-extent is 4, so the nearest wheel face stays exactly 14 studs from the
-- centreline (outside the water channel). |x| >= 64 keeps it clear of the 56-stud bridge crossing
-- [-28, 28], the perahu sites and the ford. No new camera: review reuses the existing render path.
-- The axle runs along Z, the wheel plane is XY and the shared loop turns it about local Z at a
-- constant DEG_PER_SEC. Visual/designer verdict stays pending.

local Data = {}

Data.id = "kincir_r8"
Data.familyId = "kincir_r8"
Data.folderName = "LookDevKincirR8_kincir_r8"

Data.stageAttribute = "LookDevKincirR8"
Data.kindAttribute = "KincirKind"
Data.angleAttribute = "WheelAngle"

Data.KIND = {
	wheelroot = "wheelroot",
	hub = "hub",
	axle = "axle",
	spoke = "spoke",
	blade = "blade",
	support = "support",
}
Data.KINDS = {
	"wheelroot",
	"hub",
	"axle",
	"spoke",
	"blade",
	"support",
}
Data.WHEELROOT_KIND = "wheelroot"
Data.SUPPORT_KIND = "support"
Data.MIN_PARTS = 20
Data.DEG_PER_SEC = 6

-- Mirrors MapSpec's river/bridge constants. Kept pure so specs and the applier need no require.
Data.RIVER_CENTRE = 304
Data.RIVER_AMPLITUDE = 12
Data.RIVER_PERIOD = 320
Data.RIVER_HALF = 14
Data.BANK_OFFSET = 18 -- channel half 14 + largest local Z half-extent 4
Data.MAX_LOCAL_Z_HALF = 4
Data.BRIDGE_X = 0
Data.BRIDGE_Z0 = 276
Data.BRIDGE_Z1 = 332
Data.BRIDGE_SPAN = Data.BRIDGE_Z1 - Data.BRIDGE_Z0
Data.BRIDGE_CROSS_MIN = Data.BRIDGE_X - Data.BRIDGE_SPAN / 2
Data.BRIDGE_CROSS_MAX = Data.BRIDGE_X + Data.BRIDGE_SPAN / 2

function Data.riverCentreZ(x: number): number
	return Data.RIVER_CENTRE + Data.RIVER_AMPLITUDE * math.sin(2 * math.pi * x / Data.RIVER_PERIOD)
end

-- bank = -1 is the south shelf, +1 the north shelf. One deterministic site only.
Data.SITE = { key = "wheel", x = -68, bank = 1 }

-- Pure world XZ for a site-local recipe. `lz` grows away from the channel (multiplied by bank).
-- The optional centre function lets the applier use the live MapSpec implementation.
function Data.worldXZ(site: any, lx: number, lz: number, centreFn: ((number) -> number)?): (number, number)
	local fn = centreFn or Data.riverCentreZ
	return site.x + lx, fn(site.x) + site.bank * (Data.BANK_OFFSET + lz)
end

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Only real built-in material tokens.
Data.COLOURS = {
	root = { 92, 66, 42 },
	hub = { 124, 92, 56 },
	axle = { 88, 66, 44 },
	spoke = { 150, 116, 72 },
	blade = { 168, 132, 82 },
	bladeDark = { 138, 104, 64 },
	support = { 104, 76, 48 },
}
Data.MATERIALS = {
	root = "Wood",
	hub = "Wood",
	axle = "Wood",
	spoke = "WoodPlanks",
	blade = "WoodPlanks",
	bladeDark = "Wood",
	support = "Wood",
}

-- All offsets are site-local: ly is measured from the wheel centre, which the applier places at
-- GROUND_Y + WHEEL_CENTRE_LY. `rx` tilts a cylinder's axis from Y onto the Z axle; `roll` turns a
-- bar/blade in the wheel's XY plane. `shape` may name a cylinder.
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
	rx: number?,
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
		rx = rx or 0,
		roll = roll or 0,
	}
end

Data.WHEEL_CENTRE_LY = 5.2
Data.SPOKE_RADIUS = 3.6
Data.BLADE_RADIUS = 3.6

-- The root is an ordinary small Part: it carries the wheel's tag and rotation, and every other
-- rotating part is parented under it with its base CFrame rewritten about the same centre each tick.
local recipes: { any } = {
	part("wheel_root", Data.KIND.wheelroot, 0, 0, 0, { 1, 1, 1 }, "root", "root"),
	part("hub", Data.KIND.hub, 0, 0, 0, { 2.4, 1.4, 2.4 }, "hub", "hub", "cylinder", 90),
	part("axle", Data.KIND.axle, 0, 0, 0, { 0.8, 0.8, 8 }, "axle", "axle"),
}

for index = 0, 7 do
	local theta = math.rad(index * 45)
	recipes[#recipes + 1] = part(
		"spoke_" .. (index + 1),
		Data.KIND.spoke,
		Data.SPOKE_RADIUS * math.cos(theta) / 2,
		Data.SPOKE_RADIUS * math.sin(theta) / 2,
		0,
		{ 0.32, Data.SPOKE_RADIUS, 0.32 },
		"spoke",
		"spoke",
		nil,
		nil,
		index * 45 - 90
	)
end

for index = 0, 7 do
	local theta = math.rad(index * 45)
	recipes[#recipes + 1] = part(
		"blade_" .. (index + 1),
		Data.KIND.blade,
		Data.BLADE_RADIUS * math.cos(theta),
		Data.BLADE_RADIUS * math.sin(theta),
		0,
		{ 1.8, 0.28, 2.4 },
		if index % 2 == 0 then "blade" else "bladeDark",
		"blade",
		nil,
		nil,
		index * 45
	)
end

for index, side in ipairs({ -1, 1 }) do
	recipes[#recipes + 1] = part(
		"support_" .. index,
		Data.KIND.support,
		0,
		0,
		side * 3.2,
		{ 0.9, 2 * Data.WHEEL_CENTRE_LY, 0.9 },
		"support",
		"support"
	)
end

function Data.parts(): { any }
	return table.clone(recipes)
end

function Data.isRotating(recipe: any): boolean
	return recipe.kind ~= Data.KIND.support
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
