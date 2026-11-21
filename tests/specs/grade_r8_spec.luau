--!nocheck
-- WORK_QUEUE section M item 91: grade_r8_a/b/c tropical colour grades. Pure-model checks run for
-- real under Lune; LookDev wiring, applier source, harness source and boot wiring are static guards.
-- Lune cannot drive Lighting here — no Studio claim, no CHECK evidence and no visual verdict.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapGradeR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapGradeR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevGradeR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")

	local function finite(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	local function rangeOk(range, value, scale)
		if type(range) ~= "table" or value == nil then
			return false
		end
		if type(value) == "table" then
			for _, channel in ipairs({ "r", "g", "b" }) do
				if not rangeOk(range[string.upper(channel)], value[channel], scale) then
					return false
				end
			end
			return true
		end
		if not finite(range.min) or not finite(range.max) or range.min > range.max or not finite(value) then
			return false
		end
		local scaled = value * (scale or 1)
		return scaled >= range.min and scaled <= range.max
	end

	local function signature(values)
		local parts = {}
		for _, className in ipairs(Data.TOUCHED_EFFECTS) do
			for _, prop in ipairs(Data.properties[className]) do
				local value = values[className][prop]
				if type(value) == "table" then
					parts[#parts + 1] = className .. "." .. prop .. "=" .. value.r .. "," .. value.g .. "," .. value.b
				else
					parts[#parts + 1] = className .. "." .. prop .. "=" .. tostring(value)
				end
			end
		end
		return table.concat(parts, "|")
	end

	t:describe("grade_r8 pure model", function()
		t:it("exports three ids and exactly four touchable effects, no depth-of-field", function()
			expect(Data.idPrefix):toBe("grade_r8_")
			expect(Data.order):toEqual({ "a", "b", "c" })
			expect(Data.NO_DOF):toBe(true)
			expect(Data.TOUCHED_EFFECTS):toEqual({
				"Atmosphere",
				"ColorCorrectionEffect",
				"BloomEffect",
				"SunRaysEffect",
			})
			for _, className in ipairs(Data.TOUCHED_EFFECTS) do
				expect(type(Data.properties[className])):toBe("table")
				expect(#Data.properties[className] > 0):toBe(true)
				for _, prop in ipairs(Data.properties[className]) do
					expect(string.find(string.lower(prop), "depth", 1, true) == nil):toBe(true)
				end
			end
			expect(string.find(dataSrc, "DepthOfField", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "game.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
		end)

		t:it("documents non-empty, ordered safe ranges for every tuned property", function()
			for _, className in ipairs(Data.TOUCHED_EFFECTS) do
				local effectRanges = Data.safeRanges[className]
				expect(type(effectRanges)):toBe("table")
				for _, prop in ipairs(Data.properties[className]) do
					expect(rangeOk(effectRanges[prop], 0, 1) or type(effectRanges[prop]) == "table"):toBe(true)
					local range = effectRanges[prop]
					if type(range) == "table" and finite(range.min) then
						expect(range.min <= range.max):toBe(true)
					else
						for _, channel in ipairs({ "R", "G", "B" }) do
							local channelRange = range[channel]
							expect(finite(channelRange.min) and channelRange.min <= channelRange.max):toBe(true)
						end
					end
				end
			end
			-- The sky_r6 baseline sits inside every range it touches.
			expect(rangeOk(Data.safeRanges.ColorCorrectionEffect.Saturation, 0.08, 1)):toBe(true)
			expect(rangeOk(Data.safeRanges.BloomEffect.Intensity, 0.12, 1)):toBe(true)
			expect(rangeOk(Data.safeRanges.SunRaysEffect.Spread, 0.35, 1)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Density, 0.3, 1)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Color, { r = 240, g = 236, b = 224 }, 1)):toBe(true)
		end)

		t:it("keeps all three distinct variants inside the documented ranges", function()
			local signatures = {}
			for _, key in ipairs(Data.order) do
				local variant = Data.variants[key]
				expect(variant.id):toBe(Data.idPrefix .. key)
				expect(type(variant.label)):toBe("string")
				local values = Data.valuesFor(key)
				expect(values ~= nil):toBe(true)
				expect(values):toEqual(variant.values)
				for _, className in ipairs(Data.TOUCHED_EFFECTS) do
					for _, prop in ipairs(Data.properties[className]) do
						local value = values[className][prop]
						-- Pure values already use their documented scale: bytes for Color/Decay,
						-- normalised for TintColor. The harness multiplies live Color3 channels by
						-- 255 for the byte pairs; the pure model must not scale them twice.
						expect(
							rangeOk(Data.safeRanges[className][prop], value, 1),
							variant.id .. "." .. className .. "." .. prop
						):toBe(true)
					end
				end
				local atmosphere = values.Atmosphere
				expect(atmosphere.Color.r >= atmosphere.Color.g and atmosphere.Color.g >= atmosphere.Color.b):toBe(true)
				expect(atmosphere.Decay.b >= atmosphere.Decay.g and atmosphere.Decay.g >= atmosphere.Decay.r):toBe(true)
				signatures[#signatures + 1] = signature(values)
			end
			expect(signatures[1] ~= signatures[2] and signatures[2] ~= signatures[3] and signatures[1] ~= signatures[3]):toBe(
				true
			)
			expect(Data.valuesFor("unknown")):toBe(nil)
		end)

		t:it("has the intended warm golden / fresh green / hazy humid identities", function()
			expect(Data.variants.a.label):toBe("warm golden")
			expect(Data.variants.b.label):toBe("fresh green")
			expect(Data.variants.c.label):toBe("hazy humid")
			expect(Data.variants.a.values.Atmosphere.Density < Data.variants.c.values.Atmosphere.Density):toBe(true)
			expect(
				Data.variants.b.values.ColorCorrectionEffect.Saturation
					> Data.variants.c.values.ColorCorrectionEffect.Saturation
			):toBe(true)
			expect(Data.variants.c.values.Atmosphere.Haze > Data.variants.a.values.Atmosphere.Haze):toBe(true)
		end)
	end)

	t:describe("grade_r8 wiring", function()
		t:it("ships three more candidates with SERVER review paths", function()
			expect(#LookDev.IDS):toBe(80)
			expect(LookDev.IDS[76]):toBe("grade_r8_a")
			expect(LookDev.IDS[77]):toBe("grade_r8_b")
			expect(LookDev.IDS[78]):toBe("grade_r8_c")
			for _, key in ipairs(Data.order) do
				local id = Data.idPrefix .. key
				local candidate = LookDev.candidates[id]
				expect(candidate.id):toBe(id)
				expect(candidate.status):toBe("candidate, awaiting designer yes")
				expect(candidate.idsSource):toBe("Shared.ModelMapGradeR8")
				expect(candidate.noDof):toBe(true)
				local plan = LookDev.plan(id)
				expect(plan ~= nil):toBe(true)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.ModelMapGradeR8")
				local entry = Review.paths[id]
				expect(entry ~= nil):toBe(true)
				expect(entry.datamodel):toBe("server")
				expect(entry.path):toEqual({ "World", "LookDevGradeR8" })
			end
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevGradeR8%)", 1) ~= nil):toBe(true)
		end)

		t:it("guards the applier source: reuse, save/restore, register loop, no forbidden writes", function()
			expect(string.find(applierSrc, "FindFirstChildOfClass%(className%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%.new%(className%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "local function saveProp", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "local function restore", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "LookDev%.register%(Data%.idPrefix .. key, applier%)", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Failures%.set", 1) ~= nil):toBe(true)
			expect(string.find(applierSrc, "pcall", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "DepthOfField", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "FarmService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "EconomyService", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "RaidCutscene", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "Lighting.ClockTime =", 1, true) == nil):toBe(true)
		end)

		t:it("adds three harness checks before LOOKDEV_LEAK in their own scope", function()
			local a = harnessSrc:find('"GRADE_SAFE",', 1, true)
			local b = harnessSrc:find('"GRADE_RESTORE",', 1, true)
			local c = harnessSrc:find('"GRADE_NO_DOF",', 1, true)
			local leak = harnessSrc:find('"LOOKDEV_LEAK",', 1, true)
			expect(a ~= nil and b ~= nil and c ~= nil and leak ~= nil):toBe(true)
			expect(a < b and b < c and c < leak):toBe(true)
			local block = harnessSrc:find("-- 12h. Item 91", 1, true)
			local leakEmit = harnessSrc:find("-- 13. LOOKDEV_LEAK:", 1, true)
			expect(block ~= nil and leakEmit ~= nil and block > leak and block < leakEmit):toBe(true)
			local body = harnessSrc:sub(block, leakEmit)
			expect(string.find(body, "\ndo\n", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "\nend\n\n", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "gradeMap.safeRanges", 1, true) ~= nil):toBe(true)
			-- The applier must be required by the harness itself: registration happens at module
			-- load, and a saved place's boot script may predate these candidates. Without this,
			-- enable() is a silent no-op and the safe-range check reads unchanged baseline values.
			expect(string.find(body, "ServerScriptService.Server.World.LookDevGradeR8", 1, true) ~= nil):toBe(true)
			expect(string.find(body, "DepthOfFieldEffect", 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"GRADE_SAFE",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"GRADE_RESTORE",', 1, true) ~= nil):toBe(true)
			expect(string.find(body, '"GRADE_NO_DOF",', 1, true) ~= nil):toBe(true)
		end)
	end)
end
