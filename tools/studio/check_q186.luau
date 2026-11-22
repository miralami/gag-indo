--!nocheck
-- check_q186.luau: SERVER-VM Studio check for WORK_QUEUE item 186 (DEFAULT-look denser/shadier
-- tropical forest). Reads the SHIPPING forest directly — no LookDev stage, no candidate enabled.
-- The main session pastes this whole file into execute_luau (Server VM) in a FRESH Play session and
-- saves the printed CHECK lines under docs/v2/evidence/h/<date>-round<N>/CHECK_186.txt.
-- Non-vacuity is proven by mutating live geometry then re-running the SAME check (see evidence doc).
-- No place save, no visual verdict, no weakened checks.

local NAMES = { "TREE_COUNT", "SHADE_TREES", "NO_PINES", "WALKABLE", "PATH_REACH", "PERF_BUDGET" }

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

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

-- AABB of one BasePart. cf.Position is added to the rotated half-extent corners (R10 helper).
local function partAABB(part)
	local ok, box = pcall(function()
		local cf, size = part.CFrame, part.Size
		local ex = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
		local ez = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local p = cf.Position + Vector3.new(ex.X * sx + ez.X * sz, 0, ex.Z * sx + ez.Z * sz)
				minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
				minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
			end
		end
		return {
			minX = minX,
			maxX = maxX,
			minZ = minZ,
			maxZ = maxZ,
			centreX = (minX + maxX) / 2,
			centreZ = (minZ + maxZ) / 2,
		}
	end)
	return ok and box or nil
end

-- Union AABB of a tree Model (all descendant BaseParts).
local function modelAABB(model)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	local any = false
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local b = partAABB(d)
			if b then
				any = true
				minX, maxX = math.min(minX, b.minX), math.max(maxX, b.maxX)
				minZ, maxZ = math.min(minZ, b.minZ), math.max(maxZ, b.maxZ)
			end
		end
	end
	if not any then
		return nil
	end
	return {
		minX = minX,
		maxX = maxX,
		minZ = minZ,
		maxZ = maxZ,
		centreX = (minX + maxX) / 2,
		centreZ = (minZ + maxZ) / 2,
	}
end

local function rectHit(box, rect)
	return math.min(box.maxX, rect.maxX) - math.max(box.minX, rect.minX) > 0.05
		and math.min(box.maxZ, rect.maxZ) - math.max(box.minZ, rect.minZ) > 0.05
end

local okAudit, err = pcall(function()
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	local world = workspace:FindFirstChild("World")
	local forest = world and world:FindFirstChild("BackgroundForest")
	if not forest then
		error("World.BackgroundForest missing")
	end

	-- Road rects (WALKABLE) and the six hub door lanes (PATH_REACH), project-standard semantics.
	local roadRects = {}
	for _, list in ipairs({ MapSpec.roadArms(), MapSpec.roadContinuations() }) do
		for _, r in ipairs(list) do
			roadRects[#roadRects + 1] =
				{ minX = r.x - r.sx / 2, maxX = r.x + r.sx / 2, minZ = r.z - r.sz / 2, maxZ = r.z + r.sz / 2 }
		end
	end
	local lanes = {}
	for _, key in ipairs(MapSpec.HUB_ORDER) do
		local hub = MapSpec.hub(key)
		local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
		for _, corner in ipairs({
			{ -3, hub.depth / 2 },
			{ 3, hub.depth / 2 },
			{ -3, hub.depth / 2 + 24 },
			{ 3, hub.depth / 2 + 24 },
		}) do
			local x, z = MapSpec.hubPoint(hub, corner[1], corner[2])
			minX, maxX = math.min(minX, x), math.max(maxX, x)
			minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
		end
		lanes[#lanes + 1] = { key = key, minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
	end

	-- Census the live default trees.
	local trees = {}
	for _, m in ipairs(forest:GetChildren()) do
		if attr(m, "ForestTree") == true then
			trees[#trees + 1] = { model = m, box = modelAABB(m), shade = attr(m, "ShadeTree") == true }
		end
	end
	emit("TREE_COUNT", #trees >= 450, #trees, 450)

	-- SHADE_TREES: >=3 ShadeTree models within 25 studs of EVERY hub centre (report the min).
	local hubCounts, minShade = {}, math.huge
	for _, key in ipairs(MapSpec.HUB_ORDER) do
		local hub = MapSpec.hub(key)
		local c = 0
		for _, t in ipairs(trees) do
			if t.shade and t.box then
				local dx, dz = t.box.centreX - hub.x, t.box.centreZ - hub.z
				if dx * dx + dz * dz <= 25 * 25 then
					c = c + 1
				end
			end
		end
		hubCounts[key] = c
		minShade = math.min(minShade, c)
	end
	emit("SHADE_TREES", minShade >= 3, minShade, 3, { hubs = hubCounts })

	-- NO_PINES over the whole workspace (case-insensitive), the item-74 rule.
	local pine = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if string.find(string.lower(d.Name), "pine", 1, true) then
			pine = pine + 1
		end
	end
	emit("NO_PINES", pine == 0, pine, 0)

	-- WALKABLE: no tree on a road; PATH_REACH: no tree in a hub door lane.
	local onRoad, inLane = 0, 0
	for _, t in ipairs(trees) do
		if t.box then
			for _, r in ipairs(roadRects) do
				if rectHit(t.box, r) then
					onRoad = onRoad + 1
					break
				end
			end
			for _, l in ipairs(lanes) do
				if rectHit(t.box, l) then
					inLane = inLane + 1
					break
				end
			end
		end
	end
	emit("WALKABLE", onRoad == 0, onRoad, 0)
	emit("PATH_REACH", inLane == 0, inLane, 0)

	-- PERF_BUDGET: spawn-view BasePart census, XZ radius 100 (R10 method), target <=500.
	local perf = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") then
			local p = inst.CFrame.Position
			if p.X * p.X + p.Z * p.Z <= 10000 then
				perf = perf + 1
			end
		end
	end
	emit("PERF_BUDGET", perf <= 500, perf, 500)
end)

if not okAudit then
	local reason = "audit error: " .. tostring(err)
	for _, name in ipairs(NAMES) do
		emit(name, false, 0, 0, reason)
	end
end

return results
