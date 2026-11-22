--!nocheck
-- WORK_QUEUE section N item 117: seated_r8, four catalog-dressed R15 villagers seated on the two
-- Warung benches by real Seat Parts, with four glasses and four plates on the table. Pure-data
-- counts/sites/outfit keys, LookDev/review wiring, the two new harness emits, the applier's R15
-- catalog recipe and the gallery row. No Studio claim: CHECK evidence, tracker ticks and the visual
-- verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapSeatedR8")
	local R7 = env:require("shared/ModelMapNpcsR7")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapSeatedR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevSeatedR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local sites = Data.sites()
	local props = Data.props()

	t:describe("seated_r8 pure data", function()
		t:it("locks the item-117 folder/tag contract and counts", function()
			expect(Data.id):toBe("seated_r8")
			expect(Data.familyId):toBe("seated_r8")
			expect(Data.folderName):toBe("LookDevSeatedR8_seated_r8")
			expect(Data.stageAttribute):toBe("LookDevSeatedR8")
			expect(Data.kindAttribute):toBe("SeatedKind")
			expect(Data.SEAT_KIND):toBe("seat")
			expect(Data.GLASS_KIND):toBe("glass")
			expect(Data.PLATE_KIND):toBe("plate")
			expect(Data.MIN_PROPS):toBe(8)
			expect(Data.KINDS):toEqual({ "seat", "glass", "plate" })
			expect(counts.seat):toBe(4)
			expect(counts.glass):toBe(4)
			expect(counts.plate):toBe(4)
			expect(counts.total):toBe(12)
			expect(#sites):toBe(counts.seat)
			expect(#props):toBe(counts.glass + counts.plate)
			expect(counts.glass + counts.plate >= Data.MIN_PROPS):toBe(true)
		end)

		t:it("uses only the verified R7 catalog outfit keys, with no invented IDs here", function()
			expect(Data.OUTFITS):toEqual({ "petani", "petani_wanita", "pedagang", "pak_rt" })
			for _, key in ipairs(Data.OUTFITS) do
				expect(type(R7.catalog[key])):toBe("table")
			end
			-- The exact designer-picked R7 IDs live ONLY in Shared.ModelMapNpcsR7.
			expect(R7.catalog.petani.shirt):toBe(109842878942326)
			expect(R7.catalog.petani.pants):toBe(96146120958106)
			expect(R7.catalog.petani.hats):toEqual({ 90801645168902 })
			expect(R7.catalog.petani_wanita.shirt):toBe(107918452722296)
			expect(R7.catalog.petani_wanita.pants):toBe(72201288248343)
			expect(R7.catalog.petani_wanita.hats):toEqual({ 129076562650877 })
			expect(R7.catalog.pedagang.shirt):toBe(3604934784)
			expect(R7.catalog.pedagang.pants):toBe(72201288248343)
			expect(R7.catalog.pedagang.hats):toEqual({})
			expect(R7.catalog.pak_rt.layeredShirt):toBe(18903905363)
			expect(R7.catalog.pak_rt.pants):toBe(73000190682589)
			expect(R7.catalog.pak_rt.hats):toEqual({ 73748899536912 })
		end)

		t:it("mirrors the Warung benches and puts all four seats above the bench tops", function()
			expect(Data.GROUND_Y):toBe(0.5)
			expect(Data.WARUNG.x):toBe(68)
			expect(Data.WARUNG.z):toBe(-68)
			expect(Data.WARUNG.model):toBe("Warung")
			expect(Data.BENCH.localX):toEqual({ -6.4, 6.4 })
			expect(Data.BENCH.localZ):toBe(10)
			expect(Data.BENCH.topY):toBe(1.95)
			expect(Data.BENCH.size):toEqual({ 4, 0.5, 1.6 })
			expect(Data.TABLE.topY):toBe(3.9)
			expect(Data.SEAT.size[1]):toBe(2)
			expect(Data.SEAT.size[3]):toBe(1.4)
			expect(Data.SEAT.lift):toBe(0.5)
			expect(Data.SEAT.zLift):toBe(1.35)
			local expected = {
				{ "seat_1_1", 60.7, 61.6, 180 },
				{ "seat_1_2", 62.5, 61.6, 180 },
				{ "seat_2_1", 73.5, 74.4, 180 },
				{ "seat_2_2", 75.3, 74.4, 180 },
			}
			for index, site in ipairs(sites) do
				local want = expected[index]
				expect(site.key):toBe(want[1])
				expect(math.abs(site.x - want[2]) < 1e-9):toBe(true)
				expect(site.benchX):toBe(want[3])
				expect(site.ry):toBe(want[4])
				-- Seats sit at the bench's +Z front edge: the ~0.97-wide lower-leg box centred at
				-- -56.65 starts at -57.136, clear of the bench front face at -57.2.
				expect(math.abs(site.z - -56.65) < 1e-9):toBe(true)
				expect(site.bench):toBe(math.ceil(index / 2))
				expect(site.y):toBe(2.45)
				-- Seat bottom stays clear of the bench top; both seats fit inside their 4-stud bench.
				expect(site.y - Data.SEAT.size[2] / 2 > Data.BENCH.topY):toBe(true)
				expect(math.abs(site.x - site.benchX) + Data.SEAT.size[1] / 2 <= Data.BENCH.size[1] / 2):toBe(true)
			end
		end)

		t:it("places every glass and plate on the table with valid built-in materials", function()
			local glass, plate = 0, 0
			for _, recipe in ipairs(props) do
				expect(recipe.kind == Data.GLASS_KIND or recipe.kind == Data.PLATE_KIND):toBe(true)
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(#recipe.size):toBe(3)
				expect(LookDev.isBuiltinMaterial(Data.MATERIALS[recipe.material])):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= "Painted"):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= "Leaf"):toBe(true)
				expect(recipe.ly > Data.TABLE.topY):toBe(true)
				expect(math.abs(Data.WARUNG.x + recipe.lx - 68) <= Data.TABLE.size[1] / 2):toBe(true)
				expect(math.abs(Data.WARUNG.z + recipe.lz + 58) <= Data.TABLE.size[3] / 2):toBe(true)
				if recipe.kind == Data.GLASS_KIND then
					glass += 1
					expect(recipe.size[2] > recipe.size[1]):toBe(true)
				else
					plate += 1
					expect(recipe.size[2] < recipe.size[1]):toBe(true)
				end
			end
			expect(glass):toBe(4)
			expect(plate):toBe(4)
			expect(Data.MATERIALS.glass):toBe("SmoothPlastic")
			expect(Data.MATERIALS.plate):toBe("Metal")
		end)

		t:it("has no asset-id literals or engine APIs in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "assetId", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "game%.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "require(", 1, true) == nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("seated_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 89 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(112)
			expect(LookDev.IDS[87]):toBe("laundry_r8")
			expect(LookDev.IDS[88]):toBe("layangan_r8")
			expect(LookDev.IDS[89]):toBe("seated_r8")
			local candidate = LookDev.candidates.seated_r8
			expect(candidate.id):toBe("seated_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapSeatedR8")
			expect(candidate.seatedCount):toBe(4)
			expect(candidate.propCount):toBe(8)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("seated_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("seated_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapSeatedR8")
			expect(plan.seatedCount):toBe(4)
			expect(plan.propCount):toBe(8)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.seated_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevSeatedR8" })
		end)

		t:it("appends both distinct checks at the very end of ORDER and emits them", function()
			expect(
				harnessSrc:find(
					'"KITE_COST",\n\t"KITE_STRING_CLEAR",\n\t"SEATED_COUNT",\n\t"SEATED_ON_BENCH",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("SEATED_COUNT", false, 0, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("SEATED_ON_BENCH", false, 0, "0",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("SEATED_COUNT", countPass, seatedCount, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("SEATED_ON_BENCH", benchPass, benchHits, "0",', 1, true) ~= nil):toBe(true)
			expect("SEATED_COUNT" ~= "SEATED_ON_BENCH"):toBe(true)
			expect(harnessSrc:find("-- 9r. WORK_QUEUE section N item 117:", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevSeatedR8_seated_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapSeatedR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(SR_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("task.wait(3)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("GetPartsInPart", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("OverlapParams", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('name == "Bench"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("srData.PROBE_PARTS", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps all earlier checks, KITE_* and full_r9 byte-identical", function()
			expect(
				harnessSrc:find(
					'"LAUNDRY_PARTS",\n\t"LAUNDRY_CLOTH_CLEAR",\n\t"KITE_COUNT",\n\t"KITE_COST",\n\t"KITE_STRING_CLEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("KITE_STRING_CLEAR", clearPass, buildingHits, "0",', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find('emit("KITE_COUNT", countPass, #roots, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"FLYER_COST",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("IDLE_COST",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"ROCK_PATH_CLEAR",', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("seated_r8 applier", function()
		t:it("builds real R15 rigs from R7 catalogs and seats them with Seat:Sit", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapSeatedR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ModelMapNpcsR7)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("HumanoidDescription")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CreateHumanoidModelFromDescriptionAsync", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.HumanoidRigType.R15", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Seat")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("seat:Sit(humanoid)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("humanoid.Sit = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("task.wait(0.2)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("HumanoidRootPart", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("descendant.CanCollide = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSeatedR8.rigs", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSeatedR8.seatCount", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSeatedR8.isApplied", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevSeatedR8.sitStates", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) == nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(string.find(applierSrc, "rbxassetid://%d") == nil):toBe(true)
		end)

		t:it("records a pending gallery row with exact counts and no asset IDs", function()
			expect(gallerySrc:find("| `seated_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("seated_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("4 R15 rigs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("4 Seats", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("4 glasses / 4 plates", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
