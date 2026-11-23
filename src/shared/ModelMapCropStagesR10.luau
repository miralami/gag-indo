--!strict
-- ModelMapCropStagesR10: pure data for the OFF-BY-DEFAULT "crop_stages_r10" reference-stage overlay
-- (WORK_QUEUE items 206 / 254 / 263, rebuilt after the sprint-5 hero shots showed thin slivers).
-- The default crop models are never touched: a SERVER applier stages anchored, non-collidable
-- crop-shaped Parts in each plot's outer area away from its gate, so every plot_aerial_NN camera
-- can raycast its OWN plot's bibit/tumbuh/siap. Each stage is now a ROW of three plants, one per
-- tile pitch, and the three rows sit side by side (sprout row, young row, ready row). A plant is an
-- upright Cylinder stem plus a fan of Wedge leaves (and, when ready, a cluster of Cylinder produce
-- in the crop colour). No Ball part, no SmoothPlastic: materials are names the applier maps to
-- textured Grass / LeafyGrass / Fabric.
-- Plant sizes (a leaf fan is twice its leaf length wide): sprout 1.2 tall x 1.6 wide, young
-- 2.2 x 2.0, ready 3.0 x 2.0. There is no dedicated Blender model for these stages, so every
-- stage stays primitives-only.

local Candidates: any = require(script.Parent.CropModelCandidates)
local Game: any = require(script.Parent.Config.Game)

type RGB = { r: number, g: number, b: number }
type PartSpec = {
	name: string,
	role: string,
	shape: string,
	material: string,
	plant: number,
	size: { number },
	position: { number },
	rotation: { number },
	color: RGB,
}
type Stage = { stage: string, height: number, color: RGB }
type Produce = { crop: string, color: RGB, length: number, width: number, count: number, radius: number, y: number }
type StageSample = {
	plot: number,
	stage: string,
	height: number,
	color: RGB,
	parts: { PartSpec },
	plants: { { PartSpec } },
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
Data.TILE_PITCH = 7.5 -- 6-stud tile + 1.5 gap: one plant per tile centre, rows one pitch apart
Data.STAGE_SPACING = Data.TILE_PITCH -- row-to-row distance, tangential
Data.PLANTS_PER_ROW = 3 -- plants per row, radial
Data.STEM_WIDTH = 0.25
Data.MIN_STAGE_WIDTH = 1.5 -- item 263: every plant >= 1.5 studs wide
Data.REFERENCE_CROP = "reference"
Data.MIN_HUE_DISTANCE = 0.15
Data.PLANT_ROTATION_Z = math.pi / 2 -- turns a Cylinder's X axis upright
Data.MATERIAL_STEM = "Grass"
Data.MATERIAL_LEAF = "LeafyGrass"
Data.MATERIAL_PRODUCE = "Fabric"

local STAGES: { Stage } = {
	{ stage = "bibit", height = 1.2, color = { r = 110, g = 170, b = 80 } },
	{ stage = "tumbuh", height = 2.2, color = { r = 80, g = 155, b = 65 } },
	{ stage = "siap", height = 3.0, color = { r = 64, g = 120, b = 52 } },
}
Data.STAGES = STAGES

-- Leaf fan per stage: count, leaf length (fan width = 2 x length), leaf width and the two heights
-- the leaves alternate between. Stem length and diameter come with it.
local FANS: { [string]: any } = {
	bibit = { count = 4, length = 0.8, width = 0.45, heights = { 1.2, 1.0 }, stem = 0.5 },
	tumbuh = { count = 6, length = 1.0, width = 0.55, heights = { 2.2, 1.7 }, stem = 1.4 },
	siap = { count = 6, length = 1.0, width = 0.55, heights = { 2.4, 1.9 }, stem = 2.6 },
}
Data.FANS = FANS

-- Ready-stage produce per plot, cycling red chili / white shallot / golden rice panicle. Lengths
-- run along the vertical; tops stay <= the 3.0 ready height.
local PRODUCES: { Produce } = {
	{
		crop = "cabai",
		color = { r = 200, g = 40, b = 35 },
		length = 1.0,
		width = 0.22,
		count = 6,
		radius = 0.5,
		y = 2.5,
	},
	{
		crop = "bawang",
		color = { r = 240, g = 232, b = 215 },
		length = 0.55,
		width = 0.7,
		count = 5,
		radius = 0.5,
		y = 2.7,
	},
	{
		crop = "padi",
		color = { r = 232, g = 190, b = 62 },
		length = 0.9,
		width = 0.22,
		count = 6,
		radius = 0.45,
		y = 2.55,
	},
}
Data.PRODUCES = PRODUCES

function Data.produceFor(plot: number): Produce
	return PRODUCES[((plot - 1) % #PRODUCES) + 1]
end

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
	material: string,
	plant: number,
	size: { number },
	position: { number },
	color: RGB,
	rotation: { number }
): PartSpec
	return {
		name = prefix .. "_" .. suffix,
		role = role,
		shape = shape,
		material = material,
		plant = plant,
		size = size,
		position = position,
		rotation = rotation,
		color = copyColor(color),
	}
end

-- One plant: upright stem, a fan of leaf wedges (each runs from the stem outward along its yaw,
-- so opposite leaves give a fan twice the leaf length wide) and, when ready, produce around the top.
local function plantParts(
	stageName: string,
	prefix: string,
	plant: number,
	x: number,
	z: number,
	color: RGB,
	produce: Produce
): { PartSpec }
	local fan = FANS[stageName]
	local groundY = Data.GROUND_Y
	local parts: { PartSpec } = {}
	parts[1] = makePart(
		prefix,
		"Stem",
		"stem",
		"Cylinder",
		Data.MATERIAL_STEM,
		plant,
		{ fan.stem, Data.STEM_WIDTH, Data.STEM_WIDTH },
		{ x, groundY + fan.stem / 2, z },
		color,
		{ 0, 0, Data.PLANT_ROTATION_Z }
	)
	local step = 2 * math.pi / fan.count
	for index = 1, fan.count do
		local yaw = (index - 1) * step + 0.35
		local height = fan.heights[((index - 1) % #fan.heights) + 1]
		local reach = fan.length / 2
		parts[#parts + 1] = makePart(
			prefix,
			"Leaf" .. index,
			"canopy",
			"Wedge",
			Data.MATERIAL_LEAF,
			plant,
			{ fan.width, height, fan.length },
			{ x + math.sin(yaw) * reach, groundY + height / 2, z + math.cos(yaw) * reach },
			color,
			{ 0, yaw, 0 }
		)
	end
	if stageName == "siap" then
		local step2 = 2 * math.pi / produce.count
		for index = 1, produce.count do
			local angle = (index - 1) * step2
			parts[#parts + 1] = makePart(
				prefix,
				"Produce" .. index,
				"produce",
				"Cylinder",
				Data.MATERIAL_PRODUCE,
				plant,
				{ produce.length, produce.width, produce.width },
				{ x + math.sin(angle) * produce.radius, groundY + produce.y, z + math.cos(angle) * produce.radius },
				produce.color,
				{ 0, 0, Data.PLANT_ROTATION_Z }
			)
		end
	end
	return parts
end

-- Horizontal extent of ONE plant: the larger of its X and Z spans, from each part's rotated
-- footprint (yaw-rotated Wedge boxes; upright Cylinders are round). Pass a single plant's parts.
local function plantWidth(parts: { PartSpec }): number
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, part in ipairs(parts) do
		local hx, hz = part.size[1] / 2, part.size[3] / 2
		local yaw = part.rotation[2]
		if part.shape == "Cylinder" then
			hx, hz, yaw = part.size[2] / 2, part.size[3] / 2, 0
		end
		local cosY, sinY = math.cos(yaw), math.sin(yaw)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local lx, lz = sx * hx, sz * hz
				local wx = part.position[1] + lx * cosY + lz * sinY
				local wz = part.position[3] - lx * sinY + lz * cosY
				minX, maxX = math.min(minX, wx), math.max(maxX, wx)
				minZ, maxZ = math.min(minZ, wz), math.max(maxZ, wz)
			end
		end
	end
	return math.max(maxX - minX, maxZ - minZ)
end
Data.plantWidth = plantWidth
Data.clusterWidth = plantWidth

-- Highest point of a part, honouring the upright Cylinder rotation.
local function partTop(part: PartSpec): number
	local half = if part.shape == "Cylinder" then part.size[1] / 2 else part.size[2] / 2
	return part.position[2] + half
end
Data.partTop = partTop

-- Plot cluster centre = plot centre + a small outward offset. `ux/uz` is the outward radial and
-- `(-uz, ux)` the tangential direction used to line the stage rows up inside the plot.
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

-- Three stage samples PER PLOT (plot count x 3), each one a ROW of PLANTS_PER_ROW plants. `plants`
-- keeps each plant's parts apart; `parts` is the flat row; `stem` and `canopy` alias the first
-- plant's stem / first leaf.
function Data.stageParts(): { StageSample }
	local samples: { StageSample } = {}
	for plot = 1, Game.plotCount do
		local baseX, baseZ, ux, uz = plotBasis(plot)
		local produce = Data.produceFor(plot)
		for index, stage in ipairs(Data.STAGES) do
			local along = (index - 2) * Data.STAGE_SPACING
			local color = copyColor(stage.color)
			local plants: { { PartSpec } } = {}
			local flat: { PartSpec } = {}
			for plant = 1, Data.PLANTS_PER_ROW do
				local radial = (plant - (Data.PLANTS_PER_ROW + 1) / 2) * Data.TILE_PITCH
				local x = baseX + ux * radial - uz * along
				local z = baseZ + uz * radial + ux * along
				local prefix = "CropStage_P" .. plot .. "_" .. stage.stage .. "_" .. plant
				local parts = plantParts(stage.stage, prefix, plant, x, z, color, produce)
				plants[plant] = parts
				for _, part in ipairs(parts) do
					flat[#flat + 1] = part
				end
			end
			samples[#samples + 1] = {
				plot = plot,
				stage = stage.stage,
				height = stage.height,
				color = color,
				parts = flat,
				plants = plants,
				stem = plants[1][1],
				canopy = plants[1][2],
			}
		end
	end
	return samples
end

-- Load-time contract check: keeps the correction honest before any applier or harness reads it.
do
	assert(#Data.STAGES == 3, "crop_stages_r10: stage count is not 3")
	assert(Data.MIN_STAGE_WIDTH >= 1.5, "crop_stages_r10: stage width contract below 1.5")
	assert(Data.PLANTS_PER_ROW >= 3, "crop_stages_r10: fewer than three plants per row")
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
	for _, produce in ipairs(Data.PRODUCES) do
		assert(
			produce.y + produce.length / 2 <= Data.STAGES[3].height + 1e-6,
			"crop_stages_r10: produce above ready height"
		)
	end
	local samples = Data.stageParts()
	assert(#samples == Game.plotCount * #Data.STAGES, "crop_stages_r10: stage sample count is not 30")
	local perPlot: { [number]: { [string]: boolean } } = {}
	for _, sample in ipairs(samples) do
		perPlot[sample.plot] = perPlot[sample.plot] or {}
		assert(perPlot[sample.plot][sample.stage] == nil, "crop_stages_r10: duplicate stage in plot " .. sample.plot)
		perPlot[sample.plot][sample.stage] = true
		assert(#sample.plants == Data.PLANTS_PER_ROW, "crop_stages_r10: wrong plant count in a row")
		for _, plant in ipairs(sample.plants) do
			local leaves, produce = 0, 0
			for _, part in ipairs(plant) do
				assert(
					part.shape == "Wedge" or part.shape == "Cylinder",
					"crop_stages_r10: illegal shape " .. part.shape
				)
				assert(
					part.material ~= "SmoothPlastic" and part.material ~= "Plastic",
					"crop_stages_r10: untextured material"
				)
				assert(
					part.size[1] > 0 and part.size[2] > 0 and part.size[3] > 0,
					"crop_stages_r10: non-positive part size"
				)
				assert(
					partTop(part) <= Data.GROUND_Y + sample.height + 1e-6,
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
			assert(leaves == FANS[sample.stage].count, "crop_stages_r10: wrong leaf count for " .. sample.stage)
			assert(
				produce == (if sample.stage == "siap" then Data.produceFor(sample.plot).count else 0),
				"crop_stages_r10: wrong produce count"
			)
			assert(plantWidth(plant) >= Data.MIN_STAGE_WIDTH, "crop_stages_r10: plant narrower than 1.5")
		end
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
