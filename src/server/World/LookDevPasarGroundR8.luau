--!strict
-- LookDevPasarGroundR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "pasar_ground_r8" candidate
-- (WORK_QUEUE section N item 109). Stages one folder of flat original Parts around the Pasar:
-- 40 paving stones, 36 cobble patches and 18 drainage gutter segments. No terrain is edited; every
-- slab's bottom sits on groundY() (MapSpec.GROUND_Y, fallback 0.5).
--
-- Every recipe comes from Shared.ModelMapPasarGroundR8 and every position is resolved from
-- MapSpec.hub("pasar") through MapSpec.hubPoint: no world-coordinate literals and no asset IDs. All
-- parts are anchored, non-collidable and tagged by kind with PasarGroundKind; the exact prior folder
-- (if any) is detached before staging and re-parented on restore. Game APIs are pcall guarded and
-- failures pad the published LookDevFailures counter. Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("pasar_ground_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPasarGroundR8] missing service " .. name)
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
		warn("[LookDevPasarGroundR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapPasarGroundR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevPasarGroundR8] could not require LookDev / ModelMapPasarGroundR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevPasarGroundR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevPasarGroundR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevPasarGroundR8] " .. message)
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
	return if MapSpec and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
end

-- Resolve a Pasar-local offset through MapSpec.hubPoint. The hub is read once per apply.
local function pasarPoint(hub: any, localX: number, localZ: number): (number?, number?)
	if not MapSpec or type(MapSpec.hubPoint) ~= "function" then
		fail("missing MapSpec.hubPoint")
		return nil, nil
	end
	local ok, x, z = pcall(function()
		return MapSpec.hubPoint(hub, localX, localZ)
	end)
	if not ok or type(x) ~= "number" or type(z) ~= "number" then
		fail("could not resolve Pasar point")
		return nil, nil
	end
	return x, z
end

-- One anchored, non-collidable original Part. Its centre is half a thickness above the ground so
-- the bbox bottom is exactly groundY(). Colour/material keys are the pure map's kind names.
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
		local colour = Data.COLOURS[colourKey] or Data.COLOURS.paving
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[materialKey] or "Cobblestone"]
			or Enum.Material.Cobblestone
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, kind)
		part:SetAttribute(Data.kindAttributes[kind], true)
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

local function stageRecipe(recipe: any, folder: any, hub: any, kind: string, label: string)
	local x, z = pasarPoint(hub, recipe.lx, recipe.lz)
	if x == nil or z == nil then
		return
	end
	local thickness = recipe.size[2]
	addPart(
		folder,
		"PasarGround_" .. recipe.name,
		recipe.size,
		CFrame.new(x, groundY() + thickness / 2, z),
		kind,
		kind,
		kind,
		label
	)
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace or not MapSpec or type(MapSpec.hub) ~= "function" then
			fail("missing Workspace/MapSpec.hub")
			publishFailures()
			return
		end
		local okHub, hub = pcall(function()
			return (MapSpec :: any).hub("pasar")
		end)
		if not okHub or not hub then
			fail("missing MapSpec.hub(pasar)")
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
		for _, recipe in ipairs(Data.pavingStones()) do
			stageRecipe(recipe, folder, hub, Data.KIND.paving, "paving stone")
		end
		for _, recipe in ipairs(Data.cobblePatches()) do
			stageRecipe(recipe, folder, hub, Data.KIND.cobble, "cobble patch")
		end
		for _, recipe in ipairs(Data.gutters()) do
			stageRecipe(recipe, folder, hub, Data.KIND.gutter, "drainage gutter")
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

LookDevPasarGroundR8.apply = applier.apply
LookDevPasarGroundR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevPasarGroundR8
