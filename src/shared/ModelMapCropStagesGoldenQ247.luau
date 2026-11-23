--!strict
-- ModelMapCropStagesGoldenQ247: pure data for WORK_QUEUE item 271, the golden-ripe crop-stage
-- overlay. It reuses the item-206/254 stage geometry and the already-baked padi model; nothing here
-- creates Instances or invents an asset ID. The item-247 golden camera stays unchanged.
--
-- The base crop_stages_r10 candidate owns the three stage recipes. This module only supplies the
-- golden-hour palette and the baked-model provenance for the "siap" stage, so the ripe stage reads
-- as a golden padi plant instead of a green wedge fan.

local CropStages = require(script.Parent.ModelMapCropStagesR10)

local Data = {}

Data.id = "crop_stages_golden_247"
Data.folderName = "LookDevCropStagesGoldenQ247_crop_stages_golden_247"

Data.DEMO_PLOT = CropStages.DEMO_PLOT
Data.STAGE_NAMES = { "bibit", "tumbuh", "siap" }
Data.MODEL_STAGE = "siap"
Data.MODEL_SOURCE = "padi_model"
Data.MODEL_TARGET_WIDTH = 1.8
Data.MODEL_TARGET_HEIGHT = 3.6

-- Warm, increasing ripeness. Plain RGB tables; the applier resolves them with Color3.fromRGB.
Data.GOLDEN_COLOURS = {
	bibit = { r = 168, g = 186, b = 76 },
	tumbuh = { r = 205, g = 178, b = 64 },
	siap = { r = 226, g = 158, b = 40 },
}

function Data.samples(): { { [string]: any } }
	local out = {}
	for _, sample in ipairs(CropStages.stageParts()) do
		if sample.plot == Data.DEMO_PLOT then
			out[#out + 1] = {
				plot = sample.plot,
				stage = sample.stage,
				height = sample.height,
				color = Data.GOLDEN_COLOURS[sample.stage] or sample.color,
				parts = sample.parts,
				modelSource = if sample.stage == Data.MODEL_STAGE then Data.MODEL_SOURCE else nil,
			}
		end
	end
	return out
end

do
	local samples = Data.samples()
	assert(#samples == #Data.STAGE_NAMES, "crop_stages_golden_q247: expected exactly three stages")
	for index, sample in ipairs(samples) do
		assert(sample.stage == Data.STAGE_NAMES[index], "crop_stages_golden_q247: stage order changed")
		assert(type(sample.parts) == "table" and #sample.parts > 0, "crop_stages_golden_q247: empty stage")
		if index > 1 then
			assert(sample.height > samples[index - 1].height, "crop_stages_golden_q247: heights do not rise")
		end
	end
	assert(samples[#samples].modelSource == Data.MODEL_SOURCE, "crop_stages_golden_q247: ripe stage has no baked model")
end

return Data
