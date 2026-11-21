--!nocheck
-- WORK_QUEUE section M item 71: plots_r8 plot fences and gates. Pure-data contract plus the
-- server LookDev wiring. No Studio claim: CHECK_71.txt and the visual verdict belong to the main
-- session. The applier uses procedural Parts only, so there are no asset IDs to validate.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPlotsR8")
	local Game = env:require("shared/Config/Game")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local segments = Data.fenceLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH, Data.OVERLAP)
	local gateParts = Data.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)
	local box = Data.gateBox()

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	local function lines(list)
		local groups = {}
		for _, segment in ipairs(list) do
			local fixed = if segment.axis == "x" then segment.lz else segment.lx
			local key = segment.axis .. ":" .. tostring(fixed)
			groups[key] = groups[key] or {}
			table.insert(groups[key], segment)
		end
		return groups
	end

	t:describe("plots_r8 fence and gate data", function()
		t:it("covers all ten plots with a stable staging name", function()
			expect(Data.id):toBe("plots_r8")
			expect(Data.folderName):toBe("LookDevPlotsR8_plots_r8")
			expect(Data.PLOT_COUNT):toBe(Game.plotCount)
			expect(Data.PLOT_COUNT):toBe(10)
			expect(Data.plotIndices()):toEqual({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
			expect(Data.PLOT_WIDTH):toBe(Game.tileColumns * 7.5 + 4)
			expect(Data.PLOT_DEPTH):toBe(math.ceil(Game.tilesBuilt / Game.tileColumns) * 7.5 + 4)
			expect(Data.GAP_WIDTH):toBe(6)
			expect(Data.GATE_HEIGHT):toBe(8)
			expect(Data.MIN_SEGMENTS):toBe(6)
			expect(Data.OVERLAP):toBe(0.2)
		end)

		t:it("builds at least six segments per plot with exactly 0.2 overlap between neighbours", function()
			expect(#segments >= Data.MIN_SEGMENTS):toBe(true)
			expect(#segments):toBe(8)
			local groups = lines(segments)
			local innerZ = -Data.PLOT_DEPTH / 2
			local groupsSeen = 0
			for key, group in pairs(groups) do
				groupsSeen += 1
				expect(#group):toBe(2)
				table.sort(group, function(a, b)
					return (if a.axis == "x" then a.lx else a.lz) < (if b.axis == "x" then b.lx else b.lz)
				end)
				local a, b = group[1], group[2]
				local aEnd = (if a.axis == "x" then a.lx else a.lz) + a.length / 2
				local bStart = (if b.axis == "x" then b.lx else b.lz) - b.length / 2
				if key == "x:" .. tostring(innerZ) then
					-- Inner edge: the only non-overlapping neighbours, separated by the gate gap.
					expect(near(bStart - aEnd, Data.GAP_WIDTH)):toBe(true)
					expect(near((aEnd + bStart) / 2, 0)):toBe(true)
				else
					expect(near(aEnd - bStart, Data.OVERLAP)):toBe(true)
				end
				expect(near(a.lx, b.lx) and near(a.lz, b.lz)):toBe(false) -- no stacked coplanar parts
				expect(a.thickness ~= b.thickness):toBe(true)
			end
			expect(groupsSeen):toBe(4)
		end)

		t:it("centres the six-wide gap on the inner (-Z) edge only", function()
			local inner = {}
			for _, segment in ipairs(segments) do
				if near(segment.lz, -Data.PLOT_DEPTH / 2) and segment.axis == "x" then
					inner[#inner + 1] = segment
				end
			end
			expect(#inner):toBe(2)
			table.sort(inner, function(a, b)
				return a.lx < b.lx
			end)
			local leftEnd = inner[1].lx + inner[1].length / 2
			local rightStart = inner[2].lx - inner[2].length / 2
			expect(near(leftEnd, -Data.GAP_WIDTH / 2)):toBe(true)
			expect(near(rightStart, Data.GAP_WIDTH / 2)):toBe(true)
			expect(near((leftEnd + rightStart) / 2, 0)):toBe(true)
			for _, segment in ipairs(segments) do
				if segment.axis == "z" then
					expect(near(segment.lx, -Data.PLOT_WIDTH / 2) or near(segment.lx, Data.PLOT_WIDTH / 2)):toBe(true)
				end
			end
		end)

		t:it("keeps gate posts outside the 6x8x1 box and the lintel above y=8", function()
			expect(box):toEqual({ width = 6, height = 8, depth = 1 })
			expect(#gateParts):toBe(3)
			local posts, lintel = 0, nil
			for _, part in ipairs(gateParts) do
				if part.kind == "gate_post" then
					posts += 1
					expect(math.abs(part.lx) - part.thickness / 2 >= box.width / 2):toBe(true)
					expect(part.lz):toBe(0)
				elseif part.kind == "gate_lintel" then
					lintel = part
				end
			end
			expect(posts):toBe(2)
			expect(lintel ~= nil):toBe(true)
			expect(lintel.ly - lintel.thickness / 2 >= box.height):toBe(true)
			expect(lintel.lx):toBe(0)
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapPlotsR8")
			expect(other.fenceLayout(Data.PLOT_WIDTH, Data.PLOT_DEPTH, Data.GAP_WIDTH, Data.OVERLAP)):toEqual(segments)
			expect(other.gateParts(Data.GAP_WIDTH, Data.GATE_HEIGHT)):toEqual(gateParts)
			expect(other.gateBox()):toEqual(box)
			expect(other.plotIndices()):toEqual(Data.plotIndices())

			local src = fs.readFile("src/shared/ModelMapPlotsR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("plots_r8 server LookDev wiring", function()
		t:it("registers candidate 48 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(58)
			expect(LookDev.IDS[48]):toBe("plots_r8")
			expect(LookDev.candidates.plots_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.plots_r8.idsSource):toBe("Shared.ModelMapPlotsR8")
			local plan = LookDev.plan("plots_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("plots_r8")
			expect(Review.paths.plots_r8.datamodel):toBe("server")
			expect(Review.paths.plots_r8.path):toEqual({ "World", "LookDevPlotsR8" })
		end)

		t:it("stages tagged non-collidable parts and restores only its own folder", function()
			local applier = fs.readFile("src/server/World/LookDevPlotsR8.luau")
			expect(string.find(applier, "PROCEDURAL PARTS, NO ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevPlotsR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PlotIndex", index)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'GateMarker_" .. index', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "marker.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "GetAttribute", 1, true) == nil):toBe(true)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(string.find(main, "pcall(require, script.Parent.World.LookDevPlotsR8)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
