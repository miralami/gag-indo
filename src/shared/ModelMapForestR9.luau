--!strict
-- ModelMapForestR9: pure data for the DEFAULT tropical BackgroundForest (WORK_QUEUE items 138/102,
-- V-D4 "tropical trees, no pines"). No engine APIs here: Greybox consumes placements() and builds
-- the trees. Every species ID is read from the verified vegetation_r4 map; none is invented.

local ModelMapVegetationR4 = require(script.Parent.ModelMapVegetationR4)

export type Placement = {
	x: number,
	z: number,
	yaw: number, -- radians, [0, 2*pi)
	scale: number, -- [0.85, 1.15]
	species: string,
	angle: number, -- integer degrees, part of the Model name
	layer: number, -- 1..7 ring, 8..9 hills, part of the Model name
	riverSide: boolean, -- z > 200 (palm bias)
}

type Hub = {
	key: string,
	x: number,
	z: number,
	width: number,
	depth: number,
	yaw: number,
}

export type ShadeAnchor = {
	x: number,
	z: number,
	species: string,
	angle: number, -- hub yaw in degrees, reused as the tree rotation
	layer: number, -- odd layer keeps the shade trees in the shadow-casting tier
	shade: boolean,
	hubKey: string,
}

local ModelMapForestR9 = {}

ModelMapForestR9.MIN_INSTANCES = 450
ModelMapForestR9.MIN_SPECIES = 4
ModelMapForestR9.FOLDER_NAME = "BackgroundForest"
ModelMapForestR9.NAME_PREFIX = "Tropical_"

ModelMapForestR9.SPECIES = { "kelapa", "mangga", "pisang", "bambu" } :: { string }

-- Verified R4 vegetation IDs, re-exported by reference (no literals, no new licences).
local R4_IDS = ModelMapVegetationR4.families.vegetation_r4.ids
ModelMapForestR9.IDS = {
	kelapa = R4_IDS.kelapa,
	mangga = R4_IDS.mangga,
	pisang = R4_IDS.pisang,
	bambu = R4_IDS.bambu,
} :: { [string]: number }

-- Ring bands 260..386 (layers 1..8). Item 268 removed the outer 408/444 bands: their trees read
-- as dark specks on the horizon. One compensating inner band (386 after 368) keeps the wall dense.
-- Up to 11 studs of radial jitter breaks up the "perfect circle" read while keeping every radius
-- below 400, so no placement lands on the horizon.
local BASE_RADII = { 260, 278, 296, 314, 332, 350, 368, 386 }
local RADIAL_JITTER = 12
local ANGLE_STEP = 2
local ANGLE_OFFSET = 2
local SUNSET_START = 130
local SUNSET_END = 230
local SKIP_NORTH_Z = -260
local SKIP_NORTH_X = 370
local SKIP_SOUTH_MIN = 250
local SKIP_SOUTH_MAX = 364
local RIVER_Z = 200

-- Kelapa is three times as likely on the river/south side; the inland mix still carries all four
-- species so RING_SPECIES >= 4 holds in either band.
local RIVER_SPECIES = { "kelapa", "kelapa", "kelapa", "pisang", "bambu", "mangga" } :: { string }
local INLAND_SPECIES = { "mangga", "bambu", "pisang", "mangga", "kelapa", "pisang" } :: { string }
local SHADE_SPECIES = { "mangga", "bambu", "pisang", "kelapa" } :: { string }

function ModelMapForestR9.placements(): { Placement }
	local result: { Placement } = {}
	for angle = 0, 359, ANGLE_STEP do
		for layer, base in ipairs(BASE_RADII) do
			local aDeg = (angle + (layer - 1) * ANGLE_OFFSET) % 360
			if aDeg >= SUNSET_START and aDeg <= SUNSET_END then
				continue -- sunset corridor stays open
			end
			local radius = base + ((angle * 3 + layer * 17) % RADIAL_JITTER)
			local rad = math.rad(aDeg)
			local x = math.cos(rad) * radius
			local z = math.sin(rad) * radius
			if z < SKIP_NORTH_Z and math.abs(x) < SKIP_NORTH_X then
				continue -- sawah terraces and Balai Desa slot
			end
			if z > SKIP_SOUTH_MIN and z < SKIP_SOUTH_MAX then
				continue -- river channel, banks and bridge
			end
			local riverSide = z > RIVER_Z
			local pool = if riverSide then RIVER_SPECIES else INLAND_SPECIES
			local species = pool[(angle * 7 + layer * 13) % #pool + 1]
			result[#result + 1] = {
				x = x,
				z = z,
				yaw = math.rad((angle * 37 + layer * 73) % 360),
				scale = 0.85 + ((angle * 5 + layer * 11) % 31) / 100,
				species = species,
				angle = angle,
				layer = layer,
				riverSide = riverSide,
			}
		end
	end
	return result
end

-- Mirrors MapSpec.rotatePoint: local +Z is the door side, local -Z the back of a hub. Kept local so
-- this module stays pure data (no engine API and no MapSpec dependency).
local function rotateOffset(hub: Hub, lx: number, lz: number): (number, number)
	local a = math.rad(hub.yaw)
	local cos, sin = math.cos(a), math.sin(a)
	return hub.x + lx * cos + lz * sin, hub.z - lx * sin + lz * cos
end

-- Q186 / Q262: four broadleaf/bamboo shade trees per hub, standing OUTSIDE the building (at least 6
-- studs from the footprint edge, so the 4 stud clearance spec holds with room for the crown) and off
-- the roads, plaza, lapangan and ring corridor. Offsets are hub-local { lx, lz }, local -Z is the back
-- and local +Z the door side. Pasar and Gelap sit in the dead-end alley, so Pasar uses its flanks and
-- Gelap its far (north) side; Pos Ronda keeps off the watchtower on its north-west shoulder.
local SHADE_OFFSETS: { [string]: { { number } } } = {
	pasar = { { 39, -21 }, { 39, -5 }, { -37, -13 }, { -37, 0 } },
	gelap = { { -10, -21 }, { 10, -21 }, { 0, -24 }, { -23, -7 } },
	warung = { { -13, -29 }, { 0, -29 }, { -33, -11 }, { 33, 0 } },
	ronda = { { -29, -6 }, { -29, 2 }, { -29, 10 }, { 29, 0 } },
	polisi = { { -12, -29 }, { 0, -29 }, { 31, 0 }, { 31, 6 } },
	pakrt = { { -12, -24 }, { 0, -24 }, { 12, -24 }, { -31, -8.5 } },
}

function ModelMapForestR9.shadeAnchors(hubs: { Hub }): { ShadeAnchor }
	local result: { ShadeAnchor } = {}
	for _, hub in ipairs(hubs) do
		local offsets = SHADE_OFFSETS[hub.key]
		if offsets == nil then
			-- Unknown hub: fall back to a spot well behind the back wall.
			offsets = { { 0, -hub.depth / 2 - 8 } }
		end
		for i, offset in ipairs(offsets) do
			local x, z = rotateOffset(hub, offset[1], offset[2])
			result[#result + 1] = {
				x = x,
				z = z,
				species = SHADE_SPECIES[i],
				angle = hub.yaw,
				layer = 1,
				shade = true,
				hubKey = hub.key,
			}
		end
	end
	return result
end

return ModelMapForestR9
