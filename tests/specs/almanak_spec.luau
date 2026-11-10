--!nocheck
-- The Almanak records every crop × tier × trait and rewards a cosmetic when a family page
-- completes. A double grant or a lost discovery is a player-facing bug, so both are covered.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, AlmanakService, Crops, AlmanakConfig, player, data, playerData, grants, touched

	local function record(cropId, tier, traits)
		return AlmanakService.record(player, cropId, tier, traits)
	end

	local function discoverFamily(familyId)
		for _, cropId in Crops.families[familyId] do
			record(cropId, "biasa", {})
		end
	end

	t:describe("AlmanakService", function()
		t:beforeEach(function()
			env = Env.new()
			playerData = Fakes.playerData()
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			grants = {}
			touched = {}

			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/State", {
				touch = function(_, section)
					table.insert(touched, section)
				end,
			})
			env:mock("server/Monetization/Cosmetics", {
				grant = function(_, itemId)
					grants[itemId] = (grants[itemId] or 0) + 1
					return true
				end,
			})

			AlmanakService = env:require("server/Progression/AlmanakService")
			Crops = env:require("shared/Config/Crops")
			AlmanakConfig = env:require("shared/Config/Almanak")
		end)

		t:describe("record", function()
			t:it("creates the crop entry on the first discovery", function()
				local discovery = record("padi", "biasa", {})
				expect(discovery.first):toBe(true)
				expect(discovery.newTier):toBe(true)
				expect(data.almanak.crops.padi.tiers.biasa):toBe(true)
				expect(data.almanak.crops.padi.count):toBe(1)
			end)

			t:it("does not report the same tier twice", function()
				record("padi", "biasa", {})
				local discovery = record("padi", "biasa", {})
				expect(discovery.first):toBe(false)
				expect(discovery.newTier):toBe(false)
				expect(data.almanak.crops.padi.count):toBe(2)
			end)

			t:it("reports a new tier", function()
				record("padi", "biasa", {})
				local discovery = record("padi", "sultan", {})
				expect(discovery.newTier):toBe(true)
				expect(data.almanak.crops.padi.tiers.sultan):toBe(true)
			end)

			t:it("reports only the new traits", function()
				record("padi", "biasa", { "basah" })
				local discovery = record("padi", "biasa", { "basah", "organik" })
				expect(discovery.newTraits):toEqual({ "organik" })
				expect(data.almanak.crops.padi.traits.basah):toBe(true)
				expect(data.almanak.crops.padi.traits.organik):toBe(true)
			end)

			t:it("ignores unknown crops and unknown traits", function()
				local unknown = record("nangka", "biasa", {})
				expect(unknown):toBeNil()
				local discovery = record("padi", "biasa", { "radioaktif" })
				expect(discovery.newTraits):toEqual({})
			end)

			t:it("ignores an unknown tier but still counts the harvest", function()
				local discovery = record("padi", "radioaktif", {})
				expect(discovery.newTier):toBe(false)
				expect(data.almanak.crops.padi.tiers.radioaktif):toBeNil()
				expect(data.almanak.crops.padi.count):toBe(1)
			end)

			t:it("touches the almanak state section", function()
				record("padi", "biasa", {})
				expect(touched[#touched]):toBe("almanak")
			end)
		end)

		t:describe("progress", function()
			t:it("counts discovered crops per family", function()
				local total = #Crops.families.palawija
				local found = AlmanakService.progress(data, "palawija")
				expect(found):toBe(0)
				record("padi", "biasa", {})
				found = AlmanakService.progress(data, "palawija")
				expect(found):toBe(1)
				local _, reportedTotal = AlmanakService.progress(data, "palawija")
				expect(reportedTotal):toBe(total)
			end)

			t:it("reports a page complete only when the whole family is found", function()
				local crops = Crops.families.palawija
				for index = 1, #crops - 1 do
					record(crops[index], "biasa", {})
				end
				expect(AlmanakService.isPageComplete(data, "palawija")):toBe(false)
				record(crops[#crops], "biasa", {})
				expect(AlmanakService.isPageComplete(data, "palawija")):toBe(true)
			end)

			t:it("does not count a page as complete for an empty family", function()
				expect(AlmanakService.isPageComplete(data, "tidakAda")):toBe(false)
			end)
		end)

		t:describe("page rewards", function()
			t:it("grants the page cosmetic once, on completion", function()
				local page = AlmanakConfig.pages.palawija
				discoverFamily("palawija")
				expect(grants[page.reward]):toBe(1)
				expect(data.almanak.pages.palawija):toBe(true)
			end)

			t:it("does not grant the reward again for later discoveries", function()
				local page = AlmanakConfig.pages.palawija
				discoverFamily("palawija")
				record("padi", "sultan", { "basah" })
				expect(grants[page.reward]):toBe(1)
			end)

			t:it("keeps pages independent", function()
				discoverFamily("palawija")
				expect(data.almanak.pages.palawija):toBe(true)
				expect(data.almanak.pages.kebun):toBeNil()
				expect(grants[AlmanakConfig.pages.kebun.reward]):toBeNil()
			end)
		end)
	end)
end
