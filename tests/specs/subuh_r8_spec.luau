--!nocheck
-- WORK_QUEUE section N item 121: subuh_r8, a client dawn look. Pure-model checks run for real
-- under Lune; LookDev/review wiring, applier source and harness block are static guards. No Studio
-- verdict: CHECK evidence, tracker ticks and the visual yes/no belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapSubuhR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapSubuhR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevSubuhR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/client/Main.client.luau")
	local serverMainSrc = fs.readFile("src/server/Main.server.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
	local pavingSrc = fs.readFile("tests/specs/pasar_ground_r8_spec.luau")

	local function finite(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	t:describe("subuh_r8 pure model", function()
		t:it("exports four evenly stepped dawn phases", function()
			expect(Data.id):toBe("subuh_r8")
			expect(Data.phaseCount()):toBe(4)
			expect(#Data.PHASES):toBe(4)
			local clocks = {}
			for index, phase in ipairs(Data.PHASES) do
				clocks[index] = phase.clock
				expect(type(phase.id)):toBe("string")
				expect(finite(phase.brightness)):toBe(true)
			end
			expect(clocks):toEqual({ 4.5, 5, 5.5, 6 })
			expect(Data.CLOCK_START):toBe(4.5)
			expect(Data.CLOCK_END):toBe(6)
			expect(Data.PHASES[1].colorShiftTop):toEqual({ r = 76, g = 66, b = 112 })
			expect(Data.PHASES[4].colorShiftTop):toEqual({ r = 235, g = 198, b = 152 })
			expect(Data.PHASES[1].colorShiftBottom):toEqual({ r = 92, g = 80, b = 96 })
			expect(Data.PHASES[4].colorShiftBottom):toEqual({ r = 112, g = 96, b = 88 })
			expect(Data.PHASES[1].brightness):toBe(1.2)
			expect(Data.PHASES[4].brightness):toBe(1.8)
		end)

		t:it("proves monotone warm-up and a positive jump budget", function()
			local mono = Data.monotonic()
			expect(mono.pass):toBe(true)
			expect(mono.steps):toBe(3)
			expect(mono.clocks):toEqual({ 4.5, 5, 5.5, 6 })
			expect(mono.top):toEqual({ 76, 120, 178, 235 })
			expect(#mono.warmth):toBe(4)
			expect(#mono.luminance):toBe(4)
			for index = 2, 4 do
				expect(mono.top[index] > mono.top[index - 1]):toBe(true)
				expect(mono.warmth[index] > mono.warmth[index - 1]):toBe(true)
				expect(mono.luminance[index] > mono.luminance[index - 1]):toBe(true)
			end
			expect(mono.warmth[1] < 0):toBe(true) -- cool blue at 04:30
			expect(mono.warmth[4] > 0):toBe(true) -- peach by 06:00
			expect(mono.baseJump):toBeGreaterThan(0)
			expect(mono.maxJump):toBeGreaterThan(0)
			expect(mono.maxJump <= mono.limit):toBe(true)
			expect(Data.JUMP_FACTOR):toBe(1.25)
			expect(math.abs(mono.baseJump - 159 / 255) < 0.000000001):toBe(true)
			expect(math.abs(mono.limit - 1.25 * 159 / 255) < 0.000000001):toBe(true)
			expect(math.abs(mono.maxJump - 58 / 255) < 0.000000001):toBe(true)
		end)

		t:it("clamps every phase and preset inside the DAWN_SAFE bands", function()
			expect(Data.phasesInBands()):toBe(true)
			local bands = Data.safeRanges
			expect(bands.Lighting.Brightness):toEqual({ min = 1.2, max = 3.2 })
			expect(bands.Lighting.FogEnd):toEqual({ min = 40, max = 4000 })
			expect(bands.Lighting.ColorShift_Top):toBe(bands.Lighting.Ambient)
			expect(bands.Atmosphere.Density):toEqual({ min = 0.22, max = 0.35 })
			expect(bands.Atmosphere.Haze):toEqual({ min = 1, max = 2.4 })
			expect(bands.Clouds.Cover):toEqual({ min = 0.35, max = 0.6 })
			expect(bands.ColorCorrectionEffect.Saturation):toEqual({ min = 0, max = 0.2 })
			expect(bands.ColorCorrectionEffect.Contrast):toEqual({ min = -0.02, max = 0.08 })
			expect(bands.BloomEffect.Intensity):toEqual({ min = 0, max = 0.25 })
			expect(bands.SunRaysEffect.Intensity):toEqual({ min = 0, max = 0.3 })
			expect(bands.Lamps.Shadows):toBe(false)
			expect(bands.Lamps.Range.max):toBe(30)
			expect(bands.Lamps.Brightness.max):toBe(3)
			expect(#Data.checkReadings({})):toBeGreaterThan(0)
			local broken = {
				Lighting = { Brightness = 9 },
			}
			local failures = Data.checkReadings(broken)
			expect(#failures):toBeGreaterThan(0)
			expect(table.concat(failures, "|"):find("Brightness", 1, true) ~= nil):toBe(true)
			-- ponytail ceiling: float32 endpoint rounding is accepted, real band violations are not.
			expect(Data.BAND_EPSILON):toBe(0.0001)
			local near = table.concat(Data.checkReadings({ Atmosphere = { Density = 0.22 - 1e-5 } }), "|")
			expect(near:find("Atmosphere.Density", 1, true) == nil):toBe(true)
			local far = table.concat(Data.checkReadings({ Atmosphere = { Density = 0.21 } }), "|")
			expect(far:find("Atmosphere.Density", 1, true) ~= nil):toBe(true)
		end)

		t:it("normalizes byte and fractional colour props without an engine API", function()
			expect(Data.normalizedColor("FogColor", { r = 255, g = 128, b = 0 })).toEqual({
				r = 1,
				g = 128 / 255,
				b = 0,
			})
			local byteUpper = Data.normalizedColor("ColorShift_Top", { R = 255, G = 255, B = 255 })
			expect(byteUpper.r):toBe(1)
			expect(Data.normalizedColor("TintColor", { r = 1.04, g = 1, b = 0.96 })).toEqual({
				r = 1.04,
				g = 1,
				b = 0.96,
			})
			expect(Data.normalizedColor("Brightness", { r = 1, g = 1, b = 1 })):toBe(nil)
			expect(Data.normalizedColor("FogColor", nil)):toBe(nil)
		end)

		t:it("ramps the first lamp glow then extinguishes it by 06:00", function()
			local lamp = Data.LAMP
			expect(lamp.maxLights):toBe(6)
			expect(lamp.range):toBe(14)
			expect(lamp.brightnessMax):toBe(0.45)
			expect(lamp.shadows):toBe(false)
			expect(Data.lampBrightness(4.5)):toBe(0)
			expect(Data.lampBrightness(5)):toBe(0)
			expect(math.abs(Data.lampBrightness(5.25) - 0.225) < 0.000000001):toBe(true)
			expect(Data.lampBrightness(5.5)):toBe(0.45)
			expect(math.abs(Data.lampBrightness(5.75) - 0.225) < 0.000000001):toBe(true)
			expect(Data.lampBrightness(6)):toBe(0)
			expect(Data.lampBrightness(12)):toBe(0)
			expect(Data.lampBrightness(nil)):toBe(0)
		end)

		t:it("keeps birds silent before 06:00 without staging a sound", function()
			expect(Data.BIRDS_START):toBe(6)
			expect(Data.birdsAudible(4.5)):toBe(false)
			expect(Data.birdsAudible(5)):toBe(false)
			expect(Data.birdsAudible(5.5)):toBe(false)
			expect(Data.birdsAudible(5.999)):toBe(false)
			expect(Data.birdsAudible(6)):toBe(true)
			expect(Data.birdsAudible(7)):toBe(true)
			expect(Data.birdsAudible(nil)):toBe(false)
			expect(dataSrc:find("Sound", 1, true) ~= nil):toBe(true) -- documented silence, not staged
			expect(applierSrc:find('new("Sound")', 1, true) == nil):toBe(true)
		end)

		t:it("interpolates a fresh preset and clamps stray clocks", function()
			local start = Data.presetFor(4.5)
			local finish = Data.presetFor(6)
			expect(start.ambient):toEqual(Data.PHASES[1].ambient)
			expect(finish.colorShiftTop):toEqual(Data.PHASES[4].colorShiftTop)
			expect(start.phaseId):toBe("subuh_0430")
			expect(finish.phaseId):toBe("pagi_0600")
			expect(Data.presetFor(16).brightness):toBe(1.8)
			expect(Data.presetFor(nil).brightness):toBe(1.2)
			expect(Data.phaseAt(5.5)):toBe("subuh_0530")
			local middle = Data.presetFor(5.25)
			expect(middle.brightness > start.brightness and middle.brightness < finish.brightness):toBe(true)
			expect(start ~= Data.presetFor(4.5)):toBe(true)
		end)

		t:it("keeps the pure module free of engine APIs, asset IDs and stale materials", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "assetId", 1, true) == nil):toBe(true)
			expect(dataSrc:find("%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(dataSrc:find("game%.", 1) == nil):toBe(true)
			expect(dataSrc:find("Enum%.", 1) == nil):toBe(true)
			expect(dataSrc:find("Instance%.", 1) == nil):toBe(true)
			expect(string.find(dataSrc, "require(", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Painted", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Leaf", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("subuh_r8 LookDev wiring", function()
		t:it("ships candidate 95 with a descriptor, keyed plan and client path", function()
			expect(#LookDev.IDS):toBe(116)
			expect(LookDev.IDS[95]):toBe("subuh_r8")
			local candidate = LookDev.candidates.subuh_r8
			expect(candidate.id):toBe("subuh_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(string.find(candidate.title, "client-only", 1, true) ~= nil):toBe(true)
			expect(candidate.idsSource):toBe("Shared.ModelMapSubuhR8")
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			expect(candidate.phaseCount):toBe(4)
			expect(candidate.tweenMin):toBe(20)
			expect(candidate.tweenMax):toBe(40)
			expect(candidate.birdsSilentUntil):toBe(6)
			local plan = LookDev.plan("subuh_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("subuh_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapSubuhR8")
			expect(plan.render):toBe(candidate.render)
			expect(plan.phaseCount):toBe(4)
			expect(plan.birdsSilentUntil):toBe(6)
			local entry = Review.paths.subuh_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevSubuhR8" })
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevSubuhR8%)", 1) ~= nil):toBe(true)
			expect(string.find(serverMainSrc, "LookDevSubuhR8", 1, true) == nil):toBe(true)
		end)

		t:it("appends DAWN_* last in ORDER and emits on every path", function()
			expect(
				harnessSrc:find(
					'"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",\n\t"SEASON_SAFE",\n\t"SEASON_RESTORE",\n\t"SEASON_DISTINCT",\n\t"RAIN_EMITTERS",\n\t"RAIN_OFF_CERAH",\n\t"RAIN_COST",\n\t"DAWN_PHASES_MONOTONIC",\n\t"DAWN_SAFE",\n\t"LIGHT_COST",\n}',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("DAWN_PHASES_MONOTONIC", false, 0, 3,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("DAWN_SAFE", false, 0, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"DAWN_PHASES_MONOTONIC",\n\t\tmonoPass and #errors == 0,', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find('emit("DAWN_SAFE", safePass, safeCount, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-- 9v. WORK_QUEUE section N item 121: subuh_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("runDawnChecks()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('dawnFailAll("client VM required")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Players.LocalPlayer.PlayerScripts.Client.World.LookDevSubuhR8", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("game.PlayerScripts.Client.World.LookDevSubuhR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ServerScriptService.Server.World.LookDevSubuhR8", 1, true) == nil):toBe(true)
			expect(harnessSrc:find("task.wait(5)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("api.setClockForCheck(clock)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("api.applyPhaseNowForCheck(clock)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("api.clearClockForCheck()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("look.enable(priorId, { studio = true })", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps every earlier ORDER literal byte-identical", function()
			expect(
				harnessSrc:find(
					'"LAUNDRY_PARTS",\n\t"LAUNDRY_CLOTH_CLEAR",\n\t"KITE_COUNT",\n\t"KITE_COST",\n\t"KITE_STRING_CLEAR",\n\t"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('"GRADE_SAFE",\n\t"GRADE_RESTORE",\n\t"GRADE_NO_DOF",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_EMITTERS", false, 0, 3,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_COST", false, "ERR", "<0.5ms",', 1, true) ~= nil):toBe(true)
		end)

		t:it("bumped IDS-count mirrors but not the paving count", function()
			for _, path in ipairs({
				"tests/specs/review_round3_bugfix_spec.luau",
				"tests/specs/terrain_map_r6_spec.luau",
				"tests/specs/sky_map_r6_spec.luau",
			}) do
				local src = fs.readFile(path)
				expect(src:find("expect(count):toBe(116)", 1, true) ~= nil, path):toBe(true)
			end
			expect(pavingSrc:find("expect(counts.total):toBe(" .. 94 .. ")", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("subuh_r8 applier", function()
		t:it("uses the DayCycle tween rules with a direct-write diagnostic path", function()
			expect(applierSrc:find("CLIENT-ONLY applier", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ModelMapSubuhR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("DayCycleLive.lampPositions()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("return (TweenInfo :: any).new(seconds, style, direction)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("if info and TweenService then", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("cancelTweens()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("if clockOverride ~= nil then\n\t\treturn clockOverride", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSubuhR8.setClockForCheck", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("applyAt(clock, false) -- cancel tweens; write through setProps", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("function LookDevSubuhR8.applyPhaseNowForCheck", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSubuhR8.clearClockForCheck", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("clockOverride = nil -- no check override may leak", 1, true) ~= nil):toBe(true)
		end)

		t:it("converts every colour prop to a real engine value before either write path", function()
			expect(applierSrc:find("local function engineColor", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.BYTE_COLOR_PROPS[prop]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.FRACTION_COLOR_PROPS[prop]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.normalizedColor(prop, value)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3 :: any).new(normalized.r, normalized.g, normalized.b)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find('FogColor = engineColor("FogColor", preset.fogColor)', 1, true) ~= nil):toBe(true)
			expect(
				applierSrc:find('ColorShift_Top = engineColor("ColorShift_Top", preset.colorShiftTop)', 1, true) ~= nil
			):toBe(true)
			expect(applierSrc:find('TintColor = engineColor("TintColor", preset.tintColor)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Color = engineColor("Color", preset.atmosphereColor)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Create(target, info, goals)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("setProps(target, goals)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("saveProp(target, prop) -- direct writes", 1, true) ~= nil):toBe(true)
			for _, raw in ipairs({
				"FogColor = preset.fogColor",
				"Ambient = preset.ambient",
				"ColorShift_Top = preset.colorShiftTop",
				"ColorShift_Bottom = preset.colorShiftBottom",
				"Color = preset.atmosphereColor",
				"Decay = Data.ATMOSPHERE_DECAY",
				"TintColor = preset.tintColor",
			}) do
				expect(applierSrc:find(raw, 1, true) == nil, raw):toBe(true)
			end
		end)

		t:it("owns at most six non-shadow lamps and restores LIFO", function()
			expect(applierSrc:find("Data.LAMP.maxLights", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pointLight.Shadows = Data.LAMP.shadows", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pointLight.Range = Data.LAMP.range", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("for index = #originals, 1, -1 do", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.id", 1, true) ~= nil):toBe(true)
			for _, name in ipairs({
				"currentClock",
				"setClockForCheck",
				"applyPhaseNowForCheck",
				"clearClockForCheck",
				"isApplied",
				"phaseCount",
				"appliedPhase",
				"safeReadings",
			}) do
				expect(applierSrc:find("function LookDevSubuhR8." .. name, 1, true) ~= nil, name):toBe(true)
			end
		end)

		t:it("writes no terrain, DataStore, state, sound or forbidden effect property", function()
			for _, forbidden in ipairs({
				"FillBlock",
				"ReadVoxels",
				"WriteVoxels",
				"GetDataStore",
				"DataStoreService",
				"SetAsync",
				"UpdateAsync",
				"rbxassetid://",
				'new("Sound")',
				'Instance.new("Sound")',
			}) do
				expect(applierSrc:find(forbidden, 1, true) == nil, forbidden):toBe(true)
			end
			expect(applierSrc:find("%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("drives an override-first clock with a safe default", function()
			env.services.Lighting = {
				ClockTime = 12,
				FindFirstChildOfClass = function()
					return nil
				end,
			}
			env.services.Workspace = {
				FindFirstChild = function()
					return nil
				end,
				FindFirstChildOfClass = function()
					return nil
				end,
			}
			local A = env:require("client/World/LookDevSubuhR8")
			expect(type(A.setClockForCheck)):toBe("function")
			expect(type(A.applyPhaseNowForCheck)):toBe("function")
			expect(type(A.clearClockForCheck)):toBe("function")
			expect(type(A.safeReadings)):toBe("function")
			expect(A.phaseCount()):toBe(4)
			expect(A.isApplied()):toBe(false)
			expect(A.currentClock()):toBe(12)
			expect(A.setClockForCheck(4.5)):toBe(true)
			expect(A.currentClock()):toBe(4.5)
			expect(A.setClockForCheck("bad")):toBe(false)
			expect(A.currentClock()):toBe(4.5)
			expect(A.applyPhaseNowForCheck(6)):toBe(true)
			expect(A.currentClock()):toBe(6)
			expect(A.clearClockForCheck()):toBe(true)
			expect(A.currentClock()):toBe(12)

			-- Real regression: the fake Color3 has uppercase R/G/B, never lowercase byte keys.
			A.apply()
			local fog = env.services.Lighting.FogColor
			local top = env.services.Lighting.ColorShift_Top
			expect(type(fog)):toBe("table")
			expect(fog.R ~= nil and fog.G ~= nil and fog.B ~= nil):toBe(true)
			expect(fog.r == nil and fog.g == nil and fog.b == nil):toBe(true)
			expect(math.abs(fog.R - 240 / 255) < 0.000000001):toBe(true)
			expect(math.abs(top.R - 235 / 255) < 0.000000001):toBe(true)
			A.restore()
			expect(A.isApplied()):toBe(false)
		end)
	end)

	t:describe("subuh_r8 gallery", function()
		t:it("records one pending six-column row", function()
			local row = string.match(gallerySrc, "\n(| `subuh_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("subuh_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "DAWN_PHASES_MONOTONIC", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "DAWN_SAFE", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
		end)
	end)
end
