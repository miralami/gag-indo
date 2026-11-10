--!nocheck
-- The rarity roll is the "wow" moment of M1. These tests pin the odds boundaries and prove
-- that minigame quality nudges the rare tiers without breaking the distribution.

return function(t, Env)
	local expect = t.expect
	local env, Rarity, Tiers

	local function roll(quality, value)
		return Rarity.roll(quality, function()
			return value
		end)
	end

	t:describe("RarityService", function()
		t:beforeEach(function()
			env = Env.new()
			Rarity = env:require("server/Farm/RarityService")
			Tiers = env:require("shared/Config/Tiers")
		end)

		t:describe("weight", function()
			t:it("uses the table chance for common tiers", function()
				expect(Rarity.weight("biasa", 0)):toBeNear(Tiers.list.biasa.chance)
				expect(Rarity.weight("bagus", 2)):toBeNear(Tiers.list.bagus.chance)
			end)

			t:it("uses the table chance for rare tiers at quality zero", function()
				expect(Rarity.weight("super", 0)):toBeNear(Tiers.list.super.chance)
			end)

			t:it("doubles the rare weight at quality one", function()
				expect(Rarity.weight("super", 1)):toBeNear(Tiers.list.super.chance * 2)
				expect(Rarity.weight("sultan", 1)):toBeNear(Tiers.list.sultan.chance * 2)
			end)

			t:it("treats a nil or broken quality as zero", function()
				expect(Rarity.weight("super", nil)):toBeNear(Tiers.list.super.chance)
				expect(Rarity.weight("super", 0 / 0)):toBeNear(Tiers.list.super.chance)
			end)
		end)

		t:describe("roll", function()
			t:it("walks the base table in order at quality zero", function()
				expect(roll(0, 0)):toBe("biasa")
				expect(roll(0, 0.69)):toBe("biasa")
				expect(roll(0, 0.701)):toBe("bagus")
				expect(roll(0, 0.901)):toBe("super")
				expect(roll(0, 0.976)):toBe("langka")
				expect(roll(0, 0.996)):toBe("sultan")
			end)

			t:it("turns a near miss into super when quality is high", function()
				-- 0.85 is a bagus roll at base odds; the quality boost pushes it into super.
				expect(roll(0, 0.85)):toBe("bagus")
				expect(roll(1, 0.85)):toBe("super")
			end)

			t:it("clamps rolls outside 0..1", function()
				expect(roll(0, -5)):toBe("biasa")
				expect(roll(0, 5)):toBe("sultan")
			end)

			t:it("treats invalid quality as zero", function()
				expect(roll(nil, 0.85)):toBe("bagus")
				expect(roll(0 / 0, 0.85)):toBe("bagus")
			end)

			t:it("always returns a real tier", function()
				for _, tierId in Tiers.order do
					expect(Tiers.exists(tierId)):toBe(true)
				end
				for step = 0, 99 do
					local tier = roll(1, step / 100)
					expect(Tiers.exists(tier)):toBe(true)
				end
			end)
		end)
	end)
end
