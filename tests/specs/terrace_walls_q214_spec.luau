--!nocheck
-- Item 214 data/source guard: the DEFAULT look stages one 25-stud stone retaining wall per
-- MapSpec.TERRACES entry, sitting on the lower terrace surface and clear of ramps/stairs, using
-- only rocks_r9's approved asset IDs. Live tagged-part measurement stays in tools/studio/check_q214.

local fs = require("@lune/fs")

local DATA = "src/shared/ModelMapTerraceWallsQ214.luau"
local ROCKS = "src/shared/ModelMapRocksR9.luau"
local CHECK = "tools/studio/check_q214.luau"

return function(t, Env)
	local expect = t.expect
	local dataSrc = fs.readFile(DATA)
	local checkSrc = fs.readFile(CHECK)
	local rocksSrc = fs.readFile(ROCKS)

	local env = Env.new()
	local Data = env:require("shared/ModelMapTerraceWallsQ214")
	local Rocks = env:require("shared/ModelMapRocksR9")
	local MapSpec = env:require("server/World/MapSpec")
	local parts = Data.parts(MapSpec)

	t:describe("item 214 terrace retaining walls", function()
		t:it("derives one 25-stud wall per MapSpec terrace", function()
			expect(Data.TAG):toBe("TerraceWall")
			expect(Data.MIN_WALLS):toBe(4)
			expect(Data.WALL_LENGTH):toBe(25)
			expect(#MapSpec.TERRACES):toBe(4)
			expect(#parts):toBe(#MapSpec.TERRACES)
			expect(#parts >= Data.MIN_WALLS):toBe(true)

			for index, def in ipairs(parts) do
				local terrace = MapSpec.TERRACES[index]
				local lower = if index == 1 then MapSpec.GROUND_Y else MapSpec.TERRACES[index - 1].top
				expect(def.terrace):toBe(index)
				expect(def.sx):toBe(25)
				expect(def.sy):toBe(terrace.top - lower)
				expect(def.sz):toBe(Data.WALL_DEPTH)
				expect(def.y - def.sy / 2):toBeNear(lower, 1e-9)
				expect(def.y + def.sy / 2):toBeNear(terrace.top, 1e-9)
				-- North face flush to the terrace's south face; the whole wall sits in front of it.
				expect(def.z - def.sz / 2):toBeNear(terrace.z1, 1e-9)
				expect(def.z + def.sz / 2):toBeLessThan(terrace.z1 + MapSpec.TERRAIN_VOXEL)
			end
		end)

		t:it("keeps walls inside their terrace lane and clear of ramps and stairs", function()
			for index, def in ipairs(parts) do
				local sides = MapSpec.TERRACE_SIDES
				local side = sides[((index - 1) % #sides) + 1]
				expect(def.x):toBeNear((side.x0 + side.x1) / 2, 1e-9)
				expect(def.x - def.sx / 2):toBeGreaterThan(side.x0)
				expect(def.x + def.sx / 2):toBeLessThan(side.x1)
				for _, stair in ipairs(MapSpec.STAIRS) do
					expect(math.abs(def.x - stair.x)):toBeGreaterThan((def.sx + stair.width) / 2)
				end
				for _, ramp in ipairs(MapSpec.RAMPS) do
					expect(math.abs(def.x - ramp.x)):toBeGreaterThan((def.sx + ramp.width) / 2)
				end
			end
		end)

		t:it("reuses rocks_r9 provenance and decorative staging flags only", function()
			local allowed = {}
			for _, id in ipairs(Rocks.ROCK_ASSET_IDS) do
				allowed[id] = true
			end
			for index, def in ipairs(parts) do
				expect(allowed[def.assetId]):toBe(true)
				expect(def.assetId):toBe(Rocks.assetIdFor(index))
				expect(def.shape):toBe("Block")
				expect(def.shape).never:toBe("Ball")
				expect(def.material):toBe("Rock")
				expect(def.colour):toBe("tintaLembut")
				expect(def.anchored):toBe(true)
				expect(def.canCollide):toBe(false)
				expect(def.interactive):toBe(false)
			end
			expect(dataSrc:find("%d%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(rocksSrc:find("16098456067", 1, true) ~= nil):toBe(true)
		end)

		t:it("is pure, deterministic and guarded at load time", function()
			for _, banned in ipairs({ "Instance.new", "Vector3.new", "Enum.", "ProximityPrompt", "ClickDetector", "rbxassetid" }) do
				expect(dataSrc:find(banned, 1, true) == nil):toBe(true)
			end
			expect(dataSrc:find("assert(", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find('Data.TAG = "TerraceWall"', 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("Rocks.assetIdFor", 1, true) ~= nil):toBe(true)

			local again = Data.parts(MapSpec)
			expect(#again):toBe(#parts)
			for index, def in ipairs(parts) do
				for key, value in pairs(def) do
					expect(again[index][key]):toBe(value)
				end
			end
			expect(function()
				Data.parts(nil)
			end):toThrow("MapSpec required")
		end)

		t:it("studio check keeps both targets and both FAIL calibrations", function()
			for _, token in ipairs({
				'"TERRACE_WALLS"',
				'"WALL_ON_TERRAIN"',
				'"CAL_TERRACE_WALLS_FAIL"',
				'"CAL_WALL_ON_TERRAIN_FAIL"',
				"TERRACE_WALLS = 4",
				"WALL_GAP_TOL = 0.3",
				"CAL_HIDE = 3",
				"CAL_LIFT = 2",
				"main session must wire ModelMapTerraceWallsQ214 into Greybox before this check PASSes",
				"attr(instance, \"TerraceWall\") == true",
				"FilterDescendantsInstances = { terrain }",
				"Vector3.new(0, -RAY_LENGTH, 0)",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("LookDevReview", 1, true) == nil):toBe(true)
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
		end)

		t:it("item 271 publishes three descending stone tiers per wall and a reversible harness", function()
			local q271 = fs.readFile("tools/studio/check_q271.luau")
			local steps = Data.stepParts(MapSpec)
			expect(Data.STEP_COUNT):toBe(3)
			expect(Data.STEP_DROP > 0):toBe(true)
			expect(#steps):toBe(#MapSpec.TERRACES * Data.STEP_COUNT)
			local allowed = {}
			for _, id in ipairs(Rocks.ROCK_ASSET_IDS) do
				allowed[id] = true
			end
			for wall = 1, #MapSpec.TERRACES do
				local previous = math.huge
				for tier = 1, Data.STEP_COUNT do
					local step = steps[(wall - 1) * Data.STEP_COUNT + tier]
					expect(step.terrace):toBe(wall)
					expect(step.tier):toBe(tier)
					expect(step.topY):toBeLessThan(previous)
					expect(allowed[step.assetId]):toBe(true)
					expect(step.canCollide):toBe(false)
					previous = step.topY
				end
			end
			for _, token in ipairs({
				'"TERRACE_STEPS_"',
				'"CAL_TERRACE_FLAT_271"',
				'"SUMMARY_Q271"',
				"terraceState",
				"restoreAll()",
				'"LOOKDEV_LEAK_Q271"',
			}) do
				expect(q271:find(token, 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
