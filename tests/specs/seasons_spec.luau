--!nocheck
-- Seasons only decide a calendar fallback in M0, but the helpers are already called by
-- LiveConfig and later by FarmService, so pin the boundaries now.

return function(t, Env)
	local expect = t.expect
	local env, Seasons

	t:describe("Seasons", function()
		t:beforeEach(function()
			env = Env.new()
			Seasons = env:require("shared/Config/Seasons")
		end)

		t:describe("calendar", function()
			t:it("maps November to March to the rainy season", function()
				for _, month in { 11, 12, 1, 2, 3 } do
					expect(Seasons.forMonth(month)):toBe("hujan")
				end
			end)

			t:it("maps May to September to the dry season", function()
				for _, month in { 5, 6, 7, 8, 9 } do
					expect(Seasons.forMonth(month)):toBe("kemarau")
				end
			end)

			t:it("maps the months in between to the changing season", function()
				for _, month in { 4, 10 } do
					expect(Seasons.forMonth(month)):toBe("pancaroba")
				end
			end)

			t:it("always returns a season that exists", function()
				for month = 1, 12 do
					expect(Seasons.isMusim(Seasons.forMonth(month))):toBe(true)
				end
			end)

			t:it("reads a timestamp without crashing", function()
				expect(Seasons.isMusim(Seasons.fromUnix(1_700_000_000))):toBe(true)
			end)
		end)

		t:describe("validation", function()
			t:it("accepts every listed musim and rejects anything else", function()
				for _, musim in Seasons.musimOrder do
					expect(Seasons.isMusim(musim)):toBe(true)
				end
				expect(Seasons.isMusim("salju")):toBe(false)
				expect(Seasons.isMusim(nil)):toBe(false)
				expect(Seasons.isMusim(3)):toBe(false)
			end)

			t:it("accepts every listed anomaly and rejects anything else", function()
				for _, anomali in Seasons.anomaliOrder do
					expect(Seasons.isAnomali(anomali)):toBe(true)
				end
				expect(Seasons.isAnomali("kiamat")):toBe(false)
				expect(Seasons.isAnomali(nil)):toBe(false)
			end)

			t:it("accepts every listed weather and rejects anything else", function()
				for _, cuaca in Seasons.cuacaOrder do
					expect(Seasons.isCuaca(cuaca)):toBe(true)
				end
				expect(Seasons.isCuaca("salju")):toBe(false)
				expect(Seasons.isCuaca(nil)):toBe(false)
			end)

			t:it("has weights that sum to one for every season", function()
				for _, musim in Seasons.musimOrder do
					local total = 0
					for _, cuaca in Seasons.cuacaOrder do
						total += Seasons.weatherWeights[musim][cuaca] or 0
					end
					expect(total):toBeNear(1, 1e-9)
				end
			end)
		end)

		t:describe("rollWeather", function()
			t:it("picks the first weather for a roll of zero", function()
				expect(Seasons.rollWeather("kemarau", 0)):toBe(Seasons.cuacaOrder[1])
			end)

			t:it("picks the first weather that covers the roll", function()
				-- kemarau: cerah 0.70, hujan 0.06, badai 0.02, kabut 0.22
				expect(Seasons.rollWeather("kemarau", 0.69)):toBe("cerah")
				expect(Seasons.rollWeather("kemarau", 0.71)):toBe("hujan")
				expect(Seasons.rollWeather("kemarau", 0.77)):toBe("badai")
				expect(Seasons.rollWeather("kemarau", 0.80)):toBe("kabut")
			end)

			t:it("clamps rolls outside 0..1", function()
				expect(Seasons.rollWeather("hujan", -5)):toBe(Seasons.cuacaOrder[1])
				expect(Seasons.rollWeather("hujan", 5)):toBe("kabut")
			end)

			t:it("falls back to the changing season for an unknown musim", function()
				expect(Seasons.isCuaca(Seasons.rollWeather("salju", 0.5))):toBe(true)
			end)

			t:it("always returns a weather that exists", function()
				for _, musim in Seasons.musimOrder do
					for step = 0, 99 do
						expect(Seasons.isCuaca(Seasons.rollWeather(musim, step / 100))):toBe(true)
					end
				end
			end)
		end)
	end)
end
