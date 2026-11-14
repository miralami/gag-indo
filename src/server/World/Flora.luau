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

local Flora = {}

local FOLDER_NAME = "Flora"
local WIND_TAG = "WindShake"
local GROUND_Y = 0.5
local PART_BUDGET = 200

-- Clearances. Each rule from the brief is checked against the whole footprint of a part, not only
-- its centre: a part of half-size r must sit at least r plus the rule distance away.
local ROAD_HALF_WIDTH = 9 -- rule: nothing overlaps the 18-wide road cross (|x| < 9 or |z| < 9)
local ROAD_MARGIN = 0.5 -- keeps clear of the kertas edge strips
local HUB_RADIUS = 8 -- rule: 8 studs from a hub centre
local TREE_CLEAR = 5 -- keeps bushes, rocks and tufts off the trunks
local EDGE_NORTH = 56 -- rule: nothing on the river (z > 60, |x| < 110)
local EDGE_SOUTH = -80 -- rule: nothing on the sawah terraces (z < -85)

local HUB_CENTRES = {
	{ 0, 0 },
	{ 30, 26 },
	{ 30, -26 },
	{ -30, -26 },
	{ -30, 26 },
	{ 0, -16 },
}

-- Footprints that Greybox and Decor already own (plinths, walls, roofs, signs, yard fences, the
-- set-dressing kits, stacks, beds, stones and NPC marks). Rectangles: { centreX, centreZ, halfX, halfZ }.
local KEEP_OUT_RECTS = {
	{ 0, 0, 10, 8 }, -- Pasar
	{ 0, -16, 8.5, 9 }, -- Tengkulak Gelap
	{ 30, 26, 11.5, 9.5 }, -- Rumah Pak RT and its yard fence
	{ -30, 26, 11.5, 9.5 }, -- Pos Polisi and its yard fence
	{ -29, -27, 8.5, 9 }, -- Pos Ronda and watchtower
	{ 30, -25, 8.5, 9 }, -- Warung and awning
}

-- Discs: { centreX, centreZ, radius }.
local KEEP_OUT_DISCS = {
	{ 30, 30, 16 }, -- dressing kit (Rumah Pak RT side)
	{ -30, 30, 16 }, -- dressing kit (Pos Polisi side)
	{ 12, 12, 4 }, -- crate stack
	{ -12, 12, 4 }, -- crate stack
	{ 38, -14, 4 }, -- crate stack
	{ 20, 11.5, 4 }, -- flower beds (Decor)
	{ 11.5, 20, 4 },
	{ -20, 11.5, 4 },
	{ -11.5, 20, 4 },
	{ -20, -11.5, 4 },
	{ -11.5, -20, 4 },
	{ 20, -11.5, 4 },
	{ 11.5, -20, 4 },
	{ -15, -18, 6 }, -- stepping stones (Decor)
}

-- Lattice: 15 columns by 14 rows, 10 studs apart, each point jittered by up to 2 studs.
local STEP = 10
local COLUMNS = 15
local ROWS = 14
local ORIGIN_X = -70
local ORIGIN_Z = -80

-- Cumulative chances per lattice cell: bush, then rock, then grass tuft; the rest stay empty.
local BUSH_CHANCE = 0.12
local ROCK_CHANCE = 0.2
local TUFT_CHANCE = 0.36

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
	-- Both tests must hold: a box outside the cross is clear of |x| < 9 and of |z| < 9.
	if math.abs(x) - r < ROAD_HALF_WIDTH + ROAD_MARGIN or math.abs(z) - r < ROAD_HALF_WIDTH + ROAD_MARGIN then
		return false
	end
	if z + r > EDGE_NORTH or z - r < EDGE_SOUTH then
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

-- A grass tuft: three to five thin WedgePart blades in daun or padi, fanned and slightly tilted.
local function tuftParts(cell: number, x: number, z: number, scale: number): { PartDef }
	local parts = {}
	local count = 3 + math.floor(roll(cell, 60) * 3)
	local turn = roll(cell, 61) * 360
	for k = 1, count do
		local spread = (k - (count + 1) / 2) * 0.45
		local ox = spread + (roll(cell, 62 + k) * 2 - 1) * 0.2
		local oz = (roll(cell, 70 + k) * 2 - 1) * 0.3
		local height = (1 + roll(cell, 80 + k) * 0.8) * scale
		table.insert(parts, {
			name = "FloraGrass",
			class = "WedgePart",
			size = Vector3.new(0.2, height, 0.45),
			pos = Vector3.new(x + ox, GROUND_Y + height / 2, z + oz),
			orient = Vector3.new((roll(cell, 90 + k) * 2 - 1) * 12, turn + k * 25, 0),
			colour = if k % 2 == 0 then "padi" else "daun",
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
				local x = ORIGIN_X + column * STEP + (roll(cell, 2) * 4 - 2)
				local z = ORIGIN_Z + row * STEP + (roll(cell, 3) * 4 - 2)
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
