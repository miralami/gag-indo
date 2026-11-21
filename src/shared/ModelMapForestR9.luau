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
	layer: number, -- 1..4 ring, 5..6 hills, part of the Model name
	riverSide: boolean, -- z > 200 (palm bias)
}

local ModelMapForestR9 = {}

ModelMapForestR9.MIN_INSTANCES = 250
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

-- Ring band 260..380, hills/beyond-400 band 400..460. Up to 11 studs of radial jitter keeps both
-- bands inside their limits while breaking up the "perfect circle" read.
local BASE_RADII = { 260, 296, 332, 368, 408, 444 }
local RADIAL_JITTER = 12
local ANGLE_STEP = 3
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

return ModelMapForestR9
