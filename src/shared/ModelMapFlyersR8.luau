-- ModelMapFlyersR8: pure data + deterministic flight simulation for WORK_QUEUE section M item 83.
--
-- No game APIs, no Enum, no Instances: the caller passes a MapSpec-shaped table (the real
-- ServerScriptService.Server.World.MapSpec in the Studio harness) into spawn()/bounds(). Every
-- home band comes from that MapSpec geometry; only dimensionless offsets and speeds live here.
-- Tier names follow Client.Feel.FidelityTier (Rendah/Sedang/Tinggi); an unknown tier takes the
-- conservative Rendah cap. One pure step function advances every flyer, so the 60-second cost
-- check is reproducible in Lune without waiting real time. The client applier owns the Parts and
-- the single Heartbeat loop.

local Flyers = {}

Flyers.id = "flyers_r8"
Flyers.folder = "LookDevFlyersR8_flyers_r8"
Flyers.TIERS = { "Rendah", "Sedang", "Tinggi" }
Flyers.MAX_BIRD = 6
Flyers.MAX_KUPU = 10
Flyers.MAX_CAPUNG_BY_TIER = { Rendah = 4, Sedang = 6, Tinggi = 8 }
Flyers.SIM_SECONDS = 60
Flyers.MAX_STEP_MS = 0.3
Flyers.DT = 1 / 60
Flyers.MAX_DT = 0.25
Flyers.EDGE_MARGIN = 4
Flyers.BOUND_TOLERANCE = 0.05
Flyers.SKY_CLEARANCE = 16
Flyers.BIRD_HEIGHT = 8
Flyers.KUPU_HEIGHT = 3
Flyers.CAPUNG_HEIGHT = 1.6
Flyers.KINDS = { "burung", "kupu", "capung" }

-- Original Parts only: { name, size {x,y,z}, offset {x,y,z}, {r,g,b} }. Y offsets are measured up
-- from the flyer's position. No asset IDs, no mesh, no material names.
Flyers.PARTS = {
	burung = {
		{ "Body", { 0.9, 0.8, 2.2 }, { 0, 0, 0 }, { 62, 92, 142 } },
		{ "WingL", { 2.8, 0.12, 1.0 }, { -1.6, 0.2, 0 }, { 48, 72, 116 } },
		{ "WingR", { 2.8, 0.12, 1.0 }, { 1.6, 0.2, 0 }, { 48, 72, 116 } },
	},
	kupu = {
		{ "Body", { 0.4, 0.4, 1.3 }, { 0, 0, 0 }, { 232, 158, 68 } },
		{ "WingL", { 1.6, 0.08, 1.3 }, { -0.85, 0.1, 0 }, { 248, 206, 96 } },
		{ "WingR", { 1.6, 0.08, 1.3 }, { 0.85, 0.1, 0 }, { 248, 206, 96 } },
	},
	capung = {
		{ "Body", { 0.28, 0.28, 2.4 }, { 0, 0, 0 }, { 42, 136, 160 } },
		{ "WingL", { 1.5, 0.05, 0.5 }, { -0.8, 0.12, -0.2 }, { 198, 234, 240 } },
		{ "WingR", { 1.5, 0.05, 0.5 }, { 0.8, 0.12, -0.2 }, { 198, 234, 240 } },
	},
}

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

local function hashId(id: string): number
	local h = 11
	for i = 1, #id do
		h = (h * 131 + string.byte(id, i)) % 2147483647
	end
	return h == 0 and 1 or h
end

-- Park-Miller LCG. State is per flyer: no global math.random, no shared seed drift.
local function random(state): number
	state.seed = (state.seed * 48271) % 2147483647
	return state.seed / 2147483647
end

local function ridgeHeight(mapSpec): number
	local ridge = 0
	for _, hub in ipairs(mapSpec.HUBS or {}) do
		ridge = math.max(ridge, type(hub.ridge) == "number" and hub.ridge or 0)
	end
	return ridge
end

function Flyers.caps(tier)
	local capung = Flyers.MAX_CAPUNG_BY_TIER[tier]
	if type(capung) ~= "number" then
		capung = Flyers.MAX_CAPUNG_BY_TIER.Rendah
	end
	return { burung = Flyers.MAX_BIRD, kupu = Flyers.MAX_KUPU, capung = capung }
end

function Flyers.bounds(mapSpec)
	if type(mapSpec) ~= "table" or type(mapSpec.TERRAIN_HALF) ~= "number" or type(mapSpec.GROUND_Y) ~= "number" then
		return nil
	end
	return {
		minX = -mapSpec.TERRAIN_HALF,
		maxX = mapSpec.TERRAIN_HALF,
		minZ = -mapSpec.TERRAIN_HALF,
		maxZ = mapSpec.TERRAIN_HALF,
		minY = mapSpec.GROUND_Y,
		maxY = mapSpec.GROUND_Y + ridgeHeight(mapSpec) + Flyers.SKY_CLEARANCE,
	}
end

local function homeFor(kind: string, index: number, mapSpec)
	local ground = mapSpec.GROUND_Y
	if kind == "burung" then
		local plaza, road = mapSpec.PLAZA, mapSpec.ROAD
		if not plaza or not road then
			return nil
		end
		return {
			x = plaza.x,
			z = plaza.z,
			y = ground + ridgeHeight(mapSpec) + Flyers.BIRD_HEIGHT,
			radius = plaza.width / 2 + road.radius / 2,
			angle = 2 * math.pi * (index - 1) / Flyers.MAX_BIRD,
			dir = index % 2 == 0 and -1 or 1,
		}
	end
	if kind == "kupu" then
		local plaza, road = mapSpec.PLAZA, mapSpec.ROAD
		if not plaza or not road then
			return nil
		end
		if index <= 6 then
			-- Four plaza flower-bed corners from MapSpec.PLAZA/ROAD, no hand-typed world coords.
			local corners = { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
			local corner = corners[(index - 1) % #corners + 1]
			return {
				x = plaza.x + corner[1] * (plaza.width / 2 - road.halfWidth),
				z = plaza.z + corner[2] * (plaza.depth / 2 - road.halfWidth),
				y = ground + Flyers.KUPU_HEIGHT,
				radius = road.halfWidth,
			}
		end
		-- The remaining butterflies work the first sawah verge, from MapSpec's terrace lanes.
		local terrace = mapSpec.TERRACES and mapSpec.TERRACES[1]
		local side = mapSpec.TERRACE_SIDES and mapSpec.TERRACE_SIDES[1]
		if not terrace or not side then
			return nil
		end
		return {
			x = side.x1 - (index - 6) * (mapSpec.TERRACE_GAP / 10),
			z = terrace.z1 + 8,
			y = terrace.top + Flyers.KUPU_HEIGHT,
			radius = mapSpec.TERRACE_GAP / 8,
		}
	end
	if kind == "capung" then
		local bridge = mapSpec.BRIDGE
		if not bridge or type(mapSpec.riverCentreZ) ~= "function" then
			return nil
		end
		return {
			x = bridge.x,
			z = mapSpec.riverCentreZ(bridge.x),
			y = ground + Flyers.CAPUNG_HEIGHT,
			radius = bridge.width * (0.8 + 0.1 * (index % 3)),
			zOff = (index % 2 == 0 and 1 or -1) * (bridge.width / 2 + 3),
			riverZ = mapSpec.riverCentreZ,
		}
	end
	return nil
end

-- Target tables are mutated in place, so a 3600-step simulation allocates no per-step tables.
function Flyers.pickTarget(state, bounds)
	local margin = Flyers.EDGE_MARGIN
	local lowX = math.max(bounds.minX + margin, state.home.x - state.home.radius)
	local highX = math.min(bounds.maxX - margin, state.home.x + state.home.radius)
	local lowZ = math.max(bounds.minZ + margin, state.home.z - state.home.radius)
	local highZ = math.min(bounds.maxZ - margin, state.home.z + state.home.radius)
	state.target.x = lowX + (highX - lowX) * random(state)
	state.target.z = lowZ + (highZ - lowZ) * random(state)
	return state
end

function Flyers.spawn(mapSpec, tier)
	if type(mapSpec) ~= "table" then
		error("flyers_r8: MapSpec is required")
	end
	local builtBounds = Flyers.bounds(mapSpec)
	if not builtBounds then
		error("flyers_r8: MapSpec needs GROUND_Y and TERRAIN_HALF")
	end
	local cap = Flyers.caps(tier)
	local states = {}
	for _, kind in ipairs(Flyers.KINDS) do
		for index = 1, cap[kind] do
			local id = kind .. "_" .. index
			local home = homeFor(kind, index, mapSpec)
			if not home then
				error("flyers_r8: cannot derive a home band for " .. id)
			end
			local state = {
				id = id,
				kind = kind,
				home = home,
				position = { x = home.x, y = home.y, z = home.z },
				target = { x = home.x, y = home.y, z = home.z },
				seed = hashId(id),
				speed = kind == "burung" and 0.35 or if kind == "kupu" then 0.9 else 2.2,
				t = 0,
				angle = home.angle or 0,
				yaw = 0,
				wing = 0,
			}
			state.phase = random(state) * 2 * math.pi
			if state.kind == "burung" then
				local x = home.x + home.radius * math.cos(state.angle)
				local z = home.z + home.radius * math.sin(state.angle)
				state.position.x, state.position.z = x, z
				state.yaw = math.atan2(-(home.z - z), -(home.x - x))
			elseif state.kind == "kupu" then
				Flyers.pickTarget(state, builtBounds)
				state.position.x = state.target.x
				state.position.z = state.target.z
			else
				local x = home.x + home.radius * math.sin(state.phase)
				state.position.x = x
				state.position.z = home.riverZ(x) + home.zOff
			end
			states[#states + 1] = state
		end
	end
	return states
end

function Flyers.step(state, dt, bounds)
	local stepDt = clamp(type(dt) == "number" and dt or 0, 0, Flyers.MAX_DT)
	state.t += stepDt
	local p = state.position
	local home = state.home
	local wingHz = 4
	local wingAmp = 0.5
	if state.kind == "burung" then
		local previousX, previousZ = p.x, p.z
		state.angle += home.dir * state.speed * stepDt
		p.x = home.x + home.radius * math.cos(state.angle)
		p.z = home.z + home.radius * math.sin(state.angle)
		p.y = home.y + 0.8 * math.sin(state.t * 1.6 + state.phase)
		local dx, dz = p.x - previousX, p.z - previousZ
		if math.abs(dx) + math.abs(dz) > 1e-9 then
			state.yaw = math.atan2(-dx, -dz)
		end
	elseif state.kind == "kupu" then
		local dx, dz = state.target.x - p.x, state.target.z - p.z
		local distance = math.sqrt(dx * dx + dz * dz)
		local travel = state.speed * stepDt
		if distance <= travel or distance < 1e-6 then
			p.x, p.z = state.target.x, state.target.z
			Flyers.pickTarget(state, bounds)
			dx, dz = state.target.x - p.x, state.target.z - p.z
			distance = math.sqrt(dx * dx + dz * dz)
		else
			p.x += dx / distance * travel
			p.z += dz / distance * travel
		end
		if distance > 1e-6 then
			state.yaw = math.atan2(-dx, -dz)
		end
		p.y = home.y + 0.35 * math.sin(state.t * 3 + state.phase)
		wingHz, wingAmp = 10, 0.9
	else
		local previousX, previousZ = p.x, p.z
		p.x = home.x + home.radius * math.sin(state.t * state.speed + state.phase)
		p.z = home.riverZ(p.x) + home.zOff + 0.6 * math.sin(state.t * 2 + state.phase)
		p.y = home.y + 0.25 * math.sin(state.t * 2.4 + state.phase)
		local dx, dz = p.x - previousX, p.z - previousZ
		if math.abs(dx) + math.abs(dz) > 1e-9 then
			state.yaw = math.atan2(-dx, -dz)
		end
		wingHz, wingAmp = 16, 0.75
	end
	p.x = clamp(p.x, bounds.minX + Flyers.EDGE_MARGIN, bounds.maxX - Flyers.EDGE_MARGIN)
	p.z = clamp(p.z, bounds.minZ + Flyers.EDGE_MARGIN, bounds.maxZ - Flyers.EDGE_MARGIN)
	p.y = clamp(p.y, bounds.minY + 0.25, bounds.maxY - 0.25)
	state.wing = wingAmp * math.sin(state.t * wingHz + state.phase)
	return state
end

function Flyers.stepAll(states, dt, bounds)
	for _, state in ipairs(states) do
		Flyers.step(state, dt, bounds)
	end
	return states
end

-- Deterministic horizon. Mutates the supplied states and returns states, steps and os.clock cost.
function Flyers.simulate(states, seconds, dt, bounds)
	local steps = math.max(1, math.ceil(seconds / dt))
	local started = os.clock()
	for _ = 1, steps do
		Flyers.stepAll(states, dt, bounds)
	end
	return states, steps, os.clock() - started
end

function Flyers.kindCounts(states)
	local counts = {}
	for _, kind in ipairs(Flyers.KINDS) do
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

return Flyers
