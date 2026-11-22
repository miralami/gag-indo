--!strict
-- ModelMapPropsR5: pure data for the OFF-BY-DEFAULT "props_r5" LookDev candidate
-- (WORK_QUEUE item 39, props fix). Every asset ID is reused from ModelMapPropsR4 — this module
-- requires it and never constructs an ID. The only changes over R4 are an explicit `scale`
-- multiplier per slot (so each tool reads at real-world size against the 5-stud player) and a
-- stacked karung group moved off the R4 staging row to the R4 gudang's front apron.
--
-- No game APIs, no instances, no ID literals: the Env harness can require this under Lune.
-- `effectiveHeight(entry) = entry.targetHeight * entry.scale`; R4 applier mechanics turn that
-- into Model:ScaleTo(effectiveHeight / loadedYSize), so scale 1 means "keep R4 exactly".

local ModelMapPropsR4 = require(script.Parent.ModelMapPropsR4)
local ModelMapBuildingsR4 = require(script.Parent.ModelMapBuildingsR4)

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

local ModelMapPropsR5 = {}

ModelMapPropsR5.familyId = "props_r5"
ModelMapPropsR5.groundY = ModelMapPropsR4.groundY

-- Player-height reference from MapSpec / the visual docs. Used by the spec, not an engine call.
ModelMapPropsR5.PLAYER_HEIGHT = 5

-- Multipliers over the R4 targetHeight. Values put the final stud height in the bands the
-- designer asked for: hand tool well under a 5-stud player, cart/well about waist high,
-- market stall about head high. jemuran is explicitly kept at 1 (designer: "jemuran is good").
local SCALES: { [string]: number } = {
	gerobak = 0.5, -- 6 -> 3 studs, cart bed roughly waist-high
	sumur = 0.5, -- 5 -> 2.5 studs, well rim roughly waist-high
	lapak = 0.6, -- 8 -> 4.8 studs, stall about head-high
	pagar_bambu = 1, -- not called out by the designer; left as staged in R4
	alat_tani = 0.6, -- 3 -> 1.8 studs, hand tool well under player height
	karung = 1, -- sack size unchanged; R5 fixes its CONTEXT and stacking, not its scale
	jemuran = 1, -- kept unchanged
}

local r4Family = ModelMapPropsR4.families.props_r4

-- Every R4 slot except the loose karung; the sack is relocated into the gudang group below.
local slots: { Slot } = {}
for _, r4 in ipairs(r4Family.slots) do
	if r4.slot ~= "karung" then
		slots[#slots + 1] = {
			slot = r4.slot,
			x = r4.x,
			z = r4.z,
			ry = r4.ry,
			rotX = r4.rotX,
			targetHeight = r4.targetHeight,
			scale = SCALES[r4.slot] or 1,
		}
	end
end

-- The gudang is a named storage building from ModelMapBuildingsR4, not an invented landmark.
-- Its staged slot is at (22, 20) on real MapSpec ground. The sacks sit on its +Z front apron
-- (z = 26) as a small renovation delivery, never loose on the R4 staging row at (146, 128).
local gudangSlot: ModelMapBuildingsR4.Slot? = nil
for _, candidate in ipairs(ModelMapBuildingsR4.families.buildings_r4.slots) do
	if candidate.slot == "gudang" then
		gudangSlot = candidate
		break
	end
end
local gudang = assert(gudangSlot, "props_r5 requires the buildings_r4 gudang slot")

local karungSource: Slot? = nil
for _, candidate in ipairs(r4Family.slots) do
	if candidate.slot == "karung" then
		karungSource = candidate
		break
	end
end
local karungBase = assert(karungSource, "props_r5 requires the props_r4 karung slot")

local karung: KarungGroup = {
	slot = "karung",
	context = "gudang",
	note = "front apron of the ModelMapBuildingsR4 gudang at (22,20); stacked renovation delivery",
	x = gudang.x,
	z = gudang.z + 6,
	ry = gudang.ry,
	rotX = 0,
	targetHeight = karungBase.targetHeight,
	scale = SCALES.karung,
	-- Small offsets keep the sacks in one tight stack; dy lifts the top sack onto the others.
	stack = {
		{ dx = -1.2, dy = 0, dz = 0, ry = 0 },
		{ dx = 1.2, dy = 0, dz = 0.1, ry = 0.35 },
		{ dx = 0, dy = 0, dz = 1.1, ry = 0.15 },
		{ dx = 0, dy = 1, dz = 0.5, ry = 0.2 },
	},
}

ModelMapPropsR5.families = {
	props_r5 = {
		id = "props_r5",
		title = "R5 village props — rescaled tools, unchanged jemuran, sacks stacked by the gudang",
		ids = ModelMapPropsR4.idsFor("props_r4") :: { [string]: number },
		slots = slots,
		karung = karung,
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "props_r5" }

function ModelMapPropsR5.idsFor(family: string): { [string]: number }?
	local entry = ModelMapPropsR5.families[family]
	return if entry then entry.ids else nil
end

function ModelMapPropsR5.slotsFor(family: string): { Slot }
	local entry = ModelMapPropsR5.families[family]
	return if entry then entry.slots else {}
end

function ModelMapPropsR5.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapPropsR5.count(): number
	local total = 0
	for _, familyId in ipairs(FAMILY_IDS) do
		for _ in pairs(ModelMapPropsR5.families[familyId].ids) do
			total += 1
		end
	end
	return total
end

-- Final stud height after the per-slot scale. The applier divides this by the loaded Y size.
function ModelMapPropsR5.effectiveHeight(entry: Slot): number
	return entry.targetHeight * entry.scale
end

return ModelMapPropsR5
