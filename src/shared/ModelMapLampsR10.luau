--!strict
-- ModelMapLampsR10: pure data for the OFF-BY-DEFAULT "lamps_r10" candidate (WORK_QUEUE items
-- 202, 246, 270). Item 270 replaces the twelve thin ring poles with warm single bulbs on the front
-- eaves of default houses, Warung and Pos Ronda, plus a few thick, readable junction poles.
--
-- Hub x/z/yaw/footprints are copied from MapSpec.HUBS (server-only, so it cannot be required here),
-- the same mirror ModelMapNightR8 uses. Every bulb/pole position below is a rotation and a fraction
-- of those numbers; no new world coordinate is invented here. PURE DATA: no services, Instances,
-- Enum values, asset IDs or visual verdicts. The applier owns the baked lamp model id.

local Data = {}

type Vec3 = { x: number, y: number, z: number }
type RGB = { r: number, g: number, b: number }
type Bulb = {
	name: string,
	index: number,
	role: string,
	anchor: string,
	position: Vec3,
	size: { number },
	color: RGB,
}
type Pole = {
	name: string,
	index: number,
	role: string,
	position: Vec3,
	pole: { size: { number }, color: RGB },
	head: { size: { number }, color: RGB },
}

Data.id = "lamps_r10"
Data.folderName = "LookDevLampsR10_lamps_r10"

-- Attribute names are data so the Studio harness reads exactly what the applier writes.
Data.tagAttribute = "StreetLamp"
Data.indexAttribute = "lamp"
Data.roleAttribute = "role"
Data.anchorAttribute = "lampAnchor"
Data.modelAttribute = "LampModelAsset"
Data.porchRole = "porchBulb"
Data.headRole = "lampHead"
Data.poleRole = "junctionPole"

Data.MAX_LIGHTS = 12 -- existing LIGHT_COST ceiling (12 PointLights max)
Data.LIGHT_RANGE = 16 -- existing ceiling: never exceed the item-246 harness target
Data.LIGHT_BRIGHTNESS = 1.8 -- capped <= 3 so warm pools stay readable
Data.PORCH_BULB_COUNT = 6
Data.JUNCTION_COUNT = 3
Data.MAX_JUNCTIONS = 4
Data.GROUND_Y = 0.5 -- MapSpec.GROUND_Y
Data.EAVE_OFFSET = 9.5 -- MapSpec.HEADROOM: underside of every front eave
Data.ROOF_OVERHANG = 3 -- MapSpec.ROOF_OVERHANG
Data.BULB_DROP = 1
Data.RING_RADIUS = 144 -- MapSpec.ROAD.ringCentre
Data.NIGHT_ON = 20
Data.NIGHT_OFF = 5
Data.MIN_POLE_WIDTH = 0.6

Data.BULB_SIZE = { 0.9, 0.9, 0.9 }
Data.BULB_COLOR = { r = 255, g = 204, b = 126 }
Data.POLE_SIZE = { 0.8, 11, 0.8 } -- readable thickness, >= MIN_POLE_WIDTH on X and Z
Data.POLE_COLOR = { r = 118, g = 84, b = 52 }
Data.HEAD_SIZE = { 1.4, 1.2, 1.4 }
Data.HEAD_COLOR = { r = 255, g = 204, b = 126 }
Data.LIGHT_COLOR = { r = 255, g = 190, b = 120 }

-- x, z, yaw, width and depth copied from MapSpec.HUBS. Only the four buildings with front eaves
-- used by item 270 are mirrored (Pak RT and Pos Polisi are the default houses).
local HUBS = {
	pakrt = { key = "pakrt", x = 68, z = 68, yaw = 180, width = 48, depth = 34 },
	polisi = { key = "polisi", x = -68, z = 68, yaw = 180, width = 48, depth = 44 },
	warung = { key = "warung", x = 68, z = -68, yaw = 0, width = 52, depth = 44 },
	ronda = { key = "ronda", x = -108, z = 0, yaw = 90, width = 44, depth = 40 },
}

-- Local eave anchors as fractions of each hub's width and depth. lz = 0.5 is the front wall line;
-- the applier pushes the bulb half a roof overhang past it so it reads under the eave, not inside.
local PORCH_ANCHORS = {
	{ hub = "pakrt", lx = -0.25, lz = 0.5 },
	{ hub = "polisi", lx = 0.25, lz = 0.5 },
	{ hub = "warung", lx = -0.2, lz = 0.5 },
	{ hub = "warung", lx = 0.2, lz = 0.5 },
	{ hub = "ronda", lx = -0.2, lz = 0.5 },
	{ hub = "ronda", lx = 0.2, lz = 0.5 },
}

local function rotate(cx: number, cz: number, yaw: number, lx: number, lz: number): (number, number)
	local a = math.rad(yaw)
	local cos, sin = math.cos(a), math.sin(a)
	return cx + lx * cos + lz * sin, cz - lx * sin + lz * cos
end

local function rgb(value: RGB): RGB
	return { r = value.r, g = value.g, b = value.b }
end

local function sizeOf(value: { number }): { number }
	return { value[1], value[2], value[3] }
end

function Data.hubs()
	local list = {}
	for key, hub in pairs(HUBS) do
		list[key] = {
			key = hub.key,
			x = hub.x,
			z = hub.z,
			yaw = hub.yaw,
			width = hub.width,
			depth = hub.depth,
		}
	end
	return list
end

-- Six warm single bulbs: one on each default house porch, two under the Warung eave and two under
-- the Pos Ronda eave. Fresh descriptors on every call, so callers may mutate their copy freely.
function Data.porchBulbs(): { Bulb }
	local list: { Bulb } = {}
	for index, anchor in ipairs(PORCH_ANCHORS) do
		local hub = HUBS[anchor.hub]
		local x, z =
			rotate(hub.x, hub.z, hub.yaw, anchor.lx * hub.width, anchor.lz * hub.depth + Data.ROOF_OVERHANG / 2)
		list[index] = {
			name = "PorchBulb_" .. string.format("%02d", index),
			index = index,
			role = Data.porchRole,
			anchor = anchor.hub,
			position = { x = x, y = Data.GROUND_Y + Data.EAVE_OFFSET - Data.BULB_DROP, z = z },
			size = sizeOf(Data.BULB_SIZE),
			color = rgb(Data.BULB_COLOR),
		}
	end
	return list
end

-- Junction poles sit on the ring road centreline where the four cardinal road arms meet it. Only
-- three of the four possible junctions are lit, staying at or below MAX_JUNCTIONS.
function Data.junctionPoles(): { Pole }
	local list: { Pole } = {}
	for index = 1, Data.JUNCTION_COUNT do
		local angle = (index - 1) * (math.pi / 2)
		list[index] = {
			name = "JunctionPole_" .. string.format("%02d", index),
			index = Data.PORCH_BULB_COUNT + index,
			role = Data.poleRole,
			position = {
				x = Data.RING_RADIUS * math.cos(angle),
				y = Data.GROUND_Y,
				z = Data.RING_RADIUS * math.sin(angle),
			},
			pole = { size = sizeOf(Data.POLE_SIZE), color = rgb(Data.POLE_COLOR) },
			head = { size = sizeOf(Data.HEAD_SIZE), color = rgb(Data.HEAD_COLOR) },
		}
	end
	return list
end

-- Legacy view used by ReviewCameras.luau's lamp_night camera and the item-246 harness: after item
-- 270 the only street lamps left are the junction poles. Keeping this shim derived from the same
-- pole descriptors preserves the item-240 camera pose without editing the main session's files.
function Data.lamps()
	local list = {}
	for index, pole in ipairs(Data.junctionPoles()) do
		list[index] = {
			name = pole.name,
			index = pole.index,
			position = pole.position,
			radius = Data.RING_RADIUS,
			pole = { size = sizeOf(Data.POLE_SIZE), color = rgb(Data.POLE_COLOR) },
			lantern = { size = sizeOf(Data.HEAD_SIZE), color = rgb(Data.HEAD_COLOR) },
		}
	end
	return list
end

-- Night gate shared by applier, harness and LUNE spec: on at >= 20 and <= 5, off in between.
function Data.isNight(clock: any): boolean
	return type(clock) == "number" and clock == clock and (clock >= Data.NIGHT_ON or clock <= Data.NIGHT_OFF)
end

-- Load-time contract check: keeps the recipe honest before any applier or harness reads it.
do
	local bulbs = Data.porchBulbs()
	local poles = Data.junctionPoles()
	assert(#bulbs == Data.PORCH_BULB_COUNT and #bulbs >= 6, "lamps_r10: porch bulb count below 6")
	assert(#poles >= 0 and #poles <= Data.MAX_JUNCTIONS, "lamps_r10: too many junction poles")
	assert(Data.MAX_JUNCTIONS <= 4, "lamps_r10: MAX_JUNCTIONS above 4")
	assert(#bulbs + #poles <= Data.MAX_LIGHTS and Data.MAX_LIGHTS <= 12, "lamps_r10: light budget above 12")
	assert(Data.LIGHT_RANGE > 0 and Data.LIGHT_RANGE <= 16, "lamps_r10: LIGHT_RANGE exceeds 16")
	assert(Data.LIGHT_BRIGHTNESS > 0 and Data.LIGHT_BRIGHTNESS <= 3, "lamps_r10: brightness outside 0..3")
	assert(Data.NIGHT_ON > Data.NIGHT_OFF, "lamps_r10: night thresholds inverted")
	assert(
		Data.isNight(20) and Data.isNight(5) and not Data.isNight(19.9) and not Data.isNight(5.1),
		"lamps_r10: bad night gate"
	)
	assert(
		Data.POLE_SIZE[1] >= Data.MIN_POLE_WIDTH and Data.POLE_SIZE[3] >= Data.MIN_POLE_WIDTH,
		"lamps_r10: pole too thin"
	)

	for _, bulb in ipairs(bulbs) do
		assert(bulb.role == Data.porchRole and HUBS[bulb.anchor] ~= nil, "lamps_r10: bad porch bulb anchor")
	end
	for _, pole in ipairs(poles) do
		local distance = math.sqrt(pole.position.x ^ 2 + pole.position.z ^ 2)
		assert(math.abs(distance - Data.RING_RADIUS) < 1e-6, "lamps_r10: junction pole off the ring")
	end
	for _, part in ipairs({
		{ size = Data.BULB_SIZE, color = Data.BULB_COLOR },
		{ size = Data.POLE_SIZE, color = Data.POLE_COLOR },
		{ size = Data.HEAD_SIZE, color = Data.HEAD_COLOR },
		{ size = { 1, 1, 1 }, color = Data.LIGHT_COLOR },
	}) do
		for _, dimension in ipairs(part.size) do
			assert(dimension > 0, "lamps_r10: non-positive part dimension")
		end
		for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
			assert(channel >= 0 and channel <= 255, "lamps_r10: colour channel outside 0..255")
		end
	end
end

return Data
