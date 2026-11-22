--!strict
-- LookDevSpawnDressingR5: SERVER-ONLY applier for the OFF-BY-DEFAULT "spawn_r5" candidate
-- (WORK_QUEUE item 41, spawn dressing pass). InsertService:LoadAsset works in the Server
-- datamodel but is blocked on the client, so require this from Main.server.luau and toggle from
-- a Studio Server command bar via LookDev.enable("spawn_r5").
--
-- Every position, model ID, palette and hat size comes from pure data modules under Shared.
-- This file contains no ID literals. Model placement follows the proven PropsR5 path (orient,
-- measure, ScaleTo, bbox-bottom grounding); character placement follows the proven NpcsR5 R15
-- path (HumanoidDescription, upright Y-only rotation, optional Creator Store hat Model). Every
-- engine call is pcall-guarded; a failed hat only skips that hat. apply() detaches any previous
-- same-named folder and restore() puts that exact folder back. Nothing is applied by default.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSpawnDressingR5] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local InsertService = service("InsertService")
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
		warn("[LookDevSpawnDressingR5] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, SpawnDressingMapR5, ModelMapNpcsR5 = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).SpawnDressingMapR5),
		require((Shared :: any).ModelMapNpcsR5)
end)
if not okModules or not LookDev or not SpawnDressingMapR5 or not ModelMapNpcsR5 then
	warn("[LookDevSpawnDressingR5] could not require LookDev / SpawnDressingMapR5 / ModelMapNpcsR5")
	return {}
end

local LookDevSpawnDressingR5 = {}

local activeFolder: any? = nil
local savedFolder: any? = nil
local activeTier = "Sedang"

local function folderName(): string
	return "LookDevSpawnDressingR5_" .. SpawnDressingMapR5.id
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
		warn("[LookDevSpawnDressingR5] could not create staging folder")
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

local function warnEntry(entry: any, message: string)
	warn("[LookDevSpawnDressingR5] " .. entry.slot .. ": " .. message)
end

-- MODEL PATH ------------------------------------------------------------------------------------

-- Rotate about the model's own pivot before measuring: a Z-up import needs rotX first, otherwise
-- ScaleTo would normalise its depth instead of its upright height.
local function orient(model: any, entry: any): boolean
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not ok or not pivot then
		return false
	end
	return pcall(function()
		model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(entry.rotX or 0, entry.ry, 0))
	end)
end

local function measure(model: any): (any?, number?)
	local ok, boxCFrame, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not boxCFrame or not size then
		return nil, nil
	end
	local bodySizeY = size.Y
	if bodySizeY <= 0.01 or bodySizeY ~= bodySizeY then
		return boxCFrame, nil
	end
	return boxCFrame, bodySizeY
end

-- targetHeight * the source scale (scale nil means keep the source height unchanged).
local function normaliseScale(model: any, entry: any, bodySizeY: number): boolean
	local target = if entry.scale then entry.targetHeight * entry.scale else entry.targetHeight
	if type(target) ~= "number" or target <= 0.01 or target ~= target then
		return false
	end
	return pcall(function()
		model:ScaleTo(target / bodySizeY)
	end)
end

-- Same bbox-bottom grounding math as PropsR5.placeAtGround: the pivot-to-bottom delta is added
-- to the data ground height, so the model rests on y=0.5 plus any stacked-sack yOffset.
local function placeAtGround(model: any, entry: any, boxCFrame: any?, bodySizeY: number?): boolean
	local y = (entry.y or 0) + (entry.yOffset or 0)
	if boxCFrame and bodySizeY then
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok and pivot then
			y += pivot.Y - boxCFrame.Y + bodySizeY * 0.5
		end
	end
	local okTarget, target = pcall(function()
		return CFrame.new(entry.x, y, entry.z) * CFrame.Angles(entry.rotX or 0, entry.ry, 0)
	end)
	if not okTarget or not target then
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

local function anchorAndDisableCollision(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in descendants do
		pcall(function()
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end)
	end
end

local function stageModel(entry: any, folder: any)
	local id = SpawnDressingMapR5.idFor(entry)
	if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
		warnEntry(entry, "missing or invalid resolved ID")
		return
	end
	local okLoad, model = pcall(function()
		if not InsertService then
			error("InsertService unavailable")
		end
		return (InsertService :: any):LoadAsset(id)
	end)
	if not okLoad or not model then
		warnEntry(entry, "LoadAsset failed: " .. tostring(model))
		return
	end
	pcall(function()
		model.Name = "R5_" .. entry.slot
	end)
	if not orient(model, entry) then
		warnEntry(entry, "could not orient")
	end
	local boxCFrame, bodySizeY = measure(model)
	if not bodySizeY then
		warnEntry(entry, "invalid bounding box")
		return
	end
	if not normaliseScale(model, entry, bodySizeY) then
		warnEntry(entry, "invalid target height")
	end
	local scaledBox, scaledSizeY = measure(model)
	anchorAndDisableCollision(model)
	placeAtGround(model, entry, scaledBox or boxCFrame, scaledSizeY or bodySizeY)
	pcall(function()
		model.Parent = folder
	end)
end

-- RIG PATH --------------------------------------------------------------------------------------

-- HumanoidDescription colours: skin on head and arms, shirt on torso, pants on both legs.
local function buildRig(role: any, roleName: string): any?
	local okDescription, value = pcall(function()
		return Instance.new("HumanoidDescription")
	end)
	if not okDescription or not value then
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": HumanoidDescription unavailable")
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
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": could not set description colours")
		return nil
	end
	local okRig, rig = pcall(function()
		if not Players or type((Players :: any).CreateHumanoidModelFromDescription) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return (Players :: any):CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R15)
	end)
	if not okRig or not rig then
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": R15 rig unavailable: " .. tostring(rig))
		return nil
	end
	return rig
end

-- Upright grounding. The only orientation is a vertical spin, so a rig can never lie down.
local function groundRig(model: any, entry: any): boolean
	local okBox, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not okBox or not boxCFrame or not boxSize or not okPivot or not pivot then
		return false
	end
	local bottomOffset = boxCFrame.Y - boxSize.Y * 0.5 - pivot.Y
	local okTarget, target = pcall(function()
		return CFrame.new(entry.x, entry.y - bottomOffset, entry.z) * CFrame.Angles(0, entry.ry, 0)
	end)
	if not okTarget or not target then
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

-- Hat Models are not HumanoidDescription Accessory assets: load, take the first BasePart, scale
-- its largest dimension to the data size and place it on the head. Failure skips only the hat.
local function attachHat(model: any, accessory: any, roleName: string)
	local okLoad, loaded = pcall(function()
		if not InsertService then
			error("InsertService unavailable")
		end
		return (InsertService :: any):LoadAsset(accessory.id)
	end)
	if not okLoad or not loaded then
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": hat load failed: " .. tostring(loaded))
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
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": hat has no BasePart")
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
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": could not scale hat")
		return
	end
	local okHead, head = pcall(function()
		return model:FindFirstChild("Head")
	end)
	if not okHead or not head then
		warn("[LookDevSpawnDressingR5] " .. roleName .. ": no Head for hat")
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

local function stageRig(entry: any, folder: any)
	local role = ModelMapNpcsR5.families.npcs_r5.roles[entry.key]
	if type(role) ~= "table" then
		warnEntry(entry, "missing role data")
		return
	end
	local rig = buildRig(role, entry.key)
	if not rig then
		return
	end
	pcall(function()
		rig.Name = "R5_" .. entry.key
	end)
	if not groundRig(rig, entry) then
		warnEntry(entry, "could not ground rig")
		return
	end
	pcall(function()
		rig.Parent = folder
	end)
	configureParts(rig)
	local accessory = SpawnDressingMapR5.accessoryFor(role)
	if accessory then
		attachHat(rig, accessory, entry.key)
	end
end

-- REGISTRY --------------------------------------------------------------------------------------

local applier = {
	apply = function()
		clearActive()
		local entries = SpawnDressingMapR5.entriesForTier(activeTier)
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
		for _, entry in ipairs(entries) do
			if entry.kind == "model" then
				stageModel(entry, folder)
			elseif entry.kind == "rig" then
				stageRig(entry, folder)
			end
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

function LookDevSpawnDressingR5.setTier(tier: string): boolean
	for _, candidate in ipairs(SpawnDressingMapR5.tiers) do
		if candidate == tier then
			activeTier = tier
			return true
		end
	end
	warn("[LookDevSpawnDressingR5] unknown tier: " .. tostring(tier))
	return false
end

LookDevSpawnDressingR5.apply = applier.apply
LookDevSpawnDressingR5.restore = applier.restore

LookDev.register("spawn_r5", applier)

return LookDevSpawnDressingR5
