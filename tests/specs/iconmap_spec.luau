--!nocheck
-- IconMap spec: shared icon slots for crops, currency, tiers and phone apps.

return function(t, Env)
	local expect = t.expect
	local env, IconMap

	t:describe("IconMap", function()
		t:beforeEach(function()
			env = Env.new()
			IconMap = env:require("shared/IconMap")
		end)

		t:it("maps every crop to an empty slot with a fallback and TODO-friendly id", function()
			local crops = { "padi", "singkong", "jagung", "bawang", "cabai", "tembakau", "kopi", "tebu", "kakao", "cengkeh", "durian", "sawit" }
			for _, cropId in crops do
				local entry = IconMap.crops[cropId]
				expect(entry ~= nil):toBe(true)
				expect(entry.id):toBe(0)
				expect(entry.slot):toBe("crop_" .. cropId)
				expect(type(entry.fallback) == "string" and #entry.fallback > 0):toBe(true)
				expect(IconMap.cropSlot(cropId)):toBe(entry.slot)
			end
		end)

		t:it("maps currency, tiers and phone apps to slots with empty ids", function()
			expect(IconMap.currency.cash.id):toBe(0)
			expect(IconMap.currencySlot("cash")):toBe("cash")
			expect(IconMap.currency.rupiah.slot):toBe("currency_rupiah")

			for _, tier in { "biasa", "bagus", "super", "langka", "sultan" } do
				expect(IconMap.tiers[tier].id):toBe(0)
				expect(IconMap.tierSlot(tier)):toBe("tier_" .. tier)
			end

			local apps = {
				phone = "phone",
				kebun = "garden",
				pinjol = "debt",
				tugas = "quest",
				cheat = "cheat",
				dekor = "hat",
				shop = "shop",
				board = "trophy",
			}
			for appId, slot in apps do
				expect(IconMap.phoneApps[appId].id):toBe(0)
				expect(IconMap.phoneApps[appId].slot):toBe(slot)
				expect(IconMap.phoneAppSlot(appId)):toBe(slot)
			end
		end)

		t:it("applies fallbacks into a visuals icon table without overwriting filled ids", function()
			local visuals = {
				icons = {
					crop_padi = { id = 12345, text = "*", token = "padi" },
					cash = { id = 0, text = "Rp", token = "kunyit" },
				},
			}
			IconMap.apply(visuals)
			expect(visuals.icons.crop_padi.id):toBe(12345)
			expect(type(visuals.icons.crop_padi.text) == "string"):toBe(true)
			expect(visuals.icons.cash.text):toBe("Rp")
			expect(visuals.icons.tier_sultan.id):toBe(0)
			expect(visuals.icons.phone.slot == nil):toBe(true) -- stored under slot key in icons table
			expect(visuals.icons.phone.id):toBe(0)
			expect(visuals.icons.phone.text):toBe("HP")
		end)
	end)
end
