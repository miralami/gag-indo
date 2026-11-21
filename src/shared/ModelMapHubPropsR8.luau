--!strict
-- ModelMapHubPropsR8: pure data for the OFF-BY-DEFAULT "hubprops_r8" LookDev candidate
-- (WORK_QUEUE section M item 79). Six to ten vernacular props in the open local +Z frontage of each
-- of the six Greybox hubs: Pasar (sayur crates, bakul, timbangan), Warung (bangku, teko, toples),
-- Polisi (bendera, papan pengumuman, motor), Ronda (kentongan, bale bambu), Gelap (lampu, tong,
-- kardus) and Pak RT (meja, kursi rotan, bendera).
--
-- PURE DATA ONLY: no game APIs, no Instances, no Enum values and no asset URLs at load time. Colours
-- are plain {r,g,b} arrays and materials are built-in material names resolved by the applier.
-- Every coordinate is LOCAL to its hub; the applier reads the live MapSpec.hub(key) for world x/z/yaw
-- and turns it with MapSpec.hubPoint, so this module holds no world position.
--
-- LADDER (D15): step (1) free/CC0 baked models are used for the eight kinds with a verified asset
-- (karung, gerobak, lapak, jemuran, pagar/bale bambu, sumur, motor). Step (2) adds the agent-generated
-- low-poly BambooBasket (generationId 14b48661-4c08-425f-ab3f-c641c1a885fd), baked runtime-only as
-- ServerStorage.LookDevAssets/generated_bamboo_basket, for two Pasar bakul props. It is original /
-- CC0-equivalent geometry with NO Creator Store asset ID. The remaining vernacular kinds have no
-- compliant model, so step (4) Roblox parts are used for them.
-- Every baked ID below is one of the nine verified IDs in docs/v2/visual/art/ASSET_MANIFEST.md;
-- none is invented. `target` is the real-world bounding box (width, height, depth in studs) the
-- applier scales the baked model to, measured with GetBoundingBox.
--
-- GROUNDING: props sit just outside the front wall on the apron. The row is angled across the
-- camera's review cone (at()) so every 3/4 hub review camera sees at least five props per hub
-- without another prop masking them. The applier paints a small Ground voxel pad under each prop
-- (the harness samples TERRAIN at GRASS_Y=4, so a decorative base Part alone cannot clear
-- HUBPROPS_ON_GRASS). Pads match the buildings_r8/props_r7 pattern.
local ModelMapHubPropsR8 = {}
ModelMapHubPropsR8.id = "hubprops_r8"
ModelMapHubPropsR8.familyId = "hubprops_r8"
ModelMapHubPropsR8.folderName = "LookDevHubPropsR8_hubprops_r8"
ModelMapHubPropsR8.minPropsPerHub = 6
ModelMapHubPropsR8.maxPropsPerHub = 10
ModelMapHubPropsR8.baseOffset = 0.25 -- above MapSpec.GROUND_Y (0.5)
ModelMapHubPropsR8.padMargin = 2
ModelMapHubPropsR8.HUB_KEYS = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }
ModelMapHubPropsR8.PROP_ATTRIBUTE = "HubProp"
ModelMapHubPropsR8.HUB_ATTRIBUTE = "HubKey"
ModelMapHubPropsR8.KIND_ATTRIBUTE = "PropKind"
ModelMapHubPropsR8.SOURCE_ATTRIBUTE = "Source"
-- The exact nine verified asset IDs. A baked recipe outside this set is a data defect, not a new ID.
ModelMapHubPropsR8.ALLOWED_IDS = {
	[87487192428396] = true, -- karung, Poly Haven CC0 (ASSET_MANIFEST line 416)
	[85094565897097] = true, -- agent-generated pagar bambu, CC0-equivalent (line 277/433)
	[103341007913673] = true, -- pagar bambu, Poly Pizza CC BY 3.0 (line 414)
	[138444489439223] = true, -- jemuran, Grab3D CC0 (line 417)
	[115924626989907] = true, -- lapak, Poly Pizza CC BY 3.0 (line 413)
	[119426685469058] = true, -- gerobak, Poly Pizza CC BY 3.0 (line 411)
	[10506531785] = true, -- Gerobak, Creator Store (line 432)
	[95025959179405] = true, -- sumur, Poly Pizza CC BY 3.0 (line 412)
	[106061905410704] = true, -- motor, Poly Pizza CC0 (line 99)
}

-- Step-(2) D15: agent-generated low-poly geometry, baked by the main session under this FOLDER NAME.
-- It is not a Creator Store ID; the applier clones the folder, never calls InsertService:LoadAsset.
ModelMapHubPropsR8.ALLOWED_GENERATED = {
	generated_bamboo_basket = true, -- BambooBasket, generationId 14b48661-4c08-425f-ab3f-c641c1a885fd
}

-- Footprints copied from MapSpec.HUBS (width/depth/front edge). The applier still reads the live
-- hub for yaw/x/z; these numbers only fix the local front row. `front` is depth / 2.
ModelMapHubPropsR8.HUBS = {
	pasar = { model = "Pasar", width = 64, depth = 52, front = 26 },
	gelap = { model = "TengkulakGelap", width = 32, depth = 28, front = 14 },
	warung = { model = "Warung", width = 52, depth = 44, front = 22 },
	ronda = { model = "PosRonda", width = 44, depth = 40, front = 20 },
	polisi = { model = "PosPolisi", width = 48, depth = 44, front = 22 },
	pakrt = { model = "RumahPakRT", width = 48, depth = 34, front = 17 },
}

-- Door gauges from item 78 (facades_r8). No recipe centre sits inside one of these local
-- footprints; the skewed apron row stays forward of the gauge planes.
ModelMapHubPropsR8.GAUGES = {
	pasar = { w = 6, h = 9, d = 2, lx = 0, lz = 27 },
	gelap = { w = 6, h = 9, d = 2, lx = 0, lz = 15 },
	warung = { w = 6, h = 9, d = 2, lx = 0, lz = 23 },
	ronda = { w = 6, h = 9, d = 2, lx = 0, lz = 17 },
	polisi = { w = 6, h = 9, d = 2, lx = 0, lz = 23 },
	pakrt = { w = 7, h = 10.5, d = 2, lx = -13, lz = 10.5 },
}

-- The eleven vernacular kinds named in item 79, grouped by hub. Every hub's recipe list spans its
-- group. `bendera` is the flag kind used at both Polisi and Pak RT.
ModelMapHubPropsR8.KINDS_BY_HUB = {
	pasar = { "sayur_crate", "bakul", "timbangan" },
	gelap = { "lampu", "tong", "kardus" },
	warung = { "bangku", "teko", "toples" },
	ronda = { "kentongan", "bale_bambu" },
	polisi = { "bendera", "papan_pengumuman", "motor" },
	pakrt = { "meja", "kursi_rotan", "bendera" },
}

-- Row layout: slot i runs across the hub's front apron, angled through the camera's review cone.
-- lx = side * (-22 + 7*i), lz = front + 6 - 0.6*i: 7-stud centre spacing keeps wide baked props
-- from masking their neighbours, and every centre sits inside the 35-degree half-angle cone and
-- clear of the item-78 door gauge. Pure arithmetic; no game API at load.
local CAMERA_SIDE = { pasar = 1, gelap = -1, warung = 1, ronda = -1, polisi = 1, pakrt = 1 }
local ROW_X0, ROW_DX = -22, 7
local ROW_Z0, ROW_DZ = 6, -0.6
local function at(hubKey: string, i: number): any
	return {
		lx = CAMERA_SIDE[hubKey] * (ROW_X0 + ROW_DX * i),
		lz = ModelMapHubPropsR8.HUBS[hubKey].front + ROW_Z0 + ROW_DZ * i,
	}
end
-- Procedural part helper. `shape` is a built-in part-type name; size/offset/colour are arrays.
local function part(
	name: string,
	shape: string,
	size: { number },
	offset: { number },
	color: { number },
	material: string
): any
	return { name = name, shape = shape, size = size, offset = offset, color = color, material = material }
end
local function baked(name: string, kind: string, id: number, target: { number }, pos: any, yaw: number?): any
	return {
		name = name,
		kind = kind,
		source = "baked",
		id = id,
		target = target,
		lx = pos.lx,
		lz = pos.lz,
		yaw = yaw or 0,
	}
end

local function bakedGenerated(
	name: string,
	kind: string,
	folder: string,
	target: { number },
	pos: any,
	yaw: number?
): any
	return {
		name = name,
		kind = kind,
		source = "baked",
		baked = folder,
		target = target,
		lx = pos.lx,
		lz = pos.lz,
		yaw = yaw or 0,
	}
end
local function procedural(name: string, kind: string, pos: any, parts: { any }, yaw: number?): any
	return {
		name = name,
		kind = kind,
		source = "procedural",
		lx = pos.lx,
		lz = pos.lz,
		parts = parts,
		yaw = yaw or 0,
	}
end
-- Palette entries are plain RGB bytes. Materials are built-in names (LookDev.isBuiltinMaterial).
local BAMBU = { 185, 138, 90 }
local KAYU = { 122, 84, 56 }
local DAUN = { 111, 138, 63 }
local SAYUR = { 176, 154, 62 }
local KERTAS = { 243, 233, 210 }
local MERAH = { 168, 50, 38 }
local MALAM = { 31, 78, 107 }
local BESI = { 96, 88, 76 }
local SENJA = { 246, 201, 122 }
local KARDUS = { 168, 126, 82 }
-- Pasar: produce crates, woven baskets and a scale, plus the verified karung/gerobak/lapak/jemuran/
-- pagar assets. Nine props on the skewed front apron, including two step-(2) baked bakul baskets.
local pasar = {
	procedural("PasarSayurCrate", "sayur_crate", at("pasar", 7), {
		part("CrateA", "Block", { 3, 2, 3 }, { -1, 1, 0 }, BAMBU, "WoodPlanks"),
		part("CrateB", "Block", { 3, 2, 3 }, { 1, 1, 0 }, BAMBU, "WoodPlanks"),
		part("SayurA", "Cylinder", { 2.4, 1.2, 2.4 }, { -1, 2.2, 0 }, DAUN, "Grass"),
		part("SayurB", "Cylinder", { 2.4, 1.2, 2.4 }, { 1, 2.2, 0 }, SAYUR, "Grass"),
	}),
	bakedGenerated("PasarBakulA", "bakul", "generated_bamboo_basket", { 2, 2, 1.5 }, at("pasar", 4)),
	bakedGenerated("PasarBakulB", "bakul", "generated_bamboo_basket", { 2, 2, 1.5 }, at("pasar", 5)),
	procedural("PasarTimbangan", "timbangan", at("pasar", 6), {
		part("Base", "Block", { 1.8, 0.4, 1.8 }, { 0, 0.2, 0 }, KAYU, "WoodPlanks"),
		part("Post", "Cylinder", { 0.3, 3, 0.3 }, { 0, 1.9, 0 }, BESI, "Metal"),
		part("Beam", "Block", { 4, 0.3, 0.4 }, { 0, 3.3, 0 }, BESI, "Metal"),
		part("PanL", "Cylinder", { 1.4, 0.2, 1.4 }, { -1.6, 2.6, 0 }, MALAM, "Metal"),
		part("PanR", "Cylinder", { 1.4, 0.2, 1.4 }, { 1.6, 2.6, 0 }, MALAM, "Metal"),
	}),
	baked("PasarKarung", "karung", 87487192428396, { 3, 3, 2 }, at("pasar", 2)),
	baked("PasarGerobak", "gerobak", 119426685469058, { 8, 6, 5 }, at("pasar", 8)),
	baked("PasarLapak", "lapak", 115924626989907, { 10, 6, 5 }, at("pasar", 1)),
	baked("PasarJemuran", "jemuran", 138444489439223, { 8, 7, 2 }, at("pasar", 3)),
	baked("PasarPagarBambu", "pagar_bambu", 85094565897097, { 8, 5, 0.6 }, at("pasar", 0)),
}

-- Gelap alley: a lamp, a drum and cardboard boxes, with a verified sack/cart/fence behind them.
local gelap = {
	procedural("GelapLampu", "lampu", at("gelap", 4), {
		part("Post", "Cylinder", { 0.3, 4, 0.3 }, { 0, 2, 0 }, BESI, "Metal"),
		part("Shade", "Cylinder", { 1.4, 1.2, 1.4 }, { 0, 4.2, 0 }, SENJA, "SmoothPlastic"),
	}),
	procedural("GelapTong", "tong", at("gelap", 1), {
		part("Drum", "Cylinder", { 2.4, 3.6, 2.4 }, { 0, 1.8, 0 }, MALAM, "Metal"),
		part("Lid", "Cylinder", { 2.5, 0.3, 2.5 }, { 0, 3.7, 0 }, BESI, "Metal"),
	}),
	procedural("GelapKardus", "kardus", at("gelap", 3), {
		part("BoxA", "Block", { 2.6, 2, 2.4 }, { -0.6, 1, 0 }, KARDUS, "Cardboard"),
		part("BoxB", "Block", { 2, 1.6, 2 }, { 0.9, 0.8, 0.2 }, KARDUS, "Cardboard"),
		part("Flap", "Block", { 2.6, 0.1, 1 }, { -0.6, 2.1, -0.6 }, KERTAS, "Cardboard"),
	}),
	baked("GelapKarung", "karung", 87487192428396, { 3, 3, 2 }, at("gelap", 2)),
	baked("GelapGerobak", "gerobak", 10506531785, { 6, 3.4, 5 }, at("gelap", 5)),
	baked("GelapPagarBambu", "pagar_bambu", 103341007913673, { 8, 5, 0.6 }, at("gelap", 0)),
}

-- Warung: stools, a teapot and jars, plus four verified props and the well. Nine props in one row.
local warung = {
	procedural("WarungBangku", "bangku", at("warung", 4), {
		part("Seat", "Block", { 4, 0.6, 2 }, { 0, 2, 0 }, BAMBU, "WoodPlanks"),
		part("LegL", "Block", { 0.5, 2, 1.6 }, { -1.5, 1, 0 }, KAYU, "Wood"),
		part("LegR", "Block", { 0.5, 2, 1.6 }, { 1.5, 1, 0 }, KAYU, "Wood"),
	}),
	procedural("WarungTeko", "teko", at("warung", 2), {
		part("Body", "Ball", { 1.6, 1.6, 1.6 }, { 0, 0.9, 0 }, MERAH, "SmoothPlastic"),
		part("Spout", "Cylinder", { 0.4, 1.2, 0.4 }, { 1, 1.1, 0 }, MERAH, "SmoothPlastic"),
		part("Lid", "Cylinder", { 0.7, 0.2, 0.7 }, { 0, 1.8, 0 }, BESI, "Metal"),
	}),
	procedural("WarungToples", "toples", at("warung", 3), {
		part("Jar", "Cylinder", { 1.4, 2, 1.4 }, { 0, 1, 0 }, SENJA, "SmoothPlastic"),
		part("Lid", "Cylinder", { 1.5, 0.3, 1.5 }, { 0, 2.1, 0 }, MERAH, "Metal"),
	}),
	procedural("WarungTimbangan", "timbangan", at("warung", 5), {
		part("Base", "Block", { 1.6, 0.4, 1.6 }, { 0, 0.2, 0 }, KAYU, "WoodPlanks"),
		part("Post", "Cylinder", { 0.3, 2.6, 0.3 }, { 0, 1.6, 0 }, BESI, "Metal"),
		part("Beam", "Block", { 3.4, 0.3, 0.4 }, { 0, 2.9, 0 }, BESI, "Metal"),
	}),
	baked("WarungLapak", "lapak", 115924626989907, { 10, 6, 5 }, at("warung", 8)),
	baked("WarungJemuran", "jemuran", 138444489439223, { 8, 7, 2 }, at("warung", 7)),
	baked("WarungKarung", "karung", 87487192428396, { 3, 3, 2 }, at("warung", 1)),
	baked("WarungPagarBambu", "pagar_bambu", 103341007913673, { 8, 5, 0.6 }, at("warung", 0)),
	baked("WarungSumur", "sumur", 95025959179405, { 5, 4, 5 }, at("warung", 6)),
}

-- Ronda: the kentongan and a bamboo bale, with a lamp, bench, noticeboard and verified props.
-- All seven ronda props use EXPLICIT front-apron slots instead of at(): the regular at() row leaves
-- three of them behind Tree_12's canopy from the hub_ronda review camera (verified in Studio). The
-- positions below are the tree-free, non-masking solution: every centre is inside the 35-degree
-- cone, forward of front=20, clear of the item-78 door gauge, at least 6 studs from every other
-- ronda prop and unmasked by all of them in the Lune 2D proxy. Do not switch these to at().
local ronda = {
	procedural("RondaKentongan", "kentongan", { lx = -18, lz = 22 }, {
		part("Log", "Cylinder", { 1.4, 3, 1.4 }, { 0, 1.5, 0 }, KAYU, "Wood"),
		part("Slit", "Block", { 0.3, 2.2, 0.3 }, { 0, 1.5, 0.7 }, MALAM, "Wood"),
	}),
	baked("RondaBaleBambu", "bale_bambu", 85094565897097, { 8, 5, 0.6 }, { lx = -12, lz = 21 }),
	procedural("RondaLampu", "lampu", { lx = -20, lz = 28 }, {
		part("Post", "Cylinder", { 0.3, 4, 0.3 }, { 0, 2, 0 }, BESI, "Metal"),
		part("Shade", "Cylinder", { 1.4, 1.2, 1.4 }, { 0, 4.2, 0 }, SENJA, "SmoothPlastic"),
	}),
	procedural("RondaBangku", "bangku", { lx = -18, lz = 34 }, {
		part("Seat", "Block", { 4, 0.6, 2 }, { 0, 2, 0 }, BAMBU, "WoodPlanks"),
		part("LegL", "Block", { 0.5, 2, 1.6 }, { -1.5, 1, 0 }, KAYU, "Wood"),
		part("LegR", "Block", { 0.5, 2, 1.6 }, { 1.5, 1, 0 }, KAYU, "Wood"),
	}),
	procedural("RondaPapanPengumuman", "papan_pengumuman", { lx = -10, lz = 29 }, {
		part("PostL", "Cylinder", { 0.3, 4, 0.3 }, { -2, 2, 0 }, KAYU, "Wood"),
		part("PostR", "Cylinder", { 0.3, 4, 0.3 }, { 2, 2, 0 }, KAYU, "Wood"),
		part("Board", "Block", { 5, 2.2, 0.3 }, { 0, 3.2, 0 }, KERTAS, "WoodPlanks"),
	}),
	baked("RondaJemuran", "jemuran", 138444489439223, { 8, 7, 2 }, { lx = -6, lz = 24 }),
	baked("RondaKarung", "karung", 87487192428396, { 3, 3, 2 }, { lx = 6, lz = 21 }),
}

-- Polisi: a flag, a noticeboard and the verified motorcycle, plus a desk, chairs and a lamp.
local polisi = {
	procedural("PolisiBendera", "bendera", at("polisi", 0), {
		part("Pole", "Cylinder", { 0.3, 8, 0.3 }, { 0, 4, 0 }, BESI, "Metal"),
		part("Flag", "Block", { 4, 2.4, 0.2 }, { 2, 6.5, 0 }, MERAH, "Fabric"),
	}),
	procedural("PolisiPapanPengumuman", "papan_pengumuman", at("polisi", 3), {
		part("PostL", "Cylinder", { 0.3, 4, 0.3 }, { -2, 2, 0 }, KAYU, "Wood"),
		part("PostR", "Cylinder", { 0.3, 4, 0.3 }, { 2, 2, 0 }, KAYU, "Wood"),
		part("Board", "Block", { 5, 2.2, 0.3 }, { 0, 3.2, 0 }, MALAM, "WoodPlanks"),
	}),
	baked("PolisiMotor", "motor", 106061905410704, { 6, 4, 2.5 }, at("polisi", 5)),
	procedural("PolisiMeja", "meja", at("polisi", 4), {
		part("Top", "Block", { 5, 0.5, 3 }, { 0, 3, 0 }, BAMBU, "WoodPlanks"),
		part("LegL", "Block", { 0.5, 3, 2.6 }, { -2, 1.5, 0 }, KAYU, "Wood"),
		part("LegR", "Block", { 0.5, 3, 2.6 }, { 2, 1.5, 0 }, KAYU, "Wood"),
	}),
	procedural("PolisiKursi", "kursi", at("polisi", 6), {
		part("Seat", "Block", { 2, 0.5, 2 }, { 0, 2, 0 }, BAMBU, "WoodPlanks"),
		part("Back", "Block", { 2, 2, 0.4 }, { 0, 3, -0.8 }, KAYU, "Wood"),
	}),
	procedural("PolisiLampu", "lampu", at("polisi", 1), {
		part("Post", "Cylinder", { 0.3, 4, 0.3 }, { 0, 2, 0 }, BESI, "Metal"),
		part("Shade", "Cylinder", { 1.4, 1.2, 1.4 }, { 0, 4.2, 0 }, SENJA, "SmoothPlastic"),
	}),
	baked("PolisiPagarBambu", "pagar_bambu", 85094565897097, { 8, 5, 0.6 }, at("polisi", 7)),
	baked("PolisiKarung", "karung", 87487192428396, { 3, 3, 2 }, at("polisi", 2)),
}

-- Pak RT: a table, a rattan chair and a flag (also a teapot, jars, a noticeboard and a lamp).
local pakrt = {
	procedural("PakrtMeja", "meja", at("pakrt", 6), {
		part("Top", "Block", { 5, 0.5, 3 }, { 0, 3, 0 }, BAMBU, "WoodPlanks"),
		part("LegL", "Block", { 0.5, 3, 2.6 }, { -2, 1.5, 0 }, KAYU, "Wood"),
		part("LegR", "Block", { 0.5, 3, 2.6 }, { 2, 1.5, 0 }, KAYU, "Wood"),
	}),
	procedural("PakrtKursiRotan", "kursi_rotan", at("pakrt", 3), {
		part("Seat", "Block", { 2.2, 0.5, 2 }, { 0, 2, 0 }, BAMBU, "Wood"),
		part("Back", "Block", { 2.2, 2.4, 0.4 }, { 0, 3.1, -0.8 }, BAMBU, "Wood"),
		part("Weave", "Block", { 2, 1.6, 0.2 }, { 0, 3.1, -0.55 }, KERTAS, "Fabric"),
	}),
	procedural("PakrtBendera", "bendera", at("pakrt", 7), {
		part("Pole", "Cylinder", { 0.3, 8, 0.3 }, { 0, 4, 0 }, BESI, "Metal"),
		part("Flag", "Block", { 4, 2.4, 0.2 }, { 2, 6.5, 0 }, MERAH, "Fabric"),
	}),
	procedural("PakrtTeko", "teko", at("pakrt", 1), {
		part("Body", "Ball", { 1.6, 1.6, 1.6 }, { 0, 0.9, 0 }, MERAH, "SmoothPlastic"),
		part("Spout", "Cylinder", { 0.4, 1.2, 0.4 }, { 1, 1.1, 0 }, MERAH, "SmoothPlastic"),
	}),
	procedural("PakrtToples", "toples", at("pakrt", 4), {
		part("Jar", "Cylinder", { 1.4, 2, 1.4 }, { 0, 1, 0 }, SENJA, "SmoothPlastic"),
		part("Lid", "Cylinder", { 1.5, 0.3, 1.5 }, { 0, 2.1, 0 }, MERAH, "Metal"),
	}),
	procedural("PakrtPapanPengumuman", "papan_pengumuman", at("pakrt", 5), {
		part("PostL", "Cylinder", { 0.3, 4, 0.3 }, { -2, 2, 0 }, KAYU, "Wood"),
		part("PostR", "Cylinder", { 0.3, 4, 0.3 }, { 2, 2, 0 }, KAYU, "Wood"),
		part("Board", "Block", { 5, 2.2, 0.3 }, { 0, 3.2, 0 }, KERTAS, "WoodPlanks"),
	}),
	procedural("PakrtLampu", "lampu", at("pakrt", 2), {
		part("Post", "Cylinder", { 0.3, 4, 0.3 }, { 0, 2, 0 }, BESI, "Metal"),
		part("Shade", "Cylinder", { 1.4, 1.2, 1.4 }, { 0, 4.2, 0 }, SENJA, "SmoothPlastic"),
	}),
	baked("PakrtKarung", "karung", 87487192428396, { 3, 3, 2 }, at("pakrt", 0)),
}
ModelMapHubPropsR8.recipes = {
	pasar = pasar,
	gelap = gelap,
	warung = warung,
	ronda = ronda,
	polisi = polisi,
	pakrt = pakrt,
}
return ModelMapHubPropsR8
