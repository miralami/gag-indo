--!nocheck
-- WorkerService (buruh tani) failure-path specs. A refused hire never charges or starts a shift,
-- a pass never pays for an item it did not store, and a damaged or departed player never errors.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects in
-- WorkerService.luau (see the report that accompanies this spec). Do not edit WorkerService to
-- make them pass in this file. Happy paths live in worker_spec.luau.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeWorker(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local farm = { ready = options.ready or {}, attempts = {}, failTiles = options.failTiles or {} }
		local storage = { used = 0, capacity = 40 }
		local Remotes = Fakes.remotes(env)

		env.globals.task.spawn = function() end -- the pass loop is driven by tick() in tests

		env:mock("shared/Remotes", Remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Farm/FarmService", {
			readyTiles = function()
				return table.clone(farm.ready)
			end,
			harvestToStorage = function(_, index)
				table.insert(farm.attempts, index)
				if farm.failTiles[index] then
					return false
				end
				for position, value in farm.ready do
					if value == index then
						table.remove(farm.ready, position)
						return true
					end
				end
				return false
			end,
		})
		env:mock("server/Farm/StorageService", {
			used = function()
				return storage.used
			end,
			capacity = function()
				return storage.capacity
			end,
		})

		-- Same rules as EconomyService.trySpend: a non-finite or negative amount, or cash below the
		-- floored amount, is refused. Mocked because the real module pulls in unrelated services.
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount)
				local save = playerData.get(player)
				if save == nil or type(amount) ~= "number" or amount ~= amount or amount == math.huge or amount < 0 then
					return false
				end
				amount = math.floor(amount)
				if save.cash < amount then
					notify.send(player, "n_not_enough_cash")
					return false
				end
				save.cash -= amount
				return true
			end,
			sync = function() end,
		})

		local WorkerService = env:require("server/Farm/WorkerService")
		local Worker = env:require("shared/Config/Worker")
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = options.cash or 1000
		WorkerService.start()

		return {
			env = env,
			WorkerService = WorkerService,
			Worker = Worker,
			playerData = playerData,
			notify = notify,
			rateLimit = rateLimit,
			farm = farm,
			storage = storage,
			remotes = Remotes,
			player = player,
			data = data,
		}
	end

	local function isFinite(value)
		return value == value and value ~= math.huge and value ~= -math.huge
	end

	t:describe("WorkerService failure paths", function()
		t:it("junk args on the hire remote never hire twice or charge twice", function()
			local fx = makeWorker()
			local hireRemote = fx.remotes.Worker_Hire
			hireRemote.OnServerEvent:Fire(fx.player, nil)
			hireRemote.OnServerEvent:Fire(fx.player, 42)
			hireRemote.OnServerEvent:Fire(fx.player, {})
			hireRemote.OnServerEvent:Fire(fx.player, "buruh", math.huge)
			expect(fx.data.cash):toBe(1000 - fx.Worker.hireCost)
			expect(fx.notify.keys(fx.player)):toContain("n_worker_hired")
			local hiredCount = 0
			for _, key in fx.notify.keys(fx.player) do
				if key == "n_worker_hired" then
					hiredCount += 1
				end
			end
			expect(hiredCount):toBe(1)
		end)

		t:it("a hire one coin short of the fee is refused and starts no shift", function()
			local fx = makeWorker({ cash = 1000 })
			fx.data.cash = fx.Worker.hireCost - 1
			expect(fx.WorkerService.hire(fx.player)):toBe(false)
			expect(fx.data.cash):toBe(fx.Worker.hireCost - 1)
			expect(fx.WorkerService.endsAt(fx.data)):toBe(0)
			expect(fx.player:GetAttribute("WorkerActive")):toBe(nil)
			expect(fx.notify.keys(fx.player)):toContain("n_not_enough_cash")
		end)

		t:it("a hire with exactly the fee leaves zero cash, never negative", function()
			local fx = makeWorker({ cash = 1000 })
			fx.data.cash = fx.Worker.hireCost
			expect(fx.WorkerService.hire(fx.player)):toBe(true)
			expect(fx.data.cash):toBe(0)
			expect(fx.WorkerService.active(fx.data)):toBe(true)
		end)

		t:it("a refused hire does not disturb a shift already running", function()
			local fx = makeWorker()
			fx.WorkerService.hire(fx.player)
			local ends = fx.WorkerService.endsAt(fx.data)
			local cash = fx.data.cash
			expect(fx.WorkerService.hire(fx.player)):toBe(false)
			expect(fx.WorkerService.endsAt(fx.data)):toBe(ends)
			expect(fx.data.cash):toBe(cash)
		end)

		t:it("a rate-limited hire changes nothing however often it is fired", function()
			local fx = makeWorker({ allow = false })
			for _ = 1, 5 do
				fx.remotes.Worker_Hire.OnServerEvent:Fire(fx.player)
			end
			expect(fx.data.cash):toBe(1000)
			expect(fx.WorkerService.endsAt(fx.data)):toBe(0)
			expect(fx.player:GetAttribute("WorkerActive")):toBe(nil)
			expect(#fx.notify.sent):toBe(0)
		end)

		t:it("a save with no worker table hires and ticks without error", function()
			local fx = makeWorker()
			fx.data.worker = nil
			expect(fx.WorkerService.tick(fx.player)):toBe(0)
			expect(fx.WorkerService.hire(fx.player)):toBe(true)
			expect(fx.WorkerService.endsAt(fx.data)):toBe(fx.env.wallTime + fx.Worker.hireSeconds)
		end)

		t:it("a NaN or non-numeric hiredUntil counts as no shift and never errors", function()
			local fx = makeWorker()
			fx.data.worker.hiredUntil = 0 / 0
			expect(fx.WorkerService.active(fx.data)):toBe(false)
			fx.farm.ready = { 1 }
			expect(fx.WorkerService.tick(fx.player)):toBe(0)
			fx.data.worker.hiredUntil = "soon"
			expect(fx.WorkerService.endsAt(fx.data)):toBe(0)
			expect(fx.WorkerService.hire(fx.player)):toBe(true)
		end)

		t:it("a player who leaves mid-shift is neither harvested nor charged", function()
			local fx = makeWorker({ ready = { 1, 2, 3 } })
			fx.WorkerService.hire(fx.player)
			local cash = fx.data.cash
			fx.playerData.get = function()
				return nil
			end
			local ok, harvested = pcall(fx.WorkerService.tick, fx.player)
			expect(ok):toBe(true)
			expect(harvested):toBe(0)
			expect(#fx.farm.attempts):toBe(0)
			expect(fx.data.cash):toBe(cash)
		end)

		t:it("a tile whose harvest fails is not charged for", function()
			local fx = makeWorker({ ready = { 1, 2, 3 }, failTiles = { [2] = true } })
			fx.WorkerService.hire(fx.player)
			local afterHire = fx.data.cash
			expect(fx.WorkerService.tick(fx.player)):toBe(2)
			expect(fx.data.cash):toBe(afterHire - 2 * fx.Worker.wagePerItem)
		end)

		t:it("a full gudang at the start of a pass harvests and charges nothing", function()
			local fx = makeWorker({ ready = { 1, 2 } })
			fx.WorkerService.hire(fx.player)
			local afterHire = fx.data.cash
			fx.storage.used = fx.storage.capacity
			expect(fx.WorkerService.tick(fx.player)):toBe(0)
			expect(#fx.farm.attempts):toBe(0)
			expect(fx.data.cash):toBe(afterHire)
			expect(fx.notify.keys(fx.player)):toContain("n_gudang_full")
		end)

		t:it("negative cash sends him home and pays nothing", function()
			local fx = makeWorker({ ready = { 1 } })
			fx.WorkerService.hire(fx.player)
			fx.data.cash = -50
			expect(fx.WorkerService.tick(fx.player)):toBe(0)
			expect(fx.data.cash):toBe(-50)
			expect(fx.WorkerService.active(fx.data)):toBe(false)
			expect(fx.notify.keys(fx.player)):toContain("n_worker_unpaid")
		end)

		t:it("a NaN cash never lets him harvest for free or leaves cash NaN", function()
			-- WorkerService.luau: `math.floor(data.cash / wage)` is NaN, and math.min(5, NaN) returns
			-- 5, so `affordable <= 0` is never true and the pass harvests for an unknown cash balance.
			local fx = makeWorker({ ready = { 1, 2, 3 } })
			fx.WorkerService.hire(fx.player)
			fx.data.cash = 0 / 0
			local ok, harvested = pcall(fx.WorkerService.tick, fx.player)
			expect(ok):toBe(true)
			expect(harvested):toBe(0)
			expect(isFinite(fx.data.cash)):toBe(true)
		end)

		t:it("money stays finite and non-negative across a hire and repeated passes", function()
			local fx = makeWorker({ ready = { 1, 2, 3, 4, 5 } })
			fx.data.cash = fx.Worker.hireCost + 5
			fx.WorkerService.hire(fx.player)
			for _ = 1, 3 do
				fx.WorkerService.tick(fx.player)
				expect(isFinite(fx.data.cash)):toBe(true)
				expect(fx.data.cash >= 0):toBe(true)
			end
			expect(fx.data.cash):toBe(1)
		end)
	end)
end
