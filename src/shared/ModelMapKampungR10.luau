--!strict
-- ModelMapKampungR10: pure data for the OFF-BY-DEFAULT "kampung_r10" candidate (WORK_QUEUE item 200).
-- Twelve background houses in three clusters in the band between the village ring and the plot ring.
-- No asset IDs, no engine calls: every house is a Block body + Wedge roof descriptor pair and every
-- yard is two fence Blocks + two plant Balls. A server applier consumes these descriptors.

local Data = {}

type RGB = { r: number, g: number, b: number }
type House = {
	name: string,
	cluster: number,
	position: { x: number, y: number, z: number },
	body: { size: { number }, color: RGB },
	roof: { size: { number }, color: RGB },
	yaw: number,
}
type YardPart = {
	name: string,
	house: number,
	cluster: number,
	kind: "fence" | "plant",
	shape: "Block" | "Ball",
	size: { number },
	position: { x: number, y: number, z: number },
	color: RGB,
	yaw: number,
}

Data.id = "kampung_r10"
Data.folderName = "LookDevKampungR10_kampung_r10"
Data.tagAttribute = "KampungHouse"
Data.stageAttribute = "LookDevStage"

Data.HOUSE_COUNT = 12
Data.CLUSTER_COUNT = 3
Data.HOUSES_PER_CLUSTER = 4
Data.CLUSTER_RADIUS = 165
Data.MIN_HOUSE_RADIUS = 150
Data.MAX_HOUSE_RADIUS = 185
Data.GROUND_Y = 0.5

Data.BODY_SIZE = { 16, 9, 12 }
Data.ROOF_SIZE = { 18, 6, 14 }
Data.FENCE_SIZE = { 10, 2.5, 0.8 }
Data.PLANT_SIZE = { 4, 4, 4 }

-- Warm kampung plaster and clay tile colours, one palette per cluster. Never asset IDs.
local CLUSTERS = {
	{ angle = 20, body = { r = 198, g = 132, b = 96 }, roof = { r = 126, g = 72, b = 54 } },
	{ angle = 160, body = { r = 214, g = 164, b = 104 }, roof = { r = 138, g = 82, b = 56 } },
	{ angle = 300, body = { r = 186, g = 118, b = 92 }, roof = { r = 112, g = 66, b = 52 } },
}
local OFFSETS = {
	{ -10, -8 }, -- radial, tangential
	{ -10, 8 },
	{ 10, -8 },
	{ 10, 8 },
}
local FENCE_COLOR = { r = 150, g = 108, b = 72 }
local PLANT_COLORS = {
	{ r = 86, g = 142, b = 78 },
	{ r = 112, g = 158, b = 86 },
}

local function polar(angleDeg: number, radius: number, radial: number, tangential: number): (number, number)
	local a = math.rad(angleDeg)
	local c, s = math.cos(a), math.sin(a)
	return c * (radius + radial) - s * tangential, s * (radius + radial) + c * tangential
end

local function offsetPoint(x: number, z: number, yaw: number, radial: number, tangential: number): (number, number)
	local a = math.rad(yaw)
	local c, s = math.cos(a), math.sin(a)
	return x + radial * c - tangential * s, z + radial * s + tangential * c
end

local function rgb(value: RGB): RGB
	return { r = value.r, g = value.g, b = value.b }
end

function Data.houses(): { House }
	local houses: { House } = {}
	for cluster, entry in ipairs(CLUSTERS) do
		for slot, offset in ipairs(OFFSETS) do
			local x, z = polar(entry.angle, Data.CLUSTER_RADIUS, offset[1], offset[2])
			houses[#houses + 1] = {
				name = "KampungHouse_c" .. cluster .. "_" .. slot,
				cluster = cluster,
				position = { x = x, y = Data.GROUND_Y, z = z },
				body = { size = { Data.BODY_SIZE[1], Data.BODY_SIZE[2], Data.BODY_SIZE[3] }, color = rgb(entry.body) },
				roof = { size = { Data.ROOF_SIZE[1], Data.ROOF_SIZE[2], Data.ROOF_SIZE[3] }, color = rgb(entry.roof) },
				yaw = entry.angle + (slot % 2 == 0 and 8 or -8),
			}
		end
	end
	return houses
end

function Data.yardParts(): { YardPart }
	local parts: { YardPart } = {}
	for index, house in ipairs(Data.houses()) do
		local px, pz = house.position.x, house.position.z
		for side, sign in ipairs({ -1, 1 }) do
			local fx, fz = offsetPoint(px, pz, house.yaw, 2, sign * 9)
			parts[#parts + 1] = {
				name = "KampungYard_h" .. index .. "_fence_" .. side,
				house = index,
				cluster = house.cluster,
				kind = "fence",
				shape = "Block",
				size = { Data.FENCE_SIZE[1], Data.FENCE_SIZE[2], Data.FENCE_SIZE[3] },
				position = { x = fx, y = Data.GROUND_Y + Data.FENCE_SIZE[2] / 2, z = fz },
				color = rgb(FENCE_COLOR),
				yaw = house.yaw + 90,
			}
			local gx, gz = offsetPoint(px, pz, house.yaw, 6, sign * 4)
			parts[#parts + 1] = {
				name = "KampungYard_h" .. index .. "_plant_" .. side,
				house = index,
				cluster = house.cluster,
				kind = "plant",
				shape = "Ball",
				size = { Data.PLANT_SIZE[1], Data.PLANT_SIZE[2], Data.PLANT_SIZE[3] },
				position = { x = gx, y = Data.GROUND_Y + Data.PLANT_SIZE[2] / 2, z = gz },
				color = rgb(PLANT_COLORS[side]),
				yaw = 0,
			}
		end
	end
	return parts
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	local houses = Data.houses()
	assert(#houses == Data.HOUSE_COUNT, "kampung_r10: house count is not 12")
	assert(Data.HOUSE_COUNT >= 10 and Data.HOUSE_COUNT <= 14, "kampung_r10: house count outside 10..14")

	local perCluster = {}
	for _, house in ipairs(houses) do
		assert(house.cluster >= 1 and house.cluster <= Data.CLUSTER_COUNT, "kampung_r10: bad cluster index")
		perCluster[house.cluster] = (perCluster[house.cluster] or 0) + 1
		local x, z = house.position.x, house.position.z
		local radius = math.sqrt(x * x + z * z)
		assert(
			radius >= Data.MIN_HOUSE_RADIUS and radius <= Data.MAX_HOUSE_RADIUS,
			"kampung_r10: house radius outside 150..185"
		)
		for _, color in ipairs({ house.body.color, house.roof.color }) do
			for _, channel in ipairs({ color.r, color.g, color.b }) do
				assert(channel >= 0 and channel <= 255, "kampung_r10: colour channel outside 0..255")
			end
		end
	end
	assert(#perCluster == Data.CLUSTER_COUNT, "kampung_r10: cluster count is not 3")
	for _, count in pairs(perCluster) do
		assert(count == Data.HOUSES_PER_CLUSTER, "kampung_r10: cluster does not hold 4 houses")
	end

	local yards = Data.yardParts()
	assert(#yards == Data.HOUSE_COUNT * 4, "kampung_r10: yard part count is not 4 per house")
	for _, part in ipairs(yards) do
		assert(part.kind == "fence" or part.kind == "plant", "kampung_r10: bad yard kind")
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "kampung_r10: yard colour channel outside 0..255")
		end
	end
end

return Data
