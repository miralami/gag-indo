--!nocheck
-- CheatService failure-path specs. A refused cheat never spends cash, never adds Sus and never
-- moves produce or water; a cooldown or failed steal sets no cooldown; a rate-limited or
-- damaged-save call never errors. Tests whose name starts with "[BUG]" are expected to fail:
-- they reveal real defects (see the report that accompanies this spec). Do not edit
-- CheatService or EconomyService to make them pass in this file.
-- EconomyService.trySpend is mocked with the same guards as the real function
-- (EconomyService.luau lines 111-118), so the NaN-cash test reflects the real guard.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	local function makeCheat(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local analytics = Fakes.analytics()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local sus = { added = {}, set = {} }
		local evidence = { logged = {} }
		local farm = { oplosanCalls = 0, stealCalls = 0, applyOk = true, stealOk = true, entry = nil }
		local economy = { spent = {}, refunds = {}, near = true }
		local plots = {}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Analytics/Analytics", analytics)
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount, opts)
				local data = playerData.get(player)
				if not data or not isFinite(amount) or amount < 0 then
					return false
				end
				amount = math.floor(amount)
				if not isFinite(data.cash) or data.cash < amount then
					notify.send(player, "n_not_enough_cash")
					return false
				end
				data.cash -= amount
				table.insert(economy.spent, { amount = amount, sku = opts and opts.sku })
				return true
			end,
			addCash = function(player, amount, _, opts)
				local data = playerData.get(player)
				if data and isFinite(amount) and amount > 0 then
					data.cash += math.floor(amount)
					table.insert(economy.refunds, { amount = amount, sku = opts and opts.sku })
				end
			end,
			near = function()
				return economy.near
			end,
			onCheatSale = function() end,
		})
		env:mock("server/Farm/FarmService", {
			getTileEntry = function()
				return farm.entry
			end,
			applyOplosan = function()
				farm.oplosanCalls += 1
				return farm.applyOk
			end,
			stealWater = function()
				farm.stealCalls += 1
				return farm.stealOk
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
		env:mock("server/Law/SusService", {
			add = function(player, amount)
				table.insert(sus.added, { player = player, amount = amount })
			end,
			set = function(player, value)
				table.insert(sus.set, { player = player, value = value })
			end,
		})
		env:mock("server/Law/EvidenceService", {
			logCheat = function(player, cheatId, value)
				table.insert(evidence.logged, { player = player, cheatId = cheatId, value = value })
			end,
		})

		local CheatService = env:require("server/Law/CheatService")
		CheatService.start()

		local player = Fakes.player(env, { position = env.Vector3.new(0, 0, 0) })
		local target = Fakes.player(env, { position = env.Vector3.new(10, 0, 0) })
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = options.cash or 100
		local tiles = {}
		for i = 1, 16 do
			tiles[i] = { Position = env.Vector3.new(i, 0, 0) }
		end
		plots[player] = { index = 1, tiles = tiles }
		plots[target] = { index = 2, tiles = tiles }
		if options.noPlot then
			plots[player] = nil
		end
		if options.targetSave ~= false then
			playerData.set(target, Fakes.newData(env))
		end

		return {
			env = env,
			player = player,
			target = target,
			data = data,
			remotes = remotes,
			notify = notify,
			playerData = playerData,
			sus = sus,
			evidence = evidence,
			farm = farm,
			economy = economy,
			rateLimit = rateLimit,
			fire = function(...)
				remotes.Cheat_Apply.OnServerEvent:Fire(...)
			end,
		}
	end

	local function freshEntry(fx)
		return { hot = false, plantedAt = fx.env.wallTime, growSeconds = 600 }
	end

	t:describe("CheatService failure paths", function()
		t:it("bad remote cheat ids and unknown cheat ids change nothing", function()
			local fx = makeCheat()
			fx.farm.entry = freshEntry(fx)
			for _, bad in { 42, nil, {}, true, "" } do
				fx.fire(fx.player, bad, 1)
			end
			-- "gelap" is only ever applied by a black-market sale, never by a remote.
			for _, unknown in { "gelap", "OPLOSAN", "oplosan_x", "pupuk" } do
				fx.fire(fx.player, unknown, 1, fx.target.UserId)
			end
			expect(fx.data.cash):toBe(100)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
			expect(fx.farm.stealCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
			expect(#fx.evidence.logged):toBe(0)
		end)

		t:it("a cheat from a player whose save is gone is refused", function()
			local fx = makeCheat()
			fx.farm.entry = freshEntry(fx)
			fx.playerData.get = function()
				return nil
			end
			fx.fire(fx.player, "oplosan", 1)
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
			expect(fx.farm.stealCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
		end)

		t:it("oplosan with a bad tile index is refused before anything is spent", function()
			local fx = makeCheat()
			fx.farm.entry = freshEntry(fx)
			for _, bad in { "1", nil, 0, -1, 17, 1.5, 0 / 0, math.huge } do
				fx.fire(fx.player, "oplosan", bad)
			end
			expect(fx.data.cash):toBe(100)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
		end)

		t:it("oplosan without enough cash is refused; with exactly enough it ends at zero, never negative", function()
			local poor = makeCheat({ cash = 19 })
			poor.farm.entry = freshEntry(poor)
			poor.fire(poor.player, "oplosan", 1)
			expect(poor.data.cash):toBe(19)
			expect(poor.farm.oplosanCalls):toBe(0)
			expect(#poor.sus.added):toBe(0)

			local exact = makeCheat({ cash = 20 })
			exact.farm.entry = freshEntry(exact)
			exact.fire(exact.player, "oplosan", 1)
			expect(exact.data.cash):toBe(0)
			expect(exact.data.cash >= 0):toBe(true)
			expect(exact.sus.added[1].amount):toBe(15)
			expect(exact.evidence.logged[1].cheatId):toBe("oplosan")
		end)

		t:it("oplosan from far away or with no plot moves no money", function()
			local far = makeCheat()
			far.farm.entry = freshEntry(far)
			far.economy.near = false
			far.fire(far.player, "oplosan", 1)
			expect(far.data.cash):toBe(100)
			expect(far.notify.keys(far.player)[1]):toBe("n_too_far")
			expect(#far.economy.spent):toBe(0)

			local noPlot = makeCheat({ noPlot = true })
			noPlot.farm.entry = freshEntry(noPlot)
			noPlot.fire(noPlot.player, "oplosan", 1)
			expect(noPlot.data.cash):toBe(100)
			expect(#noPlot.economy.spent):toBe(0)
			expect(noPlot.farm.oplosanCalls):toBe(0)
		end)

		t:it("oplosan on an empty, already hot, or already ripe tile is refused and costs nothing", function()
			local fx = makeCheat()
			-- nil stands for an empty tile; it is tried on its own because a nil in a list is skipped.
			fx.farm.entry = nil
			fx.fire(fx.player, "oplosan", 1)
			local entries = {
				{ hot = true, plantedAt = fx.env.wallTime, growSeconds = 600 },
				{ hot = false, plantedAt = fx.env.wallTime - 1000, growSeconds = 600 },
			}
			for _, entry in entries do
				fx.farm.entry = entry
				fx.fire(fx.player, "oplosan", 1)
			end
			expect(fx.data.cash):toBe(100)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
			expect(fx.notify.keys(fx.player)[#fx.notify.keys(fx.player)]):toBe("n_oplosan_fail")
		end)

		t:it("oplosan that FarmService cannot apply refunds the exact cost and adds no Sus", function()
			local fx = makeCheat()
			fx.farm.entry = freshEntry(fx)
			fx.farm.applyOk = false
			fx.fire(fx.player, "oplosan", 1)
			expect(fx.data.cash):toBe(100)
			expect(#fx.economy.spent):toBe(1)
			expect(fx.economy.refunds[1].amount):toBe(20)
			expect(#fx.sus.added):toBe(0)
			expect(#fx.evidence.logged):toBe(0)
			expect(fx.notify.keys(fx.player)[#fx.notify.keys(fx.player)]):toBe("n_oplosan_fail")
		end)

		t:it("curi_air with a bad, self, or absent target changes nothing", function()
			local fx = makeCheat()
			for _, bad in { "x", nil, 0 / 0, fx.player.UserId, 999999 } do
				fx.fire(fx.player, "curi_air", nil, bad)
			end
			expect(fx.farm.stealCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
			expect(next(fx.data.cooldowns)):toBe(nil)
		end)

		t:it("curi_air on a plot that is not a neighbour is refused and sets no cooldown", function()
			local fx = makeCheat({ neighbor = false })
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(fx.notify.keys(fx.player)[1]):toBe("n_not_neighbor")
			expect(fx.farm.stealCalls):toBe(0)
			expect(fx.data.cooldowns["steal_" .. fx.target.UserId]):toBe(nil)
			expect(#fx.sus.added):toBe(0)
		end)

		t:it("curi_air on the same victim during cooldown is refused and adds no Sus", function()
			local fx = makeCheat()
			fx.data.cooldowns["steal_" .. fx.target.UserId] = fx.env.wallTime + 60
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(fx.notify.keys(fx.player)[1]):toBe("n_steal_cooldown")
			expect(fx.farm.stealCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
			expect(fx.data.cooldowns["steal_" .. fx.target.UserId]):toBe(fx.env.wallTime + 60)
		end)

		t:it("a curi_air that FarmService refuses sets no cooldown, so a retry can still succeed", function()
			local fx = makeCheat()
			fx.farm.stealOk = false
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(fx.notify.keys(fx.player)[1]):toBe("n_steal_fail")
			expect(fx.data.cooldowns["steal_" .. fx.target.UserId]):toBe(nil)
			expect(#fx.sus.added):toBe(0)

			fx.farm.stealOk = true
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(fx.farm.stealCalls):toBe(2)
			expect(fx.data.cooldowns["steal_" .. fx.target.UserId]):toBe(fx.env.wallTime + 300)
			expect(fx.sus.added[1].amount):toBe(10)
		end)

		t:it("a save with no cooldowns table does not error on curi_air", function()
			-- CheatService.luau:75 indexes data.cooldowns with no nil guard, so a damaged save
			-- throws inside the remote handler (RaidService guards the same table).
			local fx = makeCheat()
			fx.data.cooldowns = nil
			local ok = pcall(fx.fire, fx.player, "curi_air", nil, fx.target.UserId)
			expect(ok):toBe(true)
		end)

		t:it("a save with NaN cash cannot buy a cheat", function()
			-- A NaN balance passes the `data.cash < amount` refusal (EconomyService.luau:116),
			-- so the cheat is applied for free and the balance stays NaN. Root cause is in
			-- EconomyService.trySpend, not CheatService.
			local fx = makeCheat()
			fx.data.cash = 0 / 0
			fx.farm.entry = freshEntry(fx)
			fx.fire(fx.player, "oplosan", 1)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
		end)

		t:it("a save with NaN sus never makes a cheat add a non-finite Sus amount", function()
			local fx = makeCheat()
			fx.data.sus = 0 / 0
			fx.farm.entry = freshEntry(fx)
			local ok = pcall(fx.fire, fx.player, "oplosan", 1)
			expect(ok):toBe(true)
			for _, entry in fx.sus.added do
				expect(isFinite(entry.amount)):toBe(true)
				expect(entry.amount > 0):toBe(true)
			end
		end)

		t:it("rate-limited cheat calls change nothing", function()
			local fx = makeCheat({ allow = false })
			fx.farm.entry = freshEntry(fx)
			fx.fire(fx.player, "oplosan", 1)
			fx.fire(fx.player, "curi_air", nil, fx.target.UserId)
			expect(fx.data.cash):toBe(100)
			expect(#fx.economy.spent):toBe(0)
			expect(fx.farm.oplosanCalls):toBe(0)
			expect(fx.farm.stealCalls):toBe(0)
			expect(#fx.sus.added):toBe(0)
			expect(#fx.notify.keys(fx.player)):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Cheat_Apply")
			expect(#fx.rateLimit.calls):toBe(2)
		end)
	end)
end
