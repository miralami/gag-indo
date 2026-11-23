--!nocheck
-- WORK_QUEUE item 243 data-only guard. Mountains must be layered blue-green silhouettes, not a
-- grey Ball; the applier must honour descriptor material and the SERVER-VM check must keep the exact
-- SC243 / MF243 / NC243 / NB243 targets. Studio measurement stays in tools/studio/check_q243.luau.

local fs = require("@lune/fs")

local APPLIER = "src/server/World/LookDevMountainsR10.luau"
local CHECK = "tools/studio/check_q243.luau"

return function(t, Env)
	local expect = t.expect
	local Data = Env.new():require("shared/ModelMapMountainsR10")
	local applierSrc = fs.readFile(APPLIER)
	local checkSrc = fs.readFile(CHECK)

	t:describe("item 243 blue-green mountain silhouettes", function()
		t:it("exposes at least eight non-Ball silhouettes beyond the 450-stud far ring", function()
			expect(Data.id):toBe("mountains_r10")
			expect(#Data.MOUNTAINS >= 8):toBe(true)
			expect(#Data.mountainParts()):toBe(#Data.MOUNTAINS)
			for _, descriptor in ipairs(Data.MOUNTAINS) do
				expect(descriptor.shape == "Wedge" or descriptor.shape == "Cylinder"):toBe(true)
				expect(descriptor.shape ~= "Ball"):toBe(true)
				expect(type(descriptor.material) == "string" and #descriptor.material > 0):toBe(true)
				local radius = math.sqrt(descriptor.position[1] ^ 2 + descriptor.position[3] ^ 2)
				expect(radius >= 450):toBe(true)
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
	end)
end
