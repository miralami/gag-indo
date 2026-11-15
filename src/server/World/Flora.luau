-- Flora: the layered nature pass for the greybox village (ART.md section 5; research tracker
-- section 1 "layers: trees, then bushes, then grass, then micro detail").
-- Everything lives in one Folder named `Flora` under the world, so a rebuild is one Destroy.
-- Positions come from a fixed lattice and a pure integer hash, so every server builds the same
-- flora. No unseeded random. Palette colours only. Anchored, unqueryable, no shadows, no lights,
-- no particles, no asset IDs.
-- Run this after Greybox.build, so the tree trunks exist for the clearance check.
-- Tree canopies (Canopy_N inside Tree_N models directly under the world) are tagged WindShake
-- with a WindSeed attribute for the client sway loop (client/World/Wind.luau).

local Props = require(script.Parent.Props)
local MapSpec = require(script.Parent.MapSpec)

local Flora = {}

local FOLDER_NAME = "Flora"
local WIND_TAG = "WindShake"
local GROUND_Y = MapSpec.GROUND_Y
local PART_BUDGET = 200

-- Clearances. Each rule from the brief is checked against the whole footprint of a part, not only
-- its centre: a part of half-size r must sit at least r plus the rule distance away.
local ROAD_HALF_WIDTH = MapSpec.ROAD.halfWidth -- rule: nothing overlaps the 28-wide road cross
local ROAD_MARGIN = 0.5 -- keeps clear of the kertas edge strips
local HUB_RADIUS = 16 -- rule: 16 studs from a hub centre (the hub clearings)
local TREE_CLEAR = 5 -- keeps bushes, rocks and tufts off the trunks
local EDGE_NORTH = MapSpec.BRIDGE.z0 - 20 -- rule: nothing on the river (z > 256, |x| < 220)
local EDGE_SOUTH = -168 -- rule: nothing on the sawah terraces (z < -168)
local EDGE_EAST = 196 -- rule: nothing past the plot ring, the forest takes over
local EDGE_WEST = -196

-- Hub centres from the hub table, so this list can never drift from the buildings.
local HUB_CENTRES = {}
for _, hub in MapSpec.HUBS do
	table.insert(HUB_CENTRES, { hub.x, hub.z })
end

-- Footprints that Greybox and Decor already own (plinths, walls, roofs, signs, the set-dressing kits,
-- stacks, beds, stones, the well, the ford markers and NPC marks). Rectangles:
-- { centreX, centreZ, halfX, halfZ }. Hub rectangles follow MapSpec.hubBounds.
local KEEP_OUT_RECTS = {
	{ MapSpec.UKUR_BOARD.x, MapSpec.UKUR_BOARD.z, MapSpec.UKUR_BOARD.boardWidth / 2 + 1, 2 },
	{ MapSpec.RONDA_TOWER.x, MapSpec.RONDA_TOWER.z, MapSpec.RONDA_TOWER.deck / 2 + 1, MapSpec.RONDA_TOWER.deck / 2 + 1 },
}
for _, hub in MapSpec.HUBS do
	local bounds = MapSpec.hubBounds(hub)
	table.insert(KEEP_OUT_RECTS, {
		(bounds.minX + bounds.maxX) / 2,
		(bounds.minZ + bounds.maxZ) / 2,
		(bounds.maxX - bounds.minX) / 2 + 4,
		(bounds.maxZ - bounds.minZ) / 2 + 4,
	})
end

-- Discs: { centreX, centreZ, radius }. Every Decor and Details item that stands at ground level in
-- the open band gets one, so a tree, bush or rock never lands on top of it.
local KEEP_OUT_DISCS = {
	-- Decor crate stacks.
	{ 40, 40, 7 },
	{ -40, 40, 7 },
	{ 56, -30, 7 },
	-- Decor Lapangan well and flagpole.
	{ 34, 92, 8 },
	{ 34, 106, 8 },
	-- Decor notice board.
	{ -32, 38, 8 },
}
-- Decor flower beds.
for _, centre in {
	{ 30, 52 }, { 52, 30 }, { -30, 52 }, { -52, 30 }, { -52, -30 }, { 52, -30 },
} do
	table.insert(KEEP_OUT_DISCS, { centre[1], centre[2], 8 })
end
-- Decor stones (north path to Pak RT) and Details stones (south-west path to Pos Polisi).
for _, stone in { { 40, 30 }, { 44, 36 }, { 48, 42 }, { 52, 46 }, { -30, 30 }, { -40, 34 }, { -50, 38 }, { -60, 42 } } do
	table.insert(KEEP_OUT_DISCS, { stone[1], stone[2], 6 })
end
-- Details mud patches, puddles, sacks and troughs.
for _, spot in {
	{ 28, -92, 8 }, { -26, -80, 7 }, { -48, -98, 8 }, { 102, -60, 8 }, { 88, 40, 7 },
	{ 26, -44, 6 }, { -26, -52, 6 }, { 84, -40, 6 },
	{ 44, -24, 4 }, { -44, -24, 4 }, { 52, -96, 4 }, { 104, 44, 4 },
	{ 98, -78, 4 }, { -100, -60, 4 },
} do
	table.insert(KEEP_OUT_DISCS, { spot[1], spot[2], spot[3] })
end
-- Details sightline breakers (hedge rows and crate stacks).
for _, breaker in { { 36, -84, 9 }, { 24, -78, 6 }, { -24, -78, 6 }, { -46, -96, 9 }, { 82, 44, 9 }, { -82, 40, 9 }, { 26, -50, 6 }, { 98, -66, 6 }, { -100, -66, 6 } } do
	table.insert(KEEP_OUT_DISCS, { breaker[1], breaker[2], breaker[3] })
end

-- Lattice: 25 columns by 24 rows, 16 studs apart, each point jittered by up to 3 studs. It covers the
-- village between the plaza ring and the plot ring, west of the forest.
local STEP = 16
local COLUMNS = 25
local ROWS = 24
local ORIGIN_X = -192
local ORIGIN_Z = -184

-- Cumulative chances per lattice cell: bush, then rock, then grass tuft; the rest stay empty.
local BUSH_CHANCE = 0.08
local ROCK_CHANCE = 0.14
local TUFT_CHANCE = 0.42

-- Integer hash in [0, 1). Pure: the same cell and salt always give the same number.
local function roll(cell: number, salt: number): number
	local h = (cell * 1103515245 + salt * 12345 + 1013904223) % 2147483648
	return h / 2147483648
end

-- Each foliage part gets a small deterministic brightness shift: 0 to 8 percent toward kertas
-- (lighter) or indigo (cooler). Both ends are palette colours.
local function tint(base: Color3, r: number): Color3
	if r < 0.5 then
		return base:Lerp(Props.palette("kertas"), r * 0.16)
	end
	return base:Lerp(Props.palette("indigo"), (r - 0.5) * 0.16)
end

local function distance(x: number, z: number, cx: number, cz: number): number
	local dx, dz = x - cx, z - cz
	return math.sqrt(dx * dx + dz * dz)
end

-- True when a square footprint of half-size r centred on (x, z) clears the road cross, the river,
-- the sawah, every hub ring, every owned footprint and every trunk.
local function fitsAt(x: number, z: number, r: number, trunks: { { number } }): boolean
	-- Both tests must hold: a box outside the cross is clear of both road arms.
	if math.abs(x) - r < ROAD_HALF_WIDTH + ROAD_MARGIN or math.abs(z) - r < ROAD_HALF_WIDTH + ROAD_MARGIN then
		return false
	end
	-- The village band: river to the north (high z), sawah to the south (low z), forest past the ring.
	if z + r > EDGE_NORTH or z - r < EDGE_SOUTH then
		return false
	end
	if x - r < EDGE_WEST or x + r > EDGE_EAST then
		return false
	end
	for _, hub in HUB_CENTRES do
		if distance(x, z, hub[1], hub[2]) < HUB_RADIUS + r then
			return false
		end
	end
	for _, rect in KEEP_OUT_RECTS do
		if math.abs(x - rect[1]) < rect[3] + r and math.abs(z - rect[2]) < rect[4] + r then
			return false
		end
	end
	for _, disc in KEEP_OUT_DISCS do
		if distance(x, z, disc[1], disc[2]) < disc[3] + r then
			return false
		end
	end
	for _, trunk in trunks do
		if distance(x, z, trunk[1], trunk[2]) < TREE_CLEAR + r then
			return false
		end
	end
	return true
end

-- A part definition: everything makePart needs, in plain numbers so the layout can be checked first.
type PartDef = {
	name: string,
	class: string,
	shape: any?,
	size: Vector3,
	pos: Vector3,
	orient: Vector3,
	colour: string,
	material: any,
	jitter: number?,
}

-- Two or three overlapping Ball parts in daun or padi, sunk slightly into the ground.
local function bushParts(cell: number, x: number, z: number, scale: number): { PartDef }
	local parts = {}
	local count = 2 + math.floor(roll(cell, 5) * 2)
	for k = 1, count do
		local ox = (roll(cell, 10 + k) * 2 - 1) * 1.6
		local oz = (roll(cell, 20 + k) * 2 - 1) * 1.6
		local size = (2.6 + roll(cell, 30 + k) * 1.2) * scale
		table.insert(parts, {
			name = "FloraBush",
			class = "Part",
			shape = Enum.PartType.Ball,
			size = Vector3.new(size, size, size),
			pos = Vector3.new(x + ox, GROUND_Y + size / 2 - 0.3, z + oz),
			orient = Vector3.new(0, 0, 0),
			colour = if roll(cell, 40 + k) < 0.5 then "daun" else "padi",
			material = Enum.Material.Grass,
			jitter = roll(cell, 46 + k),
		})
	end
	return parts
end

-- One squashed Block in tinta-lembut or bambu, Slate, turned by the cell hash.
local function rockParts(cell: number, x: number, z: number, scale: number): { PartDef }
	local sx = (1.4 + roll(cell, 50) * 1.2) * scale
	local sy = (0.7 + roll(cell, 51) * 0.5) * scale
	local sz = (1.2 + roll(cell, 52) * 0.8) * scale
	return {
		{
			name = "FloraRock",
			class = "Part",
			size = Vector3.new(sx, sy, sz),
			pos = Vector3.new(x, GROUND_Y + sy / 2 - 0.15, z),
			orient = Vector3.new(0, roll(cell, 53) * 360, 0),
			colour = if roll(cell, 54) < 0.5 then "tintaLembut" else "bambu",
			material = Enum.Material.Slate,
		},
	}
end

-- A grass tuft: 3 to 4 chunky stylized WedgePart blades in daun and padi, fanned outwards slightly.
local function tuftParts(cell: number, x: number, z: number, scale: number): { PartDef }
	local parts = {}
	local count = 3 + math.floor(roll(cell, 60) * 2)
	local turn = roll(cell, 61) * 360
	for k = 1, count do
		local spread = (k - (count + 1) / 2) * 0.4
		local ox = spread + (roll(cell, 62 + k) * 2 - 1) * 0.15
		local oz = (roll(cell, 70 + k) * 2 - 1) * 0.15
		local width = 0.45 + roll(cell, 75 + k) * 0.30
		local depth = 0.25 + roll(cell, 80 + k) * 0.10
		local height = 1.3 + roll(cell, 85 + k) * 0.90
		local fanAngle = (k - (count + 1) / 2) * 16 + (roll(cell, 90 + k) * 2 - 1) * 6
		table.insert(parts, {
			name = "FloraGrass",
			class = "WedgePart",
			size = Vector3.new(width, height, depth),
			pos = Vector3.new(x + ox, GROUND_Y + height / 2, z + oz),
			orient = Vector3.new((roll(cell, 95 + k) * 2 - 1) * 8, turn + fanAngle, 0),
			colour = if (k + math.floor(roll(cell, 105) * 2)) % 2 == 0 then "padi" else "daun",
			material = Enum.Material.Grass,
			jitter = roll(cell, 100 + k),
		})
	end
	return parts
end

-- Every part of an item must pass. The half-size is the larger horizontal side, so a turned part is covered too.
local function fitsAll(parts: { PartDef }, trunks: { { number } }): boolean
	for _, def in parts do
		local r = math.max(def.size.X, def.size.Z) / 2
		if not fitsAt(def.pos.X, def.pos.Z, r, trunks) then
			return false
		end
	end
	return true
end

local function makePart(folder: Instance, def: PartDef)
	local p = Instance.new(def.class)
	p.Name = def.name
	if def.shape then
		(p :: any).Shape = def.shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = def.size
	p.Position = def.pos
	p.Orientation = def.orient
	p.Material = def.material
	local base = Props.palette(def.colour)
	p.Color = if def.jitter then tint(base, def.jitter) else base
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
end

-- Trunk positions (X, Z) of every Tree_N model directly under the world.
local function treeTrunks(world: Instance): { { number } }
	local trunks = {}
	for _, child in world:GetChildren() do
		if child.ClassName == "Model" and string.match(child.Name, "^Tree_%d+$") then
			local trunk = child:FindFirstChild("Trunk")
			if trunk then
				table.insert(trunks, { trunk.Position.X, trunk.Position.Z })
			end
		end
	end
	return trunks
end

-- Tags each canopy with WindShake and a deterministic WindSeed in [0, 6.28).
local function tagCanopies(world: Instance)
	local collection = game:GetService("CollectionService")
	for _, child in world:GetChildren() do
		local treeNumber = if child.ClassName == "Model" then string.match(child.Name, "^Tree_(%d+)$") else nil
		if treeNumber then
			local tree = tonumber(treeNumber) :: number
			for _, part in child:GetChildren() do
				local canopy = string.match(part.Name, "^Canopy_(%d+)$")
				if canopy then
					collection:AddTag(part, WIND_TAG)
					part:SetAttribute("WindSeed", roll(tree * 10 + (tonumber(canopy) :: number), 99) * 6.28)
				end
			end
		end
	end
end

-- Builds the Flora folder under world. Destroys a previous Flora first, so calling it again
-- leaves exactly one folder with the same parts.
function Flora.build(world: Instance): Instance
	local old = world:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end

	local trunks = treeTrunks(world)
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	local count = 0
	for column = 0, COLUMNS - 1 do
		for row = 0, ROWS - 1 do
			local cell = column * 100 + row
			local choice = roll(cell, 1)
			local make
			if choice < BUSH_CHANCE then
				make = bushParts
			elseif choice < ROCK_CHANCE then
				make = rockParts
			elseif choice < TUFT_CHANCE then
				make = tuftParts
			end
			if make then
				local x = ORIGIN_X + column * STEP + (roll(cell, 2) * 6 - 3)
				local z = ORIGIN_Z + row * STEP + (roll(cell, 3) * 6 - 3)
				local scale = 0.85 + 0.3 * roll(cell, 4)
				local defs = make(cell, x, z, scale)
				if count + #defs <= PART_BUDGET and fitsAll(defs, trunks) then
					for _, def in defs do
						makePart(folder, def)
					end
					count += #defs
				end
			end
		end
	end

	folder.Parent = world
	tagCanopies(world)
	return folder
end

-- Read-only views of the owned footprints, for the spec.
Flora.KEEP_OUT_RECTS = KEEP_OUT_RECTS
Flora.KEEP_OUT_DISCS = KEEP_OUT_DISCS

return Flora
