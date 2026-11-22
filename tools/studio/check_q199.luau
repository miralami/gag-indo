--!nocheck
-- check_q199: WORK_QUEUE section Q item 199, self-contained SERVER-VM Studio check. Paste this
-- whole file into execute_luau in a fresh Play session. It measures the live place BEFORE and
-- AFTER staging hill_dressing_r10 with enableAdditive, prints verbatim CHECK lines, then restores
-- with disableAll() in the same call. No harness require, no place save, no visual verdict.
--
--   HILL_ROCKS  >=4 parts tagged HillDressing with kind="rock" on every hill
--   HILL_TREES  >=12 parts tagged HillDressing with kind="palm" on every hill
--   WALKABLE    unchanged number of downward rays at ten clear core points that first-hit
--               Terrain or a part tagged Walkable (hills are far outside the core)
--
-- CALIBRATION ANCHORS: `local before = measure()` and `local after = measure()` are separate single
-- lines so a before/after mismatch can be injected between them.
--   Delete a hill's rocks after BEFORE => HILL_ROCKS FAIL (that hill's min drops).
--   Delete a hill's palms after BEFORE => HILL_TREES FAIL.
--   Place a blocking part on one of the ten walkable rays after BEFORE => WALKABLE FAIL.

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

local CHECK_NAMES = { "HILL_ROCKS", "HILL_TREES", "WALKABLE" }
local CANDIDATE_ID = "hill_dressing_r10"
local RAY_ORIGIN_Y, RAY_LENGTH = 256, 512
-- Ten clear core points (plaza / plot-gate area), all |x|+|z| well inside the hill ring.
local GROUND_POINTS = {
	{ 0, 0 },
	{ 16, 0 },
	{ -16, 0 },
	{ 0, 16 },
	{ 0, -16 },
	{ 96, 96 },
	{ -96, 96 },
	{ 96, -96 },
	{ -96, -96 },
	{ 152, 0 },
}

local review, Data = nil, nil

-- Every reading comes from the live DataModel, never from the pure data alone.
local function measure()
	local counts = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			local okTagged, tagged = pcall(function()
				return instance:GetAttribute("HillDressing") == true
			end)
			if okTagged and tagged then
				local okHill, hill = pcall(function()
					return instance:GetAttribute("hill")
				end)
				local okKind, kind = pcall(function()
					return instance:GetAttribute("kind")
				end)
				if okHill and type(hill) == "number" and okKind and type(kind) == "string" then
					counts[hill] = counts[hill] or {}
					counts[hill][kind] = (counts[hill][kind] or 0) + 1
				end
			end
		end
	end

	local minRocks, minPalms = 0, 0
	for hill = 1, Data.HILL_COUNT do
		local perHill = counts[hill] or {}
		local rocks, palms = perHill.rock or 0, perHill.palm or 0
		if hill == 1 or rocks < minRocks then
			minRocks = rocks
		end
		if hill == 1 or palms < minPalms then
			minPalms = palms
		end
	end

	local walkable = 0
	local okParams, params = pcall(function()
		local q = RaycastParams.new()
		q.IgnoreWater = false
		return q
	end)
	if okParams then
		for _, point in ipairs(GROUND_POINTS) do
			local okRay, hit = pcall(function()
				local origin = Vector3.new(point[1], RAY_ORIGIN_Y, point[2])
				return workspace:Raycast(origin, Vector3.new(0, -RAY_LENGTH, 0), params)
			end)
			if okRay and hit then
				local instance = hit.Instance
				if instance then
					local okTerrain, isTerrain = pcall(function()
						return instance:IsA("Terrain")
					end)
					local okWalkable, flagged = pcall(function()
						return instance:GetAttribute("Walkable") == true
					end)
					if (okTerrain and isTerrain) or (okWalkable and flagged) then
						walkable += 1
					end
				end
			end
		end
	end

	return { rocks = minRocks, palms = minPalms, walkable = walkable, counts = counts }
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapHillDressingR10"))
	local LookDev = require(shared:WaitForChild("LookDev"))

	if type(Data) ~= "table" or type(Data.parts) ~= "function" or type(Data.HILL_COUNT) ~= "number" then
		error("ModelMapHillDressingR10 API missing")
	end

	-- Runtime wiring only: the owner-only LookDev / LookDevReview registry files are not touched
	-- by this harness. Register the applier in THIS VM before staging so enableAdditive can see it.
	if type(LookDev.candidates) == "table" and not LookDev.candidates[CANDIDATE_ID] then
		LookDev.candidates[CANDIDATE_ID] = { id = CANDIDATE_ID }
	end
	if type(LookDev.IDS) == "table" and not table.find(LookDev.IDS, CANDIDATE_ID) then
		LookDev.IDS[#LookDev.IDS + 1] = CANDIDATE_ID
	end
	if type(review.paths) == "table" and not review.paths[CANDIDATE_ID] then
		review.paths[CANDIDATE_ID] = { datamodel = "server", path = { "World", "LookDevHillDressingR10" } }
	end
	local okApplier, applier = pcall(function()
		local server = game:GetService("ServerScriptService"):WaitForChild("Server")
		return require(server:WaitForChild("World"):WaitForChild("LookDevHillDressingR10"))
	end)
	if okApplier and type(applier) == "table" and type(applier.apply) == "function" then
		pcall(LookDev.register, CANDIDATE_ID, applier)
	end

	-- CALIBRATION ANCHOR (BEFORE). A mismatch can be injected between the two measure calls.
	local before = measure()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local enableReason = nil
	if not enableOk or not enabled then
		enableReason = "enableAdditive failed: " .. tostring(why)
	end

	local after = measure()

	emit(
		"HILL_ROCKS",
		after.rocks >= 4,
		after.rocks,
		4,
		{ beforeRocks = before.rocks, counts = after.counts, reason = enableReason }
	)
	emit(
		"HILL_TREES",
		after.palms >= 12,
		after.palms,
		12,
		{ beforePalms = before.palms, counts = after.counts, reason = enableReason }
	)
	local delta = after.walkable - before.walkable
	emit("WALKABLE", delta == 0, delta, 0, {
		beforeWalkable = before.walkable,
		afterWalkable = after.walkable,
		rays = #GROUND_POINTS,
		reason = enableReason,
	})
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
	emitOnce("HILL_ROCKS", false, 0, 4, reason)
	emitOnce("HILL_TREES", false, 0, 12, reason)
	emitOnce("WALKABLE", false, 1, 0, reason)
end

return results
