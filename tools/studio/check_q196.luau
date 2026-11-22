--!nocheck
-- check_q196: WORK_QUEUE section Q item 196 lane 1, self-contained SERVER-VM Studio check. Paste
-- this whole file into execute_luau in a fresh Play session. It snapshots terrain voxels BEFORE
-- staging paths_curved_r10 with enableAdditive, re-reads the same region and prints verbatim
-- CHECK lines, then restores with disableAll() in the same call. No harness require, no place save,
-- no visual verdict. Voxel APIs here need SCALAR res 4, data indexed [x][y][z], and ReadVoxels'
-- third (water) return is nil on this VM.
--
--   PATH_REACH  16/16 PathfindingService routes: spawn -> 6 live MapSpec hub doors + 10 plot gates
--   PATH_CURVE  >=6 of 10 painted paths deviate >=4 studs from their straight chord
--   GATE_CLEAR  0 changed-to-Mud/Ground voxel centres in a plot footprint or gate box
--   NO_CROSS    0 changed-to-Mud/Ground voxel centres in the river channel outside the bridge
--
-- CALIBRATION ANCHORS: `local snapshot = readVoxels()` (BEFORE) and `local after = readVoxels()`
-- are separate single lines so a BEFORE/AFTER mismatch can be injected between them.

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local GRID = 40
local SPAN = 208
local VOXEL = 4 -- scalar resolution; Vector3.new(4,4,4) throws in Terrain:ReadVoxels
local MIN, MAX = -208, 208 -- 416 / 4 = 104 voxels per axis, grid-aligned (X + the path grid)
-- The river centreline is z ~= 292..316. Cover it so NO_CROSS can actually sample a river voxel;
-- paths live at r <= 148, so no baseline paint lands there, but a bad path could.
local MAX_Z = 340 -- (340 - (-208)) / 4 = 137 z-voxels
local Y_MIN, Y_MAX = -12, 20 -- 8 voxel layers
local PLOT_COUNT, GATE_RADIUS, PLOT_HALF, GATE_BOX_HALF = 10, 152, 24, 3
local RIVER_BASE, RIVER_AMP, RIVER_WAVELENGTH, RIVER_HALF = 304, 12, 320, 14
local BRIDGE_MIN_X, BRIDGE_MAX_X, BRIDGE_MIN_Z, BRIDGE_MAX_Z = -5, 5, 276, 332
local CORE_HALF, SHOULDER = 4, 1.5

local function riverCentreZ(x)
	return RIVER_BASE + RIVER_AMP * math.sin(2 * math.pi * x / RIVER_WAVELENGTH)
end

local function distanceToSegment(px, pz, ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	local lengthSq = dx * dx + dz * dz
	local t = lengthSq > 0 and math.clamp(((px - ax) * dx + (pz - az) * dz) / lengthSq, 0, 1) or 0
	local cx, cz = ax + dx * t, az + dz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

-- mats is indexed [x][y][z]; the second ReadVoxels return is occupancy, the third (water) is nil.
local function readVoxels()
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		return nil
	end
	local okRegion, region = pcall(function()
		return Region3.new(Vector3.new(MIN, Y_MIN, MIN), Vector3.new(MAX, Y_MAX, MAX_Z))
	end)
	if not okRegion or not region then
		return nil
	end
	local okRead, materials = pcall(function()
		return terrain:ReadVoxels(region, VOXEL)
	end)
	if not okRead or type(materials) ~= "table" or #materials == 0 then
		return nil
	end
	return materials
end

local function materialAt(mats, x, z)
	if type(mats) ~= "table" then
		return nil
	end
	local ix, iz = math.floor((x - MIN) / VOXEL) + 1, math.floor((z - MIN) / VOXEL) + 1
	if ix < 1 or ix > (MAX - MIN) / VOXEL or iz < 1 or iz > (MAX_Z - MIN) / VOXEL then
		return nil
	end
	local column = mats[ix]
	if type(column) ~= "table" then
		return nil
	end
	local okAir, air = pcall(function()
		return Enum.Material.Air
	end)
	for y = #column, 1, -1 do
		local layer = column[y]
		if type(layer) == "table" then
			local material = layer[iz]
			if material ~= nil and (not okAir or material ~= air) then
				return material
			end
		end
	end
	return nil
end

local function nameOf(material)
	if material == nil then
		return nil
	end
	local ok, name = pcall(function()
		local raw = tostring(material)
		return string.match(raw, "Material%.([%w_]+)") or raw
	end)
	return if ok then name else nil
end

local function changedToPaint(snapshot, after, x, z)
	local beforeName = nameOf(materialAt(snapshot, x, z))
	local currentName = nameOf(materialAt(after, x, z))
	return (currentName == "Mud" or currentName == "Ground") and beforeName ~= currentName
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local okSpec, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	local okGame, Game = pcall(function()
		return require(shared:WaitForChild("Config").Game)
	end)
	local okData, Data = pcall(function()
		return require(shared:WaitForChild("ModelMapPathsCurvedR10"))
	end)

	-- CALIBRATION ANCHOR (BEFORE). Everything below compares AFTER materials against this table.
	local snapshot = readVoxels()

	local enabled, why = review.enableAdditive("paths_curved_r10", game)
	if not enabled then
		error("enableAdditive(paths_curved_r10) failed: " .. tostring(why))
	end
	local after = readVoxels()

	if snapshot == nil or after == nil then
		emit("PATH_REACH", false, 0, 16, { reason = "Terrain or ReadVoxels unavailable" })
		emit("PATH_CURVE", false, 0, 6, { reason = "Terrain or ReadVoxels unavailable" })
		emit("GATE_CLEAR", false, 0, 0, { reason = "Terrain or ReadVoxels unavailable" })
		emit("NO_CROSS", false, 0, 0, { reason = "Terrain or ReadVoxels unavailable" })
		return
	end

	-- PATH_REACH (item 105 method, VERIFIED in a plain Play Server VM). MapSpec.HUBS is an ARRAY of
	-- six hub tables and HUB_ORDER is nil; hubPoint takes a HUB TABLE + local offsets, not a key
	-- string. GateMarker parts do not exist when only paths_curved_r10 is staged, so the 10 plot
	-- gates are reconstructed purely from the plot angle at radius 152. Terrain voxel paint is
	-- non-collidable, so 16/16 must hold.
	do
		local routes, success = 0, 0
		if okSpec and type(MapSpec) == "table" and MapSpec.SPAWN and type(MapSpec.hubPoint) == "function" then
			local spawnVec = Vector3.new(MapSpec.SPAWN.x, MapSpec.SPAWN.y, MapSpec.SPAWN.z)
			local targets = {}
			for index = 1, #MapSpec.HUBS do
				local hub = MapSpec.HUBS[index]
				local okPoint, tx, tz = pcall(MapSpec.hubPoint, hub, 0, hub.depth / 2 + 2)
				if okPoint and type(tx) == "number" and type(tz) == "number" then
					targets[#targets + 1] = Vector3.new(tx, spawnVec.Y, tz)
				end
			end
			for index = 1, PLOT_COUNT do
				local angle = (index - 3) / PLOT_COUNT * math.pi * 2
				targets[#targets + 1] =
					Vector3.new(math.cos(angle) * GATE_RADIUS, spawnVec.Y, math.sin(angle) * GATE_RADIUS)
			end
			local okService, pathService = pcall(function()
				return game:GetService("PathfindingService")
			end)
			if okService then
				for _, target in ipairs(targets) do
					routes += 1
					local okRoute, status = pcall(function()
						local path =
							pathService:CreatePath({ AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false })
						path:ComputeAsync(spawnVec, target)
						return path.Status
					end)
					if okRoute and tostring(status):find("Success", 1, true) then
						success += 1
					end
				end
			end
		end
		emit("PATH_REACH", routes == 16 and success == 16, success, 16, { routes = routes })
	end

	-- PATH_CURVE / GATE_CLEAR / NO_CROSS: read materials from the live voxels, never trust the data
	-- alone. Only cells inside a path's own painted band can contribute to that path's deviation;
	-- a neighbouring spoke can otherwise project onto this chord's axis and inflate the number.
	local paths = okData and type(Data) == "table" and type(Data.paths) == "function" and Data.paths() or nil
	local maxByPath = {}
	if type(paths) == "table" then
		for _, path in ipairs(paths) do
			maxByPath[path.index] = 0
		end
	end
	local step = SPAN * 2 / GRID
	local gateHits, riverHits, samples = 0, 0, 0
	for iz = 1, GRID do
		for ix = 1, GRID do
			local x, z = -SPAN + (ix - 0.5) * step, -SPAN + (iz - 0.5) * step
			local vx = MIN + (math.floor((x - MIN) / VOXEL) + 0.5) * VOXEL
			local vz = MIN + (math.floor((z - MIN) / VOXEL) + 0.5) * VOXEL
			samples += 1
			if changedToPaint(snapshot, after, vx, vz) then
				local inPlot = false
				for index = 1, PLOT_COUNT do
					local px, pz
					if okGame and type(Game) == "table" and type(Game.plotCenter) == "function" then
						local okCentre, cx, cz = pcall(Game.plotCenter, index)
						if okCentre and type(cx) == "number" and type(cz) == "number" then
							px, pz = cx, cz
						end
					end
					if px == nil then
						local angle = (index - 3) / PLOT_COUNT * math.pi * 2
						px, pz = math.cos(angle) * 192, math.sin(angle) * 192
					end
					if math.abs(vx - px) <= PLOT_HALF and math.abs(vz - pz) <= PLOT_HALF then
						inPlot = true
						break
					end
				end
				local inGateBox = math.abs(math.sqrt(vx * vx + vz * vz) - GATE_RADIUS) <= GATE_BOX_HALF
				if inPlot or inGateBox then
					gateHits += 1
				end
				if math.abs(vz - riverCentreZ(vx)) <= RIVER_HALF then
					local inBridge = vx >= BRIDGE_MIN_X
						and vx <= BRIDGE_MAX_X
						and vz >= BRIDGE_MIN_Z
						and vz <= BRIDGE_MAX_Z
					if not inBridge then
						riverHits += 1
					end
				end
				if type(paths) == "table" then
					for _, path in ipairs(paths) do
						local owned = false
						local points = path.points or {}
						for k = 1, #points - 1 do
							local a, b = points[k], points[k + 1]
							if distanceToSegment(vx, vz, a.x, a.z, b.x, b.z) <= CORE_HALF + SHOULDER + 0.001 then
								owned = true
								break
							end
						end
						if owned then
							local s = path.straight
							local dx, dz = s.bx - s.ax, s.bz - s.az
							local lengthSq = dx * dx + dz * dz
							local t = ((vx - s.ax) * dx + (vz - s.az) * dz) / lengthSq
							if t >= 0 and t <= 1 then
								local distance = distanceToSegment(vx, vz, s.ax, s.az, s.bx, s.bz)
								if distance > maxByPath[path.index] then
									maxByPath[path.index] = distance
								end
							end
						end
					end
				end
			end
		end
	end
	-- The 40x40 path grid only spans z <= 208; the river sits at z ~= 292..316, so NO_CROSS
	-- sweeps the real channel column-by-column on the 4-stud voxel grid (bridge excepted).
	for gx = MIN + VOXEL / 2, MAX - VOXEL / 2, VOXEL do
		local vx = MIN + (math.floor((gx - MIN) / VOXEL) + 0.5) * VOXEL
		local centre = riverCentreZ(vx)
		for gz = centre - RIVER_HALF, centre + RIVER_HALF, VOXEL do
			local vz = MIN + (math.floor((gz - MIN) / VOXEL) + 0.5) * VOXEL
			local inBridge = vx >= BRIDGE_MIN_X and vx <= BRIDGE_MAX_X and vz >= BRIDGE_MIN_Z and vz <= BRIDGE_MAX_Z
			if not inBridge and changedToPaint(snapshot, after, vx, vz) then
				riverHits += 1
			end
		end
	end
	local curved = 0
	local deviations = {}
	for _, path in ipairs(paths or {}) do
		deviations[path.index] = maxByPath[path.index]
		if maxByPath[path.index] >= 4 then
			curved += 1
		end
	end
	emit(
		"PATH_CURVE",
		type(paths) == "table" and curved >= 6,
		curved,
		6,
		{ deviations = deviations, samples = samples }
	)
	emit("GATE_CLEAR", gateHits == 0, gateHits, 0, { samples = samples })
	emit("NO_CROSS", riverHits == 0, riverHits, 0, { samples = samples })
end)

-- Restore every additively staged candidate, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emitOnce("PATH_REACH", false, 0, 16, reason)
	emitOnce("PATH_CURVE", false, 0, 6, reason)
	emitOnce("GATE_CLEAR", false, 0, 0, reason)
	emitOnce("NO_CROSS", false, 0, 0, reason)
end

return results
