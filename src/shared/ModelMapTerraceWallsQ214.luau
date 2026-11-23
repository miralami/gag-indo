--!strict
-- ModelMapTerraceWallsQ214: pure data for WORK_QUEUE item 214, DEFAULT-look stone retaining walls
-- on the sawah terraces' south-facing front walls. One 25-stud wall per MapSpec.TERRACES entry,
-- sitting on the lower terrace surface with its north face flush to the upper terrace face.
--
-- No engine calls, no Instances, no Enums, no prompts and no invented asset IDs. The caller passes
-- the live MapSpec, so TERRACES / TERRACE_SIDES / GROUND_Y stay authoritative. `assetId` is the
-- provenance from the already-approved rocks_r9 baked models; the DEFAULT look stages a plain
-- Block with the approved Rock material, not a new model instance. Staging is Greybox's job.

local Rocks = require(script.Parent.ModelMapRocksR9)

local Data = {}

Data.id = "terrace_walls_214"
Data.folderName = "LookDevTerraceWallsQ214_terrace_walls_214"

Data.TAG = "TerraceWall"
Data.MIN_WALLS = 4
Data.WALL_LENGTH = 25
Data.WALL_DEPTH = 1.5
Data.WALL_TOL = 0.3
Data.SHAPE = "Block"
Data.MATERIAL = "Rock"
Data.COLOUR = "tintaLembut"
Data.ANCHORED = true
Data.CAN_COLLIDE = false
Data.INTERACTIVE = false
Data.ALLOWED_MATERIALS = { "Rock", "Slate", "Granite" }

-- Item 271: each wall gets three low stone courses stepping down along its length, like the
-- terraces mood photo. The DEFAULT single retaining Block from parts() is untouched; stepParts()
-- is the additive, baked-model overlay staged by the q271 applier.
Data.STEP_COUNT = 3
Data.STEP_RUN = 5
Data.STEP_DROP = 0.45
Data.STEP_THICKNESS = 1.8

-- Alternating lanes: terrace 1 west, 2 east, 3 west, 4 east. Midpoints come from the live
-- MapSpec.TERRACE_SIDES, so no wall lands in the 84-stud Balai gap or on the central ramps.
local function laneX(mapSpec: any, index: number): number
	local sides = mapSpec.TERRACE_SIDES
	assert(type(sides) == "table" and #sides >= 2, "terrace_walls_q214: TERRACE_SIDES missing")
	local side = sides[((index - 1) % #sides) + 1]
	assert(type(side) == "table" and type(side.x0) == "number" and type(side.x1) == "number", "terrace_walls_q214: malformed TERRACE_SIDES entry")
	return (side.x0 + side.x1) / 2
end

-- Deterministic descriptors. y is the box centre: bottom lands exactly on the lower surface
-- (GROUND_Y for the first terrace, the previous terrace top for the rest) and top lands on this
-- terrace's top, so nothing floats and the 4-stud riser reads as built stone.
function Data.parts(mapSpec: any): { { [string]: any } }
	assert(type(mapSpec) == "table", "terrace_walls_q214: MapSpec required")
	local terraces = mapSpec.TERRACES
	assert(type(terraces) == "table" and #terraces >= Data.MIN_WALLS, "terrace_walls_q214: TERRACES shorter than the four-terrace contract")
	assert(type(mapSpec.GROUND_Y) == "number", "terrace_walls_q214: GROUND_Y missing")

	local out = {}
	for index, terrace in ipairs(terraces) do
		assert(type(terrace) == "table" and type(terrace.z1) == "number" and type(terrace.top) == "number", "terrace_walls_q214: malformed TERRACES entry")
		local lower = if index == 1 then mapSpec.GROUND_Y else terraces[index - 1].top
		assert(type(lower) == "number", "terrace_walls_q214: lower terrace top missing")
		local height = terrace.top - lower
		assert(height > 0, "terrace_walls_q214: non-positive terrace riser")

		out[#out + 1] = {
			name = string.format("TerraceWall_%02d", index),
			kind = "retaining_wall",
			terrace = index,
			x = laneX(mapSpec, index),
			y = lower + height / 2,
			z = terrace.z1 + Data.WALL_DEPTH / 2, -- north face flush to the terrace's south face
			sx = Data.WALL_LENGTH,
			sy = height,
			sz = Data.WALL_DEPTH,
			shape = Data.SHAPE,
			material = Data.MATERIAL,
			colour = Data.COLOUR,
			assetId = Rocks.assetIdFor(index), -- provenance only; no new ID and no baked clone here
			anchored = Data.ANCHORED,
			canCollide = Data.CAN_COLLIDE,
			interactive = Data.INTERACTIVE,
		}
	end
	return out
end

-- Additive baked-stone overlay (item 271): three low courses on the south face of each wall, each
-- a step lower than the one before. `topY` is published so a harness can measure the descending
-- tiers without guessing from baked mesh pivots. No literal asset IDs: provenance stays rocks_r9.
function Data.stepParts(mapSpec: any): { { [string]: any } }
	local walls = Data.parts(mapSpec)
	local out = {}
	for wallIndex, wall in ipairs(walls) do
		local base = wall.y - wall.sy / 2
		for tier = 1, Data.STEP_COUNT do
			local top = wall.y + wall.sy / 2 - (tier - 1) * Data.STEP_DROP
			assert(top > base, "terrace_walls_q214: step course sinks below the lower surface")
			out[#out + 1] = {
				name = string.format("TerraceWallStep_%02d_%02d", wallIndex, tier),
				kind = "stone_step",
				wallIndex = wallIndex,
				terrace = wall.terrace,
				tier = tier,
				x = wall.x + (tier - 2) * Data.STEP_RUN,
				y = top - Data.STEP_THICKNESS / 2,
				z = wall.z - Data.WALL_DEPTH / 2,
				sx = Data.STEP_RUN,
				sy = Data.STEP_THICKNESS,
				sz = Data.STEP_THICKNESS,
				topY = top,
				assetId = Rocks.assetIdFor(wallIndex + tier),
				shape = Data.SHAPE,
				material = Data.MATERIAL,
				colour = Data.COLOUR,
				anchored = Data.ANCHORED,
				canCollide = Data.CAN_COLLIDE,
				interactive = Data.INTERACTIVE,
			}
		end
	end
	return out
end

-- Load-time contract: constants and the reused ID source must stay honest before any caller
-- builds Parts from this module.
do
	assert(Data.TAG == "TerraceWall", "terrace_walls_q214: wrong tag")
	assert(Data.MIN_WALLS == 4, "terrace_walls_q214: wall minimum changed")
	assert(Data.WALL_LENGTH == 25, "terrace_walls_q214: wall length is not 25 studs")
	assert(Data.WALL_TOL == 0.3, "terrace_walls_q214: terrain tolerance changed")
	assert(Data.SHAPE ~= "Ball", "terrace_walls_q214: Ball is not a retaining wall")
	assert(Data.STEP_COUNT >= 3, "terrace_walls_q214: fewer than three step courses")
	assert(Data.STEP_DROP > 0, "terrace_walls_q214: step courses do not descend")
	assert(#Rocks.ROCK_ASSET_IDS > 0, "terrace_walls_q214: rocks_r9 asset IDs missing")
end

return Data
