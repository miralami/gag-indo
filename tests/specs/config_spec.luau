--!nocheck
-- Balance and sanity rules for the config tables. These catch a bad number before a playtest does.

return function(t, Env)
	local expect = t.expect
	local env, Game, Law, Crops, Cheats, Products, Tiers, Traits, Strings

	t:describe("Config", function()
		t:beforeEach(function()
			env = Env.new()
			Game = env:require("shared/Config/Game")
			Law = env:require("shared/Config/Law")
			Crops = env:require("shared/Config/Crops")
			Cheats = env:require("shared/Config/Cheats")
			Products = env:require("shared/Config/Products")
			Tiers = env:require("shared/Config/Tiers")
			Traits = env:require("shared/Config/Traits")
			Strings = env:require("shared/Strings")
		end)

		t:describe("Game.tilePrice", function()
			t:it("costs 100 for the first tile beyond the starting plots", function()
				expect(Game.tilePrice(Game.startTiles)):toBe(100)
			end)

			t:it("doubles with every tile owned", function()
				expect(Game.tilePrice(Game.startTiles + 1)):toBe(200)
				expect(Game.tilePrice(Game.startTiles + 2)):toBe(400)
			end)

			t:it("never goes below 100 even with fewer tiles than the start", function()
				expect(Game.tilePrice(0)):toBe(100)
			end)
		end)

		t:describe("tiles", function()
			t:it("lets every plot model hold the pass maximum", function()
				expect(Game.tilesBuilt):toBeAtLeast(Game.maxTilesWithPass)
			end)

			t:it("starts below the cap", function()
				expect(Game.startTiles):toBeLessThan(Game.maxTiles)
				expect(Game.maxTiles):toBeLessThan(Game.maxTilesWithPass)
			end)
		end)

		t:describe("ranks", function()
			t:it("has a requirement for every rank except the first", function()
				for index, rank in Game.rankOrder do
					expect(Game.rankIndex[rank]):toBe(index)
					if index > 1 then
						expect(Game.rankRequirements[rank]):toBeTruthy()
					end
				end
			end)

			t:it("asks for more lifetime income at every step up", function()
				local previous = 0
				for index = 2, #Game.rankOrder do
					local needed = Game.rankRequirements[Game.rankOrder[index]].lifetimeEarned
					expect(needed):toBeGreaterThan(previous)
					previous = needed
				end
			end)

			t:it("never asks for more tiles than a player without the pass can own", function()
				for _, requirement in Game.rankRequirements do
					expect(requirement.tilesOwned):toBeAtMost(Game.maxTiles)
				end
			end)
		end)

		t:describe("crops", function()
			t:it("lists every crop in the display order exactly once", function()
				local seen = {}
				for _, cropId in Crops.order do
					expect(Crops.list[cropId]):toBeTruthy()
					expect(seen[cropId]):toBeNil()
					seen[cropId] = true
				end
				local count = 0
				for _ in Crops.list do
					count += 1
				end
				expect(count):toBe(#Crops.order)
			end)

			t:it("pays more than the seed costs (otherwise farming loses money)", function()
				for cropId, crop in Crops.list do
					expect(crop.sellPrice):toBeGreaterThan(crop.seedCost)
				end
			end)

			t:it("takes longer to grow the more expensive the crop is", function()
				local previous = 0
				for _, cropId in Crops.order do
					expect(Crops.list[cropId].growSeconds):toBeGreaterThan(previous)
					previous = Crops.list[cropId].growSeconds
				end
			end)

			t:it("only uses ranks that exist", function()
				for _, crop in Crops.list do
					expect(Game.rankIndex[crop.rank]):toBeTruthy()
				end
			end)

			t:it("lets a brand new player plant the starting seeds", function()
				for cropId in Game.startSeeds do
					expect(Crops.list[cropId].rank):toBe(Game.rankOrder[1])
				end
			end)
		end)

		t:describe("law", function()
			t:it("orders the Sus thresholds gossip < letter < raid rolls < max", function()
				expect(Law.gossipSus):toBeLessThan(Law.letterSus)
				expect(Law.letterSus):toBeLessThan(Law.raidChanceSus)
				expect(Law.raidChanceSus):toBeLessThan(Law.susMax)
			end)

			t:it("resets Sus below the raid zone after a raid", function()
				expect(Law.raidResetSus):toBeLessThan(Law.raidChanceSus)
			end)

			t:it("keeps probabilities between 0 and 1", function()
				expect(Law.raidChance):toBeAtLeast(0)
				expect(Law.raidChance):toBeAtMost(1)
				expect(Law.amplopSuccess):toBeAtLeast(0)
				expect(Law.amplopSuccess):toBeAtMost(1)
			end)

			t:it("makes a failed bribe cost more than paying the fine", function()
				expect(Law.amplopFailMultiplier):toBeGreaterThan(1)
			end)

			t:it("has a sane fine range", function()
				expect(Law.fineMin):toBeGreaterThan(0)
				expect(Law.fineMax):toBeGreaterThan(Law.fineMin)
			end)

			t:it("starts Nama Baik inside its range", function()
				expect(Law.namaBaikStart):toBeAtLeast(0)
				expect(Law.namaBaikStart):toBeAtMost(Law.namaBaikMax)
			end)

			t:it("needs at least two distinct reporters for a viral report", function()
				expect(Law.viralReporters):toBeAtLeast(2)
			end)
		end)

		t:describe("cheats", function()
			t:it("gives every cheat a positive Sus cost", function()
				for _, cheat in Cheats.list do
					expect(cheat.sus):toBeGreaterThan(0)
				end
			end)

			t:it("lists only cheats that exist in the order table", function()
				for _, cheatId in Cheats.order do
					expect(Cheats.list[cheatId]):toBeTruthy()
				end
			end)

			t:it("sells to the black market at a premium", function()
				expect(Cheats.list.gelap.priceMultiplier):toBeGreaterThan(1)
			end)
		end)

		t:describe("rarity tiers", function()
			t:it("lists every tier in the display order exactly once", function()
				local seen = {}
				for _, tierId in Tiers.order do
					expect(Tiers.list[tierId]):toBeTruthy()
					expect(seen[tierId]):toBeNil()
					seen[tierId] = true
				end
				local count = 0
				for _ in Tiers.list do
					count += 1
				end
				expect(count):toBe(#Tiers.order)
			end)

			t:it("has roll chances that sum to one", function()
				local total = 0
				for _, tier in Tiers.list do
					expect(tier.chance):toBeGreaterThan(0)
					total += tier.chance
				end
				expect(total):toBeNear(1, 1e-9)
			end)

			t:it("pays more for rarer tiers", function()
				local previous = 0
				for _, tierId in Tiers.order do
					local multiplier = Tiers.list[tierId].valueMultiplier
					expect(multiplier):toBeGreaterThan(previous)
					previous = multiplier
				end
			end)

			t:it("defaults to a tier that exists and pays exactly the base price", function()
				expect(Tiers.list[Tiers.default]):toBeTruthy()
				expect(Tiers.multiplier(Tiers.default)):toBe(1)
			end)

			t:it("treats an unknown tier as the base multiplier", function()
				expect(Tiers.multiplier("dewa")):toBe(1)
				expect(Tiers.multiplier(nil)):toBe(1)
				expect(Tiers.exists("dewa")):toBe(false)
			end)

			t:it("has a string for every tier", function()
				for _, tier in Tiers.list do
					expect(Strings.get("id", tier.labelKey)).never:toBe(tier.labelKey)
					expect(Strings.get("en", tier.labelKey)).never:toBe(tier.labelKey)
				end
			end)
		end)

		t:describe("traits", function()
			t:it("lists every trait exactly once", function()
				local count = 0
				for _ in Traits.list do
					count += 1
				end
				expect(count):toBe(#Traits.order)
				for _, traitId in Traits.order do
					expect(Traits.list[traitId]):toBeTruthy()
				end
			end)

			t:it("has exactly one hot trait, and it is oplosan", function()
				local hotCount = 0
				for traitId, trait in Traits.list do
					if trait.hot then
						hotCount += 1
						expect(traitId):toBe(Traits.hotTrait)
					end
				end
				expect(hotCount):toBe(1)
			end)

			t:it("has a string for every trait", function()
				for _, trait in Traits.list do
					expect(Strings.get("id", trait.labelKey)).never:toBe(trait.labelKey)
					expect(Strings.get("en", trait.labelKey)).never:toBe(trait.labelKey)
				end
			end)

			t:it("rejects unknown trait ids", function()
				expect(Traits.exists("radioaktif")):toBe(false)
				expect(Traits.exists(nil)):toBe(false)
			end)
		end)

		t:describe("cabai event", function()
			t:it("boosts the price and ends before the next one starts", function()
				expect(Game.cabaiEventMultiplier):toBeGreaterThan(1)
				expect(Game.cabaiEventDuration):toBeLessThan(Game.cabaiEventInterval)
			end)
		end)

		t:describe("products", function()
			t:it("only grants seeds for crops that exist", function()
				for _, product in Products.products do
					if product.grant == "seeds" then
						for cropId in product.seeds do
							expect(Crops.list[cropId]):toBeTruthy()
						end
					end
				end
			end)

			t:it("has a known grant type for every product", function()
				for _, product in Products.products do
					expect(product.grant == "inventory" or product.grant == "seeds"):toBe(true)
				end
			end)

			t:it("treats id 0 as not configured", function()
				expect(Products.productKeyForId(0)):toBeNil()
				expect(Products.passConfigured("ordal")):toBe(false)
			end)
		end)
	end)
end
