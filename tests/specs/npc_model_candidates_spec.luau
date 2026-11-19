--!nocheck
-- NpcModelCandidates spec (WORK_QUEUE round 2 item 6): procedural caricature detail recipes
-- for the off-by-default "npcs" LookDev candidate. Pure data, no asset IDs.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local Recipes, Archetypes, Visuals

	t:describe("NpcModelCandidates recipes", function()
		t:beforeEach(function()
			local env = Env.new()
			Recipes = env:require("shared/NpcModelCandidates")
			Archetypes = env:require("shared/Config/NpcArchetypes")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("covers the three archetypes plus the debt collector", function()
			for _, id in Archetypes.order do
				expect(Recipes.recipeFor(id) ~= nil):toBe(true)
			end
			expect(Recipes.recipeFor("debt_collector") ~= nil):toBe(true)
			expect(Recipes.recipeFor("unknown_npc")):toBe(nil)
			expect(Recipes.recipeFor(nil)):toBe(nil)
		end)

		t:it("every detail has a valid shape, positive size, attach part and palette colour", function()
			local shapes = { Block = true, Cylinder = true, Sphere = true, Wedge = true }
			local attaches = { Head = true, Torso = true }
			local count = 0
			for _, recipe in Recipes.recipes do
				for _, d in recipe do
					expect(type(d.name) == "string" and #d.name > 0):toBe(true)
					expect(shapes[d.shape]):toBe(true)
					expect(attaches[d.attachTo]):toBe(true)
					expect(#d.size):toBe(3)
					for _, v in d.size do
						expect(type(v) == "number" and v > 0):toBe(true)
					end
					expect(#d.offset):toBe(3)
					for _, v in d.offset do
						expect(type(v) == "number"):toBe(true)
					end
					expect(Visuals.palette[d.color] ~= nil or Recipes.palette[d.color] ~= nil):toBe(true)
					count += 1
				end
			end
			expect(count >= 16):toBe(true)
		end)

		t:it("uses only the NPC design-card palette and has no asset IDs", function()
			for token in Recipes.palette do
				expect(Archetypes.palette[1] ~= nil):toBe(true)
				expect(Visuals.palette[token] ~= nil):toBe(true)
			end
			local src = fs.readFile("src/shared/NpcModelCandidates.luau")
			expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)
end
