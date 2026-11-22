--!strict
-- ModelMapMountainsR10: pure data for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE item 198 lane 1). Five wedge/ball massifs on a 500..700-stud ring plus one faint
-- smoke puff above the tallest. No engine calls, no asset IDs: a server applier consumes these
-- descriptors.

local Data = {}

type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	size: { number },
	position: { number },
	color: RGB,
	shape: string,
	transparency: number?,
}

Data.id = "mountains_r10"
Data.folderName = "LookDevMountainsR10_mountains_r10"

Data.PERF_TARGET = 500
Data.PERF_RADIUS = 100

local MOUNTAINS: { PartDescriptor } = {
	{
		name = "MountainWestRidge",
		size = { 110, 96, 90 },
		position = { 520, 12, 0 },
		color = { r = 104, g = 112, b = 98 },
		shape = "Wedge",
	},
	{
		name = "MountainNorthPeak",
		size = { 90, 120, 80 },
		position = { 360, 24, 380 },
		color = { r = 118, g = 116, b = 104 },
		shape = "Wedge",
	},
	{
		name = "MountainEastDome",
		size = { 100, 84, 100 },
		position = { -180, 8, 560 },
		color = { r = 96, g = 108, b = 92 },
		shape = "Ball",
	},
	{
		name = "MountainSouthSpur",
		size = { 80, 108, 70 },
		position = { -540, 30, -160 },
		color = { r = 124, g = 118, b = 106 },
		shape = "Wedge",
	},
	{
		name = "MountainLowShoulder",
		size = { 120, 72, 95 },
		position = { 120, -4, -620 },
		color = { r = 108, g = 104, b = 96 },
		shape = "Ball",
	},
}

local SMOKE: { PartDescriptor } = {
	{
		name = "MountainNorthPeakSmoke",
		size = { 34, 22, 34 },
		position = { 360, 108, 380 },
		color = { r = 214, g = 220, b = 218 },
		shape = "Ball",
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
	assert(#Data.MOUNTAINS >= 3, "mountains_r10: mountain count is below 3")
	for _, descriptor in ipairs(Data.MOUNTAINS) do
		local x, z = descriptor.position[1], descriptor.position[3]
		assert(
			math.sqrt(x * x + z * z) >= 450,
			"mountains_r10: " .. descriptor.name .. " is closer than 450 studs to origin"
		)
	end
	for _, list in ipairs({ Data.MOUNTAINS, Data.SMOKE }) do
		for _, descriptor in ipairs(list) do
			for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
				assert(channel >= 0 and channel <= 255, "mountains_r10: colour channel outside 0..255")
			end
		end
	end
end

return Data
