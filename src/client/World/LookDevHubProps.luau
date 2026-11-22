-- LookDevHubProps: client applier for the OFF-BY-DEFAULT "hubprops" look-dev candidate (WORK_QUEUE
-- item 8). It dresses the four shop/counter hubs (warung, pasar, pos polisi, Pak RT) with small
-- hero-prop detail parts — crates, produce, cups, desk lamp, lantern, sign — from the pure-data
-- recipes in src/shared/HubPropCandidates.luau. Details are parented to each hub's anchor part, so
-- they follow the hub for free. Everything is destroyed on disable; no asset IDs, no place save,
-- no change to the shipping greybox props.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local HubPropCandidates = require(Shared.HubPropCandidates)
local Visuals = require(Shared.Config.Visuals)

local LookDevHubProps = {}

local CONTAINER = "LookDevHubPropDetails"
local created: { Instance } = {}
local applied = false

local SHAPE_NAMES = { Block = "Block", Cylinder = "Cylinder", Sphere = "Ball", Wedge = "Wedge" }
local MATERIAL_NAMES = {
	WoodPlanks = "WoodPlanks", SmoothPlastic = "SmoothPlastic", Metal = "Metal",
	Fabric = "Fabric", Wood = "Wood",
}

local function shapeOf(name: string): any
	local ok, shape = pcall(function()
		return ((Enum :: any).PartType)[SHAPE_NAMES[name] or "Block"]
	end)
	return if ok then shape else nil
end

local function materialOf(name: string): any
	local ok, material = pcall(function()
		return ((Enum :: any).Material)[MATERIAL_NAMES[name] or "SmoothPlastic"]
	end)
	return if ok then material else nil
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function colorFor(token: string): Color3
	return Color3.fromHex(Visuals.palette[token] or Visuals.palette.tinta)
end

-- Find a hub model by name anywhere under the workspace (hubs are nested under workspace.World).
local function findHubModel(modelName: string): Instance?
	local direct = Workspace:FindFirstChild(modelName)
	if direct then
		return direct
	end
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("Model") and inst.Name == modelName then
			return inst
		end
	end
	return nil
end

local function apply(_plan: any)
	if applied then
		return
	end
	created = {}
	local container = Workspace:FindFirstChild(CONTAINER)
	if container then
		container:Destroy()
	end
	container = Instance.new("Folder")
	container.Name = CONTAINER
	container.Parent = Workspace
	table.insert(created, container)

	for _, hubKey in HubPropCandidates.hubOrder do
		local recipe = HubPropCandidates.hubs[hubKey]
		local hubModel = recipe and findHubModel(recipe.model)
		local anchor = hubModel and hubModel:FindFirstChild(recipe.anchor)
		if anchor and anchor:IsA("BasePart") then
			for _, detail in HubPropCandidates.partsFor(hubKey) do
				local part = Instance.new("Part")
				part.Name = "LookDevProp_" .. hubKey .. "_" .. detail.name
				local shape = shapeOf(detail.shape)
				if shape then
					part.Shape = shape
				end
				local material = materialOf(detail.material)
				if material then
					part.Material = material
				end
				part.Size = vec(detail.size)
				part.CFrame = anchor.CFrame * CFrame.new(vec(detail.offset))
				part.Color = colorFor(detail.color)
				part.CanCollide = false
				part.Parent = container
				table.insert(created, part)
			end
		end
	end
	applied = true
end

local function restore()
	if not applied then
		return
	end
	for _, inst in created do
		if inst.Parent then
			pcall(function()
				inst:Destroy()
			end)
		end
	end
	created = {}
	applied = false
end

LookDev.register("hubprops", { apply = apply, restore = restore })

LookDevHubProps.apply = apply
LookDevHubProps.restore = restore

return LookDevHubProps
