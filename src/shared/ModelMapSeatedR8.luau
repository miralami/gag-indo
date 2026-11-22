--!strict
-- ModelMapSeatedR8: pure data for the OFF-BY-DEFAULT "seated_r8" LookDev candidate
-- (WORK_QUEUE section N item 117). Four catalog-dressed R15 villagers sit on the two Warung benches
-- (two per bench) driven by real Seat Parts, with four glasses and four plates on the Warung table.
-- Only outfit KEYS live here: the exact catalog clothing / hat IDs stay in Shared.ModelMapNpcsR7 and
-- are read by the server applier. This module has no asset IDs, no brand, no decals, no terrain
-- edit and no engine API. Written proof: no terrain edit, no asset IDs. Only plain RGB colours and
-- real built-in SmoothPlastic/Metal/Wood material tokens.
--
-- SITE derivation mirrors MapSpec (warung x=68 z=-68 yaw=0, 52x44; table local (0,10) 14x3.4x7,
-- top Y=3.9; benches at local x={-6.4,6.4}, local z=10, world centre Y=1.7, top Y=1.95,
-- size 4x0.5x1.6, world centres (61.6,-58) / (74.4,-58)). Seats sit at bench top + 0.5 studs,
-- two per bench at +/-0.9 studs along the 4-stud bench width, moved to the bench's +Z front edge so
-- the seated rigs' shins hang clear of the 1.6-stud slab. No new camera:
-- review reuses the existing render path. Visual/designer verdict stays pending.

local Data = {}

Data.id = "seated_r8"
Data.familyId = "seated_r8"
Data.folderName = "LookDevSeatedR8_seated_r8"

Data.stageAttribute = "LookDevSeatedR8"
Data.kindAttribute = "SeatedKind"

Data.SEAT_KIND = "seat"
Data.GLASS_KIND = "glass"
Data.PLATE_KIND = "plate"
Data.KINDS = { "seat", "glass", "plate" }
Data.MIN_PROPS = 8

-- Outfit keys only. Shared.ModelMapNpcsR7 holds the verified catalog IDs for these roles; the
-- applier copies its HumanoidDescription recipe verbatim and never invents an ID.
Data.OUTFITS = { "petani", "petani_wanita", "pedagang", "pak_rt" }

Data.GROUND_Y = 0.5
Data.WARUNG = { x = 68, z = -68, model = "Warung" }
Data.BENCH = {
	localX = { -6.4, 6.4 },
	localZ = 10,
	centreY = 1.7,
	topY = 1.95,
	size = { 4, 0.5, 1.6 },
}
Data.TABLE = {
	localX = 0,
	localZ = 10,
	size = { 14, 3.4, 7 },
	topY = 3.9,
}
Data.SEAT = {
	size = { 2, 0.3, 1.4 },
	lift = 0.5,
	-- Benches are only 1.6 studs deep. Seats sit at the bench's +Z front edge so a seated R15's
	-- lower legs hang IN FRONT of the slab instead of through it. Main-session probe: zLift 0.35
	-- clipped the bench (8 hits); zLift 1.35 clears with ~0.06 stud of margin at the shin box.
	zLift = 1.35,
	offsets = { -0.9, 0.9 },
	facing = { 180, 180 },
}

-- Representative R15 body Part names probed by SEATED_ON_BENCH. Legs and feet are included so a
-- seated pose that clips into a bench is caught, not just the torso.
Data.PROBE_PARTS = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"HumanoidRootPart",
	"LeftLowerLeg",
	"RightLowerLeg",
	"LeftFoot",
	"RightFoot",
}

local sites: { any } = {}
for benchIndex, lx in ipairs(Data.BENCH.localX) do
	for seatIndex, offset in ipairs(Data.SEAT.offsets) do
		sites[#sites + 1] = {
			key = "seat_" .. benchIndex .. "_" .. seatIndex,
			bench = benchIndex,
			benchX = Data.WARUNG.x + lx,
			offsetX = offset,
			x = Data.WARUNG.x + lx + offset,
			y = Data.BENCH.topY + Data.SEAT.lift,
			z = Data.WARUNG.z + Data.BENCH.localZ + Data.SEAT.zLift,
			ry = Data.SEAT.facing[benchIndex],
		}
	end
end
Data.SITES = sites

Data.COLOURS = {
	seat = { 104, 76, 48 },
	glass = { 174, 214, 224 },
	plate = { 232, 228, 212 },
}
Data.MATERIALS = {
	seat = "Wood",
	glass = "SmoothPlastic",
	plate = "Metal",
}
Data.TRANSPARENCY = {
	glass = 0.35,
	plate = 0,
	seat = 0,
}

-- Table props: four thin cylinders as glasses and four flat discs as plates, all plain RGB with
-- built-in materials. Ly is the part centre above the table top.
local props: { any } = {}
local propX = { -4.5, -1.5, 1.5, 4.5 }
for index, x in ipairs(propX) do
	props[#props + 1] = {
		name = "glass_" .. index,
		kind = Data.GLASS_KIND,
		lx = Data.TABLE.localX + x,
		ly = Data.TABLE.topY + 0.5,
		lz = Data.TABLE.localZ - 1.5,
		size = { 0.7, 1, 0.7 },
		colour = "glass",
		material = "glass",
	}
	props[#props + 1] = {
		name = "plate_" .. index,
		kind = Data.PLATE_KIND,
		lx = Data.TABLE.localX + x,
		ly = Data.TABLE.topY + 0.07,
		lz = Data.TABLE.localZ + 1.5,
		size = { 1.3, 0.14, 1.3 },
		colour = "plate",
		material = "plate",
	}
end

function Data.sites(): { any }
	return table.clone(sites)
end

function Data.props(): { any }
	return table.clone(props)
end

function Data.counts(): { [string]: number }
	return {
		seat = #sites,
		glass = 4,
		plate = 4,
		total = #sites + #props,
	}
end

return Data
