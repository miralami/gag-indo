-- MapSpec: every layout number from docs/v2/art/MAP_SPEC.md in one place.
--
-- Pure data and pure functions only: no Instances, no Enum lookups at load time. Materials are plain
-- strings ("Grass", "Ground", ...) and coordinates are numbers, so every list here can be checked
-- without Studio. Greybox turns them into Parts and terrain fills; Decor, Details, Flora, Landscape
-- and Village read the same tables instead of keeping their own copy of the layout.
--
-- Conventions: studs, X = east, -Z = north, ground plane Y = 0.5. A terrain FillBlock's visible top
-- face is regionTop + 2, so volumeForTop() subtracts that half voxel.
--
-- The layout in this file is the WORLD-SCALE version (S = 2). Rumah Pak RT was approved as the scale
-- reference: 48 x 34 footprint, 32.6 ridge, 7 x 10.5 door, against a 7.25-stud avatar. Everything else
-- is the old village scaled 2x: 800 x 800 playable square, hubs at twice their distance, terraces 16
-- deep and 3 more of them, river at z about 304, forest ring at 260..380. Nothing in the world code
-- may hardcode a distance: it either lives here or is derived from S here.

local Ground = require(script.Parent.Ground)
local WorldConstants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config.WorldConstants)

local MapSpec = {}

local GROUND_Y = Ground.Y
local TERRAIN_VOXEL = 4

MapSpec.S = 2
MapSpec.GROUND_Y = GROUND_Y
MapSpec.TERRAIN_VOXEL = TERRAIN_VOXEL
MapSpec.TERRAIN_BASE_Y = GROUND_Y - TERRAIN_VOXEL
-- Half the 800 x 800 playable square: |x|, |z| <= 400. Hills start at this edge.
MapSpec.TERRAIN_HALF = 400

-- Widest FillBlock this build requests, on X and on Z. A 340-wide terrace fill came out full of
-- holes in Studio (2026-11-15), so every wide volume (base slab, terraces, clear envelope) is split
-- into strips no wider than this, and its height is laid in whole voxel layers.
MapSpec.MAX_FILL_SPAN = 40

-- Terrain volume whose visible top lands on `top`. `bottom` is the nominal base of the fill; the
-- region reaches half a voxel lower, which is always underground.
function MapSpec.volumeForTop(bottom: number, top: number): (number, number)
	return (bottom + top) / 2 - TERRAIN_VOXEL / 2, top - bottom
end

-- Rotation used by every hub, in degrees. Local +Z is the door side and maps to
-- (sin yaw, cos yaw): 0 = south, 45 = south-east, 90 = east, 180 = north.
function MapSpec.rotatePoint(cx: number, cz: number, yawDeg: number, lx: number, lz: number): (number, number)
	local a = math.rad(yawDeg)
	local cos, sin = math.cos(a), math.sin(a)
	return cx + lx * cos + lz * sin, cz - lx * sin + lz * cos
end

-- A local hub point in world XZ.
function MapSpec.hubPoint(hub, lx: number, lz: number): (number, number)
	return MapSpec.rotatePoint(hub.x, hub.z, hub.yaw, lx, lz)
end

-- World-space AABB of a hub footprint (rotated corners folded back to axis-aligned bounds).
function MapSpec.hubBounds(hub): { minX: number, maxX: number, minZ: number, maxZ: number }
	local hw, hd = hub.width / 2, hub.depth / 2
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, corner in { { -hw, -hd }, { hw, -hd }, { -hw, hd }, { hw, hd } } do
		local x, z = MapSpec.rotatePoint(hub.x, hub.z, hub.yaw, corner[1], corner[2])
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end

-- Hubs ----------------------------------------------------------------
-- Footprint is the building; `yaw` turns the local +Z door side. Pasar and Gelap keep yaw 0: the dead
-- end alley behind the Pasar needs axis-aligned faces, and the Pasar's south face opens on the plaza,
-- which is the SE side its door faces. `ridge` is the height of the roof peak above the ground.
--
-- Corner radius: five of the six hubs put their outer corner inside r <= 132, so the plot connector
-- ring (r 138..150) never clips a building. Gelap is the exception and cannot be made to fit while it
-- stays where MAP_SPEC puts it: its outer corner at (-96, -134) is r = 164.8, and shrinking the
-- footprint does not rescue it (even a 12x12 box at that centre is r = 152.6). The nearest compliant
-- 32x28 position is about (-34, -108), 48 studs east and level with the Pasar's north edge, which
-- would move the tengkulak out of its back alley entirely. Kept at the specified position so the
-- layout still matches the brief and the art reference; changing it is a one-line edit here.
-- Pak RT is the scale reference and is not re-proportioned.
MapSpec.HUBS = {
	{
		key = "pasar", model = "Pasar", sign = "PASAR", accent = "merah",
		x = -64, z = -64, width = 64, depth = 52, yaw = 0, ridge = 26,
		anchor = { name = "Counter", lx = 0, lz = 4, sx = 52, sy = 4.2, sz = 10, material = "WoodPlanks" },
		prompt = { object = "Pasar", action = "Jual hasil panen", name = "SellPrompt", tag = "Pasar", distance = 12 },
		shelves = { lz = -23.8, width = 56, levels = { 9.0, 13.0 } },
	},
	{
		key = "gelap", model = "TengkulakGelap", sign = "TENGKULAK GELAP", accent = "malam",
		x = -80, z = -120, width = 32, depth = 28, yaw = 0, ridge = 18,
		anchor = { name = "Counter", lx = 0, lz = 2, sx = 26, sy = 3.6, sz = 8, material = "WoodPlanks" },
		prompt = { object = "Tengkulak Gelap", action = "Jual (harga gelap)", name = "SellPrompt", tag = "Gelap", distance = 12 },
		lantern = { lx = -14.4, lz = 0 },
	},
	{
		key = "warung", model = "Warung", sign = "WARUNG", accent = "genteng",
		x = 68, z = -68, width = 52, depth = 44, yaw = 0, ridge = 24,
		anchor = { name = "Table", lx = 0, lz = 10, sx = 14, sy = 3.4, sz = 7, material = "WoodPlanks" },
		prompt = { object = "Warung", action = "Nongkrong", name = "WarungPrompt", tag = "Warung", distance = 12 },
		shelves = { lz = -19.8, width = 40, levels = { 6.2, 9.9 } },
		benches = { -6.4, 6.4 },
		lantern = { lx = 0, lz = 4 },
	},
	{
		key = "ronda", model = "PosRonda", sign = "POS RONDA", accent = "bambu",
		x = -108, z = 0, width = 44, depth = 40, yaw = 90, ridge = 16,
		anchor = { name = "Floor", lx = 0, lz = 0, sx = 40, sy = 1.2, sz = 36, material = "WoodPlanks" },
		tag = "Ronda",
	},
	{
		key = "polisi", model = "PosPolisi", sign = "POS POLISI", accent = "malam",
		x = -68, z = 68, width = 48, depth = 44, yaw = 180, ridge = 24,
		anchor = { name = "Desk", lx = 0, lz = 16, sx = 12, sy = 3.4, sz = 7, material = "Metal" },
		prompt = { object = "Pos Polisi", action = "Lapor bukti", name = "ReportPrompt", tag = "Polisi", distance = 12 },
	},
	{
		key = "pakrt", model = "RumahPakRT", sign = "RUMAH PAK RT", accent = "kunyit",
		x = 68, z = 68, width = 48, depth = 34, yaw = 180, ridge = 32.6,
		anchor = { name = "Table", lx = 5, lz = 13.5, sx = 5, sy = 2.4, sz = 3, material = "WoodPlanks" },
		prompt = { object = "Pak RT", action = "Kasih uang rokok", name = "BribePrompt", tag = "PakRT", distance = 12 },
		lantern = { lx = 0, lz = 2 },
	},
}

-- Flat awning that hangs off a hub's front eave line, out over the frontage. `reach` is how far past
-- the eave it sticks; the posts that hold it stand at `postLx` (local X offsets) so `reach` has to
-- reach the far post. These keep every awning and sign under a roof from hanging into a walkway.
MapSpec.AWNING_REACH = 6
MapSpec.AWNING_THICK = 1

MapSpec.HUB_ORDER = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }

-- Hub headroom and roof pitch, derived from the scale reference.
--
-- EAVE is the underside of every roof eave, awning, trim and spanduk a player can walk under.
-- Track C targets 9.5 studs of clear headroom in all six hubs (greybox_spec), so doors and
-- walkways read consistently on the blockout scale.
--
-- The ridge of every hub but the reference lands on its `ridge` target: rise = target - EAVE.
-- halfDepth is the eave reach from the ridge line, three studs past the wall centre line so the roof
-- overhangs the wall. The reference keeps its own authored pitch (HUB_ROOFS.pakRt).
--
-- Keys follow the builder's names: the two Pos buildings are posPolisi and posRonda, the reference is
-- pakRt. `hubRoofs()` returns exactly those keys, so Greybox and Decor index it without aliases.
MapSpec.HEADROOM = 9.5
MapSpec.EAVE_UNDERSIDE = GROUND_Y + MapSpec.HEADROOM
MapSpec.ROOF_OVERHANG = 3

-- Which roof key a hub's footprint produces: the hub key, except the reference (pakRt) and the two
-- Pos buildings, whose builders kept their old names.
function MapSpec.roofKey(hubKey: string): string
	if hubKey == "pakrt" then
		return "pakRt"
	elseif hubKey == "polisi" then
		return "posPolisi"
	elseif hubKey == "ronda" then
		return "posRonda"
	end
	return hubKey
end

-- Every hub roof, keyed by MapSpec.roofKey: { rise = eave->ridge, halfDepth = eave reach from ridge }.
-- The rise is always whatever puts the ridge on that hub's `ridge` target, the reference included, so
-- `EAVE_UNDERSIDE + rise == hub.ridge` for all six.
function MapSpec.hubRoofs(): { [string]: { rise: number, halfDepth: number } }
	local roofs = {}
	for _, hub in MapSpec.HUBS do
		roofs[MapSpec.roofKey(hub.key)] = {
			rise = hub.ridge - MapSpec.EAVE_UNDERSIDE,
			halfDepth = hub.depth / 2 + MapSpec.ROOF_OVERHANG,
		}
	end
	return roofs
end

function MapSpec.hub(key: string)
	for _, hub in MapSpec.HUBS do
		if hub.key == key then
			return hub
		end
	end
	return nil
end

-- Measuring ("ukur") board: the tall cabai-price gag of ART.md §5. It stands beside the Pasar's east
-- corner, off the road cross and inside the Pasar's own clearing.
MapSpec.UKUR_BOARD = { x = -28, z = -44, yaw = 0, postHeight = 8, boardWidth = 8, boardHeight = 5, boardBottom = 8 }

-- Open spaces ---------------------------------------------------------
MapSpec.PLAZA = { x = 0, z = 0, width = 96, depth = 84 }
MapSpec.LAPANGAN = { x = 0, z = 96, width = 72, depth = 56 }

-- Reserved future hubs: data only, nothing is built. Flora and the tree lattice keep them clear.
MapSpec.FUTURE_SLOTS = {
	{ key = "balai", name = "Balai Desa", x = 0, z = -274, width = 84, depth = 56 },
	{ key = "proyek", name = "Proyek Mangkrak", x = 280, z = 130, width = 68, depth = 60 },
	{ key = "empang", name = "Empang", x = 260, z = 236, width = 68, depth = 48 },
}

-- Player spawn: on the plaza facing -Z (north) so the first frame reads the road to Balai/terraces.
MapSpec.SPAWN = { x = 0, y = GROUND_Y, z = 28, size = 8, lookZ = -1 }

-- Golden hour window and season preset ids live in shared Config/WorldConstants (the client needs them too).
MapSpec.GOLDEN_HOUR = WorldConstants.GOLDEN_HOUR
MapSpec.SEASON_PRESETS = WorldConstants.SEASON_PRESETS

-- The watchtower stands on the Pos Ronda's north-west shoulder, outside the hut roof footprint
-- (hut roof spans z -25.2..25.2) and inside the hub clearing, so its legs never grow out of a deck.
MapSpec.RONDA_TOWER = { x = -112, z = -34, height = 36, deck = 7.2, roofRise = 3.2 }

-- Hub NPC spawn spots (tag NpcSpawn).
MapSpec.NPC_SPOTS = {
	{ npc = "pakrt", x = 68, z = 47 },
	{ npc = "tengkulak", x = -80, z = -98 },
	{ npc = "polisi", x = -68, z = 42 },
}

-- Roads ---------------------------------------------------------------
-- X and Z arms 28 wide from the plaza out to r = 136, a 12-wide connector ring on centreline r = 144
-- broken at 222..246 degrees (the NW alley), 16-wide continuations to the Balai and to the bridge.
local PLAZA_HALF_X = MapSpec.PLAZA.width / 2
local PLAZA_HALF_Z = MapSpec.PLAZA.depth / 2
local ROAD_HALF = 14
local ROAD_RADIUS = 136
local RING_CENTRE = 144
local RING_WIDTH = 12
local RING_PIECES = 56
local RING_STEP = 6
local RING_GAP_START = 222
local RING_GAP_END = 246
local LINK_HALF = 8

MapSpec.ROAD = {
	halfWidth = ROAD_HALF,
	radius = ROAD_RADIUS,
	ringCentre = RING_CENTRE,
	ringWidth = RING_WIDTH,
	gapStart = RING_GAP_START,
	gapEnd = RING_GAP_END,
	linkHalfWidth = LINK_HALF,
	y = GROUND_Y + 0.03,
	earth = { 138, 106, 70 },
	edge = "kertas",
}

-- Straight road pieces. The west arm stops at Pos Ronda's east face (x = -86), so no road runs into
-- a building; the ring picks the hub up around its west side instead.
function MapSpec.roadArms()
	local westEnd = -86
	return {
		{ name = "RoadEast", x = (PLAZA_HALF_X + ROAD_RADIUS) / 2, z = 0, sx = ROAD_RADIUS - PLAZA_HALF_X, sz = ROAD_HALF * 2, edges = true },
		{ name = "RoadWest", x = (westEnd - PLAZA_HALF_X) / 2, z = 0, sx = math.abs(westEnd) - PLAZA_HALF_X, sz = ROAD_HALF * 2, edges = true },
		{ name = "RoadNorth", x = 0, z = (-PLAZA_HALF_Z - ROAD_RADIUS) / 2, sx = ROAD_HALF * 2, sz = ROAD_RADIUS - PLAZA_HALF_Z, edges = true },
		{ name = "RoadSouth", x = 0, z = (PLAZA_HALF_Z + ROAD_RADIUS) / 2, sx = ROAD_HALF * 2, sz = ROAD_RADIUS - PLAZA_HALF_Z, edges = true },
	}
end

-- 16-wide continuations outside the connector ring: north to the Balai Desa slot, south to the bridge.
function MapSpec.roadContinuations()
	local outer = RING_CENTRE + RING_WIDTH / 2
	-- The north link stops at the first terrace ramp it meets: the ramp whose uphill end is closest to
	-- the plaza, i.e. the highest z among the ramp tops that still lie beyond the ring.
	local northEnd = nil
	for _, ramp in MapSpec.RAMPS do
		local hi = math.max(ramp.zLow, ramp.zHigh)
		if hi < -outer then
			northEnd = if northEnd == nil then hi else math.max(northEnd, hi)
		end
	end
	northEnd = northEnd or -outer
	local southEnd = 276 -- the bridge's north approach ramp
	-- The north link spans z -outer .. northEnd (both negative): centre is their mean, length their gap.
	return {
		{
			name = "RoadToBalai", x = 0, z = (-outer + northEnd) / 2,
			sx = LINK_HALF * 2, sz = math.abs(northEnd) - outer,
		},
		{
			name = "RoadToBridge", x = 0, z = (outer + southEnd) / 2,
			sx = LINK_HALF * 2, sz = southEnd - outer,
		},
	}
end

-- Ring road pieces: 6 degree chords from 246 to 582 degrees, so the 222..246 gap stays open.
function MapSpec.ringSegments(): { { x: number, z: number, yaw: number, length: number } }
	local pieces = {}
	for i = 0, RING_PIECES - 1 do
		local mid = RING_GAP_END + RING_STEP / 2 + i * RING_STEP
		local rad = math.rad(mid)
		table.insert(pieces, {
			x = math.cos(rad) * RING_CENTRE,
			z = math.sin(rad) * RING_CENTRE,
			yaw = -(mid + 90),
			length = 2 * RING_CENTRE * math.sin(math.rad(RING_STEP / 2)) + 1.2,
		})
	end
	return pieces
end

-- Terrain blocks ------------------------------------------------------
-- One block of terrain. Any span wider than MAX_FILL_SPAN is split into strips along X by the
-- builder, so no FillBlock here is ever wider than 40 studs.
local function block(x: number, y: number, z: number, sx: number, sy: number, sz: number, material: string)
	return { centre = { x, y, z }, size = { sx, sy, sz }, material = material }
end

local function blockForTop(x: number, z: number, sx: number, sz: number, top: number)
	local cy, sy = MapSpec.volumeForTop(MapSpec.TERRAIN_BASE_Y, top)
	return block(x, cy, z, sx, sy, sz, "Ground")
end

-- Height of a split strip of a very wide volume (the 800 x 800 base slab, the 680-wide terraces).
-- Such a fill is laid in layers of `thickness` (a whole number of voxels) from `bottom` up, so a
-- single FillBlock never asks the voxel engine for a 4-stud slab 800 studs across. Every layer whose
-- top is at or under `top` is laid solid; the topmost one stops at `top`.
local function stripTop(bottom: number, thickness: number, top: number, index: number): number
	return math.min(bottom + thickness * (index + 1), top)
end

-- Split any block wider than MAX_FILL_SPAN into strips no wider than MAX_FILL_SPAN on X and on Z.
-- A ground-volume fill (one that starts at the base slab) is also laid in whole 4-stud layers up to
-- its own top, so a wide fill is never one tall box either. Air never stacks: the clear envelope is
-- simply cut into strips. Nothing this build asks terrain for is wider than 40 studs (a tall, very
-- wide block came out full of holes in Studio, and a 340-wide terrace came out holed).
function MapSpec.splitWide(blocks: { { [string]: any } }): { { [string]: any } }
	local out = {}
	local bottom = MapSpec.TERRAIN_BASE_Y
	local thickness = MapSpec.TERRAIN_VOXEL
	for _, b in blocks do
		if b.size[1] <= MapSpec.MAX_FILL_SPAN and b.size[3] <= MapSpec.MAX_FILL_SPAN then
			table.insert(out, b)
			continue
		end
		-- One layer per strip. The 340-wide holes came from the width, not the height: a 40-wide, 12-tall
		-- strip filled cleanly in Studio (2026-11-15) and lands on regionTop + 2. Stacking partial layers
		-- left every terrace surface half a stud low (live 4.0/8.0/12.0/16.0 instead of 4.5/8.5/12.5/16.5).
		local layers = { { centre = b.centre[2], sy = b.size[2] } }
		local columns = math.ceil(b.size[1] / MapSpec.MAX_FILL_SPAN)
		local rows = math.ceil(b.size[3] / MapSpec.MAX_FILL_SPAN)
		local dw = b.size[1] / columns
		local dz = b.size[3] / rows
		local x0 = b.centre[1] - b.size[1] / 2
		local z0 = b.centre[3] - b.size[3] / 2
		for i = 0, columns - 1 do
			for j = 0, rows - 1 do
				for _, layer in layers do
					table.insert(out, block(x0 + dw * (i + 0.5), layer.centre, z0 + dz * (j + 0.5), dw, layer.sy, dz, b.material))
				end
			end
		end
	end
	return out
end

-- Every volume Greybox owns in the base pass: slab, road corridors, connector ring, plaza,
-- lapangan, hub clearings and the four sawah terraces.
function MapSpec.terrainBlocks(): { { [string]: any } }
	local half = MapSpec.TERRAIN_HALF
	local blocks = {
		block(0, MapSpec.TERRAIN_BASE_Y, 0, half * 2, TERRAIN_VOXEL, half * 2, "Grass"),
		block(0, MapSpec.TERRAIN_BASE_Y, 0, ROAD_RADIUS, TERRAIN_VOXEL, ROAD_HALF * 2, "Ground"),
		block(0, MapSpec.TERRAIN_BASE_Y, 0, ROAD_HALF * 2, TERRAIN_VOXEL, ROAD_RADIUS, "Ground"),
	}
	for _, road in MapSpec.roadContinuations() do
		table.insert(blocks, block(road.x, MapSpec.TERRAIN_BASE_Y, road.z, road.sx, TERRAIN_VOXEL, road.sz, "Ground"))
	end

	-- Connector ring corridor: 30 x 30 ground blocks every 12 degrees, gap 222..246 left alone.
	for i = 0, 28 do
		local deg = RING_GAP_END + 3 + i * 12
		local rad = math.rad(deg)
		table.insert(blocks, block(math.cos(rad) * RING_CENTRE, MapSpec.TERRAIN_BASE_Y, math.sin(rad) * RING_CENTRE, 30, TERRAIN_VOXEL, 30, "Ground"))
	end

	table.insert(blocks, block(MapSpec.PLAZA.x, MapSpec.TERRAIN_BASE_Y, MapSpec.PLAZA.z, MapSpec.PLAZA.width, TERRAIN_VOXEL, MapSpec.PLAZA.depth, "Ground"))
	table.insert(blocks, block(MapSpec.LAPANGAN.x, MapSpec.TERRAIN_BASE_Y, MapSpec.LAPANGAN.z, MapSpec.LAPANGAN.width, TERRAIN_VOXEL, MapSpec.LAPANGAN.depth, "Ground"))

	for _, hub in MapSpec.HUBS do
		local bounds = MapSpec.hubBounds(hub)
		table.insert(blocks, block(
			(bounds.minX + bounds.maxX) / 2,
			MapSpec.TERRAIN_BASE_Y,
			(bounds.minZ + bounds.maxZ) / 2,
			bounds.maxX - bounds.minX + 8,
			TERRAIN_VOXEL,
			bounds.maxZ - bounds.minZ + 8,
			"Ground"
		))
	end

	-- Sawah terraces: one lane per terrace side, raised to that terrace's top, so the 84-wide Balai gap
	-- through the middle of the band stays open for the ramp. The splitter lays each lane in 40-stud
	-- columns and whole-voxel strips, so no single fill is 340 studs wide.
	for _, terrace in MapSpec.TERRACES do
		local z = (terrace.z0 + terrace.z1) / 2
		local depth = terrace.z1 - terrace.z0
		for _, side in MapSpec.TERRACE_SIDES do
			table.insert(blocks, blockForTop((side.x0 + side.x1) / 2, z, side.x1 - side.x0, depth, terrace.top))
		end
	end

	return MapSpec.splitWide(blocks)
end

-- Clear envelope: everything Greybox may ever fill, from below the base slab up to a voxel over the
-- top terrace (region y -10..22, visible face 22.5), 800 x 800. One Air pass here makes a rebuild
-- idempotent, terraces included. Split into 40-stud strips like every other wide fill.
function MapSpec.terrainClear(): { { [string]: any } }
	return MapSpec.splitWide({ block(0, 6, 0, MapSpec.TERRAIN_HALF * 2, 32, MapSpec.TERRAIN_HALF * 2, "Air") })
end

-- Sawah terraces ------------------------------------------------------
-- Four terraces, each 16 deep in z, climbing north from z = -312. The Balai Desa gap (84 wide) is the
-- middle of the band, so the terraces flank the Balai; their own water panes are clipped to the two
-- sides and the gap is left open for the ramp.
MapSpec.TERRACE_STEP = 4
MapSpec.TERRACES = {
	{ top = 4.5, z0 = -328, z1 = -312 },
	{ top = 8.5, z0 = -344, z1 = -328 },
	{ top = 12.5, z0 = -360, z1 = -344 },
	{ top = 16.5, z0 = -376, z1 = -360 },
}

MapSpec.TERRACE_X = { -340, 340 }
MapSpec.TERRACE_GAP = 84
-- The two lanes either side of the Balai gap, shared by every terrace.
MapSpec.TERRACE_SIDES = {
	{ x0 = MapSpec.TERRACE_X[1], x1 = -MapSpec.TERRACE_GAP / 2 },
	{ x0 = MapSpec.TERRACE_GAP / 2, x1 = MapSpec.TERRACE_X[2] },
}
-- Water and padi rows are inset 2 studs from every bund.
local TERRACE_INSET = 2

-- Thin paddy water: 0.2 thick, centre 0.2 above the terrace top so the Part's underside sits
-- 0.1 above the bund, inset 2 studs from every edge. One pane per terrace side, both sides.
function MapSpec.paddyWater(): { { [string]: any } }
	local water = {}
	for _, terrace in MapSpec.TERRACES do
		local z = (terrace.z0 + terrace.z1) / 2
		local depth = terrace.z1 - terrace.z0 - TERRACE_INSET * 2
		for _, side in MapSpec.TERRACE_SIDES do
			table.insert(water, {
				centre = { (side.x0 + side.x1) / 2, terrace.top + 0.2, z },
				size = { side.x1 - side.x0 - TERRACE_INSET * 2, 0.2, depth },
				top = terrace.top,
			})
		end
	end
	return water
end

-- Padi row strips over each paddy, one every 8 studs along X, clipped to each water pane.
function MapSpec.paddyRows(): { { [string]: any } }
	local rows = {}
	for _, pane in MapSpec.paddyWater() do
		local halfWidth = pane.size[1] / 2 - 1
		local cx = pane.centre[1]
		local depth = pane.size[3]
		local first = math.ceil((cx - halfWidth) / 8)
		local last = math.floor((cx + halfWidth) / 8)
		for step = first, last do
			table.insert(rows, {
				centre = { step * 8, pane.top + 0.5, pane.centre[3] },
				size = { 1.2, 0.6, depth },
				top = pane.top,
			})
		end
	end
	return rows
end

-- Central access: tilted Parts climbing one terrace step over 16, 24 wide, up the Balai gap. One runs
-- from the ground beside the Balai to terrace 1, then one between every pair of terraces.
MapSpec.RAMP_WIDTH = 24
MapSpec.RAMPS = (function()
	local list = {
		{ x = 0, zLow = -296, zHigh = -312, yLow = GROUND_Y, yHigh = MapSpec.TERRACES[1].top, width = MapSpec.RAMP_WIDTH },
	}
	for i = 1, #MapSpec.TERRACES - 1 do
		table.insert(list, {
			x = 0,
			zLow = MapSpec.TERRACES[i].z0,
			zHigh = MapSpec.TERRACES[i + 1].z0,
			yLow = MapSpec.TERRACES[i].top,
			yHigh = MapSpec.TERRACES[i + 1].top,
			width = MapSpec.RAMP_WIDTH,
		})
	end
	return list
end)()

-- One riser per side per terrace boundary, because terrain voxels cannot be steps. Each riser
-- straddles the boundary: the half over the lower terrace forms the step, the half over the higher
-- one is buried in it. `top` is the upper terrace's surface, so the tread lands flush with the paddy
-- a player steps onto instead of stopping half a terrace short.
local STAIR_WIDTH = 24
local STAIR_DEPTH = 2
MapSpec.STAIRS = (function()
	local list = {}
	for _, x in { -140, 140 } do
		for i = 1, #MapSpec.TERRACES - 1 do
			local lower = MapSpec.TERRACES[i]
			local upper = MapSpec.TERRACES[i + 1]
			table.insert(list, { x = x, z = lower.z0, top = upper.top, width = STAIR_WIDTH, depth = STAIR_DEPTH })
		end
	end
	return list
end)()

-- Bridge --------------------------------------------------------------
-- Deck 10 x 56 at x = 0, top Y = 1.5, 8-stud approach ramps, railings.
MapSpec.BRIDGE = {
	x = 0,
	z0 = 276,
	z1 = 332,
	width = 10,
	top = 1.5,
	thickness = 0.5,
	rampLength = 8,
	railTop = 3.2,
	railOffsets = { 2.2, 3.1 },
	postEvery = 7,
}

-- Ford ----------------------------------------------------------------
-- Shallow crossing at the west end, 24 wide; the other bank stays reachable in the dry season.
MapSpec.FORD = { x = -250, z = 292, width = 24 }

-- River ---------------------------------------------------------------
-- Centreline z(x) = 304 + 12 sin(2 pi x / 320).
function MapSpec.riverCentreZ(x: number): number
	return 304 + 12 * math.sin(2 * math.pi * x / 320)
end

local RIVER_HALF = 14
local RIVER_BANK = 8
local RIVER_SEGMENT = 16

-- Split a z span into pieces no taller than MAX_FILL_SPAN, so a bank block or a channel block never
-- asks terrain for a fill more than 40 studs deep.
local function zPieces(centre: number, span: number): { { centre: number, span: number } }
	local pieces = {}
	local count = math.max(1, math.ceil(span / MapSpec.MAX_FILL_SPAN))
	local piece = span / count
	for i = 0, count - 1 do
		table.insert(pieces, { centre = centre - span / 2 + piece * (i + 0.5), span = piece })
	end
	return pieces
end

-- River volumes, conservative per 16-stud segment: the z span is the union of the centreline at
-- both segment ends plus the channel width, so a curved bank never leaves an unfilled gap.
--   carves: Air through the base slab and the bank shelf
--   beds:   Mud up to Y = -3.5, the depth MAP_SPEC has always used
--   banks:  Ground ledges at Y = 0.0, 8 studs each side
--   water:  visible surface -0.5, i.e. region top -2.5 under the "+2 visible top" rule
--
-- The channel is 28 wide and each bank 8, and the segment's z slack adds up to 16 more, so a single
-- segment used to reach 44..48 studs across: no piece here is allowed past MAX_FILL_SPAN. The channel
-- (water, bed, carve) and each bank are emitted as their own blocks, each split along Z.
function MapSpec.river(): { carves: { { [string]: any } }, beds: { { [string]: any } }, banks: { { [string]: any } }, water: { { [string]: any } } }
	local carves, beds, banks, water = {}, {}, {}, {}
	local bedCy, bedSy = MapSpec.volumeForTop(-8, -3.5)
	local bankCy, bankSy = MapSpec.volumeForTop(-8, 0)
	local waterCy, waterSy = MapSpec.volumeForTop(-5.5, -0.5)
	local half = MapSpec.TERRAIN_HALF
	for x0 = -half, half - RIVER_SEGMENT, RIVER_SEGMENT do
		local x1 = x0 + RIVER_SEGMENT
		local zA, zB = MapSpec.riverCentreZ(x0), MapSpec.riverCentreZ(x1)
		local cx = x0 + RIVER_SEGMENT / 2
		local lo, hi = math.min(zA, zB), math.max(zA, zB)
		-- The channel: the water column plus the z slack of this segment, split along Z.
		for _, piece in zPieces((lo + hi) / 2, (hi - lo) + RIVER_HALF * 2) do
			table.insert(water, block(cx, waterCy, piece.centre, RIVER_SEGMENT, waterSy, piece.span, "Water"))
			table.insert(beds, block(cx, bedCy, piece.centre, RIVER_SEGMENT, bedSy, piece.span, "Mud"))
			table.insert(carves, block(cx, 4, piece.centre, RIVER_SEGMENT, 24, piece.span, "Air"))
		end
		-- The bank shelf: 8 studs of Ground on each side, opening the same depth as the carve.
		local southBank = lo - RIVER_HALF - RIVER_BANK / 2
		local northBank = hi + RIVER_HALF + RIVER_BANK / 2
		table.insert(banks, block(cx, bankCy, southBank, RIVER_SEGMENT, bankSy, RIVER_BANK, "Ground"))
		table.insert(banks, block(cx, bankCy, northBank, RIVER_SEGMENT, bankSy, RIVER_BANK, "Ground"))
		for _, piece in zPieces(southBank, RIVER_BANK) do
			table.insert(carves, block(cx, 4, piece.centre, RIVER_SEGMENT, 24, piece.span, "Air"))
		end
		for _, piece in zPieces(northBank, RIVER_BANK) do
			table.insert(carves, block(cx, 4, piece.centre, RIVER_SEGMENT, 24, piece.span, "Air"))
		end
	end
	return { carves = carves, beds = beds, banks = banks, water = water }
end

-- Trees and keep-outs are derived from the hub tables, so there is one layout source.
function MapSpec.keepOutRects(): { { number } }
	local rects = {}
	for _, hub in MapSpec.HUBS do
		local bounds = MapSpec.hubBounds(hub)
		table.insert(rects, {
			(bounds.minX + bounds.maxX) / 2,
			(bounds.minZ + bounds.maxZ) / 2,
			(bounds.maxX - bounds.minX) / 2 + 2,
			(bounds.maxZ - bounds.minZ) / 2 + 2,
		})
	end
	table.insert(rects, { MapSpec.PLAZA.x, MapSpec.PLAZA.z, MapSpec.PLAZA.width / 2, MapSpec.PLAZA.depth / 2 })
	table.insert(rects, { MapSpec.LAPANGAN.x, MapSpec.LAPANGAN.z, MapSpec.LAPANGAN.width / 2, MapSpec.LAPANGAN.depth / 2 })
	for _, slot in MapSpec.FUTURE_SLOTS do
		table.insert(rects, { slot.x, slot.z, slot.width / 2, slot.depth / 2 })
	end
	return rects
end

return MapSpec
