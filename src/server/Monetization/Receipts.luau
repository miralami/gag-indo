-- Receipts: the ONLY place developer products are granted (TECH.md §7).
-- Grant + record the PurchaseId in one step, then acknowledge only after a save that
-- contains that PurchaseId has been confirmed.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Products = require(Shared.Config.Products)
local Inventory = require(Shared.Inventory)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local ShopService = require(script.Parent.Parent.Economy.ShopService)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local Receipts = {}

-- Returns false when the grant type is unknown, so the receipt is never acknowledged for nothing.
local function applyGrant(player: Player, data, product, productKey: string): boolean
	if product.grant == "inventory" then
		Inventory.add(data, product.item, product.amount or 1)
	elseif product.grant == "seeds" then
		for cropId, amount in product.seeds or {} do
			Inventory.addSeed(data, cropId, amount)
		end
	elseif product.grant == "restock" then
		ShopService.restockNow(player, data)
	elseif product.grant == "cash" then
		-- Purchased cash is not income: it must not raise rank or the leaderboard.
		local cash = tonumber(product.cash) or 0
		if cash > 0 then
			EconomyService.addCash(player, cash, false, { sku = productKey, transaction = "IAP" })
		end
	else
		warn("[Receipts] Unknown grant type", tostring(product.grant))
		return false
	end
	return true
end

function Receipts.start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local profile = PlayerData.getProfile(player)
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local data = profile.Data
		if receiptInfo.PurchaseId == nil then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- cannot be deduplicated
		end
		if type(data.receipts) ~= "table" then
			data.receipts = {}
		end

		if table.find(data.receipts, receiptInfo.PurchaseId) then
			-- Already granted in memory, but an earlier attempt may have failed to save.
			-- Never acknowledge until a save containing this PurchaseId is confirmed, or a paid
			-- purchase can be lost on the next crash with no retry left. Do not re-grant or
			-- re-notify: a normal replay still grants/notifies exactly once.
			if PlayerData.saveAndConfirm(profile, receiptInfo.PurchaseId, 15) then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local productKey = Products.productKeyForId(receiptInfo.ProductId)
		if not productKey then
			warn("[Receipts] Unknown product", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local product = Products.products[productKey]

		-- Grant AND record the PurchaseId in the same step (no yield in between),
		-- so a retry after a crash sees the ID and doesn't grant twice.
		if not applyGrant(player, data, product, productKey) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		table.insert(data.receipts, receiptInfo.PurchaseId)
		if #data.receipts > 50 then
			table.remove(data.receipts, 1)
		end
		EconomyService.sync(player)
		State.touch(player, "items")

		-- Acknowledge ONLY after a save containing this PurchaseId succeeded.
		if not PlayerData.saveAndConfirm(profile, receiptInfo.PurchaseId, 15) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		Notify.send(player, "n_purchase", "@item_" .. productKey)
		Analytics.track(player, "purchase", 1, { productKey })
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Receipts
