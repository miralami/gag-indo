--!strict
-- LookDevRondaTowerR9: SERVER-ONLY applier for the OFF-BY-DEFAULT "ronda_tower_r9" candidate
-- (WORK_QUEUE section O item 150). Builds one Pos Ronda watchtower from original Parts under
-- `LookDevRondaTowerR9_ronda_tower_r9`, over the existing greybox tower (which is NOT hidden or
-- changed). Position comes from MapSpec.RONDA_TOWER, the base from MapSpec.GROUND_Y and the brief
-- height/base/roof/kentongan/ladder recipe from Shared.ModelMapRondaTowerR9.
--
-- Every part is anchored and tagged; the folder is destroyed on restore together with its parts and
-- any prior folder is re-parented. No asset IDs and no real brand. Engine calls are pcall guarded;
-- failures are published through LookDevFailures. Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("ronda_tower_r9", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRondaTowerR9] missing service " .. name)
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
		warn("[LookDevRondaTowerR9] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRondaTowerR9),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevRondaTowerR9] could not require LookDev / ModelMapRondaTowerR9 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevRondaTowerR9] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevRondaTowerR9 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevRondaTowerR9] " .. message)
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

local function towerBase(): (number?, number?, number?)
	if
		not MapSpec
		or type(MapSpec.RONDA_TOWER) ~= "table"
		or type(MapSpec.RONDA_TOWER.x) ~= "number"
		or type(MapSpec.RONDA_TOWER.z) ~= "number"
		or type(MapSpec.GROUND_Y) ~= "number"
	then
		fail("missing MapSpec.RONDA_TOWER / GROUND_Y")
		return nil, nil, nil
	end
	return MapSpec.RONDA_TOWER.x, MapSpec.GROUND_Y, MapSpec.RONDA_TOWER.z
end

-- One anchored, non-collidable original Part from a pure-data recipe. All tags are set before
-- parenting so the read-only harness sees a complete staged tower.
local function addPart(parent: any, recipe: any, baseX: number, baseY: number, baseZ: number): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = recipe.name
		part.Shape = (Enum :: any).PartType[recipe.shape] or (Enum :: any).PartType.Block
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		local rotation = recipe.rotation
		part.CFrame = CFrame.new(baseX, baseY, baseZ)
			* CFrame.new(recipe.x, recipe.y, recipe.z)
			* CFrame.Angles(math.rad(rotation[1]), math.rad(rotation[2]), math.rad(rotation[3]))
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.bamboo
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Wood"] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false -- the candidate is a visual overlay; the greybox tower stays walkable
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.towerAttribute, Data.familyId)
		part:SetAttribute(recipe.attribute, true)
		part.Parent = parent
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. tostring(recipe.name))
		return nil
	end
	track(created)
	return created
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace then
			fail("missing Workspace")
			publishFailures()
			return
		end
		local x, y, z = towerBase()
		if x == nil or y == nil or z == nil then
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

		local okModel, model = pcall(function()
			return Instance.new("Model")
		end)
		if not okModel or not model then
			fail("could not create tower model")
			publishFailures()
			return
		end
		track(model)
		local okConfigure = pcall(function()
			model.Name = "RondaTower"
			model:SetAttribute(Data.towerAttribute, Data.familyId)
			model:SetAttribute(Data.stageAttribute, Data.familyId)
			model:SetAttribute(Data.legAttribute, Data.counts().legs)
			model.Parent = folder
		end)
		if not okConfigure then
			fail("could not configure tower model")
			publishFailures()
			return
		end

		local stagedParts = 0
		for _, recipe in ipairs(Data.parts()) do
			if addPart(model, recipe, x, y, z) then
				stagedParts += 1
			end
		end
		if stagedParts ~= Data.counts().total then
			fail("staged " .. stagedParts .. "/" .. Data.counts().total .. " tower parts")
		end
		pcall(function()
			model:SetAttribute("TowerHeight", Data.height())
		end)
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

LookDevRondaTowerR9.apply = applier.apply
LookDevRondaTowerR9.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevRondaTowerR9
