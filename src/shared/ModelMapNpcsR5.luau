--!strict
-- ModelMapNpcsR5: PURE DATA for the OFF-BY-DEFAULT "npcs_r5" LookDev candidate
-- (WORK_QUEUE item 40, solid Roblox R15 villagers). No Roblox APIs, no engine types:
-- colours are plain integer { r, g, b } triples so the Env harness can require this
-- module under Lune. The applier builds every role from HumanoidDescription + the
-- standard R15 rig; the only real asset IDs here are the three page-verified
-- Creator Store hat Models recorded in
-- docs/v2/visual/art/models_r5/npcs/MANIFEST.md.
--
-- Staging reuses the round-4 NPC row so the saved camera sees all five roles:
-- x = -16..16, y = 0.5, z = 8, ry = 0 (fronts toward +Z);
-- camera { 0, 7, 28 } -> lookAt { 0, 2.5, 8 }, player height 5 studs.

export type Rgb = {
	r: number,
	g: number,
	b: number,
}

export type Role = {
	id: string,
	skin: Rgb,
	shirt: Rgb,
	pants: Rgb,
	hat: string?, -- key into ModelMapNpcsR5.accessories; nil = Designer build / body only
}

export type Slot = {
	slot: string,
	x: number,
	y: number,
	z: number,
	ry: number,
	targetHeight: number,
}

export type Accessory = {
	id: number,
	name: string,
	creator: string,
	url: string,
	licence: string,
	kind: string,
	sourceSize: { number },
	targetSize: number, -- largest dimension in studs after the applier scales the hat
	offsetY: number, -- relative to the character's Head position
}

export type Family = {
	id: string,
	roles: { [string]: Role },
	slots: { Slot },
	camera: {
		position: { number },
		lookAt: { number },
	},
}

local ModelMapNpcsR5 = {}

ModelMapNpcsR5.familyId = "npcs_r5"
ModelMapNpcsR5.groundY = 0.5
ModelMapNpcsR5.PLAYER_HEIGHT = 5

ModelMapNpcsR5.families = {
	npcs_r5 = {
		id = "npcs_r5",
		-- Warm Indonesian-village palette; polisi is navy blue. Body colours only
		-- where no genuine free peci / batik / sarong Model was found.
		roles = {
			petani = {
				id = "petani",
				skin = { r = 198, g = 148, b = 106 },
				shirt = { r = 86, g = 122, b = 84 },
				pants = { r = 104, g = 84, b = 62 },
				hat = "caping",
			},
			pedagang = {
				id = "pedagang",
				skin = { r = 190, g = 138, b = 96 },
				shirt = { r = 170, g = 72, b = 56 },
				pants = { r = 72, g = 82, b = 104 },
			},
			petani_wanita = {
				id = "petani_wanita",
				skin = { r = 204, g = 156, b = 116 },
				shirt = { r = 206, g = 128, b = 74 },
				pants = { r = 110, g = 76, b = 92 },
				hat = "caping",
			},
			tukang_peci = {
				id = "tukang_peci",
				skin = { r = 186, g = 134, b = 94 },
				shirt = { r = 46, g = 92, b = 118 },
				pants = { r = 84, g = 78, b = 68 },
			},
			polisi = {
				id = "polisi",
				skin = { r = 196, g = 146, b = 108 },
				shirt = { r = 30, g = 46, b = 92 },
				pants = { r = 26, g = 38, b = 76 },
				hat = "polisi_cap",
			},
		},
		-- One flat row on real plaza ground; no source-model tilt is needed,
		-- so the applier only ever spins each rig about its vertical axis.
		slots = {
			{ slot = "petani", x = -16, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "pedagang", x = -8, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "petani_wanita", x = 0, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "tukang_peci", x = 8, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "polisi", x = 16, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
		},
		camera = {
			position = { 0, 7, 28 },
			lookAt = { 0, 2.5, 8 },
		},
	},
} :: { [string]: Family }

-- Verified Creator Store Model assets only. These are Model assets, NOT Accessory
-- assets: the applier loads them with InsertService and parents the mesh by hand.
-- They are never passed to HumanoidDescription.HatAccessory / ShirtAssetIds.
ModelMapNpcsR5.accessories = {
	caping = {
		id = 71002247087415,
		name = "Chinese Straw Hat Asian Conical Rice Farmer Hats",
		creator = "Zephban5961",
		url = "https://create.roblox.com/store/asset/71002247087415",
		licence = "Creator Store FREE",
		kind = "Model",
		sourceSize = { 2.4, 0.6, 2.2 },
		targetSize = 2,
		offsetY = 0.6,
	},
	caping_backup = {
		id = 14769019514,
		name = "Oriental Bamboo Conical Hat",
		creator = "RZKU",
		url = "https://create.roblox.com/store/asset/14769019514",
		licence = "Creator Store FREE",
		kind = "Model",
		sourceSize = { 2, 0.6, 2 },
		targetSize = 2,
		offsetY = 0.6,
	},
	polisi_cap = {
		id = 126970096704856,
		name = "Police Hat Cap Cop Officer Headwear Hats Accessory",
		creator = "Mukamato101",
		url = "https://create.roblox.com/store/asset/126970096704856",
		licence = "Creator Store FREE",
		kind = "Model",
		sourceSize = { 1, 1, 1 },
		targetSize = 1.5,
		offsetY = 0.5,
	},
} :: { [string]: Accessory }

-- No reliable genuine free match was found for peci/kopiah, batik shirt or sarong.
-- No substitute ID is invented: these are Designer builds, and their roles get
-- body colours only in this candidate.
ModelMapNpcsR5.designerBuild = {
	note = "peci/kopiah, batik shirt and sarong: no reliable genuine free match found; Designer builds, body colours only in npcs_r5",
	roles = { "pedagang", "tukang_peci" },
	missing = { "peci/kopiah", "batik shirt", "sarong" },
}

local FAMILY_IDS: { string } = { "npcs_r5" }

function ModelMapNpcsR5.rolesFor(family: string): { [string]: Role }?
	local entry = ModelMapNpcsR5.families[family]
	return if entry then entry.roles else nil
end

function ModelMapNpcsR5.slotsFor(family: string): { Slot }
	local entry = ModelMapNpcsR5.families[family]
	return if entry then entry.slots else {}
end

function ModelMapNpcsR5.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapNpcsR5.count(): number
	local total = 0
	for _, familyId in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapNpcsR5.rolesFor(familyId) or {}) do
			total += 1
		end
	end
	return total
end

return ModelMapNpcsR5
