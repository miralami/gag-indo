--!nocheck
-- WORK_QUEUE section N item 112: perahu_r8, two bank-side perahu, a pole net, a bamboo landing
-- stage and stacked baskets. Pure-data counts/materials, river/bridge geometry, LookDev/review
-- wiring, the two distinct harness checks, BRIDGE_WALKABLE's unchanged emit and the applier's
-- original-Part/no-terrain-edit guards. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session and the designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPerahuR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapPerahuR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevPerahuR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()

	t:describe("perahu_r8 pure data", function()
		t:it("locks the item-112 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("perahu_r8")
			expect(Data.familyId):toBe("perahu_r8")
			expect(Data.folderName):toBe("LookDevPerahuR8_perahu_r8")
			expect(Data.stageAttribute):toBe("LookDevPerahuR8")
			expect(Data.kindAttribute):toBe("PerahuKind")
			expect(Data.KINDS):toEqual({
				"hull",
				"gunwale",
				"seat",
				"netframe",
				"netmesh",
				"stageplank",
				"stagepile",
				"basket",
			})
			expect(counts.hull):toBe(6)
			expect(counts.gunwale):toBe(4)
			expect(counts.seat):toBe(4)
			expect(counts.netframe):toBe(4)
			expect(counts.netmesh):toBe(6)
			expect(counts.stageplank):toBe(6)
			expect(counts.stagepile):toBe(4)
			expect(counts.basket):toBe(5)
			expect(counts.total):toBe(39)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(counts.total <= 60):toBe(true)
			expect(Data.MIN_PARTS):toBe(35)
			local names = {}
			for _, recipe in ipairs(parts) do
				expect(names[recipe.name]):toBe(nil)
				names[recipe.name] = true
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
				expect(LookDev.isBuiltinMaterial(Data.MATERIALS[recipe.material])):toBe(true)
				expect(type(recipe.lx)):toBe("number")
				expect(type(recipe.ly)):toBe("number")
				expect(type(recipe.lz)):toBe("number")
				expect(#recipe.size):toBe(3)
				expect(Data.siteByKey(recipe.site) ~= nil):toBe(true)
			end
		end)

		t:it("uses plain RGB original Parts with built-in materials only", function()
			-- Studio has no Painted or Leaf material enum; both stale tokens are forbidden here.
			expect(string.find(dataSrc, '"Painted"', 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, '"Leaf"', 1, true) == nil):toBe(true)
			for _, token in pairs(Data.MATERIALS) do
				expect(LookDev.isBuiltinMaterial(token)):toBe(true)
			end
			expect(Data.COLOURS.hull):toEqual({ 96, 68, 44 })
			expect(Data.MATERIALS.hull):toBe("Wood")
			expect(Data.MATERIALS.net):toBe("Fabric")
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no brand", 1, true) ~= nil):toBe(true)
		end)

		t:it("mirrors the river centreline and the 56-stud bridge crossing", function()
			expect(Data.RIVER_HALF):toBe(14)
			expect(Data.BANK_OFFSET):toBe(18)
			expect(Data.RIVER_CENTRE):toBe(304)
			expect(Data.RIVER_AMPLITUDE):toBe(12)
			expect(Data.RIVER_PERIOD):toBe(320)
			expect(Data.BRIDGE_SPAN):toBe(56)
			expect(Data.BRIDGE_X):toBe(0)
			expect(Data.BRIDGE_CROSS_MIN):toBe(-28)
			expect(Data.BRIDGE_CROSS_MAX):toBe(28)
			expect(Data.riverCentreZ(0)):toBe(304)
			expect(Data.riverCentreZ(80)):toBe(316)
			expect(Data.riverCentreZ(-80)):toBe(292)
			expect(Data.riverCentreZ(160)):toBe(304)
			expect(#Data.SITES):toBe(5)
		end)

		t:it("places every part on a bank shelf clear of the channel and bridge span", function()
			for _, recipe in ipairs(parts) do
				local site = Data.siteByKey(recipe.site)
				local x, z = Data.worldXZ(site, recipe.lx, recipe.lz)
				local roll = math.rad(recipe.roll or 0)
				local halfX = math.abs(math.cos(roll)) * recipe.size[1] / 2
					+ math.abs(math.sin(roll)) * recipe.size[2] / 2
				local halfZ = recipe.size[3] / 2
				expect(math.abs(math.abs(z - Data.riverCentreZ(site.x)) - Data.BANK_OFFSET - recipe.lz) < 1e-9):toBe(
					true
				)
				-- Bridge span: no XZ box may reach the mapped crossing interval [-28, 28].
				expect(x - halfX > Data.BRIDGE_CROSS_MAX or x + halfX < Data.BRIDGE_CROSS_MIN):toBe(true)
				-- Water channel: test the centreline extremes over the whole X width, including its
				-- stationary points, so a sloped bank part cannot sneak into |z-centre| <= 14.
				local x0, x1 = x - halfX, x + halfX
				local low, high = Data.riverCentreZ(x0), Data.riverCentreZ(x1)
				for k = math.ceil((x0 - 80) / 160), math.floor((x1 - 80) / 160) do
					local sx = 80 + 160 * k
					local c = Data.riverCentreZ(sx)
					low, high = math.min(low, c), math.max(high, c)
				end
				expect(z + halfZ <= low - Data.RIVER_HALF or z - halfZ >= high + Data.RIVER_HALF):toBe(true)
			end
		end)

		t:it("has no asset-id literals or engine APIs in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "game%.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("perahu_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 84 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(90)
			expect(LookDev.IDS[83]):toBe("lumbung_r8")
			expect(LookDev.IDS[84]):toBe("perahu_r8")
			local candidate = LookDev.candidates.perahu_r8
			expect(candidate.id):toBe("perahu_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapPerahuR8")
			expect(candidate.partCount):toBe(39)
			expect(candidate.minParts):toBe(35)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("perahu_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("perahu_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapPerahuR8")
			expect(plan.partCount):toBe(39)
			expect(plan.minParts):toBe(35)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.perahu_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevPerahuR8" })
		end)

		t:it("adds two distinct check names without breaking the lumbung ORDER literal", function()
			-- Inserted before PASAR_PAVING: the lumbung_r8 spec locks the contiguous
			-- MUSALA_* / LUMBUNG_* / LOOKDEV_LEAK literal, so no name goes between them.
			expect(
				harnessSrc:find(
					'"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('"PERAHU_PARTS",\n\t"PERAHU_RIVER_CLEAR",\n\t"PASAR_PAVING",', 1, true) ~= nil):toBe(
				true
			)
			for _, name in ipairs({ "PERAHU_PARTS", "PERAHU_RIVER_CLEAR" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"', 1) ~= nil):toBe(true)
				expect(name == "BRIDGE_WALKABLE"):toBe(false)
			end
			-- BRIDGE_WALKABLE stays byte-identical and READ-ONLY.
			expect(harnessSrc:find('emit("BRIDGE_WALKABLE", walkPass', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PERAHU_PARTS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PERAHU_RIVER_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevPerahuR8_perahu_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapPerahuR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(PH_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("phChannelOverlap", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("cf.RightVector", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("80 + k * 160", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bridge.z1 - bridge.z0", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("every tagged Part tested", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("perahu_r8 applier", function()
		t:it("stages original anchored non-collidable Parts and never paints Terrain", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapPerahuR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("(MapSpec :: any).riverCentreZ", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.worldXZ(site", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CFrame.Angles(0, 0, math.rad(recipe.roll))", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, recipe.kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) == nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with exact counts and no new camera", function()
			expect(gallerySrc:find("| `perahu_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("perahu_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("39 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
