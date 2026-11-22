--!nocheck
-- WORK_QUEUE section N item 116: layangan_r8, four kites over the Lapangan field, each with a
-- diamond sail, a thin tail and a textureless Beam string to a kid-sized ground anchor. Pure-data
-- counts/materials/sites/timing constants, LookDev/review wiring, the three new harness emits and
-- the applier's one-loop/no-terrain/no-image guard. No Studio claim: CHECK evidence, tracker ticks
-- and the visual verdict belong to the main session/designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapLayanganR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapLayanganR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevLayanganR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()

	t:describe("layangan_r8 pure data", function()
		t:it("locks the item-116 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("layangan_r8")
			expect(Data.familyId):toBe("layangan_r8")
			expect(Data.folderName):toBe("LookDevLayanganR8_layangan_r8")
			expect(Data.stageAttribute):toBe("LookDevLayanganR8")
			expect(Data.kindAttribute):toBe("LayanganKind")
			expect(Data.angleAttribute):toBe("KiteAngle")
			expect(Data.ROOT_KIND):toBe("kiteroot")
			expect(Data.ANCHOR_KIND):toBe("anchor")
			expect(Data.BEAM_KIND):toBe("kitestring")
			expect(Data.KINDS):toEqual({ "kiteroot", "spine", "spar", "sail", "tail", "anchor" })
			expect(counts.kiteroot):toBe(4)
			expect(counts.spine):toBe(4)
			expect(counts.spar):toBe(4)
			expect(counts.sail):toBe(16)
			expect(counts.tail):toBe(16)
			expect(counts.anchor):toBe(4)
			expect(counts.total):toBe(48)
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
				expect(recipe.site >= 1 and recipe.site <= 4):toBe(true)
				expect(#recipe.size):toBe(3)
			end
		end)

		t:it("uses plain RGB original Parts with built-in tokens, no Painted or Leaf", function()
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

		t:it("mirrors the field and puts all four kites at 60-90 studs inside it", function()
			expect(Data.FIELD.x):toBe(0)
			expect(Data.FIELD.z):toBe(96)
			expect(Data.FIELD.width):toBe(72)
			expect(Data.FIELD.depth):toBe(56)
			expect(Data.halfW):toBe(36)
			expect(Data.halfD):toBe(28)
			expect(Data.KITE_ALT_MIN):toBe(60)
			expect(Data.KITE_ALT_MAX):toBe(90)
			expect(#Data.SITES):toBe(4)
			local anchors = {}
			for index, site in ipairs(Data.SITES) do
				local ax, az = Data.anchorXZ(site)
				local kx, kz = Data.kiteXZ(site)
				anchors[ax .. ":" .. az] = index
				expect(math.abs(kx) <= Data.halfW):toBe(true)
				expect(math.abs(kz - Data.FIELD.z) <= Data.halfD):toBe(true)
				expect(math.abs(ax) <= Data.halfW):toBe(true)
				expect(math.abs(az - Data.FIELD.z) <= Data.halfD):toBe(true)
				expect(site.altitude >= Data.KITE_ALT_MIN and site.altitude <= Data.KITE_ALT_MAX):toBe(true)
				expect(math.abs(kx - ax) <= 3):toBe(true)
				expect(math.abs(kz - az) <= 3):toBe(true)
				-- The six hub buildings sit at x = -68 / 68, at least 44 studs from any anchor.
				expect(math.abs(ax - 68) >= 44):toBe(true)
				expect(math.abs(ax + 68) >= 44):toBe(true)
			end
			expect(anchors["-24:80"]):toBe(1)
			expect(anchors["24:80"]):toBe(2)
			expect(anchors["-24:112"]):toBe(3)
			expect(anchors["24:112"]):toBe(4)
			expect(Data.SITES[1].altitude):toBe(64)
			expect(Data.SITES[2].altitude):toBe(72)
			expect(Data.SITES[3].altitude):toBe(80)
			expect(Data.SITES[4].altitude):toBe(88)
		end)

		t:it("names all six hub Models used by the string-clear raycast", function()
			expect(Data.HUB_MODELS):toEqual({
				"Pasar",
				"TengkulakGelap",
				"Warung",
				"PosRonda",
				"PosPolisi",
				"RumahPakRT",
			})
		end)

		t:it("locks the deterministic cost constants and the ColorSequence Beam spec", function()
			expect(Data.SIM_SECONDS):toBe(60)
			expect(Data.DT):toBe(1 / 60)
			expect(math.ceil(Data.SIM_SECONDS / Data.DT)):toBe(3600)
			expect(Data.MAX_STEP_MS):toBe(0.2)
			expect(Data.BEAM.faceColour[1] >= 0 and Data.BEAM.faceColour[1] <= 255):toBe(true)
			expect(Data.BEAM.width > 0):toBe(true)
			expect(Data.BEAM.segments > 0):toBe(true)
			expect(Data.BEAM.texture):toBe(nil)
			expect(string.find(dataSrc, "Texture", 1, true) == nil):toBe(true)
		end)

		t:it("has no asset-id literals or engine APIs in the pure data module", function()
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "assetId", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "game%.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "require(", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("layangan_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 88 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(112)
			expect(LookDev.IDS[87]):toBe("laundry_r8")
			expect(LookDev.IDS[88]):toBe("layangan_r8")
			local candidate = LookDev.candidates.layangan_r8
			expect(candidate.id):toBe("layangan_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapLayanganR8")
			expect(candidate.partCount):toBe(48)
			expect(candidate.minParts):toBe(40)
			expect(candidate.kiteCount):toBe(4)
			expect(candidate.maxStepMs):toBe(0.2)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("layangan_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("layangan_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapLayanganR8")
			expect(plan.partCount):toBe(48)
			expect(plan.minParts):toBe(40)
			expect(plan.kiteCount):toBe(4)
			expect(plan.maxStepMs):toBe(0.2)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.layangan_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevLayanganR8" })
		end)

		t:it("appends all three distinct checks at the very end of ORDER and emits them", function()
			expect(
				harnessSrc:find(
					'"LAUNDRY_PARTS",\n\t"LAUNDRY_CLOTH_CLEAR",\n\t"KITE_COUNT",\n\t"KITE_COST",\n\t"KITE_STRING_CLEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("KITE_COUNT", false, 0, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KITE_COUNT", countPass, #roots, 4,', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KITE_COST", false, "ERR", "<0.2ms",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KITE_COST", costPass, measuredMs, "<0.2ms",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KITE_STRING_CLEAR", false, 0, "0",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KITE_STRING_CLEAR", clearPass, buildingHits, "0",', 1, true) ~= nil):toBe(
				true
			)
			expect("KITE_COUNT" ~= "KITE_COST"):toBe(true)
			expect("KITE_COST" ~= "KITE_STRING_CLEAR"):toBe(true)
			expect("KITE_COUNT" ~= "KITE_STRING_CLEAR"):toBe(true)
			expect(harnessSrc:find("-- 9q. WORK_QUEUE section N item 116:", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevLayanganR8_layangan_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapLayanganR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(KT_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Raycast", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("FilterDescendantsInstances = { folder }", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("pump(ktData.DT)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("buildingHits", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps earlier checks, FLYER_COST, IDLE_COST and full_r9 byte-identical", function()
			expect(
				harnessSrc:find(
					'"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",\n\t"IRRIGATION_PARTS",\n\t"IRRIGATION_WATER_ON_TERRACE",',
					1,
					true
				) ~= nil
			):toBe(true)
			expect(harnessSrc:find('emit("IRRIGATION_WATER_ON_TERRACE"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("KINCIR_ROT", true, delta, "3..9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LAUNDRY_CLOTH_CLEAR", clearPass, wallHits, "0",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"FLYER_COST",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("IDLE_COST",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"ROCK_PATH_CLEAR",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("BRIDGE_WALKABLE", walkPass', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("layangan_r8 applier", function()
		t:it("stages original Parts and solid ColorSequence Beams under one Heartbeat loop", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapLayanganR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Beam")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("created.Color =", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ColorSequence.new(Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("created.Width0 =", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("created.Width1 =", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Segments", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find(".FaceColor", 1, true) == nil):toBe(true)
			expect(applierSrc:find("created.Width =", 1, true) == nil):toBe(true)
			expect(applierSrc:find("Texture", 1, true) == nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Heartbeat:Connect(tick)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("current:Disconnect()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevLayanganR8.pump", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevLayanganR8.kiteRoots", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("function LookDevLayanganR8.anchors", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("connectionCount", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("isApplied", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(Data.angleAttribute, 0)", 1, true) ~= nil):toBe(true)
			-- KITE_COST: tail Parts hang static so only 28 sail Parts are written per step
			-- (~0.14ms); 44 moving Parts measured ~0.235ms/step, over the 0.2ms limit.
			expect(applierSrc:find("recipe.kind ~= Data.ANCHOR_KIND and recipe.kind ~= Data.KIND.tail", 1, true) ~= nil):toBe(
				true
			)
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
			expect(gallerySrc:find("| `layangan_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("layangan_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("48 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("solid ColorSequence, no Texture / no asset ID", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
