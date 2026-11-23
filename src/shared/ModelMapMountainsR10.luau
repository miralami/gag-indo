--!strict
-- ModelMapMountainsR10: pure data for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE items 243 + 251 + 260). Twelve opaque Wedge ridges in three north-south distance
-- bands: near |z|=300, mid |z|=450, far |z|=600 studs from the world origin. Each band is tinted
-- progressively lighter and bluer with distance; one faint translucent Cylinder puff sits over the
-- far crest. No engine calls, no asset IDs: a server applier consumes these descriptors. No Block,
-- no Ball and no SmoothPlastic anywhere in the set.
--
-- Item 260: the bands are read from the `spawn` and `canonical_overview` review cameras as a layered
-- skyline, never at the lens. Every Mountain-tagged part stays >=250 studs from the spawn eye.
-- The old item-251 MOUNTAIN_FAR >=450 origin floor is superseded by the 300-stud near band;
-- check_q251 is left untouched and item 260 is measured by check_q260.

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

-- The only distance contract item 260 measures: spawn eye (ReviewCameras "spawn") >=250 studs.
Data.MIN_DISTANCE = 250
-- Band centres are north-distance from the origin, i.e. |z|; the applier keeps identity rotation.
Data.RIDGE_BANDS = { 300, 450, 600 }
Data.BAND_TOLERANCE = 60
-- Fraction of the spawn camera's upper-third horizon band covered by opaque ridges.
Data.SKYLINE_MIN = 0.15
Data.SKYLINE_MAX = 0.40

local NEAR = { r = 62, g = 108, b = 124 }
local MID = { r = 92, g = 140, b = 158 }
local FAR = { r = 126, g = 174, b = 196 }

local MOUNTAINS: { PartDescriptor } = {
	-- Near band (|z|=300): darkest teal shoulders, tall enough to clear the village roofline.
	{
		name = "MountainNearCrest",
		size = { 360, 96, 50 },
		position = { 0, 48, -300 },
		color = NEAR,
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainNearWestRidge",
		size = { 240, 80, 50 },
		position = { -200, 40, -300 },
		color = NEAR,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainNearEastRidge",
		size = { 240, 80, 50 },
		position = { 200, 40, -300 },
		color = NEAR,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainNearFoot",
		size = { 440, 32, 40 },
		position = { 0, 16, -290 },
		color = NEAR,
		shape = "Wedge",
		material = "Rock",
	},
	-- Mid band (|z|=450): lighter, bluer crest and flanks behind the near shoulders.
	{
		name = "MountainMidCrest",
		size = { 440, 136, 60 },
		position = { 0, 68, -450 },
		color = MID,
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainMidWestRidge",
		size = { 280, 116, 60 },
		position = { -280, 58, -450 },
		color = MID,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainMidEastRidge",
		size = { 280, 116, 60 },
		position = { 280, 58, -450 },
		color = MID,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainMidFoot",
		size = { 520, 44, 50 },
		position = { 0, 22, -445 },
		color = MID,
		shape = "Wedge",
		material = "Rock",
	},
	-- Far band (|z|=600): palest, bluest skyline, furthest from the spawn eye.
	{
		name = "MountainFarCrest",
		size = { 520, 176, 70 },
		position = { 0, 88, -600 },
		color = FAR,
		shape = "Wedge",
		material = "Rock",
	},
	{
		name = "MountainFarWestRidge",
		size = { 320, 150, 70 },
		position = { -360, 75, -600 },
		color = FAR,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainFarEastRidge",
		size = { 320, 150, 70 },
		position = { 360, 75, -600 },
		color = FAR,
		shape = "Wedge",
		material = "Slate",
	},
	{
		name = "MountainFarFoot",
		size = { 600, 56, 60 },
		position = { 0, 28, -590 },
		color = FAR,
		shape = "Wedge",
		material = "Rock",
	},
}

local SMOKE: { PartDescriptor } = {
	{
		name = "MountainFarCrestSmoke",
		size = { 30, 22, 30 },
		position = { 0, 190, -600 },
		color = { r = 196, g = 218, b = 232 },
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
	local bandsSeen: { [number]: boolean } = {}
	for _, descriptor in ipairs(Data.MOUNTAINS) do
		local z = math.abs(descriptor.position[3])
		local matched = false
		for _, band in ipairs(Data.RIDGE_BANDS) do
			if math.abs(z - band) <= Data.BAND_TOLERANCE then
				matched = true
				bandsSeen[band] = true
				break
			end
		end
		assert(matched, "mountains_r10: " .. descriptor.name .. " is outside the three ridge bands")
		assert(
			descriptor.shape == "Wedge" or descriptor.shape == "Cylinder",
			"mountains_r10: " .. descriptor.name .. " must use a Wedge or Cylinder silhouette"
		)
		assert(
			descriptor.color.b >= descriptor.color.r + 12 and descriptor.color.g >= descriptor.color.r + 12,
			"mountains_r10: " .. descriptor.name .. " is not blue-green"
		)
	end
	local bandsFound = 0
	for _ in pairs(bandsSeen) do
		bandsFound += 1
	end
	assert(bandsFound == #Data.RIDGE_BANDS, "mountains_r10: all three ridge bands must be present")
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
