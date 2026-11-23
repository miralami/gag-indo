--!strict
-- ModelMapMountainsR10: pure data for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE items 243 + 251). Stacked blue-green Wedge/Cylinder rock silhouettes beyond the north
-- hill ring, pale with distance and dark at the front, plus one faint translucent Cylinder puff above
-- the far crest. No engine calls, no asset IDs: a server applier consumes these descriptors. Every
-- Mountain-tagged part sits at least 250 studs from horizon_north and every spawn (item 251).
-- No SmoothPlastic and no Block shape anywhere in the set.
--
-- Item 251: only three crests sit inside the horizon_north frustum; the remaining shelves and
-- shoulders sit past its lateral edges but keep the far ring populated. This holds projected
-- subject coverage below the 0.6 ceiling while the three-crest read and the blue-green fade stay.

local Data = {}

type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	size: { number },
	position: { number },
	color: RGB,
	shape: string,
	material: string,
	transparency: number?,
}

Data.id = "mountains_r10"
Data.folderName = "LookDevMountainsR10_mountains_r10"

Data.PERF_TARGET = 500
Data.PERF_RADIUS = 100

-- Three depth layers: pale back crests at z<=-885, mid shelves outside the camera edges at z=-820,
-- dark front shoulders outside the camera edges at z=-740, and three small feet below the crests.
-- All centres sit north of z=-700 so the nearest bounding-box face stays >=250 studs from the eye.
local MOUNTAINS: { PartDescriptor } = {
	-- Back layer: the three readable blue-green crests, fading into the sky.
	{
		name = "MountainFarNorthCrest",
		size = { 230, 160, 76 },
		position = { 0, 70, -890 },
		color = { r = 132, g = 164, b = 156 },
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainFarWestBack",
		size = { 192, 140, 72 },
		position = { -230, 72, -890 },
		color = { r = 124, g = 156, b = 152 },
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainFarEastBack",
		size = { 192, 140, 72 },
		position = { 230, 72, -885 },
		color = { r = 126, g = 158, b = 154 },
		shape = "Wedge",
		material = "Slate",
	},
	-- Small stacked feet below each crest, still >=250 studs past the eye.
	{
		name = "MountainFarNorthFoot",
		size = { 70, 35, 30 },
		position = { 0, 45, -730 },
		color = { r = 92, g = 126, b = 132 },
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainFarWestFoot",
		size = { 60, 30, 30 },
		position = { -230, 45, -730 },
		color = { r = 90, g = 124, b = 130 },
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainFarEastFoot",
		size = { 60, 30, 30 },
		position = { 230, 45, -730 },
		color = { r = 90, g = 124, b = 130 },
		shape = "Wedge",
		material = "Slate",
	},
	-- Mid layer: lateral shelves, past the left and right edges of horizon_north.
	{
		name = "MountainMidWestShelf",
		size = { 160, 120, 80 },
		position = { -620, 60, -820 },
		color = { r = 108, g = 146, b = 148 },
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainMidEastSpur",
		size = { 160, 120, 80 },
		position = { 620, 60, -820 },
		color = { r = 108, g = 146, b = 148 },
		shape = "Cylinder",
		material = "Rock",
	},
	{
		name = "MountainMidFarEastShelf",
		size = { 160, 120, 80 },
		position = { 800, 60, -820 },
		color = { r = 106, g = 144, b = 146 },
		shape = "Wedge",
		material = "Slate",
	},
	-- Front layer: darker shoulders, also outside the camera frustum.
	{
		name = "MountainFrontWestShoulder",
		size = { 180, 130, 80 },
		position = { -900, 50, -740 },
		color = { r = 78, g = 112, b = 120 },
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainFrontEastShoulder",
		size = { 180, 130, 80 },
		position = { 900, 50, -740 },
		color = { r = 80, g = 114, b = 122 },
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainFrontFarEastToe",
		size = { 180, 130, 80 },
		position = { 1100, 50, -740 },
		color = { r = 82, g = 116, b = 124 },
		shape = "Cylinder",
		material = "Slate",
	},
}

local SMOKE: { PartDescriptor } = {
	{
		name = "MountainFarNorthCrestSmoke",
		size = { 30, 22, 30 },
		position = { 0, 180, -890 },
		color = { r = 196, g = 218, b = 214 },
		shape = "Cylinder",
		material = "Slate",
		transparency = 0.82,
	},
}

Data.MOUNTAINS = MOUNTAINS
Data.SMOKE = SMOKE

function Data.mountainParts(): { PartDescriptor }
	return Data.MOUNTAINS
end

function Data.smokeParts(): { PartDescriptor }
	return Data.SMOKE
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	local function spread(color: RGB): number
		return math.max(color.r, color.g, color.b) - math.min(color.r, color.g, color.b)
	end

	assert(#Data.MOUNTAINS >= 8, "mountains_r10: mountain count is below 8")
	for _, descriptor in ipairs(Data.MOUNTAINS) do
		local x, z = descriptor.position[1], descriptor.position[3]
		assert(
			math.sqrt(x * x + z * z) >= 450,
			"mountains_r10: " .. descriptor.name .. " is closer than 450 studs to origin"
		)
		assert(
			descriptor.shape == "Wedge" or descriptor.shape == "Cylinder",
			"mountains_r10: " .. descriptor.name .. " must use a Wedge or Cylinder silhouette"
		)
		assert(
			descriptor.color.b >= descriptor.color.r + 12 and descriptor.color.g >= descriptor.color.r + 12,
			"mountains_r10: " .. descriptor.name .. " is not blue-green"
		)
	end
	for _, list in ipairs({ Data.MOUNTAINS, Data.SMOKE }) do
		for _, descriptor in ipairs(list) do
			assert(
				descriptor.material == "Rock" or descriptor.material == "Slate",
				"mountains_r10: " .. descriptor.name .. " must use Rock or Slate"
			)
			assert(descriptor.shape ~= "Block", "mountains_r10: " .. descriptor.name .. " must not be a Block")
			assert(descriptor.shape ~= "Ball", "mountains_r10: " .. descriptor.name .. " must not be a Ball")
			assert(spread(descriptor.color) >= 18, "mountains_r10: " .. descriptor.name .. " lost its blue-green tint")
			for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
				assert(channel >= 0 and channel <= 255, "mountains_r10: colour channel outside 0..255")
			end
		end
	end
end

return Data
