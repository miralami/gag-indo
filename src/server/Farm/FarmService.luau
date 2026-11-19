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
local Visuals = require(Shared.Config.Visuals)
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
local OnboardingService = require(script.Parent.Parent.Progression.OnboardingService)
local QuestService = require(script.Parent.Parent.Progression.QuestService)
local BadgeService = require(script.Parent.Parent.Progression.BadgeService)
local PlotService = require(script.Parent.PlotService)
local SeasonsConfig = require(Shared.Config.Seasons)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)
local FirstSession = require(script.Parent.Parent.Progression.FirstSession)

local OWNED_COLOR = Color3.fromRGB(105, 72, 45)
local LOCKED_COLOR = Color3.fromRGB(100, 100, 100)
local HOT_COLOR = Color3.fromRGB(120, 200, 80)

-- BUG-004 seed floor (decision D-G3, option A). A player with no cash, no seed of any kind and
-- no planted tile is stuck, so they get exactly 1 padi seed, once per session. Never cash.
-- Weak keys: the record goes away with the Player object, so a rejoin is a new session.
local seedFloorGranted: { [Player]: boolean } = setmetatable({}, { __mode = "k" })
local SEED_FLOOR_CROP = "padi"
local SEED_PREFIX = Inventory.seedId("")

local function hasAnySeed(data): boolean
	for itemId, count in Inventory.snapshot(data) do
		if string.sub(itemId, 1, #SEED_PREFIX) == SEED_PREFIX and count > 0 then
			return true
		end
	end
	return false
end

-- Called on join, after a harvest, and after a tile purchase: the only paths here that can
-- leave a player with nothing to spend or plant. Returns true when the seed was granted.
local function checkSeedFloor(player: Player): boolean
	if seedFloorGranted[player] then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if data.cash > 0 or hasAnySeed(data) or next(data.tiles or {}) ~= nil then
		return false
	end
	seedFloorGranted[player] = true
	Inventory.addSeed(data, SEED_FLOOR_CROP, 1)
	EconomyService.sync(player)
	State.touch(player, "items")
	Notify.send(player, "n_seed_floor")
	return true
end

local function cropToken(cropId: string): string
	if cropId == "padi" or cropId == "tebu" then return "kunyit" end
	if cropId == "cabai" or cropId == "bawang" then return "merah" end
	if cropId == "kopi" or cropId == "cengkeh" or cropId == "tembakau" then return "bambu" end
	if cropId == "durian" or cropId == "sawit" then return "daun" end
	return "padi"
end

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

local function setCropVisual(tile: BasePart, cropId: string?, ready: boolean, hot: boolean, tierId: string?)
	local existing = tile:FindFirstChild("Crop") :: BasePart?
	if not cropId then
		if existing then
			existing:Destroy()
		end
		return
	end
	local crop = Crops.list[cropId]
	if not crop then
		return
	end
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
	local elapsed = math.max(0, os.time() - tile:GetAttribute("PlantedAt"))
	local stageName = if ready then "siap" elseif elapsed < math.max(1, math.floor(tile:GetAttribute("GrowSeconds") / 3)) then "bibit" else "tumbuh"
	local stage = Visuals.cropStages[stageName]
	local size = stage.stem
	local stem = visual:FindFirstChild("Stem") :: Part?
	local visualParent = visual.Parent
	if not stem then
		stem = Instance.new("Part")
		stem.Name = "Stem"
		stem.Shape = Enum.PartType.Ball
		stem.Anchored = true
		stem.CanCollide = false
		stem.CanQuery = false
		stem.Parent = visualParent
	end
	visual.Shape = Enum.PartType.Block
	visual.Size = Vector3.new(0.35, size, 0.35)
	visual.Material = Enum.Material.Wood
	local crownScale = stage.crown
	local crown = (if cropId == "padi" or cropId == "tebu" or cropId == "jagung" then Vector3.new(2.1, 0.45, 1.5) else Vector3.new(1.7, 1.5, 1.7)) * crownScale
	stem.Size = crown
	stem.Shape = Enum.PartType.Ball
	if hot then
		visual.Color = HOT_COLOR
		stem.Color = if ready then HOT_COLOR else Color3.fromHex(Visuals.palette.daun)
	else
		visual.Color = Color3.fromHex(Visuals.palette[cropToken(cropId)])
		stem.Color = if ready then crop.color else Color3.fromHex(Visuals.palette.daun)
	end
	local tier = Visuals.rarity[tierId or Tiers.default]
	if tier and tier.effect ~= "none" then
		local outline = visual:FindFirstChild("RarityOutline") :: Highlight?
		if not outline then
			outline = Instance.new("Highlight")
			outline.Name = "RarityOutline"
			outline.Adornee = visual
			outline.DepthMode = Enum.HighlightDepthMode.Occluded
			outline.Parent = visual
		end
		outline.FillTransparency = if tierId == "sultan" then 0.62 else 0.78
		local hex = Visuals.palette[tier.token]
		outline.FillColor = Color3.fromHex(hex)
		outline.OutlineColor = Color3.fromHex(hex)
		outline.OutlineTransparency = if tierId == "sultan" then 0 else 0.18
		if tierId == "langka" or tierId == "sultan" then
			local light = visual:FindFirstChild("RarityGlow") :: PointLight?
			if not light then
				light = Instance.new("PointLight")
				light.Name = "RarityGlow"
				light.Parent = visual
			end
			light.Color = Color3.fromHex(hex)
			light.Brightness = if tierId == "sultan" then 1.2 else 0.45
			light.Range = if tierId == "sultan" then 9 else 5
		else
			local light = visual:FindFirstChild("RarityGlow")
			if light then
				light:Destroy()
			end
		end
	else
		for _, name in { "RarityOutline", "RarityGlow" } do
			local effect = visual:FindFirstChild(name)
			if effect then
				effect:Destroy()
			end
		end
	end
	visual.CFrame = tile.CFrame * CFrame.new(0, tile.Size.Y / 2 + size / 2, 0)
	stem.CFrame = tile.CFrame * CFrame.new(0, tile.Size.Y / 2 + size + crown.Y / 2 - 0.2, 0)

	local glow = visual:FindFirstChild("HotGlow") :: PointLight?
	if hot and not glow then
		local light = Instance.new("PointLight")
		light.Name = "HotGlow"
			light.Color = Color3.fromHex(Visuals.palette.daun)
		light.Brightness = 1.4
		light.Range = 9
		light.Parent = visual
	elseif not hot and glow then
		glow:Destroy()
	end
	if ready and tierId == "langka" and not visual:FindFirstChild("LangkaSparkles") then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "LangkaSparkles"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.25, 0.4)
		emitter.Speed = NumberRange.new(0.6, 1.2)
		emitter.SpreadAngle = Vector2.new(120, 120)
		emitter.Color = ColorSequence.new(Color3.fromHex(Visuals.palette.ungu))
		emitter.Parent = visual
		emitter:Emit(Visuals.particles.langka)
	elseif not ready or tierId ~= "langka" then
		local emitter = visual:FindFirstChild("LangkaSparkles")
		if emitter then
			emitter:Destroy()
		end
	end
	if ready and tierId == "sultan" and not visual:FindFirstChild("SultanSparkles") then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SultanSparkles"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.35, 0.55)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Color = ColorSequence.new(Color3.fromHex(Visuals.palette.kunyit))
		emitter.Parent = visual
		emitter:Emit(Visuals.particles.sultan)
	elseif not ready or tierId ~= "sultan" then
		local emitter = visual:FindFirstChild("SultanSparkles")
		if emitter then
			emitter:Destroy()
		end
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
	local visualTier = entry and entry.tier
	tile:SetAttribute("Price", nil)

	if index > data.tilesOwned then
		tile.Color = LOCKED_COLOR
		tile.Transparency = 0.6
		setCropVisual(tile, nil, false, false, nil)
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
		tile:SetAttribute("PlantedAt", nil)
		tile:SetAttribute("GrowSeconds", nil)
		tile:SetAttribute("State", "empty")
		tile:SetAttribute("Crop", nil)
		tile:SetAttribute("ReadyAt", nil)
		tile:SetAttribute("Hot", false)
		setCropVisual(tile, nil, false, false, nil)
		if growing[player] then
			growing[player][index] = nil
		end
		return
	end

	local readyAt = entry.plantedAt + entry.growSeconds
	tile:SetAttribute("PlantedAt", entry.plantedAt)
	tile:SetAttribute("GrowSeconds", entry.growSeconds)
	local ready = os.time() >= readyAt
	tile:SetAttribute("State", if ready then "ready" else "growing")
	tile:SetAttribute("Crop", entry.crop)
	tile:SetAttribute("ReadyAt", readyAt)
	tile:SetAttribute("Hot", entry.hot == true)
	setCropVisual(tile, entry.crop, ready, entry.hot == true, visualTier)
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
	Inventory.takeSeed(data, cropId, 1)
	data.tiles[tileKey(index)] = {
		crop = cropId,
		plantedAt = os.time(),
		growSeconds = FirstSession.getGrowSeconds(player, cropId, data),
		quality = roundQuality(math.clamp(quality + ToolService.plantBonus(data), 0, 1)),
		hot = false,
		harvests = 0,
		fertilised = false,
	}
	EconomyService.sync(player)
	refreshTile(player, data, plot, index)
	Notify.send(player, "n_planted", "@crop_" .. cropId)
	OnboardingService.advance(player, "plant")
	QuestService.progress(player, "plant", 1, cropId)
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

	-- Check seasonal risk events (PLAN §3.3)
	local risks = SeasonsConfig.risks
	if risks then
		-- Banjir in hujan/badai drenching palawija
		if (runtime.cuaca == "hujan" or runtime.cuaca == "badai") and crop.family == "palawija" and math.random() < risks.banjirChance then
			data.tiles[tileKey(index)] = nil
			refreshTile(player, data, plot, index)
			Notify.send(player, "n_crop_banjir", "@crop_" .. entry.crop)
			Analytics.log(player, "risk_banjir", 1)
			return
		end
		-- Hama in pancaroba
		if runtime.musim == "pancaroba" and math.random() < risks.hamaChance then
			data.tiles[tileKey(index)] = nil
			refreshTile(player, data, plot, index)
			Notify.send(player, "n_crop_hama", "@crop_" .. entry.crop)
			Analytics.log(player, "risk_hama", 1)
			return
		end
		-- Gagal panen in El Nino drought
		if runtime.anomali == "elNino" and math.random() < risks.elNinoFailChance then
			data.tiles[tileKey(index)] = nil
			refreshTile(player, data, plot, index)
			Notify.send(player, "n_crop_gagal", "@crop_" .. entry.crop)
			Analytics.log(player, "risk_gagal", 1)
			return
		end
	end
	local traits = TraitService.roll({
		hot = entry.hot == true,
		fertilised = entry.fertilised == true,
		certified = entry.certified == true,
		weather = runtime.cuaca,
		anomaly = runtime.anomali,
	})
	local tier = RarityService.roll(quality)
	tier = FirstSession.getHarvestTier(player, data, tier)
	entry.tier = tier
	Analytics.track(player, "harvest", 1, { entry.crop, tier, destination or "sack" })

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
	checkSeedFloor(player)
	revealHarvest(player, entry.crop, tier, discovery)
	OnboardingService.advance(player, "harvest")
	QuestService.progress(player, "harvest", 1, entry.crop)
	if tier == "sultan" then
		BadgeService.award(player, "first_sultan")
	end
end

local function buyTile(player: Player, data, plot, index: number)
	if index ~= data.tilesOwned + 1 or index > maxTilesFor(player) then
		return
	end
	if not EconomyService.trySpend(player, GameConfig.tilePrice(data.tilesOwned), { sku = "petak" }) then
		return
	end
	data.tilesOwned += 1
	EconomyService.refreshRank(player) -- Juragan needs 12 tiles
	refreshTile(player, data, plot, index)
	refreshTile(player, data, plot, index + 1)
	Notify.send(player, "n_tile_bought")
	checkSeedFloor(player)
end

local function isOwnedAndNear(player: Player, _data, plot, index: number): boolean
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

	local owned = data.tilesOwned
	if type(owned) ~= "number" or owned ~= owned then
		return -- damaged save: never buy or plant against an unknown tile count
	end
	if type(data.tiles) ~= "table" then
		data.tiles = {}
	end

	if index > owned then
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

-- Harness/tests only: run the real plant/harvest resolution without a minigame
-- (docs/testing/HARNESS.md). The prompt path checks ownership and distance before it sets
-- `pending`; callers of this seam do the same. Everything after that is unchanged: canPlant,
-- the empty-tile check, doPlant's grow time and quality, doHarvest's sack and hooks.
function FarmService.commitAttempt(player: Player, attempt: any, quality: any): boolean
	if type(attempt) ~= "table" or type(attempt.tile) ~= "number" then
		return false
	end
	if attempt.action ~= "plant" and attempt.action ~= "harvest" then
		return false
	end
	if type(quality) ~= "number" or quality ~= quality then
		return false
	end
	pending[player] = {
		tile = attempt.tile,
		action = attempt.action,
		cropId = attempt.cropId,
		startedAt = os.clock(),
	}
	return finish(player, math.clamp(quality, 0, 1))
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

-- Exposed for tests; the game calls it from join, harvest and tile purchase.
function FarmService.checkSeedFloor(player: Player): boolean
	return checkSeedFloor(player)
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
	checkSeedFloor(player)

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
