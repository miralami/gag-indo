--!nocheck
-- WarungService and NeighborService failure-path specs. A warung visit never touches cash,
-- Sus or saves; a rate-limited or departed-player call is silent; a gotong royong water pays
-- Nama Baik exactly once per accepted call and never beyond the daily cap; bad remote ids,
-- missing or departed targets, non-neighbours and too-far calls pay nothing.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects.
-- Do not edit WarungService, NeighborService or RankService to make them pass in this file.
-- RankService is the real module (its daily cap and clamp are what is under test); its
-- FirstSession and Analytics dependencies are mocked.

return function(t, Env, Fakes)
	local expect = t.expect

	local RUMOR_KEYS = {
		warung_rumor_1 = true,
		warung_rumor_2 = true,
		warung_rumor_3 = true,
		warung_rumor_4 = true,
	}

	-- ---------------------------------------------------------------------------
	-- WarungService
	-- ---------------------------------------------------------------------------

	local function makeWarung(options)
		options = options or {}
		local env = Env.new()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local village = { handlers = {}, registrations = 0 }

		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/World/Village", {
			onWarung = function(handler)
				village.registrations += 1
				table.insert(village.handlers, handler)
			end,
		})

		local WarungService = env:require("server/World/WarungService")
		WarungService.start()

		local player = Fakes.player(env, { attributes = if options.vip then { Pass_VIPWarung = true } else nil })

		return {
			env = env,
			player = player,
			notify = notify,
			rateLimit = rateLimit,
			village = village,
			nongkrong = function(who)
				for _, handler in village.handlers do
					handler(who or player)
				end
			end,
		}
	end

	t:describe("WarungService failure paths", function()
		t:it("start wires exactly one Village.onWarung handler", function()
			local fx = makeWarung()
			expect(fx.village.registrations):toBe(1)
		end)

		t:it("nongkrong without the VIP pass sends one rumor key and nothing else", function()
			local fx = makeWarung()
			fx.nongkrong()
			expect(#fx.notify.sent):toBe(1)
			expect(RUMOR_KEYS[fx.notify.sent[1].key]):toBe(true)
			expect(#fx.notify.broadcasts):toBe(0)
		end)

		t:it("the VIP pass gets the VIP line on every visit and never a rumor", function()
			local fx = makeWarung({ vip = true })
			for _ = 1, 5 do
				fx.nongkrong()
			end
			expect(#fx.notify.sent):toBe(5)
			for _, item in fx.notify.sent do
				expect(item.key):toBe("warung_vip")
			end
		end)

		t:it("a rate-limited nongkrong sends nothing and is keyed to Warung", function()
			local fx = makeWarung({ allow = false })
			fx.nongkrong()
			expect(#fx.notify.sent):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Warung")
		end)

		t:it("a burst of nongkrong calls sends only what the limiter lets through", function()
			local fx = makeWarung()
			local allowed = 0
			fx.rateLimit.allow = function()
				allowed += 1
				return allowed == 1
			end
			for _ = 1, 20 do
				fx.nongkrong()
			end
			expect(#fx.notify.sent):toBe(1)
			expect(allowed):toBe(20)
		end)

		t:it("a player who left before the rumor fires causes no error", function()
			local fx = makeWarung()
			local players = fx.env.services.Players._players
			table.remove(players, table.find(players, fx.player))
			local ok = pcall(fx.nongkrong)
			expect(ok):toBe(true)
		end)

		t:it("rumor rolls only ever produce listed keys and no warnings are raised", function()
			local fx = makeWarung()
			local seen = {}
			for _ = 1, 200 do
				fx.nongkrong()
			end
			for _, item in fx.notify.sent do
				expect(RUMOR_KEYS[item.key]):toBe(true)
				seen[item.key] = true
			end
			expect(seen.warung_rumor_1 and seen.warung_rumor_2 and seen.warung_rumor_3 and seen.warung_rumor_4):toBe(true)
			expect(#fx.env.warnings):toBe(0)
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- NeighborService
	-- ---------------------------------------------------------------------------

	local function makeNeighbor(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local quests = { progress = {} }
		local plots = {}
		local economy = { near = options.near ~= false }
		local Law = env:require("shared/Config/Law")

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Progression/FirstSession", { onRankUp = function() end })
		env:mock("server/Progression/QuestService", {
			progress = function(player, action, amount)
				table.insert(quests.progress, { player = player, action = action, amount = amount })
			end,
		})
		env:mock("server/Farm/PlotService", {
			getPlotOf = function(player)
				return plots[player]
			end,
			isNeighbor = function()
				return options.neighbor ~= false
			end,
			getPlotPosition = function()
				return env.Vector3.new(5, 0, 5)
			end,
		})
		env:mock("server/Economy/EconomyService", {
			near = function()
				return economy.near
			end,
		})

		local NeighborService = env:require("server/Progression/NeighborService")
		NeighborService.start()

		local player = Fakes.player(env)
		local target = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		if options.targetSave ~= false then
			playerData.set(target, Fakes.newData(env))
		end
		plots[player] = if options.noPlot then nil else { index = 1 }
		plots[target] = { index = 2 }

		return {
			env = env,
			Law = Law,
			player = player,
			target = target,
			data = data,
			playerData = playerData,
			notify = notify,
			rateLimit = rateLimit,
			quests = quests,
			economy = economy,
			fire = function(...)
				remotes.Water_Neighbor.OnServerEvent:Fire(...)
			end,
		}
	end

	t:describe("NeighborService failure paths", function()
		t:it("bad remote target ids change nothing", function()
			local fx = makeNeighbor()
			local start = fx.data.namaBaik
			for _, bad in { "x", "", {}, true, 0 / 0 } do
				fx.fire(fx.player, bad)
			end
			fx.fire(fx.player, nil)
			expect(fx.data.namaBaik):toBe(start)
			expect(#fx.notify.sent):toBe(0)
			expect(#fx.quests.progress):toBe(0)
		end)

		t:it("self, unknown, departed, or save-less targets pay nothing", function()
			local fx = makeNeighbor()
			local start = fx.data.namaBaik
			fx.fire(fx.player, fx.player.UserId)
			fx.fire(fx.player, 999999)

			local players = fx.env.services.Players._players
			table.remove(players, table.find(players, fx.target))
			fx.fire(fx.player, fx.target.UserId)

			local noSave = makeNeighbor({ targetSave = false })
			noSave.fire(noSave.player, noSave.target.UserId)

			expect(fx.data.namaBaik):toBe(start)
			expect(#fx.quests.progress):toBe(0)
			expect(#fx.notify.sent):toBe(0)
			expect(noSave.data.namaBaik):toBe(noSave.Law.namaBaikStart)
		end)

		t:it("a target that is not a neighbour, has no plot, or is too far is refused without payout", function()
			local far = makeNeighbor({ near = false })
			far.fire(far.player, far.target.UserId)
			expect(far.notify.keys(far.player)[1]):toBe("n_too_far")
			expect(far.data.namaBaik):toBe(far.Law.namaBaikStart)

			local notNeighbor = makeNeighbor({ neighbor = false })
			notNeighbor.fire(notNeighbor.player, notNeighbor.target.UserId)
			expect(notNeighbor.notify.keys(notNeighbor.player)[1]):toBe("n_not_neighbor")
			expect(notNeighbor.data.namaBaik):toBe(notNeighbor.Law.namaBaikStart)

			local noPlot = makeNeighbor({ noPlot = true })
			noPlot.fire(noPlot.player, noPlot.target.UserId)
			expect(noPlot.notify.keys(noPlot.player)[1]):toBe("n_not_neighbor")
			expect(noPlot.data.namaBaik):toBe(noPlot.Law.namaBaikStart)
			expect(#noPlot.quests.progress):toBe(0)
		end)

		t:it("a rate-limited water call pays nothing, sends nothing and is keyed to Water_Neighbor", function()
			local fx = makeNeighbor({ allow = false })
			fx.fire(fx.player, fx.target.UserId)
			expect(fx.data.namaBaik):toBe(fx.Law.namaBaikStart)
			expect(#fx.notify.sent):toBe(0)
			expect(#fx.quests.progress):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Water_Neighbor")
		end)

		t:it("one accepted water pays Nama Baik and quest progress exactly once", function()
			local fx = makeNeighbor()
			local start = fx.data.namaBaik
			fx.fire(fx.player, fx.target.UserId)
			expect(fx.data.namaBaik):toBe(start + fx.Law.namaBaikWater)
			expect(#fx.quests.progress):toBe(1)
			expect(fx.quests.progress[1].action):toBe("water")
			expect(fx.quests.progress[1].amount):toBe(1)
			expect(#fx.notify.keys(fx.player)):toBe(1)
			expect(fx.notify.keys(fx.player)[1]):toBe("n_water_ok")
		end)

		t:it("the daily water cap stops payouts after exactly the cap, with no quest progress beyond it", function()
			local fx = makeNeighbor()
			local start = fx.data.namaBaik
			local cap = fx.Law.namaBaikWaterDailyCap
			for _ = 1, cap + 3 do
				fx.fire(fx.player, fx.target.UserId)
			end
			expect(fx.data.namaBaik):toBe(start + cap * fx.Law.namaBaikWater)
			expect(#fx.quests.progress):toBe(cap)
			expect(fx.notify.keys(fx.player)[#fx.notify.keys(fx.player)]):toBe("n_busy")
			expect(fx.data.namaBaik <= fx.Law.namaBaikMax):toBe(true)
		end)

		t:it("a save with no cooldowns table does not error on water", function()
			-- RankService.luau:67 indexes data.cooldowns with no nil guard, so a damaged save
			-- throws inside the Water_Neighbor handler instead of refusing the call.
			local fx = makeNeighbor()
			fx.data.cooldowns = nil
			local ok = pcall(fx.fire, fx.player, fx.target.UserId)
			expect(ok):toBe(true)
		end)

		t:it("a save with NaN namaBaik never produces a NaN balance", function()
			-- RankService.luau:96 clamps with math.clamp(math.floor(NaN), 0, max) (clampNamaBaik,
			-- line 23), which keeps NaN, so one accepted water writes NaN back into the save.
			local fx = makeNeighbor()
			fx.data.namaBaik = 0 / 0
			fx.fire(fx.player, fx.target.UserId)
			expect(fx.data.namaBaik == fx.data.namaBaik):toBe(true)
		end)
	end)
end
