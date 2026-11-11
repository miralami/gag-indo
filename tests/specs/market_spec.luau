--!nocheck
-- Pasar supply and demand (v2 PLAN §3.4): selling lowers the price, time raises it back,
-- and nothing ever escapes the floor/ceiling band.

return function(t, Env)
	local expect = t.expect
	local env, Crops, Market, MarketService

	t:describe("Pasar supply and demand", function()
		t:beforeEach(function()
			env = Env.new()
			Crops = env:require("shared/Config/Crops")
			Market = env:require("shared/Config/Market")
			MarketService = env:require("server/Economy/MarketService")
		end)

		t:describe("config", function()
			t:it("keeps the floor below one and the ceiling above one", function()
				expect(Market.minMultiplier):toBeLessThan(1)
				expect(Market.maxMultiplier):toBeGreaterThan(1)
			end)
		end)

		t:describe("multiplier", function()
			t:it("starts at the normal price", function()
				expect(MarketService.multiplier("padi")):toBe(1)
			end)

			t:it("falls when players sell that crop", function()
				MarketService.recordSale("padi", 100)
				expect(MarketService.multiplier("padi")):toBeNear(0.7, 1e-9)
			end)

			t:it("leaves other crops alone", function()
				MarketService.recordSale("padi", 100)
				expect(MarketService.multiplier("jagung")):toBe(1)
			end)

			t:it("never falls below the floor", function()
				MarketService.recordSale("padi", 100000)
				expect(MarketService.multiplier("padi")):toBe(Market.minMultiplier)
			end)

			t:it("ignores unknown crops", function()
				MarketService.recordSale("nangka", 100)
				expect(MarketService.multiplier("nangka")):toBe(1)
			end)

			t:it("ignores zero and negative counts", function()
				MarketService.recordSale("padi", 0)
				MarketService.recordSale("padi", -50)
				expect(MarketService.multiplier("padi")):toBe(1)
			end)
		end)

		t:describe("decay", function()
			t:it("raises the price back over time", function()
				MarketService.recordSale("padi", 100)
				local low = MarketService.multiplier("padi")
				MarketService.tick(env.now + Market.decaySeconds)
				expect(MarketService.multiplier("padi")):toBeGreaterThan(low)
			end)

			t:it("returns to normal after a long rest", function()
				MarketService.recordSale("padi", 100)
				MarketService.tick(env.now + Market.decaySeconds * 20)
				expect(MarketService.multiplier("padi")):toBeNear(1, 1e-6)
			end)
		end)

		t:describe("price board", function()
			t:it("covers every crop", function()
				local board = MarketService.snapshot()
				for _, cropId in Crops.order do
					expect(type(board[cropId])):toBe("number")
				end
			end)

			t:it("publishes one attribute per crop on ReplicatedStorage", function()
				MarketService.tick(env.now)
				local storage = env.services.ReplicatedStorage
				for _, cropId in Crops.order do
					expect(storage:GetAttribute("Market_" .. cropId)):toBe(1)
				end
			end)
		end)
	end)
end
