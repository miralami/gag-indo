--!nocheck
-- WORK_QUEUE section N item 120: rain_r8, a client rain ring plus a bounded morning-mist bump.
-- Pure-model checks run for real under Lune; LookDev/review wiring, applier source and the harness
-- block are static guards. RAIN_COST is a deterministic pump timing proxy, not an fps claim.
-- No Studio verdict: CHECK evidence, tracker ticks and the visual yes/no belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapRainR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapRainR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevRainR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/client/Main.client.luau")
	local serverMainSrc = fs.readFile("src/server/Main.server.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local CHANNELS = { "r", "g", "b" }

	local function finite(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	t:describe("rain_r8 pure model", function()
		t:it("exports a three-emitter recipe inside the item-120 budgets", function()
			expect(Data.id):toBe("rain_r8")
			expect(Data.MAX_EMITTERS):toBe(3)
			expect(Data.MAX_RATE):toBe(60)
			expect(Data.emitterCount()):toBe(3)
			expect(Data.emitterCount() <= Data.MAX_EMITTERS):toBe(true)
			expect(Data.maxRate()):toBe(50)
			expect(Data.maxRate() <= Data.MAX_RATE):toBe(true)
			expect(#Data.EMITTERS):toBe(Data.emitterCount())
			local rings, splashes = 0, 0
			for _, spec in ipairs(Data.EMITTERS) do
				expect(type(spec.id)):toBe("string")
				expect(spec.kind == "ring" or spec.kind == "splash"):toBe(true)
				if spec.kind == "ring" then
					rings += 1
				else
					splashes += 1
				end
				expect(type(spec.rate) == "number" and spec.rate > 0 and spec.rate <= Data.MAX_RATE):toBe(true)
				expect(finite(spec.lifetime[1]) and finite(spec.lifetime[2])):toBe(true)
				expect(spec.lifetime[1] < spec.lifetime[2]):toBe(true)
				expect(finite(spec.speed[1]) and finite(spec.speed[2])):toBe(true)
				expect(spec.speed[1] < spec.speed[2]):toBe(true)
				expect(#spec.size):toBe(2)
				expect(finite(spec.size[1]) and finite(spec.size[2])):toBe(true)
				expect(finite(spec.offset.x) and finite(spec.offset.y) and finite(spec.offset.z)):toBe(true)
				expect(finite(spec.spread.x) and finite(spec.spread.y)):toBe(true)
				for _, channel in ipairs(CHANNELS) do
					expect(spec.color[channel] >= 0 and spec.color[channel] <= 255):toBe(true)
				end
			end
			expect(rings):toBe(2)
			expect(splashes):toBe(1)
		end)

		t:it("documents the splash ground height and bounded mist delta", function()
			expect(Data.SPLASH_Y):toBe(0.53)
			expect(Data.MIST_DELTA):toBe(0.05)
			expect(Data.MIST_MAX):toBe(0.35)
			expect(Data.MIST_DELTA > 0 and Data.MIST_MAX < 1):toBe(true)
			expect(math.min(0.18 + Data.MIST_DELTA, Data.MIST_MAX) <= Data.MIST_MAX):toBe(true)
			expect(dataSrc:find("Ground.Y 0.5 + 0.03", 1, true) ~= nil):toBe(true)
		end)

		t:it("sets the cost proxy literals and pure weather predicate", function()
			expect(Data.MAX_STEP_MS):toBe(0.5)
			expect(Data.SIM_SECONDS):toBe(60)
			expect(math.abs(Data.DT - 1 / 60) < 0.000000001):toBe(true)
			expect(math.ceil(Data.SIM_SECONDS / Data.DT)):toBe(3600)
			expect(Data.WEATHER_RAIN):toBe("hujan")
			expect(Data.WEATHER_CLEAR):toBe("cerah")
			expect(Data.weatherIsRain("hujan")):toBe(true)
			expect(Data.weatherIsRain("cerah")):toBe(false)
			expect(Data.weatherIsRain("badai")):toBe(false)
			expect(Data.weatherIsRain(nil)):toBe(false)
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

	t:describe("rain_r8 LookDev wiring", function()
		t:it("ships candidate 94 with a descriptor, keyed plan and client path", function()
			expect(#LookDev.IDS):toBe(109)
			expect(LookDev.IDS[94]):toBe("rain_r8")
			local candidate = LookDev.candidates.rain_r8
			expect(candidate.id):toBe("rain_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(string.find(candidate.title, "client-only", 1, true) ~= nil):toBe(true)
			expect(candidate.idsSource):toBe("Shared.ModelMapRainR8")
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			expect(candidate.maxEmitters):toBe(3)
			expect(candidate.maxRate):toBe(60)
			local plan = LookDev.plan("rain_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("rain_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapRainR8")
			expect(plan.render):toBe(candidate.render)
			expect(plan.maxEmitters):toBe(3)
			expect(plan.maxRate):toBe(60)
			local entry = Review.paths.rain_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevRainR8" })
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevRainR8%)", 1) ~= nil):toBe(true)
			expect(string.find(serverMainSrc, "LookDevRainR8", 1, true) == nil):toBe(true)
		end)

		t:it("appends RAIN_* last in ORDER and emits on every path", function()
			expect(
				harnessSrc:find(
					'"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",\n\t"SEASON_SAFE",\n\t"SEASON_RESTORE",\n\t"SEASON_DISTINCT",\n\t"RAIN_EMITTERS",\n\t"RAIN_OFF_CERAH",\n\t"RAIN_COST",\n\t"DAWN_PHASES_MONOTONIC",\n\t"DAWN_SAFE",\n\t"LIGHT_COST",\n}',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("RAIN_EMITTERS", false, 0, 3,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_OFF_CERAH", false, 0, 0,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_COST", false, "ERR", "<0.5ms",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_EMITTERS", emitterPass, #liveEmitters,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("RAIN_OFF_CERAH", gatePass, offCount, #liveEmitters,', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find('emit("RAIN_COST", costPass, measuredMs, "<0.5ms",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-- 9u. WORK_QUEUE section N item 120: rain_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("runRainChecks()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Players.LocalPlayer.PlayerScripts.Client.World.LookDevRainR8", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("game.PlayerScripts.Client.World.LookDevRainR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("run:IsClient()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("os.clock()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("api.pump(rainMap.DT)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('typeof(life) == "NumberRange"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('typeof(speed) == "NumberRange"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ServerScriptService.Server.World.LookDevRainR8", 1, true) == nil):toBe(true)
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
		end)
	end)

	t:describe("rain_r8 applier", function()
		t:it("gates emitters on an override-first weather read with a safe clear default", function()
			expect(applierSrc:find("CLIENT-ONLY", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ModelMapRainR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("if cuacaOverride ~= nil then\n\t\treturn cuacaOverride", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('GetAttribute("Cuaca")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("return Data.WEATHER_CLEAR", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.weatherIsRain(currentCuaca())", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevRainR8.setCuacaForCheck", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevRainR8.clearCuacaForCheck", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("cuacaOverride = nil -- no check override may leak", 1, true) ~= nil):toBe(true)
		end)

		t:it("drives the clear override and restores attribute/default weather", function()
			env.services.Lighting = {
				FindFirstChildOfClass = function()
					return nil
				end,
			}
			env.services.Workspace = {
				FindFirstChild = function()
					return nil
				end,
			}
			local A = env:require("client/World/LookDevRainR8")
			expect(type(A.setCuacaForCheck)):toBe("function")
			expect(type(A.clearCuacaForCheck)):toBe("function")
			expect(type(A.currentWeather)):toBe("function")

			env.services.ReplicatedStorage:SetAttribute("Cuaca", Data.WEATHER_RAIN)
			expect(A.currentWeather()):toBe(Data.WEATHER_RAIN)
			expect(A.setCuacaForCheck(Data.WEATHER_CLEAR)):toBe(true)
			expect(A.currentWeather()):toBe(Data.WEATHER_CLEAR)
			expect(A.clearCuacaForCheck()):toBe(true)
			expect(A.currentWeather()):toBe(Data.WEATHER_RAIN)

			env.services.ReplicatedStorage:SetAttribute("Cuaca", nil)
			expect(A.currentWeather()):toBe(Data.WEATHER_CLEAR)
		end)

		t:it("builds textureless emitters with NumberRange Lifetime and Speed", function()
			-- Item 107's smoke regression: these two properties are NumberRange on Roblox; a
			-- NumberSequence makes the build fail once per emitter.
			expect(applierSrc:find('(Instance :: any).new("ParticleEmitter")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Lifetime = (NumberRange :: any).new(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Speed = (NumberRange :: any).new(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Lifetime = NumberSequence", 1, true) == nil):toBe(true)
			expect(applierSrc:find("pe.Speed = NumberSequence", 1, true) == nil):toBe(true)
			-- Roblox NumberSequence.new takes a keypoint TABLE (or numbers), not two keypoint args.
			-- The two-arg form warns once per emitter and leaves the folder empty in a clean Client VM.
			expect(applierSrc:find("pe.Size = (NumberSequence :: any).new({", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Size = (NumberSequence :: any).new(\n", 1, true) == nil):toBe(true)
			expect(applierSrc:find("pe.Texture", 1, true) == nil):toBe(true)
			expect(applierSrc:find("pe.Rate = spec.rate", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.emitterCount() > Data.MAX_EMITTERS", 1, true) ~= nil):toBe(true)
		end)

		t:it("follows the camera from one Heartbeat and restores LIFO on disable", function()
			expect(applierSrc:find("CurrentCamera", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("frame * (CFrame :: any).new(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.SPLASH_Y", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeatConnection:Disconnect()", 1, true) ~= nil):toBe(true)
			expect(
				applierSrc:find("effect.Density = math.min(original + Data.MIST_DELTA, Data.MIST_MAX)", 1, true) ~= nil
			):toBe(true)
			expect(applierSrc:find("atmosphere.Density = saved", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("savedDensity = nil -- LIFO exact restore", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.id", 1, true) ~= nil):toBe(true)
			for _, name in ipairs({
				"emitterCount",
				"isApplied",
				"currentWeather",
				"pump",
				"lastCostMs",
				"setCuacaForCheck",
				"clearCuacaForCheck",
			}) do
				expect(applierSrc:find("function LookDevRainR8." .. name, 1, true) ~= nil, name):toBe(true)
			end
		end)

		t:it("writes no terrain, DataStore, state or forbidden effect property", function()
			for _, forbidden in ipairs({
				"FillBlock",
				"ReadVoxels",
				"WriteVoxels",
				"GetDataStore",
				"DataStoreService",
				"SetAsync",
				"UpdateAsync",
				"rbxassetid://",
				"ClockTime =",
				"ColorCorrectionEffect",
				"BloomEffect",
				"SunRaysEffect",
			}) do
				expect(applierSrc:find(forbidden, 1, true) == nil, forbidden):toBe(true)
			end
			expect(applierSrc:find("%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("rain_r8 gallery", function()
		t:it("records one pending six-column row", function()
			local row = string.match(gallerySrc, "\n(| `rain_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("rain_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "RAIN_EMITTERS", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "RAIN_OFF_CERAH", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "RAIN_COST", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
