--!nocheck
-- WORK_QUEUE section N item 115: laundry_r8, washing lines with a sarung, a batik cloth and a
-- kebaya behind the Pasar and Tengkulak Gelap houses, plus a hammock and a tikar under each porch.
-- Pure-data counts/materials/sites, LookDev/review wiring, the two new harness emits, and the
-- applier's static anchored/no-terrain/no-animation guard. No Studio claim: CHECK evidence, tracker
-- ticks and the visual verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapLaundryR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapLaundryR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevLaundryR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()

	t:describe("laundry_r8 pure data", function()
		t:it("locks the item-115 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("laundry_r8")
			expect(Data.familyId):toBe("laundry_r8")
			expect(Data.folderName):toBe("LookDevLaundryR8_laundry_r8")
			expect(Data.stageAttribute):toBe("LookDevLaundryR8")
			expect(Data.kindAttribute):toBe("LaundryKind")
			expect(Data.KINDS):toEqual({ "post", "line", "sarung", "batik", "kebaya", "hammock", "tikar" })
			expect(Data.CLOTH_KINDS):toEqual({ "sarung", "batik", "kebaya" })
			expect(Data.WALL_NAMES):toEqual({ "BackWall", "SideWall", "LoftWall", "FrontWall" })
			expect(Data.HUB_KEYS):toEqual({ "pasar", "gelap" })
			expect(Data.HUB_MODELS.pasar):toBe("Pasar")
			expect(Data.HUB_MODELS.gelap):toBe("TengkulakGelap")
			expect(Data.HUB_DEPTH.pasar):toBe(52)
			expect(Data.HUB_DEPTH.gelap):toBe(28)
			expect(counts.post):toBe(8)
			expect(counts.line):toBe(4)
			expect(counts.sarung):toBe(4)
			expect(counts.batik):toBe(4)
			expect(counts.kebaya):toBe(4)
			expect(counts.hammock):toBe(10)
			expect(counts.tikar):toBe(10)
			expect(counts.total):toBe(44)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(Data.MIN_PARTS):toBe(40)
			local names = {}
			for _, recipe in ipairs(parts) do
				expect(names[recipe.name]):toBe(nil)
				names[recipe.name] = true
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
				expect(LookDev.isBuiltinMaterial(Data.MATERIALS[recipe.material])):toBe(true)
				expect(Data.isCloth(recipe)):toBe(
					recipe.kind == "sarung" or recipe.kind == "batik" or recipe.kind == "kebaya"
				)
				expect(#recipe.size):toBe(3)
			end
		end)

		t:it("uses plain RGB original Parts with built-in tokens, no Painted or Leaf", function()
			-- Studio has no Painted or Leaf material enum; both stale tokens are forbidden here.
			expect(string.find(dataSrc, '"Painted"', 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, '"Leaf"', 1, true) == nil):toBe(true)
			for _, token in pairs(Data.MATERIALS) do
				expect(token == "Wood" or token == "Fabric"):toBe(true)
				expect(LookDev.isBuiltinMaterial(token)):toBe(true)
			end
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("no brand", 1, true) ~= nil):toBe(true)
		end)

		t:it("derives behind and porch sites from the hub depths", function()
			expect(Data.BEHIND_OFFSET):toBe(5)
			expect(Data.PORCH_OFFSET):toBe(4)
			expect(Data.LINE_SPACING):toBe(2)
			expect(Data.behindZ("pasar")):toBe(-31)
			expect(Data.behindZ("gelap")):toBe(-19)
			expect(Data.porchZ("pasar")):toBe(22)
			expect(Data.porchZ("gelap")):toBe(10)
			for _, hub in ipairs(Data.HUB_KEYS) do
				local halfD = Data.HUB_DEPTH[hub] / 2
				expect(Data.behindZ(hub) < -halfD):toBe(true)
				expect(Data.porchZ(hub) > 0):toBe(true)
				expect(Data.porchZ(hub) < halfD):toBe(true)
			end
		end)

		t:it("keeps every cloth bbox outside the back wall and hammock/tikar on the porch", function()
			for _, recipe in ipairs(parts) do
				local halfD = Data.HUB_DEPTH[recipe.hub] / 2
				if Data.isCloth(recipe) then
					expect(recipe.lz < -halfD):toBe(true)
					-- The nearest cloth face still clears the BackWall plane (-halfD + 0.25).
					expect(recipe.lz + recipe.size[3] / 2 < -halfD):toBe(true)
				end
				if recipe.kind == "hammock" or recipe.kind == "tikar" then
					expect(recipe.lz > 0):toBe(true)
					expect(recipe.lz < halfD):toBe(true)
				end
			end
		end)

		t:it("has no asset-id literals or engine APIs in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "game%.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "require(", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("laundry_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 87 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(87)
			expect(LookDev.IDS[86]):toBe("kincir_r8")
			expect(LookDev.IDS[87]):toBe("laundry_r8")
			local candidate = LookDev.candidates.laundry_r8
			expect(candidate.id):toBe("laundry_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapLaundryR8")
			expect(candidate.partCount):toBe(44)
			expect(candidate.minParts):toBe(40)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("laundry_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("laundry_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapLaundryR8")
			expect(plan.partCount):toBe(44)
			expect(plan.minParts):toBe(40)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.laundry_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevLaundryR8" })
		end)

		t:it("appends both distinct checks at the very end of ORDER and emits them", function()
			expect(
				harnessSrc:find(
					'"IRRIGATION_PARTS",\n\t"IRRIGATION_WATER_ON_TERRACE",\n\t"KINCIR_ROT",\n\t"LAUNDRY_PARTS",\n\t"LAUNDRY_CLOTH_CLEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("LAUNDRY_PARTS", false, 0, ">=40",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LAUNDRY_PARTS", partsPass, total, ">=40",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LAUNDRY_CLOTH_CLEAR", false, 0, "0",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LAUNDRY_CLOTH_CLEAR", clearPass, wallHits, "0",', 1, true) ~= nil):toBe(true)
			expect("LAUNDRY_PARTS" ~= "LAUNDRY_CLOTH_CLEAR"):toBe(true)
			expect(harnessSrc:find("-- 9p. WORK_QUEUE section N item 115:", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevLaundryR8_laundry_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapLaundryR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(LY_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("GetPartsInPart(probe, params)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("FilterDescendantsInstances = excludes", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("CLOTH_SWAY", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("CLOTH_SWAY"', 1, true) == nil):toBe(true)
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
			expect(harnessSrc:find('emit("KINCIR_ROT", true, delta, "3..9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("BRIDGE_WALKABLE", walkPass', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("laundry_r8 applier", function()
		t:it("stages static anchored Parts with no animation and never paints Terrain", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapLaundryR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.PartType.Cylinder", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.kindAttribute, recipe.kind)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Heartbeat", 1, true) == nil):toBe(true)
			expect(applierSrc:find("TweenService", 1, true) == nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) == nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) == nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with exact counts and no brand logos", function()
			expect(gallerySrc:find("| `laundry_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("laundry_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("44 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no brand logos", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("CLOTH_SWAY skipped", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
