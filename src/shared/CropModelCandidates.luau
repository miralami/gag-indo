--!strict
-- CropModelCandidates: pure-data low-poly growth-stage recipes for the round-2 "crops" LookDev
-- candidate (WORK_QUEUE item 7). For every crop in Config/Crops there are three stages —
-- bibit (seedling), tumbuh (growing), siap (ready) — built from Roblox primitive parts only.
-- NO asset IDs, no Roblox APIs at load time: this module is pure data + pure functions so the
-- Lune spec can validate all 12 crops x 3 stages without a DataModel.
--
-- An archetype describes a crop's silhouette (stem, leaves, fruit, optional accent). partsFor()
-- expands it into a flat list of part descriptors for a given stage by scaling height, leaf size
-- and fruit size. The client adapter turns descriptors into Parts; the preview generator reads
-- the SAME function so the gallery render can never drift from the shipped models.

local CropModelCandidates = {}

CropModelCandidates.stages = { "bibit", "tumbuh", "siap" }

-- Height / leaf / fruit scaling per stage. bibit is a two-leaf seedling with no fruit;
-- tumbuh has full leaves and small fruit; siap is the full mature silhouette.
CropModelCandidates.stageScale = {
	bibit = { height = 0.34, leafSize = 0.5, leafCap = 2, fruitSize = 0 },
	tumbuh = { height = 0.7, leafSize = 0.85, leafCap = nil, fruitSize = 0.4 },
	siap = { height = 1.0, leafSize = 1.0, leafCap = nil, fruitSize = 1.0 },
}

-- Shapes use Roblox PartType names. Colors are palette tokens from Config/Visuals; the token
-- "crop" means "use this crop's own Config/Crops color". All are from the ART.md §3 palette.
-- Fields:
--   stem  = { shape, size={x,y,z}, color }
--   leaf  = { shape, size, color, count, radius, y }  (y is a fraction of stem height)
--   fruit = { shape, size, color, count, radius, y }  (omitted / fruitSize 0 => none)
--   accent= optional extra descriptor ring: { shape, size, color, count, radius, y }
CropModelCandidates.archetypes = {
	padi = {
		stem = { shape = "Cylinder", size = { 0.16, 3.4, 0.16 }, color = "padi" },
		leaf = { shape = "Wedge", size = { 0.42, 1.7, 0.14 }, color = "daun", count = 5, radius = 0.5, y = 0.72 },
		fruit = { shape = "Sphere", size = { 0.34, 0.62, 0.34 }, color = "kunyit", count = 4, radius = 0.42, y = 0.92 },
	},
	singkong = {
		stem = { shape = "Cylinder", size = { 0.34, 2.8, 0.34 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 0.85, 1.5, 0.18 }, color = "daun", count = 6, radius = 0.85, y = 0.78 },
		fruit = { shape = "Block", size = { 0.5, 0.7, 0.5 }, color = "crop", count = 3, radius = 0.5, y = 0.5 },
	},
	jagung = {
		stem = { shape = "Cylinder", size = { 0.28, 4.0, 0.28 }, color = "padi" },
		leaf = { shape = "Wedge", size = { 0.5, 2.0, 0.16 }, color = "daun", count = 5, radius = 0.7, y = 0.62 },
		fruit = { shape = "Cylinder", size = { 0.6, 1.2, 0.6 }, color = "kunyit", count = 2, radius = 0.34, y = 0.65 },
	},
	bawang = {
		-- Rescaled 2026-11-21 (WORK_QUEUE item 93): the 0.8 stem made bibit's LIVE GetBoundingBox
		-- only ~0.412 studs (< the 0.5 floor). 1.4 lifts bibit to ~0.62 studs while keeping all
		-- three stages inside 0.5..6 and both growth gaps >= 15%. No check threshold was weakened.
		stem = { shape = "Sphere", size = { 0.95, 1.4, 0.95 }, color = "ungu" },
		leaf = { shape = "Cylinder", size = { 0.16, 1.9, 0.16 }, color = "daun", count = 5, radius = 0.22, y = 1.0 },
	},
	cabai = {
		stem = { shape = "Cylinder", size = { 0.24, 2.4, 0.24 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 0.6, 1.0, 0.16 }, color = "daun", count = 7, radius = 0.7, y = 0.6 },
		fruit = { shape = "Cylinder", size = { 0.16, 0.62, 0.16 }, color = "merah", count = 8, radius = 0.62, y = 0.55 },
	},
	tembakau = {
		stem = { shape = "Cylinder", size = { 0.3, 2.6, 0.3 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 1.1, 1.2, 0.2 }, color = "daun", count = 6, radius = 0.95, y = 0.6 },
		fruit = { shape = "Sphere", size = { 0.24, 0.24, 0.24 }, color = "kertas", count = 4, radius = 0.4, y = 0.95 },
	},
	kopi = {
		stem = { shape = "Cylinder", size = { 0.4, 3.0, 0.4 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 0.9, 1.1, 0.18 }, color = "daun", count = 6, radius = 0.9, y = 0.68 },
		fruit = { shape = "Sphere", size = { 0.28, 0.28, 0.28 }, color = "merah", count = 7, radius = 0.72, y = 0.7 },
	},
	tebu = {
		stem = { shape = "Cylinder", size = { 0.34, 4.4, 0.34 }, color = "padi" },
		accent = { shape = "Cylinder", size = { 0.28, 4.0, 0.28 }, color = "bambu", count = 3, radius = 0.45, y = 0.5 },
		leaf = { shape = "Wedge", size = { 0.4, 1.8, 0.14 }, color = "daun", count = 4, radius = 0.6, y = 0.9 },
	},
	kakao = {
		stem = { shape = "Cylinder", size = { 0.5, 3.0, 0.5 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 1.1, 1.3, 0.22 }, color = "daun", count = 6, radius = 1.0, y = 0.78 },
		fruit = { shape = "Sphere", size = { 0.62, 0.85, 0.62 }, color = "genteng", count = 4, radius = 0.42, y = 0.5 },
	},
	cengkeh = {
		stem = { shape = "Cylinder", size = { 0.46, 4.2, 0.46 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 0.75, 1.5, 0.16 }, color = "daun", count = 7, radius = 1.0, y = 0.82 },
		fruit = { shape = "Sphere", size = { 0.22, 0.4, 0.22 }, color = "kunyit", count = 6, radius = 0.7, y = 0.95 },
	},
	durian = {
		stem = { shape = "Cylinder", size = { 0.6, 3.6, 0.6 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 1.2, 1.4, 0.22 }, color = "daun", count = 6, radius = 1.1, y = 0.8 },
		fruit = { shape = "Sphere", size = { 1.1, 1.2, 1.1 }, color = "padi", count = 1, radius = 0, y = 0.52 },
	},
	sawit = {
		stem = { shape = "Cylinder", size = { 0.5, 4.0, 0.5 }, color = "bambu" },
		leaf = { shape = "Wedge", size = { 1.7, 1.0, 0.22 }, color = "daun", count = 7, radius = 1.3, y = 0.95 },
		fruit = { shape = "Sphere", size = { 0.3, 0.3, 0.3 }, color = "genteng", count = 8, radius = 0.5, y = 0.78 },
	},
}

-- Crop ids in config order (kept in sync with Config/Crops.order).
CropModelCandidates.cropIds = {
	"padi",
	"singkong",
	"jagung",
	"bawang",
	"cabai",
	"tembakau",
	"kopi",
	"tebu",
	"kakao",
	"cengkeh",
	"durian",
	"sawit",
}

local function scaled(base: { number }, factor: number): { number }
	return { base[1] * factor, base[2] * factor, base[3] * factor }
end

-- Expand one archetype ring (leaf / fruit / accent) into descriptors for a stage.
local function ring(prefix: string, spec: any, stage: any, stemHeight: number, sizeFactor: number)
	local parts = {}
	local count = spec.count or 1
	if stage.leafCap and prefix == "Leaf" and count > stage.leafCap then
		count = stage.leafCap
	end
	if sizeFactor <= 0 then
		return parts
	end
	for i = 1, count do
		local angle = (i - 1) * (2 * math.pi / count)
		local radius = (spec.radius or 0) * (prefix == "Leaf" and stage.leafSize or 1)
		local y = stemHeight * (spec.y or 0.5)
		parts[#parts + 1] = {
			name = prefix .. i,
			shape = spec.shape,
			size = scaled(spec.size, sizeFactor),
			offset = { math.cos(angle) * radius, y, math.sin(angle) * radius },
			color = spec.color,
		}
	end
	return parts
end

-- The single source of truth for a crop's low-poly parts at a stage. Returns an array of
-- { name, shape, size={x,y,z}, offset={x,y,z}, color } descriptors. Offsets are relative to the
-- crop base (y=0 at the soil), which lets the adapter and the preview render agree exactly.
function CropModelCandidates.partsFor(cropId: string, stageName: string): any?
	local arch = CropModelCandidates.archetypes[cropId]
	local stage = CropModelCandidates.stageScale[stageName]
	if not arch or not stage then
		return nil
	end
	local stemHeight = arch.stem.size[2] * stage.height
	local parts = {
		{
			name = "Stem",
			shape = arch.stem.shape,
			size = scaled(arch.stem.size, stage.height),
			offset = { 0, stemHeight / 2, 0 },
			color = arch.stem.color,
		},
	}
	if arch.accent then
		for _, p in ring("Accent", arch.accent, stage, stemHeight, stage.height) do
			parts[#parts + 1] = p
		end
	end
	for _, p in ring("Leaf", arch.leaf, stage, stemHeight, stage.leafSize) do
		parts[#parts + 1] = p
	end
	if arch.fruit then
		for _, p in ring("Fruit", arch.fruit, stage, stemHeight, stage.fruitSize) do
			parts[#parts + 1] = p
		end
	end
	return parts
end

return CropModelCandidates
