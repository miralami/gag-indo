--!nocheck
-- FidelityTier (VISUAL_MASTER_PLAN section 6, V0.1): pure tier selection with an injected clock.
-- Down fast, up slow, frozen during hook moments, never thrashing at the boundary.

return function(t, Env)
	local expect = t.expect
	local FidelityTier

	local BAD = 1 / 30 -- slower than the down threshold
	local GOOD = 1 / 60 -- faster than the up threshold
	local MID = 1 / 50 -- inside the dead band

	t:describe("FidelityTier", function()
		local now
		local function clock()
			return now
		end
		local function make(opts)
			opts = opts or {}
			opts.clock = clock
			return FidelityTier.new(opts)
		end
		-- Feeds `seconds` of frames at `dt`, advancing the fake clock by dt each frame.
		local function run(tier, dt, seconds)
			local frames = math.ceil(seconds / dt)
			for _ = 1, frames do
				now += dt
				tier.step(dt)
			end
		end

		t:beforeEach(function()
			local env = Env.new()
			FidelityTier = env:require("client/Feel/FidelityTier")
			now = 1000
		end)

		t:describe("settings table", function()
			t:it("matches the table for Rendah", function()
				local s = FidelityTier.settingsFor("Rendah")
				expect(s.particleRate):toBe(0.4)
				expect(s.foliageSwayRange):toBe(25)
				expect(s.localLights):toBe("none")
				expect(s.smallPartShadows):toBe("off")
				expect(s.rain):toBe("sheet")
				expect(s.cameraDoF):toBe(false)
				expect(s.ambientLife):toBe("minimal")
			end)

			t:it("matches the table for Sedang", function()
				local s = FidelityTier.settingsFor("Sedang")
				expect(s.particleRate):toBe(0.7)
				expect(s.foliageSwayRange):toBe(50)
				expect(s.localLights):toBe("key")
				expect(s.smallPartShadows):toBe("near")
				expect(s.rain):toBe("splashes")
				expect(s.cameraDoF):toBe(false)
				expect(s.ambientLife):toBe("half")
			end)

			t:it("matches the table for Tinggi", function()
				local s = FidelityTier.settingsFor("Tinggi")
				expect(s.particleRate):toBe(1.0)
				expect(s.foliageSwayRange):toBe(80)
				expect(s.localLights):toBe("all")
				expect(s.smallPartShadows):toBe("on")
				expect(s.rain):toBe("full")
				expect(s.cameraDoF):toBe(true)
				expect(s.ambientLife):toBe("full")
			end)

			t:it("never lowers particle rate or sway range as the tier rises", function()
				local previous
				for _, name in FidelityTier.TIERS do
					local s = FidelityTier.settingsFor(name)
					if previous then
						expect(s.particleRate):toBeAtLeast(previous.particleRate)
						expect(s.foliageSwayRange):toBeAtLeast(previous.foliageSwayRange)
					end
					previous = s
				end
			end)

			t:it("falls back to Sedang for unknown names", function()
				expect(FidelityTier.settingsFor("Ultra")):toBe(FidelityTier.settingsFor("Sedang"))
				expect(FidelityTier.settingsFor(nil)):toBe(FidelityTier.settingsFor("Sedang"))
			end)

			t:it("exposes the active tier's settings on the controller", function()
				local tier = make({ setting = "Tinggi" })
				expect(tier.settings()):toBe(FidelityTier.settingsFor("Tinggi"))
			end)
		end)

		t:describe("initial tier", function()
			t:it("starts at the saved setting", function()
				expect(make({ setting = "Rendah" }).get()):toBe("Rendah")
				expect(make({ setting = "Sedang" }).get()):toBe("Sedang")
				expect(make({ setting = "Tinggi" }).get()):toBe("Tinggi")
			end)

			t:it("assumes Sedang when nothing is saved", function()
				expect(make().get()):toBe("Sedang")
				expect(make({ setting = "Otomatis" }).get()):toBe("Sedang")
			end)

			t:it("ignores an unknown saved setting", function()
				expect(make({ setting = "Ultra" }).get()):toBe("Sedang")
			end)
		end)

		t:describe("manual override", function()
			t:it("wins over the saved setting at start", function()
				expect(make({ setting = "Tinggi", override = "Rendah" }).get()):toBe("Rendah")
			end)

			t:it("wins over bad frames", function()
				local tier = make({ setting = "Tinggi", override = "Tinggi" })
				run(tier, BAD, 20)
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("wins over good frames", function()
				local tier = make({ setting = "Tinggi", override = "Rendah" })
				run(tier, GOOD, 120)
				expect(tier.get()):toBe("Rendah")
			end)

			t:it("switches live and fires the change signal", function()
				local tier = make({ setting = "Sedang" })
				local seen = {}
				tier.onChanged(function(new, old, settings)
					table.insert(seen, { new, old, settings })
				end)
				tier.setOverride("Tinggi")
				expect(tier.get()):toBe("Tinggi")
				expect(#seen):toBe(1)
				expect(seen[1][1]):toBe("Tinggi")
				expect(seen[1][2]):toBe("Sedang")
				expect(seen[1][3]):toBe(FidelityTier.settingsFor("Tinggi"))
			end)

			t:it("hands control back to auto when cleared", function()
				local tier = make({ setting = "Tinggi", override = "Rendah" })
				tier.setOverride("Otomatis")
				expect(tier.getOverride()):toBeNil()
				expect(tier.get()):toBe("Tinggi")
			end)
		end)

		t:describe("moving down", function()
			t:it("steps down one tier on sustained bad frames", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 3)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("does nothing before enough samples", function()
				local tier = make({ setting = "Tinggi" })
				for _ = 1, FidelityTier.MIN_SAMPLES - 1 do
					now += 1
					tier.step(0.1)
				end
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("steps down again after the cooldown, then stops at Rendah", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 30)
				expect(tier.get()):toBe("Rendah")
				run(tier, BAD, 30)
				expect(tier.get()):toBe("Rendah")
			end)

			t:it("ignores one hitch inside good frames", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, GOOD, 1)
				now += 0.3
				tier.step(0.3)
				run(tier, GOOD, 1)
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("fires the change signal once per step", function()
				local tier = make({ setting = "Tinggi" })
				local count = 0
				tier.onChanged(function()
					count += 1
				end)
				run(tier, BAD, 3)
				expect(count):toBe(1)
			end)

			t:it("stops signalling after disconnect", function()
				local tier = make({ setting = "Tinggi" })
				local count = 0
				local disconnect = tier.onChanged(function()
					count += 1
				end)
				disconnect()
				run(tier, BAD, 3)
				expect(count):toBe(0)
			end)
		end)

		t:describe("moving up", function()
			t:it("needs sustained good frames", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 3)
				expect(tier.get()):toBe("Sedang")
				run(tier, GOOD, FidelityTier.UP_SUSTAIN - 2)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("needs the cooldown even after enough good frames", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 3)
				run(tier, GOOD, FidelityTier.UP_SUSTAIN + 2) -- sustained, but under UP_COOLDOWN
				expect(tier.get()):toBe("Sedang")
				run(tier, GOOD, FidelityTier.UP_COOLDOWN)
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("resets the sustain timer when a dead-band stretch interrupts", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 3)
				run(tier, GOOD, FidelityTier.UP_COOLDOWN - 5)
				run(tier, MID, 2) -- dead band breaks the streak
				run(tier, GOOD, FidelityTier.UP_SUSTAIN - 4)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("never rises above the saved setting", function()
				local tier = make({ setting = "Sedang" })
				run(tier, GOOD, 300)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("with no saved setting, may climb from Sedang to Tinggi", function()
				local tier = make()
				run(tier, GOOD, FidelityTier.UP_COOLDOWN + FidelityTier.UP_SUSTAIN + 5)
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("climbs one tier at a time", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, BAD, 30)
				expect(tier.get()):toBe("Rendah")
				run(tier, GOOD, FidelityTier.UP_SUSTAIN + 2) -- the bad run already outlasted the cooldown
				expect(tier.get()):toBe("Sedang")
			end)
		end)

		t:describe("hook moments", function()
			t:it("freezes the tier during a moment", function()
				local tier = make({ setting = "Tinggi" })
				tier.beginMoment()
				run(tier, BAD, 20)
				expect(tier.get()):toBe("Tinggi")
				expect(tier.isLocked()):toBe(true)
			end)

			t:it("applies a pending down-step after the moment ends", function()
				local tier = make({ setting = "Tinggi" })
				tier.beginMoment()
				run(tier, BAD, 20)
				tier.endMoment()
				expect(tier.get()):toBe("Tinggi") -- no step until the next frame
				run(tier, BAD, 1)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("holds a nested moment until every begin has an end", function()
				local tier = make({ setting = "Tinggi" })
				tier.beginMoment()
				tier.beginMoment()
				tier.endMoment()
				run(tier, BAD, 20)
				expect(tier.get()):toBe("Tinggi")
				expect(tier.isLocked()):toBe(true)
				tier.endMoment()
				expect(tier.isLocked()):toBe(false)
				run(tier, BAD, 1)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("defers a manual override until the moment ends", function()
				local tier = make({ setting = "Tinggi" })
				local count = 0
				tier.onChanged(function()
					count += 1
				end)
				tier.beginMoment()
				tier.setOverride("Rendah")
				expect(tier.get()):toBe("Tinggi")
				expect(count):toBe(0)
				tier.endMoment()
				expect(tier.get()):toBe("Rendah")
				expect(count):toBe(1)
			end)

			t:it("ignores an unbalanced endMoment", function()
				local tier = make({ setting = "Tinggi" })
				tier.endMoment()
				tier.endMoment()
				tier.beginMoment()
				expect(tier.isLocked()):toBe(true)
			end)
		end)

		t:describe("no thrash", function()
			t:it("holds steady in the dead band between thresholds", function()
				local tier = make()
				local count = 0
				tier.onChanged(function()
					count += 1
				end)
				run(tier, MID, 200)
				expect(count):toBe(0)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("does not flip back after a down-step on borderline frames", function()
				local tier = make({ setting = "Tinggi" })
				local count = 0
				tier.onChanged(function()
					count += 1
				end)
				run(tier, BAD, 3)
				run(tier, MID, 200) -- never good enough to climb, never bad enough to fall
				expect(count):toBe(1)
				expect(tier.get()):toBe("Sedang")
			end)

			t:it("alternating frames around the boundary never change the tier", function()
				local tier = make()
				local count = 0
				tier.onChanged(function()
					count += 1
				end)
				for _ = 1, 400 do
					now += 1 / 50
					tier.step(1 / 50 + 0.004)
					now += 1 / 50
					tier.step(1 / 50 - 0.004)
				end
				expect(count):toBe(0)
			end)
		end)

		t:describe("bad inputs", function()
			t:it("ignores nil, NaN, negative, zero, infinite and non-number frame times", function()
				local tier = make({ setting = "Tinggi" })
				for _ = 1, 100 do
					now += 1
					tier.step(nil)
					tier.step(0 / 0)
					tier.step(-1)
					tier.step(0)
					tier.step(math.huge)
					tier.step("slow")
				end
				expect(tier.get()):toBe("Tinggi")
				expect(tier.average()):toBeNil()
			end)

			t:it("ignores a multi-second pause as a sample", function()
				local tier = make({ setting = "Tinggi" })
				run(tier, GOOD, 1)
				now += 10
				tier.step(10)
				run(tier, GOOD, 1)
				expect(tier.get()):toBe("Tinggi")
			end)

			t:it("cleanFrameTime passes only positive finite numbers", function()
				expect(FidelityTier.cleanFrameTime(0.016)):toBe(0.016)
				expect(FidelityTier.cleanFrameTime(nil)):toBeNil()
				expect(FidelityTier.cleanFrameTime(-0.01)):toBeNil()
				expect(FidelityTier.cleanFrameTime(0 / 0)):toBeNil()
			end)

			t:it("ignores unknown override names", function()
				local tier = make({ setting = "Tinggi" })
				tier.setOverride("Ultra")
				expect(tier.getOverride()):toBeNil()
				expect(tier.get()):toBe("Tinggi")
			end)
		end)

		t:describe("saved setting changes", function()
			t:it("lowering the setting moves down immediately", function()
				local tier = make({ setting = "Tinggi" })
				tier.setSetting("Rendah")
				expect(tier.get()):toBe("Rendah")
			end)

			t:it("is held during a moment", function()
				local tier = make({ setting = "Tinggi" })
				tier.beginMoment()
				tier.setSetting("Rendah")
				expect(tier.get()):toBe("Tinggi")
				tier.endMoment()
				expect(tier.get()):toBe("Rendah")
			end)
		end)
	end)
end
