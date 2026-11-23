--!strict
-- ModelMapBambooBridgeR10: pure data for the OFF-BY-DEFAULT "bamboo_bridge_r10" restyle
-- (WORK_QUEUE item 204, SPRINT 1; item 245, SPRINT 2 made the deck real bamboo culms).
-- Fourteen Cylinder culms span the central 6-stud bridge lane, each with darker Cylinder node
-- rings; the two round rails get node rings too. Rope ties and four end posts stay as before.
-- No engine calls, no asset IDs, no verdict.
-- The lane is mirrored from ModelMapRiverR8.BRIDGE_Z0/Z1 and MapSpec.BRIDGE (x 0, top 1.5):
-- this module stays pure, so it does not require MapSpec, which reads Roblox services at load.
-- The default timber bridge is hidden only by the SERVER applier while staged; this pure module
-- never touches instances. Geometry stays here, not duplicated in the applier.

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
Data.PLANK_THICKNESS = 0.5 -- culm diameter (the old plank thickness)
Data.PLANK_GAP = 0.12
Data.DECK_NODES_PER_CULM = 2
Data.RAIL_NODE_STEP = 8
Data.NODE_THICKNESS = 0.12
Data.NODE_RADIUS_PAD = 0.06
Data.RAIL_X = 3.2 -- inner rail face at |x| = 3, exactly the edge of the 6-stud lane
Data.RAIL_Y = 2.0
Data.RAIL_DIAMETER = 0.4
Data.ROPE_COUNT = 7
Data.POSTS_PER_END = 2

local BAMBOO_COLOR: RGB = { r = 186, g = 168, b = 96 }
local BAMBOO_NODE_COLOR: RGB = { r = 160, g = 144, b = 82 }
local WOOD_COLOR: RGB = { r = 150, g = 112, b = 64 }
Data.BAMBOO_COLOR = BAMBOO_COLOR
Data.BAMBOO_NODE_COLOR = BAMBOO_NODE_COLOR
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
	local deckY = Data.BRIDGE_START.y - Data.PLANK_THICKNESS / 2
	local nodeDiameter = Data.PLANK_THICKNESS + Data.NODE_RADIUS_PAD * 2
	local railNodeDiameter = Data.RAIL_DIAMETER + Data.NODE_RADIUS_PAD * 2

	-- Deck: one round bamboo culm per step, laid across the whole 6-stud lane. The applier
	-- rotates local Y onto world X; node rings sit at deterministic offsets along that axis.
	for index = 1, Data.PLANK_COUNT do
		local z = Data.BRIDGE_START.z + (index - 0.5) * step
		out[#out + 1] = {
			name = "BambooCulm" .. name2(index),
			kind = "deck",
			shape = "Cylinder",
			size = { Data.PLANK_THICKNESS, Data.BRIDGE_WIDTH, Data.PLANK_THICKNESS },
			position = { Data.BRIDGE_START.x, deckY, z },
			color = copy(BAMBOO_COLOR),
		}
		for nodeIndex = 1, Data.DECK_NODES_PER_CULM do
			local t = (nodeIndex / (Data.DECK_NODES_PER_CULM + 1)) * 2 - 1
			out[#out + 1] = {
				name = "BambooCulm" .. name2(index) .. "Node" .. name2(nodeIndex),
				kind = "node_deck",
				shape = "Cylinder",
				size = { nodeDiameter, Data.NODE_THICKNESS, nodeDiameter },
				position = { t * Data.BRIDGE_WIDTH / 2, deckY, z },
				color = copy(BAMBOO_NODE_COLOR),
			}
		end
	end

	-- Two round rails, one per side, plus thin node rings every RAIL_NODE_STEP studs.
	local railSides = {
		{ role = "left", sign = -1, label = "Left" },
		{ role = "right", sign = 1, label = "Right" },
	}
	for _, side in ipairs(railSides) do
		out[#out + 1] = {
			name = "BambooRail" .. side.label,
			kind = "rail_" .. side.role,
			shape = "Cylinder",
			size = { Data.RAIL_DIAMETER, length, Data.RAIL_DIAMETER },
			position = { side.sign * Data.RAIL_X, Data.RAIL_Y, centerZ },
			color = copy(BAMBOO_COLOR),
		}
		for nodeIndex = 1, math.floor(length / Data.RAIL_NODE_STEP) do
			out[#out + 1] = {
				name = "BambooRail" .. side.label .. "Node" .. name2(nodeIndex),
				kind = "node_rail",
				shape = "Cylinder",
				size = { railNodeDiameter, Data.NODE_THICKNESS, railNodeDiameter },
				position = {
					side.sign * Data.RAIL_X,
					Data.RAIL_Y,
					Data.BRIDGE_START.z + (nodeIndex - 0.5) * Data.RAIL_NODE_STEP,
				},
				color = copy(BAMBOO_NODE_COLOR),
			}
		end
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
			color = copy(WOOD_COLOR),
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
				color = copy(WOOD_COLOR),
			}
		end
	end

	return out
end

-- Load-time contract check. Keeps the additive overlay honest for every applier and harness.
do
	assert(Data.BRIDGE_WIDTH == 6, "bamboo_bridge_r10: bridge width is not 6")
	assert(Data.PLANK_COUNT == 14, "bamboo_bridge_r10: plank count changed")
	assert(Data.PLANK_COUNT >= 10, "bamboo_bridge_r10: plank count is below 10")
	assert(Data.ROPE_COUNT == 7, "bamboo_bridge_r10: rope count changed")
	assert(Data.POSTS_PER_END == 2, "bamboo_bridge_r10: posts-per-end changed")
	assert(Data.BRIDGE_END.z > Data.BRIDGE_START.z, "bamboo_bridge_r10: bridge has no forward span")
	-- Straw/yellow-green spread: red > green > blue. The fixed palette is a straw tone, not
	-- green-dominant; the green channel still clearly exceeds blue on both bamboo colours.
	assert(
		BAMBOO_COLOR.r > BAMBOO_COLOR.g and BAMBOO_COLOR.g > BAMBOO_COLOR.b,
		"bamboo_bridge_r10: bamboo palette is not yellow-green/straw"
	)
	assert(
		BAMBOO_NODE_COLOR.r > BAMBOO_NODE_COLOR.g and BAMBOO_NODE_COLOR.g > BAMBOO_NODE_COLOR.b,
		"bamboo_bridge_r10: node palette is not a darker straw"
	)

	local rails = { left = 0, right = 0 }
	local deck, deckNodes, railNodes, ropes, posts = 0, 0, 0, 0, 0
	local parts = Data.parts()
	for _, part in ipairs(parts) do
		if part.kind == "rail_left" or part.kind == "rail_right" then
			assert(part.shape == "Cylinder", "bamboo_bridge_r10: rail is not a bamboo culm")
			assert(
				part.size[1] == Data.RAIL_DIAMETER and part.size[3] == Data.RAIL_DIAMETER,
				"bamboo_bridge_r10: rail culm is not round"
			)
			if part.kind == "rail_left" then
				rails.left += 1
			else
				rails.right += 1
			end
		elseif part.kind == "deck" then
			assert(part.shape == "Cylinder", "bamboo_bridge_r10: deck is not a bamboo culm")
			assert(part.size[2] == Data.BRIDGE_WIDTH, "bamboo_bridge_r10: deck does not span the 6-stud lane")
			assert(part.size[1] > 0 and part.size[1] <= 1, "bamboo_bridge_r10: deck culm is too thick")
			assert(part.size[3] == part.size[1], "bamboo_bridge_r10: deck culm is not round")
			deck += 1
		elseif part.kind == "node_deck" or part.kind == "node_rail" then
			assert(part.shape == "Cylinder", "bamboo_bridge_r10: node ring is not a Cylinder")
			assert(part.size[2] <= 0.25, "bamboo_bridge_r10: node ring is too thick for the walk lane")
			if part.kind == "node_deck" then
				deckNodes += 1
			else
				railNodes += 1
			end
		elseif part.kind == "rope" then
			ropes += 1
		elseif part.kind == "post" then
			posts += 1
		end
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "bamboo_bridge_r10: colour channel outside 0..255")
		end
	end
	assert(
		rails.left == 1 and rails.right == 1 and rails.left + rails.right == 2,
		"bamboo_bridge_r10: rails are not exactly two (left+right)"
	)
	assert(deck == Data.PLANK_COUNT, "bamboo_bridge_r10: deck culm count changed")
	assert(deckNodes == Data.PLANK_COUNT * Data.DECK_NODES_PER_CULM, "bamboo_bridge_r10: deck node count changed")
	assert(
		railNodes == 2 * math.floor((Data.BRIDGE_END.z - Data.BRIDGE_START.z) / Data.RAIL_NODE_STEP),
		"bamboo_bridge_r10: rail node count changed"
	)
	assert(ropes == Data.ROPE_COUNT, "bamboo_bridge_r10: rope count changed")
	assert(posts == Data.POSTS_PER_END * 2, "bamboo_bridge_r10: fewer than four posts")
end

return Data
