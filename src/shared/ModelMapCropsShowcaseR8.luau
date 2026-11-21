--!strict
-- ModelMapCropsShowcaseR8: pure data for the OFF-BY-DEFAULT "crops_showcase_r8" LookDev candidate
-- (WORK_QUEUE section N item 118). Three review plots, one per growth stage (bibit, tumbuh, siap),
-- each holding all 12 crops in a row. Crop ids mirror Config/Crops.order and part recipes come from
-- the shared CropModelCandidates module; this file holds only ids, counts, a layout relative to the
-- MapSpec Lapangan field, and plain RGB colours with built-in material/shape tokens. No engine API,
-- no asset IDs, no decals, no terrain edit, no player-facing text. The server applier reads this
-- module plus MapSpec at apply time; the visual verdict stays with the designer.

local Data = {}

Data.id = "crops_showcase_r8"
Data.familyId = "crops_showcase_r8"
Data.folderName = "LookDevCropsShowcaseR8_crops_showcase_r8"

Data.stageAttribute = "LookDevCropsShowcaseR8"
Data.kindAttribute = "CropsShowcaseKind"
Data.PLOT_KIND = "plot"
Data.CROP_KIND = "crop"
Data.PLATE_KIND = "plate"
Data.CROP_PREFIX = "LookDevCrop_"

-- Exact Config/Crops.order ids: no invented crop names.
Data.CROPS = {
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
Data.STAGES = { "bibit", "tumbuh", "siap" }
Data.COUNTS = { plots = 3, crops = 12, models = 36 }

-- Site is MapSpec.LAPANGAN (centre x/z, width/depth). Only offsets live here; the applier and the
-- camera registry convert them with MapSpec.LAPANGAN and MapSpec.GROUND_Y. Three plots sit side by
-- side along Z; each crop row spans X. cropStep*11 = 49.5 studs, inside the 72-stud field width.
Data.SITE = "MapSpec.LAPANGAN"
Data.PLOT = {
	plateSize = { 56, 0.3, 8 },
	cropStep = 4.5,
	cropLift = 0.02,
}
Data.PLOTS = {
	{ stage = "bibit", zOffset = -16 },
	{ stage = "tumbuh", zOffset = 0 },
	{ stage = "siap", zOffset = 16 },
}
-- Review eye/target offsets in studs, derived from the field centre by the camera registry.
Data.CAMERA = { standoff = 22, rise = 12, lookRise = 3 }

-- Built-in shape tokens. Sphere maps to Ball because that is the engine token name.
Data.SHAPES = { Block = "Block", Cylinder = "Cylinder", Sphere = "Ball", Wedge = "Wedge" }
-- Built-in material tokens only; Painted and Leaf are deliberately absent.
Data.MATERIALS = {
	stem = "Wood",
	accent = "Wood",
	leaf = "Grass",
	fruit = "SmoothPlastic",
	plate = "Ground",
	fallback = "SmoothPlastic",
}

-- Plain RGB from the ART palette; no hex strings and no numeric asset references here.
Data.PALETTE = {
	kertas = { 243, 233, 210 },
	padi = { 155, 178, 90 },
	daun = { 111, 138, 63 },
	genteng = { 168, 69, 47 },
	merah = { 168, 50, 38 },
	bambu = { 185, 138, 90 },
	kunyit = { 201, 154, 46 },
	ungu = { 118, 82, 168 },
	tinta = { 42, 42, 42 },
}
-- Per-crop colours for the "crop" palette token, from Config/Crops.list.
Data.CROP_COLOURS = {
	padi = { 214, 196, 92 },
	singkong = { 180, 150, 96 },
	jagung = { 240, 200, 40 },
	bawang = { 196, 120, 160 },
	cabai = { 210, 40, 30 },
	tembakau = { 150, 110, 50 },
	kopi = { 110, 70, 40 },
	tebu = { 160, 190, 90 },
	kakao = { 120, 80, 50 },
	cengkeh = { 140, 90, 120 },
	durian = { 120, 140, 40 },
	sawit = { 200, 90, 30 },
}

function Data.cropX(index: number): number
	return (index - (Data.COUNTS.crops + 1) / 2) * Data.PLOT.cropStep
end

function Data.modelName(cropId: string, stage: string): string
	return Data.CROP_PREFIX .. cropId .. "_" .. stage
end

function Data.plots(): { any }
	return table.clone(Data.PLOTS)
end

function Data.counts(): { [string]: number }
	return table.clone(Data.COUNTS)
end

return Data
