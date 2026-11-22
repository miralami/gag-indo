--!nocheck
-- check_p182: WORK_QUEUE section P item 182, self-contained SERVER-VM Studio check. Paste the whole
-- file into execute_luau in a fresh Play session. It stages ONLY blocks_r9 via enableAdditive, reads
-- the live staged Parts, prints the four CHECK lines and calls disableAll() in cleanup even on error.
-- No harness require, no place save, no visual verdict.
--
-- BLOCK_TREES counts staged baked trees whose world-centre sits in the item's village ring (radius
-- 60..140), NOT the global tree count: at HEAD that is 4, post-fix 68. PERF_BUDGET mirrors the r8
-- harness proxy (BaseParts whose centre is within 100 studs of the origin, target 500). WALKABLE
-- probes six MapSpec hub-door lanes; GATE_CLEAR probes ten MapSpec/Game plot gates. A missing folder,
-- gate, lane or unreadable geometry is a FAIL, never a skip.

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

local RING_MIN, RING_MAX = 60, 140
local TREE_TARGET = 60
local PERF_TARGET = 500
local LANE_HALF, LANE_LENGTH = 3, 24
local OVERLAP_TOL = 0.05

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local function centreOf(inst)
	local ok, centre = pcall(function()
		if inst:IsA("Model") then
			return select(1, inst:GetBoundingBox()).Position
		end
		if inst:IsA("BasePart") then
			return inst.CFrame.Position
		end
		return nil
	end)
	return ok and centre or nil
end

-- Rotation-aware world AABB from CFrame:VectorToWorldSpace of the absolute half-extents (the same
-- convention the checked-in harness uses; VectorToWorldVector is not a member here).
local function partAABB(part)
	local ok, box = pcall(function()
		local cf, size = part.CFrame, part.Size
		local ex = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
		local ey = cf:VectorToWorldSpace(Vector3.new(0, size.Y / 2, 0))
		local ez = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
		local function axis(a, b, c)
			return { x = a.X + b.X + c.X, y = a.Y + b.Y + c.Y, z = a.Z + b.Z + c.Z }
		end
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local corner = axis(
						Vector3.new(ex.X * sx, ex.Y * sx, ex.Z * sx),
						Vector3.new(ey.X * sy, ey.Y * sy, ey.Z * sy),
						Vector3.new(ez.X * sz, ez.Y * sz, ez.Z * sz)
					)
					minX, maxX = math.min(minX, corner.x), math.max(maxX, corner.x)
					minY, maxY = math.min(minY, corner.y), math.max(maxY, corner.y)
					minZ, maxZ = math.min(minZ, corner.z), math.max(maxZ, corner.z)
				end
			end
		end
		return { minX = minX, maxX = maxX, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ }
	end)
	return ok and box or nil
end

local function overlaps(a, b)
	return math.min(a.maxX, b.maxX) - math.max(a.minX, b.minX) > OVERLAP_TOL
		and math.min(a.maxY, b.maxY) - math.max(a.minY, b.minY) > OVERLAP_TOL
		and math.min(a.maxZ, b.maxZ) - math.max(a.minZ, b.minZ) > OVERLAP_TOL
end

local review = nil
local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	local Data = require(shared:WaitForChild("ModelMapBlocksR9"))
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	local Game = require(shared:WaitForChild("Config").Game)

	local enabled, why = review.enableAdditive("blocks_r9", game)
	if not enabled then
		error("enableAdditive(blocks_r9) failed: " .. tostring(why))
	end
	local folder = workspace:FindFirstChild(Data.folderName)
	if not folder then
		error("staging folder missing: " .. tostring(Data.folderName))
	end

	local stagedModels, stagedParts, collidable = {}, {}, {}
	for _, inst in ipairs(folder:GetDescendants()) do
		if attr(inst, "LookDevBlocksR9") == Data.id then
			stagedModels[#stagedModels + 1] = inst
		end
		if inst:IsA("BasePart") then
			stagedParts[#stagedParts + 1] = inst
			local okCollide, collides = pcall(function()
				return inst.CanCollide
			end)
			if okCollide and collides == true then
				collidable[#collidable + 1] = inst
			end
		end
	end
	if #stagedModels == 0 or #stagedParts == 0 then
		error("blocks_r9 staged no tagged models or parts")
	end

	-- BLOCK_TREES -------------------------------------------------------------
	local bandTrees, bandShrubs, bandGrass, treeSpecies = 0, 0, 0, {}
	for _, model in ipairs(stagedModels) do
		local centre = centreOf(model)
		if centre then
			local radius = math.sqrt(centre.X * centre.X + centre.Z * centre.Z)
			local inBand = radius >= RING_MIN and radius <= RING_MAX
			if attr(model, "BlockTree") == true then
				local height = attr(model, "BlockTreeHeight")
				if type(height) == "number" and height >= Data.TREE_HEIGHT_MIN and height <= Data.TREE_HEIGHT_MAX then
					if inBand then
						bandTrees += 1
					end
					local species = attr(model, "BlockSpecies")
					if type(species) == "string" and species ~= "" then
						treeSpecies[species] = true
					end
				end
			end
			if attr(model, "BlockShrub") == true and inBand then
				bandShrubs += 1
				if attr(model, "BlockGrass") == true then
					bandGrass += 1
				end
			end
		end
	end
	local speciesCount = 0
	for _ in pairs(treeSpecies) do
		speciesCount += 1
	end
	emit("BLOCK_TREES", bandTrees >= TREE_TARGET, bandTrees, TREE_TARGET, {
		measurement = "staged trees with centre in radius 60..140",
		stagedModels = #stagedModels,
		bandShrubs = bandShrubs,
		bandGrass = bandGrass,
		species = speciesCount,
	})

	-- PERF_BUDGET -------------------------------------------------------------
	local perfParts, perfReadErrors = 0, 0
	local okScene, scene = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okScene or type(scene) ~= "table" then
		perfReadErrors += 1
		scene = {}
	end
	for _, inst in ipairs(scene) do
		local okPart, isPart = pcall(function()
			return inst:IsA("BasePart")
		end)
		if not okPart then
			perfReadErrors += 1
		elseif isPart then
			local centre = centreOf(inst)
			if centre then
				if centre.X * centre.X + centre.Y * centre.Y + centre.Z * centre.Z <= 100 * 100 then
					perfParts += 1
				end
			else
				perfReadErrors += 1
			end
		end
	end
	emit("PERF_BUDGET", perfReadErrors == 0 and perfParts <= PERF_TARGET, perfParts, PERF_TARGET, {
		proxy = "BaseParts within 100 studs of (0,0,0)",
		readErrors = perfReadErrors,
	})

	-- WALKABLE ---------------------------------------------------------------
	local lanes, laneErrors = {}, {}
	for _, key in ipairs(MapSpec.HUB_ORDER) do
		local hub = MapSpec.hub(key)
		if not hub then
			laneErrors[#laneErrors + 1] = key .. ":no-hub"
		else
			local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
			for _, corner in ipairs({
				{ -LANE_HALF, hub.depth / 2 },
				{ LANE_HALF, hub.depth / 2 },
				{ -LANE_HALF, hub.depth / 2 + LANE_LENGTH },
				{ LANE_HALF, hub.depth / 2 + LANE_LENGTH },
			}) do
				local okPoint, x, z = pcall(function()
					return MapSpec.hubPoint(hub, corner[1], corner[2])
				end)
				if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
					laneErrors[#laneErrors + 1] = key .. ":bad-corner"
					break
				end
				minX, maxX = math.min(minX, x), math.max(maxX, x)
				minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
			end
			lanes[#lanes + 1] = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, y = MapSpec.GROUND_Y }
		end
	end
	local walkBlocked = 0
	for _, lane in ipairs(lanes) do
		local gauge = {
			minX = lane.minX,
			maxX = lane.maxX,
			minY = lane.y,
			maxY = lane.y + MapSpec.HEADROOM,
			minZ = lane.minZ,
			maxZ = lane.maxZ,
		}
		for _, part in ipairs(collidable) do
			local box = partAABB(part)
			if box and overlaps(box, gauge) then
				walkBlocked += 1
			end
		end
	end
	emit("WALKABLE", #lanes == #MapSpec.HUB_ORDER and #laneErrors == 0 and walkBlocked == 0, walkBlocked, 0, {
		lanes = #lanes,
		collidableStagedParts = #collidable,
		errors = laneErrors,
	})

	-- GATE_CLEAR -------------------------------------------------------------
	local gates, gateErrors = {}, {}
	local gateRadius = MapSpec.ROAD.ringCentre + MapSpec.ROAD.ringWidth / 2 + MapSpec.S
	for index = 1, Game.plotCount do
		local px, pz = Game.plotCenter(index)
		local radius = math.sqrt(px * px + pz * pz)
		if radius <= 0 then
			gateErrors[#gateErrors + 1] = "P" .. index .. ":bad-centre"
		else
			local gx, gz = px / radius * gateRadius, pz / radius * gateRadius
			gates[#gates + 1] = {
				minX = gx - 3,
				maxX = gx + 3,
				minY = MapSpec.GROUND_Y,
				maxY = MapSpec.GROUND_Y + MapSpec.HEADROOM,
				minZ = gz - 3,
				maxZ = gz + 3,
			}
		end
	end
	local gateHits = 0
	for _, gate in ipairs(gates) do
		for _, part in ipairs(collidable) do
			local box = partAABB(part)
			if box and overlaps(box, gate) then
				gateHits += 1
			end
		end
	end
	-- Every staged plant is non-collidable by construction; a single collidable one is itself a
	-- gate-blocking defect even when it does not overlap a synthetic gate box.
	gateHits += #collidable
	emit("GATE_CLEAR", #gates == Game.plotCount and #gateErrors == 0 and gateHits == 0, gateHits, 0, {
		gates = #gates,
		collidableStagedParts = #collidable,
		errors = gateErrors,
	})
end)

pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	emit("BLOCK_TREES", false, 0, TREE_TARGET, reason)
	emit("PERF_BUDGET", false, 0, PERF_TARGET, reason)
	emit("WALKABLE", false, 1, 0, reason)
	emit("GATE_CLEAR", false, 1, 0, reason)
end

return results
