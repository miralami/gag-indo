-- Landscape: a ring of low rolling hills outside the playable village rectangle, so the horizon
-- is not a flat plane (ART.md section 5, Terrain). Pure data plus one apply(terrain) that follows
-- the same rule as Greybox.applyTerrain: clear every owned volume with Air first, then fill.
--
-- Nothing here is random. Positions are fixed numbers so every rebuild produces the same terrain.
-- The only require is Ground, the shared gameplay plane.

local Ground = require(script.Parent.Ground)
local Landscape = {}

local GROUND_Y = Ground.Y
local MAX_HILL_HEIGHT = 22

-- Greybox owns a 400x400 village base: |x|, |z| <= 200. A hill may reach under the playable
-- square, but its above-ground cap must stay outside it, so the walkable surface never rises.
local PLAYABLE_HALF = 200

Landscape.GROUND_Y = GROUND_Y
Landscape.PLAYABLE_HALF = PLAYABLE_HALF

-- Hill balls, placed beyond the playable rectangle. height = how far the top rises above GROUND_Y.
local HILLS = {
	{ x = 225, z = 0, radius = 28, height = 10, material = Enum.Material.Grass },
	{ x = 222, z = 78, radius = 24, height = 8, material = Enum.Material.Grass },
	{ x = 224, z = -78, radius = 26, height = 9, material = Enum.Material.Grass },
	{ x = -228, z = 0, radius = 32, height = 14, material = Enum.Material.Grass },
	{ x = -224, z = 78, radius = 24, height = 8, material = Enum.Material.Ground },
	{ x = -226, z = -78, radius = 28, height = 11, material = Enum.Material.Grass },
	{ x = 0, z = -230, radius = 28, height = 12, material = Enum.Material.Grass },
	{ x = -95, z = -225, radius = 28, height = 11, material = Enum.Material.Mud },
	{ x = 95, z = -224, radius = 27, height = 10, material = Enum.Material.Rock },
}

-- Small blocks for variety: a rock outcrop on the west hill's shoulder, a wet hollow beside the
-- south-west hill. Both sit outside the playable rectangle with their hills.
local OUTCROPS = {
	{ position = Vector3.new(-228, GROUND_Y + 3, 23), size = Vector3.new(12, 6, 10), material = Enum.Material.Rock },
	{ position = Vector3.new(-226, GROUND_Y + 1, -57), size = Vector3.new(14, 2, 12), material = Enum.Material.Mud },
}

-- The first build's hills and outcrops. apply clears their above-ground footprint too: moving a
-- hill must not leave its old mound on a rebuild. Only the part above GROUND_Y is cleared, so the
-- baseline below ground is left intact.
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
}

local LEGACY_OUTCROPS = {
	{ position = Vector3.new(-160, GROUND_Y + 3, 25), size = Vector3.new(12, 6, 10), material = Enum.Material.Rock },
	{ position = Vector3.new(-150, GROUND_Y + 1, -60), size = Vector3.new(14, 2, 12), material = Enum.Material.Mud },
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

-- Every volume this module currently owns, as plain data:
--   { shape = "ball", position, radius, material }  or  { shape = "block", position, size, material }
function Landscape.hillBlocks(): { { [string]: any } }
	local volumes = {}
	appendVolumes(volumes, HILLS, OUTCROPS)
	return volumes
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

-- Every volume apply clears: retired above-ground footprints, then the current full volumes.
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
	appendVolumes(volumes, HILLS, OUTCROPS)
	return volumes
end

local function fill(terrain: Terrain, volume: { [string]: any }, material: Enum.Material)
	if volume.shape == "ball" then
		terrain:FillBall(volume.position, volume.radius, material)
	else
		terrain:FillBlock(CFrame.new(volume.position), volume.size, material)
	end
end

-- Clears every owned volume with Air, sets the palette, then fills. Safe to call on every rebuild.
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
	for _, volume in Landscape.hillBlocks() do
		fill(terrain, volume, volume.material)
	end
end

return Landscape
