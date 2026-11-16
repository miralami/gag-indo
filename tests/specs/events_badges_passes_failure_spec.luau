--!nocheck
-- Failure-path specs for CabaiEvent, BadgeService and Passes. The cabai event never breaks
-- its multiplier or clock, a BadgeService API error never throws, and a pass check that
-- errors or yields leaves the pass unowned. Tests whose name starts with "[BUG]" are expected
-- to fail; they reveal real defects (see the report that accompanies this spec). Do not edit
-- the modules to make them pass in this file.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	-- ------------------------------------------------------------------ CabaiEvent
	t:describe("CabaiEvent failure paths", function()
		local env, CabaiEvent, GameConfig, notify, liveConfig, onChanged, threads, replicated

		-- CabaiEvent.start() spawns a loop that calls task.wait. The fake task yields the wait
		-- length instead of sleeping, so each loop is a coroutine that wake() advances to its
		-- next wake-up: the clock moves first, then the loop runs, as in Roblox.
		local pending
		local function fakeTask()
			return {
				spawn = function(fn)
					local thread = coroutine.create(fn)
					table.insert(threads, thread)
					local _, seconds = coroutine.resume(thread)
					pending[thread] = seconds or 0
				end,
				wait = function(seconds)
					coroutine.yield(seconds or 0)
				end,
			}
		end

		local function wake()
			for _, thread in threads do
				if coroutine.status(thread) == "suspended" then
					env:advance(pending[thread])
					local _, seconds = coroutine.resume(thread)
					pending[thread] = seconds or 0
				end
			end
		end

		local function setMode(value)
			liveConfig.events.cabai = value
			if onChanged then
				onChanged()
			end
		end

		local function flag()
			return replicated:GetAttribute("CabaiEvent")
		end

		local function countBroadcasts(key)
			local n = 0
			for _, item in notify.broadcasts do
				if item.key == key then
					n += 1
				end
			end
			return n
		end

		t:beforeEach(function()
			env = Env.new()
			threads = {}
			pending = {}
			notify = Fakes.notify()
			liveConfig = { events = { cabai = "auto" } }
			onChanged = nil
			env.globals.task = fakeTask()
			env:mock("server/Live/LiveConfig", {
				get = function()
					return liveConfig
				end,
				onChanged = function(callback)
					onChanged = callback
				end,
			})
			env:mock("server/Net/Notify", notify)
			replicated = env.services.ReplicatedStorage
			GameConfig = env:require("shared/Config/Game")
			CabaiEvent = env:require("server/Events/CabaiEvent")
		end)

		t:it("start called twice announces the event once and ends it once", function()
			CabaiEvent.start()
			CabaiEvent.start()
			wake()
			expect(countBroadcasts("event_cabai_start")):toBe(1)
			wake()
			expect(countBroadcasts("event_cabai_start")):toBe(1)
			expect(countBroadcasts("event_cabai_end")):toBe(1)
			expect(flag()):toBe(false)
		end)

		t:it("a bad admin cabai value is treated as auto and never throws", function()
			CabaiEvent.start()
			for _, bad in { "maybe", "ON", 1, true, "", {} } do
				setMode(bad)
				expect(CabaiEvent.isActive()):toBe(false)
				expect(flag()):toBe(false)
			end
			-- A missing config or a non-table events field also falls back to auto.
			liveConfig = nil
			expect(CabaiEvent.isActive()):toBe(false)
			liveConfig = { events = "on" }
			expect(CabaiEvent.isActive()):toBe(false)
			expect(countBroadcasts("event_cabai_start")):toBe(0)
		end)

		t:it("admin off cuts a running timed event and announces the end once", function()
			CabaiEvent.start()
			wake()
			expect(CabaiEvent.isActive()):toBe(true)
			expect(countBroadcasts("event_cabai_start")):toBe(1)

			setMode("off")
			expect(CabaiEvent.isActive()):toBe(false)
			expect(flag()):toBe(false)
			expect(countBroadcasts("event_cabai_end")):toBe(1)

			-- The loop keeps polling while an admin holds the switch; it must not re-announce.
			wake()
			wake()
			wake()
			expect(CabaiEvent.isActive()):toBe(false)
			expect(countBroadcasts("event_cabai_start")):toBe(1)
			expect(countBroadcasts("event_cabai_end")):toBe(1)
		end)

		t:it("admin on forces the event with no countdown and the timer cannot end it", function()
			CabaiEvent.start()
			setMode("on")
			expect(flag()):toBe(true)
			expect(replicated:GetAttribute("CabaiEventEndsAt")):toBe(0)
			expect(CabaiEvent.multiplier("cabai")):toBe(GameConfig.cabaiEventMultiplier)

			wake()
			wake()
			expect(flag()):toBe(true)
			expect(replicated:GetAttribute("CabaiEventEndsAt")):toBe(0)
			expect(countBroadcasts("event_cabai_end")):toBe(0)
		end)

		t:it("multiplier is finite and applies only to cabai in every mode", function()
			for _, mode in { "auto", "on", "off" } do
				liveConfig.events.cabai = mode
				for _, crop in { "cabai", "padi", "jagung", "", "CABAI" } do
					local m = CabaiEvent.multiplier(crop)
					expect(isFinite(m)):toBe(true)
					if crop == "cabai" and mode == "on" then
						expect(m):toBe(GameConfig.cabaiEventMultiplier)
					else
						expect(m):toBe(1)
					end
				end
				expect(isFinite(CabaiEvent.multiplier(nil))):toBe(true)
				expect(CabaiEvent.multiplier(nil)):toBe(1)
			end
		end)

		t:it("a NaN clock never activates the event or breaks the flag", function()
			local zero = 0
			env.wallTime = zero / zero
			CabaiEvent.start()
			wake()
			expect(CabaiEvent.isActive()):toBe(false)
			expect(flag()):toBe(false)
			expect(replicated:GetAttribute("CabaiEventEndsAt")):toBe(0)
			expect(CabaiEvent.multiplier("cabai")):toBe(1)
			expect(countBroadcasts("event_cabai_start")):toBe(0)
		end)

		t:it("a clock rewind during an event keeps the flag steady and the loop still ends it", function()
			CabaiEvent.start()
			wake()
			expect(countBroadcasts("event_cabai_start")):toBe(1)

			env.wallTime = env.wallTime - 1000
			expect(flag()):toBe(true)
			expect(countBroadcasts("event_cabai_end")):toBe(0)

			wake()
			expect(flag()):toBe(false)
			expect(countBroadcasts("event_cabai_end")):toBe(1)
		end)
	end)

	-- ---------------------------------------------------------------- BadgeService
	t:describe("BadgeService failure paths", function()
		local env, BadgeService, Badges, analytics, api, player
		-- Stub id that only exists inside this test's fake environment; the real config keeps 0.
		local BADGE_ID = 900001

		t:beforeEach(function()
			env = Env.new()
			analytics = Fakes.analytics()
			api = {
				calls = {},
				behavior = function()
					return true
				end,
			}
			env.services.BadgeService = {
				AwardBadge = function(_, userId, badgeId)
					table.insert(api.calls, { userId = userId, badgeId = badgeId })
					return api.behavior(userId, badgeId)
				end,
			}
			env:mock("server/Analytics/Analytics", analytics)
			Badges = env:require("shared/Config/Badges")
			Badges.list.first_raid.id = BADGE_ID
			BadgeService = env:require("server/Progression/BadgeService")
			player = Fakes.player(env)
		end)

		t:it("a throwing BadgeService call returns false and never errors", function()
			api.behavior = function()
				error("Roblox request failed")
			end
			local ok, result = pcall(BadgeService.award, player, "first_raid")
			expect(ok):toBe(true)
			expect(result):toBe(false)
			expect(#analytics.events):toBe(0)
		end)

		t:it("a result that is not exactly true is not counted as an award", function()
			for _, value in { false, "true", 1 } do
				api.behavior = function()
					return value
				end
				expect(BadgeService.award(player, "first_raid")):toBe(false)
			end
			api.behavior = function() end
			expect(BadgeService.award(player, "first_raid")):toBe(false)
			expect(#analytics.events):toBe(0)
		end)

		t:it("a confirmed award logs exactly one badge_awarded event", function()
			expect(BadgeService.award(player, "first_raid")):toBe(true)
			expect(#api.calls):toBe(1)
			expect(api.calls[1].userId):toBe(player.UserId)
			expect(api.calls[1].badgeId):toBe(BADGE_ID)
			expect(#analytics.events):toBe(1)
			expect(analytics.events[1].name):toBe("badge_awarded")
			expect(analytics.events[1].value):toBe(BADGE_ID)
		end)

		t:it("a repeat award is reported false by Roblox and logs nothing new", function()
			-- Roblox answers true the first time and false once the badge is already owned.
			api.behavior = function()
				return #api.calls == 1
			end
			expect(BadgeService.award(player, "first_raid")):toBe(true)
			expect(BadgeService.award(player, "first_raid")):toBe(false)
			expect(#api.calls):toBe(2)
			expect(#analytics.events):toBe(1)
		end)

		t:it("a departed player is not awarded and the API error stays contained", function()
			player.Parent = nil
			api.behavior = function()
				error("User is not in game")
			end
			local ok, result = pcall(BadgeService.award, player, "first_raid")
			expect(ok):toBe(true)
			expect(result):toBe(false)
			expect(#analytics.events):toBe(0)
		end)

		t:it("an unknown, missing or malformed badge key never reaches Roblox", function()
			for _, key in { "nope", "", 42, true, {} } do
				expect(BadgeService.award(player, key)):toBe(false)
			end
			expect(BadgeService.award(player, nil)):toBe(false)
			expect(#api.calls):toBe(0)
		end)

		t:it("a badge still at id 0 or below is skipped without calling Roblox", function()
			Badges.list.kades.id = 0
			Badges.list.debt_free.id = -5
			expect(BadgeService.award(player, "kades")):toBe(false)
			expect(BadgeService.award(player, "debt_free")):toBe(false)
			expect(#api.calls):toBe(0)
			expect(#analytics.events):toBe(0)
		end)
	end)

	-- -------------------------------------------------------------------- Passes
	t:describe("Passes failure paths", function()
		local env, Passes, Products, playerData, notify, marketplace, player, data, owns
		local storagePublished, workerPublished

		local GUDANG_ID = 777
		local AUTO_ID = 888

		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			storagePublished = 0
			workerPublished = 0
			owns = function()
				return false
			end
			marketplace = {
				ownsCalls = 0,
				PromptGamePassPurchaseFinished = env.newSignal(),
			}
			marketplace.UserOwnsGamePassAsync = function(_, userId, passId)
				marketplace.ownsCalls += 1
				return owns(userId, passId)
			end
			env.services.MarketplaceService = marketplace
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Farm/FarmService", { refresh = function() end })
			env:mock("server/Farm/StorageService", {
				publish = function()
					storagePublished += 1
				end,
			})
			env:mock("server/Farm/WorkerService", {
				publish = function()
					workerPublished += 1
				end,
			})
			env:mock("shared/Remotes", Fakes.remotes(env))

			Passes = env:require("server/Monetization/Passes")
			Products = env:require("shared/Config/Products")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("an ownership check that errors leaves that pass unowned and does not stop the others", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			Products.passes.autoPanen.id = AUTO_ID
			owns = function(_, passId)
				if passId == GUDANG_ID then
					error("Roblox request failed")
				end
				return passId == AUTO_ID
			end
			Passes.start()
			local ok = pcall(function()
				playerData.fireLoaded(player, data)
			end)
			expect(ok):toBe(true)
			expect(player:GetAttribute("Pass_GudangBesar")):toBeNil()
			expect(Passes.has(player, "gudangBesar")):toBe(false)
			expect(player:GetAttribute("Pass_AutoPanen")):toBe(true)
			expect(storagePublished):toBe(0)
			expect(workerPublished):toBe(1)
		end)

		t:it("a slow ownership check suspends the load and finishes when Roblox answers", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			owns = function()
				coroutine.yield()
				return true
			end
			local co = coroutine.create(function()
				Passes.start()
				playerData.fireLoaded(player, data)
			end)
			local ok1 = coroutine.resume(co)
			expect(ok1):toBe(true)
			expect(coroutine.status(co)):toBe("suspended")
			expect(player:GetAttribute("Pass_GudangBesar")):toBeNil()

			local ok2 = coroutine.resume(co)
			expect(ok2):toBe(true)
			expect(coroutine.status(co)):toBe("dead")
			expect(player:GetAttribute("Pass_GudangBesar")):toBe(true)
			expect(storagePublished):toBe(1)
		end)

		t:it("a slow ownership check that errors after yielding counts as not owned", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			owns = function()
				coroutine.yield()
				error("Roblox request timed out")
			end
			local co = coroutine.create(function()
				Passes.start()
				playerData.fireLoaded(player, data)
			end)
			coroutine.resume(co)
			local ok2 = coroutine.resume(co)
			expect(ok2):toBe(true)
			expect(coroutine.status(co)):toBe("dead")
			expect(player:GetAttribute("Pass_GudangBesar")):toBeNil()
			expect(storagePublished):toBe(0)
		end)

		t:it("a player who rejoins is checked again, so no stale ownership survives", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			owns = function()
				return true
			end
			Passes.start()
			playerData.fireLoaded(player, data)
			expect(player:GetAttribute("Pass_GudangBesar")):toBe(true)
			expect(marketplace.ownsCalls):toBe(1)

			-- Same UserId on a new Player object; Passes keeps no per-player cache to reuse.
			local again = Fakes.player(env)
			again.UserId = player.UserId
			local againData = playerData.set(again, Fakes.newData(env))
			owns = function()
				return false
			end
			playerData.fireLoaded(again, againData)
			expect(marketplace.ownsCalls):toBe(2)
			expect(again:GetAttribute("Pass_GudangBesar")):toBeNil()
			expect(Passes.has(again, "gudangBesar")):toBe(false)
		end)

		t:it("a finished purchase with a wrong pass id type or an unknown id grants nothing", function()
			Products.passes.autoPanen.id = AUTO_ID
			Passes.start()
			marketplace.PromptGamePassPurchaseFinished:Fire(player, tostring(AUTO_ID), true)
			marketplace.PromptGamePassPurchaseFinished:Fire(player, nil, true)
			marketplace.PromptGamePassPurchaseFinished:Fire(player, AUTO_ID + 1, true)
			expect(player:GetAttribute("Pass_AutoPanen")):toBeNil()
			expect(workerPublished):toBe(0)
			expect(#notify.sent):toBe(0)
		end)

		t:it("a finished purchase grants only the buyer named by the event", function()
			Products.passes.autoPanen.id = AUTO_ID
			Passes.start()
			local other = Fakes.player(env)
			marketplace.PromptGamePassPurchaseFinished:Fire(player, AUTO_ID, true)
			expect(player:GetAttribute("Pass_AutoPanen")):toBe(true)
			expect(other:GetAttribute("Pass_AutoPanen")):toBeNil()
			expect(Passes.has(other, "autoPanen")):toBe(false)
		end)

		t:it("a purchase event for a pass still at id 0 grants nothing", function()
			Passes.start()
			local ok = pcall(function()
				marketplace.PromptGamePassPurchaseFinished:Fire(player, 0, true)
			end)
			expect(ok):toBe(true)
			expect(Passes.has(player, "autoPanen")):toBe(false)
			expect(Passes.has(player, "gudangBesar")):toBe(false)
			expect(player:GetAttribute("Pass_AutoPanen")):toBeNil()
		end)

		t:it("a purchase for a player with no save sets the attribute and publishes nothing", function()
			Products.passes.gudangBesar.id = GUDANG_ID
			Passes.start()
			local noSave = Fakes.player(env)
			local ok = pcall(function()
				marketplace.PromptGamePassPurchaseFinished:Fire(noSave, GUDANG_ID, true)
			end)
			expect(ok):toBe(true)
			expect(noSave:GetAttribute("Pass_GudangBesar")):toBe(true)
			expect(storagePublished):toBe(0)
		end)
	end)
end
