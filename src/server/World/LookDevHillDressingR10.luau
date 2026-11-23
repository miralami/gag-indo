--!strict
-- LookDevHillDressingR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "hill_dressing_r10"
-- candidate (WORK_QUEUE item 199, rebuilt by item 244). Stages baked item-189 rock models and
-- real R4 tropical-tree models on the four hill domes, with procedural Wedge/Cylinder fallbacks.
-- Every staged BasePart (including model descendants) carries HillDev-free tags HillDressing /
-- hill / kind / LookDevStage so the live per-hill counts still work. No Ball parts are staged:
-- item 244 removed the round green/brown "melon" crowns and rocks. Every created instance is
-- saved once and restored in LIFO order. apply/restore are idempotent and pcall-guarded.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("hill_dressing_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevHillDressingR10] missing service " .. name)
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
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevHillDressingR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, LookDevAssetLoader = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapHillDressingR10),
		require((Shared :: any).LookDevFailures),
		require(script.Parent.LookDevAssetLoader)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevHillDressingR10] could not require LookDev / ModelMapHillDressingR10 / LookDevFailures")
	return {}
end
if not LookDevAssetLoader then
	warn("[LookDevHillDressingR10] LookDevAssetLoader unavailable; using procedural fallbacks")
end

local LookDevHillDressingR10 = {}

local FAMILY_ID = Data.id

-- Real IDs live here, NOT in the pure data module (its data-only spec forbids 8-digit literals).
-- Rocks: the three item-189 baked Creator Store IDs from ASSET_MANIFEST.md. LookDevAssets is
-- empty in this place and LoadAsset on these IDs is unauthorised, so rocks use baked() ONLY —
-- no LoadAsset call, no LookDevFailures increment; missing rocks take the Wedge/Cylinder path.
-- Trees: the four verified R4 tropical IDs; get() is baked-first with a working LoadAsset
-- fallback in this place.
local ASSET_IDS: { [string]: number } = {
	rock_round = 16098456067,
	rock_flat = 5644862709,
	rock_tall = 53370997,
	kelapa = 95769944522207,
	pisang = 119293239911242,
	mangga = 103132734600778,
	bambu = 130965811347980,
}

local failures = 0
local active = false
local created: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevHillDressingR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function stageFolder(): any?
	local okFind, existing = pcall(function()
		return (Workspace :: any):FindFirstChild((Data :: any).folderName)
	end)
	if not okFind then
		fail("could not look up staging folder: " .. tostring(existing))
		return nil
	end
	if existing then
		folder = existing
		return existing
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okNew or not instance then
		fail("could not create staging folder: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = (Data :: any).folderName
		instance.Parent = Workspace
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent staging folder: " .. tostring(why))
		return nil
	end
	created[#created + 1] = instance
	folder = instance
	return instance
end

local function setTags(part: any, descriptor: any)
	pcall(function()
		part:SetAttribute("HillDressing", true)
		part:SetAttribute("hill", descriptor.hill)
		part:SetAttribute("kind", descriptor.kind)
		part:SetAttribute("LookDevStage", FAMILY_ID)
	end)
end

local function partType(shapeName: string): any?
	local ok, partTypeValue = pcall(function()
		return (Enum :: any).PartType[shapeName]
	end)
	if not ok or not partTypeValue then
		fail("unknown part shape " .. shapeName)
		return nil
	end
	return partTypeValue
end

local function stagePart(
	name: string,
	shapeName: string,
	position: { number },
	size: { number },
	color: any,
	descriptor: any,
	parent: any,
	material: any?
)
	if shapeName == "Ball" then
		fail("Ball shape rejected for " .. name)
		return
	end
	local shape = partType(shapeName)
	if not shape then
		return
	end
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = shape
		instance.Size = Vector3.new(size[1], size[2], size[3])
		instance.CFrame = CFrame.new(position[1], position[2], position[3])
		instance.Color = Color3.fromRGB(color.r, color.g, color.b)
		instance.Material = material or Enum.Material.Slate
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = name
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. name .. ": " .. tostring(part))
		return
	end
	setTags(part, descriptor)
	created[#created + 1] = part
	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. name .. ": " .. tostring(why))
	end
end

local function bounds(instance: any)
	local ok, cframe, size = pcall(function()
		if instance:IsA("Model") then
			return instance:GetBoundingBox()
		end
		if instance:IsA("BasePart") then
			return instance.CFrame, instance.Size
		end
		return nil, nil
	end)
	if ok then
		return cframe, size
	end
	return nil, nil
end

local function scaleToHeight(instance: any, targetHeight: number): boolean
	local _, size = bounds(instance)
	local nativeY = if size and size.Y > 0 then size.Y else 1
	local factor = targetHeight / nativeY
	if factor <= 0 or factor > 10000 then
		return false
	end
	local ok = pcall(function()
		if instance:IsA("Model") then
			instance:ScaleTo(factor)
		elseif instance:IsA("BasePart") then
			instance.Size = instance.Size * factor
		end
	end)
	return ok
end

-- A baked model can itself contain a Ball primitive. NO_MELONS counts ALL staged descendants,
-- so convert any >=1.5-stud Part Ball to a Cylinder while keeping its size and placement.
local function normaliseModel(model: any, descriptor: any)
	local okDescendants, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return
	end
	for _, child in ipairs(descendants) do
		pcall(function()
			if child:IsA("LuaSourceContainer") then
				child:Destroy()
			end
		end)
		local okBase, isBase = pcall(function()
			return child:IsA("BasePart")
		end)
		if okBase and isBase then
			pcall(function()
				if child:IsA("Part") and child.Shape == Enum.PartType.Ball then
					local size = child.Size
					if math.max(size.X, size.Y, size.Z) >= 1.5 then
						child.Shape = Enum.PartType.Cylinder
					end
				end
				child.Anchored = true
				child.CanCollide = false
				child.CastShadow = false
			end)
			-- Every part of a multi-part tree still counts as a palm for check_q199.
			setTags(child, descriptor)
		end
	end
	pcall(function()
		if model:IsA("BasePart") then
			model.Anchored = true
			model.CanCollide = false
			model.CastShadow = false
			setTags(model, descriptor)
		end
	end)
end

local function placeAt(instance: any, position: { number })
	pcall(function()
		local bboxCFrame, _ = bounds(instance)
		local pivot: any = if instance:IsA("Model") then instance:GetPivot() else instance.CFrame
		if bboxCFrame and pivot then
			local offset = bboxCFrame.Position - pivot.Position
			local target = CFrame.new(Vector3.new(position[1], position[2], position[3]) - offset)
			if instance:IsA("Model") then
				instance:PivotTo(target)
			else
				instance.CFrame = target
			end
		end
	end)
end

local function loadModel(descriptor: any)
	local key = descriptor.asset
	if type(key) ~= "string" or not LookDevAssetLoader then
		return nil
	end
	local assetId = ASSET_IDS[key]
	if type(assetId) ~= "number" then
		return nil
	end
	local ok, model
	if descriptor.kind == "rock" then
		-- Baked-only: item-189 LoadAsset is unauthorised in this place.
		ok, model = pcall(function()
			return (LookDevAssetLoader :: any).baked(assetId)
		end)
	else
		ok, model = pcall(function()
			return (LookDevAssetLoader :: any).get(assetId, FAMILY_ID)
		end)
	end
	if not ok or not model then
		return nil
	end
	return model
end

local function stageModel(descriptor: any, parent: any): boolean
	local model = loadModel(descriptor)
	if not model then
		return false
	end
	if not scaleToHeight(model, descriptor.size[2]) then
		pcall(function()
			model:Destroy()
		end)
		return false
	end
	normaliseModel(model, descriptor)
	placeAt(model, descriptor.position)
	local okParent, why = pcall(function()
		model.Name = descriptor.name
		model.Parent = parent
	end)
	if not okParent then
		pcall(function()
			model:Destroy()
		end)
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
		return false
	end
	created[#created + 1] = model
	return true
end

local function stageDescriptor(descriptor: any, parent: any)
	if descriptor.asset and stageModel(descriptor, parent) then
		return
	end
	local material = if descriptor.kind == "rock"
		then Enum.Material.Slate
		elseif descriptor.kind == "palm" then Enum.Material.Wood
		else Enum.Material.Granite
	stagePart(
		descriptor.name,
		descriptor.shape,
		descriptor.position,
		descriptor.size,
		descriptor.color,
		descriptor,
		parent,
		material
	)
	if
		descriptor.kind == "palm"
		and descriptor.canopyOffset
		and descriptor.canopySize
		and descriptor.canopyColor
		and descriptor.canopyShape
	then
		local offset, canopySize = descriptor.canopyOffset, descriptor.canopySize
		stagePart(descriptor.name .. "_Canopy", descriptor.canopyShape, {
			descriptor.position[1] + offset[1],
			descriptor.position[2] + offset[2],
			descriptor.position[3] + offset[3],
		}, canopySize, descriptor.canopyColor, descriptor, parent, Enum.Material.Grass)
	end
end

local function apply(_plan: any)
	if active then
		return
	end
	failures = 0

	stageFolder()
	local root = folder
	if root then
		local okParts, parts = pcall(function()
			return (Data :: any).parts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read hill descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stageDescriptor(descriptor, root)
			end
		end
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #created == 0 then
		return
	end
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	folder = nil
	active = false
	publishFailures()
end

LookDevHillDressingR10.apply = apply
LookDevHillDressingR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevHillDressingR10
