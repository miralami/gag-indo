--!strict
-- ModelMapLapanganR8: pure data for the OFF-BY-DEFAULT "lapangan_r8" LookDev candidate
-- (WORK_QUEUE section N item 108). The village field (lapangan) gets two goal frames, a flagpole
-- with a red-over-white flag, four bamboo benches along the south side, a white-painted stone
-- boundary and five small sand patches. Every piece is built from original Parts by
-- src/server/World/LookDevLapanganR8.luau: no asset IDs, no brand marks, no game APIs here.
--
-- GOAL SIZING (the numbers this module deliberately fixes): the avatar reference height is
-- AVATAR_HEIGHT = 7.25 studs (the same number used by ModelMapBuildingsR8), the chosen ratio is
-- GOAL_RATIO = 2.2 avatar heights, so GOAL_HEIGHT = 7.25 * 2.2 = 15.95 studs. Both goal Models
-- are protected structural pieces: their two posts and one crossbar are always staged, never
-- thinned, and their bbox height must measure 15.95 (the harness allows 0.5 stud tolerance).
--
-- Pure data/functions only: no game APIs, no Instances, no Enums. Coordinates are LAPANGAN-LOCAL
-- offsets; the applier adds MapSpec.LAPANGAN.x/.z at apply time, so there are no world literals.
-- FIELD mirrors MapSpec.LAPANGAN (72x56) and ROAD_HALF mirrors MapSpec.ROAD.halfWidth: every
-- goal/bench/stone/flag/sand anchor sits outside the |x| <= 14 RoadSouth corridor through the
-- field, and the five walking corridors below stay clear.

local Data = {}

Data.id = "lapangan_r8"
Data.familyId = "lapangan_r8"
Data.folderName = "LookDevLapanganR8_lapangan_r8"

Data.stageAttribute = "LookDevLapanganR8"
Data.kindAttribute = "LapanganKind"
Data.goalAttribute = "LapanganGoal"
Data.flagpoleAttribute = "LapanganFlagpole"
Data.benchAttribute = "LapanganBench"
Data.stoneAttribute = "LapanganStone"
Data.sandAttribute = "LapanganSand"
Data.heightAttribute = "LapanganHeight"
Data.flagPanelAttribute = "LapanganFlagPanel"

Data.KIND = {
	goal = "goal",
	flagpole = "flagpole",
	bench = "bench",
	stone = "stone",
	sand = "sand",
}
Data.KINDS = { "goal", "flagpole", "bench", "stone", "sand" }

-- Avatar-relative goal sizing. Documented in the module header above.
Data.AVATAR_HEIGHT = 7.25
Data.GOAL_RATIO = 2.2
Data.GOAL_HEIGHT = 15.95
Data.GOAL_WIDTH = 12 -- crossbar span along Z

-- Mirrors of MapSpec geometry. The applier always resolves the world anchor from MapSpec itself.
Data.FIELD = { width = 72, depth = 56 }
Data.ROAD_HALF = 14
Data.LANE_WIDTH = 3.5
Data.LANE_GAP = 0.5

local halfW, halfD = Data.FIELD.width / 2, Data.FIELD.depth / 2 -- 36, 28

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. No asset-backed material.
Data.COLOURS = {
	wood = { 146, 104, 64 },
	bamboo = { 188, 166, 104 },
	red = { 196, 52, 44 },
	white = { 246, 242, 230 },
	stone = { 224, 220, 208 },
	sand = { 202, 178, 132 },
}
Data.MATERIALS = {
	wood = "Wood",
	bamboo = "WoodPlanks",
	fabric = "Fabric",
	stone = "Slate",
	sand = "Sand",
}

Data.GOAL = {
	postSize = { 0.7, Data.GOAL_HEIGHT, 0.7 },
	crossbarSize = { 0.7, 0.7, Data.GOAL_WIDTH + 0.7 },
	postZOffsets = { -Data.GOAL_WIDTH / 2, Data.GOAL_WIDTH / 2 },
}

local goalAnchors = {
	{ name = "west", x = -(halfW - 6), z = 0, yaw = 0 },
	{ name = "east", x = halfW - 6, z = 0, yaw = 0 },
}

Data.FLAGPOLE = {
	x = 26,
	z = -22,
	height = 18,
	poleSize = { 0.5, 18, 0.5 },
	panelSize = { 5, 1, 0.12 },
	panelX = 2.5, -- panel centre from the pole, along +X
	redY = 17, -- from ground, red stripe above white
	whiteY = 16,
}

Data.BENCH = {
	seatSize = { 4, 0.5, 1.2 },
	seatY = 1.4,
	backSize = { 4, 1.2, 0.3 },
	backY = 2.2,
	backZOffset = -0.5,
	legSize = { 0.4, 1.4, 0.4 },
	legY = 0.7,
	legXOffsets = { -1.6, 1.6 },
}

-- Four benches in one row along the field's south side, clear of RoadSouth (|x| <= 14).
local benchAnchors = {
	{ name = "south_west", x = -30, z = 22, yaw = 0 },
	{ name = "south_inner_west", x = -22, z = 22, yaw = 0 },
	{ name = "south_inner_east", x = 22, z = 22, yaw = 0 },
	{ name = "south_east", x = 30, z = 22, yaw = 0 },
}

Data.STONE = { size = { 1.2, 1, 1.2 }, inset = 1.5 }

-- 24 boundary stones: six on each long edge and four on each short edge. The short-edge rows
-- skip |x| <= 16 so the RoadSouth mouth (halfWidth 14) stays open.
local stoneAnchors = {}
do
	local sideZ = { -20, -12, -4, 4, 12, 20 }
	for index, z in ipairs(sideZ) do
		stoneAnchors[#stoneAnchors + 1] =
			{ name = string.format("stone_w_%02d", index), x = -(halfW - Data.STONE.inset), z = z }
		stoneAnchors[#stoneAnchors + 1] =
			{ name = string.format("stone_e_%02d", index), x = halfW - Data.STONE.inset, z = z }
	end
	local edgeX = { -32, -24, -16, 16, 24, 32 }
	for index, x in ipairs(edgeX) do
		stoneAnchors[#stoneAnchors + 1] = {
			name = string.format("stone_n_%02d", index),
			x = x,
			z = -(halfD - Data.STONE.inset),
		}
		stoneAnchors[#stoneAnchors + 1] = {
			name = string.format("stone_s_%02d", index),
			x = x,
			z = halfD - Data.STONE.inset,
		}
	end
end

Data.SAND = { size = { 5, 0.2, 3.5 } }

local sandAnchors = {
	{ name = "sand_nw", x = -28, z = -12 },
	{ name = "sand_ne", x = 28, z = -12 },
	{ name = "sand_sw", x = -26, z = 12 },
	{ name = "sand_se", x = 26, z = 12 },
	{ name = "sand_w", x = -22, z = 0 },
}

function Data.goals()
	local out = {}
	for _, anchor in ipairs(goalAnchors) do
		out[#out + 1] = {
			name = anchor.name,
			x = anchor.x,
			z = anchor.z,
			yaw = anchor.yaw,
			height = Data.GOAL_HEIGHT,
			width = Data.GOAL_WIDTH,
		}
	end
	return out
end

function Data.flagpole()
	return {
		x = Data.FLAGPOLE.x,
		z = Data.FLAGPOLE.z,
		height = Data.FLAGPOLE.height,
		panels = { "red", "white" },
	}
end

function Data.benches()
	local out = {}
	for _, anchor in ipairs(benchAnchors) do
		out[#out + 1] = { name = anchor.name, x = anchor.x, z = anchor.z, yaw = anchor.yaw }
	end
	return out
end

function Data.stones()
	local out = {}
	for _, anchor in ipairs(stoneAnchors) do
		out[#out + 1] = { name = anchor.name, x = anchor.x, z = anchor.z }
	end
	return out
end

function Data.sandPatches()
	local out = {}
	for _, anchor in ipairs(sandAnchors) do
		out[#out + 1] = { name = anchor.name, x = anchor.x, z = anchor.z }
	end
	return out
end

-- Five walking corridors in LAPANGAN-LOCAL XZ rectangles: four strips just OUTSIDE the field
-- boundary (a 0.5-stud gap from the edge) plus the RoadSouth corridor through the middle. All
-- staged pieces are inside the field and outside |x| <= Data.ROAD_HALF, so none of them reaches a
-- corridor. The harness maps these rectangles through MapSpec.LAPANGAN.x/.z before measuring.
function Data.corridors()
	local innerX, innerZ = halfW + Data.LANE_GAP, halfD + Data.LANE_GAP
	local outerX, outerZ = innerX + Data.LANE_WIDTH, innerZ + Data.LANE_WIDTH
	return {
		{ name = "west", minX = -outerX, maxX = -innerX, minZ = -outerZ, maxZ = outerZ },
		{ name = "east", minX = innerX, maxX = outerX, minZ = -outerZ, maxZ = outerZ },
		{ name = "north", minX = -innerX, maxX = innerX, minZ = -outerZ, maxZ = -innerZ },
		{ name = "south", minX = -innerX, maxX = innerX, minZ = innerZ, maxZ = outerZ },
		{ name = "road_south", minX = -Data.ROAD_HALF, maxX = Data.ROAD_HALF, minZ = -halfD, maxZ = halfD },
	}
end

-- Per-kind part counts (the harness compares these against tagged staged Parts), plus the
-- structural item counts for the spec.
function Data.counts()
	return {
		goal = #goalAnchors * 3,
		flagpole = 1 + #Data.flagpole().panels,
		bench = #benchAnchors * 4,
		stone = #stoneAnchors,
		sand = #sandAnchors,
		goals = #goalAnchors,
		flagpoles = 1,
		benches = #benchAnchors,
		corridors = #Data.corridors(),
	}
end

return Data
