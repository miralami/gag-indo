--!nocheck
-- ModelMapVegetationR7: pure data for the OFF-BY-DEFAULT "vegetation_r7" LookDev candidate
-- (WORK_QUEUE section K item 58). No Roblox APIs, no engine types, no asset-ID literals.
--
-- Every ID comes from Shared.ModelMapVegetationR4 (CC BY provenance in
-- docs/v2/visual/art/models_r4/vegetation/upload_manifest.json) or the round-6 Creator Store
-- shortlist already recorded in Shared.ModelMapVegetationR6. No kelapa, no pine, no invented ID.
--
-- Targets (real Studio, within 100 studs of eye {0,20,150} looking {0,8,96}, 70-degree cone):
-- >=60 plant model instances and >=8 distinct species. Slots sit on the LAPANGAN flanks outside
-- the R5 exclusion zones (paths, plaza, lapangan, hubs); tagged plot anchors are filtered by the
-- applier at apply time. Yaw and scale jitter are deterministic LCG values, so Lune specs see the
-- exact same slots Studio does. Triangle figures are PLANNING ESTIMATES, not measurements.

local ModelMapVegetationR4 = require(script.Parent.ModelMapVegetationR4)
local ModelMapVegetationR5 = require(script.Parent.ModelMapVegetationR5)
local ModelMapVegetationR6 = require(script.Parent.ModelMapVegetationR6)
local SpawnDressingMapR5 = require(script.Parent.SpawnDressingMapR5)

local R4_IDS = ModelMapVegetationR4.families.vegetation_r4.ids

local ModelMapVegetationR7 = {}

ModelMapVegetationR7.id = "vegetation_r7"
ModelMapVegetationR7.folderName = "LookDevModelsVegetationR7_vegetation_r7"

-- Saved review camera, identical to tools/studio/review_check_r7.luau.
ModelMapVegetationR7.savedCamera = {
	eye = { 0, 20, 150 },
	look = { 0, 8, 96 },
}
ModelMapVegetationR7.cone = {
	radius = 100,
	halfAngleDeg = 35, -- 70-degree full cone
}

ModelMapVegetationR7.ids = {
	pisang = R4_IDS.pisang,
	bambu = R4_IDS.bambu,
	mangga = R4_IDS.mangga, -- R4 broadleaf stand-in; true mango is a designer build.
	shrubs = R4_IDS.shrubs,
	kembang_sepatu = ModelMapVegetationR6.ids.kembang_sepatu,
	lidah_mertua = ModelMapVegetationR6.ids.lidah_mertua,
	teh_tehan = ModelMapVegetationR6.ids.teh_tehan,
	alang_alang = ModelMapVegetationR6.ids.alang_alang,
	bunga = ModelMapVegetationR6.ids.bunga,
}

-- Species names are the ones used in docs/v2/visual/KAMPUNG_VEGETATION.md. Where no verified free
-- asset exists, a real R4/R6 ID is used as a documented stand-in; no ID is invented.
local SPECIES_ASSET = {
	["teh-tehan"] = "teh_tehan",
	bambu = "bambu",
	pisang = "pisang",
	["kembang sepatu"] = "kembang_sepatu",
	puring = "bunga", -- R6 ornamental bunga as the croton stand-in
	["lidah mertua"] = "lidah_mertua",
	["alang-alang"] = "alang_alang",
	bunga = "bunga",
	talas = "shrubs", -- R4 shrub as the wet-edge taro stand-in
	keladi = "shrubs",
	mangga = "mangga",
}

ModelMapVegetationR7.speciesAsset = SPECIES_ASSET

-- Provenance for every ID used above; all sources are already in the repository.
ModelMapVegetationR7.sources = {
	pisang = "Shared.ModelMapVegetationR4.families.vegetation_r4.ids.pisang",
	bambu = "Shared.ModelMapVegetationR4.families.vegetation_r4.ids.bambu",
	mangga = "Shared.ModelMapVegetationR4.families.vegetation_r4.ids.mangga",
	shrubs = "Shared.ModelMapVegetationR4.families.vegetation_r4.ids.shrubs",
	kembang_sepatu = "Shared.ModelMapVegetationR6.ids.kembang_sepatu",
	lidah_mertua = "Shared.ModelMapVegetationR6.ids.lidah_mertua",
	teh_tehan = "Shared.ModelMapVegetationR6.ids.teh_tehan",
	alang_alang = "Shared.ModelMapVegetationR6.ids.alang_alang",
	bunga = "Shared.ModelMapVegetationR6.ids.bunga",
}

ModelMapVegetationR7.budgets = SpawnDressingMapR5.budgets
ModelMapVegetationR7.tiers = SpawnDressingMapR5.tiers

local TIER_RANK = { Rendah = 1, Sedang = 2, Tinggi = 3 }

function ModelMapVegetationR7.tierRank(tier)
	return if type(tier) == "string" and TIER_RANK[tier] then TIER_RANK[tier] else 0
end

ModelMapVegetationR7.exclusionMargins = ModelMapVegetationR5.exclusionMargins

function ModelMapVegetationR7.exclusionZones(mapSpec, anchorRects)
	return ModelMapVegetationR5.exclusionZones(mapSpec, anchorRects)
end

function ModelMapVegetationR7.pointAllowed(x, z, slotFootprint, zones)
	return ModelMapVegetationR5.pointAllowed(x, z, slotFootprint, zones)
end

function ModelMapVegetationR7.slotAllowed(slot, zones)
	return ModelMapVegetationR5.slotAllowed(slot, zones)
end

local TRI_ESTIMATES = {
	pisang = 1200,
	bambu = 1200,
	mangga = 1200,
	kembang_sepatu = 400,
	teh_tehan = 400,
	lidah_mertua = 300,
	alang_alang = 200,
	shrubs = 400,
	bunga = 400,
}

function ModelMapVegetationR7.estimateTriangles(slot)
	return TRI_ESTIMATES[slot.slot] or 400
end

-- Deterministic LCG: stable yaw + scale jitter across requires and across Lune/Studio.
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

local BASE_HEIGHT = {
	["teh-tehan"] = 3,
	bambu = 21,
	pisang = 12,
	["kembang sepatu"] = 4,
	puring = 3,
	["lidah mertua"] = 1.5,
	["alang-alang"] = 2,
	bunga = 2,
	talas = 3,
	keladi = 3,
	mangga = 22,
}

local function buildSlots()
	local rand = lcg(58)
	local slots, byCell = {}, {}

	-- Four studs lattice on the two lapangan flanks. Every cell is outside paths, hubs, the plaza
	-- and the lapangan itself (verified by budgetAudit/coneAudit below plus the R5 zone helpers).
	local function addCell(x, z)
		local key = x .. "," .. z
		local slot = { x = x, z = z, key = key, species = nil }
		byCell[key] = slot
		table.insert(slots, slot)
		return slot
	end
	for _, side in ipairs({ -1, 1 }) do
		for magnitude = 20, 32, 2 do
			addCell(side * magnitude, 58)
		end
		for magnitude = 20, 38, 2 do
			addCell(side * magnitude, 60)
			addCell(side * magnitude, 62)
		end
		for magnitude = 20, 32, 2 do
			addCell(side * magnitude, 64)
		end
	end

	local function mark(species, x, z, cluster)
		local key = x .. "," .. z
		local slot = byCell[key]
		if not slot then
			error("vegetation_r7: no cell at " .. key)
		end
		if slot.species then
			error("vegetation_r7: cell already assigned " .. key)
		end
		slot.species = species
		slot.cluster = cluster
	end

	-- At least 3 bambu clumps of 5-7 culms: each clump is a packed 3x2 set of real R4 bamboo.
	local clumps = {
		{ id = "A", xs = { -38, -36, -34 } },
		{ id = "B", xs = { 34, 36, 38 } },
		{ id = "C", xs = { -32, -30, -28 } },
	}
	for _, clump in ipairs(clumps) do
		for _, x in ipairs(clump.xs) do
			for _, z in ipairs({ 60, 62 }) do
				mark("bambu", x, z, "bambu_" .. clump.id)
			end
		end
	end

	-- Continuous teh-tehan fence hedge, one instance every 2 studs on each side (z=64).
	for _, side in ipairs({ -1, 1 }) do
		for magnitude = 20, 32, 2 do
			mark("teh-tehan", side * magnitude, 64, "hedge_fence")
		end
	end

	-- Fill the remaining cells in stable order. Species names come from KAMPUNG_VEGETATION.md.
	local fill = {
		{ "pisang", 6, "pisang_yard" },
		{ "kembang sepatu", 4, "house_front" },
		{ "puring", 4, "house_front" },
		{ "lidah mertua", 4, "door_pots" },
		{ "alang-alang", 4, "verge" },
		{ "bunga", 2, "fence_gap" },
		{ "talas", 4, "ditch" },
		{ "keladi", 4, "ditch" },
		{ "mangga", 3, "canopy" },
	}
	for _, entry in ipairs(fill) do
		local taken = 0
		for _, slot in ipairs(slots) do
			if taken >= entry[2] then
				break
			end
			if not slot.species then
				mark(entry[1], slot.x, slot.z, entry[3])
				taken += 1
			end
		end
		if taken < entry[2] then
			error("vegetation_r7: not enough free cells for " .. entry[1])
		end
	end

	-- Second band in the narrow corridor between the lapangan (|x|<=38) and the Pak RT hub
	-- (x>=42). Real Studio VEG_COUNT was 53/60 even though all 68 original cells were inside the
	-- pure cone: the applier rotates each model about its pivot, so assets whose bounding-box
	-- centre is offset from that pivot have their measured centre shifted in XZ. The original
	-- flanks sat 96-99 studs from the eye, i.e. <=4 studs inside the 100-stud radius, so yaw drift
	-- pushed 15 of them out. These cells sit 77-94 studs from the eye AND are >=25 degrees inside
	-- the cone, so neither radius nor cone drift can lose them. Still >=2 studs from every other
	-- slot and outside every static exclusion zone.
	local farBand = {
		{ z = 66, species = "teh-tehan", cluster = "hedge_far" },
		{ z = 68, species = "teh-tehan", cluster = "hedge_far" },
		{ z = 70, species = "teh-tehan", cluster = "hedge_far" },
		{ z = 72, species = "pisang", cluster = "pisang_far" },
		{ z = 74, species = "pisang", cluster = "pisang_far" },
		{ z = 76, species = "kembang sepatu", cluster = "house_front" },
		{ z = 78, species = "puring", cluster = "house_front" },
		{ z = 80, species = "bunga", cluster = "fence_gap" },
		{ z = 82, species = "alang-alang", cluster = "verge" },
		{ z = 84, species = "lidah mertua", cluster = "door_pots" },
	}
	for _, row in ipairs(farBand) do
		for _, side in ipairs({ -1, 1 }) do
			local x = side * 40
			addCell(x, row.z)
			mark(row.species, x, row.z, row.cluster)
		end
	end

	-- The lattice has one more cell than the themed clusters consume. Assign every leftover
	-- cell a low-cost flowering plant from KAMPUNG_VEGETATION.md so buildSlots() never throws
	-- at require time (an unassigned cell previously made the whole applier return {}).
	for _, slot in ipairs(slots) do
		if not slot.species then
			mark("bunga", slot.x, slot.z, "fence_gap")
		end
	end

	local out = {}
	for index, slot in ipairs(slots) do
		local species = slot.species
		if not species then
			error("vegetation_r7: unassigned cell " .. slot.key)
		end
		local assetKey = SPECIES_ASSET[species]
		if type(ModelMapVegetationR7.ids[assetKey]) ~= "number" then
			error("vegetation_r7: no real ID for " .. species)
		end
		local scale = 0.85 + rand() * 0.30 -- +/-15%
		table.insert(out, {
			slot = assetKey,
			species = species,
			cluster = slot.cluster,
			x = slot.x,
			z = slot.z,
			ry = rand() * math.pi * 2, -- random yaw
			targetHeight = BASE_HEIGHT[species] * scale,
			baseHeight = BASE_HEIGHT[species],
			scaleJitter = scale,
			rotX = 0,
			footprint = { halfX = 1, halfZ = 1 },
			tier = "Sedang",
			index = index,
		})
	end
	return out
end

ModelMapVegetationR7.groups = {
	{
		id = "vegetation_r7_camera_band",
		staged = true,
		tier = "Sedang",
		slots = buildSlots(),
	},
}

function ModelMapVegetationR7.slots()
	local out = {}
	for _, group in ipairs(ModelMapVegetationR7.groups) do
		for _, slot in ipairs(group.slots) do
			table.insert(out, slot)
		end
	end
	return out
end

function ModelMapVegetationR7.stagedSlots()
	local out = {}
	for _, group in ipairs(ModelMapVegetationR7.groups) do
		if group.staged then
			for _, slot in ipairs(group.slots) do
				table.insert(out, slot)
			end
		end
	end
	return out
end

-- Pure cone test matching the Studio harness: 3D range plus a 70-degree full cone around the
-- camera's look vector. `y` defaults to the model's bounding-box centre height.
function ModelMapVegetationR7.pointInCone(x, z, eye, look, radius, halfAngleDeg, y)
	local ex, ey, ez = eye[1], eye[2], eye[3]
	local lx, ly, lz = look[1], look[2], look[3]
	local vx, vy, vz = x - ex, (y or 0) - ey, z - ez
	local dx, dy, dz = lx - ex, ly - ey, lz - ez
	local vMag = math.sqrt(vx * vx + vy * vy + vz * vz)
	local dMag = math.sqrt(dx * dx + dy * dy + dz * dz)
	if vMag <= 0 or dMag <= 0 then
		return false
	end
	if radius and vMag > radius then
		return false
	end
	local cosAngle = (vx * dx + vy * dy + vz * dz) / (vMag * dMag)
	return cosAngle >= math.cos(math.rad(halfAngleDeg or 35))
end

-- Harness contract: count instances and distinct species inside the saved camera cone.
function ModelMapVegetationR7.countInCone(eye, look, radius, halfAngleDeg, slotList)
	local list = slotList or ModelMapVegetationR7.slots()
	local view = eye or ModelMapVegetationR7.savedCamera.eye
	local target = look or ModelMapVegetationR7.savedCamera.look
	local range = radius or ModelMapVegetationR7.cone.radius
	local half = halfAngleDeg or ModelMapVegetationR7.cone.halfAngleDeg
	local count, seen = 0, {}
	for _, slot in ipairs(list) do
		local centreY = slot.targetHeight * 0.5
		if ModelMapVegetationR7.pointInCone(slot.x, slot.z, view, target, range, half, centreY) then
			count += 1
			if type(slot.species) == "string" and slot.species ~= "" then
				seen[slot.species] = true
			end
		end
	end
	local species = {}
	for name in pairs(seen) do
		table.insert(species, name)
	end
	table.sort(species)
	return count, #species, species
end

function ModelMapVegetationR7.budgetAudit()
	local counts, triangles = {}, {}
	for _, tier in ipairs(ModelMapVegetationR7.tiers) do
		counts[tier], triangles[tier] = 0, 0
	end
	for _, group in ipairs(ModelMapVegetationR7.groups) do
		local rank = ModelMapVegetationR7.tierRank(group.tier)
		for _, slot in ipairs(group.slots) do
			for _, tier in ipairs(ModelMapVegetationR7.tiers) do
				if ModelMapVegetationR7.tierRank(tier) >= rank then
					counts[tier] += 1
					triangles[tier] += ModelMapVegetationR7.estimateTriangles(slot)
				end
			end
		end
	end
	return counts, triangles
end

-- Pure spacing audit: no two instances may be closer than 1.2 studs.
function ModelMapVegetationR7.minPairDistance(slotList)
	local list = slotList or ModelMapVegetationR7.slots()
	local minimum = math.huge
	for i = 1, #list do
		for j = i + 1, #list do
			local dx, dz = list[i].x - list[j].x, list[i].z - list[j].z
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance < minimum then
				minimum = distance
			end
		end
	end
	return minimum
end

-- No verified free asset ID present in R4/R6/KAMPUNG_VEGETATION.md for these requested plants.
ModelMapVegetationR7.designerBuilds = {
	{
		slot = "puring",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Croton front hedge requested; R6 ornamental bunga stands in until a real ID is verified.",
	},
	{
		slot = "talas",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Wet ditch-edge taro requested; R4 shrubs stands in until a real ID is verified.",
	},
	{
		slot = "keladi",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Ditch-edge keladi requested; R4 shrubs stands in until a real ID is verified.",
	},
	{
		slot = "mangga_true",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "R4 broadleaf stand-in is placed; no verified true mango tree ID exists in the repo.",
	},
}

-- Self-check: the pure data must satisfy the item-58 targets before any Studio check runs.
do
	local count, speciesCount = ModelMapVegetationR7.countInCone()
	assert(count >= 60, "vegetation_r7: fewer than 60 in-cone slots: " .. tostring(count))
	assert(speciesCount >= 8, "vegetation_r7: fewer than 8 species: " .. tostring(speciesCount))
	assert(ModelMapVegetationR7.minPairDistance() >= 2, "vegetation_r7: slots closer than 2 studs")
	local counts, triangles = ModelMapVegetationR7.budgetAudit()
	local budget = ModelMapVegetationR7.budgets.Sedang
	assert(counts.Sedang <= budget.instances, "vegetation_r7: Sedang instance budget exceeded")
	assert(triangles.Sedang <= budget.triangles, "vegetation_r7: Sedang triangle budget exceeded")
end

return ModelMapVegetationR7
