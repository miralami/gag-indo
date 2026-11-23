--!strict
-- ModelMapMountainsR10: pure data for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE item 243 redo). Ten layered blue-green Wedge/Cylinder silhouettes behind the north
-- hill ring plus one faint translucent Cylinder puff above the far crest. No engine calls, no asset
-- IDs: a server applier consumes these descriptors.

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

-- Three depth layers, lightest at the back and darkest at the front. All sit north of z=-470 so
-- MOUNTAIN_FAR (X/Z radius >= 450) holds, and all stay inside |x| < 370 where the forest band is
-- skipped, so the silhouettes read over the hill ring from horizon_north.
local MOUNTAINS: { PartDescriptor } = {
	-- Back layer: pale blue-green crest above the hill skyline.
	{
		name = "MountainFarNorthCrest",
		size = { 220, 150, 90 },
		position = { 0, 42, -760 },
		color = { r = 132, g = 164, b = 156 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainFarWestBack",
		size = { 180, 132, 88 },
		position = { -250, 30, -730 },
		color = { r = 124, g = 156, b = 152 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainFarEastBack",
		size = { 180, 136, 88 },
		position = { 250, 32, -720 },
		color = { r = 126, g = 158, b = 154 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	-- Middle layer: the readable peaks.
	{
		name = "MountainMidNorthPeak",
		size = { 180, 168, 96 },
		position = { -90, 62, -630 },
		color = { r = 100, g = 140, b = 144 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainMidEastSpur",
		size = { 160, 142, 90 },
		position = { 170, 48, -610 },
		color = { r = 108, g = 146, b = 148 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainMidWestShelf",
		size = { 170, 130, 90 },
		position = { -270, 38, -600 },
		color = { r = 104, g = 142, b = 146 },
		shape = "Cylinder",
		material = "SmoothPlastic",
	},
	-- Front layer: darker shoulders, still above the z=-462 hill caps.
	{
		name = "MountainFrontWestShoulder",
		size = { 150, 112, 70 },
		position = { -140, 28, -520 },
		color = { r = 78, g = 112, b = 120 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainFrontCentreRidge",
		size = { 160, 124, 72 },
		position = { 40, 34, -530 },
		color = { r = 84, g = 118, b = 124 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
	{
		name = "MountainFrontEastShoulder",
		size = { 140, 104, 70 },
		position = { 220, 24, -515 },
		color = { r = 80, g = 114, b = 122 },
		shape = "Cylinder",
		material = "SmoothPlastic",
	},
	{
		name = "MountainFrontFarWestToe",
		size = { 150, 100, 68 },
		position = { -320, 22, -505 },
		color = { r = 82, g = 116, b = 122 },
		shape = "Wedge",
		material = "SmoothPlastic",
	},
}

local SMOKE: { PartDescriptor } = {
	{
		name = "MountainFarNorthCrestSmoke",
		size = { 30, 22, 30 },
		position = { 0, 130, -760 },
		color = { r = 196, g = 218, b = 214 },
		shape = "Cylinder",
		material = "SmoothPlastic",
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
				type(descriptor.material) == "string" and #descriptor.material > 0,
				"mountains_r10: " .. descriptor.name .. " has no material"
			)
			assert(descriptor.shape ~= "Ball", "mountains_r10: " .. descriptor.name .. " must not be a Ball")
			assert(
				not (descriptor.material == "SmoothPlastic" and spread(descriptor.color) < 18),
				"mountains_r10: " .. descriptor.name .. " is grey SmoothPlastic"
			)
			for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
				assert(channel >= 0 and channel <= 255, "mountains_r10: colour channel outside 0..255")
			end
		end
	end
end

return Data
