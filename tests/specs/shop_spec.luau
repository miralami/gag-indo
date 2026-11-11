--!nocheck
-- Toko Bibit (v2 PLAN §3.4): deterministic shelves, cycle boundaries and purchases.
--
-- The point of the deterministic roll is that rejoining must not refresh the shop, so the
-- tests pin the same-inputs-same-shelves rule and the saved-shop reuse on load.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Crops, Shop, ShopStock, ShopService, Game
	local playerData, notify, rateLimit, season, player, data

	local function shelvesEqual(a, b)
		for key, value in a do
			if b[key] ~= value then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end

	t:describe("ShopStock", function()
		t:beforeEach(function()
			env = Env.new()
			Crops = env:require("shared/Config/Crops")
			Shop = env:require("shared/Config/Shop")
			ShopStock = env:require("shared/ShopStock")
		end)

		t:describe("cycle", function()
			t:it("maps a timestamp to its restock window", function()
				expect(ShopStock.cycle(0)):toBe(0)
				expect(ShopStock.cycle(Shop.restockSeconds - 1)):toBe(0)
				expect(ShopStock.cycle(Shop.restockSeconds)):toBe(1)
			end)

			t:it("reports when the next window starts", function()
				expect(ShopStock.restockAt(0)):toBe(Shop.restockSeconds)
				expect(ShopStock.restockAt(4)):toBe(5 * Shop.restockSeconds)
			end)

			t:it("is due only when the saved cycle is stale", function()
				local now = 10 * Shop.restockSeconds
				expect(ShopStock.isDue(nil, now)):toBe(true)
				expect(ShopStock.isDue({ cycle = 9 }, now)):toBe(true)
				expect(ShopStock.isDue({ cycle = 10 }, now)):toBe(false)
			end)
		end)

		t:describe("roll", function()
			t:it("returns the same shelves for the same cycle and player", function()
				local first = ShopStock.roll(7, 1234, "hujan")
				local second = ShopStock.roll(7, 1234, "hujan")
				expect(shelvesEqual(first, second)):toBe(true)
			end)

			t:it("gives different players different shelves", function()
				local base = ShopStock.roll(7, 1, "hujan")
				local foundDifference = false
				for userId = 2, 50 do
					if not shelvesEqual(base, ShopStock.roll(7, userId, "hujan")) then
						foundDifference = true
						break
					end
				end
				expect(foundDifference):toBe(true)
			end)

			t:it("always stocks padi and keeps every amount in bounds", function()
				for cycle = 1, 40 do
					for userId = 1, 10 do
						for _, musim in { "hujan", "kemarau", "pancaroba" } do
							local stock = ShopStock.roll(cycle, userId, musim)
							expect(stock.padi ~= nil):toBe(true)
							for cropId, amount in stock do
								expect(Crops.list[cropId] ~= nil):toBe(true)
								expect(amount):toBeAtLeast(Shop.amountMin)
								expect(amount):toBeAtMost(ShopStock.maxAmount(cropId))
							end
						end
					end
				end
			end)

			t:it("only stocks crops that exist", function()
				local stock = ShopStock.roll(3, 9, "kemarau")
				for cropId in stock do
					expect(Crops.exists(cropId)):toBe(true)
				end
			end)
		end)

		t:describe("chance", function()
			t:it("guarantees the always-on crop", function()
				expect(ShopStock.chance("padi", "kemarau")):toBe(1)
			end)

			t:it("makes perkebunan rarer than palawija in the same season", function()
				expect(ShopStock.chance("tebu", "kemarau")):toBeLessThan(ShopStock.chance("jagung", "kemarau"))
			end)

			t:it("falls back to the changing season and returns zero for unknown crops", function()
				expect(ShopStock.chance("cabai", "salju")):toBe(ShopStock.chance("cabai", "pancaroba"))
				expect(ShopStock.chance("nangka", "hujan")):toBe(0)
			end)
		end)
	end)

	t:describe("ShopService", function()
		t:beforeEach(function()
			env = Env.new()
			Crops = env:require("shared/Config/Crops")
			Game = env:require("shared/Config/Game")
			Shop = env:require("shared/Config/Shop")
			ShopStock = env:require("shared/ShopStock")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			rateLimit = Fakes.rateLimit(true)
			season = { musim = "hujan", cuaca = "cerah", anomali = "none" }

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Events/CabaiEvent", {
				multiplier = function()
					return 1
				end,
				isActive = function()
					return false
				end,
				start = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function()
					return env.Vector3.new(0, 0, 0)
				end,
				onPasar = function() end,
			})
			env:mock("server/Season/SeasonService", {
				musim = function()
					return season.musim
				end,
				cuaca = function()
					return season.cuaca
				end,
				anomali = function()
					return season.anomali
				end,
			})

			ShopService = env:require("server/Economy/ShopService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("ensure", function()
			t:it("rolls the shelves on first use", function()
				local shop = ShopService.ensure(player, data)
				local cycle = ShopStock.cycle(env.wallTime)
				expect(shop.cycle):toBe(cycle)
				expect(shop.musim):toBe("hujan")
				expect(shop.restockAt):toBe(ShopStock.restockAt(cycle))
				expect(shop.stock.padi):toBeTruthy()
			end)

			t:it("reuses the saved shelves inside the same cycle (rejoin cannot refresh)", function()
				local first = ShopService.ensure(player, data)
				first.stock = { padi = 3 }
				local second = ShopService.ensure(player, data)
				expect(second.stock.padi):toBe(3)
			end)

			t:it("rolls again when the restock cycle turns", function()
				local first = ShopService.ensure(player, data)
				local oldCycle = first.cycle
				env:advance(Shop.restockSeconds)
				local second = ShopService.ensure(player, data)
				expect(second.cycle):toBe(oldCycle + 1)
				expect(second.restockAt):toBe(ShopStock.restockAt(oldCycle + 1))
			end)

			t:it("rolls again when the season changes", function()
				local cycle = ShopStock.cycle(env.wallTime)
				season.musim = "kemarau"
				local shop = ShopService.ensure(player, data)
				expect(shop.musim):toBe("kemarau")
				expect(shelvesEqual(shop.stock, ShopStock.roll(cycle, player.UserId, "kemarau"))):toBe(true)
			end)

			t:it("repairs a malformed saved shop", function()
				data.shop = { cycle = "x", restockAt = "y", musim = 3, stock = "nope" }
				local shop = ShopService.ensure(player, data)
				expect(type(shop.stock)):toBe("table")
				expect(shop.stock.padi):toBeTruthy()
			end)
		end)

		t:describe("tick", function()
			t:it("publishes the countdown and reports a change", function()
				local first = ShopService.ensure(player, data)
				local firstRestockAt = first.restockAt
				env:advance(Shop.restockSeconds)
				expect(ShopService.tick(player)):toBe(true)
				expect(player:GetAttribute("ShopRestockAt")):toBe(firstRestockAt + Shop.restockSeconds)
			end)

			t:it("stays quiet when the cycle has not changed", function()
				ShopService.ensure(player, data)
				ShopService.tick(player)
				expect(ShopService.tick(player)):toBe(false)
			end)

			t:it("mirrors each stocked crop onto a ShopStock_ attribute", function()
				local shop = ShopService.ensure(player, data)
				ShopService.publish(player, shop)
				for cropId, amount in shop.stock do
					expect(player:GetAttribute("ShopStock_" .. cropId)):toBe(amount)
				end
			end)
		end)

		t:describe("buy", function()
			local shop

			t:beforeEach(function()
				shop = ShopService.ensure(player, data)
				shop.stock = { padi = 5, durian = 3 }
				ShopService.publish(player, shop)
			end)

			t:it("takes the seeds, the cash and the shelf stock", function()
				local before = data.items.seed_padi
				expect(ShopService.buy(player, "padi", 2)):toBe(true)
				expect(data.items.seed_padi):toBe(before + 2)
				expect(player:GetAttribute("Seed_padi")):toBe(before + 2)
				expect(data.cash):toBe(Game.startCash - Crops.list.padi.seedCost * 2)
				expect(shop.stock.padi):toBe(3)
				expect(player:GetAttribute("ShopStock_padi")):toBe(3)
				expect(notify.keys(player)):toContain("n_bought_seeds")
			end)

			t:it("lets the player buy the whole remaining stack", function()
				expect(ShopService.buy(player, "padi", 5)):toBe(true)
				expect(shop.stock.padi):toBe(0)
				expect(ShopService.buy(player, "padi", 1)):toBe(false)
				expect(notify.keys(player)):toContain("n_shop_sold_out")
			end)

			t:it("refuses more than the shelf holds and keeps the stock", function()
				expect(ShopService.buy(player, "padi", 6)):toBe(false)
				expect(shop.stock.padi):toBe(5)
				expect(data.cash):toBe(Game.startCash)
				expect(notify.keys(player)):toContain("n_shop_stock")
			end)

			t:it("refuses a crop that is not stocked this cycle", function()
				expect(ShopService.buy(player, "singkong", 1)):toBe(false)
				expect(notify.keys(player)):toContain("n_shop_not_stocked")
			end)

			t:it("refuses a crop above the player's rank", function()
				expect(ShopService.buy(player, "durian", 1)):toBe(false)
				expect(shop.stock.durian):toBe(3)
				expect(notify.keys(player)):toContain("n_rank_locked")
			end)

			t:it("refuses when the player is too poor", function()
				data.cash = 5
				expect(ShopService.buy(player, "padi", 1)):toBe(false)
				expect(shop.stock.padi):toBe(5)
				expect(notify.keys(player)):toContain("n_not_enough_cash")
			end)

			t:it("rejects malformed amounts and crops", function()
				expect(ShopService.buy(player, "padi", 0)):toBe(false)
				expect(ShopService.buy(player, "padi", 1.5)):toBe(false)
				expect(ShopService.buy(player, "padi", Game.maxSeedBuy + 1)):toBe(false)
				expect(ShopService.buy(player, "nangka", 1)):toBe(false)
				expect(ShopService.buy(player, 5, 1)):toBe(false)
			end)

			t:it("refuses when rate limited", function()
				rateLimit.allow = function()
					return false
				end
				expect(ShopService.buy(player, "padi", 1)):toBe(false)
				expect(data.cash):toBe(Game.startCash)
			end)

			t:it("gives the same answer for the same inputs after a rejoin", function()
				-- New session, same data and wall clock: the shelf must not refresh.
				local saved = { cycle = shop.cycle, restockAt = shop.restockAt, musim = shop.musim, stock = table.clone(shop.stock) }
				data.shop = saved
				expect(ShopService.buy(player, "padi", 1)):toBe(true)
				expect(saved.stock.padi):toBe(4)
			end)
		end)
	end)
end
