--!strict
-- ModelMapR3: real round-3 Model asset IDs and staged corner slots for the four OFF-BY-DEFAULT
-- "buildings_r3", "vegetation_r3", "props_r3" and "npcs_r3" LookDev candidates
-- (WORK_QUEUE round 3 item 23, bug fixes item 28). All 20 IDs came back from completed
-- ROBLOX_API_KEY -> Open Cloud uploads and are recorded in
-- docs/v2/visual/art/models_r3/upload_manifest.json. The IDs live here, not in the server adapter,
-- so the "no asset IDs in LookDev/adapters" guard still holds. Pure data: no game APIs at load.
--
-- ROUND-3 BUGS 3-6: staging is on REAL PLAZA ground (MapSpec.PLAZA spans X -48..48, Z -42..42),
-- centred at STAGING_ORIGIN, off the spawn/road/hub clearings. Every slot has a targetHeight in
-- studs (the server adapter calls Model:ScaleTo(targetHeight / loaded Y size)); farmer_cc0 and
-- polisi_cc0 carry rotX = math.pi/2 to fix the Z-up/Y-up import error. `ry` is the Y rotation in
-- radians and is applied together with rotX in one target CFrame.

export type Slot = {
	slot: string,
	x: number,
	z: number,
	ry: number,
	targetHeight: number,
	rotX: number?,
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
}

local ModelMapR3 = {}

-- Data seam: the same centre is used by LookDevCorner and SkyMapR3; the regression spec asserts
-- all three agree and that every coordinate stays inside the real MapSpec ground footprint.
ModelMapR3.STAGING_ORIGIN = { x = -14, z = -12 }

ModelMapR3.families = {
	buildings_r3 = {
		id = "buildings_r3",
		title = "R3 village buildings — rumah panggung, chicken coop, sawah storehouse",
		ids = {
			rumah = 85063409548405,
			kandang = 119940478952704,
			gudang = 111256303923528,
		},
		-- Camera { -14, 16, 30 } -> { -14, 4, -22 }: row across X, fronts toward +Z.
		slots = {
			{ slot = "rumah", x = -30, z = -10, ry = math.pi, targetHeight = 22 },
			{ slot = "kandang", x = -14, z = -10, ry = math.pi, targetHeight = 12 },
			{ slot = "gudang", x = 2, z = -10, ry = math.pi, targetHeight = 14 },
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
		-- Camera { -46, 12, 8 } -> { -14, 4, -12 }: row perpendicular to that view.
		slots = {
			{ slot = "kelapa_cc0", x = -27, z = -33, ry = -1.0, targetHeight = 30 },
			{ slot = "bambu_cc0", x = -22, z = -25, ry = -1.0, targetHeight = 20 },
			{ slot = "kelapa_alt", x = -17, z = -16, ry = -1.0, targetHeight = 28 },
			{ slot = "pisang", x = -11, z = -8, ry = -1.0, targetHeight = 12 },
			{ slot = "mangga", x = -6, z = 1, ry = -1.0, targetHeight = 22 },
			{ slot = "shrubs", x = -1, z = 9, ry = -1.0, targetHeight = 6 },
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
		-- Camera { 18, 11, -12 } -> { -16, 2, -12 }: row across Z, fronts toward +X.
		slots = {
			{ slot = "cart", x = -14, z = -32, ry = -math.pi / 2, targetHeight = 6 },
			{ slot = "well", x = -14, z = -22, ry = -math.pi / 2, targetHeight = 8 },
			{ slot = "stall", x = -14, z = -12, ry = -math.pi / 2, targetHeight = 10 },
			{ slot = "fence", x = -14, z = -2, ry = -math.pi / 2, targetHeight = 5 },
			{ slot = "tools", x = -14, z = 8, ry = -math.pi / 2, targetHeight = 3 },
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
		-- Camera { -14, 7, 12 } -> { -14, 2, -12 }: row across X, fronts toward +Z.
		-- rotX = pi/2 stands the two CC0 Z-up imports upright (round-3 bug 5).
		slots = {
			{ slot = "farmer_cc0", x = -34, z = -12, ry = math.pi, rotX = math.pi / 2, targetHeight = 5 },
			{ slot = "polisi_cc0", x = -26, z = -12, ry = math.pi, rotX = math.pi / 2, targetHeight = 5 },
			{ slot = "villager_a", x = -18, z = -12, ry = math.pi, targetHeight = 5 },
			{ slot = "villager_b", x = -10, z = -12, ry = math.pi, targetHeight = 5 },
			{ slot = "villager_c", x = -2, z = -12, ry = math.pi, targetHeight = 5 },
			{ slot = "villager_d", x = 6, z = -12, ry = math.pi, targetHeight = 5 },
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
