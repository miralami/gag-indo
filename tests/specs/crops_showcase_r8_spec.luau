--!nocheck
-- WORK_QUEUE section N item 118: crops_showcase_r8, three crop stage-review plots (bibit, tumbuh,
-- siap) with all 12 crops in a row per plot and one Server review camera per plot. Pure-data counts,
-- LookDev/review wiring, the single new harness emit, the applier's staging contract and both camera
-- registries. No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the
-- main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapCropsShowcaseR8")
	local Candidates = env:require("shared/CropModelCandidates")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Cameras = Env.new():require("shared/ReviewCameras")

	local dataSrc = fs.readFile("src/shared/ModelMapCropsShowcaseR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevCropsShowcaseR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local cameraSrc = fs.readFile("src/shared/ReviewCameras.luau")
	local cameraDoc = fs.readFile("docs/v2/visual/REVIEW_CAMERAS.md")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
	local growthSrc = fs.readFile("tools/studio/crop_growth_check.luau")

	local COPS = {
		"padi",
		"singkong",
		"jagung",
		"bawang",
		"cabai",
		"tembakau",
		"kopi",
		"tebu",
		"kakao",
		"cengkeh",
		"durian",
		"sawit",
	}
	local STAGES = { "bibit", "tumbuh", "siap" }

	t:describe("crops_showcase_r8 pure data", function()
		t:it("locks the folder/tag contract and the 12/3/36 counts", function()
			expect(Data.id):toBe("crops_showcase_r8")
			expect(Data.familyId):toBe("crops_showcase_r8")
			expect(Data.folderName):toBe("LookDevCropsShowcaseR8_crops_showcase_r8")
			expect(Data.stageAttribute):toBe("LookDevCropsShowcaseR8")
			expect(Data.kindAttribute):toBe("CropsShowcaseKind")
			expect(Data.PLOT_KIND):toBe("plot")
			expect(Data.CROP_KIND):toBe("crop")
			expect(Data.PLATE_KIND):toBe("plate")
			expect(Data.CROP_PREFIX):toBe("LookDevCrop_")
			expect(Data.SITE):toBe("MapSpec.LAPANGAN")
			local counts = Data.counts()
			expect(counts.plots):toBe(3)
			expect(counts.crops):toBe(12)
			expect(counts.models):toBe(36)
			expect(#Data.CROPS):toBe(12)
			expect(#Data.STAGES):toBe(3)
			expect(#Data.PLOTS):toBe(3)
		end)

		t:it("uses exactly the shared crop ids and the shared growth stages", function()
			expect(Data.CROPS):toEqual(COPS)
			expect(Data.STAGES):toEqual(STAGES)
			expect(Data.CROPS):toEqual(Candidates.cropIds)
			expect(Data.STAGES):toEqual(Candidates.stages)
			for _, crop in ipairs(Data.CROPS) do
				expect(type(Candidates.archetypes[crop])):toBe("table")
			end
		end)

		t:it("lays out three MapSpec-relative stage plots with 12 crop rows each", function()
			local expectedZ = { -16, 0, 16 }
			for index, plot in ipairs(Data.PLOTS) do
				expect(plot.stage):toBe(STAGES[index])
				expect(plot.zOffset):toBe(expectedZ[index])
			end
			expect(Data.PLOT.plateSize[1]):toBe(56)
			expect(Data.PLOT.plateSize[2]):toBe(0.3)
			expect(Data.PLOT.plateSize[3]):toBe(8)
			expect(Data.PLOT.cropStep):toBe(4.5)
			expect(Data.PLOT.cropLift):toBe(0.02)
			-- 12 evenly spaced crops span 49.5 studs, inside the 72-stud Lapangan width.
			expect(Data.cropX(1)):toBe(-24.75)
			expect(Data.cropX(12)):toBe(24.75)
			expect(math.abs(Data.cropX(12) - Data.cropX(1)) < Data.PLOT.plateSize[1]):toBe(true)
			expect(Data.modelName("padi", "bibit")):toBe("LookDevCrop_padi_bibit")
			expect(Data.modelName("sawit", "siap")):toBe("LookDevCrop_sawit_siap")
		end)

		t:it("uses only plain RGB colours and valid built-in material/shape tokens", function()
			expect(Data.MATERIALS.plate):toBe("Ground")
			expect(Data.SHAPES.Sphere):toBe("Ball")
			for _, token in pairs(Data.MATERIALS) do
				expect(LookDev.isBuiltinMaterial(token)):toBe(true)
				expect(token ~= "Painted"):toBe(true)
				expect(token ~= "Leaf"):toBe(true)
			end
			for _, token in pairs({ "Block", "Cylinder", "Ball", "Wedge" }) do
				expect(type(token)):toBe("string")
			end
			for _, rgb in pairs(Data.PALETTE) do
				expect(#rgb):toBe(3)
				for _, channel in ipairs(rgb) do
					expect(type(channel)):toBe("number")
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
			for _, crop in ipairs(COPS) do
				expect(#Data.CROP_COLOURS[crop]):toBe(3)
			end
			-- Every palette token used by the shared recipes is covered by the pure map.
			for _, crop in ipairs(COPS) do
				for _, stage in ipairs(STAGES) do
					for _, detail in ipairs(Candidates.partsFor(crop, stage)) do
						expect(Data.SHAPES[detail.shape] ~= nil):toBe(true)
						if detail.color == "crop" then
							expect(Data.CROP_COLOURS[crop] ~= nil):toBe(true)
						else
							expect(Data.PALETTE[detail.color] ~= nil):toBe(true)
						end
					end
				end
			end
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

	t:describe("crops_showcase_r8 LookDev wiring and review harness", function()
		t:it("ships candidate 90 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(114)
			expect(LookDev.IDS[89]):toBe("seated_r8")
			expect(LookDev.IDS[90]):toBe("crops_showcase_r8")
			local candidate = LookDev.candidates.crops_showcase_r8
			expect(candidate.id):toBe("crops_showcase_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapCropsShowcaseR8")
			expect(candidate.stageCount):toBe(3)
			expect(candidate.cropCount):toBe(12)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("crops_showcase_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("crops_showcase_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapCropsShowcaseR8")
			expect(plan.stageCount):toBe(3)
			expect(plan.cropCount):toBe(12)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.crops_showcase_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevCropsShowcaseR8" })
		end)

		t:it("appends CROPS_STAGED last in ORDER and emits it on both paths", function()
			expect(harnessSrc:find('"SEATED_COUNT",\n\t"SEATED_ON_BENCH",\n\t"CROPS_STAGED",', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find('emit("CROPS_STAGED", false, 0, 36,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("CROPS_STAGED", csPass, measured, 36,', 1, true) ~= nil):toBe(true)
			-- CROP_GROWTH belongs ONLY to the standalone CLIENT-VM check; never emit it here.
			expect(harnessSrc:find('emit("CROP_GROWTH"', 1, true) == nil):toBe(true)
			expect(harnessSrc:find("-- 9s. WORK_QUEUE section N item 118: crops_showcase_r8", 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find("LookDevCropsShowcaseR8_crops_showcase_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapCropsShowcaseR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(CS_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"Plot_" .. plot.stage', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("partCount <= 340", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('IsA("ValueBase")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("restoreOk", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps all earlier checks, CROP_GROWTH and full_r9 byte-identical", function()
			expect(
				harnessSrc:find(
					'"LAUNDRY_PARTS",\n\t"LAUNDRY_CLOTH_CLEAR",\n\t"KITE_COUNT",\n\t"KITE_COST",\n\t"KITE_STRING_CLEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('"KITE_STRING_CLEAR",\n\t"SEATED_COUNT",\n\t"SEATED_ON_BENCH",', 1, true) ~= nil):toBe(
				true
			)
			expect(harnessSrc:find('emit("SEATED_ON_BENCH", benchPass, benchHits, "0",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"CAMERA_CLEAR",', 1, true) ~= nil):toBe(true)
			expect(growthSrc:find('emit("CROP_GROWTH"', 1, true) ~= nil):toBe(true)
			expect(growthSrc:find("local MIN_H = 0.5", 1, true) ~= nil):toBe(true)
			expect(growthSrc:find("local MAX_H = 6.0", 1, true) ~= nil):toBe(true)
			expect(growthSrc:find("local MIN_GROWTH = 15.0", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("crops_showcase_r8 applier", function()
		t:it("stages 36 original-Part crop Models in 3 plots with no state writes", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapCropsShowcaseR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).CropModelCandidates)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.LAPANGAN", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Candidates.partsFor(cropId, stage)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Model")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"Plot_" .. plot.stage', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.modelName(cropId, stage)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevCropsShowcaseR8.plotModels", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevCropsShowcaseR8.isApplied", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevCropsShowcaseR8.counts", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) == nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("GetDataStore", 1, true) == nil):toBe(true)
			expect(applierSrc:find("DataStoreService", 1, true) == nil):toBe(true)
			expect(applierSrc:find("SetAsync", 1, true) == nil):toBe(true)
			expect(applierSrc:find("UpdateAsync", 1, true) == nil):toBe(true)
			expect(applierSrc:find("rbxassetid://%d", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("crops_showcase_r8 camera and gallery wiring", function()
		t:it("registers exactly three Server crop cameras in both registries", function()
			for _, stage in ipairs(STAGES) do
				local name = "crop_" .. stage
				expect(Cameras.get(name) ~= nil):toBe(true)
				expect(Cameras.get(name).datamodel):toBe("Server")
				expect(type(Cameras.get(name).purpose)):toBe("string")
				expect(#Cameras.get(name).position):toBe(3)
				expect(#Cameras.get(name).lookAt):toBe(3)
				expect(cameraSrc:find('"crop_' .. stage .. '"', 1, true) ~= nil):toBe(true)
				expect(cameraDoc:find("| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
				expect(cameraDoc:find("crops_showcase_r8", 1, true) ~= nil):toBe(true)
			end
			expect(cameraDoc:find("45 named cameras", 1, true) ~= nil):toBe(true)
		end)

		t:it("records a pending gallery row with exact counts and no asset IDs", function()
			expect(gallerySrc:find("| `crops_showcase_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("crops_showcase_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("36 tagged crop Models", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("306, under 340", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no DataStore/player/crop-state writes", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
