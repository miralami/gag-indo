--!nocheck
-- check_q195: WORK_QUEUE section Q item 195 lane 1, self-contained SERVER-VM Studio check. Paste
-- this whole file into execute_luau in a fresh Play session. It snapshots terrain voxels BEFORE
-- staging ground_variation_r10 with enableAdditive, re-reads the same region and prints verbatim
-- CHECK lines, then restores with disableAll(). No harness require, no place save, no visual verdict.
--
--   GROUND_TONES    >=3 distinct Enum.Material names on a 40x40 cell-centre grid
--   ROAD_UNTOUCHED  0 changed cells where the q194 offRoad predicate rejects the cell
--   PLOT_UNTOUCHED  0 changed cells inside any plot footprint
--
-- CALIBRATION ANCHOR: `local snapshot = readVoxels()` below is the BEFORE read. Inject a mutation
-- of `snapshot` on the line immediately after it to force a BEFORE/AFTER mismatch.

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
local SPAN = 200
local VOXEL = 4 -- scalar resolution; Vector3.new(4,4,4) throws in Terrain:ReadVoxels
local MIN = -208 -- 416 / 4 = 104 voxels per axis, grid-aligned
local MAX = 208
local Y_MIN, Y_MAX = -12, 20 -- 8 voxel layers
local ROAD_HALF, RING_CENTRE, RING_HALF = 14, 144, 6
local PLOT_COUNT, GATE_CLEAR, MARGIN = 10, 6, 4

-- Independent conservative predicate copied from check_q194; live MapSpec.ROAD values win.
local function offRoad(x, z, road, plotRadius)
	local half = (road and road.halfWidth) or ROAD_HALF
	local ring = (road and road.ringCentre) or RING_CENTRE
	local ringHalf = (road and road.ringWidth and road.ringWidth / 2) or RING_HALF
	local r = math.sqrt(x * x + z * z)
	if math.abs(r - ring) <= ringHalf + MARGIN then
		return false, "ring"
	end
	if math.abs(z) <= half + MARGIN and math.abs(x) <= ring + MARGIN then
		return false, "x-arm"
	end
	if math.abs(x) <= half + MARGIN and math.abs(z) <= ring + MARGIN then
		return false, "z-arm"
	end
	if math.abs(x) <= (road and road.linkHalfWidth or 8) + MARGIN and z >= ring and z <= 276 then
		return false, "bridge-link"
	end
	local plotHalf = 24
	for index = 1, PLOT_COUNT do
		local angle = (index - 3) / PLOT_COUNT * math.pi * 2
		local cx, cz = math.cos(angle) * plotRadius, math.sin(angle) * plotRadius
		if math.abs(x - cx) <= plotHalf + MARGIN and math.abs(z - cz) <= plotHalf + MARGIN then
			return false, "plot-" .. index
		end
		local dx, dz = x - cx, z - cz
		if dx * dx + dz * dz <= (plotHalf + GATE_CLEAR + MARGIN) ^ 2 then
			return false, "gate-" .. index
		end
	end
	return true, nil
end

-- mats is indexed [x][y][z]; the second ReadVoxels return is occupancy and is not needed here.
local function readVoxels()
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		return nil
	end
	local okRegion, region = pcall(function()
		return Region3.new(Vector3.new(MIN, Y_MIN, MIN), Vector3.new(MAX, Y_MAX, MAX))
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
	if ix < 1 or ix > (MAX - MIN) / VOXEL or iz < 1 or iz > (MAX - MIN) / VOXEL then
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

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local okSpec, MapSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	local road = (okSpec and type(MapSpec) == "table" and MapSpec.ROAD) or nil
	local okGame, Game = pcall(function()
		return require(shared:WaitForChild("Config").Game)
	end)
	local plotRadius = (okGame and type(Game) == "table" and type(Game.plotRadius) == "number" and Game.plotRadius)
		or 192
	local plotCount = (okGame and type(Game) == "table" and type(Game.plotCount) == "number" and Game.plotCount)
		or PLOT_COUNT

	-- CALIBRATION ANCHOR (BEFORE). Everything below compares AFTER materials against this table.
	local snapshot = readVoxels()

	local enabled, why = review.enableAdditive("ground_variation_r10", game)
	if not enabled then
		error("enableAdditive(ground_variation_r10) failed: " .. tostring(why))
	end
	local after = readVoxels()

	if snapshot == nil or after == nil then
		emit("GROUND_TONES", false, 0, 3, { reason = "Terrain or ReadVoxels unavailable" })
		emit("ROAD_UNTOUCHED", false, 0, 0, { reason = "Terrain or ReadVoxels unavailable" })
		emit("PLOT_UNTOUCHED", false, 0, 0, { reason = "Terrain or ReadVoxels unavailable" })
		return
	end

	local step = SPAN * 2 / GRID
	local materials, roadChanged, plotChanged = {}, 0, 0
	local roadSamples, plotSamples = 0, 0
	for iz = 1, GRID do
		for ix = 1, GRID do
			local x, z = -SPAN + (ix - 0.5) * step, -SPAN + (iz - 0.5) * step
			-- materialAt() reads the 4-stud voxel that CONTAINS (x,z); zone tests must use that
			-- voxel's centre, not the abstract grid point, or quantisation edge cells disagree
			-- with the applier (which zones by voxel centre).
			local vx = MIN + (math.floor((x - MIN) / VOXEL) + 0.5) * VOXEL
			local vz = MIN + (math.floor((z - MIN) / VOXEL) + 0.5) * VOXEL
			local name = nameOf(materialAt(after, x, z))
			if name then
				materials[name] = true
			end
			local beforeName = nameOf(materialAt(snapshot, x, z))
			local inPlot = false
			for index = 1, plotCount do
				local px, pz
				if okGame and type(Game) == "table" and type(Game.plotCenter) == "function" then
					local okCentre, cx, cz = pcall(Game.plotCenter, index)
					if okCentre and type(cx) == "number" and type(cz) == "number" then
						px, pz = cx, cz
					end
				end
				if px == nil then
					local angle = (index - 3) / plotCount * math.pi * 2
					px, pz = math.cos(angle) * plotRadius, math.sin(angle) * plotRadius
				end
				if math.abs(vx - px) <= 24 and math.abs(vz - pz) <= 24 then
					inPlot = true
					break
				end
			end
			local clear = offRoad(vx, vz, road, plotRadius)
			if not clear or inPlot then
				if not clear then
					roadSamples += 1
				end
				if inPlot then
					plotSamples += 1
				end
				if beforeName ~= name then
					if not clear then
						roadChanged += 1
					end
					if inPlot then
						plotChanged += 1
					end
				end
			end
		end
	end

	local distinct = 0
	for _ in pairs(materials) do
		distinct += 1
	end
	emit("GROUND_TONES", distinct >= 3, distinct, 3, { names = materials })
	emit("ROAD_UNTOUCHED", roadChanged == 0, roadChanged, 0, { samples = roadSamples })
	emit("PLOT_UNTOUCHED", plotChanged == 0, plotChanged, 0, { samples = plotSamples })
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
	emitOnce("GROUND_TONES", false, 0, 3, reason)
	emitOnce("ROAD_UNTOUCHED", false, 0, 0, reason)
	emitOnce("PLOT_UNTOUCHED", false, 0, 0, reason)
end

return results
