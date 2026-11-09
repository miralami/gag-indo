-- FarmService: the ONLY owner of tile data (plant / grow / harvest / buy tile).
-- Growth is timestamp-based, so crops keep growing while the player is offline:
--   ready when os.time() >= plantedAt + growSeconds

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local PlotService = require(script.Parent.PlotService)

local notify = EconomyService.notify

local OWNED_COLOR = Color3.fromRGB(105, 72, 45)
local LOCKED_COLOR = Color3.fromRGB(100, 100, 100)

local FarmService = {}

local selectedSeed: { [Player]: string } = {}
-- Tiles still growing, so the ready-check loop doesn't scan everything: [player][tileIndex] = readyAt
local growing: { [Player]: { [number]: number } } = {}

local function tileKey(index: number): string
	return "t" .. index
end

local function setCropVisual(tile: BasePart, cropId: string?, ready: boolean)
	local existing = tile:FindFirstChild("Crop") :: BasePart?
	if not cropId then
		if existing then
			existing:Destroy()
		end
		return
	end
	local crop = Crops.list[cropId]
	local visual = existing
	if not visual then
		local p = Instance.new("Part")
		p.Name = "Crop"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Material = Enum.Material.Grass
		p.Parent = tile
		visual = p
	end
	local size = if ready then Vector3.new(4, 3, 4) else Vector3.new(1.5, 1, 1.5)
	visual.Size = size
	visual.Color = if ready then crop.color else Color3.fromRGB(80, 170, 70)
	visual.CFrame = tile.CFrame * CFrame.new(0, tile.Size.Y / 2 + size.Y / 2, 0)
end

-- Push one tile's save data into the world (attributes, prompt, visuals).
local function refreshTile(player: Player, data, plot, index: number)
	local tile = plot.tiles[index]
	if not tile then
		return
	end
	local prompt = tile:FindFirstChild("Prompt") :: ProximityPrompt
	local entry = data.tiles[tileKey(index)]
	tile:SetAttribute("Price", nil)

	if index > data.tilesOwned then
		tile.Color = LOCKED_COLOR
		tile.Transparency = 0.6
		setCropVisual(tile, nil, false)
		tile:SetAttribute("Crop", nil)
		tile:SetAttribute("ReadyAt", nil)
		if index == data.tilesOwned + 1 then
			tile:SetAttribute("State", "buy")
			tile:SetAttribute("Price", GameConfig.tilePrice(data.tilesOwned))
			prompt.Enabled = true
		else
			tile:SetAttribute("State", "locked")
			prompt.Enabled = false
		end
		return
	end

	tile.Color = OWNED_COLOR
	tile.Transparency = 0
	prompt.Enabled = true

	if entry == nil then
		tile:SetAttribute("State", "empty")
		tile:SetAttribute("Crop", nil)
		tile:SetAttribute("ReadyAt", nil)
		setCropVisual(tile, nil, false)
		if growing[player] then
			growing[player][index] = nil
		end
		return
	end

	local readyAt = entry.plantedAt + entry.growSeconds
	local ready = os.time() >= readyAt
	tile:SetAttribute("State", if ready then "ready" else "growing")
	tile:SetAttribute("Crop", entry.crop)
	tile:SetAttribute("ReadyAt", readyAt)
	setCropVisual(tile, entry.crop, ready)
	if growing[player] then
		growing[player][index] = if ready then nil else readyAt
	end
end

local function refreshAll(player: Player)
	local data = PlayerData.get(player)
	local plot = PlotService.getPlotOf(player)
	if not data or not plot then
		return
	end
	for index = 1, GameConfig.maxTiles do
		refreshTile(player, data, plot, index)
	end
end

local function plant(player: Player, data, plot, index: number)
	local cropId = selectedSeed[player] or "padi"
	local crop = Crops.list[cropId]
	if not crop then
		return
	end
	if not EconomyService.hasRank(data, crop.rank) then
		notify(player, "n_rank_locked", "@rank_" .. crop.rank)
		return
	end
	if (data.seeds[cropId] or 0) < 1 then
		notify(player, "n_no_seed", "@crop_" .. cropId)
		return
	end
	data.seeds[cropId] -= 1
	data.tiles[tileKey(index)] = {
		crop = cropId,
		plantedAt = os.time(),
		growSeconds = crop.growSeconds,
		quality = GameConfig.autoQuality, -- week 2: minigame result replaces this
		hot = false, -- week 3: true when grown with Pupuk Oplosan
	}
	EconomyService.sync(player)
	refreshTile(player, data, plot, index)
	notify(player, "n_planted", "@crop_" .. cropId)
end

local function harvest(player: Player, data, plot, index: number)
	local entry = data.tiles[tileKey(index)]
	data.tiles[tileKey(index)] = nil
	EconomyService.addHarvest(player, entry.crop, entry.quality, entry.hot)
	refreshTile(player, data, plot, index)
	notify(player, "n_harvested", "@crop_" .. entry.crop)
end

local function buyTile(player: Player, data, plot, index: number)
	if data.tilesOwned >= GameConfig.maxTiles or index ~= data.tilesOwned + 1 then
		return
	end
	if not EconomyService.trySpend(player, GameConfig.tilePrice(data.tilesOwned)) then
		return
	end
	data.tilesOwned += 1
	EconomyService.refreshRank(player) -- Juragan needs 12 tiles
	refreshTile(player, data, plot, index)
	refreshTile(player, data, plot, index + 1)
	notify(player, "n_tile_bought")
end

local function onTilePrompt(player: Player, plotIndex: number, index: number)
	if not RateLimit.allow(player, "tile", 6, 6) then
		return
	end
	local data = PlayerData.get(player)
	local plot = PlotService.getPlot(plotIndex)
	if not data or not plot or plot.owner ~= player then
		return
	end
	local tile = plot.tiles[index]
	if not tile or not EconomyService.near(player, tile.Position, GameConfig.interactDistance) then
		return
	end

	if index > data.tilesOwned then
		buyTile(player, data, plot, index)
		return
	end

	local entry = data.tiles[tileKey(index)]
	if entry == nil then
		plant(player, data, plot, index)
	elseif os.time() >= entry.plantedAt + entry.growSeconds then
		harvest(player, data, plot, index)
	else
		notify(player, "n_still_growing")
	end
end

local function onSelectSeed(player: Player, cropId: any)
	if not RateLimit.allow(player, "Farm_SelectSeed", 8) then
		return
	end
	if type(cropId) ~= "string" or not Crops.list[cropId] then
		return
	end
	selectedSeed[player] = cropId
	player:SetAttribute("SelectedSeed", cropId)
end

local function onLoaded(player: Player, _data)
	local plot = PlotService.claim(player)
	if not plot then
		player:Kick("Server penuh. / Server is full.")
		return
	end
	growing[player] = {}
	selectedSeed[player] = "padi"
	player:SetAttribute("SelectedSeed", "padi")
	player:SetAttribute("PlotIndex", plot.index)
	refreshAll(player)

	local function onCharacter(_character: Model)
		task.wait(0.2) -- let the character finish spawning before moving it
		PlotService.teleportToPlot(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	notify(player, "n_welcome")
end

function FarmService.start()
	Remotes.Farm_SelectSeed.OnServerEvent:Connect(onSelectSeed)
	PlotService.onTilePrompt(onTilePrompt)
	PlayerData.onLoaded(onLoaded)

	-- Flip "growing" tiles to "ready" when their time comes (once per second, cheap).
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for player, tiles in growing do
				local data = PlayerData.get(player)
				local plot = PlotService.getPlotOf(player)
				if data and plot then
					for index, readyAt in tiles do
						if now >= readyAt then
							refreshTile(player, data, plot, index)
						end
					end
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	selectedSeed[player] = nil
	growing[player] = nil
end)

return FarmService
