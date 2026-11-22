--!strict
-- ModelMapAmbientWalkersR8: PURE data + deterministic 90 s walk simulation for WORK_QUEUE item 88
-- (`ambient_walkers_r8`). No engine APIs, no Instances, no Enum: this file runs unchanged under
-- Lune. The real rigs are driven in Studio by the server applier calling the REAL
-- `NpcWalk.walkTo(rig, target, WALK_SPEED, cancelFn)` in a task.spawn loop.
--
-- WHY THE 90 s CHECK IS A PURE SIM: NpcWalk yields via task.wait(0.05) every step, so a 90-second
-- walk is 1800 real yields (~90 real seconds of wall clock) and cannot be pumped synchronously in
-- an execute_luau call. `simulate()` below mirrors NpcWalk's exact step math (linear lerp toward
-- the current waypoint at WALK_SPEED * STEP_SECONDS, ARRIVAL_EPS snap, waypoint wrap, 0.05-stud
-- stall threshold) and steps it 1800 times instantly. The Studio harness separately runs the real
-- loop for a short live interval (WALKER_MOVE) to prove the applier is actually wired to NpcWalk.

local M = {}

M.id = "ambient_walkers_r8"
M.familyId = "ambient_walkers_r8"
M.lookDevId = "ambient_walkers_r8"
M.folder = "LookDevAmbientWalkersR8_ambient_walkers_r8"

M.MAX_WALKERS = 8
M.WALK_SPEED = 6 -- studs/s; the brief caps Humanoid.WalkSpeed at 8
M.STEP_SECONDS = 0.05 -- NpcWalk STEP_SECONDS
M.SIM_SECONDS = 90
M.ARRIVAL_EPS = 0.5 -- NpcWalk ARRIVE_EPSILON
M.MAX_STUCK_SECONDS = 10
M.MAX_ROAD_DEVIATION = 8
M.GROUND_Y = 0.5
M.STUCK_EPSILON = 0.05 -- NpcWalk's per-step stall threshold

-- Road corridor constants mirrored from MapSpec (server-only, so it cannot be required here).
local ARM_HALF = 14
local ARM_WEST = -86
local ARM_EAST = 136
local ARM_NORTH = -136
local ARM_SOUTH = 136
local PLAZA_HALF_X = 48
local PLAZA_HALF_Z = 42
local RING_CENTRE = 144
local RING_HALF = 6
local LINK_HALF = 8
local LINK_NORTH = -300
local LINK_SOUTH = 276
local RING_GAP_START = 222
local RING_GAP_END = 246

local function rectDistance(x: number, z: number, minX: number, maxX: number, minZ: number, maxZ: number): number
	local dx = math.max(minX - x, 0, x - maxX)
	local dz = math.max(minZ - z, 0, z - maxZ)
	return math.sqrt(dx * dx + dz * dz)
end

-- PURE distance from a point to the nearest road CORRIDOR, 0 when inside one. The rectangles are
-- MapSpec's X arms (|z|<=14, x -86..136), Z arms (|x|<=14, z -136..136), the plaza square, the two
-- 16-wide continuations and the 12-wide connector ring (minus its 222..246 degree gap).
function M.distanceToRoad(x: number, z: number): number
	local best = math.huge
	best = math.min(best, rectDistance(x, z, ARM_WEST, ARM_EAST, -ARM_HALF, ARM_HALF))
	best = math.min(best, rectDistance(x, z, -ARM_HALF, ARM_HALF, ARM_NORTH, ARM_SOUTH))
	best = math.min(best, rectDistance(x, z, -PLAZA_HALF_X, PLAZA_HALF_X, -PLAZA_HALF_Z, PLAZA_HALF_Z))
	best = math.min(best, rectDistance(x, z, -LINK_HALF, LINK_HALF, LINK_NORTH, -RING_CENTRE - RING_HALF))
	best = math.min(best, rectDistance(x, z, -LINK_HALF, LINK_HALF, RING_CENTRE + RING_HALF, LINK_SOUTH))
	local radius = math.sqrt(x * x + z * z)
	local degrees = (math.deg(math.atan2(z, x)) + 360) % 360
	if not (degrees >= RING_GAP_START and degrees <= RING_GAP_END) then
		best = math.min(best, math.abs(radius - RING_CENTRE) - RING_HALF)
	end
	return math.max(0, best)
end

local function wp(x: number, z: number): { x: number, y: number, z: number }
	return { x = x, y = M.GROUND_Y, z = z }
end

-- Eight looped routes, all on road centrelines with a +/-3 or +/-6 lane offset (well inside the
-- 14-stud arm halfwidth). Each list wraps: after the last waypoint the walker heads back to the
-- first. The two long cross routes traverse the whole village; the six short ones approach the
-- named hubs along the arm that faces them.
local ROUTES = {
	{ name = "cross_ew", waypoints = { wp(-86, 3), wp(0, 3), wp(136, 3), wp(0, 3) } },
	{ name = "cross_ns", waypoints = { wp(3, -136), wp(3, 0), wp(3, 136), wp(3, 0) } },
	{ name = "pasar_approach", waypoints = { wp(-86, -3), wp(-64, -3), wp(-40, -3), wp(-64, -3) } },
	{ name = "warung_approach", waypoints = { wp(40, -6), wp(68, -6), wp(100, -6), wp(68, -6) } },
	{ name = "polisi_approach", waypoints = { wp(-86, 6), wp(-68, 6), wp(-40, 6), wp(-68, 6) } },
	{ name = "pakrt_approach", waypoints = { wp(40, 6), wp(68, 6), wp(100, 6), wp(68, 6) } },
	{ name = "ronda_approach", waypoints = { wp(-6, -100), wp(-6, -70), wp(-6, -40), wp(-6, -70) } },
	{ name = "gelap_approach", waypoints = { wp(6, 60), wp(6, 90), wp(6, 120), wp(6, 90) } },
}

function M.routes(): { { name: string, waypoints: { { x: number, y: number, z: number } } } }
	local copy = {}
	for index, route in ipairs(ROUTES) do
		local waypoints = {}
		for wpIndex, point in ipairs(route.waypoints) do
			waypoints[wpIndex] = { x = point.x, y = point.y, z = point.z }
		end
		copy[index] = { name = route.name, waypoints = waypoints }
	end
	return copy
end

-- Deterministic mirror of NpcWalk.walkTo's step math for the full horizon. Never mutates `walkers`.
-- Returns one result per walker plus the aggregate minima/maxima the Studio checks emit.
function M.simulate(seconds: number?, walkers: any?): any
	local horizon = type(seconds) == "number" and (seconds :: number) or M.SIM_SECONDS
	local list = if type(walkers) == "table" then walkers :: any else M.routes()
	local steps = math.max(0, math.floor(horizon / M.STEP_SECONDS + 1e-9))
	local travel = M.WALK_SPEED * M.STEP_SECONDS
	local results = {}

	for index, route in ipairs(list) do
		local waypoints = route.waypoints
		local first = waypoints[1]
		local x, y, z = first.x, first.y, first.z
		local targetIndex = 2
		local reached, stalled, maxStuck = 0, 0, 0
		local maxDeviation = M.distanceToRoad(x, z)

		for _ = 1, steps do
			local target = waypoints[targetIndex]
			local dx, dz = target.x - x, target.z - z
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance <= M.ARRIVAL_EPS then
				-- NpcWalk snaps exactly onto the goal and the caller advances the waypoint.
				reached += 1
				x, y, z = target.x, target.y, target.z
				targetIndex = targetIndex % #waypoints + 1
			else
				local move = math.min(travel, distance)
				x += dx / distance * move
				z += dz / distance * move
				y += (target.y - y) * math.min(1, move / distance)
				if move < M.STUCK_EPSILON then
					stalled += M.STEP_SECONDS
				else
					stalled = 0
				end
				if stalled > maxStuck then
					maxStuck = stalled
				end
			end
			local deviation = M.distanceToRoad(x, z)
			if deviation > maxDeviation then
				maxDeviation = deviation
			end
		end

		results[index] = {
			name = route.name,
			waypointsReached = reached,
			maxStuckSeconds = maxStuck,
			maxRoadDeviation = maxDeviation,
			finalPos = { x = x, y = y, z = z },
		}
	end

	local minReached, worstStuck, worstDeviation = math.huge, 0, 0
	for _, result in ipairs(results) do
		if result.waypointsReached < minReached then
			minReached = result.waypointsReached
		end
		if result.maxStuckSeconds > worstStuck then
			worstStuck = result.maxStuckSeconds
		end
		if result.maxRoadDeviation > worstDeviation then
			worstDeviation = result.maxRoadDeviation
		end
	end
	if minReached == math.huge then
		minReached = 0
	end

	return {
		walkers = results,
		minWaypointsReached = minReached,
		maxStuckSeconds = worstStuck,
		maxRoadDeviation = worstDeviation,
		steps = steps,
		seconds = horizon,
	}
end

return M
