-- Greybox: generated stand-in for the real map (v2 PLAN §3.1).
-- It builds the v1 village and emits the same tags/attributes a designer map uses
-- (see World/Map.luau), so the rest of the game never hardcodes layout.
--
-- This module is intentionally dumb: no handlers, no services. Village.bind() wires
-- prompts and NPCs after the world exists.

local Map = require(script.Parent.Map)
local Props = require(script.Parent.Props)
local NpcFactory = require(script.Parent.NpcFactory)
local Decor = require(script.Parent.Decor)
local Ground = require(script.Parent.Ground)
local Flora = require(script.Parent.Flora)
local Details = require(script.Parent.Details)
local Landscape = require(script.Parent.Landscape)
local Visuals = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config.Visuals)

local Greybox = {}

-- The top of World.Ground, plots, spawn and every hub foundation. Terrain tops out on this same
-- plane, so the grass reads flush with the walkable ground instead of burying it.
local GROUND_Y = Ground.Y
-- Roblox terrain voxels are 4 studs. Measured in Studio (2026-11-15): a FillBlock's visible top
-- face lands on regionTop + TERRAIN_VOXEL / 2, i.e. half a voxel ABOVE the requested region, not
-- snapped up to the next whole voxel. So a 4-stud block centred on GROUND_Y - TERRAIN_VOXEL has a
-- region top of GROUND_Y - TERRAIN_VOXEL / 2 and a face exactly on GROUND_Y.
local TERRAIN_VOXEL = 4
local TERRAIN_BASE_Y = GROUND_Y - TERRAIN_VOXEL
local C = {
	paper = Props.palette("kertas"), grass = Props.palette("padi"),
	clay = Props.palette("genteng"), red = Props.palette("merah"),
	wood = Props.palette("bambu"), gold = Props.palette("kunyit"),
	blue = Props.palette("malam"), shadow = Props.palette("indigo"),
}

-- Each canopy ball gets a small deterministic brightness shift: 0 to 8 percent toward paper
-- (lighter) or shadow (cooler). Both ends are palette colours.
local function tint(base: Color3, r: number): Color3
	if r < 0.5 then
		return base:Lerp(C.paper, r * 0.16)
	end
	return base:Lerp(C.shadow, (r - 0.5) * 0.16)
end

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

-- One readable face of a sign: the name is painted on the board itself, so it reads as part of the
-- building and never floats or stacks with another sign's label.
local SIGN_PIXELS_PER_STUD = 50

local function signFace(board: Part, name: string, face: Enum.NormalId, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = SIGN_PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.TextColor3 = C.paper
	label.TextStrokeColor3 = Props.palette("tinta")
	label.TextStrokeTransparency = 0
	label.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 60
	limit.Parent = label
end

-- The board carries its name on both faces (readable from either side). `_size` is unused now that
-- the text is on the board; it stays in the signature so existing callers keep working.
local function sign(parent: Instance, cframe: CFrame, text: string, _size: Vector2?): Part
	local board = part({
		Name = "Sign",
		Size = Vector3.new(9, 3.2, 0.4),
		CFrame = cframe,
		Color = C.wood,
		Material = Enum.Material.Wood,
	})
	board.Parent = parent
	signFace(board, "SignFront", Enum.NormalId.Front, text)
	signFace(board, "SignBack", Enum.NormalId.Back, text)
	return board
end

-- Hub kit -------------------------------------------------------------------
-- Each hub is a building, not a slab: a raised stone plinth, real walls where the front stays
-- open for its prompt, a pitched roof (two tilted slabs and a ridge beam) that reads from 40
-- studs, and one palette accent. Every prompt keeps a clear walkway from the open side.
local STONE = Props.palette("tintaLembut")
local PLINTH_HEIGHT = 0.8
local PLINTH_TOP = GROUND_Y + PLINTH_HEIGHT
local ROOF_THICK = 0.6

local function block(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = part({ Name = name, Position = position, Size = size, Color = color, Material = material })
	p.Parent = parent
	return p
end

-- Decorative trim, thinner than a stud: it never blocks a player, a click or a shadow.
local function trim(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = part({
		Name = name,
		Position = position,
		Size = size,
		Color = color,
		Material = material,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	})
	p.Parent = parent
	return p
end

-- A raised stone base the building stands on. `centre` is the hub centre at ground level.
local function plinth(parent: Instance, name: string, centre: Vector3, size: Vector2, color: Color3, material: Enum.Material): Part
	return block(parent, name, Vector3.new(centre.X, GROUND_Y + PLINTH_HEIGHT / 2, centre.Z), Vector3.new(size.X, PLINTH_HEIGHT, size.Y), color, material)
end

-- Pitched roof running along X. `ridge` is the peak on the centre line; `halfDepth` is the eave
-- reach from the ridge along Z (overhang included); `rise` is the drop from ridge to eave.
-- Two tilted slabs meet at the ridge, with a ridge beam on top.
local function roof(parent: Instance, ridge: Vector3, length: number, halfDepth: number, rise: number, color: Color3, material: Enum.Material, ridgeColor: Color3, slot: string?)
	local angle = math.atan2(rise, halfDepth)
	local slope = math.sqrt(halfDepth * halfDepth + rise * rise)
	for _, side in { -1, 1 } do
		local centre = Vector3.new(
			ridge.X,
			ridge.Y - rise / 2 + math.cos(angle) * ROOF_THICK / 2,
			ridge.Z + side * (halfDepth / 2 + math.sin(angle) * ROOF_THICK / 2)
		)
		local slab = part({
			Name = "Roof",
			Size = Vector3.new(length, ROOF_THICK, slope),
			CFrame = CFrame.new(centre) * CFrame.Angles(side * angle, 0, 0),
			Color = color,
			Material = material,
		})
		slab.Parent = parent
		if slot then
			Visuals.applySurface(slab, slot, material)
		end
	end
	trim(parent, "RoofRidge", ridge + Vector3.new(0, ROOF_THICK / 2 + 0.25, 0), Vector3.new(length + 0.4, 0.5, 0.5), ridgeColor, Enum.Material.Wood)
end

-- Posts stand from the plinth up to `top`: the roof underside they hold up at their own depth.
local function posts(parent: Instance, corners: { Vector3 }, top: number, color: Color3)
	local height = top - GROUND_Y
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

-- Headroom. Every part a player can walk under at a hub (roof eave, awning, trim, spanduk) has its
-- underside on EAVE, which Decor keeps at least 9.5 studs above GROUND_Y. A roof is built from that
-- eave line up: its ridge sits `rise` above it, and the underside falls from the ridge to the eave.
local HUB_ROOFS = Decor.HUB_ROOFS
local EAVE = Decor.EAVE_UNDERSIDE
local SPANDUK_HEIGHT = 1
local AWNING_THICK = 0.5
local SIGN_HALF_HEIGHT = 1.6 -- sign() builds a 3.2 stud board

local function ridgeOf(roof: { rise: number, halfDepth: number }): number
	return EAVE + roof.rise
end

-- Roof underside `depth` studs in from its ridge line.
local function under(roof: { rise: number, halfDepth: number }, depth: number): number
	return Decor.undersideAt(roof, depth)
end

-- A wall from the plinth top up to `top` (the roof underside it meets), centred on x and z.
local function wall(parent: Instance, name: string, x: number, z: number, sizeX: number, sizeZ: number, top: number, color: Color3, material: Enum.Material): Part
	return block(parent, name, Vector3.new(x, (PLINTH_TOP + top) / 2, z), Vector3.new(sizeX, top - PLINTH_TOP, sizeZ), color, material)
end

local function buildPasar(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Pasar"
	model:SetAttribute("HubAccent", "merah")

	-- Open-front stall: plinth, a plank back wall, posts, and a tent roof with merah spanduk on the eaves.
	local pasar = HUB_ROOFS.pasar
	plinth(model, "Plinth", Vector3.new(0, GROUND_Y, 0), Vector2.new(16, 10), STONE, Enum.Material.Slate)
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
	}, under(pasar, 2), C.shadow)
	wall(model, "BackWall", 0, -4.25, 14, 0.5, under(pasar, 4.25), C.wood, Enum.Material.WoodPlanks)
	roof(model, Vector3.new(0, ridgeOf(pasar), 0), 18, pasar.halfDepth, pasar.rise, C.shadow, Enum.Material.Metal, C.wood)
	for _, z in { -5.8, 5.8 } do
		trim(model, "Spanduk", Vector3.new(0, EAVE + SPANDUK_HEIGHT / 2, z), Vector3.new(18.4, SPANDUK_HEIGHT, 0.3), C.red, Enum.Material.Fabric)
	end
	-- Front sign rests on top of the front spanduk, so it hangs from nothing and intersects nothing.
	sign(model, CFrame.new(0, EAVE + SPANDUK_HEIGHT + SIGN_HALF_HEIGHT, 6.1), "PASAR")

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

	-- Dark back-alley stall: tinta-lembut planks on three sides, open to the front, with a kunyit lantern door.
	local gelap = HUB_ROOFS.gelap
	local dark = Props.palette("tintaLembut")
	plinth(model, "Plinth", Vector3.new(0, GROUND_Y, -16), Vector2.new(11, 8), STONE, Enum.Material.Slate)
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
	}, under(gelap, 2), C.shadow)
	wall(model, "BackWall", 0, -19.5, 11, 0.5, under(gelap, 3.5), dark, Enum.Material.WoodPlanks)
	for _, x in { -5.25, 5.25 } do
		wall(model, "SideWall", x, -17.25, 0.5, 4.5, under(gelap, 3.5), dark, Enum.Material.WoodPlanks)
	end
	trim(model, "LanternDoor", Vector3.new(-5.6, 3.3, -17.25), Vector3.new(0.2, 4, 1.8), C.gold, Enum.Material.Wood)
	roof(model, Vector3.new(0, ridgeOf(gelap), -16), 13, gelap.halfDepth, gelap.rise, C.clay, Enum.Material.Slate, Props.palette("tinta"), "genteng")
	-- Sign hangs from the road-side eave (+Z), its bottom on the eave line.
	sign(model, CFrame.new(0, EAVE + SIGN_HALF_HEIGHT, -10.3), "TENGKULAK GELAP", Vector2.new(300, 70))

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

	-- House with a genteng roof and kunyit trim: plank back and side walls, open porch to the front.
	local pakRt = HUB_ROOFS.pakRt
	local center = Vector3.new(30, GROUND_Y, 26)
	local floor = plinth(model, "Floor", center, Vector2.new(18, 14), STONE, Enum.Material.Slate)
	posts(model, {
		center + Vector3.new(-8.5, 0, -6.5),
		center + Vector3.new(8.5, 0, -6.5),
		center + Vector3.new(-8.5, 0, 6.5),
		center + Vector3.new(8.5, 0, 6.5),
	}, under(pakRt, 6.5), C.shadow)
	wall(model, "BackWall", 30, 32.5, 18, 0.5, under(pakRt, 6.5), C.wood, Enum.Material.WoodPlanks)
	for _, x in { 21.5, 38.5 } do
		wall(model, "SideWall", x, 28, 0.5, 10, under(pakRt, 7), C.wood, Enum.Material.WoodPlanks)
	end
	roof(model, Vector3.new(30, ridgeOf(pakRt), 26), 21, pakRt.halfDepth, pakRt.rise, C.clay, Enum.Material.Slate, C.gold, "genteng")
	for _, z in { 18, 34 } do
		trim(model, "KunyitTrim", Vector3.new(30, EAVE + 0.25, z), Vector3.new(21.4, 0.5, 0.5), C.gold, Enum.Material.Metal)
	end
	-- Sign rests on the road-side KunyitTrim fascia (z 18), so it hangs from the eave, not over the porch.
	sign(model, CFrame.new(30, EAVE + 0.5 + SIGN_HALF_HEIGHT, 17.8), "RUMAH PAK RT", Vector2.new(280, 70))

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

	-- Police post in malam: concrete plinth, malam walls and trim, indigo roof, open porch to the front.
	local posPolisi = HUB_ROOFS.posPolisi
	local center = Vector3.new(-30, GROUND_Y, 26)
	local floor = plinth(model, "Floor", center, Vector2.new(16, 12), C.blue, Enum.Material.Concrete)
	posts(model, {
		center + Vector3.new(-7.5, 0, -5.5),
		center + Vector3.new(7.5, 0, -5.5),
		center + Vector3.new(-7.5, 0, 5.5),
		center + Vector3.new(7.5, 0, 5.5),
	}, under(posPolisi, 5.5), C.shadow)
	wall(model, "BackWall", -30, 31.5, 16, 0.5, under(posPolisi, 5.5), C.blue, Enum.Material.WoodPlanks)
	for _, x in { -37.5, -22.5 } do
		wall(model, "SideWall", x, 28, 0.5, 8, under(posPolisi, 6), C.blue, Enum.Material.WoodPlanks)
	end
	roof(model, Vector3.new(-30, ridgeOf(posPolisi), 26), 18, posPolisi.halfDepth, posPolisi.rise, C.shadow, Enum.Material.Metal, C.blue)
	for _, z in { 18.5, 33.5 } do
		trim(model, "MalamTrim", Vector3.new(-30, EAVE + 0.25, z), Vector3.new(18.4, 0.5, 0.5), C.blue, Enum.Material.Metal)
	end
	-- Sign rests on the road-side MalamTrim fascia (z 18.5), so it hangs from the eave, not over the porch.
	sign(model, CFrame.new(-30, EAVE + 0.5 + SIGN_HALF_HEIGHT, 18.3), "POS POLISI", Vector2.new(260, 70))

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

-- The watchtower stands beside the hut, on the ground at (-20, -30): clear of the hut roof, which
-- covers x -37..-23. Its legs run from the ground up to TOWER_TOP, where the deck sits.
local TOWER_TOP = 11.6

local function buildPosRonda(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PosRonda"
	model:SetAttribute("HubAccent", "bambu")

	-- Bamboo hut on a stone plinth with a thatch roof, and a small watchtower beside it.
	local posRonda = HUB_ROOFS.posRonda
	local center = Vector3.new(-30, GROUND_Y, -26)
	plinth(model, "Plinth", center, Vector2.new(12.4, 10.4), STONE, Enum.Material.Slate)
	local floor = block(model, "Floor", Vector3.new(center.X, PLINTH_TOP + 0.3, center.Z), Vector3.new(12, 0.6, 10), C.wood, Enum.Material.WoodPlanks)
	posts(model, {
		center + Vector3.new(-5.5, 0, -4.5),
		center + Vector3.new(5.5, 0, -4.5),
		center + Vector3.new(-5.5, 0, 4.5),
		center + Vector3.new(5.5, 0, 4.5),
	}, under(posRonda, 4.5), C.shadow)
	roof(model, Vector3.new(-30, ridgeOf(posRonda), -26), 14, posRonda.halfDepth, posRonda.rise, Props.palette("padi"), Enum.Material.Grass, C.wood)
	-- Sign hangs from the road-side eave (z -20), its bottom on the eave line.
	sign(model, CFrame.new(-30, EAVE + SIGN_HALF_HEIGHT, -19.8), "POS RONDA", Vector2.new(240, 70))
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

	-- Watchtower beside the hut: four bamboo legs from the ground, a deck and a small pitched roof.
	local tower = Vector3.new(-20, 0, -30)
	for _, dx in { -1.2, 1.2 } do
		for _, dz in { -1.2, 1.2 } do
			block(model, "TowerLeg", Vector3.new(tower.X + dx, (GROUND_Y + TOWER_TOP) / 2, tower.Z + dz), Vector3.new(0.6, TOWER_TOP - GROUND_Y, 0.6), C.wood, Enum.Material.Wood)
		end
	end
	block(model, "TowerDeck", Vector3.new(tower.X, TOWER_TOP + 0.2, tower.Z), Vector3.new(3.6, 0.4, 3.6), C.wood, Enum.Material.WoodPlanks)
	roof(model, Vector3.new(tower.X, 13.6, tower.Z), 3.6, 2.2, 1.6, Props.palette("padi"), Enum.Material.Grass, C.wood)

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

local function buildWarung(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Warung"
	model:SetAttribute("HubAccent", "genteng")

	-- Warung: genteng roof with a flat seng awning over the front bench, open to the front.
	local warung = HUB_ROOFS.warung
	local center = Vector3.new(30, GROUND_Y, -26)
	local floor = plinth(model, "Floor", center, Vector2.new(14, 12), STONE, Enum.Material.Slate)
	posts(model, {
		center + Vector3.new(-6.5, 0, -5.5),
		center + Vector3.new(6.5, 0, -5.5),
		center + Vector3.new(-6.5, 0, 5.5),
		center + Vector3.new(6.5, 0, 5.5),
	}, under(warung, 5.5), C.shadow)
	wall(model, "BackWall", 30, -31.5, 14, 0.5, under(warung, 5.5), C.wood, Enum.Material.WoodPlanks)
	for _, x in { 23.5, 36.5 } do
		wall(model, "SideWall", x, -28.75, 0.5, 5.5, under(warung, 5.5), C.wood, Enum.Material.WoodPlanks)
	end
	roof(model, Vector3.new(30, ridgeOf(warung), -26), 15, warung.halfDepth, warung.rise, C.clay, Enum.Material.Slate, Props.palette("tinta"), "genteng")

	-- Flat seng awning off the front eave (z -19), level with the eave line, so nothing hangs below the roof.
	part({
		Name = "Awning",
		Size = Vector3.new(14, AWNING_THICK, 3.6),
		CFrame = CFrame.new(30, EAVE + AWNING_THICK / 2, -17.2),
		Color = C.shadow,
		Material = Enum.Material.CorrodedMetal,
	}).Parent = model
	posts(model, { Vector3.new(24, GROUND_Y, -15.5), Vector3.new(36, GROUND_Y, -15.5) }, EAVE, C.wood)

	local table = part({
		Name = "Table",
		Size = Vector3.new(5, 2.2, 3),
		Position = Vector3.new(30, GROUND_Y + 1.1, -22),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.WoodPlanks,
	})
	table.Parent = model
	-- Sign rests on the top of the awning, at the eave.
	sign(model, CFrame.new(30, EAVE + AWNING_THICK + SIGN_HALF_HEIGHT, -18.8), "WARUNG", Vector2.new(240, 70))
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

-- Tree positions in XZ (studs). Each sits in a quadrant clear of the 18-wide road cross
-- (|x| and |z| >= 14), at least 14 studs from every hub centre, inside the village band
-- (|z| <= 52), so nothing lands on a road, a hub, the sawah terraces or the river.
local TREE_XZ = {
	{ 20, 40 }, { 44, 40 }, { 54, 16 }, { 56, -18 }, { 48, -40 }, { 20, -40 }, { -20, -40 },
	{ -48, -36 }, { -56, 18 }, { -52, 36 }, { -20, 40 }, { -46, -18 }, { -24, 46 }, { 40, 52 },
}

-- Canopy balls for the base tree. Colours are palette keys; tree and ball index flip them so
-- the grove mixes daun and padi, and the size scale varies per tree (deterministic, no random).
local CANOPY_BALLS = {
	{ size = 8, offset = Vector3.new(0, 11, 0) },
	{ size = 6.4, offset = Vector3.new(-2.2, 9.6, 1.2) },
	{ size = 5.6, offset = Vector3.new(1.8, 10.8, -1.8) },
}

local function treeSpots(): { Vector3 }
	local spots = {}
	for _, xz in TREE_XZ do
		table.insert(spots, Vector3.new(xz[1], GROUND_Y, xz[2]))
	end
	return spots
end

local function canopyLayout(index: number): { { size: number, offset: Vector3, color: string, castShadow: boolean } }
	local scale = 0.92 + (index % 3) * 0.08
	local layout = {}
	for ballIndex, def in CANOPY_BALLS do
		table.insert(layout, {
			size = def.size * scale,
			offset = Vector3.new(def.offset.X * scale, def.offset.Y * scale, def.offset.Z * scale),
			color = if (index + ballIndex) % 2 == 0 then "daun" else "padi",
			castShadow = ballIndex == 1,
		})
	end
	return layout
end

Greybox.treeSpots = treeSpots
Greybox.canopyLayout = canopyLayout

-- A stylised tree: a two-section tapered trunk (Cylinder parts, bambu wood) and three overlapping
-- Ball canopy parts. Five parts in total; only the first canopy ball casts a shadow.
local function buildTree(index: number, spot: Vector3): Model
	local tree = Instance.new("Model")
	tree.Name = "Tree_" .. index

	part({
		Name = "TrunkBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 2.6, 2.6),
		Position = spot + Vector3.new(0, 2, 0),
		Orientation = Vector3.new(0, 0, 90),
		Color = C.wood,
		Material = Enum.Material.Wood,
	}).Parent = tree
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 1.6, 1.6),
		Position = spot + Vector3.new(0, 7, 0),
		Orientation = Vector3.new(0, 0, 90),
		Color = C.wood,
		Material = Enum.Material.Wood,
	}).Parent = tree

	for ballIndex, ball in canopyLayout(index) do
		part({
			Name = "Canopy_" .. ballIndex,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(ball.size, ball.size, ball.size),
			Position = spot + ball.offset,
			Color = tint(Props.palette(ball.color), ((index * 7 + ballIndex * 3) % 9) / 9),
			Material = Enum.Material.Grass,
			Transparency = 0,
			CanCollide = false,
			CastShadow = ball.castShadow,
		}).Parent = tree
	end
	return tree
end

local function scatterTrees(world: Folder)
	for index, spot in treeSpots() do
		local tree = buildTree(index, spot)
		tree.Parent = world
		contour(tree, 40)
	end
end

-- Dense, realistic background forest surrounding the perimeter of the village (radius ~135-170 studs).
-- Keeps the West sunset corridor (130 deg to 230 deg) open so the low warm sun and horizon glow
-- are never blocked from illuminating the village.
local function buildBackgroundForest(world: Folder)
	local forest = Instance.new("Folder")
	forest.Name = "BackgroundForest"
	forest.Parent = world

	local ok, storage = pcall(function()
		return game:GetService("ServerStorage")
	end)
	local template = ok and storage and storage:FindFirstChild("Realistic Pine Tree")

	for angleDeg = 0, 355, 6 do
		local inSunset = (angleDeg >= 130 and angleDeg <= 230)
		if not inSunset then
			local rad = math.rad(angleDeg)
			local layers = 2 + (angleDeg % 2)
			for layer = 1, layers do
				local baseDist = if layer == 1 then 170 elseif layer == 2 then 150 else 135
				local dist = baseDist + ((angleDeg * 7 + layer * 13) % 20)
				local a = rad + math.rad((layer - 1) * 3)
				local x = math.cos(a) * dist
				local z = math.sin(a) * dist

				local tree: Model
				if template then
					tree = template:Clone() :: Model
					local scale = 0.8 + ((angleDeg * 5 + layer * 11) % 9) * 0.05
					for _, p in tree:GetDescendants() do
						if p:IsA("BasePart") then
							p.Anchored = true
							p.CanCollide = false
							p.CanQuery = false
							p.CanTouch = false
							p.CastShadow = (layer >= 2 and angleDeg % 2 == 0)
							p.Size = p.Size * scale
						end
					end
					local rotY = math.rad((angleDeg * 37 + layer * 73) % 360)
					tree:PivotTo(CFrame.new(x, 0.5, z) * CFrame.Angles(0, rotY, 0))
				else
					tree = Instance.new("Model")
					local scale = 0.8 + ((angleDeg * 5 + layer * 11) % 9) * 0.05
					part({
						Name = "Trunk",
						Shape = Enum.PartType.Cylinder,
						Size = Vector3.new(45 * scale, 2.4 * scale, 2.4 * scale),
						Position = Vector3.new(x, 22 * scale, z),
						Orientation = Vector3.new(0, 0, 90),
						Color = Color3.fromRGB(75, 52, 35),
						Material = Enum.Material.Wood,
						CanCollide = false,
						CanQuery = false,
						CanTouch = false,
						CastShadow = false,
					}).Parent = tree

					part({
						Name = "Canopy",
						Shape = Enum.PartType.Ball,
						Size = Vector3.new(24 * scale, 48 * scale, 24 * scale),
						Position = Vector3.new(x, 32 * scale, z),
						Color = Props.palette("daun"),
						Material = Enum.Material.Grass,
						CanCollide = false,
						CanQuery = false,
						CanTouch = false,
						CastShadow = (layer >= 2 and angleDeg % 2 == 0),
					}).Parent = tree
				end

				tree.Name = "Pine_" .. angleDeg .. "_" .. layer
				tree.Parent = forest
			end
		end
	end
end

-- Warm packed earth: bambu #b98a5a shaded about 25 percent, with a thin kertas edge on each side
-- so the strip reads as a path. Six road parts in total: two roads and four edge strips.
local function buildRoads(world: Folder)
	local earth = Color3.fromRGB(138, 106, 70)
	local edge = Props.palette("kertas")
	local ROAD_WIDTH = 18
	local EDGE_WIDTH = 0.4
	local ROAD_Y = GROUND_Y + 0.03
	local EDGE_Y = GROUND_Y + 0.11

	for _, horizontal in { true, false } do
		part({
			Name = "Road",
			Size = if horizontal then Vector3.new(512, 0.1, ROAD_WIDTH) else Vector3.new(ROAD_WIDTH, 0.1, 512),
			Position = Vector3.new(0, ROAD_Y, 0),
			Color = earth,
			Material = Enum.Material.Ground,
		}).Parent = world

		for _, side in { -1, 1 } do
			local across = side * (ROAD_WIDTH / 2 - EDGE_WIDTH / 2)
			part({
				Name = "RoadEdge",
				Size = if horizontal then Vector3.new(512, 0.12, EDGE_WIDTH) else Vector3.new(EDGE_WIDTH, 0.12, 512),
				Position = if horizontal then Vector3.new(0, EDGE_Y, across) else Vector3.new(across, EDGE_Y, 0),
				Color = edge,
				Material = Enum.Material.Slate,
				CanCollide = false,
			}).Parent = world
		end
	end
end

-- The exact terrain volumes Greybox owns: village ground, road corridors, hub clearings,
-- the river, and the four sawah terrace rows.
-- Clearing these before filling makes a rebuild idempotent without touching designer terrain.
local function terrainBlocks(): { { cframe: CFrame, size: Vector3, material: Enum.Material } }
	local blocks = {
		-- Village ground base (allows 3D Terrain.Decoration grass to grow)
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, 0), size = Vector3.new(400, TERRAIN_VOXEL, 400), material = Enum.Material.Grass },

		-- Road corridors (Ground material suppresses 3D grass decoration along paths)
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, 0), size = Vector3.new(400, TERRAIN_VOXEL, 18), material = Enum.Material.Ground },
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, 0), size = Vector3.new(18, TERRAIN_VOXEL, 400), material = Enum.Material.Ground },

		-- Spawn center clearing
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, 0), size = Vector3.new(32, TERRAIN_VOXEL, 32), material = Enum.Material.Ground },

		-- Hub footprints (clearing building interiors)
		{ cframe = CFrame.new(30, TERRAIN_BASE_Y, 26), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },
		{ cframe = CFrame.new(-30, TERRAIN_BASE_Y, 26), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },
		{ cframe = CFrame.new(-30, TERRAIN_BASE_Y, -26), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },
		{ cframe = CFrame.new(30, TERRAIN_BASE_Y, -26), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, 26), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },
		{ cframe = CFrame.new(0, TERRAIN_BASE_Y, -16), size = Vector3.new(28, TERRAIN_VOXEL, 24), material = Enum.Material.Ground },

		-- River
		{ cframe = CFrame.new(0, -4, 110), size = Vector3.new(220, 8, 100), material = Enum.Material.Water },
	}
	for row = 0, 3 do
		table.insert(blocks, {
			cframe = CFrame.new(0, TERRAIN_BASE_Y, -100 + row * 14),
			size = Vector3.new(120 - row * 22, TERRAIN_VOXEL, 18),
			material = Enum.Material.Ground,
		})
	end
	return blocks
end

Greybox.terrainBlocks = terrainBlocks
Greybox.GROUND_Y = GROUND_Y
Greybox.TERRAIN_VOXEL = TERRAIN_VOXEL

-- Smooth Terrain is voxelized and a place can hold terrain older than the source that made it.
-- Clear the whole historical village band (the first generator's slab reached a surface near Y=2.6,
-- the current one sits on GROUND_Y) before refilling, so no older slab survives under the new one.
local TERRAIN_CLEAR_BOTTOM = -8
local TERRAIN_CLEAR_TOP = 8

local function terrainClearBlocks(): { { cframe: CFrame, size: Vector3 } }
	return {
		{
			cframe = CFrame.new(0, (TERRAIN_CLEAR_BOTTOM + TERRAIN_CLEAR_TOP) / 2, 0),
			size = Vector3.new(400, TERRAIN_CLEAR_TOP - TERRAIN_CLEAR_BOTTOM, 400),
		},
	}
end

Greybox.terrainClearBlocks = terrainClearBlocks

-- Clears every owned volume with Air, then fills them. Safe to call on every rebuild.
function Greybox.applyTerrain(terrain: Terrain)
	pcall(function()
		terrain.Decoration = true
	end)
	local blocks = terrainBlocks()
	for _, clear in terrainClearBlocks() do
		terrain:FillBlock(clear.cframe, clear.size, Enum.Material.Air)
	end
	for _, block in blocks do
		terrain:FillBlock(block.cframe, block.size, Enum.Material.Air)
	end
	for _, block in blocks do
		terrain:FillBlock(block.cframe, block.size, block.material)
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

	-- Invisible, but the collidable plane the village is authored on: terrain tops out on GROUND_Y
	-- too, so this part is a stable floor even where the voxel surface wobbles under a player.
	local ground = part({
		Name = "Ground",
		Size = Vector3.new(512, 1, 512),
		Position = Vector3.new(0, 0, 0),
		Color = Props.palette("daun"),
		Material = Enum.Material.Grass,
		Transparency = 1,
		CanCollide = true,
	})
	ground.Parent = world
	local waterColor = Props.palette("malam")
	local grassColor = Props.palette("padi")
	workspace.Terrain.WaterColor = waterColor
	workspace.Terrain:SetMaterialColor(Enum.Material.Ground, Props.palette("bambu"))
	workspace.Terrain:SetMaterialColor(Enum.Material.Grass, grassColor)
	Greybox.applyTerrain(workspace.Terrain)
	Landscape.apply(workspace.Terrain) -- after the Ground colour above, which it recolours

	buildRoads(world)

	local spawnPos = Vector3.new(0, GROUND_Y + 0.5, 16)
	local spawnLook = Vector3.new(0, GROUND_Y + 1.5, 0)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.lookAt(spawnPos, spawnLook)
	spawn.Position = spawnPos
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
	buildBackgroundForest(world)
	contourDescendants(world)
	Decor.build(world) -- after contour: decor stays outline-free to keep the Highlight count down
	Flora.build(world)
	Details.build(world)

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
