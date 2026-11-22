--!nocheck
-- check_q241.luau: self-contained SERVER-VM Studio check for WORK_QUEUE item 241 (round "melon"
-- blobs). Reads the SHIPPING default look directly — no LookDev stage, no candidate enabled. The main
-- session pastes this whole file into execute_luau (Server VM) in a FRESH Play session and saves the
-- printed CHECK lines under docs/v2/evidence/h/<date>-sprint2/CHECK_241.txt.
--
-- Checks (targets are NOT weakened):
--   NO_MELONS   <offenders> 0     BasePart with Shape == Ball and max(Size) >= 1.5 on open lawn.
--   TREE_COUNT  <count>      450   Models with ForestTree attribute in World.BackgroundForest.
--   PERF_BUDGET <count>      500   BasePart centres within XZ radius 100 (check_q186 method).
--
-- Calibrate NO_MELONS FAIL: in the same SERVER-VM call, create an anchored 2x2x2 Ball Part named
-- "CalibrationMelon" at a verified clear lawn point (|x|,|z| > 21, outside every hub ring and
-- MapSpec.keepOutRects, near GROUND_Y), parent it under workspace.World, re-run this file, expect
-- `CHECK NO_MELONS FAIL 1 0`, then Destroy the calibration Part. Never save the place.
--
-- GENERATORS / CANDIDATES FOUND (item 241 source list — checked or deliberately deferred):
--   DEFAULT, fixed by this item:
--     src/server/World/Flora.luau              bushParts(): 2-3 overlapping green Balls, 2.2-4.6 studs.
--     src/server/World/Greybox.luau            CANOPY_BALLS/canopyLayout/buildTree/scatterTrees(): 3 green Balls per Tree_N.
--     src/server/World/Greybox.luau            buildBackgroundForest.makeTree(): 9.6x7.5x9.6 Ball canopy fallback.
--     src/server/World/Details.luau            hedgeRow() via ball(): 2.4-stud green Hedge Balls, 5 per row.
--     src/server/World/Details.luau            floorDetails(): 2.6x1.8x2.2 beige Sack Balls on lawn.
--     src/server/World/Decor.luau              stack(): Sack 1.6x1.1x1.3 Balls on open lawn in plaza crate stacks;
--                                                Studio VERIFY found 6 offenders; now squashed Cylinders.
--   DEFAULT, inspected and NOT a melon (size < 1.5 or not on open lawn):
--     src/server/World/Decor.luau              Lantern 1.4, Flower 1.4, FlagFinial 0.9.
--     src/server/World/Greybox.luau            hubBall() Lantern 1.9 at door height.
--     src/server/Farm/FarmService.luau         crop stem Balls (inside plots, not open lawn).
--   OFF-BY-DEFAULT candidates, LISTED only — item 244 owns hill_dressing_r10:
--     src/shared/ModelMapHillDressingR10.luau + src/server/World/LookDevHillDressingR10.luau
--         Ball rocks 4-8 studs grey-brown + Ball crowns 9-13 studs green on four hills.
--     src/shared/ModelMapCanonicalR10.luau     canonical overview rock/tree Balls.
--     src/server/World/LookDevForestPinesLegacy.luau  Ball pine canopies.
--     src/shared/ModelMapRocksR9.luau          round rock stand-in Balls.
--     src/shared/ModelMapRiverR8.luau          bank rock/plant Balls (1.7x1.9x1.5 descriptor).
--     src/shared/ModelMapMountainsR10.luau     far-horizon Balls.
--     src/shared/ModelMapKampungR10.luau       kampung dressing Balls.
--     src/server/World/LookDevCropStagesR10.luau, src/server/World/LookDevLampsR10.luau (small parts).

local NAMES = { "NO_MELONS", "TREE_COUNT", "PERF_BUDGET" }

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

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local okAudit, err = pcall(function()
	local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
	local world = workspace:FindFirstChild("World")
	if not world then
		error("workspace.World missing")
	end
	local groundY = MapSpec.GROUND_Y
	local roadHalf = MapSpec.ROAD.halfWidth + 1
	local hubs, keepOuts = {}, {}
	for _, hub in ipairs(MapSpec.HUBS) do
		hubs[#hubs + 1] = { hub.x, hub.z }
	end
	for _, rect in ipairs(MapSpec.keepOutRects()) do
		keepOuts[#keepOuts + 1] = rect
	end

	-- Conservative open-lawn rule: near the ground plane, clear of the road cross, hub rings,
	-- hub/plaza/future-slot footprints and the village bounds. Elevated props (door lanterns,
	-- flag finials) and hub crate-stack sacks are therefore excluded, not silently ignored.
	local function onOpenLawn(part)
		local ok, clear = pcall(function()
			local p = part.CFrame.Position
			if p.Y > groundY + 3 or p.Y < groundY - 1 then
				return false
			end
			if math.abs(p.X) <= roadHalf or math.abs(p.Z) <= roadHalf then
				return false
			end
			if math.abs(p.X) > 200 or p.Z < -170 or p.Z > 258 then
				return false
			end
			for _, hub in ipairs(hubs) do
				local dx, dz = p.X - hub[1], p.Z - hub[2]
				if dx * dx + dz * dz < 16 * 16 then
					return false
				end
			end
			for _, rect in ipairs(keepOuts) do
				if math.abs(p.X - rect[1]) < rect[3] and math.abs(p.Z - rect[2]) < rect[4] then
					return false
				end
			end
			return true
		end)
		return ok and clear == true
	end

	local melons = {}
	local perf = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") then
			local p = inst.CFrame.Position
			if p.X * p.X + p.Z * p.Z <= 10000 then
				perf += 1
			end
			local okBall, isBall = pcall(function()
				return inst.Shape == Enum.PartType.Ball
			end)
			if okBall and isBall then
				local okSize, size = pcall(function()
					return inst.Size
				end)
				if okSize and math.max(size.X, size.Y, size.Z) >= 1.5 and onOpenLawn(inst) then
					melons[#melons + 1] = inst:GetFullName()
				end
			end
		end
	end
	emit("NO_MELONS", #melons == 0, #melons, 0, { names = melons })

	local forest = world:FindFirstChild("BackgroundForest")
	if not forest then
		error("World.BackgroundForest missing")
	end
	local trees = 0
	for _, m in ipairs(forest:GetChildren()) do
		if attr(m, "ForestTree") == true then
			trees += 1
		end
	end
	emit("TREE_COUNT", trees >= 450, trees, 450)

	emit("PERF_BUDGET", perf <= 500, perf, 500)
end)

if not okAudit then
	local reason = "audit error: " .. tostring(err)
	for _, name in ipairs(NAMES) do
		emit(name, false, 0, 0, reason)
	end
end

return results
