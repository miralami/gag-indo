--!nocheck
-- T3: Farm failure-path specs/fixes.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeFarmEnv()
		local env = Env.new()
		local advanced, quests, harvested, notifications = {}, {}, {}, {}
		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(true)

		local cf = setmetatable({}, { __mul = function() return cf end })
		local function newPart(name)
			local node = { Name = name, _children = {}, _attributes = {}, CFrame = cf, Size = env.Vector3.new(6, 0.5, 6), Position = env.Vector3.new(0, 0, 0) }
			function node:SetAttribute(k, v) self._attributes[k] = v end
			function node:GetAttribute(k) return self._attributes[k] end
			function node:FindFirstChild(n) return self._children[n] end
			function node:Destroy() end
			return node
		end
		local tile1 = newPart("Tile_1")
		tile1._children.Prompt = { Enabled = false }
		local tile2 = newPart("Tile_2")
		tile2._children.Prompt = { Enabled = false }
		local plot = { index = 1, tiles = { [1] = tile1, [2] = tile2 }, spawnCFrame = { Position = env.Vector3.new(0, 0, 0) } }
		local tilePrompt

		env.globals.Instance = { new = function(className) return newPart(className) end }
		env.globals.CFrame = { new = function() return cf end }
		env.globals.Color3.fromHex = function() return {} end
		local vectorMeta = getmetatable(env.Vector3.new(0, 0, 0))
		vectorMeta.__mul = function(a, b) return env.Vector3.new(a.X * b, a.Y * b, a.Z * b) end

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Live/LiveConfig", { getRuntime = function() return { musim = "kemarau", anomali = "none", cuaca = "cerah" } end })
		env:mock("server/Analytics/Analytics", { track = function(...) table.insert(harvested, { kind = "track", args = table.pack(...) }) end, log = function() end })
		env:mock("server/Economy/EconomyService", {
			hasRank = function() return true end,
			sync = function() end,
			addHarvest = function(_, cropId, quality, options)
				table.insert(harvested, { cropId = cropId, quality = quality, options = options })
			end,
			near = function() return true end,
			refreshRank = function() end,
			addCash = function() end,
			trySpend = function(_, amount)
				-- spend is tested elsewhere; default true
				return amount ~= nil
			end,
		})
		env:mock("server/Progression/AlmanakService", { record = function() return nil end })
		env:mock("server/Progression/BadgeService", { award = function() end })
		env:mock("server/Progression/OnboardingService", { advance = function(_, step) advanced[step] = (advanced[step] or 0) + 1 end })
		env:mock("server/Progression/QuestService", { progress = function(_, action) quests[action] = (quests[action] or 0) + 1 end })
		env:mock("server/Farm/PlotService", {
			getPlotOf = function() return plot end,
			getPlot = function() return plot end,
			onTilePrompt = function(cb) tilePrompt = cb end,
		})

		local Produce = env:require("shared/Produce")
		local GameConfig = env:require("shared/Config/Game")
		local StorageService = env:require("server/Farm/StorageService")
		local FarmService = env:require("server/Farm/FarmService")

		local player = Fakes.player(env)
		plot.owner = player
		local data = playerData.set(player, Fakes.newData(env))

		return {
			env = env,
			player = player,
			data = data,
			plot = plot,
			remotes = remotes,
			notify = notify,
			rateLimit = rateLimit,
			playerData = playerData,
			Produce = Produce,
			GameConfig = GameConfig,
			StorageService = StorageService,
			FarmService = FarmService,
			harvested = harvested,
			getTilePrompt = function() return tilePrompt end,
		}
	end

	t:describe("Farm failure paths (T3)", function()
		t:it("rejects invalid seed selection and invalid complete payloads", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			fx.FarmService.start()
			fx.remotes.Farm_SelectSeed.OnServerEvent:Fire(fx.player, 123)
			fx.remotes.Farm_SelectSeed.OnServerEvent:Fire(fx.player, "not_a_crop")
			expect(fx.player:GetAttribute("SelectedSeed")):toBe(nil)

			-- No pending attempt: should be ignored safely.
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, 1)
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, 0 / 0)
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, math.huge)
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, "x")
		end)

		t:it("rejects commitAttempt with malformed args without mutating save", function()
			local fx = makeFarmEnv()
			local seeds = fx.data.items.seed_padi
			expect(fx.FarmService.commitAttempt(fx.player, nil, 1)):toBe(false)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = "1", action = "plant" }, 1)):toBe(false)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "water" }, 1)):toBe(false)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 0 / 0)):toBe(false)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, "1")):toBe(false)
			expect(fx.data.items.seed_padi):toBe(seeds)
			expect(next(fx.data.tiles or {}) == nil):toBe(true)
		end)

		t:it("does not harvest into sack past capacity and refuses when sack full", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			-- Fill sack to capacity.
			for _ = 1, fx.GameConfig.sackBaseCapacity do
				fx.Produce.add(fx.data.produce, "jagung", 1)
			end
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)):toBe(true)
			local entry = fx.data.tiles.t1
			entry.plantedAt = fx.env.wallTime - entry.growSeconds
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "harvest" }, 1)):toBe(false)
			expect(fx.data.tiles.t1 ~= nil):toBe(true)
			expect(fx.Produce.count(fx.data.produce)):toBe(fx.GameConfig.sackBaseCapacity)
		end)

		t:it("harvestToStorage refuses when missing/invalid/not ready/full", function()
			local fx = makeFarmEnv()
			expect(fx.FarmService.harvestToStorage(fx.player, "1")):toBe(false)
			expect(fx.FarmService.harvestToStorage(fx.player, 99)):toBe(false)

			fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)
			expect(fx.FarmService.harvestToStorage(fx.player, 1)):toBe(false) -- still growing

			local entry = fx.data.tiles.t1
			entry.plantedAt = fx.env.wallTime - entry.growSeconds
			-- Fill gudang to current capacity (floor behavior respected).
			local cap = fx.StorageService.capacity(fx.player, fx.data)
			for _ = 1, cap do
				fx.Produce.add(fx.data.gudang.stacks, "jagung", 1)
			end
			expect(fx.FarmService.harvestToStorage(fx.player, 1)):toBe(false)
			expect(fx.data.tiles.t1 ~= nil):toBe(true)
		end)

		t:it("applyOplosan and confiscateHotTiles ignore invalid states", function()
			local fx = makeFarmEnv()
			expect(fx.FarmService.applyOplosan(fx.player, 1)):toBe(false)
			expect(fx.FarmService.confiscateHotTiles(fx.player)):toBe(0)

			fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)
			local entry = fx.data.tiles.t1
			-- Ready crop cannot be oplosan'd.
			entry.plantedAt = fx.env.wallTime - entry.growSeconds
			expect(fx.FarmService.applyOplosan(fx.player, 1)):toBe(false)

			-- Hot tile confiscation removes it.
			entry.plantedAt = fx.env.wallTime
			entry.growSeconds = 999
			expect(fx.FarmService.applyOplosan(fx.player, 1)):toBe(true)
			expect(fx.FarmService.applyOplosan(fx.player, 1)):toBe(false)
			expect(fx.FarmService.confiscateHotTiles(fx.player)):toBe(1)
			expect(fx.data.tiles.t1):toBe(nil)
		end)

		t:it("stealWater fails safely when no opposing growing tiles", function()
			local fx = makeFarmEnv()
			local other = Fakes.player(fx.env)
			local otherData = fx.playerData.set(other, Fakes.newData(fx.env))
			-- No plot for other in this mock -> should fail.
			expect(fx.FarmService.stealWater(fx.player, other)):toBe(false)
		end)

		-- item 19: `tiles` has dynamic keys, so SaveSanitize deliberately skips it. A damaged
		-- numeric field in a planted tile must never throw at a read site; FarmService repairs it
		-- to a finite value in place before arithmetic. -3 is finite and intentionally preserved.
		local BAD = { "oops", {}, 0 / 0, math.huge, -math.huge, true, -3 }
		local function isFinite(n)
			return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
		end

		t:it("refresh survives damaged plantedAt/growSeconds and repairs them in place", function()
			for _, bad in ipairs(BAD) do
				local fx = makeFarmEnv()
				fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)
				local entry = fx.data.tiles.t1
				entry.plantedAt = bad
				entry.growSeconds = bad
				-- Must not throw; refreshTile reads the ready timestamp.
				fx.FarmService.refresh(fx.player)
				expect(isFinite(entry.plantedAt)):toBe(true)
				expect(isFinite(entry.growSeconds)):toBe(true)
			end
		end)

		t:it("readyTiles and harvestToStorage survive damaged growSeconds", function()
			for _, bad in ipairs(BAD) do
				local fx = makeFarmEnv()
				fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)
				local entry = fx.data.tiles.t1
				entry.growSeconds = bad
				local ready = fx.FarmService.readyTiles(fx.player)
				expect(type(ready)):toBe("table")
				expect(isFinite(entry.growSeconds)):toBe(true)
				-- harvestToStorage also reads the ready timestamp in its guard.
				fx.FarmService.harvestToStorage(fx.player, 1)
				expect(isFinite(entry.growSeconds)):toBe(true)
			end
		end)

		t:it("harvest commit survives damaged quality/plantedAt and records a finite quality", function()
			for _, bad in ipairs(BAD) do
				local fx = makeFarmEnv()
				fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)
				local entry = fx.data.tiles.t1
				entry.quality = bad
				entry.plantedAt = bad
				entry.growSeconds = 0
				local ok = fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "harvest" }, 1)
				expect(ok):toBe(true)
				-- No NaN/inf may leak into the economy's harvest quality.
				local last = fx.harvested[#fx.harvested]
				expect(isFinite(last.quality)):toBe(true)
			end
		end)
	end)

	t:describe("Storage/Worker/Tool failure paths (T3)", function()
		t:it("Storage publish/deposit/withdraw handle missing data safely", function()
			local env = Env.new()
			local notify = Fakes.notify()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", Fakes.playerData())
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Economy/EconomyService", { sync = function() end })
			local StorageService = env:require("server/Farm/StorageService")
			local player = Fakes.player(env)
			expect(StorageService.depositAll(player)):toBe(0)
			expect(StorageService.withdrawAll(player)):toBe(0)
			StorageService.publish(player, nil)
		end)

		t:it("Storage capacity is read-only and respects pass/base floor without deleting stored items (R1)", function()
			local env = Env.new()
			local notify = Fakes.notify()
			local playerData = Fakes.playerData()
			local rateLimit = Fakes.rateLimit(true)
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Economy/EconomyService", { sync = function() end })
			local Produce = env:require("shared/Produce")
			local Game = env:require("shared/Config/Game")
			local StorageService = env:require("server/Farm/StorageService")
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))

			-- (a) normal save: stored capacity = base; pass on -> pass capacity, pass off -> base
			expect(data.gudang.capacity):toBe(Game.gudangBaseCapacity)
			player:SetAttribute("Pass_GudangBesar", true)
			expect(StorageService.capacity(player, data)):toBe(Game.gudangPassCapacity)
			expect(data.gudang.capacity):toBe(Game.gudangBaseCapacity)
			player:SetAttribute("Pass_GudangBesar", false)
			expect(StorageService.capacity(player, data)):toBe(Game.gudangBaseCapacity)
			expect(data.gudang.capacity):toBe(Game.gudangBaseCapacity)

			-- (b) repeated calls do not mutate save
			local cap = data.gudang.capacity
			local used = Produce.count(data.gudang.stacks)
			StorageService.capacity(player, data)
			StorageService.capacity(player, data)
			StorageService.publish(player, data)
			expect(data.gudang.capacity):toBe(cap)
			expect(Produce.count(data.gudang.stacks)):toBe(used)

			-- (c) items above base capacity remain, but new deposits are rejected when full vs base
			for _ = 1, Game.gudangBaseCapacity do
				Produce.add(data.gudang.stacks, "padi", 1)
			end
			expect(Produce.count(data.gudang.stacks)):toBe(Game.gudangBaseCapacity)
			Produce.add(data.produce, "padi", 1)
			expect(StorageService.depositAll(player)):toBe(0)
			expect(Produce.count(data.gudang.stacks)):toBe(Game.gudangBaseCapacity)
			expect(Produce.count(data.produce)):toBe(1)
			expect(notify.keys(player)):toContain("n_gudang_full")
		end)

		t:it("Legacy save with stored capacity 120 keeps 120 and never deletes items (R1 a2)", function()
			local env = Env.new()
			local notify = Fakes.notify()
			local playerData = Fakes.playerData()
			local rateLimit = Fakes.rateLimit(true)
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Economy/EconomyService", { sync = function() end })
			local Produce = env:require("shared/Produce")
			local Game = env:require("shared/Config/Game")
			local StorageService = env:require("server/Farm/StorageService")
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))

			-- Save written by the old code: stored capacity 120, items above base stacked.
			data.gudang.capacity = 120
			for _ = 1, 100 do
				Produce.add(data.gudang.stacks, "padi", 1)
			end
			local used = Produce.count(data.gudang.stacks)

			-- Pass off: intentionally keeps the legacy 120 (compatibility), items untouched.
			expect(StorageService.capacity(player, data)):toBe(120)
			expect(data.gudang.capacity):toBe(120)
			expect(Produce.count(data.gudang.stacks)):toBe(used)
		end)

		t:it("R2: a prompt on a foreign plot never plants or harvests", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			fx.FarmService.start()
			local other = Fakes.player(fx.env)
			fx.plot.owner = other
			fx.getTilePrompt()(fx.player, 1, 1)
			expect(fx.data.tiles.t1):toBe(nil)
			expect(fx.data.items.seed_padi ~= nil):toBe(true)
			-- A foreign-owned plot must also not accept a Farm_Complete for a pending attempt.
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, 1)
			expect(fx.data.tiles.t1):toBe(nil)
		end)

		t:it("R2: double plant on the same tile is rejected and costs one seed", function()
			local fx = makeFarmEnv()
			local seeds = fx.data.items.seed_padi
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)):toBe(true)
			local afterFirst = fx.data.items.seed_padi
			expect(afterFirst):toBe(seeds - 1)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)):toBe(false)
			expect(fx.data.items.seed_padi):toBe(afterFirst)
		end)

		t:it("R2: double harvest pays out once", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)):toBe(true)
			local entry = fx.data.tiles.t1
			entry.plantedAt = fx.env.wallTime - entry.growSeconds
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "harvest" }, 1)):toBe(true)
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "harvest" }, 1)):toBe(false)
			local harvests = 0
			for _, rec in fx.harvested do
				if rec.cropId ~= nil then
					harvests += 1
				end
			end
			expect(harvests):toBe(1)
		end)

		t:it("R2: clock skew (planted in the future) never ripens early", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "plant", cropId = "padi" }, 1)):toBe(true)
			local entry = fx.data.tiles.t1
			entry.plantedAt = fx.env.wallTime + 3600
			expect(fx.FarmService.commitAttempt(fx.player, { tile = 1, action = "harvest" }, 1)):toBe(false)
			expect(fx.FarmService.harvestToStorage(fx.player, 1)):toBe(false)
			expect(fx.data.tiles.t1 ~= nil):toBe(true)
			local ready = fx.FarmService.readyTiles(fx.player)
			expect(#ready):toBe(0)
		end)

		t:it("R2: a pending attempt is dropped when the player leaves", function()
			local fx = makeFarmEnv()
			fx.env.globals.task.spawn = function() end
			fx.FarmService.start()
			fx.getTilePrompt()(fx.player, 1, 1) -- sets pending plant
			fx.env.services.Players.PlayerRemoving:Fire(fx.player)
			fx.remotes.Farm_Complete.OnServerEvent:Fire(fx.player, 1)
			expect(fx.data.tiles.t1):toBe(nil)
		end)

		t:it("Worker tick/hire handle missing data and inactive states", function()
			local env = Env.new()
			local notify = Fakes.notify()
			local playerData = Fakes.playerData()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Farm/FarmService", { readyTiles = function() return {} end, harvestToStorage = function() return false end })
			env:mock("server/Farm/StorageService", { used = function() return 0 end, capacity = function() return 40 end })
			env:mock("server/Economy/EconomyService", { trySpend = function() return true end, sync = function() end })
			local WorkerService = env:require("server/Farm/WorkerService")
			local player = Fakes.player(env)
			expect(WorkerService.hire(player)):toBe(false)
			expect(WorkerService.tick(player)):toBe(0)
		end)

		t:it("ToolService effects tolerate nil/unknown data and buy rejects missing data", function()
			local env = Env.new()
			local notify = Fakes.notify()
			local playerData = Fakes.playerData()
			local rateLimit = Fakes.rateLimit(true)
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Events/CabaiEvent", { multiplier = function() return 1 end, isActive = function() return false end, start = function() end })
			env:mock("server/World/Village", { getPosition = function() return env.Vector3.new(0, 0, 0) end, onPasar = function() end })
			env:mock("server/Season/SeasonService", { growSeconds = function(base) return base end, musim = function() return "hujan" end })
			local ToolService = env:require("server/Farm/ToolService")
			local player = Fakes.player(env)
			expect(ToolService.growMultiplier(nil)):toBe(1)
			expect(ToolService.plantBonus(nil)):toBe(0)
			expect(ToolService.buy(player, "cangkul")):toBe(false)
			rateLimit.allow = function() return false end
			playerData.set(player, Fakes.newData(env))
			expect(ToolService.buy(player, "cangkul")):toBe(false)
		end)
	end)
end
