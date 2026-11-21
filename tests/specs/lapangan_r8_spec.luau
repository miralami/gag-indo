--!nocheck
-- WORK_QUEUE section N item 108: lapangan_r8, the village field.
-- Pure-data counts and the avatar-relative goal numbers, LookDev/review wiring, the three new
-- harness checks and the applier's original-Part/restore guards. No Studio claim: CHECK evidence,
-- tracker ticks and the visual verdict belong to the main session and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapLapanganR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapLapanganR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevLapanganR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local goals = Data.goals()
	local flagpole = Data.flagpole()
	local benches = Data.benches()
	local stones = Data.stones()
	local patches = Data.sandPatches()
	local corridors = Data.corridors()

	t:describe("lapangan_r8 pure data", function()
		t:it("locks the item-108 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("lapangan_r8")
			expect(Data.familyId):toBe("lapangan_r8")
			expect(Data.folderName):toBe("LookDevLapanganR8_lapangan_r8")
			expect(Data.stageAttribute):toBe("LookDevLapanganR8")
			expect(Data.kindAttribute):toBe("LapanganKind")
			expect(Data.goalAttribute):toBe("LapanganGoal")
			expect(Data.flagpoleAttribute):toBe("LapanganFlagpole")
			expect(Data.benchAttribute):toBe("LapanganBench")
			expect(Data.stoneAttribute):toBe("LapanganStone")
			expect(Data.sandAttribute):toBe("LapanganSand")
			expect(Data.KINDS):toEqual({ "goal", "flagpole", "bench", "stone", "sand" })
			expect(counts.goal):toBe(6)
			expect(counts.flagpole):toBe(3)
			expect(counts.bench):toBe(16)
			expect(counts.stone):toBe(24)
			expect(counts.sand):toBe(5)
			expect(counts.goals):toBe(2)
			expect(counts.flagpoles):toBe(1)
			expect(counts.benches):toBe(4)
			expect(#goals):toBe(counts.goals)
			expect(#benches):toBe(counts.benches)
			expect(#stones):toBe(counts.stone)
			expect(#patches):toBe(counts.sand)
			expect(flagpole.panels):toEqual({ "red", "white" })
			for _, colour in ipairs(flagpole.panels) do
				expect(Data.COLOURS[colour] ~= nil):toBe(true)
			end
		end)

		t:it("documents the goal size against the 7.25-stud avatar", function()
			expect(Data.AVATAR_HEIGHT):toBe(7.25)
			expect(Data.GOAL_RATIO):toBe(2.2)
			expect(Data.GOAL_HEIGHT):toBe(15.95)
			expect(math.abs(Data.GOAL_HEIGHT - Data.AVATAR_HEIGHT * Data.GOAL_RATIO) < 0.0001):toBe(true)
			for _, goal in ipairs(goals) do
				expect(goal.height):toBe(Data.GOAL_HEIGHT)
				expect(goal.width):toBe(12)
			end
			expect(math.abs(goals[1].x + goals[2].x) < 0.0001):toBe(true)
			expect(goals[1].x < 0 and goals[2].x > 0):toBe(true)
			expect(dataSrc:find("AVATAR_HEIGHT = 7.25", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("GOAL_RATIO = 2.2", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("GOAL_HEIGHT = 15.95", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps every anchor outside the RoadSouth corridor and inside the field", function()
			local halfX, halfZ = Data.FIELD.width / 2, Data.FIELD.depth / 2
			local function clearOfRoad(x, z)
				return math.abs(x) > Data.ROAD_HALF and math.abs(x) <= halfX and math.abs(z) <= halfZ
			end
			for _, recipe in ipairs(goals) do
				expect(clearOfRoad(recipe.x, recipe.z)):toBe(true)
			end
			for _, recipe in ipairs(benches) do
				expect(clearOfRoad(recipe.x, recipe.z)):toBe(true)
			end
			for _, recipe in ipairs(stones) do
				expect(clearOfRoad(recipe.x, recipe.z)):toBe(true)
			end
			for _, recipe in ipairs(patches) do
				expect(clearOfRoad(recipe.x, recipe.z)):toBe(true)
			end
			expect(clearOfRoad(flagpole.x, flagpole.z)):toBe(true)
			-- The four benches form one south-side row, not four scattered props.
			for _, bench in ipairs(benches) do
				expect(bench.z):toBe(benches[1].z)
			end
		end)

		t:it("declares five MapSpec-derived field-edge walking corridors", function()
			expect(#corridors):toBe(5)
			expect(counts.corridors):toBe(5)
			local names = {}
			for _, corridor in ipairs(corridors) do
				expect(names[corridor.name]):toBe(nil)
				names[corridor.name] = true
				expect(corridor.maxX > corridor.minX and corridor.maxZ > corridor.minZ):toBe(true)
			end
			expect(names.west and names.east and names.north and names.south and names.road_south):toBe(true)
			expect(corridors[5].minX):toBe(-Data.ROAD_HALF)
			expect(corridors[5].maxX):toBe(Data.ROAD_HALF)
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

	t:describe("lapangan_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 80 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(88)
			expect(LookDev.IDS[79]):toBe("sounds_r8")
			expect(LookDev.IDS[80]):toBe("lapangan_r8")
			local candidate = LookDev.candidates.lapangan_r8
			expect(candidate.id):toBe("lapangan_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapLapanganR8")
			expect(candidate.goalCount):toBe(2)
			expect(candidate.goalHeight):toBe(15.95)
			local plan = LookDev.plan("lapangan_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("lapangan_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapLapanganR8")
			expect(plan.goalHeight):toBe(15.95)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.lapangan_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevLapanganR8" })
		end)

		t:it("adds the three read-only-result checks next to SOUND_RESTORE in ORDER", function()
			expect(
				harnessSrc:find(
					'"SOUND_LOADED",\n\t"SOUND_VOLUME",\n\t"SOUND_RESTORE",\n\t"LAPANGAN_PARTS",\n\t"LAPANGAN_PATH_REACH",\n\t"LAPANGAN_GOAL_SIZE",\n\t"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LUMBUNG_PARTS",\n\t"LUMBUNG_DOOR_CLEAR",\n\t"LUMBUNG_PROPS_ON_GRASS",\n\t"LOOKDEV_LEAK",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "LAPANGAN_PARTS", "LAPANGAN_PATH_REACH", "LAPANGAN_GOAL_SIZE" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"') ~= nil):toBe(true)
			end
			expect(harnessSrc:find('"LookDevLapanganR8_lapangan_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapLapanganR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MapSpec.LAPANGAN.x + row.minX", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxSize(model)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("LAPANGAN_GOAL_TOL", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('lapangan_r8", game, { studio = true }', 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("lapangan_r8 applier", function()
		t:it("stages original anchored non-collidable Parts from MapSpec.LAPANGAN and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapLapanganR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.LAPANGAN.x + localX, MapSpec.LAPANGAN.z + localZ", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.flagPanelAttribute, colour", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with an existing path and fps cost", function()
			expect(gallerySrc:find("| `lapangan_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("lapangan_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
		end)
	end)
end
