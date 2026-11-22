--!strict
-- ModelMapPlazaR9: pure data for the OFF-BY-DEFAULT "plaza_r9" LookDev candidate
-- (WORK_QUEUE section O item 149, rebuilt by section P item 175). Central Lapangan dressing: a
-- two-tier fountain with a 14-stud basin, smaller upper basin and thin water column, a four-strip
-- paved ring, four inward-facing benches, four striped umbrellas, a bunting line whose flags are
-- flat red-over-white part pairs, and one procedural shade tree at the plaza edge. No asset IDs
-- and no brand: every piece is built from original Parts by src/server/World/LookDevPlazaR9.luau.
--
-- Pure data/functions only: no game APIs, no Instances, no Enums. Every anchor is in PLAZA-LOCAL
-- coordinates (x, z) relative to MapSpec.PLAZA centre; the applier adds MapSpec.PLAZA.x/.z at
-- apply time, so there are no world-coordinate literals here. The dressed rectangle is 38x28
-- centred on the plaza; the four 6-stud arm lanes form a clear cross that stops at the paved ring,
-- so the monument at the centre never blocks a walking lane.

local Data = {}

Data.id = "plaza_r9"
Data.familyId = "plaza_r9"
Data.folderName = "LookDevPlazaR9_plaza_r9"

Data.stageAttribute = "LookDevPlazaR9"
Data.fountainAttribute = "PlazaFountain"
Data.waterAttribute = "FountainWater"
Data.waterColourAttribute = "WaterColour"
Data.benchAttribute = "PlazaBench"
Data.umbrellaAttribute = "PlazaUmbrella"
Data.stripeAttribute = "UmbrellaStripe"
Data.stripeColourAttribute = "StripeColour"
Data.buntingAttribute = "PlazaBunting"
Data.buntingPoleAttribute = "BuntingPole"
Data.buntingLineAttribute = "BuntingLine"
Data.buntingFlagAttribute = "BuntingFlag"
Data.treeAttribute = "PlazaShadeTree"
Data.treeHeightAttribute = "TreeHeight"
Data.fountainTierAttribute = "FountainTier"
Data.pavingAttribute = "PlazaPaving"
Data.flagPairAttribute = "BuntingFlagPair"
Data.flagPanelAttribute = "BuntingFlagPanel"

-- The dressed inner area: |x| <= 19, |z| <= 14 in plaza-local coordinates. MapSpec.PLAZA itself is
-- 96x84 of Ground terrain; everything here stays inside the smaller dressed rectangle.
Data.DRESSED = { width = 38, depth = 28 }
Data.LANE_WIDTH = 6

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. No asset-backed material.
Data.COLOURS = {
	water = { 74, 166, 196 },
	stone = { 168, 164, 150 },
	stoneDark = { 132, 128, 116 },
	wood = { 146, 104, 64 },
	red = { 196, 58, 48 },
	white = { 246, 242, 230 },
	blue = { 54, 104, 178 },
	leaf = { 56, 118, 62 },
	leafLight = { 82, 148, 78 },
	trunk = { 110, 78, 48 },
	rope = { 206, 190, 150 },
}

Data.STRIPE_ORDER = { "red", "white", "blue" }
Data.MATERIALS = {
	stone = "Slate",
	wood = "WoodPlanks",
	fabric = "Fabric",
	water = "SmoothPlastic",
	leaf = "Leaf",
	trunk = "Wood",
	rope = "SmoothPlastic",
}

function Data.stripeColour(index: number): string
	return Data.STRIPE_ORDER[((index - 1) % #Data.STRIPE_ORDER) + 1]
end

-- FOUNTAIN_RADIUS/LANE_GAP stay at their item-149 values: the original plaza spec locks that
-- contract. The rebuilt basin is bigger; lanes now stop at RING_RADIUS + LANE_GAP = 9.5 so the
-- 14-stud basin and its paved ring still leave a clear 6-stud approach from each road.
Data.FOUNTAIN_RADIUS = 3
Data.LANE_GAP = 0.5
Data.BASIN_RADIUS = 7
Data.RING_RADIUS = 9

Data.FOUNTAIN = {
	x = 0,
	z = 0,
	basinSize = { 14, 0.8, 14 },
	basinY = 0.4,
	waterSize = { 12.4, 0.25, 12.4 },
	waterY = 0.95,
	waterColour = "water",
	upperBasinSize = { 8, 0.7, 8 },
	upperBasinY = 1.35,
	upperWaterSize = { 6.4, 0.2, 6.4 },
	upperWaterY = 1.8,
	spoutSize = { 0.6, 4, 0.6 },
	spoutY = 3.2,
	spoutMaterial = "water", -- SmoothPlastic water column, never Neon
	tierCount = 2,
	ringRadius = Data.RING_RADIUS,
}

Data.BENCH = {
	seatSize = { 4.4, 0.5, 1.6 },
	seatY = 1.5,
	backSize = { 4.4, 1.4, 0.4 },
	backY = 2.4,
	backZOffset = -0.6,
	legSize = { 0.5, 1.3, 0.5 },
	legY = 0.65,
	legXOffsets = { -1.8, 1.8 },
	legZOffsets = { -0.5, 0.5 },
}

local benchAnchors: { { name: string, x: number, z: number } } = {
	{ name = "bench_nw", x = -12, z = -11 },
	{ name = "bench_ne", x = 12, z = -11 },
	{ name = "bench_sw", x = -12, z = 11 },
	{ name = "bench_se", x = 12, z = 11 },
}

-- Four flat strips between radius 7 (basin) and radius 9 (lane end): a square paved ring.
Data.PAVING = {
	y = 0.25,
	northSouthSize = { 18, 0.2, 2 },
	eastWestSize = { 2, 0.2, 14 },
	offset = Data.BASIN_RADIUS + 1,
}

-- One flat red-over-white pair per bunting flag: two parallel panels, never crossing pennants.
Data.FLAG = {
	topColour = "red",
	bottomColour = "white",
}

Data.UMBRELLA = {
	poleSize = { 0.4, 8, 0.4 },
	poleY = 4,
	canopyY = 8.2,
	stripeCount = 6,
	stripeSize = { 2.6, 0.3, 1.3 },
	stripeOffset = 1.3,
}

local umbrellaAnchors: { { name: string, x: number, z: number, yaw: number } } = {
	{ name = "umbrella_nw", x = -14, z = -9, yaw = 0 },
	{ name = "umbrella_ne", x = 8, z = -11, yaw = 0 },
	{ name = "umbrella_sw", x = -14, z = 9, yaw = 0 },
	{ name = "umbrella_se", x = 14, z = 9, yaw = 0 },
}

Data.BUNTING = {
	poles = { { x = -17, z = -12.5 }, { x = -6, z = -12.5 } },
	poleSize = { 0.5, 10, 0.5 },
	poleY = 5,
	lineY = 9.4,
	lineSize = { 0.12, 0.12 }, -- X span is derived from the two poles at apply time.
	flagCount = 11,
	flagSize = { 0.8, 1.2, 0.12 },
	flagY = 8.8,
}

-- Procedural stand-in: no reused asset ID and no invented ID. A 12-stud canopy tree is assembled
-- from original Cylinder/Ball Parts, so it is always available in the baked Edit-mode flow.
Data.SHADE_TREE = {
	x = 15.5,
	z = -10,
	trunkSize = { 1.4, 7, 1.4 },
	trunkY = 3.5,
	canopyBlobs = {
		{ 0, 8.5, 0, 6 },
		{ -1.5, 9.5, 0.5, 4 },
		{ 1.5, 9.8, -0.5, 4 },
		{ 0, 11, 0, 4 },
	},
}

-- Four 6-stud-wide arm lanes. Each runs from the dressed edge inward and stops 0.5 studs clear
-- of the paved ring, so the cross reads as one walking cross around the centre monument.
local laneInner = Data.RING_RADIUS + Data.LANE_GAP
local halfX, halfZ = Data.DRESSED.width / 2, Data.DRESSED.depth / 2

local lanes = {
	{ name = "north", x = 0, z = -(halfZ + laneInner) / 2, width = Data.LANE_WIDTH, depth = halfZ - laneInner },
	{ name = "south", x = 0, z = (halfZ + laneInner) / 2, width = Data.LANE_WIDTH, depth = halfZ - laneInner },
	{ name = "east", x = (halfX + laneInner) / 2, z = 0, width = halfX - laneInner, depth = Data.LANE_WIDTH },
	{ name = "west", x = -(halfX + laneInner) / 2, z = 0, width = halfX - laneInner, depth = Data.LANE_WIDTH },
}

function Data.fountain()
	return {
		x = Data.FOUNTAIN.x,
		z = Data.FOUNTAIN.z,
		radius = Data.FOUNTAIN_RADIUS,
		basinDiameter = Data.FOUNTAIN.basinSize[1],
		ringRadius = Data.RING_RADIUS,
		tierCount = Data.FOUNTAIN.tierCount,
		spoutSize = Data.FOUNTAIN.spoutSize,
		discColour = Data.COLOURS[Data.FOUNTAIN.waterColour],
		colourKey = Data.FOUNTAIN.waterColour,
	}
end

function Data.fountainTiers()
	local recipe = Data.FOUNTAIN
	return {
		{
			index = 1,
			name = "FountainBasin",
			size = recipe.basinSize,
			y = recipe.basinY,
			waterSize = recipe.waterSize,
			waterY = recipe.waterY,
		},
		{
			index = 2,
			name = "FountainTierUpper",
			size = recipe.upperBasinSize,
			y = recipe.upperBasinY,
			waterSize = recipe.upperWaterSize,
			waterY = recipe.upperWaterY,
		},
	}
end

function Data.paving()
	local recipe = Data.PAVING
	local offset = recipe.offset
	return {
		{ name = "paving_north", x = 0, z = -offset, size = recipe.northSouthSize },
		{ name = "paving_south", x = 0, z = offset, size = recipe.northSouthSize },
		{ name = "paving_east", x = offset, z = 0, size = recipe.eastWestSize },
		{ name = "paving_west", x = -offset, z = 0, size = recipe.eastWestSize },
	}
end

function Data.benches()
	local out = {}
	for _, anchor in ipairs(benchAnchors) do
		-- The seat front is local +Z; face the fountain at (0,0) in plaza-local space.
		out[#out + 1] = {
			name = anchor.name,
			x = anchor.x,
			z = anchor.z,
			yaw = math.deg(math.atan2(-anchor.x, -anchor.z)),
			size = { Data.BENCH.seatSize[1], Data.BENCH.seatSize[3] },
		}
	end
	return out
end

function Data.umbrellas()
	local out = {}
	for _, anchor in ipairs(umbrellaAnchors) do
		out[#out + 1] = {
			name = anchor.name,
			x = anchor.x,
			z = anchor.z,
			yaw = anchor.yaw,
			stripeCount = Data.UMBRELLA.stripeCount,
			stripeColours = (function()
				local colours = {}
				for index = 1, Data.UMBRELLA.stripeCount do
					colours[index] = Data.stripeColour(index)
				end
				return colours
			end)(),
		}
	end
	return out
end

function Data.flagPanelSize()
	return { Data.BUNTING.flagSize[1], Data.BUNTING.flagSize[2] / 2, Data.BUNTING.flagSize[3] }
end

function Data.flagPanels(flag: any)
	local offset = Data.BUNTING.flagSize[2] / 4
	return {
		{ name = flag.name .. "_" .. Data.FLAG.topColour, colour = Data.FLAG.topColour, yOffset = offset },
		{ name = flag.name .. "_" .. Data.FLAG.bottomColour, colour = Data.FLAG.bottomColour, yOffset = -offset },
	}
end

function Data.bunting()
	local poles = {}
	for _, pole in ipairs(Data.BUNTING.poles) do
		poles[#poles + 1] = { x = pole.x, z = pole.z }
	end
	local flags = {}
	local a, b = Data.BUNTING.poles[1], Data.BUNTING.poles[2]
	for index = 1, Data.BUNTING.flagCount do
		local t = (index - 1) / math.max(Data.BUNTING.flagCount - 1, 1)
		flags[#flags + 1] = {
			name = string.format("BuntingFlag_%02d", index),
			x = a.x + (b.x - a.x) * t,
			z = a.z + (b.z - a.z) * t,
			colour = Data.stripeColour(index),
		}
	end
	return { poles = poles, line = { a = poles[1], b = poles[2] }, flags = flags }
end

function Data.shadeTree()
	return {
		x = Data.SHADE_TREE.x,
		z = Data.SHADE_TREE.z,
		height = 12,
		canopyRadius = 3.5,
	}
end

function Data.lanes()
	local out = {}
	for _, lane in ipairs(lanes) do
		out[#out + 1] = {
			name = lane.name,
			x = lane.x,
			z = lane.z,
			width = lane.width,
			depth = lane.depth,
		}
	end
	return out
end

function Data.counts()
	return {
		fountains = 1,
		fountainTiers = Data.FOUNTAIN.tierCount,
		pavingTiles = #Data.paving(),
		benches = #benchAnchors,
		umbrellas = #umbrellaAnchors,
		buntingPoles = #Data.BUNTING.poles,
		buntingFlags = #Data.bunting().flags,
		shadeTrees = 1,
		lanes = #lanes,
	}
end

return Data
