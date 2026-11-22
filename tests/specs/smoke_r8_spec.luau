--!nocheck
-- WORK_QUEUE section M item 84: smoke_r8 chimney smoke, Warung steam and night-only torches.
-- Pure MapSpec-derived recipes and budgets, LookDev + review wiring, the three new read-only
-- harness checks and the client applier's source guards. No Studio claim: CHECK evidence, tracker
-- ticks and the visual verdict belong to the main session / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapSmokeR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	-- Loading the real applier proves it is import-safe without Roblox Instance globals.
	env:require("client/World/LookDevSmokeR8")

	local dataSrc = fs.readFile("src/shared/ModelMapSmokeR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevSmokeR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local built = Data.recipes(MapSpec)

	t:describe("smoke_r8 pure recipes", function()
		t:it("locks the item-84 emitter and rate budgets", function()
			expect(Data.id):toBe("smoke_r8")
			expect(Data.folder):toBe("LookDevSmokeR8_smoke_r8")
			expect(Data.MAX_EMITTERS):toBe(12)
			expect(Data.MAX_RATE):toBe(12)
			expect(Data.MAX_LIGHTS):toBe(24)
			expect(Data.MAX_RANGE):toBe(30)
			expect(Data.NIGHT_ON):toBe(18)
			expect(Data.NIGHT_OFF):toBe(6)
			expect(Data.emitterCount(built)):toBe(#built.emitters)
			expect(Data.emitterCount(built) <= Data.MAX_EMITTERS):toBe(true)
			expect(#built.emitters):toBe(9)
			local maxRate = 0
			for _, emitter in ipairs(built.emitters) do
				expect(type(emitter.id) == "string"):toBe(true)
				expect(emitter.rate > 0 and emitter.rate <= Data.MAX_RATE):toBe(true)
				maxRate = math.max(maxRate, emitter.rate)
				expect(type(emitter.position.x) == "number"):toBe(true)
				expect(type(emitter.position.y) == "number"):toBe(true)
				expect(type(emitter.position.z) == "number"):toBe(true)
			end
			expect(maxRate):toBe(10)
			local counts = Data.kindCounts(built.emitters)
			expect(counts.chimney):toBe(2)
			expect(counts.steam):toBe(1)
			expect(counts.torch_flame):toBe(6)
			for _, emitter in ipairs(built.emitters) do
				if emitter.kind == "torch_flame" then
					expect(emitter.nightOnly):toBe(true)
				else
					expect(emitter.nightOnly):toBe(false)
				end
			end
		end)

		t:it("locks the light budget and gives every torch a seeded light", function()
			expect(Data.lightCount(built)):toBe(#built.lights)
			expect(Data.lightCount(built) <= Data.MAX_LIGHTS):toBe(true)
			expect(#built.lights):toBe(6)
			local maxRange = 0
			for _, light in ipairs(built.lights) do
				expect(light.range > 0 and light.range <= Data.MAX_RANGE):toBe(true)
				expect(type(light.seed) == "number"):toBe(true)
				expect(light.nightOnly):toBe(true)
				maxRange = math.max(maxRange, light.range)
			end
			expect(maxRange):toBe(14)
		end)

		t:it("derives every position from MapSpec geometry", function()
			local warung = MapSpec.hub("warung")
			local pasar = MapSpec.hub("pasar")
			local chimneyWarung, chimneyPasar = built.emitters[1], built.emitters[2]
			local wx, wz = MapSpec.hubPoint(warung, -warung.width * 0.18, -warung.depth * 0.12)
			local px, pz = MapSpec.hubPoint(pasar, pasar.width * 0.18, -pasar.depth * 0.12)
			expect(chimneyWarung.position.x):toBe(wx)
			expect(chimneyWarung.position.z):toBe(wz)
			expect(chimneyWarung.position.y):toBe(warung.ridge + 2)
			expect(chimneyPasar.position.x):toBe(px)
			expect(chimneyPasar.position.z):toBe(pz)
			expect(chimneyPasar.position.y):toBe(pasar.ridge + 2)

			local steam = built.emitters[3]
			local sx, sz = MapSpec.hubPoint(warung, warung.anchor.lx, warung.anchor.lz)
			expect(steam.position.x):toBe(sx)
			expect(steam.position.z):toBe(sz)
			expect(steam.position.y):toBe(MapSpec.GROUND_Y + warung.anchor.sy + 1.2)

			for index, key in ipairs(MapSpec.HUB_ORDER) do
				local hub = MapSpec.hub(key)
				local tx, tz = MapSpec.hubPoint(hub, hub.width * 0.36, hub.depth * 0.5 + 4)
				local flame = built.emitters[3 + index]
				local light = built.lights[index]
				expect(flame.position.x):toBe(tx)
				expect(flame.position.z):toBe(tz)
				expect(flame.position.y):toBe(light.position.y)
				expect(light.position.x):toBe(tx)
				expect(light.position.z):toBe(tz)
			end
		end)

		t:it("reads ClockTime 13 as day and 20 / 5 as night", function()
			expect(Data.isNight(13)):toBe(false)
			expect(Data.isNight(20)):toBe(true)
			expect(Data.isNight(5)):toBe(true)
			expect(Data.isNight(6)):toBe(false)
			expect(Data.isNight(18)):toBe(true)
			expect(Data.isNight(nil)):toBe(false)
		end)

		t:it("flickers deterministically inside 0.7..1.0", function()
			for seed = 0, 40 do
				for step = 0, 200 do
					local value = Data.flicker(step * 0.13, seed)
					expect(value >= 0.7 and value <= 1):toBe(true)
				end
			end
			expect(Data.flicker(3.25, 17)):toBe(Data.flicker(3.25, 17))
			expect(Data.flicker(nil, nil) >= 0.7 and Data.flicker(nil, nil) <= 1):toBe(true)
		end)

		t:it("carries no engine API or asset ID in the pure module", function()
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("smoke_r8 wiring, harness and applier", function()
		t:it("ships candidate 69 with a client review path", function()
			expect(#LookDev.IDS):toBe(106)
			expect(LookDev.IDS[69]):toBe("smoke_r8")
			local candidate = LookDev.candidates.smoke_r8
			expect(candidate.id):toBe("smoke_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.idsSource):toBe("Shared.ModelMapSmokeR8")
			expect(candidate.maxEmitters):toBe(12)
			expect(candidate.maxLights):toBe(24)
			local plan = LookDev.plan("smoke_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("smoke_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapSmokeR8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.smoke_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevSmokeR8" })
		end)

		t:it("adds three pure read-only checks after FLYER_COST inside their own block", function()
			local flyerCostAt = harnessSrc:find('"FLYER_COST",', 1, true)
			local emittersAt = harnessSrc:find('"EMITTERS",', 1, true)
			local lightsAt = harnessSrc:find('"LIGHTS",', 1, true)
			local torchNightAt = harnessSrc:find('"TORCH_NIGHT",', 1, true)
			expect(flyerCostAt ~= nil and emittersAt ~= nil and lightsAt ~= nil and torchNightAt ~= nil):toBe(true)
			expect(flyerCostAt < emittersAt and emittersAt < lightsAt and lightsAt < torchNightAt):toBe(true)
			for _, name in ipairs({ "EMITTERS", "LIGHTS", "TORCH_NIGHT" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted):toBe(1)
			end
			expect(harnessSrc:find("do\n%-%- 9h%-5%. WORK_QUEUE section M item 84", 1) ~= nil):toBe(true)
			expect(harnessSrc:find("SR8.recipes(MapSpec)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("SR8.isNight(13)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("SR8.isNight(20)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("SR8.isNight(5)", 1, true) ~= nil):toBe(true)
		end)

		t:it("gates flames and lights on ClockTime and flickers from one Heartbeat", function()
			expect(applierSrc:find("require(Shared.ModelMapSmokeR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("ParticleEmitter")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("PointLight")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("isNight(Lighting.ClockTime)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('GetPropertyChangedSignal("ClockTime")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Smoke.flicker(elapsed, entry.seed)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Smoke.id", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)

		t:it("builds ParticleEmitter Lifetime and Speed as NumberRange, never NumberSequence", function()
			-- Item 107 clean-Play smoke: these two properties are NumberRange on Roblox; using
			-- NumberSequence makes buildEmitter fail and warn once per emitter (9x per full_r9 stage).
			expect(applierSrc:find("pe.Lifetime = NumberRange.new(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Speed = NumberRange.new(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pe.Lifetime = NumberSequence", 1, true) == nil):toBe(true)
			expect(applierSrc:find("pe.Speed = NumberSequence", 1, true) == nil):toBe(true)
		end)

		t:it("names a pending gallery row with an existing render path and fps note", function()
			local row = string.match(gallerySrc, "\n(| `smoke_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("smoke_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
