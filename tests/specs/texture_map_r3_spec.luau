--!nocheck
-- WORK_QUEUE round 3 items 20/21: the real CC0 PBR ID map for the OFF-BY-DEFAULT
-- "textures_r3" LookDev candidate. No visual verdict and no Studio claim here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local TextureMapR3 = env:require("shared/TextureMapR3")

	t:describe("TextureMapR3 candidate IDs", function()
		t:it("has 27 unique real-ID-shaped values", function()
			local seen = {}
			local count = 0
			for key, id in TextureMapR3.ids do
				count += 1
				expect(type(key)):toBe("string")
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(27)
		end)

		t:it("maps nine variants to three existing maps each", function()
			expect(TextureMapR3.slotCount()):toBe(9)
			for slot, variant in TextureMapR3.variants do
				expect(type(slot)):toBe("string")
				expect(type(variant.name)):toBe("string")
				expect(type(variant.baseMaterial)):toBe("string")
				for _, key in ipairs({ variant.diff, variant.nor, variant.rough }) do
					expect(type(TextureMapR3.ids[key])):toBe("number")
				end
			end
		end)

		t:it("builds asset URLs only from recorded IDs", function()
			expect(TextureMapR3.assetUrl("cobblestone_floor_01_diff")):toBe(
				"rbxassetid://" .. tostring(TextureMapR3.ids.cobblestone_floor_01_diff)
			)
			expect(TextureMapR3.assetUrl("not_a_real_map")):toBe(nil)
		end)

		t:it("keeps a conservative part-name category map", function()
			expect(TextureMapR3.categorySlots.road):toBe("paving")
			expect(TextureMapR3.categorySlots.ground):toBe("tanah")
			expect(TextureMapR3.categorySlots.field):toBe("sawah")
			expect(TextureMapR3.categorySlots.pematang):toBe("pematang")
			expect(TextureMapR3.categorySlots.river):toBe("river_bank")
			expect(TextureMapR3.categorySlots.bamboo):toBe("bambu")
			expect(TextureMapR3.categorySlots.roof):toBe("genteng")
			expect(TextureMapR3.categorySlots.metal):toBe("seng")
			expect(TextureMapR3.categorySlots.wood):toBe("wood")
		end)

		t:it("records source, licence and author for every uploaded file", function()
			local manifest = fs.readFile("docs/v2/visual/art/textures_r3/upload_manifest.json")
			expect(#manifest > 1000):toBe(true)
			expect(manifest:find("polyhaven.com/a/", 1, true) ~= nil):toBe(true)
			expect(manifest:find('"licence": "CC0"', 1, true) ~= nil):toBe(true)
			expect(manifest:find('"upload_route": "ROBLOX_API_KEY"', 1, true) ~= nil):toBe(true)
		end)
	end)
end
