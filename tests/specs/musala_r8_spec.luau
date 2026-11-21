--!nocheck
-- WORK_QUEUE section N item 110: musala_r8, a small plain prayer house on the village side of the
-- ring. Pure-data counts, green roof RGB, door/site numbers, LookDev/review wiring, the three new
-- harness checks and the applier's original-Part/restore guards. No Studio claim: CHECK evidence,
-- tracker ticks and the cultural/designer verdict belong to the main session and the designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapMusalaR8")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local dataSrc = fs.readFile("src/shared/ModelMapMusalaR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevMusalaR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local counts = Data.counts()
	local parts = Data.parts()
	local site = Data.centre({ ringCentre = 144, ringWidth = 12 })
	local corners = Data.corridorCorners()

	t:describe("musala_r8 pure data", function()
		t:it("locks the item-110 folder/tag contract and per-kind counts", function()
			expect(Data.id):toBe("musala_r8")
			expect(Data.familyId):toBe("musala_r8")
			expect(Data.folderName):toBe("LookDevMusalaR8_musala_r8")
			expect(Data.stageAttribute):toBe("LookDevMusalaR8")
			expect(Data.kindAttribute):toBe("MusalaKind")
			expect(Data.gaugeName):toBe("MusalaDoorGauge")
			expect(Data.doorWidthAttribute):toBe("DoorW")
			expect(Data.doorHeightAttribute):toBe("DoorH")
			expect(Data.doorDepthAttribute):toBe("DoorD")
			expect(Data.KINDS):toEqual({
				"base",
				"wall",
				"post",
				"door",
				"window",
				"roof",
				"horn",
				"wudhu",
				"shoes",
			})
			expect(counts.base):toBe(3)
			expect(counts.wall):toBe(6)
			expect(counts.post):toBe(4)
			expect(counts.door):toBe(3)
			expect(counts.window):toBe(6)
			expect(counts.roof):toBe(4)
			expect(counts.horn):toBe(6)
			expect(counts.wudhu):toBe(7)
			expect(counts.shoes):toBe(10)
			expect(counts.total):toBe(49)
			expect(#parts):toBe(counts.total)
			expect(counts.total >= Data.MIN_PARTS):toBe(true)
			expect(Data.MIN_PARTS):toBe(25)
			for _, recipe in ipairs(parts) do
				expect(Data.COLOURS[recipe.colour] ~= nil):toBe(true)
				expect(Data.MATERIALS[recipe.material] ~= nil):toBe(true)
			end
		end)

		t:it("uses plain RGB green roof tiers and a respectful original-Part kit", function()
			expect(Data.COLOURS.green):toEqual({ 111, 138, 63 })
			expect(Data.COLOURS.greenDark):toEqual({ 86, 112, 48 })
			-- Studio has no Enum.Material.Painted; the stale allowlist entry was removed. Plastic
			-- is valid and the green read comes from Color3, so no material token may be Painted.
			expect(Data.MATERIALS.green):toBe("Plastic")
			expect(string.find(dataSrc, '"Painted"', 1, true) == nil):toBe(true)
			local roofCount = 0
			for _, recipe in ipairs(parts) do
				if recipe.kind == "roof" then
					roofCount += 1
					expect(recipe.colour == "green" or recipe.colour == "greenDark"):toBe(true)
					expect(recipe.size[2] <= 1):toBe(true)
				end
			end
			expect(roofCount):toBe(counts.roof)
			local names = {}
			for _, recipe in ipairs(parts) do
				expect(names[recipe.name]):toBe(nil)
				names[recipe.name] = true
				expect(type(recipe.lx)):toBe("number")
				expect(type(recipe.ly)):toBe("number")
				expect(type(recipe.lz)):toBe("number")
				expect(#recipe.size):toBe(3)
			end
		end)

		t:it("derives the inner-ring site, door dims and clear approach from road data", function()
			expect(Data.SITE.angleDeg):toBe(30)
			expect(Data.SITE.insetFromInnerEdge):toBe(18)
			expect(site.radius):toBe(120)
			expect(math.abs(site.x - 60) < 1e-6):toBe(true)
			expect(math.abs(site.z - 103.923048454) < 1e-6):toBe(true)
			expect(site.yaw):toBe(30)
			expect(Data.DOOR_W):toBe(3)
			expect(Data.DOOR_H):toBe(5.4)
			expect(Data.DOOR_D):toBe(2)
			expect(Data.gaugeDims()):toEqual({ 3, 5.4, 2 })
			expect(Data.DOOR.bottom):toBe(0.4)
			expect(math.abs(Data.DOOR.ly - 3.1) < 1e-9):toBe(true)
			local x, y, z = Data.sitePoint(site, site.yaw, 0, 0, Data.CORRIDOR.maxLz)
			expect(math.abs(math.sqrt(x * x + z * z) - 134) < 1e-6):toBe(true)
			expect(y):toBe(site.y)
			expect(Data.CORRIDOR.minLx):toBe(-2)
			expect(Data.CORRIDOR.maxLx):toBe(2)
			expect(Data.CORRIDOR.minLz):toBe(6.7)
			expect(Data.CORRIDOR.maxLz):toBe(14)
			expect(#corners):toBe(4)
			for _, recipe in ipairs(parts) do
				local halfX, halfZ = recipe.size[1] / 2, recipe.size[3] / 2
				local inLane = recipe.lx + halfX > Data.CORRIDOR.minLx + 0.05
					and recipe.lx - halfX < Data.CORRIDOR.maxLx - 0.05
					and recipe.lz + halfZ > Data.CORRIDOR.minLz + 0.05
					and recipe.lz - halfZ < Data.CORRIDOR.maxLz - 0.05
				expect(inLane):toBe(false)
			end
			expect(dataSrc:find("inner edge r 138", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("needs designer review", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("NO TERRAIN EDIT", 1, true) == nil):toBe(true)
			expect(dataSrc:find("no terrain edit", 1, true) ~= nil):toBe(true)
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

	t:describe("musala_r8 LookDev wiring and review harness", function()
		t:it("ships new candidate 82 with a descriptor, plan and server review path", function()
			expect(#LookDev.IDS):toBe(82)
			expect(LookDev.IDS[81]):toBe("pasar_ground_r8")
			expect(LookDev.IDS[82]):toBe("musala_r8")
			local candidate = LookDev.candidates.musala_r8
			expect(candidate.id):toBe("musala_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapMusalaR8")
			expect(candidate.partCount):toBe(49)
			expect(candidate.minParts):toBe(25)
			expect(candidate.doorW):toBe(3)
			expect(candidate.doorH):toBe(5.4)
			expect(candidate.doorD):toBe(2)
			expect(candidate.render):toBe("docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md")
			local plan = LookDev.plan("musala_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("musala_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapMusalaR8")
			expect(plan.partCount):toBe(49)
			expect(plan.minParts):toBe(25)
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.musala_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevMusalaR8" })
		end)

		t:it("adds three distinct check names next to the lapangan trio in ORDER", function()
			expect(
				harnessSrc:find(
					'"LAPANGAN_PARTS",\n\t"LAPANGAN_PATH_REACH",\n\t"LAPANGAN_GOAL_SIZE",\n\t"MUSALA_PARTS",\n\t"MUSALA_DOOR_CLEAR",\n\t"MUSALA_PATH_REACH",\n\t"LOOKDEV_LEAK",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "MUSALA_PARTS", "MUSALA_DOOR_CLEAR", "MUSALA_PATH_REACH" }) do
				expect(harnessSrc:find('emit%(.-"' .. name .. '"', 1) ~= nil):toBe(true)
			end
			-- Distinct names: the existing facades DOOR_CLEAR and six-hub PATH_REACH stay untouched.
			expect(harnessSrc:find('emit("MUSALA_DOOR_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("MUSALA_PATH_REACH"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("MUSALA_PARTS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("DOOR_CLEAR", facadeDoorOk', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PATH_REACH",', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"LookDevMusalaR8_musala_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Shared.ModelMapMusalaR8", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("GetPartBoundsInBox", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('p.CollisionGroup = "Default"', 1, true) ~= nil):toBe(true)
			-- Regressions fixed in Studio: Roblox LookVector is a Part's local -Z, and a world-axis
			-- AABB false-positives on the yaw-rotated kit, so the lane must be tested site-local.
			expect(harnessSrc:find("-lookX - math.sin", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("SITE-LOCAL space", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bboxAABB(part)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("enable(MS_ID, game, { studio = true })", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("all tagged parts tested; none collidable by design", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MusalaDoorGauge", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("musala_r8 applier", function()
		t:it("stages original anchored non-collidable Parts from pure road data and restores exactly", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapMusalaR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.centre(road)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.sitePoint(centre, centre.yaw", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.kindAttribute, recipe.kind", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.doorWidthAttribute, Data.DOOR_W", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Color3.fromRGB", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId", 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(applierSrc, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("records a pending gallery row flagged for cultural review with no asset IDs", function()
			expect(gallerySrc:find("| `musala_r8` |", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find('LookDev.enable("musala_r8")', 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md`", 1, true) ~= nil):toBe(
				true
			)
			expect(gallerySrc:find("needs designer review: cultural content", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("no asset IDs", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("off by default", 1, true) ~= nil):toBe(true)
			expect(gallerySrc:find("fps", 1, true) ~= nil):toBe(true)
		end)
	end)
end
