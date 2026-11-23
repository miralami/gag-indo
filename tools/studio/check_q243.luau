--!nocheck
-- check_q243: WORK_QUEUE item 243, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages only mountains_r10 with enableAdditive,
-- measures the live DataModel, prints verbatim CHECK lines, then restores with disableAll() in this
-- same call. No harness require, no place save, no visual verdict.
--
--   SC243_MOUNTAINS      fraction >= 0.10 from horizon_north via SubjectCoverage.measure
--   MF243_MOUNTAIN_FAR   0 staged Mountain parts with X^2+Z^2 < 450^2
--   NC243_NO_COLLISION   0 staged Mountain parts with CanCollide == true
--   NB243_NO_GREY_BALL   0 staged candidate BaseParts that are a Ball, or SmoothPlastic with
--                        max(R,G,B)-min(R,G,B) < 18 (near-grey)
--
-- CALIBRATION ANCHORS: each measured line is a separate call so the state can be injected between
-- them. SC points at horizon_south (candidate behind the camera); MF injects a Mountain part at
-- the origin; NB injects a 2-stud grey SmoothPlastic Ball; NC flips one staged part's CanCollide.
-- All injections are destroyed/restored before the next measurement and in the final cleanup.
-- Targets stay 0.10 / 0 / 0 / 0; a weak silhouette is fixed in data, never by lowering a target.

local CANDIDATE_ID = "mountains_r10"
local COVERAGE_CAMERA = "horizon_north"
local COVERAGE_AWAY_CAMERA = "horizon_south"
local COVERAGE_TARGET = 0.10
local FAR_LIMIT = 450

local CHECK_NAMES = {
	"SC243_MOUNTAINS",
	"MF243_MOUNTAIN_FAR",
	"NC243_NO_COLLISION",
	"NB243_NO_GREY_BALL",
}
local CALIBRATION_NAMES = {
	"CAL_SC243_AWAY",
	"CAL_MF243_NEAR",
	"CAL_NC243_COLLIDE",
	"CAL_NB243_GREY_BALL",
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

local review = nil
local injected = {}
local collisionSaved = nil

local function stagedParts()
	local out = {}
	local ok, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return out
	end
	for _, instance in ipairs(descendants) do
		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if okBase and isBase then
			local okStage, stage = pcall(function()
				return instance:GetAttribute("LookDevStage")
			end)
			if okStage and stage == CANDIDATE_ID then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

local function isGrey(part)
	local okColour, colour = pcall(function()
		return part.Color
	end)
	if not okColour or not colour then
		return false
	end
	-- Color3 channels are 0..1; the 18-level grey ceiling is an 8-bit spread.
	local high = math.max(colour.R, colour.G, colour.B)
	local low = math.min(colour.R, colour.G, colour.B)
	return (high - low) * 255 < 18
end

local function measureStaged()
	local mountains, near, colliding, offenders = 0, 0, 0, 0
	for _, part in ipairs(stagedParts()) do
		local okTag, tagged = pcall(function()
			return part:GetAttribute("Mountain") == true
		end)
		if okTag and tagged then
			mountains += 1
			local okPosition, position = pcall(function()
				return part.CFrame.Position
			end)
			if
				okPosition
				and position
				and position.X * position.X + position.Z * position.Z < FAR_LIMIT * FAR_LIMIT
			then
				near += 1
			end
			local okCollision, collision = pcall(function()
				return part.CanCollide
			end)
			if okCollision and collision == true then
				colliding += 1
			end
		end

		-- Compare Enum items directly: tostring(Enum.PartType.Ball) is "Enum.PartType.Ball",
		-- not "Ball", so a string comparison would miss the injected calibration Ball.
		local okShape, shape = pcall(function()
			return part.Shape
		end)
		local okMaterial, material = pcall(function()
			return part.Material
		end)
		local greyBall = (okShape and shape == Enum.PartType.Ball)
			or (okMaterial and material == Enum.Material.SmoothPlastic and isGrey(part))
		if greyBall then
			offenders += 1
		end
	end
	return { mountains = mountains, near = near, colliding = colliding, offenders = offenders }
end

local function inject(options)
	local part = Instance.new("Part")
	part.Name = options.name
	part.Shape = options.ball and Enum.PartType.Ball or Enum.PartType.Block
	part.Size = Vector3.new(options.size[1], options.size[2], options.size[3])
	part.CFrame = CFrame.new(options.position[1], options.position[2], options.position[3])
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Color = options.color or Color3.fromRGB(90, 130, 134)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("Mountain", true)
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	part.Parent = workspace
	injected[#injected + 1] = part
	return part
end

local function destroyInjected()
	for index = #injected, 1, -1 do
		pcall(function()
			injected[index]:Destroy()
		end)
		injected[index] = nil
	end
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	review = require(shared:WaitForChild("LookDevReview"))
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("SubjectCoverage / LookDevReview API missing")
	end

	local staged, reason = review.enableAdditive(CANDIDATE_ID, game)

	-- CALIBRATION ANCHOR (SC PASS): the single SubjectCoverage call below is the pass measurement.
	local measured = coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)
	local coveragePass = staged == true and measured.ok == true and measured.fraction >= COVERAGE_TARGET
	emit("SC243_MOUNTAINS", coveragePass, shown(measured.fraction), shown(COVERAGE_TARGET), {
		fraction = measured.fraction,
		ok = measured.ok,
		candidate = CANDIDATE_ID,
		camera = COVERAGE_CAMERA,
		viewport = measured.viewport,
		sampleCount = measured.sampleCount,
		hitCount = measured.hitCount,
		reason = measured.reason or reason,
	})

	-- CALIBRATION ANCHOR (SC FAIL): point the same staged candidate at a camera that looks away.
	local away = coverage.measure(CANDIDATE_ID, COVERAGE_AWAY_CAMERA)
	local forcedAway = not (away.ok == true and away.fraction >= COVERAGE_TARGET)
	emit("CAL_SC243_AWAY", forcedAway, forcedAway and 1 or 0, 1, {
		fraction = away.fraction,
		camera = COVERAGE_AWAY_CAMERA,
		reason = away.reason,
	})

	local counts = measureStaged()
	local farDetail = { farLimit = FAR_LIMIT, mountains = counts.mountains, reason = reason }
	emit("MF243_MOUNTAIN_FAR", staged == true and counts.near == 0, counts.near, 0, farDetail)
	emit("NC243_NO_COLLISION", staged == true and counts.colliding == 0, counts.colliding, 0, {
		mountains = counts.mountains,
		reason = reason,
	})
	emit("NB243_NO_GREY_BALL", staged == true and counts.offenders == 0, counts.offenders, 0, {
		stagedParts = #stagedParts(),
		mountains = counts.mountains,
		reason = reason,
	})

	-- CALIBRATION ANCHOR (MF FAIL): a Mountain part at the origin must count as near.
	inject({
		name = "Q243_MF_NEAR",
		size = { 2, 2, 2 },
		position = { 0, 0, 0 },
		color = Color3.fromRGB(90, 130, 134),
	})
	local nearInjected = measureStaged().near
	emit("CAL_MF243_NEAR", nearInjected >= 1, nearInjected, 1, { farLimit = FAR_LIMIT })
	destroyInjected()

	-- CALIBRATION ANCHOR (NB FAIL): a grey SmoothPlastic Ball tagged as this candidate must count.
	inject({
		name = "Q243_GREY_BALL",
		ball = true,
		size = { 2, 2, 2 },
		position = { 0, 0, -600 },
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(128, 128, 128),
	})
	local ballInjected = measureStaged().offenders
	emit("CAL_NB243_GREY_BALL", ballInjected >= 1, ballInjected, 1, { shape = "Ball", material = "SmoothPlastic" })
	destroyInjected()

	-- CALIBRATION ANCHOR (NC FAIL): flip one staged part to CanCollide=true, then restore it.
	local parts = stagedParts()
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
			local collidingInjected = measureStaged().colliding
			emit("CAL_NC243_COLLIDE", collidingInjected >= 1, collidingInjected, 1, { injected = true })
			pcall(function()
				target.CanCollide = prior
			end)
			collisionSaved = nil
		end
	end
	if not results.byName["CAL_NC243_COLLIDE"] then
		emit("CAL_NC243_COLLIDE", false, 0, 1, { reason = "no staged part to flip" })
	end
end)

-- Restore every additively staged candidate and every injection, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
if collisionSaved then
	pcall(function()
		collisionSaved.part.CanCollide = collisionSaved.value
	end)
end
destroyInjected()

if not ok then
	local reason = { reason = "item 243 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target: any = 0
		if name == "SC243_MOUNTAINS" then
			target = shown(COVERAGE_TARGET)
		end
		emitOnce(name, false, 0, target, reason)
	end
	for _, name in ipairs(CALIBRATION_NAMES) do
		emitOnce(name, false, 0, 1, reason)
	end
end

return results
