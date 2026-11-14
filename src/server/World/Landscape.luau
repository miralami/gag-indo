-- Landscape: a ring of low rolling hills around the village, so the horizon is not a flat plane
-- (ART.md section 5, Terrain). Pure data plus one apply(terrain) that follows the same rule as
-- Greybox.applyTerrain: clear every owned volume with Air first, then fill.
--
-- Nothing here is random. Positions are fixed numbers so every rebuild produces the same terrain.
-- No requires: this module only builds Vector3 values and calls the Terrain API.

local Landscape = {}

local GROUND_Y = 0.5
local MAX_HILL_HEIGHT = 22

-- Hill balls, placed on a ring about 190 studs from the origin, away from the river (south, +Z)
-- and the terraces (north-centre, -Z). height = how far the top rises above GROUND_Y.
local HILLS = {
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

-- Small blocks for variety: a rock outcrop on the west hill's shoulder, a wet hollow beside the
-- south-west hill.
local OUTCROPS = {
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

-- Every volume this module owns, as plain data:
--   { shape = "ball", position, radius, material }  or  { shape = "block", position, size, material }
function Landscape.hillBlocks(): { { [string]: any } }
	local volumes = {}
	for _, hill in HILLS do
		table.insert(volumes, {
			shape = "ball",
			position = Vector3.new(hill.x, GROUND_Y + hill.height - hill.radius, hill.z),
			radius = hill.radius,
			material = hill.material,
		})
	end
	for _, block in OUTCROPS do
		table.insert(volumes, {
			shape = "block",
			position = block.position,
			size = block.size,
			material = block.material,
		})
	end
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
	local volumes = Landscape.hillBlocks()
	for _, volume in volumes do
		fill(terrain, volume, Enum.Material.Air)
	end
	for _, colour in COLOURS do
		terrain:SetMaterialColor(colour.material, Color3.fromHex(colour.hex))
	end
	for _, volume in volumes do
		fill(terrain, volume, volume.material)
	end
end

return Landscape
