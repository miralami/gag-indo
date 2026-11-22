--!nocheck
-- WORK_QUEUE section P item 175 (UNREGISTERED). Two-tier plaza fountain, paved ring, inward
-- benches and one flat red-over-white flag pair per bunting flag. No Studio claim: the live
-- geometry proof is tools/studio/check_p175.luau and its CHECK evidence belongs to the main session.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPlazaR9")
	local applierSrc = fs.readFile("src/server/World/LookDevPlazaR9.luau")

	local function try(fn, fallback)
		local ok, value = pcall(fn)
		if ok then
			return value
		end
		return fallback
	end

	local fountain = Data.fountain()
	local tiers = try(function()
		return Data.fountainTiers()
	end, {})
	local panelsPerFlag = try(function()
		return Data.flagPanels(Data.bunting().flags[1])
	end, {})
	local panelSize = try(function()
		return Data.flagPanelSize()
	end, {})
	local paving = try(function()
		return Data.paving()
	end, {})
	local benches = Data.benches()
	local lanes = Data.lanes()

	local function box(x, z, halfX, halfZ)
		return { minX = x - halfX, maxX = x + halfX, minZ = z - halfZ, maxZ = z + halfZ }
	end

	local function overlaps(a, b)
		return math.min(a.maxX, b.maxX) > math.max(a.minX, b.minX)
			and math.min(a.maxZ, b.maxZ) > math.max(a.minZ, b.minZ)
	end

	t:describe("plaza_r9 item 175 fountain", function()
		t:it("has a basin at least 14 studs across and exactly two tiers", function()
			expect(Data.FOUNTAIN.basinSize[1] >= 14):toBe(true)
			expect(Data.FOUNTAIN.basinSize[3] >= 14):toBe(true)
			expect(fountain.basinDiameter >= 14):toBe(true)
			expect(Data.FOUNTAIN.tierCount):toBe(2)
			expect(fountain.tierCount):toBe(2)
			expect(#tiers):toBe(2)
			expect(tiers[1].size[1] >= 14):toBe(true)
			expect(tiers[2].size[1] < tiers[1].size[1]):toBe(true)
			expect(tiers[2].y > tiers[1].y):toBe(true)
		end)

		t:it("uses a thin vertical non-Neon water column and a four-strip paved ring", function()
			expect(Data.FOUNTAIN.spoutSize[2] > Data.FOUNTAIN.spoutSize[1] * 3):toBe(true)
			expect(Data.MATERIALS[Data.FOUNTAIN.spoutMaterial]):toBe("SmoothPlastic")
			expect(applierSrc:find("Enum.Material.Neon", 1, true) == nil):toBe(true)
			expect(#paving):toBe(4)
			expect(fountain.ringRadius >= Data.FOUNTAIN.basinSize[1] / 2):toBe(true)
			for _, tile in ipairs(paving) do
				expect(tile.size[2] < 0.5):toBe(true)
			end
			expect(applierSrc:find("Data.fountainTierAttribute, tier.index", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.pavingAttribute, true", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("plaza_r9 item 175 flags and benches", function()
		t:it("stages every flag as one flat red-over-white part pair with no crossing", function()
			expect(#Data.bunting().flags >= 6):toBe(true)
			expect(#panelsPerFlag):toBe(2)
			expect(panelsPerFlag[1].colour):toBe("red")
			expect(panelsPerFlag[2].colour):toBe("white")
			expect(panelsPerFlag[1].yOffset > panelsPerFlag[2].yOffset):toBe(true)
			expect(panelSize[3] < panelSize[1]):toBe(true)
			expect(panelSize[3] < panelSize[2]):toBe(true)
			expect(applierSrc:find("Data.flagPairAttribute, flag.name", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.flagPanelAttribute, panel.colour", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.flagPanelSize()", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps four benches and aims each one at the fountain", function()
			expect(#benches):toBe(4)
			for _, bench in ipairs(benches) do
				local frontX, frontZ = math.sin(math.rad(bench.yaw)), math.cos(math.rad(bench.yaw))
				local toX, toZ = fountain.x - bench.x, fountain.z - bench.z
				local length = math.sqrt(toX * toX + toZ * toZ)
				expect((frontX * toX + frontZ * toZ) / length > 0.99):toBe(true)
			end
		end)
	end)

	t:describe("plaza_r9 item 175 walkable lanes", function()
		t:it("runs a 6-stud lane from each road to the fountain ring without dressing overlap", function()
			expect(#lanes):toBe(4)
			local names = {}
			for _, lane in ipairs(lanes) do
				expect(names[lane.name]):toBe(nil)
				names[lane.name] = true
				expect(lane.width == 6 or lane.depth == 6):toBe(true)
				local inner = if lane.name == "east" or lane.name == "west"
					then math.abs(lane.x) - lane.width / 2
					else math.abs(lane.z) - lane.depth / 2
				expect(inner <= fountain.ringRadius + Data.LANE_GAP + 1e-6):toBe(true)
				local rect = box(lane.x, lane.z, lane.width / 2, lane.depth / 2)
				expect(
					overlaps(
						box(fountain.x, fountain.z, Data.FOUNTAIN.basinSize[1] / 2, Data.FOUNTAIN.basinSize[3] / 2),
						rect
					)
				):toBe(false)
				for _, tile in ipairs(paving) do
					expect(overlaps(box(tile.x, tile.z, tile.size[1] / 2, tile.size[3] / 2), rect)):toBe(false)
				end
				for _, bench in ipairs(benches) do
					expect(overlaps(box(bench.x, bench.z, bench.size[1] / 2, bench.size[2] / 2), rect)):toBe(false)
				end
				for _, umbrella in ipairs(Data.umbrellas()) do
					expect(overlaps(box(umbrella.x, umbrella.z, 2.6, 2.6), rect)):toBe(false)
				end
				for _, pole in ipairs(Data.bunting().poles) do
					expect(overlaps(box(pole.x, pole.z, 0.5, 0.5), rect)):toBe(false)
				end
				expect(overlaps(box(Data.shadeTree().x, Data.shadeTree().z, 3.5, 3.5), rect)):toBe(false)
			end
			expect(names.north and names.south and names.east and names.west):toBe(true)
		end)
	end)
end
