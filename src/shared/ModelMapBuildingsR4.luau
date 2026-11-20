--!strict
-- ModelMapBuildingsR4: pure data for the OFF-BY-DEFAULT `buildings_r4` LookDev family
-- (WORK_QUEUE round 4 item 31). The four IDs came back from completed ROBLOX_API_KEY ->
-- Open Cloud uploads and are recorded in
-- docs/v2/visual/art/models_r4/buildings/upload_manifest.json. All engine work lives in
-- src/server/World/LookDevModelsBuildingsR4.luau; no asset ID is repeated there.
--
-- Staging is on REAL MapSpec terrain, not the round-3 (500,500) off-map corner: the row is
-- centred on MapSpec.SPAWN.x = 0 at z = SPAWN.z - 8 = 20, using the 60x60 LookDevCorner
-- staging idea but spread wider so the 22-stud stilt house does not overlap its neighbours.
-- Fronts face the saved +Z review camera; `rotX` is reserved for Z-up imports (all 0 here).

export type Vec3 = {
	x: number,
	y: number,
	z: number,
}

export type Slot = {
	slot: string,
	x: number,
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
}

local ModelMapBuildingsR4 = {}

ModelMapBuildingsR4.familyId = "buildings_r4"

ModelMapBuildingsR4.staging = {
	groundY = 0.5, -- MapSpec.GROUND_Y
	origin = { x = 0, y = 0.5, z = 20 }, -- SPAWN.x, SPAWN.z - 8
	derivedFrom = "MapSpec.SPAWN { x = 0, y = 0.5, z = 28 } + LookDevCorner staging offset (centred row, real terrain)",
}

ModelMapBuildingsR4.camera = {
	position = { x = 0, y = 22, z = 84 },
	lookAt = { x = 0, y = 7, z = 20 },
	derivedFrom = "SPAWN.x / SPAWN.z - 8; camera 64 studs toward +Z, inside MapSpec.TERRAIN_HALF",
}

ModelMapBuildingsR4.families = {
	buildings_r4 = {
		id = "buildings_r4",
		title = "R4 village buildings — textured CC0 stilt house, chicken coop, storehouse, warung",
		ids = {
			rumah = 134692206104779,
			kandang = 102638587410748,
			gudang = 108444766706310,
			warung = 123167704485524,
		},
		-- Row across X at z=20; camera {0,22,84} -> {0,7,20}. Source fronts: rumah faces -Z
		-- (rotated pi), the other three face +Z. Reviewed, not graded.
		slots = {
			{ slot = "rumah", x = -38, z = 20, ry = math.pi, rotX = 0, targetHeight = 22 },
			{ slot = "kandang", x = 4, z = 20, ry = 0, rotX = 0, targetHeight = 6 },
			{ slot = "gudang", x = 22, z = 20, ry = 0, rotX = 0, targetHeight = 10 },
			{ slot = "warung", x = 40, z = 20, ry = 0, rotX = 0, targetHeight = 9 },
		},
	},
} :: { [string]: Family }

function ModelMapBuildingsR4.idsFor(family: string): { [string]: number }?
	local entry = ModelMapBuildingsR4.families[family]
	return if entry then entry.ids else nil
end

function ModelMapBuildingsR4.slotsFor(family: string): { Slot }
	local entry = ModelMapBuildingsR4.families[family]
	return if entry then entry.slots else {}
end

function ModelMapBuildingsR4.familyIds(): { string }
	return { ModelMapBuildingsR4.familyId }
end

function ModelMapBuildingsR4.count(): number
	local total = 0
	for _ in pairs(ModelMapBuildingsR4.families[ModelMapBuildingsR4.familyId].ids) do
		total += 1
	end
	return total
end

return ModelMapBuildingsR4
