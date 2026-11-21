--!strict
-- ModelMapMusalaR8: pure data for the OFF-BY-DEFAULT "musala_r8" LookDev candidate
-- (WORK_QUEUE section N item 110). A small, plain musala (small prayer house): raised platform,
-- four walls and corner posts, a clear door, three windows, a green tiered roof, a pengeras suara
-- horn on a pole, a wudhu tap area and a shoe rack. All geometry is ORIGINAL PARTS staged by
-- src/server/World/LookDevMusalaR8.luau: no asset IDs, no brand marks, no terrain edit, no game API
-- in this module. Cultural content stays respectful; needs designer review: cultural content, so
-- the gallery verdict is left to the designer.
--
-- SITE derivation (pure math, no require of the server MapSpec): MapSpec.ROAD ringCentre 144,
-- ringWidth 12 -> inner edge r 138; inset 18 -> site radius r 120. Angle 30 degrees measured from
-- +Z in the MapSpec.rotatePoint convention, so centre = (120*sin30, 120*cos30) = (60, 103.92),
-- yaw = 30 and local +Z (the door side) points radially outward toward the ring. This sits on the
-- INNER / village side of the ring, clear of the ring corridor r 138..150 and the 222..246 gap.
-- keepOutRects: pakrt hub keep-out spans x 42..94, z 49..87 (site z 104 clear); LAPANGAN spans
-- x<=36 (site x 60 clear); PLAZA z<=42; RoadSouth |x|<=14; the pakrt hub itself is at (68,68).
-- Roof radius 6.2 keeps every staged part inside r 127, and the approach corridor ends at r 134,
-- before the ring edge. No new camera is introduced; review reuses the round-9 render path.

local Data = {}

Data.id = "musala_r8"
Data.familyId = "musala_r8"
Data.folderName = "LookDevMusalaR8_musala_r8"

Data.stageAttribute = "LookDevMusalaR8"
Data.kindAttribute = "MusalaKind"
Data.gaugeName = "MusalaDoorGauge"
Data.doorWidthAttribute = "DoorW"
Data.doorHeightAttribute = "DoorH"
Data.doorDepthAttribute = "DoorD"

Data.KIND = {
	base = "base",
	wall = "wall",
	post = "post",
	door = "door",
	gauge = "door_gauge",
	window = "window",
	roof = "roof",
	horn = "horn",
	wudhu = "wudhu",
	shoes = "shoes",
}
-- The gauge is staged as a harness probe, not counted as architecture.
Data.KINDS = { "base", "wall", "post", "door", "window", "roof", "horn", "wudhu", "shoes" }

Data.MIN_PARTS = 25

Data.DOOR_W = 3
Data.DOOR_H = 5.4
Data.DOOR_D = 2
local DOOR_BOTTOM = 0.4
Data.DOOR = {
	lx = 0,
	ly = DOOR_BOTTOM + Data.DOOR_H / 2,
	lz = 5,
	bottom = DOOR_BOTTOM,
}
Data.GAUGE_SIZE = { Data.DOOR_W, Data.DOOR_H, Data.DOOR_D }

-- The clear approach: local x -2..2, local z 6.7..14 (r 120 -> 134), door outward. Steps end at
-- local z 6.55; wudhu and shoe rack sit at local x -6.2..-3.0 and 3.2..5.8, outside this lane.
Data.CORRIDOR = { minLx = -2, maxLx = 2, minLz = 6.7, maxLz = 14 }
Data.OVERLAP_TOL = 0.05

Data.SITE = {
	angleDeg = 30,
	insetFromInnerEdge = 18,
	fallbackGroundY = 0.5,
}

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Green roof uses the subdued "daun"
-- palette from the hub-prop candidates; no built-in green material is in the allowlist. Material
-- tokens must name REAL engine materials: the stale Painted token is NOT one in Studio, so
-- walls/glass/roof use Plastic and keep their colour via Color3.
Data.COLOURS = {
	stone = { 158, 156, 148 },
	wall = { 150, 138, 116 },
	wood = { 104, 78, 52 },
	post = { 92, 68, 44 },
	green = { 111, 138, 63 },
	greenDark = { 86, 112, 48 },
	metal = { 190, 194, 196 },
	glass = { 176, 205, 214 },
	water = { 96, 156, 176 },
	shoe = { 58, 58, 62 },
}
Data.MATERIALS = {
	stone = "Concrete",
	wall = "Plastic",
	wood = "WoodPlanks",
	post = "Wood",
	green = "Plastic",
	greenDark = "Plastic",
	metal = "Metal",
	glass = "Plastic",
	water = "Water",
	shoe = "SmoothPlastic",
}

-- centre.y is the ground height; the applier overwrites it with MapSpec.GROUND_Y before staging.
function Data.centre(road: any?): any
	local ringCentre = if road and type(road.ringCentre) == "number" then road.ringCentre else 144
	local ringWidth = if road and type(road.ringWidth) == "number" then road.ringWidth else 12
	local radius = ringCentre - ringWidth / 2 - Data.SITE.insetFromInnerEdge
	local angle = math.rad(Data.SITE.angleDeg)
	return {
		x = math.sin(angle) * radius,
		y = Data.SITE.fallbackGroundY,
		z = math.cos(angle) * radius,
		yaw = Data.SITE.angleDeg,
		radius = radius,
	}
end

-- Same XZ convention as MapSpec.rotatePoint: local +Z maps to (sin yaw, cos yaw), local +X to
-- (cos yaw, -sin yaw). ly is a centre height above centre.y (the ground).
function Data.sitePoint(centre: any, yaw: number, lx: number, ly: number, lz: number): (number, number, number)
	local angle = math.rad(yaw)
	local cos, sin = math.cos(angle), math.sin(angle)
	return centre.x + lx * cos + lz * sin, centre.y + ly, centre.z - lx * sin + lz * cos
end

function Data.corridorCorners(): { { lx: number, lz: number } }
	local c = Data.CORRIDOR
	return {
		{ lx = c.minLx, lz = c.minLz },
		{ lx = c.maxLx, lz = c.minLz },
		{ lx = c.minLx, lz = c.maxLz },
		{ lx = c.maxLx, lz = c.maxLz },
	}
end

-- A recipe's lx/lz are site-local offsets; ly is the part CENTRE above ground.
local function part(
	name: string,
	kind: string,
	lx: number,
	ly: number,
	lz: number,
	size: { number },
	colour: string,
	material: string
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
	}
end

local recipes = {
	-- Platform and two low steps. The steps stop at local z 6.55, before the approach corridor.
	part("base_platform", "base", 0, 0.2, 0, { 12, 0.4, 10 }, "stone", "stone"),
	part("base_step_high", "base", 0, 0.12, 5.5, { 4.4, 0.24, 0.7 }, "stone", "stone"),
	part("base_step_low", "base", 0, 0.06, 6.2, { 5, 0.12, 0.7 }, "stone", "stone"),

	-- Plain walls: front wall split around a 3-stud doorway, with a lintel above it.
	part("wall_back", "wall", 0, 4.2, -4.75, { 11.6, 7.6, 0.5 }, "wall", "wall"),
	part("wall_left", "wall", -5.75, 4.2, 0, { 0.5, 7.6, 9.5 }, "wall", "wall"),
	part("wall_right", "wall", 5.75, 4.2, 0, { 0.5, 7.6, 9.5 }, "wall", "wall"),
	part("wall_front_left", "wall", -3.65, 4.2, 4.75, { 3.7, 7.6, 0.5 }, "wall", "wall"),
	part("wall_front_right", "wall", 3.65, 4.2, 4.75, { 3.7, 7.6, 0.5 }, "wall", "wall"),
	part("wall_lintel", "wall", 0, 6.9, 4.75, { 3.6, 2.2, 0.5 }, "wall", "wall"),

	-- Four corner posts.
	part("post_nw", "post", -5.6, 4.5, -4.6, { 0.8, 8.2, 0.8 }, "post", "post"),
	part("post_ne", "post", 5.6, 4.5, -4.6, { 0.8, 8.2, 0.8 }, "post", "post"),
	part("post_sw", "post", -5.6, 4.5, 4.6, { 0.8, 8.2, 0.8 }, "post", "post"),
	part("post_se", "post", 5.6, 4.5, 4.6, { 0.8, 8.2, 0.8 }, "post", "post"),

	-- Door frame: inner edges at +/-1.5 leave exactly DOOR_W = 3 clear.
	part("door_jamb_left", "door", -1.7, 3.1, 5, { 0.4, 5.4, 1 }, "wood", "wood"),
	part("door_jamb_right", "door", 1.7, 3.1, 5, { 0.4, 5.4, 1 }, "wood", "wood"),
	part("door_header", "door", 0, 5.95, 5, { 4.2, 0.5, 1 }, "wood", "wood"),

	-- Three modest windows, each a pane and a sill.
	part("window_front_left", "window", -3.6, 5.4, 5.03, { 2.2, 1.8, 0.12 }, "glass", "glass"),
	part("window_front_left_sill", "window", -3.6, 4.35, 5.15, { 2.6, 0.18, 0.5 }, "wood", "wood"),
	part("window_front_right", "window", 3.6, 5.4, 5.03, { 2.2, 1.8, 0.12 }, "glass", "glass"),
	part("window_front_right_sill", "window", 3.6, 4.35, 5.15, { 2.6, 0.18, 0.5 }, "wood", "wood"),
	part("window_side_left", "window", -6.03, 5.4, 0, { 0.12, 1.8, 2.2 }, "glass", "glass"),
	part("window_side_left_sill", "window", -6.15, 4.35, 0, { 0.5, 0.18, 2.6 }, "wood", "wood"),

	-- Tiered green roof: flattened Cylinder tiers and a small Sphere finial. Plain RGB only.
	part("roof_tier_low", "roof", 0, 8.9, 0, { 12.4, 0.6, 12.4 }, "green", "green"),
	part("roof_tier_mid", "roof", 0, 9.5, 0, { 11.5, 0.6, 11.5 }, "greenDark", "greenDark"),
	part("roof_tier_top", "roof", 0, 10.1, 0, { 8, 0.6, 8 }, "green", "green"),
	part("roof_finial", "roof", 0, 10.9, 0, { 1, 1, 1 }, "greenDark", "greenDark"),

	-- Pengeras suara horn: pole, bracket and a small stacked horn at the top.
	part("horn_base", "horn", 4.8, 0.6, -4.3, { 1.2, 1.2, 1.2 }, "stone", "stone"),
	part("horn_pole", "horn", 4.8, 8.2, -4.3, { 0.35, 14, 0.35 }, "wood", "wood"),
	part("horn_bracket", "horn", 4.8, 14.4, -4.3, { 1.6, 0.25, 0.35 }, "metal", "metal"),
	part("horn_stem", "horn", 4.8, 14.9, -4.3, { 0.14, 0.6, 0.14 }, "metal", "metal"),
	part("horn_mouth", "horn", 4.8, 15.2, -4.3, { 0.9, 0.5, 0.9 }, "metal", "metal"),
	part("horn_cap", "horn", 4.8, 15.5, -4.3, { 0.55, 0.16, 0.55 }, "metal", "metal"),

	-- Wudhu area, left of the approach and outside its lane.
	part("wudhu_pad", "wudhu", -4.6, 0.1, 8, { 3.2, 0.2, 2.6 }, "stone", "stone"),
	part("wudhu_basin", "wudhu", -4.6, 0.55, 8.4, { 2.4, 0.7, 1.4 }, "stone", "stone"),
	part("wudhu_water", "wudhu", -4.6, 0.93, 8.4, { 2, 0.08, 1.1 }, "water", "water"),
	part("wudhu_riser", "wudhu", -4.6, 1.8, 7.5, { 0.2, 2.4, 0.2 }, "metal", "metal"),
	part("wudhu_spout", "wudhu", -4.6, 2.95, 7.95, { 0.2, 0.2, 1 }, "metal", "metal"),
	part("wudhu_handle", "wudhu", -4.6, 3.15, 7.5, { 0.6, 0.16, 0.16 }, "metal", "metal"),
	part("wudhu_footrest", "wudhu", -4.6, 0.3, 9.2, { 2, 0.2, 0.4 }, "stone", "stone"),

	-- Shoe rack, right of the approach: four uprights, two shelves, four shoes.
	part("shoes_post_fl", "shoes", 3.3, 1.6, 7.5, { 0.2, 3.2, 0.2 }, "wood", "wood"),
	part("shoes_post_fr", "shoes", 5.7, 1.6, 7.5, { 0.2, 3.2, 0.2 }, "wood", "wood"),
	part("shoes_post_bl", "shoes", 3.3, 1.6, 8.5, { 0.2, 3.2, 0.2 }, "wood", "wood"),
	part("shoes_post_br", "shoes", 5.7, 1.6, 8.5, { 0.2, 3.2, 0.2 }, "wood", "wood"),
	part("shoes_shelf_low", "shoes", 4.5, 0.7, 8, { 2.7, 0.16, 1.2 }, "wood", "wood"),
	part("shoes_shelf_high", "shoes", 4.5, 2.4, 8, { 2.7, 0.16, 1.2 }, "wood", "wood"),
	part("shoes_pair_01", "shoes", 3.85, 1, 7.8, { 0.5, 0.3, 0.9 }, "shoe", "shoe"),
	part("shoes_pair_02", "shoes", 4.55, 1, 8.2, { 0.5, 0.3, 0.9 }, "shoe", "shoe"),
	part("shoes_pair_03", "shoes", 5.15, 1, 7.8, { 0.5, 0.3, 0.9 }, "shoe", "shoe"),
	part("shoes_pair_04", "shoes", 4.5, 2.7, 8, { 0.5, 0.3, 0.9 }, "shoe", "shoe"),
}

function Data.parts(): { any }
	return table.clone(recipes)
end

function Data.gauge(): any
	return {
		name = Data.gaugeName,
		kind = Data.KIND.gauge,
		lx = Data.DOOR.lx,
		ly = Data.DOOR.ly,
		lz = Data.DOOR.lz,
		size = Data.GAUGE_SIZE,
		colour = "metal",
		material = "metal",
	}
end

function Data.gaugeDims(): { number }
	return table.clone(Data.GAUGE_SIZE)
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
