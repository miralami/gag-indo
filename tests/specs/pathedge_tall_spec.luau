--!nocheck
-- WORK_QUEUE section P item 177 (UNREGISTERED): tall path-edge plants. Pure-data contract for
-- >=1 plant every 3 studs per road side, 1..2-stud tufts/flowers and exactly two flower colours.
-- The Studio CHECK lines and visual verdict belong to tools/studio/check_p177.luau and the main
-- session. This spec intentionally does NOT fail when the item-142 debris contract changes.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapPathEdgeR8")
	local MapSpec = env:require("server/World/MapSpec")

	local arms = MapSpec.roadArms()
	local ring = MapSpec.ringSegments()
	local continuations = MapSpec.roadContinuations()

	t:describe("pathedge_r8 tall plants (item 177)", function()
		t:it("declares a 3-stud plant cadence, 1..2-stud heights and two flower colours", function()
			expect(type(Data.plantPieces)):toBe("function")
			expect(type(Data.FLOWER_COLOURS)):toBe("table")
			expect(Data.PLANT_SPACING):toBeAtMost(3)
			expect(Data.PLANT_HEIGHT_MIN):toBeAtLeast(1)
			expect(Data.PLANT_HEIGHT_MAX):toBeAtMost(2)
			expect(Data.PLANT_CLEAR * 2):toBeGreaterThan(Data.CLUMP_MAX_WIDTH / 2)
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

		t:it("places a plant at most 3 studs apart on every side of every road", function()
			expect(type(Data.plantPieces)):toBe("function")
			local plants = Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)
			expect(#plants > 0):toBe(true)
			local groups, grass, flowers, colours = {}, 0, 0, {}
			for _, plant in ipairs(plants) do
				expect(plant.kind == "grass_tuft" or plant.kind == "flower"):toBe(true)
				expect(plant.height >= Data.PLANT_HEIGHT_MIN and plant.height <= Data.PLANT_HEIGHT_MAX):toBe(true)
				expect(plant.side == "-1" or plant.side == "1"):toBe(true)
				expect(type(plant.centre) == "table" and #plant.centre == 2):toBe(true)
				expect(math.abs(plant.lateral) >= plant.halfWidth + Data.PLANT_CLEAR - 1e-9):toBe(true)
				local key = tostring(plant.segment) .. "/" .. plant.side
				groups[key] = groups[key] or {}
				table.insert(groups[key], plant.along)
				if plant.kind == "flower" then
					flowers += 1
					expect(type(plant.flowerColour) == "string"):toBe(true)
					expect(#plant.flowerRgb):toBe(3)
					colours[plant.flowerColour] = true
				else
					grass += 1
				end
			end
			expect(grass > 0 and flowers > 0):toBe(true)
			local seenColours = 0
			for _ in pairs(colours) do
				seenColours += 1
			end
			expect(seenColours):toBe(2)
			local checked = 0
			for _, alongs in pairs(groups) do
				table.sort(alongs)
				for index = 2, #alongs do
					expect(alongs[index] - alongs[index - 1] <= Data.PLANT_SPACING + 1e-9):toBe(true)
				end
				checked += #alongs > 0 and 1 or 0
			end
			expect(checked):toBeGreaterThan(0)
			expect(Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)):toEqual(plants)
		end)

		t:it("applier stages measurable, off-road plants with both flower colours", function()
			local applier = fs.readFile("src/server/World/LookDevPathEdgeR8.luau")
			expect(string.find(applier, "Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)", 1, true) ~= nil):toBe(
				true
			)
			for _, token in ipairs({
				'SetAttribute("PathEdgePlant", true)',
				'SetAttribute("PlantHeight", height)',
				'SetAttribute("FlowerColour", piece.flowerColour)',
				"flowerColour(piece.flowerRgb)",
				"TallBlade_",
				"FlowerPetal_",
			}) do
				expect(string.find(applier, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
		end)
	end)
end
