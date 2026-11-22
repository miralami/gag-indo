--!strict
-- ModelMapNightR8: PURE data/functions for WORK_QUEUE section M item 90 (night_r8).
-- No services, Instances, Enum values or asset IDs: every number is a literal taken from MapSpec,
-- the facade window recipes and DayCycleLive.LAMP_POSITIONS, rotated here with pure XZ maths. The
-- SERVER applier turns these records into panes and shadowless PointLights.
--
-- WINDOW_SPECS holds 12 shutter-window anchors (two per MapSpec hub, from ModelMapFacadesR8's
-- FacadeShutteredWindow_L/R local offsets) plus the four real Pak RT WindowGlass panes recorded in
-- Greybox: 16 panes, so NIGHT_WINDOWS >= 12 is reachable without weakening the check. LAMP_SPECS
-- holds six street-post positions (the DayCycleLive Rendah lamp positions) and six hub torches:
-- 12 shadowless lights, below MAX_LIGHTS = 24. At clock 20 all panes/lights are lit; at clock 13
-- none is lit.

local Night = {}

Night.id = "night_r8"
Night.familyId = "night_r8"
Night.lookDevId = "night_r8"
Night.folder = "LookDevNightR8_night_r8"

Night.WINDOW_COLOR_HEX = "#FFCB7A"
Night.WINDOW_RGB = { 255, 203, 122 }
Night.WINDOW_MATERIAL = "Neon"
Night.DAY_WINDOW_MATERIAL = "Glass"
Night.DAY_WINDOW_RGB = { 186, 205, 214 }
Night.WINDOW_TRANSPARENCY = 0.12
Night.DAY_WINDOW_TRANSPARENCY = 0.35
Night.MAX_LIGHTS = 24
Night.GLOW_LIGHT_COUNT = 12
Night.LAMP_RANGE = 14
Night.GLOW_INTENSITY = 0.6
Night.NIGHT_ON = 18
Night.NIGHT_OFF = 6

local GROUND_Y = 0.5 -- MapSpec.GROUND_Y (server/World/Ground.luau)
local EAVE_OFFSET = 9.5 -- facade recipe: EAVE_UNDERSIDE - GROUND_Y
local SHUTTER_Y = GROUND_Y + EAVE_OFFSET - 4 -- facade window centre height
local SHUTTER_SIZE = { 3, 5, 0.4 }
local GLASS_OFFSET = 0.6 -- pane sits in front of the shutter, no z-fight

-- x, z, yaw copied from MapSpec.HUBS; gauge/footprint numbers copied from ModelMapFacadesR8.
local HUBS = {
	{ key = "pasar", x = -64, z = -64, yaw = 0, depth = 52, gaugeLx = 0, gaugeLz = 27, w = 6 },
	{ key = "gelap", x = -80, z = -120, yaw = 0, depth = 28, gaugeLx = 0, gaugeLz = 15, w = 6 },
	{ key = "warung", x = 68, z = -68, yaw = 0, depth = 44, gaugeLx = 0, gaugeLz = 23, w = 6 },
	{ key = "ronda", x = -108, z = 0, yaw = 90, depth = 40, gaugeLx = 0, gaugeLz = 17, w = 6 },
	{ key = "polisi", x = -68, z = 68, yaw = 180, depth = 44, gaugeLx = 0, gaugeLz = 23, w = 6 },
	{ key = "pakrt", x = 68, z = 68, yaw = 180, depth = 34, gaugeLx = -13, gaugeLz = 10.5, w = 7 },
}

local function rotate(cx: number, cz: number, yaw: number, lx: number, lz: number): (number, number)
	local a = math.rad(yaw)
	local cos, sin = math.cos(a), math.sin(a)
	return cx + lx * cos + lz * sin, cz - lx * sin + lz * cos
end

local WINDOW_SPECS: { any } = {}

local function addWindow(hub: any, lx: number, lz: number, y: number, size: { number }, source: string)
	local x, z = rotate(hub.x, hub.z, hub.yaw, lx, lz)
	WINDOW_SPECS[#WINDOW_SPECS + 1] = {
		x = x,
		y = y,
		z = z,
		size = { size[1], size[2], size[3] },
		orientation = hub.yaw,
		hubKey = hub.key,
		source = source,
	}
end

-- Two shutter-window panes per hub: facade recipe lx = gauge.lx +/- (w/2 + 6), lz = gauge.lz - 3.
for _, hub in ipairs(HUBS) do
	local shutterX = hub.w / 2 + 6
	for index, sign in ipairs({ -1, 1 }) do
		addWindow(
			hub,
			hub.gaugeLx + sign * shutterX,
			hub.gaugeLz - 3 + GLASS_OFFSET,
			SHUTTER_Y,
			SHUTTER_SIZE,
			if index == 1 then "FacadeShutteredWindow_L" else "FacadeShutteredWindow_R"
		)
	end
end

-- Four real WindowGlass parts on Pak RT (Greybox A/B blocks, yaw 180, y0 = GROUND_Y + 0.8).
local pakrt = HUBS[6]
for _, lx in ipairs({ -19, -7 }) do
	addWindow(pakrt, lx, 8.6 + 0.3 + GLASS_OFFSET, GROUND_Y + 0.8 + 17, { 3.6, 4.6, 0.2 }, "WindowGlass_A")
end
for _, lx in ipairs({ 5, 15 }) do
	addWindow(pakrt, lx, 6.6 + 0.3 + GLASS_OFFSET, GROUND_Y + 0.8 + 7, { 4.2, 4.2, 0.2 }, "WindowGlass_B")
end

Night.WINDOW_SPECS = WINDOW_SPECS
Night.MAX_WINDOWS = #WINDOW_SPECS

-- Six Rendah street-post positions from Shared.World.DayCycleLive.LAMP_POSITIONS, in hub order.
local STREET_POSITIONS = {
	{ -16, 3.2, 24 },
	{ 16, 3.2, 24 },
	{ -16, 3.2, 8 },
	{ 16, 3.2, 8 },
	{ 0, 3.2, 4 },
	{ 0, 3.2, 40 },
}

local LAMP_SPECS: { any } = {}
for index, hub in ipairs(HUBS) do
	local position = STREET_POSITIONS[index]
	LAMP_SPECS[#LAMP_SPECS + 1] = {
		id = "street_post_" .. hub.key,
		name = "LookDevNightR8_Post_" .. index,
		kind = "post",
		hubKey = hub.key,
		x = position[1],
		y = position[2],
		z = position[3],
	}
end
for index, hub in ipairs(HUBS) do
	local x, z = rotate(hub.x, hub.z, hub.yaw, 0, hub.depth / 2 + 4)
	LAMP_SPECS[#LAMP_SPECS + 1] = {
		id = "torch_" .. hub.key,
		name = "LookDevNightR8_Torch_" .. index,
		kind = "torch",
		hubKey = hub.key,
		x = x,
		y = GROUND_Y + Night.LAMP_RANGE * 0.8,
		z = z,
	}
end

Night.LAMP_SPECS = LAMP_SPECS

-- Night is clock >= 18 or < 6, the same gate smoke_r8 uses. 13 -> false, 20/5 -> true.
function Night.isNight(clock: any): boolean
	return type(clock) == "number"
		and clock == clock
		and clock > -math.huge
		and clock < math.huge
		and (clock >= Night.NIGHT_ON or clock < Night.NIGHT_OFF)
end

function Night.litWindowCount(clock: any): number
	return if Night.isNight(clock) then #WINDOW_SPECS else 0
end

function Night.litLightCount(clock: any): number
	return if Night.isNight(clock) then #LAMP_SPECS else 0
end

return Night
