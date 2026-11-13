-- Greybox: generated stand-in for the real map (v2 PLAN §3.1).
-- It builds the v1 village and emits the same tags/attributes a designer map uses
-- (see World/Map.luau), so the rest of the game never hardcodes layout.
--
-- This module is intentionally dumb: no handlers, no services. Village.bind() wires
-- prompts and NPCs after the world exists.

local Map = require(script.Parent.Map)
local Props = require(script.Parent.Props)
local NpcFactory = require(script.Parent.NpcFactory)
local Visuals = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config.Visuals)

local Greybox = {}

local GROUND_Y = 0.5
local C = {
	paper = Props.palette("kertas"), grass = Props.palette("padi"),
	clay = Props.palette("genteng"), red = Props.palette("merah"),
	wood = Props.palette("bambu"), gold = Props.palette("kunyit"),
	blue = Props.palette("malam"), shadow = Props.palette("indigo"),
}

local function contour(model: Model, maxDistance: number?)
	local highlight = Instance.new("Highlight")
	highlight.Name = "InkContour"
	highlight.Adornee = model
	highlight.FillTransparency = 1
	highlight.OutlineColor = Props.palette("tinta")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	model:SetAttribute("ContourMaxDistance", maxDistance or 60)
end

local function contourDescendants(model: Model)
	for _, item in model:GetDescendants() do
		if item:IsA("Model") and not item:FindFirstChild("InkContour") then
			contour(item, 48)
		end
	end
end

local function part(props: { [string]: any }): Part
	if props.Material == nil then
		props.Material = Enum.Material.Wood
	end
	return Props.part(props)
end

local DRESSING_PROPS = {
	{ "Sack", Vector3.new(7, GROUND_Y + 0.45, 5), Vector3.new(1.4, 0.9, 1.2), C.wood },
	{ "Galon", Vector3.new(10, GROUND_Y + 0.7, 5), Vector3.new(0.8, 1.4, 0.8), C.blue },
	{ "MotorBody", Vector3.new(-10, GROUND_Y + 0.5, 5), Vector3.new(2.8, 0.7, 1.2), C.red },
	{ "Laundry", Vector3.new(13, GROUND_Y + 1.5, 7), Vector3.new(2, 1.2, 0.2), C.paper },
}

local function dressingKit(): Model
	local kit = Instance.new("Model")
	kit.Name = "DressingKit"
	for _, def in DRESSING_PROPS do
		local shape = if def[1] == "Galon" then Enum.PartType.Cylinder else Enum.PartType.Block
		local material = if def[1] == "Sack" or def[1] == "Laundry" then Enum.Material.Fabric else Enum.Material.Wood
		local p = part({ Name = def[1], Position = def[2], Size = def[3], Shape = shape, Color = def[4], Material = material, CanCollide = false })
		p.Parent = kit
	end
	local motor = kit:FindFirstChild("MotorBody") :: Part
	for _, side in { -1, 1 } do
		local wheel = part({ Name = "MotorWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 0.8, 0.8), Position = motor.Position + Vector3.new(0, -0.3, side * 0.65), Orientation = Vector3.new(0, 0, 90), Color = Props.palette("tinta"), Material = Enum.Material.Rubber })
		wheel.Parent = kit
	end
	return kit
end

local function buildDressing(world: Folder)
	for index, origin in { Vector3.new(0, 0, 0), Vector3.new(30, 0, 30), Vector3.new(-30, 0, 30) } do
		local clone = dressingKit()
		clone.Name = "DressingCluster_" .. index
		for _, item in clone:GetChildren() do
			if item:IsA("BasePart") then item.Position += origin end
		end
		clone.Parent = world
	end
end

local function sign(parent: Instance, cframe: CFrame, text: string, size: Vector2?): Part
	local board = part({
		Name = "Sign",
		Size = Vector3.new(9, 3.2, 0.4),
		CFrame = cframe,
		Color = C.wood,
		Material = Enum.Material.Wood,
	})
	board.Parent = parent
	local label = Props.billboard(board, 0, size or Vector2.new(260, 70), { alwaysOnTop = true, maxDistance = 140 })
	label.Text = text
	label.TextColor3 = C.paper
	return board
end

local function roof(parent: Instance, position: Vector3, size: Vector3, color: Color3, material: Enum.Material?)
	local roofPart = part({
		Name = "Roof",
		Size = size,
		Position = position,
		Color = color,
		Material = material or Enum.Material.Fabric,
	})
	roofPart.Parent = parent
	if color == C.red or color == C.clay or color == C.gold or color == C.blue then
		local slot = if color == C.red then "genteng" elseif color == C.clay then "genteng" elseif color == C.gold then "genteng" else "seng"
		Visuals.applySurface(roofPart, slot, material or Enum.Material.Metal)
	end
end

local function posts(parent: Instance, corners: { Vector3 }, height: number, color: Color3)
	for _, position in corners do
		part({
			Name = "Post",
			Size = Vector3.new(0.7, height, 0.7),
			Position = position + Vector3.new(0, height / 2, 0),
			Color = color,
			Material = Enum.Material.Wood,
		}).Parent = parent
	end
end

local function buildPasar(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Pasar"
	model:SetAttribute("HubAccent", "merah")

	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 3, 5),
		Position = Vector3.new(0, GROUND_Y + 1.5, 0),
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = model
	posts(model, {
		Vector3.new(-6.5, GROUND_Y, -2),
		Vector3.new(6.5, GROUND_Y, -2),
		Vector3.new(-6.5, GROUND_Y, 2),
		Vector3.new(6.5, GROUND_Y, 2),
	}, 8, C.shadow)
	roof(model, Vector3.new(0, GROUND_Y + 8, 0), Vector3.new(17, 0.6, 8), C.red, Enum.Material.Metal)
	sign(model, CFrame.new(0, GROUND_Y + 10, 0), "PASAR")

	local prompt = Props.prompt(counter, "Pasar", "Jual hasil panen")
	prompt.Name = "SellPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Pasar)

	model.PrimaryPart = counter
	contour(model)
	model.Parent = world
end

local function buildGelap(world: Folder)
	local model = Instance.new("Model")
	model.Name = "TengkulakGelap"
	model:SetAttribute("HubAccent", "genteng")

	local counter = part({
		Name = "Counter",
		Size = Vector3.new(10, 2.6, 4),
		Position = Vector3.new(0, GROUND_Y + 1.3, -16),
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = model
	posts(model, {
		Vector3.new(-4.5, GROUND_Y, -18),
		Vector3.new(4.5, GROUND_Y, -18),
		Vector3.new(-4.5, GROUND_Y, -14),
		Vector3.new(4.5, GROUND_Y, -14),
	}, 7, C.shadow)
	roof(model, Vector3.new(0, GROUND_Y + 7, -16), Vector3.new(13, 0.6, 7), C.clay, Enum.Material.Metal)
	sign(model, CFrame.new(0, GROUND_Y + 9, -16), "TENGKULAK GELAP", Vector2.new(300, 70))

	local prompt = Props.prompt(counter, "Tengkulak Gelap", "Jual (harga gelap)")
	prompt.Name = "SellPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Gelap)

	model.PrimaryPart = counter
	contour(model)
	model.Parent = world
end

local function buildPakRtHouse(world: Folder)
	local model = Instance.new("Model")
	model.Name = "RumahPakRT"
	model:SetAttribute("HubAccent", "kunyit")

	local center = Vector3.new(30, GROUND_Y, 26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(18, 0.6, 14),
		Position = center,
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-8.5, 0, -6.5),
		center + Vector3.new(8.5, 0, -6.5),
		center + Vector3.new(-8.5, 0, 6.5),
		center + Vector3.new(8.5, 0, 6.5),
	}, 9, C.shadow)
	roof(model, center + Vector3.new(0, 9.5, 0), Vector3.new(21, 0.8, 17), C.gold, Enum.Material.Slate)
	sign(model, CFrame.new(30, GROUND_Y + 11.5, 19.5), "RUMAH PAK RT", Vector2.new(280, 70))

	local table = part({
		Name = "Table",
		Size = Vector3.new(5, 2.4, 3),
		Position = Vector3.new(30, GROUND_Y + 1.2, 19),
		Color = Color3.fromRGB(110, 80, 55),
		Material = Enum.Material.WoodPlanks,
	})
	table.Parent = model
	local prompt = Props.prompt(table, "Pak RT", "Kasih uang rokok")
	prompt.Name = "BribePrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.PakRT)

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

local function buildPosPolisi(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PosPolisi"
	model:SetAttribute("HubAccent", "malam")

	local center = Vector3.new(-30, GROUND_Y, 26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(16, 0.6, 12),
		Position = center,
		Color = C.blue,
		Material = Enum.Material.Concrete,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-7.5, 0, -5.5),
		center + Vector3.new(7.5, 0, -5.5),
		center + Vector3.new(-7.5, 0, 5.5),
		center + Vector3.new(7.5, 0, 5.5),
	}, 9, C.shadow)
	roof(model, center + Vector3.new(0, 9.5, 0), Vector3.new(19, 0.8, 15), C.blue, Enum.Material.Metal)
	sign(model, CFrame.new(-30, GROUND_Y + 11.5, 20), "POS POLISI", Vector2.new(260, 70))

	local desk = part({
		Name = "Desk",
		Size = Vector3.new(6, 2.2, 3),
		Position = Vector3.new(-30, GROUND_Y + 1.1, 20),
		Color = C.blue,
		Material = Enum.Material.Metal,
	})
	desk.Parent = model
	local prompt = Props.prompt(desk, "Pos Polisi", "Lapor bukti")
	prompt.Name = "ReportPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Polisi)

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

local function buildPosRonda(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PosRonda"

	local center = Vector3.new(-30, GROUND_Y, -26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(12, 0.6, 10),
		Position = center,
		Color = C.shadow,
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-5.5, 0, -4.5),
		center + Vector3.new(5.5, 0, -4.5),
		center + Vector3.new(-5.5, 0, 4.5),
		center + Vector3.new(5.5, 0, 4.5),
	}, 8, C.shadow)
	roof(model, center + Vector3.new(0, 8.5, 0), Vector3.new(14, 0.7, 12), C.gold, Enum.Material.Fabric)
	sign(model, CFrame.new(-30, GROUND_Y + 10, -20.5), "POS RONDA", Vector2.new(240, 70))
	Map.add(floor, Map.TAGS.Ronda)

	-- The cell: three low walls, open on the +Z side so the player can be walked in.
	for _, offset in { Vector3.new(-3.6, 0, 0), Vector3.new(3.6, 0, 0), Vector3.new(0, 0, -3.6) } do
		part({
			Name = "CellWall",
			Size = if offset.X ~= 0 then Vector3.new(0.5, 3.5, 8) else Vector3.new(8, 3.5, 0.5),
			Position = center + offset + Vector3.new(0, 1.75, 0),
			Color = Color3.fromRGB(90, 70, 55),
			Material = Enum.Material.Wood,
		}).Parent = model
	end

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

local function buildWarung(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Warung"
	model:SetAttribute("HubAccent", "genteng")

	local center = Vector3.new(30, GROUND_Y, -26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(14, 0.6, 12),
		Position = center,
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-6.5, 0, -5.5),
		center + Vector3.new(6.5, 0, -5.5),
		center + Vector3.new(-6.5, 0, 5.5),
		center + Vector3.new(6.5, 0, 5.5),
	}, 8, C.shadow)
	roof(model, center + Vector3.new(0, 8.5, 0), Vector3.new(17, 0.7, 15), C.clay, Enum.Material.Metal)
	sign(model, CFrame.new(30, GROUND_Y + 10, -20), "WARUNG", Vector2.new(240, 70))

	local table = part({
		Name = "Table",
		Size = Vector3.new(5, 2.2, 3),
		Position = Vector3.new(30, GROUND_Y + 1.1, -22),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.WoodPlanks,
	})
	table.Parent = model
	for _, x in { -3.2, 3.2 } do
		part({
			Name = "Bench",
			Size = Vector3.new(3, 0.4, 1.2),
			Position = Vector3.new(30 + x, GROUND_Y + 0.9, -22),
			Color = Color3.fromRGB(100, 75, 50),
			Material = Enum.Material.Wood,
		}).Parent = model
	end

	local prompt = Props.prompt(table, "Warung", "Nongkrong")
	prompt.Name = "WarungPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Warung)

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

local function scatterTrees(world: Folder)
	local spots = {
		Vector3.new(14, GROUND_Y, -42),
		Vector3.new(-16, GROUND_Y, -44),
		Vector3.new(46, GROUND_Y, 2),
		Vector3.new(-46, GROUND_Y, -8),
		Vector3.new(4, GROUND_Y, 48),
		Vector3.new(-2, GROUND_Y, -56),
		Vector3.new(52, GROUND_Y, 44),
		Vector3.new(-52, GROUND_Y, 48),
	}
	for i, spot in spots do
		local tree = Instance.new("Model")
		tree.Name = "Tree_" .. i
		part({
			Name = "Trunk",
			Size = Vector3.new(2, 9, 2),
			Position = spot + Vector3.new(0, 4.5, 0),
			Color = Color3.fromRGB(100, 70, 45),
			Material = Enum.Material.Wood,
		}).Parent = tree
		part({
			Name = "Leaves",
			Size = Vector3.new(11, 8, 11),
			Position = spot + Vector3.new(0, 11, 0),
			Color = C.grass,
			Material = Enum.Material.Grass,
			Transparency = 0.05,
		}).Parent = tree
		tree.Parent = world
		contour(tree, 40)
	end
end

local function buildRoads(world: Folder)
	for _, horizontal in { true, false } do
		part({
			Name = "Road",
			Size = if horizontal then Vector3.new(512, 0.1, 18) else Vector3.new(18, 0.1, 512),
			Position = Vector3.new(0, GROUND_Y + 0.03, 0),
			Color = C.shadow,
			Material = Enum.Material.Asphalt,
		}).Parent = world
	end
end

function Greybox.build(): Folder
	-- Replace a previous generated world; never touch a designer map.
	for _, old in Map.all(Map.TAGS.Greybox) do
		old:Destroy()
	end
	local legacy = workspace:FindFirstChild("World")
	if legacy and not Map.isDesignerWorld() then
		legacy:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "World"
	Map.add(world, Map.TAGS.Greybox)
	world.Parent = workspace

	local ground = part({
		Name = "Ground",
		Size = Vector3.new(512, 1, 512),
		Position = Vector3.new(0, 0, 0),
		Color = C.grass,
		Material = Enum.Material.Grass,
	})
	ground.Parent = world
	local waterColor = Props.palette("malam")
	local grassColor = Props.palette("padi")
	workspace.Terrain.WaterColor = waterColor
	workspace.Terrain:SetMaterialColor(Enum.Material.Ground, Props.palette("bambu"))
	workspace.Terrain:SetMaterialColor(Enum.Material.Grass, grassColor)
	workspace.Terrain:FillBlock(CFrame.new(0, -4, 110), Vector3.new(220, 8, 100), Enum.Material.Water)
	for row = 0, 3 do
		workspace.Terrain:FillBlock(CFrame.new(0, -1.5 + row * 1.5, -100 + row * 14), Vector3.new(120 - row * 22, 3, 18), Enum.Material.Ground)
	end

	buildRoads(world)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, GROUND_Y + 0.5, 16)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	Map.add(spawn, Map.TAGS.PlayerSpawn)
	spawn.Parent = world

	buildPasar(world)
	buildGelap(world)
	buildPakRtHouse(world)
	buildPosPolisi(world)
	buildPosRonda(world)
	buildWarung(world)
	buildDressing(world)
	scatterTrees(world)
	contourDescendants(world)

	-- NPCs -----------------------------------------------------------------
	NpcFactory.build({
		name = "Pak RT",
		subtitle = "Ketua RT 01",
		npc = "pakrt",
		position = Vector3.new(30, GROUND_Y, 24),
		shirt = C.gold,
		skin = Color3.fromRGB(200, 155, 110),
		mustache = true,
		peci = true,
		parent = world,
	})
	NpcFactory.build({
		name = "Bang Jago",
		subtitle = "Tengkulak",
		npc = "tengkulak",
		position = Vector3.new(-3, GROUND_Y, -16),
		shirt = C.shadow,
		skin = Color3.fromRGB(170, 125, 90),
		parent = world,
	})
	for _, x in { -26, -34 } do
		NpcFactory.build({
			name = "Polisi Desa",
			npc = "polisi",
			position = Vector3.new(x, GROUND_Y, 23),
			shirt = C.blue,
			skin = Color3.fromRGB(185, 140, 100),
			cap = C.shadow,
			parent = world,
		})
	end

	return world
end

return Greybox
