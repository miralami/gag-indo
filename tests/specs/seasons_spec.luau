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

		t:describe("growth", function()
			t:it("uses the family override when there is one", function()
				local hujan = Seasons.list.hujan
				for familyId, multiplier in hujan.growthByFamily do
					expect(Seasons.growth("hujan", familyId, "none")):toBeNear(multiplier)
				end
			end)

			t:it("makes palawija faster in the rain and slower in the dry season", function()
				expect(Seasons.growth("hujan", "palawija")):toBeGreaterThan(Seasons.growth("pancaroba", "palawija"))
				expect(Seasons.growth("kemarau", "palawija")):toBeLessThan(Seasons.growth("pancaroba", "palawija"))
			end)

			t:it("falls back to the season base and the changing season", function()
				expect(Seasons.growth("hujan", "tidakAda")):toBeNear(Seasons.list.hujan.growth)
				expect(Seasons.growth("salju", "palawija")):toBe(Seasons.growth("pancaroba", "palawija"))
				expect(Seasons.growth(nil, nil)):toBe(1)
			end)

			t:it("applies the anomaly on top of the season", function()
				local normal = Seasons.growth("pancaroba", "kebun", "none")
				expect(Seasons.growth("pancaroba", "kebun", "elNino")):toBeNear(normal * Seasons.anomaliGrowth.elNino)
				expect(Seasons.growth("pancaroba", "kebun", "laNina")):toBeNear(normal * Seasons.anomaliGrowth.laNina)
			end)

			t:it("clamps the result to a sane range", function()
				for _, musim in Seasons.musimOrder do
					for _, anomali in Seasons.anomaliOrder do
						for _, familyId in { "palawija", "kebun", "perkebunan" } do
							local multiplier = Seasons.growth(musim, familyId, anomali)
							expect(multiplier):toBeAtLeast(0.5)
							expect(multiplier):toBeAtMost(2)
						end
					end
				end
			end)
		end)

		t:describe("skyFor", function()
			t:it("starts from the season preset", function()
				local sky = Seasons.skyFor("kemarau", "cerah")
				expect(sky.clockTime):toBe(Seasons.sky.kemarau.clockTime)
				expect(sky.fogColor):toBe(Seasons.sky.kemarau.fogColor)
			end)

			t:it("darkens and shortens fog in a storm", function()
				local clear = Seasons.skyFor("pancaroba", "cerah")
				local storm = Seasons.skyFor("pancaroba", "badai")
				expect(storm.brightness):toBeLessThan(clear.brightness)
				expect(storm.fogEnd):toBeLessThan(clear.fogEnd)
				expect(storm.cloudCover):toBeGreaterThan(clear.cloudCover)
			end)

			t:it("keeps clouds and atmosphere inside their real ranges", function()
				for _, musim in Seasons.musimOrder do
					for _, cuaca in Seasons.cuacaOrder do
						local sky = Seasons.skyFor(musim, cuaca)
						expect(sky.cloudCover):toBeAtLeast(0)
						expect(sky.cloudCover):toBeAtMost(1)
						expect(sky.atmosphereDensity):toBeAtLeast(0)
						expect(sky.atmosphereDensity):toBeAtMost(1)
						expect(sky.fogEnd):toBeGreaterThan(0)
					end
				end
			end)

			t:it("falls back for unknown inputs", function()
				local sky = Seasons.skyFor("salju", "salju")
				expect(sky.clockTime):toBe(Seasons.sky.pancaroba.clockTime)
			end)
		end)

		t:describe("SeasonService", function()
			local SeasonService

			t:beforeEach(function()
				env:mock("server/Live/LiveConfig", {
					getRuntime = function()
						return { musim = "kemarau", anomali = "none", cuaca = "cerah" }
					end,
				})
				SeasonService = env:require("server/Season/SeasonService")
			end)

			t:it("reports the resolved season, weather and anomaly", function()
				expect(SeasonService.musim()):toBe("kemarau")
				expect(SeasonService.cuaca()):toBe("cerah")
				expect(SeasonService.anomali()):toBe("none")
			end)

			t:it("divides a crop's grow time by today's family multiplier", function()
				local multiplier = Seasons.growth("kemarau", "palawija", "none")
				expect(SeasonService.growSeconds(60, "palawija")):toBe(math.floor(60 / multiplier + 0.5))
			end)

			t:it("never drops below five seconds", function()
				expect(SeasonService.growSeconds(1, "palawija")):toBe(5)
			end)
		end)
	end)
end
