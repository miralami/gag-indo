-- ShopService: owns the rotating Toko Bibit shelves (v2 PLAN §3.4).
--
-- Stock is per player and deterministic per restock cycle (shared/ShopStock.luau), so leaving
-- and rejoining can never refresh the shop for free: only the next cycle (or a paid restock,
-- later) changes the shelves. EconomyService owns the cash and the seed bag; this service only
-- decides WHAT is on the shelf and how much of it may be bought.
--
-- Start order: after SeasonService (the shelf depends on today's season) and EconomyService,
-- before State.start() so the first snapshot already carries the stock.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)
local ShopStock = require(Shared.ShopStock)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local SeasonService = require(script.Parent.Parent.Season.SeasonService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)

local ShopService = {}

local RESTOCK_POLL = 2 -- seconds between shelf checks
local BUY_RATE = 4 -- purchases per second per player

local function blank(): { cycle: number, restockAt: number, musim: string, stock: { [string]: number } }
	return { cycle = 0, restockAt = 0, musim = "", stock = {} }
end

-- Mirror the shelves onto player attributes so the HUD updates without waiting for a patch.
local function publish(player: Player, shop)
	player:SetAttribute("ShopRestockAt", shop.restockAt)
	for _, cropId in Crops.order do
		-- nil removes the attribute: the crop is simply not sold this cycle.
		player:SetAttribute("ShopStock_" .. cropId, shop.stock[cropId])
	end
end
ShopService.publish = publish

-- Rolls the shelves when the restock cycle or the season changed. Returns the shop and whether
-- anything changed. Safe to call as often as you like.
function ShopService.ensure(player: Player, data)
	if not data then
		return nil, false
	end
	local shop = data.shop
	if type(shop) ~= "table" then
		shop = blank()
		data.shop = shop
	end
	if type(shop.stock) ~= "table" then
		shop.stock = {}
	end

	local now = os.time()
	local musim = SeasonService.musim()
	local cycle = ShopStock.cycle(now)
	local restockAt = ShopStock.restockAt(cycle)

	local changed = false
	if shop.cycle ~= cycle or shop.musim ~= musim then
		shop.stock = ShopStock.roll(cycle, player.UserId, musim)
		shop.cycle = cycle
		shop.musim = musim
		changed = true
	end
	if shop.restockAt ~= restockAt then
		shop.restockAt = restockAt
		changed = true
	end
	return shop, changed
end

-- The current shelves for one player, rolled if needed. { [cropId] = amount }.
function ShopService.stock(player: Player): { [string]: number }
	local shop = ShopService.ensure(player, PlayerData.get(player))
	return if shop then shop.stock else {}
end

-- Called by the restock loop: refreshes attributes and the replicated section only on change.
function ShopService.tick(player: Player): boolean
	local shop, changed = ShopService.ensure(player, PlayerData.get(player))
	if not shop or not changed then
		return false
	end
	publish(player, shop)
	State.touch(player, "shop")
	return true
end

-- Buy `amount` seeds of `cropId` from today's shelves. Returns true when the purchase went
-- through; every refusal explains itself with a toast.
function ShopService.buy(player: Player, cropId: any, amount: any): boolean
	if not RateLimit.allow(player, "Shop_BuySeed", BUY_RATE) then
		return false
	end
	if type(cropId) ~= "string" or type(amount) ~= "number" then
		return false
	end
	local crop = Crops.list[cropId]
	if not crop or amount ~= math.floor(amount) or amount < 1 or amount > GameConfig.maxSeedBuy then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if not EconomyService.hasRank(data, crop.rank) then
		Notify.send(player, "n_rank_locked", "@rank_" .. crop.rank)
		return false
	end

	local shop = ShopService.ensure(player, data)
	if not shop then
		return false
	end
	local available = shop.stock[cropId]
	if available == nil then
		Notify.send(player, "n_shop_not_stocked", "@crop_" .. cropId)
		return false
	end
	if available < amount then
		if available > 0 then
			Notify.send(player, "n_shop_stock", "@crop_" .. cropId, available)
		else
			Notify.send(player, "n_shop_sold_out", "@crop_" .. cropId)
		end
		return false
	end

	if not EconomyService.buySeed(player, cropId, amount) then
		return false
	end

	shop.stock[cropId] = available - amount
	publish(player, shop)
	State.touch(player, "shop")
	Notify.send(player, "n_bought_seeds", amount, "@crop_" .. cropId)
	return true
end

function ShopService.start()
	Remotes.Shop_BuySeed.OnServerEvent:Connect(function(player, cropId, amount)
		ShopService.buy(player, cropId, amount)
	end)

	PlayerData.onLoaded(function(player)
		local data = PlayerData.get(player)
		if not data then
			return
		end
		local shop = ShopService.ensure(player, data)
		if shop then
			publish(player, shop)
			State.touch(player, "shop")
		end
	end)

	task.spawn(function()
		while true do
			task.wait(RESTOCK_POLL)
			for _, player in Players:GetPlayers() do
				ShopService.tick(player)
			end
		end
	end)
end

return ShopService
