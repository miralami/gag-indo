--!strict
-- LookDevCorner: pure-data recipe for the round-3 "corner" LookDev candidate — one 60x60-stud
-- corner with a warung, a curved road bend and a sawah edge.
-- ROUND-3 BUG 6: no longer at (500,500) over the void. The whole corner is staged on REAL PLAZA
-- ground from src/server/World/MapSpec.luau (X -48..48, Z -42..42), centred at ORIGIN (-14,0,-12),
-- away from SPAWN (0,*,28), the road arms and the six hub clearings.
-- No Roblox APIs and no asset IDs at load: plain descriptors + pure helpers so Lune specs can
-- validate the whole corner without a DataModel. Colours are ART.md section 3 palette tokens;
-- materials are built-in Enum.Material names resolved best-effort by the client adapter.
-- V-D1: no outline objects of any kind anywhere in this candidate.
-- V-D2: shown at the golden-hour clock time (WorldConstants midpoint), applied by the adapter.

local WorldConstants = require(script.Parent.Config.WorldConstants)

local LookDevCorner = {}

LookDevCorner.SIZE = 60
LookDevCorner.ORIGIN = { -14, 0, -12 }
LookDevCorner.goldenHourClock = (WorldConstants.GOLDEN_HOUR.minClock + WorldConstants.GOLDEN_HOUR.maxClock) / 2

LookDevCorner.groups = {
	warung = "warung",
	road = "road_bend",
	sawah = "sawah_edge",
}

-- Flat descriptors. `position` is ABSOLUTE world space and already includes ORIGIN, so the adapter
-- can drop the whole corner into Workspace without doing any offset maths.
LookDevCorner.parts = {
	-- warung: counter + top, four posts, tiled roof, sign, stool, lantern
	{
		name = "WarungCounter",
		group = "warung",
		shape = "Block",
		size = { 10, 2, 4 },
		position = { -28, 1, -24 },
		color = "bambu",
		material = "WoodPlanks",
	},
	{
		name = "WarungCounterTop",
		group = "warung",
		shape = "Block",
		size = { 11, 0.4, 4.5 },
		position = { -28, 2.2, -24 },
		color = "tinta_lembut",
		material = "Wood",
	},
	{
		name = "WarungRoof",
		group = "warung",
		shape = "Block",
		size = { 14, 0.6, 10 },
		position = { -28, 9, -26 },
		color = "genteng",
		material = "Wood",
	},
	{
		name = "WarungPostFL",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { -34, 4.5, -31 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostFR",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { -22, 4.5, -31 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostBL",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { -34, 4.5, -21 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostBR",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { -22, 4.5, -21 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungSign",
		group = "warung",
		shape = "Block",
		size = { 8, 2, 0.4 },
		position = { -28, 6.5, -30.5 },
		color = "kertas",
		material = "WoodPlanks",
	},
	{
		name = "WarungStool",
		group = "warung",
		shape = "Cylinder",
		size = { 1.6, 2, 1.6 },
		position = { -31, 1, -19 },
		color = "bambu",
		material = "WoodPlanks",
	},
	{
		name = "WarungLantern",
		group = "warung",
		shape = "Sphere",
		size = { 1.4, 1.4, 1.4 },
		position = { -28, 7.5, -24 },
		color = "senja",
		material = "SmoothPlastic",
	},
	-- road_bend: cobblestone slabs on a quarter arc plus one straight approach
	{
		name = "RoadBendA",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 9.9, 0.15, -6.1 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	{
		name = "RoadBendB",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 0, 0.15, -2 },
		color = "tinta",
		material = "Cobblestone",
	},
	{
		name = "RoadBendC",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { -9.9, 0.15, -6.1 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	{
		name = "RoadBendD",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { -14, 0.15, -16 },
		color = "tinta",
		material = "Cobblestone",
	},
	{
		name = "RoadApproach",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { -14, 0.15, -22 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	-- sawah_edge: tanah strip, pematang ridge, water strip and three padi clumps
	{
		name = "SawahTanah",
		group = "sawah_edge",
		shape = "Block",
		size = { 16, 0.4, 16 },
		position = { -28, 0.2, 6 },
		color = "tinta_lembut",
		material = "Mud",
	},
	{
		name = "SawahPematang",
		group = "sawah_edge",
		shape = "Block",
		size = { 16, 1, 1.2 },
		position = { -28, 0.9, -2 },
		color = "bambu",
		material = "Mud",
	},
	{
		name = "SawahAir",
		group = "sawah_edge",
		shape = "Block",
		size = { 14, 0.2, 12 },
		position = { -28, 0.3, 8 },
		color = "malam",
		material = "Water",
	},
	{
		name = "SawahPadiA",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { -33, 1.6, 4 },
		color = "padi",
		material = "Leaf",
	},
	{
		name = "SawahPadiB",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { -27, 1.6, 9 },
		color = "padi",
		material = "Leaf",
	},
	{
		name = "SawahPadiC",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { -22, 1.6, 4 },
		color = "daun",
		material = "Leaf",
	},
}

-- Three review shots in ABSOLUTE world space, ready to paste into Studio screen_capture.
LookDevCorner.cameras = {
	{ id = "warung", position = { -34, 12, -12 }, lookAt = { -28, 4, -26 } },
	{ id = "road_bend", position = { -2, 10, 10 }, lookAt = { -2, 1, -9 } },
	{ id = "sawah_edge", position = { -14, 8, 16 }, lookAt = { -28, 1, 6 } },
}

-- Spec seam: every descriptor whose centre lies inside ORIGIN +/- SIZE/2 on X and Z.
function LookDevCorner.partsInBounds(): { any }
	local half = LookDevCorner.SIZE / 2
	local inside = {}
	for _, part in LookDevCorner.parts do
		local x, z = part.position[1], part.position[3]
		if
			x >= LookDevCorner.ORIGIN[1] - half
			and x <= LookDevCorner.ORIGIN[1] + half
			and z >= LookDevCorner.ORIGIN[3] - half
			and z <= LookDevCorner.ORIGIN[3] + half
		then
			inside[#inside + 1] = part
		end
	end
	return inside
end

return LookDevCorner
