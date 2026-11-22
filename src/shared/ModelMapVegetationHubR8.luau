--!nocheck
-- ModelMapVegetationHubR8: pure data for the OFF-BY-DEFAULT "hubveg_r8" LookDev candidate
-- (WORK_QUEUE section M item 70, densified in section O item 144). Six hubs x 36 slots:
-- 4 door beds + 2 canopy trees + 2 pisang groups of 3 + 2 bamboo clumps of 6 + 12 base slots.
--
-- No asset-ID literals, no Instances, no Enums. Every ID comes from Shared.ModelMapVegetationR7,
-- which itself only references already-approved R4/R6 assets. Every position is derived from
-- MapSpec.HUBS through seeded polar generators; no hub coordinate is typed here. MapSpec lives in
-- ServerScriptService.Server.World, so require this module from the Server datamodel (or the Lune
-- Env harness), exactly like Shared.ReviewCameras.
--
-- Item-144 design choices (all reversible, no target weakened):
--  * Mangga is the canopy tree: scaled to exactly 8 studs (from its 22-stud baked base) so its
--    conservative footprint is 6.2. Full-height mangga still cannot fit near every hub.
--  * Pisang groups are scaled to ~5.7-5.8 studs (from a 12-stud base): a full-height pisang needs a
--    12.4-stud footprint and fits zero positions at Pasar. Members sit <=0.12 studs apart so the
--    scaled bbox + member offsets stay inside the shared 6.2-stud footprint. The canopy-tree
--    clause is carried by mangga; pisang only has to form groups of three.
--  * Canopy slots share one 6.2-stud footprint and one deterministic 3-stud-separated scan: at
--    Pasar only five legal anchors exist for that span, so two independent scans cannot both fill.
--  * Bambu culms are 10.5-12 studs (from a 21-stud base); six offsets inside a 1-stud radius
--    share one 4.0-stud clump footprint.
--  * Door beds at local +/-6,+/-10 x (depth/2 + 5) sit outside the 6-stud lane; Pos Ronda's
--    front is entirely inside the ring-road exclusion zone, so its beds use the nearest allowed
--    front-corner positions (local +/-26,+/-30, depth/2 + 2) instead.
--  * A deterministic 6-stud door corridor is part of slotAllowed(), so no baked slot can land
--    in the road-to-door lane and PATH_REACH measures the same geometry.

local R7 = require(script.Parent.ModelMapVegetationR7)
local R5 = require(script.Parent.ModelMapVegetationR5)
local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)

local ModelMapVegetationHubR8 = {}

ModelMapVegetationHubR8.id = "hubveg_r8"
ModelMapVegetationHubR8.folderName = "LookDevModelsVegetationHubR8_hubveg_r8"
ModelMapVegetationHubR8.hubKeys = MapSpec.HUB_ORDER

ModelMapVegetationHubR8.RADIUS = 40
ModelMapVegetationHubR8.MIN_SPACING = 2
ModelMapVegetationHubR8.MIN_PER_HUB = 30
ModelMapVegetationHubR8.MIN_SPECIES_PER_HUB = 4
ModelMapVegetationHubR8.TARGET_PER_HUB = 36
ModelMapVegetationHubR8.MIN_TREES = 2
ModelMapVegetationHubR8.TREE_HEIGHT_MIN = 8
ModelMapVegetationHubR8.TREE_HEIGHT_MAX = 12
ModelMapVegetationHubR8.PISANG_GROUPS = 2
ModelMapVegetationHubR8.PISANG_GROUP_SIZE = 3
ModelMapVegetationHubR8.BAMBU_CLUMPS = 2
ModelMapVegetationHubR8.BAMBU_CLUMP_MIN = 5
ModelMapVegetationHubR8.BAMBU_CLUMP_MAX = 7
ModelMapVegetationHubR8.BAMBU_CLUMP_SIZE = 6
ModelMapVegetationHubR8.BAMBU_CULM_HEIGHT_MIN = 10
ModelMapVegetationHubR8.DOOR_BEDS_PER_HUB = 4
ModelMapVegetationHubR8.LANE_HALF_WIDTH = 3
ModelMapVegetationHubR8.LANE_LENGTH = 24

ModelMapVegetationHubR8.ids = R7.ids
ModelMapVegetationHubR8.sources = R7.sources
ModelMapVegetationHubR8.exclusionMargins = R5.exclusionMargins

-- R7's speciesAsset table is shared; copy it before adding the two scaled door-bed aliases so no
-- other candidate sees them. All four new keys still resolve to verified R7 IDs.
local speciesAsset = table.clone(R7.speciesAsset)
speciesAsset.mangga_tree = R7.speciesAsset.mangga
speciesAsset.pisang_group = R7.speciesAsset.pisang
speciesAsset.bambu_clump = R7.speciesAsset.bambu
speciesAsset.bunga_bed = R7.speciesAsset.bunga
speciesAsset.shrub_bed = R7.speciesAsset["kembang sepatu"]
ModelMapVegetationHubR8.speciesAsset = speciesAsset

-- Nine base species; every hub cycles through them with a different offset. The four item-144
-- groups use the aliases above and carry their own deterministic footprints.
local SPECIES_ORDER = {
	"bambu",
	"teh-tehan",
	"kembang sepatu",
	"alang-alang",
	"talas",
	"keladi",
	"bunga",
	"puring",
	"lidah mertua",
}
ModelMapVegetationHubR8.speciesOrder = SPECIES_ORDER

-- Conservative XZ half-span per species, measured from a real Studio Play probe of the SCALED model
-- AABBs (see tests/specs/hubveg_r8_spec.luau MEASURED_XZ_SPAN). Each value covers the max
-- measured span * 1.41 (random-yaw AABB inflation) + the harness's 0.05 stud overlap tolerance.
-- The four item-144 entries add the group member offsets on top of that; slotAllowed() rejects
-- any slot whose footprint touches a zone, so a passing slot cannot overlap a building or path.
local FOOTPRINT = {
	bambu = { halfX = 4.5, halfZ = 4.5 },
	["teh-tehan"] = { halfX = 3, halfZ = 3 },
	["kembang sepatu"] = { halfX = 4, halfZ = 4 },
	["alang-alang"] = { halfX = 1.5, halfZ = 1.5 },
	talas = { halfX = 2.5, halfZ = 2.5 },
	keladi = { halfX = 2.5, halfZ = 2.5 },
	bunga = { halfX = 3.5, halfZ = 3.5 },
	puring = { halfX = 5.5, halfZ = 5.5 },
	["lidah mertua"] = { halfX = 1, halfZ = 1 },
	mangga_tree = { halfX = 6.2, halfZ = 6.2 },
	pisang_group = { halfX = 6.2, halfZ = 6.2 },
	bambu_clump = { halfX = 4, halfZ = 4 },
	bunga_bed = { halfX = 1.6, halfZ = 1.6 },
	shrub_bed = { halfX = 1.6, halfZ = 1.6 },
}
ModelMapVegetationHubR8.footprints = FOOTPRINT

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
	mangga_tree = 8,
	pisang_group = 5.8,
	bambu_clump = 12,
	bunga_bed = 0.95,
	shrub_bed = 1.5,
}
ModelMapVegetationHubR8.baseHeights = BASE_HEIGHT

-- Same deterministic LCG as R7: stable jitter across requires and across Lune/Studio.
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

-- R5 zones cover paths, hub footprints, plots, plaza and lapangan. keepOutRects() adds the reserved
-- future slots. Both are converted to the same {x,z,halfX,halfZ} shape R5.pointAllowed expects.
function ModelMapVegetationHubR8.exclusionZones(mapSpec, anchorRects)
	local out = R5.exclusionZones(mapSpec, anchorRects)
	for _, rect in ipairs(mapSpec.keepOutRects()) do
		table.insert(out, {
			name = "keepout",
			x = rect[1],
			z = rect[2],
			halfX = rect[3],
			halfZ = rect[4],
		})
	end
	return out
end

-- All six hub yaw values are multiples of 90 degrees, so folding the four local lane corners into
-- a world AABB is exact. The rectangle runs from the facade plane outward to the road.
local DOOR_LANES = {}
for _, hub in ipairs(MapSpec.HUBS) do
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, localPoint in ipairs({
		{ -ModelMapVegetationHubR8.LANE_HALF_WIDTH, hub.depth / 2 },
		{ ModelMapVegetationHubR8.LANE_HALF_WIDTH, hub.depth / 2 },
		{ -ModelMapVegetationHubR8.LANE_HALF_WIDTH, hub.depth / 2 + ModelMapVegetationHubR8.LANE_LENGTH },
		{ ModelMapVegetationHubR8.LANE_HALF_WIDTH, hub.depth / 2 + ModelMapVegetationHubR8.LANE_LENGTH },
	}) do
		local x, z = MapSpec.hubPoint(hub, localPoint[1], localPoint[2])
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	DOOR_LANES[#DOOR_LANES + 1] = {
		hub = hub.key,
		x = (minX + maxX) / 2,
		z = (minZ + maxZ) / 2,
		halfX = (maxX - minX) / 2,
		halfZ = (maxZ - minZ) / 2,
	}
end
ModelMapVegetationHubR8.doorLanes = DOOR_LANES

function ModelMapVegetationHubR8.clearOfLane(slot)
	for _, lane in ipairs(DOOR_LANES) do
		if
			math.abs(slot.x - lane.x) <= slot.footprint.halfX + lane.halfX
			and math.abs(slot.z - lane.z) <= slot.footprint.halfZ + lane.halfZ
		then
			return false
		end
	end
	return true
end

function ModelMapVegetationHubR8.pointAllowed(x, z, slotFootprint, zones)
	return R5.pointAllowed(x, z, slotFootprint, zones)
end

function ModelMapVegetationHubR8.slotAllowed(slot, zones)
	return R5.slotAllowed(slot, zones) and ModelMapVegetationHubR8.clearOfLane(slot)
end

local RADII = {}
for radius = ModelMapVegetationHubR8.RADIUS - 1, 15, -2 do
	table.insert(RADII, radius)
end

local TAU = math.pi * 2

-- Rotate a small member offset into world axes. Yaw uses MapSpec's sign convention (local +Z maps
-- to (sin yaw, cos yaw)), matching the applier's CFrame rotation.
local function memberOffset(x, z, ry, ox, oz)
	local c, s = math.cos(ry), math.sin(ry)
	return x + ox * c + oz * s, z - ox * s + oz * c
end

local function buildSlots()
	local zones = ModelMapVegetationHubR8.exclusionZones(MapSpec, {})
	local out = {}
	local index = 0

	local function clearOfPlaced(probe)
		for _, slot in ipairs(out) do
			local dx, dz = probe.x - slot.x, probe.z - slot.z
			local need = math.max(probe.spacing or ModelMapVegetationHubR8.MIN_SPACING, slot.spacing or 2)
			if dx * dx + dz * dz < need ^ 2 then
				return false
			end
		end
		return true
	end

	-- One deterministic polar scan per group kind. Big-footprint groups get first refusal so a
	-- later base slot never steals one of their few legal anchors.
	local function scan(hub, hubIndex, kind, wanted, footprint, spacing, seed)
		local rand = lcg(seed + hubIndex * 17)
		local found = {}
		for _, radius in ipairs(RADII) do
			if #found >= wanted then
				break
			end
			for step = 1, 360 do
				if #found >= wanted then
					break
				end
				local angle = (step - 1 + rand() * 0.8) * (TAU / 360)
				local r = radius + (rand() - 0.5) * 0.4
				local x, z = hub.x + math.cos(angle) * r, hub.z + math.sin(angle) * r
				local probe = { x = x, z = z, footprint = footprint, spacing = spacing }
				local clear = true
				for _, other in ipairs(found) do
					local dx, dz = x - other.x, z - other.z
					if dx * dx + dz * dz < spacing ^ 2 then
						clear = false
						break
					end
				end
				if clear and ModelMapVegetationHubR8.slotAllowed(probe, zones) and clearOfPlaced(probe) then
					found[#found + 1] = {
						x = x,
						z = z,
						ry = rand() * TAU,
						variation = rand(),
					}
				end
			end
		end
		if #found < wanted then
			error(
				"hubveg_r8: "
					.. tostring(hub.key)
					.. " fits only "
					.. #found
					.. " "
					.. kind
					.. " slots (need "
					.. wanted
					.. ")"
			)
		end
		return found
	end

	local function add(slot)
		index += 1
		slot.index = index
		out[#out + 1] = slot
		return slot
	end

	for hubIndex, hubKey in ipairs(ModelMapVegetationHubR8.hubKeys) do
		local hub = MapSpec.hub(hubKey)
		if not hub then
			error("hubveg_r8: no MapSpec hub for " .. tostring(hubKey))
		end
		local count = 0

		-- 4 small flower/shrub beds just outside the facade, clear of the 6-stud lane. Pos Ronda's
		-- whole front is inside the ring-road zone, so it uses the nearest allowed front corners.
		local bedOffsets = { -10, -6, 6, 10 }
		if hubKey == "ronda" then
			bedOffsets = { -30, -26, 26, 30 }
		end
		for bedIndex, dx in ipairs(bedOffsets) do
			local lz = hub.depth / 2 + (hubKey == "ronda" and 2 or 5)
			local species = if bedIndex % 2 == 1 then "bunga_bed" else "shrub_bed"
			local footprint = FOOTPRINT[species]
			-- Neighbouring hub bands can overlap (Pasar/Ronda meet near -85,-30), so nudge the
			-- bed deterministically until it clears both the zones and earlier slots.
			local placedBed = false
			for attempt = 0, 14 do
				local nx = dx + ((attempt % 5) - 2) * 0.6
				local nz = lz + math.floor(attempt / 5) * 0.6
				local x, z = MapSpec.hubPoint(hub, nx, nz)
				local probe = { x = x, z = z, footprint = footprint, spacing = 2 }
				if ModelMapVegetationHubR8.slotAllowed(probe, zones) and clearOfPlaced(probe) then
					add({
						hub = hubKey,
						species = species,
						slot = speciesAsset[species],
						kind = "door_bed",
						x = x,
						z = z,
						ry = 0,
						targetHeight = BASE_HEIGHT[species],
						rotX = 0,
						footprint = footprint,
						spacing = 2,
					})
					count += 1
					placedBed = true
					break
				end
			end
			if not placedBed then
				error("hubveg_r8: " .. hubKey .. " door bed " .. bedIndex .. " blocked")
			end
		end

		-- Canopy group: 2 pisang groups of 3 + 2 mangga trees (9-11 studs). Both share the same
		-- conservative 8.5-stud footprint, so they are chosen in ONE 6-separated scan; at Pasar
		-- that footprint has only five legal anchors and two independent scans would fight over
		-- them. Pisang members stay <=0.12 studs from their anchor.
		local canopyCount = ModelMapVegetationHubR8.PISANG_GROUPS + ModelMapVegetationHubR8.MIN_TREES
		local pisangOffsets = { { 0, 0 }, { 0.1, 0.06 }, { -0.08, 0.08 } }
		for canopyIndex, spot in ipairs(scan(hub, hubIndex, "canopy", canopyCount, FOOTPRINT.mangga_tree, 3, 211)) do
			if canopyIndex <= ModelMapVegetationHubR8.PISANG_GROUPS then
				local group = "pisang_" .. hubKey .. "_" .. canopyIndex
				local members = {}
				for memberIndex, offset in ipairs(pisangOffsets) do
					local ox, oz = memberOffset(spot.x, spot.z, spot.ry, offset[1], offset[2])
					members[memberIndex] = {
						x = ox,
						z = oz,
						ry = spot.ry,
						targetHeight = BASE_HEIGHT.pisang_group * (0.98 + spot.variation * 0.02),
					}
				end
				add({
					hub = hubKey,
					species = "pisang_group",
					slot = speciesAsset.pisang_group,
					kind = "pisang_group",
					x = spot.x,
					z = spot.z,
					ry = spot.ry,
					targetHeight = members[1].targetHeight,
					rotX = 0,
					footprint = FOOTPRINT.pisang_group,
					spacing = 3,
					group = group,
					groupKind = "pisang",
					members = members,
				})
			else
				add({
					hub = hubKey,
					species = "mangga_tree",
					slot = speciesAsset.mangga_tree,
					kind = "tree",
					x = spot.x,
					z = spot.z,
					ry = spot.ry,
					targetHeight = BASE_HEIGHT.mangga_tree,
					rotX = 0,
					footprint = FOOTPRINT.mangga_tree,
					spacing = 3,
					tree = true,
					treeIndex = canopyIndex - ModelMapVegetationHubR8.PISANG_GROUPS,
				})
			end
			count += 1
		end

		-- 2 bamboo clumps of 6 culms, each 10.5-12 studs, inside a 1-stud member radius.
		local bambuOffsets = {
			{ 0, 0 },
			{ 0.7, 0 },
			{ -0.7, 0 },
			{ 0, 0.7 },
			{ 0, -0.7 },
			{ 0.45, 0.45 },
		}
		for clumpIndex, spot in
			ipairs(scan(hub, hubIndex, "bambu", ModelMapVegetationHubR8.BAMBU_CLUMPS, FOOTPRINT.bambu_clump, 4, 337))
		do
			local group = "bambu_" .. hubKey .. "_" .. clumpIndex
			local members = {}
			for memberIndex, offset in ipairs(bambuOffsets) do
				local ox, oz = memberOffset(spot.x, spot.z, spot.ry, offset[1], offset[2])
				members[memberIndex] = {
					x = ox,
					z = oz,
					ry = spot.ry,
					targetHeight = 10.5 + ((spot.variation + memberIndex * 0.13) % 1) * 1.5,
				}
			end
			add({
				hub = hubKey,
				species = "bambu_clump",
				slot = speciesAsset.bambu_clump,
				kind = "bambu_clump",
				x = spot.x,
				z = spot.z,
				ry = spot.ry,
				targetHeight = members[1].targetHeight,
				rotX = 0,
				footprint = FOOTPRINT.bambu_clump,
				spacing = 4,
				group = group,
				groupKind = "bambu",
				members = members,
			})
			count += 1
		end

		-- Fill the rest with the original nine-species base layer.
		local rand = lcg(8070 + hubIndex * 31)
		for _, radius in ipairs(RADII) do
			if count >= ModelMapVegetationHubR8.TARGET_PER_HUB then
				break
			end
			for step = 1, 360 do
				if count >= ModelMapVegetationHubR8.TARGET_PER_HUB then
					break
				end
				local angle = (step - 1 + rand() * 0.8) * (TAU / 360)
				local r = radius + (rand() - 0.5) * 0.4
				local x, z = hub.x + math.cos(angle) * r, hub.z + math.sin(angle) * r
				local species = SPECIES_ORDER[((hubIndex * 3 + count) % #SPECIES_ORDER) + 1]
				local footprint = FOOTPRINT[species]
				local probe = { x = x, z = z, footprint = footprint, spacing = 2 }
				if ModelMapVegetationHubR8.slotAllowed(probe, zones) and clearOfPlaced(probe) then
					local assetKey = speciesAsset[species]
					if type(R7.ids[assetKey]) ~= "number" then
						error("hubveg_r8: no real ID for " .. tostring(species))
					end
					local baseHeight = BASE_HEIGHT[species]
					if type(baseHeight) ~= "number" then
						error("hubveg_r8: no base height for " .. tostring(species))
					end
					add({
						hub = hubKey,
						species = species,
						slot = assetKey,
						kind = "base",
						x = x,
						z = z,
						ry = rand() * TAU,
						targetHeight = baseHeight * (0.85 + rand() * 0.30),
						rotX = 0,
						footprint = footprint,
						spacing = 2,
					})
					count += 1
				end
			end
		end
		if count < ModelMapVegetationHubR8.MIN_PER_HUB then
			error(
				"hubveg_r8: hub "
					.. hubKey
					.. " fits only "
					.. count
					.. " slots (need "
					.. ModelMapVegetationHubR8.MIN_PER_HUB
					.. ")"
			)
		end
	end
	return out
end

local bakedSlots = buildSlots()

function ModelMapVegetationHubR8.slots()
	return bakedSlots
end

function ModelMapVegetationHubR8.slotsForHub(key)
	local out = {}
	for _, slot in ipairs(bakedSlots) do
		if slot.hub == key then
			table.insert(out, slot)
		end
	end
	return out
end

-- Pure helpers for the Studio check and the specs. A zones argument lets the applier pass its own
-- runtime zones (including tagged plot anchors) instead of the baked no-anchor set.
local function defaultZones(zones)
	if type(zones) == "table" then
		return zones
	end
	return ModelMapVegetationHubR8.exclusionZones(MapSpec, {})
end

function ModelMapVegetationHubR8.countForHub(key, zones)
	local list = defaultZones(zones)
	local count = 0
	for _, slot in ipairs(bakedSlots) do
		if slot.hub == key and ModelMapVegetationHubR8.slotAllowed(slot, list) then
			count += 1
		end
	end
	return count
end

function ModelMapVegetationHubR8.speciesForHub(key, zones)
	local list = defaultZones(zones)
	local seen, out = {}, {}
	for _, slot in ipairs(bakedSlots) do
		if slot.hub == key and ModelMapVegetationHubR8.slotAllowed(slot, list) and not seen[slot.species] then
			seen[slot.species] = true
			table.insert(out, slot.species)
		end
	end
	table.sort(out)
	return out
end

function ModelMapVegetationHubR8.treesForHub(key, zones)
	local list = defaultZones(zones)
	local count = 0
	for _, slot in ipairs(bakedSlots) do
		if
			slot.hub == key
			and slot.kind == "tree"
			and slot.targetHeight >= ModelMapVegetationHubR8.TREE_HEIGHT_MIN
			and slot.targetHeight <= ModelMapVegetationHubR8.TREE_HEIGHT_MAX
			and ModelMapVegetationHubR8.slotAllowed(slot, list)
		then
			count += 1
		end
	end
	return count
end

function ModelMapVegetationHubR8.pisangGroupsForHub(key, zones)
	local list = defaultZones(zones)
	local seen, count = {}, 0
	for _, slot in ipairs(bakedSlots) do
		if
			slot.hub == key
			and slot.kind == "pisang_group"
			and slot.members
			and #slot.members == ModelMapVegetationHubR8.PISANG_GROUP_SIZE
			and not seen[slot.group]
			and ModelMapVegetationHubR8.slotAllowed(slot, list)
		then
			seen[slot.group] = true
			count += 1
		end
	end
	return count
end

function ModelMapVegetationHubR8.bambuClumpsForHub(key, zones)
	local list = defaultZones(zones)
	local seen, count = {}, 0
	for _, slot in ipairs(bakedSlots) do
		if
			slot.hub == key
			and slot.kind == "bambu_clump"
			and slot.members
			and #slot.members >= ModelMapVegetationHubR8.BAMBU_CLUMP_MIN
			and #slot.members <= ModelMapVegetationHubR8.BAMBU_CLUMP_MAX
			and not seen[slot.group]
			and ModelMapVegetationHubR8.slotAllowed(slot, list)
		then
			local tall = true
			for _, member in ipairs(slot.members) do
				if member.targetHeight < ModelMapVegetationHubR8.BAMBU_CULM_HEIGHT_MIN then
					tall = false
					break
				end
			end
			if tall then
				seen[slot.group] = true
				count += 1
			end
		end
	end
	return count
end

-- Self-check: the baked data must satisfy the item-144 targets before any Studio check runs.
do
	for _, hubKey in ipairs(ModelMapVegetationHubR8.hubKeys) do
		local list = ModelMapVegetationHubR8.slotsForHub(hubKey)
		if #list < ModelMapVegetationHubR8.MIN_PER_HUB then
			error("hubveg_r8: " .. hubKey .. " has " .. #list .. " slots")
		end
		local seen = {}
		for _, slot in ipairs(list) do
			local dx, dz = slot.x - MapSpec.hub(hubKey).x, slot.z - MapSpec.hub(hubKey).z
			if dx * dx + dz * dz > ModelMapVegetationHubR8.RADIUS ^ 2 then
				error("hubveg_r8: " .. hubKey .. " slot outside radius")
			end
			seen[slot.species] = (seen[slot.species] or 0) + 1
		end
		local species = 0
		for _ in pairs(seen) do
			species += 1
		end
		if species < ModelMapVegetationHubR8.MIN_SPECIES_PER_HUB then
			error("hubveg_r8: " .. hubKey .. " has " .. species .. " species")
		end
		if ModelMapVegetationHubR8.treesForHub(hubKey) < ModelMapVegetationHubR8.MIN_TREES then
			error("hubveg_r8: " .. hubKey .. " has too few trees")
		end
		if ModelMapVegetationHubR8.pisangGroupsForHub(hubKey) < ModelMapVegetationHubR8.PISANG_GROUPS then
			error("hubveg_r8: " .. hubKey .. " has too few pisang groups")
		end
		if ModelMapVegetationHubR8.bambuClumpsForHub(hubKey) < ModelMapVegetationHubR8.BAMBU_CLUMPS then
			error("hubveg_r8: " .. hubKey .. " has too few bambu clumps")
		end
	end
end

return ModelMapVegetationHubR8
