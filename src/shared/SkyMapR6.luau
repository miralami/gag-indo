--!strict
-- SkyMapR6: pure data for the six OFF-BY-DEFAULT round-6 Creator Store sky
-- candidates sky_r6_a..sky_r6_f (WORK_QUEUE section J item 44). Every face ID
-- below was read from the six real free models in a Play-Solo Server VM; provenance
-- is in docs/v2/evidence/h/2026-11-20-sky-r6-asset-load/REPORT.md. Legacy
-- http://www.roblox.com/asset/?id=N values were normalised to the integer N here;
-- the client applier adds the asset scheme prefix at apply time. No engine API,
-- no value types, no instances and no ID construction: colours stay plain arrays.
-- No visual was graded. sky_r5 (Shared.SkyMapR5) stays the unchanged baseline.

local SkyMapR6 = {}

-- The six exact Roblox Sky face property names, in stable iteration order.
SkyMapR6.faceKeys = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

type SkySet = {
	label: string,
	modelId: number,
	source: string,
	creator: string,
	licence: string,
	storeUrl: string,
	ids: { [string]: number },
}

-- Each set is one real free Creator Store Model. Only its six Sky faces are used;
-- scripts inside models e and f are deliberately NOT copied (see the REPORT).
-- The repeated Ft/Lf/Rt ID in set d is exactly what the loaded model contains.
SkyMapR6.sets = {
	a = {
		label = "Realistic Sky",
		modelId = 4607457995,
		source = "Creator Store free Model",
		creator = "Xeksworld08",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/4607457995",
		ids = {
			SkyboxBk = 150335574,
			SkyboxDn = 150335585,
			SkyboxFt = 150335628,
			SkyboxLf = 150335620,
			SkyboxRt = 150335610,
			SkyboxUp = 150335642,
		},
	},
	b = {
		label = "Sky-Realistic",
		modelId = 10256505900,
		source = "Creator Store free Model",
		creator = "Dev_Flowey",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/10256505900",
		ids = {
			SkyboxBk = 144933338,
			SkyboxDn = 144931530,
			SkyboxFt = 144933262,
			SkyboxLf = 144933244,
			SkyboxRt = 144933299,
			SkyboxUp = 144931564,
		},
	},
	c = {
		label = "Realistic Clear Sky",
		modelId = 9589448285,
		source = "Creator Store free Model",
		creator = "HeyItzDaredevil",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/9589448285",
		ids = {
			SkyboxBk = 9544505500,
			SkyboxDn = 9544547905,
			SkyboxFt = 9544504852,
			SkyboxLf = 9544547694,
			SkyboxRt = 9544547542,
			SkyboxUp = 9544547398,
		},
	},
	d = {
		label = "Realistic Clear Skies (SKYBOX)",
		modelId = 11219565245,
		source = "Creator Store free Model",
		creator = "TrainMaker6",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/11219565245",
		ids = {
			SkyboxBk = 91458002,
			SkyboxDn = 91457980,
			SkyboxFt = 91458024,
			SkyboxLf = 91458024,
			SkyboxRt = 91458024,
			SkyboxUp = 91458002,
		},
	},
	e = {
		label = "Blue Sky W Scattered Clouds Daytime Skybox Light",
		modelId = 71778157196658,
		source = "Creator Store free Model",
		creator = "Rozosere48",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/71778157196658",
		ids = {
			SkyboxBk = 2835173905,
			SkyboxDn = 2493829793,
			SkyboxFt = 2835177931,
			SkyboxLf = 2835174704,
			SkyboxRt = 2835177433,
			SkyboxUp = 2835175409,
		},
	},
	f = {
		label = "Sunless blue sky skybox realistic clouds",
		modelId = 79778158338852,
		source = "Creator Store free Model",
		creator = "f0xz08",
		licence = "Creator Store free model",
		storeUrl = "https://create.roblox.com/store/asset/79778158338852",
		ids = {
			SkyboxBk = 591058823,
			SkyboxDn = 591059876,
			SkyboxFt = 591058104,
			SkyboxLf = 591057861,
			SkyboxRt = 591057625,
			SkyboxUp = 591059642,
		},
	},
} :: { [string]: SkySet }

SkyMapR6.order = { "a", "b", "c", "d", "e", "f" }

-- One shared atmosphere stack for all six candidates: humid warm-white haze with
-- a light-blue Decay. Decay/Color are plain {r,g,b} triples; the client applier
-- converts them at apply time.
SkyMapR6.atmosphere = {
	Density = 0.30,
	Haze = 1.6,
	Color = { 240, 236, 224 },
	Decay = { 150, 190, 220 },
	Offset = 0.65,
	Glare = 1.2,
}

-- Volumetric Terrain Clouds cover. Saved and restored exactly on disable.
SkyMapR6.cloudCover = 0.5

-- Sun stays on; soft SunRays, low Bloom and a slight saturation lift. TintColor is
-- a 0-1 {r,g,b} triple, not a 0-255 fromRGB triple.
-- Each effect instance and every property it touches is saved and restored.
SkyMapR6.effects = {
	celestialBodiesShown = true,
	sunRays = { Intensity = 0.18, Spread = 0.35, Enabled = true },
	bloom = { Intensity = 0.12, Threshold = 0.95, Size = 18, Enabled = true },
	colorCorrection = {
		Saturation = 0.08,
		Contrast = 0.02,
		TintColor = { 1, 1, 1 },
		Brightness = 0,
		Enabled = true,
	},
}

-- One saved review camera for all six: eye ~20 degrees below the look target
-- (atan2(28.6 - 9, 54) ~= 19.9 degrees), so the sky fills half the frame.
SkyMapR6.savedCamera = {
	eye = { -14, 9, 42 },
	look = { -14, 28.6, -12 },
}

function SkyMapR6.faceCount(): number
	return #SkyMapR6.faceKeys
end

return SkyMapR6
