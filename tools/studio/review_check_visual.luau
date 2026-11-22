--!nocheck
-- review_check_visual: WORK_QUEUE item 217, self-contained SERVER-VM Studio check. Paste this whole
-- file into execute_luau in a fresh Play session. Pure-data audit: no staging, no place save, no
-- visual verdict. Prints verbatim CHECK lines, collects results.checks / results.byName, returns results.
--
--   NO_FLOATERS / NO_CUBE_SHRUBS / SIZE_SANITY  offenders in the shipped descriptor set, target 0
--   GOOD_SET_NONEMPTY   shipped descriptor count is > 0 (a vacuous pass is never a pass)
--   FIXTURE_*           each PASSES only when the bad fixture trips the matching predicate
--   AUDIT_PROBE         VisualRiskAudit.probeOk (the predicates classify hand-built samples)
--
-- CALIBRATION ANCHORS: `local goodSet = gatherGoodSet()` and `local fixtureParts = Fixture.parts()`
-- are separate single lines so a before/after mismatch can be injected between them. The three
-- goodSet predicate calls and the three fixture predicate calls are also one line each.

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

local CHECK_NAMES = {
	"NO_FLOATERS",
	"NO_CUBE_SHRUBS",
	"SIZE_SANITY",
	"GOOD_SET_NONEMPTY",
	"FIXTURE_NO_FLOATERS_FAILED",
	"FIXTURE_NO_CUBE_SHRUBS_FAILED",
	"FIXTURE_SIZE_SANITY_FAILED",
	"AUDIT_PROBE",
}
local TARGETS = {
	NO_FLOATERS = 0,
	NO_CUBE_SHRUBS = 0,
	SIZE_SANITY = 0,
	GOOD_SET_NONEMPTY = ">0",
	FIXTURE_NO_FLOATERS_FAILED = ">=1",
	FIXTURE_NO_CUBE_SHRUBS_FAILED = ">=1",
	FIXTURE_SIZE_SANITY_FAILED = ">=1",
	AUDIT_PROBE = 1,
}

-- Module -> descriptor function. Only a real function returning a descriptor table contributes to
-- goodSet; every skip is recorded as a note, never counted as a pass.
local CANDIDATES = {
	{ id = "horizon_fill_r10", module = "ModelMapHorizonFillR10", fn = "skirtParts" },
	{ id = "paths_curved_r10", module = "ModelMapPathsCurvedR10", fn = "parts" },
	{ id = "ground_variation_r10", module = "ModelMapGroundVariationR10", fn = "parts" },
	{ id = "meadow_r10", module = "ModelMapMeadowR10", fn = "parts" },
	{ id = "rocks_r9", module = "ModelMapRocksR9", fn = "parts" },
	{ id = "buildings_r8", module = "ModelMapBuildingsR8", fn = "parts" },
	{ id = "plots_r8", module = "ModelMapPlotsR8", fn = "parts" },
	{ id = "river_r8", module = "ModelMapRiverR8", fn = "parts" },
	{ id = "water_r8", module = "ModelMapWaterR8", fn = "parts" },
}

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Audit = require(shared:WaitForChild("VisualRiskAudit"))
	local Fixture = require(shared:WaitForChild("ModelMapVisualFixtureBad"))
	if type(Audit) ~= "table" or type(Audit.floaters) ~= "function" then
		error("VisualRiskAudit API missing")
	end
	if type(Fixture) ~= "table" or type(Fixture.parts) ~= "function" then
		error("ModelMapVisualFixtureBad API missing")
	end

	local notes = {}
	local function gatherGoodSet()
		local goodSet = {}
		for _, candidate in ipairs(CANDIDATES) do
			local okModule, loaded = pcall(function()
				return require(shared:WaitForChild(candidate.module))
			end)
			if not okModule or type(loaded) ~= "table" then
				notes[#notes + 1] = candidate.id .. ": require failed"
				continue
			end
			if type(loaded[candidate.fn]) ~= "function" then
				notes[#notes + 1] = candidate.id .. ": no " .. candidate.fn .. "()"
				continue
			end
			local okParts, parts = pcall(loaded[candidate.fn])
			if not okParts or type(parts) ~= "table" then
				notes[#notes + 1] = candidate.id .. ": " .. candidate.fn .. "() did not return a table"
				continue
			end
			for _, descriptor in ipairs(parts) do
				goodSet[#goodSet + 1] = descriptor
			end
		end
		return goodSet
	end

	local goodSet = gatherGoodSet() -- CALIBRATION ANCHOR: shipped candidates
	local fixtureParts = Fixture.parts() -- CALIBRATION ANCHOR: deliberately bad fixture

	local floaters = Audit.floaters(goodSet)
	local cubes = Audit.cubeShrubs(goodSet)
	local sizes = Audit.sizeSanity(goodSet)
	emit("NO_FLOATERS", #floaters == 0, #floaters, 0, { checked = #goodSet, offenders = floaters, skipped = notes })
	emit("NO_CUBE_SHRUBS", #cubes == 0, #cubes, 0, { checked = #goodSet, offenders = cubes, skipped = notes })
	emit("SIZE_SANITY", #sizes == 0, #sizes, 0, { checked = #goodSet, offenders = sizes, skipped = notes })
	emit("GOOD_SET_NONEMPTY", #goodSet > 0, #goodSet, ">0", { emptyIsFailure = Audit.emptyIsFailure, skipped = notes })

	local fixtureFloaters = Audit.floaters(fixtureParts)
	local fixtureCubes = Audit.cubeShrubs(fixtureParts)
	local fixtureSizes = Audit.sizeSanity(fixtureParts)
	emit(
		"FIXTURE_NO_FLOATERS_FAILED",
		#fixtureFloaters >= 1,
		#fixtureFloaters,
		">=1",
		{ checked = #fixtureParts, offenders = fixtureFloaters }
	)
	emit(
		"FIXTURE_NO_CUBE_SHRUBS_FAILED",
		#fixtureCubes >= 1,
		#fixtureCubes,
		">=1",
		{ checked = #fixtureParts, offenders = fixtureCubes }
	)
	emit(
		"FIXTURE_SIZE_SANITY_FAILED",
		#fixtureSizes >= 1,
		#fixtureSizes,
		">=1",
		{ checked = #fixtureParts, offenders = fixtureSizes }
	)

	local probeOk = Audit.probeOk == true
	emit("AUDIT_PROBE", probeOk, probeOk and 1 or 0, 1, { emptyIsFailure = Audit.emptyIsFailure })
end)

if not ok then
	local reason = { reason = "audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, TARGETS[name], reason)
	end
end

-- ------------------------------------------------------------------------------------------------
-- WORK_QUEUE item 239: SUBJECT_COVERAGE. Separate SERVER-VM block; item-217 checks above are kept
-- intact. The temporary fixture is destroyed and every staged candidate restored on every path.
--   SUBJECT_COVERAGE_FIXTURE        well-framed temporary part must measure >= 0.15
--   SUBJECT_COVERAGE_FIXTURE_FAIL   deliberately shrunk fixture must measure < 0.15 (calibration)
--   SUBJECT_COVERAGE_KAMPUNG_R10    sprint-1 pair expected < 0.15 (FAIL is the expected line)
--   SUBJECT_COVERAGE_DITCH_WATER_R10  sprint-1 pair expected < 0.15 (FAIL is the expected line)
--   SUBJECT_COVERAGE_PROBE          synthetic-data self-probe through the same sampling core
--
-- CALIBRATION ANCHORS (single lines): the `local good = coverage.measure(...)` line for the pass,
-- the `scFixture.Size = Vector3.new(0.2, 0.2, 0.2)` line for the fail. Inject a bad first opaque hit
-- to push a measurement down, or shrink the fixture further before the second measure to prove the
-- target bites. Staged-pair values are reported as measured; if one is >= 0.15, report it to the
-- main session for camera correction instead of weakening 0.15.

local SC_CHECK_NAMES = {
	"SUBJECT_COVERAGE_FIXTURE",
	"SUBJECT_COVERAGE_FIXTURE_FAIL",
	"SUBJECT_COVERAGE_FIXTURE_CALIBRATION",
	"SUBJECT_COVERAGE_KAMPUNG_R10",
	"SUBJECT_COVERAGE_DITCH_WATER_R10",
	"SUBJECT_COVERAGE_PROBE",
}
local SC_TARGETS = {
	SUBJECT_COVERAGE_FIXTURE = "0.15",
	SUBJECT_COVERAGE_FIXTURE_FAIL = "0.15",
	SUBJECT_COVERAGE_FIXTURE_CALIBRATION = 1,
	SUBJECT_COVERAGE_KAMPUNG_R10 = "0.15",
	SUBJECT_COVERAGE_DITCH_WATER_R10 = "0.15",
	SUBJECT_COVERAGE_PROBE = 1,
}
local scReview, scFixture = nil, nil

local function shown(value)
	return string.format("%.4f", tonumber(value) or 0)
end

local scOk, scErr = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local coverage = require(shared:WaitForChild("SubjectCoverage"))
	scReview = require(shared:WaitForChild("LookDevReview"))
	if type(coverage) ~= "table" or type(coverage.measure) ~= "function" or type(coverage.probe) ~= "function" then
		error("SubjectCoverage API missing")
	end
	if
		type(scReview) ~= "table"
		or type(scReview.enableAdditive) ~= "function"
		or type(scReview.disableAll) ~= "function"
	then
		error("LookDevReview staging API missing")
	end
	local registry = require(shared:WaitForChild("ReviewCameras"))
	local camera = registry.get("spawn")
	if type(camera) ~= "table" or type(camera.position) ~= "table" or type(camera.lookAt) ~= "table" then
		error("spawn review camera missing")
	end
	local eye = Vector3.new(camera.position[1], camera.position[2], camera.position[3])
	local look = Vector3.new(camera.lookAt[1], camera.lookAt[2], camera.lookAt[3])
	local centre = eye + (look - eye).Unit * 12

	scFixture = Instance.new("Part")
	scFixture.Name = "Q239_FIXTURE"
	scFixture.Size = Vector3.new(18, 12, 1)
	scFixture.CFrame = CFrame.lookAt(centre, eye)
	scFixture.Anchored = true
	scFixture.CanCollide = false
	scFixture.Transparency = 0
	scFixture:SetAttribute("LookDevStage", "Q239_FIXTURE")
	scFixture.Parent = game:GetService("Workspace")

	local good = coverage.measure("Q239_FIXTURE", "spawn") -- CALIBRATION ANCHOR: well-framed fixture
	emit("SUBJECT_COVERAGE_FIXTURE", good.ok == true and good.fraction >= 0.15, shown(good.fraction), "0.15", good)

	scFixture.Size = Vector3.new(0.2, 0.2, 0.2) -- CALIBRATION ANCHOR: deliberately unframed fixture
	local low = coverage.measure("Q239_FIXTURE", "spawn")
	emit("SUBJECT_COVERAGE_FIXTURE_FAIL", false, shown(low.fraction), "0.15", {
		measured = low.fraction,
		candidateId = "Q239_FIXTURE",
		camera = "spawn",
		reason = low.reason,
	})
	local bit = low.fraction < 0.15
	emit("SUBJECT_COVERAGE_FIXTURE_CALIBRATION", bit, bit and 1 or 0, 1, { measured = low.fraction })
	pcall(function()
		scFixture:Destroy()
	end)
	scFixture = nil

	local function stagedMeasure(candidateId, cameraName, checkName)
		pcall(function()
			scReview.disableAll()
		end)
		local staged, why = scReview.enableAdditive(candidateId, game)
		if not staged then
			emit(checkName, false, "0.0000", "0.15", { staged = false, reason = why })
			return
		end
		local measured = coverage.measure(candidateId, cameraName)
		local below = measured.fraction < 0.15
		emit(checkName, not below, shown(measured.fraction), "0.15", {
			measured = measured.fraction,
			candidateId = candidateId,
			camera = cameraName,
			expectedBelow = 0.15,
			detail = measured,
			stageReason = why,
		})
	end

	stagedMeasure("kampung_r10", "kampung_view", "SUBJECT_COVERAGE_KAMPUNG_R10")
	pcall(function()
		scReview.disableAll()
	end)
	stagedMeasure("ditch_water_r10", "plot_gate_01", "SUBJECT_COVERAGE_DITCH_WATER_R10")
	pcall(function()
		scReview.disableAll()
	end)

	local probeOk = coverage.probe() == true
	emit("SUBJECT_COVERAGE_PROBE", probeOk, probeOk and 1 or 0, 1, { synthetic = true })
end)

pcall(function()
	if scReview then
		scReview.disableAll()
	end
end)
pcall(function()
	if scFixture then
		scFixture:Destroy()
	end
end)

if not scOk then
	local reason = { reason = "subject coverage error: " .. tostring(scErr) }
	for _, name in ipairs(SC_CHECK_NAMES) do
		emitOnce(name, false, 0, SC_TARGETS[name], reason)
	end
end

return results
