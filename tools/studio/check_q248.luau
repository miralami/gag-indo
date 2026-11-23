--!nocheck
-- check_q248: WORK_QUEUE item 248, full_r11 combined review set. Self-contained SERVER-VM Studio
-- harness. Paste this WHOLE file into execute_luau in a fresh Play Server session. One call: it
-- stages, measures, emits verbatim CHECK lines, runs fail-capable calibration anchors, restores
-- LIFO on every path. Reused for item 220 (PERF_BUDGET census) and item 221 (walkability audit).
-- No harness require, no camera capture, no place save, no publish, no HttpService, no store-model
-- insertion, no visual verdict. The main session owns evidence and Studio.
--
-- ADDITIVE SET (21) — derived, NOT invented. Every id is a row in docs/v2/visual/CANDIDATES.md
-- lines 18-76 whose last (Designer yes/no) cell starts **yes, and every id is verified at runtime
-- against Shared.LookDev.IDS. No full_r10/full_r11 ID exists (item 223 doc note); this is an
-- additive enableAdditive recipe like item 103's full_r9, not a new candidate ID.
--   icons, day_cycle, icons_r3, buildings_r4, vegetation_r4, props_r4, vegetation_r5, sky_r5,
--   sky_r6_e, spawn_ground_r6, npcs_r6, npcs_r7, hubveg_r8, plots_r8, sawah_r8, river_r8,
--   water_r8_a, buildings_r8, props_r5, npcs_r5, pasar_awnings_r8
--
-- Emitted lines (measured first, target second):
--   CHECK STAGE_COUNT <PASS|FAIL> <staged> <21>
--   CHECK LOAD_FAILURES <PASS|FAIL> <count> 0
--   CHECK CROSS_OVERLAP <PASS|FAIL> <n> collidable pairs 0 pairs
--   CHECK PERF_BUDGET <PASS|FAIL> <near100 BaseParts> 500   (real count; never faked)
--   CHECK LOOKDEV_LEAK <PASS|FAIL> <signature deltas> 0     (after disableAll)
--   CHECK PATH_REACH <PASS|FAIL> <routes ok> 16
--   CHECK GATE_CLEAR <PASS|FAIL> <corridor hits> 0
--   CHECK LANE_CLEAR <PASS|FAIL> <blocked door rays> 0
--   SUMMARY_Q248 ... / SUMMARY_Q220 PERF_BUDGET ... / SUMMARY_Q221 PATH_REACH ... GATE_CLEAR ... LANE_CLEAR ...
-- CAL_<CHECK>_FAIL anchors inject a fault, require the SAME measure to fail, then restore LIFO.

local YES_IDS = {
	"icons",
	"day_cycle",
	"icons_r3",
	"buildings_r4",
	"vegetation_r4",
	"props_r4",
	"vegetation_r5",
	"sky_r5",
	"sky_r6_e",
	"spawn_ground_r6",
	"npcs_r6",
	"npcs_r7",
	"hubveg_r8",
	"plots_r8",
	"sawah_r8",
	"river_r8",
	"water_r8_a",
	"buildings_r8",
	"props_r5",
	"npcs_r5",
	"pasar_awnings_r8",
}

local PERF_TARGET = 500
local PERF_RADIUS = 100 -- BasePart centre within XZ radius 100 of (0,0,0)
local HASH = 8 -- XZ spatial hash cell for cross-candidate AABB comparison
local TOLERANCE = 0.5 -- touching faces are not overlaps
local PLOT_COUNT, GATE_RADIUS, JUNCTION_RADIUS, GAP_MIN = 10, 152, 144, 8
local DOOR_RAY_LENGTH, DOOR_RAY_Y = 8, 1.5

local CHECK_NAMES = {
	"STAGE_COUNT",
	"LOAD_FAILURES",
	"CROSS_OVERLAP",
	"PERF_BUDGET",
	"LOOKDEV_LEAK",
	"PATH_REACH",
	"GATE_CLEAR",
	"LANE_CLEAR",
	"CAL_STAGE_COUNT_FAIL",
	"CAL_LOAD_FAILURES_FAIL",
	"CAL_CROSS_OVERLAP_FAIL",
	"CAL_PERF_BUDGET_FAIL",
	"CAL_LOOKDEV_LEAK_FAIL",
	"CAL_PATH_REACH_FAIL",
	"CAL_GATE_CLEAR_FAIL",
	"CAL_LANE_CLEAR_FAIL",
}
local TARGETS = {
	STAGE_COUNT = #YES_IDS,
	LOAD_FAILURES = 0,
	CROSS_OVERLAP = "0 pairs",
	PERF_BUDGET = PERF_TARGET,
	LOOKDEV_LEAK = 0,
	PATH_REACH = 16,
	GATE_CLEAR = 0,
	LANE_CLEAR = 0,
}
for _, name in ipairs(CHECK_NAMES) do
	if string.sub(name, 1, 4) == "CAL_" then
		TARGETS[name] = 1
	end
end

local YES_SET = {}
for _, id in ipairs(YES_IDS) do
	YES_SET[id] = true
end

local results = { checks = {}, byName = {}, checkNames = {} }
local function emit(name, passed, measured, target, detail)
	if not results.byName[name] then
		results.checkNames[#results.checkNames + 1] = name
	end
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

-- LIFO restore of every injected attribute, part and local override.
local restores = {}
local function pushRestore(fn)
	restores[#restores + 1] = fn
end
local function runRestores()
	for index = #restores, 1, -1 do
		local fn = restores[index]
		restores[index] = nil
		pcall(fn)
	end
end

local review, LookDev, failures = nil, nil, nil
local priorId = nil
local stageFailures = {}
local unknownIds = {}
local auditError = nil
local calPass = 0

local function service(name)
	local ok, result = pcall(function()
		return game:GetService(name)
	end)
	return ok and result or nil
end

local function saveAttr(target, prop, value)
	local okRead, old = pcall(function()
		return target:GetAttribute(prop)
	end)
	if not okRead then
		return false
	end
	pushRestore(function()
		pcall(function()
			target:SetAttribute(prop, old)
		end)
	end)
	local okWrite = pcall(function()
		target:SetAttribute(prop, value)
	end)
	return okWrite
end

local function newTaggedPart(id, name, size, position, collidable)
	local folder = Instance.new("Folder")
	folder.Name = "Q248_CAL_" .. id -- suffix `_<id>` makes ownerOf() attribute it to a real candidate
	folder.Parent = workspace
	pushRestore(function()
		folder:Destroy()
	end)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = collidable
	part.CanQuery = true
	part.CastShadow = false
	part.Parent = folder
	return part
end

-- Owner = nearest ancestor Folder named `<Module>_<candidate id>`. This is the folder convention
-- every applier uses (item 103 precedent); CAL parts use the same suffix so the measure sees them.
local function ownerOf(instance)
	local node = instance
	for _ = 1, 16 do
		if not node then
			break
		end
		local okName, name = pcall(function()
			return node.Name
		end)
		if okName and type(name) == "string" then
			local suffix = string.match(name, "_([%w_]+)$")
			if suffix and YES_SET[suffix] then
				return suffix
			end
		end
		local okParent, parent = pcall(function()
			return node.Parent
		end)
		if not okParent or not parent or parent == game then
			break
		end
		node = parent
	end
	return nil
end

local function collectParts()
	local found, unreadable = {}, 0
	local ok, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return found, 1
	end
	for _, instance in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if not okPart then
			unreadable += 1
		elseif isPart then
			local owner = ownerOf(instance)
			if owner then
				local okBox, cf, size = pcall(function()
					return instance:GetBoundingBox()
				end)
				local okCollide, collide = pcall(function()
					return instance.CanCollide == true
				end)
				if not okBox or not okCollide or typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then
					unreadable += 1
				else
					local centre, half = cf.Position, size * 0.5
					found[#found + 1] = {
						instance = instance,
						owner = owner,
						collide = collide,
						centre = centre,
						min = centre - half,
						max = centre + half,
					}
				end
			end
		end
	end
	return found, unreadable
end

local function aabbOverlap(a, b)
	return a.max.X > b.min.X + TOLERANCE
		and b.max.X > a.min.X + TOLERANCE
		and a.max.Y > b.min.Y + TOLERANCE
		and b.max.Y > a.min.Y + TOLERANCE
		and a.max.Z > b.min.Z + TOLERANCE
		and b.max.Z > a.min.Z + TOLERANCE
end

local function measureOverlap(parts)
	local collidable, buckets, seen, pairCount = {}, {}, {}, 0
	for index, part in ipairs(parts) do
		if part.collide then
			collidable[#collidable + 1] = { index = index, part = part }
			for gx = math.floor(part.min.X / HASH), math.floor(part.max.X / HASH) do
				for gz = math.floor(part.min.Z / HASH), math.floor(part.max.Z / HASH) do
					local key = gx .. ":" .. gz
					buckets[key] = buckets[key] or {}
					buckets[key][#buckets[key] + 1] = #collidable
				end
			end
		end
	end
	for _, bucket in pairs(buckets) do
		for i = 1, #bucket do
			for j = i + 1, #bucket do
				local a, b = collidable[bucket[i]], collidable[bucket[j]]
				if a and b and a.part.owner ~= b.part.owner then
					local lo, hi = math.min(a.index, b.index), math.max(a.index, b.index)
					local pairKey = lo .. ":" .. hi
					if not seen[pairKey] and aabbOverlap(a.part, b.part) then
						seen[pairKey] = true
						pairCount += 1
					end
				end
			end
		end
	end
	return pairCount, #collidable
end

local function measurePerf()
	local count, errors = 0, 0
	local ok, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return 0, 1
	end
	for _, instance in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if not okPart then
			errors += 1
		elseif isPart then
			local okPos, pos = pcall(function()
				return instance.Position
			end)
			if not okPos or typeof(pos) ~= "Vector3" then
				errors += 1
			elseif pos.X * pos.X + pos.Z * pos.Z <= PERF_RADIUS * PERF_RADIUS then
				count += 1
			end
		end
	end
	return count, errors
end

local function signature(serviceName)
	local ok, list = pcall(function()
		return service(serviceName):GetDescendants()
	end)
	if not ok or type(list) ~= "table" then
		return nil
	end
	local map = {}
	for _, instance in ipairs(list) do
		local okKey, key = pcall(function()
			return instance.ClassName .. "|" .. instance:GetFullName()
		end)
		if not okKey then
			return nil
		end
		map[key] = (map[key] or 0) + 1
	end
	return map
end

local function snapshot()
	local workspaceSig, lightingSig = signature("Workspace"), signature("Lighting")
	if not workspaceSig or not lightingSig then
		return nil
	end
	return { Workspace = workspaceSig, Lighting = lightingSig }
end

local function diffSignatures(before, after)
	if not before or not after then
		return nil, {}
	end
	local total, offenders = 0, {}
	for container, map in pairs(before) do
		for key, count in pairs(map) do
			local afterCount = (after[container] or {})[key] or 0
			if count ~= afterCount then
				total += math.abs(count - afterCount)
				offenders[#offenders + 1] = container .. ":" .. key .. " " .. count .. "->" .. afterCount
			end
		end
	end
	for container, map in pairs(after) do
		for key, count in pairs(map) do
			if not before[container] or not before[container][key] then
				total += count
				offenders[#offenders + 1] = container .. ":" .. key .. " 0->" .. count
			end
		end
	end
	return total, offenders
end

local function loadFailureTotal()
	local total = 0
	for _, id in ipairs(YES_IDS) do
		local ok, count = pcall(function()
			return failures.get(id)
		end)
		if ok and type(count) == "number" then
			total += count
		end
	end
	return total
end

local CORRIDORS = {}
for _, angle in ipairs({ 0, 90, 180, 270 }) do
	local radians = math.rad(angle)
	local dx, dz = math.cos(radians), math.sin(radians)
	CORRIDORS[#CORRIDORS + 1] = { x = dx * JUNCTION_RADIUS, z = dz * JUNCTION_RADIUS }
	CORRIDORS[#CORRIDORS + 1] = { x = dx * GATE_RADIUS, z = dz * GATE_RADIUS }
end

local function measureGateHits(parts)
	local hits = 0
	for _, part in ipairs(parts) do
		for _, corridor in ipairs(CORRIDORS) do
			local dx, dz = part.centre.X - corridor.x, part.centre.Z - corridor.z
			if dx * dx + dz * dz < GAP_MIN * GAP_MIN then
				hits += 1
			end
		end
	end
	return hits
end

local MapSpec = nil
local function doors()
	local list = {}
	if type(MapSpec) == "table" and type(MapSpec.HUBS) == "table" then
		for index, hub in ipairs(MapSpec.HUBS) do
			local ok, tx, tz = pcall(MapSpec.hubPoint, hub, 0, hub.depth / 2 + 2)
			if ok and type(tx) == "number" and type(tz) == "number" then
				local radians = math.rad(hub.yaw or 0)
				local nx, nz = math.sin(radians), math.cos(radians)
				list[#list + 1] = {
					index = index,
					key = hub.key or tostring(index),
					normal = Vector3.new(nx, 0, nz),
					origin = Vector3.new(tx, DOOR_RAY_Y, tz),
				}
			end
		end
	end
	return list
end

local function measureLaneBlocked(doorList, parts)
	local owned, errors, blocked = {}, 0, 0
	for _, part in ipairs(parts) do
		owned[part.instance] = true
	end
	local okParams, params = pcall(function()
		local query = RaycastParams.new()
		query.IgnoreWater = false
		query.FilterType = Enum.RaycastFilterType.Exclude
		local excluded = {}
		local players = service("Players")
		if players then
			for _, player in ipairs(players:GetPlayers()) do
				if player.Character then
					excluded[#excluded + 1] = player.Character
				end
			end
		end
		query.FilterDescendantsInstances = excluded
		return query
	end)
	if not okParams then
		return 0, 1
	end
	for _, door in ipairs(doorList) do
		local okRay, hit = pcall(function()
			return workspace:Raycast(door.origin, door.normal * DOOR_RAY_LENGTH, params)
		end)
		if not okRay then
			errors += 1
		elseif hit and hit.Instance and owned[hit.Instance] then
			blocked += 1
		end
	end
	return blocked, errors
end

local function pathTargets(overrideIndex)
	local targets, spawnVec = {}, nil
	if type(MapSpec) ~= "table" or not MapSpec.SPAWN then
		return targets
	end
	spawnVec = Vector3.new(MapSpec.SPAWN.x, MapSpec.SPAWN.y, MapSpec.SPAWN.z)
	if type(MapSpec.HUBS) == "table" then
		for _, hub in ipairs(MapSpec.HUBS) do
			local ok, tx, tz = pcall(MapSpec.hubPoint, hub, 0, hub.depth / 2 + 2)
			if ok and type(tx) == "number" and type(tz) == "number" then
				targets[#targets + 1] = Vector3.new(tx, spawnVec.Y, tz)
			end
		end
	end
	for index = 1, PLOT_COUNT do
		local angle = (index - 3) / PLOT_COUNT * math.pi * 2
		targets[#targets + 1] = Vector3.new(math.cos(angle) * GATE_RADIUS, spawnVec.Y, math.sin(angle) * GATE_RADIUS)
	end
	if overrideIndex and targets[overrideIndex] then
		targets[overrideIndex] =
			Vector3.new(targets[overrideIndex].X, targets[overrideIndex].Y + 5000, targets[overrideIndex].Z)
	end
	return targets, spawnVec
end

local function measurePaths(overrideIndex)
	local targets, spawnVec = pathTargets(overrideIndex)
	if #targets ~= 16 or not spawnVec then
		return 0, #targets
	end
	local pathService = service("PathfindingService")
	if not pathService then
		return 0, #targets
	end
	local success = 0
	for _, target in ipairs(targets) do
		local ok, status = pcall(function()
			local path = pathService:CreatePath({ AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false })
			path:ComputeAsync(spawnVec, target)
			return path.Status
		end)
		if ok and tostring(status):find("Success", 1, true) then
			success += 1
		end
	end
	return success, #targets
end

local function printSummary()
	local function measured(name)
		local entry = results.byName[name]
		return entry and entry.measured or 0
	end
	local cal = 0
	for _, name in ipairs(CHECK_NAMES) do
		if string.sub(name, 1, 4) == "CAL_" and results.byName[name] and results.byName[name].passed then
			cal += 1
		end
	end
	print(
		string.format(
			"SUMMARY_Q248 STAGE_COUNT %s/%d LOAD_FAILURES %s/0 CROSS_OVERLAP %s/0 PERF_BUDGET %s/%d LOOKDEV_LEAK %s/0 PATH_REACH %s/16 GATE_CLEAR %s/0 LANE_CLEAR %s/0 CAL %d/8",
			tostring(measured("STAGE_COUNT")),
			#YES_IDS,
			tostring(measured("LOAD_FAILURES")),
			tostring(measured("CROSS_OVERLAP")),
			tostring(measured("PERF_BUDGET")),
			PERF_TARGET,
			tostring(measured("LOOKDEV_LEAK")),
			tostring(measured("PATH_REACH")),
			tostring(measured("GATE_CLEAR")),
			tostring(measured("LANE_CLEAR")),
			cal
		)
	)
	print(
		string.format(
			"SUMMARY_Q220 PERF_BUDGET %s/%d CAL %d/1",
			tostring(measured("PERF_BUDGET")),
			PERF_TARGET,
			results.byName.CAL_PERF_BUDGET_FAIL and results.byName.CAL_PERF_BUDGET_FAIL.passed and 1 or 0
		)
	)
	print(
		string.format(
			"SUMMARY_Q221 PATH_REACH %s/16 GATE_CLEAR %s/0 LANE_CLEAR %s/0 CAL %d/3",
			tostring(measured("PATH_REACH")),
			tostring(measured("GATE_CLEAR")),
			tostring(measured("LANE_CLEAR")),
			(results.byName.CAL_PATH_REACH_FAIL and results.byName.CAL_PATH_REACH_FAIL.passed and 1 or 0)
				+ (results.byName.CAL_GATE_CLEAR_FAIL and results.byName.CAL_GATE_CLEAR_FAIL.passed and 1 or 0)
				+ (results.byName.CAL_LANE_CLEAR_FAIL and results.byName.CAL_LANE_CLEAR_FAIL.passed and 1 or 0)
		)
	)
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	LookDev = require(shared:WaitForChild("LookDev"))
	failures = require(shared:WaitForChild("LookDevFailures"))
	local okSpec, loadedSpec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	MapSpec = okSpec and loadedSpec or nil

	if
		type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("LookDevReview.enableAdditive/disableAll missing")
	end
	if type(LookDev) ~= "table" or type(LookDev.IDS) ~= "table" or type(LookDev.additiveIds) ~= "function" then
		error("LookDev.IDS/additiveIds missing")
	end
	if type(failures) ~= "table" or type(failures.get) ~= "function" or type(failures.set) ~= "function" then
		error("LookDevFailures API missing")
	end

	-- Reject any doc-derived id that is not a real LookDev.IDS entry: never invent an ID.
	for _, id in ipairs(YES_IDS) do
		if table.find(LookDev.IDS, id) == nil then
			unknownIds[#unknownIds + 1] = id
		end
	end
	if #unknownIds > 0 then
		error("CANDIDATES.md yes row not in LookDev.IDS: " .. table.concat(unknownIds, ","))
	end

	local okCurrent, current = pcall(function()
		return LookDev.current()
	end)
	if okCurrent and type(current) == "string" then
		priorId = current
	end
	pcall(review.disableAll) -- clear any prior active/additive staging before the baseline

	local baseline = snapshot()
	if not baseline then
		error("Workspace/Lighting signature snapshot unavailable")
	end

	-- Stage the derived set in doc order. enableAdditive never disables another candidate.
	for _, id in ipairs(YES_IDS) do
		local stageOk, staged, why = pcall(review.enableAdditive, id, game, { studio = true })
		if not stageOk or staged == false then
			stageFailures[#stageFailures + 1] = id .. ":" .. tostring(why or staged)
		end
	end

	local additive = LookDev.additiveIds()
	local stageCount = type(additive) == "table" and #additive or 0
	emit("STAGE_COUNT", stageCount == #YES_IDS and #stageFailures == 0 and #unknownIds == 0, stageCount, #YES_IDS, {
		stageFailures = stageFailures,
		unknownIds = unknownIds,
		ids = YES_IDS,
	})

	local loadFailures = loadFailureTotal()
	emit("LOAD_FAILURES", loadFailures == 0, loadFailures, 0, { ids = YES_IDS })

	local parts, unreadable = collectParts()
	local owners = {}
	for _, part in ipairs(parts) do
		owners[part.owner] = true
	end
	local ownerCount = 0
	for _ in pairs(owners) do
		ownerCount += 1
	end
	local crossPairs, collidableCount = measureOverlap(parts)
	local crossOk = crossPairs == 0 and #parts > 0 and ownerCount > 0 and unreadable == 0
	emit("CROSS_OVERLAP", crossOk, tostring(crossPairs) .. " collidable pairs", "0 pairs", {
		pairs = crossPairs,
		collidableParts = collidableCount,
		parts = #parts,
		folders = ownerCount,
		unreadable = unreadable,
	})

	local perfParts, perfErrors = measurePerf()
	emit("PERF_BUDGET", perfErrors == 0 and perfParts <= PERF_TARGET, perfParts, PERF_TARGET, {
		proxy = "BasePart centre within XZ radius 100 of (0,0,0)",
		readErrors = perfErrors,
	})

	local doorList = doors()
	local gateHits = measureGateHits(parts)
	emit("GATE_CLEAR", gateHits == 0 and #doorList > 0, gateHits, 0, { corridors = #CORRIDORS, doors = #doorList })

	local laneBlocked, laneErrors = measureLaneBlocked(doorList, parts)
	emit("LANE_CLEAR", laneBlocked == 0 and laneErrors == 0 and #doorList > 0, laneBlocked, 0, {
		doors = #doorList,
		rayErrors = laneErrors,
	})

	local routes, routeTotal = measurePaths(nil)
	emit("PATH_REACH", routes == 16 and routeTotal == 16, routes, 16, { routes = routeTotal })

	-- CAL LOAD_FAILURES: one real counter set to 1 must move the aggregate; LIFO restore the count.
	do
		local victim = YES_IDS[1]
		local okOld, old = pcall(function()
			return failures.get(victim)
		end)
		if okOld then
			pushRestore(function()
				pcall(function()
					failures.set(victim, old)
				end)
			end)
		end
		local setOk = pcall(function()
			failures.set(victim, 1)
		end)
		local measured = setOk and loadFailureTotal() or 0
		local failed = measured >= 1
		emit("CAL_LOAD_FAILURES_FAIL", failed, failed and 1 or 0, 1, { victim = victim, measured = measured })
		if failed then
			calPass += 1
		end
		runRestores()
	end

	-- CAL CROSS_OVERLAP: two collidable parts owned by DIFFERENT candidates, same AABB.
	do
		local a = YES_IDS[1]
		local b = YES_IDS[2]
		local p = Vector3.new(350, 2, 350) -- outside the perf proxy and away from staged geometry
		newTaggedPart(a, "Q248_CAL_OVERLAP_A", Vector3.new(2, 2, 2), p, true)
		newTaggedPart(b, "Q248_CAL_OVERLAP_B", Vector3.new(2, 2, 2), p + Vector3.new(0.2, 0, 0.2), true)
		local calParts = collectParts()
		local calPairCount = measureOverlap(calParts)
		local failed = calPairCount >= 1
		emit("CAL_CROSS_OVERLAP_FAIL", failed, failed and 1 or 0, 1, { pairs = calPairCount, owners = { a, b } })
		if failed then
			calPass += 1
		end
		runRestores()
	end

	-- CAL PERF_BUDGET: 501 real Parts at the proxy centre push the count past 500.
	do
		for index = 1, PERF_TARGET + 1 do
			newTaggedPart(
				YES_IDS[1],
				"Q248_CAL_PERF_" .. index,
				Vector3.new(0.1, 0.1, 0.1),
				Vector3.new(0, 0.1, 0),
				false
			)
		end
		local count, errors = measurePerf()
		local failed = errors == 0 and count > PERF_TARGET
		emit("CAL_PERF_BUDGET_FAIL", failed, failed and 1 or 0, 1, { measured = count, readErrors = errors })
		if failed then
			calPass += 1
		end
		runRestores()
	end

	-- CAL GATE_CLEAR: one staged-owned part at a junction/gate corridor centre.
	do
		local corridor = CORRIDORS[1]
		newTaggedPart(
			YES_IDS[1],
			"Q248_CAL_GATE",
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(corridor.x, 1, corridor.z),
			false
		)
		local calParts = collectParts()
		local hits = measureGateHits(calParts)
		local failed = hits > 0
		emit("CAL_GATE_CLEAR_FAIL", failed, failed and 1 or 0, 1, { hits = hits })
		if failed then
			calPass += 1
		end
		runRestores()
	end

	-- CAL LANE_CLEAR: one staged-owned block across the first live MapSpec door ray.
	do
		local door = doorList[1]
		if door then
			newTaggedPart(
				YES_IDS[1],
				"Q248_CAL_LANE",
				Vector3.new(2, 2, 2),
				door.origin + door.normal * (DOOR_RAY_LENGTH * 0.5),
				false
			)
			local calParts = collectParts()
			local blocked, errors = measureLaneBlocked(doorList, calParts)
			local failed = errors == 0 and blocked > 0
			emit("CAL_LANE_CLEAR_FAIL", failed, failed and 1 or 0, 1, { blocked = blocked, door = door.key })
			if failed then
				calPass += 1
			end
		else
			emit("CAL_LANE_CLEAR_FAIL", false, 0, 1, { reason = "no live MapSpec doors" })
		end
		runRestores()
	end

	-- CAL PATH_REACH: one target moved 5000 studs up; the same 16-route measure must miss it.
	do
		local routesCal, totalCal = measurePaths(1)
		local failed = routesCal < routes and totalCal == 16
		emit("CAL_PATH_REACH_FAIL", failed, failed and 1 or 0, 1, { baseline = routes, measured = routesCal })
		if failed then
			calPass += 1
		end
	end

	-- Every injection is gone before the clean unstage and the leak signature diff.
	runRestores()
	pcall(review.disableAll)
	local after = snapshot()
	local leak, leakOffenders = diffSignatures(baseline, after)
	local leakValue = leak or 1
	emit("LOOKDEV_LEAK", leak == 0, leakValue, 0, {
		offenders = leakOffenders,
		stageFailures = stageFailures,
		restored = after ~= nil,
	})

	-- CAL LOOKDEV_LEAK: a part injected AFTER disableAll survives it, so the diff must be > 0.
	do
		local leftover = Instance.new("Part")
		leftover.Name = "Q248_LEAK_CALIBRATION"
		leftover.Size = Vector3.new(0.2, 0.2, 0.2)
		leftover.CFrame = CFrame.new(0, 0.1, 0)
		leftover.Anchored = true
		leftover.CanCollide = false
		leftover.CastShadow = false
		leftover.Parent = workspace
		pushRestore(function()
			leftover:Destroy()
		end)
		pcall(review.disableAll)
		local calAfter = snapshot()
		local calDelta, calOffenders = diffSignatures(baseline, calAfter)
		local failed = type(calDelta) == "number" and calDelta >= 1
		emit("CAL_LOOKDEV_LEAK_FAIL", failed, failed and 1 or 0, 1, { delta = calDelta, offenders = calOffenders })
		if failed then
			calPass += 1
		end
		runRestores()
	end

	-- CAL STAGE_COUNT: after the clean unstage the registry is the 0-id baseline. Stage one real,
	-- non-yes id through the SAME API; the count read by STAGE_COUNT must move off that baseline.
	do
		local baseAdditive = LookDev.additiveIds()
		local baseCount = type(baseAdditive) == "table" and #baseAdditive or 0
		local extra = nil
		for _, id in ipairs(LookDev.IDS) do
			if not YES_SET[id] then
				extra = id
				break
			end
		end
		if extra then
			local stageOk, staged = pcall(review.enableAdditive, extra, game, { studio = true })
			local calAdditive = LookDev.additiveIds()
			local calCount = type(calAdditive) == "table" and #calAdditive or 0
			local failed = stageOk and staged ~= false and calCount > baseCount
			emit("CAL_STAGE_COUNT_FAIL", failed, failed and 1 or 0, 1, {
				extra = extra,
				baseline = baseCount,
				count = calCount,
			})
			if failed then
				calPass += 1
			end
		else
			emit("CAL_STAGE_COUNT_FAIL", false, 0, 1, { reason = "no non-yes LookDev.IDS entry" })
		end
	end
end)

-- Restore on every path: injections first, all staging second, the prior active candidate last.
runRestores()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
if priorId and LookDev and type(LookDev.enable) == "function" then
	pcall(function()
		LookDev.enable(priorId, { studio = true })
	end)
end

if not ok then
	auditError = tostring(err)
end
for _, name in ipairs(CHECK_NAMES) do
	emitOnce(name, false, name == "CROSS_OVERLAP" and "ERR collidable pairs" or 1, TARGETS[name] or 0, {
		reason = "item 248 audit error: " .. tostring(auditError),
	})
end

printSummary()
return results
