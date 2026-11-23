--!strict
-- ModelMapRiverFoamQ212: pure data for WORK_QUEUE item 212, a thin foam line along BOTH river banks.
-- No Roblox APIs, no Instances, no Enums, no asset IDs and no new colours: every descriptor is a
-- cheap Block Part at the MapSpec visible water edge. The server wires these descriptors into the
-- default Greybox (anchored, CanCollide=false, no prompts, tagged RiverFoam=true, clearly named).
--
-- Geometry mirrors src/server/World/MapSpec.luau MapSpec.river(): TERRAIN_HALF=400,
-- RIVER_SEGMENT=16, RIVER_HALF=14; each segment's south edge is min(z(x0),z(x1))-14 and its north
-- edge is max(z(x0),z(x1))+14. WATER_SURFACE_Y comes from the sibling ModelMapRiverR8 module, so
-- this file never invents a second water height. One 16-stud strip per segment per bank = 100 parts.

local RiverR8 = require(script.Parent.ModelMapRiverR8)

local Data = {}

Data.TAG = "RiverFoam"
Data.KIND_ATTR = "RiverFoamKind"
Data.KIND = "foam"

Data.MIN_COVERAGE = 0.60
Data.PERF_BUDGET = 120

-- Mirrored MapSpec.river() constants; checked against MapSpec in tests/specs/river_foam_q212_spec.
Data.TERRAIN_HALF = 400
Data.RIVER_SEGMENT = 16
Data.WATER_HALF = RiverR8.WATER_HALF

-- Sampling: one sample every 4 studs on each bank; a sample is covered when a live foam centre is
-- within 8.5 studs along X (16-stud strip + boundary slack) and 2.5 studs across the bank edge.
Data.BANK_SAMPLE_STEP = 4
Data.COVER_TOL_X = 0.5
Data.COVER_TOL_Z = 2.5

Data.FOAM_LENGTH = Data.RIVER_SEGMENT
Data.FOAM_WIDTH = 0.8
Data.FOAM_THICKNESS = 0.08
Data.FOAM_INSET = 0.4 -- keep the 0.8-wide strip just inside the visible water edge
Data.FOAM_Y = RiverR8.WATER_SURFACE_Y + 0.06

-- Existing Props.palette name ("kertas", #f3e9d2), never a new colour or asset ID.
Data.COLOUR = "kertas"
Data.MATERIAL = "SmoothPlastic"
Data.TRANSPARENCY = 0.45

local BANKS = { "south", "north" }

function Data.riverCentreZ(x: number): number
	return RiverR8.RIVER_CENTRE(x)
end

-- Mirrors MapSpec.river()'s conservative per-segment z union.
local function segmentAt(x: number): (number, number, number, number)
	local index = math.floor((x + Data.TERRAIN_HALF) / Data.RIVER_SEGMENT)
	local x0 = -Data.TERRAIN_HALF + index * Data.RIVER_SEGMENT
	local x1 = x0 + Data.RIVER_SEGMENT
	local zA, zB = Data.riverCentreZ(x0), Data.riverCentreZ(x1)
	return x0, x1, math.min(zA, zB), math.max(zA, zB)
end

-- Deterministic descriptors. South uses the segment's minimum centreline endpoint, north its
-- maximum, matching the water volumes MapSpec emits. `Side` is data, not an engine enum.
function Data.parts(): { { [string]: any } }
	local out = {}
	local index = 0
	for x0 = -Data.TERRAIN_HALF, Data.TERRAIN_HALF - Data.RIVER_SEGMENT, Data.RIVER_SEGMENT do
		local x1 = x0 + Data.RIVER_SEGMENT
		local zA, zB = Data.riverCentreZ(x0), Data.riverCentreZ(x1)
		local lo, hi = math.min(zA, zB), math.max(zA, zB)
		for _, bank in ipairs(BANKS) do
			index += 1
			local edgeZ = if bank == "south" then lo - Data.WATER_HALF else hi + Data.WATER_HALF
			local inset = if bank == "south" then Data.FOAM_INSET else -Data.FOAM_INSET
			out[#out + 1] = {
				name = `RiverFoam{bank == "south" and "South" or "North"}_{string.format("%03d", index)}`,
				kind = Data.KIND,
				Side = bank,
				segment = index,
				x = (x0 + x1) / 2,
				y = Data.FOAM_Y,
				z = edgeZ + inset,
				shape = "Block",
				size = { Data.FOAM_LENGTH, Data.FOAM_THICKNESS, Data.FOAM_WIDTH },
				colour = Data.COLOUR,
				material = Data.MATERIAL,
				transparency = Data.TRANSPARENCY,
			}
		end
	end
	return out
end

-- Pure coverage by sampling both banks. `foam` holds world-space centres from the LIVE tagged
-- parts (only visible ones are passed by the harness), so hiding a subset measurably fails.
-- Returns (fraction, coveredSamples, totalSamples).
function Data.coverage(foam: { { x: number, z: number } }?): (number, number, number)
	local pieces = foam or {}
	local covered, total = 0, 0
	local x = -Data.TERRAIN_HALF
	while x <= Data.TERRAIN_HALF do
		local _, _, lo, hi = segmentAt(x)
		for _, bank in ipairs(BANKS) do
			local edgeZ = if bank == "south" then lo - Data.WATER_HALF else hi + Data.WATER_HALF
			total += 1
			for _, piece in ipairs(pieces) do
				if
					type(piece.x) == "number"
					and type(piece.z) == "number"
					and math.abs(x - piece.x) <= Data.FOAM_LENGTH / 2 + Data.COVER_TOL_X
					and math.abs(edgeZ - piece.z) <= Data.COVER_TOL_Z
				then
					covered += 1
					break
				end
			end
		end
		x += Data.BANK_SAMPLE_STEP
	end
	return if total > 0 then covered / total else 0, covered, total
end

-- Load-time contract: catches a broken recipe before any server builder or Studio check reads it.
do
	assert(Data.TAG == "RiverFoam", "river_foam_q212: tag changed")
	assert(Data.KIND_ATTR == "RiverFoamKind", "river_foam_q212: kind attribute changed")
	assert(Data.WATER_HALF == RiverR8.WATER_HALF, "river_foam_q212: channel width drifted from MapSpec")
	assert(Data.MIN_COVERAGE == 0.60, "river_foam_q212: coverage target changed")
	assert(Data.PERF_BUDGET >= 100, "river_foam_q212: perf budget is below the default line")

	local parts = Data.parts()
	local perBank = { south = 0, north = 0 }
	for _, part in ipairs(parts) do
		perBank[part.Side] = (perBank[part.Side] or 0) + 1
		assert(part.shape == "Block", "river_foam_q212: foam must stay a cheap Block, never a Ball")
		assert(part.kind == Data.KIND, "river_foam_q212: unexpected part kind")
		assert(part.size[1] == Data.RIVER_SEGMENT, "river_foam_q212: strip does not span one segment")
		assert(part.size[2] <= 0.1 and part.size[3] <= 1, "river_foam_q212: foam is not a thin line")
		assert(part.y > RiverR8.WATER_SURFACE_Y, "river_foam_q212: foam is below the water surface")
		assert(part.y < RiverR8.WATER_SURFACE_Y + 0.2, "river_foam_q212: foam floats too high")
		assert(part.transparency > 0 and part.transparency < 1, "river_foam_q212: foam must be see-through")
		assert(string.find(part.name, "RiverFoam", 1, true) == 1, "river_foam_q212: unclear part name")
	end
	assert(perBank.south == 50 and perBank.north == 50, "river_foam_q212: both banks need equal coverage")
	local fraction, covered, total = Data.coverage(parts)
	assert(total == 402 and covered == total, "river_foam_q212: sampling does not cover both banks")
	assert(fraction >= Data.MIN_COVERAGE, "river_foam_q212: coverage below target")
	local thinner = {}
	for index, part in ipairs(parts) do
		if index % 2 == 1 then
			thinner[#thinner + 1] = { x = part.x, z = part.z }
		end
	end
	local reduced = Data.coverage(thinner)
	assert(reduced < Data.MIN_COVERAGE, "river_foam_q212: coverage calibration is vacuous")
end

return Data
