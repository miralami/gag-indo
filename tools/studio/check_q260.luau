--!nocheck
-- check_q260: WORK_QUEUE item 260, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY mountains_r10 with enableAdditive,
-- measures the live DataModel, prints verbatim CHECK lines plus SUMMARY_Q260, then restores every
-- injection and calls LookDevReview.disableAll() on every path. No harness require, no place save,
-- no visual verdict. check_q251 is deliberately untouched: its MOUNTAIN_FAR >=450 conflicts with
-- item 260's 300-stud near band.
--
--   MOUNTAIN_DISTANCE  >= 250 studs: nearest point of any tagged Mountain part's AABB to the
--                       `spawn` review camera eye (ReviewCameras.get("spawn"), not a literal).
--   NO_BOX_MOUNTAIN    0 tagged Mountain parts with Shape == Enum.PartType.Block.
--   RIDGE_LAYERS       3 distinct north-distance bands at |z| = 300 / 450 / 600 studs (tolerance
--                      60); no tagged part outside those bands.
--   SKYLINE_COVER      0.15..0.40 of 64 horizon-band rays hit an opaque tagged Mountain part.
--                      Ray frame: from spawn eye, aimed at the ridge skyline (mean X/Z of the
--                      staged crests, mean crest Y) — the saved `spawn` camera faces the market
--                      south, so its own lookAt puts every north ridge behind the fan. Re-aiming
--                      centres the ridges, so the band is ny 0.35..0.60 (not the old 0.20..0.45).
--                      FOV 70, aspect 16:9, nx 0.02..0.98. Include filter on staged parts only.
--
-- CALIBRATION ANCHORS (each must FAIL its own condition, then restore):
--   CAL_RIDGE_LAYERS_FAIL   inject a fourth Wedge band at |z| = 750 -> 4 bands / an off-band part.
--   CAL_SKYLINE_COVER_FAIL  remeasure with an empty part set -> fraction 0, below the 0.15 floor.
-- Both are detected as PASS 1 1; they prove the checks are not vacuous. The structural checks are
-- measured before injection; only the fourth-band Wedge is ever added to the DataModel.

local CANDIDATE_ID = "mountains_r10"
local SPAWN_CAMERA = "spawn"

local MIN_DISTANCE = 250
local RIDGE_BANDS = { 300, 450, 600 }
local BAND_TOLERANCE = 60
local SKYLINE_MIN = 0.15
local SKYLINE_MAX = 0.40

local SAMPLES = 8
local RAYS_PER_CAMERA = SAMPLES * SAMPLES -- 64
local HORIZON_TOP = 0.35
local HORIZON_BOTTOM = 0.60
local FOV_DEG = 70
local ASPECT = 16 / 9
local RAY_LENGTH = 5000
local OPAQUE_LIMIT = 0.5

local CHECK_NAMES = {
	"MOUNTAIN_DISTANCE",
	"NO_BOX_MOUNTAIN",
	"RIDGE_LAYERS",
	"SKYLINE_COVER",
	"CAL_RIDGE_LAYERS_FAIL",
	"CAL_SKYLINE_COVER_FAIL",
}
local MAIN_NAMES = { "MOUNTAIN_DISTANCE", "NO_BOX_MOUNTAIN", "RIDGE_LAYERS", "SKYLINE_COVER" }
local CAL_NAMES = { "CAL_RIDGE_LAYERS_FAIL", "CAL_SKYLINE_COVER_FAIL" }
local CHECK_TARGETS = {
	MOUNTAIN_DISTANCE = tostring(MIN_DISTANCE),
	NO_BOX_MOUNTAIN = 0,
	RIDGE_LAYERS = 3,
	SKYLINE_COVER = "0.15..0.40",
	CAL_RIDGE_LAYERS_FAIL = 1,
	CAL_SKYLINE_COVER_FAIL = 1,
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

local function passedCount(names)
	local count = 0
	for _, name in ipairs(names) do
		if results.byName[name] and results.byName[name].passed then
			count += 1
		end
	end
	return count
end

local review, Cameras = nil, nil
local injected = {}

local function worldDescendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	return ok and type(list) == "table" and list or {}
end

-- Only this candidate's staged parts count. The applier sets both attributes on every descriptor.
local function mountainParts()
	local out = {}
	for _, instance in ipairs(worldDescendants()) do
		pcall(function()
			if
				instance:IsA("BasePart")
				and instance:GetAttribute("LookDevStage") == CANDIDATE_ID
				and instance:GetAttribute("Mountain") == true
			then
				out[#out + 1] = instance
			end
		end)
	end
	return out
end

local function opaqueMountainParts()
	local out = {}
	for _, part in ipairs(mountainParts()) do
		pcall(function()
			if part.Transparency < OPAQUE_LIMIT then
				out[#out + 1] = part
			end
		end)
	end
	return out
end

local function spawnEye()
	if type(Cameras) ~= "table" or type(Cameras.get) ~= "function" then
		return nil
	end
	local ok, camera = pcall(Cameras.get, SPAWN_CAMERA)
	if not ok or not camera or type(camera.position) ~= "table" then
		return nil
	end
	return { x = camera.position[1], y = camera.position[2], z = camera.position[3] }
end

-- Same nearest-AABB-point method as check_q251: a huge far wedge cannot hide a close face.
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

local function measureStructure()
	local eye = spawnEye()
	local parts = mountainParts()
	local minDistance, minPart = math.huge, nil
	local boxes, offBand = 0, 0
	local seen = {}
	for _, part in ipairs(parts) do
		if eye then
			local distance = aabbDistance(eye, part)
			if distance and distance < minDistance then
				minDistance = distance
				minPart = part.Name
			end
		end
		pcall(function()
			if part.Shape == Enum.PartType.Block then
				boxes += 1
			end
			local z = math.abs(part.CFrame.Position.Z)
			local matched = false
			for index, band in ipairs(RIDGE_BANDS) do
				if math.abs(z - band) <= BAND_TOLERANCE then
					matched = true
					seen[index] = true
					break
				end
			end
			if not matched then
				offBand += 1
			end
		end)
	end
	if minDistance == math.huge then
		minDistance = 0
	end
	local bands = 0
	for index = 1, #RIDGE_BANDS do
		if seen[index] then
			bands += 1
		end
	end
	return {
		parts = #parts,
		eye = eye,
		minDistance = minDistance,
		minPart = minPart,
		boxes = boxes,
		bands = bands,
		offBand = offBand,
	}
end

local function unit(v)
	local length = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
	if length <= 0 then
		return { 0, 0, 0 }
	end
	return { v[1] / length, v[2] / length, v[3] / length }
end

local function cross(a, b)
	return {
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1],
	}
end

-- Mean X/Z of the staged opaque parts, mean crest Y (part centre + half height).
local function ridgeCentroid(parts)
	local count, sumX, sumZ, sumCrestY = 0, 0, 0, 0
	for _, part in ipairs(parts) do
		pcall(function()
			local position, size = part.CFrame.Position, part.Size
			sumX += position.X
			sumZ += position.Z
			sumCrestY += position.Y + size.Y / 2
			count += 1
		end)
	end
	if count == 0 then
		return nil
	end
	return { sumX / count, sumCrestY / count, sumZ / count }
end

-- `parts` is passed in so the CAL_ leg can remeasure with an empty set without mutating the world.
-- From spawn eye, aimed at the ridge skyline: the saved spawn camera looks south at the market.
local function measureSkyline(parts)
	local eye = spawnEye()
	local centroid = ridgeCentroid(parts)
	if not eye or not centroid then
		return { hits = 0, rays = RAYS_PER_CAMERA, fraction = 0, eye = eye, parts = #parts }
	end
	local okFrame, frame = pcall(function()
		return CFrame.lookAt(Vector3.new(eye.x, eye.y, eye.z), Vector3.new(centroid[1], centroid[2], centroid[3]))
	end)
	if not okFrame or not frame then
		return { hits = 0, rays = RAYS_PER_CAMERA, fraction = 0, eye = eye, parts = #parts }
	end

	local params = RaycastParams.new()
	params.IgnoreWater = false
	params.FilterType = Enum.RaycastFilterType.Include
	params:AddToFilter(parts)

	local forward = unit({ centroid[1] - eye.x, centroid[2] - eye.y, centroid[3] - eye.z })
	local right = unit(cross(forward, { 0, 1, 0 }))
	local up = unit(cross(right, forward))
	local tanV = math.tan(math.rad(FOV_DEG) / 2)
	local tanH = tanV * ASPECT

	local hits = 0
	for iy = 0, SAMPLES - 1 do
		local ny = HORIZON_TOP + (HORIZON_BOTTOM - HORIZON_TOP) * iy / (SAMPLES - 1)
		for ix = 0, SAMPLES - 1 do
			local nx = 0.02 + 0.96 * ix / (SAMPLES - 1)
			local sx = (2 * nx - 1) * tanH
			local sy = (1 - 2 * ny) * tanV
			local direction = unit({
				forward[1] + right[1] * sx + up[1] * sy,
				forward[2] + right[2] * sx + up[2] * sy,
				forward[3] + right[3] * sx + up[3] * sy,
			})
			local okRay, result = pcall(function()
				return workspace:Raycast(
					frame.Position,
					Vector3.new(direction[1], direction[2], direction[3]) * RAY_LENGTH,
					params
				)
			end)
			if okRay and result then
				hits += 1
			end
		end
	end
	return { hits = hits, rays = RAYS_PER_CAMERA, fraction = hits / RAYS_PER_CAMERA, eye = eye, parts = #parts }
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectFourthBand()
	local ok, part = pcall(function()
		local made = Instance.new("Part")
		made.Name = "Q260_FOURTH_BAND"
		made.Shape = Enum.PartType.Wedge
		made.Size = Vector3.new(60, 40, 40)
		made.CFrame = CFrame.new(0, 30, -750)
		made.Material = Enum.Material.Rock
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

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Cameras = require(shared:WaitForChild("ReviewCameras"))
	if
		type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
	then
		error("LookDevReview / ReviewCameras API missing")
	end
	if not spawnEye() then
		error(SPAWN_CAMERA .. " has no numeric position in ReviewCameras")
	end

	local staged, why = review.enableAdditive(CANDIDATE_ID, game)
	if staged ~= true then
		error("enableAdditive(" .. CANDIDATE_ID .. ") failed: " .. tostring(why))
	end

	local structure = measureStructure()
	local detail = {
		camera = SPAWN_CAMERA,
		eye = structure.eye,
		parts = structure.parts,
		nearestPart = structure.minPart,
		bands = structure.bands,
		offBand = structure.offBand,
		reason = why,
	}
	emit(
		"MOUNTAIN_DISTANCE",
		structure.parts > 0 and structure.eye ~= nil and structure.minDistance >= MIN_DISTANCE,
		shownDist(structure.minDistance),
		tostring(MIN_DISTANCE),
		detail
	)
	emit("NO_BOX_MOUNTAIN", structure.parts > 0 and structure.boxes == 0, structure.boxes, 0, detail)
	emit(
		"RIDGE_LAYERS",
		structure.parts > 0 and structure.bands == #RIDGE_BANDS and structure.offBand == 0,
		structure.bands,
		#RIDGE_BANDS,
		detail
	)

	local opaque = opaqueMountainParts()
	local skyline = measureSkyline(opaque)
	emit(
		"SKYLINE_COVER",
		#opaque > 0 and skyline.fraction >= SKYLINE_MIN and skyline.fraction <= SKYLINE_MAX,
		shown(skyline.fraction),
		"0.15..0.40",
		{
			hits = skyline.hits,
			rays = skyline.rays,
			opaqueParts = skyline.parts,
			camera = SPAWN_CAMERA,
			aim = "ridge skyline",
			band = { HORIZON_TOP, HORIZON_BOTTOM },
			fov = FOV_DEG,
			aspect = ASPECT,
			eye = skyline.eye,
			reason = why,
		}
	)

	-- CALIBRATION ANCHOR (RIDGE_LAYERS FAIL): a fourth band must be counted as off-pattern.
	local injectedOk = injectFourthBand()
	local calStructure = measureStructure()
	local layersFailed = injectedOk
		and calStructure.parts > structure.parts
		and (calStructure.bands > #RIDGE_BANDS or calStructure.offBand > 0)
	emit("CAL_RIDGE_LAYERS_FAIL", layersFailed, layersFailed and 1 or 0, 1, {
		injected = injectedOk,
		beforeBands = structure.bands,
		afterBands = calStructure.bands,
		offBand = calStructure.offBand,
		parts = calStructure.parts,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (SKYLINE_COVER FAIL): no tagged ridge parts means no skyline hits.
	local empty = measureSkyline({})
	local coverFailed = empty.fraction < SKYLINE_MIN
	emit("CAL_SKYLINE_COVER_FAIL", coverFailed, coverFailed and 1 or 0, 1, {
		fraction = shown(empty.fraction),
		parts = empty.parts,
		rays = empty.rays,
	})
end)

-- Restore every mutation on every path: injected part first, then all staged candidates.
destroyInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 260 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

print(
	string.format(
		"SUMMARY_Q260 MAIN %d/%d CAL %d/%d",
		passedCount(MAIN_NAMES),
		#MAIN_NAMES,
		passedCount(CAL_NAMES),
		#CAL_NAMES
	)
)

return results
