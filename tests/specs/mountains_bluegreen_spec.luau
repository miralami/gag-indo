--!nocheck
-- WORK_QUEUE items 243 + 251 + 260 data-only guard. Mountains must be layered blue-green rock
-- ridges at 300/450/600 studs, never a grey Ball, a Block or SmoothPlastic; the applier and
-- SERVER-VM checks must keep their exact targets. Studio measurement stays in check_q243.luau,
-- check_q251.luau and (for item 260) check_q260.luau.

local fs = require("@lune/fs")

local APPLIER = "src/server/World/LookDevMountainsR10.luau"
local CHECK = "tools/studio/check_q243.luau"
local CHECK_251 = "tools/studio/check_q251.luau"
local CHECK_260 = "tools/studio/check_q260.luau"

return function(t, Env)
	local expect = t.expect
	local Data = Env.new():require("shared/ModelMapMountainsR10")
	local applierSrc = fs.readFile(APPLIER)
	local checkSrc = fs.readFile(CHECK)
	local check251Src = fs.readFile(CHECK_251)
	local check260Src = fs.readFile(CHECK_260)

	t:describe("item 243 blue-green mountain silhouettes", function()
		t:it("exposes terrain ridge data: three bands, no part descriptors", function()
			expect(Data.id):toBe("mountains_r10")
			expect(#Data.BANDS):toBe(3)
			expect(#Data.shapes() > 100):toBe(true)
			expect(#Data.mountainParts()):toBe(0)
			expect(#Data.smokeParts()):toBe(0)
			for _, shape in ipairs(Data.shapes()) do
				expect(shape.kind == "Ball" or shape.kind == "Cylinder" or shape.kind == "Wedge"):toBe(true)
				expect(shape.kind ~= "Block"):toBe(true)
				local radial = math.sqrt(shape.x ^ 2 + shape.z ^ 2)
				expect(radial >= Data.MIN_RADIUS):toBe(true)
			end
		end)

		t:it("keeps the blue-green ladder: greener near band, bluer far band, bluish haze", function()
			expect(Data.BANDS[1].slope):toBe("LeafyGrass")
			expect(Data.BANDS[3].slope):toBe("Slate")
			expect(Data.ATMOSPHERE.color.b >= Data.ATMOSPHERE.color.r + 20):toBe(true)
		end)

		t:it("is terrain only: no Part, no Block, no SmoothPlastic in the applier", function()
			expect(applierSrc:find('.new("Part")', 1, true) == nil):toBe(true)
			expect(applierSrc:find("PartType", 1, true) == nil):toBe(true)
			expect(applierSrc:find("SmoothPlastic", 1, true) == nil):toBe(true)
			expect(applierSrc:find(":FillBall(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Material.Air", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps the exact four SERVER-VM targets and real calibration injections", function()
			expect(checkSrc:find('"SC243_MOUNTAINS"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('"MF243_MOUNTAIN_FAR"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('"NC243_NO_COLLISION"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('"NB243_NO_GREY_BALL"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("COVERAGE_TARGET = 0.10", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("FAR_LIMIT = 450", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('COVERAGE_CAMERA = "horizon_north"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("Enum.PartType.Ball", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("Color3.fromRGB(128, 128, 128)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("review.disableAll()", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps the exact item-251 SERVER-VM targets and non-vacuous FAIL anchors", function()
			for _, name in ipairs({
				"MOUNTAIN_DIST",
				"NO_BOX_MOUNTAIN",
				"SUBJECT_COVERAGE_251",
				"SC251_MAX",
				"MOUNTAIN_FAR",
				"NO_COLLISION",
				"CAL_MOUNTAIN_DIST_FAIL",
				"CAL_NO_BOX_MOUNTAIN_FAIL",
				"CAL_SUBJECT_COVERAGE_251_FAIL",
				"CAL_SC251_MAX_FAIL",
				"CAL_MOUNTAIN_FAR_FAIL",
				"CAL_NO_COLLISION_FAIL",
			}) do
				expect(check251Src:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(check251Src:find("MIN_DISTANCE = 250", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("MIN_COVERAGE = 0.10", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("MAX_COVERAGE = 0.6", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("FAR_LIMIT = 450", 1, true) ~= nil):toBe(true)
			expect(check251Src:find('COVERAGE_CAMERA = "horizon_north"', 1, true) ~= nil):toBe(true)
			expect(check251Src:find('COVERAGE_AWAY_CAMERA = "horizon_south"', 1, true) ~= nil):toBe(true)
			expect(check251Src:find("part.Shape == Enum.PartType.Block", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("aabbDistance(reference, part)", 1, true) ~= nil):toBe(true)
			-- horizon_south has no projected rects, so the FAIL anchor is the negation of PASS,
			-- matching item 240: away.ok == false is a valid FAIL demonstration.
			expect(check251Src:find("not (away.ok == true and awayFraction >= MIN_COVERAGE)", 1, true) ~= nil):toBe(
				true
			)
			expect(check251Src:find("coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA, nil, deps)", 1, true) ~= nil):toBe(
				true
			)
			expect(check251Src:find('SetAttribute("Mountain", true)', 1, true) ~= nil):toBe(true)
			expect(check251Src:find("CFrame.new(cameraPoint.x, cameraPoint.y, cameraPoint.z - 12)", 1, true) ~= nil):toBe(
				true
			)
			expect(check251Src:find("target.CanCollide = true", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(check251Src:find("destroyInjected()", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps the exact item-260 SERVER-VM targets and non-vacuous FAIL anchors", function()
			for _, name in ipairs({
				"FOOTHILLS",
				"RIDGE_LAYERS",
				"MOUNTAIN_DIST",
				"NO_BOX_MOUNTAIN",
				"CAL_RIDGE_LAYERS_FAIL",
				"CAL_NO_BOX_MOUNTAIN_FAIL",
			}) do
				expect(check260Src:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(check260Src:find("MIN_DISTANCE = 480", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("workspace.Terrain", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("Raycast(", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("Enum.PartType.Block", 1, true) ~= nil):toBe(true)
			expect(check260Src:find('SetAttribute("Mountain", true)', 1, true) ~= nil):toBe(true)
			expect(check260Src:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("destroyInjected()", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("SUMMARY_Q260", 1, true) ~= nil):toBe(true)
		end)
	end)
end
