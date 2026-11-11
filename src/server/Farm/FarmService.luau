-- FarmService: the ONLY owner of tile data (plant / grow / harvest / buy tile / cheats
-- that touch growth). Growth is timestamp-based, so crops keep growing while offline:
--   ready when os.time() >= plantedAt + growSeconds
--
-- Flow (TECH.md §5): the tile ProximityPrompt starts an attempt on the server, the client
-- plays a minigame and reports a score, the server re-checks everything before mutating.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local Cheats = require(Shared.Config.Cheats)
local GameConfig = require(Shared.Config.Game)
local Tiers = require(Shared.Config.Tiers)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Produce = require(Shared.Produce)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local LiveConfig = require(script.Parent.Parent.Live.LiveConfig)
local ToolService = require(script.Parent.ToolService)
local StorageService = require(script.Parent.StorageService)
local RarityService = require(script.Parent.RarityService)
local TraitService = require(script.Parent.TraitService)
local AlmanakService = require(script.Parent.Parent.Progression.AlmanakService)
local PlotService = require(script.Parent.PlotService)

local OWNED_COLOR = Color3.fromRGB(105, 72, 45)
local LOCKED_COLOR = Color3.fromRGB(100, 100, 100)
local HOT_COLOR = Color3.fromRGB(120, 200, 80)

local FarmService = {}

type Pending = {
	tile: number,
	action: string,
	cropId: string?,
	startedAt: number,
}

local selectedSeed: { [Player]: string } = {}
local pending: { [Player]: Pending } = {}
-- Tiles still growing, so the ready-check loop doesn't scan everything: [player][tile] = readyAt
local growing: { [Player]: { [number]: number } } = {}

local function tileKey(index: number): string
	return "t" .. index
end

local function roundQuality(q: number): number
	return math.floor(q * 1000 + 0.5) / 1000
end

local function maxTilesFor(player: Player): number
	if player:GetAttribute("Pass_ExtraPlot") then
		return GameConfig.maxTilesWithPass
	end
	return GameConfig.maxTiles
end

local function setCropVisual(tile: BasePart, cropId: string?, ready: boolean, hot: boolean)
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
	if hot then
		visual.Color = if ready then HOT_COLOR else HOT_COLOR:Lerp(Color3.new(0, 0, 0), 0.25)
	else
		visual.Color = if ready then crop.color else Color3.fromRGB(80, 170, 70)
	end
	visual.CFrame = tile.CFrame * CFrame.new(0, tile.Size.Y / 2 + size.Y / 2, 0)

	local glow = visual:FindFirstChild("HotGlow") :: PointLight?
	if hot and not glow then
		local light = Instance.new("PointLight")
		light.Name = "HotGlow"
		light.Color = Color3.fromRGB(120, 255, 90)
		light.Brightness = 1.4
		light.Range = 9
		light.Parent = visual
	elseif not hot and glow then
		glow:Destroy()
	end
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
		setCropVisual(tile, nil, false, false)
		tile:SetAttribute("Crop", nil)
		tile:SetAttribute("ReadyAt", nil)
		tile:SetAttribute("Hot", false)
		if index == data.tilesOwned + 1 and index <= maxTilesFor(player) then
			tile:SetAttribute("State", "buy")
			tile:SetAttribute("Price", GameConfig.tilePrice(data.tilesOwned))
			prompt.Enabled = true
		else
			tile:SetAttribute("State", "locked")
			prompt.Enabled = false
		end
		if growing[player] then
			growing[player][index] = nil
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
		tile:SetAttribute("Hot", false)
		setCropVisual(tile, nil, false, false)
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
	tile:SetAttribute("Hot", entry.hot == true)
	setCropVisual(tile, entry.crop, ready, entry.hot == true)
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
	for index = 1, GameConfig.tilesBuilt do
		refreshTile(player, data, plot, index)
	end
end

local function canPlant(player: Player, data, cropId: string): boolean
	local crop = Crops.list[cropId]
	if not crop then
		return false
	end
	if not EconomyService.hasRank(data, crop.rank) then
		Notify.send(player, "n_rank_locked", "@rank_" .. crop.rank)
		return false
	end
	if Inventory.getSeed(data, cropId) < 1 then
		Notify.send(player, "n_no_seed", "@crop_" .. cropId)
		return false
	end
	return true
end

-- The sack is carried; a full sack must be sold or stored before the next harvest.
local function sackFull(player: Player, data): boolean
	if Produce.count(data.produce or {}) < ToolService.sackCapacity(data) then
		return false
	end
	Notify.send(player, "n_sack_full")
	return true
end

local function doPlant(player: Player, data, plot, index: number, cropId: string, quality: number)
	local crop = Crops.list[cropId]
	Inventory.takeSeed(data, cropId, 1)
	data.tiles[tileKey(index)] = {
		crop = cropId,
		plantedAt = os.time(),
		growSeconds = ToolService.growSeconds(crop.growSeconds, crop.family, data),
		quality = roundQuality(math.clamp(quality + ToolService.plantBonus(data), 0, 1)),
		hot = false,
		harvests = 0,
		fertilised = false,
	}
	EconomyService.sync(player)
	refreshTile(player, data, plot, index)
	Notify.send(player, "n_planted", "@crop_" .. cropId)
end

local function revealHarvest(player: Player, cropId: string, tier: string, discovery: any?)
	if Tiers.isRare(tier) then
		-- The "wow" harvest: the client tints this toast with the tier colour.
		Notify.send(player, "n_rarity_reveal", "@crop_" .. cropId, "@tier_" .. tier, tier)
	elseif discovery and (discovery.newTier or #discovery.newTraits > 0) then
		Notify.send(player, "n_almanak_new", "@crop_" .. cropId, "@tier_" .. tier)
	else
		Notify.send(player, "n_harvested", "@crop_" .. cropId)
	end
	if discovery and discovery.pageCompleted and discovery.reward and discovery.family then
		Notify.send(player, "n_almanak_page", "@almanak_page_" .. discovery.family, "@cosmetic_" .. discovery.reward)
	end
end

local function doHarvest(
	player: Player,
	data,
	plot,
	index: number,
	harvestQuality: number,
	destination: string?
)
	local entry = data.tiles[tileKey(index)]
	if not entry then
		return
	end
	local crop = Crops.list[entry.crop]
	if not crop then
		data.tiles[tileKey(index)] = nil
		refreshTile(player, data, plot, index)
		return
	end

	-- Planting and harvesting each set a quality; the crop's final quality is their average.
	local quality = (entry.quality + harvestQuality) / 2
	local runtime = LiveConfig.getRuntime()
	local traits = TraitService.roll({
		hot = entry.hot == true,
		fertilised = entry.fertilised == true,
		certified = entry.certified == true,
		weather = runtime.cuaca,
		anomaly = runtime.anomali,
	})
	local tier = RarityService.roll(quality)

	if destination == "gudang" then
		data.gudang = data.gudang or { capacity = GameConfig.gudangBaseCapacity, stacks = {} }
		data.gudang.stacks = data.gudang.stacks or {}
		Produce.add(data.gudang.stacks, entry.crop, quality, { tier = tier, traits = traits })
		StorageService.publish(player, data)
		State.touch(player, "gudang")
	else
		EconomyService.addHarvest(player, entry.crop, quality, { tier = tier, traits = traits })
	end
	local discovery = AlmanakService.record(player, entry.crop, tier, traits)

	-- Kebun and perkebunan re-harvest from the same plant until it is spent.
	local harvests = (entry.harvests or 0) + 1
	if crop.regrowSeconds and harvests < (crop.maxHarvests or 1) then
		entry.harvests = harvests
		entry.plantedAt = os.time()
		entry.growSeconds = ToolService.growSeconds(crop.regrowSeconds, crop.family, data)
		entry.quality = roundQuality(harvestQuality)
		entry.hot = false
		entry.fertilised = false
		entry.certified = nil
	else
		data.tiles[tileKey(index)] = nil
	end

	refreshTile(player, data, plot, index)
	revealHarvest(player, entry.crop, tier, discovery)
end

local function buyTile(player: Player, data, plot, index: number)
	if index ~= data.tilesOwned + 1 or index > maxTilesFor(player) then
		return
	end
	if not EconomyService.trySpend(player, GameConfig.tilePrice(data.tilesOwned)) then
		return
	end
	data.tilesOwned += 1
	EconomyService.refreshRank(player) -- Juragan needs 12 tiles
	refreshTile(player, data, plot, index)
	refreshTile(player, data, plot, index + 1)
	Notify.send(player, "n_tile_bought")
end

local function isOwnedAndNear(player: Player, data, plot, index: number): boolean
	local tile = plot.tiles[index]
	if not tile or index < 1 or index > GameConfig.tilesBuilt then
		return false
	end
	if not EconomyService.near(player, tile.Position, GameConfig.interactDistance) then
		Notify.send(player, "n_too_far")
		return false
	end
	return true
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
	if not isOwnedAndNear(player, data, plot, index) then
		return
	end

	if index > data.tilesOwned then
		buyTile(player, data, plot, index)
		return
	end

	local entry = data.tiles[tileKey(index)]
	if entry == nil then
		local cropId = selectedSeed[player] or "padi"
		if not canPlant(player, data, cropId) then
			return
		end
		pending[player] = { tile = index, action = "plant", cropId = cropId, startedAt = os.clock() }
		Remotes.Minigame_Start:FireClient(player, "plant", index, cropId)
	elseif os.time() >= entry.plantedAt + entry.growSeconds then
		if sackFull(player, data) then
			return
		end
		pending[player] = { tile = index, action = "harvest", startedAt = os.clock() }
		Remotes.Minigame_Start:FireClient(player, "harvest", index, entry.crop)
	else
		Notify.send(player, "n_still_growing")
	end
end

-- Re-validate the pending attempt, then apply it with the minigame's quality.
local function finish(player: Player, quality: number): boolean
	local attempt = pending[player]
	if not attempt then
		return false
	end
	local data = PlayerData.get(player)
	local plot = PlotService.getPlotOf(player)
	if not data or not plot then
		pending[player] = nil
		return false
	end
	local index = attempt.tile
	if not plot.tiles[index] then
		pending[player] = nil
		return false
	end
	if attempt.action == "plant" then
		if data.tiles[tileKey(index)] ~= nil then
			pending[player] = nil
			return false
		end
		local cropId = attempt.cropId or "padi"
		if not canPlant(player, data, cropId) then
			pending[player] = nil
			return false
		end
		pending[player] = nil
		doPlant(player, data, plot, index, cropId, quality)
		return true
	elseif attempt.action == "harvest" then
		local entry = data.tiles[tileKey(index)]
		if not entry or os.time() < entry.plantedAt + entry.growSeconds then
			pending[player] = nil
			return false
		end
		pending[player] = nil
		if sackFull(player, data) then
			return false
		end
		doHarvest(player, data, plot, index, quality)
		return true
	end
	pending[player] = nil
	return false
end

local function onComplete(player: Player, score: any)
	if not RateLimit.allow(player, "Farm_Complete", 4) then
		return
	end
	if type(score) ~= "number" or score ~= score or score == math.huge or score == -math.huge then
		return
	end
	local attempt = pending[player]
	if not attempt then
		return
	end
	local elapsed = os.clock() - attempt.startedAt
	if elapsed < GameConfig.minigameMinSeconds or elapsed > GameConfig.minigameMaxSeconds then
		return
	end
	score = math.clamp(score, 0, 1)
	finish(player, 0.8 + 0.5 * score)
end

local function onAuto(player: Player, tile: any, action: any, cropId: any)
	if not RateLimit.allow(player, "Farm_Auto", GameConfig.autoRatePerSecond) then
		return
	end
	local attempt = pending[player]
	if not attempt or attempt.tile ~= tile or attempt.action ~= action then
		return
	end
	if action == "plant" and cropId ~= nil and cropId ~= attempt.cropId then
		return
	end
	if type(tile) ~= "number" or (action ~= "plant" and action ~= "harvest") then
		return
	end
	finish(player, GameConfig.autoQuality)
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

-- Cheat support (called by CheatService; FarmService still owns the growth numbers).
function FarmService.applyOplosan(player: Player, index: number): boolean
	local data = PlayerData.get(player)
	local plot = PlotService.getPlotOf(player)
	if not data or not plot then
		return false
	end
	local entry = data.tiles[tileKey(index)]
	if not entry or entry.hot or index > data.tilesOwned then
		return false
	end
	local now = os.time()
	local readyAt = entry.plantedAt + entry.growSeconds
	local remaining = readyAt - now
	if remaining <= 0 then
		return false
	end
	local shift = remaining * (Cheats.list.oplosan.growBonus or 0.4)
	entry.plantedAt -= shift
	entry.hot = true
	-- It was force-fed, so it is no longer "organic" (unfertilised).
	entry.fertilised = true
	refreshTile(player, data, plot, index)
	return true
end

function FarmService.hasGrowing(player: Player): boolean
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local now = os.time()
	for _, entry in data.tiles do
		if now < entry.plantedAt + entry.growSeconds then
			return true
		end
	end
	return false
end

-- Attacker crops speed up, victim crops slow down (GDD §4, Curi Air).
function FarmService.stealWater(attacker: Player, victim: Player): boolean
	local attackerData = PlayerData.get(attacker)
	local victimData = PlayerData.get(victim)
	local attackerPlot = PlotService.getPlotOf(attacker)
	local victimPlot = PlotService.getPlotOf(victim)
	if not attackerData or not victimData or not attackerPlot or not victimPlot then
		return false
	end
	local shift = Cheats.list.curi_air.shiftSeconds or 30
	local now = os.time()
	local attackerAffected = 0
	local victimAffected = 0

	for index, entry in attackerData.tiles do
		if now < entry.plantedAt + entry.growSeconds then
			entry.plantedAt -= shift
			attackerAffected += 1
			refreshTile(attacker, attackerData, attackerPlot, tonumber(string.sub(index, 2)) or 0)
		end
	end
	for index, entry in victimData.tiles do
		if now < entry.plantedAt + entry.growSeconds then
			entry.plantedAt += shift
			victimAffected += 1
			refreshTile(victim, victimData, victimPlot, tonumber(string.sub(index, 2)) or 0)
		end
	end

	return attackerAffected > 0 and victimAffected > 0
end

-- RaidService confiscates hot produce (GDD §4, §5.3).
function FarmService.confiscateHotTiles(player: Player): number
	local data = PlayerData.get(player)
	local plot = PlotService.getPlotOf(player)
	if not data or not plot then
		return 0
	end
	local count = 0
	for index, entry in data.tiles do
		if entry.hot then
			data.tiles[index] = nil
			count += 1
			refreshTile(player, data, plot, tonumber(string.sub(index, 2)) or 0)
		end
	end
	return count
end

function FarmService.getTileEntry(player: Player, index: number): any?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	return data.tiles[tileKey(index)]
end

-- Worker support: which tiles are ready, in stable order.
function FarmService.readyTiles(player: Player): { number }
	local data = PlayerData.get(player)
	if not data then
		return {}
	end
	local now = os.time()
	local ready = {}
	for key, entry in data.tiles do
		if Crops.list[entry.crop] and now >= entry.plantedAt + entry.growSeconds then
			table.insert(ready, tonumber(string.sub(key, 2)) or 0)
		end
	end
	table.sort(ready)
	return ready
end

-- Harvest one ready tile straight into the gudang (buruh tani). No minigame, but the same
-- rarity/trait/almanak rules; the caller already checked the gudang has room.
function FarmService.harvestToStorage(player: Player, index: number): boolean
	if type(index) ~= "number" then
		return false
	end
	local data = PlayerData.get(player)
	local plot = PlotService.getPlotOf(player)
	if not data or not plot or not plot.tiles[index] then
		return false
	end
	local entry = data.tiles[tileKey(index)]
	if not entry or not Crops.list[entry.crop] then
		return false
	end
	if os.time() < entry.plantedAt + entry.growSeconds then
		return false
	end
	if StorageService.used(data) >= StorageService.capacity(player, data) then
		return false
	end
	doHarvest(player, data, plot, index, GameConfig.autoQuality, "gudang")
	return true
end

function FarmService.refresh(player: Player)
	refreshAll(player)
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
	Notify.send(player, "n_welcome")
end

function FarmService.start()
	Remotes.Farm_SelectSeed.OnServerEvent:Connect(onSelectSeed)
	Remotes.Farm_Complete.OnServerEvent:Connect(onComplete)
	Remotes.Farm_Auto.OnServerEvent:Connect(onAuto)
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
	pending[player] = nil
	growing[player] = nil
end)

return FarmService
