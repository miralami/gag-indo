--!strict
-- LookDevModelsNpcsR7: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_r7"
-- candidate (WORK_QUEUE item 56, hats + real costumes). Enable from a Studio
-- Server command bar; .restore() puts the previous staging folder back.
--
-- Bodies, colours, slots and yaw are the R6 rig contract. Costume Image IDs live
-- only in Shared.ModelMapNpcsR7. Hats come from the baked-copy-first loader
-- (ServerStorage.LookDevAssets -> LoadAsset fallback) and are ALWAYS attached via
-- Humanoid:AddAccessory; a bare MeshPart is wrapped in an Accessory/Handle with a
-- HatAttachment matching the head. Pak RT gets an original black Fabric peci with
-- no asset ID. Every hat problem increments the shared failure counter and warns.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsNpcsR7] missing service " .. name)
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
		warn("[LookDevModelsNpcsR7] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return
		require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapNpcsR7),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevModelsNpcsR7] could not require LookDev / ModelMapNpcsR7 / LookDevFailures")
	return {}
end

local LookDevModelsNpcsR7 = {}

local FAMILY_ID = "npcs_r7"
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

-- A hat failure is never silent. The final count is published with
-- LookDevFailures.set() at the end of apply(), even when apply() bails early.
local function fail(roleName: string, message: string)
	failures += 1
	warn("[LookDevModelsNpcsR7] " .. roleName .. ": " .. message)
end

-- Non-hat staging warnings: reported once per role, not counted as hat failures.
local function warnRole(roleName: string, warned: { [string]: boolean }, message: string)
	if warned[roleName] then
		return
	end
	warned[roleName] = true
	warn("[LookDevModelsNpcsR7] " .. roleName .. ": " .. message)
end

local function folderName(): string
	return "LookDevModelsNpcsR7_" .. FAMILY_ID
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
		warn("[LookDevModelsNpcsR7] could not create staging folder")
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

-- Image IDs go on classic clothing SIBLINGS of the Humanoid, never on
-- HumanoidDescription (which rejects Image IDs).
local function dressRig(rig: any, humanoid: any?, role: any, roleName: string, warned: { [string]: boolean })
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
end

-- AddAccessory needs a named Head attachment. R15 heads normally have one; make
-- it when a baked rig is missing it so a wrapped hat still mounts correctly.
local function headAndAttachment(rig: any, roleName: string)
	local okHead, head = pcall(function()
		return rig:FindFirstChild("Head")
	end)
	if not okHead or not head then
		fail(roleName, "no Head part for hat mount")
		return nil, nil
	end
	local okAttach, attachment = pcall(function()
		return head:FindFirstChild("HatAttachment")
	end)
	if okAttach and attachment then
		return head, attachment
	end
	local okMake, made = pcall(function()
		local created = Instance.new("Attachment")
		created.Name = "HatAttachment"
		created.CFrame = CFrame.new(0, head.Size.Y * 0.5, 0)
		created.Parent = head
		return created
	end)
	if okMake and made then
		return head, made
	end
	fail(roleName, "could not create Head HatAttachment")
	return nil, nil
end

local function findAccessory(root: any): any?
	local okSelf, isAccessory = pcall(function()
		return root:IsA("Accessory")
	end)
	if okSelf and isAccessory then
		return root
	end
	local okDescendants, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if not okDescendants or not descendants then
		return nil
	end
	for _, descendant in ipairs(descendants) do
		local ok, matches = pcall(function()
			return descendant:IsA("Accessory")
		end)
		if ok and matches then
			return descendant
		end
	end
	return nil
end

local function findBasePart(root: any): any?
	local okSelf, isPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okSelf and isPart then
		return root
	end
	local okDescendants, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if not okDescendants or not descendants then
		return nil
	end
	for _, descendant in ipairs(descendants) do
		local ok, matches = pcall(function()
			return descendant:IsA("BasePart")
		end)
		if ok and matches then
			return descendant
		end
	end
	return nil
end

-- Bare MeshPart -> Accessory with a Handle and a HatAttachment matching the head.
local function wrapMesh(part: any, headAttachment: any, hat: any, roleName: string): any?
	local okSize = pcall(function()
		local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
		local largest = math.max(sx, sy, sz)
		if largest <= 0 then
			error("invalid hat size")
		end
		local factor = hat.targetSize / largest
		part.Size = Vector3.new(sx * factor, sy * factor, sz * factor)
		part.CFrame = headAttachment.WorldCFrame * CFrame.new(0, hat.offsetY, 0)
	end)
	if not okSize then
		fail(roleName, "could not size wrapped hat")
		return nil
	end
	local okWrap, accessory = pcall(function()
		local acc = Instance.new("Accessory")
		acc.Name = hat.name or "Hat"
		part.Name = "Handle"
		part.Parent = acc
		local existing = part:FindFirstChild(headAttachment.Name)
		if not existing then
			local attachment = Instance.new("Attachment")
			attachment.Name = headAttachment.Name
			attachment.CFrame = headAttachment.CFrame
			attachment.Parent = part
		end
		return acc
	end)
	if not okWrap or not accessory then
		fail(roleName, "could not wrap hat MeshPart: " .. tostring(accessory))
		return nil
	end
	return accessory
end

local function attachHat(rig: any, humanoid: any?, hat: any, roleName: string)
	if type(hat) ~= "table" or type(hat.id) ~= "number" then
		fail(roleName, "missing/bad hat data")
		return
	end
	-- The baked copy is preferred by the loader; LoadAsset is only a fallback.
	local okLoad, loaded = pcall(function()
		return require(script.Parent.LookDevAssetLoader).get(hat.id, "npcs_r7")
	end)
	if not okLoad or not loaded then
		fail(roleName, "hat load failed: " .. tostring(loaded))
		return
	end
	local _, headAttachment = headAndAttachment(rig, roleName)
	if not headAttachment then
		return
	end

	local accessory = findAccessory(loaded)
	if not accessory then
		local part = findBasePart(loaded)
		if not part then
			fail(roleName, "hat has no Accessory or usable BasePart")
			return
		end
		local okWrap, wrapped = pcall(wrapMesh, part, headAttachment, hat, roleName)
		if not okWrap then
			fail(roleName, "hat wrap threw: " .. tostring(wrapped))
			return
		end
		if not wrapped then
			return -- wrapMesh already counted and warned
		end
		accessory = wrapped
	end

	local okAdd, addError = pcall(function()
		(humanoid :: any):AddAccessory(accessory)
	end)
	if not okAdd then
		fail(roleName, "AddAccessory failed: " .. tostring(addError))
	end
end

-- Original peci: black Fabric cylinder, 1.1 x 0.55 x 0.95, straight on the Head.
-- No asset ID: this is built from primitives, then AddAccessory just like real hats.
local function attachPeci(rig: any, humanoid: any?, roleName: string)
	local spec = (Data.hats :: any).peci
	if type(spec) ~= "table" or type(spec.size) ~= "table" then
		fail(roleName, "missing/bad peci build data")
		return
	end
	local head, headAttachment = headAndAttachment(rig, roleName)
	if not head or not headAttachment then
		return
	end

	local okBuild, accessory = pcall(function()
		local acc = Instance.new("Accessory")
		acc.Name = spec.name or "PakRT_Peci"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(spec.size.x, spec.size.y, spec.size.z)
		handle.Material = Enum.Material.Fabric
		handle.Color = Color3.fromRGB(26, 26, 26) -- #1A1A1A
		handle.CanCollide = false
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Parent = handle
		local attachment = Instance.new("Attachment")
		attachment.Name = headAttachment.Name
		attachment.CFrame = CFrame.new(0, -spec.size.y * 0.5, 0)
		attachment.Parent = handle
		handle.CFrame = headAttachment.WorldCFrame * CFrame.new(0, spec.size.y * 0.5, 0)
		handle.Parent = acc
		return acc
	end)
	if not okBuild or not accessory then
		fail(roleName, "peci build failed: " .. tostring(accessory))
		return
	end

	local okAdd, addError = pcall(function()
		(humanoid :: any):AddAccessory(accessory)
	end)
	if okAdd then
		return
	end
	fail(roleName, "peci AddAccessory failed: " .. tostring(addError) .. "; welding fallback")

	-- Keep the Accessory child even when the engine refuses AddAccessory: weld the
	-- Handle directly to the Head, centred on its top surface.
	pcall(function()
		local handle = accessory:FindFirstChild("Handle")
		if handle then
			handle.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.5 + spec.size.y * 0.5, 0)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = handle
			weld.Parent = handle
		end
		accessory.Parent = rig
	end)
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
		warn("[LookDevModelsNpcsR7] missing family map for " .. FAMILY_ID)
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
			pcall(function()
				rig.Name = "R7_" .. slot.slot
				rig:SetAttribute("LookDevR7", FAMILY_ID)
				rig:SetAttribute("Role", roleName)
			end)
			if groundRig(rig, slot, roleName, warned) then
				pcall(function()
					rig.Parent = folder
				end)
				configureParts(rig)
				local humanoid = findHumanoid(rig)
				dressRig(rig, humanoid, role, roleName, warned)

				local hatKey = role.hat
				if hatKey == "peci" then
					attachPeci(rig, humanoid, roleName)
				elseif hatKey then
					attachHat(rig, humanoid, (Data.hats :: any)[hatKey], roleName)
				end
				placed += 1
			end
		end
	end
	if placed < #familyMap.slots then
		warn("[LookDevModelsNpcsR7] " .. FAMILY_ID .. " placed " .. placed .. "/" .. #familyMap.slots .. " rigs")
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

LookDevModelsNpcsR7.apply = apply
LookDevModelsNpcsR7.restore = restore

LookDev.register("npcs_r7", { apply = apply, restore = restore })

return LookDevModelsNpcsR7
