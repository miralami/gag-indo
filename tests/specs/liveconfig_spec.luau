--!nocheck
-- LiveConfig is written by admins and read by every service, so a malformed document must
-- never reach gameplay. These tests cover validation, merge and resolve without touching
-- DataStore / MessagingService (the module only talks to them inside pcall + task.spawn).

return function(t, Env)
	local expect = t.expect
	local env, LiveConfig, Seasons

	local function document(overrides)
		local base = {
			seasonOverride = "auto",
			anomaly = "none",
			cuacaOverride = "auto",
			priceMultipliers = {},
			features = {},
			events = { cabai = "auto" },
			updatedAt = 0,
		}
		for key, value in overrides or {} do
			base[key] = value
		end
		return base
	end

	t:describe("LiveConfig", function()
		t:beforeEach(function()
			env = Env.new()
			LiveConfig = env:require("server/Live/LiveConfig")
			Seasons = env:require("shared/Config/Seasons")
		end)

		t:describe("sanitize", function()
			t:it("returns an empty patch for a non-table", function()
				expect(next(LiveConfig.sanitize(nil))):toBeNil()
				expect(next(LiveConfig.sanitize("hujan"))):toBeNil()
				expect(next(LiveConfig.sanitize(42))):toBeNil()
			end)

			t:it("keeps a known season override and auto", function()
				expect(LiveConfig.sanitize({ seasonOverride = "hujan" }).seasonOverride):toBe("hujan")
				expect(LiveConfig.sanitize({ seasonOverride = "auto" }).seasonOverride):toBe("auto")
			end)

			t:it("drops an unknown season override", function()
				expect(LiveConfig.sanitize({ seasonOverride = "salju" }).seasonOverride):toBeNil()
			end)

			t:it("keeps a known anomaly", function()
				expect(LiveConfig.sanitize({ anomaly = "elNino" }).anomaly):toBe("elNino")
				expect(LiveConfig.sanitize({ anomaly = "laNina" }).anomaly):toBe("laNina")
				expect(LiveConfig.sanitize({ anomaly = "none" }).anomaly):toBe("none")
			end)

			t:it("drops an unknown anomaly", function()
				expect(LiveConfig.sanitize({ anomaly = "kiamat" }).anomaly):toBeNil()
			end)

			t:it("keeps known weather and auto, drops the rest", function()
				expect(LiveConfig.sanitize({ cuacaOverride = "badai" }).cuacaOverride):toBe("badai")
				expect(LiveConfig.sanitize({ cuacaOverride = "auto" }).cuacaOverride):toBe("auto")
				expect(LiveConfig.sanitize({ cuacaOverride = "salju" }).cuacaOverride):toBeNil()
			end)

			t:it("keeps only usable price multipliers", function()
				local patch = LiveConfig.sanitize({
					priceMultipliers = {
						padi = 2,
						jagung = "2",
						cabai = 0,
						durian = -1,
						rusak = 1 / 0,
						besar = 1000,
					},
				})
				expect(patch.priceMultipliers.padi):toBe(2)
				expect(patch.priceMultipliers.jagung):toBeNil()
				expect(patch.priceMultipliers.cabai):toBeNil()
				expect(patch.priceMultipliers.durian):toBeNil()
				expect(patch.priceMultipliers.rusak):toBeNil()
				expect(patch.priceMultipliers.besar):toBeNil()
			end)

			t:it("turns feature flags into booleans only", function()
				local patch = LiveConfig.sanitize({
					features = { gudang = true, pasar = false, aneh = "yes" },
				})
				expect(patch.features.gudang):toBe(true)
				expect(patch.features.pasar):toBe(false)
				expect(patch.features.aneh):toBe(false)
			end)

			t:it("accepts only the three cabai modes", function()
				expect(LiveConfig.sanitize({ events = { cabai = "on" } }).events.cabai):toBe("on")
				expect(LiveConfig.sanitize({ events = { cabai = "off" } }).events.cabai):toBe("off")
				expect(LiveConfig.sanitize({ events = { cabai = "auto" } }).events.cabai):toBe("auto")
				expect(LiveConfig.sanitize({ events = { cabai = "kadang" } }).events):toBeNil()
				expect(LiveConfig.sanitize({ events = { lain = "on" } }).events):toBeNil()
			end)

			t:it("never invents fields that were not in the document", function()
				local patch = LiveConfig.sanitize({})
				expect(next(patch)):toBeNil()
			end)
		end)

		t:describe("merge", function()
			t:it("replaces scalar fields", function()
				local merged = LiveConfig.merge(document(), { seasonOverride = "kemarau" })
				expect(merged.seasonOverride):toBe("kemarau")
			end)

			t:it("keeps untouched scalar fields", function()
				local merged = LiveConfig.merge(document({ anomaly = "laNina" }), { seasonOverride = "kemarau" })
				expect(merged.anomaly):toBe("laNina")
			end)

			t:it("merges price multipliers instead of replacing them", function()
				local base = document({ priceMultipliers = { padi = 2 } })
				local merged = LiveConfig.merge(base, { priceMultipliers = { jagung = 3 } })
				expect(merged.priceMultipliers.padi):toBe(2)
				expect(merged.priceMultipliers.jagung):toBe(3)
			end)

			t:it("merges feature flags instead of replacing them", function()
				local base = document({ features = { gudang = true } })
				local merged = LiveConfig.merge(base, { features = { pasar = false } })
				expect(merged.features.gudang):toBe(true)
				expect(merged.features.pasar):toBe(false)
			end)

			t:it("merges events per event id", function()
				local base = document({ events = { cabai = "on", panen = "auto" } })
				local merged = LiveConfig.merge(base, { events = { cabai = "off" } })
				expect(merged.events.cabai):toBe("off")
				expect(merged.events.panen):toBe("auto")
			end)

			t:it("does not mutate the base document", function()
				local base = document({ priceMultipliers = { padi = 2 } })
				LiveConfig.merge(base, { seasonOverride = "hujan", priceMultipliers = { jagung = 3 } })
				expect(base.seasonOverride):toBe("auto")
				expect(base.priceMultipliers.jagung):toBeNil()
			end)
		end)

		t:describe("resolve", function()
			t:it("uses the calendar when the season override is auto", function()
				local runtime = LiveConfig.resolve(document(), os.time({ year = 2026, month = 1, day = 15 }))
				expect(runtime.musim):toBe("hujan")
				expect(runtime.seasonSource):toBe("calendar")
			end)

			t:it("uses the override when one is set", function()
				local runtime = LiveConfig.resolve(document({ seasonOverride = "kemarau" }), 0)
				expect(runtime.musim):toBe("kemarau")
				expect(runtime.seasonSource):toBe("override")
			end)

			t:it("defaults an unknown anomaly to none", function()
				expect(LiveConfig.resolve(document({ anomaly = "kiamat" }), 0).anomali):toBe("none")
			end)

			t:it("keeps a real anomaly", function()
				expect(LiveConfig.resolve(document({ anomaly = "elNino" }), 0).anomali):toBe("elNino")
			end)

			t:it("uses the weather override when one is set", function()
				expect(LiveConfig.resolve(document({ cuacaOverride = "badai" }), 0).cuaca):toBe("badai")
			end)

			t:it("picks a valid weather for the resolved season", function()
				local runtime = LiveConfig.resolve(document({ seasonOverride = "hujan" }), 0)
				expect(Seasons.isCuaca(runtime.cuaca)):toBe(true)
			end)

			t:it("gives the same weather all day (stable roll)", function()
				local dayStart = 1_700_000_000 -- one hour before the UTC day ends
				local config = document({ seasonOverride = "kemarau" })
				local morning = LiveConfig.resolve(config, dayStart)
				local evening = LiveConfig.resolve(config, dayStart + 3600)
				expect(morning.cuaca):toBe(evening.cuaca)
			end)

			t:it("carries the price multipliers, features and events through", function()
				local runtime = LiveConfig.resolve(
					document({ priceMultipliers = { padi = 2 }, features = { gudang = true }, events = { cabai = "on" } }),
					0
				)
				expect(runtime.priceMultipliers.padi):toBe(2)
				expect(runtime.features.gudang):toBe(true)
				expect(runtime.events.cabai):toBe("on")
			end)
		end)

		t:describe("defaults", function()
			t:it("starts in auto with the cabai event on its v1 timer", function()
				local runtime = LiveConfig.getRuntime()
				expect(runtime.seasonSource):toBe("calendar")
				expect(runtime.anomali):toBe("none")
				expect(runtime.events.cabai):toBe("auto")
				expect(LiveConfig.get().events.cabai):toBe("auto")
			end)
		end)
	end)
end
