--!nocheck
-- Cloud cover regression (WORK_QUEUE item 61): the shipping sky E needs Cover ~0.5 on a clear
-- day in every season; the hujan/badai overlays must still raise it. Pure data, no Roblox fakes.

return function(t, Env)
	local expect = t.expect
	local env, Seasons, DayCycle

	t:describe("shipping cloud cover", function()
		t:beforeEach(function()
			env = Env.new()
			Seasons = env:require("shared/Config/Seasons")
			DayCycle = env:require("shared/World/DayCycle")
		end)

		t:it("gives every season a clear-day Cover of 0.5", function()
			for _, musim in Seasons.musimOrder do
				local cover = Seasons.skyFor(musim, "cerah").cloudCover
				expect(cover):toBeAtLeast(0.4)
				expect(cover):toBeAtMost(0.6)
				expect(cover):toBeNear(0.5, 1e-9)
			end
		end)

		t:it("uses the same clear-day Cover when attributes are absent", function()
			local cover = Seasons.skyFor(nil, nil).cloudCover
			expect(cover):toBeAtLeast(0.4)
			expect(cover):toBeAtMost(0.6)
			expect(cover):toBeNear(0.5, 1e-9)
		end)

		t:it("lets hujan and badai overlays raise Cover above the clear day", function()
			for _, musim in Seasons.musimOrder do
				local clear = Seasons.skyFor(musim, "cerah").cloudCover
				expect(Seasons.skyFor(musim, "hujan").cloudCover):toBeGreaterThan(clear)
				expect(Seasons.skyFor(musim, "badai").cloudCover):toBeGreaterThan(clear)
			end
		end)

		t:it("keeps the DayCycle fallback at the shipping Cover at ClockTime 13", function()
			local preset = DayCycle.presetFor(1260, nil, "Sedang")
			expect(preset.clockTime):toBeNear(13, 1e-9)
			expect(preset.cloudCover):toBeNear(0.5, 1e-9)
		end)
	end)
end
