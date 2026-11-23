--!nocheck
-- check_q250: WORK_QUEUE item 250, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a fresh Play session. Stages each paired candidate via LookDevReview.enableAdditive,
-- measures SubjectCoverage and CAMERA_GRASS from the re-aimed camera, proves CAMERA_CLEAR for the
-- item-218 variants, prints verbatim CHECK lines and restores with disableAll() on every path.
--
--   SC250_<ID>       staged candidate visible fraction >= 0.15 from its item-250 camera
--   CG250_<ID>       0 item-250 camera eyes/rays fail CAMERA_GRASS (4 / 3 / 12)
--   CAMERA_CLEAR_218 0 opaque hits in the first 6 studs for all eight item-218 variants
--
-- CALIBRATION ANCHORS (single lines; change the injected state, never the targets):
--   * CAMERA_GRASS: OLD_EYES[1].eye is the recorded sprint-2 path_curve 5.25-stud eye.
--     CAL_CAMERA_GRASS_OLD_250 must see >=1 FAIL from the old set.
--   * CAMERA_CLEAR: a temporary opaque Part 2 studs along the first variant's eye ray makes
--     CAL_CAMERA_CLEAR_218_BLOCK see >=1 hit. Destroyed before return.

local results = { checks = {}, byName = {} }

local PAIRS = {
	{ id = "road_fence_r10", camera = "path_curve", sc = "SC250_ROAD_FENCE_R10", cg = "CG250_ROAD_FENCE_R10" },
	{
		id = "ditch_water_r10",
		camera = "ditch_water_close",
		sc = "SC250_DITCH_WATER_R10",
		cg = "CG250_DITCH_WATER_R10",
	},
	{
		id = "crop_stages_r10",
		camera = "crop_stages_close",
		sc = "SC250_CROP_STAGES_R10",
		cg = "CG250_CROP_STAGES_R10",
	},
	{
		id = "hill_dressing_r10",
		camera = "terrace_wall",
		sc = "SC250_HILL_DRESSING_R10",
		cg = "CG250_HILL_DRESSING_R10",
	},
	{ id = "hubveg_r8", camera = "hub_warung", sc = "SC250_HUBVEG_R8", cg = "CG250_HUBVEG_R8" },
}
local NEW_218 = {
	"plaza_centre_golden",
	"plaza_centre_night",
	"pasar_awnings_golden",
	"pasar_awnings_night",
	"path_curve_golden",
	"path_curve_night",
	"lamp_night_golden",
	"lamp_night_night",
}
local CAL_GRASS = "CAL_CAMERA_GRASS_OLD_250"
local CAL_CLEAR = "CAL_CAMERA_CLEAR_218_BLOCK"
local CHECK_NAMES = {}
for _, pair in ipairs(PAIRS) do
	CHECK_NAMES[#CHECK_NAMES + 1] = pair.sc
	CHECK_NAMES[#CHECK_NAMES + 1] = pair.cg
end
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_GRASS
CHECK_NAMES[#CHECK_NAMES + 1] = "CAMERA_CLEAR_218"
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_CLEAR

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

-- Recorded sprint-2 eyes from docs/v2/visual/REVIEW_CAMERAS.md; same set as review_check_visual.luau.
local OLD_EYES = {
	{ name = "path_curve", eye = { 90, 5.25, -26 }, look = { 90, 1.1, -10 } },
	{ name = "ditch_water_close", eye = { 42.6443, 12, -131.2458 }, look = { 46.9706, 10, -144.5606 } },
	{ name = "ditch_water_close_look", eye = { 46.9706, 10, -144.5606 }, look = { 65.2026, 0.58, -200.6729 } },
	{ name = "hill_dressing_via_terrace_wall", eye = { -120, 37.5, -318 }, look = { -120, 16.5, -238 } },
	{ name = "hub_warung", eye = { 113.799, 9.5, -26.201 }, look = { 68, 12.5, -68 } },
}

-- hubveg_r8 stages real BaseParts under LookDevHubVegR8 / Hub attributes, not LookDevStage, so
-- SubjectCoverage.collectParts finds none and measures 0. Mirror LookDevStage onto those staged parts
-- for the measurement only, then restore the exact prior attribute values before disableAll().
local hubvegTagged = {}

local function tagStagedHubveg(shared)
	local okData, Data = pcall(function()
		return require(shared:WaitForChild("ModelMapVegetationHubR8"))
	end)
	if not okData or type(Data) ~= "table" or type(Data.folderName) ~= "string" then
		return 0
	end
	local okFolder, folder = pcall(function()
		return workspace:FindFirstChild(Data.folderName)
	end)
	if not okFolder or not folder then
		return 0
	end
	local okDesc, descendants = pcall(function()
		return folder:GetDescendants()
	end)
	if not okDesc or type(descendants) ~= "table" then
		return 0
	end
	local count = 0
	for _, instance in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okPart and isPart then
			local okGet, saved = pcall(function()
				return instance:GetAttribute("LookDevStage")
			end)
			local okSet = pcall(function()
				instance:SetAttribute("LookDevStage", "hubveg_r8")
			end)
			if okGet and okSet then
				hubvegTagged[#hubvegTagged + 1] = { part = instance, saved = saved }
				count += 1
			end
		end
	end
	return count
end

local function restoreStagedHubveg()
	for index = #hubvegTagged, 1, -1 do
		local entry = hubvegTagged[index]
		pcall(function()
			entry.part:SetAttribute("LookDevStage", entry.saved)
		end)
		hubvegTagged[index] = nil
	end
end

local review, blocker = nil, nil

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	local Grass = require(shared:WaitForChild("CameraGrass"))
	review = require(shared:WaitForChild("LookDevReview"))
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	local terrain = game:GetService("Workspace"):FindFirstChildOfClass("Terrain")
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(Grass) ~= "table"
		or type(Grass.evaluate) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
		or not terrain
	then
		error("SubjectCoverage / CameraGrass / LookDevReview / ReviewCameras / Terrain API missing")
	end

	local cache = {}
	local function readColumn(x, z)
		local x0, y0, z0, x1, y1, z1 = Grass.regionFor(x, z)
		local key = x0 .. ":" .. z0
		if cache[key] then
			return cache[key]
		end
		local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
		local okRead, materials, occupancies = pcall(function()
			return terrain:ReadVoxels(region, Grass.VOXEL)
		end)
		local column
		if okRead and type(materials) == "table" and type(occupancies) == "table" then
			column = Grass.column(materials, occupancies, x, z)
		else
			column = { ok = false, reason = "ReadVoxels failed: " .. tostring(occupancies) }
		end
		cache[key] = column
		return column
	end

	local clearDistance = tonumber(Cameras.clearDistance) or 6
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = {}
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			excluded[#excluded + 1] = player.Character
		end
	end
	params.FilterDescendantsInstances = excluded

	local function clearHits(cameraName)
		local entry = Cameras.get(cameraName)
		if type(entry) ~= "table" or type(entry.position) ~= "table" or type(entry.lookAt) ~= "table" then
			return 1
		end
		local eye = Vector3.new(entry.position[1], entry.position[2], entry.position[3])
		local look = Vector3.new(entry.lookAt[1], entry.lookAt[2], entry.lookAt[3])
		local dir = look - eye
		if dir.Magnitude <= 0 then
			return 1
		end
		local hit = workspace:Raycast(eye, dir.Unit * clearDistance, params)
		if not hit or not hit.Instance then
			return 0
		end
		local okTransparency, transparency = pcall(function()
			return hit.Instance.Transparency
		end)
		if okTransparency and type(transparency) == "number" and transparency < 0.5 then
			return 1
		end
		return 0
	end

	for _, pair in ipairs(PAIRS) do
		pcall(review.disableAll)
		local staged, why = review.enableAdditive(pair.id, game)
		if not staged then
			emit(pair.sc, false, "0.0000", "0.15", { staged = false, reason = why, camera = pair.camera })
			emit(pair.cg, false, 1, 0, { staged = false, reason = why, camera = pair.camera })
		else
			-- hubveg_r8 uses its own stage attribute; mirror it onto the real staged parts for this
			-- measurement. Count is diagnostic only: the fraction still comes from coverage.measure.
			local taggedCount = 0
			if pair.id == "hubveg_r8" then
				taggedCount = tagStagedHubveg(shared)
			end
			-- CALIBRATION ANCHOR (SC): move the camera or shrink the staged subject before this line
			-- to make the measurement fail; never lower the 0.15 target.
			local measured = coverage.measure(pair.id, pair.camera)
			emit(pair.sc, measured.ok == true and measured.fraction >= 0.15, shown(measured.fraction), "0.15", {
				fraction = measured.fraction,
				id = pair.id,
				camera = pair.camera,
				detail = measured,
				stageReason = why,
				taggedParts = taggedCount,
			})

			local camera = Cameras.get(pair.camera)
			local result = Grass.evaluate(camera.position, camera.lookAt, readColumn)
			emit(pair.cg, result.ok == true, result.ok and 0 or 1, 0, {
				camera = pair.camera,
				eyeClearance = result.eyeClearance,
				lowEye = result.lowEye,
				lowGrassHits = result.lowGrassHits,
				samples = result.samples,
				reason = result.reason,
			})
		end
		restoreStagedHubveg()
		pcall(review.disableAll)
	end

	-- Non-vacuous CAMERA_GRASS calibration from the recorded sprint-2 OLD eyes.
	local oldFailed, oldDetails = 0, {}
	for _, entry in ipairs(OLD_EYES) do
		local result = Grass.evaluate(entry.eye, entry.look, readColumn)
		if not result.ok then
			oldFailed += 1
			oldDetails[#oldDetails + 1] = {
				name = entry.name,
				eyeClearance = result.eyeClearance,
				lowEye = result.lowEye,
				lowGrassHits = result.lowGrassHits,
			}
		end
	end
	local calibrated = oldFailed >= 1
	emit(CAL_GRASS, calibrated, calibrated and 1 or 0, 1, {
		checked = #OLD_EYES,
		failed = oldFailed,
		entries = oldDetails,
	})

	-- Item 218 CAMERA_CLEAR proof: aggregate every new variant, then inject a blocker for the FAIL.
	local blocked, clearDetails = 0, {}
	for _, name in ipairs(NEW_218) do
		local hits = clearHits(name)
		clearDetails[name] = hits
		blocked += hits
	end
	emitOnce("CAMERA_CLEAR_218", blocked == 0, blocked, 0, {
		checked = #NEW_218,
		hits = clearDetails,
		clearDistance = clearDistance,
	})

	local first = Cameras.get(NEW_218[1])
	if type(first) == "table" then
		local eye = Vector3.new(first.position[1], first.position[2], first.position[3])
		local look = Vector3.new(first.lookAt[1], first.lookAt[2], first.lookAt[3])
		local direction = (look - eye).Unit
		blocker = Instance.new("Part")
		blocker.Name = "Q250_CC_BLOCKER"
		blocker.Size = Vector3.new(2, 2, 2)
		blocker.CFrame = CFrame.lookAt(eye + direction * 2, eye)
		blocker.Anchored = true
		blocker.CanCollide = false
		blocker.Transparency = 0
		blocker.Parent = workspace
		local hitCount = clearHits(NEW_218[1])
		emit(CAL_CLEAR, hitCount >= 1, hitCount, 1, { camera = NEW_218[1], clearDistance = clearDistance })
		pcall(function()
			blocker:Destroy()
		end)
		blocker = nil
	else
		emit(CAL_CLEAR, false, 0, 1, { reason = "first item-218 camera missing" })
	end
end)

pcall(function()
	if review then
		review.disableAll()
	end
end)
restoreStagedHubveg()
pcall(function()
	if blocker then
		blocker:Destroy()
	end
end)

if not ok then
	local reason = { reason = "item 250 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target: any = "0.15"
		if name:find("CG250_", 1, true) or name == "CAMERA_CLEAR_218" then
			target = 0
		elseif name == CAL_GRASS or name == CAL_CLEAR then
			target = 1
		end
		emitOnce(name, false, 0, target, reason)
	end
end

return results
