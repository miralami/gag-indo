-- ModelMapSeasonR8: pure data for the OFF-BY-DEFAULT "season_r8_hujan/kemarau/panen" LookDev looks
-- (WORK_QUEUE section N item 119). Three seasonal looks tied to Config.Seasons.sky field names:
-- hujan (wetter ground, more puddle sheets, cooler grade), kemarau (dry-grass tint, lower Clouds
-- Cover, more haze) and panen (standalone golden-padi look; there is no "panen" musim in Seasons).
--
-- SCOPE: only Lighting's own scalar/byte-RGB props, the existing Atmosphere effect, Clouds.Cover
-- under Workspace.Terrain, a bounded snapshot/restored set of existing tinted decor Parts, and six
-- own anchored puddle-sheet Parts for hujan. No ColorCorrection, Bloom, SunRays, ClockTime, Terrain
-- voxel edit, DataStore/player/crop state, asset ID, brand, decal or player-facing text.
--
-- There is no engine API here: all colours are plain {r,g,b} byte triples in the documented
-- 0..255 scale. The CLIENT applier converts them at apply time and snapshots/restores every
-- overwritten value exactly; no asset IDs, no terrain edit.
--
-- Safe bands are deliberately SEASON bands, not a copy of the grade_r8 bands. The shipped
-- Seasons.sky density values (hujan 0.18, kemarau 0.12, pancaroba 0.10) sit below the grade's
-- 0.22 floor, so the lower bound is extended to 0.10 while the 0.35 upper bound is unchanged.
-- Haze likewise starts at the Seasons floor 0.4; Clouds.Cover starts at the Seasons baseline 0.35
-- and stays inside the recorded harness band 0.4..0.6 for every preset.

local ModelMapSeasonR8 = {}

ModelMapSeasonR8.idPrefix = "season_r8_"
ModelMapSeasonR8.order = { "hujan", "kemarau", "panen" }

-- Ties to Config.Seasons (strings only; no runtime dependency). "panen" is a standalone golden
-- harvest look, not a Seasons musim; it borrows the pancaroba warm-padi palette intent.
ModelMapSeasonR8.seasonsTie = {
	hujan = "Config.Seasons.sky.hujan",
	kemarau = "Config.Seasons.sky.kemarau",
	panen = "Config.Seasons.sky.pancaroba (golden harvest intent; no panen musim)",
}

ModelMapSeasonR8.TOUCHED = { "Lighting", "Atmosphere", "Clouds", "Decor" }

-- Exact property names the applier saves/restores. Decor has no fixed property list: the selectors
-- below decide which existing Parts get their Color3 snapshotted.
ModelMapSeasonR8.properties = {
	Lighting = {
		"Brightness",
		"Ambient",
		"OutdoorAmbient",
		"ColorShift_Top",
		"ColorShift_Bottom",
		"FogColor",
		"FogEnd",
	},
	Atmosphere = { "Density", "Haze", "Color", "Decay", "Offset", "Glare" },
	Clouds = { "Cover" },
	Decor = { "Color" },
}

-- Bounds rationale: Brightness 1.2..3.2 covers the Seasons.hujan rain-dimmed value (1.35) through
-- Seasons.kemarau (3.0). Byte-RGB channels are 0..255. FogEnd >= 40 with a 4000 ceiling.
-- Density 0.10..0.35, Haze 0.4..2.4, Offset 0.5..0.8 and Glare 0.8..1.5 are the documented
-- tropical bands extended down only where the shipped Seasons table requires it.
-- Clouds.Cover 0.35..0.60 includes the shipped 0.35 baseline and the harness 0.4..0.6 band.
ModelMapSeasonR8.safeRanges = {
	Lighting = {
		Brightness = { min = 1.2, max = 3.2 },
		FogEnd = { min = 40, max = 4000 },
		Ambient = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
		OutdoorAmbient = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
		ColorShift_Top = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
		ColorShift_Bottom = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
		FogColor = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
	},
	Atmosphere = {
		Density = { min = 0.1, max = 0.35 },
		Haze = { min = 0.4, max = 2.4 },
		Offset = { min = 0.5, max = 0.8 },
		Glare = { min = 0.8, max = 1.5 },
		Color = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
		Decay = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
	},
	Clouds = { Cover = { min = 0.35, max = 0.6 } },
	Decor = {
		Color = {
			R = { min = 0, max = 255 },
			G = { min = 0, max = 255 },
			B = { min = 0, max = 255 },
		},
	},
}

-- Bounded selectors over EXISTING decor only. The applier walks Workspace descendants once, takes
-- at most `max` Parts per selector in traversal order, and snapshots their exact original Color3
-- before writing a tint. Name prefixes and attributes come from the existing decor appliers:
--   "PadiPart"            -> LookDevSawahR8 blade / tuft Parts
--   "puddle_" + attribute -> LookDevPathEdgeR8 puddle sheets
--   "grass_tuft_" + attr  -> LookDevPathEdgeR8 grass tufts
-- Nothing is tinted when those decor candidates are off; diagnostics report the count.
ModelMapSeasonR8.TINT_SELECTORS = {
	{ key = "padi", attribute = "PadiPart", max = 24 },
	{ key = "puddle", namePrefix = "puddle_", attribute = "LookDevPathEdgeR8", max = 12 },
	{ key = "grass", namePrefix = "grass_tuft_", attribute = "LookDevPathEdgeR8", max = 24 },
}

-- Own additive geometry for hujan only: six anchored, non-collidable tinted puddle overlays in one
-- Workspace folder. x/z are village-local offsets; the applier takes the Y from MapSpec.ROAD.y
-- when reachable, otherwise from the documented client-side fallback below.
ModelMapSeasonR8.PUDDLE_FOLDER = "LookDevSeasonR8_hujan_puddles"
ModelMapSeasonR8.PUDDLE_MATERIAL = "SmoothPlastic" -- built-in, never Painted or Leaf
ModelMapSeasonR8.PUDDLE_TRANSPARENCY = 0.55
-- Documented client-side fallback for MapSpec.ROAD.y (Ground.Y 0.5 + 0.03). Used only when MapSpec
-- is unreachable from the Client VM; the applier still prefers MapSpec.ROAD.y when available.
ModelMapSeasonR8.PUDDLE_Y_FALLBACK = 0.53
ModelMapSeasonR8.PUDDLE_SHEETS = {
	{ x = -5, z = 20, sx = 2.4, sz = 1.4 },
	{ x = 5, z = 26, sx = 2.2, sz = 1.2 },
	{ x = -5, z = 34, sx = 2.6, sz = 1.4 },
	{ x = 5, z = 42, sx = 2.0, sz = 1.2 },
	{ x = -4, z = 50, sx = 2.4, sz = 1.4 },
	{ x = 4, z = 58, sx = 2.2, sz = 1.2 },
}

-- Pairwise clause: relative difference in percent, abs(a-b)/max(abs(a),abs(b),0.001)*100.
-- Counted over scalar props plus every byte-RGB channel plus every tint channel. Every pair must
-- differ in at least DISTINCT_TARGET values by at least DISTINCT_PCT percent.
ModelMapSeasonR8.DISTINCT_PCT = 10
ModelMapSeasonR8.DISTINCT_TARGET = 2

ModelMapSeasonR8.variants = {
	hujan = {
		id = "season_r8_hujan",
		label = "wet rain look",
		values = {
			Lighting = {
				Brightness = 1.4,
				Ambient = { r = 88, g = 84, b = 104 },
				OutdoorAmbient = { r = 118, g = 114, b = 134 },
				ColorShift_Top = { r = 225, g = 210, b = 190 },
				ColorShift_Bottom = { r = 95, g = 85, b = 105 },
				FogColor = { r = 185, g = 170, b = 165 },
				FogEnd = 1200,
			},
			Atmosphere = {
				Density = 0.18,
				Haze = 1.2,
				Color = { r = 228, g = 226, b = 218 },
				Decay = { r = 160, g = 196, b = 232 },
				Offset = 0.62,
				Glare = 1.25,
			},
			Clouds = { Cover = 0.58 },
		},
		tints = {
			padi = { r = 82, g = 104, b = 70 },
			puddle = { r = 58, g = 92, b = 118 },
			grass = { r = 78, g = 112, b = 70 },
		},
		puddleSheets = 6,
	},
	kemarau = {
		id = "season_r8_kemarau",
		label = "dry season look",
		values = {
			Lighting = {
				Brightness = 3,
				Ambient = { r = 105, g = 90, b = 98 },
				OutdoorAmbient = { r = 145, g = 125, b = 120 },
				ColorShift_Top = { r = 255, g = 220, b = 150 },
				ColorShift_Bottom = { r = 100, g = 80, b = 95 },
				FogColor = { r = 245, g = 205, b = 145 },
				FogEnd = 3000,
			},
			Atmosphere = {
				Density = 0.12,
				Haze = 2.2,
				Color = { r = 250, g = 236, b = 210 },
				Decay = { r = 170, g = 190, b = 210 },
				Offset = 0.78,
				Glare = 1.45,
			},
			Clouds = { Cover = 0.4 },
		},
		tints = {
			padi = { r = 166, g = 150, b = 92 },
			puddle = { r = 104, g = 98, b = 82 },
			grass = { r = 142, g = 130, b = 72 },
		},
		puddleSheets = 0,
	},
	panen = {
		id = "season_r8_panen",
		label = "golden harvest look",
		values = {
			Lighting = {
				Brightness = 2.6,
				Ambient = { r = 118, g = 106, b = 102 },
				OutdoorAmbient = { r = 152, g = 138, b = 130 },
				ColorShift_Top = { r = 255, g = 218, b = 150 },
				ColorShift_Bottom = { r = 128, g = 108, b = 95 },
				FogColor = { r = 245, g = 198, b = 148 },
				FogEnd = 3500,
			},
			Atmosphere = {
				Density = 0.1,
				Haze = 0.8,
				Color = { r = 252, g = 240, b = 214 },
				Decay = { r = 180, g = 200, b = 230 },
				Offset = 0.75,
				Glare = 1.4,
			},
			Clouds = { Cover = 0.48 },
		},
		tints = {
			padi = { r = 226, g = 182, b = 64 },
			puddle = { r = 120, g = 104, b = 72 },
			grass = { r = 164, g = 148, b = 72 },
		},
		puddleSheets = 0,
	},
}

function ModelMapSeasonR8.valuesFor(key: string): any?
	local variant = ModelMapSeasonR8.variants[key]
	return if variant then variant.values else nil
end

function ModelMapSeasonR8.tintsFor(key: string): any?
	local variant = ModelMapSeasonR8.variants[key]
	return if variant then variant.tints else nil
end

function ModelMapSeasonR8.puddlesFor(key: string): number
	local variant = ModelMapSeasonR8.variants[key]
	return if variant then variant.puddleSheets else 0
end

return ModelMapSeasonR8
