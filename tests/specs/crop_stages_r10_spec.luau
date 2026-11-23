--!nocheck
-- WORK_QUEUE items 206 / 254: LUNE-ONLY pure-data contract for "crop_stages_r10".
-- Studio checks live in tools/studio/check_q206.luau (height/colour) and check_q254.luau
-- (height/colour + width + NO_MELONS + FAIL calibrations). No Studio staging or visual verdict here.

local fs = require("@lune/fs")

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapCropStagesR10")
	local Candidates = env:require("shared/CropModelCandidates")
	local Game = env:require("shared/Config/Game")
	local pureSrc = fs.readFile("src/shared/ModelMapCropStagesR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevCropStagesR10.luau")
	local checkSrc = fs.readFile("tools/studio/check_q254.luau")
	local q263Src = fs.readFile("tools/studio/check_q263.luau")

	t:describe("crop_stages_r10 pure data", function()
		t:it("stays pure and keeps its additive reference identity", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("crop_stages_r10")
			expect(Data.folderName):toBe("LookDevCropStagesR10_crop_stages_r10")
			expect(Data.MIN_HUE_DISTANCE):toBe(0.15)
			expect(Data.MIN_STAGE_WIDTH):toBe(1.5)
			expect(Data.REFERENCE_CROP):toBe("reference")
			expect(Data.PLANTS_PER_ROW >= 3):toBe(true)
			expect(Data.TILE_PITCH):toBe(7.5)
			expect(Data.MATERIAL_LEAF):toBe("LeafyGrass")
		end)

		t:it("defines exactly three stages with strictly increasing heights", function()
			expect(#Data.STAGES):toBe(3)
			expect({ Data.STAGES[1].stage, Data.STAGES[2].stage, Data.STAGES[3].stage }):toEqual({
				"bibit",
				"tumbuh",
				"siap",
			})
			expect(Data.STAGES[1].height):toBe(1.2)
			expect(Data.STAGES[2].height):toBe(2.2)
			expect(Data.STAGES[3].height):toBe(3.0)
			for index = 2, #Data.STAGES do
				expect(Data.STAGES[index].height > Data.STAGES[index - 1].height):toBe(true)
			end
		end)

		t:it("keeps siap colour >= 0.15 from bibit in normalised RGB space", function()
			local bibit, siap = Data.STAGES[1], Data.STAGES[3]
			local distance = Data.hueDistance(bibit.color, siap.color)
			expect(distance >= 0.15):toBe(true)
			expect(distance >= Data.MIN_HUE_DISTANCE):toBe(true)
			expect(distance > 0 and distance <= 1):toBe(true)
			expect(Data.hueDistance(bibit.color, bibit.color)):toBe(0)
			expect(Data.hueDistance({ r = 0, g = 0, b = 0 }, { r = 255, g = 255, b = 255 })):toBe(1)
			for _, stage in ipairs(Data.STAGES) do
				for _, channel in ipairs({ stage.color.r, stage.color.g, stage.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
			expect(Data.STAGES[1].color):toEqual({ r = 110, g = 170, b = 80 })
			expect(Data.STAGES[2].color):toEqual({ r = 80, g = 155, b = 65 })
			expect(Data.STAGES[3].color):toEqual({ r = 64, g = 120, b = 52 })
			expect(Data.PRODUCES[1].color):toEqual({ r = 200, g = 40, b = 35 })
		end)

		t:it("audits current heights and colours for every shipped crop kind", function()
			expect(Data.CROPS):toEqual(Candidates.cropIds)
			expect(#Data.CROPS):toBe(12)
			for _, cropId in ipairs(Data.CROPS) do
				local current = Data.CURRENT[cropId]
				expect(current.bibit.height < current.tumbuh.height):toBe(true)
				expect(current.tumbuh.height < current.siap.height):toBe(true)
				expect(current.bibit.leaf):toBe(Candidates.archetypes[cropId].leaf.color)
			end
		end)

		t:it("names one plot_aerial_NN camera per configured plot", function()
			local cameras = {}
			for index = 1, Game.plotCount do
				cameras[#cameras + 1] = string.format("plot_aerial_%02d", index)
			end
			expect(Data.CAMERA_NAMES):toEqual(cameras)
			expect(#Data.CAMERA_NAMES):toBe(10)
		end)

		t:it("stages 30 rows of plants, one plant per tile pitch, three rows per plot", function()
			local samples = Data.stageParts()
			expect(#samples):toBe(30)
			expect(#samples):toBe(Game.plotCount * 3)
			local byPlot: { [number]: { string } } = {}
			local expectedLeaves = { bibit = 4, tumbuh = 6, siap = 6 }
			local minWidth = { bibit = 1.6, tumbuh = 2.0, siap = 2.0 }
			for index, sample in ipairs(samples) do
				byPlot[sample.plot] = byPlot[sample.plot] or {}
				byPlot[sample.plot][#byPlot[sample.plot] + 1] = sample.stage
				local stage = Data.STAGES[((index - 1) % 3) + 1]
				expect(sample.plot):toBe(math.floor((index - 1) / 3) + 1)
				expect(sample.stage):toBe(stage.stage)
				expect(sample.height):toBe(stage.height)
				expect(sample.color):toEqual(stage.color)
				expect(#sample.plants):toBe(Data.PLANTS_PER_ROW)
				expect(sample.parts[1]):toEqual(sample.stem)
				expect(sample.stem.shape):toBe("Cylinder")
				expect(sample.stem.role):toBe("stem")
				expect(sample.stem.rotation[3]):toBe(Data.PLANT_ROTATION_Z) -- upright, not a flat sliver
				expect(sample.canopy.shape):toBe("Wedge")
				expect(sample.canopy.role):toBe("canopy")
				local produce = Data.produceFor(sample.plot)
				local flatCount, top = 0, 0
				for plantIndex, plant in ipairs(sample.plants) do
					local leaves, pods = 0, 0
					for _, part in ipairs(plant) do
						flatCount += 1
						expect(part.shape == "Wedge" or part.shape == "Cylinder"):toBe(true)
						expect(part.plant):toBe(plantIndex)
						expect(part.material ~= "SmoothPlastic"):toBe(true)
						expect(part.size[1] > 0 and part.size[2] > 0 and part.size[3] > 0):toBe(true)
						local partTop = Data.partTop(part)
						top = math.max(top, partTop)
						expect(partTop <= Data.GROUND_Y + sample.height + 1e-6):toBe(true)
						if part.role == "canopy" then
							leaves += 1
							expect(part.shape):toBe("Wedge")
							expect(part.material):toBe("LeafyGrass")
							expect(part.color):toEqual(stage.color)
						elseif part.role == "produce" then
							pods += 1
							expect(part.shape):toBe("Cylinder")
							expect(part.color):toEqual(produce.color)
						end
					end
					expect(leaves):toBe(expectedLeaves[sample.stage])
					expect(pods):toBe(if sample.stage == "siap" then produce.count else 0)
					expect(Data.plantWidth(plant) >= Data.MIN_STAGE_WIDTH):toBe(true)
					expect(Data.plantWidth(plant) >= minWidth[sample.stage] - 1e-6):toBe(true)
				end
				expect(#sample.parts):toBe(flatCount)
				-- The tallest part reaches the stage height (1.2 / 2.2 / 3.0 studs).
				expect(math.abs(top - (Data.GROUND_Y + sample.height)) < 0.15):toBe(true)
				if sample.plot == Data.DEMO_PLOT then
					expect(sample.stem.position[1] > 192):toBe(true) -- outer side of plot 3, away from its gate
				end
			end
			for plot = 1, Game.plotCount do
				expect(byPlot[plot]):toEqual({ "bibit", "tumbuh", "siap" })
				local centre = Data.demoCentreFor(plot)
				expect(centre[2]):toBe(Data.GROUND_Y + Data.STAGES[2].height)
				expect(centre[2] > Data.GROUND_Y):toBe(true)
			end
			expect(Data.demoCentre()):toEqual(Data.demoCentreFor(Data.DEMO_PLOT))

			local fresh = Env.new():require("shared/ModelMapCropStagesR10")
			expect(serialize(fresh.stageParts())):toBe(serialize(Data.stageParts()))
			expect(serialize(fresh.demoCentre())):toBe(serialize(Data.demoCentre()))
			expect(serialize(fresh.demoCentreFor(1))):toBe(serialize(Data.demoCentreFor(1)))
			expect(serialize(fresh.CURRENT)):toBe(serialize(Data.CURRENT))
		end)

		t:it("rows step one tile pitch apart and plants sit on tile centres", function()
			local samples = Data.stageParts()
			local row = {}
			for _, sample in ipairs(samples) do
				if sample.plot == Data.DEMO_PLOT then
					row[#row + 1] = sample
				end
			end
			expect(#row):toBe(3)
			-- plot 3 is due east: radial = +X, tangential = +Z.
			for index, sample in ipairs(row) do
				local stems = {}
				for _, plant in ipairs(sample.plants) do
					stems[#stems + 1] = plant[1].position
				end
				for plantIndex = 2, #stems do
					expect(math.abs(stems[plantIndex][1] - stems[plantIndex - 1][1] - Data.TILE_PITCH) < 1e-6):toBe(
						true
					)
					expect(math.abs(stems[plantIndex][3] - stems[1][3]) < 1e-6):toBe(true)
				end
				if index > 1 then
					local previous = row[index - 1].plants[1][1].position
					expect(math.abs(stems[1][3] - previous[3] - Data.STAGE_SPACING) < 1e-6):toBe(true)
				end
			end
		end)

		t:it("cycles chili / shallot / rice produce by plot with distinct crop colours", function()
			local seen = {}
			for plot = 1, 3 do
				seen[Data.produceFor(plot).crop] = true
			end
			expect(seen.cabai and seen.bawang and seen.padi):toBe(true)
			expect(Data.produceFor(4).crop):toBe(Data.produceFor(1).crop)
		end)

		t:it("ships the item-254 check lines and both FAIL calibrations", function()
			for _, name in ipairs({
				"CROP_STAGE_HEIGHT",
				"CROP_STAGE_COLOR",
				"CROP_STAGE_WIDTH",
				"NO_MELONS",
				"CAL_CROP_STAGE_WIDTH_FAIL",
				"CAL_NO_MELONS_FAIL",
			}) do
				expect(string.find(checkSrc, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(checkSrc, "review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(string.find(checkSrc, "destroyInjected()", 1, true) ~= nil):toBe(true)
			expect(string.find(checkSrc, "Enum.PartType.Ball", 1, true) ~= nil):toBe(true)
		end)

		t:it("builds from textured primitives only and ships item-263 checks", function()
			for _, token in ipairs({ "materialFor", 'SetAttribute("plant"', "CanCollide = false" }) do
				expect(string.find(applierSrc, token, 1, true) ~= nil):toBe(true)
			end
			for _, banned in ipairs({ "LookDevAssetLoader", ".baked(", "SmoothPlastic", "PartType.Ball" }) do
				expect(string.find(applierSrc, banned, 1, true) == nil):toBe(true)
			end
			expect(string.find(pureSrc, "primitives-only", 1, true) ~= nil):toBe(true)
			for _, name in ipairs({
				"CROP_STAGE_HEIGHT",
				"CROP_STAGE_COLOR",
				"CROP_STAGE_WIDTH",
				"FURROW_RELIEF",
				"DITCH_VISIBLE",
				"CAL_FURROW_RELIEF_FAIL",
				"CAL_DITCH_VISIBLE_FAIL",
				"CAL_CROP_STAGE_WIDTH_FAIL",
				"CAL_CROP_STAGE_HEIGHT_FAIL",
			}) do
				expect(string.find(q263Src, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(q263Src, "SUMMARY_Q263", 1, true) ~= nil):toBe(true)
		end)

		t:it("item 271 golden overlay reuses the stage recipe and the baked padi model", function()
			local q271Src = fs.readFile("tools/studio/check_q271.luau")
			local goldenSrc = fs.readFile("src/shared/ModelMapCropStagesGoldenQ247.luau")
			local goldenApplierSrc = fs.readFile("src/server/World/LookDevCropStagesGoldenQ247.luau")
			local Golden = env:require("shared/ModelMapCropStagesGoldenQ247")
			local samples = Golden.samples()
			expect(Golden.id):toBe("crop_stages_golden_247")
			expect(Golden.DEMO_PLOT):toBe(Data.DEMO_PLOT)
			expect(#samples):toBe(#Golden.STAGE_NAMES)
			expect(samples[#samples].modelSource):toBe("padi_model")
			for index, sample in ipairs(samples) do
				expect(sample.stage):toBe(Golden.STAGE_NAMES[index])
				expect(#sample.parts):toBeGreaterThan(0)
				if index > 1 then
					expect(sample.height):toBeGreaterThan(samples[index - 1].height)
				end
			end
			expect(samples[3].color.r):toBeGreaterThan(samples[1].color.r)
			for _, banned in ipairs({ "game.", "Instance.new", "Enum.", "rbxassetid://" }) do
				expect(string.find(goldenSrc, banned, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(goldenSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			for _, token in ipairs({ ".baked(", "ModelAssetId", "GoldenStage", "LookDev.register" }) do
				expect(string.find(goldenApplierSrc, token, 1, true) ~= nil):toBe(true)
			end
			for _, token in ipairs({
				'"CROP_GOLDEN_"',
				'"SUMMARY_Q271"',
				"restoreAll()",
				'"LOOKDEV_LEAK_Q271"',
			}) do
				expect(string.find(q271Src, token, 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
