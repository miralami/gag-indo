--!strict
-- Pure data for WORK_QUEUE item 210: DEFAULT-look Warung front dressing.
-- No engine calls, no instances, no asset IDs, no new colours. The two existing MapSpec benches
-- are tagged as seats by Greybox; this recipe adds two low stools, a serving table, a stove and a
-- hanging lantern. Every local coordinate is derived from the warung hub's anchor and benches and
-- sits in front of the table (local z > anchor.lz) and outside all six 6-stud door lanes.

local Data = {}

Data.TAG = "WarungDress"
Data.KIND_ATTR = "WarungDressKind"
Data.MIN_SEATS = 4

-- Existing Props palette names only; Greybox resolves each through Props.palette().
Data.PALETTE_NAMES = { "bambu", "genteng", "kunyit", "merah", "tintaLembut" }

-- Pure: given the warung hub table, return the NEW dressing parts deterministically.
function Data.parts(hub: { [string]: any })
	local benches = hub.benches
	local outerX = math.abs(benches[1]) + 5.1 -- stools sit outboard of the existing benches
	local anchorZ = hub.anchor.lz
	return {
		{
			name = "WarungStoolL",
			kind = "seat",
			lx = -outerX,
			lz = anchorZ + 4.5,
			shape = "Cylinder",
			sx = 2.4,
			sy = 1.2,
			sz = 2.4,
			y = 0.6,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungStoolR",
			kind = "seat",
			lx = outerX,
			lz = anchorZ + 4.5,
			shape = "Cylinder",
			sx = 2.4,
			sy = 1.2,
			sz = 2.4,
			y = 0.6,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungServerTop",
			kind = "table",
			lx = 0,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 6,
			sy = 0.4,
			sz = 2.4,
			y = 2.2,
			colour = "bambu",
			material = "WoodPlanks",
		},
		{
			name = "WarungServerLegL",
			kind = "table",
			lx = -2.4,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 0.4,
			sy = 2.2,
			sz = 2,
			y = 1.1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungServerLegR",
			kind = "table",
			lx = 2.4,
			lz = anchorZ + 6.5,
			shape = "Block",
			sx = 0.4,
			sy = 2.2,
			sz = 2,
			y = 1.1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungStove",
			kind = "stove",
			lx = -16,
			lz = anchorZ + 7.5,
			shape = "Cylinder",
			sx = 3,
			sy = 2.4,
			sz = 3,
			y = 1.2,
			colour = "genteng",
			material = "Metal",
		},
		{
			name = "WarungStoveChimney",
			kind = "stove",
			lx = -16,
			lz = anchorZ + 7.5,
			shape = "Cylinder",
			sx = 0.7,
			sy = 2.2,
			sz = 0.7,
			y = 3.4,
			colour = "tintaLembut",
			material = "Metal",
		},
		{
			name = "WarungLanternPost",
			kind = "lantern",
			lx = 12,
			lz = anchorZ + 9,
			shape = "Block",
			sx = 0.4,
			sy = 7,
			sz = 0.4,
			y = 3.5,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungLanternArm",
			kind = "lantern",
			lx = 10.5,
			lz = anchorZ + 9,
			shape = "Block",
			sx = 3,
			sy = 0.3,
			sz = 0.3,
			y = 6.8,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "WarungLanternBody",
			kind = "lantern",
			lx = 9,
			lz = anchorZ + 9,
			shape = "Cylinder",
			sx = 1.6,
			sy = 1.6,
			sz = 1.6,
			y = 5.7,
			colour = "kunyit",
			material = "Metal",
		},
		{
			name = "WarungLanternCap",
			kind = "lantern",
			lx = 9,
			lz = anchorZ + 9,
			shape = "Cylinder",
			sx = 1.9,
			sy = 0.2,
			sz = 1.9,
			y = 6.6,
			colour = "merah",
			material = "Metal",
		},
	}
end

return Data
