--!nocheck
-- WORK_QUEUE section M item 75: pathedge_r8 dirt-path edge dressing. Pure-data contract plus the
-- server LookDev wiring. No Studio claim: CHECK_75.txt and the visual verdict belong to the main
-- session. The applier uses procedural Parts only, so there are no asset IDs to validate.

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
	local pieces = Data.allPieces(arms, ring, continuations)

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
		end)

		t:it("places at least 120 deterministic pieces on both sides of every path", function()
			expect(#pieces >= Data.MIN_EDGE_PIECES):toBe(true)
			local paths, sides, kinds, puddles = {}, {}, {}, 0
			for _, piece in ipairs(pieces) do
				expect(piece.side == "-1" or piece.side == "1"):toBe(true)
				expect(math.abs(piece.offset) >= Data.CENTRAL_CLEAR / 2):toBe(true)
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
			expect(other.allPieces(arms, ring, continuations)):toEqual(pieces)
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
					expect(near(perpendicular, math.abs(piece.offset))):toBe(true)
					expect(perpendicular >= Data.CENTRAL_CLEAR / 2):toBe(true)
				end
			end
			-- Rotated ring: local +Z (sin yaw, cos yaw) is the perpendicular edge normal.
			for _, segment in ipairs(ring) do
				for _, piece in ipairs(Data.ringPieces(segment, 7)) do
					local yaw = math.rad(segment.yaw)
					local perpendicular =
						math.abs((piece.x - segment.x) * math.sin(yaw) + (piece.z - segment.z) * math.cos(yaw))
					expect(near(perpendicular, math.abs(piece.offset))):toBe(true)
					expect(perpendicular >= Data.CENTRAL_CLEAR / 2):toBe(true)
				end
			end
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapPathEdgeR8")
			expect(other.armPieces(arms[1], 17)):toEqual(Data.armPieces(arms[1], 17))
			expect(other.ringPieces(ring[1], 7)):toEqual(Data.ringPieces(ring[1], 7))
			local src = fs.readFile("src/shared/ModelMapPathEdgeR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("pathedge_r8 server LookDev wiring", function()
		t:it("registers candidate 51 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(55)
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
			expect(string.find(applier, "PROCEDURAL PARTS, NO ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.roadArms()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.ringSegments()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.roadContinuations()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevPathEdgeR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Path", path)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", side)', 1, true) ~= nil):toBe(true)
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
	end)
end
