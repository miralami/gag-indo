--!nocheck
-- WORK_QUEUE round-2 item 17: LONG ECONOMY SIM.
-- One player, eight hours of simulated time (480 x 60 s cycles), run twice: once with an
-- "optimal" planting/harvesting/selling loop (buy seeds, borrow when broke, repay when able)
-- and once "idle" (no actions). Assert no overflow/NaN, cash stays finite and within MAX_CASH,
-- lifetimeEarned never shrinks, no economic dead end in the optimal loop, and no silent cash
-- drift in the idle loop. Metrics are printed as [SIM] lines for the designer report.

return function(t, Env, Fakes)
	local expect = t.expect
	local HOURS = 8
	local CYCLE_SECONDS = 60
	local CYCLES = HOURS * 3600 / CYCLE_SECONDS -- 480
	local TILES = 4

	local function finite(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end

	local function makeWorld()
		local env = Env.new()
		env.globals.task.spawn = function() end -- no real loops while advancing fake time
		local PASAR = env.Vector3.new(10, 0, 0)
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/World/Village", {
			getPosition = function() return PASAR end,
			onPasar = function() end,
			onReport = function() end,
		})
		local cabai = {
			multiplier = function() return 1 end,
			isActive = function() return false end,
			start = function() end,
		}
		env:mock("server/Events/CabaiEvent", cabai)
		-- Real RankService so promotions are part of the sim; only its rank-up side effect
		-- (FirstSession) is stubbed.
		env:mock("server/Progression/FirstSession", { onRankUp = function() end })
		env:mock("server/Progression/OnboardingService", { advance = function() end })

		local Economy = env:require("server/Economy/EconomyService")
		local Market = env:require("server/Economy/MarketService")
		local Debt = env:require("server/Economy/DebtService")
		local Crops = env:require("shared/Config/Crops")
		local Inventory = env:require("shared/Inventory")
		local Produce = env:require("shared/Produce")
		local GameConfig = env:require("shared/Config/Game")
		local Pinjol = env:require("shared/Config/Pinjol")

		Debt.bindRaid({ isBusy = function() return false end })
		Debt.bindCollector({ summon = function() end, dismiss = function() end })

		local player = Fakes.player(env, { position = PASAR })
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = GameConfig.startCash

		return {
			env = env, Economy = Economy, Market = Market, Debt = Debt,
			Crops = Crops, Inventory = Inventory, Produce = Produce, Pinjol = Pinjol, GameConfig = GameConfig,
			player = player, data = data, playerData = playerData,
		}
	end

	-- Walk every numeric leaf of a save; any NaN/inf is a defect.
	local function nonFiniteFields(value, path, out, depth)
		if depth > 12 or type(value) ~= "table" then return out end
		for k, v in value do
			if type(v) == "number" then
				if not finite(v) then table.insert(out, path .. "." .. tostring(k) .. "=" .. tostring(v)) end
			elseif type(v) == "table" then
				nonFiniteFields(v, path .. "." .. tostring(k), out, depth + 1)
			end
		end
		return out
	end

	local function assertHealthy(w, cycle, label)
		local d = w.data
		expect(finite(d.cash)):toBe(true)
		if not finite(d.cash) then error(label .. " cycle " .. cycle .. ": cash=" .. tostring(d.cash)) end
		expect(d.cash >= 0):toBe(true)
		expect(d.cash <= w.Economy.MAX_CASH):toBe(true)
		expect(finite(d.lifetimeEarned)):toBe(true)
		local bad = nonFiniteFields(d, "save", {}, 0)
		if #bad > 0 then
			error(label .. " cycle " .. cycle .. ": non-finite fields: " .. table.concat(bad, ", "))
		end
	end

	-- One full 8-hour optimal run. Returns metrics for the caller to assert/report.
	local function runOptimal(w, label)
		local d = w.data
		local seedCost = w.Crops.list.padi.seedCost
		local borrows, repays, deadEnds, cyclesWorked = 0, 0, 0, 0
		local peakCash, minCash = d.cash, d.cash
		local lastEarned = d.lifetimeEarned

		for cycle = 1, CYCLES do
			-- Service ticks happen once per cycle (60 s of sim time).
			w.Debt.tick(w.player)
			w.Market.tick(w.env.wallTime)

			-- Ensure enough padi seeds to plant TILES tiles.
			local seeds = w.Inventory.getSeed(d, "padi")
			if seeds < TILES then
				local need = TILES - seeds
				if not w.Economy.buySeed(w.player, "padi", need) then
					-- Broke: take the smallest useful loan the rank/Nama Baik allows.
					local debt = w.Debt.ensure(d)
					if not debt.active then
						local limit = w.Pinjol.calcLimit(d.rank or "gurem", d.namaBaik or 50)
						local want = math.min(limit, math.max(seedCost * need, 100))
						if want > 0 and w.Debt.borrow(w.player, want) then borrows += 1 end
					end
				end
			end

			-- Plant (consume seeds) and harvest, then sell at the Pasar.
			if w.Inventory.takeSeed(d, "padi", TILES) then
				cyclesWorked += 1
				for _ = 1, TILES do
					w.Economy.addHarvest(w.player, "padi", 1.0)
				end
				w.Economy.sellAll(w.player, "pasar")
			end

			-- Debt hygiene: clear a loan once cash comfortably covers it.
			local debt = w.Debt.ensure(d)
			if debt.active and debt.owed > 0 and d.cash > debt.owed + seedCost * TILES then
				if w.Debt.repay(w.player, math.floor(debt.owed)) then repays += 1 end
			end

			-- Dead-end guard: the player must still be able to act next cycle.
			local canContinue = w.Inventory.getSeed(d, "padi") >= TILES
				or d.cash >= seedCost * TILES
				or (not w.Debt.ensure(d).active)
			if not canContinue then deadEnds += 1 end

			assertHealthy(w, cycle, label)
			expect(d.lifetimeEarned >= lastEarned):toBe(true)
			lastEarned = d.lifetimeEarned
			peakCash = math.max(peakCash, d.cash)
			minCash = math.min(minCash, d.cash)
			w.env:advance(CYCLE_SECONDS)
		end

		return {
			cash = d.cash, earned = d.lifetimeEarned, rank = tostring(d.rank),
			peakCash = peakCash, minCash = minCash, borrows = borrows, repays = repays,
			deadEnds = deadEnds, cyclesWorked = cyclesWorked,
		}
	end

	t:describe("Long economy sim — 8 hours, optimal vs idle (round-2 item 17)", function()
		t:it("optimal strategy runs 8 hours without overflow, runaway cash or a dead end", function()
			local w = makeWorld()
			local m = runOptimal(w, "optimal")
			expect(m.deadEnds):toBe(0)
			expect(m.cyclesWorked):toBe(CYCLES)
			expect(m.peakCash > w.GameConfig.startCash):toBe(true)
			expect(m.peakCash <= w.Economy.MAX_CASH):toBe(true)
			print(string.format(
				"[SIM] optimal cash=%d earned=%d rank=%s peak=%d min=%d borrows=%d repays=%d deadEnds=%d worked=%d cycles=%d",
				m.cash, m.earned, m.rank, m.peakCash, m.minCash, m.borrows, m.repays, m.deadEnds, m.cyclesWorked, CYCLES
			))
		end)

		t:it("a broke player borrows, recovers and repays within 8 hours without a dead end", function()
			local w = makeWorld()
			local d = w.data
			d.cash = 0
			for cropId in pairs(w.Crops.list) do
				d.items["seed_" .. cropId] = 0
			end
			local m = runOptimal(w, "broke")
			expect(m.borrows > 0):toBe(true)
			expect(m.repays > 0):toBe(true)
			expect(m.deadEnds):toBe(0)
			expect(m.cash > 0):toBe(true)
			expect(d.debt.active):toBe(false)
			print(string.format(
				"[SIM] broke cash=%d earned=%d rank=%s peak=%d min=%d borrows=%d repays=%d deadEnds=%d worked=%d cycles=%d",
				m.cash, m.earned, m.rank, m.peakCash, m.minCash, m.borrows, m.repays, m.deadEnds, m.cyclesWorked, CYCLES
			))
		end)

		t:it("idle strategy holds cash and seeds flat for 8 hours with no overflow", function()
			local w = makeWorld()
			local d = w.data
			local cash0, seeds0, earned0 = d.cash, w.Inventory.getSeed(d, "padi"), d.lifetimeEarned

			for cycle = 1, CYCLES do
				w.Debt.tick(w.player)
				w.Market.tick(w.env.wallTime)
				assertHealthy(w, cycle, "idle")
				w.env:advance(CYCLE_SECONDS)
			end

			expect(d.cash):toBe(cash0)
			expect(w.Inventory.getSeed(d, "padi")):toBe(seeds0)
			expect(d.lifetimeEarned):toBe(earned0)
			print(string.format(
				"[SIM] idle cash=%d seeds=%d earned=%d cycles=%d",
				d.cash, seeds0, d.lifetimeEarned, CYCLES
			))
		end)
	end)
end
