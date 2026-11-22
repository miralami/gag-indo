--!strict
-- ModelMapRoadFenceR10: pure data for the OFF-BY-DEFAULT "road_fence_r10" candidate
-- (WORK_QUEUE item 201). Six short bamboo fence stretches beside the main roads, one to two per
-- arm, all kept at radius 60..120 so the r=144 junction ring and the r=152 plot gates are never
-- crossed. No engine calls, no asset IDs: a server applier consumes these descriptors.

local Data = {}

type Vec3 = { number }
type RGB = { r: number, g: number, b: number }
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
	kind: string,
	stretch: number,
	position: Vec3,
	size: Vec3,
	color: RGB,
}

Data.id = "road_fence_r10"
Data.folderName = "LookDevRoadFenceR10_road_fence_r10"

Data.FENCE_HEIGHT = 1.2
Data.BAMBOO_COLOR = { r = 180, g = 165, b = 90 }
Data.GROUND_Y = 0.5

Data.RADIUS_MIN = 60
Data.RADIUS_MAX = 120
Data.RING_CENTRE = 144
Data.GATE_RADIUS = 152
Data.GAP_MIN = 8
Data.SIDE_OFFSET = 10 -- inside the 14-stud road half-width

Data.POST_SPACING = 4
Data.POST_THICKNESS = 0.4
Data.RAIL_THICKNESS = 0.25
Data.RAIL_HEIGHT_OFFSET = 0.85

-- A stretch ends 36 studs before the ring centreline: the reserved band covers the r=136..150
-- ring, every junction on it, and the r=152 plot gates. No post or rail is emitted inside it.
local function ringKeepOut(): { Gap }
	return { { from = Data.RADIUS_MAX, to = Data.GATE_RADIUS + Data.GAP_MIN } }
end

-- angle 0 = east, 90 = south, 180 = west, 270 = north. The west arm stops at r=84, short of the
-- Pos Ronda footprint at x=-86; the other arms stop at r<=116, still 28 studs inside the ring.
local STRETCHES: { Stretch } = {
	{ name = "FenceEastNorth", angle = 0, radiusFrom = 64, radiusTo = 116, side = -1, gaps = ringKeepOut() },
	{ name = "FenceEastSouth", angle = 0, radiusFrom = 68, radiusTo = 116, side = 1, gaps = ringKeepOut() },
	{ name = "FenceWestNorth", angle = 180, radiusFrom = 60, radiusTo = 84, side = 1, gaps = ringKeepOut() },
	{ name = "FenceWestSouth", angle = 180, radiusFrom = 60, radiusTo = 84, side = -1, gaps = ringKeepOut() },
	{ name = "FenceNorthEast", angle = 270, radiusFrom = 64, radiusTo = 116, side = -1, gaps = ringKeepOut() },
	{ name = "FenceSouthWest", angle = 90, radiusFrom = 68, radiusTo = 116, side = 1, gaps = ringKeepOut() },
}

function Data.stretches(): { Stretch }
	return table.clone(STRETCHES)
end

local function pointOnStretch(angle: number, radius: number, side: number): (number, number)
	local radians = math.rad(angle)
	local dx, dz = math.cos(radians), math.sin(radians)
	return dx * radius - dz * Data.SIDE_OFFSET * side, dz * radius + dx * Data.SIDE_OFFSET * side
end

local function bamboo(): RGB
	return { r = Data.BAMBOO_COLOR.r, g = Data.BAMBOO_COLOR.g, b = Data.BAMBOO_COLOR.b }
end

local function inGap(stretch: Stretch, radius: number): boolean
	for _, gap in ipairs(stretch.gaps) do
		if radius >= gap.from and radius <= gap.to then
			return true
		end
	end
	return false
end

function Data.parts(): { PartDescriptor }
	local parts: { PartDescriptor } = {}
	for index, stretch in ipairs(STRETCHES) do
		local previous: { x: number, z: number }? = nil
		for radius = stretch.radiusFrom, stretch.radiusTo, Data.POST_SPACING do
			if not inGap(stretch, radius) then
				local x, z = pointOnStretch(stretch.angle, radius, stretch.side)
				parts[#parts + 1] = {
					name = stretch.name .. "_Post_" .. radius,
					kind = "post",
					stretch = index,
					position = { x, Data.GROUND_Y + Data.FENCE_HEIGHT / 2, z },
					size = { Data.POST_THICKNESS, Data.FENCE_HEIGHT, Data.POST_THICKNESS },
					color = bamboo(),
				}
				if previous then
					parts[#parts + 1] = {
						name = stretch.name .. "_Rail_" .. radius,
						kind = "rail",
						stretch = index,
						position = {
							(previous.x + x) / 2,
							Data.GROUND_Y + Data.RAIL_HEIGHT_OFFSET,
							(previous.z + z) / 2,
						},
						size = if stretch.angle % 180 == 0
							then { Data.POST_SPACING, Data.RAIL_THICKNESS, Data.RAIL_THICKNESS }
							else { Data.RAIL_THICKNESS, Data.RAIL_THICKNESS, Data.POST_SPACING },
						color = bamboo(),
					}
				end
				previous = { x = x, z = z }
			end
		end
	end
	return parts
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
	for _, channel in ipairs({ Data.BAMBOO_COLOR.r, Data.BAMBOO_COLOR.g, Data.BAMBOO_COLOR.b }) do
		assert(channel >= 0 and channel <= 255, "road_fence_r10: colour channel outside 0..255")
	end
	assert(#Data.parts() > 0, "road_fence_r10: no fence parts")
end

return Data
