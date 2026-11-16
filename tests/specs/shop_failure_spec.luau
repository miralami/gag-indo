--!nocheck
-- T4 (ShopService): failure-path specs. Every refusal must leave stock and cash untouched.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeShopEnv(opts)
		opts = opts or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(opts.rateAllowed ~= false)
		local econ = { buyCalls = 0, rankOk = true, buyOk = true }

		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Season/SeasonService", { musim = function() return "kemarau" end })
		env:mock("server/Progression/OnboardingService", { advance = function() end })
		env:mock("server/Economy/EconomyService", {
			hasRank = function() return econ.rankOk end,
			buySeed = function()
				econ.buyCalls += 1
				return econ.buyOk
			end,
		})

		local Crops = env:require("shared/Config/Crops")
		local GameConfig = env:require("shared/Config/Game")
		local ShopService = env:require("server/Economy/ShopService")

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		ShopService.ensure(player, data)

		return {
			env = env,
			player = player,
			data = data,
			econ = econ,
			notify = notify,
			Crops = Crops,
			GameConfig = GameConfig,
			ShopService = ShopService,
			playerData = playerData,
		}
	end

	t:describe("Shop failure paths (T4)", function()
		t:it("buy rejects malformed crop and amount arguments without spending", function()
			local fx = makeShopEnv()
			local before = fx.data.shop.stock.padi
			expect(fx.ShopService.buy(fx.player, nil, 1)):toBe(false)
			expect(fx.ShopService.buy(fx.player, 123, 1)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", "1")):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", 0)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", -3)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", 1.5)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", 0 / 0)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", math.huge)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "padi", fx.GameConfig.maxSeedBuy + 1)):toBe(false)
			expect(fx.ShopService.buy(fx.player, "tidak_ada_tanaman", 1)):toBe(false)
			expect(fx.econ.buyCalls):toBe(0)
			expect(fx.data.shop.stock.padi):toBe(before)
		end)

		t:it("buy refuses with no save data and when the rate limit denies", function()
			local fx = makeShopEnv()
			fx.playerData.set(fx.player, nil)
			expect(fx.ShopService.buy(fx.player, "padi", 1)):toBe(false)
			expect(fx.econ.buyCalls):toBe(0)

			local limited = makeShopEnv({ rateAllowed = false })
			expect(limited.ShopService.buy(limited.player, "padi", 1)):toBe(false)
			expect(limited.econ.buyCalls):toBe(0)
		end)

		t:it("buy refuses a locked rank without spending", function()
			local fx = makeShopEnv()
			fx.econ.rankOk = false
			local before = fx.data.shop.stock.padi
			expect(fx.ShopService.buy(fx.player, "padi", 1)):toBe(false)
			expect(fx.econ.buyCalls):toBe(0)
			expect(fx.data.shop.stock.padi):toBe(before)
		end)

		t:it("buy refuses crops not on today's shelf and amounts above stock", function()
			local fx = makeShopEnv()
			local offShelf
			for _, cropId in fx.Crops.order do
				if fx.data.shop.stock[cropId] == nil then
					offShelf = cropId
					break
				end
			end
			if offShelf then
				expect(fx.ShopService.buy(fx.player, offShelf, 1)):toBe(false)
			end

			fx.data.shop.stock.padi = 2
			expect(fx.ShopService.buy(fx.player, "padi", 3)):toBe(false)
			expect(fx.data.shop.stock.padi):toBe(2)
			expect(fx.econ.buyCalls):toBe(0)
		end)

		t:it("a failed economy spend leaves the shelf untouched", function()
			local fx = makeShopEnv()
			fx.data.shop.stock.padi = 5
			fx.econ.buyOk = false
			expect(fx.ShopService.buy(fx.player, "padi", 2)):toBe(false)
			expect(fx.econ.buyCalls):toBe(1)
			expect(fx.data.shop.stock.padi):toBe(5)
		end)

		t:it("a successful buy decrements stock exactly once per purchase", function()
			local fx = makeShopEnv()
			fx.data.shop.stock.padi = 5
			expect(fx.ShopService.buy(fx.player, "padi", 2)):toBe(true)
			expect(fx.data.shop.stock.padi):toBe(3)
			expect(fx.ShopService.buy(fx.player, "padi", 3)):toBe(true)
			expect(fx.data.shop.stock.padi):toBe(0)
			expect(fx.ShopService.buy(fx.player, "padi", 1)):toBe(false)
			expect(fx.data.shop.stock.padi):toBe(0)
		end)

		t:it("ensure, stock and tick tolerate missing data and corrupt shelves", function()
			local fx = makeShopEnv()
			local shop, changed = fx.ShopService.ensure(fx.player, nil)
			expect(shop):toBe(nil)
			expect(changed):toBe(false)
			expect(type(fx.ShopService.stock(fx.player))):toBe("table")
			expect(fx.ShopService.tick(fx.player)):toBe(false)

			fx.data.shop = "corrupt"
			local rebuilt = fx.ShopService.ensure(fx.player, fx.data)
			expect(type(rebuilt.stock)):toBe("table")
			fx.data.shop.stock = nil
			expect(type(fx.ShopService.ensure(fx.player, fx.data).stock)):toBe("table")
		end)

		t:it("restockNow without data refuses; with data it bumps the nonce once", function()
			local fx = makeShopEnv()
			fx.playerData.set(fx.player, nil)
			expect(fx.ShopService.restockNow(fx.player, nil)):toBe(false)

			local ok = makeShopEnv()
			expect(ok.ShopService.restockNow(ok.player, ok.data)):toBe(true)
			expect(ok.data.shop.nonce):toBe(1)
			expect(ok.ShopService.tick(ok.player)):toBe(false)
		end)
	end)
end
