--!nocheck
-- WORK_QUEUE section M item 72: sawah_r8 terrace dressing. Pure-data contract plus the server
-- LookDev wiring. No Studio claim: CHECK_72.txt and the visual verdict belong to the main session.
-- The applier uses procedural Parts only, so there are no asset IDs to validate.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapSawahR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local panes = MapSpec.paddyWater()
	local terraces = Data.terraceIndices()
	local tufts = Data.vergeTufts(panes)

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	t:describe("sawah_r8 terrace dressing data", function()
		t:it("covers all four terraces with a stable staging name", function()
			expect(Data.id):toBe("sawah_r8")
			expect(Data.folderName):toBe("LookDevSawahR8_sawah_r8")
			expect(Data.TERRACE_TOPS):toEqual({ 4.5, 8.5, 12.5, 16.5 })
			expect(terraces):toEqual({ 1, 2, 3, 4 })
			for index, terrace in ipairs(MapSpec.TERRACES) do
				expect(near(Data.TERRACE_TOPS[index], terrace.top)):toBe(true)
			end
			expect(Data.WATER_TRANSPARENCY):toBe(0.55)
			expect(#Data.WATER_COLOR):toBe(3)
			expect(Data.MIN_VERGE_TUFTS):toBe(40)
		end)

		t:it("derives two real water panes per terrace inside its MapSpec band", function()
			expect(#panes):toBe(8)
			for _, index in ipairs(terraces) do
				local band = MapSpec.TERRACES[index]
				local pair = Data.waterPanes(panes, index)
				expect(#pair):toBe(2)
				for side, pane in ipairs(pair) do
					expect(Data.SIDES[side]):toBe(if side == 1 then "west" else "east")
					expect(near(pane.centre[2], band.top + 0.2)):toBe(true)
					expect(pane.centre[3] >= band.z0 and pane.centre[3] <= band.z1):toBe(true)
					expect(pane.size[1] > 0 and pane.size[3] > 0):toBe(true)
				end
			end
			expect(Data.waterPanes(panes, 5)):toEqual({})
		end)

		t:it("places at least ten deterministic three-blade tufts per terrace on the bunds", function()
			expect(#tufts >= Data.MIN_VERGE_TUFTS):toBe(true)
			local perTerrace = {}
			for _, tuft in ipairs(tufts) do
				perTerrace[tuft.terrace] = (perTerrace[tuft.terrace] or 0) + 1
				expect(#tuft.blades):toBe(3)
				local pair = Data.waterPanes(panes, tuft.terrace)
				local pane = if tuft.side == "west" then pair[1] else pair[2]
				local zMin = pane.centre[3] - pane.size[3] / 2
				local zMax = pane.centre[3] + pane.size[3] / 2
				expect(tuft.z <= zMin or tuft.z >= zMax):toBe(true)
				for blade in ipairs(tuft.blades) do
					expect(Data.BLADE_HEIGHTS[blade] > 0):toBe(true)
				end
			end
			for _, index in ipairs(terraces) do
				expect(perTerrace[index] >= 10):toBe(true)
			end
			local other = Env.new():require("shared/ModelMapSawahR8")
			expect(other.vergeTufts(panes)):toEqual(tufts)
		end)

		t:it("builds exactly one hut on terrace 2 clear of the water and ramp", function()
			local hut = Data.gubukPosition(panes)
			expect(near(hut.y, 8.5)):toBe(true)
			expect(hut.x < -42):toBe(true)
			local west = Data.waterPanes(panes, 2)[1]
			expect(hut.z <= west.centre[3] - west.size[3] / 2):toBe(true)
			local parts = Data.gubukParts()
			local posts, roofs, benches = 0, 0, 0
			for _, piece in ipairs(parts) do
				if piece.kind == "gubuk_post" then
					posts += 1
				elseif piece.kind == "gubuk_roof" then
					roofs += 1
				elseif piece.kind == "gubuk_bench" then
					benches += 1
				end
			end
			expect(posts):toBe(4)
			expect(roofs):toBe(1)
			expect(benches):toBe(1)
		end)

		t:it("places a few stepping stones between terraces", function()
			local stones = Data.steppingStones()
			expect(#stones > 0 and #stones <= 4):toBe(true)
			for _, stone in ipairs(stones) do
				expect(stone.terrace >= 2):toBe(true)
				expect(stone.y > 0 and stone.size[2] > 0):toBe(true)
			end
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapSawahR8")
			expect(other.terraceIndices()):toEqual(terraces)
			expect(other.waterPanes(panes, 2)):toEqual(Data.waterPanes(panes, 2))
			expect(other.gubukPosition(panes)):toEqual(Data.gubukPosition(panes))
			expect(other.gubukParts()):toEqual(Data.gubukParts())
			expect(other.steppingStones()):toEqual(Data.steppingStones())
			local src = fs.readFile("src/shared/ModelMapSawahR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("sawah_r8 server LookDev wiring", function()
		t:it("registers candidate 49 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(54)
			expect(LookDev.IDS[49]):toBe("sawah_r8")
			expect(LookDev.candidates.sawah_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.sawah_r8.idsSource):toBe("Shared.ModelMapSawahR8")
			local plan = LookDev.plan("sawah_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("sawah_r8")
			expect(Review.paths.sawah_r8.datamodel):toBe("server")
			expect(Review.paths.sawah_r8.path):toEqual({ "World", "LookDevSawahR8" })
		end)

		t:it("stages tagged non-collidable procedural parts and restores only its own folder", function()
			local applier = fs.readFile("src/server/World/LookDevSawahR8.luau")
			expect(string.find(applier, "PROCEDURAL PARTS, NO ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.paddyWater()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevSawahR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", Data.SIDES[sideIndex])', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Gubuk", 1)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, '"SawahWater_" .. terrace', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(string.find(main, "pcall(require, script.Parent.World.LookDevSawahR8)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
