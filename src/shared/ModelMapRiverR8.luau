--!strict
-- ModelMapRiverR8: pure data for the OFF-BY-DEFAULT "river_r8" LookDev candidate
-- (WORK_QUEUE section M item 73, redone in section O item 141). River-bank plants from the baked
-- vegetation list, twelve half-buried boulder stand-ins, a second pair of bridge rails with an
-- 8-stud clear walking corridor, and six stepping stones on the banks near the bridge.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. The applier
-- (src/server/World/LookDevRiverR8.luau) resolves every species to an ID already recorded in
-- Shared.ModelMapVegetationR4 / Shared.ModelMapVegetationR6 and clones it via LookDevAssetLoader.
-- Rocks: no verified rock MODEL id exists in any shared ModelMap* module (only Rock textures in
-- TextureMapR3/R4 and the procedural FloraRock), so two procedural shapes (Ball, squashed Wedge)
-- are the documented stand-ins; the applier never invents an asset ID.
-- RIVER_CENTRE mirrors MapSpec.riverCentreZ so this module stays pure; the applier passes the real
-- MapSpec function to bankPlants()/bankRocks().

local ModelMapRiverR8 = {}

ModelMapRiverR8.id = "river_r8"
ModelMapRiverR8.folderName = "LookDevRiverR8_river_r8"
ModelMapRiverR8.MIN_BANK_VEG = 40
ModelMapRiverR8.MIN_SPECIES = 4
ModelMapRiverR8.MIN_TALL = 6
ModelMapRiverR8.MIN_ROCKS = 12
ModelMapRiverR8.BRIDGE_WIDTH = 10
ModelMapRiverR8.WALKABLE_MIN = 8
ModelMapRiverR8.BRIDGE_Z0 = 276
ModelMapRiverR8.BRIDGE_Z1 = 332
ModelMapRiverR8.BRIDGE_CENTRE_Z = 304
ModelMapRiverR8.BANK_OFFSET = 18 -- channel half 14 + bank shelf half 4
ModelMapRiverR8.VEG_KINDS = { "talas", "keladi", "bambu", "alang-alang" }

local RAIL_X = 4.5 -- centre of a 1-stud rail: inner face exactly 4 from bridge centre x=0
local RAIL_THICKNESS = 1
local POST_EVERY = 7

-- Mirrors MapSpec.riverCentreZ(x) = 304 + 12 sin(2 pi x / 320), kept pure for specs.
function ModelMapRiverR8.RIVER_CENTRE(x: number): number
	return 304 + 12 * math.sin(2 * math.pi * x / 320)
end

function ModelMapRiverR8.bridgeSides(): { number }
	return { -1, 1 }
end

-- One continuous rail per side plus its post z positions. Inner rail faces sit at |x| = 4,
-- leaving exactly WALKABLE_MIN = 8 studs clear between them.
function ModelMapRiverR8.railLayout(): { any }
	local postZs = {}
	for z = ModelMapRiverR8.BRIDGE_Z0 + 2, ModelMapRiverR8.BRIDGE_Z1 - 2, POST_EVERY do
		postZs[#postZs + 1] = z
	end

	local out = {}
	for index, side in ipairs(ModelMapRiverR8.bridgeSides()) do
		out[index] = {
			Side = if side < 0 then "left" else "right",
			x = side * RAIL_X,
			z0 = ModelMapRiverR8.BRIDGE_Z0,
			z1 = ModelMapRiverR8.BRIDGE_Z1,
			thickness = RAIL_THICKNESS,
			postZs = postZs,
		}
	end
	return out
end

-- Deterministic placements on both bank shelves: z = centreZ -/+ BANK_OFFSET. Species cycle in
-- talas/keladi/bambu/alang-alang order. The caller supplies the centreline function and x range;
-- with (-48, 48, 2) there are 56 placements inside 40 studs of the bridge centre (0, 304).
function ModelMapRiverR8.bankVeg(centreZFn: (number) -> number, xMin: number, xMax: number, step: number): { any }
	local out = {}
	if step <= 0 or xMax < xMin then
		return out
	end
	local index = 0
	local x = xMin
	while x <= xMax do
		local centreZ = centreZFn(x)
		for _, bank in ipairs({ "south", "north" }) do
			index += 1
			local z = if bank == "south"
				then centreZ - ModelMapRiverR8.BANK_OFFSET
				else centreZ + ModelMapRiverR8.BANK_OFFSET
			out[#out + 1] = {
				x = x,
				z = z,
				Side = bank,
				Species = ModelMapRiverR8.VEG_KINDS[(index - 1) % #ModelMapRiverR8.VEG_KINDS + 1],
				VegX = x,
				VegZ = z,
			}
		end
		x += step
	end
	return out
end

-- Item-141 redo: five real species from the baked vegetation list. Species cycle talas, keladi,
-- alang-alang, bambu, kelapa, bambu so bambu/kelapa (Tall=true, staged at 18/22 studs) are common.
-- Placements skip |x| <= 6 (the 10-wide deck footprint), sit at z = centreZ -/+ BANK_OFFSET on
-- both banks, and 54 of them land within 40 studs of the bridge centre (0, 304) — well over
-- MIN_BANK_VEG = 40. Deterministic under Lune and Studio; no engine APIs.
local PLANT_CYCLE = { "talas", "keladi", "alang-alang", "bambu", "kelapa", "bambu" }
local TALL_SPECIES = { bambu = true, kelapa = true }
local PLANT_X_MIN, PLANT_X_MAX, PLANT_X_STEP = -36, 36, 2
local PLANT_BRIDGE_GAP = 6 -- BRIDGE_WIDTH / 2 + 1

function ModelMapRiverR8.bankPlants(centreZFn: ((number) -> number)?): { any }
	local centre = centreZFn or ModelMapRiverR8.RIVER_CENTRE
	local out = {}
	local index = 0
	local x = PLANT_X_MIN
	while x <= PLANT_X_MAX do
		if math.abs(x) > PLANT_BRIDGE_GAP then
			for _, bank in ipairs({ "south", "north" }) do
				index += 1
				local z = centre(x)
					+ (if bank == "south" then -ModelMapRiverR8.BANK_OFFSET else ModelMapRiverR8.BANK_OFFSET)
				local species = PLANT_CYCLE[(index - 1) % #PLANT_CYCLE + 1]
				out[#out + 1] = {
					x = x,
					z = z,
					Side = bank,
					Species = species,
					Tall = TALL_SPECIES[species] == true,
					Height = if species == "kelapa"
						then 22
						elseif species == "bambu" then 18
						elseif species == "alang-alang" then 2
						else 2.5,
					VegX = x,
					VegZ = z,
				}
			end
		end
		x += PLANT_X_STEP
	end
	return out
end

-- Twelve boulders, six per bank, three studs outside the plant row. Two procedural stand-ins
-- (Ball, squashed Wedge), every axis in [1, 4] studs, centre at GROUND_Y - 0.1 * height so the
-- lower half is buried. No rock model ID exists in the shared maps, so none is invented.
local ROCK_X = { -24, -14, -6, 6, 14, 24 }
local ROCK_SHAPES = { "ball", "wedge" }
local ROCK_SIZES = {
	ball = { 2.4, 2.0, 2.2 },
	wedge = { 3.2, 1.6, 2.8 },
}
local ROCK_GROUND_Y = 0.5 -- MapSpec.GROUND_Y; the applier reads the live value.

function ModelMapRiverR8.bankRocks(centreZFn: ((number) -> number)?): { any }
	local centre = centreZFn or ModelMapRiverR8.RIVER_CENTRE
	local out = {}
	for _, bank in ipairs({ "south", "north" }) do
		for index, x in ipairs(ROCK_X) do
			local shape = ROCK_SHAPES[(index - 1) % #ROCK_SHAPES + 1]
			local size = ROCK_SIZES[shape]
			local z = centre(x)
				+ (if bank == "south" then -(ModelMapRiverR8.BANK_OFFSET + 3) else ModelMapRiverR8.BANK_OFFSET + 3)
			out[#out + 1] = {
				x = x,
				z = z,
				y = ROCK_GROUND_Y - size[2] * 0.1,
				Side = bank,
				Shape = shape,
				size = { size[1], size[2], size[3] },
			}
		end
	end
	return out
end

-- Six flat stones, three on each bank, outside the 10-wide deck footprint (|x| <= 5) and outside
-- the 28-wide channel (|z - centreZ| = 18 > 14).
function ModelMapRiverR8.steppingStones(): { any }
	local slots = {
		{ Side = "south", x = -20 },
		{ Side = "south", x = -12 },
		{ Side = "south", x = 12 },
		{ Side = "north", x = -12 },
		{ Side = "north", x = 12 },
		{ Side = "north", x = 20 },
	}
	local out = {}
	for index, slot in ipairs(slots) do
		local z = ModelMapRiverR8.RIVER_CENTRE(slot.x)
			+ (if slot.Side == "south" then -ModelMapRiverR8.BANK_OFFSET else ModelMapRiverR8.BANK_OFFSET)
		out[index] = {
			x = slot.x,
			y = 0.25,
			z = z,
			Side = slot.Side,
			size = { 3.5, 0.5, 3 },
		}
	end
	return out
end

return ModelMapRiverR8
