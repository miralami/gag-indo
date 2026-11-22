--!nocheck
-- Item 241 data-only guard: the default-look generators no longer emit literal Ball parts >=1.5 on
-- open lawn, they use baked shrub/tree IDs from ASSET_MANIFEST.md, and the SERVER-VM check keeps the
-- NO_MELONS / TREE_COUNT / PERF_BUDGET targets. Studio measurement stays in tools/studio/check_q241.luau.

local fs = require("@lune/fs")

local FLORA = "src/server/World/Flora.luau"
local GREYBOX = "src/server/World/Greybox.luau"
local DETAILS = "src/server/World/Details.luau"
local DECOR = "src/server/World/Decor.luau"
local CHECK = "tools/studio/check_q241.luau"
local MANIFEST = "docs/v2/visual/art/ASSET_MANIFEST.md"

local BAKED_IDS = { "9953859659", "116666781655827", "5661660655" }

local CANDIDATE_SOURCES = {
	"ModelMapHillDressingR10.luau",
	"LookDevHillDressingR10.luau",
	"ModelMapCanonicalR10.luau",
	"LookDevForestPinesLegacy.luau",
	"ModelMapRocksR9.luau",
	"ModelMapRiverR8.luau",
	"ModelMapMountainsR10.luau",
	"ModelMapKampungR10.luau",
}

-- Literal Ball sizes >= 1.5 in a generator source. Variable diameters (produce, hub lanterns) are
-- deliberately not matched: those are small props or elevated, not lawn blobs.
local function bigBallLiterals(src)
	local offenders, at = {}, 1
	while true do
		local i = string.find(src, "PartType.Ball", at, true)
		if not i then
			break
		end
		local chunk = src:sub(i, i + 400)
		local nums = chunk:match("Size%s*=%s*Vector3%.new%(([^)]*)%)")
		if nums then
			local a, b, c = nums:match("([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)")
			if a and math.max(tonumber(a), tonumber(b), tonumber(c)) >= 1.5 then
				offenders[#offenders + 1] = string.sub(chunk, 1, 60)
			end
		end
		at = i + 1
	end
	return offenders
end

return function(t, Env)
	local expect = t.expect
	local floraSrc = fs.readFile(FLORA)
	local greyboxSrc = fs.readFile(GREYBOX)
	local detailsSrc = fs.readFile(DETAILS)
	local decorSrc = fs.readFile(DECOR)
	local checkSrc = fs.readFile(CHECK)
	local manifestSrc = fs.readFile(MANIFEST)

	t:describe("item 241 no melons", function()
		t:it("default generators place no literal Ball part of 1.5 studs or more", function()
			expect(table.concat(bigBallLiterals(floraSrc), "|")):toBe("")
			expect(table.concat(bigBallLiterals(greyboxSrc), "|")):toBe("")
			expect(table.concat(bigBallLiterals(detailsSrc), "|")):toBe("")
			expect(table.concat(bigBallLiterals(decorSrc), "|")):toBe("")
		end)

		t:it("Flora bushes use baked shrubs, not Ball canopies", function()
			expect(floraSrc:find("PartType.Ball", 1, true) == nil):toBe(true)
			expect(floraSrc:find("LookDevAssetLoader.baked", 1, true) ~= nil):toBe(true)
			expect(floraSrc:find("placeBakedShrub", 1, true) ~= nil):toBe(true)
		end)

		t:it("Greybox village and background trees use the baked tree path", function()
			expect(greyboxSrc:find("bakedTree(", 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find("LookDevAssetLoader.baked", 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find("Vector3.new(9.6", 1, true) == nil):toBe(true)
		end)

		t:it("Details hedges carry baked shrubs and sacks are not Balls", function()
			expect(detailsSrc:find("addBakedShrub(", 1, true) ~= nil):toBe(true)
			local sackStart = detailsSrc:find('Name = "Sack"', 1, true)
			expect(sackStart ~= nil):toBe(true)
			expect(detailsSrc:sub(sackStart, sackStart + 240):find("PartType.Cylinder", 1, true) ~= nil):toBe(true)
		end)

		t:it("Decor crate-stack sack recipe is not a Ball on open lawn", function()
			local at, count = 1, 0
			while true do
				local i = decorSrc:find('Name = "Sack"', at, true)
				if not i then
					break
				end
				count += 1
				local chunk = decorSrc:sub(i, i + 240)
				expect(chunk:find("PartType.Cylinder", 1, true) ~= nil):toBe(true)
				expect(chunk:find("PartType.Ball", 1, true) == nil):toBe(true)
				expect(chunk:find("Vector3.new(1.6, 1.1, 1.3)", 1, true) ~= nil):toBe(true)
				at = i + 1
			end
			expect(count):toBe(1)
			local stack = decorSrc:match("local sacks = {(.-)\n\t}")
			expect(stack ~= nil):toBe(true)
			local sackCount = 0
			for _ in stack:gmatch("Vector3%.new") do
				sackCount += 1
			end
			expect(sackCount):toBe(4)
		end)

		t:it("every default baked shrub ID is recorded in ASSET_MANIFEST.md", function()
			for _, id in ipairs(BAKED_IDS) do
				expect(manifestSrc:find(id, 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("studio check keeps the NO_MELONS, TREE_COUNT and PERF_BUDGET targets", function()
			expect(checkSrc:find('emit("NO_MELONS", #melons == 0, #melons, 0', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("TREE_COUNT", trees >= 450, trees, 450', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('emit("PERF_BUDGET", perf <= 500, perf, 500', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find(">= 1.5", 1, true) ~= nil):toBe(true)
		end)

		t:it("studio check names every generator and candidate source", function()
			for _, source in ipairs(CANDIDATE_SOURCES) do
				expect(checkSrc:find(source, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("bushParts()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("makeTree()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("hedgeRow()", 1, true) ~= nil):toBe(true)
		end)

		t:it("TREE_COUNT data invariant still has at least 450 background trees", function()
			local env = Env.new()
			local Data = env:require("shared/ModelMapForestR9")
			local MapSpec = env:require("server/World/MapSpec")
			local count = #Data.placements() + #Data.shadeAnchors(MapSpec.HUBS)
			expect(count >= 450):toBe(true)
		end)
	end)
end
