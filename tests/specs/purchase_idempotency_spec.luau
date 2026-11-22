--!nocheck
-- WORK_QUEUE item 14: purchase receipt idempotency. Other specs cover each isolated failure
-- (duplicate PurchaseId, failed save, unknown product, erroring game-pass check); this one drives
-- the REAL PlayerData + Receipts together with a fake ProfileStore to prove the durable outcome:
-- a Robux purchase is granted at most once in the saved profile and acknowledged only after a save
-- containing its PurchaseId is confirmed. Product IDs below are synthetic test integers, never
-- real Roblox IDs (shipped config keeps every id at 0 until the designer creates them).
--
-- Cases mirrored here for the end-to-end proof: duplicate PurchaseId, player leaving mid-grant,
-- failed save after grant, unknown product, and an erroring game-pass ownership check.

return function(t, Env, Fakes)
	local expect = t.expect

	local PRODUCT_ID = 111 -- synthetic, not a real product
	local PASS_ID = 777 -- synthetic, not a real pass

	local function makeWorld()
		local env = Env.new()
		local factory = function() return nil end
		local store = {}
		function store.StartSessionAsync(_, key, opts)
			return factory()
		end
		env:mock("server/Packages/ProfileStore", { New = function() return store end })

		local notify, analytics = Fakes.notify(), Fakes.analytics()
		local economy = { syncCalls = 0, cashAdded = {} }
		function economy.sync() economy.syncCalls += 1 end
		function economy.addCash(_, amount, earned)
			table.insert(economy.cashAdded, { amount = amount, earned = earned })
		end
		env:mock("server/Net/Notify", notify)
		env:mock("server/Analytics/Analytics", analytics)
		env:mock("server/Economy/EconomyService", economy)
		env:mock("server/Economy/ShopService", { restockNow = function() return true end })
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Farm/FarmService", { refresh = function() end })
		env:mock("server/Farm/StorageService", { publish = function() end })
		env:mock("server/Farm/WorkerService", { publish = function() end })
		env:mock("shared/Remotes", Fakes.remotes(env))

		local Products = env:require("shared/Config/Products")
		Products.products.amplopPremium.id = PRODUCT_ID
		Products.byProductId[PRODUCT_ID] = { key = "amplopPremium", product = Products.products.amplopPremium }
		Products.passes.extraPlot.id = PASS_ID

		local PlayerData = env:require("server/Data/PlayerData")
		PlayerData.start()

		local marketplace = { ProcessReceipt = nil, PromptGamePassPurchaseFinished = env.newSignal() }
		env.services.MarketplaceService = marketplace
		local Receipts = env:require("server/Monetization/Receipts")
		Receipts.start()

		return {
			env = env, PlayerData = PlayerData, notify = notify, analytics = analytics,
			marketplace = marketplace, economy = economy, Products = Products,
			setProfile = function(fn) factory = fn end,
			process = function(info) return marketplace.ProcessReceipt(info) end,
		}
	end

	local function makeProfile(env, data)
		local p = {
			Data = data, _active = true, OnAfterSave = env.newSignal(),
			OnSessionEnd = env.newSignal(), saves = 0,
		}
		function p:IsActive() return self._active end
		function p:AddUserId() end
		function p:Reconcile() end
		function p:Save()
			self.saves += 1
			self.OnAfterSave:Fire(self.Data) -- a successful save contains the current data
		end
		function p:EndSession()
			self._active = false
			self.OnSessionEnd:Fire()
		end
		return p
	end

	local function loadPlayer(w, profile)
		w.setProfile(function() return profile end)
		local player = Fakes.player(w.env)
		w.env.services.Players.PlayerAdded:Fire(player)
		return player
	end

	local function receipt(player, productId)
		return { PlayerId = player.UserId, PurchaseId = "P-1", ProductId = productId or PRODUCT_ID }
	end

	t:describe("purchase idempotency, end to end (item 14)", function()
		t:it("a duplicate PurchaseId grants and notifies exactly once", function()
			local w = makeWorld()
			local data = Fakes.newData(w.env)
			data.receipts = {}
			local profile = makeProfile(w.env, data)
			local player = loadPlayer(w, profile)

			expect(w.process(receipt(player))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(w.process(receipt(player))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(data.items.amplopPremium):toBe(1)
			expect(#data.receipts):toBe(1)
			expect(#w.notify.sent):toBe(1)
			expect(#w.analytics.events):toBe(1)
		end)

		t:it("a player who leaves mid-grant is not acknowledged; a retry after rejoin grants once", function()
			local w = makeWorld()
			local data = Fakes.newData(w.env)
			data.receipts = {}
			local profile = makeProfile(w.env, data)
			-- The save fires OnAfterSave (confirming) but the session ends before the bounded wait
			-- closes: saveAndConfirm returns false, so Roblox must retry rather than be acknowledged.
			profile.Save = function(self)
				self.saves += 1
				self.OnAfterSave:Fire(self.Data)
				self._active = false -- leave between grant and acknowledgement
			end
			local player = loadPlayer(w, profile)

			expect(w.process(receipt(player))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(#w.notify.sent):toBe(0)
			-- Simulate the engine removing the departing player from Players. The fake service's
			-- PlayerRemoving signal does not do this on its own, so without this GetPlayerByUserId
			-- would keep returning the stale player with its released profile.
			local playersService = w.env.services.Players
			local index = table.find(playersService._players, player)
			if index then
				table.remove(playersService._players, index)
			end
			playersService.PlayerRemoving:Fire(player)
			-- The durable save that survives the leave never contained the receipt, so on rejoin the
			-- profile is fresh: a retry must grant once, not zero times and not twice.
			local againData = Fakes.newData(w.env)
			againData.receipts = {}
			local againProfile = makeProfile(w.env, againData)
			local again = loadPlayer(w, againProfile)
			again.UserId = player.UserId

			expect(w.process(receipt(again))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(againData.items.amplopPremium):toBe(1)
			expect(#againData.receipts):toBe(1)
			expect(#w.notify.sent):toBe(1)
		end)

		t:it("a failed save after grant is not acknowledged and a retry never double-grants", function()
			local w = makeWorld()
			local data = Fakes.newData(w.env)
			data.receipts = {}
			local profile = makeProfile(w.env, data)
			local saveAttempts = 0
			profile.Save = function()
				saveAttempts += 1
				error("DataStore down")
			end
			local player = loadPlayer(w, profile)

			expect(w.process(receipt(player))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(#w.notify.sent):toBe(0)
			expect(data.items.amplopPremium):toBe(1) -- grant is in memory
			expect(#data.receipts):toBe(1) -- PurchaseId recorded before the save
			-- The grant and PurchaseId are in memory but no save succeeded. Once saving works the
			-- retry hits the dedup path; it must RE-CONFIRM a save before acknowledging (BUG-016).
			profile.Save = function(self)
				saveAttempts += 1
				self.OnAfterSave:Fire(self.Data)
			end
			expect(w.process(receipt(player))):toBe("ProductPurchaseDecision.PurchaseGranted")
			expect(saveAttempts):toBe(2) -- the dedup retry actually re-saved, not just early-returned
			expect(data.items.amplopPremium):toBe(1) -- still exactly one grant
			expect(#data.receipts):toBe(1) -- still exactly one recorded id
		end)

		t:it("an unknown product is never acknowledged, granted or recorded", function()
			local w = makeWorld()
			local data = Fakes.newData(w.env)
			data.receipts = {}
			local player = loadPlayer(w, makeProfile(w.env, data))

			expect(w.process(receipt(player, 999999))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(data.items.amplopPremium):toBe(0)
			expect(#data.receipts):toBe(0)
			expect(#w.notify.sent):toBe(0)
			-- placeholder id 0 (the shipped default) is likewise never a real purchase
			expect(w.process(receipt(player, 0))):toBe("ProductPurchaseDecision.NotProcessedYet")
			expect(#data.receipts):toBe(0)
		end)

		t:it("a game-pass ownership check that errors grants nothing, however often it is retried", function()
			local w = makeWorld()
			w.marketplace.UserOwnsGamePassAsync = function()
				error("Roblox request failed")
			end
			local Passes = w.env:require("server/Monetization/Passes")
			Passes.start()
			-- Each load fires the real PlayerData.onLoaded → Passes.checkPasses; none may grant.
			for _ = 1, 3 do
				local data = Fakes.newData(w.env)
				local player = loadPlayer(w, makeProfile(w.env, data))
				expect(player:GetAttribute("Pass_ExtraPlot")):toBeNil()
				expect(Passes.has(player, "extraPlot")):toBe(false)
			end
		end)
	end)
end
