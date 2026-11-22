-- ModelMapWaterR8: pure data for the OFF-BY-DEFAULT "water_r8_a/b/c" LookDev candidates
-- (WORK_QUEUE section M item 76). Three river-water looks expressed as Terrain water properties.
--
-- Pure data/functions only: no engine APIs, no Instances, no Enums, no asset IDs. The client applier
-- reads and writes the real Terrain properties; this module only describes values and their bounds.
--
-- safeRanges document the defensible Roblox limits used by the harness. WaterColor is validated per
-- 8-bit channel because the palettes store rgb bytes: conversion is channel255 = Color3.R * 255
-- (the applier calls Color3.fromRGB(r, g, b)). Numeric ranges are inclusive.

local ModelMapWaterR8 = {}

ModelMapWaterR8.idPrefix = "water_r8_"
ModelMapWaterR8.order = { "a", "b", "c" }

-- Exact Terrain water property names. The applier only touches these five.
ModelMapWaterR8.properties = {
	"WaterColor",
	"WaterTransparency",
	"WaterReflectance",
	"WaterWaveSize",
	"WaterWaveSpeed",
}

-- Bounds rationale:
--   WaterColor channels: 0..255 are the byte inputs of Color3.fromRGB.
--   WaterTransparency 0.05..0.75: never fully opaque (hides the riverbed) nor invisible.
--   WaterReflectance 0..0.6: Roblox accepts 0..1, but water above 0.6 reads as polished metal.
--   WaterWaveSize 0..1: Roblox accepts 0..1; larger crests break the small river silhouette.
--   WaterWaveSpeed -2..2: Roblox accepts -8..8; beyond 2 the surface flickers at review distance.
ModelMapWaterR8.safeRanges = {
	WaterColor = {
		R = { min = 0, max = 255 },
		G = { min = 0, max = 255 },
		B = { min = 0, max = 255 },
	},
	WaterTransparency = { min = 0.05, max = 0.75 },
	WaterReflectance = { min = 0, max = 0.6 },
	WaterWaveSize = { min = 0, max = 1 },
	WaterWaveSpeed = { min = -2, max = 2 },
}

-- Three visually distinct palettes. Every value sits inside safeRanges above.
ModelMapWaterR8.variants = {
	a = {
		id = "water_r8_a",
		label = "clear tropical green",
		values = {
			WaterColor = { r = 48, g = 124, b = 104 },
			WaterTransparency = 0.28,
			WaterReflectance = 0.35,
			WaterWaveSize = 0.42,
			WaterWaveSpeed = 0.9,
		},
	},
	b = {
		id = "water_r8_b",
		label = "murky brown after rain",
		values = {
			WaterColor = { r = 96, g = 84, b = 58 },
			WaterTransparency = 0.12,
			WaterReflectance = 0.12,
			WaterWaveSize = 0.7,
			WaterWaveSpeed = 1.6,
		},
	},
	c = {
		id = "water_r8_c",
		label = "bright turquoise",
		values = {
			WaterColor = { r = 40, g = 182, b = 196 },
			WaterTransparency = 0.42,
			WaterReflectance = 0.5,
			WaterWaveSize = 0.3,
			WaterWaveSpeed = 0.55,
		},
	},
}

function ModelMapWaterR8.valuesFor(key: string): any?
	local variant = ModelMapWaterR8.variants[key]
	return if variant then variant.values else nil
end

return ModelMapWaterR8
