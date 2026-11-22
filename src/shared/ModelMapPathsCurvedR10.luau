--!strict
-- ModelMapPathsCurvedR10: pure data for the OFF-BY-DEFAULT "paths_curved_r10" candidate
-- (WORK_QUEUE item 196 lane 1). Tone keys are STRINGS so this module needs no engine types. The
-- geometry is a conservative copy of MapSpec numbers (MapSpec is server-only and cannot be required
-- from shared); the server applier re-checks every painted cell at live voxel centres. Every path
-- is a serpentine spoke on the plot angle, painted Mud (8 studs wide) with a Ground shoulder, and
-- clipped by the plot-footprint / gate-box / river keep-outs so GATE_CLEAR and NO_CROSS hold by
-- construction.

local Game = require(script.Parent.Config.Game)

local Data = {}

Data.id = "paths_curved_r10"
Data.folderName = "LookDevPathsCurvedR10_paths_curved_r10"

Data.PATH_COUNT = 10
Data.CORE_HALF = 4 -- 8 studs wide
Data.SHOULDER = 1.5 -- blended shoulder on each side
Data.TONE_CORE = "Mud"
Data.TONE_SHOULDER = "Ground"
Data.GATE_RADIUS = 152
Data.PLOT_HALF = 24
Data.PLOT_RADIUS = Game.plotRadius
Data.RING_CENTRE = 144
Data.RING_WIDTH = 12

-- River centreline z = 304 + 12*sin(2*pi*x/320), half-width 14; bridge corridor x in [-5,5],
-- z in [276,332] is the only place a painted voxel may enter the channel.
Data.RIVER_BASE = 304
Data.RIVER_AMP = 12
Data.RIVER_WAVELENGTH = 320
Data.RIVER_HALF = 14
Data.BRIDGE_MIN_X, Data.BRIDGE_MAX_X = -5, 5
Data.BRIDGE_MIN_Z, Data.BRIDGE_MAX_Z = 276, 332

-- Control points live on the inner approach side of the gate box (r <= 148), so every one passes
-- zoneClear: the gate box is r in [149,155] and the nearest plot footprint starts at r >= 158.
Data.RADIUS_MIN = 110
Data.RADIUS_MAX = 148
Data.CONTROL_COUNT = 8 -- within the 6..10 range
Data.GATE_BOX_HALF = 3
Data.DEVIATION_MIN = 4
Data.DEVIATION_MAX = 12
Data.WORLD_SPAN = 208
Data.GRID_DEFAULT = 40

local function lcg(seed: number): () -> number
	local state = seed
	return function()
		state = (state * 16807) % 65521
		return (state - 1) / 65520
	end
end

local function distanceToSegment(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
	local dx, dz = bx - ax, bz - az
	local lengthSq = dx * dx + dz * dz
	local t = lengthSq > 0 and math.clamp(((px - ax) * dx + (pz - az) * dz) / lengthSq, 0, 1) or 0
	local cx, cz = ax + dx * t, az + dz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

function Data.riverCentreZ(x: number): number
	return Data.RIVER_BASE + Data.RIVER_AMP * math.sin(2 * math.pi * x / Data.RIVER_WAVELENGTH)
end

function Data.zoneClear(x: number, z: number): boolean
	for index = 1, Game.plotCount do
		local px, pz = Game.plotCenter(index)
		if math.abs(x - px) <= Data.PLOT_HALF and math.abs(z - pz) <= Data.PLOT_HALF then
			return false
		end
	end
	local radius = math.sqrt(x * x + z * z)
	if math.abs(radius - Data.GATE_RADIUS) <= Data.GATE_BOX_HALF then
		return false
	end
	if math.abs(z - Data.riverCentreZ(x)) <= Data.RIVER_HALF then
		local inBridge = x >= Data.BRIDGE_MIN_X
			and x <= Data.BRIDGE_MAX_X
			and z >= Data.BRIDGE_MIN_Z
			and z <= Data.BRIDGE_MAX_Z
		if not inBridge then
			return false
		end
	end
	return true
end

local function buildPaths(): { any }
	local rand = lcg(196)
	local paths = {}
	for index = 1, Data.PATH_COUNT do
		local angle = (index - 3) / Data.PATH_COUNT * math.pi * 2
		local amplitude = 8 + rand() * 3 -- 8..11 studs, always <= 12
		local sign = if rand() < 0.5 then 1 else -1
		local cosA, sinA = math.cos(angle), math.sin(angle)
		local points = {}
		for k = 0, Data.CONTROL_COUNT - 1 do
			local t = k / (Data.CONTROL_COUNT - 1)
			local radius = Data.RADIUS_MIN + t * (Data.RADIUS_MAX - Data.RADIUS_MIN)
			local offset = sign * amplitude * math.sin(2 * math.pi * t)
			points[k + 1] = { x = radius * cosA - offset * sinA, z = radius * sinA + offset * cosA }
		end
		local first, last = points[1], points[Data.CONTROL_COUNT]
		paths[index] = {
			index = index,
			plotIndex = index,
			angle = angle,
			points = points,
			straight = { ax = first.x, az = first.z, bx = last.x, bz = last.z },
		}
	end
	return paths
end

local PATHS = buildPaths()

function Data.paths(): { any }
	return PATHS
end

function Data.maxDeviation(pathIndex: number): number
	local path = PATHS[pathIndex]
	local s = path.straight
	local maximum = 0
	for _, point in ipairs(path.points) do
		local distance = distanceToSegment(point.x, point.z, s.ax, s.az, s.bx, s.bz)
		if distance > maximum then
			maximum = distance
		end
	end
	return maximum
end

local function pathDistance(path, x: number, z: number): number
	local points = path.points
	local minimum = math.huge
	for k = 1, #points - 1 do
		local a, b = points[k], points[k + 1]
		local distance = distanceToSegment(x, z, a.x, a.z, b.x, b.z)
		if distance < minimum then
			minimum = distance
		end
	end
	return minimum
end

function Data.paintAt(x: number, z: number): string?
	if not Data.zoneClear(x, z) then
		return nil
	end
	local best = math.huge
	local tone: string? = nil
	for _, path in ipairs(PATHS) do
		local distance = pathDistance(path, x, z)
		if distance <= Data.CORE_HALF + Data.SHOULDER and distance < best then
			best = distance
			tone = if distance <= Data.CORE_HALF then Data.TONE_CORE else Data.TONE_SHOULDER
		end
	end
	return tone
end

-- Per-path deviation of the PAINTED grid cells, mirrored by the Studio harness: only Mud/Ground
-- cells whose along-axis projection lies between the straight endpoints contribute.
function Data.paintedDeviation(cells: { any }, path): number
	local s = path.straight
	local dx, dz = s.bx - s.ax, s.bz - s.az
	local lengthSq = dx * dx + dz * dz
	local maximum = 0
	for _, cell in ipairs(cells) do
		if cell.tone == Data.TONE_CORE or cell.tone == Data.TONE_SHOULDER then
			-- A cell from a neighbouring spoke can project onto this chord's axis; only cells
			-- actually inside this path's painted band may contribute to its deviation.
			if pathDistance(path, cell.x, cell.z) <= Data.CORE_HALF + Data.SHOULDER + 0.001 then
				local t = ((cell.x - s.ax) * dx + (cell.z - s.az) * dz) / lengthSq
				if t >= 0 and t <= 1 then
					local distance = distanceToSegment(cell.x, cell.z, s.ax, s.az, s.bx, s.bz)
					if distance > maximum then
						maximum = distance
					end
				end
			end
		end
	end
	return maximum
end

function Data.sampleGrid(n: number?): { any }
	local count = n or Data.GRID_DEFAULT
	local step = Data.WORLD_SPAN * 2 / count
	local cells = {}
	for iz = 1, count do
		for ix = 1, count do
			local x = -Data.WORLD_SPAN + (ix - 0.5) * step
			local z = -Data.WORLD_SPAN + (iz - 0.5) * step
			cells[#cells + 1] = { x = x, z = z, tone = Data.paintAt(x, z), clear = Data.zoneClear(x, z) }
		end
	end
	return cells
end

do
	assert(Data.PATH_COUNT == #PATHS, "paths_curved_r10: path count is not 10")
	local grid = Data.sampleGrid(Data.GRID_DEFAULT)
	local curved, tones = 0, {}
	for _, path in ipairs(PATHS) do
		local pointCount = #path.points
		assert(pointCount >= 6 and pointCount <= 10, "paths_curved_r10: control point count outside 6..10")
		local deviation = Data.maxDeviation(path.index)
		assert(
			deviation >= Data.DEVIATION_MIN and deviation <= Data.DEVIATION_MAX,
			"paths_curved_r10: deviation outside 4..12"
		)
		for _, point in ipairs(path.points) do
			assert(Data.zoneClear(point.x, point.z), "paths_curved_r10: control point fails zoneClear")
		end
		if Data.paintedDeviation(grid, path) >= Data.DEVIATION_MIN then
			curved += 1
		end
	end
	assert(curved >= 6, "paths_curved_r10: fewer than 6 paths show >= 4 stud painted deviation")
	for _, cell in ipairs(grid) do
		if cell.tone ~= nil then
			assert(
				cell.tone == Data.TONE_CORE or cell.tone == Data.TONE_SHOULDER,
				"paths_curved_r10: unknown painted tone"
			)
			tones[cell.tone] = true
		end
	end
	assert(tones[Data.TONE_CORE] == true and tones[Data.TONE_SHOULDER] == true, "paths_curved_r10: grid misses a tone")
end

return Data
