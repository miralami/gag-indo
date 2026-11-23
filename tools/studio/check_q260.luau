--!nocheck
-- check_q260: WORK_QUEUE item 260 (terrain rebuild), self-contained SERVER-VM Studio check. Paste
-- this whole file into execute_luau in a FRESH Play session. It stages ONLY mountains_r10 with
-- enableAdditive (terrain ridges, no parts), samples the live terrain with downward raycasts that
-- accept Workspace.Terrain only, prints verbatim CHECK lines plus SUMMARY_Q260, then restores
-- every injection and calls LookDevReview.disableAll() on every path. No harness require, no place
-- save, no visual verdict (the look is judged from the hero shots, not from these numbers).
--
--   RIDGE_LAYERS     3 distinct ridge bands: along 72 bearings, terrain height is sampled every 10
--                    studs from radius 410 to 1200. A band counts when its crest window
--                    (640 / 820 / 1020 +-90) rises above 20 studs on at least half the bearings.
--   MOUNTAIN_DIST    >= 480: the smallest radius at which terrain rises above 8 studs on any bearing.
--   NO_BOX_MOUNTAIN  0 tagged Mountain parts (the candidate stages none) and 0 Block-shaped ones.
--
-- CALIBRATION ANCHORS (each must FAIL its own condition, then restore):
--   CAL_RIDGE_LAYERS_FAIL     disableAll() writes Air over the same shapes; the remeasure must count
--                             0 bands and no terrain above 8 studs. This also proves restore works.
--   CAL_NO_BOX_MOUNTAIN_FAIL  inject one tagged Block part; the box counter must read 1.
-- Both are detected as PASS 1 1; they prove the checks are not vacuous.

local CANDIDATE_ID = "mountains_r10"

local MIN_DISTANCE = 480
local BAND_CENTRES = { 640, 820, 1020 }
local BAND_WINDOW = 90
local BAND_MIN_HEIGHT = 20
local BAND_MIN_FRACTION = 0.5
local DIST_MIN_HEIGHT = 8

local BEARINGS = 72
local RADIUS_FROM = 410
local RADIUS_TO = 1200
local RADIUS_STEP = 10
local CAST_TOP = 500
local CAST_LENGTH = 700

local CHECK_NAMES = {
	"RIDGE_LAYERS",
	"MOUNTAIN_DIST",
	"NO_BOX_MOUNTAIN",
	"CAL_RIDGE_LAYERS_FAIL",
	"CAL_NO_BOX_MOUNTAIN_FAIL",
}
local MAIN_NAMES = { "RIDGE_LAYERS", "MOUNTAIN_DIST", "NO_BOX_MOUNTAIN" }
local CAL_NAMES = { "CAL_RIDGE_LAYERS_FAIL", "CAL_NO_BOX_MOUNTAIN_FAIL" }
local CHECK_TARGETS = {
	RIDGE_LAYERS = 3,
	MOUNTAIN_DIST = tostring(MIN_DISTANCE),
	NO_BOX_MOUNTAIN = 0,
	CAL_RIDGE_LAYERS_FAIL = 1,
	CAL_NO_BOX_MOUNTAIN_FAIL = 1,
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

local function passedCount(names)
	local count = 0
	for _, name in ipairs(names) do
		if results.byName[name] and results.byName[name].passed then
			count += 1
		end
	end
	return count
end

local review = nil
local injected = {}

local function worldDescendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	return ok and type(list) == "table" and list or {}
end

-- Tagged parts of this candidate. The terrain candidate stages none, so the count must stay 0.
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

local function countBoxes()
	local parts = mountainParts()
	local boxes = 0
	for _, part in ipairs(parts) do
		pcall(function()
			if part.Shape == Enum.PartType.Block then
				boxes += 1
			end
		end)
	end
	return #parts, boxes
end

-- Terrain surface height under (x, z), or 0 when the ray finds no terrain.
local function terrainHeight(params, x, z)
	local ok, result = pcall(function()
		return workspace:Raycast(Vector3.new(x, CAST_TOP, z), Vector3.new(0, -CAST_LENGTH, 0), params)
	end)
	if ok and result then
		return result.Position.Y
	end
	return 0
end

-- Height profile per bearing: profile[b][i] is the height at radius RADIUS_FROM + (i - 1) * STEP.
local function measureTerrain()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params:AddToFilter({ workspace.Terrain })
	params.IgnoreWater = true

	local radii = {}
	for radius = RADIUS_FROM, RADIUS_TO, RADIUS_STEP do
		radii[#radii + 1] = radius
	end
	local bandBearings = { 0, 0, 0 }
	local minRadius = math.huge
	local tallest = { 0, 0, 0 }
	for bearing = 0, BEARINGS - 1 do
		local rad = math.rad(bearing * 360 / BEARINGS)
		local cosA, sinA = math.cos(rad), math.sin(rad)
		local crest = { 0, 0, 0 }
		for _, radius in ipairs(radii) do
			local height = terrainHeight(params, cosA * radius, sinA * radius)
			if height > DIST_MIN_HEIGHT and radius < minRadius then
				minRadius = radius
			end
			for index, centre in ipairs(BAND_CENTRES) do
				if math.abs(radius - centre) <= BAND_WINDOW and height > crest[index] then
					crest[index] = height
				end
			end
		end
		for index = 1, #BAND_CENTRES do
			if crest[index] > BAND_MIN_HEIGHT then
				bandBearings[index] += 1
			end
			if crest[index] > tallest[index] then
				tallest[index] = crest[index]
			end
		end
	end
	local bands = 0
	for index = 1, #BAND_CENTRES do
		if bandBearings[index] / BEARINGS >= BAND_MIN_FRACTION then
			bands += 1
		end
	end
	if minRadius == math.huge then
		minRadius = 0
	end
	return { bands = bands, bandBearings = bandBearings, minRadius = minRadius, tallest = tallest }
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local function injectBox()
	local ok, part = pcall(function()
		local made = Instance.new("Part")
		made.Name = "Q260_BOX"
		made.Shape = Enum.PartType.Block
		made.Size = Vector3.new(60, 40, 40)
		made.CFrame = CFrame.new(0, 30, -750)
		made.Anchored = true
		made.CanCollide = false
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
	if
		type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("LookDevReview API missing")
	end

	local staged, why = review.enableAdditive(CANDIDATE_ID, game)
	if staged ~= true then
		error("enableAdditive(" .. CANDIDATE_ID .. ") failed: " .. tostring(why))
	end

	local terrain = measureTerrain()
	local parts, boxes = countBoxes()
	local detail = {
		bandBearings = terrain.bandBearings,
		tallest = terrain.tallest,
		bearings = BEARINGS,
		taggedParts = parts,
		reason = why,
	}
	emit("RIDGE_LAYERS", terrain.bands == #BAND_CENTRES, terrain.bands, #BAND_CENTRES, detail)
	emit(
		"MOUNTAIN_DIST",
		terrain.minRadius >= MIN_DISTANCE,
		string.format("%.1f", terrain.minRadius),
		tostring(MIN_DISTANCE),
		detail
	)
	emit("NO_BOX_MOUNTAIN", parts == 0 and boxes == 0 and terrain.bands > 0, boxes, 0, detail)

	-- CALIBRATION ANCHOR (RIDGE_LAYERS FAIL): restoring the candidate must remove every ridge.
	review.disableAll()
	local after = measureTerrain()
	local layersFailed = after.bands == 0 and after.minRadius == 0
	emit("CAL_RIDGE_LAYERS_FAIL", layersFailed, layersFailed and 1 or 0, 1, {
		beforeBands = terrain.bands,
		afterBands = after.bands,
		afterMinRadius = after.minRadius,
	})

	-- CALIBRATION ANCHOR (NO_BOX_MOUNTAIN FAIL): one tagged Block part must be counted as a box.
	local injectedOk = injectBox()
	local calParts, calBoxes = countBoxes()
	local boxFailed = injectedOk and calBoxes == 1 and calParts == 1
	emit("CAL_NO_BOX_MOUNTAIN_FAIL", boxFailed, boxFailed and 1 or 0, 1, {
		injected = injectedOk,
		boxes = calBoxes,
		parts = calParts,
	})
	destroyInjected()
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
