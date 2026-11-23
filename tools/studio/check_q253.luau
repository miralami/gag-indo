--!nocheck
-- check_q253: WORK_QUEUE item 253, self-contained SERVER-VM Studio check. Paste this whole file
-- into execute_luau in a FRESH Play session. It stages ONLY kampung_r10 via
-- LookDevReview.enableAdditive, measures the live DataModel, prints verbatim CHECK lines, restores
-- with disableAll() on every path, and leaves no injected instance behind. No harness require, no
-- place save, no visual verdict.
--
--   NO_MELONS            0 staged kampung BaseParts with Shape == Ball and max(Size) >= 1.5
--   SHRUB_MODELS         >= one tagged hedge cluster per house cluster (3 clusters -> target 3)
--   CAL_NO_MELONS_FAIL   inject a 2-stud Ball shrub tagged kampung -> >=1 offender -> 1 1
--   CAL_LOOKDEV_LEAK_FAIL leave that tagged part through unstage -> >=1 leak -> 1 1
--   LOOKDEV_LEAK         0 staged/injected instances after disableAll() and injection cleanup
--
-- NO_MELONS is the item 241/244 predicate: a KampungHouse-tagged BasePart, Shape == Ball, max
-- dimension >= 1.5. SHRUB_MODELS keeps its name but counts Wedge/Cylinder parts with role="shrub",
-- stage tag, HedgeShrub and shrubCluster; a cluster must stay inside the old 4-stud yard footprint.
-- The baked shrub IDs have no bake in this place, so no model path is assumed. Geometric, not a look
-- verdict.
--
-- Restore contract: disableAll() runs immediately after the staged measurements (leaving only the
-- injected calibration part), again in the outer guard on every path, and the injection is destroyed
-- before the final LOOKDEV_LEAK measurement.

local CANDIDATE_ID = "kampung_r10"
local CHECK_NAMES = {
	"NO_MELONS",
	"SHRUB_MODELS",
	"CAL_NO_MELONS_FAIL",
	"CAL_LOOKDEV_LEAK_FAIL",
	"LOOKDEV_LEAK",
}
local CHECK_TARGETS = {
	NO_MELONS = 0,
	SHRUB_MODELS = 3,
	CAL_NO_MELONS_FAIL = 1,
	CAL_LOOKDEV_LEAK_FAIL = 1,
	LOOKDEV_LEAK = 0,
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

local function descendants()
	local ok, list = pcall(function()
		return workspace:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list, 0
	end
	return {}, 1
end

local function tagKey()
	return if Data and Data.tagAttribute then Data.tagAttribute else "KampungHouse"
end

local function stageKey()
	return if Data and Data.stageAttribute then Data.stageAttribute else "LookDevStage"
end

local function folderName()
	return if Data and Data.folderName then Data.folderName else "LookDevKampungR10_kampung_r10"
end

-- Item 241/244 NO_MELONS predicate, scoped to the staged kampung tag. Enum items are compared
-- directly: tostring(Enum.PartType.Ball) is "Enum.PartType.Ball", not "Ball".
local function measureMelons()
	local offenders = {}
	local all = descendants()
	for _, instance in ipairs(all) do
		if attr(instance, tagKey()) == true then
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

-- A hedge cluster counts for its house cluster only when its Wedge/Cylinder parts carry the tag,
-- stage, shrub role, HedgeShrub marker and one shared shrubCluster name, and their combined XZ
-- footprint stays inside the old 4-stud yard Ball.
local function measureShrubModels()
	local clusters, anchors, bounds, invalid = {}, {}, {}, 0
	local maxCluster = if Data and Data.CLUSTER_COUNT then Data.CLUSTER_COUNT else 3
	for _, instance in ipairs(descendants()) do
		local okBase, isBase = pcall(function()
			return instance:IsA("BasePart")
		end)
		if
			okBase
			and isBase
			and attr(instance, tagKey()) == true
			and attr(instance, stageKey()) == CANDIDATE_ID
			and attr(instance, "role") == "shrub"
			and attr(instance, "HedgeShrub") == true
		then
			local okShape, shape = pcall(function()
				return instance.Shape
			end)
			local okGeom, position, size = pcall(function()
				return instance.CFrame.Position, instance.Size
			end)
			local cluster = attr(instance, "cluster")
			local anchor = attr(instance, "shrubCluster")
			local shaped = okShape and (shape == Enum.PartType.Wedge or shape == Enum.PartType.Cylinder)
			local tagged = type(cluster) == "number"
				and cluster >= 1
				and cluster <= maxCluster
				and type(anchor) == "string"
			if okGeom and position and size and shaped and tagged then
				local box = bounds[anchor]
				if not box then
					box = {
						cluster = cluster,
						minX = position.X,
						maxX = position.X,
						minZ = position.Z,
						maxZ = position.Z,
					}
					bounds[anchor] = box
				end
				local hx, hz = size.X / 2, size.Z / 2
				box.minX = math.min(box.minX, position.X - hx)
				box.maxX = math.max(box.maxX, position.X + hx)
				box.minZ = math.min(box.minZ, position.Z - hz)
				box.maxZ = math.max(box.maxZ, position.Z + hz)
			else
				invalid += 1
			end
		end
	end
	for anchor, box in pairs(bounds) do
		if box.maxX - box.minX <= 4 and box.maxZ - box.minZ <= 4 then
			anchors[anchor] = true
			clusters[box.cluster] = true
		else
			invalid += 1
		end
	end
	local covered = 0
	for _ in pairs(clusters) do
		covered += 1
	end
	local anchorCount = 0
	for _ in pairs(anchors) do
		anchorCount += 1
	end
	return covered, anchorCount, anchors, invalid
end

-- A leak is any surviving tagged instance (staged hedge part or injected calibration)
-- or the candidate's staging folder itself.
local function measureLeaks()
	local leaks, seen = {}, {}
	local function add(name)
		if name and not seen[name] then
			seen[name] = true
			leaks[#leaks + 1] = name
		end
	end
	for _, instance in ipairs(descendants()) do
		local stage = attr(instance, stageKey())
		local tagged = attr(instance, tagKey())
		if stage == CANDIDATE_ID or tagged == true then
			local okName, name = pcall(function()
				return instance:GetFullName()
			end)
			if okName then
				add(name)
			end
		end
	end
	local okFolder, folder = pcall(function()
		return workspace:FindFirstChild(folderName())
	end)
	if okFolder and folder then
		local okName, name = pcall(function()
			return folder:GetFullName()
		end)
		if okName then
			add(name)
		end
	end
	return leaks
end

local function injectCalibrationBall()
	local spot = nil
	if Data and type(Data.yardParts) == "function" then
		local okYards, yards = pcall(Data.yardParts)
		if okYards and type(yards) == "table" then
			for _, part in ipairs(yards) do
				if part.kind == "shrub" and part.cluster == 1 then
					spot = part
					break
				end
			end
		end
	end
	local x = if spot then spot.position.x else 150
	local y = if spot then spot.position.y + 2 else 2.5
	local z = if spot then spot.position.z else 0
	local part = Instance.new("Part")
	part.Name = "Q253_MELON_CALIBRATION"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2, 2, 2)
	part.CFrame = CFrame.new(x, y, z)
	part.Color = Color3.fromRGB(86, 142, 78)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute(tagKey(), true)
	part:SetAttribute("role", "shrub")
	part:SetAttribute("house", 1)
	part:SetAttribute("cluster", 1)
	part:SetAttribute(stageKey(), CANDIDATE_ID)
	part:SetAttribute("HedgeShrub", true)
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
	Data = require(shared:WaitForChild("ModelMapKampungR10"))
	local LookDev = require(shared:WaitForChild("LookDev"))

	if
		type(Data) ~= "table"
		or type(Data.yardParts) ~= "function"
		or type(Data.CLUSTER_COUNT) ~= "number"
		or type(review.enableAdditive) ~= "function"
		or type(review.disableAll) ~= "function"
	then
		error("ModelMapKampungR10 / LookDevReview API missing")
	end

	-- Runtime wiring only; the owner's registry files are untouched.
	if type(LookDev.candidates) == "table" and not LookDev.candidates[CANDIDATE_ID] then
		LookDev.candidates[CANDIDATE_ID] = { id = CANDIDATE_ID }
	end
	if type(LookDev.IDS) == "table" and not table.find(LookDev.IDS, CANDIDATE_ID) then
		LookDev.IDS[#LookDev.IDS + 1] = CANDIDATE_ID
	end
	if type(review.paths) == "table" and not review.paths[CANDIDATE_ID] then
		review.paths[CANDIDATE_ID] = { datamodel = "server", path = { "World", "LookDevKampungR10" } }
	end
	local okApplier, applier = pcall(function()
		local server = game:GetService("ServerScriptService"):WaitForChild("Server")
		return require(server:WaitForChild("World"):WaitForChild("LookDevKampungR10"))
	end)
	if okApplier and type(applier) == "table" and type(applier.apply) == "function" then
		pcall(LookDev.register, CANDIDATE_ID, applier)
	end

	local enableOk, enabled, why = pcall(review.enableAdditive, CANDIDATE_ID, game)
	local reason = nil
	if not enableOk or not enabled then
		reason = "enableAdditive failed: " .. tostring(why)
	end

	local melons = measureMelons()
	local covered, anchors, clusters, invalid = measureShrubModels()
	local minClusters = Data.CLUSTER_COUNT
	emit("NO_MELONS", #melons == 0, #melons, 0, { names = melons, reason = reason })
	emit(
		"SHRUB_MODELS",
		covered >= minClusters,
		covered,
		minClusters,
		{
			anchors = anchors,
			clusters = clusters,
			invalid = invalid,
			reason = reason,
		}
	)

	-- CALIBRATION ANCHOR (NO_MELONS FAIL): a tagged 2-stud Ball shrub must be caught.
	injectCalibrationBall()
	local seen = #measureMelons()
	emit("CAL_NO_MELONS_FAIL", seen >= 1, seen >= 1 and 1 or 0, 1, { offendersSeen = seen })

	-- Restore the staged set now. The injected part survives on purpose for the leak anchor.
	pcall(function()
		review.disableAll()
	end)
end)

-- Restore every additive candidate on every path, including a measurement error.
pcall(function()
	if review then
		review.disableAll()
	else
		require(game:GetService("ReplicatedStorage").Shared.LookDevReview).disableAll()
	end
end)

-- CALIBRATION ANCHOR (LOOKDEV_LEAK FAIL): the injected tagged part is still present after unstage.
local leaked = measureLeaks()
emit("CAL_LOOKDEV_LEAK_FAIL", #leaked >= 1, #leaked >= 1 and 1 or 0, 1, { leaks = leaked })

-- Final cleanup: with both the staged set and the injection gone, nothing kampung-tagged remains.
destroyInjected()
local after = measureLeaks()
emit("LOOKDEV_LEAK", #after == 0, #after, 0, { leaks = after })

if not ok then
	local reason = { reason = "item 253 audit error: " .. tostring(err) }
	local targets = {
		NO_MELONS = 0,
		SHRUB_MODELS = if Data and Data.CLUSTER_COUNT then Data.CLUSTER_COUNT else CHECK_TARGETS.SHRUB_MODELS,
		CAL_NO_MELONS_FAIL = 1,
		CAL_LOOKDEV_LEAK_FAIL = 1,
		LOOKDEV_LEAK = 0,
	}
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, name == "LOOKDEV_LEAK" and 1 or 0, targets[name], reason)
	end
end

return results
