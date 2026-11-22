--!nocheck
-- OnboardingService and Receipts failure-path specs.
-- Receipts is money-critical: an unknown, unloaded or erroring purchase never grants, a replayed
-- PurchaseId grants once, and a damaged save never makes ProcessReceipt throw.
-- Onboarding: out-of-order, repeated, malformed or departed-player calls change nothing and
-- reward exactly once. Tests whose name starts with "[BUG]" are expected to fail: they reveal
-- real defects in src/server/Monetization/Receipts.luau. Do not edit the modules to make them pass.
-- Product ids here are obviously fake (9001xx) and are only set inside the test environment.

return function(t, Env, Fakes)
	local expect = t.expect

	local FAKE_IDS = {
		amplopPremium = 900101,
		karungBibit = 900102,
		restockToko = 900103,
		rupiahKecil = 900104,
	}

	local function countKey(list, key)
		local count = 0
		for _, value in list do
			if value == key then
				count += 1
			end
		end
		return count
	end

	t:describe("Receipts failure paths", function()
		local env, playerData, notify, analytics, marketplace, economy, shop, player, data, Receipts

		local function process(info)
			return marketplace.ProcessReceipt(info)
		end

		local function receipt(purchaseId, productId)
			return { PlayerId = player.UserId, PurchaseId = purchaseId, ProductId = productId or FAKE_IDS.amplopPremium }
		end

		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()
			marketplace = { ProcessReceipt = nil }
			env.services.MarketplaceService = marketplace

			economy = { failCash = false, added = {}, syncs = 0 }
			shop = { restocks = 0 }

			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Analytics/Analytics", analytics)
			env:mock("server/Economy/EconomyService", {
				sync = function()
					economy.syncs += 1
				end,
				addCash = function(_, amount)
					if economy.failCash then
						error("datastore offline")
					end
					table.insert(economy.added, amount)
				end,
			})
			env:mock("server/Economy/ShopService", {
				restockNow = function()
					shop.restocks += 1
					return true
				end,
			})
			env:mock("shared/Remotes", Fakes.remotes(env))

			-- Fake, non-zero ids so the products are "configured" for this test only.
			local Products = env:require("shared/Config/Products")
			for key, id in FAKE_IDS do
				Products.products[key].id = id
				Products.byProductId[id] = { key = key, product = Products.products[key] }
			end
			Products.products.rupiahKecil.cash = 2500

			Receipts = env:require("server/Monetization/Receipts")
			Receipts.start()

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("keeps a purchase unrecorded when its grant errors, then grants it once on retry", function()
			economy.failCash = true
			local ok = pcall(process, receipt("p1", FAKE_IDS.rupiahKecil))
			expect(ok):toBe(false)
			expect(#data.receipts):toBe(0)
			expect(#notify.keys(player)):toBe(0)
			expect(#analytics.events):toBe(0)

			economy.failCash = false
			expect(process(receipt("p1", FAKE_IDS.rupiahKecil))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(#economy.added):toBe(1)
			expect(economy.added[1]):toBe(2500)
			expect(data.receipts[1]):toBe("p1")
		end)

		t:it("a product with an unknown grant type is not acknowledged as granted", function()
			-- Receipts.luau applyGrant: the `else` branch only warns, then the PurchaseId is recorded
			-- and PurchaseGranted is returned. The player is charged and receives nothing.
			local Products = env:require("shared/Config/Products")
			Products.products.amplopPremium.grant = "mystery"
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(data.items.amplopPremium):toBe(0)
		end)

		t:it("a damaged receipts table (nil) does not error and is repaired", function()
			-- Receipts.luau line 52: table.find(data.receipts, ...) throws when receipts is nil.
			data.receipts = nil
			local ok = pcall(process, receipt("p1"))
			expect(ok):toBe(true)
			expect(type(data.receipts)):toBe("table")
		end)

		t:it("a damaged receipts value (non-table) does not error and is repaired", function()
			-- Same line 52 / line 66 path: a string or number is not a table, so table.find throws.
			data.receipts = "junk"
			local ok = pcall(process, receipt("p1"))
			expect(ok):toBe(true)
			expect(type(data.receipts)):toBe("table")
		end)

		t:it("a receipt without a PurchaseId grants nothing", function()
			-- Receipts.luau line 52 and 66 accept a nil PurchaseId: nothing can dedup it, so every
			-- retry would grant again. Roblox always sends one; this guards against a malformed call.
			local decision = process({ PlayerId = player.UserId, ProductId = FAKE_IDS.amplopPremium })
			expect(decision):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(data.items.amplopPremium):toBe(0)
		end)

		t:it("replayed receipts reward and notify exactly once", function()
			process(receipt("p1"))
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(process(receipt("p1"))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(data.items.amplopPremium):toBe(1)
			expect(countKey(notify.keys(player), "n_purchase")):toBe(1)
			expect(#analytics.events):toBe(1)
			expect(analytics.events[1].name):toBe("purchase")
		end)

		t:it("malformed receipt info waits and never grants or throws", function()
			local malformed = {
				{ PlayerId = "abc", PurchaseId = "p1", ProductId = FAKE_IDS.amplopPremium },
				{ PlayerId = player.UserId, PurchaseId = "p1", ProductId = tostring(FAKE_IDS.amplopPremium) },
				{ PlayerId = player.UserId, PurchaseId = "p1", ProductId = nil },
				{ PlayerId = player.UserId, PurchaseId = "p1", ProductId = 0 },
			}
			for _, info in malformed do
				local ok, decision = pcall(process, info)
				expect(ok):toBe(true)
				expect(decision):toBe("ProductPurchaseDecision.NotProcessedYet")
			end
			expect(data.items.amplopPremium):toBe(0)
			expect(#data.receipts):toBe(0)
			expect(#notify.keys(player)):toBe(0)
		end)
	end)

	t:describe("OnboardingService failure paths", function()
		local env, Onboarding, OnboardingService, playerData, notify, analytics, player, data

		t:beforeEach(function()
			env = Env.new()
			Onboarding = env:require("shared/Config/Onboarding")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Analytics/Analytics", analytics)

			OnboardingService = env:require("server/Progression/OnboardingService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("out-of-order steps change nothing and send no toast or analytics", function()
			expect(OnboardingService.advance(player, "harvest")):toBe(false)
			expect(OnboardingService.advance(player, "buy")):toBe(false)
			expect(data.tutorial.step):toBe(1)
			expect(next(data.tutorial.done)):toBeNil()
			expect(#notify.keys(player)):toBe(0)
			expect(#analytics.funnelSteps):toBe(0)
		end)

		t:it("repeating a completed step does nothing the second time", function()
			expect(OnboardingService.advance(player, "plant")):toBe(true)
			expect(OnboardingService.advance(player, "plant")):toBe(false)
			expect(data.tutorial.step):toBe(2)
			expect(countKey(notify.keys(player), "n_tutorial_step")):toBe(1)
			expect(#analytics.funnelSteps):toBe(1)
		end)

		t:it("rewards each step and the finish exactly once, even when called again after completion", function()
			OnboardingService.advance(player, "plant")
			OnboardingService.advance(player, "harvest")
			OnboardingService.advance(player, "sell")
			OnboardingService.advance(player, "buy")
			expect(#analytics.funnelSteps):toBe(Onboarding.total + 1)
			expect(analytics.funnelSteps[Onboarding.total + 1].name):toBe("finished")
			expect(countKey(notify.keys(player), "n_tutorial_finished")):toBe(1)

			expect(OnboardingService.advance(player, "buy")):toBe(false)
			expect(OnboardingService.advance(player, "plant")):toBe(false)
			expect(#analytics.funnelSteps):toBe(Onboarding.total + 1)
			expect(countKey(notify.keys(player), "n_tutorial_finished")):toBe(1)
		end)

		t:it("bad remote step arguments are refused without error or state change", function()
			local bad = { 42, true, "", "PLANT", {}, 0 / 0, function() end }
			for _, value in bad do
				local ok, result = pcall(OnboardingService.advance, player, value)
				expect(ok):toBe(true)
				expect(result):toBe(false)
			end
			local ok, result = pcall(OnboardingService.advance, player, nil)
			expect(ok):toBe(true)
			expect(result):toBe(false)
			expect(data.tutorial.step):toBe(1)
			expect(#notify.keys(player)):toBe(0)
		end)

		t:it("a missing or non-table tutorial is rebuilt and the first step still works", function()
			for _, damaged in { "junk", 7, true } do
				data.tutorial = damaged
				expect(OnboardingService.advance(player, "plant")):toBe(true)
				expect(data.tutorial.done.plant):toBe(true)
				expect(data.tutorial.step):toBe(2)
			end

			data.tutorial = nil
			expect(OnboardingService.ensure(data).step):toBe(1)
			expect(OnboardingService.advance(player, "plant")):toBe(true)
		end)

		t:it("a damaged step (NaN, infinite, negative, fractional, text) is repaired and keeps completed steps", function()
			local bad = { 0 / 0, math.huge, -math.huge, -3, 2.5, "x" }
			for _, value in bad do
				data.tutorial = { step = value, done = { plant = true } }
				local tutorial = OnboardingService.ensure(data)
				expect(tutorial.step == tutorial.step):toBe(true)
				expect(tutorial.step >= 1 and tutorial.step <= Onboarding.total + 1):toBe(true)
				expect(tutorial.done.plant):toBe(true)
			end
		end)

		t:it("a departed player (no live data) is refused without error or toast", function()
			playerData.get = function()
				return nil
			end
			local ok, result = pcall(OnboardingService.advance, player, "plant")
			expect(ok):toBe(true)
			expect(result):toBe(false)
			expect(#notify.keys(player)):toBe(0)
			expect(#analytics.funnelSteps):toBe(0)
		end)

		t:it("loading a save with a damaged tutorial publishes a valid step", function()
			data.tutorial = { step = 0 / 0, done = "junk" }
			OnboardingService.start()
			playerData.fireLoaded(player, data)
			expect(type(data.tutorial.done)):toBe("table")
			expect(data.tutorial.step):toBe(1)
			expect(player:GetAttribute("TutorialStep")):toBe("plant")
		end)
	end)
end
