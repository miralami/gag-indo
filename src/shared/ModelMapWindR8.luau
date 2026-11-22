-- ModelMapWindR8: pure data for WORK_QUEUE section M item 85 (gentle wind and sway).
-- No engine APIs, no instances and no asset IDs: every world position comes from the caller's
-- MapSpec, with only dimensionless offsets defined here. The client applier owns all mutation.

local Wind = {}

Wind.id = "wind_r8"
Wind.folder = "LookDevWindR8_wind_r8"

Wind.MAX_WIND = 12
Wind.MAX_TWEENS = 30
Wind.MAX_TILT_DEG = 4
Wind.TILT_SPEED = 0.45 -- rad/s: a full lean cycle is about 14 s

local BREEZE = { x = 2.5, y = 0, z = 1.5 }
local LAUNDRY_HUBS = { "warung", "pakrt" }
local SIGN_HUBS = { "pasar", "warung", "ronda", "polisi" }
local TILT_HUBS = { "warung", "pasar", "pakrt" }
local CLOTHS_PER_LINE = 3

function Wind.magnitude(v: any?): number
	if type(v) ~= "table" or type(v.x) ~= "number" or type(v.y) ~= "number" or type(v.z) ~= "number" then
		return 0
	end
	return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

-- Non-zero gentle breeze, comfortably under MAX_WIND. Fresh table per call.
function Wind.windVector(): { x: number, y: number, z: number }
	return { x = BREEZE.x, y = BREEZE.y, z = BREEZE.z }
end

local function hubPosition(mapSpec, hub, localX: number, localZ: number, y: number)
	local x, z
	if type(mapSpec.hubPoint) == "function" then
		x, z = mapSpec.hubPoint(hub, localX, localZ)
	elseif type(mapSpec.rotatePoint) == "function" then
		x, z = mapSpec.rotatePoint(hub.x, hub.z, hub.yaw, localX, localZ)
	else
		x, z = hub.x + localX, hub.z + localZ
	end
	return { x = x, y = y, z = z }
end

local function requireMapSpec(mapSpec)
	if type(mapSpec) ~= "table" or type(mapSpec.hub) ~= "function" or type(mapSpec.GROUND_Y) ~= "number" then
		error("wind_r8: MapSpec with hub() and GROUND_Y is required")
	end
end

local function hubFor(mapSpec, key: string)
	local hub = mapSpec.hub(key)
	if not hub or type(hub.width) ~= "number" or type(hub.depth) ~= "number" then
		error("wind_r8: MapSpec is missing hub " .. tostring(key))
	end
	return hub
end

-- One spec per swaying target: jemuran cloth pieces and hanging sign boards. Fresh tables per call.
function Wind.tweenPlan(mapSpec): { any }
	requireMapSpec(mapSpec)
	local plan = {}
	local ground = mapSpec.GROUND_Y

	for _, key in ipairs(LAUNDRY_HUBS) do
		local hub = hubFor(mapSpec, key)
		local lineId = "jemuran_" .. key
		local y = ground + (type(hub.ridge) == "number" and hub.ridge or 24) * 0.45
		for index = 1, CLOTHS_PER_LINE do
			plan[#plan + 1] = {
				id = lineId .. "_" .. index,
				kind = "laundry",
				lineId = lineId,
				position = hubPosition(mapSpec, hub, (index - 2) * 1.6, hub.depth * 0.5 + 4, y),
				amplitudeDeg = 6 + index * 0.5,
				duration = 2.4 + index * 0.2,
			}
		end
	end

	for index, key in ipairs(SIGN_HUBS) do
		local hub = hubFor(mapSpec, key)
		plan[#plan + 1] = {
			id = "sign_" .. key,
			kind = "sign",
			lineId = "sign_" .. key,
			position = hubPosition(
				mapSpec,
				hub,
				hub.width * 0.28,
				hub.depth * 0.5 + 3,
				ground + (type(hub.ridge) == "number" and hub.ridge or 20) * 0.55
			),
			amplitudeDeg = 4 + index * 0.4,
			duration = 3 + index * 0.25,
		}
	end

	if #plan > Wind.MAX_TWEENS then
		error("wind_r8: tween plan exceeds MAX_TWEENS")
	end
	return plan
end

-- Pisang and bamboo models to tilt. All maxDeg values equal MAX_TILT_DEG so tiltFor() stays in band.
function Wind.tiltPlan(mapSpec): { any }
	requireMapSpec(mapSpec)
	local plan = {}
	for index, key in ipairs(TILT_HUBS) do
		local hub = hubFor(mapSpec, key)
		for speciesIndex, species in ipairs({ "pisang", "bambu" }) do
			local side = speciesIndex == 1 and -1 or 1
			plan[#plan + 1] = {
				id = "tilt_" .. key .. "_" .. species,
				species = species,
				position = hubPosition(mapSpec, hub, side * hub.width * 0.34, hub.depth * 0.5 + 8, mapSpec.GROUND_Y),
				maxDeg = Wind.MAX_TILT_DEG,
				seed = index * 2 + speciesIndex,
			}
		end
	end
	return plan
end

-- Deterministic slow sine, in degrees, clamped to the shared tilt ceiling.
function Wind.tiltFor(seed: any, t: any): number
	local phase = type(seed) == "number" and seed or 1
	local time = type(t) == "number" and t or 0
	local angle = Wind.MAX_TILT_DEG * math.sin(time * Wind.TILT_SPEED + phase * 1.7)
	return math.max(-Wind.MAX_TILT_DEG, math.min(Wind.MAX_TILT_DEG, angle))
end

return Wind
