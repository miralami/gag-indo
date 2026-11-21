--!nocheck
-- WORK_QUEUE section M item 75, redone in section O item 142: pathedge_r8 dirt-path edge dressing.
-- Pure-data contract, the read-only harness check and the server LookDev wiring. No Studio claim:
-- CHECK_75.txt / CHECK_142.txt and the visual verdict belong to the main session. The only asset ID
-- is read from Shared.ModelMapVegetationR6; the applier never writes an ID literal.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPathEdgeR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")

	local arms = MapSpec.roadArms()
	local ring = MapSpec.ringSegments()
	local continuations = MapSpec.roadContinuations()
	local road = MapSpec.ROAD
	local ringHalf = road.ringWidth / 2
	local pieces = Data.allPieces(arms, ring, continuations, road)

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	t:describe("pathedge_r8 path-edge data", function()
		t:it("uses a stable staging name and spacing contract", function()
			expect(Data.id):toBe("pathedge_r8")
			expect(Data.folderName):toBe("LookDevPathEdgeR8_pathedge_r8")
			expect(Data.MIN_EDGE_PIECES):toBe(120)
			expect(Data.PUDDLE_TRANSPARENCY):toBe(0.4)
			expect(Data.CENTRAL_CLEAR):toBe(6)
			expect(Data.SPACING_MIN):toBe(3)
			expect(Data.SPACING_MAX):toBe(5)
			-- item 142 constants: offset band, check band and clump width ceiling.
			expect(Data.PATH_OFFSET_MIN):toBe(0.3)
			expect(Data.PATH_OFFSET_MAX):toBe(2.5)
			expect(Data.PATH_EDGE_GROW):toBe(3)
			expect(Data.CLUMP_MAX_WIDTH):toBe(1.5)
		end)

		t:it("places at least 120 deterministic pieces on both sides of every path", function()
			expect(#pieces >= Data.MIN_EDGE_PIECES):toBe(true)
			local paths, sides, kinds, puddles = {}, {}, {}, 0
			for _, piece in ipairs(pieces) do
				expect(piece.side == "-1" or piece.side == "1"):toBe(true)
				expect(type(piece.centre) == "table" and #piece.centre == 2):toBe(true)
				expect(type(piece.halfWidth) == "number" and piece.halfWidth > 0):toBe(true)
				expect(piece.lateral == piece.offset):toBe(true)
				expect(math.abs(piece.lateral) >= piece.halfWidth + Data.PATH_OFFSET_MIN - 1e-9):toBe(true)
				expect(math.abs(piece.lateral) <= piece.halfWidth + Data.PATH_OFFSET_MAX + 1e-9):toBe(true)
				paths[piece.path] = true
				sides[piece.side] = true
				kinds[piece.kind] = (kinds[piece.kind] or 0) + 1
				if piece.kind == "puddle" then
					puddles += 1
				end
			end
			expect(sides["-1"]):toBe(true)
			expect(sides["1"]):toBe(true)
			expect(puddles > 0):toBe(true)
			expect(kinds.grass_tuft > 0 and kinds.pebble > 0):toBe(true)
			for _, arm in ipairs(arms) do
				expect(paths[arm.name]):toBe(true)
			end
			for _, continuation in ipairs(continuations) do
				expect(paths[continuation.name]):toBe(true)
			end
			expect(paths.RingRoad):toBe(true)
			local other = Env.new():require("shared/ModelMapPathEdgeR8")
			expect(other.allPieces(arms, ring, continuations, road)):toEqual(pieces)
		end)

		t:it("keeps every piece outside the central clear band of its own path", function()
			local byPath = {}
			for _, arm in ipairs(arms) do
				byPath[arm.name] = arm
			end
			for _, continuation in ipairs(continuations) do
				byPath[continuation.name] = continuation
			end
			for _, piece in ipairs(pieces) do
				local path = byPath[piece.path]
				if path then
					local perpendicular = if path.sx > path.sz
						then math.abs(piece.z - path.z)
						else math.abs(piece.x - path.x)
					expect(near(perpendicular, math.abs(piece.lateral))):toBe(true)
					expect(perpendicular >= Data.CENTRAL_CLEAR / 2):toBe(true)
				end
			end
			-- Rotated ring: local +Z (sin yaw, cos yaw) is the perpendicular edge normal.
			for index, segment in ipairs(ring) do
				local yaw = math.rad(segment.yaw)
				local nx, nz = math.sin(yaw), math.cos(yaw)
				for _, piece in ipairs(Data.ringPieces(segment, 7, ringHalf, index)) do
					local perpendicular = (piece.x - segment.x) * nx + (piece.z - segment.z) * nz
					local centrePerpendicular = (piece.centre[1] - segment.x) * nx + (piece.centre[2] - segment.z) * nz
					expect(near(perpendicular, piece.lateral)):toBe(true)
					expect(near(centrePerpendicular, 0)):toBe(true)
					expect(math.abs(perpendicular) >= Data.CENTRAL_CLEAR / 2):toBe(true)
				end
			end
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapPathEdgeR8")
			expect(other.armPieces(arms[1], 17)):toEqual(Data.armPieces(arms[1], 17))
			expect(other.ringPieces(ring[1], 7, ringHalf, 1)):toEqual(Data.ringPieces(ring[1], 7, ringHalf, 1))
			local src = fs.readFile("src/shared/ModelMapPathEdgeR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
			for _, constant in ipairs({ "PATH_OFFSET_MIN", "PATH_OFFSET_MAX", "PATH_EDGE_GROW", "CLUMP_MAX_WIDTH" }) do
				expect(string.find(src, constant, 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("item 142: every lateral sits in the edge band, both sides and spacing hold", function()
			local sides, minExtra, maxExtra = { ["-1"] = 0, ["1"] = 0 }, math.huge, -math.huge
			local grassMin, grassMax = math.huge, -math.huge
			local bySegmentSide = {}
			for _, piece in ipairs(pieces) do
				local extra = math.abs(piece.lateral) - piece.halfWidth
				expect(extra >= Data.PATH_OFFSET_MIN - 1e-9):toBe(true)
				expect(extra <= Data.PATH_OFFSET_MAX + 1e-9):toBe(true)
				expect(extra <= Data.PATH_EDGE_GROW):toBe(true)
				expect(math.abs(piece.lateral) >= piece.halfWidth):toBe(true)
				expect(math.abs(piece.lateral) <= piece.halfWidth + Data.PATH_EDGE_GROW):toBe(true)
				expect(sides[piece.side] ~= nil):toBe(true)
				sides[piece.side] += 1
				minExtra, maxExtra = math.min(minExtra, extra), math.max(maxExtra, extra)
				if piece.kind == "grass_tuft" then
					-- Inner edge of a <=1.5-wide clump reaches the road edge.
					expect(extra <= Data.CLUMP_MAX_WIDTH / 2 + 1e-9):toBe(true)
					grassMin, grassMax = math.min(grassMin, extra), math.max(grassMax, extra)
				end
				local key = tostring(piece.segment) .. "/" .. piece.side
				bySegmentSide[key] = bySegmentSide[key] or {}
				table.insert(bySegmentSide[key], piece.along)
			end
			expect(#pieces >= 120):toBe(true)
			expect(sides["-1"] > 0 and sides["1"] > 0):toBe(true)
			expect(minExtra >= Data.PATH_OFFSET_MIN - 1e-9):toBe(true)
			expect(maxExtra <= Data.PATH_OFFSET_MAX + 1e-9):toBe(true)
			expect(grassMin <= Data.CLUMP_MAX_WIDTH / 2):toBe(true)
			local groups = 0
			for _, alongs in pairs(bySegmentSide) do
				groups += 1
				table.sort(alongs)
				for i = 2, #alongs do
					expect(alongs[i] - alongs[i - 1] >= Data.SPACING_MIN - 1e-9):toBe(true)
				end
			end
			expect(groups > 0):toBe(true)
		end)
	end)

	t:describe("pathedge_r8 server LookDev wiring", function()
		t:it("registers candidate 51 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(79)
			expect(LookDev.IDS[51]):toBe("pathedge_r8")
			expect(LookDev.candidates.pathedge_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.pathedge_r8.idsSource):toBe("Shared.ModelMapPathEdgeR8")
			local plan = LookDev.plan("pathedge_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("pathedge_r8")
			expect(Review.paths.pathedge_r8.datamodel):toBe("server")
			expect(Review.paths.pathedge_r8.path):toEqual({ "World", "LookDevPathEdgeR8" })
		end)

		t:it("stages tagged non-collidable parts and restores only its own folder", function()
			local applier = fs.readFile("src/server/World/LookDevPathEdgeR8.luau")
			expect(string.find(applier, "NO INVENTED ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "VegR6.ids.alang_alang", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevAssetLoader.get(GRASS_ASSET_ID, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "Data.CLUMP_MAX_WIDTH", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.roadArms()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.ringSegments()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.roadContinuations()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "Data.allPieces(arms, ring, continuations, MapSpec.ROAD)", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(applier, 'SetAttribute("LookDevPathEdgeR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("PathEdgePart", true)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Lateral", piece.lateral)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("HalfWidth", piece.halfWidth)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("CentreX", piece.centre[1])', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("CentreZ", piece.centre[2])', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", piece.kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Path", piece.path)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", piece.side)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(string.find(main, "pcall(require, script.Parent.World.LookDevPathEdgeR8)", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("item 142: PATH_EDGE_OFFSET is read-only, ordered beside PATH_CLEAR with target 0", function()
			local harness = fs.readFile("tools/studio/review_check_r8.luau")
			local start = string.find(harness, "local ORDER = {", 1, true)
			expect(start ~= nil):toBe(true)
			local finish = string.find(harness, "\n}", start, true)
			expect(finish ~= nil):toBe(true)
			local order = string.sub(harness, start, finish)
			local edge = string.find(order, '"PATH_EDGE"', 1, true)
			local clear = string.find(order, '"PATH_CLEAR"', 1, true)
			local offset = string.find(order, '"PATH_EDGE_OFFSET"', 1, true)
			expect(edge ~= nil and clear ~= nil and offset ~= nil):toBe(true)
			expect(edge < clear and clear < offset):toBe(true)

			local emitAt = string.find(harness, 'emit("PATH_EDGE_OFFSET"', 1, true)
			expect(emitAt ~= nil):toBe(true)
			local compact = string.gsub(string.sub(harness, emitAt, emitAt + 200), "%s", "")
			expect(string.find(compact, ",0,", 1, true) ~= nil):toBe(true)
			expect(string.find(harness, "local PATH_EDGE_GROW = 3", 1, true) ~= nil):toBe(true)

			local blockStart = string.find(harness, "-- 9f-2. WORK_QUEUE section O item 142: PATH_EDGE_OFFSET", 1, true)
			local blockEnd = string.find(harness, "-- 9g. r8 buildings family", blockStart, true)
			expect(blockStart ~= nil and blockEnd ~= nil):toBe(true)
			local block = string.sub(harness, blockStart, blockEnd)
			expect(string.find(block, "enable(", 1, true) == nil):toBe(true)
			expect(string.find(block, "PathEdgePart", 1, true) ~= nil):toBe(true)
			for _, key in ipairs({ "Lateral", "HalfWidth", "CentreX", "CentreZ" }) do
				expect(string.find(block, '"' .. key .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(block, "nearestPathCentreDistance", 1, true) ~= nil):toBe(true)
			expect(string.find(block, "offsetOffenders", 1, true) ~= nil):toBe(true)
		end)
	end)
end
