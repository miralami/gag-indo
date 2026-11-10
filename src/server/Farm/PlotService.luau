-- PlotService: builds plot models and assigns one plot per player.
-- Owns the plot models and tile parts. Knows nothing about save data.
-- Week 5 art pass: replace these generated parts with real models, keep the attributes/tags.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)

local Props = require(script.Parent.Parent.World.Props)
local Map = require(script.Parent.Parent.World.Map)

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

local function buildPlot(world: Instance, index: number, anchorCFrame: CFrame?): Plot
	local cf
	if anchorCFrame then
		cf = anchorCFrame
	else
		local angle = (index - 1) / GameConfig.plotCount * math.pi * 2
		local center = Vector3.new(math.cos(angle) * GameConfig.plotRadius, 0, math.sin(angle) * GameConfig.plotRadius)
		-- -Z of this CFrame faces the village center
		cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	end

	local cols = GameConfig.tileColumns
	local rows = math.ceil(GameConfig.tilesBuilt / cols)

	local model = Instance.new("Model")
	model.Name = "Plot_" .. index
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)

	local base = Props.part({
		Name = "Base",
		Size = Vector3.new(cols * STEP + 4, 0.4, rows * STEP + 4),
		CFrame = cf * CFrame.new(0, 0.7, 0),
		Color = Color3.fromRGB(90, 140, 60),
		Material = Enum.Material.Grass,
	})
	base.Parent = model
	model.PrimaryPart = base

	local tiles = {}
	for i = 1, GameConfig.tilesBuilt do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local x = (col - (cols - 1) / 2) * STEP
		local z = (row - (rows - 1) / 2) * STEP
		local tile = Props.part({
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
		tile:SetAttribute("Hot", false)
		local prompt = Props.prompt(tile, "Petak", "Tanam / Panen")
		prompt.Name = "Prompt"
		CollectionService:AddTag(tile, "Tile") -- client finds tiles by tag (works with streaming)
		prompt.Enabled = false
		prompt.Triggered:Connect(function(player)
			if tilePromptHandler then
				tilePromptHandler(player, index, i)
			end
		end)
		Props.billboard(tile, 4, Vector2.new(140, 40), { name = "Status", maxDistance = 70 })
		tile.Parent = model
		tiles[i] = tile
	end

	-- Sign on the side facing the village center
	local signPost = Props.part({
		Name = "SignPost",
		Size = Vector3.new(6, 3, 0.4),
		CFrame = cf * CFrame.new(0, 3, -(rows * STEP / 2 + 3)),
		Color = Color3.fromRGB(140, 100, 60),
		Material = Enum.Material.Wood,
	})
	signPost.Parent = model
	local sign = Props.billboard(signPost, 3, Vector2.new(220, 50), { alwaysOnTop = true })
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
	-- Designer map: build the plots inside the tagged world if there is one.
	local tagged = Map.first(Map.TAGS.World)
	local world: Instance
	if tagged then
		world = tagged
	else
		local folder = workspace:FindFirstChild("World")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "World"
			folder.Parent = workspace
		end
		world = folder
	end

	-- Designer map: one PlotAnchor per plot, attribute PlotIndex = 1..plotCount.
	local anchors = Map.all(Map.TAGS.PlotAnchor)
	if #anchors > 0 then
		for _, anchor in anchors do
			if anchor:IsA("BasePart") then
				local index = tonumber(anchor:GetAttribute("PlotIndex"))
					or tonumber(anchor:GetAttribute("Index"))
					or tonumber(string.match(anchor.Name, "%d+"))
				if index and index >= 1 and index <= GameConfig.plotCount and plots[index] == nil then
					-- The anchor's CFrame is the plot origin; -Z faces the entrance.
					plots[index] = buildPlot(world, index, anchor.CFrame)
				end
			end
		end
		return
	end

	-- Greybox / placeholder map: ring of generated plots around the village.
	for i = 1, GameConfig.plotCount do
		plots[i] = buildPlot(world, i)
	end
end

function PlotService.onTilePrompt(handler: (Player, number, number) -> ())
	tilePromptHandler = handler
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
		tile:SetAttribute("Hot", false)
		tile.Color = Color3.fromRGB(100, 100, 100)
		tile.Transparency = 0.6
		local prompt = tile:FindFirstChild("Prompt") :: ProximityPrompt
		if prompt then
			prompt.Enabled = false
		end
	end
end

function PlotService.getPlot(index: number): Plot?
	return plots[index]
end

function PlotService.getPlotOf(player: Player): Plot?
	return plotOf[player]
end

function PlotService.isNeighbor(a: number, b: number): boolean
	if a == b then
		return false
	end
	local diff = math.abs(a - b)
	return diff == 1 or diff == GameConfig.plotCount - 1
end

function PlotService.getPlotPosition(plot: Plot): Vector3
	local base = plot.model.PrimaryPart
	return if base then base.Position else plot.spawnCFrame.Position
end

function PlotService.getNeighbors(plotIndex: number): { number }
	local count = GameConfig.plotCount
	return {
		((plotIndex - 2) % count) + 1,
		(plotIndex % count) + 1,
	}
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
