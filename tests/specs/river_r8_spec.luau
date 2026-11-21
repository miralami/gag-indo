--!nocheck
-- WORK_QUEUE section M item 73: river_r8 river banks and bridge dressing. Pure-data contract plus
-- the server LookDev wiring. No Studio claim: CHECK_73.txt and the visual verdict belong to the
-- main session. The applier uses procedural Parts only, so there are no asset IDs to validate.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapRiverR8")
	local MapSpec = env:require("server/World/MapSpec")
	local LookDev = env:require("shared/LookDev")
	local Review = env:require("shared/LookDevReview")
	local veg = Data.bankVeg(Data.RIVER_CENTRE, -48, 48, 2)
	local rails = Data.railLayout()
	local stones = Data.steppingStones()

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	t:describe("river_r8 river-bank data", function()
		t:it("uses a stable staging name and mirrors the real river centreline", function()
			expect(Data.id):toBe("river_r8")
			expect(Data.folderName):toBe("LookDevRiverR8_river_r8")
			expect(Data.MIN_BANK_VEG):toBe(30)
			expect(Data.BRIDGE_WIDTH):toBe(10)
			expect(Data.WALKABLE_MIN):toBe(8)
			expect(Data.BRIDGE_Z0):toBe(276)
			expect(Data.BRIDGE_Z1):toBe(332)
			expect(Data.BRIDGE_CENTRE_Z):toBe(304)
			expect(Data.BANK_OFFSET):toBe(18)
			for _, x in ipairs({ -80, -40, 0, 40, 80 }) do
				expect(near(Data.RIVER_CENTRE(x), MapSpec.riverCentreZ(x))):toBe(true)
			end
		end)

		t:it("places deterministic vegetation on both banks, at least 30 near the bridge", function()
			expect(#veg >= Data.MIN_BANK_VEG):toBe(true)
			local south, north, nearBridge, speciesCount = 0, 0, 0, 0
			local seenSpecies = {}
			for _, v in ipairs(veg) do
				local sign = if v.Side == "south" then -1 else 1
				expect(v.Side == "south" or v.Side == "north"):toBe(true)
				expect(near(v.z, Data.RIVER_CENTRE(v.x) + sign * Data.BANK_OFFSET)):toBe(true)
				expect(v.VegX):toBe(v.x)
				expect(v.VegZ):toBe(v.z)
				if v.Side == "south" then
					south += 1
				else
					north += 1
				end
				if not seenSpecies[v.Species] then
					seenSpecies[v.Species] = true
					speciesCount += 1
				end
				local dz = v.z - Data.BRIDGE_CENTRE_Z
				if math.sqrt(v.x * v.x + dz * dz) <= 40 then
					nearBridge += 1
				end
			end
			expect(south > 0 and north > 0):toBe(true)
			expect(nearBridge >= Data.MIN_BANK_VEG):toBe(true)
			expect(speciesCount):toBe(#Data.VEG_KINDS)
			local other = Env.new():require("shared/ModelMapRiverR8")
			expect(other.bankVeg(Data.RIVER_CENTRE, -48, 48, 2)):toEqual(veg)
		end)

		t:it("keeps an 8-stud clear corridor between the two side rails", function()
			expect(Data.bridgeSides()):toEqual({ -1, 1 })
			expect(#rails):toBe(2)
			local sides = {}
			for _, rail in ipairs(rails) do
				sides[rail.Side] = true
				expect(near(rail.z0, Data.BRIDGE_Z0)):toBe(true)
				expect(near(rail.z1, Data.BRIDGE_Z1)):toBe(true)
				-- Inner face = |x| - thickness/2, so both sides leave >= 8 studs walkable.
				expect(math.abs(rail.x) - rail.thickness / 2 >= Data.WALKABLE_MIN / 2):toBe(true)
				expect(#rail.postZs > 0):toBe(true)
				for _, z in ipairs(rail.postZs) do
					expect(z >= rail.z0 and z <= rail.z1):toBe(true)
				end
			end
			expect(sides.left):toBe(true)
			expect(sides.right):toBe(true)
			expect(Env.new():require("shared/ModelMapRiverR8").railLayout()):toEqual(rails)
		end)

		t:it("stages exactly six stones on the banks, clear of deck and channel", function()
			expect(#stones):toBe(6)
			local banks = {}
			for _, stone in ipairs(stones) do
				banks[stone.Side] = true
				expect(math.abs(stone.x) > Data.BRIDGE_WIDTH / 2):toBe(true)
				expect(math.abs(stone.z - Data.RIVER_CENTRE(stone.x)) > 14):toBe(true)
				expect(stone.y > 0 and stone.size[2] > 0):toBe(true)
			end
			expect(banks.south):toBe(true)
			expect(banks.north):toBe(true)
			expect(Env.new():require("shared/ModelMapRiverR8").steppingStones()):toEqual(stones)
		end)

		t:it("is deterministic and free of Roblox APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapRiverR8")
			expect(other.bankVeg(MapSpec.riverCentreZ, -48, 48, 2)):toEqual(
				Data.bankVeg(MapSpec.riverCentreZ, -48, 48, 2)
			)
			expect(other.RIVER_CENTRE(37)):toBe(Data.RIVER_CENTRE(37))
			expect(#other.steppingStones()):toBe(#stones)
			local src = fs.readFile("src/shared/ModelMapRiverR8.luau")
			expect(string.find(src, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			expect(string.find(src, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(src, "Enum.", 1, true) ~= nil):toBe(false)
		end)
	end)

	t:describe("river_r8 server LookDev wiring", function()
		t:it("registers candidate 50 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(56)
			expect(LookDev.IDS[50]):toBe("river_r8")
			expect(LookDev.candidates.river_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.river_r8.idsSource):toBe("Shared.ModelMapRiverR8")
			local plan = LookDev.plan("river_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("river_r8")
			expect(Review.paths.river_r8.datamodel):toBe("server")
			expect(Review.paths.river_r8.path):toEqual({ "World", "LookDevRiverR8" })
		end)

		t:it("stages tagged non-collidable parts and restores only its own folder", function()
			local applier = fs.readFile("src/server/World/LookDevRiverR8.luau")
			expect(string.find(applier, "PROCEDURAL PARTS, NO ASSET IDS", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "MapSpec.riverCentreZ", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("LookDevRiverR8", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Kind", kind)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", veg.Side)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Species", veg.Species)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("VegX", veg.VegX)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("VegZ", veg.VegZ)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", rail.Side)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'SetAttribute("Side", stone.Side)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, '"BankVeg_river_r8"', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, '"BridgeRails_river_r8"', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, '"SteppingStones_river_r8"', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevFailures).set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "activeFolder:Destroy()", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
			local main = fs.readFile("src/server/Main.server.luau")
			expect(string.find(main, "pcall(require, script.Parent.World.LookDevRiverR8)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
