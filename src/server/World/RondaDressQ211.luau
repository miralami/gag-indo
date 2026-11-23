--!strict
-- Pure data for WORK_QUEUE item 211: DEFAULT-look Pos Ronda dressing.
-- No engine calls, no instances, no asset IDs, no new colours. Every local coordinate is derived
-- from the Ronda hub's 40x36 Floor anchor. The props sit on that floor, inside the six 6-stud hub
-- door lanes' exclusion zone, and are staged by buildPosRonda() as non-collidable, non-interactive
-- decorative Parts. The staged ronda_tower_r9 candidate and its height guard are untouched.

local Data = {}

Data.TAG = "RondaDress"
Data.KIND_ATTR = "RondaDressKind"
Data.MIN_PROPS = 4
Data.KINDS = { "kentongan", "bench", "lamp", "rack" }

-- Existing Props.palette names only; Greybox resolves each through Props.palette().
Data.PALETTE_NAMES = { "bambu", "genteng", "kunyit", "tintaLembut", "kertas" }

-- Pure: given the Ronda hub, return the NEW dressing parts deterministically.
function Data.parts(hub: { [string]: any }): { { [string]: any } }
	local halfX = hub.anchor.sx / 2
	local halfZ = hub.anchor.sz / 2
	local cell = hub.anchor.sz / 3 -- the builder's 12-stud guard cell
	local floorTop = hub.anchor.sy / 2 + 1.1 -- plinth top + the Floor's raised centre

	local drumX = -cell / 4
	local drumZ = 0
	local drumLength = cell * 0.3
	local benchX = cell / 2 + 5
	local benchZ = cell / 2 + 2
	local lampX = -halfX + 6
	local lampZ = cell / 2 + 4
	local rackX = halfX - 8
	local rackZ = -halfZ + 7

	return {
		-- Kentongan: a hollow log drum laid on two little blocks, with a dark slit on top.
		{
			name = "RondaKentonganLog",
			kind = "kentongan",
			lx = drumX,
			lz = drumZ,
			shape = "Cylinder",
			pitch = 90,
			sx = 1.8,
			sy = drumLength,
			sz = 1.8,
			y = floorTop + 1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaKentonganRestL",
			kind = "kentongan",
			lx = drumX,
			lz = drumZ - drumLength / 3,
			shape = "Block",
			sx = 2,
			sy = 0.5,
			sz = 0.5,
			y = floorTop + 0.25,
			colour = "tintaLembut",
			material = "Wood",
		},
		{
			name = "RondaKentonganRestR",
			kind = "kentongan",
			lx = drumX,
			lz = drumZ + drumLength / 3,
			shape = "Block",
			sx = 2,
			sy = 0.5,
			sz = 0.5,
			y = floorTop + 0.25,
			colour = "tintaLembut",
			material = "Wood",
		},
		{
			name = "RondaKentonganSlit",
			kind = "kentongan",
			lx = drumX,
			lz = drumZ,
			shape = "Block",
			sx = 0.2,
			sy = 0.12,
			sz = drumLength * 0.7,
			y = floorTop + 1.9,
			colour = "tintaLembut",
			material = "Wood",
		},
		-- Bench: a plank on two legs, outboard of the cell's east wall.
		{
			name = "RondaBenchSeat",
			kind = "bench",
			lx = benchX,
			lz = benchZ,
			shape = "Block",
			sx = 7,
			sy = 0.5,
			sz = 2.6,
			y = floorTop + 2.4,
			colour = "genteng",
			material = "WoodPlanks",
		},
		{
			name = "RondaBenchLegL",
			kind = "bench",
			lx = benchX - 2.6,
			lz = benchZ,
			shape = "Block",
			sx = 0.5,
			sy = 2.2,
			sz = 2,
			y = floorTop + 1.1,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaBenchLegR",
			kind = "bench",
			lx = benchX + 2.6,
			lz = benchZ,
			shape = "Block",
			sx = 0.5,
			sy = 2.2,
			sz = 2,
			y = floorTop + 1.1,
			colour = "bambu",
			material = "Wood",
		},
		-- Gardu lamp: a bamboo post with an arm, lantern and cap.
		{
			name = "RondaGarduPost",
			kind = "lamp",
			lx = lampX,
			lz = lampZ,
			shape = "Block",
			sx = 0.5,
			sy = 7,
			sz = 0.5,
			y = floorTop + 3.5,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaGarduArm",
			kind = "lamp",
			lx = lampX + 1.2,
			lz = lampZ,
			shape = "Block",
			sx = 2.6,
			sy = 0.3,
			sz = 0.3,
			y = floorTop + 6.8,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaGarduLantern",
			kind = "lamp",
			lx = lampX + 2.4,
			lz = lampZ,
			shape = "Cylinder",
			sx = 1.5,
			sy = 1.5,
			sz = 1.5,
			y = floorTop + 6,
			colour = "kunyit",
			material = "Metal",
		},
		{
			name = "RondaGarduCap",
			kind = "lamp",
			lx = lampX + 2.4,
			lz = lampZ,
			shape = "Cylinder",
			sx = 1.8,
			sy = 0.25,
			sz = 1.8,
			y = floorTop + 6.9,
			colour = "kertas",
			material = "Metal",
		},
		-- Small rack: two posts and two shelves.
		{
			name = "RondaRackPostL",
			kind = "rack",
			lx = rackX - 2.9,
			lz = rackZ,
			shape = "Block",
			sx = 0.4,
			sy = 5,
			sz = 1.8,
			y = floorTop + 2.5,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaRackPostR",
			kind = "rack",
			lx = rackX + 2.9,
			lz = rackZ,
			shape = "Block",
			sx = 0.4,
			sy = 5,
			sz = 1.8,
			y = floorTop + 2.5,
			colour = "bambu",
			material = "Wood",
		},
		{
			name = "RondaRackShelfLow",
			kind = "rack",
			lx = rackX,
			lz = rackZ,
			shape = "Block",
			sx = 6.4,
			sy = 0.35,
			sz = 2.2,
			y = floorTop + 1.8,
			colour = "bambu",
			material = "WoodPlanks",
		},
		{
			name = "RondaRackShelfHigh",
			kind = "rack",
			lx = rackX,
			lz = rackZ,
			shape = "Block",
			sx = 6.4,
			sy = 0.35,
			sz = 2.2,
			y = floorTop + 4.3,
			colour = "bambu",
			material = "WoodPlanks",
		},
	}
end

return Data
