--!nocheck
-- ModelMapVegetationHubR8: pure data for the OFF-BY-DEFAULT "hubveg_r8" LookDev candidate
-- (WORK_QUEUE section M item 70). Per-hub vegetation dressing, six hubs x 16 slots.
--
-- No asset-ID literals, no Instances, no Enums. Every ID comes from Shared.ModelMapVegetationR7,
-- which itself only references already-approved R4/R6 assets. Every position is derived from
-- MapSpec.HUBS through a seeded polar generator; no hub coordinate is typed here. MapSpec lives in
-- ServerScriptService.Server.World, so require this module from the Server datamodel (or the Lune
-- Env harness), exactly like Shared.ReviewCameras.

local R7 = require(script.Parent.ModelMapVegetationR7)
local R5 = require(script.Parent.ModelMapVegetationR5)
local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)

local ModelMapVegetationHubR8 = {}

ModelMapVegetationHubR8.id = "hubveg_r8"
ModelMapVegetationHubR8.folderName = "LookDevModelsVegetationHubR8_hubveg_r8"
ModelMapVegetationHubR8.hubKeys = MapSpec.HUB_ORDER

ModelMapVegetationHubR8.RADIUS = 40
ModelMapVegetationHubR8.MIN_SPACING = 2
ModelMapVegetationHubR8.MIN_PER_HUB = 12
ModelMapVegetationHubR8.MIN_SPECIES_PER_HUB = 4
ModelMapVegetationHubR8.TARGET_PER_HUB = 16

ModelMapVegetationHubR8.ids = R7.ids
ModelMapVegetationHubR8.speciesAsset = R7.speciesAsset
ModelMapVegetationHubR8.sources = R7.sources
ModelMapVegetationHubR8.exclusionMargins = R5.exclusionMargins

-- Nine documented species; each hub cycles through them with a different offset so every hub
-- gets well over the four-species floor even after runtime plot-anchor rejections. Mangga and
-- pisang are excluded: their 16-24 stud canopies cannot sit outside a hub footprint/road and
-- still stay within RADIUS=40. Nine species still far exceeds the four-species floor.
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
-- AABBs (see tests/specs/hubveg_r8_spec.luau for the measured table). Each value covers the max
-- measured span * 1.41 (random-yaw AABB inflation) + the harness's 0.05 stud overlap tolerance,
-- rounded up. pointAllowed() rejects any slot whose footprint touches a zone, so a slot that passes
-- cannot have its real bounding box overlap a building or path.
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

function ModelMapVegetationHubR8.pointAllowed(x, z, slotFootprint, zones)
	return R5.pointAllowed(x, z, slotFootprint, zones)
end

function ModelMapVegetationHubR8.slotAllowed(slot, zones)
	return R5.slotAllowed(slot, zones)
end

local RADII = {}
for radius = ModelMapVegetationHubR8.RADIUS - 1, 15, -2 do
	table.insert(RADII, radius)
end

local function buildSlots()
	local rand = lcg(8070)
	local zones = ModelMapVegetationHubR8.exclusionZones(MapSpec, {})
	local out = {}
	local index = 0

	local function clearOfPlaced(x, z)
		for _, slot in ipairs(out) do
			local dx, dz = x - slot.x, z - slot.z
			if dx * dx + dz * dz < ModelMapVegetationHubR8.MIN_SPACING ^ 2 then
				return false
			end
		end
		return true
	end

	for hubIndex, hubKey in ipairs(ModelMapVegetationHubR8.hubKeys) do
		local hub = MapSpec.hub(hubKey)
		if not hub then
			error("hubveg_r8: no MapSpec hub for " .. tostring(hubKey))
		end
		local count = 0
		for _, radius in ipairs(RADII) do
			if count >= ModelMapVegetationHubR8.TARGET_PER_HUB then
				break
			end
			for step = 1, 360 do
				if count >= ModelMapVegetationHubR8.TARGET_PER_HUB then
					break
				end
				local angle = (step - 1 + rand() * 0.8) * (math.pi * 2 / 360)
				local r = radius + (rand() - 0.5) * 0.4
				local x, z = hub.x + math.cos(angle) * r, hub.z + math.sin(angle) * r
				local species = SPECIES_ORDER[((hubIndex * 3 + count) % #SPECIES_ORDER) + 1]
				local footprint = FOOTPRINT[species]
				if not footprint then
					error("hubveg_r8: no footprint for " .. tostring(species))
				end
				local probe = { x = x, z = z, footprint = footprint }
				if ModelMapVegetationHubR8.slotAllowed(probe, zones) and clearOfPlaced(x, z) then
					local assetKey = R7.speciesAsset[species]
					if type(R7.ids[assetKey]) ~= "number" then
						error("hubveg_r8: no real ID for " .. tostring(species))
					end
					local baseHeight = BASE_HEIGHT[species]
					if type(baseHeight) ~= "number" then
						error("hubveg_r8: no base height for " .. tostring(species))
					end
					index += 1
					count += 1
					table.insert(out, {
						hub = hubKey,
						species = species,
						slot = assetKey,
						x = x,
						z = z,
						ry = rand() * math.pi * 2,
						targetHeight = baseHeight * (0.85 + rand() * 0.30),
						rotX = 0,
						footprint = footprint,
						index = index,
					})
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
function ModelMapVegetationHubR8.countForHub(key, zones)
	local list = if type(zones) == "table" then zones else ModelMapVegetationHubR8.exclusionZones(MapSpec, {})
	local count = 0
	for _, slot in ipairs(bakedSlots) do
		if slot.hub == key and ModelMapVegetationHubR8.slotAllowed(slot, list) then
			count += 1
		end
	end
	return count
end

function ModelMapVegetationHubR8.speciesForHub(key, zones)
	local list = if type(zones) == "table" then zones else ModelMapVegetationHubR8.exclusionZones(MapSpec, {})
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

-- Self-check: the baked data must satisfy the item-70 targets before any Studio check runs.
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
	end
end

return ModelMapVegetationHubR8
