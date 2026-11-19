--!strict
-- LookDevCorner: pure-data recipe for the round-3 "corner" LookDev candidate — one 60x60-stud
-- corner with a warung, a curved road bend and a sawah edge, placed away from the runtime world.
-- No Roblox APIs and no asset IDs at load: plain descriptors + pure helpers so Lune specs can
-- validate the whole corner without a DataModel. Colours are ART.md section 3 palette tokens;
-- materials are built-in Enum.Material names resolved best-effort by the client adapter.
-- V-D1: no outline objects of any kind anywhere in this candidate.
-- V-D2: shown at the golden-hour clock time (WorldConstants midpoint), applied by the adapter.

local WorldConstants = require(script.Parent.Config.WorldConstants)

local LookDevCorner = {}

LookDevCorner.SIZE = 60
LookDevCorner.ORIGIN = { 500, 0, 500 }
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
		position = { 486, 1, 488 },
		color = "bambu",
		material = "WoodPlanks",
	},
	{
		name = "WarungCounterTop",
		group = "warung",
		shape = "Block",
		size = { 11, 0.4, 4.5 },
		position = { 486, 2.2, 488 },
		color = "tinta_lembut",
		material = "Wood",
	},
	{
		name = "WarungRoof",
		group = "warung",
		shape = "Block",
		size = { 14, 0.6, 10 },
		position = { 486, 9, 486 },
		color = "genteng",
		material = "Wood",
	},
	{
		name = "WarungPostFL",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { 480, 4.5, 481 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostFR",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { 492, 4.5, 481 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostBL",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { 480, 4.5, 491 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungPostBR",
		group = "warung",
		shape = "Cylinder",
		size = { 0.6, 9, 0.6 },
		position = { 492, 4.5, 491 },
		color = "bambu",
		material = "Wood",
	},
	{
		name = "WarungSign",
		group = "warung",
		shape = "Block",
		size = { 8, 2, 0.4 },
		position = { 486, 6.5, 481.5 },
		color = "kertas",
		material = "WoodPlanks",
	},
	{
		name = "WarungStool",
		group = "warung",
		shape = "Cylinder",
		size = { 1.6, 2, 1.6 },
		position = { 483, 1, 493 },
		color = "bambu",
		material = "WoodPlanks",
	},
	{
		name = "WarungLantern",
		group = "warung",
		shape = "Sphere",
		size = { 1.4, 1.4, 1.4 },
		position = { 486, 7.5, 488 },
		color = "senja",
		material = "SmoothPlastic",
	},
	-- road_bend: cobblestone slabs on a quarter arc plus one straight approach
	{
		name = "RoadBendA",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 523.9, 0.15, 505.9 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	{
		name = "RoadBendB",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 514, 0.15, 510 },
		color = "tinta",
		material = "Cobblestone",
	},
	{
		name = "RoadBendC",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 504.1, 0.15, 505.9 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	{
		name = "RoadBendD",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 500, 0.15, 496 },
		color = "tinta",
		material = "Cobblestone",
	},
	{
		name = "RoadApproach",
		group = "road_bend",
		shape = "Block",
		size = { 7, 0.3, 7 },
		position = { 500, 0.15, 490 },
		color = "tinta_lembut",
		material = "Cobblestone",
	},
	-- sawah_edge: tanah strip, pematang ridge, water strip and three padi clumps
	{
		name = "SawahTanah",
		group = "sawah_edge",
		shape = "Block",
		size = { 16, 0.4, 16 },
		position = { 486, 0.2, 518 },
		color = "tinta_lembut",
		material = "Mud",
	},
	{
		name = "SawahPematang",
		group = "sawah_edge",
		shape = "Block",
		size = { 16, 1, 1.2 },
		position = { 486, 0.9, 510 },
		color = "bambu",
		material = "Mud",
	},
	{
		name = "SawahAir",
		group = "sawah_edge",
		shape = "Block",
		size = { 14, 0.2, 12 },
		position = { 486, 0.3, 520 },
		color = "malam",
		material = "Water",
	},
	{
		name = "SawahPadiA",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { 481, 1.6, 516 },
		color = "padi",
		material = "Leaf",
	},
	{
		name = "SawahPadiB",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { 487, 1.6, 521 },
		color = "padi",
		material = "Leaf",
	},
	{
		name = "SawahPadiC",
		group = "sawah_edge",
		shape = "Sphere",
		size = { 1.6, 2, 1.6 },
		position = { 492, 1.6, 516 },
		color = "daun",
		material = "Leaf",
	},
}

-- Three review shots in ABSOLUTE world space, ready to paste into Studio screen_capture.
LookDevCorner.cameras = {
	{ id = "warung", position = { 480, 12, 500 }, lookAt = { 486, 4, 486 } },
	{ id = "road_bend", position = { 512, 10, 522 }, lookAt = { 512, 1, 503 } },
	{ id = "sawah_edge", position = { 500, 8, 528 }, lookAt = { 486, 1, 518 } },
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
