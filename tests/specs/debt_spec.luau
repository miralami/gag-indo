--!nocheck
-- Pinjol (DebtService) unit spec (v2 PLAN §3.5).

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Pinjol, DebtService, StorageService
	local playerData, notify, state, player, data

	t:describe("DebtService", function()
		t:beforeEach(function()
			env = Env.new()
			Pinjol = env:require("shared/Config/Pinjol")
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Net/State", {
				touch = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function()
					return Vector3.new(0, 0, 0)
				end,
				onPasar = function() end,
			})

			local EconomyService = env:require("server/Economy/EconomyService")
			EconomyService.start()
			StorageService = env:require("server/Farm/StorageService")
			DebtService = env:require("server/Economy/DebtService")

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			data.cash = 1000
			data.rank = "gurem"
			data.namaBaik = 50
			DebtService.publish(player, data)
		end)

		t:it("calculates limit based on rank and reputation", function()
			local limitGurem = Pinjol.calcLimit("gurem", 50)
			expect(limitGurem):toBe(500)

			local limitHighRep = Pinjol.calcLimit("gurem", 100)
			expect(limitHighRep):toBe(750)

			local limitSultan = Pinjol.calcLimit("sultan", 50)
			expect(limitSultan):toBe(50000)
		end)

		t:it("allows valid borrowing, adds admin fee, and grants cash", function()
			local ok = DebtService.borrow(player, 400)
			expect(ok):toBe(true)
			expect(data.debt.active):toBe(true)
			expect(data.debt.principal):toBe(400)
			expect(data.debt.owed):toBe(440) -- 400 + 10% fee
			expect(data.cash):toBe(1400)
			expect(player:GetAttribute("DebtActive")):toBe(true)
			expect(player:GetAttribute("DebtOwed")):toBe(440)
			expect(notify.keys(player)):toContain("n_debt_borrowed")
		end)

		t:it("refuses borrowing above limit or when loan already active", function()
			expect(DebtService.borrow(player, 10000)):toBe(false)
			expect(DebtService.borrow(player, 300)):toBe(true)
			-- Second loan refused
			expect(DebtService.borrow(player, 100)):toBe(false)
			expect(notify.keys(player)):toContain("n_debt_already_active")
		end)

		t:it("accrues interest with hard cap at 3x principal", function()
			DebtService.borrow(player, 400)
			local now = data.debt.lastInterestAt + 7200 -- 2 hours later
			DebtService.accrueInterest(data, now, false)
			-- 400 * 5% * 2 hours = 40 interest
			expect(data.debt.owed):toBe(480)

			-- Advance 1000 hours to hit ceiling (3x principal = 1200)
			DebtService.accrueInterest(data, now + 3600000, false)
			expect(data.debt.owed):toBe(1200)
		end)

		t:it("replaces partial and full repayments", function()
			DebtService.borrow(player, 400) -- owed = 440
			data.cash = 1000

			-- Partial repayment: 200
			local ok = DebtService.repay(player, 200)
			expect(ok):toBe(true)
			expect(data.debt.owed):toBe(240)
			expect(data.cash):toBe(800)

			-- Full repayment of remainder
			ok = DebtService.repay(player, nil)
			expect(ok):toBe(true)
			expect(data.debt.active):toBe(false)
			expect(data.debt.owed):toBe(0)
			expect(data.cash):toBe(560)
			expect(player:GetAttribute("DebtActive")):toBe(false)
			expect(notify.keys(player)):toContain("n_debt_cleared")
		end)

		t:it("progresses overdue stages and seizes crops from gudang", function()
			DebtService.borrow(player, 400)
			data.gudang = {
				capacity = 100,
				stacks = {
					stack1 = { crop = "padi", count = 50, tier = "biasa", traits = {} },
				},
			}
			local now = env.wallTime
			data.debt.dueAt = now - 400 -- 400s overdue (past stage 3: 360s)
			data.debt.lastInterestAt = now

			DebtService.tick(player)
			expect(data.debt.stage):toBe(1)

			data.debt.stage = 2
			data.debt.lastInterestAt = now
			DebtService.tick(player)
			expect(data.debt.stage):toBe(3)
			expect(notify.keys(player)):toContain("n_debt_seized")
		end)
	end)
end
