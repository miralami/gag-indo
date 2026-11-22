--!nocheck
-- WORK_QUEUE section P item 175 (UNREGISTERED), fountain rebuilt by item 188. Baked Creator Store
-- fountain at a 16-stud basin, paved ring, inward benches and one flat red-over-white flag pair per
-- bunting flag. No Studio claim: live CHECK evidence belongs to the main session.

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

	t:describe("plaza_r9 item 188 baked fountain", function()
		t:it("uses the real baked asset scaled to a 16-stud basin inside [14,18]", function()
			expect(Data.FOUNTAIN_ASSET_ID):toBe(93434732057582)
			expect(Data.FOUNTAIN_BASIN_MIN):toBe(14)
			expect(Data.FOUNTAIN_BASIN_MAX):toBe(18)
			expect(fountain.basinDiameter):toBe(16)
			expect(fountain.basinDiameter >= Data.FOUNTAIN_BASIN_MIN):toBe(true)
			expect(fountain.basinDiameter <= Data.FOUNTAIN_BASIN_MAX):toBe(true)
			expect(fountain.x):toBe(0)
			expect(fountain.z):toBe(0)
			expect(fountain.ringRadius):toBe(Data.RING_RADIUS)
			expect(#tiers):toBe(2) -- data kept for compatibility; no Parts are built from it
			expect(applierSrc:find("LookDevAssetLoader.get(Data.FOUNTAIN_ASSET_ID, Data.familyId)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("GetBoundingBox()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ScaleTo(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("PivotTo(CFrame.new(x, groundY(), z))", 1, true) ~= nil):toBe(true)
		end)

		t:it("tags baked water for the R8 check and keeps a four-strip paved ring", function()
			expect(applierSrc:find("Data.waterAttribute, true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Data.waterColourAttribute, recipe.waterColour", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Material.Neon", 1, true) == nil):toBe(true)
			expect(#paving):toBe(4)
			expect(fountain.ringRadius >= Data.FOUNTAIN.basinDiameter / 2):toBe(true)
			for _, tile in ipairs(paving) do
				expect(tile.size[2] < 0.5):toBe(true)
			end
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
					overlaps(box(fountain.x, fountain.z, fountain.basinDiameter / 2, fountain.basinDiameter / 2), rect)
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
