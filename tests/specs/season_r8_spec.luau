--!nocheck
-- WORK_QUEUE section N item 119: season_r8_hujan/kemarau/panen seasonal looks. Pure-model checks run
-- for real under Lune; LookDev/review wiring, applier source and the harness block are static guards.
-- SEASON_DISTINCT is the named form of the item's pairwise >=10% clause. No Studio claim: CHECK
-- evidence, tracker ticks and the visual verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapSeasonR8")
	local Seasons = env:require("shared/Config/Seasons")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local dataSrc = fs.readFile("src/shared/ModelMapSeasonR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevSeasonR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/client/Main.client.luau")
	local serverMainSrc = fs.readFile("src/server/Main.server.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local CHANNELS = { "r", "g", "b" }
	local UPPER = { "R", "G", "B" }
	local CLASSES = { "Lighting", "Atmosphere", "Clouds" }
	local KEYS = { "hujan", "kemarau", "panen" }
	local IDS = {
		season_r8_hujan = "season_r8_hujan",
		season_r8_kemarau = "season_r8_kemarau",
		season_r8_panen = "season_r8_panen",
	}

	local function finite(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	local function rangeOk(range, value, scale)
		if type(value) == "table" then
			for _, channel in ipairs(CHANNELS) do
				if not rangeOk(range and range[string.upper(channel)], value[channel], scale) then
					return false
				end
			end
			return true
		end
		if type(range) ~= "table" or not finite(range.min) or not finite(range.max) then
			return false
		end
		if range.min > range.max or not finite(value) then
			return false
		end
		local scaled = value * (scale or 1)
		return scaled >= range.min and scaled <= range.max
	end

	local function numbersFor(key)
		local out, values, tints = {}, Data.valuesFor(key), Data.tintsFor(key)
		for _, className in ipairs(CLASSES) do
			for _, prop in ipairs(Data.properties[className]) do
				local value = values[className][prop]
				if type(value) == "table" then
					for _, channel in ipairs(CHANNELS) do
						out[#out + 1] = value[channel]
					end
				else
					out[#out + 1] = value
				end
			end
		end
		for _, selector in ipairs(Data.TINT_SELECTORS) do
			for _, channel in ipairs(CHANNELS) do
				out[#out + 1] = tints[selector.key][channel]
			end
		end
		return out
	end

	local function diffCount(a, b)
		local count = 0
		for index, left in ipairs(a) do
			local right = b[index]
			local scale = math.max(math.abs(left), math.abs(right), 0.001)
			if math.abs(left - right) / scale * 100 >= Data.DISTINCT_PCT then
				count += 1
			end
		end
		return count
	end

	t:describe("season_r8 pure model", function()
		t:it("exports three ids, a narrow touched set and pure Seasons ties", function()
			expect(Data.idPrefix):toBe("season_r8_")
			expect(Data.order):toEqual(KEYS)
			expect(Data.TOUCHED):toEqual({ "Lighting", "Atmosphere", "Clouds", "Decor" })
			expect(Data.seasonsTie.hujan):toBe("Config.Seasons.sky.hujan")
			expect(Data.seasonsTie.kemarau):toBe("Config.Seasons.sky.kemarau")
			expect(string.find(Data.seasonsTie.panen, "no panen musim", 1, true) ~= nil):toBe(true)
			expect(Seasons.sky.hujan ~= nil and Seasons.sky.kemarau ~= nil):toBe(true)
			expect(Seasons.sky.panen):toBe(nil)
			for _, className in ipairs(CLASSES) do
				expect(type(Data.properties[className])):toBe("table")
				expect(#Data.properties[className] > 0):toBe(true)
			end
			expect(Data.properties.Clouds):toEqual({ "Cover" })
			expect(Data.properties.Decor):toEqual({ "Color" })
		end)

		t:it("keeps the pure module free of engine APIs, asset IDs and long literals", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "assetId", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(string.find(dataSrc, "game%.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "require(", 1, true) == nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(LookDev.isBuiltinMaterial(Data.PUDDLE_MATERIAL)):toBe(true)
			expect(Data.PUDDLE_MATERIAL ~= "Painted" and Data.PUDDLE_MATERIAL ~= "Leaf"):toBe(true)
		end)

		t:it("defines objective season-safe bands coherent with the shipped Seasons sky", function()
			for _, className in ipairs(Data.TOUCHED) do
				expect(type(Data.safeRanges[className])):toBe("table")
				for _, prop in ipairs(Data.properties[className]) do
					local range = Data.safeRanges[className][prop]
					expect(type(range)):toBe("table")
					if range.min ~= nil then
						expect(finite(range.min) and finite(range.max) and range.min <= range.max):toBe(true)
					else
						for _, channel in ipairs(UPPER) do
							local channelRange = range[channel]
							expect(
								finite(channelRange.min)
									and finite(channelRange.max)
									and channelRange.min <= channelRange.max
							):toBe(true)
						end
					end
				end
			end
			-- Shipping Seasons presets sit below the grade_r8 density floor; the season band must
			-- include them without lifting the 0.35 upper bound.
			expect(Data.safeRanges.Atmosphere.Density.min):toBe(0.1)
			expect(Data.safeRanges.Atmosphere.Density.max):toBe(0.35)
			expect(rangeOk(Data.safeRanges.Atmosphere.Density, Seasons.sky.hujan.atmosphereDensity)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Density, Seasons.sky.kemarau.atmosphereDensity)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Density, Seasons.sky.pancaroba.atmosphereDensity)):toBe(true)
			expect(rangeOk(Data.safeRanges.Clouds.Cover, Seasons.sky.hujan.cloudCover)):toBe(true)
			expect(rangeOk(Data.safeRanges.Clouds.Cover, 0.4)):toBe(true)
			expect(rangeOk(Data.safeRanges.Clouds.Cover, 0.6)):toBe(true)
			expect(rangeOk(Data.safeRanges.Lighting.FogEnd, 40)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Haze, 0.4)):toBe(true)
			expect(rangeOk(Data.safeRanges.Atmosphere.Haze, 2.4)):toBe(true)
		end)

		t:it("keeps all three presets inside the bands with exact ids and tint palettes", function()
			for _, key in ipairs(KEYS) do
				local variant = Data.variants[key]
				expect(variant.id):toBe(Data.idPrefix .. key)
				expect(type(variant.label)):toBe("string")
				local values = Data.valuesFor(key)
				expect(values):toEqual(variant.values)
				for _, className in ipairs(CLASSES) do
					for _, prop in ipairs(Data.properties[className]) do
						expect(
							rangeOk(Data.safeRanges[className][prop], values[className][prop]),
							variant.id .. "." .. className .. "." .. prop
						):toBe(true)
					end
				end
				expect(values.Atmosphere.Color.r >= values.Atmosphere.Color.g):toBe(true)
				expect(values.Atmosphere.Color.g >= values.Atmosphere.Color.b):toBe(true)
				expect(values.Atmosphere.Decay.b >= values.Atmosphere.Decay.g):toBe(true)
				expect(values.Atmosphere.Decay.g >= values.Atmosphere.Decay.r):toBe(true)
				local tints = Data.tintsFor(key)
				expect(tints):toEqual(variant.tints)
				for _, selector in ipairs(Data.TINT_SELECTORS) do
					for _, channel in ipairs(CHANNELS) do
						expect(
							rangeOk(
								Data.safeRanges.Decor.Color[UPPER[table.find(CHANNELS, channel)]],
								tints[selector.key][channel]
							)
						):toBe(true)
					end
				end
			end
			expect(Data.valuesFor("unknown")):toBe(nil)
			expect(Data.tintsFor("unknown")):toBe(nil)
			expect(Data.puddlesFor("unknown")):toBe(0)
		end)

		t:it("gives each preset its own identity and hujan only the six puddle sheets", function()
			expect(Data.variants.hujan.label):toBe("wet rain look")
			expect(Data.variants.kemarau.label):toBe("dry season look")
			expect(Data.variants.panen.label):toBe("golden harvest look")
			expect(Data.puddlesFor("hujan")):toBe(6)
			expect(Data.puddlesFor("kemarau")):toBe(0)
			expect(Data.puddlesFor("panen")):toBe(0)
			expect(Data.PUDDLE_Y_FALLBACK):toBe(0.53)
			expect(#Data.PUDDLE_SHEETS):toBe(6)
			for _, sheet in ipairs(Data.PUDDLE_SHEETS) do
				expect(finite(sheet.x) and finite(sheet.z) and finite(sheet.sx) and finite(sheet.sz)):toBe(true)
			end
			expect(Data.variants.hujan.values.Clouds.Cover > Data.variants.kemarau.values.Clouds.Cover):toBe(true)
			expect(Data.variants.kemarau.values.Atmosphere.Haze > Data.variants.panen.values.Atmosphere.Haze):toBe(true)
			expect(Data.variants.panen.values.Lighting.Brightness > Data.variants.hujan.values.Lighting.Brightness):toBe(
				true
			)
		end)

		t:it("bounds the tint selectors to a small deterministic set of existing decor", function()
			expect(#Data.TINT_SELECTORS):toBe(3)
			expect(Data.TINT_SELECTORS[1].key):toBe("padi")
			expect(Data.TINT_SELECTORS[1].attribute):toBe("PadiPart")
			expect(Data.TINT_SELECTORS[1].max):toBe(24)
			expect(Data.TINT_SELECTORS[2].key):toBe("puddle")
			expect(Data.TINT_SELECTORS[2].namePrefix):toBe("puddle_")
			expect(Data.TINT_SELECTORS[2].max):toBe(12)
			expect(Data.TINT_SELECTORS[3].key):toBe("grass")
			expect(Data.TINT_SELECTORS[3].namePrefix):toBe("grass_tuft_")
			expect(Data.TINT_SELECTORS[3].max):toBe(24)
			local total = 0
			for _, selector in ipairs(Data.TINT_SELECTORS) do
				total += selector.max
			end
			expect(total):toBe(60)
		end)

		t:it("proves SEASON_DISTINCT: every pair differs in at least two values by >=10%", function()
			local counts = {}
			local lengths = {}
			for _, key in ipairs(KEYS) do
				lengths[#lengths + 1] = #numbersFor(key)
			end
			expect(lengths[1] == lengths[2] and lengths[2] == lengths[3]):toBe(true)
			for index = 1, #KEYS - 1 do
				for other = index + 1, #KEYS do
					local count = diffCount(numbersFor(KEYS[index]), numbersFor(KEYS[other]))
					counts[KEYS[index] .. "-" .. KEYS[other]] = count
					expect(count >= Data.DISTINCT_TARGET, KEYS[index] .. "-" .. KEYS[other]):toBe(true)
				end
			end
			local minimum = math.huge
			for _, count in pairs(counts) do
				if count < minimum then
					minimum = count
				end
			end
			expect(minimum >= Data.DISTINCT_TARGET):toBe(true)
			expect(Data.DISTINCT_PCT):toBe(10)
			expect(Data.DISTINCT_TARGET):toBe(2)
		end)
	end)

	t:describe("season_r8 LookDev wiring", function()
		t:it("ships candidates 91-93 with descriptors, keyed plans and client paths", function()
			expect(#LookDev.IDS):toBe(107)
			expect(LookDev.IDS[90]):toBe("crops_showcase_r8")
			expect(LookDev.IDS[91]):toBe("season_r8_hujan")
			expect(LookDev.IDS[92]):toBe("season_r8_kemarau")
			expect(LookDev.IDS[93]):toBe("season_r8_panen")
			for _, key in ipairs(KEYS) do
				local id = Data.idPrefix .. key
				local candidate = LookDev.candidates[id]
				expect(candidate.id):toBe(id)
				expect(candidate.style):toBe("cartoonish-realism")
				expect(candidate.status):toBe("candidate, awaiting designer yes")
				expect(candidate.idsSource):toBe("Shared.ModelMapSeasonR8")
				expect(candidate.seasonKey):toBe(key)
				expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
				local plan = LookDev.plan(id)
				expect(plan ~= nil):toBe(true)
				expect(plan.id):toBe(id)
				expect(plan.key):toBe(key)
				expect(plan.seasonKey):toBe(key)
				expect(plan.idsSource):toBe("Shared.ModelMapSeasonR8")
				local entry = Review.paths[id]
				expect(entry ~= nil):toBe(true)
				expect(entry.datamodel):toBe("client")
				expect(entry.path):toEqual({ "World", "LookDevSeasonR8" })
			end
			expect(string.find(mainSrc, "pcall%(require, script%.Parent%.World%.LookDevSeasonR8%)", 1) ~= nil):toBe(
				true
			)
			expect(string.find(serverMainSrc, "pcall%(require, script%.Parent%.World%.LookDevSeasonR8%)", 1) == nil):toBe(
				true
			)
		end)

		t:it("appends SEASON_SAFE/RESTORE/DISTINCT last in ORDER and emits on every path", function()
			expect(
				harnessSrc:find(
					'"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",\n\t"SEASON_SAFE",\n\t"SEASON_RESTORE",\n\t"SEASON_DISTINCT",\n\t"RAIN_EMITTERS",\n\t"RAIN_OFF_CERAH",\n\t"RAIN_COST",\n\t"DAWN_PHASES_MONOTONIC",\n\t"DAWN_SAFE",\n\t"LIGHT_COST",\n}',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("SEASON_SAFE", false, 0, 3,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("SEASON_RESTORE", false, 0, 3,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("SEASON_DISTINCT", false, 0, 2,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"SEASON_SAFE",\n\t\t#errors == 0', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"SEASON_RESTORE",\n\t\t#errors == 0', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"SEASON_DISTINCT",\n\t\t#errors == 0', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("look.enable(priorId, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-- 9t. WORK_QUEUE section N item 119: season_r8_*", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Players.LocalPlayer.PlayerScripts.Client.World.LookDevSeasonR8", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("game.PlayerScripts.Client.World.LookDevSeasonR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('seasonFailAll("client VM required")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("run:IsClient()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("task.wait(5)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ServerScriptService.Server.World.LookDevSeasonR8", 1, true) == nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapSeasonR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('FindFirstChildOfClass("Clouds")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("seasonMap.safeRanges", 1, true) ~= nil):toBe(true)
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
			expect(harnessSrc:find('emit("CROPS_STAGED", csPass, measured, 36,', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("season_r8 applier", function()
		t:it("resolves the plan key, saves/restores LIFO and stages only own puddles", function()
			expect(applierSrc:find("CLIENT-ONLY", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ModelMapSeasonR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("(Shared :: any).World", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ServerScriptService", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("script.Parent.MapSpec", 1, true) == nil):toBe(true)
			expect(applierSrc:find("PUDDLE_Y_FALLBACK", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("roadY = Data.PUDDLE_Y_FALLBACK", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.ROAD.y unavailable; puddle sheets not staged", 1, true) == nil):toBe(true)
			expect(applierSrc:find('"seasonKey", "key"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("string.sub(plan.id, #Data.idPrefix + 1)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.idPrefix .. key, applier)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("local function saveProp", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("for index = #savedOrder, 1, -1 do", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("local function restore", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('FindFirstChildOfClass("Clouds")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("savedFolder.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Failures.set", 1) ~= nil):toBe(true)
			for _, name in ipairs({ "appliedKey", "isApplied", "savedCount", "tintedParts" }) do
				expect(applierSrc:find("function LookDevSeasonR8." .. name, 1, true) ~= nil):toBe(true)
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
				"Lighting.ClockTime =",
				"ColorCorrectionEffect",
				"BloomEffect",
				"SunRaysEffect",
			}) do
				expect(applierSrc:find(forbidden, 1, true) == nil, forbidden):toBe(true)
			end
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("season_r8 gallery and count literals", function()
		t:it("records three pending six-column gallery rows", function()
			for _, key in ipairs(KEYS) do
				local id = Data.idPrefix .. key
				expect(gallerySrc:find("| `" .. id .. "` |", 1, true) ~= nil):toBe(true)
				expect(gallerySrc:find('LookDev.enable("' .. id .. '")', 1, true) ~= nil):toBe(true)
			end
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("SEASON_DISTINCT", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("Clouds.Cover may be overwritten by the client Sky tween", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("no DataStore/player/crop state", 1, true) ~= nil):toBe(true)
		end)

		t:it("bumped only the IDS-count mirrors to 107", function()
			for _, path in ipairs({
				"tests/specs/review_round3_bugfix_spec.luau",
				"tests/specs/terrain_map_r6_spec.luau",
				"tests/specs/sky_map_r6_spec.luau",
			}) do
				local src = fs.readFile(path)
				expect(src:find("expect(count):toBe(107)", 1, true) ~= nil, path):toBe(true)
			end
		end)
	end)
end
