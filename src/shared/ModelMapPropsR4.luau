--!strict
-- ModelMapPropsR4: pure data for the OFF-BY-DEFAULT "props_r4" LookDev candidate
-- (WORK_QUEUE round 4 item 31, props lane). All seven IDs came back from completed
-- ROBLOX_API_KEY -> Open Cloud uploads; see
-- docs/v2/visual/art/models_r4/props/upload_manifest.json. No game APIs, no instances,
-- no ID construction here, so the spec can require this under Lune.
--
-- Staging is on the real playable terrain near spawn (MapSpec.SPAWN at 0, 28);
-- unlike the round-3 corner at (500, 500), every X/Z below is inside the
-- MapSpec.TERRAIN_HALF footprint and above MapSpec.GROUND_Y. All sources are Y-up,
-- so rotX is 0 everywhere in this batch; the applier still honours a non-zero rotX.

export type Slot = {
	slot: string,
	x: number,
	z: number,
	ry: number,
	rotX: number,
	targetHeight: number,
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
}

export type Camera = {
	position: { x: number, y: number, z: number },
	target: { x: number, y: number, z: number },
}

local ModelMapPropsR4 = {}

-- Ground plane from src/server/World/Ground.luau (MapSpec.GROUND_Y).
ModelMapPropsR4.groundY = 0.5

-- Two tidy rows on the plaza's north-east shoulder, outside all six MapSpec hub
-- footprints and the plot connector ring. Camera { 142, 9, 146 } -> { 142, 3, 122 }.
ModelMapPropsR4.staging = { x = 142, z = 122, note = "real terrain near spawn; rows at z 116 and z 128" }

ModelMapPropsR4.camera = {
	position = { x = 142, y = 9, z = 146 },
	target = { x = 142, y = 3, z = 122 },
} :: Camera

ModelMapPropsR4.families = {
	props_r4 = {
		id = "props_r4",
		title = "R4 village props — real textured gerobak, sumur, lapak, pagar bambu, alat tani, karung, jemuran",
		ids = {
			gerobak = 119426685469058,
			sumur = 95025959179405,
			lapak = 115924626989907,
			pagar_bambu = 103341007913673,
			alat_tani = 109848917287023,
			karung = 87487192428396,
			jemuran = 138444489439223,
		},
		-- Row 1 faces the saved camera (+Z); row 2 is turned 0.35 rad so the fence
		-- and the drying line read side-on rather than edge-on.
		slots = {
			{ slot = "gerobak", x = 130, z = 116, ry = math.pi, rotX = 0, targetHeight = 6 },
			{ slot = "sumur", x = 138, z = 116, ry = math.pi, rotX = 0, targetHeight = 5 },
			{ slot = "lapak", x = 146, z = 116, ry = math.pi, rotX = 0, targetHeight = 8 },
			{ slot = "pagar_bambu", x = 130, z = 128, ry = 0.35, rotX = 0, targetHeight = 5 },
			{ slot = "alat_tani", x = 138, z = 128, ry = 0.35, rotX = 0, targetHeight = 3 },
			{ slot = "karung", x = 146, z = 128, ry = 0.35, rotX = 0, targetHeight = 2 },
			{ slot = "jemuran", x = 154, z = 128, ry = 0.35, rotX = 0, targetHeight = 7 },
		},
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "props_r4" }

function ModelMapPropsR4.idsFor(family: string): { [string]: number }?
	local entry = ModelMapPropsR4.families[family]
	return if entry then entry.ids else nil
end

function ModelMapPropsR4.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapPropsR4.count(): number
	local total = 0
	for _, familyId in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapPropsR4.families[familyId].ids) do
			total += 1
		end
	end
	return total
end

return ModelMapPropsR4
