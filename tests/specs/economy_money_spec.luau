--!nocheck
-- Money invariants: back-to-back buys and sells, integer payouts, and explicit caps.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeEnv()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local cabai = { value = 1 }
		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Events/CabaiEvent", {
			multiplier = function(cropId)
				return if cropId == "cabai" then cabai.value else 1
			end,
			isActive = function() return cabai.value > 1 end,
			start = function() end,
		})
		local PASAR = env.Vector3.new(10, 0, 0)
		env:mock("server/World/Village", {
			getPosition = function() return PASAR end,
			onPasar = function() end,
		})
		local Produce = env:require("shared/Produce")
		local Inventory = env:require("shared/Inventory")
		local GameConfig = env:require("shared/Config/Game")
		local Economy = env:require("server/Economy/EconomyService")
		local player = Fakes.player(env, { position = PASAR })
		local data = playerData.set(player, Fakes.newData(env))
		return {
			env = env,
			player = player,
			data = data,
			cabai = cabai,
			Produce = Produce,
			Inventory = Inventory,
			GameConfig = GameConfig,
			Economy = Economy,
		}
	end

	local function addStack(fx, cropId, count, tier, hot)
		local traits = if hot then { "oplosan" } else {}
		local key = fx.Produce.key(cropId, tier or "biasa", traits)
		fx.data.produce[key] = {
			crop = cropId,
			tier = tier or "biasa",
			traits = traits,
			count = count,
			qualitySum = count,
		}
	end

	local function isInt(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n == math.floor(n)
	end

	t:describe("Money invariants (T5 prep)", function()
		t:it("two back-to-back buySeed calls cannot overspend; cash never goes negative", function()
			local fx = makeEnv()
			local crop = fx.env:require("shared/Config/Crops").list.padi
			fx.data.cash = crop.seedCost * 3
			expect(fx.Economy.buySeed(fx.player, "padi", 2)):toBe(true)
			expect(fx.Economy.buySeed(fx.player, "padi", 2)):toBe(false)
			expect(fx.data.cash):toBe(crop.seedCost)
			expect(fx.data.cash >= 0):toBe(true)
		end)

		t:it("selling the same stock twice pays only once and empties the sack", function()
			local fx = makeEnv()
			addStack(fx, "padi", 10)
			local before = fx.data.cash
			fx.Economy.sellAll(fx.player, "pasar")
			local afterFirst = fx.data.cash
			expect(afterFirst > before):toBe(true)
			fx.Economy.sellAll(fx.player, "pasar")
			expect(fx.data.cash):toBe(afterFirst)
			expect(fx.Produce.count(fx.data.produce)):toBe(0)
		end)

		t:it("payouts stay integer for fractional price, rarity, event, pass and nama baik", function()
			for _, tier in { "biasa", "langka", "sultan" } do
				for _, eventValue in { 1, 1.37 } do
					for _, namaBaik in { 0, 33, 50, 100 } do
						for _, ordal in { false, true } do
							local fx = makeEnv()
							fx.cabai.value = eventValue
							fx.data.namaBaik = namaBaik
							fx.player:SetAttribute("Pass_Ordal", ordal)
							addStack(fx, "cabai", 7, tier)
							local before = fx.data.cash
							fx.Economy.sellAll(fx.player, "pasar")
							local gained = fx.data.cash - before
							expect(isInt(fx.data.cash)):toBe(true)
							expect(gained > 0):toBe(true)
							expect(isInt(gained)):toBe(true)
						end
					end
				end
			end
		end)

		t:it("huge stacks never make cash infinite or NaN and stay under the explicit cap", function()
			local fx = makeEnv()
			local cap = fx.Economy.MAX_CASH
			expect(type(cap)):toBe("number")
			addStack(fx, "padi", 1e15, "sultan")
			fx.Economy.sellAll(fx.player, "pasar")
			expect(isInt(fx.data.cash)):toBe(true)
			expect(fx.data.cash <= cap):toBe(true)
		end)

		t:it("an infinite stack is refused and keeps the produce instead of erasing it", function()
			local fx = makeEnv()
			addStack(fx, "padi", math.huge)
			local cash = fx.data.cash
			fx.Economy.sellAll(fx.player, "pasar")
			expect(fx.data.cash):toBe(cash)
			expect(fx.Produce.count(fx.data.produce) > 0):toBe(true)
		end)
	end)
end
