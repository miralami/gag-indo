--!nocheck
-- check_q254: WORK_QUEUE item 254, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY crop_stages_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores with disableAll() on every path. No harness require, no place save, no visual verdict.
--
--   CROP_STAGE_HEIGHT  staged Parts exist AND 0 violations of bibit < tumbuh < siap (check_q206 logic)
--   CROP_STAGE_COLOR   staged Parts exist AND 0 siap/bibit colour distances < 0.15 (check_q206 logic)
--   CROP_STAGE_WIDTH   every (plot, stage) cluster's widest live Part >= 1.2 studs
--   NO_MELONS          zero Ball-shaped plant Parts among the staged CropStage set
--
-- CALIBRATION ANCHORS (non-vacuous): inject one thin tagged cluster -> min width drops below 1.2 ->
-- `CHECK CAL_CROP_STAGE_WIDTH_FAIL PASS 1 1`; inject one tagged Ball part -> melons rise above 0 ->
-- `CHECK CAL_NO_MELONS_FAIL PASS 1 1`. Injections are destroyed after each anchor and on exit.
-- The measure() moments are separate single lines so a mismatch can be injected between them.

local CANDIDATE_ID = "crop_stages_r10"
local MIN_WIDTH = 1.2
local MIN_HUE_DISTANCE = 0.15
local CHECK_NAMES = {
	"CROP_STAGE_HEIGHT",
	"CROP_STAGE_COLOR",
	"CROP_STAGE_WIDTH",
	"NO_MELONS",
	"CAL_CROP_STAGE_WIDTH_FAIL",
	"CAL_NO_MELONS_FAIL",
}
local CHECK_TARGETS = {
	CROP_STAGE_HEIGHT = 0,
	CROP_STAGE_COLOR = 0,
	CROP_STAGE_WIDTH = "1.2",
	NO_MELONS = 0,
	CAL_CROP_STAGE_WIDTH_FAIL = 1,
	CAL_NO_MELONS_FAIL = 1,
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

local review, Data, Failures, Workspace = nil, nil, nil, nil
local injected = {}

-- Same normalised RGB metric as Data.hueDistance, fed by live Color3 (0..1) samples.
local function colourDistance(first, second)
	return Data.hueDistance({ r = first.R * 255, g = first.G * 255, b = first.B * 255 }, {
		r = second.R * 255,
		g = second.G * 255,
		b = second.B * 255,
	})
end

local function descendants()
	local ok, list = pcall(function()
		return Workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list, 0
	end
	return {}, 1
end

-- Every reading comes from live workspace descendants with attribute CropStage==true.
local function measure()
	local all, readErrors = descendants()
	local heights, canopies, clusters = {}, {}, {}
	local staged, melons = 0, 0

	for _, instance in ipairs(all) do
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
					plot = instance:GetAttribute("plot"),
					color = instance.Color,
					position = instance.CFrame.Position,
					shape = instance.Shape,
					sizeX = instance.Size.X,
					sizeZ = instance.Size.Z,
				}
			end)
			if not okRead or type(read) ~= "table" then
				readErrors += 1
			elseif read.stage ~= "bibit" and read.stage ~= "tumbuh" and read.stage ~= "siap" then
				readErrors += 1
			elseif type(read.height) ~= "number" or not read.color or not read.position then
				readErrors += 1
			else
				local cropKey = read.crop or Data.REFERENCE_CROP
				heights[cropKey] = heights[cropKey] or {}
				heights[cropKey][read.stage] = read.height
				if read.role == "canopy" then
					canopies[cropKey] = canopies[cropKey] or {}
					canopies[cropKey][read.stage] = read.color
				end
				if read.shape == Enum.PartType.Ball then
					melons += 1
				end
				local clusterKey = tostring(read.plot) .. ":" .. read.stage
				local width = math.max(read.sizeX or 0, read.sizeZ or 0)
				clusters[clusterKey] = math.max(clusters[clusterKey] or 0, width)
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

	local minWidth, clusterCount = math.huge, 0
	for _, width in pairs(clusters) do
		clusterCount += 1
		if width < minWidth then
			minWidth = width
		end
	end
	if clusterCount == 0 then
		minWidth = 0
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
		errors = readErrors,
		heightViolations = heightViolations,
		colorViolations = colorViolations,
		minWidth = minWidth,
		clusterCount = clusterCount,
		melons = melons,
		loadFailures = loadFailures,
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

local function track(part)
	injected[#injected + 1] = part
end

-- One thin extra cluster: NO existing cluster loses its widest part, but the minimum drops.
local function injectNarrowCluster()
	local color = Data.STAGES[1].color
	local part = Instance.new("Part")
	part.Name = "Q254_WIDTH_CALIBRATION"
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(0, Data.GROUND_Y + 0.1, 0)
	part.Color = Color3.fromRGB(color.r, color.g, color.b)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("CropStage", true)
	part:SetAttribute("stage", Data.STAGES[1].stage)
	part:SetAttribute("plot", 9999)
	part:SetAttribute("height", Data.STAGES[1].height)
	part:SetAttribute("CropStageRole", "canopy")
	part:SetAttribute("crop", Data.REFERENCE_CROP)
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	part.Parent = Workspace
	track(part)
end

local function injectBall()
	local color = Data.STAGES[1].color
	local part = Instance.new("Part")
	part.Name = "Q254_NO_MELONS_CALIBRATION"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.4, 1.2, 1.4)
	part.CFrame = CFrame.new(0, Data.GROUND_Y + 0.6, 0)
	part.Color = Color3.fromRGB(color.r, color.g, color.b)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("CropStage", true)
	part:SetAttribute("stage", Data.STAGES[1].stage)
	part:SetAttribute("plot", 9998)
	part:SetAttribute("height", Data.STAGES[1].height)
	part:SetAttribute("CropStageRole", "canopy")
	part:SetAttribute("crop", Data.REFERENCE_CROP)
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	part.Parent = Workspace
	track(part)
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapCropStagesR10"))
	Failures = require(shared:WaitForChild("LookDevFailures"))
	Workspace = game:GetService("Workspace")

	if type(Data) ~= "table" or type(Data.stageParts) ~= "function" or type(Data.hueDistance) ~= "function" then
		error("ModelMapCropStagesR10 API missing")
	end

	-- CALIBRATION ANCHOR (BEFORE): a mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
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
		reason = reason,
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
		reason = reason,
	}
	local colorPass = after.staged > 0 and after.colorViolations == 0
	local colorMeasured = if colorPass then after.colorViolations else 0
	emit("CROP_STAGE_COLOR", colorPass, colorMeasured, 0, colorDetail)

	local expectedClusters = #Data.CAMERA_NAMES * #Data.STAGES
	local widthPass = after.staged > 0
		and after.errors == 0
		and after.clusterCount == expectedClusters
		and after.minWidth >= MIN_WIDTH
	emit("CROP_STAGE_WIDTH", widthPass, string.format("%.2f", after.minWidth), "1.2", {
		minWidth = string.format("%.2f", after.minWidth),
		clusterCount = after.clusterCount,
		expectedClusters = expectedClusters,
		staged = after.staged,
		readErrors = after.errors,
		reason = reason,
	})

	emit("NO_MELONS", after.staged > 0 and after.melons == 0, after.melons, 0, {
		melons = after.melons,
		staged = after.staged,
		readErrors = after.errors,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (CROP_STAGE_WIDTH FAIL): one thin tagged cluster must drop the minimum.
	injectNarrowCluster()
	local calWidth = measure()
	local widthFailed = calWidth.minWidth < MIN_WIDTH and calWidth.clusterCount > expectedClusters
	emit("CAL_CROP_STAGE_WIDTH_FAIL", widthFailed, widthFailed and 1 or 0, 1, {
		minWidth = string.format("%.2f", calWidth.minWidth),
		clusterCount = calWidth.clusterCount,
		expectedClusters = expectedClusters,
		injectedParts = #injected,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (NO_MELONS FAIL): one tagged Ball part must be counted.
	injectBall()
	local calMelons = measure()
	local melonsFailed = calMelons.melons > 0
	emit("CAL_NO_MELONS_FAIL", melonsFailed, melonsFailed and 1 or 0, 1, {
		melons = calMelons.melons,
		injectedParts = #injected,
	})
end)

-- Restore every additively staged candidate and every injection, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
destroyInjected()

if not ok then
	local reason = { reason = "item 254 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

return results
