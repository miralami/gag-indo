--!nocheck
-- HubPropCandidates spec (WORK_QUEUE round 2 item 8): pure-data hero-prop recipes for the
-- off-by-default "hubprops" LookDev candidate. No asset IDs, no Roblox APIs at load.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local Recipes

	t:describe("HubPropCandidates recipes", function()
		t:beforeEach(function()
			Recipes = Env.new():require("shared/HubPropCandidates")
		end)

		t:it("dresses all four shop hubs named in the queue", function()
			expect(#Recipes.hubOrder):toBe(4)
			for _, key in Recipes.hubOrder do
				expect(Recipes.hubs[key] ~= nil):toBe(true)
				expect(type(Recipes.hubs[key].model) == "string"):toBe(true)
				expect(type(Recipes.hubs[key].anchor) == "string"):toBe(true)
				expect(#Recipes.hubs[key].parts >= 5):toBe(true)
			end
			expect(Recipes.partsFor("not_a_hub")):toBe(nil)
		end)

		t:it("every hub produces valid low-poly part descriptors incl. lantern and sign", function()
			local shapes = { Block = true, Cylinder = true, Sphere = true, Wedge = true }
			local materials = { WoodPlanks = true, SmoothPlastic = true, Metal = true, Fabric = true, Wood = true }
			for _, key in Recipes.hubOrder do
				local parts = Recipes.partsFor(key)
				local hasLantern = false
				local hasSign = false
				for _, p in parts do
					expect(type(p.name) == "string" and #p.name > 0):toBe(true)
					expect(shapes[p.shape]):toBe(true)
					expect(materials[p.material]):toBe(true)
					expect(#p.size):toBe(3)
					for _, v in p.size do
						expect(type(v) == "number" and v > 0 and v <= 60):toBe(true)
					end
					expect(#p.offset):toBe(3)
					for _, v in p.offset do
						expect(type(v) == "number"):toBe(true)
					end
					expect(Recipes.palette[p.color] ~= nil):toBe(true)
					if p.name == "HangingLantern" then hasLantern = true end
					if p.name == "SignBoard" then hasSign = true end
				end
				-- Within the per-hub instance budget (MAP_SPEC: 8-12 props per hub).
				expect(#parts <= 12):toBe(true)
				expect(hasLantern):toBe(true)
				expect(hasSign):toBe(true)
			end
		end)

		t:it("uses each hub's own accent colour on the shared sign board", function()
			for _, key in Recipes.hubOrder do
				local found = false
				for _, p in Recipes.partsFor(key) do
					if p.name == "SignBoard" then
						expect(p.color):toBe(Recipes.ACCENT[key])
						found = true
					end
				end
				expect(found):toBe(true)
			end
		end)

		t:it("has no asset IDs", function()
			local src = fs.readFile("src/shared/HubPropCandidates.luau")
			expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)
end
