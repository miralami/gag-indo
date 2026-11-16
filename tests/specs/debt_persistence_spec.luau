--!nocheck
-- Pinjol across sessions: a loan saved and reloaded keeps its interest and due date, clock
-- rewinds never reduce what is owed, an overdue loan is escalated once on rejoin, and money
-- plus debt stays consistent over a chain of borrows and repayments.

return function(t, Env, Fakes)
	local expect = t.expect

	local function deepCopy(value)
		if type(value) ~= "table" then
			return value
		end
		local out = {}
		for k, v in value do
			out[deepCopy(k)] = deepCopy(v)
		end
		return out
	end

	local function makeDebt()
		local env = Env.new()
		local Pinjol = env:require("shared/Config/Pinjol")
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/World/Village", {
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onPasar = function() end,
		})
		local EconomyService = env:require("server/Economy/EconomyService")
		EconomyService.start()
		local DebtService = env:require("server/Economy/DebtService")
		local collector = { summons = 0, dismissals = 0 }
		function collector.summon()
			collector.summons += 1
		end
		function collector.dismiss()
			collector.dismissals += 1
		end
		DebtService.bindCollector(collector)
		DebtService.bindRaid({ isBusy = function() return false end })

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = 1000
		data.rank = "gurem"
		data.namaBaik = 50
		DebtService.publish(player, data)

		local function countKey(key)
			local n = 0
			for _, sent in notify.sent do
				if sent.key == key then
					n += 1
				end
			end
			return n
		end

		return {
			env = env,
			Pinjol = Pinjol,
			playerData = playerData,
			player = player,
			data = data,
			DebtService = DebtService,
			EconomyService = EconomyService,
			collector = collector,
			countKey = countKey,
		}
	end

	-- Save, then load in a "new session": the saved copy replaces the live data.
	local function reload(fx)
		local saved = deepCopy(fx.data)
		fx.data = fx.playerData.set(fx.player, saved)
		fx.DebtService.onLoaded(fx.player, fx.data)
		return fx.data
	end

	t:describe("Pinjol across sessions (T5 prep)", function()
		t:it("interest and due date survive a save and reload, with offline interest applied once", function()
			local fx = makeDebt()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			local dueAt = fx.data.debt.dueAt
			local owedBefore = fx.data.debt.owed
			fx.env:advance(3600)
			local reloaded = reload(fx)
			expect(reloaded.debt.dueAt):toBe(dueAt)
			local expected = math.min(
				fx.Pinjol.maxDebtMultiplier * 400,
				owedBefore + 400 * fx.Pinjol.offlineInterestRatePerHour * 1
			)
			expect(math.abs(reloaded.debt.owed - expected) < 1):toBe(true)
			-- A second reload in the same instant adds no more interest.
			local owedNow = reloaded.debt.owed
			reload(fx)
			expect(fx.data.debt.owed):toBe(owedNow)
		end)

		t:it("a clock that rewinds never reduces what is owed", function()
			local fx = makeDebt()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			fx.env:advance(1800)
			fx.DebtService.tick(fx.player)
			local owed = fx.data.debt.owed
			-- Server clock jumps back: interest must not go negative or shrink the debt.
			fx.env.wallTime -= 3600
			fx.DebtService.tick(fx.player)
			expect(fx.data.debt.owed >= owed):toBe(true)
			expect(fx.data.debt.owed):toBe(owed)
			reload(fx)
			expect(fx.data.debt.owed >= owed):toBe(true)
		end)

		t:it("an overdue loan is escalated once when the player rejoins, not on every rejoin", function()
			local fx = makeDebt()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			fx.env:advance(fx.Pinjol.dueSeconds + fx.Pinjol.OVERDUE_STAGE_SHAME + 60)
			reload(fx)
			fx.DebtService.tick(fx.player)
			local namaBaikAfterFirst = fx.data.namaBaik
			local shamesAfterFirst = fx.countKey("n_debt_shamed")
			expect(shamesAfterFirst):toBe(1)

			reload(fx)
			fx.DebtService.tick(fx.player)
			fx.DebtService.tick(fx.player)
			expect(fx.countKey("n_debt_shamed")):toBe(1)
			expect(fx.data.namaBaik):toBe(namaBaikAfterFirst)
		end)

		t:it("money and debt stay consistent over a chain of borrows and repayments", function()
			local fx = makeDebt()
			math.randomseed(20261116)
			local lastCash = fx.data.cash
			for _ = 1, 60 do
				local roll = math.random(1, 3)
				if roll == 1 then
					local before = fx.data.cash
					local ok = fx.DebtService.borrow(fx.player, math.random(10, 300))
					if ok then
						expect(fx.data.cash > before):toBe(true)
					else
						expect(fx.data.cash):toBe(before)
					end
				elseif roll == 2 then
					fx.DebtService.repay(fx.player, math.random(1, 500))
				else
					fx.env:advance(math.random(60, 900))
					fx.DebtService.tick(fx.player)
				end
				local debt = fx.data.debt
				expect(fx.data.cash >= 0):toBe(true)
				expect(debt.owed >= 0):toBe(true)
				expect(debt.owed <= debt.principal * fx.Pinjol.maxDebtMultiplier + 1):toBe(true)
				if not debt.active then
					expect(debt.owed):toBe(0)
				end
				lastCash = fx.data.cash
			end
			expect(lastCash >= 0):toBe(true)
		end)
	end)
end
