--!nocheck
-- WORK_QUEUE section M item 90: night_r8 warm night windows and lamps. Pure-model checks run for
-- real under Lune; LookDev wiring, applier source, harness source and boot wiring are static guards.
-- Lune cannot run the Roblox applier — no Studio claim, no CHECK evidence and no visual verdict here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapNightR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local MapSpec = env:require("server/World/MapSpec")
	local applierSrc = fs.readFile("src/server/World/LookDevNightR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local dataSrc = fs.readFile("src/shared/ModelMapNightR8.luau")

	local function finite(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	local function signature(list)
		local out = {}
		for index, entry in ipairs(list) do
			out[index] = table.concat({
				tostring(entry.x),
				tostring(entry.y),
				tostring(entry.z),
				tostring(entry.orientation or 0),
				tostring(entry.hubKey or entry.id or ""),
			}, ":")
		end
		return table.concat(out, "|")
	end

	t:describe("night_r8 pure model", function()
		t:it("exports pure identifiers and the exact warm palette", function()
			expect(Data.id):toBe("night_r8")
			expect(Data.familyId):toBe("night_r8")
			expect(Data.lookDevId):toBe("night_r8")
			expect(Data.folder):toBe("LookDevNightR8_night_r8")
			expect(Data.WINDOW_COLOR_HEX):toBe("#FFCB7A")
			expect(Data.WINDOW_RGB):toEqual({ 255, 203, 122 })
			expect(Data.WINDOW_MATERIAL):toBe("Neon")
			expect(Data.DAY_WINDOW_MATERIAL):toBe("Glass")
			expect(Data.MAX_LIGHTS):toBe(24)
			expect(Data.GLOW_LIGHT_COUNT):toBe(12)
			expect(Data.LAMP_RANGE):toBe(14)
			expect(Data.GLOW_INTENSITY < 1):toBe(true)
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)

		t:it("gates night at 18..6: 13 day, 20 and 5 night", function()
			expect(Data.isNight(13)):toBe(false)
			expect(Data.isNight(20)):toBe(true)
			expect(Data.isNight(5)):toBe(true)
			expect(Data.isNight(18)):toBe(true)
			expect(Data.isNight(6)):toBe(false)
			expect(Data.isNight("20")):toBe(false)
			expect(Data.isNight(0 / 0)):toBe(false)
			expect(Data.litWindowCount(20) >= 12):toBe(true)
			expect(Data.litWindowCount(13)):toBe(0)
			expect(Data.litLightCount(20) <= 24):toBe(true)
			expect(Data.litLightCount(20) >= 1):toBe(true)
			expect(Data.litLightCount(13)):toBe(0)
		end)

		t:it("keeps deterministic in-bounds window and lamp data", function()
			expect(#Data.WINDOW_SPECS >= 12):toBe(true)
			expect(Data.MAX_WINDOWS):toBe(#Data.WINDOW_SPECS)
			expect(#Data.LAMP_SPECS):toBe(Data.GLOW_LIGHT_COUNT)
			expect(#Data.LAMP_SPECS <= Data.MAX_LIGHTS):toBe(true)
			local hubs = {}
			local posts, torches = 0, 0
			for _, entry in ipairs(Data.WINDOW_SPECS) do
				expect(finite(entry.x) and finite(entry.y) and finite(entry.z)):toBe(true)
				expect(entry.y > 0 and entry.y < 100):toBe(true)
				expect(math.abs(entry.x) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(entry.z) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(type(entry.size) == "table" and #entry.size == 3):toBe(true)
				expect(type(entry.hubKey) == "string" and type(entry.orientation) == "number"):toBe(true)
				hubs[entry.hubKey] = true
			end
			for _, key in ipairs(MapSpec.HUB_ORDER) do
				expect(hubs[key] == true):toBe(true)
			end
			for _, entry in ipairs(Data.LAMP_SPECS) do
				expect(finite(entry.x) and finite(entry.y) and finite(entry.z)):toBe(true)
				expect(entry.y > 0 and entry.y < 100):toBe(true)
				expect(math.abs(entry.x) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(entry.z) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(type(entry.id) == "string" and type(entry.name) == "string"):toBe(true)
				if entry.kind == "post" then
					posts += 1
				elseif entry.kind == "torch" then
					torches += 1
				end
			end
			expect(posts):toBe(6)
			expect(torches):toBe(6)
			local before = signature(Data.WINDOW_SPECS) .. "#" .. signature(Data.LAMP_SPECS)
			Data.isNight(20)
			Data.litWindowCount(13)
			Data.litLightCount(5)
			expect(signature(Data.WINDOW_SPECS) .. "#" .. signature(Data.LAMP_SPECS)):toBe(before)
		end)
	end)

	t:describe("night_r8 wiring", function()
		t:it("ships candidate 75 with a SERVER review path", function()
			expect(#LookDev.IDS):toBe(105)
			expect(LookDev.IDS[75]):toBe("night_r8")
			local candidate = LookDev.candidates.night_r8
			expect(candidate.id):toBe("night_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapNightR8")
			expect(candidate.maxLights):toBe(24)
			local plan = LookDev.plan("night_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("night_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapNightR8")
			expect(plan.maxLights):toBe(24)
			local entry = Review.paths.night_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevNightR8" })
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevNightR8%)", 1) ~= nil):toBe(true)
		end)

		t:it("guards the applier source: clock override, Neon, shadowless lights, exact restore", function()
			expect(string.find(applierSrc, "require%(%(Shared :: any%)%.ModelMapNightR8%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "setClockForCheck", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "clearClockForCheck", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, 'GetPropertyChangedSignal%("ClockTime"%)', 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Enum%.Material%[", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "fromRGB(255, 203, 122)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "PointLight", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "point.Shadows = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, 'LookDev.register("night_r8"', 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LookDevNightR8.restore = restore", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Failures.set", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "diagnostics", 1, true) ~= nil):toBe(true)
			-- No gameplay hook and no direct Lighting.ClockTime write: the override never mutates it.
			expect(string.find(applierSrc, "FarmService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "EconomyService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "RaidCutscene", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "Lighting.ClockTime =", 1, true) == nil):toBe(true)
		end)

		t:it("adds both harness checks before LOOKDEV_LEAK with the deterministic clock override", function()
			local a = harnessSrc:find('"NIGHT_WINDOWS",', 1, true)
			local b = harnessSrc:find('"NIGHT_LIGHTS",', 1, true)
			local leak = harnessSrc:find('"LOOKDEV_LEAK",', 1, true)
			expect(a ~= nil and b ~= nil and leak ~= nil):toBe(true)
			expect(a < b and b < leak):toBe(true)
			local block = harnessSrc:find("-- 12g. Item 90", 1, true)
			local leakEmit = harnessSrc:find("-- 13. LOOKDEV_LEAK:", 1, true)
			expect(block ~= nil and leakEmit ~= nil and block > leak and block < leakEmit):toBe(true)
			local body = harnessSrc:sub(block, leakEmit)
			expect(string.find(body, "setClockForCheck%(20%)", 1) ~= nil):toBe(true)
			expect(string.find(body, "setClockForCheck%(13%)", 1) ~= nil):toBe(true)
			expect(string.find(body, "clearClockForCheck", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "Enum%.Material%.Neon", 1) ~= nil):toBe(true)
			expect(string.find(body, "instance%.Shadows", 1) ~= nil):toBe(true)
			expect(string.find(body, '"NIGHT_WINDOWS",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"NIGHT_LIGHTS",', 1, true) ~= nil):toBe(true)
		end)
	end)
end
