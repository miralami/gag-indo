--!strict
-- ModelMapPropsR6: pure data for the OFF-BY-DEFAULT "props_r6" LookDev candidate
-- (WORK_QUEUE item 50, props at real size). Every asset ID is reused from ModelMapPropsR4 via
-- require — this module never constructs an ID. Over R5 it corrects the tool scales so the
-- gerobak, sumur and cangkul (R4 `alat_tani`) read at real size against the 5-stud player, adds a
-- named `targets` table the spec checks against actual GetBoundingBox sizes, and moves the saved
-- camera out from behind the pine row. No game APIs, no instances, no ID literals: Lune requires
-- this module directly.
--
-- `effectiveHeight(entry) = entry.targetHeight * entry.scale`; the R6 applier turns that into
-- Model:ScaleTo(effectiveHeight / loadedYSize), so scale 1 keeps R4 exactly.

local ModelMapPropsR4 = require(script.Parent.ModelMapPropsR4)
local ModelMapPropsR5 = require(script.Parent.ModelMapPropsR5)

export type Slot = {
	slot: string,
	x: number,
	z: number,
	ry: number,
	rotX: number,
	targetHeight: number, -- R4 base height in studs
	scale: number, -- multiplier over targetHeight; 1 = unchanged from R4
}

export type Sack = {
	dx: number,
	dy: number,
	dz: number,
	ry: number,
}

export type KarungGroup = Slot & {
	context: string,
	note: string,
	stack: { Sack },
	yOffset: number?,
}

export type Family = {
	id: string,
	title: string,
	ids: { [string]: number },
	slots: { Slot },
	karung: KarungGroup,
}

export type Camera = {
	position: { x: number, y: number, z: number },
	target: { x: number, y: number, z: number },
}

local ModelMapPropsR6 = {}

ModelMapPropsR6.familyId = "props_r6"
ModelMapPropsR6.groundY = ModelMapPropsR4.groundY

-- Player-height reference from MapSpec / the visual docs. Used by the spec, not an engine call.
ModelMapPropsR6.PLAYER_HEIGHT = 5

-- Final stud sizes the spec compares with post-ScaleTo GetBoundingBox measurements.
-- gerobak.length is the ~8-stud longitudinal planning target from WORK_QUEUE item 50.
ModelMapPropsR6.targets = {
	gerobak = { height = 6, length = 8 },
	sumur = { height = 4.5 },
	lapak = { height = 4.8 },
	pagar_bambu = { height = 5 },
	alat_tani = { height = 4.5 }, -- cangkul hand tool
	karung = { height = 2 },
	jemuran = { height = 7 },
}

-- R4's saved camera {142,9,146} -> {142,3,122} sat behind the pine row. Shift the eye +12 in X
-- to sidestep the pines; the look target stays on the two prop staging rows.
ModelMapPropsR6.camera = {
	position = { x = 154, y = 10, z = 140 },
	target = { x = 142, y = 3, z = 122 },
} :: Camera

-- Multipliers over the R4 targetHeight. gerobak 6 -> 6 tall (~8 long), sumur 5 -> 4.5,
-- alat_tani (cangkul) 3 -> 4.5. lapak/pagar_bambu/karung/jemuran keep their R5 behaviour.
local SCALES: { [string]: number } = {
	gerobak = 1, -- 6 -> 6 studs tall, cart ~8 long
	sumur = 0.9, -- 5 -> 4.5 studs, in the requested 4-5 band
	lapak = 0.6, -- 8 -> 4.8 studs, unchanged from R5
	pagar_bambu = 1, -- untouched from R5
	alat_tani = 1.5, -- 3 -> 4.5 studs, cangkul at real size
	karung = 1, -- sack context/stacking unchanged from R5
	jemuran = 1, -- designer liked R5's jemuran
}

local r5Family = ModelMapPropsR5.families.props_r5

local slots: { Slot } = {}
for _, r5 in ipairs(r5Family.slots) do
	slots[#slots + 1] = {
		slot = r5.slot,
		x = r5.x,
		z = r5.z,
		ry = r5.ry,
		rotX = r5.rotX,
		targetHeight = r5.targetHeight,
		scale = SCALES[r5.slot] or 1,
	}
end

-- Reuse R5's gudang karung group verbatim (same site, note and stack; no new IDs).
local r5Karung = r5Family.karung
local karung: KarungGroup = {
	slot = r5Karung.slot,
	context = r5Karung.context,
	note = r5Karung.note,
	x = r5Karung.x,
	z = r5Karung.z,
	ry = r5Karung.ry,
	rotX = r5Karung.rotX,
	targetHeight = r5Karung.targetHeight,
	scale = SCALES.karung,
	stack = r5Karung.stack,
}

ModelMapPropsR6.families = {
	props_r6 = {
		id = "props_r6",
		title = "R6 village props — real-size gerobak/sumur/cangkul, camera clear of the pines",
		ids = ModelMapPropsR4.idsFor("props_r4") :: { [string]: number },
		slots = slots,
		karung = karung,
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "props_r6" }

function ModelMapPropsR6.idsFor(family: string): { [string]: number }?
	local entry = ModelMapPropsR6.families[family]
	return if entry then entry.ids else nil
end

function ModelMapPropsR6.slotsFor(family: string): { Slot }
	local entry = ModelMapPropsR6.families[family]
	return if entry then entry.slots else {}
end

function ModelMapPropsR6.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapPropsR6.count(): number
	local total = 0
	for _, familyId in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapPropsR6.families[familyId].ids) do
			total += 1
		end
	end
	return total
end

-- Final stud height after the per-slot scale. The applier divides this by the loaded Y size.
function ModelMapPropsR6.effectiveHeight(entry: Slot): number
	return entry.targetHeight * entry.scale
end

return ModelMapPropsR6
