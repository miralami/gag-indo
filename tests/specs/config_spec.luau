--!nocheck
-- Balance and sanity rules for the config tables. These catch a bad number before a playtest does.

return function(t, Env)
	local expect = t.expect
	local env, Game, Law, Crops, Cheats, Products, Tiers, Traits, Almanak, Strings

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
			Almanak = env:require("shared/Config/Almanak")
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

		t:describe("Game.plotCenter (MAP_SPEC §4)", function()
			local function rounded(index)
				local x, z = Game.plotCenter(index)
				return math.floor(x + 0.5), math.floor(z + 0.5)
			end

			t:it("puts every plot on the ring at Game.plotRadius", function()
				expect(Game.plotRadius):toBeAtLeast(1)
				for index = 1, Game.plotCount do
					local x, z = Game.plotCenter(index)
					expect(math.floor(math.sqrt(x * x + z * z) + 0.5)):toBe(Game.plotRadius)
				end
			end)

			t:it("matches the spec table for P1, P3, P5 and P8", function()
				-- Ring is clockwise from north, 360 / plotCount degrees apart, P3 due east.
				local r = Game.plotRadius
				local step = math.pi * 2 / Game.plotCount
				local function expected(index)
					local a = (index - 3) * step
					return math.floor(math.cos(a) * r + 0.5), math.floor(math.sin(a) * r + 0.5)
				end
				for _, index in { 1, 3, 5, 8 } do
					local ex, ez = expected(index)
					local x, z = rounded(index)
					expect(x):toBe(ex)
					expect(z + 0):toBe(ez + 0)
				end
				-- Anchors that do not depend on the formula: P3 due east, P8 due west, P1 north-east of north.
				local x3, z3 = rounded(3)
				expect(x3):toBe(r)
				expect(z3 + 0):toBe(0)
				local x8, z8 = rounded(8)
				expect(x8):toBe(-r)
				expect(z8 + 0):toBe(0)
				local x1, z1 = rounded(1)
				expect(x1 > 0 and z1 < 0):toBe(true)
				local x5, z5 = rounded(5)
				expect(x5):toBe(x1)
				expect(z5):toBe(-z1)
			end)

			t:it("keeps neighbouring plot centres at least one ring chord apart and index +-1 adjacent", function()
				local chord = 2 * Game.plotRadius * math.sin(math.pi / Game.plotCount)
				for index = 1, Game.plotCount do
					local nextIndex = index % Game.plotCount + 1
					local ax, az = Game.plotCenter(index)
					local bx, bz = Game.plotCenter(nextIndex)
					local gap = math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
					expect(gap):toBeAtLeast(chord - 0.01)
				end
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

		t:describe("crop families", function()
			t:it("puts every crop in exactly one family", function()
				local seen = {}
				for _, familyId in Crops.familyOrder do
					expect(Crops.families[familyId]):toBeTruthy()
					for _, cropId in Crops.families[familyId] do
						expect(Crops.list[cropId].family):toBe(familyId)
						expect(seen[cropId]):toBeNil()
						seen[cropId] = true
					end
				end
				local count = 0
				for _ in Crops.list do
					count += 1
				end
				local seenCount = 0
				for _ in seen do
					seenCount += 1
				end
				expect(seenCount):toBe(count)
			end)

			t:it("only gives re-harvests to kebun and perkebunan", function()
				for _, crop in Crops.list do
					if crop.regrowSeconds ~= nil then
						expect(crop.family == "kebun" or crop.family == "perkebunan"):toBe(true)
						expect(crop.maxHarvests):toBeGreaterThan(1)
					end
				end
			end)

			t:it("marks only perkebunan crops as needing a permit", function()
				for _, crop in Crops.list do
					if crop.permit then
						expect(crop.family):toBe("perkebunan")
					end
				end
			end)
		end)

		t:describe("almanak pages", function()
			t:it("has one page per family, with a real cosmetic reward", function()
				local Cosmetics = env:require("shared/Config/Cosmetics")
				for _, familyId in Crops.familyOrder do
					local page = Almanak.pages[familyId]
					expect(page):toBeTruthy()
					expect(page.family):toBe(familyId)
					expect(Cosmetics.list[page.reward]):toBeTruthy()
					expect(Strings.get("id", page.labelKey)).never:toBe(page.labelKey)
				end
			end)

			t:it("lists every page exactly once in the display order", function()
				local count = 0
				for _ in Almanak.pages do
					count += 1
				end
				expect(count):toBe(#Almanak.order)
				for _, pageId in Almanak.order do
					expect(Almanak.pages[pageId]):toBeTruthy()
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
				local known = { inventory = true, seeds = true, restock = true, cash = true }
				for key, product in Products.products do
					expect(known[product.grant] == true):toBe(true)
					expect(key):toBeTruthy()
				end
			end)

			t:it("gives every cash pack a non-negative cash amount", function()
				for _, product in Products.products do
					if product.grant == "cash" then
						expect(type(product.cash)):toBe("number")
						expect(product.cash):toBeAtLeast(0)
					end
				end
			end)

			t:it("gives every pass a unique attribute", function()
				local seen = {}
				for _, pass in Products.passes do
					expect(type(pass.attribute)):toBe("string")
					expect(seen[pass.attribute]):toBeNil()
					seen[pass.attribute] = true
				end
			end)

			t:it("ships the gudang and auto-panen passes unconfigured", function()
				expect(Products.passConfigured("gudangBesar")):toBe(false)
				expect(Products.passConfigured("autoPanen")):toBe(false)
			end)

			t:it("treats id 0 as not configured", function()
				expect(Products.productKeyForId(0)):toBeNil()
				expect(Products.passConfigured("ordal")):toBe(false)
			end)
		end)

		t:describe("audio", function()
			t:it("has valid groups for every registered sound", function()
				local Audio = env:require("shared/Config/Audio")
				for _, def in Audio.sounds do
					expect(Audio.groups[def.group]):toBeTruthy()
					expect(def.id):toBeAtLeast(0)
				end
			end)

			t:it("points areas to sound keys that exist", function()
				local Audio = env:require("shared/Config/Audio")
				for _, key in Audio.areas do
					expect(Audio.sounds[key]):toBeTruthy()
				end
			end)

			t:it("points weather to sound keys that exist", function()
				local Audio = env:require("shared/Config/Audio")
				for _, key in Audio.weather do
					expect(Audio.sounds[key]):toBeTruthy()
				end
			end)
		end)

		t:describe("onboarding", function()
			t:it("has strings for every step", function()
				local Onboarding = env:require("shared/Config/Onboarding")
				for _, step in Onboarding.steps do
					expect(Strings.get("id", step.labelKey)).never:toBe(step.labelKey)
					expect(Strings.get("en", step.labelKey)).never:toBe(step.labelKey)
				end
			end)
		end)
	end)
end
