--!nocheck
-- ModelMapVegetationR5: pure data for the OFF-BY-DEFAULT "vegetation_r5" LookDev candidate
-- (WORK_QUEUE round 5 item 37). No Roblox APIs, no engine types, no asset-ID literals: the three
-- placed model IDs are read from Shared.ModelMapVegetationR4, whose real CC BY provenance is recorded
-- in docs/v2/visual/art/models_r4/vegetation/upload_manifest.json.
--
-- Designer notes (2026-11-20): pisang is good; kelapa stays out of spawn but its asset is kept for a
-- later level; bamboo must be dense clumps, not single thin poles; pines are banned (V-D4). The
-- disabled kelapa group at the bottom is data only and is NEVER iterated by the applier.
--
-- Zones are built here from MapSpec geometry plus tagged PlotAnchor rectangles supplied by the
-- server applier. Every slot carries its own XZ footprint; pointAllowed() is the single overlap test.

local ModelMapVegetationR4 = require(script.Parent.ModelMapVegetationR4)
local R4_IDS = ModelMapVegetationR4.families.vegetation_r4.ids

local ModelMapVegetationR5 = {}

ModelMapVegetationR5.id = "vegetation_r5"
ModelMapVegetationR5.folderName = "LookDevVegetationR5"
ModelMapVegetationR5.sourceFamily = "vegetation_r4"

-- Only placed assets. Kelapa is deliberately absent: see otherLevels below.
ModelMapVegetationR5.ids = {
	pisang = R4_IDS.pisang,
	bambu = R4_IDS.bambu,
	mangga = R4_IDS.mangga, -- R4 broadleaf stand-in; true mango is a Designer build (see below).
}

-- Conservative XZ slack added to each rectangle. Margins live in data, not in the applier.
ModelMapVegetationR5.exclusionMargins = {
	path = 3,
	hub = 2,
	plot = 3,
	open = 2,
}

local MARGINS = ModelMapVegetationR5.exclusionMargins

local function footprint(halfX, halfZ)
	return { halfX = halfX, halfZ = halfZ }
end

local function rect(name, x, z, halfX, halfZ)
	return { name = name, x = x, z = z, halfX = halfX, halfZ = halfZ }
end

-- A conservative AABB of a rotated road piece; touch counts as overlap because the margins already
-- add slack and a touching tree canopy is exactly what the designer flagged.
local function pathRect(name, x, z, sx, sz, yaw)
	local radians = math.rad(yaw or 0)
	local c, s = math.abs(math.cos(radians)), math.abs(math.sin(radians))
	return rect(
		name,
		x,
		z,
		(math.abs(sx) * c + math.abs(sz) * s) / 2 + MARGINS.path,
		(math.abs(sx) * s + math.abs(sz) * c) / 2 + MARGINS.path
	)
end

function ModelMapVegetationR5.pathZones(mapSpec)
	local out = {}
	for _, arm in ipairs(mapSpec.roadArms()) do
		table.insert(out, pathRect(arm.name, arm.x, arm.z, arm.sx, arm.sz, 0))
	end
	for _, piece in ipairs(mapSpec.ringSegments()) do
		table.insert(out, pathRect("RingRoad", piece.x, piece.z, piece.length, mapSpec.ROAD.ringWidth, piece.yaw))
	end
	for _, link in ipairs(mapSpec.roadContinuations()) do
		table.insert(out, pathRect(link.name, link.x, link.z, link.sx, link.sz, 0))
	end
	return out
end

function ModelMapVegetationR5.hubZones(mapSpec)
	local out = {}
	for _, hub in ipairs(mapSpec.HUBS) do
		local b = mapSpec.hubBounds(hub)
		table.insert(
			out,
			rect(
				"hub:" .. hub.key,
				(b.minX + b.maxX) / 2,
				(b.minZ + b.maxZ) / 2,
				(b.maxX - b.minX) / 2 + MARGINS.hub,
				(b.maxZ - b.minZ) / 2 + MARGINS.hub
			)
		)
	end
	return out
end

-- anchorRects come from the server applier: tagged PlotAnchor BaseParts converted to {x,z,halfX,halfZ}.
function ModelMapVegetationR5.plotZones(anchorRects)
	local out = {}
	for _, anchor in ipairs(anchorRects or {}) do
		table.insert(out, rect("plot", anchor.x, anchor.z, anchor.halfX + MARGINS.plot, anchor.halfZ + MARGINS.plot))
	end
	return out
end

-- The plaza and lapangan are kept clear too: trees there are what made round 4 look messy.
function ModelMapVegetationR5.openZones(mapSpec)
	local out = {}
	for _, open in ipairs({ mapSpec.PLAZA, mapSpec.LAPANGAN }) do
		table.insert(out, rect("open", open.x, open.z, open.width / 2 + MARGINS.open, open.depth / 2 + MARGINS.open))
	end
	return out
end

function ModelMapVegetationR5.exclusionZones(mapSpec, anchorRects)
	local out = {}
	for _, group in ipairs({
		ModelMapVegetationR5.pathZones(mapSpec),
		ModelMapVegetationR5.hubZones(mapSpec),
		ModelMapVegetationR5.plotZones(anchorRects),
		ModelMapVegetationR5.openZones(mapSpec),
	}) do
		for _, zone in ipairs(group) do
			table.insert(out, zone)
		end
	end
	return out
end

function ModelMapVegetationR5.pointAllowed(x, z, treeFootprint, zones)
	local halfX = treeFootprint and treeFootprint.halfX or 0
	local halfZ = treeFootprint and treeFootprint.halfZ or 0
	for _, zone in ipairs(zones or {}) do
		if math.abs(x - zone.x) <= halfX + zone.halfX and math.abs(z - zone.z) <= halfZ + zone.halfZ then
			return false
		end
	end
	return true
end

function ModelMapVegetationR5.slotAllowed(slot, zones)
	return ModelMapVegetationR5.pointAllowed(slot.x, slot.z, slot.footprint, zones)
end

-- Positions are chosen on real MapSpec terrain, outside every static zone. `cluster` groups the
-- repeated slots of one clump; each bamboo clump has five offset stalks of the SAME R4 model.
ModelMapVegetationR5.groups = {
	{
		id = "pisang_clusters",
		slots = {
			{
				slot = "pisang",
				cluster = "A",
				x = -64,
				z = 34,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "A",
				x = -68,
				z = 37,
				ry = 0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "A",
				x = -60,
				z = 38,
				ry = -0.2,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 64,
				z = 34,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 60,
				z = 37,
				ry = -0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 68,
				z = 38,
				ry = 0.2,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "C",
				x = -30,
				z = 56,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "C",
				x = -34,
				z = 59,
				ry = 0.4,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "C",
				x = -27,
				z = 61,
				ry = -0.4,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
		},
	},
	{
		id = "bambu_clumps",
		slots = {
			{
				slot = "bambu",
				cluster = "A",
				x = -104,
				z = 44,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -107,
				z = 46,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -101,
				z = 46,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -105,
				z = 49,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -102,
				z = 50,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 104,
				z = 44,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 101,
				z = 46,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 107,
				z = 46,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 103,
				z = 49,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 106,
				z = 50,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = 32,
				z = 56,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = 29,
				z = 59,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = 35,
				z = 59,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = 31,
				z = 62,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = 34,
				z = 63,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
		},
	},
	{
		id = "mangga_standin",
		slots = {
			{
				slot = "mangga",
				cluster = "A",
				x = -58,
				z = 108,
				ry = 0,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
			{
				slot = "mangga",
				cluster = "B",
				x = 58,
				z = 108,
				ry = 1.2,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
		},
	},
} :: { { id: string, slots: { any } } }

-- No verified free mango tree exists in the repo. Keep the R4 broadleaf stand-in reference and
-- hand the real model to the designer; do not invent a new asset ID.
ModelMapVegetationR5.designerBuilds = {
	{
		slot = "mangga_true",
		note = "Designer build needed: no CC0/CC BY true mango tree was verified; R4 broadleaf stand-in stays.",
		reference = "docs/v2/visual/art/models_r4/vegetation/HANDOFF.md",
	},
}

-- KEPT FOR ANOTHER LEVEL, NEVER PLACED HERE. The applier iterates groups only; this entry is an
-- explicitly disabled data reference so the real R4 kelapa ID is not lost (round-5 designer note,
-- V-D4 no pines/kelapa at spawn). No pine asset is recorded at all.
ModelMapVegetationR5.otherLevels = {
	{
		id = "kelapa_other_level",
		enabled = false,
		modelKey = "kelapa",
		modelId = R4_IDS.kelapa,
		note = "Keep the real R4 kelapa asset for a later level; never placed by vegetation_r5.",
		slots = {
			{ slot = "kelapa", x = -72, z = 108, ry = 0, targetHeight = 30, rotX = 0, footprint = footprint(6, 6) },
		},
	},
}

function ModelMapVegetationR5.slots()
	local out = {}
	for _, group in ipairs(ModelMapVegetationR5.groups) do
		for _, slot in ipairs(group.slots) do
			table.insert(out, slot)
		end
	end
	return out
end

function ModelMapVegetationR5.placedKeys()
	local keys = {}
	for _, slot in ipairs(ModelMapVegetationR5.slots()) do
		keys[slot.slot] = true
	end
	return keys
end

return ModelMapVegetationR5
