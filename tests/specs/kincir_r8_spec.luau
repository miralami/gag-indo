--!nocheck
-- WORK_QUEUE section N item 114: kincir_r8, one small wooden waterwheel on the north river bank.
-- Pure-data counts/materials/rate, the river mirror and single bank site, LookDev/review wiring,
-- the new harness KINCIR_ROT emit and the applier's one-loop/no-terrain guard. No Studio claim:
-- CHECK evidence, tracker ticks and the visual verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapKincirR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapKincirR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevKincirR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()

	t:describe("kincir_r8 pure data", function()
		t:it("locks the item-114 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("kincir_r8")
			expect(Data.familyId):toBe("kincir_r8")
			expect(Data.folderName):toBe("LookDevKincirR8_kincir_r8")
			expect(Data.stageAttribute):toBe("LookDevKincirR8")
			expect(Data.kindAttribute):toBe("KincirKind")
			expect(Data.angleAttribute):toBe("WheelAngle")
			expect(Data.WHEELROOT_KIND):toBe("wheelroot")
			expect(Data.SUPPORT_KIND):toBe("support")
			expect(Data.DEG_PER_SEC):toBe(6)
			expect(Data.KINDS):toEqual({
				"wheelroot",
				"hub",
				"axle",
				"spoke",
				"blade",
				"support",
			})
			expect(counts.wheelroot):toBe(1)
			expect(counts.hub):toBe(1)
			expect(counts.axle):toBe(1)
			expect(counts.spoke):toBe(8)
			expect(counts.blade):toBe(8)
			expect(counts.support):toBe(2)
			expect(counts.total):toBe(21)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(Data.MIN_PARTS):toBe(20)
			expect(parts[1].kind):toBe("wheelroot")
			local names = {}
			for _, recipe in ipairs(parts) do
				expect(names[recipe.name]):toBe(nil)
				names[recipe.name] = true
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
				expect(LookDev.isBuiltinMaterial(Data.MATERIALS[recipe.material])):toBe(true)
				expect(Data.isRotating(recipe)):toBe(recipe.kind ~= "support")
				expect(#recipe.size):toBe(3)
			end
		end)

		t:it("uses plain RGB original Parts with Wood / WoodPlanks tokens only", function()
			-- Studio has no Painted or Leaf material enum; both stale tokens are forbidden here.
			expect(string.find(dataSrc, '"Painted"', 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, '"Leaf"', 1, true) == nil):toBe(true)
			for _, token in pairs(Data.MATERIALS) do
				expect(token == "Wood" or token == "WoodPlanks"):toBe(true)
				expect(LookDev.isBuiltinMaterial(token)):toBe(true)
			end
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no brand", 1, true) ~= nil):toBe(true)
		end)

		t:it("mirrors MapSpec's river and places one site clear of channel and bridge", function()
			expect(Data.RIVER_CENTRE):toBe(304)
			expect(Data.RIVER_AMPLITUDE):toBe(12)
			expect(Data.RIVER_PERIOD):toBe(320)
			expect(Data.RIVER_HALF):toBe(14)
			expect(Data.BANK_OFFSET):toBe(18)
			expect(Data.MAX_LOCAL_Z_HALF):toBe(4)
			expect(Data.riverCentreZ(0)):toBe(304)
			expect(Data.riverCentreZ(80)):toBe(316)
			expect(Data.riverCentreZ(-80)):toBe(292)
			expect(Data.riverCentreZ(160)):toBe(304)
			expect(Data.SITE.x):toBe(-68)
			expect(Data.SITE.bank):toBe(1)
			expect(Data.BRIDGE_CROSS_MIN):toBe(-28)
			expect(Data.BRIDGE_CROSS_MAX):toBe(28)
			expect(math.abs(Data.SITE.x) > 28):toBe(true)
			for _, other in ipairs({ -52, 56, -88, 88, 120, -250 }) do
				expect(math.abs(Data.SITE.x - other) > 12):toBe(true)
			end
			local siteZ = Data.riverCentreZ(Data.SITE.x) + Data.SITE.bank * Data.BANK_OFFSET
			expect(math.abs(siteZ - 310.33) < 0.02):toBe(true)
		end)

		t:it("keeps every part face outside the channel and the bridge crossing", function()
			for _, recipe in ipairs(parts) do
				local x, z = Data.worldXZ(Data.SITE, recipe.lx, recipe.lz)
				local halfZ = recipe.size[3] / 2
				expect(halfZ <= Data.MAX_LOCAL_Z_HALF + 1e-9):toBe(true)
				local centreDistance = math.abs(z - Data.riverCentreZ(x))
				expect(centreDistance - halfZ >= Data.RIVER_HALF - 1e-9):toBe(true)
				local radial = math.sqrt(recipe.size[1] ^ 2 + recipe.size[2] ^ 2) / 2 + math.abs(recipe.lx)
				expect(x + radial < Data.BRIDGE_CROSS_MIN):toBe(true)
				expect(x - radial > Data.BRIDGE_CROSS_MIN - 100):toBe(true)
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

	t:describe("kincir_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 86 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(89)
			expect(LookDev.IDS[85]):toBe("irrigation_r8")
			expect(LookDev.IDS[86]):toBe("kincir_r8")
			local candidate = LookDev.candidates.kincir_r8
			expect(candidate.id):toBe("kincir_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapKincirR8")
			expect(candidate.partCount):toBe(21)
			expect(candidate.minParts):toBe(20)
			expect(candidate.degPerSec):toBe(6)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("kincir_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("kincir_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapKincirR8")
			expect(plan.partCount):toBe(21)
			expect(plan.minParts):toBe(20)
			expect(plan.degPerSec):toBe(6)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.kincir_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevKincirR8" })
		end)

		t:it("appends KINCIR_ROT at the very end of ORDER and emits it", function()
			expect(
				harnessSrc:find('"IRRIGATION_PARTS",\n\t"IRRIGATION_WATER_ON_TERRACE",\n\t"KINCIR_ROT",', 1, true)
					~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("KINCIR_ROT", false, 0, "3..9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KINCIR_ROT", true, delta, "3..9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-- 9o. WORK_QUEUE section N item 114:", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("KINCIR_PARTS", 1, true) == nil):toBe(true)
			expect(harnessSrc:find("KINCIR_STAGE", 1, true) == nil):toBe(true)
			expect(harnessSrc:find("LookDevKincirR8_kincir_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapKincirR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(KC_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("pump(1)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("connectionCount", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("angleAttribute", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("exact one tagged root", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps earlier checks and full_r9 byte-identical", function()
			expect(
				harnessSrc:find(
					'"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",\n\t"IRRIGATION_PARTS",\n\t"IRRIGATION_WATER_ON_TERRACE",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("IRRIGATION_WATER_ON_TERRACE"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("BRIDGE_WALKABLE", walkPass', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("kincir_r8 applier", function()
		t:it("stages original anchored Parts under one Heartbeat loop and never paints Terrain", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapKincirR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.PartType.Cylinder", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("current:Disconnect()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("connectionCount", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevKincirR8.pump", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevKincirR8.wheelRoot", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.angleAttribute, angle)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) == nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with exact counts and one shared loop", function()
			expect(gallerySrc:find("| `kincir_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("kincir_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("21 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("one shared Heartbeat loop", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
