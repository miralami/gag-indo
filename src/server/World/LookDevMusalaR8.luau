--!strict
-- LookDevMusalaR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "musala_r8" candidate
-- (WORK_QUEUE section N item 110). Stages one folder of original Parts: a small plain musala with
-- a green tiered roof, a pengeras suara horn on a pole, a wudhu tap area and a shoe rack, plus one
-- invisible door gauge Part for the harness. No terrain is edited. All geometry is anchored and
-- non-collidable; the exact prior folder (if any) is detached before staging and re-parented on
-- restore. Game APIs are pcall guarded and failures pad the published LookDevFailures counter.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("musala_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevMusalaR8] missing service " .. name)
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
		warn("[LookDevMusalaR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapMusalaR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevMusalaR8] could not require LookDev / ModelMapMusalaR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevMusalaR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevMusalaR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevMusalaR8] " .. message)
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

local function groundY(): number
	return if MapSpec and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else Data.SITE.fallbackGroundY
end

-- The site centre and yaw are pure data from MapSpec.ROAD; only the ground height comes from the live
-- map. No world-coordinate literals live in this applier.
local function site(): any
	local road = if MapSpec and type(MapSpec.ROAD) == "table" then MapSpec.ROAD else nil
	local centre = Data.centre(road)
	centre.y = groundY()
	return centre
end

-- One anchored, non-collidable original Part. Site-local offsets resolve through Data.sitePoint;
-- Data.sitePoint mirrors MapSpec.rotatePoint, so local +Z is the door side facing the ring.
local function addPart(parent: any, recipe: any, centre: any, label: string): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Musala_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		local x, y, z = Data.sitePoint(centre, centre.yaw, recipe.lx, recipe.ly, recipe.lz)
		part.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(centre.yaw), 0)
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.stone
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Concrete"] or Enum.Material.Concrete
		part.Anchored = true
		part.CanCollide = false
		if recipe.kind == Data.KIND.gauge then
			part.Transparency = 1
			part:SetAttribute(Data.doorWidthAttribute, Data.DOOR_W)
			part:SetAttribute(Data.doorHeightAttribute, Data.DOOR_H)
			part:SetAttribute(Data.doorDepthAttribute, Data.DOOR_D)
		end
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
		local centre = site()
		for _, recipe in ipairs(Data.parts()) do
			addPart(folder, recipe, centre, recipe.kind)
		end
		addPart(folder, Data.gauge(), centre, "door gauge")
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

LookDevMusalaR8.apply = applier.apply
LookDevMusalaR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevMusalaR8
