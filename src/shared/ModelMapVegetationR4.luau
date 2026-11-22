--!strict
-- ModelMapVegetationR4: real round-4 Model asset IDs and staging for the OFF-BY-DEFAULT
-- "vegetation_r4" LookDev candidate (WORK_QUEUE round 4 item 31). All five IDs came back from
-- completed ROBLOX_API_KEY -> Open Cloud uploads; provenance, exact CC BY 3.0 attribution and
-- triangle counts are in docs/v2/visual/art/models_r4/vegetation/upload_manifest.json.
--
-- Pure data only: no game APIs at load time, so specs can require this under Lune. Positions are
-- absolute and on REAL MapSpec terrain: the five slots sit across the LAPANGAN (village green,
-- centre { 0, 0, 96 }, 72x56 -> |x| <= 36, 68 <= z <= 124) with the camera north of it looking
-- south. No 60x60 corner staging at (500,500): that was the round-3 bug (item 28).
--
-- `targetHeight` is the intended stud height after Model:ScaleTo (player ~5 studs). `rotX` is an
-- optional X rotation for Z-up imports; all five downloads were measured Y-up, so it is 0 here.
-- Every field is explicit so the spec can audit it without Studio.

export type Slot = {
	slot: string,
	x: number,
	z: number,
	ry: number,
	targetHeight: number,
	rotX: number,
}

export type Camera = {
	position: { number },
	target: { number },
	footprint: string,
}

export type DesignerBuild = {
	slot: string,
	targetHeight: number,
	reason: string,
	references: { string },
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
	camera: Camera,
}

local ModelMapVegetationR4 = {}

ModelMapVegetationR4.families = {
	vegetation_r4 = {
		id = "vegetation_r4",
		title = "R4 tropical vegetation — real textured kelapa, pisang, bambu, broadleaf mangga stand-in and shrubs",
		ids = {
			kelapa = 95769944522207,
			pisang = 119293239911242,
			bambu = 130965811347980,
			mangga = 103132734600778,
			shrubs = 116666781655827,
		},
		-- Camera { 0, 20, 150 } -> { 0, 8, 96 }: row across X on the lapangan, fronts toward +Z.
		slots = {
			{ slot = "kelapa", x = -32, z = 96, ry = 0, targetHeight = 30, rotX = 0 }, -- brief 25-35
			{ slot = "pisang", x = -16, z = 96, ry = 0, targetHeight = 12, rotX = 0 }, -- brief 10-14
			{ slot = "bambu", x = 0, z = 96, ry = 0, targetHeight = 21, rotX = 0 }, -- brief 18-25
			{ slot = "mangga", x = 16, z = 96, ry = 0, targetHeight = 22, rotX = 0 },
			{ slot = "shrubs", x = 32, z = 96, ry = 0, targetHeight = 3, rotX = 0 },
		},
		camera = {
			position = { 0, 20, 150 },
			target = { 0, 8, 96 },
			footprint = "MapSpec.LAPANGAN",
		},
	},
} :: { [string]: Family }

-- No licensed, downloadable free source was found for a true mango tree or for a rice plant at
-- any growth stage. These are NOT staged: they carry no ID on purpose, so the applier cannot
-- load a placeholder. Full briefs and references are in
-- docs/v2/visual/art/models_r4/vegetation/HANDOFF.md.
ModelMapVegetationR4.designerBuilds = {
	{
		slot = "mangga_true",
		targetHeight = 22,
		reason = "No CC0/CC BY downloadable mango tree; the staged 'mangga' is a CC BY broadleaf Balsa tree stand-in.",
		references = {
			"https://poly.pizza/search/mango_tree",
			"docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md (item 5, V-D4 tropical rule)",
		},
	},
	{
		slot = "padi_bibit",
		targetHeight = 1,
		reason = "No CC0/CC BY downloadable rice seedling; a 2D sprite or real plant mesh is needed (no primitives).",
		references = {
			"https://sketchfab.com/3d-models/rice-plant-be6aa4ac9adc4f558cc789a0baed8ae3",
			"docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md (item 5: single-stage CC BY candidate, authenticated download)",
		},
	},
	{
		slot = "padi_tumbuh",
		targetHeight = 2,
		reason = "Vegetative-stage rice: no compliant source; derive from the same licensed real plant if one is obtained.",
		references = {
			"docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md",
			"docs/v2/visual/art/models_r4/vegetation/HANDOFF.md",
		},
	},
	{
		slot = "padi_siap",
		targetHeight = 3,
		reason = "Fruiting-stage rice with drooping panicles: no compliant source; no script-built stand-in allowed.",
		references = {
			"docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md",
			"docs/v2/visual/art/models_r4/vegetation/HANDOFF.md",
		},
	},
} :: { DesignerBuild }

local FAMILY_IDS: { string } = { "vegetation_r4" }

function ModelMapVegetationR4.idsFor(family: string): { [string]: number }?
	local entry = ModelMapVegetationR4.families[family]
	return if entry then entry.ids else nil
end

function ModelMapVegetationR4.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapVegetationR4.count(): number
	local total = 0
	for _ in pairs(ModelMapVegetationR4.families.vegetation_r4.ids) do
		total += 1
	end
	return total
end

return ModelMapVegetationR4
