-- Greybox: generated stand-in for the real map (v2 PLAN §3.1).
-- It builds the v1 village and emits the same tags/attributes a designer map uses
-- (see World/Map.luau), so the rest of the game never hardcodes layout.
--
-- This module is intentionally dumb: no handlers, no services. Village.bind() wires
-- prompts and NPCs after the world exists.

local Map = require(script.Parent.Map)
local Props = require(script.Parent.Props)
local NpcFactory = require(script.Parent.NpcFactory)

local Greybox = {}

local GROUND_Y = 0.5

local function part(props: { [string]: any }): Part
	return Props.part(props)
end

local function sign(parent: Instance, cframe: CFrame, text: string, size: Vector2?): Part
	local board = part({
		Name = "Sign",
		Size = Vector3.new(9, 3.2, 0.4),
		CFrame = cframe,
		Color = Color3.fromRGB(95, 65, 45),
		Material = Enum.Material.Wood,
	})
	board.Parent = parent
	local label = Props.billboard(board, 0, size or Vector2.new(260, 70), { alwaysOnTop = true, maxDistance = 140 })
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 240, 190)
	return board
end

local function roof(parent: Instance, position: Vector3, size: Vector3, color: Color3, material: Enum.Material?)
	part({
		Name = "Roof",
		Size = size,
		Position = position,
		Color = color,
		Material = material or Enum.Material.Fabric,
	}).Parent = parent
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

	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 3, 5),
		Position = Vector3.new(0, GROUND_Y + 1.5, 0),
		Color = Color3.fromRGB(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = model
	posts(model, {
		Vector3.new(-6.5, GROUND_Y, -2),
		Vector3.new(6.5, GROUND_Y, -2),
		Vector3.new(-6.5, GROUND_Y, 2),
		Vector3.new(6.5, GROUND_Y, 2),
	}, 8, Color3.fromRGB(110, 80, 50))
	roof(model, Vector3.new(0, GROUND_Y + 8, 0), Vector3.new(17, 0.6, 8), Color3.fromRGB(30, 110, 170))
	sign(model, CFrame.new(0, GROUND_Y + 10, 0), "PASAR")

	local prompt = Props.prompt(counter, "Pasar", "Jual hasil panen")
	prompt.Name = "SellPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Pasar)

	model.PrimaryPart = counter
	model.Parent = world
end

local function buildGelap(world: Folder)
	local model = Instance.new("Model")
	model.Name = "TengkulakGelap"

	local counter = part({
		Name = "Counter",
		Size = Vector3.new(10, 2.6, 4),
		Position = Vector3.new(0, GROUND_Y + 1.3, -16),
		Color = Color3.fromRGB(80, 55, 40),
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = model
	posts(model, {
		Vector3.new(-4.5, GROUND_Y, -18),
		Vector3.new(4.5, GROUND_Y, -18),
		Vector3.new(-4.5, GROUND_Y, -14),
		Vector3.new(4.5, GROUND_Y, -14),
	}, 7, Color3.fromRGB(60, 45, 35))
	roof(model, Vector3.new(0, GROUND_Y + 7, -16), Vector3.new(13, 0.6, 7), Color3.fromRGB(120, 35, 35), Enum.Material.Fabric)
	sign(model, CFrame.new(0, GROUND_Y + 9, -16), "TENGKULAK GELAP", Vector2.new(300, 70))

	local prompt = Props.prompt(counter, "Tengkulak Gelap", "Jual (harga gelap)")
	prompt.Name = "SellPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Gelap)

	model.PrimaryPart = counter
	model.Parent = world
end

local function buildPakRtHouse(world: Folder)
	local model = Instance.new("Model")
	model.Name = "RumahPakRT"

	local center = Vector3.new(30, GROUND_Y, 26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(18, 0.6, 14),
		Position = center,
		Color = Color3.fromRGB(160, 130, 90),
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-8.5, 0, -6.5),
		center + Vector3.new(8.5, 0, -6.5),
		center + Vector3.new(-8.5, 0, 6.5),
		center + Vector3.new(8.5, 0, 6.5),
	}, 9, Color3.fromRGB(120, 90, 60))
	roof(model, center + Vector3.new(0, 9.5, 0), Vector3.new(21, 0.8, 17), Color3.fromRGB(160, 70, 40), Enum.Material.Slate)
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
	model.Parent = world
end

local function buildPosPolisi(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PosPolisi"

	local center = Vector3.new(-30, GROUND_Y, 26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(16, 0.6, 12),
		Position = center,
		Color = Color3.fromRGB(180, 180, 185),
		Material = Enum.Material.Concrete,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-7.5, 0, -5.5),
		center + Vector3.new(7.5, 0, -5.5),
		center + Vector3.new(-7.5, 0, 5.5),
		center + Vector3.new(7.5, 0, 5.5),
	}, 9, Color3.fromRGB(70, 80, 110))
	roof(model, center + Vector3.new(0, 9.5, 0), Vector3.new(19, 0.8, 15), Color3.fromRGB(25, 70, 140), Enum.Material.Slate)
	sign(model, CFrame.new(-30, GROUND_Y + 11.5, 20), "POS POLISI", Vector2.new(260, 70))

	local desk = part({
		Name = "Desk",
		Size = Vector3.new(6, 2.2, 3),
		Position = Vector3.new(-30, GROUND_Y + 1.1, 20),
		Color = Color3.fromRGB(70, 85, 120),
		Material = Enum.Material.Metal,
	})
	desk.Parent = model
	local prompt = Props.prompt(desk, "Pos Polisi", "Lapor bukti")
	prompt.Name = "ReportPrompt"
	prompt.MaxActivationDistance = 12
	Map.add(prompt, Map.TAGS.Polisi)

	model.PrimaryPart = floor
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
		Color = Color3.fromRGB(110, 85, 60),
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-5.5, 0, -4.5),
		center + Vector3.new(5.5, 0, -4.5),
		center + Vector3.new(-5.5, 0, 4.5),
		center + Vector3.new(5.5, 0, 4.5),
	}, 8, Color3.fromRGB(95, 70, 50))
	roof(model, center + Vector3.new(0, 8.5, 0), Vector3.new(14, 0.7, 12), Color3.fromRGB(200, 120, 30), Enum.Material.Fabric)
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
	model.Parent = world
end

local function buildWarung(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Warung"

	local center = Vector3.new(30, GROUND_Y, -26)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(14, 0.6, 12),
		Position = center,
		Color = Color3.fromRGB(150, 120, 85),
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model
	posts(model, {
		center + Vector3.new(-6.5, 0, -5.5),
		center + Vector3.new(6.5, 0, -5.5),
		center + Vector3.new(-6.5, 0, 5.5),
		center + Vector3.new(6.5, 0, 5.5),
	}, 8, Color3.fromRGB(110, 85, 60))
	roof(model, center + Vector3.new(0, 8.5, 0), Vector3.new(17, 0.7, 15), Color3.fromRGB(60, 120, 80), Enum.Material.Fabric)
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
			Color = Color3.fromRGB(60, 130, 60),
			Material = Enum.Material.Grass,
			Transparency = 0.05,
		}).Parent = tree
		tree.Parent = world
	end
end

local function buildRoads(world: Folder)
	for _, horizontal in { true, false } do
		part({
			Name = "Road",
			Size = if horizontal then Vector3.new(512, 0.1, 18) else Vector3.new(18, 0.1, 512),
			Position = Vector3.new(0, GROUND_Y + 0.03, 0),
			Color = Color3.fromRGB(120, 115, 105),
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
		Color = Color3.fromRGB(110, 160, 70),
		Material = Enum.Material.Grass,
	})
	ground.Parent = world

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
	scatterTrees(world)

	-- NPCs -----------------------------------------------------------------
	NpcFactory.build({
		name = "Pak RT",
		subtitle = "Ketua RT 01",
		npc = "pakrt",
		position = Vector3.new(30, GROUND_Y, 24),
		shirt = Color3.fromRGB(150, 130, 70),
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
		shirt = Color3.fromRGB(60, 55, 60),
		skin = Color3.fromRGB(170, 125, 90),
		parent = world,
	})
	for _, x in { -26, -34 } do
		NpcFactory.build({
			name = "Polisi Desa",
			npc = "polisi",
			position = Vector3.new(x, GROUND_Y, 23),
			shirt = Color3.fromRGB(40, 70, 120),
			skin = Color3.fromRGB(185, 140, 100),
			cap = Color3.fromRGB(30, 50, 95),
			parent = world,
		})
	end

	return world
end

return Greybox
