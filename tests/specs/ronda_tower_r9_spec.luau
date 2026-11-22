--!nocheck
-- WORK_QUEUE section O item 150: ronda_tower_r9 Pos Ronda watchtower.
-- Pure data (position from MapSpec, brief height/base, kentongan + ladder), LookDev/review wiring,
-- the three new read-only harness checks and the applier's original-Part/restore guards.
-- No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapRondaTowerR9")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapRondaTowerR9.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevRondaTowerR9.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local config = Data.config()
	local parts = Data.parts()
	local counts = Data.counts()
	local base = Data.baseSize()

	t:describe("ronda_tower_r9 pure data", function()
		t:it("locks the item-150 contract and the MapSpec position", function()
			expect(Data.id):toBe("ronda_tower_r9")
			expect(Data.familyId):toBe("ronda_tower_r9")
			expect(Data.folderName):toBe("LookDevRondaTowerR9_ronda_tower_r9")
			expect(Data.stageAttribute):toBe("LookDevRondaTowerR9")
			expect(Data.towerAttribute):toBe("RondaTower")
			expect(config.x):toBe(MapSpec.RONDA_TOWER.x)
			expect(config.z):toBe(MapSpec.RONDA_TOWER.z)
			expect(config.baseY):toBe(MapSpec.GROUND_Y)
			expect(config.height):toBe(Data.height())
			expect(MapSpec.RONDA_TOWER.height):toBe(36) -- the greybox is never mutated
		end)

		t:it("keeps the brief height and an 8x8 base plus one tolerance", function()
			expect(Data.height() >= 28 and Data.height() <= 32):toBe(true)
			expect(base.spread * 2 + base.legSize):toBe(base.width)
			expect(base.width <= 8):toBe(true)
			expect(base.depth <= 8):toBe(true)
			expect(base.width <= 9 and base.depth <= 9):toBe(true)
		end)

		t:it("builds four legs, a deck, a pitched roof, a kentongan and a ladder", function()
			expect(counts.legs):toBe(4)
			expect(counts.deck):toBe(1)
			expect(counts.roof):toBe(2)
			expect(counts.kentongan >= 2):toBe(true) -- bamboo gong plus its slit
			expect(counts.ladder >= 2 + 10):toBe(true) -- two rails plus at least ten rungs
			expect(counts.total):toBe(#parts)
			local byName = {}
			for _, recipe in ipairs(parts) do
				byName[recipe.name] = (byName[recipe.name] or 0) + 1
				expect(recipe.y >= 0):toBe(true)
				expect(recipe.y + recipe.size[2] / 2 <= Data.height()):toBe(true)
				expect(#recipe.colour > 0):toBe(true)
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
			end
			expect(byName.Kentongan):toBe(1)
			expect(byName.TowerDeck):toBe(1)
			expect(byName.LadderRail):toBe(2)
		end)

		t:it("holds no asset IDs or engine geometry APIs in the pure data module", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Color3", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "CFrame", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)

	t:describe("ronda_tower_r9 LookDev wiring and review harness", function()
		t:it("ships candidate 63 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(118)
			expect(LookDev.IDS[63]):toBe("ronda_tower_r9")
			local candidate = LookDev.candidates.ronda_tower_r9
			expect(candidate.id):toBe("ronda_tower_r9")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapRondaTowerR9")
			local plan = LookDev.plan("ronda_tower_r9")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("ronda_tower_r9")
			expect(plan.idsSource):toBe("Shared.ModelMapRondaTowerR9")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.ronda_tower_r9
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevRondaTowerR9" })
		end)

		t:it("adds the three TOWER checks next to PLAZA_PATH_REACH in ORDER", function()
			expect(
				harnessSrc:find(
					'"PLAZA_PATH_REACH",\n\t"TOWER_HEIGHT",\n\t"TOWER_BASE",\n\t"TOWER_PATH_CLEAR",\n\t"VEG_NEAR",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "TOWER_HEIGHT", "TOWER_BASE", "TOWER_PATH_CLEAR" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"') ~= nil):toBe(true)
			end
			expect(harnessSrc:find('"LookDevRondaTowerR9_ronda_tower_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "RondaTower") == TOWER_ID', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(part, "TowerLeg") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxSize(towerModel)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(leg)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ipairs(pathRects)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ipairs(pathSegments)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("CENTRAL_HALF + normalExtent", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("TOWER_HEIGHT_MIN, TOWER_HEIGHT_MAX = 28, 32", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("TOWER_BASE_MAX = 9", 1, true) ~= nil):toBe(true)
			-- The restore proof stays single; this item does not add a duplicate LOOKDEV_LEAK.
			local _, leakCount = string.gsub(harnessSrc, 'emit%(.-"LOOKDEV_LEAK"', "")
			expect(leakCount):toBe(1)
		end)
	end)

	t:describe("ronda_tower_r9 applier", function()
		t:it("stages original anchored non-collidable Parts at MapSpec.RONDA_TOWER and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapRondaTowerR9)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.RONDA_TOWER.x, MapSpec.GROUND_Y, MapSpec.RONDA_TOWER.z", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.parts()", 1, true) ~= nil):toBe(true)
			-- The greybox tower is left alone; LOOKDEV_LEAK covers candidate folder cleanup.
			expect(string.find(applierSrc, "Transparency", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with an existing path and fps cost", function()
			expect(gallerySrc:find("| `ronda_tower_r9` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("ronda_tower_r9")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
		end)
	end)
end
