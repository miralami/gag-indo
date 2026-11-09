-- EconomyService: the ONLY code that changes cash, seeds and harvest sacks.
-- Also mirrors those values onto player attributes so the client HUD can read them.
-- Sus / evidence stay out of this module: a cheat sale is reported through a hook that
-- CheatService registers at startup (keeps the dependency graph acyclic).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local Cheats = require(Shared.Config.Cheats)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local RankService = require(script.Parent.Parent.Progression.RankService)
local Village = require(script.Parent.Parent.World.Village)

local EconomyService = {}

local ORDAL_SALE_BONUS = 1.1

-- Set by CheatService.start(): (player, cheatId, value, position) -> ()
local cheatSaleHandler: ((Player, string, number, Vector3) -> ())? = nil

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
	player:SetAttribute("Item_amplopPremium", data.inventory.amplopPremium or 0)
	player:SetAttribute("Item_jaminanKilat", data.inventory.jaminanKilat or 0)
	local bag = 0
	for _, cropId in Crops.order do
		player:SetAttribute("Seed_" .. cropId, data.seeds[cropId] or 0)
		local sack = data.harvest[cropId]
		bag += if sack then sack.count else 0
	end
	player:SetAttribute("HarvestCount", bag)
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

function EconomyService.addHarvest(player: Player, cropId: string, quality: number, hot: boolean)
	local data = PlayerData.get(player)
	if not data or not Crops.list[cropId] then
		return
	end
	local sack = data.harvest[cropId]
	if not sack then
		sack = { count = 0, qualitySum = 0, hotCount = 0, hotQualitySum = 0 }
		data.harvest[cropId] = sack
	end
	sack.hotQualitySum = sack.hotQualitySum or 0
	sack.count += 1
	if hot then
		sack.hotCount = (sack.hotCount or 0) + 1
		sack.hotQualitySum += quality
	else
		sack.qualitySum += quality
	end
	EconomyService.sync(player)
end

-- Confiscated during a raid. Returns how many items were removed.
function EconomyService.removeHotHarvest(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local removed = 0
	for cropId, sack in data.harvest do
		local hot = sack.hotCount or 0
		if hot > 0 then
			removed += hot
			sack.count -= hot
			sack.hotCount = 0
			sack.hotQualitySum = 0
			if sack.count <= 0 then
				data.harvest[cropId] = nil
			end
		end
	end
	if removed > 0 then
		EconomyService.sync(player)
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

	local legalValue = 0
	local hotValue = 0
	for cropId, sack in data.harvest do
		local crop = Crops.list[cropId]
		if crop and sack.count > 0 then
			legalValue += crop.sellPrice * (sack.qualitySum or 0)
			hotValue += crop.sellPrice * (sack.hotQualitySum or 0)
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
		data.harvest = {}
		EconomyService.addCash(player, total, true)
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
	local total = legalValue * multiplier

	for cropId, sack in data.harvest do
		local hot = sack.hotCount or 0
		sack.count -= hot
		sack.qualitySum = 0
		if sack.count <= 0 then
			data.harvest[cropId] = nil
		else
			sack.hotQualitySum = sack.hotQualitySum or 0
		end
	end

	EconomyService.addCash(player, total, true)
	Notify.send(player, "n_sold", math.floor(total))
end

local function onBuySeed(player: Player, cropId: any, amount: any)
	if not RateLimit.allow(player, "Shop_BuySeed", 4) then
		return
	end
	if type(cropId) ~= "string" or type(amount) ~= "number" then
		return
	end
	local crop = Crops.list[cropId]
	if not crop or amount ~= math.floor(amount) or amount < 1 or amount > GameConfig.maxSeedBuy then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if not EconomyService.hasRank(data, crop.rank) then
		Notify.send(player, "n_rank_locked", "@rank_" .. crop.rank)
		return
	end
	if not EconomyService.trySpend(player, crop.seedCost * amount) then
		return
	end
	data.seeds[cropId] = (data.seeds[cropId] or 0) + amount
	EconomyService.sync(player)
	Notify.send(player, "n_bought_seeds", amount, "@crop_" .. cropId)
end

local function onMarketSell(player: Player, _cropId: any, channel: any)
	local resolved = if channel == "gelap" then "gelap" else "pasar"
	EconomyService.sellAll(player, resolved)
end

function EconomyService.start()
	Remotes.Shop_BuySeed.OnServerEvent:Connect(onBuySeed)
	Remotes.Market_Sell.OnServerEvent:Connect(onMarketSell)
	Village.onPasar(function(player, channel)
		EconomyService.sellAll(player, channel)
	end)
	PlayerData.onLoaded(function(player)
		EconomyService.sync(player)
	end)
end

return EconomyService
