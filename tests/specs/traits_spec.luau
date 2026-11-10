--!nocheck
-- Traits come from conditions, not luck alone. These tests pin which condition opens which
-- trait and that the chance roll still applies.

return function(t, Env)
	local expect = t.expect
	local env, TraitService, Traits

	-- rng that returns the given values in order, then zero forever.
	local function sequence(values)
		local index = 0
		return function()
			index += 1
			return values[index] or 0
		end
	end

	t:describe("TraitService", function()
		t:beforeEach(function()
			env = Env.new()
			TraitService = env:require("server/Farm/TraitService")
			Traits = env:require("shared/Config/Traits")
		end)

		t:describe("roll", function()
			t:it("always adds oplosan to a hot tile", function()
				local rolled = TraitService.roll({ hot = true }, sequence({ 1, 1, 1 }))
				expect(table.find(rolled, "oplosan")):toBeTruthy()
			end)

			t:it("never adds oplosan to a clean tile", function()
				local rolled = TraitService.roll({ hot = false }, sequence({ 1, 1, 1 }))
				expect(table.find(rolled, "oplosan")):toBeNil()
			end)

			t:it("rolls basah only in rain or a storm", function()
				expect(table.find(TraitService.roll({ weather = "hujan" }, sequence({ 0 })), "basah")):toBeTruthy()
				expect(table.find(TraitService.roll({ weather = "badai" }, sequence({ 0 })), "basah")):toBeTruthy()
				expect(table.find(TraitService.roll({ weather = "cerah" }, sequence({ 0 })), "basah")):toBeNil()
			end)

			t:it("rolls kering only during El Nino", function()
				expect(table.find(TraitService.roll({ anomaly = "elNino" }, sequence({ 0, 0 })), "kering")):toBeTruthy()
				expect(table.find(TraitService.roll({ anomaly = "none" }, sequence({ 0, 0 })), "kering")):toBeNil()
			end)

			t:it("rolls organik only when the plot was never fertilised", function()
				expect(table.find(TraitService.roll({ fertilised = false }, sequence({ 0, 0, 0 })), "organik")):toBeTruthy()
				expect(table.find(TraitService.roll({ fertilised = true }, sequence({ 0, 0, 0 })), "organik")):toBeNil()
			end)

			t:it("always adds bersertifikat when a stamp was applied", function()
				local rolled = TraitService.roll({ certified = true }, sequence({ 1, 1, 1 }))
				expect(table.find(rolled, "bersertifikat")):toBeTruthy()
			end)

			t:it("honours each trait's chance", function()
				local chance = Traits.list.basah.chance
				expect(table.find(TraitService.roll({ weather = "hujan" }, sequence({ chance - 0.01 })), "basah")):toBeTruthy()
				expect(table.find(TraitService.roll({ weather = "hujan" }, sequence({ chance })), "basah")):toBeNil()
			end)

			t:it("stacks several conditions", function()
				local rolled = TraitService.roll(
					{ hot = true, weather = "hujan", anomaly = "elNino", fertilised = false, certified = true },
					sequence({ 0, 0, 0 })
				)
				expect(rolled):toEqual({ "basah", "bersertifikat", "kering", "oplosan", "organik" })
			end)

			t:it("returns a sorted list", function()
				local rolled = TraitService.roll({ hot = true, weather = "hujan" }, sequence({ 0 }))
				local copy = table.clone(rolled)
				table.sort(copy)
				expect(rolled):toEqual(copy)
			end)

			t:it("copes with a nil context", function()
				expect(TraitService.roll(nil, sequence({ 1, 1, 1 }))):toEqual({})
			end)
		end)

		t:describe("eligible", function()
			t:it("lists every condition that is met, before the chance roll", function()
				local list = TraitService.eligible({ hot = true, weather = "hujan", certified = true })
				expect(table.find(list, "oplosan")):toBeTruthy()
				expect(table.find(list, "basah")):toBeTruthy()
				expect(table.find(list, "bersertifikat")):toBeTruthy()
				expect(table.find(list, "kering")):toBeNil()
			end)
		end)
	end)
end
