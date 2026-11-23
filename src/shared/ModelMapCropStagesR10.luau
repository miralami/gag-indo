--!strict
-- ModelMapCropStagesR10: pure data for the OFF-BY-DEFAULT "crop_stages_r10" reference-stage overlay
-- (WORK_QUEUE items 206 / 254). The default crop models are never touched: a SERVER applier stages
-- anchored, non-collidable crop-shaped Parts (Cylinder stem + Wedge leaves + Cylinder produce) in
-- each plot's outer area away from its gate, so every plot_aerial_NN camera can raycast its OWN
-- plot's bibit/tumbuh/siap. No Ball part: item 254 replaced the old lollipop canopy.
-- Heights stay 1.2 / 2.6 / 4.2 and the stage colours stay distinct. No engine calls, no asset IDs.

local Candidates: any = require(script.Parent.CropModelCandidates)
local Game: any = require(script.Parent.Config.Game)

type RGB = { r: number, g: number, b: number }
type PartSpec = {
	name: string,
	role: string,
	shape: string,
	size: { number },
	position: { number },
	rotation: { number },
	color: RGB,
}
type Stage = { stage: string, height: number, color: RGB }
type StageSample = {
	plot: number,
	stage: string,
	height: number,
	color: RGB,
	parts: { PartSpec },
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
Data.STEM_WIDTH = 0.24
Data.MIN_STAGE_WIDTH = 1.2
Data.PRODUCT_COLOR = { r = 214, g = 132, b = 46 }
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

local function makePart(
	prefix: string,
	suffix: string,
	role: string,
	shape: string,
	size: { number },
	position: { number },
	color: RGB,
	rotation: { number }?
): PartSpec
	return {
		name = prefix .. "_" .. suffix,
		role = role,
		shape = shape,
		size = size,
		position = position,
		rotation = rotation or { 0, 0, 0 },
		color = copyColor(color),
	}
end

-- Leaf layout per stage. bibit = two side wedges plus a short top wedge (sprout);
-- tumbuh = five wedges in a rising fan; siap = six larger wedges plus three Cylinder produce.
local function leavesFor(stageName: string, prefix: string, x: number, z: number, groundY: number, color: RGB)
	local parts: { PartSpec } = {}
	if stageName == "bibit" then
		local y = groundY + 0.82
		parts[1] = makePart(prefix, "LeafL", "canopy", "Wedge", { 1.35, 0.45, 0.32 }, { x - 0.36, y, z }, color, { 0, 0, -0.28 })
		parts[2] = makePart(prefix, "LeafR", "canopy", "Wedge", { 1.35, 0.45, 0.32 }, { x + 0.36, y, z }, color, { 0, 0, 0.28 })
		parts[3] = makePart(prefix, "LeafTop", "canopy", "Wedge", { 1.35, 0.4, 0.3 }, { x, groundY + 1.0, z }, color)
		return parts
	end

	if stageName == "tumbuh" then
		local fan = {
			{ -1.0, 1.75, -0.45 },
			{ -0.5, 2.05, -0.22 },
			{ 0, 2.2, 0 },
			{ 0.5, 2.05, 0.22 },
			{ 1.0, 1.75, 0.45 },
		}
		for index, blade in ipairs(fan) do
			parts[index] = makePart(
				prefix,
				"Leaf" .. index,
				"canopy",
				"Wedge",
				{ 1.4, 0.8, 0.32 },
				{ x + blade[1], groundY + blade[2], z },
				color,
				{ 0, 0, blade[3] }
			)
		end
		return parts
	end

	local fan = {
		{ -1.2, 2.6, -0.5 },
		{ -0.7, 3.0, -0.3 },
		{ -0.2, 3.2, -0.12 },
		{ 0.2, 3.2, 0.12 },
		{ 0.7, 3.0, 0.3 },
		{ 1.2, 2.6, 0.5 },
	}
	for index, blade in ipairs(fan) do
		parts[index] = makePart(
			prefix,
			"Leaf" .. index,
			"canopy",
			"Wedge",
			{ 1.5, 1.0, 0.36 },
			{ x + blade[1], groundY + blade[2], z },
			color,
			{ 0, 0, blade[3] }
		)
	end
	for index, dx in ipairs({ -0.5, 0, 0.5 }) do
		parts[#parts + 1] = makePart(
			prefix,
			"Produce" .. index,
			"produce",
			"Cylinder",
			{ 0.55, 0.65, 0.55 },
			{ x + dx, groundY + 3.75, z + 0.1 },
			Data.PRODUCT_COLOR
		)
	end
	return parts
end

local function clusterWidth(parts: { PartSpec }): number
	local widest = 0
	for _, part in ipairs(parts) do
		local width = math.max(part.size[1], part.size[3])
		if width > widest then
			widest = width
		end
	end
	return widest
end
Data.clusterWidth = clusterWidth

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
-- height/colour, and a parts array: Cylinder stem, Wedge leaves, plus Cylinder produce when ready.
-- `stem` and `canopy` stay as aliases for the primary stem / first leaf.
function Data.stageParts(): { StageSample }
	local samples: { StageSample } = {}
	for plot = 1, Game.plotCount do
		local baseX, baseZ, ux, uz = plotBasis(plot)
		for index, stage in ipairs(Data.STAGES) do
			local along = (index - 2) * Data.STAGE_SPACING
			local x = baseX - uz * along
			local z = baseZ + ux * along
			local groundY = Data.GROUND_Y
			local color = copyColor(stage.color)
			local prefix = "CropStage_P" .. plot .. "_" .. stage.stage
			local stem = makePart(
				prefix,
				"Stem",
				"stem",
				"Cylinder",
				{ Data.STEM_WIDTH, stage.height, Data.STEM_WIDTH },
				{ x, groundY + stage.height / 2, z },
				color
			)
			local leaves = leavesFor(stage.stage, prefix, x, z, groundY, color)
			local parts = { stem }
			for _, leaf in ipairs(leaves) do
				parts[#parts + 1] = leaf
			end
			samples[#samples + 1] = {
				plot = plot,
				stage = stage.stage,
				height = stage.height,
				color = copyColor(color),
				parts = parts,
				stem = stem,
				canopy = leaves[1],
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
	local leafCounts: { [string]: number } = { bibit = 3, tumbuh = 5, siap = 6 }
	local samples = Data.stageParts()
	assert(#samples == Game.plotCount * #Data.STAGES, "crop_stages_r10: stage sample count is not 30")
	local perPlot: { [number]: { [string]: boolean } } = {}
	for _, sample in ipairs(samples) do
		perPlot[sample.plot] = perPlot[sample.plot] or {}
		assert(perPlot[sample.plot][sample.stage] == nil, "crop_stages_r10: duplicate stage in plot " .. sample.plot)
		perPlot[sample.plot][sample.stage] = true
		local leaves, produce = 0, 0
		for _, part in ipairs(sample.parts) do
			assert(part.shape == "Wedge" or part.shape == "Cylinder", "crop_stages_r10: illegal shape " .. part.shape)
			assert(part.size[1] > 0 and part.size[2] > 0 and part.size[3] > 0, "crop_stages_r10: non-positive part size")
			assert(
				part.position[2] + part.size[2] / 2 <= Data.GROUND_Y + sample.height + 1e-6,
				"crop_stages_r10: part exceeds stage height"
			)
			if part.role == "canopy" then
				leaves += 1
				assert(part.shape == "Wedge", "crop_stages_r10: leaf is not a Wedge")
			elseif part.role == "produce" then
				produce += 1
				assert(part.shape == "Cylinder", "crop_stages_r10: produce is not a Cylinder")
			end
		end
		assert(leaves == leafCounts[sample.stage], "crop_stages_r10: wrong leaf count for " .. sample.stage)
		assert(produce == (if sample.stage == "siap" then 3 else 0), "crop_stages_r10: wrong produce count")
		assert(clusterWidth(sample.parts) >= Data.MIN_STAGE_WIDTH, "crop_stages_r10: stage narrower than 1.2")
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
