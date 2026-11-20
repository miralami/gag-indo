--!strict
-- ModelMapPlotsR8: pure data for the OFF-BY-DEFAULT "plots_r8" LookDev candidate
-- (WORK_QUEUE section M item 71). Plot fences with a gate on the INNER (-Z) side of all ten plots.
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
ModelMapPlotsR8.MIN_SEGMENTS = 6
ModelMapPlotsR8.OVERLAP = 0.2
ModelMapPlotsR8.FENCE_HEIGHT = 4
ModelMapPlotsR8.POST_THICKNESS = 1

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
-- on local x=0. Returns plain numbers only; deterministic for identical inputs.
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

-- Offsets are relative to the gate centre at local (0, GROUND_Y, -(depth/2 + 3)).
-- Posts sit outside the 6-wide box (inner faces at +/-3.5) and the lintel bottom is above y=8.
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
	}
end

function ModelMapPlotsR8.gateBox()
	return {
		width = ModelMapPlotsR8.GAP_WIDTH,
		height = ModelMapPlotsR8.GATE_HEIGHT,
		depth = 1,
	}
end

return ModelMapPlotsR8
