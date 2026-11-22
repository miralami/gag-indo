--!nocheck
-- TextureMap spec (WORK_QUEUE round 2 item 5): seven agent-made texture CANDIDATES behind an
-- off-by-default LookDev flag. The shipping Visuals.textures slots all stay 0.

return function(t, Env)
	local expect = t.expect
	local TextureMap, Visuals

	t:describe("TextureMap candidate registry", function()
		t:beforeEach(function()
			local env = Env.new()
			TextureMap = env:require("shared/TextureMap")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("covers all seven texture slots with real positive ids", function()
			local slots = { "bambu", "genteng", "seng", "paving", "sawah", "kertas", "tanah" }
			local count = 0
			for _ in TextureMap.candidateIds do
				count += 1
			end
			expect(count):toBe(#slots)
			for _, slot in slots do
				local id = TextureMap.candidateIds[slot]
				expect(type(id) == "number" and id > 0):toBe(true)
			end
		end)

		t:it("ships seven zero texture slots in the shipping Visuals config", function()
			local count = 0
			for _, id in Visuals.textures do
				expect(id):toBe(0)
				count += 1
			end
			expect(count):toBe(7)
		end)

		t:it("maps every part category to a known slot with a built-in fallback material", function()
			local LookDev = Env.new():require("shared/LookDev")
			local slots = {}
			for slot in TextureMap.candidateIds do
				slots[slot] = true
			end
			local count = 0
			for _, slot in TextureMap.categorySlots do
				expect(slots[slot]):toBe(true)
				expect(LookDev.isBuiltinMaterial(TextureMap.fallbackMaterials[slot])):toBe(true)
				count += 1
			end
			expect(count):toBe(7)
		end)

		t:it("is off by default and toggles every Visuals.textures slot on/off", function()
			expect(TextureMap.usingCandidates()):toBe(false)
			TextureMap.applyCandidates(Visuals, true)
			expect(TextureMap.usingCandidates()):toBe(true)
			for slot, id in TextureMap.candidateIds do
				expect(Visuals.textures[slot]):toBe(id)
			end
			TextureMap.applyCandidates(Visuals, false)
			expect(TextureMap.usingCandidates()):toBe(false)
			for slot in TextureMap.candidateIds do
				expect(Visuals.textures[slot]):toBe(0)
			end
		end)
	end)
end
