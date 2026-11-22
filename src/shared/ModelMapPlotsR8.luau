--!strict
-- ModelMapPlotsR8: pure data for the OFF-BY-DEFAULT "plots_r8" LookDev candidate
-- (WORK_QUEUE section M item 71, redone in section O item 143). Canonical plot dressing: a
-- 3-stud bamboo fence (two rails + a post every 4 studs), a gate with a lintel and name sign,
-- a scarecrow, a mailbox with a small sign, a 2-stud outer irrigation ditch and a gubuk in
-- exactly three plots. The gate stays on the INNER (-Z) side of all ten plots.
--
-- Pure data/functions only: no game APIs, no Instances, no Enums, no asset IDs. Procedural Parts
-- are built by src/server/World/LookDevPlotsR8.luau, so no asset ID exists or is needed here.
-- Constants mirror Config.Game and PlotService: 4x4 tiles of 6 with a 1.5 gap plus a 4-stud
-- border gives the 34x34 Base; the signpost sits at local z = -(depth/2 + 3).

local ModelMapPlotsR8 = {}

ModelMapPlotsR8.id = "plots_r8"
ModelMapPlotsR8.folderName = "LookDevPlotsR8_plots_r8"
ModelMapPlotsR8.PLOT_COUNT = 10
ModelMapPlotsR8.PLOT_WIDTH = 34
ModelMapPlotsR8.PLOT_DEPTH = 34
ModelMapPlotsR8.GAP_WIDTH = 6
ModelMapPlotsR8.GATE_HEIGHT = 8
ModelMapPlotsR8.MIN_SEGMENTS = 8
ModelMapPlotsR8.OVERLAP = 0.2
ModelMapPlotsR8.FENCE_HEIGHT = 3
ModelMapPlotsR8.POST_SPACING = 4
ModelMapPlotsR8.POST_THICKNESS = 1
ModelMapPlotsR8.DITCH_WIDTH = 2

-- Item 181 palette. Plain RGB triples keep this module free of Roblox APIs/Enums; the applier and
-- the Studio check turn them into the same Color3, so a wood gate cannot drift back to flat cream.
ModelMapPlotsR8.GATE_WOOD_RGB = { 150, 96, 44 }
ModelMapPlotsR8.GATE_ROPE_RGB = { 92, 66, 38 }
ModelMapPlotsR8.GATE_SIGN_PREFIX = "P" -- numeric plot id; keeps hardcoded text out of the applier

function ModelMapPlotsR8.plotIndices(): { number }
	local out = {}
	for index = 1, ModelMapPlotsR8.PLOT_COUNT do
		out[index] = index
	end
	return out
end

-- Two collinear pieces per edge. Adjacent pieces share exactly `overlap` studs along their length.
-- Alternating cross-section thickness keeps the shared volume from having coplanar side faces.
local function edge(axis: string, fixed: number, from: number, to: number, overlap: number, first: number)
	local length = (to - from + overlap) / 2
	local out = {}
	for i = 0, 1 do
		local along = from + i * (length - overlap) + length / 2
		out[#out + 1] = {
			lx = if axis == "x" then along else fixed,
			lz = if axis == "x" then fixed else along,
			length = length,
			axis = axis,
			thickness = if (first + i) % 2 == 0 then 0.8 else 0.6,
		}
	end
	return out
end

-- Eight segments: two on the inner edge split by the centred gate gap, two per side and two on
-- the outer edge. The gap between the two inner segments is exactly `gapWidth` wide and centred
-- on local x=0. Each segment carries TWO rails (see fenceRails), so one segment is one counted
-- fence run and never one Part. Returns plain numbers only; deterministic for identical inputs.
function ModelMapPlotsR8.fenceLayout(width: number, depth: number, gapWidth: number, overlap: number)
	if width <= 0 or depth <= 0 or gapWidth <= 0 or gapWidth >= width or overlap < 0 then
		return {}
	end
	local halfW, halfD, halfGap = width / 2, depth / 2, gapWidth / 2
	local innerZ, outerZ = -halfD, halfD
	local innerLength = halfW - halfGap
	local segments = {
		{
			lx = -(halfGap + innerLength / 2),
			lz = innerZ,
			length = innerLength,
			axis = "x",
			thickness = 0.8,
		},
		{
			lx = halfGap + innerLength / 2,
			lz = innerZ,
			length = innerLength,
			axis = "x",
			thickness = 0.6,
		},
	}
	local left = edge("z", -halfW, innerZ, outerZ, overlap, 0)
	local right = edge("z", halfW, innerZ, outerZ, overlap, 1)
	local outer = edge("x", outerZ, -halfW, halfW, overlap, 0)
	for _, segment in ipairs(left) do
		segments[#segments + 1] = segment
	end
	for _, segment in ipairs(right) do
		segments[#segments + 1] = segment
	end
	for _, segment in ipairs(outer) do
		segments[#segments + 1] = segment
	end
	return segments
end

-- Two bamboo rails per segment, measured up from GROUND_Y. Both sit inside the 3-stud fence.
function ModelMapPlotsR8.fenceRails()
	return {
		{ ly = 0.8, thickness = 0.6 },
		{ ly = 2.2, thickness = 0.6 },
	}
end

-- Posts lie at multiples of POST_SPACING inside each edge, so neighbours are exactly 4 studs
-- apart and no post lands on the 6-wide gate gap. Kind is applied by the applier, not here.
local function spaced(from: number, to: number)
	local out = {}
	local first = math.ceil(from / ModelMapPlotsR8.POST_SPACING) * ModelMapPlotsR8.POST_SPACING
	for value = first, to, ModelMapPlotsR8.POST_SPACING do
		out[#out + 1] = value
	end
	return out
end

function ModelMapPlotsR8.fencePosts(width: number, depth: number, gapWidth: number)
	if width <= 0 or depth <= 0 or gapWidth < 0 then
		return {}
	end
	local halfW, halfD = width / 2, depth / 2
	local height, thick = ModelMapPlotsR8.FENCE_HEIGHT, ModelMapPlotsR8.POST_THICKNESS
	local posts = {}
	for _, x in ipairs(spaced(-halfW, halfW)) do
		if math.abs(x) >= gapWidth / 2 then
			posts[#posts + 1] = { axis = "y", lx = x, lz = -halfD, length = height, thickness = thick }
		end
		posts[#posts + 1] = { axis = "y", lx = x, lz = halfD, length = height, thickness = thick }
	end
	for _, z in ipairs(spaced(-halfD, halfD)) do
		posts[#posts + 1] = { axis = "y", lx = -halfW, lz = z, length = height, thickness = thick }
		posts[#posts + 1] = { axis = "y", lx = halfW, lz = z, length = height, thickness = thick }
	end
	return posts
end

-- Offsets are relative to the gate centre at local (0, GROUND_Y, -(depth/2 + 3)).
-- Posts sit outside the 6-wide box (inner faces at +/-3.5), the lintel bottom is above y=8.05
-- and the name sign hangs above the lintel, well outside the 6x8x1 gate-clearance box.
function ModelMapPlotsR8.gateParts(width: number, height: number)
	local postX = width / 2 + ModelMapPlotsR8.POST_THICKNESS
	return {
		{
			kind = "gate_post",
			lx = -postX,
			ly = height / 2,
			lz = 0,
			length = height,
			axis = "y",
			thickness = ModelMapPlotsR8.POST_THICKNESS,
		},
		{
			kind = "gate_post",
			lx = postX,
			ly = height / 2,
			lz = 0,
			length = height,
			axis = "y",
			thickness = ModelMapPlotsR8.POST_THICKNESS,
		},
		{
			kind = "gate_lintel",
			lx = 0,
			ly = height + 1,
			lz = 0,
			length = width + 2 * ModelMapPlotsR8.POST_THICKNESS + 2,
			axis = "x",
			thickness = ModelMapPlotsR8.POST_THICKNESS,
		},
		{
			kind = "gate_sign",
			lx = 0,
			ly = height + 3.3,
			lz = 0,
			length = width + 4,
			axis = "x",
			thickness = 2,
		},
	}
end

-- Item 181: two rope collars around the gate posts and one bamboo tie under the sign board. All
-- three sit outside the 6x8x1 clearance box (posts at |lx| >= 4, tie above the lintel top).
function ModelMapPlotsR8.gateDetailParts(width: number, height: number)
	local postX = width / 2 + ModelMapPlotsR8.POST_THICKNESS
	return {
		{
			kind = "gate_rope",
			lx = -postX,
			ly = height / 2,
			lz = 0,
			length = 0.4,
			axis = "y",
			thickness = ModelMapPlotsR8.POST_THICKNESS + 0.4,
		},
		{
			kind = "gate_rope",
			lx = postX,
			ly = height / 2,
			lz = 0,
			length = 0.4,
			axis = "y",
			thickness = ModelMapPlotsR8.POST_THICKNESS + 0.4,
		},
		{
			kind = "gate_bamboo",
			lx = 0,
			ly = height + 1.9,
			lz = 0,
			length = width + 2 * ModelMapPlotsR8.POST_THICKNESS,
			axis = "x",
			thickness = 0.3,
		},
	}
end

function ModelMapPlotsR8.gateBox()
	return {
		width = ModelMapPlotsR8.GAP_WIDTH,
		height = ModelMapPlotsR8.GATE_HEIGHT,
		depth = 1,
	}
end

-- Scarecrow near the plot centre: pole, shirt, cross arms and head, all plain relative numbers.
function ModelMapPlotsR8.scarecrowParts()
	local x, z = -6, 2
	return {
		{ kind = "scarecrow", lx = x, lz = z, ly = 2.5, axis = "y", length = 5, thickness = 0.4 },
		{ kind = "scarecrow", lx = x, lz = z, ly = 3, axis = "y", length = 2, thickness = 1.6 },
		{ kind = "scarecrow", lx = x, lz = z, ly = 3.6, axis = "x", length = 4, thickness = 0.3 },
		{ kind = "scarecrow", lx = x, lz = z, ly = 5.3, axis = "y", length = 1.2, thickness = 1 },
	}
end

-- Mailbox just inside the gate, offset to the right of the opening.
function ModelMapPlotsR8.mailboxParts(width: number, depth: number)
	local x, z = width / 3, -depth / 2 + 2
	return {
		{ kind = "mailbox", lx = x, lz = z, ly = 2, axis = "y", length = 4, thickness = 0.5 },
		{ kind = "mailbox", lx = x, lz = z, ly = 4.2, axis = "x", length = 2.4, thickness = 1.5 },
		{ kind = "mailbox_sign", lx = x, lz = z, ly = 5.4, axis = "x", length = 2.8, thickness = 0.9 },
	}
end

-- A 2-stud water sheet along the OUTER (+Z) edge plus its two narrow banks. Heights are up
-- from GROUND_Y; the sheet is deliberately thin and transparent so raycasts ignore it.
function ModelMapPlotsR8.ditchLayout(width: number, depth: number)
	local sheetZ = depth / 2 + 1 + ModelMapPlotsR8.DITCH_WIDTH / 2
	local span = width - 2
	return {
		water = {
			lx = 0,
			lz = sheetZ,
			ly = 0.08,
			width = span,
			depth = ModelMapPlotsR8.DITCH_WIDTH,
			thickness = 0.1,
		},
		banks = {
			{
				lx = 0,
				lz = sheetZ - ModelMapPlotsR8.DITCH_WIDTH / 2 - 0.25,
				ly = 0.18,
				width = span,
				depth = 0.5,
				thickness = 0.36,
			},
			{
				lx = 0,
				lz = sheetZ + ModelMapPlotsR8.DITCH_WIDTH / 2 + 0.25,
				ly = 0.18,
				width = span,
				depth = 0.5,
				thickness = 0.36,
			},
		},
	}
end

-- Deterministic three-plot corner gubuk set.
function ModelMapPlotsR8.gubukPlots()
	return { 2, 5, 8 }
end

-- Small hut in the near-right corner of a plot: four posts, a thatch roof and a bench.
function ModelMapPlotsR8.gubukParts(width: number, depth: number)
	local cx, cz = width / 2 - 5, -depth / 2 + 5
	local out = {}
	for _, dx in ipairs({ -2.5, 2.5 }) do
		for _, dz in ipairs({ -2.5, 2.5 }) do
			out[#out + 1] = { kind = "gubuk", lx = cx + dx, lz = cz + dz, ly = 2.5, size = { 0.5, 5, 0.5 } }
		end
	end
	out[#out + 1] = { kind = "gubuk", lx = cx, lz = cz, ly = 5.6, size = { 7, 0.8, 7 } }
	out[#out + 1] = { kind = "gubuk", lx = cx, lz = cz - 2, ly = 1.2, size = { 3, 0.4, 1.2 } }
	return out
end

return ModelMapPlotsR8
