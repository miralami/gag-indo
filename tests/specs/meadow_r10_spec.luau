--!nocheck
-- WORK_QUEUE section Q item 194: LUNE-ONLY data/applier contract for "meadow_r10". Studio staging,
-- MEADOW_VISIBLE and the visual verdict belong to the main session's harness, not to this spec.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapMeadowR10")
	local Game = env:require("shared/Config/Game")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local patches = Data.patches()
	local pureSrc = fs.readFile("src/shared/ModelMapMeadowR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevMeadowR10.luau")

	t:describe("meadow_r10 pure data", function()
		t:it("publishes the item-194 contract and the five baked IDs", function()
			expect(Data.id):toBe("meadow_r10")
			expect(Data.folderName):toBe("LookDevMeadowR10_meadow_r10")
			expect(Data.MIN_PATCHES):toBe(20)
			expect(Data.MIN_ITEMS_PER_PATCH):toBe(10)
			expect(Data.MAX_ITEMS_PER_PATCH):toBe(20)
			expect(Data.MIN_VISIBLE):toBe(6)
			expect(Data.GATE_CLEAR):toBe(6)
			expect(Data.GROUND_Y):toBe(0.5)
			expect(Data.ids.flower_a):toBe(7974911801)
			expect(Data.ids.flower_b):toBe(13032768586)
			expect(Data.ids.daisy):toBe(70509679878841)
			expect(Data.ids.tall_grass):toBe(128368650541272)
			expect(Data.ids.wild_grass):toBe(8715139325)
		end)

		t:it("builds at least 20 deterministic mixed patches with valid items", function()
			expect(#patches >= Data.MIN_PATCHES):toBe(true)
			local southern = 0
			for _, patch in ipairs(patches) do
				expect(type(patch.index) == "number"):toBe(true)
				expect(type(patch.x) == "number" and type(patch.z) == "number"):toBe(true)
				expect(patch.radius > 0):toBe(true)
				expect(#patch.items >= Data.MIN_ITEMS_PER_PATCH):toBe(true)
				expect(#patch.items <= Data.MAX_ITEMS_PER_PATCH):toBe(true)
				if patch.z > 0 then
					southern += 1
				end
				local species = {}
				for _, item in ipairs(patch.items) do
					local dx, dz = item.x - patch.x, item.z - patch.z
					expect(math.sqrt(dx * dx + dz * dz) <= patch.radius + 1e-6):toBe(true)
					expect(math.abs(item.offsetX - dx) < 1e-6 and math.abs(item.offsetZ - dz) < 1e-6):toBe(true)
					expect(item.VegX == item.x and item.VegZ == item.z):toBe(true)
					expect(item.PatchIndex == patch.index):toBe(true)
					expect(item.height > 0):toBe(true)
					expect(Data.ids[item.species] ~= nil):toBe(true)
					expect(Data.zoneClear(item.VegX, item.VegZ)):toBe(true)
					for index = 1, Game.plotCount do
						local px, pz = Game.plotCenter(index)
						expect(math.sqrt((item.VegX - px) ^ 2 + (item.VegZ - pz) ^ 2) > 29.2):toBe(true)
					end
					species[item.species] = true
				end
				local distinct = 0
				for _ in pairs(species) do
					distinct += 1
				end
				expect(distinct):toBe(5)
			end
			-- Pure proxy for MEADOW_VISIBLE; the Studio ray test is decisive.
			expect(southern >= Data.MIN_VISIBLE):toBe(true)
			expect(Env.new():require("shared/ModelMapMeadowR10").patches()):toEqual(patches)
		end)

		t:it("stays pure: no engine calls and no undeclared asset IDs", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			local seen = {}
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				if #run <= 15 then
					seen[tonumber(run)] = true
				end
			end
			for _, id in pairs(Data.ids) do
				expect(seen[id]):toBe(true)
				seen[id] = nil
			end
			local extra = 0
			for _ in pairs(seen) do
				extra += 1
			end
			expect(extra):toBe(0)
		end)
	end)

	t:describe("meadow_r10 server LookDev wiring", function()
		t:it("registers a candidate with a server review path", function()
			expect(LookDev.candidates.meadow_r10 ~= nil):toBe(true)
			expect(Review.paths.meadow_r10 ~= nil):toBe(true)
			expect(Review.paths.meadow_r10.datamodel):toBe("server")
			expect(table.find(LookDev.IDS, "meadow_r10") ~= nil):toBe(true)
		end)

		t:it("stages real baked plants with deterministic tags and restores its own folder", function()
			for _, token in ipairs({
				"LookDevAssetLoader.get(",
				'SetAttribute("MeadowPlant", true)',
				'SetAttribute("MeadowAssetId", assetId)',
				'SetAttribute("PatchIndex"',
				'SetAttribute("VegX"',
				'SetAttribute("VegZ"',
				'SetAttribute("Species", item.species)',
				'SetAttribute("LookDevMeadowR10", FAMILY_ID)',
				"LookDev.register(FAMILY_ID",
				"LookDevFailures).set(FAMILY_ID, failures)",
				"activeFolder:Destroy()",
				"LookDevMeadowR10",
				"MeadowPlants_meadow_r10",
			}) do
				expect(string.find(applierSrc, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applierSrc, "rbxassetid://%d") == nil):toBe(true)
			expect(string.find(applierSrc, "TierThin.shouldKeep(tier, patch.index)", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "VegR5.pointAllowed(", 1, true) ~= nil):toBe(true)
		end)
	end)
end
