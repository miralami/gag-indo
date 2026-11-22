--!nocheck
-- WORK_QUEUE item 12: server cleanup on PlayerRemoving. Several leave handlers were already
-- covered in other specs (raid fine via resolveOnLeave, FarmService pending/growing, PlotService,
-- RateLimit buckets, PlayerData mid-load release, leaderboard record with a vanished save). These
-- lock the handlers that had no spec: the debt collector NPC, the IsAdmin attribute, the final
-- leaderboard flush, the harness gate, evidence offers/tokens, and the Net/State release hook.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	-- -----------------------------------------------------------------------------------------
	-- DebtService: the summon Pinjol collector is an in-memory NPC and must be dismissed when
	-- its owner leaves, or it lingers in the world with no player to harass.
	-- -----------------------------------------------------------------------------------------
	local function makeDebt()
		local env = Env.new()
		env.globals.task.spawn = function() end -- start() owns an interest loop
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Economy/EconomyService", {})
		env:mock("server/Progression/RankService", {})
		env:mock("server/Farm/StorageService", {})
		env:mock("server/Progression/BadgeService", {})
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/World/Village", {
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onPasar = function() end,
		})

		local DebtService = env:require("server/Economy/DebtService")
		local collector = { dismissed = {} }
		function collector.summon() end
		function collector.dismiss(player)
			table.insert(collector.dismissed, player)
		end
		DebtService.bindRaid({ isBusy = function() return false end })
		DebtService.bindCollector(collector)
		DebtService.start()

		local player = Fakes.player(env)
		playerData.set(player, Fakes.newData(env))
		return { env = env, DebtService = DebtService, collector = collector, player = player }
	end

	t:describe("leave cleanup: debt collector NPC (item 12)", function()
		t:it("dismisses the collector when the borrower leaves", function()
			local fx = makeDebt()
			fx.env.services.Players.PlayerRemoving:Fire(fx.player)
			expect(#fx.collector.dismissed):toBe(1)
			expect(fx.collector.dismissed[1]):toBe(fx.player)
		end)

		t:it("is safe when no collector is bound", function()
			local env = Env.new()
			env.globals.task.spawn = function() end
			env:mock("server/Data/PlayerData", Fakes.playerData())
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Net/Notify", Fakes.notify())
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Net/State", { touch = function() end })
			env:mock("server/Economy/EconomyService", {})
			env:mock("server/Progression/RankService", {})
			env:mock("server/Farm/StorageService", {})
			env:mock("server/Progression/BadgeService", {})
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/World/Village", { getPosition = function() return env.Vector3.new(0, 0, 0) end })
			local DebtService = env:require("server/Economy/DebtService")
			DebtService.bindRaid({ isBusy = function() return false end })
			DebtService.start()
			local player = Fakes.player(env)
			expect(function()
				env.services.Players.PlayerRemoving:Fire(player)
			end).never:toThrow()
		end)
	end)

	-- -----------------------------------------------------------------------------------------
	-- AdminService: IsAdmin is an attribute on the player. On leave it must be cleared so a
	-- reused UserId in a later session never inherits an admin flag from a departed player.
	-- -----------------------------------------------------------------------------------------
	local function makeAdmin()
		local env = Env.new()
		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		local adminIds = {}
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Economy/EconomyService", { sync = function() end, addCash = function() end })
		env:mock("server/Live/LiveConfig", {
			get = function() return { seasonOverride = "auto", anomaly = "none" } end,
			getRuntime = function() return { musim = "kemarau", anomali = "none" } end,
			update = function() end,
			refresh = function() end,
		})
		env:mock("server/Live/Admins", {
			isAdmin = function(userId) return adminIds[userId] == true end,
		})
		local AdminService = env:require("server/Live/AdminService")
		AdminService.start()
		local admin = Fakes.player(env, { name = "Admin" })
		adminIds[admin.UserId] = true
		local plain = Fakes.player(env, { name = "Plain" })
		return { env = env, admin = admin, plain = plain, adminIds = adminIds }
	end

	t:describe("leave cleanup: IsAdmin attribute (item 12)", function()
		t:it("clears IsAdmin when an admin leaves", function()
			local fx = makeAdmin()
			fx.env.services.Players.PlayerAdded:Fire(fx.admin)
			expect(fx.admin:GetAttribute("IsAdmin")):toBe(true)
			fx.env.services.Players.PlayerRemoving:Fire(fx.admin)
			expect(fx.admin:GetAttribute("IsAdmin")):toBe(false)
		end)

		t:it("is safe when a non-admin leaves", function()
			local fx = makeAdmin()
			fx.env.services.Players.PlayerAdded:Fire(fx.plain)
			expect(fx.plain:GetAttribute("IsAdmin")):toBe(false)
			expect(function()
				fx.env.services.Players.PlayerRemoving:Fire(fx.plain)
			end).never:toThrow()
			expect(fx.plain:GetAttribute("IsAdmin")):toBe(false)
		end)
	end)

	-- -----------------------------------------------------------------------------------------
	-- LeaderboardService: PlayerRemoving forces a final score write. The existing spec covers a
	-- record() call whose save has already vanished; this proves the leave handler fires it and
	-- flushes the departing player's final value.
	-- -----------------------------------------------------------------------------------------
	local function makeBoard()
		local env = Env.new()
		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		local LeaderboardService = env:require("server/Social/LeaderboardService")
		local store = { attempts = 0, values = {} }
		function store:SetAsync(key, value)
			self.attempts += 1
			self.values[key] = value
		end
		LeaderboardService.bindDataStore(function() return store end)
		-- start() registers PlayerRemoving first, then spins an infinite task.spawn loop which
		-- would hang the synchronous fake env. Suppress spawn only for start(); restore it so
		-- record()'s finite write task still runs when the leave handler fires.
		local realSpawn = env.globals.task.spawn
		env.globals.task.spawn = function() end
		LeaderboardService.start()
		env.globals.task.spawn = realSpawn
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.lifetimeEarned = 1234
		return { env = env, player = player, data = data, store = store, playerData = playerData }
	end

	t:describe("leave cleanup: final leaderboard flush (item 12)", function()
		t:it("writes the departing player's score on PlayerRemoving", function()
			local fx = makeBoard()
			fx.env.services.Players.PlayerRemoving:Fire(fx.player)
			expect(fx.store.values[tostring(fx.player.UserId)]):toBe(1234)
		end)

		t:it("skips a departing player with no save", function()
			local fx = makeBoard()
			fx.playerData.get = function() return nil end
			expect(function()
				fx.env.services.Players.PlayerRemoving:Fire(fx.player)
			end).never:toThrow()
			expect(fx.store.values[tostring(fx.player.UserId)]):toBeNil()
		end)
	end)

	-- -----------------------------------------------------------------------------------------
	-- Harness: Gate is a shared in-memory flag; one player's enable must not leak into the next
	-- session, so any PlayerRemoving closes it.
	-- -----------------------------------------------------------------------------------------
	t:describe("leave cleanup: harness gate (item 12)", function()
		t:it("closes an open gate when any player leaves", function()
			local env = Env.new()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", Fakes.playerData())
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Live/Admins", { isAdmin = function() return false end })
			for _, mod in {
				"server/Economy/EconomyService", "server/Economy/ShopService",
				"server/Farm/FarmService", "server/Farm/StorageService", "server/Farm/PlotService",
				"server/Progression/QuestService", "server/Progression/OnboardingService",
				"server/World/Village", "server/Law/RaidService", "server/Testing/RaidTrigger",
			} do
				env:mock(mod, {})
			end
			local Gate = env:require("server/Testing/Gate")
			expect(Gate.enable({ studio = true, admin = true })):toBe(true)
			expect(Gate.isOpen()):toBe(true)
			local Harness = env:require("server/Testing/Harness")
			Harness.start()
			local player = Fakes.player(env)
			env.services.Players.PlayerRemoving:Fire(player)
			expect(Gate.isOpen()):toBe(false)
		end)
	end)

	-- -----------------------------------------------------------------------------------------
	-- EvidenceService: offers and proof tokens are in memory keyed by UserId. A departing
	-- reporter's tokens must be dropped, or a later report could still be made in their name.
	-- -----------------------------------------------------------------------------------------
	local function makeEvidence()
		local env = Env.new()
		env.globals.task.spawn = function() end -- start() owns the expiry loop
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local guids = 0
		env.services.HttpService = {
			GenerateGUID = function()
				guids += 1
				return `guid-{guids}`
			end,
		}
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Economy/EconomyService", {
			transfer = function(from, to, amount)
				local a, b = playerData.get(from), playerData.get(to)
				if not a or not b or not isFinite(amount) then return 0 end
				local moved = math.clamp(math.floor(amount), 0, a.cash)
				a.cash -= moved
				b.cash += moved
				return moved
			end,
		})
		env:mock("server/Progression/RankService", { addNamaBaik = function() end })
		env:mock("server/Law/SusService", { add = function() end })
		env:mock("server/Law/RaidService", { start = function() end })
		env:mock("server/World/Village", {
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onReport = function() end,
		})
		local EvidenceService = env:require("server/Law/EvidenceService")
		EvidenceService.start()
		local cheater = Fakes.player(env, { position = env.Vector3.new(5, 0, 0) })
		local reporter = Fakes.player(env, { position = env.Vector3.new(0, 0, 0) })
		playerData.set(cheater, Fakes.newData(env))
		playerData.set(reporter, Fakes.newData(env))
		local lastOffer
		remotes.Evidence_Offer.FireClient = function(_, player, eventId)
			if player == reporter then lastOffer = eventId end
		end
		return { env = env, EvidenceService = EvidenceService, cheater = cheater, reporter = reporter,
			remotes = remotes, playerData = playerData, offer = function() return lastOffer end }
	end

	t:describe("leave cleanup: evidence offers and tokens (item 12)", function()
		t:it("drops a departing reporter's tokens", function()
			local fx = makeEvidence()
			fx.EvidenceService.logCheat(fx.cheater, "curi_air", 100)
			fx.remotes.Evidence_Record.OnServerEvent:Fire(fx.reporter, fx.offer())
			expect(fx.EvidenceService.tokenCount(fx.reporter)):toBe(1)
			fx.env.services.Players.PlayerRemoving:Fire(fx.reporter)
			expect(fx.EvidenceService.tokenCount(fx.reporter)):toBe(0)
		end)

		t:it("a later report of a token owned by a departed player grants nothing", function()
			local fx = makeEvidence()
			fx.EvidenceService.logCheat(fx.cheater, "curi_air", 100)
			fx.remotes.Evidence_Record.OnServerEvent:Fire(fx.reporter, fx.offer())
			local before = fx.playerData.get(fx.cheater).cash
			fx.env.services.Players.PlayerRemoving:Fire(fx.reporter)
			fx.remotes.Evidence_Report.OnServerEvent:Fire(fx.reporter, "guid-2")
			expect(fx.playerData.get(fx.cheater).cash):toBe(before)
		end)
	end)

	-- -----------------------------------------------------------------------------------------
	-- Net/State: the pending-patch dirty set is released through PlayerData.onBeforeRelease.
	-- The patch loop is task.spawn-driven, so this locks that the hook is registered with
	-- PlayerData and that running it after a touch is safe (no patch/throw for a departed player).
	-- -----------------------------------------------------------------------------------------
	t:describe("leave cleanup: structured-state release hook (item 12)", function()
		t:it("registers a PlayerData before-release hook that safely clears a touched player", function()
			local env = Env.new()
			env.globals.task.spawn = function() end
			local hooks = {}
			local playerData = Fakes.playerData()
			playerData.onBeforeRelease = function(cb)
				table.insert(hooks, cb)
			end
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			local State = env:require("server/Net/State")
			State.start()
			expect(#hooks >= 1):toBe(true)
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))
			State.touch(player, "cash")
			expect(function()
				hooks[1](player, data)
			end).never:toThrow()
		end)
	end)
end
