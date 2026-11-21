--!nocheck
-- WORK_QUEUE section N item 111: lumbung_r8, a stilt rice barn plus toga/chilli fence yards and
-- rice drying mats at three houses. Pure-data counts, valid material tokens, yard sample centres
-- and snapped cells, door dims, LookDev/review wiring, the three new harness checks and the
-- applier's original-Part/Terrain-restore guards. No Studio claim: CHECK evidence, tracker ticks and
-- the visual verdict belong to the main session and the designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapLumbungR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapLumbungR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevLumbungR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()
	local hubs = {
		pasar = { x = -64, z = -64, yaw = 0, width = 64, depth = 52 },
		gelap = { x = -80, z = -120, yaw = 0, width = 32, depth = 28 },
		pakrt = { x = 68, z = 68, yaw = 180, width = 48, depth = 34 },
	}
	local yards = Data.yards(hubs)
	local barn = Data.barnCentre(hubs.pasar)

	t:describe("lumbung_r8 pure data", function()
		t:it("locks the item-111 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("lumbung_r8")
			expect(Data.familyId):toBe("lumbung_r8")
			expect(Data.folderName):toBe("LookDevLumbungR8_lumbung_r8")
			expect(Data.stageAttribute):toBe("LookDevLumbungR8")
			expect(Data.kindAttribute):toBe("LumbungKind")
			expect(Data.gaugeName):toBe("LumbungDoorGauge")
			expect(Data.doorWidthAttribute):toBe("DoorW")
			expect(Data.doorHeightAttribute):toBe("DoorH")
			expect(Data.doorDepthAttribute):toBe("DoorD")
			expect(Data.KINDS):toEqual({
				"stilt",
				"floor",
				"wall",
				"door",
				"roof",
				"ladder",
				"vent",
				"fence",
				"toga",
				"chilli",
				"mat",
				"rake",
			})
			expect(counts.stilt):toBe(6)
			expect(counts.floor):toBe(3)
			expect(counts.wall):toBe(6)
			expect(counts.door):toBe(3)
			expect(counts.roof):toBe(4)
			expect(counts.ladder):toBe(6)
			expect(counts.vent):toBe(2)
			expect(counts.fence):toBe(18)
			expect(counts.toga):toBe(9)
			expect(counts.chilli):toBe(12)
			expect(counts.mat):toBe(15)
			expect(counts.rake):toBe(6)
			expect(counts.total):toBe(90)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(counts.total <= 110):toBe(true)
			expect(Data.MIN_PARTS):toBe(80)
			expect(Data.HOUSE_KEYS):toEqual({ "pasar", "gelap", "pakrt" })
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
				expect(recipe.scope == "barn" or table.find(Data.HOUSE_KEYS, recipe.scope) ~= nil):toBe(true)
			end
		end)

		t:it("uses plain RGB original Parts with built-in materials only", function()
			-- Studio has no Enum.Material.Painted or Enum.Material.Leaf; both stale tokens are
			-- forbidden here and colour comes from Color3 instead.
			expect(string.find(dataSrc, '"Painted"', 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, '"Leaf"', 1, true) == nil):toBe(true)
			for _, token in pairs(Data.MATERIALS) do
				expect(LookDev.isBuiltinMaterial(token)):toBe(true)
			end
			expect(Data.COLOURS.thatch):toEqual({ 154, 128, 72 })
			expect(Data.MATERIALS.thatch):toBe("Plastic")
			expect(Data.MATERIALS.herb):toBe("Plastic")
			expect(Data.MATERIALS.leaf):toBe("Plastic")
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("SERVER applier owns the real Ground voxel pads", 1, true) ~= nil):toBe(true)
		end)

		t:it("derives the barn, the three yard centres and their snapped cell boxes", function()
			expect(Data.BARN.hubKey):toBe("pasar")
			expect(Data.BARN.lx):toBe(-18)
			expect(Data.BARN.lz):toBe(30)
			expect(math.abs(barn.x + 82) < 1e-9):toBe(true)
			expect(math.abs(barn.z + 34) < 1e-9):toBe(true)
			expect(barn.yaw):toBe(0)
			expect(#yards):toBe(3)
			expect(Data.YARD_COUNT):toBe(3)
			expect(yards[1].key):toBe("pasar")
			expect(yards[2].key):toBe("gelap")
			expect(yards[3].key):toBe("pakrt")
			expect(yards[1].x):toBe(-64)
			expect(yards[1].z):toBe(-32)
			expect(yards[2].x):toBe(-80)
			expect(yards[2].z):toBe(-100)
			expect(yards[3].x):toBe(81)
			expect(yards[3].z):toBe(44)
			for _, yard in ipairs(yards) do
				expect(yard.sx):toBe(12)
				expect(yard.sz):toBe(8)
				expect(yard.region.maxX - yard.region.minX):toBe(16)
				expect(yard.region.maxZ - yard.region.minZ):toBe(8)
				expect(#yard.region.cells):toBe(8)
				expect(yard.region.minX % 4):toBe(0)
				expect(yard.region.maxZ % 4):toBe(0)
			end
			expect(yards[1].region.minX):toBe(-72)
			expect(yards[1].region.maxX):toBe(-56)
			expect(yards[1].region.minZ):toBe(-36)
			expect(yards[1].region.maxZ):toBe(-28)
			expect(yards[3].region.minX):toBe(72)
			expect(yards[3].region.maxX):toBe(88)
			expect(yards[3].region.minZ):toBe(40)
			expect(yards[3].region.maxZ):toBe(48)
		end)

		t:it("locks the door gauge dims", function()
			expect(Data.DOOR_W):toBe(3.2)
			expect(Data.DOOR_H):toBe(4.8)
			expect(Data.DOOR_D):toBe(2)
			expect(Data.gaugeDims()):toEqual({ 3.2, 4.8, 2 })
			expect(Data.DOOR.bottom):toBe(3.6)
			expect(Data.DOOR.ly):toBe(6)
			expect(Data.gauge().kind):toBe("door_gauge")
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

	t:describe("lumbung_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 83 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(90)
			expect(LookDev.IDS[82]):toBe("musala_r8")
			expect(LookDev.IDS[83]):toBe("lumbung_r8")
			local candidate = LookDev.candidates.lumbung_r8
			expect(candidate.id):toBe("lumbung_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapLumbungR8")
			expect(candidate.partCount):toBe(90)
			expect(candidate.minParts):toBe(80)
			expect(candidate.doorW):toBe(3.2)
			expect(candidate.doorH):toBe(4.8)
			expect(candidate.doorD):toBe(2)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("lumbung_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("lumbung_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapLumbungR8")
			expect(plan.partCount):toBe(90)
			expect(plan.minParts):toBe(80)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.lumbung_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevLumbungR8" })
		end)

		t:it("adds three distinct check names before LOOKDEV_LEAK in ORDER", function()
			expect(
				harnessSrc:find(
					'"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "LUMBUNG_PARTS", "LUMBUNG_DOOR_CLEAR", "LUMBUNG_PROPS_ON_GRASS" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"', 1) ~= nil):toBe(true)
			end
			-- Distinct names: the existing facades DOOR_CLEAR and props PROPS_ON_GRASS stay intact.
			expect(harnessSrc:find('emit("LUMBUNG_PARTS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LUMBUNG_DOOR_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LUMBUNG_PROPS_ON_GRASS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("DOOR_CLEAR", facadeDoorOk', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PROPS_ON_GRASS", onGrassCount == 0', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LookDevLumbungR8_lumbung_r8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapLumbungR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("GetPartBoundsInBox", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('p.CollisionGroup = "Default"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("FilterDescendantsInstances = { lbFolder }", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("-lookX - math.sin", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("grassAt(sample)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("voxelHasNonGrass(cell.x, GRASS_Y, cell.z)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LumbungDoorGauge", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(LB_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("pure yard list must be non-empty", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("lumbung_r8 applier", function()
		t:it("stages original anchored non-collidable Parts and exact Ground voxels", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapLumbungR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("(MapSpec :: any).hub(key)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("(MapSpec :: any).hubPoint", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.sitePoint(centre", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, recipe.kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.doorWidthAttribute, Data.DOOR_W", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("volumeForTop", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FillBlock", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Material.Ground", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LIFO", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("restoreSavedVoxels()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with exact counts and no new camera", function()
			expect(gallerySrc:find("| `lumbung_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("lumbung_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("90 original Parts", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("1 invisible door gauge", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("Ground voxel pads", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no new camera", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending — review in Studio", 1, true) ~= nil):toBe(true)
		end)
	end)
end
