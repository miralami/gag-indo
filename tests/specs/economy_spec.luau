--!nocheck
return function(t, Env, Fakes)
	local expect = t.expect
	local env, Crops, GameConfig, Cheats, Economy, Produce, Inventory, notify, rateLimit, remotes, cabai, player, data

	local PASAR = nil
	local GELAP = nil

	local function setStack(cropId, count, qualitySum, hot)
		local traits = if hot then { "oplosan" } else {}
		data.produce[Produce.key(cropId, "biasa", traits)] = {
			crop = cropId,
			tier = "biasa",
			traits = traits,
			count = count,
			qualitySum = qualitySum,
		}
	end

	local function getStack(cropId, hot)
		return data.produce[Produce.key(cropId, "biasa", if hot then { "oplosan" } else {})]
	end

	t:describe("EconomyService", function()
		t:beforeEach(function()
			env = Env.new()
			Crops = env:require("shared/Config/Crops")
			GameConfig = env:require("shared/Config/Game")
			Cheats = env:require("shared/Config/Cheats")
			Produce = env:require("shared/Produce")
			Inventory = env:require("shared/Inventory")

			PASAR = env.Vector3.new(10, 0, 0)
			GELAP = env.Vector3.new(-50, 0, 0)

			local playerData = Fakes.playerData()
			notify = Fakes.notify()
			rateLimit = Fakes.rateLimit(true)
			remotes = Fakes.remotes(env)
			cabai = { value = 1 }
			function cabai.multiplier(cropId)
				return if cropId == "cabai" then cabai.value else 1
			end
			function cabai.isActive()
				return cabai.value > 1
			end
			function cabai.start() end

			env:mock("shared/Remotes", remotes)
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/RateLimit", rateLimit)
			env:mock("server/Analytics/Analytics", Fakes.analytics())
			env:mock("server/Events/CabaiEvent", cabai)
			env:mock("server/World/Village", {
				getPosition = function(name)
					return if name == "gelap" then GELAP else PASAR
				end,
				onPasar = function() end,
			})
			Economy = env:require("server/Economy/EconomyService")

			player = Fakes.player(env, { position = PASAR })
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("addCash", function()
			t:it("adds cash and counts earned money toward lifetime income", function()
				Economy.addCash(player, 100, true)
				expect(data.cash):toBe(GameConfig.startCash + 100)
				expect(data.lifetimeEarned):toBe(100)
			end)

			t:it("does not count non-income cash (refunds, transfers) as earned", function()
				Economy.addCash(player, 100, false)
				expect(data.cash):toBe(GameConfig.startCash + 100)
				expect(data.lifetimeEarned):toBe(0)
			end)

			t:it("rejects zero, negative, NaN and infinite amounts", function()
				Economy.addCash(player, 0, true)
				Economy.addCash(player, -10, true)
				Economy.addCash(player, 0 / 0, true)
				Economy.addCash(player, math.huge, true)
				expect(data.cash):toBe(GameConfig.startCash)
			end)

			t:it("floors fractional amounts so cash stays whole", function()
				Economy.addCash(player, 10.9, true)
				expect(data.cash):toBe(GameConfig.startCash + 10)
			end)

			t:it("promotes the player once lifetime income passes the rank threshold", function()
				Economy.addCash(player, GameConfig.rankRequirements.petani.lifetimeEarned, true)
				expect(data.rank):toBe("petani")
				expect(player:GetAttribute("Rank")):toBe("petani")
			end)

			t:it("mirrors cash onto the player attribute for the HUD", function()
				Economy.addCash(player, 25, true)
				expect(player:GetAttribute("Cash")):toBe(GameConfig.startCash + 25)
			end)
		end)

		t:describe("trySpend", function()
			t:it("deducts and returns true when the player can afford it", function()
				expect(Economy.trySpend(player, 20)):toBe(true)
				expect(data.cash):toBe(GameConfig.startCash - 20)
			end)

			t:it("allows spending exactly all the cash", function()
				expect(Economy.trySpend(player, GameConfig.startCash)):toBe(true)
				expect(data.cash):toBe(0)
			end)

			t:it("refuses, keeps the cash and shows a toast when too poor", function()
				expect(Economy.trySpend(player, GameConfig.startCash + 1)):toBe(false)
				expect(data.cash):toBe(GameConfig.startCash)
				expect(notify.keys(player)):toContain("n_not_enough_cash")
			end)

			t:it("refuses negative and NaN amounts (no free money)", function()
				expect(Economy.trySpend(player, -50)):toBe(false)
				expect(Economy.trySpend(player, 0 / 0)):toBe(false)
				expect(data.cash):toBe(GameConfig.startCash)
			end)
		end)

		t:describe("transfer", function()
			local other, otherData

			t:beforeEach(function()
				other = Fakes.player(env)
				otherData = Fakes.newData(env)
				env:require("server/Data/PlayerData").set(other, otherData)
			end)

			t:it("moves money without creating any", function()
				local total = data.cash + otherData.cash
				expect(Economy.transfer(player, other, 30)):toBe(30)
				expect(data.cash + otherData.cash):toBe(total)
			end)

			t:it("moves at most what the sender has", function()
				expect(Economy.transfer(player, other, 99999)):toBe(GameConfig.startCash)
				expect(data.cash):toBe(0)
			end)

			t:it("moves nothing for invalid amounts", function()
				expect(Economy.transfer(player, other, -10)):toBe(0)
				expect(Economy.transfer(player, other, 0 / 0)):toBe(0)
				expect(data.cash):toBe(GameConfig.startCash)
			end)
		end)

		t:describe("harvest sack", function()
			t:it("keeps clean and hot quality in separate stacks", function()
				Economy.addHarvest(player, "padi", 1, false)
				Economy.addHarvest(player, "padi", 0.5, true)
				local clean = getStack("padi", false)
				local hot = getStack("padi", true)
				expect(clean.count):toBe(1)
				expect(clean.qualitySum):toBeNear(1)
				expect(hot.count):toBe(1)
				expect(hot.qualitySum):toBeNear(0.5)
			end)

			t:it("ignores crops that do not exist", function()
				Economy.addHarvest(player, "tembakau", 1, false)
				expect(next(data.produce)):toBeNil()
			end)

			t:it("reports the total number of items on the HUD", function()
				Economy.addHarvest(player, "padi", 1, false)
				Economy.addHarvest(player, "jagung", 1, true)
				expect(player:GetAttribute("HarvestCount")):toBe(2)
			end)

			t:it("removes only hot produce when confiscating", function()
				setStack("padi", 2, 2.0, false)
				setStack("padi", 1, 0.9, true)
				setStack("jagung", 2, 1.8, true)
				expect(Economy.removeHotHarvest(player)):toBe(3)
				expect(getStack("padi", false).count):toBe(2)
				expect(getStack("padi", true)):toBeNil()
				expect(getStack("jagung", true)):toBeNil()
			end)

			t:it("confiscates nothing from a clean sack", function()
				setStack("padi", 3, 2.7, false)
				expect(Economy.removeHotHarvest(player)):toBe(0)
				expect(getStack("padi", false).count):toBe(3)
			end)
		end)

		t:describe("sellAll at the Pasar", function()
			t:it("pays base price times total quality", function()
				setStack("padi", 2, 1.8, false)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash + math.floor(Crops.list.padi.sellPrice * 1.8))
			end)

			t:it("counts the sale as earned income", function()
				setStack("padi", 2, 2, false)
				Economy.sellAll(player, "pasar")
				expect(data.lifetimeEarned):toBe(Crops.list.padi.sellPrice * 2)
			end)

			t:it("empties the sack when everything was clean", function()
				setStack("padi", 2, 2, false)
				Economy.sellAll(player, "pasar")
				expect(next(data.produce)):toBeNil()
				expect(player:GetAttribute("HarvestCount")):toBe(0)
			end)

			-- Regression: commit f0443f8 "Fix Pasar sale leaving clean produce count in the sack".
			t:it("leaves only the hot items in the sack after selling the clean ones", function()
				setStack("padi", 3, 3.0, false)
				setStack("padi", 2, 1.2, true)
				Economy.sellAll(player, "pasar")
				expect(getStack("padi", false)):toBeNil()
				expect(getStack("padi", true).count):toBe(2)
				expect(getStack("padi", true).qualitySum):toBeNear(1.2)
				expect(player:GetAttribute("HarvestCount")):toBe(2)
			end)

			t:it("pays only for the clean produce when hot produce is also in the sack", function()
				setStack("padi", 3, 3.0, false)
				setStack("padi", 2, 1.2, true)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash + math.floor(Crops.list.padi.sellPrice * 3.0))
			end)

			t:it("refuses a sack that is only hot produce", function()
				setStack("padi", 2, 1.8, true)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash)
				expect(notify.keys(player)):toContain("n_hot_pasar")
				expect(getStack("padi", true).count):toBe(2)
			end)

			t:it("says there is nothing to sell for an empty sack", function()
				Economy.sellAll(player, "pasar")
				expect(notify.keys(player)):toContain("n_nothing_to_sell")
			end)

			t:it("refuses when the player stands too far from the market", function()
				setStack("padi", 2, 2, false)
				player.Character.HumanoidRootPart.Position = env.Vector3.new(500, 0, 0)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash)
				expect(notify.keys(player)):toContain("n_too_far")
				expect(getStack("padi", false).count):toBe(2)
			end)

			t:it("refuses when rate limited", function()
				setStack("padi", 2, 2, false)
				rateLimit.allow = function()
					return false
				end
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash)
			end)

			t:it("gives the Ordal pass holder 10% more", function()
				player:SetAttribute("Pass_Ordal", true)
				setStack("jagung", 2, 2, false)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash + math.floor(Crops.list.jagung.sellPrice * 2 * 1.1))
			end)

			t:it("applies the Harga Cabai Meroket multiplier to cabai only", function()
				cabai.value = GameConfig.cabaiEventMultiplier
				setStack("cabai", 1, 1, false)
				setStack("padi", 1, 1, false)
				Economy.sellAll(player, "pasar")
				local expected = Crops.list.cabai.sellPrice * GameConfig.cabaiEventMultiplier + Crops.list.padi.sellPrice
				expect(data.cash):toBe(GameConfig.startCash + expected)
			end)

			t:it("pays normal cabai price when the event is off", function()
				setStack("cabai", 1, 1, false)
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash + Crops.list.cabai.sellPrice)
			end)

			t:it("applies the rarity tier multiplier (M1 seam, sultan = x25)", function()
				data.produce[Produce.key("padi", "sultan", {})] = {
					crop = "padi",
					tier = "sultan",
					traits = {},
					count = 1,
					qualitySum = 1,
				}
				Economy.sellAll(player, "pasar")
				expect(data.cash):toBe(GameConfig.startCash + Crops.list.padi.sellPrice * 25)
			end)
		end)

		t:describe("sellAll to the Tengkulak Gelap", function()
			local handlerCalls

			t:beforeEach(function()
				handlerCalls = {}
				Economy.onCheatSale(function(who, cheatId, value, position)
					table.insert(handlerCalls, { player = who, cheatId = cheatId, value = value, position = position })
				end)
				player.Character.HumanoidRootPart.Position = GELAP
			end)

			t:it("pays the black market premium on clean and hot produce", function()
				setStack("padi", 1, 1.0, false)
				setStack("padi", 2, 1.8, true)
				Economy.sellAll(player, "gelap")
				local base = Crops.list.padi.sellPrice * (1.0 + 1.8)
				expect(data.cash):toBe(GameConfig.startCash + math.floor(base * Cheats.list.gelap.priceMultiplier))
			end)

			t:it("empties the whole sack", function()
				setStack("padi", 1, 1.0, false)
				setStack("padi", 2, 1.8, true)
				Economy.sellAll(player, "gelap")
				expect(next(data.produce)):toBeNil()
			end)

			t:it("reports only the extra profit to the cheat handler", function()
				setStack("padi", 2, 2, false)
				Economy.sellAll(player, "gelap")
				local base = Crops.list.padi.sellPrice * 2
				local extra = math.floor(base * Cheats.list.gelap.priceMultiplier - base)
				expect(#handlerCalls):toBe(1)
				expect(handlerCalls[1].cheatId):toBe("gelap")
				expect(handlerCalls[1].value):toBe(extra)
			end)

			t:it("does nothing with an empty sack", function()
				Economy.sellAll(player, "gelap")
				expect(#handlerCalls):toBe(0)
				expect(notify.keys(player)):toContain("n_nothing_to_sell")
			end)

			t:it("does not accept a sale from the Pasar spot", function()
				setStack("padi", 2, 2, false)
				player.Character.HumanoidRootPart.Position = PASAR
				Economy.sellAll(player, "gelap")
				expect(notify.keys(player)):toContain("n_too_far")
				expect(getStack("padi", false).count):toBe(2)
			end)
		end)

		t:describe("seed purchases (v3 items)", function()
			t:it("adds seeds to items and mirrors the Seed attribute", function()
				Economy.start()
				local before = Inventory.getSeed(data, "padi")
				remotes.Shop_BuySeed.OnServerEvent:Fire(player, "padi", 2)
				expect(Inventory.getSeed(data, "padi")):toBe(before + 2)
				expect(player:GetAttribute("Seed_padi")):toBe(before + 2)
				expect(data.cash):toBe(GameConfig.startCash - Crops.list.padi.seedCost * 2)
			end)
		end)
	end)
end
