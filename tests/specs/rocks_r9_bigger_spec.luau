--!nocheck
-- WORK_QUEUE section P item 176: unregistered pure-data spec for the enlarged rocks_r9 candidate.
-- Fails on the pre-fix 24-bank/12-hill/12-field set (median longest side 3.2 > 2.5, no groups,
-- no in-channel stones). Registration, Studio evidence and tracker ticks belong to the main session.

local function median(values)
	if #values == 0 then
		return 0
	end
	table.sort(values)
	return values[math.ceil(#values / 2)]
end

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapRocksR9")
	local MapSpec = env:require("server/World/MapSpec")
	local rocks = Data.rocks({
		centreZ = MapSpec.riverCentreZ,
		terrainHalf = MapSpec.TERRAIN_HALF,
		terraces = MapSpec.TERRACES,
		terraceX = MapSpec.TERRACE_X,
		terraceGap = MapSpec.TERRACE_GAP,
		riverHalf = 14,
		riverBank = 8,
	})

	local longSides, groups, water = {}, {}, {}
	for _, rock in ipairs(rocks) do
		longSides[#longSides + 1] = math.max(rock.size[1], rock.size[2], rock.size[3])
		if rock.group and rock.site ~= "water" then
			groups[rock.group] = (groups[rock.group] or 0) + 1
		end
		if rock.site == "water" then
			water[#water + 1] = rock
		end
	end

	t:describe("rocks_r9 item 176 bigger varied rocks", function()
		t:it("generates at least 40 rocks", function()
			expect(Data.count(rocks) >= 40):toBe(true)
		end)

		t:it("keeps every longest side in 0.8..2.5 studs with a median of at least 1.2", function()
			expect(Data.SIZE_MIN):toBe(0.8)
			expect(Data.SIZE_MAX):toBe(2.5)
			expect(#longSides):toBe(#rocks)
			for _, side in ipairs(longSides) do
				expect(side >= 0.8 and side <= 2.5):toBe(true)
			end
			for _, rock in ipairs(rocks) do
				for _, extent in ipairs(rock.size) do
					expect(extent >= 0.8 and extent <= 2.5):toBe(true)
				end
			end
			expect(median(longSides) >= 1.2):toBe(true)
		end)

		t:it("uses all three baked model IDs round-robin at the 0.8..2.5 footprint", function()
			expect(#Data.ROCK_ASSET_IDS):toBe(3)
			expect(Data.ROCK_ASSET_ID_ATTRIBUTE):toBe("RockAssetId")
			local seen = {}
			for index, rock in ipairs(rocks) do
				local id = Data.assetIdFor(index)
				expect(id):toBe(Data.ROCK_ASSET_IDS[((index - 1) % 3) + 1])
				seen[id] = true
				local longest = math.max(rock.size[1], rock.size[2], rock.size[3])
				expect(longest >= Data.SIZE_MIN and longest <= Data.SIZE_MAX):toBe(true)
			end
			local distinct = 0
			for _ in pairs(seen) do
				distinct += 1
			end
			expect(distinct):toBe(3)
		end)

		t:it("forms clusters of 2..4 on both river banks and at the stepping stones", function()
			local clusterCount, south, north, stepping = 0, 0, 0, 0
			for group, size in pairs(groups) do
				if size >= 2 then
					expect(size >= Data.CLUSTER_MIN and size <= Data.CLUSTER_MAX):toBe(true)
					clusterCount += 1
					if string.find(group, "south", 1, true) then
						south += 1
					end
					if string.find(group, "north", 1, true) then
						north += 1
					end
					if string.find(group, "stepping", 1, true) then
						stepping += 1
					end
				end
			end
			expect(clusterCount >= 20):toBe(true)
			expect(south >= 8):toBe(true)
			expect(north >= 8):toBe(true)
			expect(stepping >= 8):toBe(true)
		end)

		t:it("half-buries a few stones inside the river channel", function()
			expect(#water >= 3):toBe(true)
			for _, rock in ipairs(water) do
				expect(math.abs(rock.z - MapSpec.riverCentreZ(rock.x)) < 14):toBe(true)
				expect(rock.bury):toBe(Data.BURY_FRACTION)
			end
		end)

		t:it("uses only the two documented rock palettes", function()
			local palettes = {}
			for _, rock in ipairs(rocks) do
				palettes[rock.palette] = true
			end
			expect(palettes.grey_brown):toBe(true)
			expect(palettes.moss_green):toBe(true)
			local count = 0
			for _ in pairs(palettes) do
				count += 1
			end
			expect(count):toBe(2)
		end)
	end)
end
