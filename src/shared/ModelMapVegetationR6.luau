--!nocheck
-- ModelMapVegetationR6: pure data for the OFF-BY-DEFAULT "vegetation_r6" LookDev candidate
-- (WORK_QUEUE section J item 47). No Roblox APIs, no engine types, no ID literals for the proven
-- R4 families: pisang / bambu / mangga / shrubs are required from ModelMapVegetationR4 whose CC BY
-- provenance is in docs/v2/visual/art/models_r4/vegetation/upload_manifest.json.
--
-- New groups are real free Creator Store Models from the 2026-11-20 shortlist:
-- docs/v2/evidence/h/2026-11-20-r6-vegetation-ids/REPORT.md. No asset was loaded or graded here;
-- no pine and no kelapa. Plant placement follows docs/v2/visual/KAMPUNG_VEGETATION.md.
-- Zone helpers are delegated to ModelMapVegetationR5 (same MapSpec geometry and margins).
--
-- Triangle figures are PLANNING ESTIMATES per slot (1200 tree / 400 shrub / 300 pot / 200 grass),
-- not measurements. They only prove the tier budgets, never claim a rendered triangle count.

local ModelMapVegetationR4 = require(script.Parent.ModelMapVegetationR4)
local ModelMapVegetationR5 = require(script.Parent.ModelMapVegetationR5)
local SpawnDressingMapR5 = require(script.Parent.SpawnDressingMapR5)

local R4_IDS = ModelMapVegetationR4.families.vegetation_r4.ids

local ModelMapVegetationR6 = {}

ModelMapVegetationR6.id = "vegetation_r6"
ModelMapVegetationR6.folderName = "LookDevVegetationR6"

ModelMapVegetationR6.ids = {
	pisang = R4_IDS.pisang,
	bambu = R4_IDS.bambu,
	mangga = R4_IDS.mangga, -- R4 broadleaf stand-in; real mango is a designer build below.
	shrubs = R4_IDS.shrubs,
	-- kembang sepatu: 15344074131, free Creator Store Model, REPORT.md, https://create.roblox.com/store/asset/15344074131.
	kembang_sepatu = 15344074131,
	-- lidah mertua: 184362803, free Creator Store Model, REPORT.md, https://create.roblox.com/store/asset/184362803.
	lidah_mertua = 184362803,
	-- teh-tehan hedge substitute: 8864962424, free Creator Store Model, REPORT.md, https://create.roblox.com/store/asset/8864962424.
	teh_tehan = 8864962424,
	-- alang-alang: 361802126, free Creator Store Model, REPORT.md, https://create.roblox.com/store/asset/361802126.
	alang_alang = 361802126,
	-- ornamental bunga: 9639782964, free Creator Store Model, REPORT.md, https://create.roblox.com/store/asset/9639782964.
	bunga = 9639782964,
}

-- Alternates recorded by the same shortlist. Never loaded by this candidate.
ModelMapVegetationR6.alternates = {
	-- https://create.roblox.com/store/asset/115462020907259 (REPORT.md, free Creator Store Model).
	kembang_sepatu = 115462020907259,
	-- https://create.roblox.com/store/asset/5445549227 (REPORT.md, free Creator Store Model).
	lidah_mertua = 5445549227,
}

-- Exact same tier caps as the round-5 spawn dressing pass; reused, not copied.
ModelMapVegetationR6.budgets = SpawnDressingMapR5.budgets
ModelMapVegetationR6.tiers = SpawnDressingMapR5.tiers

local TIER_RANK = { Rendah = 1, Sedang = 2, Tinggi = 3 }

function ModelMapVegetationR6.tierRank(tier)
	return if type(tier) == "string" and TIER_RANK[tier] then TIER_RANK[tier] else 0
end

-- Same margins and the same single overlap test as R5; the applier supplies tagged anchor rects.
ModelMapVegetationR6.exclusionMargins = ModelMapVegetationR5.exclusionMargins

function ModelMapVegetationR6.exclusionZones(mapSpec, anchorRects)
	return ModelMapVegetationR5.exclusionZones(mapSpec, anchorRects)
end

function ModelMapVegetationR6.pointAllowed(x, z, slotFootprint, zones)
	return ModelMapVegetationR5.pointAllowed(x, z, slotFootprint, zones)
end

function ModelMapVegetationR6.slotAllowed(slot, zones)
	return ModelMapVegetationR5.slotAllowed(slot, zones)
end

-- The R4 vegetation review shot: row across X on the lapangan, fronts toward +Z.
ModelMapVegetationR6.savedCamera = {
	eye = { 0, 20, 150 },
	look = { 0, 8, 96 },
}

local function footprint(halfX, halfZ)
	return { halfX = halfX, halfZ = halfZ }
end

-- Staged clusters sit in the camera band z 92..108, outside the lapangan/hubs/roads. Unstaged
-- clusters fill the rest of the kampung and the real sawah terraces far to the north.
ModelMapVegetationR6.groups = {
	{
		id = "pisang_yard_clumps",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "pisang",
				cluster = "A",
				x = -46,
				z = 100,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "A",
				x = -50,
				z = 102,
				ry = 0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "A",
				x = -43,
				z = 103,
				ry = -0.2,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 46,
				z = 92,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 50,
				z = 94,
				ry = -0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "B",
				x = 43,
				z = 95,
				ry = 0.2,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
		},
	},
	{
		id = "bambu_yard_clumps",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "bambu",
				cluster = "A",
				x = -58,
				z = 104,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -61,
				z = 106,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -55,
				z = 106,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -58,
				z = 108,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "A",
				x = -60,
				z = 100,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 58,
				z = 98,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 61,
				z = 100,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 55,
				z = 100,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 58,
				z = 102,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "B",
				x = 64,
				z = 101,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
		},
	},
	{
		id = "mangga_canopy",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "mangga",
				cluster = "A",
				x = -72,
				z = 100,
				ry = 0,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
			{
				slot = "mangga",
				cluster = "B",
				x = 72,
				z = 100,
				ry = 1.2,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
		},
	},
	{
		id = "hedge_line",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "kembang_sepatu",
				cluster = "A",
				x = -42,
				z = 108,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "A",
				x = -46,
				z = 108,
				ry = 0.4,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "A",
				x = -50,
				z = 108,
				ry = -0.4,
				targetHeight = 3.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "B",
				x = 42,
				z = 100,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "B",
				x = 46,
				z = 100,
				ry = 0.4,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "B",
				x = 50,
				z = 100,
				ry = -0.4,
				targetHeight = 3.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "A",
				x = -54,
				z = 110,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "A",
				x = -58,
				z = 110,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "A",
				x = -62,
				z = 110,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "B",
				x = 54,
				z = 106,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "B",
				x = 58,
				z = 106,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "B",
				x = 62,
				z = 106,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
	{
		id = "lidah_mertua_pots",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "lidah_mertua",
				cluster = "A",
				x = -42,
				z = 96,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "lidah_mertua",
				cluster = "A",
				x = -44,
				z = 98,
				ry = 0.6,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "lidah_mertua",
				cluster = "B",
				x = 42,
				z = 96,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "lidah_mertua",
				cluster = "B",
				x = 44,
				z = 98,
				ry = 0.6,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
		},
	},
	{
		id = "bund_verge",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "alang_alang",
				cluster = "A",
				x = -64,
				z = 106,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "A",
				x = -68,
				z = 106,
				ry = 0.3,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "B",
				x = 64,
				z = 106,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "B",
				x = 68,
				z = 106,
				ry = 0.3,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
	{
		id = "fence_gap_flowers",
		staged = true,
		tier = "Rendah",
		slots = {
			{
				slot = "bunga",
				cluster = "A",
				x = -40,
				z = 110,
				ry = 0,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "bunga",
				cluster = "A",
				x = -42,
				z = 112,
				ry = 0.5,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "bunga",
				cluster = "B",
				x = 40,
				z = 110,
				ry = 0,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "bunga",
				cluster = "B",
				x = 42,
				z = 112,
				ry = 0.5,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
		},
	},
	{
		id = "pisang_kampung",
		staged = false,
		tier = "Sedang",
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
		},
	},
	{
		id = "bambu_kampung",
		staged = false,
		tier = "Sedang",
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
		},
	},
	{
		id = "mangga_kampung",
		staged = false,
		tier = "Sedang",
		slots = {
			{
				slot = "mangga",
				cluster = "A",
				x = -110,
				z = 60,
				ry = 0,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
			{
				slot = "mangga",
				cluster = "B",
				x = 110,
				z = 60,
				ry = 1.2,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(5, 5),
			},
		},
	},
	{
		id = "hedge_fence_kampung",
		staged = false,
		tier = "Sedang",
		slots = {
			{
				slot = "teh_tehan",
				cluster = "A",
				x = -80,
				z = 96,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "A",
				x = -84,
				z = 96,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "A",
				x = -104,
				z = 70,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "A",
				x = -104,
				z = 74,
				ry = 0.4,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "B",
				x = 80,
				z = 96,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "B",
				x = 84,
				z = 96,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "B",
				x = 76,
				z = 90,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "B",
				x = 76,
				z = 94,
				ry = 0.4,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
	{
		id = "lidah_mertua_kampung",
		staged = false,
		tier = "Sedang",
		slots = {
			{
				slot = "lidah_mertua",
				cluster = "A",
				x = -106,
				z = 70,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "lidah_mertua",
				cluster = "B",
				x = 76,
				z = 102,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
		},
	},
	{
		id = "sawah_edge",
		staged = false,
		tier = "Sedang",
		slots = {
			{
				slot = "alang_alang",
				cluster = "A",
				x = -60,
				z = -306,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "A",
				x = -64,
				z = -304,
				ry = 0.4,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "A",
				x = -68,
				z = -306,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "B",
				x = 60,
				z = -306,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "B",
				x = 64,
				z = -304,
				ry = 0.4,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "B",
				x = 68,
				z = -306,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
	{
		id = "fence_gaps_kampung",
		staged = false,
		tier = "Sedang",
		slots = {
			{
				slot = "bunga",
				cluster = "A",
				x = -106,
				z = 74,
				ry = 0,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
			{
				slot = "bunga",
				cluster = "B",
				x = 76,
				z = 100,
				ry = 0,
				targetHeight = 2,
				rotX = 0,
				footprint = footprint(1.5, 1.5),
			},
		},
	},
	{
		id = "pisang_outer",
		staged = false,
		tier = "Tinggi",
		slots = {
			{
				slot = "pisang",
				cluster = "C",
				x = -118,
				z = 110,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "C",
				x = -118,
				z = 114,
				ry = 0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "D",
				x = 98,
				z = 70,
				ry = 0,
				targetHeight = 12,
				rotX = 0,
				footprint = footprint(3, 3),
			},
			{
				slot = "pisang",
				cluster = "D",
				x = 100,
				z = 70,
				ry = 0.3,
				targetHeight = 11,
				rotX = 0,
				footprint = footprint(3, 3),
			},
		},
	},
	{
		id = "bambu_outer",
		staged = false,
		tier = "Tinggi",
		slots = {
			{
				slot = "bambu",
				cluster = "C",
				x = -118,
				z = 118,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = -116,
				z = 118,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = -114,
				z = 118,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = -112,
				z = 118,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "C",
				x = -110,
				z = 118,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "D",
				x = 98,
				z = 60,
				ry = 0,
				targetHeight = 21,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "D",
				x = 98,
				z = 64,
				ry = 0.5,
				targetHeight = 19,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "D",
				x = 100,
				z = 60,
				ry = 1.1,
				targetHeight = 23,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "D",
				x = 100,
				z = 64,
				ry = 1.7,
				targetHeight = 20,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
			{
				slot = "bambu",
				cluster = "D",
				x = 102,
				z = 60,
				ry = 2.3,
				targetHeight = 22,
				rotX = 0,
				footprint = footprint(2.5, 2.5),
			},
		},
	},
	{
		id = "sawah_edge_outer",
		staged = false,
		tier = "Tinggi",
		slots = {
			{
				slot = "alang_alang",
				cluster = "C",
				x = -100,
				z = -306,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "C",
				x = -104,
				z = -304,
				ry = 0.4,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "C",
				x = -108,
				z = -306,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "D",
				x = 100,
				z = -306,
				ry = 0,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "alang_alang",
				cluster = "D",
				x = 104,
				z = -304,
				ry = 0.4,
				targetHeight = 1.5,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "shrubs",
				cluster = "D",
				x = 108,
				z = -306,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
	{
		id = "hedge_outer",
		staged = false,
		tier = "Tinggi",
		slots = {
			{
				slot = "kembang_sepatu",
				cluster = "C",
				x = -118,
				z = 108,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "C",
				x = -118,
				z = 112,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "kembang_sepatu",
				cluster = "D",
				x = 94,
				z = 128,
				ry = 0,
				targetHeight = 4,
				rotX = 0,
				footprint = footprint(2, 2),
			},
			{
				slot = "teh_tehan",
				cluster = "D",
				x = 96,
				z = 128,
				ry = 0,
				targetHeight = 3,
				rotX = 0,
				footprint = footprint(2, 2),
			},
		},
	},
}

-- No verified free source was found for these plants; no ID is invented. Briefs and reference
-- photos live in docs/v2/visual/KAMPUNG_VEGETATION.md.
ModelMapVegetationR6.designerBuilds = {
	{
		slot = "pepaya",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Fast single-stem fruit tree near the house; no clearly-correct free model ID found.",
	},
	{
		slot = "talas",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Taro/keladi in wet shady pockets; no clearly-correct free model ID found.",
	},
	{
		slot = "singkong",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Cassava rows on dry ground above the sawah bund; no clearly-correct free model ID found.",
	},
	{
		slot = "nangka",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Large yard jackfruit tree; no clearly-correct free model ID found.",
	},
	{
		slot = "rambutan",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Mid-size yard fruit tree; no clearly-correct free model ID found.",
	},
	{
		slot = "jambu_air",
		reference = "docs/v2/visual/KAMPUNG_VEGETATION.md",
		note = "Small water-apple tree behind the house; no clearly-correct free model ID found.",
	},
}

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

function ModelMapVegetationR6.estimateTriangles(slot)
	return TRI_ESTIMATES[slot.slot] or 400
end

function ModelMapVegetationR6.slots()
	local out = {}
	for _, group in ipairs(ModelMapVegetationR6.groups) do
		for _, slot in ipairs(group.slots) do
			table.insert(out, slot)
		end
	end
	return out
end

function ModelMapVegetationR6.stagedSlots()
	local out = {}
	for _, group in ipairs(ModelMapVegetationR6.groups) do
		if group.staged then
			for _, slot in ipairs(group.slots) do
				table.insert(out, slot)
			end
		end
	end
	return out
end

-- Cumulative count / planning triangles visible at each tier (staged slots are always included).
function ModelMapVegetationR6.budgetAudit()
	local counts, triangles = {}, {}
	for _, tier in ipairs(ModelMapVegetationR6.tiers) do
		counts[tier], triangles[tier] = 0, 0
	end
	for _, group in ipairs(ModelMapVegetationR6.groups) do
		local rank = ModelMapVegetationR6.tierRank(group.tier)
		for _, slot in ipairs(group.slots) do
			for _, tier in ipairs(ModelMapVegetationR6.tiers) do
				if ModelMapVegetationR6.tierRank(tier) >= rank then
					counts[tier] += 1
					triangles[tier] += ModelMapVegetationR6.estimateTriangles(slot)
				end
			end
		end
	end
	return counts, triangles
end

return ModelMapVegetationR6
