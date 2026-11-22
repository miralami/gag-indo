--!nocheck
-- WORK_QUEUE item 206 (SPRINT 1): LUNE-ONLY pure-data contract for "crop_stages_r10".
-- Studio raycast checks (CROP_STAGE_HEIGHT / CROP_STAGE_COLOR / CAMERA_SAMPLES) belong to
-- tools/studio/check_q206.luau. LookDev IDS and review wiring belong to the main session.
-- This spec asserts neither Studio staging nor IDS counts.

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
			expect(Data.REFERENCE_CROP):toBe("reference")
		end)

		t:it("defines exactly three stages with strictly increasing heights", function()
			expect(#Data.STAGES):toBe(3)
			expect({ Data.STAGES[1].stage, Data.STAGES[2].stage, Data.STAGES[3].stage }):toEqual({
				"bibit",
				"tumbuh",
				"siap",
			})
			expect(Data.STAGES[1].height):toBe(1.2)
			expect(Data.STAGES[2].height):toBe(2.6)
			expect(Data.STAGES[3].height):toBe(4.2)
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
			expect(Data.STAGES[3].color):toEqual({ r = 196, g = 162, b = 52 })
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
			local registrySrc = fs.readFile("src/shared/ReviewCameras.luau")
			expect(string.find(registrySrc, 'plot_aerial_{string.format("%02d", index)}', 1, true) ~= nil):toBe(true)
		end)

		t:it("stages 30 stem+canopy samples, three per plot, deterministically", function()
			local samples = Data.stageParts()
			expect(#samples):toBe(30)
			expect(#samples):toBe(Game.plotCount * 3)
			local byPlot: { [number]: { string } } = {}
			for index, sample in ipairs(samples) do
				byPlot[sample.plot] = byPlot[sample.plot] or {}
				byPlot[sample.plot][#byPlot[sample.plot] + 1] = sample.stage
				local stage = Data.STAGES[((index - 1) % 3) + 1]
				expect(sample.plot):toBe(math.floor((index - 1) / 3) + 1)
				expect(sample.stage):toBe(stage.stage)
				expect(sample.height):toBe(stage.height)
				expect(sample.color):toEqual(stage.color)
				expect(sample.stem.role):toBe("stem")
				expect(sample.stem.shape):toBe("Block")
				expect(sample.canopy.role):toBe("canopy")
				expect(sample.canopy.shape):toBe("Ball")
				expect(sample.stem.size[2]):toBe(sample.height)
				expect(sample.stem.color):toEqual(sample.canopy.color)
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
	end)
end
