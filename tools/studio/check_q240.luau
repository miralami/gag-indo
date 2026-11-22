--!nocheck
-- check_q240: WORK_QUEUE item 240, self-contained SERVER-VM Studio check. Paste this whole file into
-- execute_luau in a fresh Play session. For each re-aimed sprint-1 subject it stages the candidate
-- with LookDevReview.enableAdditive, measures SubjectCoverage, casts the standard CAMERA_CLEAR ray
-- from the paired review camera, prints verbatim CHECK lines, then restores with disableAll() in the
-- same call. No harness require, no place save, no visual verdict.
--
--   SC240_<ID>   candidate visible fraction >= 0.15 from its item-240 camera
--   CC240_<ID>   0 opaque hits within Cameras.clearDistance studs (6), Characters excluded
--
-- The lamp pair sets Lighting.ClockTime from `lamp_night.clockTime` (21) before staging and restores
-- the prior ClockTime afterwards. Nothing writes a lighting default or saves the place.
--
-- CALIBRATION ANCHORS (single lines; change the injected state, never the targets):
--   * SC240: `local measured = coverage.measure(pair.id, pair.camera)` is the pass measurement.
--     For the ditch pair, `local away = coverage.measure(pair.id, "horizon_north")` points the
--     camera away from the staged subject; CAL_SC240_AWAY must see fraction < 0.15.
--   * CC240: `local hit = workspace:Raycast(eye, dir.Unit * clearDistance, params)` is the clear
--     ray. A temporary opaque Part is injected 2 studs along the first camera's ray;
--     CAL_CC240_BLOCK must then see >= 1 hit. The blocker is destroyed before the next pair.
-- Targets stay 0.15 and 0; a poor camera is fixed by moving the camera, not by weakening them.

local results = { checks = {}, byName = {} }

local PAIRS = {
	{ id = "kampung_r10", camera = "kampung_view", sc = "SC240_KAMPUNG_R10", cc = "CC240_KAMPUNG_R10" },
	{ id = "road_fence_r10", camera = "path_curve", sc = "SC240_ROAD_FENCE_R10", cc = "CC240_ROAD_FENCE_R10" },
	{ id = "signposts_r10", camera = "signpost_pasar", sc = "SC240_SIGNPOSTS_R10", cc = "CC240_SIGNPOSTS_R10" },
	{
		id = "crop_stages_r10",
		camera = "crop_stages_close",
		sc = "SC240_CROP_STAGES_R10",
		cc = "CC240_CROP_STAGES_R10",
	},
	{
		id = "ditch_water_r10",
		camera = "ditch_water_close",
		sc = "SC240_DITCH_WATER_R10",
		cc = "CC240_DITCH_WATER_R10",
	},
	{ id = "lamps_r10", camera = "lamp_night", sc = "SC240_LAMPS_R10", cc = "CC240_LAMPS_R10" },
}
local CAL_SC = "CAL_SC240_AWAY"
local CAL_CC = "CAL_CC240_BLOCK"
local CHECK_NAMES = {}
for _, pair in ipairs(PAIRS) do
	CHECK_NAMES[#CHECK_NAMES + 1] = pair.sc
	CHECK_NAMES[#CHECK_NAMES + 1] = pair.cc
end
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_SC
CHECK_NAMES[#CHECK_NAMES + 1] = CAL_CC

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

local review, savedClock, blocker = nil, nil, nil

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	review = require(shared:WaitForChild("LookDevReview"))
	local Cameras = require(shared:WaitForChild("ReviewCameras"))
	if
		type(coverage) ~= "table"
		or type(coverage.measure) ~= "function"
		or type(review) ~= "table"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
		or type(Cameras) ~= "table"
		or type(Cameras.get) ~= "function"
	then
		error("SubjectCoverage / LookDevReview / ReviewCameras API missing")
	end

	local Lighting = game:GetService("Lighting")
	local clearDistance = tonumber(Cameras.clearDistance) or 6
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function refreshExcludes()
		local excluded = {}
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			if player.Character then
				excluded[#excluded + 1] = player.Character
			end
		end
		params.FilterDescendantsInstances = excluded
	end
	refreshExcludes()

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
		-- CALIBRATION ANCHOR (CC): this single ray is the CAMERA_CLEAR measurement.
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

	local function restoreClock()
		if savedClock then
			pcall(function()
				Lighting.ClockTime = savedClock.value
			end)
			savedClock = nil
		end
	end

	for _, pair in ipairs(PAIRS) do
		pcall(review.disableAll)
		restoreClock()

		local camera = Cameras.get(pair.camera)
		if type(camera) == "table" and type(camera.clockTime) == "number" then
			local okClock, prior = pcall(function()
				return Lighting.ClockTime
			end)
			if okClock then
				savedClock = { value = prior }
				pcall(function()
					Lighting.ClockTime = camera.clockTime
				end)
			end
		end

		local staged, why = review.enableAdditive(pair.id, game)
		if not staged then
			emit(pair.sc, false, "0.0000", "0.15", { staged = false, reason = why, camera = pair.camera })
			emit(pair.cc, false, 1, 0, { staged = false, reason = why, camera = pair.camera })
		else
			-- CALIBRATION ANCHOR (SC): move the camera or shrink the staged subject before this line
			-- to make the measurement fail; never change the 0.15 target in the emit below.
			local measured = coverage.measure(pair.id, pair.camera)
			emit(pair.sc, measured.ok == true and measured.fraction >= 0.15, shown(measured.fraction), "0.15", {
				fraction = measured.fraction,
				id = pair.id,
				camera = pair.camera,
				detail = measured,
				stageReason = why,
			})

			if pair.id == "ditch_water_r10" then
				-- CALIBRATION ANCHOR (SC FAIL): point away from the subject while it is still staged.
				local away = coverage.measure(pair.id, "horizon_north")
				-- Calibration is the negation of the SC pass condition (ok and fraction >= 0.15).
				-- Pointing away may yield ok=false with "no projected rects" (fraction 0): still a FAIL.
				local forcedFail = not (away.ok == true and away.fraction >= 0.15)
				emit(CAL_SC, forcedFail, forcedFail and 1 or 0, 1, {
					fraction = away.fraction,
					id = pair.id,
					camera = "horizon_north",
					reason = away.reason,
				})
			end

			local hits = clearHits(pair.camera)
			emit(pair.cc, hits == 0, hits, 0, {
				camera = pair.camera,
				clearDistance = clearDistance,
				id = pair.id,
			})

			if pair.id == "kampung_r10" and type(camera) == "table" then
				-- CALIBRATION ANCHOR (CC FAIL): inject an opaque Part 2 studs along the first eye ray.
				local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
				local look = Vector3.new(camera.lookAt[1], camera.lookAt[2], camera.lookAt[3])
				local direction = (look - eye).Unit
				blocker = Instance.new("Part")
				blocker.Name = "Q240_CC_BLOCKER"
				blocker.Size = Vector3.new(2, 2, 2)
				blocker.CFrame = CFrame.lookAt(eye + direction * 2, eye)
				blocker.Anchored = true
				blocker.CanCollide = false
				blocker.Transparency = 0
				blocker.Parent = workspace
				local blocked = clearHits(pair.camera)
				local forcedBlock = blocked >= 1
				emit(CAL_CC, forcedBlock, blocked, 1, { camera = pair.camera, clearDistance = clearDistance })
				pcall(function()
					blocker:Destroy()
				end)
				blocker = nil
			end
		end

		restoreClock()
		pcall(review.disableAll)
	end
end)

pcall(function()
	if review then
		review.disableAll()
	end
end)
pcall(restoreClock)
pcall(function()
	if blocker then
		blocker:Destroy()
	end
end)

if not ok then
	local reason = { reason = "item 240 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		local target: any = "0.15"
		if name == CAL_SC or name == CAL_CC then
			target = 1
		end
		emitOnce(name, false, 0, target, reason)
	end
end

return results
