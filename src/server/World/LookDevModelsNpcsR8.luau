--!strict
-- LookDevModelsNpcsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_r8"
-- candidate (WORK_QUEUE item 86). Enable from a Studio Server command bar;
-- .restore() puts the previous staging folder back.
--
-- Bodies, colours, second-row slots and yaw are the pure Shared.ModelMapNpcsR8
-- contract. Every outfit (classic Shirt/Pants, layered ShirtAccessory, Hat
-- accessories and the kids' BodyHeightScale/HeadScale) goes on a
-- HumanoidDescription, then Players creates the R15 rig. Catalog IDs come only
-- from the verified data module; no asset is loaded by this applier.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsNpcsR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Players = service("Players")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and value then
		Shared = value
	else
		warn("[LookDevModelsNpcsR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapNpcsR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevModelsNpcsR8] could not require LookDev / ModelMapNpcsR8 / LookDevFailures")
	return {}
end

local LookDevModelsNpcsR8 = {}

local FAMILY_ID = "npcs_r8"
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

-- Never silent: the count is published with LookDevFailures.set() at apply end.
local function fail(roleName: string, message: string)
	failures += 1
	warn("[LookDevModelsNpcsR8] " .. roleName .. ": " .. message)
end

local function warnRole(roleName: string, warned: { [string]: boolean }, message: string)
	if warned[roleName] then
		return
	end
	warned[roleName] = true
	warn("[LookDevModelsNpcsR8] " .. roleName .. ": " .. message)
end

local function folderName(): string
	return "LookDevModelsNpcsR8_" .. FAMILY_ID
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function findPrevious(): any?
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(folderName())
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	local ok, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not ok or not folder then
		warn("[LookDevModelsNpcsR8] could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = folderName()
	end)
	pcall(function()
		folder.Parent = Workspace
	end)
	return folder
end

local function buildRig(role: any, roleName: string, warned: { [string]: boolean }): any?
	local okDescription, value = pcall(function()
		return Instance.new("HumanoidDescription")
	end)
	if not okDescription or not value then
		warnRole(roleName, warned, "HumanoidDescription unavailable")
		return nil
	end
	local hd: any = value

	local okColours = pcall(function()
		local skin = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		hd.HeadColor = skin
		hd.LeftArmColor = skin
		hd.RightArmColor = skin
		hd.TorsoColor = skin
		hd.LeftLegColor = skin
		hd.RightLegColor = skin
	end)
	if not okColours then
		warnRole(roleName, warned, "could not set HumanoidDescription colours")
		return nil
	end

	local catalog = role.catalog
	if type(catalog) ~= "table" then
		warnRole(roleName, warned, "missing catalog outfit")
		return nil
	end
	local okCatalog, catalogError = pcall(function()
		if catalog.shirt then
			hd.Shirt = catalog.shirt
		end
		if catalog.pants then
			hd.Pants = catalog.pants
		end
		local accessories = {}
		for _, hatId in ipairs(catalog.hats or {}) do
			table.insert(accessories, { AccessoryType = Enum.AccessoryType.Hat, AssetId = hatId, IsLayered = false })
		end
		if catalog.layeredShirt then
			table.insert(accessories, {
				AccessoryType = Enum.AccessoryType.Shirt,
				AssetId = catalog.layeredShirt,
				IsLayered = true,
				Order = 1,
			})
		end
		hd:SetAccessories(accessories, true)
	end)
	if not okCatalog then
		fail(roleName, "catalog outfit failed: " .. tostring(catalogError))
	end

	-- Kids only: scale support is version-dependent, so an unsupported property
	-- is a warning, never a load failure.
	if role.bodyHeightScale ~= nil then
		local okHeight = pcall(function()
			hd.BodyHeightScale = role.bodyHeightScale
		end)
		if not okHeight then
			warnRole(roleName, warned, "BodyHeightScale unsupported")
		end
	end
	if role.headScale ~= nil then
		local okHead = pcall(function()
			hd.HeadScale = role.headScale
		end)
		if not okHead then
			warnRole(roleName, warned, "HeadScale unsupported")
		end
	end

	local okAsync, asyncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescriptionAsync
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescriptionAsync unavailable")
		end
		return create(Players, hd, Enum.HumanoidRigType.R15)
	end)
	if okAsync and asyncRig then
		return asyncRig
	end

	local okSync, syncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescription
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return create(Players, hd, Enum.HumanoidRigType.R15)
	end)
	if okSync and syncRig then
		return syncRig
	end
	warnRole(roleName, warned, "R15 rig unavailable: " .. tostring(syncRig))
	return nil
end

-- HumanoidDescription.BodyHeightScale is not a valid member in every Studio build,
-- so the description attempt above is best-effort. The authoritative values are
-- written to the rig's Humanoid scale Instances here, after the rig exists.
local function scaleRig(rig: any, role: any, roleName: string, warned: { [string]: boolean })
	if role.bodyHeightScale == nil and role.headScale == nil then
		return
	end
	local okHumanoid, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if not okHumanoid or not humanoid then
		warnRole(roleName, warned, "no Humanoid for scale")
		return
	end
	for key, value in pairs({ BodyHeightScale = role.bodyHeightScale, HeadScale = role.headScale }) do
		if value ~= nil then
			local okScale = pcall(function()
				local node = humanoid[key]
				if typeof(node) ~= "Instance" then
					error("scale node missing")
				end
				node.Value = value
			end)
			if not okScale then
				warnRole(roleName, warned, key .. " unsupported on rig")
			end
		end
	end
end

local function hatIdsText(catalog: any): string
	local parts = {}
	for _, hatId in ipairs(catalog.hats or {}) do
		parts[#parts + 1] = tostring(hatId)
	end
	return table.concat(parts, ",")
end

local function countHatAccessories(rig: any): number
	local found = 0
	pcall(function()
		for _, child in ipairs(rig:GetChildren()) do
			if child:IsA("Accessory") and child.AccessoryType == Enum.AccessoryType.Hat then
				found += 1
			end
		end
	end)
	return found
end

local function groundRig(model: any, slot: any, roleName: string, warned: { [string]: boolean }): boolean
	local okBox, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not okBox or not boxCFrame or not boxSize or not okPivot or not pivot then
		warnRole(roleName, warned, "could not measure rig bounds")
		return false
	end
	local bottomOffset = boxCFrame.Y - boxSize.Y * 0.5 - pivot.Y
	local okTarget, target = pcall(function()
		return CFrame.new(slot.x, slot.y - bottomOffset, slot.z) * CFrame.Angles(0, slot.ry, 0)
	end)
	if not okTarget or not target then
		warnRole(roleName, warned, "could not build ground CFrame")
		return false
	end
	if pcall(function()
		model:PivotTo(target)
	end) then
		return true
	end
	return pcall(function()
		model:SetPrimaryPartCFrame(target)
	end)
end

local function configureParts(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in ipairs(descendants) do
		pcall(function()
			if (descendant :: any):IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end)
	end
end

local function apply()
	clearActive()
	failures = 0
	pcall(function()
		(LookDevFailures :: any).reset(FAMILY_ID)
	end)

	local familyMap = Data.families[FAMILY_ID]
	if type(familyMap) ~= "table" or type(familyMap.roles) ~= "table" or type(familyMap.slots) ~= "table" then
		warn("[LookDevModelsNpcsR8] missing family map for " .. FAMILY_ID)
		LookDevFailures.set(FAMILY_ID, failures)
		return
	end

	local previous = findPrevious()
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder = newFolder()
	if not folder then
		LookDevFailures.set(FAMILY_ID, failures)
		return
	end
	activeFolder = folder

	local warned: { [string]: boolean } = {}
	local placed = 0
	for _, slot in ipairs(familyMap.slots) do
		local roleName = tostring(slot.slot)
		local role = familyMap.roles[slot.slot]
		if type(role) ~= "table" then
			warnRole(roleName, warned, "missing role data")
			continue
		end
		local rig = buildRig(role, roleName, warned)
		if rig then
			scaleRig(rig, role, roleName, warned)
			pcall(function()
				rig.Name = "R8_" .. roleName
				rig:SetAttribute("LookDevR8", FAMILY_ID)
				rig:SetAttribute("Role", roleName)
				rig:SetAttribute("ShirtId", role.catalog.shirt or role.catalog.layeredShirt)
				rig:SetAttribute("PantsId", role.catalog.pants)
				rig:SetAttribute("HatIds", hatIdsText(role.catalog))
			end)
			if groundRig(rig, slot, roleName, warned) then
				pcall(function()
					rig.Parent = folder
				end)
				configureParts(rig)
				local expected = #(role.catalog.hats or {})
				local found = countHatAccessories(rig)
				if found < expected then
					fail(roleName, "catalog hats attached " .. found .. "/" .. expected)
				end
				placed += 1
			end
		end
	end
	if placed < #familyMap.slots then
		warn("[LookDevModelsNpcsR8] " .. FAMILY_ID .. " placed " .. placed .. "/" .. #familyMap.slots .. " rigs")
	end
	LookDevFailures.set(FAMILY_ID, failures)
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

LookDevModelsNpcsR8.apply = apply
LookDevModelsNpcsR8.restore = restore

LookDev.register("npcs_r8", { apply = apply, restore = restore })

return LookDevModelsNpcsR8
