--!nocheck
-- Pinjol (DebtService) unit spec (v2 PLAN §3.5).
--
-- The loan is the riskiest economy loop in the game: it must cap interest, allow one loan at a
-- time, refuse borrowing during a raid, and escalate overdue loans all the way to repeated
-- gudang seizure until the debt is paid.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Pinjol, DebtService, StorageService
	local playerData, notify, state, player, data, raid, collector

	local function countKey(key)
		local count = 0
		for _, sent in notify.sent do
			if sent.key == key then
				count += 1
			end
		end
		return count
	end

	local function countBroadcast(key)
		local count = 0
		for _, sent in notify.broadcasts do
			if sent.key == key then
				count += 1
			end
		end
		return count
	end

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

			raid = { busy = false }
			raid.isBusy = function()
				return raid.busy
			end
			collector = { summons = 0, dismissals = 0 }
			collector.summon = function()
				collector.summons += 1
			end
			collector.dismiss = function()
				collector.dismissals += 1
			end
			DebtService.bindRaid(raid)
			DebtService.bindCollector(collector)

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

		t:it("refuses borrowing during a raid", function()
			raid.busy = true
			expect(DebtService.borrow(player, 400)):toBe(false)
			expect(data.debt.active):toBe(false)
			expect(notify.keys(player)):toContain("n_debt_raid")

			raid.busy = false
			expect(DebtService.borrow(player, 400)):toBe(true)
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

		t:it("dismisses the collector when the loan is fully repaid", function()
			DebtService.borrow(player, 400)
			data.debt.dueAt = env.wallTime - 200
			DebtService.tick(player)
			expect(collector.summons):toBe(1)

			data.cash = 1000
			expect(DebtService.repay(player, nil)):toBe(true)
			expect(collector.dismissals):toBe(1)
		end)

		t:it("escalates overdue loans: warning, phone spam, public shame, collector", function()
			DebtService.borrow(player, 400)

			-- Stage 1: warning + the phone starts buzzing.
			data.debt.dueAt = env.wallTime - 1
			DebtService.tick(player)
			expect(data.debt.stage):toBe(1)
			expect(notify.keys(player)):toContain("n_debt_overdue_warning")
			expect(countKey("n_debt_spam")):toBe(1)

			-- The spam repeats on the next tick while the loan stays overdue.
			DebtService.tick(player)
			expect(countKey("n_debt_spam")):toBe(2)

			-- Stage 2: Nama Baik hit, server-wide shame, collector at the plot.
			data.debt.dueAt = env.wallTime - 200
			DebtService.tick(player)
			expect(data.debt.stage):toBe(2)
			expect(data.namaBaik):toBe(50 - Pinjol.shameNamaBaikPenalty)
			expect(countBroadcast("n_debt_shamed_public")):toBe(1)
			expect(collector.summons):toBe(1)
			expect(notify.keys(player)):toContain("n_debt_collector")

			-- Stage 3 is reached without waiting for another transition tick.
			data.debt.dueAt = env.wallTime - 400
			DebtService.tick(player)
			expect(data.debt.stage):toBe(3)
		end)

		t:it("seizes gudang every tick until the debt is paid", function()
			DebtService.borrow(player, 400) -- owed 440
			data.gudang = {
				capacity = 100,
				stacks = {
					first = { crop = "padi", count = 10, tier = "biasa", traits = {} }, -- 10 * 18 * 0.5 = 90
				},
			}
			data.debt.dueAt = env.wallTime - 400
			DebtService.tick(player)

			expect(data.debt.stage):toBe(3)
			expect(data.debt.owed):toBe(350)
			expect(data.gudang.stacks.first):toBeNil()
			expect(notify.keys(player)):toContain("n_debt_seized")
			expect(data.debt.active):toBe(true)

			-- More crops arrive later: the next tick seizes them too.
			data.gudang.stacks.second = { crop = "padi", count = 10, tier = "biasa", traits = {} }
			DebtService.tick(player)
			expect(data.debt.owed):toBe(260)
			expect(data.debt.active):toBe(true)

			-- Enough crops to settle the rest: the loan closes and the collector leaves.
			data.gudang.stacks.third = { crop = "padi", count = 100, tier = "biasa", traits = {} }
			DebtService.tick(player)
			expect(data.debt.owed):toBe(0)
			expect(data.debt.active):toBe(false)
			expect(data.debt.stage):toBe(0)
			expect(notify.keys(player)):toContain("n_debt_cleared")
			expect(collector.dismissals):toBe(1)
		end)

		t:it("keeps the loan after a rejoin and accrues offline interest", function()
			DebtService.borrow(player, 400) -- owed 440
			data.debt.lastInterestAt = env.wallTime - 3600 -- one hour offline
			data.debt.dueAt = env.wallTime + 600

			local rejoinPlayer = Fakes.player(env)
			playerData.set(rejoinPlayer, data)
			DebtService.onLoaded(rejoinPlayer, data)

			-- 400 * 2% offline rate * 1 hour = 8
			expect(data.debt.owed):toBe(448)
			expect(data.debt.active):toBe(true)
			expect(rejoinPlayer:GetAttribute("DebtActive")):toBe(true)
		end)

		t:it("summons the collector again when a shamed loan is still overdue on rejoin", function()
			DebtService.borrow(player, 400)
			data.debt.dueAt = env.wallTime - 200
			DebtService.tick(player)
			expect(data.debt.stage):toBe(2)

			local rejoinPlayer = Fakes.player(env)
			playerData.set(rejoinPlayer, data)
			DebtService.onLoaded(rejoinPlayer, data)
			expect(collector.summons):toBe(2)
		end)
	end)
end
