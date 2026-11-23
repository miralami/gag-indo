--!nocheck
-- check_q268: WORK_QUEUE item 268, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. Pure measurement: no screen_capture, no place save,
-- no model text, no asset IDs, no DataModel mutation.
--
--   NO_DOME_HILLS  0 sphere-like hills rendered: (#Landscape.hillBlocks ball volumes) multiplied by
--                  the DOME_HILLS_ENABLED gate (false -> 0). Also requires the source-level switch
--                  GreyboxTerrainConfig.DOME_HILLS == false, which Greybox wires into the gate.
--   HORIZON_SPECKS 0 ModelMapForestR9.placements() whose sqrt(x^2 + z^2) >= 400 studs.
--
-- CALIBRATION ANCHORS (single-line injections; change the state, never the target):
--   * NO_DOME_HILLS: flip `local enabled = Landscape.DOME_HILLS_ENABLED ~= false` to
--     `local enabled = true` -> the same measure sees all raw ball volumes and FAILs. Or flip
--     `local configOff = GreyboxTerrainConfig.DOME_HILLS == false` to `== true` -> config FAIL.
--   * HORIZON_SPECKS: change `countSpecks(placements, 400)` to `countSpecks(placements, 380)`
--     -> the inner band is counted and the measure FAILs.
-- Each is detected as PASS 1 when injected, proving the checks are not vacuous. The 400 threshold
-- and the 0 targets are never edited.

local results = { checks = {}, byName = {} }
local CHECK_NAMES = { "NO_DOME_HILLS", "HORIZON_SPECKS" }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK " .. name .. " " .. (passed and "PASS" or "FAIL") .. " " .. tostring(measured) .. " " .. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

local function countSpecks(placements, minRadius)
	local n = 0
	for _, p in ipairs(placements) do
		if math.sqrt(p.x * p.x + p.z * p.z) >= minRadius then
			n += 1
		end
	end
	return n
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local server = game:GetService("ServerScriptService"):WaitForChild("Server")
	local Landscape = require(server:WaitForChild("World"):WaitForChild("Landscape"))
	local GreyboxTerrainConfig = require(shared:WaitForChild("GreyboxTerrainConfig"))
	local ModelMapForestR9 = require(shared:WaitForChild("ModelMapForestR9"))
	if type(Landscape) ~= "table" or type(Landscape.hillBlocks) ~= "function" then
		error("Landscape.hillBlocks API missing")
	end
	if type(GreyboxTerrainConfig) ~= "table" or type(ModelMapForestR9.placements) ~= "function" then
		error("GreyboxTerrainConfig / ModelMapForestR9 API missing")
	end

	local rawBalls = 0
	for _, volume in ipairs(Landscape.hillBlocks()) do
		if volume.shape == "ball" then
			rawBalls += 1
		end
	end
	local enabled = Landscape.DOME_HILLS_ENABLED ~= false -- CALIBRATION ANCHOR (GATE): set to `true` to FAIL
	local effectiveBalls = enabled and rawBalls or 0
	local configOff = GreyboxTerrainConfig.DOME_HILLS == false -- CALIBRATION ANCHOR (CONFIG): set to `== true` to FAIL
	emit("NO_DOME_HILLS", effectiveBalls == 0 and configOff, effectiveBalls, 0, {
		rawBalls = rawBalls,
		gate = Landscape.DOME_HILLS_ENABLED,
		config = GreyboxTerrainConfig.DOME_HILLS,
	})

	local placements = ModelMapForestR9.placements()
	local specks = countSpecks(placements, 400) -- CALIBRATION ANCHOR (BAND): 400 -> 380 to FAIL
	emit("HORIZON_SPECKS", specks == 0, specks, 0, { placements = #placements, threshold = 400 })
end)

if not ok then
	local reason = { reason = "item 268 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, 0, reason)
	end
end

local function measured(name)
	local entry = results.byName[name]
	return entry and entry.measured or 0
end

print("SUMMARY_Q268 NO_DOME_HILLS " .. tostring(measured("NO_DOME_HILLS")) .. " HORIZON_SPECKS " .. tostring(measured("HORIZON_SPECKS")))
return results
