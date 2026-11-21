--!strict
-- LookDevLaundryR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "laundry_r8" candidate
-- (WORK_QUEUE section N item 115). Stages one folder of original Parts: two washing lines with a
-- sarung, a batik cloth and a kebaya behind each of two houses, plus a hammock and a tikar under
-- each porch. Every part is anchored, non-collidable and tagged. No animation: CLOTH_SWAY belongs to
-- item 85 (wind_r8), which is off by default and single-active. No Terrain read or write, no asset
-- IDs, no decals. Game APIs are pcall guarded and failures pad the published LookDevFailures counter.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("laundry_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevLaundryR8] missing service " .. name)
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
		warn("[LookDevLaundryR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapLaundryR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevLaundryR8] could not require LookDev / ModelMapLaundryR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevLaundryR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevLaundryR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local applied = false

local function fail(message: string)
	failures += 1
	warn("[LookDevLaundryR8] " .. message)
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

local function mapReady(): boolean
	return MapSpec ~= nil
		and type((MapSpec :: any).hub) == "function"
		and type((MapSpec :: any).hubPoint) == "function"
		and type((MapSpec :: any).GROUND_Y) == "number"
end

local function addPart(folder: any, recipe: any): any?
	local hub = (MapSpec :: any).hub(recipe.hub)
	if not hub then
		fail("missing MapSpec hub " .. tostring(recipe.hub))
		return nil
	end
	local x, z = (MapSpec :: any).hubPoint(hub, recipe.lx, recipe.lz)
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Laundry_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(x, (MapSpec :: any).GROUND_Y + recipe.ly, z)
			* CFrame.Angles(0, 0, math.rad(recipe.roll))
		if recipe.shape == "cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.post
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Wood"] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, recipe.kind)
		part.Parent = folder
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. tostring(recipe.name))
		return nil
	end
	track(created)
	return created
end

local function apply()
	if applied then
		return
	end
	applied = true
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
	if not mapReady() then
		fail("MapSpec hub / hubPoint / GROUND_Y unavailable")
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
		addPart(folder, recipe)
	end
	publishFailures()
end

local function restore()
	if not applied then
		return
	end
	applied = false
	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	publishFailures()
end

LookDevLaundryR8.apply = apply
LookDevLaundryR8.restore = restore

LookDev.register(Data.familyId, { apply = apply, restore = restore })

return LookDevLaundryR8
