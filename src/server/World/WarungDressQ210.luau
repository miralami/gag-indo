--!strict
-- Pure data for WORK_QUEUE item 210: DEFAULT-look Warung front dressing.
-- No engine calls, no instances, no asset IDs, no new colours. The two existing MapSpec benches
-- are tagged as seats by Greybox; this recipe adds two low stools, a serving table, a stove and a
-- hanging lantern. Every local coordinate is derived from the warung hub's anchor and benches and
-- sits in front of the table (local z > anchor.lz) and outside all six 6-stud door lanes.

local Data = {}

Data.TAG = "WarungDress"
Data.KIND_ATTR = "WarungDressKind"
Data.MIN_SEATS = 4

-- Existing Props palette names only; Greybox resolves each through Props.palette().
Data.PALETTE_NAMES = { "bambu", "genteng", "kunyit", "merah", "tintaLembut" }

-- Pure: given the warung hub table, return the NEW dressing parts deterministically.
function Data.parts(hub: { [string]: any })
	local benches = hub.benches
	local outerX = math.abs(benches[1]) + 5.1 -- stools sit outboard of the existing benches
	local anchorZ = hub.anchor.lz
	return {
		{
			name = "WarungStoolL",
			kind = "seat",
			lx = -outerX,
			lz = anchorZ + 4.5,
			shape = "Cylinder",
			sx = 2.4,
			sy = 1.2,
			sz = 2.4,
			y = 0.6,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungStoolR",
			kind = "seat",
			lx = outerX,
			lz = anchorZ + 4.5,
			shape = "Cylinder",
			sx = 2.4,
			sy = 1.2,
			sz = 2.4,
			y = 0.6,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungServerTop",
			kind = "table",
			lx = 0,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 6,
			sy = 0.4,
			sz = 2.4,
			y = 2.2,
			colour = "bambu",
			material = "WoodPlanks",
		},
		{
			name = "WarungServerLegL",
			kind = "table",
			lx = -2.4,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 0.4,
			sy = 2.2,
			sz = 2,
			y = 1.1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungServerLegR",
			kind = "table",
			lx = 2.4,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 0.4,
			sy = 2.2,
			sz = 2,
			y = 1.1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungStove",
			kind = "stove",
			lx = -16,
			lz = anchorZ + 7.5,
			shape = "Cylinder",
			sx = 3,
			sy = 2.4,
			sz = 3,
			y = 1.2,
			colour = "genteng",
			material = "Metal",
		},
		{
			name = "WarungStoveChimney",
			kind = "stove",
			lx = -16,
			lz = anchorZ + 7.5,
			shape = "Cylinder",
			sx = 0.7,
			sy = 2.2,
			sz = 0.7,
			y = 3.4,
			colour = "tintaLembut",
			material = "Metal",
		},
		{
			name = "WarungLanternPost",
			kind = "lantern",
			lx = 12,
			lz = anchorZ + 9,
			shape = "Block",
			sx = 0.4,
			sy = 7,
			sz = 0.4,
			y = 3.5,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungLanternArm",
			kind = "lantern",
			lx = 10.5,
			lz = anchorZ + 9,
			shape = "Block",
			sx = 3,
			sy = 0.3,
			sz = 0.3,
			y = 6.8,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungLanternBody",
			kind = "lantern",
			lx = 9,
			lz = anchorZ + 9,
			shape = "Cylinder",
			sx = 1.6,
			sy = 1.6,
			sz = 1.6,
			y = 5.7,
			colour = "kunyit",
			material = "Metal",
		},
		{
			name = "WarungLanternCap",
			kind = "lantern",
			lx = 9,
			lz = anchorZ + 9,
			shape = "Cylinder",
			sx = 1.9,
			sy = 0.2,
			sz = 1.9,
			y = 6.6,
			colour = "merah",
			material = "Metal",
		},
	}
end

-- OVERLAY (item 272) --------------------------------------------------------
-- Additive, default OFF candidate "warung_props_r10". Everything above is the untouched DEFAULT
-- recipe; the functions below are the applier and are reached only from the Studio harness or
-- LookDevReview after the main session wires the candidate id. No engine call runs at load: the
-- optional LookDev registration is pcall-guarded so the pure-data Lune spec can require this module
-- with a fake DataModel (no ReplicatedStorage service) and still read Data.parts().
--
-- ponytail: the Indonesian House Props Kit 89268533487636 is not baked; the designer must bake it
-- into ServerStorage.LookDevAssets before ModelMapWarungPropsR10.MODEL_IDS can point at it. Until
-- then the applier stages live-verified baked substitutes only -- no runtime fetch, no new id.

local OVERLAY_ID = "warung_props_r10"
local overlayData: any? = nil
local overlayRoot: any? = nil
local overlayCreated: { any } = {}
local overlaySaved: { { target: any, key: string, value: any } } = {}
local overlayActive = false

local function overlayService(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	return ok and value or nil
end

local function overlayModule(): any?
	if overlayData then
		return overlayData
	end
	local shared = overlayService("ReplicatedStorage")
	if not shared then
		return nil
	end
	local okFolder, folder = pcall(function()
		return (shared :: any):WaitForChild("Shared")
	end)
	if not okFolder or not folder then
		return nil
	end
	local okData, module = pcall(function()
		return require((folder :: any):WaitForChild("ModelMapWarungPropsR10"))
	end)
	if okData and type(module) == "table" then
		overlayData = module
	end
	return overlayData
end

local function overlaySaveAttribute(target: any, key: string)
	for _, entry in ipairs(overlaySaved) do
		if entry.target == target and entry.key == key then
			return
		end
	end
	local ok, value = pcall(function()
		return target:GetAttribute(key)
	end)
	if ok then
		overlaySaved[#overlaySaved + 1] = { target = target, key = key, value = value }
	end
end

local function overlayTag(part: any, props: any, def: any)
	pcall(function()
		part:SetAttribute(props.tagAttribute, true)
		part:SetAttribute(props.indexAttribute, def.index)
		part:SetAttribute(props.kindAttribute, def.kind)
		part:SetAttribute("LookDevStage", OVERLAY_ID)
		if def.modelId then
			part:SetAttribute(props.modelAttribute, def.modelId)
		end
	end)
end

-- Baked substitute. Component-wise scale around the bake's bounding-box centre is the same method
-- item 271 proved in Studio; GetBoundingBox returns a CFrame whose .Position is the centre.
local function overlayStageModel(def: any, props: any, loader: any, parent: any): boolean
	local okBaked, model = pcall(function()
		return loader.baked(def.modelId)
	end)
	if not okBaked or not model then
		return false
	end
	overlayCreated[#overlayCreated + 1] = model
	pcall(function()
		loader.stripScripts(model)
	end)
	local okBox, centre, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not okBox or not centre or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		return false
	end
	local parts = {}
	local okParts, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not okParts or type(descendants) ~= "table" then
		return false
	end
	for _, part in ipairs(descendants) do
		local isPart = false
		pcall(function()
			isPart = part:IsA("BasePart")
		end)
		if isPart then
			parts[#parts + 1] = part
		end
	end
	if #parts == 0 then
		return false
	end
	local centrePos = centre.Position
	local scale = Vector3.new(def.size[1] / size.X, def.size[2] / size.Y, def.size[3] / size.Z)
	local target = Vector3.new(def.position.x, def.position.y + def.size[2] / 2, def.position.z)
	local okStage = pcall(function()
		for _, part in ipairs(parts) do
			local oldSize = part.Size
			part.Size = Vector3.new(oldSize.X * scale.X, oldSize.Y * scale.Y, oldSize.Z * scale.Z)
			local rel = part.Position - centrePos
			part.CFrame = CFrame.new(target + Vector3.new(rel.X * scale.X, rel.Y * scale.Y, rel.Z * scale.Z))
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = false
			overlayTag(part, props, def)
		end
		model.Parent = parent
	end)
	return okStage
end

local function overlayStagePart(def: any, props: any, parent: any): boolean
	local shape = if def.shape == "Cylinder"
		then Enum.PartType.Cylinder
		elseif def.shape == "Ball" then Enum.PartType.Ball
		else Enum.PartType.Block
	local okPart, part = pcall(function()
		local instance = Instance.new("Part")
		instance.Name = def.name
		instance.Shape = shape
		instance.Size = Vector3.new(def.size[1], def.size[2], def.size[3])
		instance.CFrame = CFrame.new(def.position.x, def.centreY or def.position.y, def.position.z)
		instance.Color = Color3.fromRGB(def.color.r, def.color.g, def.color.b)
		instance.Material = Enum.Material[def.material] or Enum.Material.Plastic
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		return instance
	end)
	if not okPart or not part then
		return false
	end
	overlayCreated[#overlayCreated + 1] = part
	overlayTag(part, props, def)
	pcall(function()
		part.Parent = parent
	end)
	return true
end

function Data.overlayApply()
	if overlayActive then
		return true
	end
	local props = overlayModule()
	local workspace = overlayService("Workspace")
	if not props or not workspace then
		return false
	end
	local okFolder, existing = pcall(function()
		return workspace:FindFirstChild(props.folderName)
	end)
	if not okFolder then
		return false
	end
	if existing then
		overlayRoot = existing
		overlaySaveAttribute(existing, "LookDevStage")
		pcall(function()
			existing:SetAttribute("LookDevStage", OVERLAY_ID)
		end)
	else
		local okNew, folder = pcall(function()
			return Instance.new("Folder")
		end)
		if not okNew or not folder then
			return false
		end
		overlayCreated[#overlayCreated + 1] = folder
		pcall(function()
			folder.Name = props.folderName
			folder:SetAttribute("LookDevStage", OVERLAY_ID)
			folder.Parent = workspace
		end)
		overlayRoot = folder
	end
	local okLoader, loader = pcall(function()
		return require(script.Parent:WaitForChild("LookDevAssetLoader"))
	end)
	if not okLoader or type(loader) ~= "table" then
		return false
	end
	for _, def in ipairs(props.props()) do
		local stager = if def.modelId then overlayStageModel else overlayStagePart
		local dependency = if def.modelId then loader else overlayRoot
		pcall(stager, def, props, dependency, overlayRoot)
	end
	overlayActive = true
	return true
end

function Data.overlayRestore()
	if not overlayActive and #overlayCreated == 0 and #overlaySaved == 0 then
		return true
	end
	local okAll = true
	for index = #overlaySaved, 1, -1 do
		local entry = overlaySaved[index]
		pcall(function()
			entry.target:SetAttribute(entry.key, entry.value)
		end)
		overlaySaved[index] = nil
	end
	for index = #overlayCreated, 1, -1 do
		local instance = overlayCreated[index]
		local ok, why = pcall(function()
			instance:Destroy()
		end)
		if not ok then
			okAll = false
			warn("[WarungDressQ210] overlay restore failed: " .. tostring(why))
		end
		overlayCreated[index] = nil
	end
	overlayRoot = nil
	overlayActive = false
	return okAll
end

Data.overlayId = OVERLAY_ID

-- Optional boot wiring. LookDev.register ignores unknown ids, so this is a no-op until the main
-- session adds "warung_props_r10" to Shared.LookDev.IDS; the harness stages apply/restore directly.
pcall(function()
	local shared = overlayService("ReplicatedStorage")
	if not shared then
		return
	end
	local okFolder, folder = pcall(function()
		return (shared :: any):WaitForChild("Shared")
	end)
	if not okFolder or not folder then
		return
	end
	local okLookDev, lookDev = pcall(function()
		return require((folder :: any):WaitForChild("LookDev"))
	end)
	if okLookDev and type(lookDev) == "table" and type(lookDev.register) == "function" then
		lookDev.register(OVERLAY_ID, { apply = Data.overlayApply, restore = Data.overlayRestore })
	end
end)

return Data
