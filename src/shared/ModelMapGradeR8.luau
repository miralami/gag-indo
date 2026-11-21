-- ModelMapGradeR8: pure data for the OFF-BY-DEFAULT "grade_r8_a/b/c" LookDev candidates
-- (WORK_QUEUE section M item 91). Three tropical colour grades: warm golden, fresh green,
-- hazy humid. Each tunes Atmosphere, ColorCorrectionEffect, BloomEffect and SunRaysEffect only.
--
-- Pure data/functions only: no engine APIs, no Instances, no Enums, no asset IDs. The SERVER
-- applier reads and writes the real Lighting effect properties; this module only describes
-- values and their documented bounds. The numeric ranges are mirrored in docs/v2/visual/GRADE_R8.md.
--
-- Colour scales: Atmosphere.Color and Atmosphere.Decay are BYTE triples fed to Color3.fromRGB
-- (each channel 0..255). ColorCorrectionEffect.TintColor is a NORMALISED triple fed to
-- Color3.new (each channel 0..1). Bounds are inclusive.

local ModelMapGradeR8 = {}

ModelMapGradeR8.idPrefix = "grade_r8_"
ModelMapGradeR8.order = { "a", "b", "c" }

-- No depth-of-field of any kind. Exactly these four effect classes may be touched.
ModelMapGradeR8.NO_DOF = true
ModelMapGradeR8.TOUCHED_EFFECTS = {
	"Atmosphere",
	"ColorCorrectionEffect",
	"BloomEffect",
	"SunRaysEffect",
}

-- Exact Lighting child property names. The applier saves/restores every one of these.
ModelMapGradeR8.properties = {
	Atmosphere = { "Density", "Haze", "Color", "Decay", "Offset", "Glare" },
	ColorCorrectionEffect = { "Saturation", "Contrast", "TintColor", "Brightness" },
	BloomEffect = { "Intensity", "Threshold", "Size" },
	SunRaysEffect = { "Intensity", "Spread" },
}

-- Bounds rationale (full narrative in docs/v2/visual/GRADE_R8.md):
--   Saturation 0..0.20: a slight lift only; above that the village turns poster-like.
--   Contrast -0.02..0.08: mild separation, never crushed blacks.
--   Brightness -0.05..0.05: exposure nudge only.
--   TintColor channels 0.90..1.10: near-white; stronger tints distort the chosen sky.
--   Bloom Intensity 0..0.25 / Threshold 0.85..1.0 / Size 10..24: soft glow, no halo washout.
--   SunRays Intensity 0..0.30 / Spread 0.15..0.50: soft rays, never a flare.
--   Atmosphere Density 0.22..0.35 / Haze 1.0..2.4: the recorded tropical humid band.
--   Atmosphere Color channels 0..255 with R>=G>=B (warm white).
--   Atmosphere Decay channels 0..255 with B>=G>=R (light blue).
--   Atmosphere Offset 0.5..0.8 / Glare 0.8..1.5: sky_r6 baseline plus modest headroom.
ModelMapGradeR8.safeRanges = {
	ColorCorrectionEffect = {
		Saturation = { min = 0, max = 0.2 },
		Contrast = { min = -0.02, max = 0.08 },
		Brightness = { min = -0.05, max = 0.05 },
		TintColor = {
			R = { min = 0.9, max = 1.1 },
			G = { min = 0.9, max = 1.1 },
			B = { min = 0.9, max = 1.1 },
		},
	},
	BloomEffect = {
		Intensity = { min = 0, max = 0.25 },
		Threshold = { min = 0.85, max = 1 },
		Size = { min = 10, max = 24 },
	},
	SunRaysEffect = {
		Intensity = { min = 0, max = 0.3 },
		Spread = { min = 0.15, max = 0.5 },
	},
	Atmosphere = {
		Density = { min = 0.22, max = 0.35 },
		Haze = { min = 1, max = 2.4 },
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
		Offset = { min = 0.5, max = 0.8 },
		Glare = { min = 0.8, max = 1.5 },
	},
}

-- Three visually distinct palettes. Every value sits inside safeRanges above. The shipping
-- default (no candidate enabled) stays untouched: the sky_r6 baseline is Density 0.30,
-- Haze 1.6, Color {240,236,224}, Decay {150,190,220}, Offset 0.65, Glare 1.2; SunRays
-- 0.18/0.35; Bloom 0.12/0.95/18; ColorCorrection 0.08/0.02/0/{1,1,1}.
ModelMapGradeR8.variants = {
	a = {
		id = "grade_r8_a",
		label = "warm golden",
		values = {
			Atmosphere = {
				Density = 0.28,
				Haze = 1.4,
				Color = { r = 252, g = 238, b = 208 },
				Decay = { r = 168, g = 198, b = 226 },
				Offset = 0.68,
				Glare = 1.3,
			},
			ColorCorrectionEffect = {
				Saturation = 0.15,
				Contrast = 0.05,
				TintColor = { r = 1.04, g = 1, b = 0.93 },
				Brightness = 0.02,
			},
			BloomEffect = { Intensity = 0.15, Threshold = 0.92, Size = 18 },
			SunRaysEffect = { Intensity = 0.24, Spread = 0.3 },
		},
	},
	b = {
		id = "grade_r8_b",
		label = "fresh green",
		values = {
			Atmosphere = {
				Density = 0.24,
				Haze = 1.05,
				Color = { r = 240, g = 238, b = 218 },
				Decay = { r = 146, g = 190, b = 214 },
				Offset = 0.6,
				Glare = 1.1,
			},
			ColorCorrectionEffect = {
				Saturation = 0.19,
				Contrast = 0.04,
				TintColor = { r = 0.95, g = 1.06, b = 0.96 },
				Brightness = -0.01,
			},
			BloomEffect = { Intensity = 0.1, Threshold = 0.96, Size = 15 },
			SunRaysEffect = { Intensity = 0.16, Spread = 0.42 },
		},
	},
	c = {
		id = "grade_r8_c",
		label = "hazy humid",
		values = {
			Atmosphere = {
				Density = 0.34,
				Haze = 2.2,
				Color = { r = 246, g = 240, b = 226 },
				Decay = { r = 158, g = 192, b = 224 },
				Offset = 0.76,
				Glare = 1.44,
			},
			ColorCorrectionEffect = {
				Saturation = 0.06,
				Contrast = -0.01,
				TintColor = { r = 1, g = 1.02, b = 1.04 },
				Brightness = 0.01,
			},
			BloomEffect = { Intensity = 0.22, Threshold = 0.86, Size = 22 },
			SunRaysEffect = { Intensity = 0.1, Spread = 0.48 },
		},
	},
}

function ModelMapGradeR8.valuesFor(key: string): any?
	local variant = ModelMapGradeR8.variants[key]
	return if variant then variant.values else nil
end

return ModelMapGradeR8
