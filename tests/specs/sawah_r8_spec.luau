--!nocheck
-- WORK_QUEUE section M item 72, rebuilt in section O item 140: sawah_r8 terrace dressing. Pure-data
-- contract for dense padi rows/clumps plus the server LookDev wiring and the four new read-only
-- harness checks. No Studio claim: the CHECK_* evidence and the visual verdict belong to the main
-- session. The applier uses procedural Parts only, so there are no asset IDs to validate.

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

		t:it("grows deterministic padi rows of small clumps on all four terraces", function()
			expect(Data.PADI_ROWS_MIN):toBe(10)
			expect(Data.PADI_CLUMPS_MIN):toBe(250)
			expect(Data.PADI_CLUMP_WIDTH):toBe(1.5)
			expect(Data.PADI_MAX_PART):toBe(2.5)
			expect(Data.ROW_SPACING):toBe(2)
			expect(Data.ROW_SPACING > Data.PADI_CLUMP_WIDTH):toBe(true) -- water visible between rows

			local rows = Data.padiRows(panes)
			local clumps = Data.padiClumps(panes)
			local rowsByTerrace, clumpsByTerrace = {}, {}
			local rowsByPane = {}
			for _, row in ipairs(rows) do
				rowsByTerrace[row.terrace] = (rowsByTerrace[row.terrace] or 0) + 1
				local paneKey = row.terrace .. ":" .. row.side
				rowsByPane[paneKey] = rowsByPane[paneKey] or {}
				table.insert(rowsByPane[paneKey], row)
				local pair = Data.waterPanes(panes, row.terrace)
				local pane = if row.side == "west" then pair[1] else pair[2]
				expect(row.x >= pane.centre[1] - pane.size[1] / 2):toBe(true)
				expect(row.x <= pane.centre[1] + pane.size[1] / 2):toBe(true)
			end
			local clumpsByRow = {}
			for _, clump in ipairs(clumps) do
				clumpsByTerrace[clump.terrace] = (clumpsByTerrace[clump.terrace] or 0) + 1
				expect(clump.blades >= 3 and clump.blades <= 5):toBe(true)
				expect(clump.y > 0):toBe(true)
				clumpsByRow[clump.row] = clumpsByRow[clump.row] or {}
				table.insert(clumpsByRow[clump.row], clump)
				local row = rows[clump.row]
				expect(row ~= nil):toBe(true)
				expect(clump.z >= row.z0 and clump.z <= row.z1):toBe(true)
				expect(near(clump.x, row.x)):toBe(true)
			end
			for _, index in ipairs(terraces) do
				expect((rowsByTerrace[index] or 0) >= Data.PADI_ROWS_MIN):toBe(true)
				expect((clumpsByTerrace[index] or 0) >= Data.PADI_CLUMPS_MIN):toBe(true)
			end
			for _, list in pairs(rowsByPane) do
				table.sort(list, function(a, b)
					return a.x < b.x
				end)
				for index = 2, #list do
					expect(near(list[index].x - list[index - 1].x, Data.ROW_SPACING)):toBe(true)
				end
			end
			for _, list in pairs(clumpsByRow) do
				table.sort(list, function(a, b)
					return a.z < b.z
				end)
				for index = 2, #list do
					expect(near(list[index].z - list[index - 1].z, Data.ROW_SPACING)):toBe(true)
				end
			end
			local widest = 0
			for _, blade in ipairs(Data.PADI_BLADES) do
				widest = math.max(widest, math.abs(blade.dx))
				expect(blade.height > 0 and blade.height <= Data.PADI_MAX_PART):toBe(true)
			end
			expect(widest * 2 + Data.PADI_BLADE_WIDTH <= Data.PADI_CLUMP_WIDTH):toBe(true)
			local other = Env.new():require("shared/ModelMapSawahR8")
			expect(other.padiRows(panes)):toEqual(rows)
			expect(other.padiClumps(panes)):toEqual(clumps)
			expect(Data.waterPanes(panes, 1)[1].size[3] > Data.PADI_CLUMP_WIDTH):toBe(true)
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
			expect(#LookDev.IDS):toBe(72)
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

		t:it("tags every padi part and keeps the applier reversible", function()
			local applier = fs.readFile("src/server/World/LookDevSawahR8.luau")
			expect(string.find(applier, "Data.padiClumps(panes)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PadiPart", true)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("TerraceIndex", clump.terrace)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PadiClump", clump.id)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PadiRow", clump.row)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("TerraceIndex", tuft.terrace)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "Data.PADI_BLADE_WIDTH", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
		end)

		t:it("registers the four item-140 checks in ORDER with their targets", function()
			local harness = fs.readFile("tools/studio/review_check_r8.luau")
			local start = string.find(harness, "local ORDER = {", 1, true)
			expect(start ~= nil):toBe(true)
			local finish = string.find(harness, "\n}", start, true)
			expect(finish ~= nil):toBe(true)
			local order = string.sub(harness, start, finish)
			local gubuk = string.find(order, '"GUBUK"', 1, true)
			local river = string.find(order, '"RIVER_BANK_VEG"', 1, true)
			expect(gubuk ~= nil and river ~= nil):toBe(true)
			local previous = gubuk
			for _, name in ipairs({ "TUFT_SHAPE", "PADI_ROWS", "PADI_CLUMPS", "SAWAH_GREEN" }) do
				local at = string.find(order, '"' .. name .. '"', 1, true)
				expect(at ~= nil):toBe(true)
				expect(at > previous and at < river):toBe(true)
				previous = at
			end
			local function emitTarget(name, target)
				local at = string.find(harness, 'emit("' .. name .. '"', 1, true)
				expect(at ~= nil):toBe(true)
				local compact = string.gsub(string.sub(harness, at, at + 300), "%s", "")
				expect(string.find(compact, "," .. target .. ",", 1, true) ~= nil):toBe(true)
			end
			emitTarget("TUFT_SHAPE", "0")
			emitTarget("PADI_ROWS", "10")
			emitTarget("PADI_CLUMPS", "250")
			emitTarget("SAWAH_GREEN", "40")

			local blockStart = string.find(harness, "-- 9d-2. WORK_QUEUE section O item 140", 1, true)
			local blockEnd = string.find(harness, "-- 9e. r8 river family", blockStart, true)
			expect(blockStart ~= nil and blockEnd ~= nil):toBe(true)
			local block = string.sub(harness, blockStart, blockEnd)
			expect(string.find(block, "enable(", 1, true) == nil):toBe(true)
			expect(string.find(block, "sawah_above", 1, true) ~= nil):toBe(true)
			expect(string.find(block, "workspace:Raycast", 1, true) ~= nil):toBe(true)
			expect(string.find(block, 'attr(hit.Instance, "PadiPart") == true', 1, true) ~= nil):toBe(true)
			expect(string.find(block, 'part:IsA("BasePart")', 1, true) ~= nil):toBe(true)
			expect(string.find(block, '"PadiClump"', 1, true) ~= nil):toBe(true)
			expect(string.find(block, '"PadiRow"', 1, true) ~= nil):toBe(true)
		end)
	end)
end
