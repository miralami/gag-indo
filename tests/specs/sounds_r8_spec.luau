--!nocheck
-- WORK_QUEUE section M item 92: sounds_r8 ambient sound beds. Pure-model checks run for real
-- under Lune; LookDev wiring, applier source, harness source and boot wiring are static guards.
-- Lune cannot load Roblox audio — no Studio claim, no CHECK evidence and no aural verdict here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapSoundsR8")
	local Repeat = Env.new():require("shared/ModelMapSoundsR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapSoundsR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevSoundsR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")

	local VERIFIED_IDS = {
		jangkrik = 9114894498,
		ayam = 9114370190,
		birds = 9112750044,
		river = 9118187543,
		wind = 116565742544806,
		kentongan = 9046655769,
	}
	local ORDER = { "jangkrik", "ayam", "birds", "river", "wind", "kentongan" }

	t:describe("sounds_r8 pure model", function()
		t:it("exports six beds with the verified Creator Store IDs and deterministic accessors", function()
			expect(Data.id):toBe("sounds_r8")
			expect(Data.lookDevId):toBe("sounds_r8")
			expect(Data.folder):toBe("LookDevSoundsR8_sounds_r8")
			expect(Data.groupName):toBe("JD_sounds_r8")
			expect(#Data.BEDS):toBe(6)
			expect(Data.bedOrder):toEqual(ORDER)
			expect(Data.MAX_VOLUME):toBe(0.5)
			expect(Data.MAX_ROLLOFF):toBe(80)
			expect(Data.LOAD_TIMEOUT_S):toBe(10)
			expect(Data.ROLLOFF_MIN):toBe(4)
			for index, key in ipairs(ORDER) do
				local bed = Data.BEDS[index]
				expect(bed.key):toBe(key)
				expect(bed.id):toBe(VERIFIED_IDS[key])
				expect(type(bed.name)):toBe("string")
				expect(#bed.name > 0):toBe(true)
				expect(type(bed.creator)):toBe("string")
				expect(#bed.creator > 0):toBe(true)
				expect(bed.looped):toBe(true)
				expect(Data.bedFor(key)):toEqual(bed)
				expect(Data.idFor(key)):toBe(VERIFIED_IDS[key])
			end
			expect(Data.bedFor("unknown")):toBe(nil)
			expect(Data.idFor("unknown")):toBe(nil)
			expect(Data.BEDS):toEqual(Repeat.BEDS)
			expect(Data.bedOrder):toEqual(Repeat.bedOrder)
		end)

		t:it("caps every bed at volume 0.5 and rolloff 80 with spread positions", function()
			local slots, seen = {}, {}
			for _, bed in ipairs(Data.BEDS) do
				expect(type(bed.volume)):toBe("number")
				expect(bed.volume > 0 and bed.volume <= Data.MAX_VOLUME):toBe(true)
				expect(type(bed.rollOffMax)):toBe("number")
				expect(bed.rollOffMax > Data.ROLLOFF_MIN and bed.rollOffMax <= Data.MAX_ROLLOFF):toBe(true)
				expect(bed.timeSlot == "night" or bed.timeSlot == "day" or bed.timeSlot == "always"):toBe(true)
				slots[bed.timeSlot] = true
				expect(type(bed.position)):toBe("table")
				for _, axis in ipairs({ "x", "y", "z" }) do
					local value = bed.position[axis]
					expect(type(value)):toBe("number")
					expect(value > -400 and value < 400):toBe(true)
				end
				expect(seen[bed.key] == nil):toBe(true)
				seen[bed.key] = true
			end
			expect(slots.night == true and slots.day == true and slots.always == true):toBe(true)
			expect(Data.bedFor("jangkrik").timeSlot):toBe("night")
			expect(Data.bedFor("ayam").timeSlot):toBe("day")
			expect(Data.bedFor("birds").timeSlot):toBe("day")
			expect(Data.bedFor("river").timeSlot):toBe("always")
			expect(Data.bedFor("wind").timeSlot):toBe("always")
		end)

		t:it("stays pure: no engine API, no asset URL literal and no invented id", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance%.new", 1) == nil):toBe(true)
			expect(string.find(dataSrc, "game:", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum%.", 1) == nil):toBe(true)
			expect(string.find(dataSrc, "GetService", 1, true) == nil):toBe(true)
			for _, id in pairs(VERIFIED_IDS) do
				expect(type(id)):toBe("number")
			end
		end)
	end)

	t:describe("sounds_r8 wiring", function()
		t:it("adds one SERVER candidate with the six-bed descriptor and review path", function()
			expect(#LookDev.IDS):toBe(105)
			expect(LookDev.IDS[79]):toBe("sounds_r8")
			expect(LookDev.IDS[8]):toBe("sounds")
			local candidate = LookDev.candidates.sounds_r8
			expect(candidate.id):toBe("sounds_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapSoundsR8")
			expect(candidate.soundCount):toBe(6)
			local plan = LookDev.plan("sounds_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("sounds_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapSoundsR8")
			expect(plan.soundCount):toBe(6)
			local entry = Review.paths.sounds_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevSoundsR8" })
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevSoundsR8%)", 1) ~= nil):toBe(
				true
			)
		end)

		t:it("guards the applier: positional capped beds, one group, setup failures, exact restore", function()
			expect(string.find(applierSrc, "FindFirstChild%(Data%.groupName%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Instance") ~= nil):toBe(true)
			expect(string.find(applierSrc, "SoundGroup", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "RollOffMaxDistance", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "RollOffMinDistance", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "ASSET_PREFIX .. tostring%(bed%.id%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "math%.min%(bed%.volume, Data%.MAX_VOLUME%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "math%.min%(bed%.rollOffMax, Data%.MAX_ROLLOFF%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LookDev%.register%(Data%.id", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Failures%.set", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "sound:Stop()", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "sound:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "pcall", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "diagnostics", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "bedSpecs", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "rbxassetid://%d", 1) == nil):toBe(true)
			for _, id in pairs(VERIFIED_IDS) do
				expect(string.find(applierSrc, tostring(id), 1, true) == nil):toBe(true)
			end
			expect(string.find(applierSrc, "FarmService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "EconomyService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "RaidCutscene", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "Humanoid", 1, true) == nil):toBe(true)
		end)

		t:it("adds three harness checks before LOOKDEV_LEAK in their own scope", function()
			local a = harnessSrc:find('"SOUND_LOADED",', 1, true)
			local b = harnessSrc:find('"SOUND_VOLUME",', 1, true)
			local c = harnessSrc:find('"SOUND_RESTORE",', 1, true)
			local leak = harnessSrc:find('"LOOKDEV_LEAK",', 1, true)
			expect(a ~= nil and b ~= nil and c ~= nil and leak ~= nil):toBe(true)
			expect(a < b and b < c and c < leak):toBe(true)
			local block = harnessSrc:find("-- 12i. Item 92", 1, true)
			local leakEmit = harnessSrc:find("-- 13. LOOKDEV_LEAK:", 1, true)
			expect(block ~= nil and leakEmit ~= nil and block > leak and block < leakEmit):toBe(true)
			local body = harnessSrc:sub(block, leakEmit)
			expect(string.find(body, "\ndo\n", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "\nend\n\n", 1, true) ~= nil):toBe(true)
			-- Registration happens at module load; a saved place's boot may predate this applier.
			expect(string.find(body, "ServerScriptService.Server.World.LookDevSoundsR8", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "Data.LOAD_TIMEOUT_S", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "task.wait", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "os.clock", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "IsLoaded", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "MAX_VOLUME", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "MAX_ROLLOFF", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "SoundGroup", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "BasePart", 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"SOUND_LOADED",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"SOUND_VOLUME",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"SOUND_RESTORE",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, "not%-authorized", 1) ~= nil):toBe(true)
		end)
	end)
end
