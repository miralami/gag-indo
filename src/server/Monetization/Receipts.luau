-- Receipts: the ONLY place developer products are granted (TECH.md §7).
-- Grant + record the PurchaseId in one step, then acknowledge only after a save that
-- contains that PurchaseId has been confirmed.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Products = require(Shared.Config.Products)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local Receipts = {}

local function applyGrant(data, product)
	if product.grant == "inventory" then
		data.inventory[product.item] = (data.inventory[product.item] or 0) + (product.amount or 1)
	elseif product.grant == "seeds" then
		for cropId, amount in product.seeds or {} do
			data.seeds[cropId] = (data.seeds[cropId] or 0) + amount
		end
	end
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

		if table.find(data.receipts, receiptInfo.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
		end

		local productKey = Products.productKeyForId(receiptInfo.ProductId)
		if not productKey then
			warn("[Receipts] Unknown product", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local product = Products.products[productKey]

		-- Grant AND record the PurchaseId in the same step (no yield in between),
		-- so a retry after a crash sees the ID and doesn't grant twice.
		applyGrant(data, product)
		table.insert(data.receipts, receiptInfo.PurchaseId)
		if #data.receipts > 50 then
			table.remove(data.receipts, 1)
		end
		EconomyService.sync(player)

		-- Acknowledge ONLY after a save containing this PurchaseId succeeded.
		if not PlayerData.saveAndConfirm(profile, receiptInfo.PurchaseId, 15) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		Notify.send(player, "n_purchase", "@item_" .. productKey)
		Analytics.log(player, "purchase", 1)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Receipts
