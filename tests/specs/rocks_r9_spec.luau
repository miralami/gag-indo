--!nocheck
-- WORK_QUEUE section O item 151: rocks_r9 half-buried boulders and stones.
-- Pure data (three bands, three procedural shapes, size/bury bounds, gate/path exclusion helpers),
-- LookDev/review wiring, the four new read-only harness checks and the applier's source guards.
-- No Studio claim: CHECK evidence, tracker ticks and the visual verdict belong to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapRocksR9")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapRocksR9.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevRocksR9.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local ctx = {
		centreZ = MapSpec.riverCentreZ,
		terrainHalf = MapSpec.TERRAIN_HALF,
		terraces = MapSpec.TERRACES,
		terraceX = MapSpec.TERRACE_X,
		terraceGap = MapSpec.TERRACE_GAP,
		riverHalf = 14,
		riverBank = 8,
	}
	local rocks = Data.rocks(ctx)
	local bands = Data.bandCounts(rocks)
	local kinds = Data.kinds(rocks)

	t:describe("rocks_r9 pure data", function()
		t:it("locks the item-151 contract and mirrors MapSpec's river centre", function()
			expect(Data.id):toBe("rocks_r9")
			expect(Data.familyId):toBe("rocks_r9")
			expect(Data.folderName):toBe("LookDevRocksR9_rocks_r9")
			expect(Data.MIN_ROCKS):toBe(25)
			expect(Data.MIN_SPECIES):toBe(2)
			expect(Data.GATE_CLEAR):toBe(2)
			expect(Data.BURY_FRACTION):toBeGreaterThan(0)
			expect(Data.BURY_FRACTION):toBeLessThan(0.5)
			for _, x in ipairs({ -220, -80, 0, 120, 320 }) do
				expect(math.abs(Data.RIVER_CENTRE(x) - MapSpec.riverCentreZ(x)) < 0.0001):toBe(true)
			end
		end)

		t:it("generates at least 25 rocks across all three MapSpec-derived bands", function()
			expect(Data.count(rocks) >= Data.MIN_ROCKS):toBe(true)
			expect(bands.river > 0 and bands.hill > 0 and bands.field > 0):toBe(true)
			expect(bands.river + bands.hill + bands.field):toBe(#rocks)
			expect(#kinds >= Data.MIN_SPECIES):toBe(true)
			for _, kind in ipairs(kinds) do
				local known = false
				for _, candidate in ipairs(Data.KINDS) do
					if candidate == kind then
						known = true
					end
				end
				expect(known):toBe(true)
			end
			-- Derived from MapSpec, not from a baked world coordinate.
			for _, rock in ipairs(rocks) do
				if rock.band == "river" then
					local centre = MapSpec.riverCentreZ(rock.x)
					expect(math.abs(math.abs(rock.z - centre) - (14 + 8 / 2)) < 0.0001):toBe(true)
				elseif rock.band == "hill" then
					expect(math.max(math.abs(rock.x), math.abs(rock.z)) < MapSpec.TERRAIN_HALF):toBe(true)
				else
					expect(math.abs(rock.z) > 300):toBe(true)
				end
			end
		end)

		t:it("keeps every rock 1-4 studs wide and half-buried by 40%", function()
			for _, rock in ipairs(rocks) do
				for _, extent in ipairs(rock.size) do
					expect(extent >= Data.SIZE_MIN and extent <= Data.SIZE_MAX):toBe(true)
				end
				expect(rock.bury):toBe(Data.BURY_FRACTION)
				local parts = Data.partsFor(rock)
				expect(#parts >= 1):toBe(true)
				for _, recipe in ipairs(parts) do
					expect(recipe.shape == "Ball" or recipe.shape == "Wedge"):toBe(true)
					for _, extent in ipairs(recipe.size) do
						expect(extent > 0 and extent <= Data.SIZE_MAX):toBe(true)
					end
				end
			end
			local cluster = nil
			for _, rock in ipairs(rocks) do
				if rock.kind == "boulder_cluster" then
					cluster = rock
					break
				end
			end
			expect(cluster ~= nil):toBe(true)
			expect(#Data.partsFor(cluster)):toBe(3)
		end)

		t:it("drops rocks near a gate and rocks intersecting a path", function()
			local gate = { x = rocks[1].x, z = rocks[1].z }
			local excluded = Data.gateExcluded(rocks, { gate }, Data.GATE_CLEAR)
			expect(#excluded):toBe(#rocks - 1)
			expect(Data.gateExcluded(rocks, {}, Data.GATE_CLEAR)):toEqual(rocks)
			local target = rocks[2]
			local rects = {
				{ x = target.x, z = target.z, halfX = 1, halfZ = 1 },
			}
			local segments = {
				{ x = target.x, z = target.z, yaw = 0, length = 4 },
			}
			expect(#Data.pathExcluded(rocks, {}, {})):toBe(#rocks)
			expect(#Data.pathExcluded(rocks, rects, {})):toBe(#rocks - 1)
			expect(#Data.pathExcluded(rocks, {}, segments)):toBe(#rocks - 1)
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

	t:describe("rocks_r9 LookDev wiring and review harness", function()
		t:it("ships candidate 64 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(68)
			expect(LookDev.IDS[64]):toBe("rocks_r9")
			local candidate = LookDev.candidates.rocks_r9
			expect(candidate.id):toBe("rocks_r9")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapRocksR9")
			expect(candidate.minRocks):toBe(25)
			local plan = LookDev.plan("rocks_r9")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("rocks_r9")
			expect(plan.idsSource):toBe("Shared.ModelMapRocksR9")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.rocks_r9
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevRocksR9" })
		end)

		t:it("adds the four ROCK checks next to the path family in ORDER", function()
			expect(
				harnessSrc:find(
					'"PATH_CLEAR",\n\t"PATH_EDGE_OFFSET",\n\t"ROCK_COUNT",\n\t"ROCK_SPECIES",\n\t"ROCK_PATH_CLEAR",\n\t"ROCK_GATE_CLEAR",\n\t"BLDG_VISIBLE",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "ROCK_COUNT", "ROCK_SPECIES", "ROCK_PATH_CLEAR", "ROCK_GATE_CLEAR" }) do
				local _, count = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(count):toBe(1)
			end
			expect(harnessSrc:find('"LookDevRocksR9_rocks_r9"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(inst, "RockR9") == ROCK_KEY', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ipairs(pathRects)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("CENTRAL_HALF + normalExtent", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"gate_marker"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('taggedNear("PlotAnchor"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("#rockGates < ROCK_GATE_EXPECTED", 1, true) ~= nil):toBe(true)
			local _, clearCount = string.gsub(harnessSrc, 'emit%(.-"PATH_CLEAR"', "")
			expect(clearCount):toBe(1)
			local _, gateCount = string.gsub(harnessSrc, 'emit%(.-"GATE_CLEAR"', "")
			expect(gateCount):toBe(1)
		end)

		t:it("names a pending gallery row with an existing render path", function()
			local row = string.match(gallerySrc, "\n(| `rocks_r9` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("rocks_r9")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("rocks_r9 applier", function()
		t:it("stages original anchored non-collidable Parts and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapRocksR9)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).ModelMapPlotsR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("groundY - recipe.size[2] * Data.BURY_FRACTION", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.pathExcluded(Data.gateExcluded", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("#gates < PlotsData.PLOT_COUNT", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('GetTagged("PlotAnchor")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId, applier)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
