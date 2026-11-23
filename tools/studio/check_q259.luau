--!nocheck
-- check_q259: WORK_QUEUE item 259, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY hill_dressing_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, then
-- restores every injection and calls disableAll() on every path. No harness require, no place
-- save, no visual verdict. Item 259 scope: rock sizes, not tree or terrain-material counts.
--
--   HILL_ROCKS  >=5 parts tagged HillDressing with kind="rock" on EVERY hill (min reported)
--   ROCK_MIN_SIZE  smallest axis of any tagged rock BasePart >= 4 studs (baked descendants too)
--   WALKABLE    unchanged number of downward first-hits at the ten clear core points from
--               check_q244/q199 (Terrain or Walkable-tagged); measured as an after-before delta
--   NO_MELONS   0 staged HillDressing BaseParts that are a Ball with max(Size) >= 1.5
--
-- CALIBRATION ANCHORS (each must FAIL the condition, then assert detection):
--   CAL_ROCK_MIN_SIZE_FAIL  inject a 2-stud tagged rock -> measured min < 4
--   CAL_NO_MELONS_FAIL      inject a 2-stud tagged Ball -> melon count > 0
-- Injections are destroyed immediately after their anchor line. SUMMARY_Q259 closes the run.

local CANDIDATE_ID = "hill_dressing_r10"
local ROCK_TARGET = 5
local ROCK_MIN_AXIS = 4
local RAY_ORIGIN_Y, RAY_LENGTH = 256, 512

local CHECK_NAMES = {
	"HILL_ROCKS",
	"ROCK_MIN_SIZE",
	"WALKABLE",
	"NO_MELONS",
	"CAL_ROCK_MIN_SIZE_FAIL",
	"CAL_NO_MELONS_FAIL",
}
-- Ten clear core points (plaza / plot-gate area), copied verbatim from check_q244.
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
local CHECK_TARGETS = {
	HILL_ROCKS = ROCK_TARGET,
	ROCK_MIN_SIZE = ROCK_MIN_AXIS,
	WALKABLE = 0,
	NO_MELONS = 0,
	CAL_ROCK_MIN_SIZE_FAIL = 1,
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

local function attr(instance, key)
	local ok, value = pcall(function()
		return instance:GetAttribute(key)
	end)
	return ok and value or nil
end

local review, Data = nil, nil
local injected = {}

-- Per-hill kind counts from the live tagged descendants (same logic as check_q244).
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

-- Smallest axis of every tagged rock BasePart, including parts inside baked models.
local function measureRocks()
	local minSize, count, readErrors = math.huge, 0, 0
	local okDescendants, descendants = pcall(function()
		return workspace:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return { min = 0, count = 0, readErrors = 1 }
	end
	for _, instance in ipairs(descendants) do
		if attr(instance, "HillDressing") == true and attr(instance, "kind") == "rock" then
			local okBase, isBase = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okBase and isBase then
				local okSize, size = pcall(function()
					return instance.Size
				end)
				if
					okSize
					and size
					and type(size.X) == "number"
					and type(size.Y) == "number"
					and type(size.Z) == "number"
				then
					count += 1
					minSize = math.min(minSize, size.X, size.Y, size.Z)
				else
					readErrors += 1
				end
			end
		end
	end
	if minSize == math.huge then
		minSize = 0
	end
	return { min = minSize, count = count, readErrors = readErrors }
end

-- Same ten downward rays and first-hit rule as check_q244 / check_q199.
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

local function inject(shape, size, name)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = Vector3.new(size, size, size)
	part.CFrame = CFrame.new(462, 12, 0) -- hill 1 centre, clear of the village core
	part.Material = Enum.Material.SmoothPlastic
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

	-- The two measurement moments stay separate so a between-line change is detectable.
	local beforeWalkable = measureWalkable()

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local counts = measureCounts()
	local rocks = measureRocks()
	local afterWalkable = measureWalkable()
	local melons = measureMelons()
	local minRock = math.floor(rocks.min * 100) / 100

	emit(
		"HILL_ROCKS",
		reason == nil and counts.rocks >= ROCK_TARGET,
		counts.rocks,
		ROCK_TARGET,
		{ minPalms = counts.palms, counts = counts.counts, reason = reason }
	)
	emit(
		"ROCK_MIN_SIZE",
		reason == nil and rocks.count > 0 and rocks.min >= ROCK_MIN_AXIS,
		minRock,
		ROCK_MIN_AXIS,
		{ rockParts = rocks.count, readErrors = rocks.readErrors, reason = reason }
	)
	local delta = afterWalkable - beforeWalkable
	emit("WALKABLE", reason == nil and delta == 0, delta, 0, {
		beforeWalkable = beforeWalkable,
		afterWalkable = afterWalkable,
		rays = #GROUND_POINTS,
		reason = reason,
	})
	emit("NO_MELONS", reason == nil and #melons == 0, #melons, 0, { names = melons, reason = reason })

	-- CALIBRATION ANCHOR (ROCK_MIN_SIZE FAIL): a live 2-stud tagged rock must be measured.
	inject(Enum.PartType.Block, 2, "Q259_SMALL_ROCK_CALIBRATION")
	local calRocks = measureRocks()
	local rockFailed = calRocks.count > 0 and calRocks.min < ROCK_MIN_AXIS
	emit("CAL_ROCK_MIN_SIZE_FAIL", rockFailed, rockFailed and 1 or 0, 1, {
		injectedSize = 2,
		minRock = calRocks.min,
		rockParts = calRocks.count,
	})
	destroyInjected()

	-- CALIBRATION ANCHOR (NO_MELONS FAIL): a live tagged Ball must be seen.
	inject(Enum.PartType.Ball, 2, "Q259_MELON_CALIBRATION")
	local seen = #measureMelons()
	local melonFailed = seen >= 1
	emit("CAL_NO_MELONS_FAIL", melonFailed, melonFailed and 1 or 0, 1, { offendersSeen = seen })
	destroyInjected()
end)

-- Restore every injection and every additive candidate, even when a measurement threw.
destroyInjected()
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

if not ok then
	local reason = { reason = "item 259 audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, 0, CHECK_TARGETS[name], reason)
	end
end

local function measured(name)
	local entry = results.byName[name]
	return type(entry and entry.measured) == "number" and entry.measured or 0
end

local function passed(name)
	local entry = results.byName[name]
	return entry ~= nil and entry.passed == true
end

local calPass = 0
for _, name in ipairs({ "CAL_ROCK_MIN_SIZE_FAIL", "CAL_NO_MELONS_FAIL" }) do
	if passed(name) then
		calPass += 1
	end
end
print(
	string.format(
		"SUMMARY_Q259 HILL_ROCKS %d/%d ROCK_MIN_SIZE %.2f/%d WALKABLE %d/0 NO_MELONS %d/0 CAL %d/2",
		measured("HILL_ROCKS"),
		ROCK_TARGET,
		measured("ROCK_MIN_SIZE"),
		ROCK_MIN_AXIS,
		measured("WALKABLE"),
		measured("NO_MELONS"),
		calPass
	)
)

return results
