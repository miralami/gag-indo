--!nocheck
-- Designer-approved catalog outfits for npcs_r7 (2026-11-21): row A for every role,
-- batik B2 for Pak RT. Locks the exact real catalog IDs and that the applier puts
-- them on the HumanoidDescription instead of the drawn templates and built peci.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Map = env:require("shared/ModelMapNpcsR7")
	local applier = fs.readFile("src/server/World/LookDevModelsNpcsR7.luau")

	t:describe("npcs_r7 catalog outfits", function()
		t:it("gives every role the designer-picked catalog outfit", function()
			local c = Map.catalog
			expect(c.petani.shirt):toBe(109842878942326)
			expect(c.petani.pants):toBe(96146120958106)
			expect(c.petani.hats[1]):toBe(90801645168902)
			expect(c.petani_wanita.shirt):toBe(107918452722296)
			expect(c.petani_wanita.hats[1]):toBe(129076562650877)
			expect(c.pedagang.shirt):toBe(3604934784)
			expect(c.pak_rt.layeredShirt):toBe(18903905363)
			expect(c.pak_rt.hats[1]):toBe(73748899536912)
			expect(c.polisi.shirt):toBe(134524039208416)
			expect(c.polisi.pants):toBe(73000190682589)
			expect(c.polisi.hats[1]):toBe(122271821782451)
			for _, id in ipairs(Map.roleIds) do
				expect(Map.roles[id].catalog):toBe(c[id])
			end
		end)

		t:it("dresses rigs through HumanoidDescription and counts missing hats as failures", function()
			expect(applier:find("hd.Shirt = catalog.shirt", 1, true) ~= nil):toBe(true)
			expect(applier:find("hd:SetAccessories(accessories, true)", 1, true) ~= nil):toBe(true)
			expect(applier:find('"catalog hats attached "', 1, true) ~= nil):toBe(true)
		end)

		t:it("spaces villagers 6 studs apart", function()
			expect(Map.slots[2].x - Map.slots[1].x):toBe(6)
		end)
	end)
end
