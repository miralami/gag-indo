--!nocheck
-- Item 242 data-only guard. The default look owns a buried far-fill ring beyond the playable square
-- and the shipped Sky clamps Atmosphere.Haze to a reversible floor so the far edge fades into the
-- sky. Studio geometry measurement lives in tools/studio/check_q242.luau; this spec reads data and
-- source only, with no Instance creation and no Studio calls.

local fs = require("@lune/fs")

local LANDSCAPE = "src/server/World/Landscape.luau"
local SKY = "src/client/World/Sky.luau"
local CHECK = "tools/studio/check_q242.luau"

local function rectBounds(part)
	local x, _, z = part.position[1], part.position[2], part.position[3]
	local sx, _, sz = part.size[1], part.size[2], part.size[3]
	return x - sx / 2, x + sx / 2, z - sz / 2, z + sz / 2
end

local function outsideSquare(part, half)
	local x0, x1, z0, z1 = rectBounds(part)
	return x0 >= half or x1 <= -half or z0 >= half or z1 <= -half
end

local function outsidePerfProxy(part)
	local x0, x1, z0, z1 = rectBounds(part)
	local dx = if x0 > 0 then x0 elseif x1 < 0 then -x1 else 0
	local dz = if z0 > 0 then z0 elseif z1 < 0 then -z1 else 0
	return math.sqrt(dx * dx + dz * dz) > 100
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Landscape = env:require("server/World/Landscape")
	local SkyMapR6 = env:require("shared/SkyMapR6")
	local landscapeSrc = fs.readFile(LANDSCAPE)
	local skySrc = fs.readFile(SKY)
	local checkSrc = fs.readFile(CHECK)

	t:describe("item 242 horizon fill", function()
		t:it("owns a far-fill ring of buried parts outside the playable square and PERF proxy", function()
			local parts = Landscape.horizonFillParts()
			expect(#parts >= 4):toBe(true)
			for _, part in ipairs(parts) do
				expect(type(part.name) == "string" and string.find(part.name, "Horizon", 1, true) ~= nil):toBe(true)
				expect(part.tag):toBe("HorizonFill")
				expect(part.size[2] <= 2):toBe(true)
				expect(part.size[1] <= 2048 and part.size[3] <= 2048):toBe(true)
				-- Top stays below the Terrain base slab: no walkable surface is added.
				expect(part.position[2] + part.size[2] / 2):toBeLessThan(Landscape.GROUND_Y - 4)
				expect(outsideSquare(part, Landscape.PLAYABLE_HALF)):toBe(true)
				expect(outsidePerfProxy(part)):toBe(true)
			end
		end)

		t:it("rebuilds the ring idempotently as non-collidable, queryable, shadowless parts", function()
			expect(landscapeSrc:find("Landscape.horizonFillParts()", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("FindFirstChild(FILL_FOLDER)", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("Destroy()", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("CastShadow = false", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("CanQuery = true", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("SetAttribute(descriptor.tag, true)", 1, true) ~= nil):toBe(true)
			expect(landscapeSrc:find("applyHorizonFill(terrain)", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps a reversible 1.6 haze floor and uses it in both Sky paths", function()
			expect(SkyMapR6.HORIZON_HAZE_FLOOR):toBe(1.6)
			expect(skySrc:find("local HORIZON_HAZE_FLOOR = SkyMapR6.HORIZON_HAZE_FLOOR", 1, true) ~= nil):toBe(true)
			expect(skySrc:find("math.max(SHIPPING_ATMOSPHERE.Haze, HORIZON_HAZE_FLOOR)", 1, true) ~= nil):toBe(true)
			expect(skySrc:find("math.max(preset.atmosphereHaze or 1, HORIZON_HAZE_FLOOR)", 1, true) ~= nil):toBe(true)
			-- The OFF candidate must keep its exact HAZE data; no candidate staging here.
			expect(env:require("shared/ModelMapHorizonFillR10").HAZE):toBe(2.0)
		end)

		t:it("keeps the SERVER-VM check at 90% of 192 rays and a calibrated FAIL anchor", function()
			expect(
				checkSrc:find('CHECK_NAMES = { "HORIZON_FILL", "PERF_BUDGET", "CAL_HORIZON_FILL_FAIL" }', 1, true)
					~= nil
			):toBe(true)
			expect(checkSrc:find("SAMPLES = 8", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("RAYS_PER_CAMERA = SAMPLES * SAMPLES", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("TOTAL_RAYS * 0.90", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("RAY_LENGTH = 5000", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("0.40 + 0.20", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("0.02 + 0.96", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("XZ radius 100", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("perf <= 500", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("fraction < HORIZON_FRACTION", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("RaycastFilterType.Exclude", 1, true) ~= nil):toBe(true)
		end)
	end)
end
