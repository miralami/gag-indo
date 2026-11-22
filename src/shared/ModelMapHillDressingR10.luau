--!strict
-- ModelMapHillDressingR10: pure data for the OFF-BY-DEFAULT "hill_dressing_r10" candidate
-- (WORK_QUEUE item 199). Rock outcrops, terrace steps and palms on the four hill domes.
-- No engine calls and no asset IDs: a server applier consumes these descriptors.

local Data = {}

type RGB = { r: number, g: number, b: number }
type Hill = { x: number, z: number, radius: number }
type Descriptor = {
	name: string,
	kind: string,
	hill: number,
	position: { number },
	size: { number },
	color: RGB,
	shape: string,
	crownOffset: { number }?,
	crownSize: { number }?,
	crownColor: RGB?,
}

Data.id = "hill_dressing_r10"
Data.folderName = "LookDevHillDressingR10_hill_dressing_r10"

-- Four hill centres, matched to the hill-ring horizon. All clear of the village core
-- (|x|,|z| <= 208), so the plot gates and plaza stay untouched.
local HILLS: { Hill } = {
	{ x = 462, z = 0, radius = 56 },
	{ x = 446, z = 178, radius = 46 },
	{ x = -462, z = 0, radius = 58 },
	{ x = 0, z = -462, radius = 58 },
}
Data.HILLS = HILLS
Data.HILL_COUNT = #Data.HILLS
Data.ROCKS_PER_HILL = 5
Data.TREES_PER_HILL = 13
Data.TERRACES = 3 -- a few steps near hill 1

local ROCK_COLORS: { RGB } = {
	{ r = 118, g = 112, b = 102 },
	{ r = 132, g = 126, b = 114 },
	{ r = 104, g = 103, b = 96 },
}
local TRUNK_COLOR: RGB = { r = 112, g = 88, b = 58 }
local CROWN_COLORS: { RGB } = {
	{ r = 64, g = 116, b = 62 },
	{ r = 82, g = 132, b = 70 },
	{ r = 56, g = 104, b = 58 },
}
local TERRACE_COLOR: RGB = { r = 146, g = 138, b = 116 }

local function copyColor(color: RGB): RGB
	return { r = color.r, g = color.g, b = color.b }
end

-- Slope height above the ground plane; larger near the summit, lower at the rim.
local function slopeY(hill: Hill, distance: number): number
	return 3 + (1 - distance / hill.radius) * 9
end

function Data.parts(): { Descriptor }
	local parts: { Descriptor } = {}
	for hillIndex, hill in ipairs(Data.HILLS) do
		for rock = 1, Data.ROCKS_PER_HILL do
			local angle = rock * (2 * math.pi / Data.ROCKS_PER_HILL) + hillIndex * 0.31
			local distance = hill.radius * (0.24 + 0.12 * (rock % 3))
			local y = slopeY(hill, distance) + rock % 2
			local size = 4 + (rock % 3) * 2
			parts[#parts + 1] = {
				name = `Hill{hillIndex}_Rock{rock}`,
				kind = "rock",
				hill = hillIndex,
				position = {
					hill.x + math.cos(angle) * distance,
					y,
					hill.z + math.sin(angle) * distance,
				},
				size = { size, 3 + rock % 4, size - 1 },
				color = copyColor(ROCK_COLORS[1 + rock % #ROCK_COLORS]),
				shape = if rock % 2 == 0 then "Wedge" else "Ball",
			}
		end

		for tree = 1, Data.TREES_PER_HILL do
			local angle = tree * (2 * math.pi / Data.TREES_PER_HILL) + hillIndex * 0.37
			local distance = hill.radius * (0.42 + 0.32 * (tree % 4 / 3))
			local height = 10 + tree % 3 * 2
			local crownSize = 9 + tree % 3 * 2
			parts[#parts + 1] = {
				name = `Hill{hillIndex}_Palm{tree}`,
				kind = "palm",
				hill = hillIndex,
				position = {
					hill.x + math.cos(angle) * distance,
					slopeY(hill, distance) + height / 2,
					hill.z + math.sin(angle) * distance,
				},
				size = { 2, height, 2 },
				color = copyColor(TRUNK_COLOR),
				shape = "Block",
				crownOffset = { 0, height / 2 + 2, 0 },
				crownSize = { crownSize, 5, crownSize },
				crownColor = copyColor(CROWN_COLORS[1 + tree % #CROWN_COLORS]),
			}
		end
	end

	local hill = Data.HILLS[1]
	for step = 1, Data.TERRACES do
		local angle = step * 0.8
		local distance = hill.radius * (0.18 + step * 0.08)
		parts[#parts + 1] = {
			name = `Hill1_Terrace{step}`,
			kind = "terrace",
			hill = 1,
			position = {
				hill.x + math.cos(angle) * distance,
				slopeY(hill, distance) + 1,
				hill.z + math.sin(angle) * distance,
			},
			size = { 14, 2, 10 },
			color = copyColor(TERRACE_COLOR),
			shape = "Block",
		}
	end
	return parts
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	assert(Data.HILL_COUNT >= 3, "hill_dressing_r10: hill count below 3")
	assert(Data.ROCKS_PER_HILL >= 4, "hill_dressing_r10: rocks per hill below 4")
	assert(Data.TREES_PER_HILL >= 12, "hill_dressing_r10: trees per hill below 12")
	for hillIndex, entry in ipairs(Data.HILLS) do
		assert(entry.radius > 0, "hill_dressing_r10: non-positive hill radius")
		assert(entry.x ~= nil and entry.z ~= nil, "hill_dressing_r10: missing hill centre")
		local rocks, palms = 0, 0
		for _, part in ipairs(Data.parts()) do
			if part.hill == hillIndex then
				if part.kind == "rock" then
					rocks += 1
				elseif part.kind == "palm" then
					palms += 1
				end
			end
		end
		assert(rocks >= 4, "hill_dressing_r10: per-hill rock count below 4")
		assert(palms >= 12, "hill_dressing_r10: per-hill tree count below 12")
	end
	local parts = Data.parts()
	for _, part in ipairs(parts) do
		local colors = { part.color }
		if part.crownColor then
			colors[#colors + 1] = part.crownColor
		end
		for _, color in ipairs(colors) do
			for _, channel in ipairs({ color.r, color.g, color.b }) do
				assert(channel >= 0 and channel <= 255, "hill_dressing_r10: colour channel outside 0..255")
			end
		end
	end
end

return Data
