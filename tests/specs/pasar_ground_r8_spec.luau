--!nocheck
-- WORK_QUEUE section N item 109: pasar_ground_r8, the Pasar ground dressing.
-- Pure-data counts and lane/height contracts, LookDev/review wiring, the two new harness checks and
-- the applier's original-Part/restore guards. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPasarGroundR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapPasarGroundR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevPasarGroundR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local paving = Data.pavingStones()
	local cobble = Data.cobblePatches()
	local gutters = Data.gutters()
	local lane = Data.lane()
	local corners = Data.laneCorners()

	t:describe("pasar_ground_r8 pure data", function()
		t:it("locks the item-109 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("pasar_ground_r8")
			expect(Data.familyId):toBe("pasar_ground_r8")
			expect(Data.folderName):toBe("LookDevPasarGroundR8_pasar_ground_r8")
			expect(Data.stageAttribute):toBe("LookDevPasarGroundR8")
			expect(Data.kindAttribute):toBe("PasarGroundKind")
			expect(Data.pavingAttribute):toBe("PasarGroundPaving")
			expect(Data.cobbleAttribute):toBe("PasarGroundCobble")
			expect(Data.gutterAttribute):toBe("PasarGroundGutter")
			expect(Data.KINDS):toEqual({ "paving", "cobble", "gutter" })
			expect(counts.paving):toBe(40)
			expect(counts.cobble):toBe(36)
			expect(counts.gutter):toBe(18)
			expect(counts.pavingCount):toBe(76)
			expect(counts.total):toBe(94)
			expect(#paving):toBe(counts.paving)
			expect(#cobble):toBe(counts.cobble)
			expect(#gutters):toBe(counts.gutter)
			expect(counts.pavingCount >= 60):toBe(true)
			expect(Data.MIN_PAVING):toBe(60)
			expect(Data.MATERIALS.paving):toBe("Cobblestone")
			expect(Data.MATERIALS.cobble):toBe("Slate")
			expect(Data.MATERIALS.gutter):toBe("Slate")
			for _, kind in ipairs(Data.KINDS) do
				expect(Data.COLOURS[kind] ~= nil):toBe(true)
				expect(Data.kindAttributes[kind] ~= nil):toBe(true)
			end
		end)

		t:it("fixes the 0.15-stud bottom tolerance and the six-stud lane rectangle", function()
			expect(Data.PAVING_TOL):toBe(0.15)
			expect(lane.lx):toBe(0)
			expect(lane.lz):toBe(33)
			expect(lane.width):toBe(76)
			expect(lane.depth):toBe(6)
			expect(Data.LANE.depth):toBe(6)
			expect(#corners):toBe(4)
			local minX, maxX = math.huge, -math.huge
			local minZ, maxZ = math.huge, -math.huge
			for _, corner in ipairs(corners) do
				minX, maxX = math.min(minX, corner.lx), math.max(maxX, corner.lx)
				minZ, maxZ = math.min(minZ, corner.lz), math.max(maxZ, corner.lz)
			end
			expect(minX):toBe(-38)
			expect(maxX):toBe(38)
			expect(minZ):toBe(30)
			expect(maxZ):toBe(36)
			expect(dataSrc:find("PAVING_TOL = 0.15", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("bottom face", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("NO TERRAIN EDIT", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps every recipe out of the lane and clear of the stall footprints", function()
			local function hitsBox(recipe, minX, maxX, minZ, maxZ)
				local halfX, halfZ = recipe.size[1] / 2, recipe.size[3] / 2
				return recipe.lx + halfX > minX + 0.05
					and recipe.lx - halfX < maxX - 0.05
					and recipe.lz + halfZ > minZ + 0.05
					and recipe.lz - halfZ < maxZ - 0.05
			end
			for _, recipe in ipairs(paving) do
				expect(hitsBox(recipe, -38, 38, 30, 36)):toBe(false)
			end
			for _, recipe in ipairs(cobble) do
				expect(hitsBox(recipe, -38, 38, 30, 36)):toBe(false)
			end
			for _, recipe in ipairs(gutters) do
				expect(hitsBox(recipe, -38, 38, 30, 36)):toBe(false)
			end
			-- Front stalls span local z 38..46; the side stacks span x +/-39..49 at z 8..28.
			for _, recipe in ipairs(paving) do
				expect(hitsBox(recipe, -40, 40, 38, 46)):toBe(false)
				expect(hitsBox(recipe, -49, -39, 8, 28)):toBe(false)
				expect(hitsBox(recipe, 39, 49, 8, 28)):toBe(false)
			end
			for _, recipe in ipairs(gutters) do
				expect(hitsBox(recipe, -40, 40, 38, 46)):toBe(false)
				expect(hitsBox(recipe, -49, -39, 8, 28)):toBe(false)
				expect(hitsBox(recipe, 39, 49, 8, 28)):toBe(false)
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

	t:describe("pasar_ground_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 81 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(85)
			expect(LookDev.IDS[80]):toBe("lapangan_r8")
			expect(LookDev.IDS[81]):toBe("pasar_ground_r8")
			local candidate = LookDev.candidates.pasar_ground_r8
			expect(candidate.id):toBe("pasar_ground_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapPasarGroundR8")
			expect(candidate.pavingCount):toBe(76)
			expect(candidate.pavingTolerance):toBe(0.15)
			local plan = LookDev.plan("pasar_ground_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("pasar_ground_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapPasarGroundR8")
			expect(plan.pavingCount):toBe(76)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.pasar_ground_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevPasarGroundR8" })
		end)

		t:it("adds the two read-only-result checks next to the lapangan trio in ORDER", function()
			expect(
				harnessSrc:find(
					'"PASAR_PAVING",\n\t"PASAR_GROUND_LANE_CLEAR",\n\t"SOUND_LOADED",\n\t"SOUND_VOLUME",\n\t"SOUND_RESTORE",\n\t"LAPANGAN_PARTS",\n\t"LAPANGAN_PATH_REACH",\n\t"LAPANGAN_GOAL_SIZE",\n\t"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "PASAR_PAVING", "PASAR_GROUND_LANE_CLEAR" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"', 1) ~= nil):toBe(true)
			end
			-- The distinct name must be used; item 148's bare LANE_CLEAR stays as it was.
			expect(harnessSrc:find('emit("PASAR_GROUND_LANE_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("LANE_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"LookDevPasarGroundR8_pasar_ground_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapPasarGroundR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MapSpec.hubPoint(hub, corner", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("PAVING_TOL = 0.15", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('measuredSurface = "slab bbox bottom"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(PG_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("pasar_ground_r8 applier", function()
		t:it("stages original anchored non-collidable Parts from MapSpec.hub(pasar) and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapPasarGroundR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('(MapSpec :: any).hub("pasar")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("return MapSpec.hubPoint(hub, localX, localZ)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttributes[kind], true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("groundY() + thickness / 2", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with an existing path and fps cost", function()
			expect(gallerySrc:find("| `pasar_ground_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("pasar_ground_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
		end)
	end)
end
