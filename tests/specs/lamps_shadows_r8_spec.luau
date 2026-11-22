--!nocheck
-- WORK_QUEUE section N item 122: lamps_shadows_r8, audit of the night-light cost across the
-- additive full_r9 review set (item 103). Source-level only: ORDER tail placement, emit on every
-- path, the exact 13-ID staging list, undeweakened thresholds/anti-vacuity, PointLight+SpotLight
-- coverage, and candidate lamp constants. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local LookDev = Env.new():require("shared/LookDev")
	local Smoke = Env.new():require("shared/ModelMapSmokeR8")
	local Night = Env.new():require("shared/ModelMapNightR8")
	local Subuh = Env.new():require("shared/ModelMapSubuhR8")

	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")

	-- Full ORDER tail: every earlier entry byte-identical, LIGHT_COST appended after DAWN_SAFE.
	local ORDER_TAIL =
		'"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",\n\t"SEASON_SAFE",\n\t"SEASON_RESTORE",\n\t"SEASON_DISTINCT",\n\t"RAIN_EMITTERS",\n\t"RAIN_OFF_CERAH",\n\t"RAIN_COST",\n\t"DAWN_PHASES_MONOTONIC",\n\t"DAWN_SAFE",\n\t"LIGHT_COST",\n}'

	local FULL_R9_IDS = {
		"hubveg_r8",
		"plots_r8",
		"sawah_r8",
		"river_r8",
		"pathedge_r8",
		"facades_r8",
		"hubprops_r8",
		"streetfurn_r8",
		"spanduk_r8",
		"animals_r8",
		"flyers_r8",
		"smoke_r8",
		"wind_r8",
	}
	local FULL_R9_FOLDERS = {
		"LookDevModelsVegetationHubR8_hubveg_r8",
		"LookDevPlotsR8_plots_r8",
		"LookDevSawahR8_sawah_r8",
		"LookDevRiverR8_river_r8",
		"LookDevPathEdgeR8_pathedge_r8",
		"LookDevFacadesR8_facades_r8",
		"LookDevHubPropsR8_hubprops_r8",
		"LookDevStreetFurnR8_streetfurn_r8",
		"LookDevSpandukR8_spanduk_r8",
		"LookDevAnimalsR8_animals_r8",
		"LookDevFlyersR8_flyers_r8",
		"LookDevSmokeR8_smoke_r8",
		"LookDevWindR8_wind_r8",
	}

	local function listLuau(dir: string): { string }
		local out = {}
		local function walk(d)
			for _, name in fs.readDir(d) do
				local p = d .. "/" .. name
				if fs.isDir(p) then
					walk(p)
				elseif string.sub(name, -5) == ".luau" then
					out[#out + 1] = p
				end
			end
		end
		walk(dir)
		table.sort(out)
		return out
	end
	local SRC_FILES = listLuau("src")

	t:describe("lamps_shadows_r8 harness audit", function()
		t:it("appends LIGHT_COST last in ORDER, earlier entries byte-identical", function()
			expect(harnessSrc:find(ORDER_TAIL, 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"DAWN_SAFE",\n\t"LIGHT_COST",\n}', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"DAWN_SAFE",\n\t"LIGHT_COST",\n\t"', 1, true) == nil):toBe(true)
		end)

		t:it("emits LIGHT_COST on setup-failure and pass paths", function()
			expect(
				harnessSrc:find('emit("LIGHT_COST", false, "ERR", "0 violations", { reason = reason })', 1, true) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("LIGHT_COST", passed, violations, "0 violations", {', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("-- 9w. WORK_QUEUE section N item 122: lamps_shadows_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("runLightCostChecks()", 1, true) ~= nil):toBe(true)
		end)

		t:it("stages the exact 13-ID full_r9 list in the SERVER VM", function()
			expect(#FULL_R9_IDS):toBe(13)
			expect(#FULL_R9_FOLDERS):toBe(13)
			for _, id in ipairs(FULL_R9_IDS) do
				expect(harnessSrc:find('{ id = "' .. id .. '", folder =', 1, true) ~= nil):toBe(true)
			end
			for _, folder in ipairs(FULL_R9_FOLDERS) do
				expect(harnessSrc:find('folder = "' .. folder .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(harnessSrc:find("run:IsServer()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Review.enableAdditive(entry.id, game, { studio = true })", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("Review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("look.enable(priorId, { studio = true })", 1, true) ~= nil):toBe(true)
		end)

		t:it("enumerates PointLight and SpotLight with undeweakened thresholds", function()
			expect(harnessSrc:find('instance:IsA("PointLight")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('instance:IsA("SpotLight")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("instance.Shadows", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("instance.Range", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("instance.Brightness", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("castsShadows == true", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("range > 30", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("brightness > 3", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("totalLights > 0", 1, true) ~= nil):toBe(true)
		end)

		t:it("adds no LookDev ID, count or CANDIDATES row beyond the 112 registered", function()
			expect(#LookDev.IDS):toBe(112)
			expect(LookDev.IDS[113]):toBe(nil)
		end)
	end)

	t:describe("lamps_shadows_r8 source lamp limits", function()
		t:it("no light constructor in src sets Shadows = true", function()
			for _, path in ipairs(SRC_FILES) do
				local src = fs.readFile(path)
				for line in string.gmatch(src, "[^\n]+") do
					local shadowTrue = string.find(line, "%.Shadows%s*=%s*true", 1) ~= nil
					local globalShadow = string.find(line, "GlobalShadows", 1, true) ~= nil
					expect(not (shadowTrue and not globalShadow)):toBe(true)
				end
			end
		end)

		t:it("candidate lamp Range/Brightness constants stay within limits", function()
			expect(Smoke.MAX_RANGE):toBe(30)
			expect(Smoke.LAMP_RANGE <= 30):toBe(true)
			expect(Night.LAMP_RANGE <= 30):toBe(true)
			expect(Night.GLOW_INTENSITY <= 3):toBe(true)
			expect(Subuh.LAMP.range <= 30):toBe(true)
			expect(Subuh.LAMP.brightnessMax <= 3):toBe(true)
			expect(Subuh.LAMP.shadows):toBe(false)
			expect(Subuh.safeRanges.Lamps.Shadows):toBe(false)
			expect(Subuh.safeRanges.Lamps.Range.max <= 30):toBe(true)
			expect(Subuh.safeRanges.Lamps.Brightness.max <= 3):toBe(true)
		end)
	end)
end
