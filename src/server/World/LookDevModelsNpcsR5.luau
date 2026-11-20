--!strict
-- LookDevModelsNpcsR5: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_r5"
-- candidate (WORK_QUEUE item 40, solid Roblox R15 villagers). InsertService:LoadAsset
-- is blocked on the client, so require this from Main.server.luau and toggle from a
-- Studio Server command bar. Eligibility is handled by Shared.LookDev: off until
-- .enable("npcs_r5") is called; .disable() restores the previous look.
--
-- Every role is built from Instance.new("HumanoidDescription") plus
-- Players:CreateHumanoidModelFromDescription(..., Enum.HumanoidRigType.R15), so the
-- body is solid and upright. No imported body model, no animation and no rotation
-- about X: the only orientation spins about the vertical axis. The three real
-- Creator Store hat Models are loaded by InsertService and scaled to a data-defined
-- size; a missing API or a failed hat only skips that piece, never bootstrap.
--
-- No asset ID literal lives here: IDs, colours, slots, camera and hat sizes come
-- only from Shared.ModelMapNpcsR5. Every engine call is pcall-guarded.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsNpcsR5] missing service " .. name)
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
		warn("[LookDevModelsNpcsR5] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, ModelMapNpcsR5 = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapNpcsR5)
end)
if not okModules or not LookDev or not ModelMapNpcsR5 then
	warn("[LookDevModelsNpcsR5] could not require LookDev / ModelMapNpcsR5")
	return {}
end

local okLoaders, loadedFailures, loadedAssetLoader = pcall(function()
	return require((Shared :: any).LookDevFailures), require(script.Parent.LookDevAssetLoader)
end)
if not okLoaders or not loadedFailures or not loadedAssetLoader then
	warn("[LookDevModelsNpcsR5] could not require LookDevFailures / LookDevAssetLoader")
	return {}
end
local LookDevFailures = loadedFailures
local LookDevAssetLoader = loadedAssetLoader

local LookDevModelsNpcsR5 = {}

local FAMILY_ID = "npcs_r5"
local activeFolder: any? = nil
local savedFolder: any? = nil

local function folderName(): string
	return "LookDevModelsNpcsR5_" .. FAMILY_ID
end

-- Warn at most once per role, so a missing API/service never floods Output.
local function warnRole(roleName: string, warned: { [string]: boolean }, message: string)
	if warned[roleName] then
		return
	end
	warned[roleName] = true
	warn("[LookDevModelsNpcsR5] " .. roleName .. ": " .. message)
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
		warn("[LookDevModelsNpcsR5] could not create staging folder")
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
-- shirt on the torso and pants on both legs.
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

	local okRig, rig = pcall(function()
		if not Players or type((Players :: any).CreateHumanoidModelFromDescription) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return (Players :: any):CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R15)
	end)
	if not okRig or not rig then
		warnRole(roleName, warned, "R15 rig unavailable: " .. tostring(rig))
		return nil
	end
	return rig
end

-- Measure the bounding box, then put its bottom on the slot's ground height.
-- bottomOffset is measured from the rig's own pivot, so subtracting it from slot.y
-- grounds the model; ry only spins about Y, so no lying-down rotation is possible.
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

-- Hat Models are not HumanoidDescription Accessory assets: load them, take the
-- first BasePart, scale its largest dimension to the data-defined size and place
-- it on the head. Any failure skips only the hat; the solid body stays staged.
local function attachHat(model: any, accessory: any, roleName: string, warned: { [string]: boolean })
	if type(accessory.id) ~= "number" or accessory.id <= 0 or accessory.id % 1 ~= 0 then
		LookDevFailures.add(FAMILY_ID, 1)
		warnRole(roleName, warned, "hat has no asset ID")
		return
	end
	-- Legacy runtime path was `(InsertService :: any):LoadAsset(accessory.id)`;
	-- the loader clones the baked hat first and counts failures loudly.
	local loaded = LookDevAssetLoader.get(accessory.id, FAMILY_ID)
	if not loaded then
		warnRole(roleName, warned, "hat LoadAsset failed: " .. tostring(loaded))
		return
	end

	local okPart, part = pcall(function()
		for _, descendant in ipairs(loaded:GetDescendants()) do
			if descendant:IsA("BasePart") then
				return descendant
			end
		end
		return nil
	end)
	if not okPart or not part then
		warnRole(roleName, warned, "hat has no BasePart")
		return
	end

	local okScale = pcall(function()
		local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
		local largest = math.max(sx, sy, sz)
		if largest <= 0 then
			error("invalid hat size")
		end
		local factor = accessory.targetSize / largest
		part.Size = Vector3.new(sx * factor, sy * factor, sz * factor)
	end)
	if not okScale then
		warnRole(roleName, warned, "could not scale hat")
		return
	end

	local okHead, head = pcall(function()
		return model:FindFirstChild("Head")
	end)
	if not okHead or not head then
		warnRole(roleName, warned, "no Head for hat")
		return
	end
	pcall(function()
		part.CFrame = head.CFrame * CFrame.new(0, accessory.offsetY, 0)
	end)
	pcall(function()
		part.Anchored = true
	end)
	pcall(function()
		part.CanCollide = false
	end)
	pcall(function()
		part.Parent = model
	end)
end

local applier = {
	apply = function()
		clearActive()
		local familyMap = ModelMapNpcsR5.families[FAMILY_ID]
		if type(familyMap) ~= "table" or type(familyMap.roles) ~= "table" or type(familyMap.slots) ~= "table" then
			warn("[LookDevModelsNpcsR5] missing family map for " .. FAMILY_ID)
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
					rig.Name = "R5_" .. slot.slot
				end)
				if groundRig(rig, slot, tostring(slot.slot), warned) then
					pcall(function()
						rig.Parent = folder
					end)
					configureParts(rig)
					local accessory = if role.hat then ModelMapNpcsR5.accessories[role.hat] else nil
					if accessory then
						attachHat(rig, accessory, tostring(slot.slot), warned)
					end
					placed += 1
				end
			end
		end
		if placed < #familyMap.slots then
			warn("[LookDevModelsNpcsR5] " .. FAMILY_ID .. " placed " .. placed .. "/" .. #familyMap.slots .. " rigs")
		end
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
	end,
}

LookDevModelsNpcsR5.apply = applier.apply
LookDevModelsNpcsR5.restore = applier.restore

LookDev.register("npcs_r5", applier)

return LookDevModelsNpcsR5
