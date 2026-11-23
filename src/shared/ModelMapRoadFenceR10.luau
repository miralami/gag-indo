--!strict
-- ModelMapRoadFenceR10: pure data for the OFF-BY-DEFAULT "road_fence_r10" candidate
-- (WORK_QUEUE item 201, rebuilt by item 262). Six road-shoulder stretches, each filled with repeated
-- 2.5-stud baked bamboo-fence models; the real creator-store id lives in the server applier, never
-- here. One shoulder patch per stretch drives the Grass -> Ground voxel repaint that keeps the fence
-- readable from road level. All stretches stay inside radius 60..120, clear of the r=144 junction
-- ring and the r=152 plot gates. No engine calls, no asset IDs: a server applier consumes this data.

local Data = {}

type Vec3 = { number }
type Gap = { from: number, to: number }
type Stretch = {
	name: string,
	angle: number,
	radiusFrom: number,
	radiusTo: number,
	side: number,
	gaps: { Gap },
}
type PartDescriptor = {
	name: string,
	group: string,
	asset: string,
	stretch: number,
	position: Vec3,
	angle: number,
	height: number,
	footprint: Vec3,
}
type ShoulderPatch = {
	name: string,
	stretch: number,
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
}

Data.id = "road_fence_r10"
Data.folderName = "LookDevRoadFenceR10_road_fence_r10"

Data.FENCE_HEIGHT = 2.5 -- item 262: baked model scaled to ~2.5 studs tall
Data.MODEL_ASSET_KEY = "fence_bamboo" -- applier maps this to pick 1's real asset ID
Data.MODEL_FOOTPRINT = { 6.4, 2.5, 0.5 } -- scaled bbox estimate: long, tall, thin
Data.MODEL_STEP = 6 -- legacy estimate; parts() now tiles each run end to end from the real length
Data.BAMBOO_COLOR = { r = 180, g = 165, b = 90 }
Data.GROUND_Y = 0.5

Data.RADIUS_MIN = 60
Data.RADIUS_MAX = 120
Data.RING_CENTRE = 144
Data.GATE_RADIUS = 152
Data.GAP_MIN = 8
Data.ROAD_HALF = 14 -- MapSpec.ROAD.halfWidth: the arm road surface spans +-14 studs of its centreline
Data.SHOULDER_GAP = 2 -- fence centre sits this far outside the road edge, on the grass shoulder
Data.SHOULDER_MIN = 1.5 -- spec band for the gap between the road edge and the fence centre
Data.SHOULDER_MAX = 2.5
Data.SIDE_OFFSET = Data.ROAD_HALF + Data.SHOULDER_GAP -- 16: never on the dirt road surface
-- Mid-run gate gap: a long run opens here so the fence reads as runs with a gateway, not one wall.
Data.GATE_GAP = { from = 88, to = 98 }
Data.GATE_GAP_MIN_RADIUS_TO = 116 -- only the long arms get the gate gap

Data.SHOULDER_HALF_WIDTH = 4 -- repaint band centred on the fence line
Data.PATCH_PADDING = 2 -- snap margin at either end of a stretch

-- A stretch ends 36 studs before the ring centreline: the reserved band covers the r=136..150
-- ring, every junction on it, and the r=152 plot gates. No model is placed inside it.
local function ringKeepOut(): { Gap }
	return { { from = Data.RADIUS_MAX, to = Data.GATE_RADIUS + Data.GAP_MIN } }
end

-- angle 0 = east, 90 = south, 180 = west, 270 = north. The west arm stops at r=84, short of the
-- Pos Ronda footprint at x=-86; the other arms stop at r<=116, still inside the ring keep-out.
local STRETCHES: { Stretch } = {
	{ name = "FenceEastNorth", angle = 0, radiusFrom = 64, radiusTo = 116, side = -1, gaps = ringKeepOut() },
	{ name = "FenceEastSouth", angle = 0, radiusFrom = 68, radiusTo = 116, side = 1, gaps = ringKeepOut() },
	{ name = "FenceWestNorth", angle = 180, radiusFrom = 60, radiusTo = 84, side = 1, gaps = ringKeepOut() },
	{ name = "FenceWestSouth", angle = 180, radiusFrom = 60, radiusTo = 84, side = -1, gaps = ringKeepOut() },
	{ name = "FenceNorthEast", angle = 270, radiusFrom = 64, radiusTo = 116, side = -1, gaps = ringKeepOut() },
	{ name = "FenceSouthWest", angle = 90, radiusFrom = 68, radiusTo = 116, side = 1, gaps = ringKeepOut() },
	{ name = "FenceNorthWest", angle = 270, radiusFrom = 64, radiusTo = 116, side = 1, gaps = ringKeepOut() },
	{ name = "FenceSouthEast", angle = 90, radiusFrom = 68, radiusTo = 116, side = -1, gaps = ringKeepOut() },
}

function Data.stretches(): { Stretch }
	return table.clone(STRETCHES)
end

local function pointOnStretch(angle: number, radius: number, side: number): (number, number)
	local radians = math.rad(angle)
	local dx, dz = math.cos(radians), math.sin(radians)
	return dx * radius - dz * Data.SIDE_OFFSET * side, dz * radius + dx * Data.SIDE_OFFSET * side
end

Data.MAX_JOIN_GAP = 0.3 -- largest gap allowed between two consecutive modules inside a run

-- Continuous intervals along the arm (radius from, radius to) of one stretch: the stretch span minus
-- the ring keep-out and, on the long arms, the mid-run gate gap.
local function runIntervals(stretch: Stretch): { Gap }
	local cuts: { Gap } = {}
	for _, gap in ipairs(stretch.gaps) do
		cuts[#cuts + 1] = gap
	end
	if stretch.radiusTo >= Data.GATE_GAP_MIN_RADIUS_TO then
		cuts[#cuts + 1] = Data.GATE_GAP
	end
	table.sort(cuts, function(a, b)
		return a.from < b.from
	end)
	local runs: { Gap } = {}
	local cursor = stretch.radiusFrom
	for _, cut in ipairs(cuts) do
		if cut.from > cursor then
			runs[#runs + 1] = { from = cursor, to = math.min(cut.from, stretch.radiusTo) }
		end
		cursor = math.max(cursor, cut.to)
	end
	if cursor < stretch.radiusTo then
		runs[#runs + 1] = { from = cursor, to = stretch.radiusTo }
	end
	return runs
end

function Data.runs(): { { group: string, stretch: number, from: number, to: number } }
	local out = {}
	for index, stretch in ipairs(STRETCHES) do
		for _, run in ipairs(runIntervals(stretch)) do
			out[#out + 1] = { group = stretch.name, stretch = index, from = run.from, to = run.to }
		end
	end
	return out
end

-- One descriptor per baked-model instance. Every run is tiled end to end: the module count is the
-- smallest that keeps each join gap at or under MAX_JOIN_GAP, and the modules are spread evenly so
-- the first and last ones sit flush with the run ends (overlap, never a gap). `length` is the real
-- module length along the road; the applier measures it, the default is the footprint estimate.
function Data.parts(length: number?): { PartDescriptor }
	local parts: { PartDescriptor } = {}
	local moduleLength = length or Data.MODEL_FOOTPRINT[1]
	for index, stretch in ipairs(STRETCHES) do
		local segment = 0
		for _, run in ipairs(runIntervals(stretch)) do
			local span = run.to - run.from
			if span < moduleLength then
				continue
			end
			local count = math.ceil((span - moduleLength) / (moduleLength + Data.MAX_JOIN_GAP)) + 1
			local step = if count > 1 then (span - moduleLength) / (count - 1) else 0
			for k = 0, count - 1 do
				local radius = run.from + moduleLength / 2 + k * step
				local x, z = pointOnStretch(stretch.angle, radius, stretch.side)
				parts[#parts + 1] = {
					name = stretch.name .. "_Model_" .. segment,
					group = stretch.name,
					asset = Data.MODEL_ASSET_KEY,
					stretch = index,
					position = { x, Data.GROUND_Y + Data.FENCE_HEIGHT / 2, z },
					angle = stretch.angle,
					height = Data.FENCE_HEIGHT,
					footprint = { moduleLength, Data.FENCE_HEIGHT, Data.MODEL_FOOTPRINT[3] },
				}
				segment += 1
			end
		end
	end
	return parts
end

-- Axis-aligned shoulder bands (every stretch runs along an X or Z road arm). The applier snaps each
-- band outward to the 4-stud terrain voxel grid before it repaints Grass cells as Ground.
function Data.shoulderPatches(): { ShoulderPatch }
	local patches: { ShoulderPatch } = {}
	local band = Data.SHOULDER_HALF_WIDTH + Data.PATCH_PADDING
	for index, stretch in ipairs(STRETCHES) do
		local x1, z1 = pointOnStretch(stretch.angle, stretch.radiusFrom, stretch.side)
		local x2, z2 = pointOnStretch(stretch.angle, stretch.radiusTo, stretch.side)
		patches[#patches + 1] = {
			name = stretch.name .. "_Shoulder",
			stretch = index,
			minX = math.min(x1, x2) - band,
			maxX = math.max(x1, x2) + band,
			minZ = math.min(z1, z2) - band,
			maxZ = math.max(z1, z2) + band,
		}
	end
	return patches
end

-- Load-time contract check, before any applier or harness reads the data.
do
	local stretches = Data.stretches()
	assert(#stretches >= 6, "road_fence_r10: fewer than 6 stretches")
	for _, stretch in ipairs(stretches) do
		assert(stretch.radiusFrom >= 60, "road_fence_r10: radiusFrom below 60")
		assert(stretch.radiusTo <= 120, "road_fence_r10: radiusTo exceeds 120")
		assert(stretch.radiusTo > stretch.radiusFrom, "road_fence_r10: empty stretch")
	end
	assert(Data.FENCE_HEIGHT >= 2.4 and Data.FENCE_HEIGHT <= 2.8, "road_fence_r10: bad model height")
	for _, channel in ipairs({ Data.BAMBOO_COLOR.r, Data.BAMBOO_COLOR.g, Data.BAMBOO_COLOR.b }) do
		assert(channel >= 0 and channel <= 255, "road_fence_r10: colour channel outside 0..255")
	end
	local parts = Data.parts()
	assert(#parts > 0, "road_fence_r10: no fence models")
	local groups = {}
	for _, part in ipairs(parts) do
		assert(part.asset == Data.MODEL_ASSET_KEY, "road_fence_r10: missing asset key")
		assert(part.height == Data.FENCE_HEIGHT, "road_fence_r10: mixed model heights")
		groups[part.group] = true
	end
	local groupCount = 0
	for _ in pairs(groups) do
		groupCount += 1
	end
	assert(groupCount >= 6, "road_fence_r10: fewer than 6 model groups")
	assert(#Data.shoulderPatches() >= 6, "road_fence_r10: missing shoulder patches")
end

return Data
