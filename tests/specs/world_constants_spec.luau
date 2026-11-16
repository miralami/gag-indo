-- Single source of truth for world values (T1).
-- HEADROOM, SPAWN, GOLDEN_HOUR, SEASON_PRESETS live only in MapSpec.luau.
return function(t, Env)
	local expect = t.expect
	local env
	local fs = require("@lune/fs")

	local function readSource(rel)
		return fs.readFile("src/" .. rel)
	end

	local targets = {
		"server/World/Greybox.luau",
		"server/World/Landscape.luau",
		"server/World/Map.luau",
		"shared/Config/Seasons.luau",
		"client/World/Sky.luau",
		"server/Season/SeasonService.luau",
	}

	t:describe("world constants single source (T1)", function()
		t:beforeEach(function()
			env = Env.new()
		end)

		t:it("has HEADROOM, SPAWN, GOLDEN_HOUR, SEASON_PRESETS only in MapSpec", function()
			local MapSpec = env:require("server/World/MapSpec")
			expect(MapSpec.HEADROOM):toBe(9.5)
			expect(MapSpec.SPAWN.x):toBe(0)
			expect(MapSpec.SPAWN.z):toBe(28)
			expect(MapSpec.SPAWN.lookZ):toBe(-1)
			expect(MapSpec.GOLDEN_HOUR.minClock):toBe(16.0)
			expect(MapSpec.GOLDEN_HOUR.maxClock):toBe(17.0)
			expect(#MapSpec.SEASON_PRESETS):toBe(3)

			for _, rel in targets do
				local src = readSource(rel)
				-- no literal headroom value
				expect(string.find(src, "9%.5", 1) == nil):toBe(true)
				-- no literal spawn point 0,0.5,28 / lookZ -1 tuple patterns
				expect(string.find(src, "SPAWN = { x = 0", 1, true) == nil):toBe(true)
				-- no golden hour window literals as constants
				expect(string.find(src, "16%.0") == nil):toBe(true)
				expect(string.find(src, "17%.0") == nil):toBe(true)
				-- no season preset list literal
				expect(string.find(src, '"hujan", "kemarau", "pancaroba"', 1, true) == nil):toBe(true)
			end
		end)

		t:it("shared modules never reach into server code (client cannot see it)", function()
			for _, rel in { "shared/Config/Seasons.luau", "shared/Config/WorldConstants.luau" } do
				local src = readSource(rel)
				expect(string.find(src, "World.MapSpec", 1, true) == nil):toBe(true)
				expect(string.find(src, "ServerScriptService", 1, true) == nil):toBe(true)
				expect(string.find(src, "server/", 1, true) == nil):toBe(true)
			end
			local MapSpec = env:require("server/World/MapSpec")
			local WC = env:require("shared/Config/WorldConstants")
			expect(MapSpec.GOLDEN_HOUR == WC.GOLDEN_HOUR):toBe(true)
			expect(MapSpec.SEASON_PRESETS == WC.SEASON_PRESETS):toBe(true)
		end)
	end)
end
