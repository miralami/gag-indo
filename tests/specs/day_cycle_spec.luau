--!nocheck
-- Pure day-cycle data (WORK_QUEUE round 3 item 10, LUNE-ONLY). Eight phases over a 24-minute
-- day, golden hour at spawn, readable night, and a fresh season/weather-derived preset.

local EXPECTED_IDS = {
	"dini_hari",
	"subuh",
	"pagi",
	"dhuha",
	"siang_bolong",
	"sore",
	"maghrib",
	"malam",
}

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local DayCycle = env:require("shared/World/DayCycle")
	local Strings = env:require("shared/Strings")
	local Seasons = env:require("shared/Config/Seasons")

	local function elapsedFor(clock)
		return ((clock - DayCycle.START_CLOCK + 24) % 24) * DayCycle.SECONDS_PER_GAME_HOUR
	end

	local function close(a, b, eps)
		return math.abs(a - b) <= (eps or 1e-6)
	end

	local function mix(a, b, alpha)
		return a + (b - a) * alpha
	end

	local function colorNear(actual, expected, eps)
		return actual ~= nil
			and close(actual.R, expected.R, eps)
			and close(actual.G, expected.G, eps)
			and close(actual.B, expected.B, eps)
	end

	local function channelMix(a, b, alpha)
		return { R = mix(a.R, b.R, alpha), G = mix(a.G, b.G, alpha), B = mix(a.B, b.B, alpha) }
	end

	local BASE = {
		clockTime = 9,
		brightness = 2,
		fogEnd = 1000,
		fogColor = env.globals.Color3.fromRGB(200, 190, 180),
		ambient = env.globals.Color3.fromRGB(100, 100, 100),
		saturation = 0,
		sunRays = 0,
	}

	t:describe("day cycle data", function()
		t:it("spawn opens at 16:00 golden hour", function()
			expect(DayCycle.clockAt(0)):toBe(16)
			local segment = DayCycle.segmentAt(0)
			expect(segment.from):toBe("sore")
			expect(segment.to):toBe("sore")
			expect(segment.alpha):toBe(0)
			expect(DayCycle.phaseInfo(0).id):toBe("sore")
			expect(DayCycle.isNight(0)):toBe(false)
			expect(DayCycle.presetFor(0, BASE).phaseId):toBe("sore")
		end)

		t:it("clock wraps after 24 real minutes", function()
			expect(DayCycle.DAY_SECONDS):toBe(1440)
			expect(DayCycle.SECONDS_PER_GAME_HOUR):toBe(60)
			expect(DayCycle.clockAt(1440)):toBe(16)
			expect(DayCycle.clockAt(elapsedFor(0))):toBe(0)
			expect(DayCycle.clockAt(1441)):toBeNear(16 + 1 / 60)
			expect(DayCycle.clockAt(2 * DayCycle.DAY_SECONDS + 60)):toBeNear(17)
			expect(DayCycle.segmentAt(1440).phase):toBe("sore")
		end)

		t:it("maghrib arrives about two minutes in", function()
			expect(DayCycle.clockAt(105)):toBe(17.75)
			local segment = DayCycle.segmentAt(105)
			expect(segment.phase):toBe("maghrib")
			expect(segment.from):toBe("maghrib")
			expect(DayCycle.presetFor(105, BASE).phaseId):toBe("maghrib")
			expect(DayCycle.isNight(105)):toBe(true)
		end)

		t:it("night arrives about three minutes in", function()
			expect(DayCycle.clockAt(180)):toBe(19)
			expect(DayCycle.segmentAt(180).phase):toBe("malam")
			local preset = DayCycle.presetFor(180, BASE)
			expect(preset.phaseId):toBe("malam")
			expect(preset.lampLevel):toBe(1)
			expect(DayCycle.isNight(180)):toBe(true)
		end)

		t:it("has eight phases in game-hour order with real labels", function()
			expect(#DayCycle.PHASES):toBe(8)
			for index, phase in ipairs(DayCycle.PHASES) do
				expect(phase.id):toBe(EXPECTED_IDS[index])
				expect(Strings.raw[phase.labelKey] ~= nil):toBe(true)
				expect(phase.start < phase.finish):toBe(true)
				expect(phase.transitionSeconds):toBeAtLeast(20)
				expect(phase.transitionSeconds):toBeAtMost(40)
				expect(phase.lampLevel):toBeAtLeast(0)
				expect(phase.lampLevel):toBeAtMost(1)
				if index > 1 then
					expect(DayCycle.PHASES[index - 1].finish < phase.start):toBe(true)
				end
			end
			expect(DayCycle.PHASES[8].finish < DayCycle.PHASES[1].start + 24):toBe(true)
		end)

		t:it("blends gaps between neighbour phases", function()
			local gap = DayCycle.segmentAt(elapsedFor(3.6))
			expect(gap.from):toBe("dini_hari")
			expect(gap.to):toBe("subuh")
			expect(gap.alpha):toBeNear(0.2)
			expect(gap.phase):toBe("dini_hari")

			local midpoint = DayCycle.segmentAt(elapsedFor(3.75))
			expect(midpoint.alpha):toBeNear(0.5)
			expect(midpoint.phase):toBe("subuh")

			local from, to = DayCycle.PHASES[1], DayCycle.PHASES[2]
			local preset = DayCycle.presetFor(elapsedFor(3.6), BASE)
			expect(colorNear(preset.ambient, channelMix(from.ambient, to.ambient, 0.2))):toBe(true)
			expect(preset.brightness):toBeNear(2 * mix(from.brightnessMultiplier, to.brightnessMultiplier, 0.2))
		end)

		t:it("blends malam into dini_hari across midnight", function()
			local wrap = DayCycle.segmentAt(elapsedFor(0))
			expect(wrap.from):toBe("malam")
			expect(wrap.to):toBe("dini_hari")
			expect(wrap.alpha):toBeNear(1 / 3)
			expect(wrap.phase):toBe("malam")

			local late = DayCycle.segmentAt(elapsedFor(0.75))
			expect(late.alpha):toBeNear(5 / 6)
			expect(late.phase):toBe("dini_hari")

			local preset = DayCycle.presetFor(elapsedFor(0), BASE)
			expect(
				colorNear(
					preset.colorShiftTop,
					channelMix(DayCycle.PHASES[8].colorShiftTop, DayCycle.PHASES[1].colorShiftTop, 1 / 3)
				)
			):toBe(true)
		end)

		t:it("never mutates the season preset", function()
			local season = Seasons.skyFor("kemarau", "cerah")
			local before = {
				clockTime = season.clockTime,
				brightness = season.brightness,
				fogEnd = season.fogEnd,
				saturation = season.saturation,
				sunRays = season.sunRays,
				ambientR = season.ambient.R,
			}
			local preset = DayCycle.presetFor(180, season, "Sedang")
			expect(preset == season):toBe(false)
			expect(season.clockTime):toBe(before.clockTime)
			expect(season.brightness):toBe(before.brightness)
			expect(season.fogEnd):toBe(before.fogEnd)
			expect(season.saturation):toBe(before.saturation)
			expect(season.sunRays):toBe(before.sunRays)
			expect(season.ambient.R):toBe(before.ambientR)
			expect(preset.clockTime):toBe(19)
		end)

		t:it("overrides clockTime but keeps season and weather fields", function()
			local presetWithMarker = {
				clockTime = 9,
				brightness = 2,
				fogEnd = 1000,
				fogColor = BASE.fogColor,
				atmosphereColor = BASE.fogColor,
				atmosphereDensity = 0.3,
				cloudCover = 0.62,
				marker = "keep me",
				saturation = 0.22,
				sunRays = 0.1,
			}
			local preset = DayCycle.presetFor(0, presetWithMarker)
			expect(preset.clockTime):toBe(16)
			expect(preset.fogColor == presetWithMarker.fogColor):toBe(true)
			expect(preset.atmosphereColor == presetWithMarker.atmosphereColor):toBe(true)
			expect(preset.atmosphereDensity):toBe(0.3)
			expect(preset.cloudCover):toBe(0.62)
			expect(preset.marker):toBe("keep me")
			expect(preset.brightness):toBe(2 * DayCycle.PHASES[6].brightnessMultiplier)
			expect(preset.saturation):toBeNear(0.22 + DayCycle.PHASES[6].saturationDelta)
			expect(preset.sunRays):toBeNear(0.1 + DayCycle.PHASES[6].sunRaysDelta)
		end)

		t:it("lerps colour fields from phase endpoints", function()
			local sore = DayCycle.PHASES[6]
			local preset = DayCycle.presetFor(0, BASE)
			expect(colorNear(preset.ambient, sore.ambient)):toBe(true)
			expect(colorNear(preset.outdoorAmbient, sore.outdoorAmbient)):toBe(true)
			expect(colorNear(preset.colorShiftTop, sore.colorShiftTop)):toBe(true)
			expect(colorNear(preset.colorShiftBottom, sore.colorShiftBottom)):toBe(true)
			expect(colorNear(preset.tint, sore.tint)):toBe(true)

			local maghrib = DayCycle.PHASES[7]
			local sunset = DayCycle.presetFor(elapsedFor(18), BASE)
			expect(colorNear(sunset.ambient, maghrib.ambient)):toBe(true)
			expect(colorNear(sunset.tint, maghrib.tint)):toBe(true)
		end)

		t:it("keeps night readable with every lamp on", function()
			for _, musim in { "hujan", "kemarau", "pancaroba" } do
				local season = Seasons.skyFor(musim, "cerah")
				local night = DayCycle.presetFor(180, season)
				expect(night.brightness):toBeAtLeast(0.8)
				expect(night.fogEnd):toBeAtLeast(700)
				expect(night.lampLevel):toBe(1)
				expect(DayCycle.isNight(180)):toBe(true)
				local early = DayCycle.presetFor(elapsedFor(2), season)
				expect(early.brightness):toBeAtLeast(0.8)
				expect(early.fogEnd):toBeAtLeast(700)
				expect(early.lampLevel):toBeAtLeast(0.5)
				expect(DayCycle.isNight(elapsedFor(2))):toBe(true)
			end
			expect(DayCycle.isNight(elapsedFor(8))):toBe(false)
			expect(DayCycle.isNight(elapsedFor(16))):toBe(false)
			expect(DayCycle.isNight(elapsedFor(23.75))):toBe(true)
		end)

		t:it("keeps Rendah within the lamp budget", function()
			local rendah = DayCycle.presetFor(180, BASE, "Rendah")
			expect(rendah.maxLights):toBeAtMost(6)
			expect(rendah.shadowLights):toBe(0)
			for _, tier in { "Sedang", "Tinggi", "bogus", 42 } do
				local preset = DayCycle.presetFor(180, BASE, tier)
				expect(preset.maxLights > 0):toBe(true)
				expect(preset.maxLights < math.huge):toBe(true)
				expect(preset.shadowLights >= 0):toBe(true)
				expect(preset.shadowLights < math.huge):toBe(true)
			end
		end)

		t:it("follows one sound bed per phase", function()
			for _, phase in ipairs(DayCycle.PHASES) do
				local elapsed = elapsedFor((phase.start + phase.finish) / 2)
				expect(DayCycle.phaseInfo(elapsed).soundBed):toBe(phase.soundBed)
				expect(DayCycle.phaseInfo(elapsed).labelKey):toBe(phase.labelKey)
				expect(DayCycle.phaseInfo(elapsed).transitionSeconds):toBe(phase.transitionSeconds)
				expect(DayCycle.presetFor(elapsed, BASE).soundBed):toBe(phase.soundBed)
			end
		end)

		t:it("falls back safely on nil and junk inputs", function()
			for _, bad in { nil, 0 / 0, math.huge, -math.huge, -60, "noon", {} } do
				expect(DayCycle.clockAt(bad)):toBe(16)
				expect(DayCycle.phaseInfo(bad).id):toBe("sore")
			end
			expect(DayCycle.segmentAt(nil).from):toBe("sore")
			for _, bad in { nil, "junk", 42 } do
				local preset = DayCycle.presetFor(0, bad)
				expect(type(preset)):toBe("table")
				expect(preset.brightness > 0):toBe(true)
				expect(preset.fogEnd >= 40):toBe(true)
				expect(preset.ambient ~= nil):toBe(true)
			end
			local junkFields = DayCycle.presetFor(0, { brightness = "bad", fogEnd = -5, saturation = {} })
			expect(junkFields.brightness > 0):toBe(true)
			expect(junkFields.fogEnd >= 40):toBe(true)
		end)

		t:it("exports the adzan setting key that Strings defines", function()
			expect(DayCycle.ADZAN_SETTING_KEY):toBe("setting_adzan")
			expect(Strings.raw[DayCycle.ADZAN_SETTING_KEY] ~= nil):toBe(true)
		end)
	end)
end
