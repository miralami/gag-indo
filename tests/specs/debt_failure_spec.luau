--!nocheck
-- T4 (DebtService): failure-path specs. Bad input and corrupt save fields must refuse or skip,
-- never error and never move money.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeDebtEnv()
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
		local raid = { busy = false }
		function raid.isBusy()
			return raid.busy
		end
		local collector = { summons = 0, dismissals = 0 }
		function collector.summon()
			collector.summons += 1
		end
		function collector.dismiss()
			collector.dismissals += 1
		end
		DebtService.bindRaid(raid)
		DebtService.bindCollector(collector)

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = 1000
		data.rank = "gurem"
		data.namaBaik = 50
		DebtService.publish(player, data)

		return {
			env = env,
			Pinjol = Pinjol,
			playerData = playerData,
			player = player,
			data = data,
			DebtService = DebtService,
			raid = raid,
			collector = collector,
		}
	end

	t:describe("Pinjol failure paths (T4)", function()
		t:it("borrow refuses non-finite, fractional, zero and negative amounts", function()
			local fx = makeDebtEnv()
			local cash = fx.data.cash
			for _, bad in { 0 / 0, math.huge, -math.huge, 0, -50, 12.5, "100" } do
				expect(fx.DebtService.borrow(fx.player, bad)):toBe(false)
			end
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.debt.active):toBe(false)
		end)

		t:it("borrow refuses without save data and while a raid is running", function()
			local fx = makeDebtEnv()
			fx.raid.busy = true
			expect(fx.DebtService.borrow(fx.player, 100)):toBe(false)
			expect(fx.data.debt.active):toBe(false)
			fx.raid.busy = false
			fx.playerData.set(fx.player, nil)
			expect(fx.DebtService.borrow(fx.player, 100)):toBe(false)
		end)

		t:it("repay without an active loan changes nothing", function()
			local fx = makeDebtEnv()
			local cash = fx.data.cash
			expect(fx.DebtService.repay(fx.player, 100)):toBe(false)
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.debt.owed):toBe(0)
		end)

		t:it("repay with a sub-unit amount pays nothing and keeps the loan", function()
			local fx = makeDebtEnv()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			local owed = fx.data.debt.owed
			local cash = fx.data.cash
			fx.DebtService.repay(fx.player, 0.5)
			expect(fx.data.debt.owed):toBe(owed)
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.debt.active):toBe(true)
		end)

		t:it("repay with NaN falls back to paying the full owed amount", function()
			local fx = makeDebtEnv()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			expect(fx.DebtService.repay(fx.player, 0 / 0)):toBe(true)
			expect(fx.data.debt.active):toBe(false)
			expect(fx.data.debt.owed):toBe(0)
		end)

		t:it("overdue seizure skips corrupt gudang stacks instead of erroring", function()
			local fx = makeDebtEnv()
			expect(fx.DebtService.borrow(fx.player, 400)):toBe(true)
			fx.data.debt.dueAt = fx.env.wallTime - 100000
			fx.data.debt.stage = 3
			fx.data.gudang = {
				capacity = 100,
				stacks = {
					badNumber = 5,
					badCount = { crop = "padi" },
					good = { crop = "padi", count = 10, tier = "biasa", traits = {} },
				},
			}
			local ok = pcall(fx.DebtService.tick, fx.player)
			expect(ok):toBe(true)
		end)

		-- WORK_QUEUE item 14 mutation D19: dropping `or debt.owed <= 0` lets repay() "clear" a
		-- loan that already has a zero balance, paying nothing and awarding the cleared badge.
		t:it("repay refuses an active loan whose owed balance is already zero", function()
			local fx = makeDebtEnv()
			fx.data.debt.active = true
			fx.data.debt.owed = 0
			fx.data.debt.principal = 100
			local cash = fx.data.cash
			expect(fx.DebtService.repay(fx.player, 25)):toBe(false)
			expect(fx.data.debt.active):toBe(true)
			expect(fx.data.cash):toBe(cash)
		end)
	end)
end
