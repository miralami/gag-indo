--!nocheck
-- WORK_QUEUE round 3 item 25, code half: pure plan + saved adzan setting for the OFF-BY-DEFAULT
-- "day_cycle" LookDev candidate. No visual verdict and no Studio claim here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local DayCycle = env:require("shared/World/DayCycle")
	local DayCycleLive = env:require("shared/World/DayCycleLive")
	local AdzanSetting = env:require("shared/Settings/AdzanSetting")
	local Audio = env:require("shared/Config/Audio")

	local function elapsedFor(clock)
		return ((clock - DayCycle.START_CLOCK + 24) % 24) * DayCycle.SECONDS_PER_GAME_HOUR
	end

	t:describe("day-cycle live plan", function()
		t:it("exports the five silent sound beds and the adzan defaults", function()
			expect(DayCycleLive.ID):toBe("day_cycle")
			expect(DayCycleLive.SOUND_BEDS):toEqual({ "ayam", "bedug", "kentongan", "jangkrik", "adzan" })
			local plan = DayCycleLive.plan()
			expect(plan.id):toBe("day_cycle")
			expect(plan.soundBeds):toEqual(DayCycleLive.SOUND_BEDS)
			expect(plan.adzan.settingKey):toBe(DayCycle.ADZAN_SETTING_KEY)
			expect(plan.adzan.defaultOn):toBe(true)
			expect(plan.adzan.volume):toBe(AdzanSetting.VOLUME)
			expect(plan.adzan.volume):toBeGreaterThan(0)
			expect(plan.adzan.volume):toBeAtMost(0.2) -- LOW
		end)

		t:it("keeps every phase and gap tween inside 20..40 s", function()
			expect(DayCycleLive.MIN_TWEEN_SECONDS):toBe(20)
			expect(DayCycleLive.MAX_TWEEN_SECONDS):toBe(40)
			expect(DayCycleLive.plan().tweenSeconds.min):toBe(20)
			expect(DayCycleLive.plan().tweenSeconds.max):toBe(40)
			for _, phase in ipairs(DayCycle.PHASES) do
				expect(DayCycleLive.tweenSeconds(elapsedFor((phase.start + phase.finish) / 2))):toBeAtLeast(20)
				expect(DayCycleLive.tweenSeconds(elapsedFor((phase.start + phase.finish) / 2))):toBeAtMost(40)
			end
			for index, phase in ipairs(DayCycle.PHASES) do
				local next = DayCycle.PHASES[if index == #DayCycle.PHASES then 1 else index + 1]
				local gapStart = phase.finish
				local gapEnd = if index == #DayCycle.PHASES then next.start + 24 else next.start
				expect(DayCycleLive.tweenSeconds(elapsedFor((gapStart + gapEnd) / 2))):toBeAtLeast(20)
				expect(DayCycleLive.tweenSeconds(elapsedFor((gapStart + gapEnd) / 2))):toBeAtMost(40)
			end
			for _, bad in { nil, 0 / 0, math.huge, "noon", {} } do
				-- Junk degrades to DayCycle's sore phase (30 s), still inside the bounds.
				expect(DayCycleLive.tweenSeconds(bad)):toBeAtLeast(20)
				expect(DayCycleLive.tweenSeconds(bad)):toBeAtMost(40)
			end
		end)

		t:it("maps phases to only the five known beds", function()
			expect(DayCycleLive.soundBedsFor(elapsedFor(5))):toEqual({ "ayam", "bedug", "adzan" })
			expect(DayCycleLive.soundBedsFor(elapsedFor(18))):toEqual({ "bedug", "adzan" })
			expect(DayCycleLive.soundBedsFor(elapsedFor(20))):toEqual({ "kentongan", "jangkrik" })
			expect(DayCycleLive.soundBedsFor(elapsedFor(13))):toEqual({})
			for _, phase in ipairs(DayCycle.PHASES) do
				for _, bed in DayCycleLive.soundBedsFor(elapsedFor((phase.start + phase.finish) / 2)) do
					expect(DayCycleLive.isSoundBed(bed)):toBe(true)
				end
			end
			expect(DayCycleLive.isSoundBed("bed_pagi")):toBe(false) -- phase keys are not bed slots
			expect(DayCycleLive.isSoundBed(nil)):toBe(false)
		end)

		t:it("caps night lamps at the Rendah budget", function()
			local rendah = DayCycleLive.lampBudget("Rendah")
			expect(rendah.maxLights):toBeAtMost(6)
			expect(rendah.shadowLights):toBe(0)
			expect(#DayCycleLive.lampPositions()):toBeAtMost(rendah.maxLights)
			for _, position in DayCycleLive.lampPositions() do
				expect(#position):toBe(3)
				expect(type(position[1]) == "number" and type(position[2]) == "number"):toBe(true)
			end
			for _, tier in { "Sedang", "Tinggi", "bogus", 42, nil } do
				local budget = DayCycleLive.lampBudget(tier)
				expect(budget.maxLights):toBeAtMost(rendah.maxLights)
				expect(budget.shadowLights):toBe(0)
			end
		end)

		t:it("reuses DayCycle.presetFor without mutating the season preset", function()
			local base = {
				clockTime = 9,
				brightness = 2,
				fogEnd = 1000,
				ambient = env.globals.Color3.fromRGB(100, 100, 100),
			}
			local preset = DayCycleLive.preset(180, base, "Rendah")
			expect(preset):toBeTruthy()
			expect(preset == base):toBe(false)
			expect(preset.clockTime):toBe(19)
			expect(preset.phaseId):toBe("malam")
			expect(preset.maxLights):toBe(6)
			expect(base.clockTime):toBe(9)
			expect(base.brightness):toBe(2)
		end)
	end)

	t:describe("saved adzan setting", function()
		t:it("defaults ON for missing or damaged persisted values", function()
			expect(AdzanSetting.KEY):toBe("setting_adzan")
			expect(AdzanSetting.DEFAULT_ON):toBe(true)
			expect(AdzanSetting.read(nil)):toBe(true)
			expect(AdzanSetting.read({})):toBe(true)
			local profile = {}
			for _, bad in { "banana", {}, 0 / 0, math.huge, -math.huge, 42 } do
				profile[AdzanSetting.KEY] = bad
				expect(AdzanSetting.read(profile)):toBe(true)
			end
		end)

		t:it("reads boolean and boolean-like off values", function()
			local profile = {}
			for _, off in { false, 0, "off", "FALSE", "0" } do
				profile[AdzanSetting.KEY] = off
				expect(AdzanSetting.read(profile)):toBe(false)
			end
			for _, on in { true, 1, "on", "TRUE", "1" } do
				profile[AdzanSetting.KEY] = on
				expect(AdzanSetting.read(profile)):toBe(true)
			end
		end)

		t:it("writes and re-reads on a mock profile without touching other fields", function()
			local profile = { cash = 250, setting_adzan = true }
			expect(AdzanSetting.write(profile, false)):toBe(true)
			expect(profile.setting_adzan):toBe(false)
			expect(profile.cash):toBe(250)
			expect(AdzanSetting.read(profile)):toBe(false)
			expect(AdzanSetting.write(profile, true)):toBe(true)
			expect(AdzanSetting.read(profile)):toBe(true)
			expect(AdzanSetting.write(profile, "banana")):toBe(false)
			expect(profile.setting_adzan):toBe(true) -- invalid write leaves saved data intact
			expect(AdzanSetting.write(nil, false)):toBe(false)
		end)
	end)

	t:describe("day-cycle live wiring", function()
		t:it("registers the candidate and restores the sky on disable", function()
			local adapter = fs.readFile("src/client/World/LookDevDayCycle.luau")
			expect(
				string.find(adapter, 'LookDev.register("day_cycle", { apply = apply, restore = restore })', 1, true)
					~= nil
			):toBe(true)
			expect(string.find(adapter, "DayCycleLive.preset(", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "local function restore()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "PointLight", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "light.Shadows = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("has five zero-id sound slots and no asset IDs in the new pure files", function()
			for _, name in DayCycleLive.SOUND_BEDS do
				local def = Audio.sounds[name]
				expect(def):toBeTruthy()
				expect(def.group):toBe("ambience")
				expect(def.id):toBe(0)
				expect(def.volume):toBeAtMost(0.35)
			end
			expect(Audio.sounds.adzan.volume):toBe(AdzanSetting.VOLUME)
			for _, path in
				{
					"src/shared/World/DayCycleLive.luau",
					"src/shared/Settings/AdzanSetting.luau",
					"src/client/World/LookDevDayCycle.luau",
				}
			do
				local src = fs.readFile(path)
				expect(string.find(src, "GetService", 1, true) ~= nil):toBe(
					path == "src/client/World/LookDevDayCycle.luau"
				)
				expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "assetId", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			end
		end)

		t:it("records an absolute spawn-facing review camera, not a verdict", function()
			local readme = fs.readFile("docs/v2/visual/art/daycycle/README.md")
			expect(string.find(readme, ':enable("day_cycle")', 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "{ 0, 12, 52 }", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "{ 0, 3, -20 }", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "review position", 1, true) ~= nil):toBe(true)
		end)
	end)
end
