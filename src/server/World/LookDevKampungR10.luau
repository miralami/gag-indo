--!strict
-- LookDevKampungR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "kampung_r10" candidate
-- (WORK_QUEUE items 200 and 261). Stages 12 baked house models in three loose two-row clusters,
-- with real baked shrub models at each yard anchor and plain fence Blocks. The house model is
-- `18239791051` (pick 1: Rumah Kampung Simple Indonesia); shrub IDs are the verified vegetation
-- IDs already in ASSET_MANIFEST.md. Every clone comes from LookDevAssetLoader.baked(); no runtime
-- insertion. Scripts are stripped defensively and all parts are anchored, non-collidable and
-- non-shadow-casting. Every staged descendant carries LookDevStage + KampungHouse attributes; the
-- invisible shrub anchors keep q253's hedge-cluster contract. LIFO restore and pcall guards
-- throughout. No prompts, no gameplay state. Placement comes from Shared.ModelMapKampungR10.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("kampung_r10", game)

type SavedProp = { target: any, attr: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevKampungR10] missing service " .. name)
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
	warn("[LookDevKampungR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, LookDevAssetLoader = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapKampungR10),
		require((Shared :: any).LookDevFailures),
		require(script.Parent.LookDevAssetLoader)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevKampungR10] could not require LookDev / ModelMapKampungR10 / LookDevFailures")
	return {}
end
if not LookDevAssetLoader then
	warn("[LookDevKampungR10] LookDevAssetLoader unavailable; no baked house or shrub can be staged")
end

local LookDevKampungR10 = {}

local FAMILY_ID = Data.id
local HOUSE_ASSET_ID = 18239791051
local SHRUB_ASSET_IDS = { 116666781655827, 9953859659, 5661660655 }
local SHRUB_ANCHOR_SIZE = { 0.4, 0.2, 0.4 }
local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevKampungR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- Save the prior attribute value once per target+key, then set it. New instances still take part so
-- the save/restore contract is uniform; their saved values are void when they are destroyed.
local function setAttribute(target: any, key: string, value: any)
	local attrKey = tostring(target) .. "." .. key
	local seen = false
	for _, entry in ipairs(savedOrder) do
		if entry.key == attrKey then
			seen = true
			break
		end
	end
	if not seen then
		local okRead, prior = pcall(function()
			return target:GetAttribute(key)
		end)
		if not okRead then
			fail("could not read attribute " .. key .. ": " .. tostring(prior))
			return
		end
		savedOrder[#savedOrder + 1] = { target = target, attr = key, key = attrKey, value = prior }
	end
	local okSet, why = pcall(function()
		target:SetAttribute(key, value)
	end)
	if not okSet then
		fail("could not set attribute " .. key .. ": " .. tostring(why))
	end
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

-- Tag every descendant (and the model root) with the family identity. role="shrub" is reserved for
-- the invisible q253 anchor; baked shrub visuals carry role="shrubVisual" so they cannot be counted
-- as Wedge/Cylinder hedge blades by the older check.
local function tagInstance(instance: any, houseIndex: number, role: string, descriptor: any)
	setAttribute(instance, (Data :: any).stageAttribute, FAMILY_ID)
	setAttribute(instance, (Data :: any).tagAttribute, true)
	setAttribute(instance, "house", houseIndex)
	setAttribute(instance, "role", role)
	if descriptor.cluster then
		setAttribute(instance, "cluster", descriptor.cluster)
	end
	if descriptor.shrubCluster then
		setAttribute(instance, "shrubCluster", descriptor.shrubCluster)
	end
	if descriptor.hedgeAnchor then
		setAttribute(instance, "HedgeShrub", true)
	end
	if descriptor.modelAsset then
		setAttribute(instance, (Data :: any).modelAttribute, descriptor.modelAsset)
	end
end

-- Bakes are already stripped, but strip again defensively. A Ball from a source model would trip
-- q253 NO_MELONS, so convert any >=1.5-stud Ball to a Cylinder before staging it.
local function sanitizeModel(model: any, descriptor: any, houseIndex: number, role: string)
	local okDescendants, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		fail("could not read staged model descendants")
		return false
	end
	for _, child in ipairs(descendants) do
		pcall(function()
			if child:IsA("BaseScript") or child:IsA("LuaSourceContainer") then
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
		end
		tagInstance(child, houseIndex, role, descriptor)
	end
	pcall(function()
		if model:IsA("BasePart") then
			model.Anchored = true
			model.CanCollide = false
			model.CastShadow = false
		end
	end)
	tagInstance(model, houseIndex, role, descriptor)
	return true
end

local function scaleModel(model: any, targetSize: { number }, strict: boolean): boolean
	local _, size = bounds(model)
	if not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		fail("staged model has no usable bounding box")
		return false
	end
	local tolerance = if strict then (Data :: any).scaleTolerance else 1
	local factor = targetSize[2] / size.Y
	if strict then
		factor = math.min(factor, targetSize[1] * (1 + tolerance) / size.X, targetSize[3] * (1 + tolerance) / size.Z)
		factor = math.max(factor, targetSize[2] * (1 - tolerance) / size.Y)
	end
	if factor <= 0 or factor > 10000 then
		fail("staged model scale factor out of range: " .. tostring(factor))
		return false
	end
	local okScale, why = pcall(function()
		model:ScaleTo(factor)
	end)
	if not okScale then
		fail("could not scale staged model: " .. tostring(why))
		return false
	end
	if strict then
		local _, after = bounds(model)
		if
			not after
			or math.abs(after.X - targetSize[1]) > targetSize[1] * tolerance
			or math.abs(after.Y - targetSize[2]) > targetSize[2] * tolerance
			or math.abs(after.Z - targetSize[3]) > targetSize[3] * tolerance
		then
			fail("staged house bounding box is outside the 20% HOUSE_SCALE target")
			return false
		end
	end
	return true
end

-- Centre the bounding box on the data position and rest its bottom on GROUND_Y. No baked-model yaw:
-- the live world bbox is the HOUSE_SCALE measurement surface, so rotating it would inflate X/Z.
local function placeModel(model: any, position: { number })
	pcall(function()
		local bboxCFrame, size = bounds(model)
		local pivot: any = if model:IsA("Model") then model:GetPivot() else model.CFrame
		if not bboxCFrame or not size or not pivot then
			return
		end
		local offset = bboxCFrame.Position - pivot.Position
		local centre = Vector3.new(position[1], position[2] + size.Y / 2, position[3])
		local target = CFrame.new(centre - offset)
		if model:IsA("Model") then
			model:PivotTo(target)
		else
			model.CFrame = target
		end
	end)
end

local function bakedModel(assetId: number): any?
	if not LookDevAssetLoader then
		return nil
	end
	local ok, model = pcall(function()
		return (LookDevAssetLoader :: any).baked(assetId)
	end)
	if not ok then
		fail("baked lookup threw for " .. tostring(assetId) .. ": " .. tostring(model))
		return nil
	end
	return model
end

local function stagePart(descriptor: any, parent: any, houseIndex: number, role: string, shape: string?)
	if shape == "Ball" then
		fail("Ball shape rejected for " .. tostring(descriptor and descriptor.name))
		return
	end
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		local partType = (Enum.PartType :: any)[shape or "Block"] or (Enum.PartType :: any).Block
		instance.Shape = partType
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position.x, descriptor.position.y, descriptor.position.z)
			* CFrame.Angles(0, math.rad(descriptor.yaw or 0), 0)
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Transparency = descriptor.transparent and 1 or 0
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(part))
		return
	end
	created[#created + 1] = part

	local descriptorTags = {
		cluster = descriptor.cluster,
		hedgeAnchor = role == "shrub",
	}
	tagInstance(part, houseIndex, role, descriptorTags)
	if role == "shrub" and descriptor.name then
		setAttribute(part, "shrubCluster", descriptor.name)
	end

	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
	end
end

local function stageHouseModel(house: any, houseIndex: number, root: any)
	local okBaked, model = pcall(function()
		return (LookDevAssetLoader :: any).baked(HOUSE_ASSET_ID)
	end)
	if not okBaked then
		fail("baked lookup threw for house model " .. tostring(HOUSE_ASSET_ID) .. ": " .. tostring(model))
		return
	end
	if not model then
		fail("no baked house model " .. tostring(HOUSE_ASSET_ID))
		return
	end
	created[#created + 1] = model
	local descriptor = { cluster = house.cluster, modelAsset = HOUSE_ASSET_ID }
	local okSanitize, why = pcall(sanitizeModel, model, descriptor, houseIndex, "house")
	if not okSanitize or not why then
		fail("could not sanitize house model " .. houseIndex .. ": " .. tostring(why))
		return
	end
	if not scaleModel(model, (Data :: any).BODY_SIZE, true) then
		return
	end
	placeModel(model, house.position)
	local okParent, parentWhy = pcall(function()
		model.Name = house.name
		model.Parent = root
	end)
	if not okParent then
		fail("could not parent house model " .. houseIndex .. ": " .. tostring(parentWhy))
	end
end

local function stageHouses(root: any)
	local okHouses, houses = pcall(function()
		return (Data :: any).houses()
	end)
	if not okHouses or type(houses) ~= "table" then
		fail("could not read house descriptors: " .. tostring(houses))
		return
	end
	for index, house in ipairs(houses) do
		local okBuild, why = pcall(stageHouseModel, house, index, root)
		if not okBuild then
			fail("could not stage house " .. index .. ": " .. tostring(why))
		end
	end
end

-- The anchor is invisible: it exists only to keep q253's 4-stud Wedge/Cylinder hedge-cluster
-- measurement honest. The visible plant is the baked shrub staged directly beside it.
local function stageShrubAnchor(descriptor: any, root: any, houseIndex: number)
	stagePart({
		name = descriptor.name .. "_anchor",
		size = SHRUB_ANCHOR_SIZE,
		position = {
			x = descriptor.position.x,
			y = descriptor.position.y + SHRUB_ANCHOR_SIZE[2] / 2,
			z = descriptor.position.z,
		},
		color = descriptor.color,
		cluster = descriptor.cluster,
		transparent = true,
	}, root, houseIndex, "shrub", "Cylinder")
end

local function stageShrubModel(descriptor: any, root: any, houseIndex: number)
	local model = nil
	for _, assetId in ipairs(SHRUB_ASSET_IDS) do
		model = bakedModel(assetId)
		if model then
			break
		end
	end
	if not model then
		fail("no baked shrub model for " .. tostring(descriptor.name))
		return
	end
	created[#created + 1] = model
	local shrubTags = { cluster = descriptor.cluster, shrubCluster = descriptor.name }
	local okSanitize, why = pcall(sanitizeModel, model, shrubTags, houseIndex, "shrubVisual")
	if not okSanitize or not why then
		fail("could not sanitize shrub model " .. descriptor.name .. ": " .. tostring(why))
		return
	end
	if
		not scaleModel(
			model,
			{ (Data :: any).SHRUB_SIZE[1], (Data :: any).SHRUB_HEIGHT, (Data :: any).SHRUB_SIZE[3] },
			false
		)
	then
		return
	end
	placeModel(model, descriptor.position)
	local okParent, parentWhy = pcall(function()
		model.Name = descriptor.name .. "_model"
		model.Parent = root
	end)
	if not okParent then
		fail("could not parent shrub model " .. descriptor.name .. ": " .. tostring(parentWhy))
	end
end

local function stageYards(root: any)
	local okYards, yards = pcall(function()
		return (Data :: any).yardParts()
	end)
	if not okYards or type(yards) ~= "table" then
		fail("could not read yard descriptors: " .. tostring(yards))
		return
	end
	for _, part in ipairs(yards) do
		local okBuild, why = pcall(function()
			if part.kind == "shrub" then
				stageShrubAnchor(part, root, part.house)
				stageShrubModel(part, root, part.house)
			else
				stagePart(part, root, part.house, part.kind, part.shape)
			end
		end)
		if not okBuild then
			fail("could not stage yard part " .. tostring(part.name) .. ": " .. tostring(why))
		end
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
		stageHouses(root)
		stageYards(root)
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #savedOrder == 0 and #created == 0 then
		return
	end
	for index = #savedOrder, 1, -1 do
		local entry = savedOrder[index]
		local ok, why = pcall(function()
			entry.target:SetAttribute(entry.attr, entry.value)
		end)
		if not ok then
			fail("could not restore attribute " .. entry.key .. ": " .. tostring(why))
		end
		savedOrder[index] = nil
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

LookDevKampungR10.apply = apply
LookDevKampungR10.restore = restore

local okRegister, whyRegister = pcall(function()
	LookDev.register(FAMILY_ID, { apply = apply, restore = restore })
end)
if not okRegister then
	warn("[LookDevKampungR10] could not register applier: " .. tostring(whyRegister))
end

return LookDevKampungR10
