return function(t, _Env, _Fakes)
	local env, Visuals, Tiers
	t:describe("Visual art slots and stages", function()
		t:beforeEach(function()
			env = _Env.new()
			Visuals = env:require("shared/Config/Visuals")
			Tiers = env:require("shared/Config/Tiers")
		end)
		t:it("maps all tier colors, crop stages, and zero-id icon slots", function()
			t.expect(#Visuals.artSlots):toBe(23)
			for _, tier in Tiers.order do
				local presentation = Visuals.rarity[tier]
				t.expect(presentation ~= nil and Visuals.palette[presentation.token] ~= nil):toBe(true)
			end
			for _, stage in { "bibit", "tumbuh", "siap" } do
				local spec = Visuals.cropStages[stage]
				t.expect(spec ~= nil and spec.stem > 0 and spec.crown > 0):toBe(true)
			end
			for _, slot in Visuals.artSlots do
				t.expect(Visuals.icons[slot] ~= nil and Visuals.icons[slot].id == 0):toBe(true)
			end
		end)
	end)
end
