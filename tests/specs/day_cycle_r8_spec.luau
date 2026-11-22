--!nocheck
-- WORK_QUEUE section M item 89: day_cycle_r8 tune. Pure shared-model checks run for real under
-- Lune; LookDev wiring, applier source, harness source and doc guards are static. No Studio claim,
-- no CHECK evidence, no visual verdict: those belong to the main session and the designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapDayCycleR8")
	local DayCycle = env:require("shared/World/DayCycle")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapDayCycleR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevDayCycleR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local docSrc = fs.readFile("docs/v2/visual/DAY_CYCLE.md")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local function samePhase(a, b)
		if type(a) ~= "table" or type(b) ~= "table" then
			return false
		end
		for key, value in pairs(a) do
			if type(value) == "table" and type(value.R) == "number" then
				if type(b[key]) ~= "table" or b[key].R ~= value.R or b[key].G ~= value.G or b[key].B ~= value.B then
					return false
				end
			elseif b[key] ~= value then
				return false
			end
		end
		for key in pairs(b) do
			if a[key] == nil then
				return false
			end
		end
		return true
	end

	t:describe("day_cycle_r8 pure model", function()
		t:it("exports the tuned table beside the untouched base table", function()
			expect(Data.id):toBe("day_cycle_r8")
			expect(Data.BASE_PHASES == DayCycle.PHASES):toBe(true)
			expect(#Data.PHASES):toBe(#Data.BASE_PHASES)
			expect(Data.PHASE_JUMP_FACTOR):toBe(1.25)
			expect(Data.BASE_SHADOW_SOFTNESS):toBe(0.3)
			expect(Data.TUNED_SHADOW_SOFTNESS):toBe(0.45)
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
		end)

		t:it("computes Rec.709 luminance on 0-255 channels", function()
			-- Color3.fromRGB is normalized in both Roblox and the Lune test double.
			local white = env.globals.Color3.fromRGB(255, 255, 255)
			expect(math.abs(Data.luminance(white) - 255) < 1e-9):toBe(true)
			local grey = env.globals.Color3.fromRGB(100, 100, 100)
			expect(math.abs(Data.luminance(grey) - 100) < 1e-9):toBe(true)
			local top = env.globals.Color3.fromRGB(255, 206, 132)
			expect(math.abs(Data.luminance(top) - 211.074) < 0.01):toBe(true)
			-- Literal byte triples are accepted too.
			expect(math.abs(Data.luminance({ r = 255, g = 206, b = 132 }) - 211.074) < 0.01):toBe(true)
			expect(Data.luminance(nil)):toBe(0)
		end)

		t:it("raises the 16:00 sun-vs-ambient ratio by at least 20 percent", function()
			local base = Data.contrastAt1600(Data.BASE_PHASES)
			local tuned = Data.contrastAt1600(Data.PHASES)
			expect(math.abs(base - 2.160825) < 0.001):toBe(true)
			expect(math.abs(tuned - 2.705297) < 0.001):toBe(true)
			expect(tuned >= 1.2 * base):toBe(true)
			expect(Data.contrastRatio(nil)):toBe(0)
		end)

		t:it("stays under the documented 1.25x adjacent-jump limit", function()
			local baseJump = Data.adjacentJumps(Data.BASE_PHASES)
			local tunedJump = Data.adjacentJumps(Data.PHASES)
			expect(math.abs(baseJump - 0.623529) < 0.001):toBe(true)
			expect(math.abs(Data.documentedLimit - 1.25 * baseJump) < 1e-9):toBe(true)
			expect(tunedJump <= Data.documentedLimit):toBe(true)
			expect(Data.maxAdjacentJump(Data.PHASES)):toBe(tunedJump)
		end)

		t:it("duck-types Color3 channels so real Roblox userdata is not skipped", function()
			-- In Studio a real Color3 is userdata (type() ~= "table"); the old type() guards made
			-- both checks vacuous (0 >= 0). Lock the fix: channels are read via a pcall helper and
			-- there is no more `type(rgb) ~= "table"` / `type(a) == "table"` colour gate.
			expect(string.find(dataSrc, "colorChannels", 1, true) ~= nil):toBe(true)
			expect(string.find(dataSrc, "pcall%(function%(%)", 1) ~= nil):toBe(true)
			expect(string.find(dataSrc, 'type%(rgb%) ~= "table"', 1) == nil):toBe(true)
			-- The old colour gate lived inside adjacentJumps; type() checks legitimately remain in
			-- the maghrib deep-compare below it, so scope the assertion to the adjacentJumps body.
			local adjStart = string.find(dataSrc, "function ModelMapDayCycleR8.adjacentJumps", 1, true)
			local adjEnd = string.find(dataSrc, "local function sameValue", 1, true)
			expect(adjStart ~= nil and adjEnd ~= nil and adjStart < adjEnd):toBe(true)
			expect(string.find(dataSrc:sub(adjStart, adjEnd), 'type%(a%) == "table"', 1) == nil):toBe(true)
			-- A non-table channel provider (the userdata shape) must still yield a real luminance.
			local fakeUserdata = setmetatable({}, {
				__index = function(_, key)
					if key == "R" then
						return 1
					elseif key == "G" then
						return 206 / 255
					elseif key == "B" then
						return 132 / 255
					end
				end,
			})
			expect(math.abs(Data.luminance(fakeUserdata) - 211.074) < 0.01):toBe(true)
		end)

		t:it("leaves Maghrib and every other non-Sore phase byte-identical", function()
			expect(Data.maghribUnchanged()):toBe(true)
			expect(#Data.maghribChanges()):toBe(0)
			local changed = 0
			for index, base in ipairs(Data.BASE_PHASES) do
				if samePhase(base, Data.PHASES[index]) then
					expect(base.id ~= "sore"):toBe(true)
				else
					changed += 1
					expect(base.id):toBe("sore")
				end
			end
			expect(changed):toBe(1)
		end)

		t:it("keeps the spawn grade smooth with a lower sun and softer shadows", function()
			local base = DayCycle.presetFor(0, nil, "Rendah")
			local tuned = Data.presetFor(0, nil, "Rendah")
			expect(tuned.phaseId):toBe("sore")
			expect(tuned.clockTime):toBe(base.clockTime - 0.75)
			expect(tuned.shadowSoftness):toBe(0.45)
			expect(tuned.ambient.R < base.ambient.R):toBe(true)
			expect(tuned.colorShiftTop.G < base.colorShiftTop.G):toBe(true)
			-- Mid-gap alpha still produces a finite eased grade, never a snap to raw values.
			local mid =
				Data.presetFor((17.5 - DayCycle.START_CLOCK) * DayCycle.SECONDS_PER_GAME_HOUR + 1, nil, "Rendah")
			expect(mid.shadowSoftness >= 0.3 and mid.shadowSoftness <= 0.45):toBe(true)
			expect(mid.colorShiftTop.R > 0 and mid.colorShiftTop.R <= 1):toBe(true)
		end)
	end)

	t:describe("day_cycle_r8 wiring", function()
		t:it("ships candidate 74 with a client review path", function()
			expect(#LookDev.IDS):toBe(117)
			expect(LookDev.IDS[74]):toBe("day_cycle_r8")
			local candidate = LookDev.candidates.day_cycle_r8
			expect(candidate.id):toBe("day_cycle_r8")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapDayCycleR8")
			expect(candidate.shadowSoftness):toBe(0.45)
			local plan = LookDev.plan("day_cycle_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("day_cycle_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapDayCycleR8")
			expect(plan.shadowSoftness):toBe(0.45)
			local entry = Review.paths.day_cycle_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("client")
			expect(entry.path):toEqual({ "World", "LookDevDayCycleR8" })
		end)

		t:it("applies tuned values with a 20-40 s tween and an exact ShadowSoftness restore", function()
			expect(string.find(applierSrc, "require%(Shared%.ModelMapDayCycleR8%)") ~= nil):toBe(true)
			expect(string.find(applierSrc, "ShadowSoftness = preset.shadowSoftness", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "saveProp%(target, prop%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "entry.target[entry.prop] = entry.value", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "TweenService:Create", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "tweenInfo%(seconds%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "DayCycleLive.tweenSeconds(elapsed)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, 'LookDev.register("day_cycle_r8"', 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LookDevDayCycleR8.restore = restore", 1, true) ~= nil):toBe(true)
		end)

		t:it("adds three pure harness checks before the mutating LOOKDEV_LEAK", function()
			local a = harnessSrc:find('"DAY_PHASES_MONOTONIC",', 1, true)
			local b = harnessSrc:find('"DAY_1600_CONTRAST",', 1, true)
			local c = harnessSrc:find('"DAY_MAGHRIB_UNCHANGED",', 1, true)
			local leak = harnessSrc:find('"LOOKDEV_LEAK",', 1, true)
			expect(a ~= nil and b ~= nil and c ~= nil and leak ~= nil):toBe(true)
			expect(a < b and b < c and c < leak):toBe(true)
			expect(harnessSrc:find("-- 12f. Item 89", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require%(game%.ReplicatedStorage%.Shared%.ModelMapDayCycleR8%)", 1) ~= nil):toBe(
				true
			)
			-- Non-vacuity guards: both checks must FAIL when the base measurement is 0, so an
			-- unreadable-Color3 environment can never emit a vacuous 0 >= 0 / 0 <= limit PASS.
			expect(harnessSrc:find("baseRatio > 0", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("baseJump > 0", 1, true) ~= nil):toBe(true)
			for _, name in ipairs({ "DAY_PHASES_MONOTONIC", "DAY_1600_CONTRAST", "DAY_MAGHRIB_UNCHANGED" }) do
				local count = 0
				local at = 1
				while true do
					local found = harnessSrc:find('"' .. name .. '"', at, true)
					if not found then
						break
					end
					count += 1
					at = found + 1
				end
				expect(count >= 2):toBe(true) -- ORDER plus emit, never a skipped line
			end
		end)

		t:it("documents the limits and lists a pending candidate row", function()
			expect(string.find(docSrc, "Documented numeric limits %(item 89%)", 1) ~= nil):toBe(true)
			expect(string.find(docSrc, "0.2126", 1, true) ~= nil):toBe(true)
			expect(string.find(docSrc, "1.25", 1, true) ~= nil):toBe(true)
			expect(string.find(docSrc, "ShadowSoftness", 1, true) ~= nil):toBe(true)
			expect(string.find(gallerySrc, "`day_cycle_r8`", 1, true) ~= nil):toBe(true)
			expect(string.find(gallerySrc, 'LookDev.enable("day_cycle_r8")', 1, true) ~= nil):toBe(true)
		end)
	end)
end
