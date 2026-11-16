--!nocheck
-- T6 (Law, RaidService): failure-path specs. A refused raid never moves money, produce or
-- the counter; a leaving player is fined exactly once; a damaged save never errors.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects in
-- RaidService.luau (see the report that accompanies this spec). Do not edit RaidService to
-- make them pass in this file.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeRaid(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local analytics = Fakes.analytics()
		local rateLimit = Fakes.rateLimit(options.allowChoose ~= false)
		local badges = { awarded = {} }
		local ranks = { namaBaik = {} }
		local farm = { confiscateCalls = 0 }
		local economy = { spent = {}, hotCalls = 0 }
		local sus = { set = {}, add = {} }
		local cutscene = { events = {} }
		local village = { police = {} }
		local plot = options.plot
		local starts, ends = {}, {}
		local releaseHook = nil

		env.globals.CFrame = {
			new = function(x, y, z)
				return { X = x, Y = y, Z = z }
			end,
		}
		-- Raid timers and the jail loop run through task.spawn; a no-op keeps each test
		-- deterministic (the choosing and timeout timers still run through task.delay).
		env.globals.task.spawn = function() end

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Analytics/Analytics", analytics)
		env:mock("server/Progression/BadgeService", {
			award = function(_, id)
				table.insert(badges.awarded, id)
			end,
		})
		env:mock("server/Progression/RankService", {
			addNamaBaik = function(_, amount)
				table.insert(ranks.namaBaik, amount)
			end,
		})
		env:mock("server/Farm/FarmService", {
			confiscateHotTiles = function()
				farm.confiscateCalls += 1
				return 0
			end,
		})
		env:mock("server/Farm/PlotService", {
			getPlotOf = function()
				return plot
			end,
		})
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount, opts)
				local data = playerData.get(player)
				if data == nil or data.cash < amount then
					return false
				end
				data.cash -= amount
				table.insert(economy.spent, { amount = amount, sku = opts and opts.sku })
				return true
			end,
			removeHotHarvest = function()
				economy.hotCalls += 1
				return 0
			end,
		})
		env:mock("server/Npc/CutsceneHooks", {
			emitRaid = function(event)
				table.insert(cutscene.events, event)
			end,
		})
		env:mock("server/World/Village", {
			police = village.police,
			getPosition = function()
				return env.Vector3.new(0, 0, 20)
			end,
		})

		local RaidService = env:require("server/Law/RaidService")
		local Law = env:require("shared/Config/Law")

		playerData.onBeforeRelease = function(callback)
			releaseHook = callback
		end
		RaidService.bindSus({
			set = function(player, value)
				table.insert(sus.set, { player = player, value = value })
			end,
			add = function(player, amount)
				table.insert(sus.add, { player = player, amount = amount })
			end,
		})
		RaidService.init()

		remotes.Raid_Start.FireClient = function(_, _, payload)
			table.insert(starts, payload)
		end
		remotes.Raid_End.FireClient = function(_, _, outcome)
			table.insert(ends, outcome)
		end

		local player = Fakes.player(env, { position = env.Vector3.new(0, 0, 0) })
		player.Character.FindFirstChildOfClass = function()
			return nil
		end
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = options.cash or 10000

		return {
			env = env,
			player = player,
			data = data,
			remotes = remotes,
			notify = notify,
			playerData = playerData,
			analytics = analytics,
			badges = badges,
			ranks = ranks,
			farm = farm,
			economy = economy,
			sus = sus,
			cutscene = cutscene,
			starts = starts,
			ends = ends,
			RaidService = RaidService,
			Law = Law,
			releaseHook = function(p, d)
				releaseHook(p, d)
			end,
		}
	end

	-- Start a raid and advance past the 3 s police walk, so the player is choosing.
	local function startChoosing(fx, isViral)
		fx.RaidService.start(fx.player, isViral == true)
		fx.env:advance(3)
	end

	t:describe("Raid failure paths (T6)", function()
		t:it("a raid during cooldown is refused and moves no money, produce or sus", function()
			local fx = makeRaid()
			fx.data.cooldowns.raidSafeUntil = os.time() + 60
			local cash = fx.data.cash
			local produce = fx.data.produce
			fx.RaidService.start(fx.player, false)
			expect(fx.RaidService.getState(fx.player)):toBe("idle")
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.produce):toBe(produce)
			expect(fx.economy.hotCalls):toBe(0)
			expect(fx.farm.confiscateCalls):toBe(0)
			expect(#fx.starts):toBe(0)
			expect(#fx.sus.set):toBe(0)
			expect(#fx.analytics.events):toBe(0)
			expect(fx.data.stats.raids):toBe(0)
		end)

		t:it("a second raid while one is already incoming is ignored", function()
			local fx = makeRaid()
			fx.RaidService.start(fx.player, false)
			fx.RaidService.start(fx.player, false)
			expect(fx.RaidService.getState(fx.player)):toBe("incoming")
			expect(fx.farm.confiscateCalls):toBe(1)
			expect(#fx.analytics.events):toBe(1)
			expect(#fx.badges.awarded):toBe(1)
			expect(#fx.notify.keys(fx.player)):toBe(1)
		end)

		t:it("a raid while jailed is refused and the jail state is kept", function()
			local fx = makeRaid({ cash = 0 })
			startChoosing(fx)
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			expect(fx.RaidService.getState(fx.player)):toBe("jail")
			expect(fx.RaidService.isBusy(fx.player)):toBe(true)

			local confiscated = fx.farm.confiscateCalls
			fx.RaidService.start(fx.player, true)
			expect(fx.RaidService.getState(fx.player)):toBe("jail")
			expect(fx.farm.confiscateCalls):toBe(confiscated)
		end)

		t:it("a raid on a player with no plot and no character still starts without error", function()
			local fx = makeRaid()
			fx.player.Character = nil
			local ok = pcall(fx.RaidService.start, fx.player, false)
			expect(ok):toBe(true)
			expect(fx.RaidService.getState(fx.player)):toBe("incoming")
		end)

		t:it("a raid on a player whose save is gone is refused", function()
			local fx = makeRaid()
			fx.playerData.get = function()
				return nil
			end
			fx.RaidService.start(fx.player, false)
			expect(fx.RaidService.getState(fx.player)):toBe("idle")
			expect(#fx.starts):toBe(0)
			expect(fx.farm.confiscateCalls):toBe(0)
		end)

		t:it("a player who leaves mid-raid is fined once and later choices are ignored", function()
			local fx = makeRaid()
			startChoosing(fx)
			local fine = fx.data.cash * fx.Law.finePercent
			local cashBefore = fx.data.cash
			fx.releaseHook(fx.player, fx.data)
			expect(fx.data.cash):toBe(cashBefore - 2000)
			expect(fx.data.cooldowns.raidSafeUntil):toBe(fx.env.wallTime + fx.Law.raidCooldown)
			expect(fx.data.stats.raids):toBe(1)
			expect(fx.data.namaBaik):toBe(fx.Law.namaBaikStart + fx.Law.namaBaikCaught)
			expect(fine):toBe(2000)

			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			fx.env:advance(30)
			expect(fx.data.cash):toBe(cashBefore - 2000)
			expect(fx.data.stats.raids):toBe(1)
			expect(fx.RaidService.getState(fx.player)):toBe("idle")
		end)

		t:it("leaving twice or leaving with no raid never fines twice", function()
			local fx = makeRaid()
			fx.releaseHook(fx.player, fx.data)
			expect(fx.data.cash):toBe(10000)
			expect(fx.data.stats.raids):toBe(0)

			startChoosing(fx)
			fx.releaseHook(fx.player, fx.data)
			fx.releaseHook(fx.player, fx.data)
			expect(fx.data.cash):toBe(8000)
			expect(fx.data.stats.raids):toBe(1)
		end)

		t:it("NaN cash and NaN sus in a damaged save never error and never leave NaN cash", function()
			local fx = makeRaid()
			fx.data.sus = 0 / 0
			local started = pcall(fx.RaidService.start, fx.player, false)
			expect(started):toBe(true)
			expect(fx.RaidService.getState(fx.player)):toBe("incoming")

			fx.env:advance(3)
			fx.data.cash = 0 / 0
			local left = pcall(fx.releaseHook, fx.player, fx.data)
			expect(left):toBe(true)
			expect(fx.data.cash == fx.data.cash):toBe(true)
			expect(fx.data.cash >= 0):toBe(true)
		end)

		t:it("a save with no cooldown table does not error on raid start", function()
			local fx = makeRaid()
			fx.data.cooldowns = nil
			local ok = pcall(fx.RaidService.start, fx.player, false)
			expect(ok):toBe(true)
		end)

		t:it("a save with no stats table does not error when the player leaves mid-raid", function()
			local fx = makeRaid()
			startChoosing(fx)
			fx.data.stats = nil
			local ok = pcall(fx.releaseHook, fx.player, fx.data)
			expect(ok):toBe(true)
		end)

		t:it("a viral raid refuses the amplop choice and moves no money", function()
			local fx = makeRaid()
			startChoosing(fx, true)
			local cash = fx.data.cash
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "amplop")
			expect(fx.RaidService.getState(fx.player)):toBe("choosing")
			expect(fx.data.cash):toBe(cash)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.notify.keys(fx.player)[#fx.notify.keys(fx.player)]):toBe("n_viral_case")
		end)

		t:it("invalid or rate-limited choices change nothing", function()
			local fx = makeRaid({ allowChoose = false })
			startChoosing(fx)
			local cash = fx.data.cash
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "steal")
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, 42)
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, nil)
			expect(fx.RaidService.getState(fx.player)):toBe("choosing")
			expect(fx.data.cash):toBe(cash)
			expect(#fx.economy.spent):toBe(0)
		end)

		t:it("a choice that times out is fined exactly once and a late choice is ignored", function()
			local fx = makeRaid()
			startChoosing(fx)
			fx.env:advance(fx.Law.raidChoiceTimeout)
			expect(fx.RaidService.getState(fx.player)):toBe("idle")
			expect(fx.data.cooldowns.raidSafeUntil):toBe(fx.env.wallTime + fx.Law.raidCooldown)
			expect(fx.data.cash):toBe(8000)
			expect(fx.ends[1]):toBe("denda")

			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			expect(fx.data.cash):toBe(8000)
			expect(#fx.economy.spent):toBe(1)
		end)

		t:it("a broke player is jailed and cash floors at zero, never goes negative", function()
			-- The fine is at least Law.fineMin (50), so 30 cash cannot cover it.
			local fx = makeRaid({ cash = 30 })
			startChoosing(fx)
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			expect(fx.RaidService.getState(fx.player)):toBe("jail")
			expect(fx.data.cash):toBe(0)
			expect(fx.player:GetAttribute("InJail")):toBe(true)
		end)

		t:it("releasing from jail is idempotent and the raid counter rises once", function()
			local fx = makeRaid({ cash = 0 })
			startChoosing(fx)
			fx.remotes.Raid_Choose.OnServerEvent:Fire(fx.player, "denda")
			expect(fx.data.stats.raids):toBe(1)
			expect(fx.RaidService.releaseFromJail(fx.player)):toBe(true)
			expect(fx.RaidService.releaseFromJail(fx.player)):toBe(false)
			expect(fx.RaidService.getState(fx.player)):toBe("idle")
			expect(fx.data.stats.raids):toBe(1)
			expect(fx.player:GetAttribute("InJail")):toBe(false)
		end)
	end)
end
