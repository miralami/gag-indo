--!nocheck
-- Buruh tani (v2 PLAN §3.4): hiring, the per-item wage, and the pass limits.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Worker, WorkerService
	local playerData, notify, rateLimit, player, data, ready, harvested, gudangFree

	t:describe("WorkerService", function()
		t:beforeEach(function()
			env = Env.new()
			Worker = env:require("shared/Config/Worker")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			rateLimit = Fakes.rateLimit(true)
			ready = {}
			harvested = 0
			gudangFree = true

			local function hasReady(index)
				for _, value in ready do
					if value == index then
						return true
					end
				end
				return false
			end
			local function removeReady(index)
				for position, value in ready do
					if value == index then
						table.remove(ready, position)
						return
					end
				end
			end

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Farm/FarmService", {
				readyTiles = function()
					return table.clone(ready)
				end,
				harvestToStorage = function(_, index)
					if not hasReady(index) then
						return false
					end
					removeReady(index)
					harvested += 1
					return true
				end,
			})
			env:mock("server/Farm/StorageService", {
				used = function()
					return if gudangFree then 0 else 999
				end,
				capacity = function()
					return 40
				end,
			})
			env:mock("server/Economy/EconomyService", {
				trySpend = function(_, amount)
					if data.cash < amount then
						notify.send(player, "n_not_enough_cash")
						return false
					end
					data.cash -= amount
					return true
				end,
				sync = function() end,
			})

			WorkerService = env:require("server/Farm/WorkerService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			data.cash = 1000
		end)

		t:describe("hire", function()
			t:it("charges the fee and starts a shift", function()
				expect(WorkerService.hire(player)):toBe(true)
				expect(data.cash):toBe(1000 - Worker.hireCost)
				expect(WorkerService.endsAt(data)):toBe(env.wallTime + Worker.hireSeconds)
				expect(WorkerService.active(data)):toBe(true)
				expect(player:GetAttribute("WorkerActive")):toBe(true)
				expect(notify.keys(player)):toContain("n_worker_hired")
			end)

			t:it("starts a new shift after the old one ends", function()
				data.worker.hiredUntil = env.wallTime - 1
				expect(WorkerService.hire(player)):toBe(true)
				expect(WorkerService.endsAt(data)):toBe(env.wallTime + Worker.hireSeconds)
			end)

			t:it("refuses a second hire while one is working", function()
				WorkerService.hire(player)
				local cash = data.cash
				expect(WorkerService.hire(player)):toBe(false)
				expect(data.cash):toBe(cash)
				expect(notify.keys(player)):toContain("n_worker_busy")
			end)

			t:it("refuses when the player cannot afford the fee", function()
				data.cash = 10
				expect(WorkerService.hire(player)):toBe(false)
				expect(data.cash):toBe(10)
				expect(notify.keys(player)):toContain("n_not_enough_cash")
			end)

			t:it("refuses when rate limited", function()
				rateLimit.allow = function()
					return false
				end
				expect(WorkerService.hire(player)):toBe(false)
				expect(data.cash):toBe(1000)
			end)
		end)

		t:describe("tick", function()
			t:it("does nothing without an active shift", function()
				ready = { 1, 2 }
				expect(WorkerService.tick(player)):toBe(0)
				expect(harvested):toBe(0)
			end)

			t:it("harvests ready tiles and charges per item", function()
				WorkerService.hire(player)
				local afterHire = data.cash
				ready = { 1, 2, 3 }
				expect(WorkerService.tick(player)):toBe(3)
				expect(harvested):toBe(3)
				expect(data.cash):toBe(afterHire - 3 * Worker.wagePerItem)
				expect(notify.keys(player)):toContain("n_worker_harvested")
			end)

			t:it("caps one pass", function()
				WorkerService.hire(player)
				ready = { 1, 2, 3, 4, 5, 6, 7, 8 }
				expect(WorkerService.tick(player)):toBe(Worker.maxItemsPerPass)
				expect(#ready):toBe(8 - Worker.maxItemsPerPass)
			end)

			t:it("only pays for what he can afford", function()
				WorkerService.hire(player)
				data.cash = Worker.wagePerItem + 1
				ready = { 1, 2, 3 }
				expect(WorkerService.tick(player)):toBe(1)
				expect(data.cash):toBe(1)
			end)

			t:it("goes home when the wage cannot be paid", function()
				WorkerService.hire(player)
				data.cash = 0
				ready = { 1 }
				expect(WorkerService.tick(player)):toBe(0)
				expect(WorkerService.active(data)):toBe(false)
				expect(notify.keys(player)):toContain("n_worker_unpaid")
			end)

			t:it("stops when the gudang is full", function()
				WorkerService.hire(player)
				ready = { 1, 2 }
				gudangFree = false
				expect(WorkerService.tick(player)):toBe(0)
				expect(notify.keys(player)):toContain("n_gudang_full")
			end)

			t:it("expires the shift when time runs out", function()
				WorkerService.hire(player)
				env:advance(Worker.hireSeconds + 1)
				ready = { 1 }
				expect(WorkerService.tick(player)):toBe(0)
				expect(player:GetAttribute("WorkerActive")):toBe(false)
			end)
		end)
	end)
end
