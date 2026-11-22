--!strict
-- ModelMapNpcsR4: pure data for the OFF-BY-DEFAULT "npcs_r4" LookDev candidate
-- (WORK_QUEUE round 4 item 31). Five real, page-verified textured Model assets;
-- every ID came back from a completed ROBLOX_API_KEY -> Open Cloud upload and is
-- recorded in docs/v2/visual/art/models_r4/npcs/upload_manifest.json.
--
-- Staging is on REAL terrain near spawn, not the old (500,500) corner:
--   MapSpec.SPAWN = { x = 0, y = 0.5, z = 28, lookZ = -1 }
--   MapSpec.PLAZA = { x = 0, z = 0, width = 96, depth = 84 }
--   MapSpec.GROUND_Y = 0.5, MapSpec.TERRAIN_HALF = 400
-- The row sits at z = 8, x = -16..16 on the plaza's flat ground, facing the
-- saved review camera at the spawn position. No game API is called here; specs
-- require this module under Lune and cross-check the camera against MapSpec.

export type Slot = {
	slot: string,
	x: number,
	y: number,
	z: number,
	ry: number,
	rotX: number?,
	targetHeight: number,
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
	camera: {
		position: { number },
		lookAt: { number },
	},
}

local ModelMapNpcsR4 = {}

ModelMapNpcsR4.families = {
	npcs_r4 = {
		id = "npcs_r4",
		title = "R4 villagers — petani caping, pedagang, petani wanita, tukang peci, polisi",
		ids = {
			petani_caping = 119484467697394,
			pedagang = 77509780044045,
			petani_wanita = 123174857731098,
			tukang_peci = 115389644627447,
			polisi = 105455683512183,
		},
		-- Camera { 0, 7, 28 } -> { 0, 2.5, 8 }: row across X, fronts toward +Z.
		slots = {
			{ slot = "petani_caping", x = -16, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "pedagang", x = -8, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			-- Source is Z-up: the source's +Z lies in world Z, so rotX = -pi/2 lifts it to +Y.
			{ slot = "petani_wanita", x = 0, y = 0.5, z = 8, ry = 0, rotX = -math.pi / 2, targetHeight = 5 },
			{ slot = "tukang_peci", x = 8, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
			{ slot = "polisi", x = 16, y = 0.5, z = 8, ry = 0, targetHeight = 5 },
		},
		camera = {
			position = { 0, 7, 28 },
			lookAt = { 0, 2.5, 8 },
		},
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "npcs_r4" }

function ModelMapNpcsR4.idsFor(family: string): { [string]: number }?
	local entry = ModelMapNpcsR4.families[family]
	return if entry then entry.ids else nil
end

function ModelMapNpcsR4.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapNpcsR4.count(): number
	local total = 0
	for _, familyId in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapNpcsR4.families[familyId].ids) do
			total += 1
		end
	end
	return total
end

return ModelMapNpcsR4
