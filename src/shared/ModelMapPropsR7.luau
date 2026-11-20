--!strict
-- ModelMapPropsR7: pure data for the OFF-BY-DEFAULT "props_r7" LookDev candidate
-- (WORK_QUEUE item 57). No IDs are constructed here: ids/sizes/orientation are derived by require
-- from ModelMapPropsR6, which in turn reuses ModelMapPropsR4's real Creator Store uploads.
-- No game APIs, no instances: Lune specs can require this module directly.
--
-- The yard centre is chosen at apply time by LookDevModelsPropsR7 (scan of tree/pine trunks in
-- workspace). This module only holds the layout rules: six props, one row, 6 studs apart, and a
-- camera 28 studs in front of that row (+Z), 7 up, looking at the row centre at y=2.

local ModelMapPropsR4 = require(script.Parent.ModelMapPropsR4)
local ModelMapPropsR6 = require(script.Parent.ModelMapPropsR6)

export type Slot = {
	slot: string,
	targetHeight: number, -- R4 base height
	scale: number, -- R6 multiplier over targetHeight
	height: number, -- final stud height (R6 effectiveHeight)
	ry: number,
	rotX: number,
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

local ModelMapPropsR7 = {}

ModelMapPropsR7.familyId = "props_r7"
ModelMapPropsR7.groundY = ModelMapPropsR4.groundY
ModelMapPropsR7.folderName = "LookDevModelsPropsR7_props_r7"
ModelMapPropsR7.tagAttribute = "LookDevR7"
ModelMapPropsR7.slotAttribute = "PropSlot"
ModelMapPropsR7.cameraPosAttribute = "ReviewCameraPos"
ModelMapPropsR7.cameraLookAttribute = "ReviewLookAt"

-- Six slots, exact WORK_QUEUE order. gerobak first; karung is deliberately absent.
ModelMapPropsR7.slotOrder = { "gerobak", "sumur", "lapak", "pagar_bambu", "alat_tani", "jemuran" }
ModelMapPropsR7.spacing = 6
ModelMapPropsR7.yardSize = 40
ModelMapPropsR7.trunkClearance = 15
ModelMapPropsR7.padMargin = 2 -- footprint + 2 studs before the Terrain:FillBlock

-- Camera = row centre + (0, up, front); look target = row centre with y = lookY.
-- front=28 (was 18): the 70-degree cone half-angle is 35 degrees. At front=18 the two row ends
-- (x=+/-15) measured 38.7-39.5 degrees off-axis, so gerobak and jemuran failed PROPS_VISIBLE.
-- At front=28 the worst end is ~28 degrees, leaving ~7 degrees of margin while the eye stays
-- inside the 40x40 yard's 15-stud trunk-clearance ring (28 < 20+15).
ModelMapPropsR7.cameraRule = { front = 28, up = 7, lookY = 2 }

-- ID provenance: ModelMapPropsR6.idsFor("props_r6") is ModelMapPropsR4.idsFor("props_r4")
-- via require, so gerobak/sumur/lapak/pagar_bambu/alat_tani/jemuran are the same six real IDs.
local r6Family = ModelMapPropsR6.families[ModelMapPropsR6.familyId]
local sourceIds = ModelMapPropsR6.idsFor(ModelMapPropsR6.familyId) or {}
local r6SlotsByName: { [string]: any } = {}
for _, r6 in ipairs(r6Family.slots) do
	r6SlotsByName[r6.slot] = r6
end

local ids: { [string]: number } = {}
local slots: { Slot } = {}
for index, slotName in ipairs(ModelMapPropsR7.slotOrder) do
	ids[slotName] = sourceIds[slotName]
	local r6 = r6SlotsByName[slotName]
	if r6 then
		slots[index] = {
			slot = slotName,
			targetHeight = r6.targetHeight,
			scale = r6.scale,
			height = ModelMapPropsR6.effectiveHeight(r6),
			ry = r6.ry,
			rotX = r6.rotX,
		}
	end
end

ModelMapPropsR7.families = {
	props_r7 = {
		id = "props_r7",
		title = "R7 village props — one visible row in an open yard, real R6 sizes, Ground pads",
		ids = ids,
		slots = slots,
	},
} :: { [string]: Family }

local FAMILY_IDS: { string } = { "props_r7" }

function ModelMapPropsR7.idsFor(family: string): { [string]: number }?
	local entry = ModelMapPropsR7.families[family]
	return if entry then entry.ids else nil
end

function ModelMapPropsR7.slotsFor(family: string): { Slot }
	local entry = ModelMapPropsR7.families[family]
	return if entry then entry.slots else {}
end

function ModelMapPropsR7.familyIds(): { string }
	return table.clone(FAMILY_IDS)
end

function ModelMapPropsR7.count(): number
	return #ModelMapPropsR7.slotOrder
end

-- X offset from the row centre for 1-based slot index (six slots -> -15,-9,-3,3,9,15).
function ModelMapPropsR7.rowOffset(index: number): number
	return (index - (#ModelMapPropsR7.slotOrder + 1) / 2) * ModelMapPropsR7.spacing
end

-- Pure camera rule, evaluated against the yard centre the applier picked in Studio.
function ModelMapPropsR7.cameraFor(centreX: number, centreZ: number): Camera
	local rule = ModelMapPropsR7.cameraRule
	return {
		position = { x = centreX, y = rule.up, z = centreZ + rule.front },
		target = { x = centreX, y = rule.lookY, z = centreZ },
	} :: Camera
end

return ModelMapPropsR7
