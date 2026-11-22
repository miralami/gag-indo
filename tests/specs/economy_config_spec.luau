--!nocheck
-- BUG-015: the Pasar Nama Baik bonus must follow Config/Market.namaBaikMaxBonus. The old code read
-- the config for the scale but clamped with a hardcoded +-0.05, so tuning the config to any other
-- value was silently capped. This spec drives the real sellAll with a TUNED config (10%) and proves
-- the payout follows it (the old clamp would have paid only 5%).

return function(t, Env, Fakes)
	local expect = t.expect

	t:describe("EconomyService Nama Baik bonus config (BUG-015)", function()
		t:it("pays the configured bonus, not a hardcoded 5% clamp", function()
			local env = Env.new()
			local Law = env:require("shared/Config/Law")
			local Crops = env:require("shared/Config/Crops")
			local GameConfig = env:require("shared/Config/Game")
			local Produce = env:require("shared/Produce")
			local PASAR = env.Vector3.new(10, 0, 0)

			local playerData = Fakes.playerData()
			local player = Fakes.player(env, { position = PASAR })

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", Fakes.notify())
			env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Events/CabaiEvent", {
				multiplier = function() return 1 end,
				isActive = function() return false end,
				start = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function() return PASAR end,
				onPasar = function() end,
			})
			env:mock("server/Economy/MarketService", {
				multiplier = function() return 1 end,
				recordSale = function() end,
			})
			-- Tune to 10%. With Law start 50 / max 100, namaBaik=100 -> scale 1 -> +10%.
			-- The old hardcoded clamp would still pay only +5%.
			env:mock("shared/Config/Market", { namaBaikMaxBonus = 0.10 })

			local Economy = env:require("server/Economy/EconomyService")
			local data = playerData.set(player, Fakes.newData(env))
			data.namaBaik = Law.namaBaikMax
			data.produce[Produce.key("padi", "biasa", {})] = {
				crop = "padi", tier = "biasa", traits = {}, count = 1, qualitySum = 1,
			}

			Economy.sellAll(player, "pasar")
			local expected = math.floor(Crops.list.padi.sellPrice * 1.10)
			expect(data.cash):toBe(GameConfig.startCash + expected)
		end)
	end)
end
