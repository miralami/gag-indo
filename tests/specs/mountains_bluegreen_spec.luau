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
		t:it("exposes at least eight non-Ball silhouettes beyond the 250-stud spawn floor", function()
			expect(Data.id):toBe("mountains_r10")
			expect(#Data.MOUNTAINS >= 8):toBe(true)
			expect(#Data.mountainParts()):toBe(#Data.MOUNTAINS)
			for _, descriptor in ipairs(Data.MOUNTAINS) do
				expect(descriptor.shape == "Wedge" or descriptor.shape == "Cylinder"):toBe(true)
				expect(descriptor.shape ~= "Ball"):toBe(true)
				expect(descriptor.shape ~= "Block"):toBe(true)
				expect(descriptor.material == "Rock" or descriptor.material == "Slate"):toBe(true)
				local radius = math.sqrt(descriptor.position[1] ^ 2 + descriptor.position[3] ^ 2)
				expect(radius >= Data.MIN_DISTANCE):toBe(true)
			end
		end)

		t:it("exposes the exact item-260 ridge bands and skyline targets in pure data", function()
			expect(Data.MIN_DISTANCE):toBe(250)
			expect(#Data.RIDGE_BANDS):toBe(3)
			expect(Data.RIDGE_BANDS[1]):toBe(300)
			expect(Data.RIDGE_BANDS[2]):toBe(450)
			expect(Data.RIDGE_BANDS[3]):toBe(600)
			expect(Data.BAND_TOLERANCE):toBe(60)
			expect(Data.SKYLINE_MIN):toBe(0.15)
			expect(Data.SKYLINE_MAX):toBe(0.40)
			local seen = {}
			for _, descriptor in ipairs(Data.MOUNTAINS) do
				expect(descriptor.shape == "Block"):toBe(false)
				for _, band in ipairs(Data.RIDGE_BANDS) do
					if math.abs(math.abs(descriptor.position[3]) - band) <= Data.BAND_TOLERANCE then
						seen[band] = true
					end
				end
			end
			for _, band in ipairs(Data.RIDGE_BANDS) do
				expect(seen[band] == true):toBe(true)
			end
		end)

		t:it("keeps a blue-green spread on every staged descriptor", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					local colour = descriptor.color
					local spread = math.max(colour.r, colour.g, colour.b) - math.min(colour.r, colour.g, colour.b)
					expect(spread >= 18):toBe(true)
					expect(colour.b >= colour.r + 12):toBe(true)
					expect(colour.g >= colour.r + 12):toBe(true)
					expect(descriptor.shape ~= "Ball"):toBe(true)
				end
			end
			local smoke = Data.smokeParts()[1]
			expect(smoke.shape ~= "Ball"):toBe(true)
			expect(type(smoke.transparency) == "number" and smoke.transparency > 0):toBe(true)
		end)

		t:it("applies descriptor material with a pcall fallback and keeps stage/restore behaviour", function()
			expect(applierSrc:find('name ~= "Wedge" and name ~= "Cylinder"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("(Enum :: any).Material[name]", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pcall(function()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Material = material", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("Mountain", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("LookDevStage", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CastShadow = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance:Destroy()", 1, true) ~= nil):toBe(true)
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
				"MOUNTAIN_DISTANCE",
				"NO_BOX_MOUNTAIN",
				"RIDGE_LAYERS",
				"SKYLINE_COVER",
				"CAL_RIDGE_LAYERS_FAIL",
				"CAL_SKYLINE_COVER_FAIL",
			}) do
				expect(check260Src:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(check260Src:find("MIN_DISTANCE = 250", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("RIDGE_BANDS = { 300, 450, 600 }", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("BAND_TOLERANCE = 60", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("SKYLINE_MIN = 0.15", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("SKYLINE_MAX = 0.40", 1, true) ~= nil):toBe(true)
			expect(check260Src:find('SPAWN_CAMERA = "spawn"', 1, true) ~= nil):toBe(true)
			expect(check260Src:find("Cameras.get, SPAWN_CAMERA", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("Enum.RaycastFilterType.Include", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("part.Shape == Enum.PartType.Block", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("aabbDistance(eye, part)", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("measureSkyline({})", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("CFrame.new(0, 30, -750)", 1, true) ~= nil):toBe(true)
			expect(check260Src:find('SetAttribute("Mountain", true)', 1, true) ~= nil):toBe(true)
			expect(check260Src:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("destroyInjected()", 1, true) ~= nil):toBe(true)
			expect(check260Src:find("SUMMARY_Q260", 1, true) ~= nil):toBe(true)
		end)
	end)
end
