-- ModelMapAnimalsR8: pure data + deterministic wander simulation for WORK_QUEUE section M item 82.
--
-- No game APIs, no Enum, no Instances: the caller passes a MapSpec-shaped table (the real
-- Server.World.MapSpec in the Studio harness) into spawn()/bounds(). Every home band comes from
-- that MapSpec geometry; only dimensionless offsets and speeds live here. One pure step function
-- advances all animals, so the 60-second bounds and os.clock cost checks are reproducible in Lune
-- without waiting real time. The client applier owns the Parts and the single Heartbeat loop.

local Animals = {}

Animals.id = "animals_r8"
Animals.folder = "LookDevAnimalsR8_animals_r8"
Animals.MAX_ANIMALS = 14
Animals.SIM_SECONDS = 60
Animals.MAX_STEP_MS = 0.3
Animals.DT = 1 / 60
Animals.MAX_DT = 0.25
Animals.EDGE_MARGIN = 4
Animals.BOUND_TOLERANCE = 0.05
Animals.ROOF_CLEARANCE = 4
Animals.KINDS = { "ayam", "bebek", "kambing", "kucing" }
Animals.COUNT = { ayam = 4, bebek = 4, kambing = 2, kucing = 1 }
Animals.SPEED = { ayam = 1.6, bebek = 1.1, kambing = 0.8, kucing = 0.25 }

-- Simple original parts: { name, size {x,y,z}, offset {x,y,z}, {r,g,b} }. Y offsets are measured up
-- from the animal's ground-relative position. No asset IDs, no mesh, no material names.
Animals.PARTS = {
	ayam = {
		{ "Body", { 1.8, 1.2, 2.4 }, { 0, 1.1, 0 }, { 232, 222, 190 } },
		{ "Head", { 0.9, 0.9, 0.9 }, { 0, 2.0, -1.1 }, { 240, 232, 205 } },
		{ "Beak", { 0.3, 0.25, 0.5 }, { 0, 1.9, -1.65 }, { 232, 150, 54 } },
		{ "Tail", { 0.3, 0.9, 0.9 }, { 0, 1.7, 1.35 }, { 208, 188, 148 } },
		{ "LegL", { 0.16, 0.9, 0.16 }, { -0.5, 0.45, 0 }, { 224, 146, 58 } },
		{ "LegR", { 0.16, 0.9, 0.16 }, { 0.5, 0.45, 0 }, { 224, 146, 58 } },
	},
	bebek = {
		{ "Body", { 1.8, 1.2, 2.8 }, { 0, 1.1, 0 }, { 246, 226, 130 } },
		{ "Head", { 0.9, 0.9, 0.9 }, { 0, 2.0, -1.3 }, { 248, 232, 158 } },
		{ "Beak", { 0.5, 0.22, 0.7 }, { 0, 1.9, -1.9 }, { 228, 150, 48 } },
		{ "Tail", { 0.4, 0.6, 0.8 }, { 0, 1.6, 1.6 }, { 232, 208, 120 } },
		{ "LegL", { 0.16, 0.8, 0.16 }, { -0.5, 0.4, 0.3 }, { 230, 144, 46 } },
		{ "LegR", { 0.16, 0.8, 0.16 }, { 0.5, 0.4, 0.3 }, { 230, 144, 46 } },
	},
	kambing = {
		{ "Body", { 2.4, 1.6, 3.2 }, { 0, 1.7, 0 }, { 176, 142, 104 } },
		{ "Head", { 1.1, 1.1, 1.3 }, { 0, 2.6, -1.9 }, { 190, 156, 116 } },
		{ "HornL", { 0.14, 0.6, 0.14 }, { -0.4, 3.3, -2.0 }, { 220, 208, 176 } },
		{ "HornR", { 0.14, 0.6, 0.14 }, { 0.4, 3.3, -2.0 }, { 220, 208, 176 } },
		{ "Tail", { 0.2, 0.6, 0.5 }, { 0, 2.0, 1.8 }, { 172, 136, 98 } },
		{ "LegFL", { 0.22, 1.2, 0.22 }, { -0.7, 0.6, -1.0 }, { 158, 124, 92 } },
		{ "LegFR", { 0.22, 1.2, 0.22 }, { 0.7, 0.6, -1.0 }, { 158, 124, 92 } },
		{ "LegBL", { 0.22, 1.2, 0.22 }, { -0.7, 0.6, 1.0 }, { 158, 124, 92 } },
		{ "LegBR", { 0.22, 1.2, 0.22 }, { 0.7, 0.6, 1.0 }, { 158, 124, 92 } },
	},
	kucing = {
		{ "Body", { 1.2, 1.0, 2.0 }, { 0, 0.9, 0 }, { 120, 118, 116 } },
		{ "Head", { 0.9, 0.9, 0.9 }, { 0, 1.6, -1.0 }, { 134, 132, 130 } },
		{ "EarL", { 0.22, 0.4, 0.22 }, { -0.3, 2.1, -1.0 }, { 110, 108, 106 } },
		{ "EarR", { 0.22, 0.4, 0.22 }, { 0.3, 2.1, -1.0 }, { 110, 108, 106 } },
		{ "Tail", { 0.18, 0.18, 1.2 }, { 0, 1.2, 1.5 }, { 110, 108, 106 } },
		{ "LegFL", { 0.16, 0.6, 0.16 }, { -0.35, 0.3, -0.6 }, { 116, 114, 112 } },
		{ "LegFR", { 0.16, 0.6, 0.16 }, { 0.35, 0.3, -0.6 }, { 116, 114, 112 } },
		{ "LegBL", { 0.16, 0.6, 0.16 }, { -0.35, 0.3, 0.6 }, { 116, 114, 112 } },
		{ "LegBR", { 0.16, 0.6, 0.16 }, { 0.35, 0.3, 0.6 }, { 116, 114, 112 } },
	},
}

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

local function hashId(id: string): number
	local h = 7
	for i = 1, #id do
		h = (h * 131 + string.byte(id, i)) % 2147483647
	end
	return h == 0 and 1 or h
end

-- Park-Miller LCG. State is per animal: no global math.random, no shared seed drift.
local function random(state): number
	state.seed = (state.seed * 48271) % 2147483647
	return state.seed / 2147483647
end

function Animals.bounds(mapSpec)
	if type(mapSpec) ~= "table" or type(mapSpec.TERRAIN_HALF) ~= "number" or type(mapSpec.GROUND_Y) ~= "number" then
		return nil
	end
	local ridge = 0
	for _, hub in ipairs(mapSpec.HUBS or {}) do
		ridge = math.max(ridge, type(hub.ridge) == "number" and hub.ridge or 0)
	end
	return {
		minX = -mapSpec.TERRAIN_HALF,
		maxX = mapSpec.TERRAIN_HALF,
		minZ = -mapSpec.TERRAIN_HALF,
		maxZ = mapSpec.TERRAIN_HALF,
		minY = mapSpec.GROUND_Y,
		maxY = mapSpec.GROUND_Y + ridge + Animals.ROOF_CLEARANCE,
	}
end

local function homeFor(kind: string, index: number, mapSpec)
	local ground = mapSpec.GROUND_Y
	local warung = type(mapSpec.hub) == "function" and mapSpec.hub("warung") or nil
	if kind == "ayam" then
		if not warung or type(mapSpec.hubPoint) ~= "function" then
			return nil
		end
		local lx = (index - (Animals.COUNT.ayam + 1) / 2) * (warung.width / 8)
		local lz = warung.depth / 2 + 6 + (index % 2) * 2
		local x, z = mapSpec.hubPoint(warung, lx, lz)
		return { x = x, y = ground, z = z, radius = warung.width / 5 }
	end
	if kind == "bebek" then
		local bridge = mapSpec.BRIDGE
		if not bridge or type(mapSpec.riverCentreZ) ~= "function" then
			return nil
		end
		local x = bridge.x + (index - (Animals.COUNT.bebek + 1) / 2) * bridge.width
		local bank = bridge.width / 2 + 5
		local z = mapSpec.riverCentreZ(x) + ((index % 2 == 0) and bank or -bank)
		return { x = x, y = ground, z = z, radius = bridge.width / 2 }
	end
	if kind == "kambing" then
		local terrace = mapSpec.TERRACES and mapSpec.TERRACES[1]
		local side = mapSpec.TERRACE_SIDES and mapSpec.TERRACE_SIDES[1]
		if not terrace or not side then
			return nil
		end
		local x = side.x1 - index * (mapSpec.TERRACE_GAP / 3)
		return { x = x, y = ground, z = terrace.z1 + 12, radius = mapSpec.TERRACE_GAP / 6 }
	end
	if kind == "kucing" then
		if not warung or type(mapSpec.hubPoint) ~= "function" then
			return nil
		end
		local x, z = mapSpec.hubPoint(warung, warung.width / 5, 0)
		return { x = x, y = ground + warung.ridge - 2, z = z, radius = 2 }
	end
	return nil
end

-- Target tables are mutated in place, so a 3600-step simulation allocates no per-step tables.
function Animals.pickTarget(state, bounds)
	local margin = Animals.EDGE_MARGIN
	local lowX = math.max(bounds.minX + margin, state.home.x - state.home.radius)
	local highX = math.min(bounds.maxX - margin, state.home.x + state.home.radius)
	local lowZ = math.max(bounds.minZ + margin, state.home.z - state.home.radius)
	local highZ = math.min(bounds.maxZ - margin, state.home.z + state.home.radius)
	state.target.x = lowX + (highX - lowX) * random(state)
	state.target.z = lowZ + (highZ - lowZ) * random(state)
	state.target.y = state.home.y
	return state
end

function Animals.spawn(mapSpec)
	if type(mapSpec) ~= "table" then
		error("animals_r8: MapSpec is required")
	end
	local bounds = Animals.bounds(mapSpec)
	if not bounds then
		error("animals_r8: MapSpec needs GROUND_Y and TERRAIN_HALF")
	end
	local states = {}
	for _, kind in ipairs(Animals.KINDS) do
		for index = 1, Animals.COUNT[kind] do
			local id = kind .. "_" .. index
			local home = homeFor(kind, index, mapSpec)
			if not home then
				error("animals_r8: cannot derive a home band for " .. id)
			end
			local state = {
				id = id,
				kind = kind,
				home = home,
				position = { x = home.x, y = home.y, z = home.z },
				target = { x = home.x, y = home.y, z = home.z },
				seed = hashId(id),
				speed = Animals.SPEED[kind],
				t = 0,
				yaw = 0,
				bob = 0,
			}
			Animals.pickTarget(state, bounds)
			local dx, dz = state.target.x - home.x, state.target.z - home.z
			if math.abs(dx) + math.abs(dz) > 1e-6 then
				state.yaw = math.atan2(-dx, -dz)
			end
			state.baseYaw = state.yaw
			states[#states + 1] = state
		end
	end
	return states
end

function Animals.step(state, dt, bounds)
	local stepDt = clamp(type(dt) == "number" and dt or 0, 0, Animals.MAX_DT)
	state.t += stepDt
	local dx, dz = state.target.x - state.position.x, state.target.z - state.position.z
	local distance = math.sqrt(dx * dx + dz * dz)
	local travel = state.speed * stepDt
	if distance <= travel or distance < 1e-6 then
		state.position.x = state.target.x
		state.position.z = state.target.z
		Animals.pickTarget(state, bounds)
		dx, dz = state.target.x - state.position.x, state.target.z - state.position.z
		distance = math.sqrt(dx * dx + dz * dz)
	else
		state.position.x += dx / distance * travel
		state.position.z += dz / distance * travel
	end
	state.position.x = clamp(state.position.x, bounds.minX + Animals.EDGE_MARGIN, bounds.maxX - Animals.EDGE_MARGIN)
	state.position.z = clamp(state.position.z, bounds.minZ + Animals.EDGE_MARGIN, bounds.maxZ - Animals.EDGE_MARGIN)

	local bob = 0
	if state.kind == "ayam" then
		bob = 0.12 * (1 - math.abs(math.sin(state.t * 4 + state.seed * 0.01)))
	elseif state.kind == "kucing" then
		state.yaw = state.baseYaw + 0.08 * math.sin(state.t * 1.4)
	end
	if state.kind ~= "kucing" and distance > 1e-6 then
		state.yaw = math.atan2(-dx, -dz)
	end
	state.bob = bob
	state.position.y = clamp(state.home.y + bob, bounds.minY, bounds.maxY)
	return state
end

function Animals.stepAll(states, dt, bounds)
	for _, state in ipairs(states) do
		Animals.step(state, dt, bounds)
	end
	return states
end

-- Deterministic horizon. Mutates the supplied states and returns them with the step count.
function Animals.simulate(states, seconds, dt, bounds)
	local steps = math.max(1, math.ceil(seconds / dt))
	for _ = 1, steps do
		Animals.stepAll(states, dt, bounds)
	end
	return states, steps
end

function Animals.kindCounts(states)
	local counts = {}
	for _, kind in ipairs(Animals.KINDS) do
		counts[kind] = 0
	end
	for _, state in ipairs(states) do
		if counts[state.kind] == nil then
			counts[state.kind] = 0
		end
		counts[state.kind] += 1
	end
	return counts
end

return Animals
