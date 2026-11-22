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

return results
