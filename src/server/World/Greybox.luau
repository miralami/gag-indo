-- Greybox: generated stand-in for the real map (v2 PLAN §3.1, docs/v2/visual/art/MAP_SPEC.md).
-- It builds the blockout village and emits the same tags/attributes a designer map uses
-- (see World/Map.luau), so the rest of the game never hardcodes layout.
--
-- This module is intentionally dumb: no handlers, no services. Village.bind() wires
-- prompts and NPCs after the world exists. Every coordinate comes from MapSpec; nothing here
-- keeps a second copy of the layout.

local Map = require(script.Parent.Map)
local Props = require(script.Parent.Props)
local NpcFactory = require(script.Parent.NpcFactory)
local Decor = require(script.Parent.Decor)
local Ground = require(script.Parent.Ground)
local Flora = require(script.Parent.Flora)
local Details = require(script.Parent.Details)
local Landscape = require(script.Parent.Landscape)
local MapSpec = require(script.Parent.MapSpec)
local ModelMapForestR9 = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").ModelMapForestR9)
local Visuals = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config.Visuals)
local okLoader, Loader = pcall(function()
	return require(script.Parent.LookDevAssetLoader)
end)
local LookDevAssetLoader = if okLoader and Loader then Loader else {}

local Greybox = {}

-- The top of World.Ground, plots, spawn and every hub foundation. Terrain tops out on this same
-- plane, so the grass reads flush with the walkable ground instead of burying it.
local GROUND_Y = Ground.Y
-- Roblox terrain voxels are 4 studs. Measured in Studio (2026-11-15): a FillBlock's visible top
-- face lands on regionTop + TERRAIN_VOXEL / 2, i.e. half a voxel ABOVE the requested region, not
-- snapped up to the next whole voxel. MapSpec.volumeForTop encodes that rule so every terrain
-- surface here lands exactly on the requested height.
local TERRAIN_VOXEL = 4
local C = {
	paper = Props.palette("kertas"), grass = Props.palette("padi"),
	clay = Props.palette("genteng"), red = Props.palette("merah"),
	wood = Props.palette("bambu"), gold = Props.palette("kunyit"),
	blue = Props.palette("malam"), shadow = Props.palette("indigo"),
}
-- Road and path earth: bambu #b98a5a shaded about 25 percent. Landscape recolours the Ground
-- terrain material to the same value, so the road Parts and the terrain corridors read as one.
local EARTH = Color3.fromRGB(138, 106, 70)

local function contour(model: Model, maxDistance: number?)
	local highlight = Instance.new("Highlight")
	highlight.Name = "InkContour"
	highlight.Adornee = model
	highlight.FillTransparency = 1
	highlight.OutlineColor = Props.palette("tinta")
	-- Thin ink: a faint line, not a hard black edge (designer feedback 2026-11-16).
	highlight.OutlineTransparency = if maxDistance and maxDistance <= 48 then 0.8 else 0.6
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

-- Set dressing ---------------------------------------------------------------
-- Three clusters near the hubs, placed from the hub tables so they never reach the road cross
-- (|x|, |z| >= 21) or another hub. Offsets stay within ~12 studs of the cluster origin.
local function hubsDressing(): { { number } }
	local list = {}
	for _, key in { "pasar", "ronda", "gelap" } do
		local hub = MapSpec.hub(key)
		list[#list + 1] = { hub.x + 14, hub.z + 22 }
	end
	return list
end
local DRESSING_ORIGINS = hubsDressing()
local DRESSING_PROPS = {
	{ "Sack", Vector3.new(2.5, GROUND_Y + 0.45, 1.5), Vector3.new(1.4, 0.9, 1.2), C.wood, Enum.Material.Fabric },
	{ "Galon", Vector3.new(4.5, GROUND_Y + 0.7, 1.5), Vector3.new(0.8, 1.4, 0.8), C.blue, Enum.Material.Wood },
	{ "MotorBody", Vector3.new(-3.5, GROUND_Y + 0.5, 1.5), Vector3.new(2.8, 0.7, 1.2), C.red, Enum.Material.Wood },
	{ "Laundry", Vector3.new(5.5, GROUND_Y + 1.5, 3.5), Vector3.new(2, 1.2, 0.2), C.paper, Enum.Material.Fabric },
}

local function dressingKit(): Model
	local kit = Instance.new("Model")
	kit.Name = "DressingKit"
	for _, def in DRESSING_PROPS do
		local shape = if def[1] == "Galon" then Enum.PartType.Cylinder else Enum.PartType.Block
		local p = part({ Name = def[1], Position = def[2], Size = def[3], Shape = shape, Color = def[4], Material = def[5], CanCollide = false })
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
	for index, origin in DRESSING_ORIGINS do
		local clone = dressingKit()
		clone.Name = "DressingCluster_" .. index
		for _, item in clone:GetChildren() do
			if item:IsA("BasePart") then
				item.Position += Vector3.new(origin[1], 0, origin[2])
			end
		end
		clone.Parent = world
	end
end

-- Signs ----------------------------------------------------------------------
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

-- Hub kit -------------------------------------------------------------------
-- Each hub is a building, not a slab: a raised stone plinth, real walls where the front stays
-- open for its prompt, a pitched roof (two tilted slabs and a ridge beam) that reads from 40
-- studs, and one palette accent. Every prompt keeps a clear walkway from the open side.
--
-- Hubs are built in a local frame: +Z is the door side and MapSpec.hubPoint turns a local point
-- into world XZ. Unrotated boxes set Position + Orientation (0, yaw, 0); tilted roof slabs set a
-- CFrame built as translate * yaw * pitch, never Position and CFrame together (Props.part applies
-- properties in an unordered loop).
local STONE = Props.palette("tintaLembut")
local PLINTH_HEIGHT = 0.8
local PLINTH_TOP = GROUND_Y + PLINTH_HEIGHT
local ROOF_THICK = 0.6

-- Headroom. Every part a player can walk under at a hub (roof eave, awning, trim, spanduk) has its
-- underside on EAVE, which MapSpec pins to HEADROOM above GROUND_Y across all six hubs.
-- A roof is built from that eave line up: its ridge sits `rise` above it, and the underside falls
-- from the ridge to the eave.
local HUB_ROOFS = Decor.HUB_ROOFS
local EAVE = Decor.EAVE_UNDERSIDE
local SPANDUK_HEIGHT = 1
local AWNING_THICK = 0.5
local SIGN_HEIGHT = 3.2
local SIGN_HALF_HEIGHT = SIGN_HEIGHT / 2
-- Every hub building part that stops at the eave, so a loft wall can close the triangle under a roof.
local WALL_TOP = EAVE
local DOOR_HEIGHT = 10.5 -- the reference door: 1.45 avatars

local function ridgeOf(roof: { rise: number, halfDepth: number }): number
	return EAVE + roof.rise
end

-- Roof underside `depth` studs in from its ridge line.
local function under(roof: { rise: number, halfDepth: number }, depth: number): number
	return Decor.undersideAt(roof, depth)
end

-- A part placed in a hub's local frame. `ly` is the world centre height.
local function hubBlock(parent: Instance, hub, name: string, lx: number, ly: number, lz: number, size: Vector3, color: Color3, material: Enum.Material): Part
	local x, z = MapSpec.hubPoint(hub, lx, lz)
	local p = part({
		Name = name,
		Size = size,
		Position = Vector3.new(x, ly, z),
		Orientation = Vector3.new(0, hub.yaw, 0),
		Color = color,
		Material = material,
	})
	p.Parent = parent
	return p
end

-- Decorative trim, thinner than a stud: it never blocks a player, a click or a shadow.
local function hubTrim(parent: Instance, hub, name: string, lx: number, ly: number, lz: number, size: Vector3, color: Color3, material: Enum.Material): Part
	local x, z = MapSpec.hubPoint(hub, lx, lz)
	local p = part({
		Name = name,
		Size = size,
		Position = Vector3.new(x, ly, z),
		Orientation = Vector3.new(0, hub.yaw, 0),
		Color = color,
		Material = material,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	})
	p.Parent = parent
	return p
end

local function hubBall(parent: Instance, hub, name: string, lx: number, ly: number, lz: number, diameter: number, color: Color3, material: Enum.Material): Part
	local x, z = MapSpec.hubPoint(hub, lx, lz)
	local p = part({
		Name = name,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		Position = Vector3.new(x, ly, z),
		Color = color,
		Material = material,
		CanCollide = false,
		CanQuery = false,
	})
	p.Parent = parent
	return p
end

-- A raised stone base the building stands on.
local function hubPlinth(parent: Instance, hub): Part
	return hubBlock(parent, hub, "Plinth", 0, GROUND_Y + PLINTH_HEIGHT / 2, 0, Vector3.new(hub.width, PLINTH_HEIGHT, hub.depth), STONE, Enum.Material.Slate)
end

-- Posts stand from the ground up to the roof underside at their own depth.
local function hubPosts(parent: Instance, hub, roof: { rise: number, halfDepth: number }, corners: { { number } }, color: Color3)
	for _, corner in corners do
		local lx, lz = corner[1], corner[2]
		local top = under(roof, math.abs(lz))
		local height = top - GROUND_Y
		hubBlock(parent, hub, "Post", lx, GROUND_Y + height / 2, lz, Vector3.new(0.7, height, 0.7), color, Enum.Material.Wood)
	end
end

-- The tall cabai-price "ukur" board: a post and a board hung on it. It stands on open ground beside
-- the Pasar, off the road cross, and it is a sign, so it is drawn thin and left uncollidable.
local function buildUkurBoard(world: Folder)
	local board = MapSpec.UKUR_BOARD
	for _, side in { -1, 1 } do
		part({
			Name = "UkurPost",
			Size = Vector3.new(0.4, board.postHeight, 0.4),
			Position = Vector3.new(board.x + side * (board.boardWidth / 2 - 0.4), GROUND_Y + board.postHeight / 2, board.z),
			Color = C.wood,
			Material = Enum.Material.Wood,
		}).Parent = world
	end
	part({
		Name = "UkurBoard",
		Size = Vector3.new(board.boardWidth, board.boardHeight, 0.3),
		Position = Vector3.new(board.x, GROUND_Y + board.boardBottom + board.boardHeight / 2, board.z),
		Orientation = Vector3.new(0, board.yaw, 0),
		Color = C.red,
		Material = Enum.Material.WoodPlanks,
	}).Parent = world
	part({
		Name = "UkurCap",
		Size = Vector3.new(board.boardWidth + 0.6, 0.4, 0.5),
		Position = Vector3.new(board.x, GROUND_Y + board.boardBottom + board.boardHeight, board.z),
		Orientation = Vector3.new(0, board.yaw, 0),
		Color = C.gold,
		Material = Enum.Material.Metal,
		CanCollide = false,
	}).Parent = world
end

-- Pitched roof running along local X. `ridgeY` is the peak on the centre line; `halfDepth` is the
-- eave reach from the ridge along local Z (overhang included); `rise` is the drop from ridge to eave.
local function hubRoof(parent: Instance, hub, name: string, lx: number, lz: number, ridgeY: number, length: number, halfDepth: number, rise: number, color: Color3, material: Enum.Material, ridgeColor: Color3, slot: string?)
	local angle = math.atan2(rise, halfDepth)
	local slope = math.sqrt(halfDepth * halfDepth + rise * rise)
	local yaw = math.rad(hub.yaw)
	for _, side in { -1, 1 } do
		local cy = ridgeY - rise / 2 + math.cos(angle) * ROOF_THICK / 2
		local lzSide = lz + side * (halfDepth / 2 + math.sin(angle) * ROOF_THICK / 2)
		local x, z = MapSpec.hubPoint(hub, lx, lzSide)
		local slab = part({
			Name = name,
			Size = Vector3.new(length, ROOF_THICK, slope),
			CFrame = CFrame.new(x, cy, z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(side * angle, 0, 0),
			Color = color,
			Material = material,
		})
		slab.Parent = parent
		if slot then
			Visuals.applySurface(slab, slot, material)
		end
	end
	hubTrim(parent, hub, "RoofRidge", lx, ridgeY + ROOF_THICK / 2 + 0.25, lz, Vector3.new(length + 0.4, 0.5, 0.5), ridgeColor, Enum.Material.Wood)
end

-- The board carries its name on both faces (readable from either side). It sits just outside the
-- front eave, its bottom resting on the eave/fascia line, so it never floats over a walkway.
local function hubSign(parent: Instance, hub, lz: number, ly: number, text: string, width: number): Part
	local x, z = MapSpec.hubPoint(hub, 0, lz)
	local board = part({
		Name = "Sign",
		Size = Vector3.new(width, SIGN_HEIGHT, 0.4),
		Position = Vector3.new(x, ly, z),
		Orientation = Vector3.new(0, hub.yaw, 0),
		Color = C.wood,
		Material = Enum.Material.Wood,
	})
	board.Parent = parent
	signFace(board, "SignFront", Enum.NormalId.Front, text)
	signFace(board, "SignBack", Enum.NormalId.Back, text)
	return board
end

-- The prompt-bearing part, built from the hub's anchor record so MapSpec stays the only layout.
local function hubAnchor(parent: Instance, hub): Part
	local anchor = hub.anchor
	return hubBlock(parent, hub, anchor.name, anchor.lx, GROUND_Y + anchor.sy / 2, anchor.lz, Vector3.new(anchor.sx, anchor.sy, anchor.sz), C.wood, Enum.Material.WoodPlanks)
end

local function hubPrompt(anchor: Part, hub)
	if not hub.prompt then
		return
	end
	local prompt = Props.prompt(anchor, hub.prompt.object, hub.prompt.action)
	prompt.Name = hub.prompt.name
	prompt.MaxActivationDistance = hub.prompt.distance
	Map.add(prompt, Map.TAGS[hub.prompt.tag])
end

-- Hubs -----------------------------------------------------------------------
-- All six hubs keep clear walkable headroom at the eave line (MapSpec.HEADROOM) and a ridge on the
-- height each hub's silhouette needs (MapSpec.HUBS[*].ridge). Walls stop at the eave; the triangle
-- under the roof is closed by a loft wall so no hub reads as an open scaffold.

-- A wall whose top follows the roof underside, deepest at `deepestZ`, closed off at the eave.
local function hubClosedWall(parent: Instance, hub, name: string, lx: number, lz: number, sizeX: number, sizeZ: number, deepestZ: number, roof, color: Color3, material: Enum.Material): Part
	local top = math.min(under(roof, deepestZ), WALL_TOP)
	return hubBlock(parent, hub, name, lx, (PLINTH_TOP + top) / 2, lz, Vector3.new(sizeX, top - PLINTH_TOP, sizeZ), color, material)
end

-- Loft: the storey between the eave and the roof underside, inset a little so the roof overhangs it.
local function hubLoft(parent: Instance, hub, roof, color: Color3, material: Enum.Material)
	local inset = 0.6
	local top = under(roof, 0)
	hubBlock(parent, hub, "LoftWall", 0, (WALL_TOP + top) / 2, -hub.depth / 2 + inset, Vector3.new(hub.width - inset * 2, top - WALL_TOP, 0.5), color, material)
	for _, side in { -1, 1 } do
		hubBlock(parent, hub, "LoftWall", side * (hub.width / 2 - inset), (WALL_TOP + top) / 2, 0, Vector3.new(0.5, top - WALL_TOP, hub.depth - inset * 2), color, material)
	end
end

-- Pasar: open-front stall with a two-storey market hall. The south face (local +Z) opens on the
-- plaza, so the stall row, the shelves on the back wall and the spanduk all read from the spawn side.
-- Footprint 64 x 52.
local function buildPasar(world: Folder)
	local hub = MapSpec.hub("pasar")
	local roof = HUB_ROOFS.pasar
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local halfW, halfD = hub.width / 2, hub.depth / 2
	hubPlinth(model, hub)
	local counter = hubAnchor(model, hub)
	hubPosts(model, hub, roof, { { -halfW + 2, -halfD + 2 }, { halfW - 2, -halfD + 2 }, { -halfW + 2, halfD - 2 }, { halfW - 2, halfD - 2 } }, C.shadow)
	hubClosedWall(model, hub, "BackWall", 0, -halfD + 0.25, hub.width, 0.5, halfD - 0.25, roof, C.wood, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		hubClosedWall(model, hub, "SideWall", side * (halfW - 0.25), -6, 0.5, 32, 20, roof, C.wood, Enum.Material.WoodPlanks)
	end
	hubLoft(model, hub, roof, C.wood, Enum.Material.WoodPlanks)
	-- Stall row: five booths under the loft, each a counter board on two legs, so the ground floor
	-- reads as a market hall and not an empty barn.
	for booth = -2, 2 do
		local lx = booth * 11
		hubBlock(model, hub, "StallCounter", lx, GROUND_Y + 1.8, -6, Vector3.new(9, 0.4, 4), C.wood, Enum.Material.WoodPlanks)
		for _, side in { -1, 1 } do
			hubBlock(model, hub, "StallLeg", lx + side * 4, GROUND_Y + 0.9, -6, Vector3.new(0.4, 1.8, 3.6), C.wood, Enum.Material.Wood)
		end
		hubBlock(model, hub, "StallDivider", lx + 5.5, GROUND_Y + 3.2, -6, Vector3.new(0.3, 6.4, 8), C.wood, Enum.Material.WoodPlanks)
	end
	hubRoof(model, hub, "Roof", 0, 0, ridgeOf(roof), hub.width + 2, roof.halfDepth, roof.rise, C.shadow, Enum.Material.Metal, C.wood)
	for _, side in { -1, 1 } do
		hubTrim(model, hub, "Spanduk", 0, EAVE + SPANDUK_HEIGHT / 2, side * roof.halfDepth, Vector3.new(hub.width + 2.4, SPANDUK_HEIGHT, 0.3), C.red, Enum.Material.Fabric)
	end
	hubSign(model, hub, roof.halfDepth + 0.1, EAVE + SPANDUK_HEIGHT + SIGN_HALF_HEIGHT, hub.sign, 22)
	hubPrompt(counter, hub)

	model.PrimaryPart = counter
	contour(model)
	model.Parent = world
end

-- Tengkulak Gelap: a tiled shed at the end of the alley behind the Pasar. Three dark walls, a merah
-- lantern door on the open +Z face, and the kunyit lantern ball above it. Footprint 32 x 28.
local function buildGelap(world: Folder)
	local hub = MapSpec.hub("gelap")
	local roof = HUB_ROOFS.gelap
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local dark = Props.palette("tintaLembut")
	local halfW, halfD = hub.width / 2, hub.depth / 2
	hubPlinth(model, hub)
	local counter = hubAnchor(model, hub)
	hubPosts(model, hub, roof, { { -halfW + 2, -halfD + 2 }, { halfW - 2, -halfD + 2 }, { -halfW + 2, halfD - 2 }, { halfW - 2, halfD - 2 } }, C.shadow)
	hubClosedWall(model, hub, "BackWall", 0, -halfD + 0.25, hub.width, 0.5, halfD - 0.25, roof, dark, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		hubClosedWall(model, hub, "SideWall", side * (halfW - 0.25), -4, 0.5, 16, 11, roof, dark, Enum.Material.WoodPlanks)
	end
	-- Merah door frame with the lantern ball hanging on the front eave line. The frame is a full
	-- 10.5-stud door, the same height as the reference, measured from the ground plane: the eave is at
	-- 11.25, so a door standing on the 0.8 plinth would push its head through the roof.
	for _, side in { -1, 1 } do
		hubTrim(model, hub, "LanternDoor", side * 3.6, GROUND_Y + DOOR_HEIGHT / 2, halfD - 0.6, Vector3.new(0.4, DOOR_HEIGHT, 0.4), C.red, Enum.Material.Wood)
	end
	hubTrim(model, hub, "LanternDoor", 0, GROUND_Y + DOOR_HEIGHT + 0.25, halfD - 0.6, Vector3.new(7.6, 0.5, 0.4), C.red, Enum.Material.Wood)
	hubBall(model, hub, "Lantern", 0, GROUND_Y + DOOR_HEIGHT - 1.6, halfD - 0.6, 1.9, C.gold, Enum.Material.SmoothPlastic)
	hubRoof(model, hub, "Roof", 0, 0, ridgeOf(roof), hub.width + 2, roof.halfDepth, roof.rise, C.clay, Enum.Material.Slate, Props.palette("tinta"), "genteng")
	hubSign(model, hub, roof.halfDepth + 0.1, EAVE + SIGN_HALF_HEIGHT, hub.sign, 18)
	hubPrompt(counter, hub)

	model.PrimaryPart = counter
	contour(model)
	model.Parent = world
end

-- Warung: genteng roof over a two-storey shop house, a flat seng awning over the front bench, open to
-- the south (+Z). Footprint 52 x 44.
local function buildWarung(world: Folder)
	local hub = MapSpec.hub("warung")
	local roof = HUB_ROOFS.warung
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local halfW, halfD = hub.width / 2, hub.depth / 2
	hubPlinth(model, hub)
	local table = hubAnchor(model, hub)
	hubPosts(model, hub, roof, { { -halfW + 2, -halfD + 2 }, { halfW - 2, -halfD + 2 }, { -halfW + 2, halfD - 2 }, { halfW - 2, halfD - 2 } }, C.shadow)
	hubClosedWall(model, hub, "BackWall", 0, -halfD + 0.25, hub.width, 0.5, halfD - 0.25, roof, C.wood, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		hubClosedWall(model, hub, "SideWall", side * (halfW - 0.25), -6, 0.5, 32, 16, roof, C.wood, Enum.Material.WoodPlanks)
	end
	hubLoft(model, hub, roof, C.wood, Enum.Material.WoodPlanks)
	hubRoof(model, hub, "Roof", 0, 0, ridgeOf(roof), hub.width + 2, roof.halfDepth, roof.rise, C.clay, Enum.Material.Slate, Props.palette("tinta"), "genteng")
	-- Flat seng awning off the front eave, level with the eave line, so nothing hangs below the roof.
	hubTrim(model, hub, "Awning", 0, EAVE + AWNING_THICK / 2, roof.halfDepth + MapSpec.AWNING_REACH / 2, Vector3.new(hub.width, AWNING_THICK, MapSpec.AWNING_REACH), C.shadow, Enum.Material.CorrodedMetal)
	for _, side in { -1, 1 } do
		local top = EAVE
		local height = top - GROUND_Y
		hubBlock(model, hub, "AwningPost", side * (halfW - 5), GROUND_Y + height / 2, roof.halfDepth + MapSpec.AWNING_REACH, Vector3.new(0.7, height, 0.7), C.wood, Enum.Material.Wood)
	end
	hubSign(model, hub, roof.halfDepth + MapSpec.AWNING_REACH - 0.6, EAVE + AWNING_THICK + SIGN_HALF_HEIGHT, hub.sign, 18)
	for _, x in hub.benches do
		hubBlock(model, hub, "Bench", x, GROUND_Y + 1.2, 10, Vector3.new(4, 0.5, 1.6), C.wood, Enum.Material.Wood)
	end
	hubPrompt(table, hub)

	model.PrimaryPart = table
	contour(model)
	model.Parent = world
end

-- Pos Polisi: malam two-storey concrete post, porch open to the north (local +Z, yaw 180).
-- Footprint 48 x 44.
local function buildPosPolisi(world: Folder)
	local hub = MapSpec.hub("polisi")
	local roof = HUB_ROOFS.posPolisi
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local halfW, halfD = hub.width / 2, hub.depth / 2
	hubPlinth(model, hub)
	local desk = hubAnchor(model, hub)
	hubPosts(model, hub, roof, { { -halfW + 2, -halfD + 2 }, { halfW - 2, -halfD + 2 }, { -halfW + 2, halfD - 2 }, { halfW - 2, halfD - 2 } }, C.shadow)
	hubClosedWall(model, hub, "BackWall", 0, -halfD + 0.25, hub.width, 0.5, halfD - 0.25, roof, C.blue, Enum.Material.Concrete)
	for _, side in { -1, 1 } do
		hubClosedWall(model, hub, "SideWall", side * (halfW - 0.25), -6, 0.5, 32, 16, roof, C.blue, Enum.Material.Concrete)
	end
	hubLoft(model, hub, roof, C.blue, Enum.Material.Concrete)
	hubRoof(model, hub, "Roof", 0, 0, ridgeOf(roof), hub.width + 2, roof.halfDepth, roof.rise, C.shadow, Enum.Material.Metal, C.blue)
	for _, side in { -1, 1 } do
		hubTrim(model, hub, "MalamTrim", 0, EAVE + 0.25, side * (roof.halfDepth - 0.2), Vector3.new(hub.width + 2.4, 0.5, 0.5), C.blue, Enum.Material.Metal)
	end
	hubSign(model, hub, roof.halfDepth + 0.1, EAVE + 0.5 + SIGN_HALF_HEIGHT, hub.sign, 18)
	hubPrompt(desk, hub)

	model.PrimaryPart = desk
	contour(model)
	model.Parent = world
end

-- Rumah Pak RT: the scale reference for the whole village (docs/v2/visual/art/map concept art). A player is
-- about 7.25 studs tall, so the door is 10.5 (1.45 avatars) and the house is two storeys: a tall front
-- block A with a gold gable roof (ridge about 32 studs up) beside a lower block B with a zinc front, a
-- porch awning across both, porch open to the north (local +Z, yaw 180). Footprint 48 x 34.
local function buildPakRt(world: Folder)
	local hub = MapSpec.hub("pakrt")
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local y0 = PLINTH_TOP
	local WALL = 0.8
	local DOOR_W, DOOR_H = 7, 10.5
	local A = { cx = -13, w = 22, cz = -3, d = 24, wall = 22, rise = 9 }
	local B = { cx = 10, w = 24, cz = -4, d = 22, wall = 15, rise = 7 }
	local roofHub = { x = hub.x, z = hub.z, yaw = hub.yaw + 90 }

	hubPlinth(model, hub)
	local table = hubAnchor(model, hub)

	-- Box between two heights, in the hub's local frame.
	local function box(name: string, lx: number, lz: number, sx: number, sz: number, yBottom: number, yTop: number, color: Color3, material: Enum.Material): Part
		return hubBlock(model, hub, name, lx, (yBottom + yTop) / 2, lz, Vector3.new(sx, yTop - yBottom, sz), color, material)
	end

	-- Block A: two storeys, door in the front wall.
	local topA = y0 + A.wall
	box("BackWall", A.cx, A.cz - A.d / 2 + WALL / 2, A.w, WALL, y0, topA, C.wood, Enum.Material.WoodPlanks)
	box("SideWall", A.cx - A.w / 2 + WALL / 2, A.cz, WALL, A.d, y0, topA, C.wood, Enum.Material.WoodPlanks)
	box("SideWall", A.cx + A.w / 2 - WALL / 2, A.cz, WALL, A.d, y0, topA, C.wood, Enum.Material.WoodPlanks)
	local frontZA = A.cz + A.d / 2 - WALL / 2
	local sideW = (A.w - DOOR_W) / 2
	box("FrontWall", A.cx - DOOR_W / 2 - sideW / 2, frontZA, sideW, WALL, y0, topA, C.wood, Enum.Material.WoodPlanks)
	box("FrontWall", A.cx + DOOR_W / 2 + sideW / 2, frontZA, sideW, WALL, y0, topA, C.wood, Enum.Material.WoodPlanks)
	box("Lintel", A.cx, frontZA, DOOR_W, WALL, y0 + DOOR_H, topA, C.wood, Enum.Material.WoodPlanks)

	-- Block B: one storey and a half, zinc front.
	local topB = y0 + B.wall
	box("BackWall", B.cx, B.cz - B.d / 2 + WALL / 2, B.w, WALL, y0, topB, C.wood, Enum.Material.WoodPlanks)
	box("SideWall", B.cx + B.w / 2 - WALL / 2, B.cz, WALL, B.d, y0, topB, C.wood, Enum.Material.WoodPlanks)
	local frontZB = B.cz + B.d / 2 - WALL / 2
	box("FrontWall", B.cx, frontZB, B.w, WALL, y0, topB, C.paper, Enum.Material.Metal)

	-- Stepped gable fills, so the triangle under each roof is closed.
	local function gable(lx: number, lz: number, width: number, eaveY: number, rise: number)
		local steps = 4
		for k = 0, steps - 1 do
			local w = width * (1 - (k + 0.5) / steps)
			box("Gable", lx, lz, w, WALL, eaveY + k * rise / steps, eaveY + (k + 1) * rise / steps, C.wood, Enum.Material.WoodPlanks)
		end
	end
	gable(A.cx, frontZA, A.w, topA, A.rise)
	gable(A.cx, A.cz - A.d / 2 + WALL / 2, A.w, topA, A.rise)
	gable(B.cx, frontZB, B.w, topB, B.rise)
	gable(B.cx, B.cz - B.d / 2 + WALL / 2, B.w, topB, B.rise)

	-- Gable roofs, ridge along local Z. hubRoof runs its ridge along local X, so it gets a hub turned 90
	-- degrees and the block centre swapped into that frame: (lx, lz) -> (-lz, lx).
	hubRoof(model, roofHub, "Roof", -A.cz, A.cx, topA + A.rise, A.d + 3, A.w / 2 + 1.5, A.rise, C.gold, Enum.Material.Slate, C.clay, "genteng")
	hubRoof(model, roofHub, "Roof", -B.cz, B.cx, topB + B.rise, B.d + 3, B.w / 2 + 1.5, B.rise, C.gold, Enum.Material.Slate, C.clay, "genteng")

	-- Porch awning across both blocks, high at the walls and falling toward the front.
	local awningZ0, awningZ1 = 7, 17.5
	local awningHigh, awningLow = y0 + 13, y0 + 10.2
	local pitch = math.atan2(awningHigh - awningLow, awningZ1 - awningZ0)
	local awningLen = math.sqrt((awningZ1 - awningZ0) ^ 2 + (awningHigh - awningLow) ^ 2)
	local ax, az = MapSpec.hubPoint(hub, -1, (awningZ0 + awningZ1) / 2)
	local awning = part({
		Name = "Awning",
		Size = Vector3.new(50, AWNING_THICK, awningLen),
		CFrame = CFrame.new(ax, (awningHigh + awningLow) / 2, az) * CFrame.Angles(0, math.rad(hub.yaw), 0) * CFrame.Angles(pitch, 0, 0),
		Color = C.clay,
		Material = Enum.Material.Metal,
	})
	awning.Parent = model
	hubTrim(model, hub, "KunyitTrim", -1, awningLow + 0.25, awningZ1 + 0.1, Vector3.new(50.4, 0.5, 0.5), C.gold, Enum.Material.Metal)
	for _, lx in { -23, -9, 9, 21 } do
		local underside = awningHigh - (awningHigh - awningLow) * (17 - awningZ0) / (awningZ1 - awningZ0)
		box("Post", lx, 17, 0.8, 0.8, GROUND_Y, underside, C.shadow, Enum.Material.Wood)
	end

	-- Door frame, upper-floor windows on A, lower windows on B.
	for _, side in { -1, 1 } do
		hubTrim(model, hub, "DoorFrame", A.cx + side * (DOOR_W / 2 + 0.2), y0 + DOOR_H / 2, frontZA + 0.45, Vector3.new(0.5, DOOR_H, 0.3), C.gold, Enum.Material.Wood)
	end
	hubTrim(model, hub, "DoorFrame", A.cx, y0 + DOOR_H + 0.2, frontZA + 0.45, Vector3.new(DOOR_W + 1, 0.5, 0.3), C.gold, Enum.Material.Wood)
	local function window(lx: number, lz: number, yCentre: number, w: number, h: number)
		hubTrim(model, hub, "WindowFrame", lx, yCentre, lz + 0.15, Vector3.new(w + 1, h + 1, 0.3), C.shadow, Enum.Material.Wood)
		local glass = hubTrim(model, hub, "WindowGlass", lx, yCentre, lz + 0.3, Vector3.new(w, h, 0.2), Props.palette("malam"), Enum.Material.Glass)
		glass.Transparency = 0.35
	end
	window(A.cx - 6, frontZA + WALL / 2, y0 + 17, 3.6, 4.6)
	window(A.cx + 6, frontZA + WALL / 2, y0 + 17, 3.6, 4.6)
	window(B.cx - 5, frontZB + WALL / 2, y0 + 7, 4.2, 4.2)
	window(B.cx + 5, frontZB + WALL / 2, y0 + 7, 4.2, 4.2)

	hubSign(model, hub, awningZ1 + 0.2, y0 + 12.2, hub.sign, 14)
	hubPrompt(table, hub)

	model.PrimaryPart = table
	contour(model)
	model.Parent = world
end

-- Pos Ronda: bamboo two-storey guard hut on a plinth (door east, yaw 90) with the 36-stud
-- watchtower on its north-west shoulder (MapSpec.RONDA_TOWER, clear of the hut roof). Footprint
-- 44 x 40.
local function buildPosRonda(world: Folder)
	local hub = MapSpec.hub("ronda")
	local roof = HUB_ROOFS.posRonda
	local model = Instance.new("Model")
	model.Name = hub.model
	model:SetAttribute("HubAccent", hub.accent)

	local halfW, halfD = hub.width / 2, hub.depth / 2
	hubPlinth(model, hub)
	local floor = hubAnchor(model, hub)
	floor.Position = Vector3.new(floor.Position.X, PLINTH_TOP + 0.3, floor.Position.Z)
	hubPosts(model, hub, roof, { { -halfW + 2, -halfD + 2 }, { halfW - 2, -halfD + 2 }, { -halfW + 2, halfD - 2 }, { halfW - 2, halfD - 2 } }, C.shadow)
	hubClosedWall(model, hub, "BackWall", 0, -halfD + 0.25, hub.width, 0.5, halfD - 0.25, roof, C.wood, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		hubClosedWall(model, hub, "SideWall", side * (halfW - 0.25), -5, 0.5, 28, 14, roof, C.wood, Enum.Material.WoodPlanks)
	end
	hubLoft(model, hub, roof, C.wood, Enum.Material.WoodPlanks)
	hubRoof(model, hub, "Roof", 0, 0, ridgeOf(roof), hub.width + 2, roof.halfDepth, roof.rise, C.grass, Enum.Material.Grass, C.wood)
	hubSign(model, hub, roof.halfDepth + 0.1, EAVE + SIGN_HALF_HEIGHT, hub.sign, 16)
	Map.add(floor, Map.TAGS.Ronda)

	-- The cell: three low walls, open on the local +Z side so the player can be walked in.
	for _, offset in { { -5.5, 0 }, { 5.5, 0 }, { 0, -5.5 } } do
		local size = if offset[1] ~= 0 then Vector3.new(0.5, 5, 12) else Vector3.new(12, 5, 0.5)
		hubBlock(model, hub, "CellWall", offset[1], PLINTH_TOP + 2.5, offset[2], size, Color3.fromRGB(90, 70, 55), Enum.Material.Wood)
	end

	-- Watchtower beside the hut: four bamboo legs from the ground, a deck and a small pitched roof.
	local tower = MapSpec.RONDA_TOWER
	local towerHub = { x = tower.x, z = tower.z, yaw = 0 }
	local towerTop = GROUND_Y + tower.height
	local legSpread = tower.deck / 2 - 1
	for _, dx in { -legSpread, legSpread } do
		for _, dz in { -legSpread, legSpread } do
			hubBlock(model, towerHub, "TowerLeg", dx, (GROUND_Y + towerTop) / 2, dz, Vector3.new(1.1, towerTop - GROUND_Y, 1.1), C.wood, Enum.Material.Wood)
		end
	end
	hubBlock(model, towerHub, "TowerDeck", 0, towerTop + 0.2, 0, Vector3.new(tower.deck, 0.5, tower.deck), C.wood, Enum.Material.WoodPlanks)
	hubRoof(model, towerHub, "Roof", 0, 0, towerTop + 3, tower.deck + 0.6, 4, tower.roofRise, C.grass, Enum.Material.Grass, C.wood)

	model.PrimaryPart = floor
	contour(model)
	model.Parent = world
end

-- Trees ----------------------------------------------------------------------
-- Tree positions in XZ (studs), inside the plaza ring and the four quadrants and clear of the road
-- cross (|x|, |z| >= 21), every hub footprint, the plaza, the Lapangan, the dressing kits and the
-- Ronda tower. They are village-scale landmarks, not world-scale ones: the trees themselves are
-- unchanged, so their stump spacing and canopy sizes stay readable.
local TREE_XZ = {
	{ -28, -24 }, { 28, -32 }, { 68, -28 }, { 48, -108 }, { -40, -104 }, { -68, -24 }, { -32, -112 },
	{ 112, -48 }, { 60, 24 }, { 48, 108 }, { -48, 108 }, { 68, 104 }, { -112, 48 }, { -68, 28 },
	{ 112, 28 }, { -100, 68 },
}

-- Canopy anchors for the base tree. Retained as pure data for the wind/tagging contract; item 241
-- removed the Ball parts themselves. Village trees now wear baked vegetation_r4 meshes (below).
local CANOPY_BALLS = {
	{ size = 8, offset = Vector3.new(0, 11, 0) },
	{ size = 6.4, offset = Vector3.new(-2.2, 9.6, 1.2) },
	{ size = 5.6, offset = Vector3.new(1.8, 10.8, -1.8) },
}

local function treeSpots(): { Vector3 }
	local spots = {}
	local keepOut = MapSpec.keepOutRects()
	local roadClear = MapSpec.ROAD.halfWidth + 3
	for _, xz in TREE_XZ do
		local blocked = math.abs(xz[1]) < roadClear or math.abs(xz[2]) < roadClear
		for _, rect in keepOut do
			if math.abs(xz[1] - rect[1]) < rect[3] + 3 and math.abs(xz[2] - rect[2]) < rect[4] + 3 then
				blocked = true
			end
		end
		if not blocked then
			table.insert(spots, Vector3.new(xz[1], GROUND_Y, xz[2]))
		end
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

-- Item 241: baked-first tree retrieval. `baked()` never calls InsertService, so the default look
-- needs no runtime load; mangga is the broadleaf fallback for any missing species bake.
local function bakedTree(species: string): any?
	for _, key in { species, "mangga" } do
		local id = ModelMapForestR9.IDS[key]
		if type(id) == "number" then
			local ok, source = pcall(function()
				return LookDevAssetLoader.baked(id)
			end)
			if ok and source then
				return source
			end
		end
	end
	return nil
end

-- Strip scripts, sanitise legacy names and apply the default-look part flags to a baked clone.
local function normaliseBaked(source, castShadow: boolean)
	local doomed = {}
	for _, d in source:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			doomed[#doomed + 1] = d
		end
		local clean = string.gsub(d.Name, "[Pp][Ii][Nn][Ee]", "")
		if clean ~= d.Name then
			d.Name = clean
		end
	end
	for _, d in doomed do
		d:Destroy()
	end
	for _, d in source:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = castShadow
		end
	end
end

-- A stylised village tree: a small Trunk marker for Flora's clearance check plus one baked
-- tropical tree mesh for the crown. No Ball part is created (item 241).
local function buildTree(index: number, spot: Vector3): Model
	local tree = Instance.new("Model")
	tree.Name = "Tree_" .. index

	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 2, 1.4),
		Position = spot + Vector3.new(0, 1, 0),
		Color = C.wood,
		Material = Enum.Material.Wood,
	}).Parent = tree

	local species = ModelMapForestR9.SPECIES[(index - 1) % #ModelMapForestR9.SPECIES + 1]
	if type(species) == "string" then
		local source = bakedTree(species)
		if source then
			pcall(function()
				normaliseBaked(source, true)
				if source:IsA("Model") then
					source:ScaleTo(0.5)
				end
				source.Name = "CanopyBaked_" .. species
				source:PivotTo(CFrame.new(spot.X, GROUND_Y, spot.Z))
				source.Parent = tree
			end)
		end
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

-- Dense tropical background forest around the perimeter (WORK_QUEUE items 138/102, V-D4:
-- tropical trees only, no pines). ModelMapForestR9 supplies the deterministic ring (260..380)
-- and hills/beyond-400 (400..460) placements, with the West sunset corridor (130..230), the
-- sawah/Balai north band and the river south band already removed. Kelapa is biased to the river
-- side. Baked vegetation_r4 models are cloned; no Ball canopy fallback exists after item 241.
-- Nothing here is a LookDev candidate: this is the default.
local function buildBackgroundForest(world: Folder)
	-- WORK_QUEUE item 138: the saved place carries the pre-V-D4 pine forest as a stale top-level
	-- Workspace.BackgroundForest. Remove any such folder so the shipped world has one forest only
	-- and NO_PINES (whole-workspace, default look) reads zero. Never saved to the place.
	local okWs, ws = pcall(function()
		return workspace
	end)
	if okWs and ws and type((ws :: any).GetChildren) == "function" then
		local okList, children = pcall(function()
			return (ws :: any):GetChildren()
		end)
		if okList and type(children) == "table" then
			for _, child in ipairs(children) do
				if child.Name == ModelMapForestR9.FOLDER_NAME then
					pcall(function()
						child:Destroy()
					end)
				end
			end
		end
	end
	local okOld, old = pcall(function()
		return (world :: any):FindFirstChild(ModelMapForestR9.FOLDER_NAME)
	end)
	if okOld and old then
		pcall(function()
			old:Destroy()
		end)
	end

	local forest = Instance.new("Folder")
	forest.Name = ModelMapForestR9.FOLDER_NAME
	forest.Parent = world
	type ForestEntry = {
		x: number,
		z: number,
		yaw: number?, -- ring placements carry radians; shade anchors reuse angle instead
		scale: number?,
		species: string,
		angle: number,
		layer: number,
		shade: boolean?,
		hubKey: string?,
	}

	local function makeTree(p: ForestEntry, name: string)
		local tree: Model? = nil
		local source = bakedTree(p.species)
		if source and (source :: any):IsA("Model") then
			tree = source :: Model
		end
		if not tree then
			-- Item 241: no Ball canopy fallback. One Model per placement keeps TREE_COUNT stable;
			-- only a plain trunk is drawn when no baked mesh is available.
			tree = Instance.new("Model")
			local isPalm = p.species == "kelapa"
			part({
				Name = "Trunk",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.2, if isPalm then 8.5 else 5.5, 1.2),
				Position = Vector3.new(0, if isPalm then 4.25 else 2.75, 0),
				Color = Color3.fromRGB(75, 52, 35),
				Material = Enum.Material.Wood,
			}).Parent = tree
		end
		if tree then
			local castShadow = p.layer % 2 == 1 -- odd tiers cast; shade anchors use layer 1
			normaliseBaked(tree, castShadow)
			pcall(function()
				tree:ScaleTo(p.scale or 1.15)
			end)
			for _, d in tree:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.CastShadow = castShadow
				end
			end
			tree.Name = name
			tree:SetAttribute("ForestTree", true)
			tree:SetAttribute("ForestSpecies", p.species)
			if p.shade then
				tree:SetAttribute("ShadeTree", true)
			end
			-- pcall-guarded: Lune's mock Instance has no PivotTo; real Studio always places the tree.
			pcall(function()
				tree:PivotTo(CFrame.new(p.x, GROUND_Y, p.z) * CFrame.Angles(0, p.yaw or math.rad(p.angle), 0))
			end)
			tree.Parent = forest
		end
	end

	for _, p in ModelMapForestR9.placements() do
		makeTree(p, ModelMapForestR9.NAME_PREFIX .. p.species .. "_" .. p.angle .. "_" .. p.layer)
	end
	-- Q186: shade trees use the same baked path and post-processing as the ring trees.
	for i, p in ipairs(ModelMapForestR9.shadeAnchors(MapSpec.HUBS)) do
		makeTree(p, "Shade_" .. p.species .. "_" .. p.hubKey .. "_" .. i)
	end
end

-- Sawah ----------------------------------------------------------------------
-- Thin paddy water Parts (MAP_SPEC §5): 0.2 thick, 0.1 above each terrace top, inset 2 studs from
-- the bund, malam Glass, no collision. Padi rows are instanced strips poking through the water.
local function buildPaddy(world: Folder)
	for _, water in MapSpec.paddyWater() do
		part({
			Name = "PaddyWater",
			Size = Vector3.new(water.size[1], water.size[2], water.size[3]),
			Position = Vector3.new(water.centre[1], water.centre[2], water.centre[3]),
			Color = C.blue,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Reflectance = 0.15,
			CanCollide = false,
			CastShadow = false,
		}).Parent = world
	end
	for _, row in MapSpec.paddyRows() do
		part({
			Name = "PadiRow",
			Size = Vector3.new(row.size[1], row.size[2], row.size[3]),
			Position = Vector3.new(row.centre[1], row.centre[2], row.centre[3]),
			Color = C.grass,
			Material = Enum.Material.Grass,
			CanCollide = false,
			CastShadow = false,
		}).Parent = world
	end
end

-- Terraces, ramps, stairs and bridge ----------------------------------------
-- Tilted Parts climb one terrace step each (4 studs over 16) from the ground to the last terrace.
-- Terrain voxels cannot be steps, so the central access is geometry and the side access is stairs.
-- Both are MapSpec.RAMP_WIDTH (24) wide: a doubled world needs doubled treads.

local function buildTerraces(world: Folder)
	for _, ramp in MapSpec.RAMPS do
		local rise = ramp.yHigh - ramp.yLow
		local run = ramp.zHigh - ramp.zLow
		local length = math.sqrt(run * run + rise * rise)
		local angle = math.atan2(rise, math.abs(run))
		part({
			Name = "TerraceRamp",
			Size = Vector3.new(ramp.width, 0.4, length),
			CFrame = CFrame.new(ramp.x, (ramp.yLow + ramp.yHigh) / 2 - 0.2, (ramp.zLow + ramp.zHigh) / 2) * CFrame.Angles(angle, 0, 0),
			Color = EARTH,
			Material = Enum.Material.Ground,
		}).Parent = world
	end
	for _, stair in MapSpec.STAIRS do
		part({
			Name = "TerraceStep",
			Size = Vector3.new(stair.width, stair.top - GROUND_Y, stair.depth),
			Position = Vector3.new(stair.x, (GROUND_Y + stair.top) / 2, stair.z),
			Color = EARTH,
			Material = Enum.Material.Ground,
		}).Parent = world
	end
end

-- Bamboo bridge at x = 0: deck 10 x 56 (z 276..332), top Y = 1.5, 8-stud approach ramps and two
-- railings. A forded crossing 24 wide sits further west in MapSpec.FORD for the dry season.
local function buildBridge(world: Folder)
	local bridge = MapSpec.BRIDGE
	local deckY = bridge.top - bridge.thickness / 2
	local segments = 6
	local segment = (bridge.z1 - bridge.z0) / segments
	for index = 0, segments - 1 do
		part({
			Name = "BridgeDeck",
			Size = Vector3.new(bridge.width, bridge.thickness, segment - 0.06),
			Position = Vector3.new(bridge.x, deckY, bridge.z0 + segment * (index + 0.5)),
			Color = C.wood,
			Material = Enum.Material.WoodPlanks,
		}).Parent = world
	end

	for _, side in { -1, 1 } do
		local x = bridge.x + side * (bridge.width / 2 - 0.2)
		for z = bridge.z0 + 2, bridge.z1 - 2, bridge.postEvery do
			part({
				Name = "BridgePost",
				Size = Vector3.new(0.3, bridge.railTop - bridge.top, 0.3),
				Position = Vector3.new(x, (bridge.top + bridge.railTop) / 2, z),
				Color = C.wood,
				Material = Enum.Material.Wood,
				CanCollide = false,
			}).Parent = world
		end
		part({
			Name = "BridgeRail",
			Size = Vector3.new(0.22, 0.22, bridge.z1 - bridge.z0),
			Position = Vector3.new(x, bridge.railTop, (bridge.z0 + bridge.z1) / 2),
			Color = C.wood,
			Material = Enum.Material.Wood,
			CanCollide = false,
		}).Parent = world
	end

	-- Ramps. A slab rotated about X by +angle has its local +Z end low, so the north ramp (high end
	-- at z0, the deck side) takes -angle and the south ramp (high end at z1) takes +angle.
	local rise = bridge.top - GROUND_Y
	local run = bridge.rampLength
	local angle = math.atan2(rise, run)
	local length = math.sqrt(run * run + rise * rise)
	for _, side in { -1, 1 } do
		local z = if side == -1 then bridge.z0 - run / 2 else bridge.z1 + run / 2
		part({
			Name = "BridgeRamp",
			Size = Vector3.new(bridge.width, bridge.thickness, length),
			CFrame = CFrame.new(bridge.x, (GROUND_Y + bridge.top) / 2 - bridge.thickness / 2, z) * CFrame.Angles(side * angle, 0, 0),
			Color = C.wood,
			Material = Enum.Material.WoodPlanks,
		}).Parent = world
	end
end

-- The ford: a shallow mud crossing 24 wide at MapSpec.FORD, level with the water surface, so the far
-- bank stays reachable in the dry season. Mud, not a bridge: kemarau is when it is used.
local function buildFord(world: Folder)
	local ford = MapSpec.FORD
	local surface = -0.5
	part({
		Name = "RiverFord",
		Size = Vector3.new(ford.width, 0.4, 34),
		Position = Vector3.new(ford.x, surface - 0.2, ford.z),
		Color = Props.palette("tintaLembut"),
		Material = Enum.Material.Mud,
	}).Parent = world
	for _, side in { -1, 1 } do
		part({
			Name = "FordMarker",
			Size = Vector3.new(0.4, 3.2, 0.4),
			Position = Vector3.new(ford.x + side * (ford.width / 2 + 1), GROUND_Y + 1.6, MapSpec.riverCentreZ(ford.x) - 20),
			Color = C.wood,
			Material = Enum.Material.Wood,
		}).Parent = world
	end
end

-- Roads ----------------------------------------------------------------------
-- MAP_SPEC §4 at world scale: 28-wide X and Z arms out to r = 136 (the west arm ends at Pos Ronda),
-- the broken 12-wide connector ring on r = 144, and 16-wide north/south continuations to the Balai
-- and the bridge.
local EDGE_WIDTH = 0.4
local ROAD_EDGE_OFFSET = 0.08

local function buildRoads(world: Folder)
	local road = MapSpec.ROAD
	local earth = Color3.fromRGB(road.earth[1], road.earth[2], road.earth[3])
	local edge = Props.palette(road.edge)

	for _, arm in MapSpec.roadArms() do
		part({
			Name = arm.name,
			Size = Vector3.new(arm.sx, 0.1, arm.sz),
			Position = Vector3.new(arm.x, road.y, arm.z),
			Color = earth,
			Material = Enum.Material.Ground,
		}).Parent = world
		local horizontal = arm.sx > arm.sz
		for _, side in { -1, 1 } do
			local position = if horizontal
				then Vector3.new(arm.x, road.y + ROAD_EDGE_OFFSET, arm.z + side * (arm.sz / 2 - EDGE_WIDTH / 2))
				else Vector3.new(arm.x + side * (arm.sx / 2 - EDGE_WIDTH / 2), road.y + ROAD_EDGE_OFFSET, arm.z)
			part({
				Name = "RoadEdge",
				Size = if horizontal then Vector3.new(arm.sx, 0.12, EDGE_WIDTH) else Vector3.new(EDGE_WIDTH, 0.12, arm.sz),
				Position = position,
				Color = edge,
				Material = Enum.Material.Slate,
				CanCollide = false,
			}).Parent = world
		end
	end

	for _, piece in MapSpec.ringSegments() do
		part({
			Name = "RingRoad",
			Size = Vector3.new(piece.length, 0.1, road.ringWidth),
			Position = Vector3.new(piece.x, road.y, piece.z),
			Orientation = Vector3.new(0, piece.yaw, 0),
			Color = earth,
			Material = Enum.Material.Ground,
		}).Parent = world
	end

	for _, continuation in MapSpec.roadContinuations() do
		part({
			Name = continuation.name,
			Size = Vector3.new(continuation.sx, 0.1, continuation.sz),
			Position = Vector3.new(continuation.x, road.y, continuation.z),
			Color = earth,
			Material = Enum.Material.Ground,
		}).Parent = world
	end
end

-- Terrain --------------------------------------------------------------------
-- MapSpec carries every volume as plain numbers and string materials; this module only converts
-- them. MapSpec has already split every wide volume into strips no wider than MAX_FILL_SPAN (40
-- studs): a 340-wide FillBlock came out full of holes in Studio, and the base slab is 800 wide.
-- The clear envelope (region y -10..22) covers every volume Greybox may ever fill, including the
-- terrace tops, so one Air pass makes a rebuild idempotent: no per-block clear is needed.
local function terrainFrom(volume: { [string]: any }): { cframe: CFrame, size: Vector3, material: Enum.Material }
	return {
		cframe = CFrame.new(volume.centre[1], volume.centre[2], volume.centre[3]),
		size = Vector3.new(volume.size[1], volume.size[2], volume.size[3]),
		material = Enum.Material[volume.material],
	}
end

local function terrainBlocks(): { { cframe: CFrame, size: Vector3, material: Enum.Material } }
	local blocks = {}
	for _, volume in MapSpec.terrainBlocks() do
		table.insert(blocks, terrainFrom(volume))
	end
	return blocks
end

Greybox.terrainBlocks = terrainBlocks
Greybox.GROUND_Y = GROUND_Y
Greybox.TERRAIN_VOXEL = TERRAIN_VOXEL

local function terrainClearBlocks(): { { cframe: CFrame, size: Vector3 } }
	local clears = {}
	for _, volume in MapSpec.terrainClear() do
		table.insert(clears, { cframe = CFrame.new(volume.centre[1], volume.centre[2], volume.centre[3]), size = Vector3.new(volume.size[1], volume.size[2], volume.size[3]) })
	end
	return clears
end

Greybox.terrainClearBlocks = terrainClearBlocks

local function riverVolumes(): { [string]: { { cframe: CFrame, size: Vector3, material: Enum.Material } } }
	local raw = MapSpec.river()
	local out = { carves = {}, beds = {}, banks = {}, water = {} }
	for kind, list in raw do
		for _, volume in list do
			table.insert(out[kind], terrainFrom(volume))
		end
	end
	return out
end

Greybox.riverVolumes = riverVolumes

-- Order matters: clear the envelope, lay the base (slab, roads, plaza, lapangan, hubs, terraces),
-- carve the river through the slab with Air, then fill bed, banks and water on top of the carve.
-- Every list is already split into <= 40-stud pieces, so no FillBlock asks the voxel engine for a
-- volume 800 studs across.
function Greybox.applyTerrain(terrain: Terrain)
	pcall(function()
		terrain.Decoration = true
	end)
	local blocks = terrainBlocks()
	for _, clear in terrainClearBlocks() do
		terrain:FillBlock(clear.cframe, clear.size, Enum.Material.Air)
	end
	for _, block in blocks do
		terrain:FillBlock(block.cframe, block.size, block.material)
	end
	local river = riverVolumes()
	for _, carve in river.carves do
		terrain:FillBlock(carve.cframe, carve.size, Enum.Material.Air)
	end
	for _, bed in river.beds do
		terrain:FillBlock(bed.cframe, bed.size, bed.material)
	end
	for _, bank in river.banks do
		terrain:FillBlock(bank.cframe, bank.size, bank.material)
	end
	for _, water in river.water do
		terrain:FillBlock(water.cframe, water.size, water.material)
	end
end

-- NPCs -----------------------------------------------------------------------
-- One model per MAP_SPEC NPC spot. NpcFactory's default facing is -Z (north), which is the door
-- direction for all three spots: Pak RT and Pos Polisi open north, and the Gelap alley walker
-- looks north up the alley into his own door.
local NPC_CONFIG = {
	pakrt = { name = "Pak RT", subtitle = "Ketua RT 01", shirt = function() return C.gold end, skin = Color3.fromRGB(200, 155, 110), mustache = true, peci = true },
	tengkulak = { name = "Bang Jago", subtitle = "Tengkulak", shirt = function() return C.shadow end, skin = Color3.fromRGB(170, 125, 90) },
	polisi = {
		name = "Polisi Desa",
		shirt = function() return C.blue end,
		skin = Color3.fromRGB(185, 140, 100),
		cap = function() return C.shadow end,
	},
}

local function buildNpcs(world: Folder)
	for _, spot in MapSpec.NPC_SPOTS do
		local config = NPC_CONFIG[spot.npc]
		if config then
			NpcFactory.build({
				name = config.name,
				subtitle = config.subtitle,
				npc = spot.npc,
				position = Vector3.new(spot.x, GROUND_Y, spot.z),
				shirt = config.shirt(),
				skin = config.skin,
				mustache = config.mustache,
				peci = config.peci,
				cap = config.cap and config.cap(),
				parent = world,
			})
		end
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

	-- Invisible, but the collidable plane the village is authored on. Split north/south so the
	-- carved river band is open: one 800 plane at Y = 0.5 would let a player walk over water. The
	-- north plane reaches the base slab's north edge (-400) to the river's north bank, the south plane
	-- covers the far meadow down to the south edge. Terrain still floors the banks, the river bed and
	-- the meadow. Widths and centres are read from the river so they follow MapSpec.
	local half = MapSpec.TERRAIN_HALF
	local northEdge = -half
	local southEdge = half
	local riverNorth = MapSpec.riverCentreZ(0) - 14 -- the channel's north bank line at x = 0
	local riverSouth = MapSpec.riverCentreZ(0) + 14
	part({
		Name = "GroundNorth",
		Size = Vector3.new(half * 2, 1, riverNorth - northEdge),
		Position = Vector3.new(0, 0, (northEdge + riverNorth) / 2),
		Color = Props.palette("daun"),
		Material = Enum.Material.Grass,
		Transparency = 1,
		CanCollide = true,
	}).Parent = world
	part({
		Name = "GroundSouth",
		Size = Vector3.new(half * 2, 1, southEdge - riverSouth),
		Position = Vector3.new(0, 0, (riverSouth + southEdge) / 2),
		Color = Props.palette("daun"),
		Material = Enum.Material.Grass,
		Transparency = 1,
		CanCollide = true,
	}).Parent = world

	workspace.Terrain.WaterColor = C.blue
	workspace.Terrain:SetMaterialColor(Enum.Material.Ground, Props.palette("bambu"))
	workspace.Terrain:SetMaterialColor(Enum.Material.Grass, C.grass)
	Greybox.applyTerrain(workspace.Terrain)
	Landscape.apply(workspace.Terrain) -- after the Ground colour above, which it recolours

	buildRoads(world)

	-- Spawn from MapSpec, facing north so the first frame reads the road to the Balai and terraces.
	local spawnPos = Vector3.new(MapSpec.SPAWN.x, MapSpec.SPAWN.y, MapSpec.SPAWN.z)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(MapSpec.SPAWN.size, 1, MapSpec.SPAWN.size)
	spawn.CFrame = CFrame.lookAt(spawnPos, spawnPos + Vector3.new(0, 0, MapSpec.SPAWN.lookZ))
	spawn.Position = spawnPos
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	Map.add(spawn, Map.TAGS.PlayerSpawn)
	spawn.Parent = world

	buildPasar(world)
	buildGelap(world)
	buildWarung(world)
	buildPosPolisi(world)
	buildPakRt(world)
	buildPosRonda(world)
	buildPaddy(world)
	buildTerraces(world)
	buildBridge(world)
	buildFord(world)
	buildUkurBoard(world)
	buildDressing(world)
	scatterTrees(world)
	buildBackgroundForest(world)
	contourDescendants(world)
	Decor.build(world) -- after contour: decor stays outline-free to keep the Highlight count down
	Flora.build(world)
	Details.build(world)
	buildNpcs(world)

	return world
end

return Greybox
