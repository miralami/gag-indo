--!strict
-- ModelMapRiverR8: pure data for the OFF-BY-DEFAULT "river_r8" LookDev candidate
-- (WORK_QUEUE section M item 73). River-bank vegetation, a second pair of bridge rails with an
-- 8-stud clear walking corridor, and six stepping stones on the banks near the bridge.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. Procedural Parts
-- are built by src/server/World/LookDevRiverR8.luau. RIVER_CENTRE mirrors MapSpec.riverCentreZ so
-- this module stays pure; the applier passes the real MapSpec function to bankVeg().

local ModelMapRiverR8 = {}

ModelMapRiverR8.id = "river_r8"
ModelMapRiverR8.folderName = "LookDevRiverR8_river_r8"
ModelMapRiverR8.MIN_BANK_VEG = 30
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
