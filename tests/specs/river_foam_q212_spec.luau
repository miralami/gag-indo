--!nocheck
-- WORK_QUEUE item 212: LUNE-ONLY pure-data contract for the RiverFoam line. The live measurement
-- (FOAM_LINE / PERF_BUDGET and both FAIL calibrations) is tools/studio/check_q212.luau; the main
-- session wires ModelMapRiverFoamQ212 into Greybox before that check can PASS. No Studio verdict here.

local fs = require("@lune/fs")

local DATA = "src/shared/ModelMapRiverFoamQ212.luau"
local CHECK = "tools/studio/check_q212.luau"
local MAPSPEC = "src/server/World/MapSpec.luau"
local PROPS = "src/server/World/Props.luau"

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local dataSrc = fs.readFile(DATA)
	local checkSrc = fs.readFile(CHECK)
	local mapSpecSrc = fs.readFile(MAPSPEC)
	local propsSrc = fs.readFile(PROPS)

	local env = Env.new()
	local Data = env:require("shared/ModelMapRiverFoamQ212")
	local RiverR8 = env:require("shared/ModelMapRiverR8")
	local MapSpec = env:require("server/World/MapSpec")
	local parts = Data.parts()

	t:describe("item 212 river bank foam", function()
		t:it("publishes the RiverFoam contract and mirrors MapSpec river geometry", function()
			expect(Data.TAG):toBe("RiverFoam")
			expect(Data.KIND_ATTR):toBe("RiverFoamKind")
			expect(Data.KIND):toBe("foam")
			expect(Data.MIN_COVERAGE):toBe(0.60)
			expect(Data.PERF_BUDGET):toBe(120)
			expect(Data.TERRAIN_HALF):toBe(MapSpec.TERRAIN_HALF)
			expect(Data.RIVER_SEGMENT):toBe(16)
			expect(Data.WATER_HALF):toBe(14)
			expect(Data.FOAM_INSET * 2):toBe(Data.FOAM_WIDTH)
			expect(dataSrc:find("ModelMapRiverR8", 1, true) ~= nil):toBe(true)
			expect(mapSpecSrc:find("local RIVER_HALF = 14", 1, true) ~= nil):toBe(true)
			expect(mapSpecSrc:find("local RIVER_SEGMENT = 16", 1, true) ~= nil):toBe(true)
			expect(mapSpecSrc:find("function MapSpec.riverCentreZ", 1, true) ~= nil):toBe(true)
			for _, x in ipairs({ -400, -37, 0, 123, 400 }) do
				expect(Data.riverCentreZ(x)):toBe(MapSpec.riverCentreZ(x))
			end
		end)

		t:it("lays one thin, clearly named Block per segment on each bank", function()
			expect(#parts):toBe(100)
			local perBank = { south = 0, north = 0 }
			for _, part in ipairs(parts) do
				perBank[part.Side] += 1
				expect(part.shape):toBe("Block")
				expect(part.shape == "Ball"):toBe(false)
				expect(part.kind):toBe(Data.KIND)
				expect(string.find(part.name, "RiverFoam", 1, true)):toBe(1)
				expect(part.size[1]):toBe(16)
				expect(part.size[2] <= 0.1):toBe(true)
				expect(part.size[3] <= 1):toBe(true)
				expect(part.x >= -Data.TERRAIN_HALF and part.x <= Data.TERRAIN_HALF):toBe(true)
				expect(part.y >= RiverR8.WATER_SURFACE_Y):toBe(true)
				expect(part.y <= RiverR8.WATER_SURFACE_Y + Data.FOAM_SURFACE_EPSILON):toBe(true)
				expect(part.transparency > 0 and part.transparency < 1):toBe(true)
				expect(propsSrc:find(part.colour .. " = Color3.fromHex", 1, true) ~= nil):toBe(true)
				local _, _, lo, hi = 0, 0, 0, 0
				-- Segment z union is deterministic: re-derive the expected edge from MapSpec itself.
				local x0 = math.floor((part.x + Data.TERRAIN_HALF) / Data.RIVER_SEGMENT) * Data.RIVER_SEGMENT
					- Data.TERRAIN_HALF
				local zA, zB = MapSpec.riverCentreZ(x0), MapSpec.riverCentreZ(x0 + Data.RIVER_SEGMENT)
				lo, hi = math.min(zA, zB), math.max(zA, zB)
				local edge = if part.Side == "south" then lo - Data.WATER_HALF else hi + Data.WATER_HALF
				expect(math.abs(math.abs(part.z - edge) - Data.FOAM_INSET) < 1e-9):toBe(true)
			end
			expect(perBank.south):toBe(50)
			expect(perBank.north):toBe(50)
		end)

		t:it("samples both banks and fails when a subset is hidden", function()
			local descriptors = {}
			for _, part in ipairs(parts) do
				descriptors[#descriptors + 1] = { x = part.x, z = part.z }
			end
			local fraction, covered, total = Data.coverage(descriptors)
			expect(total):toBe(402)
			expect(covered):toBe(total)
			expect(fraction):toBe(1)
			expect(fraction >= Data.MIN_COVERAGE):toBe(true)

			local reduced = {}
			for index, piece in ipairs(descriptors) do
				if index % 2 == 1 then
					reduced[#reduced + 1] = piece
				end
			end
			local calFraction, calCovered = Data.coverage(reduced)
			expect(calCovered < covered):toBe(true)
			expect(calFraction < Data.MIN_COVERAGE):toBe(true)
			local empty = Data.coverage({})
			expect(empty):toBe(0)
		end)

		t:it("stays deterministic, pure and load-time asserted", function()
			local fresh = Env.new():require("shared/ModelMapRiverFoamQ212")
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(fresh.TAG):toBe(Data.TAG)
			expect(fresh.PERF_BUDGET):toBe(Data.PERF_BUDGET)
			expect(dataSrc:find("assert(", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("Instance.new", 1, true) == nil):toBe(true)
			for _, banned in ipairs({ "ProximityPrompt", "ClickDetector", "rbxassetid", "assetId", "Color3.fromHex" }) do
				expect(dataSrc:find(banned, 1, true) == nil):toBe(true)
			end
		end)

		t:it("keeps the Studio check read-only apart from reversible calibrations", function()
			for _, token in ipairs({
				'"FOAM_LINE"',
				'"PERF_BUDGET"',
				'"CAL_FOAM_LINE_FAIL"',
				'"CAL_PERF_BUDGET_FAIL"',
				"0.60",
				"ModelMapRiverFoamQ212",
				"wire src/shared/ModelMapRiverFoamQ212.luau into",
				"SetAttribute(Foam.TAG, true)",
				"Transparency = 1",
				"Destroy()",
				"GetDescendants()",
				"coverage(",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("LookDevReview", 1, true) == nil):toBe(true)
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
		end)

		t:it("item 271 centres foam on the water and ships a reversible SERVER-VM harness", function()
			local q271 = fs.readFile("tools/studio/check_q271.luau")
			expect(Data.FOAM_Y):toBe(RiverR8.WATER_SURFACE_Y)
			expect(Data.FOAM_SURFACE_EPSILON):toBe(0.05)
			expect(Data.MODEL_ID):toBe(13286158859)
			for _, token in ipairs({
				'"FOAM_ON_WATER_"',
				'"CAL_FOAM_FLOAT_271"',
				'"SUMMARY_Q271"',
				"liveWaterTop",
				"restoreAll()",
				"LookDevReview",
				'"LOOKDEV_LEAK_Q271"',
			}) do
				expect(q271:find(token, 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
