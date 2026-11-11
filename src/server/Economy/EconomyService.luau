-- EconomyService: the ONLY code that changes cash, seeds and the harvest sack.
-- Also mirrors the scalar values onto player attributes so the client HUD can read them,
-- and touches the structured state sections that changed (v2 PLAN §7.1).
-- Sus / evidence stay out of this module: a cheat sale is reported through a hook that
-- CheatService registers at startup (keeps the dependency graph acyclic).

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
local RankService = require(script.Parent.Parent.Progression.RankService)
local OnboardingService = require(script.Parent.Parent.Progression.OnboardingService)
local Village = require(script.Parent.Parent.World.Village)
local CabaiEvent = require(script.Parent.Parent.Events.CabaiEvent)
local MarketService = require(script.Parent.MarketService)

local EconomyService = {}

local ORDAL_SALE_BONUS = 1.1

local saleHook: ((Player, number) -> ())? = nil

function EconomyService.onSale(hook: (Player, number) -> ())
	saleHook = hook
end

function EconomyService.onCheatSale(handler: (Player, string, number, Vector3) -> ())
	cheatSaleHandler = handler
end

local function isFiniteNumber(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function near(player: Player, position: Vector3, maxDistance: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - position).Magnitude <= maxDistance
end
EconomyService.near = near

function EconomyService.hasRank(data, rank: string): boolean
	return (GameConfig.rankIndex[data.rank] or 1) >= (GameConfig.rankIndex[rank] or 1)
end

-- Mirror save data onto attributes (read-only for the client; the server ignores client attributes).
function EconomyService.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.cash)
	player:SetAttribute("LifetimeEarned", data.lifetimeEarned)
	player:SetAttribute("TilesOwned", data.tilesOwned)
	player:SetAttribute("Item_amplopPremium", Inventory.get(data, "amplopPremium"))
	player:SetAttribute("Item_jaminanKilat", Inventory.get(data, "jaminanKilat"))
	for _, cropId in Crops.order do
		player:SetAttribute("Seed_" .. cropId, Inventory.getSeed(data, cropId))
	end
	player:SetAttribute("HarvestCount", Produce.count(data.produce or {}))
end

-- earned = true when this is income (counts toward lifetimeEarned / ranks)
function EconomyService.addCash(player: Player, amount: number, earned: boolean)
	local data = PlayerData.get(player)
	if not data or not isFiniteNumber(amount) or amount <= 0 then
		return
	end
	amount = math.floor(amount)
	data.cash += amount
	if earned then
		data.lifetimeEarned += amount
		RankService.refresh(player)
	end
	EconomyService.sync(player)
end

-- Returns true and deducts if the player can afford it.
function EconomyService.trySpend(player: Player, amount: number): boolean
	local data = PlayerData.get(player)
	if not data or not isFiniteNumber(amount) or amount < 0 then
		return false
	end
	amount = math.floor(amount)
	if data.cash < amount then
		Notify.send(player, "n_not_enough_cash")
		return false
	end
	data.cash -= amount
	EconomyService.sync(player)
	return true
end

-- Move money between two players without minting any (GDD §6).
-- Returns how much actually moved.
function EconomyService.transfer(from: Player, to: Player, amount: number): number
	local fromData = PlayerData.get(from)
	local toData = PlayerData.get(to)
	if not fromData or not toData or not isFiniteNumber(amount) then
		return 0
	end
	local moved = math.clamp(math.floor(amount), 0, fromData.cash)
	if moved <= 0 then
		return 0
	end
	fromData.cash -= moved
	toData.cash += moved
	EconomyService.sync(from)
	EconomyService.sync(to)
	return moved
end

-- Re-check rank requirements that depend on things other than income (e.g. tiles owned).
function EconomyService.refreshRank(player: Player)
	RankService.refresh(player)
	EconomyService.sync(player)
end

-- `options` = { tier = string?, traits = { string }? }. Defaults to a clean, common stack so
-- callers that only know the crop (old tests, admin grants) still work.
function EconomyService.addHarvest(
	player: Player,
	cropId: string,
	quality: number,
	options: { tier: string?, traits: { string }? }?
)
	local data = PlayerData.get(player)
	if not data or not Crops.list[cropId] then
		return
	end
	local opts = options or {}
	data.produce = data.produce or {}
	Produce.add(data.produce, cropId, quality, {
		tier = opts.tier,
		traits = opts.traits,
	})
	EconomyService.sync(player)
	State.touch(player, "produce")
end

-- Confiscated during a raid. Returns how many items were removed.
function EconomyService.removeHotHarvest(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local removed = Produce.removeHot(data.produce or {})
	if removed > 0 then
		EconomyService.sync(player)
		State.touch(player, "produce")
	end
	return removed
end

-- Sell the sack at the Pasar ("pasar") or the Tengkulak Gelap ("gelap").
function EconomyService.sellAll(player: Player, channel: string)
	if not RateLimit.allow(player, "Market_Sell", 2) then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local position = Village.getPosition(if channel == "gelap" then "gelap" else "pasar")
	if not near(player, position, GameConfig.interactDistance) then
		Notify.send(player, "n_too_far")
		return
	end

	local legalValue = 0 -- base value, used by the Tengkulak Gelap
	local marketValue = 0 -- Pasar value after supply and demand
	local hotValue = 0
	local soldCleanCount = 0
	local soldCounts = {}
	for _, stack in data.produce or {} do
		local crop = Crops.list[stack.crop]
		if crop and stack.count > 0 then
			-- Harga Cabai Meroket and the rarity tier multiply the base price. Minigame quality
			-- does not (M1): it nudges the rarity roll instead of the payout.
			local unit = crop.sellPrice * CabaiEvent.multiplier(stack.crop) * Tiers.multiplier(stack.tier)
			if Produce.isHot(stack) then
				hotValue += unit * stack.count
			else
				legalValue += unit * stack.count
				marketValue += unit * stack.count * MarketService.multiplier(stack.crop)
				soldCounts[stack.crop] = (soldCounts[stack.crop] or 0) + stack.count
				soldCleanCount += stack.count
			end
		end
	end

	if channel == "gelap" then
		if legalValue + hotValue <= 0 then
			Notify.send(player, "n_nothing_to_sell")
			return
		end
		local multiplier = Cheats.list.gelap.priceMultiplier or 1.3
		local total = (legalValue + hotValue) * multiplier
		local extra = total - (legalValue + hotValue)
		data.produce = {}
		EconomyService.addCash(player, total, true)
		State.touch(player, "produce")
		Notify.send(player, "n_sold_gelap", math.floor(total))
		if cheatSaleHandler then
			cheatSaleHandler(player, "gelap", math.floor(extra), position)
		end
		return
	end

	-- Pasar: hot (oplosan) produce is refused; only clean produce is sold.
	if legalValue <= 0 then
		Notify.send(player, if hotValue > 0 then "n_hot_pasar" else "n_nothing_to_sell")
		return
	end
	local multiplier = if player:GetAttribute("Pass_Ordal") then ORDAL_SALE_BONUS else 1
	local total = marketValue * multiplier

	-- Clean produce sold; only the hot (oplosan) stacks stay in the sack.
	Produce.removeClean(data.produce or {})
	for cropId, count in soldCounts do
		MarketService.recordSale(cropId, count)
	end

	EconomyService.addCash(player, total, true)
	State.touch(player, "produce")
	Notify.send(player, "n_sold", math.floor(total))
	OnboardingService.advance(player, "sell")
	if saleHook then
		saleHook(player, soldCleanCount)
	end
end

-- Pays for seeds and puts them in the bag. Stock and toasts live in ShopService, which calls
-- this after it has checked today's shelves.
function EconomyService.buySeed(player: Player, cropId: string, amount: number): boolean
	local data = PlayerData.get(player)
	local crop = Crops.list[cropId]
	if not data or not crop then
		return false
	end
	if not isFiniteNumber(amount) or amount ~= math.floor(amount) or amount < 1 or amount > GameConfig.maxSeedBuy then
		return false
	end
	if not EconomyService.hasRank(data, crop.rank) then
		return false
	end
	if not EconomyService.trySpend(player, crop.seedCost * amount) then
		return false
	end
	Inventory.addSeed(data, cropId, amount)
	EconomyService.sync(player)
	State.touch(player, "items")
	return true
end

local function onMarketSell(player: Player, _cropId: any, channel: any)
	local resolved = if channel == "gelap" then "gelap" else "pasar"
	EconomyService.sellAll(player, resolved)
end

function EconomyService.start()
	Remotes.Market_Sell.OnServerEvent:Connect(onMarketSell)
	Village.onPasar(function(player, channel)
		EconomyService.sellAll(player, channel)
	end)
	PlayerData.onLoaded(function(player)
		EconomyService.sync(player)
	end)
end

return EconomyService
