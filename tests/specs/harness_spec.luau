--!nocheck
-- The playtest harness gate (MASTER_PLAN §3, task 0.3): hooks run only when Studio AND the
-- flag AND an admin all agree. A published server can never satisfy the Studio test.
return function(t, Env, Fakes)
	local expect = t.expect
	local env, Gate

	t:describe("Harness gate", function()
		t:beforeEach(function()
			env = Env.new()
			Gate = env:require("server/Testing/Gate")
		end)

		t:it("refuses every hook while the flag is off", function()
			expect(Gate.isOpen()):toBe(false)
			expect(Gate.canCall({ studio = true, admin = true })):toBe(false)
			expect(Gate.canCall({ studio = true, admin = false })):toBe(false)
			expect(Gate.canCall({ studio = false, admin = true })):toBe(false)
		end)

		t:it("only opens for a Studio admin", function()
			expect(Gate.enable({ studio = false, admin = true })):toBe(false)
			expect(Gate.enable({ studio = true, admin = false })):toBe(false)
			expect(Gate.enable(nil)):toBe(false)
			expect(Gate.isOpen()):toBe(false)
			expect(Gate.canCall({ studio = true, admin = true })):toBe(false)
		end)

		t:it("allows the hooks once a Studio admin opens it", function()
			expect(Gate.enable({ studio = true, admin = true })):toBe(true)
			expect(Gate.isOpen()):toBe(true)
			expect(Gate.canCall({ studio = true, admin = true })):toBe(true)
		end)

		t:it("always refuses in a published server, even with the flag open", function()
			expect(Gate.enable({ studio = true, admin = true })):toBe(true)
			expect(Gate.canCall({ studio = false, admin = true })):toBe(false)
			expect(Gate.allowed({ studio = false, flag = true, admin = true })):toBe(false)
		end)

		t:it("refuses a non-admin even with the flag open", function()
			Gate.enable({ studio = true, admin = true })
			expect(Gate.canCall({ studio = true, admin = false })):toBe(false)
		end)

		t:it("takes booleans only, not truthy values", function()
			expect(Gate.allowed({ studio = 1, flag = true, admin = true })):toBe(false)
			expect(Gate.allowed({ studio = true, flag = "yes", admin = true })):toBe(false)
			expect(Gate.allowed({ studio = true, flag = true, admin = {} })):toBe(false)
			expect(Gate.allowed(nil)):toBe(false)
		end)

		t:it("close() puts it back to refusing", function()
			Gate.enable({ studio = true, admin = true })
			Gate.close()
			expect(Gate.isOpen()):toBe(false)
			expect(Gate.canCall({ studio = true, admin = true })):toBe(false)
		end)
	end)

	-- FarmService.commitAttempt is the harness seam: it must run the REAL plant/harvest
	-- resolution, so the harness can never report a plant the game itself would refuse.
	local env2, FarmService, StorageService, ToolService, Crops, Produce, GameConfig
	local data, player, advanced, quests, harvested, remotes, tilePrompt
	local plot, tile1, tile2

	-- Fake world + fakes around the REAL FarmService, shared by the describes below.
	local function setupFarm()
			env2 = Env.new()
			advanced = {}
			quests = {}
			harvested = {}

			-- The real doPlant builds world parts; give the fake env just enough of them.
			local cf = setmetatable({}, { __mul = function() return cf end })
			local function newPart(name)
				local node = { Name = name, _children = {}, _attributes = {}, CFrame = cf }
				function node:SetAttribute(key, value)
					self._attributes[key] = value
				end
				function node:GetAttribute(key)
					return self._attributes[key]
				end
				function node:FindFirstChild(childName)
					return self._children[childName]
				end
				function node:Destroy() end
				return node
			end
			tile1 = newPart("Tile_1")
			tile1.Size = env2.Vector3.new(6, 0.5, 6)
			tile1.Position = env2.Vector3.new(0, 0, 0)
			tile1._children.Prompt = { Enabled = false }
			tile2 = newPart("Tile_2")
			tile2.Size = env2.Vector3.new(6, 0.5, 6)
			tile2.Position = env2.Vector3.new(0, 0, 8)
			tile2._children.Prompt = { Enabled = false }
			plot = { index = 1, tiles = { [1] = tile1, [2] = tile2 }, spawnCFrame = { Position = env2.Vector3.new(0, 0, 0) } }

			env2.globals.Instance = { new = function(className)
				return newPart(className)
			end }
			env2.globals.CFrame = { new = function()
				return cf
			end }
			env2.globals.Color3.fromHex = function()
				return {}
			end
			local vectorMeta = getmetatable(env2.Vector3.new(0, 0, 0))
			vectorMeta.__mul = function(a, b)
				return env2.Vector3.new(a.X * b, a.Y * b, a.Z * b)
			end

			local playerData = Fakes.playerData()
			remotes = Fakes.remotes(env2)
			env2:mock("shared/Remotes", remotes)
			env2:mock("server/Data/PlayerData", playerData)
			env2:mock("server/Net/Notify", Fakes.notify())
			env2:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env2:mock("server/Net/State", { touch = function() end })
			env2:mock("server/Live/LiveConfig", {
				getRuntime = function()
					return { musim = "kemarau", anomali = "none", cuaca = "cerah" }
				end,
			})
			env2:mock("server/Analytics/Analytics", {
				track = function() end,
				log = function() end,
			})
			env2:mock("server/Economy/EconomyService", {
				hasRank = function()
					return true
				end,
				sync = function() end,
				addHarvest = function(_, cropId, quality, options)
					table.insert(harvested, { cropId = cropId, quality = quality, options = options })
					Produce.add(data.produce, cropId, quality, options)
				end,
				near = function()
					return true
				end,
				refreshRank = function() end,
				addCash = function() end,
				trySpend = function()
					return true
				end,
			})
			env2:mock("server/Progression/AlmanakService", {
				record = function()
					return nil
				end,
			})
			env2:mock("server/Progression/BadgeService", { award = function() end })
			env2:mock("server/Progression/OnboardingService", {
				advance = function(_, stepId)
					advanced[stepId] = (advanced[stepId] or 0) + 1
					return true
				end,
			})
			env2:mock("server/Progression/QuestService", {
				progress = function(_, action)
					quests[action] = (quests[action] or 0) + 1
				end,
			})
			env2:mock("server/Farm/PlotService", {
				getPlotOf = function()
					return plot
				end,
				getPlot = function()
					return plot
				end,
				onTilePrompt = function(callback)
					tilePrompt = callback
				end,
			})
			env2:mock("server/World/Village", {
				getPosition = function()
					return env2.Vector3.new(0, 0, 0)
				end,
			})

			Crops = env2:require("shared/Config/Crops")
			Produce = env2:require("shared/Produce")
			GameConfig = env2:require("shared/Config/Game")
			ToolService = env2:require("server/Farm/ToolService")
			StorageService = env2:require("server/Farm/StorageService")
			FarmService = env2:require("server/Farm/FarmService")
			player = Fakes.player(env2)
			plot.owner = player
			data = playerData.set(player, Fakes.newData(env2))
	end

	t:describe("FarmService.commitAttempt", function()
		t:beforeEach(setupFarm)

		t:it("plants through the real doPlant: seed, grow time, quality, hooks", function()
			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(true)

			local crop = Crops.list.padi
			local entry = data.tiles.t1
			expect(entry):toBeTruthy()
			expect(entry.crop):toBe("padi")
			expect(data.items.seed_padi):toBe(GameConfig.startSeeds.padi - 1)
			expect(entry.growSeconds):toBe(20)
			local expectedQuality = math.floor(math.clamp(0.9 + ToolService.plantBonus(data), 0, 1) * 1000 + 0.5) / 1000
			expect(entry.quality):toBe(expectedQuality)
			expect(advanced.plant):toBe(1)
			expect(quests.plant):toBe(1)
		end)

		t:it("refuses a second plant on the same tile and spends nothing", function()
			FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)
			local seeds = data.items.seed_padi
			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(false)
			expect(data.items.seed_padi):toBe(seeds)
			expect(advanced.plant):toBe(1)
		end)

		t:it("harvests through the real doHarvest into the sack", function()
			FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)
			local entry = data.tiles.t1
			entry.plantedAt = env2.wallTime - entry.growSeconds

			expect(FarmService.commitAttempt(player, { tile = 1, action = "harvest" }, 0.9)):toBe(true)
			expect(data.tiles.t1):toBeNil()
			expect(#harvested):toBe(1)
			expect(harvested[1].cropId):toBe("padi")
			expect(advanced.harvest):toBe(1)
			expect(quests.harvest):toBe(1)
		end)

		t:it("refuses to harvest a crop that is still growing", function()
			FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)
			expect(FarmService.commitAttempt(player, { tile = 1, action = "harvest" }, 0.9)):toBe(false)
			expect(data.tiles.t1):toBeTruthy()
			expect(#harvested):toBe(0)
		end)

		t:it("refuses a malformed attempt without touching the save", function()
			expect(FarmService.commitAttempt(player, nil, 0.9)):toBe(false)
			expect(FarmService.commitAttempt(player, { tile = 1, action = "sell" }, 0.9)):toBe(false)
			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, "high")):toBe(false)
			expect(data.tiles.t1):toBeNil()
			expect(data.items.seed_padi):toBe(GameConfig.startSeeds.padi)
		end)
	end)

	t:describe("FarmService pending attempts", function()
		t:beforeEach(setupFarm)

		-- Regression: PlayerRemoving drops `pending`, so a Farm_Complete that arrives after the
		-- player is gone cannot pay out the attempt that was in flight.
		t:it("drops the pending attempt when the player leaves, so a stale Farm_Complete pays nothing", function()
			-- start() also spawns the once-a-second ready loop; keep it out of the test.
			env2.globals.task.spawn = function() end
			local starts = {}
			remotes.Minigame_Start.FireClient = function(_, _, action, index)
				table.insert(starts, { action = action, tile = index })
			end
			FarmService.start()

			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(true)
			local entry = data.tiles.t1
			entry.plantedAt = env2.wallTime - entry.growSeconds

			tilePrompt(player, 1, 1) -- the real prompt handler sets `pending` and starts the minigame
			expect(#starts):toBe(1)
			expect(starts[1].action):toBe("harvest")
			expect(starts[1].tile):toBe(1)

			env2.services.Players.PlayerRemoving:Fire(player)
			-- Past the minigame floor, so the stale report would pass the timing gate if the
			-- attempt were still pending.
			env2:advance(1)
			remotes.Farm_Complete.OnServerEvent:Fire(player, 1)

			expect(data.tiles.t1):toBe(entry)
			expect(entry.crop):toBe("padi")
			expect(#harvested):toBe(0)
		end)
	end)

	t:describe("FarmService harvesting with a full gudang", function()
		t:beforeEach(setupFarm)

		-- Regression: a full gudang must not block a sack harvest, and the harvest must not
		-- push the gudang past its capacity.
		t:it("still harvests into the sack and leaves the gudang at capacity", function()
			local capacity = StorageService.capacity(player, data)
			for _ = 1, capacity do
				Produce.add(data.gudang.stacks, "jagung", 1)
			end
			expect(StorageService.used(data)):toBe(capacity)

			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(true)
			local entry = data.tiles.t1
			entry.plantedAt = env2.wallTime - entry.growSeconds

			expect(FarmService.commitAttempt(player, { tile = 1, action = "harvest" }, 0.9)):toBe(true)
			expect(#harvested):toBe(1)
			expect(Produce.count(data.produce)):toBe(1)
			expect(Produce.count(data.gudang.stacks)):toBe(capacity)
			expect(StorageService.used(data)):toBe(capacity)
		end)
	end)
end
