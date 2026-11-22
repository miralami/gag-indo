--!strict
-- ModelMapCropStagesR10: pure data for the OFF-BY-DEFAULT "crop_stages_r10" reference-stage overlay
-- (WORK_QUEUE item 206, SPRINT 1). The default crop models are never touched: a SERVER applier stages
-- six anchored Parts (one stem Block + one canopy Ball per stage) per plot, in each plot's outer area
-- away from its gate, so every plot_aerial_NN camera can raycast its OWN plot's bibit/tumbuh/siap.
-- Heights strictly increase; the siap canopy is retinted far enough from bibit to clear the 0.15
-- normalised RGB distance floor. No engine calls, no asset IDs: only pure tables/functions.

local Candidates: any = require(script.Parent.CropModelCandidates)
local Game: any = require(script.Parent.Config.Game)

type RGB = { r: number, g: number, b: number }
type PartSpec = {
	name: string,
	role: string,
	shape: string,
	size: { number },
	position: { number },
	color: RGB,
}
type Stage = { stage: string, height: number, color: RGB }
type StageSample = {
	plot: number,
	stage: string,
	height: number,
	color: RGB,
	stem: PartSpec,
	canopy: PartSpec,
}

local Data = {}

Data.id = "crop_stages_r10"
Data.folderName = "LookDevCropStagesR10_crop_stages_r10"

-- Mirrors server/World/Ground.Y and ModelMapPlotsR8.PLOT_WIDTH; kept local so this stays engine-free.
Data.GROUND_Y = 0.5
Data.DEMO_PLOT = 3 -- plot 3 is due east at (192, 0); its gate faces inward (-X).
Data.DEMO_OFFSET = { x = 8, z = 0 } -- radial OUTWARD 8 studs (clear of the gate), z is tangential.
Data.STAGE_SPACING = 4 -- stages sit side by side tangentially inside each 34x34 plot.
Data.STEM_WIDTH = 0.6
Data.CANOPY_SIZE = { 1.4, 1.2, 1.4 }
Data.REFERENCE_CROP = "reference"
Data.MIN_HUE_DISTANCE = 0.15

local STAGES: { Stage } = {
	{ stage = "bibit", height = 1.2, color = { r = 110, g = 170, b = 80 } },
	{ stage = "tumbuh", height = 2.6, color = { r = 80, g = 155, b = 65 } },
	{ stage = "siap", height = 4.2, color = { r = 196, g = 162, b = 52 } },
}
Data.STAGES = STAGES

-- One plot_aerial_NN camera per configured plot (ReviewCameras builds the same names from Game.plotCount).
local cameraNames: { string } = {}
for index = 1, Game.plotCount do
	cameraNames[index] = string.format("plot_aerial_%02d", index)
end
Data.CAMERA_NAMES = cameraNames

-- Crop kinds under audit, in the shipped Config/Crops order.
local crops: { string } = {}
for _, cropId in ipairs(Candidates.cropIds) do
	crops[#crops + 1] = cropId
end
Data.CROPS = crops

-- Current (pre-correction) top height and canopy palette token, read from the shipped recipes.
-- Top = max(offset.y + size.y / 2) over every descriptor at that stage.
local currentByCrop: { [string]: any } = {}
for _, cropId in ipairs(Data.CROPS) do
	local arch = Candidates.archetypes[cropId]
	local byStage: { [string]: any } = {}
	for _, stageName in ipairs(Candidates.stages) do
		local parts = Candidates.partsFor(cropId, stageName)
		local top = 0
		if type(parts) == "table" then
			for _, part in ipairs(parts) do
				local candidateTop = part.offset[2] + part.size[2] / 2
				if candidateTop > top then
					top = candidateTop
				end
			end
		end
		byStage[stageName] = { height = top, leaf = arch.leaf.color }
	end
	currentByCrop[cropId] = byStage
end
Data.CURRENT = currentByCrop

-- Normalised Euclidean RGB distance in 0..1 (divide by the unit-cube diagonal sqrt(3)).
function Data.hueDistance(a: RGB, b: RGB): number
	local dr = (a.r - b.r) / 255
	local dg = (a.g - b.g) / 255
	local db = (a.b - b.b) / 255
	return math.sqrt((dr * dr + dg * dg + db * db) / 3)
end

local function copyColor(color: RGB): RGB
	return { r = color.r, g = color.g, b = color.b }
end

-- Plot cluster centre = plot centre + a small outward offset. `ux/uz` is the outward radial and
-- `(-uz, ux)` the tangential direction used to line the three stages up inside the plot.
local function plotBasis(plot: number): (number, number, number, number)
	local px, pz = Game.plotCenter(plot)
	local radius = math.sqrt(px * px + pz * pz)
	if radius <= 0 then
		return px + Data.DEMO_OFFSET.x, pz + Data.DEMO_OFFSET.z, 1, 0
	end
	local ux, uz = px / radius, pz / radius
	local baseX = px + ux * Data.DEMO_OFFSET.x - uz * Data.DEMO_OFFSET.z
	local baseZ = pz + uz * Data.DEMO_OFFSET.x + ux * Data.DEMO_OFFSET.z
	return baseX, baseZ, ux, uz
end

function Data.demoCentreFor(plot: number): { number }
	local baseX, baseZ = plotBasis(plot)
	return { baseX, Data.GROUND_Y + Data.STAGES[2].height, baseZ }
end

function Data.demoCentre(): { number }
	return Data.demoCentreFor(Data.DEMO_PLOT)
end

-- Three stage samples PER PLOT (plot count x 3). Each carries a distinct `plot`, the stage name,
-- height/colour, and a stem Block + canopy Ball with role tags so the Studio check can tell a canopy
-- from a stem when measuring colour distance.
function Data.stageParts(): { StageSample }
	local samples: { StageSample } = {}
	for plot = 1, Game.plotCount do
		local baseX, baseZ, ux, uz = plotBasis(plot)
		for index, stage in ipairs(Data.STAGES) do
			local along = (index - 2) * Data.STAGE_SPACING
			local x = baseX - uz * along
			local z = baseZ + ux * along
			local topY = Data.GROUND_Y + stage.height
			local color = copyColor(stage.color)
			local prefix = "CropStage_P" .. plot .. "_" .. stage.stage
			samples[#samples + 1] = {
				plot = plot,
				stage = stage.stage,
				height = stage.height,
				color = copyColor(color),
				stem = {
					name = prefix .. "_Stem",
					role = "stem",
					shape = "Block",
					size = { Data.STEM_WIDTH, stage.height, Data.STEM_WIDTH },
					position = { x, Data.GROUND_Y + stage.height / 2, z },
					color = copyColor(color),
				},
				canopy = {
					name = prefix .. "_Canopy",
					role = "canopy",
					shape = "Ball",
					size = { Data.CANOPY_SIZE[1], Data.CANOPY_SIZE[2], Data.CANOPY_SIZE[3] },
					position = { x, topY, z },
					color = copyColor(color),
				},
			}
		end
	end
	return samples
end

-- Load-time contract check: keeps the correction honest before any applier or harness reads it.
do
	assert(#Data.STAGES == 3, "crop_stages_r10: stage count is not 3")
	assert(#Data.CROPS == #Candidates.cropIds, "crop_stages_r10: crop coverage is incomplete")
	for index = 2, #Data.STAGES do
		assert(
			Data.STAGES[index].height > Data.STAGES[index - 1].height,
			"crop_stages_r10: stage heights do not strictly increase"
		)
	end
	for _, cropId in ipairs(Data.CROPS) do
		local current = Data.CURRENT[cropId]
		assert(
			current.bibit.height < current.tumbuh.height and current.tumbuh.height < current.siap.height,
			"crop_stages_r10: stage heights do not strictly increase for " .. cropId
		)
		for index = 2, #Data.STAGES do
			assert(
				Data.STAGES[index].height > Data.STAGES[index - 1].height,
				"crop_stages_r10: stage heights do not strictly increase for " .. cropId
			)
		end
	end
	local bibit, siap = Data.STAGES[1], Data.STAGES[3]
	assert(
		Data.hueDistance(bibit.color, siap.color) >= Data.MIN_HUE_DISTANCE,
		"crop_stages_r10: siap/bibit hue distance below 0.15"
	)
	for _, stage in ipairs(Data.STAGES) do
		for _, channel in ipairs({ stage.color.r, stage.color.g, stage.color.b }) do
			assert(channel >= 0 and channel <= 255, "crop_stages_r10: colour channel outside 0..255")
		end
	end
	local samples = Data.stageParts()
	assert(#samples == Game.plotCount * #Data.STAGES, "crop_stages_r10: stage sample count is not 30")
	local perPlot: { [number]: { [string]: boolean } } = {}
	for _, sample in ipairs(samples) do
		perPlot[sample.plot] = perPlot[sample.plot] or {}
		assert(perPlot[sample.plot][sample.stage] == nil, "crop_stages_r10: duplicate stage in plot " .. sample.plot)
		perPlot[sample.plot][sample.stage] = true
	end
	for plot = 1, Game.plotCount do
		local seen = perPlot[plot]
		assert(seen ~= nil, "crop_stages_r10: plot " .. plot .. " has no stage samples")
		for _, stage in ipairs(Data.STAGES) do
			assert(seen[stage.stage] == true, "crop_stages_r10: plot " .. plot .. " missing " .. stage.stage)
		end
	end
	assert(#Data.CAMERA_NAMES == Game.plotCount, "crop_stages_r10: plot aerial camera count mismatch")
end

return Data
