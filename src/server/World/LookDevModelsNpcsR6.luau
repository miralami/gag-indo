--!strict
-- LookDevModelsNpcsR6: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_r6"
-- candidate (WORK_QUEUE item 48, role-specific textured R15 villagers).
-- InsertService:LoadAsset is blocked on the client, so require this from
-- Main.server.luau and toggle from a Studio Server command bar. Eligibility is
-- handled by Shared.LookDev: off until .enable("npcs_r6") is called; .disable()
-- restores the previous look.
--
-- Bodies come from HumanoidDescription with the Async creator preferred and the
-- older R5 creator only as a pcall-guarded fallback. The ten real Image IDs live
-- ONLY in Shared.ModelMapNpcsR6: they go on Shirt/Pants siblings of the Humanoid
-- (not on HumanoidDescription, which rejects Image IDs). Hat loading is a
-- multi-strategy attacher because the R5 round saw 0 accessories on all five
-- rigs. Every engine call is pcall-guarded; a missing template or a bad hat only
-- skips that piece and never breaks the toggle.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsNpcsR6] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Players = service("Players")
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = service("InsertService")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and value then
		Shared = value
	else
		warn("[LookDevModelsNpcsR6] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapNpcsR6)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevModelsNpcsR6] could not require LookDev / ModelMapNpcsR6")
	return {}
end

local okLoaders, loadedFailures, loadedAssetLoader = pcall(function()
	return require((Shared :: any).LookDevFailures), require(script.Parent.LookDevAssetLoader)
end)
if not okLoaders or not loadedFailures or not loadedAssetLoader then
	warn("[LookDevModelsNpcsR6] could not require LookDevFailures / LookDevAssetLoader")
	return {}
end
local LookDevFailures = loadedFailures
local LookDevAssetLoader = loadedAssetLoader

local LookDevModelsNpcsR6 = {}

local FAMILY_ID = "npcs_r6"
local activeFolder: any? = nil
local savedFolder: any? = nil

local function folderName(): string
	return "LookDevModelsNpcsR6_" .. FAMILY_ID
end

-- Warn at most once per role, so a missing API/service never floods Output.
local function warnRole(roleName: string, warned: { [string]: boolean }, message: string)
	if warned[roleName] then
		return
	end
	warned[roleName] = true
	warn("[LookDevModelsNpcsR6] " .. roleName .. ": " .. message)
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
		warn("[LookDevModelsNpcsR6] could not create staging folder")
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

-- HumanoidDescription colour fields are Color3. Skin goes on head and arms,
-- shirt on the torso and pants on both legs; the real textures are applied later.
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
		hd.HeadColor = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		hd.TorsoColor = Color3.fromRGB(role.shirt.r, role.shirt.g, role.shirt.b)
		hd.LeftArmColor = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		hd.RightArmColor = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		hd.LeftLegColor = Color3.fromRGB(role.pants.r, role.pants.g, role.pants.b)
		hd.RightLegColor = Color3.fromRGB(role.pants.r, role.pants.g, role.pants.b)
	end)
	if not okColours then
		warnRole(roleName, warned, "could not set HumanoidDescription colours")
		return nil
	end

	-- Preferred API first. The deprecated non-Async call is used only if the
	-- preferred one is missing or fails, and that attempt is itself pcall-guarded.
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

local function findHumanoid(rig: any): any?
	local ok, humanoid = pcall(function()
		return rig:FindFirstChild("Humanoid")
	end)
	if ok and humanoid then
		return humanoid
	end
	local okClass, byClass = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if okClass and byClass then
		return byClass
	end
	return nil
end

-- Image IDs are set on classic clothing SIBLINGS of the Humanoid, parented to the
-- rig Model (the Humanoid's parent). HumanoidDescription.Shirt/Pants take clothing
-- asset IDs, not Image IDs, so they are deliberately never touched here.
local function dressRig(rig: any, humanoid: any?, role: any, roleName: string, warned: { [string]: boolean }): boolean
	local parent = rig
	if humanoid then
		local okParent, humanoidParent = pcall(function()
			return humanoid.Parent
		end)
		if okParent and humanoidParent then
			parent = humanoidParent
		end
	end

	local okShirt = pcall(function()
		local shirt = Instance.new("Shirt")
		shirt.ShirtTemplate = "rbxassetid://" .. role.shirtId
		shirt.Parent = parent
	end)
	if not okShirt then
		warnRole(roleName, warned, "could not set Shirt template")
	end

	local okPants = pcall(function()
		local pants = Instance.new("Pants")
		pants.PantsTemplate = "rbxassetid://" .. role.pantsId
		pants.Parent = parent
	end)
	if not okPants then
		warnRole(roleName, warned, "could not set Pants template")
	end
	return okShirt or okPants
end

-- The R5 round staged five rigs with 0 accessories: one BasePart rescale was not
-- enough. Try, in order: LoadAsset -> Accessory descendant -> Humanoid:AddAccessory;
-- else the R5 first-BasePart rescale, parented under Head when one exists.
local function attachHat(rig: any, humanoid: any?, hat: any, roleName: string, warned: { [string]: boolean }): boolean
	if type(hat) ~= "table" or type(hat.id) ~= "number" or hat.id <= 0 or hat.id % 1 ~= 0 then
		LookDevFailures.add(FAMILY_ID, 1)
		warnRole(roleName, warned, "no hat data")
		return false
	end
	-- Legacy runtime path was LoadAsset(hat.id); the loader clones the baked hat first.
	local loaded = LookDevAssetLoader.get(hat.id, FAMILY_ID)
	if not loaded then
		warnRole(roleName, warned, "hat LoadAsset failed: " .. tostring(loaded))
		return false
	end

	local okDescendants, descendants = pcall(function()
		return loaded:GetDescendants()
	end)
	if not okDescendants or not descendants then
		descendants = {}
	end

	local okAccessory, accessory = pcall(function()
		for _, descendant in ipairs(descendants) do
			if descendant:IsA("Accessory") then
				return descendant
			end
		end
		return nil
	end)
	if okAccessory and accessory and humanoid then
		local okAdd = pcall(function()
			humanoid:AddAccessory(accessory)
		end)
		if okAdd then
			return true
		end
		warnRole(roleName, warned, "AddAccessory failed; trying BasePart fallback")
	end

	local okPart, part = pcall(function()
		for _, descendant in ipairs(descendants) do
			if descendant:IsA("BasePart") then
				return descendant
			end
		end
		return nil
	end)
	if not okPart or not part then
		warnRole(roleName, warned, "hat attach failed: no Accessory and no usable BasePart")
		return false
	end

	local okScale = pcall(function()
		local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
		local largest = math.max(sx, sy, sz)
		if largest <= 0 then
			error("invalid hat size")
		end
		local factor = hat.targetSize / largest
		part.Size = Vector3.new(sx * factor, sy * factor, sz * factor)
	end)
	if not okScale then
		warnRole(roleName, warned, "hat attach failed: could not scale BasePart")
		return false
	end

	local okHead, head = pcall(function()
		return rig:FindFirstChild("Head")
	end)
	local target = if okHead and head then head else rig
	if okHead and head then
		pcall(function()
			part.CFrame = head.CFrame * CFrame.new(0, hat.offsetY, 0)
		end)
	end
	pcall(function()
		part.Anchored = true
	end)
	pcall(function()
		part.CanCollide = false
	end)
	pcall(function()
		part.Parent = target
	end)
	return true
end

-- Measure the bounding box, then put its bottom on the slot's ground height.
-- slot.ry carries the 180-degree camera-facing flip from the data module; the
-- only rotation here is about the vertical axis.
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

-- Static review dummies: anchored, non-colliding, motionless.
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
	local familyMap = Data.families[FAMILY_ID]
	if type(familyMap) ~= "table" or type(familyMap.roles) ~= "table" or type(familyMap.slots) ~= "table" then
		warn("[LookDevModelsNpcsR6] missing family map for " .. FAMILY_ID)
		return
	end

	local previous = findPrevious()
	if previous then
		-- Detach, not Destroy: restore() puts this exact folder back.
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder = newFolder()
	if not folder then
		return
	end
	activeFolder = folder

	local warned: { [string]: boolean } = {}
	local placed = 0
	for _, slot in ipairs(familyMap.slots) do
		local role = familyMap.roles[slot.slot]
		if type(role) ~= "table" then
			warnRole(tostring(slot.slot), warned, "missing role data")
			continue
		end
		local rig = buildRig(role, tostring(slot.slot), warned)
		if rig then
			pcall(function()
				rig.Name = "R6_" .. slot.slot
			end)
			if groundRig(rig, slot, tostring(slot.slot), warned) then
				pcall(function()
					rig.Parent = folder
				end)
				configureParts(rig)
				local humanoid = findHumanoid(rig)
				dressRig(rig, humanoid, role, tostring(slot.slot), warned)
				if role.hat then
					local hat = Data.hats[role.hat]
					attachHat(rig, humanoid, hat, tostring(slot.slot), warned)
				end
				placed += 1
			end
		end
	end
	if placed < #familyMap.slots then
		warn("[LookDevModelsNpcsR6] " .. FAMILY_ID .. " placed " .. placed .. "/" .. #familyMap.slots .. " rigs")
	end
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

LookDevModelsNpcsR6.apply = apply
LookDevModelsNpcsR6.restore = restore

LookDev.register("npcs_r6", { apply = apply, restore = restore })

return LookDevModelsNpcsR6
