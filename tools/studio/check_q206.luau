--!nocheck
-- check_q206: WORK_QUEUE item 206, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a fresh Play session. It measures the live DataModel BEFORE and AFTER staging
-- crop_stages_r10 with enableAdditive, prints verbatim CHECK lines, then restores with disableAll()
-- in the same call. No harness require, no place save, no visual verdict.
--
--   CROP_STAGE_HEIGHT  staged Parts exist AND 0 violations of bibit < tumbuh < siap
--   CROP_STAGE_COLOR   staged Parts exist AND 0 crop samples with siap/bibit distance < 0.15
--   CAMERA_SAMPLES     every plot_aerial_NN raycast first-hits a staged CropStage part in its plot
--
-- Every reading comes from live workspace descendants with attribute CropStage==true.
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a mismatch can be injected between them.
--   CROP_STAGE_HEIGHT FAIL: set one stage Part's "height" attribute below the previous stage.
--   CROP_STAGE_COLOR  FAIL: retint a siap canopy Part to bibit's colour (distance < 0.15).
--   CAMERA_SAMPLES    FAIL: deleting all staged Parts => no ray first-hits CropStage => FAIL 0/N.
--                           Also fails if a plot's cluster is moved off its own plot_aerial ray.

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

local CHECK_NAMES = { "CROP_STAGE_HEIGHT", "CROP_STAGE_COLOR", "CAMERA_SAMPLES" }
local CANDIDATE_ID = "crop_stages_r10"
local MIN_HUE_DISTANCE = 0.15
local PLOT_AERIAL_BACK = 40
local PLOT_AERIAL_RISE = 30

local review, Data, Failures, ReviewCameras, Game, Workspace = nil, nil, nil, nil, nil, nil

-- Same normalised RGB metric as Data.hueDistance, fed by live Color3 (0..1) samples.
local function colourDistance(first, second)
	return Data.hueDistance({ r = first.R * 255, g = first.G * 255, b = first.B * 255 }, {
		r = second.R * 255,
		g = second.G * 255,
		b = second.B * 255,
	})
end

local function measure()
	local heights, canopies, positions = {}, {}, {}
	local staged, errors = 0, 0

	local okDescendants, descendants = pcall(function()
		return Workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		errors += 1
	else
		for _, instance in ipairs(descendants) do
			local okTag, tagged = pcall(function()
				return instance:GetAttribute("CropStage") == true
			end)
			if okTag and tagged then
				staged += 1
				local okRead, read = pcall(function()
					return {
						stage = instance:GetAttribute("stage"),
						height = instance:GetAttribute("height"),
						role = instance:GetAttribute("CropStageRole"),
						crop = instance:GetAttribute("crop"),
						color = instance.Color,
						position = instance.CFrame.Position,
					}
				end)
				if not okRead or type(read) ~= "table" then
					errors += 1
				elseif read.stage ~= "bibit" and read.stage ~= "tumbuh" and read.stage ~= "siap" then
					errors += 1
				elseif type(read.height) ~= "number" or not read.color or not read.position then
					errors += 1
				else
					local cropKey = read.crop or Data.REFERENCE_CROP
					heights[cropKey] = heights[cropKey] or {}
					heights[cropKey][read.stage] = read.height
					if read.role == "canopy" then
						canopies[cropKey] = canopies[cropKey] or {}
						canopies[cropKey][read.stage] = read.color
					end
					positions[#positions + 1] = read.position
				end
			end
		end
	end

	local heightViolations = 0
	for _, stages in pairs(heights) do
		local bibit, tumbuh, siap = stages.bibit, stages.tumbuh, stages.siap
		if
			type(bibit) ~= "number"
			or type(tumbuh) ~= "number"
			or type(siap) ~= "number"
			or not (bibit < tumbuh and tumbuh < siap)
		then
			heightViolations += 1
		end
	end

	local colorViolations = 0
	for _, stages in pairs(canopies) do
		local bibit, siap = stages.bibit, stages.siap
		if not bibit or not siap then
			colorViolations += 1
		else
			local okDistance, distance = pcall(colourDistance, bibit, siap)
			if not okDistance or type(distance) ~= "number" or distance < MIN_HUE_DISTANCE then
				colorViolations += 1
			end
		end
	end

	local loadFailures = 0
	if Failures and type(Failures.get) == "function" then
		local okFailures, count = pcall(Failures.get, CANDIDATE_ID)
		if okFailures and type(count) == "number" then
			loadFailures = count
		end
	end

	return {
		staged = staged,
		errors = errors,
		heightViolations = heightViolations,
		colorViolations = colorViolations,
		positions = positions,
		loadFailures = loadFailures,
	}
end

local function sampleCameras()
	local sampled = 0

	for _, name in ipairs(Data.CAMERA_NAMES) do
		-- Each plot_aerial_NN camera aims at its OWN plot cluster, never a single shared demo plot.
		local index = tonumber(string.match(name, "(%d+)$")) or Data.DEMO_PLOT
		local centre = nil
		if type(Data.demoCentreFor) == "function" then
			local okCentre, value = pcall(Data.demoCentreFor, index)
			if okCentre then
				centre = value
			end
		end
		if not centre then
			centre = Data.demoCentre()
		end
		local target = Vector3.new(centre[1], centre[2], centre[3])
		local eye = nil
		if ReviewCameras and type(ReviewCameras.get) == "function" then
			local okCam, camera = pcall(ReviewCameras.get, name)
			if okCam and camera and camera.position then
				local okEye, value = pcall(function()
					return Vector3.new(camera.position[1], camera.position[2], camera.position[3])
				end)
				if okEye then
					eye = value
				end
			end
		end
		if not eye and Game then
			local px, pz = Game.plotCenter(index)
			local radius = math.sqrt(px * px + pz * pz)
			if radius > 0 then
				local okEye, value = pcall(function()
					return Vector3.new(
						px - (px / radius) * PLOT_AERIAL_BACK,
						Data.GROUND_Y + PLOT_AERIAL_RISE,
						pz - (pz / radius) * PLOT_AERIAL_BACK
					)
				end)
				if okEye then
					eye = value
				end
			end
		end

		if eye then
			local delta = target - eye
			local length = delta.Magnitude
			if length > 0 then
				local okRay, hit = pcall(function()
					return Workspace:Raycast(eye, delta / length * (length + 10))
				end)
				if okRay and hit then
					local okHit, tagged = pcall(function()
						return hit.Instance and hit.Instance:GetAttribute("CropStage") == true
					end)
					if okHit and tagged then
						sampled += 1
					end
				end
			end
		end
	end

	return sampled, #Data.CAMERA_NAMES
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapCropStagesR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))
	Game = require(shared:WaitForChild("Config").Game)
	Workspace = game:GetService("Workspace")
	local okRegistry, registry = pcall(function()
		return require(shared:WaitForChild("ReviewCameras"))
	end)
	if okRegistry then
		ReviewCameras = registry
	end

	if type(Data) ~= "table" or type(Data.stageParts) ~= "function" or type(Data.hueDistance) ~= "function" then
		error("ModelMapCropStagesR10 API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	-- CALIBRATION ANCHOR (AFTER).
	local after = measure()

	local heightDetail = {
		["before.violations"] = before.heightViolations,
		afterViolations = after.heightViolations,
		beforeStaged = before.staged,
		afterStaged = after.staged,
		readErrors = after.errors,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	local heightPass = after.staged > 0 and after.heightViolations == 0
	local heightMeasured = if heightPass then after.heightViolations else 0
	emit("CROP_STAGE_HEIGHT", heightPass, heightMeasured, 0, heightDetail)

	local colorDetail = {
		["before.violations"] = before.colorViolations,
		afterViolations = after.colorViolations,
		minDistance = MIN_HUE_DISTANCE,
		readErrors = after.errors,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	local colorPass = after.staged > 0 and after.colorViolations == 0
	local colorMeasured = if colorPass then after.colorViolations else 0
	emit("CROP_STAGE_COLOR", colorPass, colorMeasured, 0, colorDetail)

	local sampled, cameraCount = sampleCameras()
	local cameraDetail = {
		beforeStaged = before.staged,
		afterStaged = after.staged,
		cameraCount = cameraCount,
		loadFailures = after.loadFailures,
		reason = enableReason,
	}
	emit(
		"CAMERA_SAMPLES",
		sampled == cameraCount and cameraCount > 0 and after.staged > 0,
		sampled,
		cameraCount,
		cameraDetail
	)
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
	local cameraTarget = 10
	if Data and type(Data.CAMERA_NAMES) == "table" then
		cameraTarget = #Data.CAMERA_NAMES
	end
	for _, name in ipairs(CHECK_NAMES) do
		local target = if name == "CAMERA_SAMPLES" then cameraTarget else 0
		emitOnce(name, false, 0, target, reason)
	end
end

return results
