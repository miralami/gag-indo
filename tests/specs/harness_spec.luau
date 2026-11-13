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
	local env2, FarmService, ToolService, Crops, GameConfig, data, player, advanced, quests, harvested
	local plot, tile1, tile2

	t:describe("FarmService.commitAttempt", function()
		t:beforeEach(function()
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
			env2:mock("shared/Remotes", Fakes.remotes(env2))
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
			env2:mock("server/Farm/StorageService", {
				used = function()
					return 0
				end,
				capacity = function()
					return 40
				end,
				publish = function() end,
				withdrawAll = function()
					return 0
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
			})
			env2:mock("server/World/Village", {
				getPosition = function()
					return env2.Vector3.new(0, 0, 0)
				end,
			})

			Crops = env2:require("shared/Config/Crops")
			GameConfig = env2:require("shared/Config/Game")
			ToolService = env2:require("server/Farm/ToolService")
			FarmService = env2:require("server/Farm/FarmService")
			player = Fakes.player(env2)
			data = playerData.set(player, Fakes.newData(env2))
		end)

		t:it("plants through the real doPlant: seed, grow time, quality, hooks", function()
			expect(FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(true)

			local crop = Crops.list.padi
			local entry = data.tiles.t1
			expect(entry):toBeTruthy()
			expect(entry.crop):toBe("padi")
			expect(data.items.seed_padi):toBe(GameConfig.startSeeds.padi - 1)
			expect(entry.growSeconds):toBe(ToolService.growSeconds(crop.growSeconds, crop.family, data))
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
end
