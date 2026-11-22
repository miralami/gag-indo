-- LookDevCrops: client applier for the OFF-BY-DEFAULT "crops" look-dev candidate (WORK_QUEUE
-- item 7). It builds an in-world showcase of low-poly growth-stage models for EVERY crop in
-- Config/Crops — 12 crops x 3 stages (bibit/tumbuh/siap) — from the pure-data recipes in
-- src/shared/CropModelCandidates.luau. Everything is removed on disable; no asset IDs, no place
-- save, no change to the shipping crop visuals that FarmService builds.
--
-- The showcase is a small floating grid near the player so the designer can review all 36 models
-- at once regardless of what is planted in the current save.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local CropModelCandidates = require(Shared.CropModelCandidates)
local Crops = require(Shared.Config.Crops)
local Visuals = require(Shared.Config.Visuals)

local LookDevCrops = {}

local CONTAINER = "LookDevCropShowcase"
local COLS = 6
local CELL_X = 5
local CELL_Z = 6
local created: { Instance } = {}
local applied = false

local SHAPE_NAMES = {
	Block = "Block", Cylinder = "Cylinder", Sphere = "Ball", Wedge = "Wedge",
}

local function shapeOf(name: string): any
	local ok, shape = pcall(function()
		return ((Enum :: any).PartType)[SHAPE_NAMES[name] or "Block"]
	end)
	return if ok then shape else nil
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function colorFor(cropId: string, token: string): Color3
	if token == "crop" then
		local crop = Crops.list[cropId]
		if crop then
			return crop.color
		end
	end
	return Color3.fromHex(Visuals.palette[token] or Visuals.palette.tinta)
end

local function buildCell(origin: Vector3, cropId: string, stage: string): Model
	local model = Instance.new("Model")
	model.Name = "LookDevCrop_" .. cropId .. "_" .. stage

	local base = Instance.new("Part")
	base.Name = "Soil"
	base.Shape = Enum.PartType.Block
	base.Size = Vector3.new(3.6, 0.2, 3.6)
	base.CFrame = CFrame.new(origin)
	base.Color = Color3.fromHex(Visuals.palette.tinta_lembut)
	base.Material = Enum.Material.SmoothPlastic
	base.CanCollide = false
	base.Parent = model
	table.insert(created, base)

	for _, detail in CropModelCandidates.partsFor(cropId, stage) do
		local part = Instance.new("Part")
		part.Name = detail.name
		local shape = shapeOf(detail.shape)
		if shape then
			part.Shape = shape
		end
		part.Size = vec(detail.size)
		part.CFrame = CFrame.new(origin) * CFrame.new(vec(detail.offset))
		part.Color = colorFor(cropId, detail.color)
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.Parent = model
		table.insert(created, part)
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 180, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.2, 0)
	billboard.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromHex(Visuals.palette.tinta)
	label.TextColor3 = Color3.fromHex(Visuals.palette.kertas)
	label.TextScaled = true
	label.Text = cropId .. " / " .. stage
	label.Parent = billboard
	billboard.Parent = model
	table.insert(created, billboard)

	table.insert(created, model)
	return model
end

local function originPoint(): Vector3
	local player = Players.LocalPlayer
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local p = if root and root:IsA("BasePart") then root.Position else Vector3.new(0, 4, 28)
	return Vector3.new(p.X - (COLS * CELL_X) / 2, p.Y + 10, p.Z + 14)
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

	local origin = originPoint()
	local index = 0
	for _, cropId in CropModelCandidates.cropIds do
		for _, stage in CropModelCandidates.stages do
			local col = index % COLS
			local row = math.floor(index / COLS)
			local cellOrigin = origin + Vector3.new(col * CELL_X, 0, row * CELL_Z)
			buildCell(cellOrigin, cropId, stage).Parent = container
			index += 1
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

LookDev.register("crops", { apply = apply, restore = restore })

LookDevCrops.apply = apply
LookDevCrops.restore = restore

return LookDevCrops
