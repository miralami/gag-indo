--!nocheck
-- WORK_QUEUE section P item 173: every facades_r8 ridge cap must sit on a REAL Greybox RoofRidge.
-- Pure-data spec (Lune, no Studio): centres are rebuilt from MapSpec plus the two Greybox constants
-- that position the ridge trim, then compared with the staged recipe centres in world space.
-- This spec is deliberately NOT registered in tests/run.luau; main session registers it.

local HUB_KEYS = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }
local TRIM_LIFT = 0.55 -- Greybox hubTrim: ROOF_THICK / 2 + 0.25
local PAKRT_PLINTHTOP = 0.5 + 0.8 -- MapSpec.GROUND_Y + Greybox.PLINTH_HEIGHT
local PAKRT_RIDGES = {
	{ lx = -13, lz = -3, y = PAKRT_PLINTHTOP + 22 + 9 }, -- Greybox buildPakRt block A
	{ lx = 10, lz = -4, y = PAKRT_PLINTHTOP + 15 + 7 }, -- Greybox buildPakRt block B
}
local TOLERANCE = 0.5

local function distance(a, b, c)
	return math.sqrt(a * a + b * b + c * c)
end

return function(t, Env)
	local expect = t.expect
	local Data = Env.new():require("shared/ModelMapFacadesR8")
	local MapSpec = Env.new():require("server/World/MapSpec")

	-- World centre of each RoofRidge of a hub, derived from the same local numbers Greybox uses.
	local function ridgesFor(key)
		local hub = MapSpec.hub(key)
		if key == "pakrt" then
			local ridges = {}
			for _, ridge in ipairs(PAKRT_RIDGES) do
				local x, z = MapSpec.hubPoint(hub, ridge.lx, ridge.lz)
				ridges[#ridges + 1] = { x = x, y = ridge.y + TRIM_LIFT, z = z }
			end
			return ridges
		end
		return { { x = hub.x, y = hub.ridge + TRIM_LIFT, z = hub.z } }
	end

	local function capsFor(key)
		local caps = {}
		for _, recipe in ipairs(Data.hubs[key].parts) do
			if recipe.kind == "ridge_cap" then
				caps[#caps + 1] = recipe
			end
		end
		return caps
	end

	t:describe("facades_r8 ridge caps sit on real ridges (item 173)", function()
		t:it("places one ridge-aligned cap on each RoofRidge of every hub", function()
			for _, key in ipairs(HUB_KEYS) do
				local hub = MapSpec.hub(key)
				local ridges = ridgesFor(key)
				local caps = capsFor(key)
				expect(#caps):toBe(#ridges)
				local used = {}
				for _, recipe in ipairs(caps) do
					-- Pakrt's two roofs use a roofHub yawed +90 (Greybox buildPakRt), so its
					-- ridges run local Z in the hub frame; every other hub's ridge runs local X.
					if key == "pakrt" then
						expect(recipe.size[3] > recipe.size[1]):toBe(true)
					else
						expect(recipe.size[1] > recipe.size[3]):toBe(true)
					end
					expect(recipe.size[2] <= 1):toBe(true)
					local cx, cz = MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
					local cy = MapSpec.GROUND_Y + recipe.y
					local matched = nil
					for index, ridge in ipairs(ridges) do
						local gap = distance(cx - ridge.x, cy - ridge.y, cz - ridge.z)
						if not used[index] and gap <= TOLERANCE then
							matched = index
							break
						end
					end
					expect(matched ~= nil):toBe(true)
					if matched then
						used[matched] = true
					end
				end
			end
		end)

		t:it("gives pakrt exactly two caps, one per real ridge", function()
			expect(#capsFor("pakrt")):toBe(2)
		end)
	end)
end
