--!strict
-- ModelMapBlocksR9: pure data for the OFF-BY-DEFAULT "blocks_r9" LookDev candidate
-- (WORK_QUEUE section O item 145). Trees and shrubs fill the grass blocks between the ring road,
-- the plots and the hubs. No engine APIs, no asset-ID literals: every ID is re-exported by
-- reference from Shared.ModelMapVegetationR7 (verified R4/R6 IDs only). MapSpec lives in
-- ServerScriptService.Server.World, so require this module from the Server VM or the Lune Env.
--
-- The four tree species are stand-ins: mangga uses the R4 broadleaf (no verified true mango),
-- bambu and pisang are baked R4 models scaled down into the 6-12 stud medium canopy band, and
-- teh-tehan is a baked hedge model used as the fourth canopy stand-in. No new ID is invented;
-- a designer replacement needs only new IDs in R7, not a change to the slot geometry.
--
-- Every slot comes from a deterministic LCG over a MapSpec/Config.Game-derived lattice. R5's
-- exclusion zones (paths, hubs, tagged plots, plaza, lapangan), the first clearDistance studs of
-- every named ReviewCameras eye->lookAt ray, plus an explicit footprint-overlap and 3-stud
-- separation test decide acceptance. The applier re-checks with live tagged PlotAnchors.

local Game = require(script.Parent.Config.Game)
local R5 = require(script.Parent.ModelMapVegetationR5)
local R7 = require(script.Parent.ModelMapVegetationR7)
local ReviewCameras = require(script.Parent.ReviewCameras)
local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)

local ModelMapBlocksR9 = {}

ModelMapBlocksR9.id = "blocks_r9"
ModelMapBlocksR9.folderName = "LookDevBlocksR9_blocks_r9"

ModelMapBlocksR9.MIN_TREES = 60
ModelMapBlocksR9.MIN_SHRUBS = 80
ModelMapBlocksR9.MIN_SPECIES = 4
ModelMapBlocksR9.TARGET_TREES = 72
ModelMapBlocksR9.TARGET_SHRUBS = 96
ModelMapBlocksR9.TREE_HEIGHT_MIN = 6
ModelMapBlocksR9.TREE_HEIGHT_MAX = 12
ModelMapBlocksR9.MIN_SPACING = 3
ModelMapBlocksR9.SCALE_JITTER = 0.15
ModelMapBlocksR9.LCG_SEED = 145
ModelMapBlocksR9.LATTICE_STEP = 6
ModelMapBlocksR9.POSITION_JITTER = 1.2
-- Camera-clear sampling: 0.5-stud steps over every ray's first ReviewCameras.clearDistance studs.
ModelMapBlocksR9.CAMERA_SAMPLE_STEP = 0.5
ModelMapBlocksR9.CAMERA_CLEAR_TOLERANCE = 0.5
-- Conservative plot half-span: a fraction of the plot-ring radius, wider than the tagged anchors,
-- so slots rejected by the pure data can never become valid at apply time.
ModelMapBlocksR9.PLOT_RADIUS_FRACTION = 1 / 10
ModelMapBlocksR9.EXTENT = Game.plotRadius * (1 + ModelMapBlocksR9.PLOT_RADIUS_FRACTION) + MapSpec.ROAD.ringWidth

ModelMapBlocksR9.ids = R7.ids
ModelMapBlocksR9.sources = R7.sources

-- asset key -> species label, base height and conservative XZ half-span at that height.
local TREE_PLAN = {
	{ key = "mangga", species = "mangga", height = 9, half = 6 },
	{ key = "bambu", species = "bambu", height = 11, half = 2.5 },
	{ key = "pisang", species = "pisang", height = 8, half = 7 },
	{ key = "teh_tehan", species = "teh-tehan", height = 7, half = 5 },
}
local SHRUB_PLAN = {
	{ key = "shrubs", species = "shrubs", height = 2.5, half = 3 },
	{ key = "bunga", species = "bunga", height = 2, half = 2.5 },
	{ key = "kembang_sepatu", species = "kembang sepatu", height = 3, half = 3 },
	{ key = "alang_alang", species = "alang-alang", height = 2, half = 2 },
}
ModelMapBlocksR9.treePlan = TREE_PLAN
ModelMapBlocksR9.shrubPlan = SHRUB_PLAN

local function lcg(seed)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function()
		state = (state * 48271) % 2147483647
		return (state - 1) / 2147483646
	end
end

local function plotRects()
	local out = {}
	local half = Game.plotRadius * ModelMapBlocksR9.PLOT_RADIUS_FRACTION
	for index = 1, Game.plotCount do
		local x, z = Game.plotCenter(index)
		table.insert(out, { x = x, z = z, halfX = half, halfZ = half })
	end
	return out
end

function ModelMapBlocksR9.exclusionZones(anchorRects)
	return R5.exclusionZones(MapSpec, anchorRects or plotRects())
end

function ModelMapBlocksR9.slotAllowed(slot, zones)
	return R5.slotAllowed(slot, zones)
end

local function footprintsOverlap(a, b)
	return math.abs(a.x - b.x) < a.footprint.halfX + b.footprint.halfX
		and math.abs(a.z - b.z) < a.footprint.halfZ + b.footprint.halfZ
end

-- XZ sample points along the first clearDistance studs of every named review ray. Sampling the
-- horizontal projection is intentionally conservative: a vertical-only ray still yields one
-- sample, and no slot can hide between two 0.5-stud samples once the tolerance is applied.
local cameraSamples: { { x: number, z: number } } = {}
do
	local clear = ReviewCameras.clearDistance
	local steps = math.max(1, math.ceil(clear / ModelMapBlocksR9.CAMERA_SAMPLE_STEP))
	for _, camera in ipairs(ReviewCameras.all()) do
		local eye, look = camera.position, camera.lookAt
		local dx, dy, dz = look[1] - eye[1], look[2] - eye[2], look[3] - eye[3]
		local length = math.sqrt(dx * dx + dy * dy + dz * dz)
		if length > 0 then
			local ux, uz = dx / length, dz / length
			for step = 0, steps do
				local t = math.min(clear, length) * step / steps
				table.insert(cameraSamples, { x = eye[1] + ux * t, z = eye[3] + uz * t })
			end
		end
	end
end

function ModelMapBlocksR9.cameraClear(slot)
	local bottom = MapSpec.GROUND_Y
	local top = bottom + slot.height
	local bandTop = bottom + ReviewCameras.clearDistance
	if top < bottom or bottom > bandTop then
		return false
	end
	local tol = ModelMapBlocksR9.CAMERA_CLEAR_TOLERANCE
	local minX, maxX = slot.x - slot.footprint.halfX - tol, slot.x + slot.footprint.halfX + tol
	local minZ, maxZ = slot.z - slot.footprint.halfZ - tol, slot.z + slot.footprint.halfZ + tol
	for _, point in ipairs(cameraSamples) do
		if point.x >= minX and point.x <= maxX and point.z >= minZ and point.z <= maxZ then
			return false
		end
	end
	return true
end

local function buildSlots()
	local rand = lcg(ModelMapBlocksR9.LCG_SEED)
	local zones = ModelMapBlocksR9.exclusionZones()
	local cells = {}
	local limit = math.floor(ModelMapBlocksR9.EXTENT / ModelMapBlocksR9.LATTICE_STEP)
	for ix = -limit, limit do
		for iz = -limit, limit do
			table.insert(cells, { ix * ModelMapBlocksR9.LATTICE_STEP, iz * ModelMapBlocksR9.LATTICE_STEP })
		end
	end
	for i = #cells, 2, -1 do
		local j = math.floor(rand() * i) + 1
		cells[i], cells[j] = cells[j], cells[i]
	end

	local out, trees, shrubs = {}, 0, 0
	local seen = {}
	local function add(candidate, plan, kind)
		if not ModelMapBlocksR9.slotAllowed(candidate, zones) then
			return false
		end
		if not ModelMapBlocksR9.cameraClear(candidate) then
			return false
		end
		for _, other in ipairs(seen) do
			local dx, dz = candidate.x - other.x, candidate.z - other.z
			if dx * dx + dz * dz < ModelMapBlocksR9.MIN_SPACING ^ 2 then
				return false
			end
			if footprintsOverlap(candidate, other) then
				return false
			end
		end
		candidate.kind = kind
		candidate.index = #out + 1
		candidate.slot = plan.key
		candidate.species = plan.species
		table.insert(out, candidate)
		table.insert(seen, candidate)
		if kind == "tree" then
			trees += 1
		else
			shrubs += 1
		end
		return true
	end

	for _, cell in ipairs(cells) do
		if trees >= ModelMapBlocksR9.TARGET_TREES and shrubs >= ModelMapBlocksR9.TARGET_SHRUBS then
			break
		end
		local wantTree = trees < ModelMapBlocksR9.TARGET_TREES
			and (
				shrubs >= ModelMapBlocksR9.TARGET_SHRUBS
				or trees * ModelMapBlocksR9.TARGET_SHRUBS <= shrubs * ModelMapBlocksR9.TARGET_TREES
			)
		local planList = if wantTree then TREE_PLAN else SHRUB_PLAN
		local plan = planList[math.floor(rand() * #planList) + 1]
		local scale = 1 + (rand() * 2 - 1) * ModelMapBlocksR9.SCALE_JITTER
		local height =
			math.clamp(plan.height * scale, ModelMapBlocksR9.TREE_HEIGHT_MIN, ModelMapBlocksR9.TREE_HEIGHT_MAX)
		local candidate = {
			x = cell[1] + (rand() * 2 - 1) * ModelMapBlocksR9.POSITION_JITTER,
			z = cell[2] + (rand() * 2 - 1) * ModelMapBlocksR9.POSITION_JITTER,
			species = plan.species,
			height = height,
			yaw = rand() * math.pi * 2,
			scale = scale,
			footprint = { halfX = plan.half, halfZ = plan.half },
		}
		add(candidate, plan, if wantTree then "tree" else "shrub")
	end
	return out
end

local SLOTS = buildSlots()

function ModelMapBlocksR9.slots()
	return table.clone(SLOTS)
end

function ModelMapBlocksR9.trees()
	local out = {}
	for _, slot in ipairs(SLOTS) do
		if slot.kind == "tree" then
			table.insert(out, slot)
		end
	end
	return out
end

function ModelMapBlocksR9.shrubs()
	local out = {}
	for _, slot in ipairs(SLOTS) do
		if slot.kind == "shrub" then
			table.insert(out, slot)
		end
	end
	return out
end

function ModelMapBlocksR9.speciesCount(kind)
	local seen = {}
	for _, slot in ipairs(SLOTS) do
		if kind == nil or slot.kind == kind then
			seen[slot.species] = true
		end
	end
	local count = 0
	for _ in pairs(seen) do
		count += 1
	end
	return count
end

function ModelMapBlocksR9.minSpacing(slotList)
	local list = slotList or SLOTS
	local minimum = math.huge
	for i = 1, #list do
		for j = i + 1, #list do
			local dx, dz = list[i].x - list[j].x, list[i].z - list[j].z
			minimum = math.min(minimum, math.sqrt(dx * dx + dz * dz))
		end
	end
	return minimum
end

-- Self-check: pure data must meet the item-145 targets before any Studio check runs.
do
	assert(#ModelMapBlocksR9.trees() >= ModelMapBlocksR9.MIN_TREES, "blocks_r9: fewer than 60 trees")
	assert(#ModelMapBlocksR9.shrubs() >= ModelMapBlocksR9.MIN_SHRUBS, "blocks_r9: fewer than 80 shrubs")
	assert(
		ModelMapBlocksR9.speciesCount("tree") >= ModelMapBlocksR9.MIN_SPECIES,
		"blocks_r9: fewer than 4 tree species"
	)
	assert(ModelMapBlocksR9.minSpacing() >= ModelMapBlocksR9.MIN_SPACING, "blocks_r9: slots closer than 3 studs")
	for _, slot in ipairs(SLOTS) do
		assert(ModelMapBlocksR9.cameraClear(slot), "blocks_r9: slot blocks a review camera")
	end
end

return ModelMapBlocksR9
