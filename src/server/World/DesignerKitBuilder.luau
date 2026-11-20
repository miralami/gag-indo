--!strict
-- DesignerKitBuilder: Studio-only, manually invoked kit assembly for WORK_QUEUE item 49.
--
-- Studio Command Bar (Server, Edit mode, Rojo synced):
--   require(game.ServerScriptService.Server.World.DesignerKitBuilder).build()
--   require(game.ServerScriptService.Server.World.DesignerKitBuilder).clear()
--
-- `build(parent?)` makes one Folder named by Shared.DesignerKitMap.folderName under `parent`
-- (ServerStorage when omitted) and fills it from the data map. `clear(parent?)` destroys
-- only that exact folder. Requiring this module does nothing. No service is started, no
-- LookDev candidate is registered, no spawn is dressed, no terrain is sculpted and nothing
-- is saved or published. Every engine call is pcall-guarded: a failure warns and skips.

local DesignerKitBuilder = {}

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[DesignerKitBuilder] missing service " .. name)
		return nil
	end
	return value
end

local function kitMap(): any?
	local replicated = service("ReplicatedStorage")
	if not replicated then
		return nil
	end
	local okShared, shared = pcall(function()
		return (replicated :: any):WaitForChild("Shared")
	end)
	if not okShared or not shared then
		warn("[DesignerKitBuilder] missing Shared folder")
		return nil
	end
	local okMap, map = pcall(function()
		return require((shared :: any).DesignerKitMap)
	end)
	if not okMap or not map then
		warn("[DesignerKitBuilder] could not require Shared.DesignerKitMap")
		return nil
	end
	return map
end

local function resolveParent(requested: any?): any?
	if requested ~= nil then
		return requested
	end
	return service("ServerStorage")
end

local function stripScripts(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in ipairs(descendants) do
		pcall(function()
			if (descendant :: any):IsA("LuaSourceContainer") then
				(descendant :: any):Destroy()
			end
		end)
	end
end

local function anchorAndDisableCollision(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in ipairs(descendants) do
		pcall(function()
			if (descendant :: any):IsA("BasePart") then
				(descendant :: any).Anchored = true;
				(descendant :: any).CanCollide = false
			end
		end)
	end
end

local function measure(model: any): (any?, number?)
	local ok, boxCFrame, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not boxCFrame or not size then
		return nil, nil
	end
	local height = size.Y
	if height <= 0.01 or height ~= height then
		return boxCFrame, nil
	end
	return boxCFrame, height
end

local function scaleToHeight(model: any, target: any?, height: number?): boolean
	if type(target) ~= "number" or target <= 0.01 or target ~= target or not height then
		return true -- no target: keep the source scale, true to the original asset
	end
	return pcall(function()
		model:ScaleTo(target / height)
	end)
end

-- Bounding-box bottom to y=0: measure the world box, read the current pivot, then move
-- that pivot down by the box's bottom height. Never changes the source scale or rotation.
local function pivotAtBase(model: any, name: string): boolean
	local boxCFrame, height = measure(model)
	if not boxCFrame or not height then
		warn("[DesignerKitBuilder] " .. name .. ": could not measure bounds for base pivot")
		return false
	end
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not okPivot or not pivot then
		warn("[DesignerKitBuilder] " .. name .. ": could not read pivot")
		return false
	end
	local bottomY = boxCFrame.Y - height * 0.5
	local okTarget, target = pcall(function()
		return pivot - Vector3.new(0, bottomY, 0)
	end)
	if not okTarget or not target then
		warn("[DesignerKitBuilder] " .. name .. ": could not build base pivot target")
		return false
	end
	local okMove = pcall(function()
		model:PivotTo(target)
	end)
	if not okMove then
		warn("[DesignerKitBuilder] " .. name .. ": PivotTo failed")
	end
	return okMove
end

local function loadModel(id: number, name: string): any?
	local insertService = service("InsertService")
	if not insertService then
		return nil
	end
	local ok, model = pcall(function()
		return (insertService :: any):LoadAsset(id)
	end)
	if not ok or not model then
		warn("[DesignerKitBuilder] " .. name .. ": LoadAsset failed for a source-map id")
		return nil
	end
	return model
end

local function rgb(parts: any): any?
	local ok, colour = pcall(function()
		return Color3.fromRGB(parts.r, parts.g, parts.b)
	end)
	if not ok or not colour then
		return nil
	end
	return colour
end

-- R15 role rig from ModelMapNpcsR5 body colours only: no costume Image ID, no hat ID,
-- no imported body model. A failed colour or API call skips just that role.
local function buildRole(role: any, name: string): any?
	local players = service("Players")
	if not players then
		return nil
	end
	local okDescription, value = pcall(function()
		return Instance.new("HumanoidDescription")
	end)
	if not okDescription or not value then
		warn("[DesignerKitBuilder] " .. name .. ": HumanoidDescription unavailable")
		return nil
	end
	local description: any = value
	local skin = rgb(role.skin)
	local shirt = rgb(role.shirt)
	local pants = rgb(role.pants)
	if not skin or not shirt or not pants then
		warn("[DesignerKitBuilder] " .. name .. ": invalid role body colours")
		return nil
	end
	local okColours = pcall(function()
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = shirt
		description.LeftLegColor = pants
		description.RightLegColor = pants
	end)
	if not okColours then
		warn("[DesignerKitBuilder] " .. name .. ": could not set body colours")
		return nil
	end
	local okRig, rig = pcall(function()
		return (players :: any):CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not okRig or not rig then
		warn("[DesignerKitBuilder] " .. name .. ": R15 rig unavailable")
		return nil
	end
	return rig
end

local function buildItem(entry: any): any?
	local name = entry.name
	local model
	if type(entry.id) == "number" then
		model = loadModel(entry.id, name)
	elseif entry.role ~= nil then
		model = buildRole(entry.role, name)
	else
		warn("[DesignerKitBuilder] " .. tostring(name) .. ": no source id or role")
		return nil
	end
	if not model then
		return nil
	end
	stripScripts(model)
	anchorAndDisableCollision(model)
	local _, height = measure(model)
	if not scaleToHeight(model, entry.targetHeight, height) then
		warn("[DesignerKitBuilder] " .. name .. ": ScaleTo failed")
	end
	pivotAtBase(model, name)
	return model
end

function DesignerKitBuilder.build(parent: any?): any?
	local map = kitMap()
	if not map then
		return nil
	end
	local target = resolveParent(parent)
	if not target then
		warn("[DesignerKitBuilder] no parent for " .. map.folderName)
		return nil
	end
	local okFolder, folder = pcall(function()
		local created = Instance.new("Folder")
		created.Name = map.folderName
		created.Parent = target
		return created
	end)
	if not okFolder or not folder then
		warn("[DesignerKitBuilder] could not create " .. map.folderName)
		return nil
	end
	for _, entry in ipairs(map.items) do
		local okItem, err = pcall(function()
			local model = buildItem(entry)
			if model then
				local okParent = pcall(function()
					model.Name = entry.name
					model.Parent = folder
				end)
				if not okParent then
					warn("[DesignerKitBuilder] could not parent " .. entry.name)
				end
			end
		end)
		if not okItem then
			warn("[DesignerKitBuilder] " .. entry.name .. ": " .. tostring(err))
		end
	end
	return folder
end

function DesignerKitBuilder.clear(parent: any?): boolean
	local map = kitMap()
	if not map then
		return false
	end
	local target = resolveParent(parent)
	if not target then
		warn("[DesignerKitBuilder] no parent for clear")
		return false
	end
	local okFind, folder = pcall(function()
		return (target :: any):FindFirstChild(map.folderName)
	end)
	if not okFind then
		warn("[DesignerKitBuilder] could not search for " .. map.folderName)
		return false
	end
	if not folder then
		return false
	end
	local okDestroy = pcall(function()
		(folder :: any):Destroy()
	end)
	if not okDestroy then
		warn("[DesignerKitBuilder] could not destroy " .. map.folderName)
		return false
	end
	return true
end

return DesignerKitBuilder
