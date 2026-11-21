--!nocheck
-- WORK_QUEUE section N item 113: irrigation_r8, two orang-orangan sawah, two bamboo flumes with
-- thin water sheets, a bamboo clapper and stacked padi sheaves. Pure-data counts/materials, the
-- terrace-top mirror and water-sheet delta, LookDev/review wiring, the two distinct harness checks,
-- SAWAH_TOPS' unchanged emit and the applier's original-Part/no-terrain-edit guards. No Studio
-- claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapIrrigationR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapIrrigationR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevIrrigationR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()

	t:describe("irrigation_r8 pure data", function()
		t:it("locks the item-113 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("irrigation_r8")
			expect(Data.familyId):toBe("irrigation_r8")
			expect(Data.folderName):toBe("LookDevIrrigationR8_irrigation_r8")
			expect(Data.stageAttribute):toBe("LookDevIrrigationR8")
			expect(Data.kindAttribute):toBe("IrrigationKind")
			expect(Data.terraceAttribute):toBe("Terrace")
			expect(Data.WATERSHEET_KIND):toBe("watersheet")
			expect(Data.KINDS):toEqual({
				"scarecpole",
				"crossbar",
				"shirt",
				"head",
				"hat",
				"flume",
				"watersheet",
				"clapper",
				"sheaf",
			})
			expect(counts.scarecpole):toBe(2)
			expect(counts.crossbar):toBe(2)
			expect(counts.shirt):toBe(10)
			expect(counts.head):toBe(2)
			expect(counts.hat):toBe(6)
			expect(counts.flume):toBe(12)
			expect(counts.watersheet):toBe(2)
			expect(counts.clapper):toBe(6)
			expect(counts.sheaf):toBe(8)
			expect(counts.total):toBe(50)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(counts.total <= 60):toBe(true)
			expect(Data.MIN_PARTS):toBe(40)
			local names = {}
			for _, recipe in ipairs(parts) do
				expect(names[recipe.name]):toBe(nil)
				names[recipe.name] = true
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
				expect(LookDev.isBuiltinMaterial(Data.MATERIALS[recipe.material])):toBe(true)
				expect(type(recipe.x)):toBe("number")
				expect(type(recipe.y)):toBe("number")
				expect(type(recipe.z)):toBe("number")
				expect(recipe.terrace >= 1 and recipe.terrace <= 4):toBe(true)
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
			expect(Data.MATERIALS.water):toBe("Water")
			expect(Data.COLOURS.water):toEqual({ 86, 104, 52 })
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no brand", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("SAWAH_TOPS stays READ-ONLY", 1, true) ~= nil):toBe(true)
		end)

		t:it("mirrors MapSpec terrace tops and bands", function()
			expect(Data.TERRACE_TOPS):toEqual({ 4.5, 8.5, 12.5, 16.5 })
			expect(Data.TERRACE_BANDS):toEqual({
				{ z0 = -328, z1 = -312 },
				{ z0 = -344, z1 = -328 },
				{ z0 = -360, z1 = -344 },
				{ z0 = -376, z1 = -360 },
			})
			expect(Data.terraceTop(1)):toBe(4.5)
			expect(Data.terraceTop(4)):toBe(16.5)
			expect(Data.WATER_CENTRE_OFFSET):toBe(0.2)
			expect(Data.WATER_THICKNESS):toBe(0.1)
			expect(Data.WATER_TOP_DELTA):toBe(0.25)
			expect(Data.WATER_TOL):toBe(0.3)
			expect(Data.WATER_TOP_DELTA <= Data.WATER_TOL):toBe(true)
		end)

		t:it("puts every water-sheet top within 0.3 studs of its terrace top", function()
			local sheets = Data.waterSheets()
			expect(#sheets):toBe(2)
			for _, sheet in ipairs(sheets) do
				local band = Data.TERRACE_BANDS[sheet.terrace]
				expect(band ~= nil):toBe(true)
				expect(sheet.z >= band.z0 and sheet.z <= band.z1):toBe(true)
				expect(sheet.size[2]):toBe(Data.WATER_THICKNESS)
				local topY = sheet.y + sheet.size[2] / 2
				local delta = math.abs(topY - Data.terraceTop(sheet.terrace))
				expect(math.abs(sheet.y - (Data.terraceTop(sheet.terrace) + Data.WATER_CENTRE_OFFSET)) < 1e-9):toBe(
					true
				)
				expect(delta <= Data.WATER_TOL):toBe(true)
				expect(math.abs(delta - Data.WATER_TOP_DELTA) < 1e-9):toBe(true)
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

	t:describe("irrigation_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 85 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(89)
			expect(LookDev.IDS[84]):toBe("perahu_r8")
			expect(LookDev.IDS[85]):toBe("irrigation_r8")
			local candidate = LookDev.candidates.irrigation_r8
			expect(candidate.id):toBe("irrigation_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapIrrigationR8")
			expect(candidate.partCount):toBe(50)
			expect(candidate.minParts):toBe(40)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("irrigation_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("irrigation_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapIrrigationR8")
			expect(plan.partCount):toBe(50)
			expect(plan.minParts):toBe(40)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.irrigation_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevIrrigationR8" })
		end)

		t:it("appends two distinct ORDER names after LOOKDEV_LEAK without touching existing literals", function()
			-- Every existing contiguous ORDER literal ends at LOOKDEV_LEAK; new names go after it.
			expect(
				harnessSrc:find(
					'"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",\n\t"IRRIGATION_PARTS",\n\t"IRRIGATION_WATER_ON_TERRACE",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('"PERAHU_PARTS",\n\t"PERAHU_RIVER_CLEAR",\n\t"PASAR_PAVING",', 1, true) ~= nil):toBe(
				true
			)
			for _, name in ipairs({ "IRRIGATION_PARTS", "IRRIGATION_WATER_ON_TERRACE" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"', 1) ~= nil):toBe(true)
				expect(name == "BRIDGE_WALKABLE"):toBe(false)
			end
			expect(harnessSrc:find('emit("IRRIGATION_PARTS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("IRRIGATION_WATER_ON_TERRACE"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-- 9n. WORK_QUEUE section N item 113:", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevIrrigationR8_irrigation_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapIrrigationR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(IR_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MapSpec.TERRACES", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("terraceAttribute", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("every tagged watersheet tested", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps SAWAH_TOPS present and byte-identical", function()
			expect(harnessSrc:find('"SAWAH_TOPS",\n\t"SAWAH_WATER",\n\t"SAWAH_VERGE",\n\t"GUBUK",', 1, true) ~= nil):toBe(
				true
			)
			expect(
				harnessSrc:find(
					'emit(\n\t"SAWAH_TOPS",\n\tsawahMapReady and topSamples == 8 and #topFailed == 0,\n\tsawahMapReady and math.floor(topWorst * 100) / 100 or 999,\n\tSAWAH_TOP_TOL,\n\ttopDetail\n)',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("BRIDGE_WALKABLE", walkPass', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("irrigation_r8 applier", function()
		t:it("stages original anchored non-collidable Parts and never paints Terrain", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapIrrigationR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.PartType.Cylinder", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Transparency = 0.55", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, recipe.kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.terraceAttribute, recipe.terrace", 1, true) ~= nil):toBe(true)
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
			expect(gallerySrc:find("| `irrigation_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("irrigation_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("50 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
