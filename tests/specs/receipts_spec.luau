--!nocheck
-- Robux purchases: a double grant or a lost grant is a real-money bug, so this is tested hard.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, playerData, notify, analytics, marketplace, player, data, shop, economy

	local AMPLOP_ID = 111
	local BIBIT_ID = 222
	local RESTOCK_ID = 333
	local CASH_ID = 444

	local function receipt(purchaseId, productId)
		return { PlayerId = player.UserId, PurchaseId = purchaseId, ProductId = productId or AMPLOP_ID }
	end

	local function process(info)
		return marketplace.ProcessReceipt(info)
	end

	t:describe("Receipts", function()
		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()
			marketplace = { ProcessReceipt = nil }
			env.services.MarketplaceService = marketplace

			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Analytics/Analytics", analytics)
			economy = {
				sync = function() end,
				cashAdded = {},
				addCash = function(_, amount, earned)
					table.insert(economy.cashAdded, { amount = amount, earned = earned })
				end,
			}
			shop = {
				restocks = 0,
				restockNow = function()
					shop.restocks += 1
					return true
				end,
			}
			env:mock("server/Economy/EconomyService", economy)
			env:mock("server/Economy/ShopService", shop)
			env:mock("shared/Remotes", Fakes.remotes(env))

			-- Configure products (the real config ships with id 0 = not configured).
			local Products = env:require("shared/Config/Products")
			Products.products.amplopPremium.id = AMPLOP_ID
			Products.products.karungBibit.id = BIBIT_ID
			Products.products.restockToko.id = RESTOCK_ID
			Products.products.rupiahKecil.id = CASH_ID
			Products.products.rupiahKecil.cash = 2500
			Products.byProductId[AMPLOP_ID] = { key = "amplopPremium", product = Products.products.amplopPremium }
			Products.byProductId[BIBIT_ID] = { key = "karungBibit", product = Products.products.karungBibit }
			Products.byProductId[RESTOCK_ID] = { key = "restockToko", product = Products.products.restockToko }
			Products.byProductId[CASH_ID] = { key = "rupiahKecil", product = Products.products.rupiahKecil }

			local Receipts = env:require("server/Monetization/Receipts")
			Receipts.start()

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("grants an inventory item and acknowledges the purchase", function()
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(data.items.amplopPremium):toBe(1)
			expect(notify.keys(player)):toContain("n_purchase")
		end)

		t:it("grants seed bundles", function()
			local Products = env:require("shared/Config/Products")
			local Inventory = env:require("shared/Inventory")
			local before = Inventory.getSeed(data, "padi")
			process(receipt("p1", BIBIT_ID))
			expect(Inventory.getSeed(data, "padi")):toBe(before + Products.products.karungBibit.seeds.padi)
			expect(Inventory.getSeed(data, "cabai")):toBe(Products.products.karungBibit.seeds.cabai)
		end)

		t:it("records the PurchaseId before acknowledging", function()
			process(receipt("p1"))
			expect(data.receipts):toContain("p1")
			expect(playerData.saveCalls[1].purchaseId):toBe("p1")
		end)

		t:it("does not grant twice when Roblox retries the same purchase", function()
			process(receipt("p1"))
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(data.items.amplopPremium):toBe(1)
		end)

		t:it("grants each distinct purchase", function()
			process(receipt("p1"))
			process(receipt("p2"))
			expect(data.items.amplopPremium):toBe(2)
		end)

		t:it("does not acknowledge when the save is not confirmed, so Roblox retries", function()
			playerData.confirmSaves = false
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(#notify.keys(player)):toBe(0)
		end)

		t:it("does not double-grant when the retry follows an unconfirmed save", function()
			playerData.confirmSaves = false
			process(receipt("p1"))
			playerData.confirmSaves = true
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(data.items.amplopPremium):toBe(1)
		end)

		t:it("waits (NotProcessedYet) when the buyer is not in the server", function()
			local ghost = { PlayerId = 424242, PurchaseId = "p1", ProductId = AMPLOP_ID }
			expect(process(ghost)):toBe("ProductPurchaseDecision.NotProcessedYet")
		end)

		t:it("waits when the buyer's data is not loaded yet", function()
			local early = Fakes.player(env)
			local info = { PlayerId = early.UserId, PurchaseId = "p1", ProductId = AMPLOP_ID }
			expect(process(info)):toBe("ProductPurchaseDecision.NotProcessedYet")
		end)

		t:it("does not grant an unknown product", function()
			expect(process(receipt("p1", 999999))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(data.items.amplopPremium):toBe(0)
			expect(#data.receipts):toBe(0)
		end)

		t:it("never treats the placeholder id 0 as a real Roblox purchase", function()
			-- Every product ships with id 0 until the designer creates it in the dashboard.
			expect(process(receipt("p0", 0))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(data.items.amplopPremium):toBe(0)
			expect(#data.receipts):toBe(0)
			expect(#notify.keys(player)):toBe(0)
		end)

		t:it("restocks the shop once per purchase", function()
			expect(process(receipt("p1", RESTOCK_ID))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(shop.restocks):toBe(1)
			process(receipt("p1", RESTOCK_ID))
			expect(shop.restocks):toBe(1)
		end)

		t:it("grants cash without counting it as earned income", function()
			expect(process(receipt("p1", CASH_ID))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(#economy.cashAdded):toBe(1)
			expect(economy.cashAdded[1].amount):toBe(2500)
			expect(economy.cashAdded[1].earned):toBe(false)
		end)

		t:it("grants no cash while a pack has no price yet", function()
			local Products = env:require("shared/Config/Products")
			Products.products.rupiahKecil.cash = 0
			expect(process(receipt("p1", CASH_ID))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(#economy.cashAdded):toBe(0)
			expect(data.receipts):toContain("p1")
		end)

		t:it("remembers only the latest 50 purchase ids", function()
			for index = 1, 55 do
				process(receipt("p" .. index))
			end
			expect(#data.receipts):toBe(50)
			expect(data.receipts[1]):toBe("p6")
			expect(data.receipts[50]):toBe("p55")
		end)
	end)
end
