--!nocheck
-- check_q244: WORK_QUEUE item 244, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY hill_dressing_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores with disableAll() in this same call on every path. No harness require, no place save,
-- no visual verdict. Default look is untouched (item 241 already shipped).
--
--   HILL_ROCKS  >=4 parts tagged HillDressing with kind="rock" on EVERY hill (min reported)
--   HILL_TREES  >=12 parts tagged HillDressing with kind="palm" on EVERY hill (min reported)
--   WALKABLE    unchanged number of downward rays at the ten clear village-core points from
--               check_q199 (Terrain or Walkable-tagged first hit)
--   NO_MELONS   0 staged HillDressing BaseParts that are a Ball with max(Size) >= 1.5,
--               including parts inside cloned baked/loaded models
--
-- HILL_ROCKS / HILL_TREES / WALKABLE are guarded by live per-hill counts and rays because a
-- descriptor count or an assumed hill position is not evidence: a multi-part model can change
-- what is actually staged, and a misplaced rock could block a village-core ray. All four values
-- are measured from the live DataModel; targets 4 / 12 / 0 / 0 are never lowered.
--
-- CALIBRATION ANCHOR: inject a 2-stud Ball tagged HillDressing=true, kind="rock",
-- LookDevStage="hill_dressing_r10" on hill 1 after the PASS measurement. NO_MELONS must see it
-- (>=1 -> `CHECK CAL_NO_MELONS_FAIL PASS 1 1`). The injection is destroyed before restore.

local CANDIDATE_ID = "hill_dressing_r10"
local CHECK_NAMES = { "HILL_ROCKS", "HILL_TREES", "WALKABLE", "NO_MELONS" }
local RAY_ORIGIN_Y, RAY_LENGTH = 256, 512
-- Ten clear core points (plaza / plot-gate area), copied verbatim from check_q199.
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

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local review, Data = nil, nil
local injected = {}

-- Per-hill kind counts, exactly the check_q199 counting logic.
local function measureCounts()
	local counts = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if okDescendants and type(descendants) == "table" then
		for _, instance in ipairs(descendants) do
			if attr(instance, "HillDressing") == true then
				local hill, kind = attr(instance, "hill"), attr(instance, "kind")
				if type(hill) == "number" and type(kind) == "string" then
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
	return { rocks = minRocks, palms = minPalms, counts = counts }
end

-- Same ten downward rays and first-hit rule as check_q199.
local function measureWalkable()
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
					local okFlagged, flagged = pcall(function()
						return instance:GetAttribute("Walkable") == true
					end)
					if (okTerrain and isTerrain) or (okFlagged and flagged) then
						walkable += 1
					end
				end
			end
		end
	end
	return walkable
end

-- All staged descendants, including model descendants. Enum items are compared directly:
-- tostring(Enum.PartType.Ball) is "Enum.PartType.Ball", not "Ball".
local function measureMelons()
	local offenders = {}
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return offenders
	end
	for _, instance in ipairs(descendants) do
		if attr(instance, "HillDressing") == true then
			local okBase, isBase = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okBase and isBase then
				local okShape, shape = pcall(function()
					return instance.Shape
				end)
				if okShape and shape == Enum.PartType.Ball then
					local okSize, size = pcall(function()
						return instance.Size
					end)
					if okSize and math.max(size.X, size.Y, size.Z) >= 1.5 then
						offenders[#offenders + 1] = instance:GetFullName()
					end
				end
			end
		end
	end
	return offenders
end

local function injectCalibrationBall()
	local part = Instance.new("Part")
	part.Name = "Q244_MELON_CALIBRATION"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2, 2, 2)
	part.CFrame = CFrame.new(462, 12, 0) -- hill 1 centre, well clear of the village core
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(128, 128, 128)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("HillDressing", true)
	part:SetAttribute("hill", 1)
	part:SetAttribute("kind", "rock")
	part:SetAttribute("LookDevStage", CANDIDATE_ID)
	part.Parent = workspace
	injected[#injected + 1] = part
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
	review = require(shared:WaitForChild("LookDevReview"))
	Data = require(shared:WaitForChild("ModelMapHillDressingR10"))
	local LookDev = require(shared:WaitForChild("LookDev"))

	if
		type(Data) ~= "table"
		or type(Data.parts) ~= "function"
		or type(Data.HILL_COUNT) ~= "number"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("ModelMapHillDressingR10 / LookDevReview API missing")
	end

	-- Runtime wiring only: owner-only LookDev / LookDevReview registry files are not touched.
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

	-- CALIBRATION ANCHOR (BEFORE): the two measure() moments are separate lines.
	local beforeWalkable = measureWalkable()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local counts = measureCounts()
	local afterWalkable = measureWalkable()
	local melons = measureMelons()

	emit("HILL_ROCKS", counts.rocks >= 4, counts.rocks, 4, {
		counts = counts.counts,
		reason = reason,
	})
	emit("HILL_TREES", counts.palms >= 12, counts.palms, 12, {
		counts = counts.counts,
		reason = reason,
	})
	local delta = afterWalkable - beforeWalkable
	emit("WALKABLE", delta == 0, delta, 0, {
		beforeWalkable = beforeWalkable,
		afterWalkable = afterWalkable,
		rays = #GROUND_POINTS,
		reason = reason,
	})
	emit("NO_MELONS", #melons == 0, #melons, 0, { names = melons, reason = reason })

	-- CALIBRATION ANCHOR (NO_MELONS FAIL): a HillDressing Ball must be seen even inside the
	-- staged set; emit a 1/1 anchor and destroy the injection immediately.
	injectCalibrationBall()
	local seen = #measureMelons()
	emit("CAL_NO_MELONS_FAIL", seen >= 1, seen >= 1 and 1 or 0, 1, { offendersSeen = seen })
	destroyInjected()
end)

-- Restore every additive candidate and every injection, even when a measurement threw.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)
destroyInjected()

if not ok then
	local reason = { reason = "item 244 audit error: " .. tostring(err) }
	emitOnce("HILL_ROCKS", false, 0, 4, reason)
	emitOnce("HILL_TREES", false, 0, 12, reason)
	emitOnce("WALKABLE", false, 1, 0, reason)
	emitOnce("NO_MELONS", false, 1, 0, reason)
	emitOnce("CAL_NO_MELONS_FAIL", false, 0, 1, reason)
end

return results
