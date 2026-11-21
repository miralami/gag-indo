--!strict
-- LookDevPerahuR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "perahu_r8" candidate
-- (WORK_QUEUE section N item 112). Stages one folder of original Parts: two perahu, a pole-mounted
-- fishing net, a bamboo landing stage and a stack of baskets, all on the river bank shelves.
-- Every part is anchored, non-collidable and tagged. No Terrain read or write: the bank is already
-- Ground and the water is existing Terrain water. Game APIs are pcall guarded and failures pad the
-- published LookDevFailures counter. Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("perahu_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPerahuR8] missing service " .. name)
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
		warn("[LookDevPerahuR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapPerahuR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevPerahuR8] could not require LookDev / ModelMapPerahuR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevPerahuR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevPerahuR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevPerahuR8] " .. message)
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

local function addPart(parent: any, recipe: any, x: number, y: number, z: number, label: string): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Perahu_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(recipe.roll))
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.hull
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Wood"] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, recipe.kind)
		part.Parent = parent
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. tostring(recipe.name) .. " for " .. label)
		return nil
	end
	track(created)
	return created
end

local function mapGeometry()
	if
		not MapSpec
		or type((MapSpec :: any).riverCentreZ) ~= "function"
		or type((MapSpec :: any).BRIDGE) ~= "table"
		or type((MapSpec :: any).BRIDGE.z0) ~= "number"
		or type((MapSpec :: any).BRIDGE.z1) ~= "number"
		or type((MapSpec :: any).GROUND_Y) ~= "number"
	then
		fail("MapSpec riverCentreZ / BRIDGE / GROUND_Y unavailable")
		return nil, nil
	end
	return (MapSpec :: any).riverCentreZ, (MapSpec :: any).GROUND_Y
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
		local centreFn, groundY = mapGeometry()
		if not centreFn or not groundY then
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

		for _, recipe in ipairs(Data.parts()) do
			local site = Data.siteByKey(recipe.site)
			if site then
				local x, z = Data.worldXZ(site, recipe.lx, recipe.lz, centreFn)
				addPart(folder, recipe, x, groundY + recipe.ly, z, recipe.site)
			else
				fail("unknown site " .. tostring(recipe.site))
			end
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

LookDevPerahuR8.apply = applier.apply
LookDevPerahuR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevPerahuR8
