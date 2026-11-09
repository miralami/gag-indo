-- PlotService: builds the greybox village and assigns plots to players.
-- Owns the World folder, plot models and tile parts. Knows nothing about save data.
-- Week 5 art pass: replace these generated parts with real models, keep the attribute names.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)

local TILE_SIZE = 6
local TILE_GAP = 1.5
local STEP = TILE_SIZE + TILE_GAP

export type Plot = {
	index: number,
	model: Model,
	owner: Player?,
	tiles: { [number]: BasePart },
	spawnCFrame: CFrame,
	sign: TextLabel,
}

local PlotService = {}

local plots: { Plot } = {}
local plotOf: { [Player]: Plot } = {}
local tilePromptHandler: ((Player, number, number) -> ())? = nil
local pasarHandler: ((Player) -> ())? = nil

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function makePrompt(parent: Instance, objectText: string, actionText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = objectText
	prompt.ActionText = actionText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = parent
	return prompt
end

local function makeBillboard(parent: Instance, height: number, size: Vector2): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Status"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 70
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = ""
	label.Parent = gui
	return label
end

local function buildPasar(world: Folder)
	local stall = Instance.new("Model")
	stall.Name = "Pasar"
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 3, 5),
		Position = Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = stall
	local roof = part({
		Name = "Roof",
		Size = Vector3.new(16, 0.6, 8),
		Position = Vector3.new(0, 8, 0),
		Color = Color3.fromRGB(30, 110, 170),
		Material = Enum.Material.Fabric,
	})
	roof.Parent = stall
	for _, x in { -7, 7 } do
		part({
			Name = "Pole",
			Size = Vector3.new(0.6, 8, 0.6),
			Position = Vector3.new(x, 4, 0),
			Color = Color3.fromRGB(110, 80, 50),
		}).Parent = stall
	end
	local sign = makeBillboard(roof, 2.5, Vector2.new(220, 50))
	sign.Text = "PASAR"
	local prompt = makePrompt(counter, "Pasar", "Jual hasil panen")
	prompt.Name = "SellPrompt"
	CollectionService:AddTag(prompt, "PasarPrompt")
	prompt.Triggered:Connect(function(player)
		if pasarHandler then
			pasarHandler(player)
		end
	end)
	stall.PrimaryPart = counter
	stall.Parent = world
end

local function buildPlot(world: Folder, index: number): Plot
	local angle = (index - 1) / GameConfig.plotCount * math.pi * 2
	local center = Vector3.new(math.cos(angle) * GameConfig.plotRadius, 0, math.sin(angle) * GameConfig.plotRadius)
	-- -Z of this CFrame faces the village center
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))

	local cols = GameConfig.tileColumns
	local rows = math.ceil(GameConfig.maxTiles / cols)

	local model = Instance.new("Model")
	model.Name = "Plot_" .. index
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)

	local base = part({
		Name = "Base",
		Size = Vector3.new(cols * STEP + 4, 0.4, rows * STEP + 4),
		CFrame = cf * CFrame.new(0, 0.7, 0),
		Color = Color3.fromRGB(90, 140, 60),
		Material = Enum.Material.Grass,
	})
	base.Parent = model
	model.PrimaryPart = base

	local tiles = {}
	for i = 1, GameConfig.maxTiles do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local x = (col - (cols - 1) / 2) * STEP
		local z = (row - (rows - 1) / 2) * STEP
		local tile = part({
			Name = "Tile_" .. i,
			Size = Vector3.new(TILE_SIZE, 0.5, TILE_SIZE),
			CFrame = cf * CFrame.new(x, 1.1, z),
			Color = Color3.fromRGB(100, 100, 100),
			Material = Enum.Material.Ground,
			Transparency = 0.6,
		})
		tile:SetAttribute("PlotIndex", index)
		tile:SetAttribute("TileIndex", i)
		tile:SetAttribute("State", "noowner") -- noowner | locked | buy | empty | growing | ready
		local prompt = makePrompt(tile, "Petak", "Tanam / Panen")
		prompt.Name = "Prompt"
		CollectionService:AddTag(tile, "Tile") -- client finds tiles by tag (works with streaming)
		prompt.Enabled = false
		prompt.Triggered:Connect(function(player)
			if tilePromptHandler then
				tilePromptHandler(player, index, i)
			end
		end)
		makeBillboard(tile, 4, Vector2.new(140, 40))
		tile.Parent = model
		tiles[i] = tile
	end

	-- Sign on the side facing the village center
	local signPost = part({
		Name = "SignPost",
		Size = Vector3.new(6, 3, 0.4),
		CFrame = cf * CFrame.new(0, 3, -(rows * STEP / 2 + 3)),
		Color = Color3.fromRGB(140, 100, 60),
		Material = Enum.Material.Wood,
	})
	signPost.Parent = model
	local sign = makeBillboard(signPost, 3, Vector2.new(220, 50))
	sign.Text = "Lahan Kosong"

	model.Parent = world

	return {
		index = index,
		model = model,
		owner = nil,
		tiles = tiles,
		spawnCFrame = cf * CFrame.new(0, 4, -(rows * STEP / 2 + 7)) * CFrame.Angles(0, math.pi, 0),
		sign = sign,
	}
end

function PlotService.build()
	local world = Instance.new("Folder")
	world.Name = "World"

	part({
		Name = "Ground",
		Size = Vector3.new(512, 1, 512),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(110, 160, 70),
		Material = Enum.Material.Grass,
	}).Parent = world

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 1, 14)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	buildPasar(world)
	for i = 1, GameConfig.plotCount do
		plots[i] = buildPlot(world, i)
	end

	world.Parent = workspace
end

function PlotService.onTilePrompt(handler: (Player, number, number) -> ())
	tilePromptHandler = handler
end

function PlotService.onPasarPrompt(handler: (Player) -> ())
	pasarHandler = handler
end

function PlotService.claim(player: Player): Plot?
	if plotOf[player] then
		return plotOf[player]
	end
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plotOf[player] = plot
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.sign.Text = "Lahan " .. player.DisplayName
			return plot
		end
	end
	return nil
end

function PlotService.release(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	plotOf[player] = nil
	plot.owner = nil
	plot.model:SetAttribute("OwnerUserId", 0)
	plot.sign.Text = "Lahan Kosong"
	for _, tile in plot.tiles do
		local crop = tile:FindFirstChild("Crop")
		if crop then
			crop:Destroy()
		end
		tile:SetAttribute("State", "noowner")
		tile:SetAttribute("Crop", nil)
		tile:SetAttribute("ReadyAt", nil)
		tile:SetAttribute("Price", nil)
		tile.Color = Color3.fromRGB(100, 100, 100)
		tile.Transparency = 0.6
		local prompt = tile:FindFirstChild("Prompt") :: ProximityPrompt
		prompt.Enabled = false
	end
end

function PlotService.getPlot(index: number): Plot?
	return plots[index]
end

function PlotService.getPlotOf(player: Player): Plot?
	return plotOf[player]
end

function PlotService.getPasarPosition(): Vector3
	return Vector3.new(0, 1.5, 0)
end

function PlotService.teleportToPlot(player: Player)
	local plot = plotOf[player]
	local character = player.Character
	if plot and character then
		-- Load the area around the plot first (needed when StreamingEnabled is on).
		pcall(function()
			player:RequestStreamAroundAsync(plot.spawnCFrame.Position, 5)
		end)
		if character.Parent then
			character:PivotTo(plot.spawnCFrame)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlotService.release(player)
end)

return PlotService
