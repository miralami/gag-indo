--!strict
-- LookDevFacadesR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "facades_r8" candidate
-- (WORK_QUEUE section M item 78). Main.server wires the candidate; this file only registers it.
--
-- PROCEDURAL PARTS, NO ASSET IDS. Every recipe comes from Shared.ModelMapFacadesR8 and is placed in
-- the live MapSpec.hub(key) frame (hubPoint + hub.yaw), never at a hardcoded world position. For each
-- of the six Greybox hub Models this stages ten anchored, non-collidable decorative Parts plus one
-- transparent FacadeDoorGauge Part. Every decorative Part carries a WeldConstraint to the hub's
-- anchor part as structural documentation (both ends are anchored). Shipping Greybox parts are
-- never touched. Restore destroys the whole staged folder and its saved instances.
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("facades_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevFacadesR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedValue = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedValue then
	Shared = sharedValue
else
	warn("[LookDevFacadesR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapFacadesR8),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not LookDevFailures or not TierThin then
	warn("[LookDevFacadesR8] could not require LookDev / ModelMapFacadesR8 / LookDevFailures / TierThin")
	return {}
end

local MapSpec: any? = nil
local okSpec, specValue = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and specValue then
	MapSpec = specValue
else
	warn("[LookDevFacadesR8] could not require MapSpec")
end

local LookDevFacadesR8 = {}

local FAMILY_ID: string = Data.id
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevFacadesR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
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

-- Find the real Greybox Model by its MapSpec name. Workspace.World is the shipping container; a
-- recursive scan also accepts a model parented directly under Workspace by a designer.
local function hubModel(name: string): any?
	if not Workspace then
		return nil
	end
	local ok, found = pcall(function()
		local world = (Workspace :: any):FindFirstChild("World")
		local roots = world and { world, Workspace } or { Workspace }
		for _, root in ipairs(roots) do
			for _, instance in ipairs(root:GetDescendants()) do
				if instance:IsA("Model") and instance.Name == name then
					return instance
				end
			end
		end
		return nil
	end)
	return if ok then found else nil
end

local function anchorPart(model: any): any?
	local primary: any? = nil
	pcall(function()
		primary = model.PrimaryPart
	end)
	if primary then
		local okPart, isPart = pcall(function()
			return primary:IsA("BasePart")
		end)
		if okPart and isPart then
			return primary
		end
	end
	local ok, found = pcall(function()
		for _, instance in ipairs(model:GetDescendants()) do
			if instance:IsA("BasePart") then
				return instance
			end
		end
		return nil
	end)
	return if ok then found else nil
end

local function localCFrame(hub: any, lx: number, lz: number, y: number, pitch: number): any?
	if not MapSpec then
		return nil
	end
	local ok, cf = pcall(function()
		local x, z = MapSpec.hubPoint(hub, lx, lz)
		local placed = CFrame.new(x, MapSpec.GROUND_Y + y, z) * CFrame.Angles(0, math.rad(hub.yaw), 0)
		if pitch ~= 0 then
			placed *= CFrame.Angles(0, 0, math.rad(pitch))
		end
		return placed
	end)
	return if ok then cf else nil
end

local function stageRecipe(hub: any, hubKey: string, recipe: any, folder: any, anchor: any): boolean
	local okNew, part = pcall(function()
		return Instance.new("Part")
	end)
	if not okNew or not part then
		fail("could not create " .. tostring(recipe.name) .. " for " .. hubKey)
		return false
	end
	track(part)
	local cf = localCFrame(hub, recipe.lx, recipe.lz, recipe.y, recipe.pitch)
	local okSet = cf ~= nil
		and pcall(function()
			part.Name = recipe.name
			part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
			part.CFrame = cf
			part.Color = Color3.fromRGB(recipe.color[1], recipe.color[2], recipe.color[3])
			part.Material = Enum.Material[recipe.material]
			part.Anchored = true
			part.CanCollide = false
			part:SetAttribute("FacadePart", true)
			part:SetAttribute("FacadeKind", recipe.kind)
			part:SetAttribute("HubKey", hubKey)
			part.Parent = folder
		end)
	if not okSet then
		fail("could not configure " .. tostring(recipe.name) .. " for " .. hubKey)
		return false
	end
	local okWeld = pcall(function()
		local weld = Instance.new("WeldConstraint")
		weld.Name = "FacadeWeld_" .. recipe.name
		weld.Part0 = part
		weld.Part1 = anchor
		weld.Parent = part
		track(weld)
	end)
	if not okWeld then
		fail("could not weld " .. tostring(recipe.name) .. " for " .. hubKey)
	end
	return true
end

local function stageGauge(hub: any, hubKey: string, gauge: any, folder: any): boolean
	local okNew, part = pcall(function()
		return Instance.new("Part")
	end)
	if not okNew or not part then
		fail("could not create FacadeDoorGauge for " .. hubKey)
		return false
	end
	track(part)
	local cf = localCFrame(hub, gauge.lx, gauge.lz, gauge.base + gauge.h / 2, 0)
	local okSet = cf ~= nil
		and pcall(function()
			part.Name = Data.gaugeName
			part.Size = Vector3.new(gauge.w, gauge.h, gauge.d)
			part.CFrame = cf
			part.Transparency = 1
			part.Anchored = true
			part.CanCollide = false
			part:SetAttribute("HubKey", hubKey)
			part:SetAttribute("DoorW", gauge.w)
			part:SetAttribute("DoorH", gauge.h)
			part:SetAttribute("DoorD", gauge.d)
			part.Parent = folder
		end)
	if not okSet then
		fail("could not configure FacadeDoorGauge for " .. hubKey)
		return false
	end
	return true
end

-- ponytail: every FacadePart is structural here — each hub has exactly 10 recipes and the harness
-- FACADE_MIN_PARTS=10 + all-six-kinds checks need all of them; add surplus recipes before thinning.
local function stageHub(hubKey: string, entry: any, parent: any, tier: any): boolean
	if not MapSpec then
		fail("missing MapSpec for " .. hubKey)
		return false
	end
	local hub: any? = nil
	local okHub, resolved = pcall(function()
		return MapSpec.hub(hubKey)
	end)
	if okHub then
		hub = resolved
	end
	if not hub then
		fail("no MapSpec hub for " .. hubKey)
		return false
	end
	local model = hubModel(tostring(entry.model))
	if not model then
		fail("missing hub Model " .. tostring(entry.model))
		return false
	end
	local anchor = anchorPart(model)
	if not anchor then
		fail("no anchor part in " .. tostring(entry.model))
		return false
	end
	local folder = newFolder(hubKey, parent)
	if not folder then
		fail("could not create folder for " .. hubKey)
		return false
	end
	track(folder)
	pcall(function()
		folder:SetAttribute("HubKey", hubKey)
	end)

	local ok = true
	for index, recipe in ipairs(entry.parts) do
		-- structural=true: the facade detail and its door gauge stay at every tier.
		if TierThin.shouldKeep(tier, index, true) then
			if not stageRecipe(hub, hubKey, recipe, folder, anchor) then
				ok = false
			end
		end
	end
	if not stageGauge(hub, hubKey, entry.gauge, folder) then
		ok = false
	end
	return ok
end

local function apply(plan)
	local tier = plan and plan.tier
	failures = 0
	clearActive()
	local previous: any? = nil
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

	for _, hubKey in ipairs(Data.HUB_KEYS) do
		local entry = Data.hubs[hubKey]
		if not entry then
			fail("missing recipe for " .. hubKey)
		else
			stageHub(hubKey, entry, folder, tier)
		end
	end
	publishFailures()
end

local function restore()
	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
end

LookDevFacadesR8.apply = apply
LookDevFacadesR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevFacadesR8
