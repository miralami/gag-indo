--!strict
-- ModelMapLumbungR8: pure data for the OFF-BY-DEFAULT "lumbung_r8" LookDev candidate
-- (WORK_QUEUE section N item 111). One lumbung padi on stilts (raised floor, six stilts, walls,
-- tiered thatch roof, clear door with an invisible gauge, ladder) plus, at each of three house hubs
-- (pasar, gelap, pakrt), a bamboo garden fence with toga herb and chilli pots, a tempat jemur padi
-- drying mat and rake marks on a well-swept yard. All geometry is ORIGINAL PARTS staged by
-- src/server/World/LookDevLumbungR8.luau: no asset IDs, no brand marks, no terrain edit and no
-- engine API in this module. The SERVER applier owns the real Ground voxel pads and their exact
-- LIFO restore; this module only publishes the yard sample centres and their snapped cell boxes.
-- No new camera: review reuses the existing REVIEW_ROUND9.md render path.
--
-- SITE derivation: every position comes from MapSpec.hub(key) and MapSpec.hubPoint(hub, lx, lz).
-- The barn sits at a hub-local offset from pasar; the three yards sit just beyond each house's
-- front eave, inside its clearing and clear of PLAZA, LAPANGAN and the other hub keep-outs. No
-- world-coordinate literal appears in the applier. Visual/designer verdict stays pending.

local Data = {}

Data.id = "lumbung_r8"
Data.familyId = "lumbung_r8"
Data.folderName = "LookDevLumbungR8_lumbung_r8"

Data.stageAttribute = "LookDevLumbungR8"
Data.kindAttribute = "LumbungKind"
Data.gaugeName = "LumbungDoorGauge"
Data.doorWidthAttribute = "DoorW"
Data.doorHeightAttribute = "DoorH"
Data.doorDepthAttribute = "DoorD"

Data.KIND = {
	stilt = "stilt",
	floor = "floor",
	wall = "wall",
	door = "door",
	roof = "roof",
	ladder = "ladder",
	vent = "vent",
	fence = "fence",
	toga = "toga",
	chilli = "chilli",
	mat = "mat",
	rake = "rake",
	gauge = "door_gauge",
}
-- The gauge is a harness probe, not architecture: it is excluded from KINDS and counts().
Data.KINDS = {
	"stilt",
	"floor",
	"wall",
	"door",
	"roof",
	"ladder",
	"vent",
	"fence",
	"toga",
	"chilli",
	"mat",
	"rake",
}

Data.MIN_PARTS = 80

Data.DOOR_W = 3.2
Data.DOOR_H = 4.8
Data.DOOR_D = 2
local DOOR_BOTTOM = 3.6
Data.DOOR = {
	lx = 0,
	ly = DOOR_BOTTOM + Data.DOOR_H / 2,
	lz = 5,
	bottom = DOOR_BOTTOM,
}
Data.GAUGE_SIZE = { Data.DOOR_W, Data.DOOR_H, Data.DOOR_D }

-- Terrain authoring grid; the applier and the harness snap with the same number.
Data.VOXEL = 4

Data.HOUSE_KEYS = { "pasar", "gelap", "pakrt" }
Data.BARN = {
	hubKey = "pasar",
	lx = -18,
	lz = 30,
	yawOffsetDeg = 0,
	fallbackGroundY = 0.5,
}

-- One yard sample per house. lx/lz are hub-local; sx/sz are the Ground pad footprint in studs.
-- The pads start just beyond the facade door gauge and stay inside each hub clearing.
Data.YARDS = {
	{ key = "pasar", lx = 0, lz = 32, sx = 12, sz = 8 },
	{ key = "gelap", lx = 0, lz = 20, sx = 12, sz = 8 },
	{ key = "pakrt", lx = -13, lz = 24, sx = 12, sz = 8 },
}
Data.YARD_COUNT = #Data.YARDS

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Material tokens must name REAL built-in
-- materials: the stale Painted token is not one in Studio, so colour comes from Color3 instead.
Data.COLOURS = {
	wood = { 104, 78, 52 },
	woodDark = { 72, 52, 34 },
	thatch = { 154, 128, 72 },
	thatchDark = { 124, 98, 54 },
	ground = { 132, 108, 74 },
	groundDark = { 110, 88, 60 },
	bamboo = { 150, 158, 88 },
	leaf = { 86, 124, 58 },
	herb = { 74, 132, 70 },
	chilli = { 164, 48, 38 },
	pot = { 142, 86, 58 },
	fabric = { 206, 196, 166 },
	padi = { 196, 166, 84 },
	stone = { 146, 142, 132 },
	metal = { 178, 180, 176 },
}
Data.MATERIALS = {
	wood = "Wood",
	woodDark = "Wood",
	thatch = "Plastic",
	thatchDark = "Plastic",
	ground = "Ground",
	groundDark = "Ground",
	bamboo = "WoodPlanks",
	-- The stale Leaf token is not a real engine material in Studio (like old Painted): green from Color3.
	leaf = "Plastic",
	herb = "Plastic",
	chilli = "Plastic",
	pot = "Concrete",
	fabric = "Fabric",
	padi = "Plastic",
	stone = "Concrete",
	metal = "Metal",
}

-- Same XZ convention as MapSpec.rotatePoint: local +Z maps to (sin yaw, cos yaw), local +X to
-- (cos yaw, -sin yaw). ly is a centre height above the ground plane.
local function rotate(hub: any, lx: number, lz: number): (number, number)
	local angle = math.rad(hub.yaw)
	local cos, sin = math.cos(angle), math.sin(angle)
	return hub.x + lx * cos + lz * sin, hub.z - lx * sin + lz * cos
end

function Data.barnCentre(hub: any): any
	local x, z = rotate(hub, Data.BARN.lx, Data.BARN.lz)
	return {
		x = x,
		y = Data.BARN.fallbackGroundY,
		z = z,
		yaw = hub.yaw + Data.BARN.yawOffsetDeg,
	}
end

function Data.sitePoint(centre: any, lx: number, ly: number, lz: number): (number, number, number)
	local angle = math.rad(centre.yaw)
	local cos, sin = math.cos(angle), math.sin(angle)
	return centre.x + lx * cos + lz * sin, centre.y + ly, centre.z - lx * sin + lz * cos
end

-- Pure yard sample list. `hubs` is a table keyed by Data.HOUSE_KEYS, each entry carrying the
-- MapSpec.hub fields x/z/yaw. No engine API is used; the applier reads the same hubs from MapSpec.
function Data.yards(hubs: any?): { any }
	local out = {}
	if type(hubs) ~= "table" then
		return out
	end
	for _, yard in ipairs(Data.YARDS) do
		local hub = hubs[yard.key]
		if type(hub) == "table" and type(hub.x) == "number" and type(hub.z) == "number" then
			local x, z = rotate(hub, yard.lx, yard.lz)
			out[#out + 1] = {
				key = yard.key,
				lx = yard.lx,
				lz = yard.lz,
				x = x,
				z = z,
				sx = yard.sx,
				sz = yard.sz,
				region = Data.yardRegion(x, z, yard.sx, yard.sz),
			}
		end
	end
	return out
end

-- Outward-snapped 4-stud XZ cells covering a yard pad. The applier snapshots and fills this exact
-- region; the harness samples every cell centre independently.
function Data.yardRegion(x: number, z: number, sx: number, sz: number): any
	local minX = math.floor((x - sx / 2) / Data.VOXEL) * Data.VOXEL
	local maxX = math.ceil((x + sx / 2) / Data.VOXEL) * Data.VOXEL
	local minZ = math.floor((z - sz / 2) / Data.VOXEL) * Data.VOXEL
	local maxZ = math.ceil((z + sz / 2) / Data.VOXEL) * Data.VOXEL
	if maxX - minX < Data.VOXEL then
		maxX = minX + Data.VOXEL
	end
	if maxZ - minZ < Data.VOXEL then
		maxZ = minZ + Data.VOXEL
	end
	local cells = {}
	for cx = minX, maxX - Data.VOXEL, Data.VOXEL do
		for cz = minZ, maxZ - Data.VOXEL, Data.VOXEL do
			cells[#cells + 1] = {
				x = cx + Data.VOXEL / 2,
				z = cz + Data.VOXEL / 2,
			}
		end
	end
	return {
		minX = minX,
		maxX = maxX,
		minZ = minZ,
		maxZ = maxZ,
		cells = cells,
	}
end

local function part(
	name: string,
	kind: string,
	scope: string,
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
		scope = scope,
		lx = lx,
		ly = ly,
		lz = lz,
		size = size,
		colour = colour,
		material = material,
	}
end

local barn = {
	-- Six stilts lift the floor clear of the yard.
	part("barn_stilt_1", "stilt", "barn", -5, 1.6, -4, { 0.5, 3.2, 0.5 }, "wood", "wood"),
	part("barn_stilt_2", "stilt", "barn", 5, 1.6, -4, { 0.5, 3.2, 0.5 }, "wood", "wood"),
	part("barn_stilt_3", "stilt", "barn", -5, 1.6, 0, { 0.5, 3.2, 0.5 }, "wood", "wood"),
	part("barn_stilt_4", "stilt", "barn", 5, 1.6, 0, { 0.5, 3.2, 0.5 }, "wood", "wood"),
	part("barn_stilt_5", "stilt", "barn", -5, 1.6, 4, { 0.5, 3.2, 0.5 }, "wood", "wood"),
	part("barn_stilt_6", "stilt", "barn", 5, 1.6, 4, { 0.5, 3.2, 0.5 }, "wood", "wood"),

	-- Raised floor and two beams.
	part("barn_floor_slab", "floor", "barn", 0, 3.35, 0, { 12, 0.5, 10 }, "woodDark", "woodDark"),
	part("barn_floor_beam_l", "floor", "barn", -4, 3.05, 0, { 0.6, 0.4, 10 }, "wood", "wood"),
	part("barn_floor_beam_r", "floor", "barn", 4, 3.05, 0, { 0.6, 0.4, 10 }, "wood", "wood"),

	-- Walls leave a 3.2-stud clear doorway at local x -1.6..1.6.
	part("barn_wall_back", "wall", "barn", 0, 6.2, -4.75, { 11.6, 5, 0.4 }, "wood", "wood"),
	part("barn_wall_left", "wall", "barn", -5.75, 6.2, 0, { 0.4, 5, 9.5 }, "wood", "wood"),
	part("barn_wall_right", "wall", "barn", 5.75, 6.2, 0, { 0.4, 5, 9.5 }, "wood", "wood"),
	part("barn_wall_front_l", "wall", "barn", -3.7, 6.2, 4.75, { 3.8, 5, 0.4 }, "wood", "wood"),
	part("barn_wall_front_r", "wall", "barn", 3.7, 6.2, 4.75, { 3.8, 5, 0.4 }, "wood", "wood"),
	part("barn_wall_lintel", "wall", "barn", 0, 8.6, 4.75, { 3.6, 0.4, 0.4 }, "woodDark", "woodDark"),

	-- Door frame; the invisible gauge is staged separately at Data.DOOR.
	part("barn_door_jamb_l", "door", "barn", -1.8, 6, 4.75, { 0.4, 4.8, 0.6 }, "woodDark", "woodDark"),
	part("barn_door_jamb_r", "door", "barn", 1.8, 6, 4.75, { 0.4, 4.8, 0.6 }, "woodDark", "woodDark"),
	part("barn_door_header", "door", "barn", 0, 8.6, 4.75, { 4, 0.4, 0.6 }, "woodDark", "woodDark"),

	-- Tiered thatch roof; colour comes from plain RGB, never from an asset.
	part("barn_roof_low", "roof", "barn", 0, 9.4, 0, { 13, 0.6, 11 }, "thatch", "thatch"),
	part("barn_roof_mid", "roof", "barn", 0, 10.1, 0, { 11, 0.6, 9.5 }, "thatchDark", "thatchDark"),
	part("barn_roof_top", "roof", "barn", 0, 10.8, 0, { 8, 0.6, 7 }, "thatch", "thatch"),
	part("barn_roof_ridge", "roof", "barn", 0, 11.3, 0, { 1, 0.6, 8 }, "thatchDark", "thatchDark"),

	-- Ladder up to the raised floor: two rails and four rungs.
	part("barn_ladder_rail_l", "ladder", "barn", -1.2, 1.9, 5.8, { 0.24, 3.8, 0.24 }, "wood", "wood"),
	part("barn_ladder_rail_r", "ladder", "barn", 1.2, 1.9, 5.8, { 0.24, 3.8, 0.24 }, "wood", "wood"),
	part("barn_ladder_rung_1", "ladder", "barn", 0, 0.8, 5.8, { 2.6, 0.18, 0.3 }, "woodDark", "woodDark"),
	part("barn_ladder_rung_2", "ladder", "barn", 0, 1.7, 5.8, { 2.6, 0.18, 0.3 }, "woodDark", "woodDark"),
	part("barn_ladder_rung_3", "ladder", "barn", 0, 2.6, 5.8, { 2.6, 0.18, 0.3 }, "woodDark", "woodDark"),
	part("barn_ladder_rung_4", "ladder", "barn", 0, 3.5, 5.8, { 2.6, 0.18, 0.3 }, "woodDark", "woodDark"),

	-- Two small side vents.
	part("barn_vent_l", "vent", "barn", -5.95, 7, -2, { 0.12, 1.2, 2 }, "woodDark", "woodDark"),
	part("barn_vent_r", "vent", "barn", 5.95, 7, -2, { 0.12, 1.2, 2 }, "woodDark", "woodDark"),
}

-- One house yard kit, authored hub-locally around the yard centre. hx/hz are relative to the yard;
-- the applier adds Data.YARDS[key].lx/lz and rotates through MapSpec.hubPoint.
local houseKit = {
	part("fence_post_1", "fence", "", -5, 1.2, -3, { 0.25, 2.4, 0.25 }, "bamboo", "bamboo"),
	part("fence_post_2", "fence", "", 0, 1.2, -3, { 0.25, 2.4, 0.25 }, "bamboo", "bamboo"),
	part("fence_post_3", "fence", "", 5, 1.2, -3, { 0.25, 2.4, 0.25 }, "bamboo", "bamboo"),
	part("fence_rail_1", "fence", "", -2.5, 1.6, -3, { 5, 0.18, 0.18 }, "bamboo", "bamboo"),
	part("fence_rail_2", "fence", "", 2.5, 1.6, -3, { 5, 0.18, 0.18 }, "bamboo", "bamboo"),
	part("fence_rail_top", "fence", "", 0, 2.2, -3, { 10.2, 0.16, 0.16 }, "bamboo", "bamboo"),

	part("toga_pot", "toga", "", -4, 0.5, 1, { 1, 1, 1 }, "pot", "pot"),
	part("toga_leaf_1", "toga", "", -4.4, 1.4, 1, { 0.9, 1.2, 0.9 }, "herb", "herb"),
	part("toga_leaf_2", "toga", "", -3.6, 1.4, 1, { 0.9, 1.2, 0.9 }, "herb", "herb"),

	part("chilli_pot_1", "chilli", "", 3, 0.45, 1, { 0.9, 0.9, 0.9 }, "pot", "pot"),
	part("chilli_pot_2", "chilli", "", 4.5, 0.45, 1, { 0.9, 0.9, 0.9 }, "pot", "pot"),
	part("chilli_leaf_1", "chilli", "", 3, 1.25, 1, { 0.9, 1.1, 0.9 }, "chilli", "chilli"),
	part("chilli_leaf_2", "chilli", "", 4.5, 1.25, 1, { 0.9, 1.1, 0.9 }, "chilli", "chilli"),

	part("mat_cloth", "mat", "", 0, 0.06, 1.2, { 7, 0.08, 4.6 }, "fabric", "fabric"),
	part("mat_roller_l", "mat", "", -3.5, 0.16, 1.2, { 0.25, 0.22, 4.8 }, "woodDark", "woodDark"),
	part("mat_roller_r", "mat", "", 3.5, 0.16, 1.2, { 0.25, 0.22, 4.8 }, "woodDark", "woodDark"),
	part("mat_padi_1", "mat", "", -1.4, 0.28, 1.2, { 1.1, 0.3, 2.8 }, "padi", "padi"),
	part("mat_padi_2", "mat", "", 1.4, 0.28, 1.2, { 1.1, 0.3, 2.8 }, "padi", "padi"),

	part("rake_mark_l", "rake", "", -2.5, 0.03, 3, { 4.4, 0.04, 0.12 }, "groundDark", "groundDark"),
	part("rake_mark_r", "rake", "", 2.5, 0.03, 3, { 4.4, 0.04, 0.12 }, "groundDark", "groundDark"),
}

local recipes = table.clone(barn)
for _, key in ipairs(Data.HOUSE_KEYS) do
	for _, recipe in ipairs(houseKit) do
		recipes[#recipes + 1] = {
			name = key .. "_" .. recipe.name,
			kind = recipe.kind,
			scope = key,
			lx = recipe.lx,
			ly = recipe.ly,
			lz = recipe.lz,
			size = recipe.size,
			colour = recipe.colour,
			material = recipe.material,
		}
	end
end

function Data.parts(): { any }
	return table.clone(recipes)
end

function Data.gauge(): any
	return {
		name = Data.gaugeName,
		kind = Data.KIND.gauge,
		scope = "barn",
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
