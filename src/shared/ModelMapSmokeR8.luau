-- ModelMapSmokeR8: pure recipes for WORK_QUEUE section M item 84 (kitchen smoke, steam, fire).
-- No game APIs, no Enum, no Instances and no asset IDs: positions come from the caller's MapSpec
-- (the same module the server harness reads), with only dimensionless offsets defined here. The
-- client applier owns the Parts, ParticleEmitters, PointLights, Heartbeat and ClockTime signal.

local Smoke = {}

Smoke.id = "smoke_r8"
Smoke.folder = "LookDevSmokeR8_smoke_r8"

Smoke.MAX_EMITTERS = 12
Smoke.MAX_RATE = 12
Smoke.MAX_LIGHTS = 24
Smoke.MAX_RANGE = 30
Smoke.NIGHT_ON = 18
Smoke.NIGHT_OFF = 6

-- Matches DayCycleLive.lampBudget(tier).range (Rendah ceiling); lights stay well under MAX_LIGHTS.
Smoke.LAMP_RANGE = 14
Smoke.RATES = { chimney = 8, steam = 6, torch_flame = 10 }
Smoke.CHIMNEY_HUBS = { "warung", "pasar" }

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

local function hashId(id: string): number
	local h = 17
	for i = 1, #id do
		h = (h * 131 + string.byte(id, i)) % 2147483647
	end
	return h == 0 and 1 or h
end

-- Fresh tables per call. Missing MapSpec pieces raise instead of silently emitting fewer effects.
function Smoke.recipes(mapSpec)
	if type(mapSpec) ~= "table" or type(mapSpec.hub) ~= "function" or type(mapSpec.GROUND_Y) ~= "number" then
		error("smoke_r8: MapSpec with hub() and GROUND_Y is required")
	end
	local emitters, lights = {}, {}
	local ground = mapSpec.GROUND_Y

	-- Two kitchen chimneys, above the ridge of two real hub roofs.
	for index, key in ipairs(Smoke.CHIMNEY_HUBS) do
		local hub = mapSpec.hub(key)
		if not hub or type(hub.ridge) ~= "number" then
			error("smoke_r8: MapSpec is missing hub " .. tostring(key))
		end
		local side = index == 1 and -1 or 1
		emitters[#emitters + 1] = {
			id = "chimney_" .. key,
			kind = "chimney",
			position = hubPosition(mapSpec, hub, side * hub.width * 0.18, -hub.depth * 0.12, hub.ridge + 2),
			rate = Smoke.RATES.chimney,
			nightOnly = false,
		}
	end

	-- Steam rises off the real Warung counter anchor, never from a hand-typed world position.
	local warung = mapSpec.hub("warung")
	local anchor = warung and warung.anchor
	if not anchor then
		error("smoke_r8: MapSpec is missing the warung counter anchor")
	end
	emitters[#emitters + 1] = {
		id = "steam_warung",
		kind = "steam",
		position = hubPosition(mapSpec, warung, anchor.lx, anchor.lz, ground + anchor.sy + 1.2),
		rate = Smoke.RATES.steam,
		nightOnly = false,
	}

	-- One torch post per hub (MapSpec-derived front side). Each flame gets its own flickering light.
	local hubs = mapSpec.HUB_ORDER or mapSpec.HUBS or {}
	for _, hub in ipairs(hubs) do
		local key = type(hub) == "string" and hub or hub.key
		if type(key) == "string" then
			if type(hub) == "string" then
				hub = mapSpec.hub(key)
			end
			if not hub or type(hub.width) ~= "number" or type(hub.depth) ~= "number" then
				error("smoke_r8: MapSpec is missing hub " .. tostring(key))
			end
			local id = "torch_" .. key
			local position =
				hubPosition(mapSpec, hub, hub.width * 0.36, hub.depth * 0.5 + 4, ground + Smoke.LAMP_RANGE * 0.8)
			emitters[#emitters + 1] = {
				id = id .. "_flame",
				kind = "torch_flame",
				position = position,
				rate = Smoke.RATES.torch_flame,
				range = Smoke.LAMP_RANGE,
				nightOnly = true,
			}
			lights[#lights + 1] = {
				id = id .. "_light",
				position = position,
				range = Smoke.LAMP_RANGE,
				seed = hashId(id),
				nightOnly = true,
			}
		end
	end

	return { emitters = emitters, lights = lights }
end

function Smoke.emitterCount(built): number
	return type(built) == "table" and type(built.emitters) == "table" and #built.emitters or 0
end

function Smoke.lightCount(built): number
	return type(built) == "table" and type(built.lights) == "table" and #built.lights or 0
end

-- Night is clock >= 18 or < 6; ClockTime 13 is day, so torches are off there.
function Smoke.isNight(clockTime: any): boolean
	return type(clockTime) == "number"
		and clockTime == clockTime
		and (clockTime >= Smoke.NIGHT_ON or clockTime < Smoke.NIGHT_OFF)
end

-- Deterministic brightness multiplier in [0.7, 1.0]: slow sine + a smaller faster flutter.
function Smoke.flicker(t: any, seed: any): number
	local time = type(t) == "number" and t or 0
	local s = type(seed) == "number" and seed or 1
	local wave = 0.85 + 0.1 * math.sin(time * 6.3 + s * 0.37) + 0.05 * math.sin(time * 17.7 + s * 1.13)
	return math.max(0.7, math.min(1, wave))
end

function Smoke.kindCounts(emitters): { [string]: number }
	local counts = { chimney = 0, steam = 0, torch_flame = 0 }
	for _, emitter in ipairs(emitters or {}) do
		counts[emitter.kind] = (counts[emitter.kind] or 0) + 1
	end
	return counts
end

return Smoke
