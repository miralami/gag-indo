--!nocheck
-- check_q251: WORK_QUEUE item 251, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY mountains_r10 with enableAdditive,
-- measures the live DataModel, prints verbatim CHECK lines, then restores with disableAll() on every
-- path. No harness require, no place save, no visual verdict.
--
--   MOUNTAIN_DIST           nearest staged Mountain part >= 250 studs from horizon_north AND every spawn
--   NO_BOX_MOUNTAIN         0 staged Mountain-tagged Parts whose Shape == Enum.PartType.Block
--   SUBJECT_COVERAGE_251    >= 0.10 from horizon_north via SubjectCoverage.measure
--   SC251_MAX               <= 0.60 from the same measure (mountains must not fill the lens)
--   MOUNTAIN_FAR            0 staged Mountain parts with X^2+Z^2 < 450^2 (item 243, preserved)
--   NO_COLLISION            0 staged Mountain parts with CanCollide == true (item 243, preserved)
--
-- Distance uses the nearest point of each part's world AABB to each reference point, so a large far
-- wedge cannot hide a close face. References: horizon_north registry eye, MapSpec.SPAWN, every
-- MapSpec.NPC_SPOTS entry, every live SpawnLocation and every live NpcSpawn-tagged instance.
--
-- CALIBRATION ANCHORS (each fails its own check; all injections destroyed on every path):
--   CAL_MOUNTAIN_DIST_FAIL / CAL_NO_BOX_MOUNTAIN_FAIL / CAL_MOUNTAIN_FAR_FAIL: inject one near
--   Block Mountain part in front of horizon_north (12 studs away, inside the 450 origin ring).
--   CAL_SUBJECT_COVERAGE_251_FAIL: measure the same staged candidate from horizon_south (behind it).
--   CAL_SC251_MAX_FAIL: deep-zoom SubjectCoverage at the frontmost staged part via a deps override,
--   no world mutation, so the reported fraction must exceed 0.60.
--   CAL_NO_COLLISION_FAIL: flip one staged part to CanCollide=true, then restore its old value.
-- Targets stay 250 / 0 / 0.10 / 0.6 / 0 / 0; a weak silhouette is fixed in data, never by lowering
-- a target.

local CANDIDATE_ID = "mountains_r10"
local COVERAGE_CAMERA = "horizon_north"
local COVERAGE_AWAY_CAMERA = "horizon_south"
local MIN_COVERAGE = 0.10
local MAX_COVERAGE = 0.6
local MIN_DISTANCE = 250
local FAR_LIMIT = 450
local ZOOM_BACKOFF = 30

local CHECK_NAMES = {
	"MOUNTAIN_DIST",
	"NO_BOX_MOUNTAIN",
	"SUBJECT_COVERAGE_251",
	"SC251_MAX",
	"MOUNTAIN_FAR",
	"NO_COLLISION",
}
local CHECK_TARGETS = {
	MOUNTAIN_DIST = tostring(MIN_DISTANCE),
	NO_BOX_MOUNTAIN = 0,
	SUBJECT_COVERAGE_251 = "0.10",
	SC251_MAX = "0.6",
	MOUNTAIN_FAR = 0,
	NO_COLLISION = 0,
}
local CALIBRATION_NAMES = {
	"CAL_MOUNTAIN_DIST_FAIL",
	"CAL_NO_BOX_MOUNTAIN_FAIL",
	"CAL_SUBJECT_COVERAGE_251_FAIL",
	"CAL_SC251_MAX_FAIL",
	"CAL_MOUNTAIN_FAR_FAIL",
	"CAL_NO_COLLISION_FAIL",
}

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

local function shown(value)
	return string.format("%.4f", tonumber(value) or 0)
end

local function shownDist(value)
	return string.format("%.1f", tonumber(value) or 0)
end

local review = nil
local cameraRegistry = nil
local MapSpec = nil
local injected = {}
local collisionSaved = nil

local function worldDescendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

local function stagedParts()
	local out = {}
	for _, instance in ipairs(worldDescendants()) do
		pcall(function()
			if instance:IsA("BasePart") and instance:GetAttribute("LookDevStage") == CANDIDATE_ID then
				out[#out + 1] = instance
			end
		end)
	end
	return out
end

local function mountainParts()
	local out = {}
	for _, part in ipairs(stagedParts()) do
		pcall(function()
			if part:GetAttribute("Mountain") == true then
				out[#out + 1] = part
			end
		end)
	end
	return out
end

local function point(x, y, z, label)
	return { x = tonumber(x) or 0, y = tonumber(y) or 0, z = tonumber(z) or 0, label = label }
end

-- All reference points, read live where possible. MapSpec stays the static source for the player
-- spawn and the three NpcSpawn spots; live SpawnLocation / NpcSpawn instances are added too.
local function referencePoints()
	local points = {}
	local cameraPoint = nil
	if cameraRegistry and type(cameraRegistry.get) == "function" then
		local ok, entry = pcall(cameraRegistry.get, COVERAGE_CAMERA)
		if ok and entry and type(entry.position) == "table" then
			cameraPoint = point(entry.position[1], entry.position[2], entry.position[3], COVERAGE_CAMERA)
			points[#points + 1] = cameraPoint
		end
	end
	local spawnCount = 0
	if MapSpec and type(MapSpec) == "table" then
		local spawn = MapSpec.SPAWN
		if spawn then
			points[#points + 1] = point(spawn.x, spawn.y, spawn.z, "player_spawn")
			spawnCount += 1
		end
		for _, spot in ipairs(MapSpec.NPC_SPOTS or {}) do
			points[#points + 1] = point(spot.x, MapSpec.GROUND_Y, spot.z, "npc_spawn_" .. tostring(spot.npc))
			spawnCount += 1
		end
	end
	for _, instance in ipairs(worldDescendants()) do
		pcall(function()
			local position = nil
			if instance:IsA("SpawnLocation") then
				position = instance.CFrame.Position
			else
				local service = game:GetService("CollectionService")
				if service:HasTag(instance, "NpcSpawn") then
					local okFrame, frame = pcall(function()
						return instance:GetModelCFrame()
					end)
					position = okFrame and frame and frame.Position or instance.Position
				end
			end
			if position then
				points[#points + 1] = point(position.X, position.Y, position.Z, "live_" .. instance.Name)
				spawnCount += 1
			end
		end)
	end
	return points, cameraPoint, spawnCount
end

-- Exact for these identity-rotation Parts; the wedge/cylinder AABB is conservative for its silhouette.
local function aabbDistance(reference, part)
	local okFrame, frame = pcall(function()
		return part.CFrame
	end)
	local okSize, size = pcall(function()
		return part.Size
	end)
	if not okFrame or not okSize or not frame or not size then
		return nil
	end
	local position = frame.Position
	local function axis(delta, half)
		local outside = math.abs(delta) - half
		return outside > 0 and outside or 0
	end
	local dx = axis(reference.x - position.X, size.X / 2)
	local dy = axis(reference.y - position.Y, size.Y / 2)
	local dz = axis(reference.z - position.Z, size.Z / 2)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function measureMountains()
	local parts = mountainParts()
	local points, cameraPoint, spawnCount = referencePoints()
	local minDistance, minPair = math.huge, nil
	for _, part in ipairs(parts) do
		for _, reference in ipairs(points) do
			local distance = aabbDistance(reference, part)
			if distance and distance < minDistance then
				minDistance = distance
				minPair = { part = part.Name, reference = reference.label }
			end
		end
	end
	if minDistance == math.huge then
		minDistance = 0
	end

	local boxes, near, colliding = 0, 0, 0
	for _, part in ipairs(parts) do
		pcall(function()
			if part.Shape == Enum.PartType.Block then
				boxes += 1
			end
			local position = part.CFrame.Position
			if position.X * position.X + position.Z * position.Z < FAR_LIMIT * FAR_LIMIT then
				near += 1
			end
			if part.CanCollide == true then
				colliding += 1
			end
		end)
	end
	return {
		mountains = #parts,
		references = #points,
		cameraPoint = cameraPoint,
		spawnCount = spawnCount,
		minDistance = minDistance,
		minPair = minPair,
		boxes = boxes,
		near = near,
		colliding = colliding,
	}
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectNearBlock(cameraPoint)
	if not cameraPoint then
		return false
	end
	local ok, part = pcall(function()
		local made = Instance.new("Part")
		made.Name = "Q251_NEAR_BLOCK"
		made.Shape = Enum.PartType.Block
		made.Size = Vector3.new(6, 6, 6)
		made.CFrame = CFrame.new(cameraPoint.x, cameraPoint.y, cameraPoint.z - 12)
		made.Material = Enum.Material.Rock
		made.Color = Color3.fromRGB(90, 130, 134)
		made.Anchored = true
		made.CanCollide = false
		made.CastShadow = false
		made:SetAttribute("Mountain", true)
		made:SetAttribute("LookDevStage", CANDIDATE_ID)
		made.Parent = workspace
		return made
	end)
	if ok and part then
		injected[#injected + 1] = part
		return true
	end
	return false
end

-- No world mutation: feed SubjectCoverage a camera registry override with the eye 30 studs south
-- of the frontmost staged part, looking straight into it. All engine deps stay the live ones.
local function zoomMeasure(coverage)
	local target = nil
	local frontmostZ = -math.huge
	local bestVolume = -1
	for _, part in ipairs(stagedParts()) do
		pcall(function()
			local size, position = part.Size, part.CFrame.Position
			local frontZ = position.Z + size.Z / 2
			local volume = size.X * size.Y * size.Z
			if frontZ > frontmostZ or (frontZ == frontmostZ and volume > bestVolume) then
				frontmostZ = frontZ
				bestVolume = volume
				target = { position = { position.X, position.Y, position.Z }, size = { size.X, size.Y, size.Z } }
			end
		end)
	end
	if not target then
		return nil
	end
	local eye = {
		target.position[1],
		target.position[2],
		target.position[3] + target.size[3] / 2 + ZOOM_BACKOFF,
	}
	local look = { target.position[1], target.position[2], target.position[3] }
	local okDeps, deps = pcall(function()
		return {
			game = game,
			Instance = Instance,
			Vector2 = Vector2,
			Vector3 = Vector3,
			CFrame = CFrame,
			RaycastParams = RaycastParams,
			Enum = Enum,
			reviewCameras = {
				get = function(name)
					if name == COVERAGE_CAMERA then
						return { position = eye, lookAt = look }
					end
					return nil
				end,
			},
		}
	end)
	if not okDeps or not deps then
		return nil
	end
	return coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA, nil, deps)
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	review = require(shared:WaitForChild("LookDevReview"))
	cameraRegistry = require(shared:WaitForChild("ReviewCameras"))
	local okSpec, spec = pcall(function()
		return require(game:GetService("ServerScriptService").Server.World.MapSpec)
	end)
	MapSpec = okSpec and type(spec) == "table" and spec or nil
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(cameraRegistry) ~= "table"
		or type(cameraRegistry.get) ~= "function"
	then
		error("SubjectCoverage / LookDevReview / ReviewCameras API missing")
	end

	local staged, why = review.enableAdditive(CANDIDATE_ID, game)
	if staged ~= true then
		error("enableAdditive(" .. CANDIDATE_ID .. ") failed: " .. tostring(why))
	end

	-- The two coverage lines are the same single measure; one checks the floor, one the ceiling.
	local measured = coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)
	local fraction = tonumber(measured.fraction) or 0
	local coverageDetail = {
		fraction = fraction,
		ok = measured.ok,
		candidate = CANDIDATE_ID,
		camera = COVERAGE_CAMERA,
		viewport = measured.viewport,
		sampleCount = measured.sampleCount,
		hitCount = measured.hitCount,
		reason = measured.reason or why,
	}
	emit(
		"SUBJECT_COVERAGE_251",
		measured.ok == true and fraction >= MIN_COVERAGE,
		shown(fraction),
		"0.10",
		coverageDetail
	)
	emit("SC251_MAX", measured.ok == true and fraction <= MAX_COVERAGE, shown(fraction), "0.6", coverageDetail)

	-- CALIBRATION ANCHOR (coverage floor FAIL): same candidate, camera looking the other way.
	local away = coverage.measure(CANDIDATE_ID, COVERAGE_AWAY_CAMERA)
	local awayFraction = tonumber(away.fraction) or 0
	local awayFailed = not (away.ok == true and awayFraction >= MIN_COVERAGE)
	emit("CAL_SUBJECT_COVERAGE_251_FAIL", awayFailed, awayFailed and 1 or 0, 1, {
		fraction = shown(awayFraction),
		camera = COVERAGE_AWAY_CAMERA,
		reason = away.reason,
	})

	-- CALIBRATION ANCHOR (coverage ceiling FAIL): deep-zoom without moving any world part.
	local zoomed = zoomMeasure(coverage)
	local zoomFraction = zoomed and tonumber(zoomed.fraction) or 0
	local zoomFailed = zoomed ~= nil and zoomed.ok == true and zoomFraction > MAX_COVERAGE
	emit("CAL_SC251_MAX_FAIL", zoomFailed, zoomFailed and 1 or 0, 1, {
		fraction = shown(zoomFraction),
		backoff = ZOOM_BACKOFF,
		ok = zoomed and zoomed.ok or false,
		reason = zoomed and zoomed.reason or "no staged part to zoom",
	})

	local counts = measureMountains()
	local structuralDetail = {
		mountains = counts.mountains,
		references = counts.references,
		spawnReferences = counts.spawnCount,
		nearestPair = counts.minPair,
		camera = COVERAGE_CAMERA,
		farLimit = FAR_LIMIT,
		reason = why,
	}
	emit(
		"MOUNTAIN_DIST",
		counts.mountains > 0
			and counts.cameraPoint ~= nil
			and counts.spawnCount > 0
			and counts.minDistance >= MIN_DISTANCE,
		shownDist(counts.minDistance),
		tostring(MIN_DISTANCE),
		structuralDetail
	)
	emit("NO_BOX_MOUNTAIN", counts.mountains > 0 and counts.boxes == 0, counts.boxes, 0, structuralDetail)
	emit("MOUNTAIN_FAR", counts.mountains > 0 and counts.near == 0, counts.near, 0, structuralDetail)
	emit("NO_COLLISION", counts.mountains > 0 and counts.colliding == 0, counts.colliding, 0, structuralDetail)

	-- CALIBRATION ANCHORS (structural FAIL): one near Block Mountain part must break three checks.
	local injectedOk = injectNearBlock(counts.cameraPoint)
	local cal = measureMountains()
	local distFailed = injectedOk and cal.minDistance < MIN_DISTANCE and cal.mountains > counts.mountains
	emit("CAL_MOUNTAIN_DIST_FAIL", distFailed, distFailed and 1 or 0, 1, {
		minDistance = shownDist(cal.minDistance),
		mountains = cal.mountains,
	})
	local boxFailed = injectedOk and cal.boxes >= 1
	emit("CAL_NO_BOX_MOUNTAIN_FAIL", boxFailed, boxFailed and 1 or 0, 1, {
		boxes = cal.boxes,
		mountains = cal.mountains,
	})
	local farFailed = injectedOk and cal.near >= 1
	emit("CAL_MOUNTAIN_FAR_FAIL", farFailed, farFailed and 1 or 0, 1, {
		near = cal.near,
		farLimit = FAR_LIMIT,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (collision FAIL): flip one staged part and restore its old value.
	local parts = mountainParts()
	if #parts > 0 then
		local target = parts[1]
		local okSaved, prior = pcall(function()
			return target.CanCollide
		end)
		if okSaved then
			collisionSaved = { part = target, value = prior }
			pcall(function()
				target.CanCollide = true
			end)
			local colliding = measureMountains().colliding
			local collisionFailed = colliding >= 1
			emit("CAL_NO_COLLISION_FAIL", collisionFailed, collisionFailed and 1 or 0, 1, { colliding = colliding })
			pcall(function()
				target.CanCollide = prior
			end)
			collisionSaved = nil
		end
	end
	if not results.byName["CAL_NO_COLLISION_FAIL"] then
		emit("CAL_NO_COLLISION_FAIL", false, 0, 1, { reason = "no staged part to flip" })
	end
end)

-- Restore every mutation on every path: collision first, then all staged candidates and injections.
if collisionSaved then
	pcall(function()
		collisionSaved.part.CanCollide = collisionSaved.value
	end)
	collisionSaved = nil
end
destroyInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 251 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
	for _, name in ipairs(CALIBRATION_NAMES) do
		emitOnce(name, false, 0, 1, reason)
	end
end

return results
