--!strict
-- LookDevLapanganR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "lapangan_r8" candidate
-- (WORK_QUEUE section N item 108). Builds the village field dressing from original Parts under one
-- folder: two 15.95-stud goal frames (2.2 x the 7.25-stud avatar), one flagpole with a red-over-
-- white panel flag, four bamboo benches along the south side, 24 white-painted boundary stones and
-- five sand patches.
--
-- Every recipe comes from Shared.ModelMapLapanganR8 and every position is resolved from
-- MapSpec.LAPANGAN plus a field-local offset; no world-coordinate literals and no asset IDs. The
-- field is already Ground terrain, so no voxel pads are painted. All parts are anchored and
-- non-collidable, tagged per kind with the LapanganKind attribute, and destroyed on restore with
-- the staging folder; the exact prior folder (if any) is re-parented. Game APIs are pcall guarded
-- and any failure pads the published LookDevFailures counter. Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("lapangan_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevLapanganR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevLapanganR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapLapanganR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevLapanganR8] could not require LookDev / ModelMapLapanganR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevLapanganR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevLapanganR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevLapanganR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

-- Resolve a field-local offset into a world position from MapSpec.LAPANGAN (never a world literal).
local function lapanganPoint(localX: number, localZ: number): (number?, number?)
	if not MapSpec or type(MapSpec.LAPANGAN) ~= "table" then
		fail("missing MapSpec.LAPANGAN")
		return nil, nil
	end
	return MapSpec.LAPANGAN.x + localX, MapSpec.LAPANGAN.z + localZ
end

local function groundY(): number
	return if MapSpec and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
end

-- One anchored, non-collidable original Part, tagged with its LapanganKind. Colour is a plain
-- {r,g,b} array from the pure map.
local function addPart(
	parent: any,
	name: string,
	size: { number },
	cframe: any,
	colourKey: string,
	materialKey: string,
	kind: string,
	label: string
): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(size[1], size[2], size[3])
		part.CFrame = cframe
		local colour = Data.COLOURS[colourKey] or Data.COLOURS.stone
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[materialKey] or "SmoothPlastic"]
			or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, kind)
		part.Parent = parent
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. name .. " for " .. label)
		return nil
	end
	track(created)
	return created
end

local function newModel(name: string, attribute: string, value: any, folder: any, label: string): any?
	local ok, model = pcall(function()
		return Instance.new("Model")
	end)
	if not ok or not model then
		fail("could not create model for " .. label)
		return nil
	end
	track(model)
	local okSet = pcall(function()
		model.Name = name
		model:SetAttribute(attribute, value)
		model:SetAttribute(Data.stageAttribute, Data.familyId)
		model.Parent = folder
	end)
	if not okSet then
		fail("could not configure model for " .. label)
		return nil
	end
	return model
end

-- A goal is three structural Parts: two posts of full GOAL_HEIGHT and one crossbar whose top is
-- flush with the posts. The resulting Model bbox height is exactly Data.GOAL_HEIGHT.
local function stageGoal(recipe: any, folder: any): boolean
	local x, z = lapanganPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local label = "goal/" .. recipe.name
	local model = newModel("LapanganGoal_" .. recipe.name, Data.goalAttribute, Data.familyId, folder, label)
	if not model then
		return false
	end
	pcall(function()
		model:SetAttribute(Data.heightAttribute, Data.GOAL_HEIGHT)
	end)
	local base = CFrame.new(x, groundY(), z) * CFrame.Angles(0, math.rad(recipe.yaw), 0)
	local goal = Data.GOAL
	for _, offset in ipairs(goal.postZOffsets) do
		addPart(
			model,
			"GoalPost",
			goal.postSize,
			base * CFrame.new(0, Data.GOAL_HEIGHT / 2, offset),
			"wood",
			"wood",
			Data.KIND.goal,
			label
		)
	end
	addPart(
		model,
		"GoalCrossbar",
		goal.crossbarSize,
		base * CFrame.new(0, Data.GOAL_HEIGHT - goal.crossbarSize[2] / 2, 0),
		"wood",
		"wood",
		Data.KIND.goal,
		label
	)
	return true
end

local function stageFlagpole(folder: any): boolean
	local recipe = Data.flagpole()
	local x, z = lapanganPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local model = newModel("LapanganFlagpole", Data.flagpoleAttribute, true, folder, "flagpole")
	if not model then
		return false
	end
	local flagpole = Data.FLAGPOLE
	local base = CFrame.new(x, groundY(), z)
	addPart(
		model,
		"FlagPole",
		flagpole.poleSize,
		base * CFrame.new(0, flagpole.height / 2, 0),
		"wood",
		"wood",
		Data.KIND.flagpole,
		"flagpole"
	)
	for _, colour in ipairs(recipe.panels) do
		local panel = addPart(
			model,
			"FlagPanel_" .. colour,
			flagpole.panelSize,
			base * CFrame.new(flagpole.panelX, flagpole[colour .. "Y"], 0),
			colour,
			"fabric",
			Data.KIND.flagpole,
			"flagpole"
		)
		if panel then
			pcall(function()
				panel:SetAttribute(Data.flagPanelAttribute, colour)
			end)
		end
	end
	return true
end

local function stageBench(recipe: any, folder: any): boolean
	local x, z = lapanganPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local label = "bench/" .. recipe.name
	local model = newModel("LapanganBench_" .. recipe.name, Data.benchAttribute, true, folder, label)
	if not model then
		return false
	end
	local base = CFrame.new(x, groundY(), z) * CFrame.Angles(0, math.rad(recipe.yaw), 0)
	local bench = Data.BENCH
	addPart(
		model,
		"BenchSeat",
		bench.seatSize,
		base * CFrame.new(0, bench.seatY, 0),
		"bamboo",
		"bamboo",
		Data.KIND.bench,
		label
	)
	addPart(
		model,
		"BenchBack",
		bench.backSize,
		base * CFrame.new(0, bench.backY, bench.backZOffset),
		"bamboo",
		"bamboo",
		Data.KIND.bench,
		label
	)
	for _, offset in ipairs(bench.legXOffsets) do
		addPart(
			model,
			"BenchLeg",
			bench.legSize,
			base * CFrame.new(offset, bench.legY, 0),
			"bamboo",
			"bamboo",
			Data.KIND.bench,
			label
		)
	end
	return true
end

local function stageStone(recipe: any, folder: any)
	local x, z = lapanganPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return
	end
	local stone = addPart(
		folder,
		"LapanganStone_" .. recipe.name,
		Data.STONE.size,
		CFrame.new(x, groundY() + Data.STONE.size[2] / 2, z),
		"white",
		"stone",
		Data.KIND.stone,
		"boundary stone"
	)
	if stone then
		pcall(function()
			stone:SetAttribute(Data.stoneAttribute, true)
		end)
	end
end

local function stageSand(recipe: any, folder: any)
	local x, z = lapanganPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return
	end
	local sand = addPart(
		folder,
		"LapanganSand_" .. recipe.name,
		Data.SAND.size,
		CFrame.new(x, groundY() + Data.SAND.size[2] / 2, z),
		"sand",
		"sand",
		Data.KIND.sand,
		"sand patch"
	)
	if sand then
		pcall(function()
			sand:SetAttribute(Data.sandAttribute, true)
		end)
	end
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace or not MapSpec then
			fail("missing Workspace/MapSpec")
			publishFailures()
			return
		end
		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)
		pcall(function()
			folder:SetAttribute(Data.stageAttribute, Data.familyId)
		end)
		for _, goal in ipairs(Data.goals()) do
			stageGoal(goal, folder)
		end
		stageFlagpole(folder)
		for _, bench in ipairs(Data.benches()) do
			stageBench(bench, folder)
		end
		for _, stone in ipairs(Data.stones()) do
			stageStone(stone, folder)
		end
		for _, patch in ipairs(Data.sandPatches()) do
			stageSand(patch, folder)
		end
		publishFailures()
	end,

	restore = function()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		publishFailures()
	end,
}

LookDevLapanganR8.apply = applier.apply
LookDevLapanganR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevLapanganR8
