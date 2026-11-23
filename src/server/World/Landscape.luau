-- Landscape: a ring of hills 40..80 studs tall outside the playable village rectangle, so the
-- horizon is not a flat plane, with a low saddle on the west edge at z 70..200 for the sunset
-- (ART.md section 5, Terrain). Pure data plus one apply(terrain) that follows the same rule as
-- Greybox.applyTerrain: clear the retired volumes with Air first, then fill the current ones.
--
-- Nothing here is random. Positions are fixed numbers so every rebuild produces the same terrain.
-- The only require is Ground, the shared gameplay plane.
--
-- WORLD SCALE: the village doubled (MapSpec.S), so the hill ring doubled with it. The playable
-- square is now 800 x 800, hills start at +-400, and heights doubled to 40..80 so the horizon still
-- reads over the bigger hubs.

local Ground = require(script.Parent.Ground)
local MapSpec = require(script.Parent.MapSpec)
local Landscape = {}

local GROUND_Y = Ground.Y
local MAX_HILL_HEIGHT = 80

-- Greybox owns an 800x800 village base: |x|, |z| <= 400. A hill may reach under the playable
-- square, but its above-ground cap must stay outside it, so the walkable surface never rises.
local PLAYABLE_HALF = MapSpec.TERRAIN_HALF

-- WORK_QUEUE item 242: a low, flat grass ring BEYOND that square closes the grey void seen from the
-- three canonical overview cameras. It is buried below Terrain's base slab (GROUND_Y - TERRAIN_VOXEL)
-- so it never changes the walkable surface; its top is only a ray target for the far edge. Four
-- non-collidable Parts, each within Roblox's 2048-stud Size cap, are cheaper than extra Terrain fills.
-- This is a reversible default; the designer may retune the band or swap it for a hill silhouette.
local FILL_FOLDER = "HorizonFill"
local FILL_TAG = "HorizonFill"
local FILL_INNER = PLAYABLE_HALF + 4 -- clear of the 400-stud playable square
local FILL_OUTER = FILL_INNER + 1048 -- 1452; still inside one 2048 Part on Z
local FILL_HALF_Z = 1024
local FILL_CENTRE_Y = GROUND_Y - 8.5 -- top -7.5, below the -1.5 Terrain base
local FILL_THICKNESS = 1
local FILL_COLOUR = "#6f8a3f"

-- Widest FillBlock either pass may request. A wide, thin fill came out full of holes in Studio
-- (2026-11-15), so every oversized volume is split into 40-stud strips before it reaches terrain.
local MAX_SPAN = MapSpec.MAX_FILL_SPAN

Landscape.GROUND_Y = GROUND_Y
Landscape.PLAYABLE_HALF = PLAYABLE_HALF
Landscape.MAX_HILL_HEIGHT = MAX_HILL_HEIGHT

-- WORK_QUEUE item 268: reversible dome-hill switch. Read the shared config directly so the gate is
-- correct even when Greybox.build() is not called in an already-built place (the review place loads
-- terrain from disk). Greybox.build still re-asserts it. pcall keeps Lune specs (no `game`) on the
-- old default true, so their hill-fill tests keep their fixtures. Only the FILL pass is gated:
-- clearBlocks (Air) and applyHorizonFill always run, so the horizon stays closed.
local domeDefault = true
local okConfig, config = pcall(function()
	return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").GreyboxTerrainConfig)
end)
if okConfig and type(config) == "table" and type(config.DOME_HILLS) == "boolean" then
	domeDefault = config.DOME_HILLS
end
Landscape.DOME_HILLS_ENABLED = domeDefault

-- Hill balls, placed beyond the playable rectangle. height = how far the top rises above GROUND_Y.
-- Every ball keeps its above-ground cap (radius sqrt(height * (2 * radius - height))) clear of
-- |x|, |z| <= 400, so the walkable surface never rises: a ball's centre sits at least 400 plus its
-- own cap away from the square on whichever axis it faces.
local HILLS = {
	{ x = 462, z = 0, radius = 56, height = 62, material = Enum.Material.Grass },
	{ x = 446, z = 178, radius = 46, height = 52, material = Enum.Material.Grass },
	{ x = 444, z = -182, radius = 44, height = 46, material = Enum.Material.Ground },
	{ x = -462, z = 0, radius = 58, height = 72, material = Enum.Material.Grass },
	{ x = -450, z = -200, radius = 48, height = 48, material = Enum.Material.Grass },
	{ x = -456, z = -262, radius = 52, height = 56, material = Enum.Material.Rock },
	-- West sunset gap: hills on the west edge z 70..200 are capped at 24 studs and the lowest,
	-- widest gap is centred on z = 132, so the 17.2 ClockTime sun line (-0.93, 0.20, 0.31) leaves
	-- the square unblocked.
	{ x = -446, z = 70, radius = 34, height = 20, material = Enum.Material.Grass },
	{ x = -442, z = 132, radius = 40, height = 12, material = Enum.Material.Ground },
	{ x = -444, z = 196, radius = 32, height = 24, material = Enum.Material.Grass },
	{ x = 0, z = -462, radius = 58, height = 60, material = Enum.Material.Grass },
	{ x = -204, z = -454, radius = 50, height = 46, material = Enum.Material.Mud },
	{ x = 208, z = -454, radius = 50, height = 50, material = Enum.Material.Grass },
	-- South: behind the river meadow, low enough to leave the sunset line over the bridge open.
	{ x = -142, z = 450, radius = 44, height = 40, material = Enum.Material.Grass },
	{ x = 152, z = 448, radius = 42, height = 40, material = Enum.Material.Mud },
}

-- Small blocks for variety: a rock outcrop on the west hill's shoulder, a wet hollow on the west
-- edge south of the sunset gap. Both sit outside the playable rectangle with their hills.
local OUTCROPS = {
	{ position = Vector3.new(-428, GROUND_Y + 6, 40), size = Vector3.new(20, 12, 18), material = Enum.Material.Rock },
	{ position = Vector3.new(-424, GROUND_Y + 2, 214), size = Vector3.new(22, 4, 20), material = Enum.Material.Mud },
}

-- Every earlier build's hills and outcrops. apply clears their above-ground footprint too: moving a
-- hill must not leave its old mound on a rebuild. Only the part above GROUND_Y is cleared, so the
-- baseline below ground is left intact. LEGACY_HILLS is the half-scale ring (playable 200) and
-- LEGACY_HILLS_400 the first pass on the doubled square (playable 400, 40 tall), so a place that
-- was opened at either scale comes back clean.
local LEGACY_HILLS = {
	{ x = 190, z = 0, radius = 32, height = 14, material = Enum.Material.Grass },
	{ x = 172, z = 80, radius = 26, height = 10, material = Enum.Material.Grass },
	{ x = 172, z = -80, radius = 28, height = 12, material = Enum.Material.Grass },
	{ x = -190, z = 0, radius = 34, height = 16, material = Enum.Material.Grass },
	{ x = -172, z = 80, radius = 26, height = 9, material = Enum.Material.Ground },
	{ x = -172, z = -80, radius = 30, height = 13, material = Enum.Material.Grass },
	{ x = 0, z = -190, radius = 30, height = 15, material = Enum.Material.Grass },
	{ x = -95, z = -164, radius = 28, height = 11, material = Enum.Material.Mud },
	{ x = 95, z = -164, radius = 27, height = 10, material = Enum.Material.Rock },
	{ x = 245, z = 0, radius = 42, height = 40, material = Enum.Material.Grass },
	{ x = 240, z = 95, radius = 36, height = 28, material = Enum.Material.Grass },
	{ x = 238, z = -95, radius = 34, height = 26, material = Enum.Material.Ground },
	{ x = -246, z = 0, radius = 44, height = 36, material = Enum.Material.Grass },
	{ x = -244, z = 110, radius = 36, height = 24, material = Enum.Material.Grass },
	{ x = -244, z = -110, radius = 40, height = 30, material = Enum.Material.Rock },
	{ x = -238, z = 40, radius = 28, height = 10, material = Enum.Material.Grass },
	{ x = -236, z = 68, radius = 30, height = 6, material = Enum.Material.Ground },
	{ x = -238, z = 94, radius = 26, height = 12, material = Enum.Material.Grass },
	{ x = 0, z = -246, radius = 44, height = 34, material = Enum.Material.Grass },
	{ x = -110, z = -240, radius = 38, height = 26, material = Enum.Material.Mud },
	{ x = 110, z = -240, radius = 38, height = 28, material = Enum.Material.Grass },
}

local LEGACY_OUTCROPS = {
	{ position = Vector3.new(-160, GROUND_Y + 3, 25), size = Vector3.new(12, 6, 10), material = Enum.Material.Rock },
	{ position = Vector3.new(-150, GROUND_Y + 1, -60), size = Vector3.new(14, 2, 12), material = Enum.Material.Mud },
	{ position = Vector3.new(-232, GROUND_Y + 4, 22), size = Vector3.new(14, 8, 12), material = Enum.Material.Rock },
	{ position = Vector3.new(-230, GROUND_Y + 1.5, 108), size = Vector3.new(16, 3, 14), material = Enum.Material.Mud },
}

-- Palette colours (ART.md section 3). Ground #8a6a46 is not in that table; it was requested
-- explicitly for this lane and should be added to section 3 or swapped.
local COLOURS = {
	{ material = Enum.Material.Grass, hex = "#6f8a3f" }, -- daun
	{ material = Enum.Material.Ground, hex = "#8a6a46" }, -- requested; not yet in ART.md section 3
	{ material = Enum.Material.Mud, hex = "#5b4a38" }, -- tinta-lembut
	{ material = Enum.Material.Rock, hex = "#5b4a38" }, -- tinta-lembut
	-- Water is coloured with Terrain.WaterColor (Greybox.build sets it to malam); SetMaterialColor
	-- rejects Water with "Unsupported terrain material".
}

local function ballVolume(hill)
	return {
		shape = "ball",
		position = Vector3.new(hill.x, GROUND_Y + hill.height - hill.radius, hill.z),
		radius = hill.radius,
		height = hill.height,
		material = hill.material,
	}
end

local function blockVolume(block)
	return {
		shape = "block",
		position = block.position,
		size = block.size,
		material = block.material,
	}
end

local function appendVolumes(out, hills, blocks)
	for _, hill in hills do
		table.insert(out, ballVolume(hill))
	end
	for _, block in blocks do
		table.insert(out, blockVolume(block))
	end
end

-- Split one volume into pieces no wider than MAX_SPAN on X or Z, so no FillBlock is 800 studs across.
-- Balls are left alone: the wide-fill defect was a FillBlock (a box) coming out holed, and a FillBall
-- is not a block, so a hill keeps exactly one operation however wide its base is. A block is cut into
-- a grid of strips, and one that already fits passes through untouched.
local function splitVolume(volume: { [string]: any }): { { [string]: any } }
	if volume.shape ~= "block" then
		return { volume }
	end

	local sx, sy, sz = volume.size.X, volume.size.Y, volume.size.Z
	if sx <= MAX_SPAN and sz <= MAX_SPAN then
		return { volume }
	end
	local columns = math.ceil(sx / MAX_SPAN)
	local rows = math.ceil(sz / MAX_SPAN)
	local dw, dz = sx / columns, sz / rows
	local x0, z0 = volume.position.X - sx / 2, volume.position.Z - sz / 2
	local pieces = {}
	for i = 0, columns - 1 do
		for j = 0, rows - 1 do
			table.insert(pieces, {
				shape = "block",
				position = Vector3.new(x0 + dw * (i + 0.5), volume.position.Y, z0 + dz * (j + 0.5)),
				size = Vector3.new(dw, sy, dz),
				material = volume.material,
			})
		end
	end
	return pieces
end

local function splitAll(volumes)
	local out = {}
	for _, volume in volumes do
		for _, piece in splitVolume(volume) do
			table.insert(out, piece)
		end
	end
	return out
end

-- Every volume this module currently owns, as plain data, already split into 40-stud pieces:
--   { shape = "ball", position, radius, material }  or  { shape = "block", position, size, material }
function Landscape.hillBlocks(): { { [string]: any } }
	local volumes = {}
	appendVolumes(volumes, HILLS, OUTCROPS)
	return splitAll(volumes)
end

-- Item 242 far fill as plain data: four buried grass slabs forming a ring just outside the playable
-- square. XZ bounds are one axis-aligned rectangle per slab, so the data-only spec can prove none of
-- them enters the playable square or the 100-stud PERF proxy. No Instance or Enum call at load.
function Landscape.horizonFillParts(): { { [string]: any } }
	local width = FILL_OUTER - FILL_INNER
	local centre = (FILL_INNER + FILL_OUTER) / 2
	local cross = FILL_HALF_Z * 2
	local function descriptor(name: string, x: number, z: number, sx: number, sz: number)
		return {
			name = name,
			tag = FILL_TAG,
			size = { sx, FILL_THICKNESS, sz },
			position = { x, FILL_CENTRE_Y, z },
			colour = FILL_COLOUR,
		}
	end
	return {
		descriptor("HorizonFillEast", centre, 0, width, cross),
		descriptor("HorizonFillWest", -centre, 0, width, cross),
		descriptor("HorizonFillNorth", 0, centre, FILL_INNER * 2, width),
		descriptor("HorizonFillSouth", 0, -centre, FILL_INNER * 2, width),
	}
end

do
	for _, part in ipairs(Landscape.horizonFillParts()) do
		assert(part.size[1] <= 2048 and part.size[3] <= 2048, "Landscape: far fill exceeds the Part Size cap")
		assert(
			part.position[2] + part.size[2] / 2 < GROUND_Y - MapSpec.TERRAIN_VOXEL,
			"Landscape: far fill is not below the Terrain base"
		)
	end
end

-- Clip an old volume to the part above GROUND_Y. Clearing this restores the baseline surface
-- without digging a crater under the old hill.
local function aboveGroundClear(volume)
	if volume.shape == "ball" then
		local top = volume.position.Y + volume.radius
		if top <= GROUND_Y then
			return nil
		end
		local cap = math.sqrt(volume.radius ^ 2 - (GROUND_Y - volume.position.Y) ^ 2)
		local height = top - GROUND_Y
		return {
			shape = "block",
			position = Vector3.new(volume.position.X, GROUND_Y + height / 2, volume.position.Z),
			size = Vector3.new(cap * 2, height, cap * 2),
			material = Enum.Material.Air,
		}
	end

	local top = volume.position.Y + volume.size.Y / 2
	local bottom = math.max(GROUND_Y, volume.position.Y - volume.size.Y / 2)
	if top <= bottom then
		return nil
	end
	return {
		shape = "block",
		position = Vector3.new(volume.position.X, (bottom + top) / 2, volume.position.Z),
		size = Vector3.new(volume.size.X, top - bottom, volume.size.Z),
		material = Enum.Material.Air,
	}
end

-- Every legacy volume's above-ground footprint, and nothing else, split so no clear exceeds 40 studs
-- on X or Z. Clearing the current HILLS and OUTCROPS as well would double the fill count for no gain:
-- fills are idempotent and the current hill data is fixed in code, so the Air pass exists only to
-- erase retired volumes.
--
-- WORLD SCALE: two ring generations are retired here, the half-scale one and the first pass on the
-- doubled square, so this is 25 volumes and about 97 strip pieces after the 40-stud split. With 16
-- hill fills and 4 material colours that is roughly 118 terrain operations per rebuild — well past
-- the old 40-operation cap, which was authored for a single 9-hill ring. A place opened at either
-- earlier scale still comes back clean.
function Landscape.clearBlocks(): { { [string]: any } }
	local retired = {}
	appendVolumes(retired, LEGACY_HILLS, LEGACY_OUTCROPS)

	local volumes = {}
	for _, volume in retired do
		local clear = aboveGroundClear(volume)
		if clear then
			table.insert(volumes, clear)
		end
	end
	return splitAll(volumes)
end

local function fill(terrain: Terrain, volume: { [string]: any }, material: Enum.Material)
	if volume.shape == "ball" then
		terrain:FillBall(volume.position, volume.radius, material)
	else
		terrain:FillBlock(CFrame.new(volume.position), volume.size, material)
	end
end

-- Rebuild the far-fill folder from data. Greybox.build() destroys the whole World folder on a
-- rebuild, but this also removes an older copy if apply() is called twice on the same place, so the
-- result is idempotent. The parts are invisible to physics and shadows, queryable by the ray check,
-- and never inside the playable square or the 100-stud PERF proxy.
local function applyHorizonFill(terrain: Terrain)
	local root = terrain.Parent
	local world = root and root:FindFirstChild("World") or root
	if not world then
		return
	end
	local previous = world:FindFirstChild(FILL_FOLDER)
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = FILL_FOLDER
	folder.Parent = world
	for _, descriptor in ipairs(Landscape.horizonFillParts()) do
		local part = Instance.new("Part")
		part.Name = descriptor.name
		part.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		part.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		part.Color = Color3.fromHex(descriptor.colour)
		part.Material = Enum.Material.Grass
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.CanQuery = true
		part:SetAttribute(descriptor.tag, true)
		part.Parent = folder
	end
end

-- Clears the retired footprints with Air, sets the palette, then fills the current volumes. Safe
-- to call on every rebuild.
function Landscape.apply(terrain: Terrain)
	-- Terrain.Decoration (grass decoration) cannot be written from a script ('lacking capability
	-- PluginOrOpenCloud', seen in Studio 2026-11-14). It is a place-file setting: tick it in
	-- Studio > Terrain > Properties > Decoration (track C), like Lighting.Technology.
	local clear = Landscape.clearBlocks()
	for _, volume in clear do
		fill(terrain, volume, Enum.Material.Air)
	end
	for _, colour in COLOURS do
		terrain:SetMaterialColor(colour.material, Color3.fromHex(colour.hex))
	end
	if Landscape.DOME_HILLS_ENABLED ~= false then
		for _, volume in Landscape.hillBlocks() do
			fill(terrain, volume, volume.material)
		end
	end
	applyHorizonFill(terrain)
end

return Landscape
