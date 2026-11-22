--!strict
-- ModelMapBuildingsR8: pure data for the OFF-BY-DEFAULT "buildings_r8" LookDev candidate
-- (WORK_QUEUE section M item 77). No game APIs, no Instances, no Enum at load: Lune specs can
-- require this module directly.
--
-- Six real free Creator Store buildings, staged in one row with 20 studs of CLEAR GAP between
-- adjacent footprints (centre spacing varies with each staged width). The site is chosen at apply
-- time by LookDevBuildingsR8 as a model-free box. Sizes are native world bounding boxes in studs
-- (X=width, Y=height, Z=depth) measured in Studio; staged = native * scale. rumah_joglo REQUIRES
-- scale 0.75: native width 76.87 breaks the 12..60 width band, staged 57.66 fits. The applier
-- scales with Model:ScaleTo BEFORE measuring the bbox and placing the gauge.

export type Slot = {
	slot: string,
	id: number,
	name: string,
	creator: string,
	nativeWidth: number,
	nativeHeight: number,
	nativeDepth: number,
	scale: number,
	stagedWidth: number,
	stagedHeight: number,
	stagedDepth: number,
	clearFacade: string, -- "front" (min Z), or "both" (runtime probe picks front unless blocked)
	source: string,
}

export type Camera = {
	position: { x: number, y: number, z: number },
	target: { x: number, y: number, z: number },
}

local ModelMapBuildingsR8 = {}

ModelMapBuildingsR8.familyId = "buildings_r8"
ModelMapBuildingsR8.folderName = "LookDevBuildingsR8_buildings_r8"
ModelMapBuildingsR8.tagAttribute = "LookDevBuildingsR8"
ModelMapBuildingsR8.slotAttribute = "BuildingSlot"
ModelMapBuildingsR8.gaugeName = "DoorGauge"
ModelMapBuildingsR8.gaugeKindAttribute = "GaugeKind"
ModelMapBuildingsR8.facadeAttribute = "Facade"
ModelMapBuildingsR8.cameraPosAttribute = "ReviewCameraPos"
ModelMapBuildingsR8.cameraLookAttribute = "ReviewLookAt"

-- 20 studs of CLEAR GAP between adjacent footprints, not centre spacing: a fixed 20-stud centre
-- pitch makes wide buildings overlap and mutually occlude in the review cone.
ModelMapBuildingsR8.gap = 20
ModelMapBuildingsR8.trunkClearance = 15
ModelMapBuildingsR8.padMargin = 2

-- Site: a 340x80 footprint (70 studs tall, probed at Y=25) that must be free of existing World
-- Models; the shipping Pasar/Warung hubs occupy the old (0,-62) yard.
ModelMapBuildingsR8.siteWidth = 340
ModelMapBuildingsR8.siteDepth = 80
ModelMapBuildingsR8.siteHeight = 70
ModelMapBuildingsR8.siteProbeY = 25

-- One avatar-fit gauge per building, staged as a real Part so the harness can recompute clearance.
ModelMapBuildingsR8.gauge = {
	width = 7,
	height = 7.25, -- >= the required 7; >= AVATAR_HEIGHT
	depth = 2,
	floorOffset = 1.5, -- keeps the ground slab out of the opening probe
}

ModelMapBuildingsR8.MIN_WIDTH = 12
ModelMapBuildingsR8.MAX_WIDTH = 60
ModelMapBuildingsR8.MIN_DOOR = 7
ModelMapBuildingsR8.AVATAR_HEIGHT = 7.25

-- Signed Z offset from the row centre. Negative `front` puts the camera on the min-Z (facade)
-- side: 228 studs out, 60 up. This is the verified clear vantage; the old +Z 215/30 rule had rays
-- blocked by shipping World buildings (PosPolisi/RumahPakRT) between camera and the row.
ModelMapBuildingsR8.cameraRule = { front = -228, up = 60, lookY = 16 }

-- Exact WORK_QUEUE order. Every id is a real free Creator Store model from search_asset; none
-- invented. The rejected no-clear-opening asset is deliberately absent from this map.
ModelMapBuildingsR8.order = {
	"indonesian_house",
	"rumah_4",
	"rumah_joglo",
	"pendopo_jawa",
	"warung_penyetan",
	"nipa_hut",
}

ModelMapBuildingsR8.slots = {
	{
		slot = "indonesian_house",
		id = 81909711760416,
		name = "indonesian_house",
		creator = "Dagelan_Smg",
		nativeWidth = 36.67,
		nativeHeight = 30.00,
		nativeDepth = 52.03,
		scale = 1.0,
		stagedWidth = 36.67,
		stagedHeight = 30.00,
		stagedDepth = 52.03,
		clearFacade = "front",
		source = "Creator Store, free (search_asset)",
	},
	{
		slot = "rumah_4",
		id = 140621903274156,
		name = "rumah_4",
		creator = "Dagelan_Smg",
		nativeWidth = 37.61,
		nativeHeight = 31.53,
		nativeDepth = 54.80,
		scale = 1.0,
		stagedWidth = 37.61,
		stagedHeight = 31.53,
		stagedDepth = 54.80,
		clearFacade = "both",
		source = "Creator Store, free (search_asset)",
	},
	{
		slot = "rumah_joglo",
		id = 4820552419,
		name = "rumah_joglo",
		creator = "Annovaire",
		nativeWidth = 76.87,
		nativeHeight = 44.00,
		nativeDepth = 75.35,
		scale = 0.75, -- required: 76.87 native width is outside 12..60
		stagedWidth = 57.66, -- 76.87 * 0.75 = 57.6525; handoff figure 57.66
		stagedHeight = 33.00,
		stagedDepth = 56.51,
		clearFacade = "both",
		source = "Creator Store, free (search_asset)",
	},
	{
		slot = "pendopo_jawa",
		id = 136417251697510,
		name = "pendopo_jawa",
		creator = "Pramadhita_wira",
		nativeWidth = 30.52,
		nativeHeight = 48.10,
		nativeDepth = 51.56,
		scale = 1.0,
		stagedWidth = 30.52,
		stagedHeight = 48.10,
		stagedDepth = 51.56,
		clearFacade = "both",
		source = "Creator Store, free (search_asset)",
	},
	{
		slot = "warung_penyetan",
		id = 118767493095408,
		name = "warung_penyetan",
		creator = "Voltcho1354",
		nativeWidth = 24.00,
		nativeHeight = 13.02,
		nativeDepth = 13.82,
		scale = 1.0,
		stagedWidth = 24.00,
		stagedHeight = 13.02,
		stagedDepth = 13.82,
		clearFacade = "both",
		source = "Creator Store, free (search_asset)",
	},
	{
		slot = "nipa_hut",
		id = 167594119,
		name = "nipa_hut",
		creator = "SanchettaSam", -- "Nipa Hut Set"
		nativeWidth = 22.72,
		nativeHeight = 28.42,
		nativeDepth = 44.29,
		scale = 1.0,
		stagedWidth = 22.72,
		stagedHeight = 28.42,
		stagedDepth = 44.29,
		clearFacade = "both",
		source = "Creator Store, free (search_asset)",
	},
} :: { Slot }

local ids: { [string]: number } = {}
for _, entry in ipairs(ModelMapBuildingsR8.slots) do
	ids[entry.slot] = entry.id
end
ModelMapBuildingsR8.ids = ids

function ModelMapBuildingsR8.idsFor(family: string): { [string]: number }?
	return if family == ModelMapBuildingsR8.familyId then ids else nil
end

function ModelMapBuildingsR8.slotsFor(family: string): { Slot }
	return if family == ModelMapBuildingsR8.familyId then ModelMapBuildingsR8.slots else {}
end

function ModelMapBuildingsR8.count(): number
	return #ModelMapBuildingsR8.order
end

-- X offsets of slot centres from the left edge of the row: offset[1]=0; each later offset adds
-- half the previous staged width, the clear gap, and half the current staged width.
function ModelMapBuildingsR8.rowOffsets(): { number }
	local offsets: { number } = {}
	for index, entry in ipairs(ModelMapBuildingsR8.slots) do
		if index == 1 then
			offsets[index] = 0
		else
			local previous = ModelMapBuildingsR8.slots[index - 1]
			offsets[index] = offsets[index - 1]
				+ previous.stagedWidth / 2
				+ ModelMapBuildingsR8.gap
				+ entry.stagedWidth / 2
		end
	end
	return offsets
end

-- Absolute slot centres for a row centred on centreX (defaults to the origin).
function ModelMapBuildingsR8.rowCentres(centreX: number?): { number }
	local offsets = ModelMapBuildingsR8.rowOffsets()
	local slots = ModelMapBuildingsR8.slots
	local left = offsets[1] - slots[1].stagedWidth / 2
	local right = offsets[#offsets] + slots[#offsets].stagedWidth / 2
	local rowMiddle = (left + right) / 2
	local base = centreX or 0
	local centres: { number } = {}
	for index, offset in ipairs(offsets) do
		centres[index] = base + offset - rowMiddle
	end
	return centres
end

-- Legacy API kept: X offset from the row centre for a 1-based slot index, now gap-derived.
function ModelMapBuildingsR8.rowOffset(index: number): number
	return ModelMapBuildingsR8.rowCentres()[index] or 0
end

-- Pure camera rule, evaluated against the yard centre the applier picked in Studio.
function ModelMapBuildingsR8.cameraFor(centreX: number, centreZ: number): Camera
	local rule = ModelMapBuildingsR8.cameraRule
	return {
		position = { x = centreX, y = rule.up, z = centreZ + rule.front },
		target = { x = centreX, y = rule.lookY, z = centreZ },
	} :: Camera
end

return ModelMapBuildingsR8
