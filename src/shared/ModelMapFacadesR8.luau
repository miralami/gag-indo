--!strict
-- ModelMapFacadesR8: pure data for the OFF-BY-DEFAULT "facades_r8" LookDev candidate
-- (WORK_QUEUE section M item 78). Procedural facade details for the six existing Greybox hub
-- Models: shuttered windows, a porch roof, a ridge cap, a lantern bracket, a doorstep and an eave.
--
-- PURE DATA ONLY: no game APIs, no Instances, no Enum values and no asset IDs at load time. Every
-- coordinate is LOCAL to its hub; the server applier converts it with MapSpec.hubPoint(hub, lx, lz)
-- and turns with hub.yaw, so this module never contains a world position. Colours are plain
-- {r,g,b} arrays and materials are built-in material names consumed at apply time.
--
-- Each hub owns an explicit avatar-fit door gauge in its open local +Z front. The gauge is staged as
-- a transparent, non-collidable Part so a Studio harness can probe the exact opening. Gauge sizes
-- follow the map reference: 7 x 10.5 x 2 for pakrt, 6 x 9 x 2 for the other five. All six hubs are
-- open on local +Z in Greybox; pakrt has a real door in Block A, gelap has a lantern-door frame, and
-- ronda's cell is open on +Z. Pasar, warung and polisi have no literal door leaf, so their gauge is
-- placed in the open front as the avatar-fit opening the player actually walks through.

local ModelMapFacadesR8 = {}

ModelMapFacadesR8.id = "facades_r8"
ModelMapFacadesR8.folderName = "LookDevFacadesR8_facades_r8"
ModelMapFacadesR8.gaugeName = "FacadeDoorGauge"
ModelMapFacadesR8.minPartsPerHub = 10

ModelMapFacadesR8.KINDS = {
	"shuttered_window",
	"porch_roof",
	"ridge_cap",
	"lantern_bracket",
	"doorstep",
	"eave",
}

-- Local hub frame numbers copied from MapSpec.HUBS so this shared module stays pure. The applier
-- still reads the live MapSpec.hub(key) for yaw, x and z; these are footprint/ridge sizes only.
local EAVE_OFFSET = 9.5 -- MapSpec.EAVE_UNDERSIDE - MapSpec.GROUND_Y
local SIDE_SIGNS = { -1, 1 }
local SIDE_TAGS = { "L", "R" }

-- Every recipe is relative to the gauge centre (gx, gz) or to the hub footprint (halfD). `y` is an
-- offset above MapSpec.GROUND_Y. `pitch` is an optional local-X tilt in degrees for the porch roof.
local function recipes(gx: number, gz: number, halfD: number, ridge: number, gauge: any, ridgeAlongZ: boolean?): { any }
	local top = gauge.base + gauge.h -- gauge head, above ground
	local shutterX = gauge.w / 2 + 6
	local porchX = gauge.w / 2 + 7
	local bracketX = gauge.w / 2 + 5
	local eaveX = 12 -- item 139: the old 13/13.5 pushed pakrt's left eave outside hub bbox + 3
	local out = {} :: { any }

	local function add(
		name: string,
		kind: string,
		lx: number,
		lz: number,
		y: number,
		size: { number },
		color: { number },
		material: string,
		pitch: number?
	)
		out[#out + 1] = {
			name = name,
			kind = kind,
			lx = lx,
			lz = lz,
			y = y,
			size = size,
			color = color,
			material = material,
			pitch = pitch or 0,
		}
	end

	for index, sign in ipairs(SIDE_SIGNS) do
		local tag = SIDE_TAGS[index]
		add(
			"FacadeShutteredWindow_" .. tag,
			"shuttered_window",
			gx + sign * shutterX,
			gz - 3,
			EAVE_OFFSET - 4,
			{ 3, 5, 0.4 },
			{ 158, 108, 68 },
			"WoodPlanks"
		)
		add(
			"FacadePorchRoof_" .. tag,
			"porch_roof",
			gx + sign * porchX,
			gz - 1,
			top + 3,
			{ 8, 0.4, 8 },
			{ 112, 78, 58 },
			"Slate",
			8 * sign
		)
		add(
			"FacadeLanternBracket_" .. tag,
			"lantern_bracket",
			gx + sign * bracketX,
			gz - 2,
			EAVE_OFFSET - 1.5,
			{ 0.8, 4, 0.8 },
			{ 96, 88, 76 },
			"Metal"
		)
		add(
			"FacadeEave_" .. tag,
			"eave",
			gx + sign * eaveX,
			halfD + 2,
			EAVE_OFFSET + 0.6,
			{ 6, 0.5, 1.2 },
			{ 92, 64, 48 },
			"Wood"
		)
	end
	-- item 139: width * 0.8 was 25.6..51.2 studs on the six hubs — a floating diagonal pole. A 10-stud
	-- cap fits every hub; pakrt's gable ridge runs along local Z, so its cap is turned to match.
	local capSize = if ridgeAlongZ then { 1.2, 0.6, 10 } else { 10, 0.6, 1.2 }
	add("FacadeRidgeCap", "ridge_cap", 0, 0, ridge + 0.6, capSize, { 176, 142, 72 }, "Metal")
	add(
		"FacadeDoorstep",
		"doorstep",
		gx,
		gz + gauge.d / 2 + 1.5,
		0.15,
		{ gauge.w + 2, 0.3, 2 },
		{ 136, 130, 118 },
		"Slate"
	)
	return out
end

local function hub(model: string, width: number, depth: number, ridge: number, gauge: any, ridgeAlongZ: boolean?): any
	return {
		model = model,
		width = width,
		depth = depth,
		ridge = ridge,
		gauge = gauge,
		parts = recipes(gauge.lx, gauge.lz, depth / 2, ridge, gauge, ridgeAlongZ),
	}
end

-- `base` is the gauge bottom above MapSpec.GROUND_Y. The 0.85 default clears the 0.8-tall plinth;
-- ronda uses 1.75 because its Floor part rises 0.9 above the plinth. Pakrt's 7-stud opening sits
-- in Block A's front-wall gap, forward of the wall plane and under the high end of its awning.
ModelMapFacadesR8.hubs = {
	pasar = hub("Pasar", 64, 52, 26, { w = 6, h = 9, d = 2, lx = 0, lz = 27, base = 0.85 }),
	gelap = hub("TengkulakGelap", 32, 28, 18, { w = 6, h = 9, d = 2, lx = 0, lz = 15, base = 0.85 }),
	warung = hub("Warung", 52, 44, 24, { w = 6, h = 9, d = 2, lx = 0, lz = 23, base = 0.85 }),
	ronda = hub("PosRonda", 44, 40, 16, { w = 6, h = 9, d = 2, lx = 0, lz = 17, base = 1.75 }),
	polisi = hub("PosPolisi", 48, 44, 24, { w = 6, h = 9, d = 2, lx = 0, lz = 23, base = 0.85 }),
	pakrt = hub("RumahPakRT", 48, 34, 32.6, { w = 7, h = 10.5, d = 2, lx = -13, lz = 10.5, base = 0.85 }, true),
}

ModelMapFacadesR8.HUB_KEYS = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }

return ModelMapFacadesR8
