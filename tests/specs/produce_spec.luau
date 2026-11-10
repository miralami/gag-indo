--!nocheck
-- Produce stacks (v3 schema). The key format is the save format, so these tests are
-- really about "can a save from today still be read after a refactor?".

return function(t, Env)
	local expect = t.expect
	local env, Produce, Tiers

	t:describe("Produce", function()
		t:beforeEach(function()
			env = Env.new()
			Produce = env:require("shared/Produce")
			Tiers = env:require("shared/Config/Tiers")
		end)

		t:describe("keys", function()
			t:it("joins crop, tier and traits with pipes", function()
				expect(Produce.key("padi", "biasa", {})):toBe("padi|biasa|")
			end)

			t:it("sorts traits so the same stack always gets the same key", function()
				expect(Produce.key("padi", "biasa", { "kering", "oplosan" })):toBe(
					Produce.key("padi", "biasa", { "oplosan", "kering" })
				)
				expect(Produce.key("padi", "biasa", { "kering", "oplosan" })):toBe("padi|biasa|kering+oplosan")
			end)

			t:it("drops unknown traits", function()
				expect(Produce.key("padi", "biasa", { "oplosan", "radioaktif" })):toBe("padi|biasa|oplosan")
			end)

			t:it("de-duplicates repeated traits", function()
				expect(Produce.key("padi", "biasa", { "oplosan", "oplosan" })):toBe("padi|biasa|oplosan")
			end)

			t:it("falls back to the default tier for unknown or missing tiers", function()
				expect(Produce.key("padi", nil, {})):toBe("padi|" .. Tiers.default .. "|")
				expect(Produce.key("padi", "dewa", {})):toBe("padi|" .. Tiers.default .. "|")
			end)

			t:it("parses a key back into crop, tier and traits", function()
				local cropId, tier, traits = Produce.parse("durian|langka|oplosan+organik")
				expect(cropId):toBe("durian")
				expect(tier):toBe("langka")
				expect(traits):toEqual({ "oplosan", "organik" })
			end)

			t:it("returns nil for a malformed key", function()
				local cropId = Produce.parse("nonsense")
				expect(cropId):toBeNil()
			end)

			t:it("drops unknown traits when parsing and repairs a bad tier", function()
				local _, tier, traits = Produce.parse("padi|dewa|oplosan+radioaktif")
				expect(tier):toBe(Tiers.default)
				expect(traits):toEqual({ "oplosan" })
			end)
		end)

		t:describe("add", function()
			t:it("creates a stack with one item", function()
				local sack = {}
				local stack = Produce.add(sack, "padi", 0.8)
				expect(stack.crop):toBe("padi")
				expect(stack.tier):toBe(Tiers.default)
				expect(stack.count):toBe(1)
				expect(stack.qualitySum):toBeNear(0.8)
				expect(sack[Produce.key("padi", Tiers.default, {})]):toBe(stack)
			end)

			t:it("adds to the same stack for the same crop, tier and traits", function()
				local sack = {}
				Produce.add(sack, "padi", 0.5)
				Produce.add(sack, "padi", 0.25)
				local stack = sack[Produce.key("padi", Tiers.default, {})]
				expect(stack.count):toBe(2)
				expect(stack.qualitySum):toBeNear(0.75)
			end)

			t:it("keeps different tiers apart", function()
				local sack = {}
				Produce.add(sack, "padi", 1, { tier = "biasa" })
				Produce.add(sack, "padi", 1, { tier = "sultan" })
				expect(Produce.count(sack)):toBe(2)
				expect(sack[Produce.key("padi", "sultan", {})].count):toBe(1)
			end)

			t:it("keeps hot and clean produce apart", function()
				local sack = {}
				Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				Produce.add(sack, "padi", 1)
				expect(Produce.count(sack)):toBe(2)
				expect(sack[Produce.key("padi", "biasa", { "oplosan" })].count):toBe(1)
				expect(sack[Produce.key("padi", "biasa", {})].count):toBe(1)
			end)

			t:it("always stores traits sorted", function()
				local sack = {}
				Produce.add(sack, "padi", 1, { traits = { "organik", "basah" } })
				expect(sack[Produce.key("padi", "biasa", { "basah", "organik" })].traits):toEqual({ "basah", "organik" })
			end)
		end)

		t:describe("hot produce", function()
			t:it("treats the oplosan trait as hot", function()
				local sack = {}
				local stack = Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				expect(Produce.isHot(stack)):toBe(true)
				expect(Produce.hasTrait(stack, "oplosan")):toBe(true)
			end)

			t:it("treats clean produce as not hot", function()
				local sack = {}
				local stack = Produce.add(sack, "padi", 1, { traits = { "organik" } })
				expect(Produce.isHot(stack)):toBe(false)
			end)

			t:it("removes only hot stacks", function()
				local sack = {}
				Produce.add(sack, "padi", 1)
				Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				expect(Produce.removeHot(sack)):toBe(2)
				expect(Produce.count(sack)):toBe(1)
				expect(sack[Produce.key("padi", "biasa", {})].count):toBe(1)
			end)

			t:it("removes only clean stacks", function()
				local sack = {}
				Produce.add(sack, "padi", 1)
				Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				expect(Produce.removeClean(sack)):toBe(1)
				expect(Produce.count(sack)):toBe(1)
				expect(sack[Produce.key("padi", "biasa", { "oplosan" })]):toBeTruthy()
			end)

			t:it("counts nothing in an empty sack", function()
				expect(Produce.count({})):toBe(0)
				expect(Produce.removeHot({})):toBe(0)
				expect(Produce.removeClean({})):toBe(0)
			end)
		end)

		t:describe("snapshot", function()
			t:it("copies stacks so the save data stays private", function()
				local sack = {}
				Produce.add(sack, "padi", 1)
				local copy = Produce.snapshot(sack)
				copy[Produce.key("padi", "biasa", {})].count = 99
				expect(Produce.count(sack)):toBe(1)
			end)

			t:it("copies the trait list too", function()
				local sack = {}
				Produce.add(sack, "padi", 1, { traits = { "oplosan" } })
				local copy = Produce.snapshot(sack)
				table.insert(copy[Produce.key("padi", "biasa", { "oplosan" })].traits, "basah")
				expect(#sack[Produce.key("padi", "biasa", { "oplosan" })].traits):toBe(1)
			end)
		end)

		t:describe("clear", function()
			t:it("empties the sack", function()
				local sack = {}
				Produce.add(sack, "padi", 1)
				Produce.add(sack, "jagung", 1)
				Produce.clear(sack)
				expect(next(sack)):toBeNil()
			end)
		end)
	end)
end
