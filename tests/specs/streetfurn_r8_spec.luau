--!nocheck
-- WORK_QUEUE section M item 80: streetfurn_r8 street furniture.
-- Pure MapSpec-derived anchors, Strings keys, LookDev/review wiring, the three new read-only harness
-- checks and the applier's source guards. No Studio claim: CHECK evidence, tracker ticks and the
-- visual verdict belong to the main session / designer.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapStreetFurnR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local Strings = env:require("shared/Strings")

	local dataSrc = fs.readFile("src/shared/ModelMapStreetFurnR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevStreetFurnR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local gallerySrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local road = MapSpec.ROAD
	local posts = Data.ringPosts(road.ringCentre, Data.POST_SPACING, road.gapStart, road.gapEnd, road.ringWidth)
	local signs = Data.signs(MapSpec.PLAZA)
	local bridge = nil
	for _, continuation in ipairs(MapSpec.roadContinuations()) do
		if continuation.name == "RoadToBridge" then
			bridge = continuation
		end
	end
	local gapura = Data.gapura(bridge, road.linkHalfWidth)
	local arm = nil
	for _, candidate in ipairs(MapSpec.roadArms()) do
		if candidate.name == "RoadEast" then
			arm = candidate
		end
	end
	local poles = Data.poles(arm)
	local cable = #poles > 1
			and Data.cablePoints(
				{ x = poles[1].x, z = poles[1].z, y = poles[1].height },
				{ x = poles[2].x, z = poles[2].z, y = poles[2].height }
			)
		or {}
	local bales = Data.bales(MapSpec.PLAZA)
	local counts = Data.counts({
		posts = posts,
		signs = signs,
		gapura = gapura,
		poles = poles,
		cable = cable,
		bales = bales,
	})

	t:describe("streetfurn_r8 pure data", function()
		t:it("locks the item-80 contract", function()
			expect(Data.id):toBe("streetfurn_r8")
			expect(Data.familyId):toBe("streetfurn_r8")
			expect(Data.folderName):toBe("LookDevStreetFurnR8_streetfurn_r8")
			expect(Data.stageAttribute):toBe("StreetFurnR8")
			expect(Data.kindAttribute):toBe("StreetFurnKind")
			expect(Data.vergeAttribute):toBe("VergePost")
			expect(Data.POST_SPACING):toBe(40)
			expect(Data.MIN_POSTS):toBe(18)
			expect(Data.SIGN_COUNT):toBe(3)
			expect(Data.GAPURA_COUNT):toBe(1)
			expect(Data.BALE_COUNT):toBe(2)
			expect(Data.CLEAR_HALF):toBe(6)
		end)

		t:it("places >=18 alternating lampu/obor posts on the MapSpec ring verge", function()
			expect(#posts >= Data.MIN_POSTS):toBe(true)
			expect(counts.lampu >= 8):toBe(true)
			expect(counts.obor >= 8):toBe(true)
			expect(counts.lampu + counts.obor):toBe(#posts)
			local expectedRadius = road.ringCentre + road.ringWidth / 2 + Data.VERGE_OFFSET
			for index, post in ipairs(posts) do
				local radius = math.sqrt(post.x * post.x + post.z * post.z)
				expect(math.abs(radius - expectedRadius) < 0.0001):toBe(true)
				expect(post.kind):toBe(if index % 2 == 1 then "lampu" else "obor")
				expect(Data.RECIPES[post.kind] ~= nil):toBe(true)
				expect(post.angle >= road.gapEnd and post.angle <= road.gapStart + 360):toBe(true)
			end
		end)

		t:it("derives signs, gapura, poles, sagging cable and bales from passed-in geometry", function()
			expect(#signs):toBe(3)
			for index, sign in ipairs(signs) do
				expect(sign.key):toBe(Data.SIGN_KEYS[index])
				expect(math.abs(sign.x) > MapSpec.PLAZA.width / 2):toBe(true)
				expect(math.abs(sign.z) > MapSpec.PLAZA.depth / 2):toBe(true)
			end
			expect(#gapura):toBe(1)
			expect(gapura[1].z > bridge.z - bridge.sz / 2):toBe(true)
			expect(gapura[1].halfSpan):toBe(road.linkHalfWidth + 1)
			expect(#poles >= Data.MIN_POLES):toBe(true)
			for _, pole in ipairs(poles) do
				expect(math.abs(pole.z - arm.z) > arm.sz / 2):toBe(true)
			end
			expect(#cable):toBe(Data.CABLE_SEGMENTS + 1)
			local middle = cable[math.floor(#cable / 2) + 1]
			expect(middle.y <= cable[1].y - Data.CABLE_SAG + 1e-6):toBe(true)
			expect(math.abs(middle.y - (cable[1].y - Data.CABLE_SAG)) < 1e-6):toBe(true)
			expect(#bales):toBe(2)
			expect(counts.sign):toBe(3)
			expect(counts.gapura):toBe(1)
			expect(counts.pole):toBe(#poles)
			expect(counts.bale):toBe(2)
		end)

		t:it("carries no engine API or asset ID in the pure data module", function()
			expect(string.find(dataSrc, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Enum.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Instance.", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "Color3", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "CFrame", 1, true) == nil):toBe(true)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)
	end)

	t:describe("streetfurn_r8 Strings, LookDev wiring and review harness", function()
		t:it("ships candidate 65 with Strings parity keys", function()
			expect(#LookDev.IDS):toBe(86)
			expect(LookDev.IDS[65]):toBe("streetfurn_r8")
			local candidate = LookDev.candidates.streetfurn_r8
			expect(candidate.id):toBe("streetfurn_r8")
			expect(candidate.style):toBe("cartoonish-realism")
			expect(candidate.status):toBe("candidate, awaiting designer yes")
			expect(candidate.idsSource):toBe("Shared.ModelMapStreetFurnR8")
			expect(candidate.minPosts):toBe(18)
			expect(candidate.signCount):toBe(3)
			expect(candidate.baleCount):toBe(2)
			local plan = LookDev.plan("streetfurn_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("streetfurn_r8")
			expect(type(plan.render)):toBe("string")
			local entry = Review.paths.streetfurn_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevStreetFurnR8" })
			for _, key in ipairs(Data.SIGN_KEYS) do
				local entryText = Strings.raw[key]
				expect(type(entryText)):toBe("table")
				expect(type(entryText.id)):toBe("string")
				expect(type(entryText.en)):toBe("string")
				expect(#entryText.id > 0 and #entryText.en > 0):toBe(true)
			end
		end)

		t:it("adds the three new checks next to the path family in ORDER", function()
			expect(
				harnessSrc:find(
					'"PATH_EDGE",\n\t"STREETFURN",\n\t"STRINGS_PARITY",\n\t"STREETFURN_CLEAR",\n\t"SIGN_TEXT_PARITY",\n\t"SIGN_FACING",\n\t"ANIMAL_COUNT",\n\t"ANIMAL_BOUNDS",\n\t"ANIMAL_COST",\n\t"PATH_CLEAR",\n\t"PATH_EDGE_OFFSET",\n\t"ROCK_COUNT",',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, name in ipairs({ "STREETFURN", "STRINGS_PARITY", "STREETFURN_CLEAR" }) do
				local _, emitted = string.gsub(harnessSrc, 'emit%(.-"' .. name .. '"', "")
				expect(emitted):toBe(1)
			end
			expect(harnessSrc:find('"LookDevStreetFurnR8_streetfurn_r8"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('attr(part, "VergePost")', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ipairs(pathRects)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("ipairs(pathSegments)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("require(game.ReplicatedStorage.Shared.Strings)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"sign_pasar", "sign_sawah", "sign_balai"', 1, true) ~= nil):toBe(true)
		end)

		t:it("names a pending gallery row with an existing render path and review camera", function()
			local row = string.match(gallerySrc, "\n(| `streetfurn_r8` |[^\r\n]+)")
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("streetfurn_r8")', 1, true) ~= nil):toBe(true)
			local render = string.match(row, "`[^`]+` | [^|]+ | `[^`]+` | `([^`]+)`")
			expect(render ~= nil):toBe(true)
			expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
			expect(string.find(row, "| pending", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "`spawn`", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("streetfurn_r8 applier", function()
		t:it("stages original anchored parts, Strings text and exact restore", function()
			expect(applierSrc:find("require((Shared :: any).ModelMapStreetFurnR8)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require((Shared :: any).Strings)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.MapSpec)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.ringPosts(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.cablePoints(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Strings.get(SIGN_LANG, key)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("TextLabel")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.vergeAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(Data.familyId, applier)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("folder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
