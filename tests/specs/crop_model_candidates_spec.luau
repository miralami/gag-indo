--!nocheck
-- CropModelCandidates spec (WORK_QUEUE round 2 item 7): pure-data low-poly growth-stage recipes
-- for the off-by-default "crops" LookDev candidate. No asset IDs, no Roblox APIs at load.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local Recipes, Crops, Visuals

	t:describe("CropModelCandidates recipes", function()
		t:beforeEach(function()
			local env = Env.new()
			Recipes = env:require("shared/CropModelCandidates")
			Crops = env:require("shared/Config/Crops")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("covers all 12 config crops in all 3 growth stages", function()
			expect(#Recipes.cropIds):toBe(12)
			expect(#Recipes.stages):toBe(3)
			for _, id in Crops.order do
				expect(table.find(Recipes.cropIds, id) ~= nil):toBe(true)
				expect(Recipes.archetypes[id] ~= nil):toBe(true)
			end
			expect(Recipes.partsFor("not_a_crop", "siap")):toBe(nil)
			expect(Recipes.partsFor("padi", "not_a_stage")):toBe(nil)
		end)

		t:it("every crop/stage produces valid low-poly part descriptors", function()
			local shapes = { Block = true, Cylinder = true, Sphere = true, Wedge = true }
			local total = 0
			for _, cropId in Recipes.cropIds do
				for _, stage in Recipes.stages do
					local parts = Recipes.partsFor(cropId, stage)
					expect(parts ~= nil):toBe(true)
					expect(#parts >= 1):toBe(true)
					expect(parts[1].name):toBe("Stem")
					for _, p in parts do
						expect(type(p.name) == "string" and #p.name > 0):toBe(true)
						expect(shapes[p.shape]):toBe(true)
						expect(#p.size):toBe(3)
						for _, v in p.size do
							expect(type(v) == "number" and v > 0 and v <= 8):toBe(true)
						end
						expect(#p.offset):toBe(3)
						for _, v in p.offset do
							expect(type(v) == "number"):toBe(true)
						end
						expect(Visuals.palette[p.color] ~= nil or p.color == "crop"):toBe(true)
						total += 1
					end
				end
			end
			-- 36 models, each with a stem; most with leaves/fruit. Bibit has no fruit.
			expect(total >= 36):toBe(true)
		end)

		t:it("growth stages increase stem height and only siap/bibit follow the fruit rule", function()
			local function stemHeight(crop, stage)
				local parts = Recipes.partsFor(crop, stage)
				return parts[1].size[2]
			end
			for _, crop in Recipes.cropIds do
				expect(stemHeight(crop, "tumbuh") > stemHeight(crop, "bibit")):toBe(true)
				expect(stemHeight(crop, "siap") > stemHeight(crop, "tumbuh")):toBe(true)
			end
			local bibit = Recipes.partsFor("padi", "bibit")
			local siap = Recipes.partsFor("padi", "siap")
			local bibitFruit, siapFruit = 0, 0
			for _, p in bibit do if p.name:find("Fruit", 1, true) then bibitFruit += 1 end end
			for _, p in siap do if p.name:find("Fruit", 1, true) then siapFruit += 1 end end
			expect(bibitFruit):toBe(0)
			expect(siapFruit > 0):toBe(true)
		end)

		t:it("has no asset IDs", function()
			local src = fs.readFile("src/shared/CropModelCandidates.luau")
			expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)
end
