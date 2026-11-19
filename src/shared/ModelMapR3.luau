--!strict
-- ModelMapR3: real round-3 Model asset IDs and corner staging for the four OFF-BY-DEFAULT
-- "buildings_r3", "vegetation_r3", "props_r3" and "npcs_r3" LookDev candidates
-- (WORK_QUEUE round 3 item 23). All 20 IDs came back from completed ROBLOX_API_KEY -> Open
-- Cloud uploads and are recorded in docs/v2/visual/art/models_r3/upload_manifest.json.
-- The IDs live here, not in the server adapter, so the "no asset IDs in LookDev/adapters" guard
-- still holds. Pure data: no game APIs at load time, so specs can require this under Lune.
--
-- Positions are absolute, inside the 60x60 corner (origin { 500, 0, 500 }, X/Z 470-530).
-- Each family is a single tidy row facing its saved review camera in MANIFEST.md, with at
-- least 4 studs between neighbouring slots. `ry` is a Y rotation in radians.

export type Slot = {
	slot: string,
	x: number,
	z: number,
	ry: number,
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
}

local ModelMapR3 = {}

ModelMapR3.families = {
	buildings_r3 = {
		id = "buildings_r3",
		title = "R3 village buildings — rumah panggung, chicken coop, sawah storehouse",
		ids = {
			rumah = 85063409548405,
			kandang = 119940478952704,
			gudang = 111256303923528,
		},
		-- Camera { 500, 16, 542 } -> { 500, 4, 490 }: row across X, fronts toward +Z.
		slots = {
			{ slot = "rumah", x = 484, z = 502, ry = math.pi },
			{ slot = "kandang", x = 500, z = 502, ry = math.pi },
			{ slot = "gudang", x = 516, z = 502, ry = math.pi },
		},
	},

	vegetation_r3 = {
		id = "vegetation_r3",
		title = "R3 tropical vegetation — kelapa, bambu, pisang, mangga, shrubs",
		ids = {
			kelapa_cc0 = 110335398915554,
			bambu_cc0 = 118009659509388,
			kelapa_alt = 109494105307245,
			pisang = 101217327819812,
			mangga = 121015860286403,
			shrubs = 130954290306373,
		},
		-- Camera { 468, 12, 520 } -> { 500, 4, 500 }: row perpendicular to that view.
		slots = {
			{ slot = "kelapa_cc0", x = 487, z = 479, ry = -1.0 },
			{ slot = "bambu_cc0", x = 492, z = 487, ry = -1.0 },
			{ slot = "kelapa_alt", x = 497, z = 496, ry = -1.0 },
			{ slot = "pisang", x = 503, z = 504, ry = -1.0 },
			{ slot = "mangga", x = 508, z = 513, ry = -1.0 },
			{ slot = "shrubs", x = 513, z = 521, ry = -1.0 },
		},
	},

	props_r3 = {
		id = "props_r3",
		title = "R3 village props — cart, well, market stall, bamboo fence, tools",
		ids = {
			cart = 123070528502160,
			well = 108779169207130,
			stall = 119525167329493,
			fence = 85094565897097,
			tools = 110400413362502,
		},
		-- Camera { 532, 11, 500 } -> { 498, 2, 500 }: row across Z, fronts toward +X.
		slots = {
			{ slot = "cart", x = 500, z = 480, ry = -math.pi / 2 },
			{ slot = "well", x = 500, z = 490, ry = -math.pi / 2 },
			{ slot = "stall", x = 500, z = 500, ry = -math.pi / 2 },
			{ slot = "fence", x = 500, z = 510, ry = -math.pi / 2 },
			{ slot = "tools", x = 500, z = 520, ry = -math.pi / 2 },
		},
	},

	npcs_r3 = {
		id = "npcs_r3",
		title = "R3 villagers — farmer, polisi and four distinct villagers",
		ids = {
			farmer_cc0 = 109551357778200,
			polisi_cc0 = 95267863359958,
			villager_a = 75743269173481,
			villager_b = 100304009103314,
			villager_c = 75017945133929,
			villager_d = 128549093376717,
		},
		-- Camera { 500, 7, 524 } -> { 500, 2, 500 }: row across X, fronts toward +Z.
		slots = {
			{ slot = "farmer_cc0", x = 480, z = 500, ry = math.pi },
			{ slot = "polisi_cc0", x = 488, z = 500, ry = math.pi },
			{ slot = "villager_a", x = 496, z = 500, ry = math.pi },
			{ slot = "villager_b", x = 504, z = 500, ry = math.pi },
			{ slot = "villager_c", x = 512, z = 500, ry = math.pi },
			{ slot = "villager_d", x = 520, z = 500, ry = math.pi },
		},
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "buildings_r3", "vegetation_r3", "props_r3", "npcs_r3" }

function ModelMapR3.idsFor(family: string): { [string]: number }?
	local entry = ModelMapR3.families[family]
	return if entry then entry.ids else nil
end

function ModelMapR3.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapR3.count(): number
	local total = 0
	for _, family in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapR3.families[family].ids) do
			total += 1
		end
	end
	return total
end

return ModelMapR3
