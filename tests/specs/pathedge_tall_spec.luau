--!nocheck
-- WORK_QUEUE section Q item 190 (supersedes item 177): tall baked path-edge plants.
-- Pure-data contract for 2..4-stud jittered cadence, 1..2.5-stud grass/flower/stone models from
-- Data.PLANT_ASSET_IDS and exactly two flower colours. The Studio CHECK lines and visual verdict
-- belong to the main session. This spec intentionally does NOT fail when the item-142 debris
-- contract changes.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPathEdgeR8")
	local MapSpec = env:require("server/World/MapSpec")

	local arms = MapSpec.roadArms()
	local ring = MapSpec.ringSegments()
	local continuations = MapSpec.roadContinuations()

	t:describe("pathedge_r8 tall plants (item 190)", function()
		t:it("declares 2..4-stud jitter, 1..2.5-stud heights, two colours and three baked asset ids", function()
			expect(type(Data.plantPieces)):toBe("function")
			expect(type(Data.plantStep)):toBe("function")
			expect(Data.PLANT_SPACING_MIN):toBe(2)
			expect(Data.PLANT_SPACING_MAX):toBe(4)
			expect(Data.PLANT_HEIGHT_MIN):toBeAtLeast(1)
			expect(Data.PLANT_HEIGHT_MAX):toBeAtMost(2.5)
			expect(Data.PLANT_CLEAR * 2):toBeGreaterThan(Data.CLUMP_MAX_WIDTH / 2)
			expect(type(Data.PLANT_ASSET_IDS)):toBe("table")
			expect(Data.PLANT_ASSET_ID_ATTRIBUTE):toBe("EdgeAssetId")
			expect(type(Data.assetIdFor)):toBe("function")
			local ids = {}
			for _, kind in ipairs({ "grass_tuft", "flower", "stone" }) do
				local id = Data.PLANT_ASSET_IDS[kind]
				expect(type(id)):toBe("number")
				expect(id):toBeGreaterThan(0)
				expect(ids[id]):toBe(nil)
				ids[id] = true
				expect(Data.assetIdFor(kind)):toBe(id)
			end
			expect(Data.assetIdFor("missing")):toBe(nil)
			local varied = false
			for index = 1, 20 do
				local step = Data.plantStep(419, index)
				expect(step >= Data.PLANT_SPACING_MIN - 1e-9):toBe(true)
				expect(step <= Data.PLANT_SPACING_MAX + 1e-9):toBe(true)
				if index > 1 and step ~= Data.plantStep(419, index - 1) then
					varied = true
				end
			end
			expect(varied):toBe(true)
			expect(type(Data.FLOWER_COLOURS)):toBe("table")
			expect(#Data.FLOWER_COLOURS):toBe(2)
			local names, rgbs = {}, {}
			for _, colour in ipairs(Data.FLOWER_COLOURS) do
				expect(type(colour.name) == "string" and colour.name ~= ""):toBe(true)
				expect(#colour.rgb):toBe(3)
				expect(names[colour.name]):toBe(nil)
				names[colour.name] = true
				rgbs[table.concat(colour.rgb, ",")] = true
			end
			local distinct = 0
			for _ in pairs(rgbs) do
				distinct += 1
			end
			expect(distinct):toBe(2)
		end)

		t:it("places irregularly spaced off-road plants, stones, baked ids and ~12-stud flowers", function()
			expect(type(Data.plantPieces)):toBe("function")
			local plants = Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)
			expect(#plants > 0):toBe(true)
			local groups, flowerGroups, kinds, colours = {}, {}, {}, {}
			for _, plant in ipairs(plants) do
				expect(plant.kind == "grass_tuft" or plant.kind == "flower" or plant.kind == "stone"):toBe(true)
				expect(type(Data.assetIdFor(plant.kind))):toBe("number")
				expect(plant.height >= Data.PLANT_HEIGHT_MIN and plant.height <= Data.PLANT_HEIGHT_MAX):toBe(true)
				expect(plant.side == "-1" or plant.side == "1"):toBe(true)
				expect(type(plant.centre) == "table" and #plant.centre == 2):toBe(true)
				expect(math.abs(plant.lateral) >= plant.halfWidth + Data.PLANT_CLEAR - 1e-9):toBe(true)
				local key = tostring(plant.segment) .. "/" .. plant.side
				groups[key] = groups[key] or {}
				table.insert(groups[key], plant.along)
				kinds[plant.kind] = (kinds[plant.kind] or 0) + 1
				if plant.kind == "flower" then
					flowerGroups[key] = flowerGroups[key] or {}
					table.insert(flowerGroups[key], plant.along)
					expect(type(plant.flowerColour) == "string"):toBe(true)
					expect(#plant.flowerRgb):toBe(3)
					colours[plant.flowerColour] = true
				end
			end
			expect(kinds.grass_tuft > 0 and kinds.stone > 0 and kinds.flower > 0):toBe(true)
			local seenColours = 0
			for _ in pairs(colours) do
				seenColours += 1
			end
			expect(seenColours):toBe(2)
			local irregular = false
			local checked = 0
			for _, alongs in pairs(groups) do
				table.sort(alongs)
				for index = 2, #alongs do
					local gap = alongs[index] - alongs[index - 1]
					expect(gap >= Data.PLANT_SPACING_MIN - 1e-9):toBe(true)
					expect(gap <= Data.PLANT_SPACING_MAX + 1e-9):toBe(true)
					if gap > Data.PLANT_SPACING_MIN + 0.05 and gap < Data.PLANT_SPACING_MAX - 0.05 then
						irregular = true
					end
				end
				checked += #alongs > 0 and 1 or 0
			end
			expect(checked):toBeGreaterThan(0)
			expect(irregular):toBe(true)
			local flowerGaps, flowerTotal = 0, 0
			for _, alongs in pairs(flowerGroups) do
				table.sort(alongs)
				for index = 2, #alongs do
					local gap = alongs[index] - alongs[index - 1]
					expect(gap >= 4 * Data.PLANT_SPACING_MIN - 1e-9):toBe(true)
					expect(gap <= 4 * Data.PLANT_SPACING_MAX + 1e-9):toBe(true)
					flowerGaps += 1
					flowerTotal += gap
				end
			end
			expect(flowerGaps):toBeGreaterThan(0)
			expect(flowerTotal / flowerGaps >= 10 and flowerTotal / flowerGaps <= 14):toBe(true)
			expect(Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)):toEqual(plants)
		end)

		t:it("applier stages baked models with measurable, off-road plant anchors", function()
			local applier = fs.readFile("src/server/World/LookDevPathEdgeR8.luau")
			expect(string.find(applier, "Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)", 1, true) ~= nil):toBe(
				true
			)
			for _, token in ipairs({
				'SetAttribute("PathEdgePlant", true)',
				'SetAttribute("PlantHeight", height)',
				'SetAttribute("FlowerColour", piece.flowerColour)',
				'SetAttribute("EdgeAssetId",',
				"Data.assetIdFor(piece.kind)",
				"LookDevAssetLoader.get(assetId, FAMILY_ID)",
				"CanCollide = false",
			}) do
				expect(string.find(applier, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applier, "TallBlade_", 1, true) == nil):toBe(true)
			expect(string.find(applier, "FlowerPetal_", 1, true) == nil):toBe(true)
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
		end)
	end)
end
