--!nocheck
-- WORK_QUEUE section O item 149: plaza_r9 central plaza dressing (fountain baked in item 188).
-- Pure-data counts and lane geometry, LookDev/review wiring, the seven read-only harness checks and
-- the applier's baked-model/restore guards. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session and the designer respectively.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPlazaR9")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapPlazaR9.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevPlazaR9.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local lanes = Data.lanes()
	local fountain = Data.fountain()
	local benches = Data.benches()
	local umbrellas = Data.umbrellas()
	local bunting = Data.bunting()
	local tree = Data.shadeTree()

	local function overlaps(a, b)
		return math.min(a.maxX, b.maxX) > math.max(a.minX, b.minX)
			and math.min(a.maxZ, b.maxZ) > math.max(a.minZ, b.minZ)
	end

	local function box(x, z, halfX, halfZ)
		return { minX = x - halfX, maxX = x + halfX, minZ = z - halfZ, maxZ = z + halfZ }
	end

	t:describe("plaza_r9 pure data", function()
		t:it("locks the item-149 counts and folder/tag contract", function()
			expect(Data.id):toBe("plaza_r9")
			expect(Data.familyId):toBe("plaza_r9")
			expect(Data.folderName):toBe("LookDevPlazaR9_plaza_r9")
			expect(Data.stageAttribute):toBe("LookDevPlazaR9")
			expect(Data.fountainAttribute):toBe("PlazaFountain")
			expect(Data.waterAttribute):toBe("FountainWater")
			expect(Data.benchAttribute):toBe("PlazaBench")
			expect(Data.umbrellaAttribute):toBe("PlazaUmbrella")
			expect(Data.buntingAttribute):toBe("PlazaBunting")
			expect(Data.treeAttribute):toBe("PlazaShadeTree")
			expect(counts.fountains):toBe(1)
			expect(counts.benches):toBe(4)
			expect(counts.umbrellas):toBe(4)
			expect(counts.buntingPoles):toBe(2)
			expect(counts.buntingFlags >= 6):toBe(true)
			expect(counts.shadeTrees):toBe(1)
			expect(counts.lanes):toBe(4)
			expect(#fountain.colourKey > 0):toBe(true)
			expect(#fountain.discColour):toBe(3)
			expect(Data.COLOURS[fountain.colourKey] ~= nil):toBe(true)
		end)

		t:it("keeps every piece inside the 38x28 dressed area", function()
			expect(Data.DRESSED.width):toBe(38)
			expect(Data.DRESSED.depth):toBe(28)
			expect(Data.LANE_WIDTH):toBe(6)
			local halfX, halfZ = Data.DRESSED.width / 2, Data.DRESSED.depth / 2
			local function inside(x, z)
				return math.abs(x) <= halfX and math.abs(z) <= halfZ
			end
			expect(inside(fountain.x, fountain.z)):toBe(true)
			for _, bench in ipairs(benches) do
				expect(inside(bench.x, bench.z)):toBe(true)
			end
			for _, umbrella in ipairs(umbrellas) do
				expect(inside(umbrella.x, umbrella.z)):toBe(true)
			end
			for _, pole in ipairs(bunting.poles) do
				expect(inside(pole.x, pole.z)):toBe(true)
			end
			for _, flag in ipairs(bunting.flags) do
				expect(inside(flag.x, flag.z)):toBe(true)
			end
			expect(inside(tree.x, tree.z)):toBe(true)
			expect(tree.height >= 10):toBe(true)
			expect(math.max(math.abs(tree.x), math.abs(tree.z)) >= 8):toBe(true) -- at the plaza edge
		end)

		t:it("declares four 6-stud lanes clear of every dressing footprint", function()
			expect(#lanes):toBe(4)
			local names = {}
			for _, lane in ipairs(lanes) do
				expect(names[lane.name]):toBe(nil)
				names[lane.name] = true
				expect(lane.width == 6 or lane.depth == 6):toBe(true)
				expect(lane.width > 0 and lane.depth > 0):toBe(true)
			end
			expect(names.north and names.south and names.east and names.west):toBe(true)
			-- Fountain sits at the centre, inside the 3.5-stud lane gap, not inside a lane.
			expect(Data.FOUNTAIN_RADIUS):toBe(3)
			expect(Data.LANE_GAP):toBe(0.5)
			for _, lane in ipairs(lanes) do
				local rect = box(lane.x, lane.z, lane.width / 2, lane.depth / 2)
				expect(overlaps(box(fountain.x, fountain.z, Data.FOUNTAIN_RADIUS, Data.FOUNTAIN_RADIUS), rect)):toBe(
					false
				)
				for _, bench in ipairs(benches) do
					expect(overlaps(box(bench.x, bench.z, bench.size[1] / 2, bench.size[2] / 2), rect)):toBe(false)
				end
				for _, umbrella in ipairs(umbrellas) do
					expect(overlaps(box(umbrella.x, umbrella.z, 2.6, 2.6), rect)):toBe(false)
				end
				for _, pole in ipairs(bunting.poles) do
					expect(overlaps(box(pole.x, pole.z, 0.5, 0.5), rect)):toBe(false)
				end
				expect(overlaps(box(tree.x, tree.z, tree.canopyRadius, tree.canopyRadius), rect)):toBe(false)
			end
		end)

		t:it("has striped umbrellas and alternating bunting flags", function()
			expect(#umbrellas):toBe(4)
			for _, umbrella in ipairs(umbrellas) do
				expect(#umbrella.stripeColours):toBe(Data.UMBRELLA.stripeCount)
				for index, colour in ipairs(umbrella.stripeColours) do
					expect(colour):toBe(Data.STRIPE_ORDER[((index - 1) % 3) + 1])
					expect(Data.COLOURS[colour] ~= nil):toBe(true)
				end
			end
			expect(Data.STRIPE_ORDER):toEqual({ "red", "white", "blue" })
			expect(#bunting.poles):toBe(2)
			expect(#bunting.flags >= 6):toBe(true)
			for index, flag in ipairs(bunting.flags) do
				expect(flag.colour):toBe(Data.STRIPE_ORDER[((index - 1) % 3) + 1])
			end
		end)

		t:it("declares the one baked fountain asset id and no engine APIs in pure data", function()
			expect(Data.FOUNTAIN_ASSET_ID):toBe(93434732057582)
			expect(Data.FOUNTAIN_BASIN_MIN):toBe(14)
			expect(Data.FOUNTAIN_BASIN_MAX):toBe(18)
			expect(dataSrc:find(tostring(Data.FOUNTAIN_ASSET_ID), 1, true) ~= nil):toBe(true)
			local withoutId = string.gsub(dataSrc, tostring(Data.FOUNTAIN_ASSET_ID), "")
			expect(string.find(withoutId, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "assetId", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "game%.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("plaza_r9 LookDev wiring and review harness", function()
		t:it("ships candidate 62 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(110)
			expect(LookDev.IDS[62]):toBe("plaza_r9")
			local candidate = LookDev.candidates.plaza_r9
			expect(candidate.id):toBe("plaza_r9")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapPlazaR9")
			expect(candidate.benchCount):toBe(4)
			expect(candidate.umbrellaCount):toBe(4)
			local plan = LookDev.plan("plaza_r9")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("plaza_r9")
			expect(plan.idsSource):toBe("Shared.ModelMapPlazaR9")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.plaza_r9
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevPlazaR9" })
		end)

		t:it("adds the seven read-only checks next to PASAR_AWNING_ON_GRASS in ORDER", function()
			expect(
				harnessSrc:find(
					'"PASAR_AWNING_ON_GRASS",\n\t"PLAZA_FOUNTAIN",\n\t"PLAZA_BENCHES",\n\t"PLAZA_UMBRELLAS",\n\t"PLAZA_BUNTING",\n\t"PLAZA_SHADE_TREE",\n\t"PLAZA_LANE_CLEAR",\n\t"PLAZA_PATH_REACH",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({
				"PLAZA_FOUNTAIN",
				"PLAZA_BENCHES",
				"PLAZA_UMBRELLAS",
				"PLAZA_BUNTING",
				"PLAZA_SHADE_TREE",
				"PLAZA_LANE_CLEAR",
				"PLAZA_PATH_REACH",
			}) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"') ~= nil):toBe(true)
			end
			expect(harnessSrc:find('"LookDevPlazaR9_plaza_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "PlazaFountain") == "plaza_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "FountainWater") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "PlazaBench") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "PlazaUmbrella") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "BuntingFlag") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "PlazaShadeTree") == true', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require(game.ReplicatedStorage.Shared.ModelMapPlazaR9)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MapSpec.PLAZA.width / 2", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("OVERLAP_TOL", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("plaza_r9 applier", function()
		t:it("stages a baked fountain model plus original Parts from MapSpec.PLAZA and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapPlazaR9)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.LookDevAssetLoader)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevAssetLoader.get(Data.FOUNTAIN_ASSET_ID, Data.familyId)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("GetBoundingBox()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ScaleTo(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("PivotTo(CFrame.new(x, groundY(), z))", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.fountainAssetIdAttribute, Data.FOUNTAIN_ASSET_ID", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.PLAZA.x + localX, MapSpec.PLAZA.z + localZ", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true) -- other stages still use Parts
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.waterAttribute, true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.buntingFlagAttribute, true", 1, true) ~= nil):toBe(true)
			local fountainStart = applierSrc:find("local function stageFountain", 1, true)
			local fountainEnd = applierSrc:find("local function stagePaving", 1, true)
			local fountainSrc = applierSrc:sub(fountainStart, fountainEnd - 1)
			expect(fountainSrc:find('Instance.new("Part")', 1, true) == nil):toBe(true)
			expect(fountainSrc:find("addPart(", 1, true) == nil):toBe(true)
			expect(fountainSrc:find("Data.fountainTiers()", 1, true) == nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row with an existing path and fps cost", function()
			expect(gallerySrc:find("| `plaza_r9` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("plaza_r9")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("pending —", 1, true) ~= nil):toBe(true)
		end)
	end)
end
