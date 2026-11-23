--!nocheck
-- check_q271: WORK_QUEUE item 271, self-contained SERVER-VM Studio check for the four reworked
-- sprint-3 "tidak" sets. Paste the whole file into execute_luau in a fresh Play session. It stages
-- each additive applier alone, measures geometry, runs three FAIL calibrations, restores LIFO and
-- prints verbatim CHECK lines plus SUMMARY_Q271. No camera, no capture, no place save, no publish.
--
-- MAIN LINES (measured / target):
--   TERRACE_STEPS_TERRACE_WALLS_214       min distinct descending tiers per wall / 3
--   SAWAH_DRESSING_SAWAH_DRESSING_215     staged sawah dressing parts / >=1
--   FOAM_ON_WATER_RIVER_FOAM_212          highest staged foam top / water+epsilon
--   CROP_GOLDEN_CROP_STAGES_GOLDEN_247    staged golden stage parts / >=1
--   NO_SCRIPTS_<ID>                       LuaSourceContainers under the staged folder / 0
--   MODEL_USED_<ID>                       parts with a baked ModelAssetId / >=1
--   LOOKDEV_LEAK_Q271                     folder left in Workspace after restore / 0
--
-- CALIBRATION ANCHORS (PASS means the injected fault made the named check FAIL):
--   CAL_FOAM_FLOAT_271     add one foam-tagged Part 1 stud above the water surface
--   CAL_TERRACE_FLAT_271   strip StepTier from one third tier; fewer than three tiers remain
--   CAL_NO_SCRIPTS_271     add a ModuleScript under a staged folder
-- Every injection is destroyed before its candidate is restored. Nothing is persisted.

local results = { checks = {}, byName = {}, pass = 0, fail = 0, calPass = 0, calFail = 0 }
local Workspace
local Data = {}
local staged = {} -- LIFO restore stack

local function service(name)
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	return ok and value or nil
end

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	if detail and detail ~= "" then
		line = line .. " " .. detail
	end
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed == true }
	if name:sub(1, 4) == "CAL_" then
		if passed then
			results.calPass += 1
		else
			results.calFail += 1
		end
	elseif passed then
		results.pass += 1
	else
		results.fail += 1
	end
	print(line)
end

local function label(id)
	return (id:gsub("[^%w]", "_")):upper()
end

local function descendantsOf(instance)
	local out = {}
	if not instance then
		return out
	end
	local ok, list = pcall(function()
		return instance:GetDescendants()
	end)
	if ok and type(list) == "table" then
		for _, item in ipairs(list) do
			out[#out + 1] = item
		end
	end
	return out
end

local function attribute(instance, name)
	local ok, value = pcall(function()
		return instance:GetAttribute(name)
	end)
	return ok and value or nil
end

local function restoreAll()
	for index = #staged, 1, -1 do
		local entry = staged[index]
		staged[index] = nil
		if entry and type(entry.restore) == "function" then
			pcall(entry.restore)
		end
	end
end

local function push(id, applier)
	if type(applier) ~= "table" or type(applier.apply) ~= "function" or type(applier.restore) ~= "function" then
		emit("STAGE_" .. label(id), false, "no-applier", "table")
		return false
	end
	local ok, err = pcall(applier.apply)
	if not ok then
		emit("STAGE_" .. label(id), false, "apply-error", "ok", tostring(err))
		return false
	end
	staged[#staged + 1] = { restore = applier.restore, label = id }
	return true
end

local function stagedFolder(folderName)
	local ok, folder = pcall(function()
		return Workspace and Workspace:FindFirstChild(folderName) or nil
	end)
	return ok and folder or nil
end

local function isPart(instance)
	local ok, value = pcall(function()
		return instance:IsA("BasePart")
	end)
	return ok and value == true
end

local function isScript(instance)
	local ok, value = pcall(function()
		return instance:IsA("LuaSourceContainer")
	end)
	return ok and value == true
end

local function partsWith(folder, predicate)
	local out = {}
	for _, item in ipairs(descendantsOf(folder)) do
		if isPart(item) and predicate(item) then
			out[#out + 1] = item
		end
	end
	return out
end

local function countScripts(folder)
	local count = 0
	for _, item in ipairs(descendantsOf(folder)) do
		if isScript(item) then
			count += 1
		end
	end
	return count
end

local function measureNoScripts(id, folder)
	local count = countScripts(folder)
	emit("NO_SCRIPTS_" .. label(id), count == 0, count, 0)
	return count
end

local function measureModelUsed(id, folder)
	local parts = partsWith(folder, function(instance)
		local assetId = attribute(instance, "ModelAssetId")
		return type(assetId) == "number" and assetId > 0
	end)
	emit("MODEL_USED_" .. label(id), #parts > 0, #parts, 1)
	return #parts
end

-- FOAM_ON_WATER: top of every staged foam piece must sit within the data's surface epsilon.
local function foamState(folder)
	local highest, count = -math.huge, 0
	for _, part in
		ipairs(partsWith(folder, function(instance)
			return attribute(instance, "FoamOnWater") == true
		end))
	do
		count += 1
		local ok, top = pcall(function()
			return part.CFrame.Position.Y + part.Size.Y / 2
		end)
		if ok and top > highest then
			highest = top
		end
	end
	return count > 0 and highest or nil, count
end

local function foamPasses(highest, count, ceiling)
	return count > 0 and type(highest) == "number" and highest <= ceiling + 1e-6
end

local function emitFoam(name, highest, count, ceiling, waterTop, passed)
	emit(
		name,
		passed,
		highest and string.format("%.3f", highest) or "nil",
		string.format("%.3f", ceiling),
		"water=" .. string.format("%.3f", waterTop) .. " pieces=" .. count
	)
end

-- TERRACE_STEPS: at least three distinct tiers per terrace, strictly descending with tier index.
local function terraceState(folder)
	local groups = {}
	for _, part in ipairs(descendantsOf(folder)) do
		local tier = attribute(part, "StepTier")
		local terrace = attribute(part, "TerraceIndex")
		local topY = attribute(part, "TopY")
		if isPart(part) and type(tier) == "number" and type(terrace) == "number" and type(topY) == "number" then
			local group = groups[terrace]
			if not group then
				group = {}
				groups[terrace] = group
			end
			if group[tier] == nil or topY > group[tier] then
				group[tier] = topY
			end
		end
	end
	local minTiers, descending, terraces = math.huge, true, 0
	for _, tiers in pairs(groups) do
		terraces += 1
		local count, last = 0, math.huge
		for index = 1, 64 do
			local top = tiers[index]
			if top == nil then
				break
			end
			count += 1
			if top >= last then
				descending = false
			end
			last = top
		end
		if count < minTiers then
			minTiers = count
		end
	end
	if terraces == 0 then
		minTiers = 0
	end
	return minTiers, descending, terraces
end

local function emitTerrace(name, minTiers, descending, terraces, target, passed)
	emit(name, passed, minTiers, target, "terraces=" .. terraces .. " descending=" .. tostring(descending))
end

local function measureGolden(folder)
	local parts = partsWith(folder, function(instance)
		return attribute(instance, "GoldenStage") == true
	end)
	emit("CROP_GOLDEN_" .. label("crop_stages_golden_247"), #parts > 0, #parts, 1)
	return #parts
end

local function measureDressing(folder)
	local parts = partsWith(folder, function(instance)
		return attribute(instance, Data.DressingTag) == true
	end)
	local groups = {}
	for _, part in ipairs(parts) do
		local group = attribute(part, Data.DressingGroupAttr)
		if type(group) == "string" then
			groups[group] = true
		end
	end
	local groupCount = 0
	for _ in pairs(groups) do
		groupCount += 1
	end
	emit("SAWAH_DRESSING_" .. label("sawah_dressing_215"), #parts > 0, #parts, 1, "groups=" .. groupCount)
	return #parts
end

-- ---------------------------------------------------------------------------
-- Boot: require pure data and appliers. Missing modules FAIL loudly, never vacuously.
Workspace = service("Workspace")
local ReplicatedStorage = service("ReplicatedStorage")
local ServerScriptService = service("ServerScriptService")
if not Workspace or not ReplicatedStorage or not ServerScriptService then
	emit("BOOT_Q271", false, "missing-services", "Workspace/ReplicatedStorage/ServerScriptService")
	return results
end
local okShared, sharedFolder = pcall(function()
	return ReplicatedStorage:WaitForChild("Shared")
end)
local okServer, serverFolder = pcall(function()
	return ServerScriptService:WaitForChild("Server")
end)
if not okShared or not sharedFolder or not okServer or not serverFolder then
	emit("BOOT_Q271", false, "missing-folders", "Shared/Server")
	return results
end
local okModules, loaded = pcall(function()
	local world = serverFolder:WaitForChild("World")
	return {
		MapSpec = require(world:WaitForChild("MapSpec")),
		Foam = require(sharedFolder:WaitForChild("ModelMapRiverFoamQ212")),
		Terrace = require(sharedFolder:WaitForChild("ModelMapTerraceWallsQ214")),
		Dressing = require(sharedFolder:WaitForChild("ModelMapSawahDressingQ215")),
		Golden = require(sharedFolder:WaitForChild("ModelMapCropStagesGoldenQ247")),
		foamApplier = require(world:WaitForChild("LookDevRiverFoamQ212")),
		terraceApplier = require(world:WaitForChild("LookDevTerraceWallsQ214")),
		dressingApplier = require(world:WaitForChild("LookDevSawahDressingQ215")),
		goldenApplier = require(world:WaitForChild("LookDevCropStagesGoldenQ247")),
	}
end)
if not okModules or type(loaded) ~= "table" then
	emit("BOOT_Q271", false, "require-error", "all-modules", tostring(loaded))
	return results
end
local MapSpec = loaded.MapSpec
Data.Foam = loaded.Foam
Data.Terrace = loaded.Terrace
Data.Dressing = loaded.Dressing
Data.Golden = loaded.Golden
Data.DressingTag = loaded.Dressing.TAG
Data.DressingGroupAttr = loaded.Dressing.GROUP_ATTR

local okReview, review = pcall(function()
	return require(sharedFolder:WaitForChild("LookDevReview"))
end)
if okReview and type(review) == "table" and type(review.disableAll) == "function" then
	pcall(review.disableAll)
end

local function liveWaterTop()
	local ok, river = pcall(function()
		return MapSpec.river()
	end)
	if not ok or type(river) ~= "table" or type(river.water) ~= "table" or not river.water[1] then
		return nil
	end
	local first = river.water[1]
	return first.centre[2] + first.size[2] / 2 + MapSpec.TERRAIN_VOXEL / 2
end

local waterTop = liveWaterTop()
if type(waterTop) ~= "number" then
	emit("BOOT_Q271", false, "no-river-water", "number")
	return results
end
local ceiling = waterTop + Data.Foam.FOAM_SURFACE_EPSILON

-- FOAM -----------------------------------------------------------------------
do
	local ok = push("river_foam_212", loaded.foamApplier)
	local folder = stagedFolder(Data.Foam.folderName)
	if ok then
		measureNoScripts("river_foam_212", folder)
		measureModelUsed("river_foam_212", folder)
		local highest, count = foamState(folder)
		emitFoam(
			"FOAM_ON_WATER_" .. label("river_foam_212"),
			highest,
			count,
			ceiling,
			waterTop,
			foamPasses(highest, count, ceiling)
		)
		-- CAL: one part 1 stud above the surface must make FOAM_ON_WATER fail.
		local injected
		pcall(function()
			injected = Instance.new("Part")
			injected.Name = "CalFloatingFoam"
			injected.Size = Vector3.new(1, 0.08, 1)
			injected.CFrame = CFrame.new(0, waterTop + 1, 0)
			injected:SetAttribute("FoamOnWater", true)
			injected.Parent = folder
		end)
		local badHighest, badCount = foamState(folder)
		local broken = not foamPasses(badHighest, badCount, ceiling)
		emit(
			"CAL_FOAM_FLOAT_271",
			broken,
			broken and 1 or 0,
			1,
			"foamTop="
				.. string.format("%.3f", badHighest or 0)
				.. " ceiling="
				.. string.format("%.3f", ceiling)
				.. " pieces="
				.. badCount
		)
		pcall(function()
			if injected then
				injected:Destroy()
			end
		end)
	end
	restoreAll()
end

-- TERRACE WALLS --------------------------------------------------------------
do
	local ok = push("terrace_walls_214", loaded.terraceApplier)
	local folder = stagedFolder(Data.Terrace.folderName)
	if ok then
		measureNoScripts("terrace_walls_214", folder)
		measureModelUsed("terrace_walls_214", folder)
		local minTiers, descending, terraces = terraceState(folder)
		emitTerrace(
			"TERRACE_STEPS_" .. label("terrace_walls_214"),
			minTiers,
			descending,
			terraces,
			Data.Terrace.STEP_COUNT,
			minTiers >= Data.Terrace.STEP_COUNT and descending
		)
		-- CAL: strip the third tier everywhere; min tiers drops below 3.
		local saved = {}
		for _, part in ipairs(descendantsOf(folder)) do
			if attribute(part, "StepTier") == Data.Terrace.STEP_COUNT then
				saved[#saved + 1] = part
				pcall(function()
					part:SetAttribute("StepTier", nil)
				end)
			end
		end
		local badMin, badDescending = terraceState(folder)
		local broken = badMin < Data.Terrace.STEP_COUNT or not badDescending
		emit(
			"CAL_TERRACE_FLAT_271",
			broken,
			broken and 1 or 0,
			1,
			"minTiers=" .. badMin .. " descending=" .. tostring(badDescending)
		)
		for _, part in ipairs(saved) do
			pcall(function()
				part:SetAttribute("StepTier", Data.Terrace.STEP_COUNT)
			end)
		end
	end
	restoreAll()
end

-- SAWAH DRESSING -------------------------------------------------------------
do
	local ok = push("sawah_dressing_215", loaded.dressingApplier)
	local folder = stagedFolder(Data.Dressing.folderName)
	if ok then
		measureNoScripts("sawah_dressing_215", folder)
		measureModelUsed("sawah_dressing_215", folder)
		measureDressing(folder)
		-- CAL: a ModuleScript under the staged folder must make NO_SCRIPTS fail.
		local injected
		pcall(function()
			injected = Instance.new("ModuleScript")
			injected.Name = "CalInjectedScript"
			injected.Source = "return true"
			injected.Parent = folder
		end)
		-- Silent count: emitting NO_SCRIPTS here would add a stray FAIL line before the next candidate.
		local broken = countScripts(folder) > 0
		emit("CAL_NO_SCRIPTS_271", broken, broken and 1 or 0, 1, "injected-one-module-script")
		pcall(function()
			if injected then
				injected:Destroy()
			end
		end)
	end
	restoreAll()
end

-- CROP GOLDEN ----------------------------------------------------------------
do
	local ok = push("crop_stages_golden_247", loaded.goldenApplier)
	local folder = stagedFolder(Data.Golden.folderName)
	if ok then
		measureNoScripts("crop_stages_golden_247", folder)
		measureModelUsed("crop_stages_golden_247", folder)
		measureGolden(folder)
	end
	restoreAll()
end

-- LEAK + SUMMARY -------------------------------------------------------------
local leaked = 0
for _, name in ipairs({
	Data.Foam.folderName,
	Data.Terrace.folderName,
	Data.Dressing.folderName,
	Data.Golden.folderName,
}) do
	if stagedFolder(name) then
		leaked += 1
	end
end
if okReview and type(review) == "table" and type(review.disableAll) == "function" then
	pcall(review.disableAll)
end
emit("LOOKDEV_LEAK_Q271", leaked == 0, leaked, 0)
local total = results.pass + results.fail
local SUMMARY_Q271 = "SUMMARY_Q271"
print(
	SUMMARY_Q271
		.. string.format(
			" MAIN %d/%d CAL %d/%d LEAK %d",
			results.pass,
			total,
			results.calPass,
			results.calPass + results.calFail,
			leaked
		)
)

return results
