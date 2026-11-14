--!nocheck
-- Seed floor (BUG-004, decision D-G3 option A): a broke player with no cash, no seed of any
-- kind and no planted tile gets exactly 1 padi seed, once per session, never cash.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, FarmService, Inventory, Crops
	local playerData, notify, player, data

	local function clearBag()
		data.items = { amplopPremium = 0, jaminanKilat = 0 }
	end

	local function plant()
		data.tiles = { t1 = { crop = "padi", plantedAt = env.wallTime, growSeconds = 60, quality = 1 } }
	end

	t:describe("Seed floor (BUG-004)", function()
		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			notify = Fakes.notify()

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Net/State", { touch = function() end })
			env:mock("server/Live/LiveConfig", {
				getRuntime = function()
					return { musim = "kemarau", anomali = "none", cuaca = "cerah" }
				end,
			})
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Economy/EconomyService", { sync = function() end })
			env:mock("server/Progression/AlmanakService", { record = function() return nil end })
			env:mock("server/Progression/BadgeService", { award = function() end })
			env:mock("server/Progression/OnboardingService", { advance = function() return true end })
			env:mock("server/Progression/QuestService", { progress = function() end })
			env:mock("server/Farm/PlotService", {
				getPlotOf = function() return nil end,
				getPlot = function() return nil end,
				claim = function() return nil end,
				onTilePrompt = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function() return Vector3.new(0, 0, 0) end,
				onPasar = function() end,
			})

			FarmService = env:require("server/Farm/FarmService")
			Inventory = env:require("shared/Inventory")
			Crops = env:require("shared/Config/Crops")

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			data.cash = 0
			clearBag()
		end)

		t:it("grants exactly 1 padi seed when the player is broke", function()
			expect(FarmService.checkSeedFloor(player)):toBe(true)
			expect(Inventory.getSeed(data, "padi")):toBe(1)
			expect(notify.keys(player)):toContain("n_seed_floor")
		end)

		t:it("never changes cash", function()
			FarmService.checkSeedFloor(player)
			expect(data.cash):toBe(0)
		end)

		t:it("does not grant when cash is above zero", function()
			data.cash = 1
			expect(FarmService.checkSeedFloor(player)):toBe(false)
			expect(Inventory.getSeed(data, "padi")):toBe(0)
		end)

		t:it("does not grant when the player already holds padi", function()
			Inventory.addSeed(data, "padi", 1)
			expect(FarmService.checkSeedFloor(player)):toBe(false)
			expect(Inventory.getSeed(data, "padi")):toBe(1)
		end)

		t:it("does not grant when the player holds a seed of another crop", function()
			local other = Crops.order[#Crops.order]
			expect(other ~= "padi"):toBe(true)
			Inventory.addSeed(data, other, 1)
			expect(FarmService.checkSeedFloor(player)):toBe(false)
			expect(Inventory.getSeed(data, "padi")):toBe(0)
		end)

		t:it("does not grant when a crop is planted", function()
			plant()
			expect(FarmService.checkSeedFloor(player)):toBe(false)
			expect(Inventory.getSeed(data, "padi")):toBe(0)
		end)

		t:it("grants only once per session", function()
			expect(FarmService.checkSeedFloor(player)):toBe(true)
			clearBag()
			expect(FarmService.checkSeedFloor(player)):toBe(false)
			expect(Inventory.getSeed(data, "padi")):toBe(0)
		end)

		t:it("a new session (new Player object) can be granted again", function()
			expect(FarmService.checkSeedFloor(player)):toBe(true)
			local rejoined = Fakes.player(env)
			local rejoinedData = playerData.set(rejoined, Fakes.newData(env))
			rejoinedData.cash = 0
			rejoinedData.items = { amplopPremium = 0, jaminanKilat = 0 }
			expect(FarmService.checkSeedFloor(rejoined)):toBe(true)
			expect(Inventory.getSeed(rejoinedData, "padi")):toBe(1)
		end)
	end)
end
