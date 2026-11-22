--!strict
-- ModelMapBambooBridgeR10: pure data for the OFF-BY-DEFAULT "bamboo_bridge_r10" restyle
-- (WORK_QUEUE item 204, SPRINT 1). Bamboo-coloured planks across the central 6-stud bridge lane,
-- two round rails, rope ties and two posts at each end. No engine calls, no asset IDs, no verdict.
-- The lane is mirrored from ModelMapRiverR8.BRIDGE_Z0/Z1 and MapSpec.BRIDGE (x 0, top 1.5):
-- this module stays pure, so it does not require MapSpec, which reads Roblox services at load.
-- The river_r8 default bridge is never modified: this is an additive decorative overlay.

local Data = {}

type Point3 = { x: number, y: number, z: number }
type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	kind: string,
	shape: string,
	size: { number },
	position: { number },
	color: RGB,
}

Data.id = "bamboo_bridge_r10"
Data.folderName = "LookDevBambooBridgeR10_bamboo_bridge_r10"

local BRIDGE_START: Point3 = { x = 0, y = 1.5, z = 276 }
local BRIDGE_END: Point3 = { x = 0, y = 1.5, z = 332 }
Data.BRIDGE_START = BRIDGE_START
Data.BRIDGE_END = BRIDGE_END
Data.BRIDGE_WIDTH = 6
Data.PLANK_COUNT = 14
Data.PLANK_THICKNESS = 0.5
Data.PLANK_GAP = 0.12
Data.RAIL_X = 3.2 -- inner rail face at |x| = 3, exactly the edge of the 6-stud lane
Data.RAIL_Y = 2.0
Data.ROPE_COUNT = 7
Data.POSTS_PER_END = 2

local BAMBOO_COLOR: RGB = { r = 186, g = 168, b = 96 }
local WOOD_COLOR: RGB = { r = 150, g = 112, b = 64 }
Data.BAMBOO_COLOR = BAMBOO_COLOR
Data.WOOD_COLOR = WOOD_COLOR

local function copy(color: RGB): RGB
	return { r = color.r, g = color.g, b = color.b }
end

local function name2(index: number): string
	return string.format("%02d", index)
end

function Data.parts(): { PartDescriptor }
	local out: { PartDescriptor } = {}
	local length = Data.BRIDGE_END.z - Data.BRIDGE_START.z
	local centerZ = (Data.BRIDGE_START.z + Data.BRIDGE_END.z) / 2
	local step = length / Data.PLANK_COUNT

	-- Deck: one bamboo plank per step, spanning the whole 6-stud lane.
	for index = 1, Data.PLANK_COUNT do
		out[#out + 1] = {
			name = "BambooPlank" .. name2(index),
			kind = "deck",
			shape = "Block",
			size = { Data.BRIDGE_WIDTH, Data.PLANK_THICKNESS, step - Data.PLANK_GAP },
			position = {
				Data.BRIDGE_START.x,
				Data.BRIDGE_START.y - Data.PLANK_THICKNESS / 2,
				Data.BRIDGE_START.z + (index - 0.5) * step,
			},
			color = copy(Data.BAMBOO_COLOR),
		}
	end

	-- Two round rails, one per side. Cylinders are rotated onto the bridge axis by the applier.
	local railSides = {
		{ role = "left", sign = -1, label = "Left" },
		{ role = "right", sign = 1, label = "Right" },
	}
	for _, side in ipairs(railSides) do
		out[#out + 1] = {
			name = "BambooRail" .. side.label,
			kind = "rail_" .. side.role,
			shape = "Cylinder",
			size = { 0.4, length, 0.4 },
			position = { side.sign * Data.RAIL_X, Data.RAIL_Y, centerZ },
			color = copy(Data.BAMBOO_COLOR),
		}
	end

	-- Rope ties cross from rail to rail, between the planks.
	for index = 1, Data.ROPE_COUNT do
		out[#out + 1] = {
			name = "BambooRope" .. name2(index),
			kind = "rope",
			shape = "Block",
			size = { Data.RAIL_X * 2 + 0.4, 0.12, 0.2 },
			position = {
				Data.BRIDGE_START.x,
				Data.RAIL_Y + 0.15,
				Data.BRIDGE_START.z + index * (length / (Data.ROPE_COUNT + 1)),
			},
			color = copy(Data.WOOD_COLOR),
		}
	end

	-- Two posts at each end, one on each rail line.
	local postEnds = {
		{ label = "Start", z = Data.BRIDGE_START.z },
		{ label = "End", z = Data.BRIDGE_END.z },
	}
	for _, endPoint in ipairs(postEnds) do
		for _, side in ipairs(railSides) do
			out[#out + 1] = {
				name = "BambooPost" .. side.label .. endPoint.label,
				kind = "post",
				shape = "Cylinder",
				size = { 0.6, 3.2, 0.6 },
				position = { side.sign * Data.RAIL_X, 1.6, endPoint.z },
				color = copy(Data.WOOD_COLOR),
			}
		end
	end

	return out
end

-- Load-time contract check. Keeps the additive overlay honest for every applier and harness.
do
	assert(Data.BRIDGE_WIDTH == 6, "bamboo_bridge_r10: bridge width is not 6")
	assert(Data.PLANK_COUNT >= 10, "bamboo_bridge_r10: plank count is below 10")
	assert(Data.BRIDGE_END.z > Data.BRIDGE_START.z, "bamboo_bridge_r10: bridge has no forward span")

	local rails = { left = 0, right = 0 }
	local posts = 0
	local parts = Data.parts()
	for _, part in ipairs(parts) do
		if part.kind == "rail_left" then
			rails.left += 1
		elseif part.kind == "rail_right" then
			rails.right += 1
		elseif part.kind == "post" then
			posts += 1
		elseif part.kind == "deck" then
			assert(part.size[1] == Data.BRIDGE_WIDTH, "bamboo_bridge_r10: deck does not span the 6-stud lane")
			assert(part.size[2] <= 1, "bamboo_bridge_r10: deck plank is too thick")
		end
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "bamboo_bridge_r10: colour channel outside 0..255")
		end
	end
	assert(
		rails.left == 1 and rails.right == 1 and rails.left + rails.right == 2,
		"bamboo_bridge_r10: rails are not exactly two (left+right)"
	)
	assert(posts >= 4, "bamboo_bridge_r10: fewer than four posts")
end

return Data
