--!strict
-- ModelMapBambooBridgeR10: pure data for the OFF-BY-DEFAULT "bamboo_bridge_r10" restyle
-- (WORK_QUEUE item 204/245/252; item 258 rebuilds it as the concrete village bridge).
-- Fourteen dark concrete deck slabs span the 6-stud lane, with yellow square posts every 4 studs,
-- two black pipe rails per side, white stone end pillars, stone abutments and a black-white
-- striped curb (docs/v2/visual/refs/bridge_ref.jpg). Posts, rails and pillars stay outside the walk lane.
-- The baked Creator Store model is staged by the SERVER applier from its own asset id; this
-- module only supplies its placement, scale and deck colour (no engine calls, no asset IDs).
-- The default timber bridge is hidden only by the SERVER applier while staged; this pure module
-- never touches instances. Geometry stays here, not duplicated in the applier.

local Data = {}

type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	kind: string,
	shape: string,
	size: { number },
	position: { number },
	color: RGB,
	material: string,
}

Data.id = "bamboo_bridge_r10"
Data.folderName = "LookDevBambooBridgeR10_bamboo_bridge_r10"

local BRIDGE_START = { x = 0, y = 1.5, z = 276 }
local BRIDGE_END = { x = 0, y = 1.5, z = 332 }
Data.BRIDGE_START = BRIDGE_START
Data.BRIDGE_END = BRIDGE_END
Data.BRIDGE_WIDTH = 6
Data.PLANK_COUNT = 14
Data.PLANK_THICKNESS = 0.6
Data.PLANK_GAP = 0.12
Data.RAIL_X = 3.2
Data.LANE_HALF = 2.0 -- only the deck may sit inside |x| < LANE_HALF
Data.RAIL_HEIGHTS = { 1.2, 2.6 } -- studs above the deck top
Data.RAIL_Y = BRIDGE_START.y + 2.6 -- upper rail, kept for older checks
Data.RAIL_DIAMETER = 0.36
Data.POST_SIZE = { 0.5, 3, 0.5 }
Data.POST_SPACING = 4
Data.POST_INSET = 4
Data.CURB_SEGMENTS = 56 -- one stripe per stud along each edge
Data.CURB_HEIGHT = 0.3
Data.STONE_CHIPS_PER_PILLAR = 4
Data.PILLAR_SIZE = { 1.6, 5, 1.6 }
Data.ABUTMENT_SIZE = { 7.2, 3, 3.5 }

local DECK_COLOR: RGB = { r = 58, g = 62, b = 66 }
local POST_COLOR: RGB = { r = 230, g = 190, b = 30 }
local RAIL_COLOR: RGB = { r = 18, g = 20, b = 22 }
local PILLAR_COLOR: RGB = { r = 242, g = 240, b = 236 }
local ABUTMENT_COLOR: RGB = { r = 150, g = 148, b = 140 }
local CURB_DARK_COLOR: RGB = { r = 24, g = 24, b = 24 }
local CURB_LIGHT_COLOR: RGB = { r = 236, g = 236, b = 232 }
local STONE_COLORS: { RGB } = {
	{ r = 196, g = 202, b = 196 },
	{ r = 158, g = 166, b = 160 },
	{ r = 214, g = 218, b = 212 },
	{ r = 176, g = 182, b = 176 },
}
Data.DECK_COLOR = DECK_COLOR
Data.POST_COLOR = POST_COLOR
Data.RAIL_COLOR = RAIL_COLOR
Data.PILLAR_COLOR = PILLAR_COLOR
Data.ABUTMENT_COLOR = ABUTMENT_COLOR
Data.CURB_DARK_COLOR = CURB_DARK_COLOR
Data.CURB_LIGHT_COLOR = CURB_LIGHT_COLOR
Data.STONE_COLORS = STONE_COLORS

-- Older Studio checks still read these keys; item 258 no longer uses them for parts.
local BAMBOO_COLOR: RGB = { r = 186, g = 168, b = 96 }
local BAMBOO_NODE_COLOR: RGB = { r = 160, g = 144, b = 82 }
local WOOD_COLOR: RGB = { r = 150, g = 112, b = 64 }
Data.BAMBOO_COLOR = BAMBOO_COLOR
Data.BAMBOO_NODE_COLOR = BAMBOO_NODE_COLOR
Data.WOOD_COLOR = WOOD_COLOR

-- Baked-pick placement. The asset id lives only in the SERVER applier; the model is scaled to
-- six studs wide and set near the north bank so the procedural deck carries the whole span.
Data.model = {
	name = "ConcreteBridgeSlab",
	role = "model",
	position = { 0, 1.2, BRIDGE_START.z + 6 },
	targetWidth = Data.BRIDGE_WIDTH,
	color = DECK_COLOR,
}

local function copy(color: RGB): RGB
	return { r = color.r, g = color.g, b = color.b }
end

local function name2(index: number): string
	return string.format("%02d", index)
end

local function sameColor(a: RGB, b: RGB): boolean
	return a.r == b.r and a.g == b.g and a.b == b.b
end

function Data.parts(): { PartDescriptor }
	local out: { PartDescriptor } = {}
	local startZ, endZ = Data.BRIDGE_START.z, Data.BRIDGE_END.z
	local length = endZ - startZ
	local centerZ = (startZ + endZ) / 2
	local step = length / Data.PLANK_COUNT
	local deckTop = Data.BRIDGE_START.y
	local deckY = deckTop - Data.PLANK_THICKNESS / 2
	local curbX = Data.BRIDGE_WIDTH / 2 - 0.2

	-- Dark concrete deck slabs: the old 14-plank cadence, now a continuous slab lane.
	for index = 1, Data.PLANK_COUNT do
		out[#out + 1] = {
			name = "ConcreteDeck" .. name2(index),
			kind = "deck",
			shape = "Block",
			size = { Data.BRIDGE_WIDTH, Data.PLANK_THICKNESS, step - Data.PLANK_GAP },
			position = { 0, deckY, startZ + (index - 0.5) * step },
			color = copy(DECK_COLOR),
			material = "Concrete",
		}
	end

	local sides = {
		{ role = "left", sign = -1, label = "Left" },
		{ role = "right", sign = 1, label = "Right" },
	}

	-- Two black pipe rails per side, post to post, 1.2 and 2.6 studs above the deck. The applier
	-- rotates local Y onto world Z for the rail_* roles.
	for _, side in ipairs(sides) do
		for level, height in ipairs(Data.RAIL_HEIGHTS) do
			out[#out + 1] = {
				name = "PipeRail" .. side.label .. level,
				kind = "rail_" .. side.role,
				shape = "Cylinder",
				size = { Data.RAIL_DIAMETER, length, Data.RAIL_DIAMETER },
				position = { side.sign * Data.RAIL_X, deckTop + height, centerZ },
				color = copy(RAIL_COLOR),
				material = "Metal",
			}
		end
	end

	-- Yellow square posts every POST_SPACING studs along both edges, between the end pillars.
	local postIndex = 0
	local z = startZ + Data.POST_INSET
	while z <= endZ - Data.POST_INSET + 1e-6 do
		for _, side in ipairs(sides) do
			postIndex += 1
			out[#out + 1] = {
				name = "YellowPost" .. side.label .. name2(postIndex),
				kind = "post",
				shape = "Block",
				size = { Data.POST_SIZE[1], Data.POST_SIZE[2], Data.POST_SIZE[3] },
				position = { side.sign * Data.RAIL_X, deckTop + Data.POST_SIZE[2] / 2, z },
				color = copy(POST_COLOR),
				material = "Metal",
			}
		end
		z += Data.POST_SPACING
	end

	-- White stone end pillars (Cobblestone) with a mottled Slate chip panel on the outward face as
	-- the river-stone pattern, plus a stone abutment under each bank end of the deck.
	local pillarEnds = {
		{ label = "Start", z = startZ, outward = -1 },
		{ label = "End", z = endZ, outward = 1 },
	}
	local chipIndex = 0
	for _, endPoint in ipairs(pillarEnds) do
		out[#out + 1] = {
			name = "StoneAbutment" .. endPoint.label,
			kind = "abutment",
			shape = "Block",
			size = { Data.ABUTMENT_SIZE[1], Data.ABUTMENT_SIZE[2], Data.ABUTMENT_SIZE[3] },
			position = {
				0,
				deckTop - 0.3 - Data.ABUTMENT_SIZE[2] / 2,
				endPoint.z + endPoint.outward * (Data.ABUTMENT_SIZE[3] / 2 - 0.5),
			},
			color = copy(ABUTMENT_COLOR),
			material = "Cobblestone",
		}
		for _, side in ipairs(sides) do
			local pillarX, pillarY = side.sign * Data.RAIL_X, Data.PILLAR_SIZE[2] / 2
			out[#out + 1] = {
				name = "StonePillar" .. side.label .. endPoint.label,
				kind = "pillar",
				shape = "Block",
				size = { Data.PILLAR_SIZE[1], Data.PILLAR_SIZE[2], Data.PILLAR_SIZE[3] },
				position = { pillarX, pillarY, endPoint.z },
				color = copy(PILLAR_COLOR),
				material = "Cobblestone",
			}
			for chip = 1, Data.STONE_CHIPS_PER_PILLAR do
				chipIndex += 1
				out[#out + 1] = {
					name = "StoneChip" .. name2(chipIndex),
					kind = "pillar_stone",
					shape = "Block",
					size = { 0.5, 0.35, 0.08 },
					position = {
						pillarX + (chip % 2 == 0 and 0.35 or -0.35),
						deckTop + 1.4 + (chip <= 2 and -0.6 or 0.6),
						endPoint.z + endPoint.outward * (Data.PILLAR_SIZE[3] / 2 + 0.04),
					},
					color = copy(STONE_COLORS[(chipIndex - 1) % #STONE_COLORS + 1]),
					material = "Slate",
				}
			end
		end
	end

	-- Black-white striped curb on both deck edges, alternating every stud.
	local curbStep = length / Data.CURB_SEGMENTS
	for _, side in ipairs(sides) do
		for index = 1, Data.CURB_SEGMENTS do
			out[#out + 1] = {
				name = "Curb" .. side.label .. name2(index),
				kind = "curb",
				shape = "Block",
				size = { 0.4, Data.CURB_HEIGHT, curbStep },
				position = {
					side.sign * curbX,
					deckTop + Data.CURB_HEIGHT / 2,
					startZ + (index - 0.5) * curbStep,
				},
				color = copy(
					if (index + (side.sign < 0 and 0 or 1)) % 2 == 0 then CURB_DARK_COLOR else CURB_LIGHT_COLOR
				),
				material = "Concrete",
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
	assert(Data.BRIDGE_END.z > Data.BRIDGE_START.z, "bamboo_bridge_r10: bridge has no forward span")
	assert(POST_COLOR.r > POST_COLOR.g and POST_COLOR.g > POST_COLOR.b, "bamboo_bridge_r10: posts are not yellow")
	assert(RAIL_COLOR.r < 60 and RAIL_COLOR.g < 60 and RAIL_COLOR.b < 60, "bamboo_bridge_r10: rails are not black")
	assert(
		PILLAR_COLOR.r > 200 and PILLAR_COLOR.g > 200 and PILLAR_COLOR.b > 200,
		"bamboo_bridge_r10: pillars are not white"
	)

	local rails = { left = 0, right = 0 }
	local deck, posts, pillars, stones, curbs, abutments = 0, 0, 0, 0, 0, 0
	local curbColors = { dark = 0, light = 0 }
	local parts = Data.parts()
	for _, part in ipairs(parts) do
		if part.kind == "rail_left" or part.kind == "rail_right" then
			assert(part.shape == "Cylinder", "bamboo_bridge_r10: rail is not a pipe")
			assert(
				part.size[1] == Data.RAIL_DIAMETER and part.size[3] == Data.RAIL_DIAMETER,
				"bamboo_bridge_r10: rail pipe is not round"
			)
			assert(sameColor(part.color, RAIL_COLOR), "bamboo_bridge_r10: rail is not black")
			rails[part.kind == "rail_left" and "left" or "right"] += 1
		elseif part.kind == "deck" then
			assert(part.shape == "Block", "bamboo_bridge_r10: deck is not a slab")
			assert(part.size[1] == Data.BRIDGE_WIDTH, "bamboo_bridge_r10: deck does not span the lane")
			assert(sameColor(part.color, DECK_COLOR), "bamboo_bridge_r10: deck is not dark concrete")
			deck += 1
		elseif part.kind == "post" then
			assert(part.shape == "Block", "bamboo_bridge_r10: post is not square")
			assert(part.size[1] == part.size[3], "bamboo_bridge_r10: post cross-section is not square")
			assert(sameColor(part.color, POST_COLOR), "bamboo_bridge_r10: post is not yellow")
			posts += 1
		elseif part.kind == "pillar" then
			assert(sameColor(part.color, PILLAR_COLOR), "bamboo_bridge_r10: pillar is not white")
			pillars += 1
		elseif part.kind == "pillar_stone" then
			stones += 1
		elseif part.kind == "abutment" then
			abutments += 1
		elseif part.kind == "curb" then
			if sameColor(part.color, CURB_DARK_COLOR) then
				curbColors.dark += 1
			elseif sameColor(part.color, CURB_LIGHT_COLOR) then
				curbColors.light += 1
			else
				error("bamboo_bridge_r10: curb is not black or white")
			end
			curbs += 1
		end
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "bamboo_bridge_r10: colour channel outside 0..255")
		end
	end
	assert(rails.left == 2 and rails.right == 2, "bamboo_bridge_r10: rails are not two per side")
	assert(deck == Data.PLANK_COUNT, "bamboo_bridge_r10: deck slab count changed")
	assert(posts >= 8 and posts % 2 == 0, "bamboo_bridge_r10: fewer than four yellow posts per side")
	assert(pillars == 4, "bamboo_bridge_r10: fewer than four end pillars")
	assert(abutments == 2, "bamboo_bridge_r10: stone abutments missing")
	assert(stones == pillars * Data.STONE_CHIPS_PER_PILLAR, "bamboo_bridge_r10: stone pattern incomplete")
	assert(curbs == 2 * Data.CURB_SEGMENTS, "bamboo_bridge_r10: curb segments changed")
	assert(curbColors.dark > 0 and curbColors.light > 0, "bamboo_bridge_r10: curb is not striped")
	assert(
		type(Data.model.position) == "table" and Data.model.targetWidth == Data.BRIDGE_WIDTH,
		"bamboo_bridge_r10: baked model placement missing"
	)
end

return Data
