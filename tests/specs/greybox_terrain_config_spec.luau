--!nocheck
local fs = require("@lune/fs")

return function(t)
	local expect = t.expect

	t:describe("GreyboxTerrainConfig", function()
		t:it("exposes GRASS_DECORATION as a boolean defaulting to false", function()
			local src = fs.readFile("src/shared/GreyboxTerrainConfig.luau")
			expect(string.find(src, "GRASS_DECORATION = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("is wired into Greybox.applyTerrain", function()
			local src = fs.readFile("src/server/World/Greybox.luau")
			expect(string.find(src, "GreyboxTerrainConfig.GRASS_DECORATION", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "GreyboxTerrainConfig = require", 1, true) ~= nil):toBe(true)
		end)
	end)
end
