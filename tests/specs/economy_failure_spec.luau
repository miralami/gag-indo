--!nocheck
-- T4 (EconomyService / MarketService): failure-path specs. Refusals must not move cash,
-- seeds or the Pasar price board.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeEconEnv()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(true)
		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Events/CabaiEvent", {
			multiplier = function() return 1 end,
			isActive = function() return false end,
			start = function() end,
		})
		env:mock("server/World/Village", {
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onPasar = function() end,
		})

		local Crops = env:require("shared/Config/Crops")
		local GameConfig = env:require("shared/Config/Game")
		local Inventory = env:require("shared/Inventory")
		local Economy = env:require("server/Economy/EconomyService")
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))

		return {
			env = env,
			player = player,
			data = data,
			notify = notify,
			Crops = Crops,
			GameConfig = GameConfig,
			Inventory = Inventory,
			Economy = Economy,
		}
	end

	t:describe("Economy and Pasar failure paths (T4)", function()
		t:it("buySeed refuses bad crop and amount arguments without touching cash or seeds", function()
			local fx = makeEconEnv()
			local cash = fx.data.cash
			local seeds = fx.Inventory.getSeed(fx.data, "padi")
			expect(fx.Economy.buySeed(fx.player, "tidak_ada", 1)):toBe(false)
			expect(fx.Economy.buySeed(fx.player, "padi", 0)):toBe(false)
			expect(fx.Economy.buySeed(fx.player, "padi", 1.5)):toBe(false)
			expect(fx.Economy.buySeed(fx.player, "padi", 0 / 0)):toBe(false)
			expect(fx.Economy.buySeed(fx.player, "padi", math.huge)):toBe(false)
			expect(fx.Economy.buySeed(fx.player, "padi", fx.GameConfig.maxSeedBuy + 1)):toBe(false)
			expect(fx.data.cash):toBe(cash)
			expect(fx.Inventory.getSeed(fx.data, "padi")):toBe(seeds)
		end)

		t:it("buySeed refuses when the player cannot afford it and changes nothing", function()
			local fx = makeEconEnv()
			local crop = fx.Crops.list.padi
			fx.data.cash = crop.seedCost - 1
			local seeds = fx.Inventory.getSeed(fx.data, "padi")
			expect(fx.Economy.buySeed(fx.player, "padi", 1)):toBe(false)
			expect(fx.data.cash):toBe(crop.seedCost - 1)
			expect(fx.Inventory.getSeed(fx.data, "padi")):toBe(seeds)
		end)

		t:it("buySeed success deducts exactly seedCost times amount and adds the seeds", function()
			local fx = makeEconEnv()
			local crop = fx.Crops.list.padi
			fx.data.cash = crop.seedCost * 3
			local seeds = fx.Inventory.getSeed(fx.data, "padi")
			expect(fx.Economy.buySeed(fx.player, "padi", 2)):toBe(true)
			expect(fx.data.cash):toBe(crop.seedCost)
			expect(fx.Inventory.getSeed(fx.data, "padi")):toBe(seeds + 2)
		end)

		t:it("buySeed refuses a locked rank", function()
			local fx = makeEconEnv()
			fx.data.rank = "gurem"
			local locked
			for _, cropId in fx.Crops.order do
				if fx.GameConfig.rankIndex[fx.Crops.list[cropId].rank] > fx.GameConfig.rankIndex.gurem then
					locked = cropId
					break
				end
			end
			if locked then
				fx.data.cash = 10_000_000
				local cash = fx.data.cash
				expect(fx.Economy.buySeed(fx.player, locked, 1)):toBe(false)
				expect(fx.data.cash):toBe(cash)
			end
		end)

		t:it("trySpend and addCash ignore non-finite amounts", function()
			local fx = makeEconEnv()
			local cash = fx.data.cash
			expect(fx.Economy.trySpend(fx.player, 0 / 0)):toBe(false)
			expect(fx.Economy.trySpend(fx.player, math.huge)):toBe(false)
			fx.Economy.addCash(fx.player, 0 / 0, true)
			fx.Economy.addCash(fx.player, math.huge, true)
			expect(fx.data.cash):toBe(cash)
		end)

		t:it("trySpend refuses when the saved cash is NaN or infinite", function()
			local fx = makeEconEnv()
			fx.data.cash = 0 / 0
			expect(fx.Economy.trySpend(fx.player, 1)):toBe(false)
			fx.data.cash = math.huge
			expect(fx.Economy.trySpend(fx.player, 1)):toBe(false)
		end)

		t:it("Pasar price ignores NaN and infinite sale counts and keeps the price finite", function()
			local fx = makeEconEnv()
			local Market = fx.env:require("shared/Config/Market")
			local MarketService = fx.env:require("server/Economy/MarketService")
			MarketService.recordSale("padi", 0 / 0)
			MarketService.recordSale("padi", math.huge)
			local m = MarketService.multiplier("padi")
			expect(m == m):toBe(true)
			expect(m >= Market.minMultiplier and m <= Market.maxMultiplier):toBe(true)
		end)
	end)
end
