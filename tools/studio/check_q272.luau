--!nocheck
-- check_q272: WORK_QUEUE item 272, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a FRESH Play session. Stages ONLY the additive "warung_props_r10" Warung overlay
-- directly through WarungDressQ210.overlayApply/overlayRestore, measures the live DataModel, runs
-- three FAIL calibrations, restores every mutation LIFO and prints verbatim CHECK lines plus
-- SUMMARY_Q272. No camera, no capture, no place save/publish, no web service APIs, no visual verdict.
--
--   MODEL_USED             staged BaseParts carrying a live-verified baked ModelAssetId / >=1
--   NO_SCRIPTS             LuaSourceContainers under the staged folder / 0
--   OVERVIEW_STRAY_REMOVED top-level Workspace strays named in the pure data / 0
--   LOOKDEV_LEAK_Q272      staged folder left after restore / 0
--
-- CALIBRATION ANCHORS (PASS means the injected fault made the named check FAIL):
--   CAL_MODEL_USED_272       clear the baked-model attribute on every staged model part
--   CAL_NO_SCRIPTS_272       add one inert ModuleScript under the staged folder
--   CAL_OVERVIEW_STRAY_272   add one top-level Workspace Part named after the known stray

local results = { checks = {}, byName = {}, pass = 0, fail = 0, calPass = 0, calFail = 0 }
local Workspace
local Data = {}
local injected = {} -- LIFO restore stack

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

local function recordSet(target, prop, value, isAttribute)
	local okRead, old = pcall(function()
		if isAttribute then
			return target:GetAttribute(prop)
		end
		return target[prop]
	end)
	if not okRead then
		return false
	end
	injected[#injected + 1] = { target = target, prop = prop, value = old, isAttribute = isAttribute }
	pcall(function()
		if isAttribute then
			target:SetAttribute(prop, value)
		else
			target[prop] = value
		end
	end)
	return true
end

local function recordDestroy(instance)
	injected[#injected + 1] = { destroy = instance }
end

local function restoreInjected()
	for index = #injected, 1, -1 do
		local entry = injected[index]
		injected[index] = nil
		pcall(function()
			if entry.destroy then
				entry.destroy:Destroy()
			elseif entry.isAttribute then
				entry.target:SetAttribute(entry.prop, entry.value)
			else
				entry.target[entry.prop] = entry.value
			end
		end)
	end
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

local function modelParts(folder)
	local allowed = {}
	for _, id in ipairs(Data.props.ALLOWED_IDS) do
		allowed[id] = true
	end
	return partsWith(folder, function(instance)
		return allowed[attribute(instance, Data.props.modelAttribute)] == true
	end)
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

local function topLevelChildren()
	local out = {}
	local ok, list = pcall(function()
		return Workspace:GetChildren()
	end)
	if ok and type(list) == "table" then
		for _, item in ipairs(list) do
			out[#out + 1] = item
		end
	end
	return out
end

local function strayParts()
	local names = {}
	for _, name in ipairs(Data.props.OVERVIEW_STRAY_NAMES) do
		names[name] = true
	end
	local found = {}
	for _, child in ipairs(topLevelChildren()) do
		local okName, name = pcall(function()
			return child.Name
		end)
		if okName and names[name] then
			local okPosition, position = pcall(function()
				return child:GetPivot().Position
			end)
			found[#found + 1] = name
				.. " @"
				.. (okPosition and string.format("%.2f,%.2f,%.2f", position.X, position.Y, position.Z) or "?")
		end
	end
	return found
end

local function stagedFolder()
	local ok, folder = pcall(function()
		return Workspace and Workspace:FindFirstChild(Data.props.folderName) or nil
	end)
	return ok and folder or nil
end

-- ---------------------------------------------------------------------------
-- Boot: require pure data and the applier. Missing modules FAIL loudly, never vacuously.
Workspace = service("Workspace")
local ReplicatedStorage = service("ReplicatedStorage")
local ServerScriptService = service("ServerScriptService")
if not Workspace or not ReplicatedStorage or not ServerScriptService then
	emit("BOOT_Q272", false, "missing-services", "Workspace/ReplicatedStorage/ServerScriptService")
	return results
end
local okShared, sharedFolder = pcall(function()
	return ReplicatedStorage:WaitForChild("Shared")
end)
local okServer, serverFolder = pcall(function()
	return ServerScriptService:WaitForChild("Server")
end)
if not okShared or not sharedFolder or not okServer or not serverFolder then
	emit("BOOT_Q272", false, "missing-folders", "Shared/Server")
	return results
end
local okModules, loaded = pcall(function()
	local world = serverFolder:WaitForChild("World")
	return {
		props = require(sharedFolder:WaitForChild("ModelMapWarungPropsR10")),
		warung = require(world:WaitForChild("WarungDressQ210")),
	}
end)
if
	not okModules
	or type(loaded) ~= "table"
	or type(loaded.props) ~= "table"
	or type(loaded.warung) ~= "table"
	or type(loaded.warung.overlayApply) ~= "function"
	or type(loaded.warung.overlayRestore) ~= "function"
then
	emit("BOOT_Q272", false, "require-error", "ModelMapWarungPropsR10/WarungDressQ210", tostring(loaded))
	return results
end
Data.props = loaded.props
Data.warung = loaded.warung

local okReview, review = pcall(function()
	return require(sharedFolder:WaitForChild("LookDevReview"))
end)
if okReview and type(review) == "table" and type(review.disableAll) == "function" then
	pcall(review.disableAll)
end

local staged = false
do
	local ok, applied = pcall(Data.warung.overlayApply)
	staged = ok and applied == true
	if not staged then
		emit("STAGE_WARUNG_PROPS_R10", false, "stage-failed", "true", tostring(applied))
	end
end

if staged then
	local folder = stagedFolder()
	local models = modelParts(folder)
	local scripts = countScripts(folder)
	local strays = strayParts()

	emit(
		"MODEL_USED",
		#models > 0,
		#models,
		1,
		"folder=" .. tostring(Data.props.folderName) .. " kitNotBaked=" .. tostring(Data.props.HOUSE_PROPS_KIT_NAME)
	)
	emit("NO_SCRIPTS", scripts == 0, scripts, 0, "folder=" .. tostring(Data.props.folderName))
	emit("OVERVIEW_STRAY_REMOVED", #strays == 0, #strays, 0, table.concat(strays, " | "))

	-- CALIBRATION (MODEL USED FAIL): clear the baked-model attribute on every model part.
	local cleared = 0
	for _, part in ipairs(models) do
		if recordSet(part, Data.props.modelAttribute, nil, true) then
			cleared += 1
		end
	end
	local badModels = #modelParts(folder)
	local modelBroken = badModels == 0
	emit("CAL_MODEL_USED_272", modelBroken, modelBroken and 1 or 0, 1, "cleared=" .. cleared .. " models=" .. badModels)
	restoreInjected()

	-- CALIBRATION (NO SCRIPTS FAIL): one inert ModuleScript under the staged folder.
	local injectedScript = false
	if folder then
		local inert = Instance.new("ModuleScript")
		inert.Name = "CalInjectedScript"
		inert.Source = "return true"
		inert.Parent = folder
		recordDestroy(inert)
		injectedScript = true
	end
	local badScripts = countScripts(folder)
	local scriptBroken = badScripts > 0
	emit("CAL_NO_SCRIPTS_272", scriptBroken, scriptBroken and 1 or 0, 1, "injected=" .. tostring(injectedScript))
	restoreInjected()

	-- CALIBRATION (OVERVIEW STRAY FAIL): one top-level Workspace Part named after the known stray.
	local fake = Instance.new("Part")
	fake.Name = Data.props.OVERVIEW_STRAY_NAMES[1]
	fake.Anchored = true
	fake:SetAttribute("LookDevStage", "CAL_Q272")
	fake.Parent = Workspace
	recordDestroy(fake)
	local badStrays = #strayParts()
	local strayBroken = badStrays > 0
	emit("CAL_OVERVIEW_STRAY_272", strayBroken, strayBroken and 1 or 0, 1, "found=" .. badStrays)
	restoreInjected()
end

-- Restore the overlay on every path, then measure the leak and print the summary.
pcall(Data.warung.overlayRestore)
restoreInjected()
if okReview and type(review) == "table" and type(review.disableAll) == "function" then
	pcall(review.disableAll)
end
local leaked = stagedFolder() and 1 or 0
emit("LOOKDEV_LEAK_Q272", leaked == 0, leaked, 0)
local total = results.pass + results.fail
print(
	"SUMMARY_Q272"
		.. string.format(
			" MODEL_USED %d/1 NO_SCRIPTS %d/0 OVERVIEW_STRAY_REMOVED %d/0 CAL %d/3 LEAK %d",
			results.byName.MODEL_USED and results.byName.MODEL_USED.passed and 1 or 0,
			results.byName.NO_SCRIPTS and results.byName.NO_SCRIPTS.passed and 0 or 1,
			results.byName.OVERVIEW_STRAY_REMOVED and results.byName.OVERVIEW_STRAY_REMOVED.passed and 0 or 1,
			results.calPass,
			leaked
		)
		.. " MAIN "
		.. tostring(results.pass)
		.. "/"
		.. tostring(total)
)

return results
