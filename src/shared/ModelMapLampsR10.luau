--!strict
-- ModelMapLampsR10: pure data for the OFF-BY-DEFAULT "lamps_r10" candidate (WORK_QUEUE items
-- 202, 246, 256). Twelve warm street lamps evenly spaced around the MapSpec ring road (radius 144).
-- Item 246: the PointLight sits at the pole centre so its <=16 range reaches the road, with a
-- capped brightness so the warm pool stays readable instead of blowing out. Item 256: applier
-- stages a model-based old-style lamp (see ASSET_MANIFEST lamps_r10_model) with scripts/light cone
-- removed. Data stays pure: no engine calls, no asset IDs.

local Data = {}

type Vec3 = { x: number, y: number, z: number }
type RGB = { r: number, g: number, b: number }
type LampPart = { size: { number }, color: RGB }
type Lamp = {
	name: string,
	index: number,
	position: Vec3,
	radius: number,
	pole: LampPart,
	lantern: LampPart,
}

Data.id = "lamps_r10"
Data.folderName = "LookDevLampsR10_lamps_r10"

Data.LAMP_COUNT = 12
Data.LIGHT_RANGE = 16 -- hard ceiling: never exceed the LIGHT_COST budget
Data.RING_RADIUS = 144
Data.GROUND_Y = 0.5
Data.NIGHT_ON = 18
Data.NIGHT_OFF = 6

Data.POLE_SIZE = { 0.7, 9, 0.7 }
Data.POLE_COLOR = { r = 118, g = 84, b = 52 } -- warm wood
Data.LANTERN_SIZE = { 1.6, 1.6, 1.6 }
Data.LANTERN_COLOR = { r = 255, g = 204, b = 126 } -- warm glow
Data.LIGHT_COLOR = { r = 255, g = 190, b = 120 } -- warm amber PointLight
Data.LIGHT_BRIGHTNESS = 2.5 -- item 246: visible road pool, capped <= 3 to avoid blowout

local LAMPS: { Lamp } = {}
for index = 1, Data.LAMP_COUNT do
	local angle = (index - 1) * (2 * math.pi / Data.LAMP_COUNT)
	LAMPS[index] = {
		name = "StreetLamp_" .. string.format("%02d", index),
		index = index,
		position = {
			x = Data.RING_RADIUS * math.cos(angle),
			y = Data.GROUND_Y,
			z = Data.RING_RADIUS * math.sin(angle),
		},
		radius = Data.RING_RADIUS,
		pole = {
			size = { Data.POLE_SIZE[1], Data.POLE_SIZE[2], Data.POLE_SIZE[3] },
			color = { r = Data.POLE_COLOR.r, g = Data.POLE_COLOR.g, b = Data.POLE_COLOR.b },
		},
		lantern = {
			size = { Data.LANTERN_SIZE[1], Data.LANTERN_SIZE[2], Data.LANTERN_SIZE[3] },
			color = { r = Data.LANTERN_COLOR.r, g = Data.LANTERN_COLOR.g, b = Data.LANTERN_COLOR.b },
		},
	}
end

-- Fresh descriptors on every call: callers may mutate their copy without changing the recipe.
function Data.lamps(): { Lamp }
	local list: { Lamp } = {}
	for index, lamp in ipairs(LAMPS) do
		list[index] = {
			name = lamp.name,
			index = lamp.index,
			position = { x = lamp.position.x, y = lamp.position.y, z = lamp.position.z },
			radius = lamp.radius,
			pole = {
				size = { lamp.pole.size[1], lamp.pole.size[2], lamp.pole.size[3] },
				color = { r = lamp.pole.color.r, g = lamp.pole.color.g, b = lamp.pole.color.b },
			},
			lantern = {
				size = { lamp.lantern.size[1], lamp.lantern.size[2], lamp.lantern.size[3] },
				color = { r = lamp.lantern.color.r, g = lamp.lantern.color.g, b = lamp.lantern.color.b },
			},
		}
	end
	return list
end

-- Load-time contract check: keeps the recipe honest before any applier or harness reads it.
do
	local lamps = Data.lamps()
	assert(#lamps >= 12, "lamps_r10: fewer than 12 lamps")
	assert(#lamps == Data.LAMP_COUNT, "lamps_r10: lamp count does not match LAMP_COUNT")
	assert(Data.LIGHT_RANGE <= 16, "lamps_r10: LIGHT_RANGE exceeds 16")
	assert(Data.LIGHT_BRIGHTNESS > 0 and Data.LIGHT_BRIGHTNESS <= 3, "lamps_r10: LIGHT_BRIGHTNESS outside 0..3")
	for _, lamp in ipairs(lamps) do
		local distance = math.sqrt(lamp.position.x * lamp.position.x + lamp.position.z * lamp.position.z)
		assert(math.abs(distance - Data.RING_RADIUS) < 1e-6, "lamps_r10: lamp is off the ring road")
		for _, part in ipairs({ lamp.pole, lamp.lantern }) do
			assert(part.color.r >= 0 and part.color.r <= 255, "lamps_r10: colour channel outside 0..255")
			assert(part.color.g >= 0 and part.color.g <= 255, "lamps_r10: colour channel outside 0..255")
			assert(part.color.b >= 0 and part.color.b <= 255, "lamps_r10: colour channel outside 0..255")
		end
	end
	for _, channel in ipairs({ Data.LIGHT_COLOR.r, Data.LIGHT_COLOR.g, Data.LIGHT_COLOR.b }) do
		assert(channel >= 0 and channel <= 255, "lamps_r10: light colour channel outside 0..255")
	end
end

return Data
