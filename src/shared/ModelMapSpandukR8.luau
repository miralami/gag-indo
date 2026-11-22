--!strict
-- ModelMapSpandukR8: pure data for the OFF-BY-DEFAULT "spanduk_r8" LookDev candidate
-- (WORK_QUEUE section M item 81). Warung and Pasar signs, one spanduk strung across the main south
-- road, and two bunting strings (one text panel each). All text comes from Shared.Strings KEYS;
-- no brand logos and no player-facing text literal lives here.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs, no world-coordinate
-- literals. Every anchor is derived from geometry passed in by the caller (MapSpec hubs / road arms),
-- never from a hand-typed world position. Offsets below are dimensionless stud offsets from that
-- geometry. Facing is supplied as an approach-camera NAME; the applier and the harness turn that into
-- a world facing normal with rotation/dot math.

local ModelMapSpandukR8 = {}

ModelMapSpandukR8.id = "spanduk_r8"
ModelMapSpandukR8.familyId = "spanduk_r8"
ModelMapSpandukR8.folderName = "LookDevSpandukR8_spanduk_r8"
ModelMapSpandukR8.stageAttribute = "SpandukR8"
ModelMapSpandukR8.kindAttribute = "SpandukKind"
ModelMapSpandukR8.keyAttribute = "SignKey"
ModelMapSpandukR8.cameraAttribute = "ApproachCamera"

-- Every Strings key this item stages. The harness SIGN_TEXT_PARITY check and the spec use this exact
-- list; each key must carry a non-empty id AND en in Shared.Strings.
ModelMapSpandukR8.SIGN_KEYS = {
	"spanduk_selamat_datang",
	"sign_warung",
	"spanduk_pasar",
	"bunting_mampir",
	"bunting_belanja",
}

-- Headroom: a 7.25-stud avatar must pass under the spanduk. Keep >= 9 studs of ground clearance.
ModelMapSpandukR8.MIN_HEADROOM = 9
ModelMapSpandukR8.BANNER_CLEARANCE = 9.5
ModelMapSpandukR8.BUNTING_FLAGS = 7
ModelMapSpandukR8.BUNTING_SAG = 1.2
ModelMapSpandukR8.EXPECTED_SIGNS = 4 -- warung, pasar, road spanduk, one bunting text panel
ModelMapSpandukR8.EXPECTED_BUNTING_STRINGS = 2

-- Dimensionless offsets from the passed-in MapSpec geometry, in studs.
local HUB_SIGN_APRON = 4 -- studs past the hub front eave
local HUB_SIGN_HEIGHT = 8 -- board centre above the ground plane
local HUB_SIGN_SPAN = 14 -- board width
local SPANDUK_POLE_OUTSET = 1.5 -- studs beyond the road arm half width
local SPANDUK_POLE_HEIGHT = 13
local SPANDUK_BOARD_HEIGHT = 4
local BUNTING_APRON = 8
local BUNTING_POLE_INSET = 0.6 -- fraction of the hub half width
local BUNTING_POLE_HEIGHT = 11
local BUNTING_PANEL_HEIGHT = 3.2
local BUNTING_PANEL_WIDTH = 8

-- Local part recipes. Colours are plain {r,g,b} arrays; sizes/offsets are {x,y,z} arrays. No IDs.
ModelMapSpandukR8.RECIPES = {
	sign = {
		{
			name = "PostL",
			shape = "Cylinder",
			size = { 0.5, 9, 0.5 },
			offset = { -5.4, 4.5, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "PostR",
			shape = "Cylinder",
			size = { 0.5, 9, 0.5 },
			offset = { 5.4, 4.5, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "Board",
			shape = "Block",
			size = { HUB_SIGN_SPAN, 3.2, 0.5 },
			offset = { 0, HUB_SIGN_HEIGHT, 0 },
			colour = { 206, 176, 118 },
			material = "WoodPlanks",
		},
	},
	spanduk = {
		{
			name = "PoleL",
			shape = "Cylinder",
			size = { 0.9, SPANDUK_POLE_HEIGHT, 0.9 },
			offset = { 0, SPANDUK_POLE_HEIGHT / 2, 0 },
			colour = { 150, 96, 48 },
			material = "Wood",
		},
		{
			name = "PoleR",
			shape = "Cylinder",
			size = { 0.9, SPANDUK_POLE_HEIGHT, 0.9 },
			offset = { 0, SPANDUK_POLE_HEIGHT / 2, 0 },
			colour = { 150, 96, 48 },
			material = "Wood",
		},
		{
			name = "Board",
			shape = "Block",
			size = { 1, SPANDUK_BOARD_HEIGHT, 0.4 },
			offset = { 0, ModelMapSpandukR8.BANNER_CLEARANCE + SPANDUK_BOARD_HEIGHT / 2, 0 },
			colour = { 178, 62, 48 },
			material = "Fabric",
		},
	},
	flag = {
		{
			name = "Flag",
			shape = "Block",
			size = { 1.4, 1.8, 0.15 },
			offset = { 0, 0, 0 },
			colour = { 224, 168, 62 },
			material = "Fabric",
		},
	},
	bunting = {
		{
			name = "PoleL",
			shape = "Cylinder",
			size = { 0.5, BUNTING_POLE_HEIGHT, 0.5 },
			offset = { 0, BUNTING_POLE_HEIGHT / 2, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "PoleR",
			shape = "Cylinder",
			size = { 0.5, BUNTING_POLE_HEIGHT, 0.5 },
			offset = { 0, BUNTING_POLE_HEIGHT / 2, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "Cord",
			shape = "Block",
			size = { 1, 0.1, 0.1 },
			offset = { 0, 0, 0 },
			colour = { 92, 74, 54 },
			material = "SmoothPlastic",
		},
		{
			name = "Board",
			shape = "Block",
			size = { BUNTING_PANEL_WIDTH, BUNTING_PANEL_HEIGHT, 0.3 },
			offset = { 0, 0, 0 },
			colour = { 206, 176, 118 },
			material = "Fabric",
		},
	},
}

-- Hub-local point to world XZ. Mirrors MapSpec.rotatePoint with the hub's own yaw; pure math only.
local function hubPoint(hub, lx: number, lz: number): (number, number)
	local a = math.rad(hub.yaw or 0)
	local c, s = math.cos(a), math.sin(a)
	return hub.x + lx * c + lz * s, hub.z - lx * s + lz * c
end

-- A freestanding sign on a hub's front apron, aimed at that hub's approach camera.
function ModelMapSpandukR8.hubSign(hub, key: string, camera: string)
	if type(hub) ~= "table" or type(hub.x) ~= "number" or type(hub.z) ~= "number" then
		return nil
	end
	local x, z = hubPoint(hub, 0, hub.depth / 2 + HUB_SIGN_APRON)
	return { key = key, camera = camera, x = x, z = z, kind = "sign" }
end

-- A spanduk strung across the full width of a straight road arm. The banner board is raised to
-- BANNER_CLEARANCE so the underside clears a 7.25-stud avatar by well over the required margin.
function ModelMapSpandukR8.roadSpanduk(arm, key: string, camera: string)
	if type(arm) ~= "table" or type(arm.x) ~= "number" or type(arm.z) ~= "number" or type(arm.sx) ~= "number" then
		return nil
	end
	return {
		key = key,
		camera = camera,
		x = arm.x,
		z = arm.z,
		halfSpan = arm.sx / 2 + SPANDUK_POLE_OUTSET,
		poleHeight = SPANDUK_POLE_HEIGHT,
		clearance = ModelMapSpandukR8.BANNER_CLEARANCE,
		kind = "spanduk",
	}
end

-- A bunting string between two poles on a hub's front apron. One middle flag carries Strings text
-- and faces `camera`; the rest are decorative triangles. `side` picks the apron flank.
function ModelMapSpandukR8.bunting(hub, key: string, camera: string, side: number)
	if type(hub) ~= "table" or type(hub.x) ~= "number" or type(hub.z) ~= "number" then
		return nil
	end
	local inset = hub.width * BUNTING_POLE_INSET * side
	local lz = hub.depth / 2 + BUNTING_APRON
	local lx, leftZ = hubPoint(hub, -inset, lz)
	local rx, rightZ = hubPoint(hub, inset, lz)
	return {
		key = key,
		camera = camera,
		left = { x = lx, z = leftZ },
		right = { x = rx, z = rightZ },
		count = ModelMapSpandukR8.BUNTING_FLAGS,
		poleHeight = BUNTING_POLE_HEIGHT,
		textIndex = math.floor(ModelMapSpandukR8.BUNTING_FLAGS / 2) + 1,
		kind = "bunting",
	}
end

-- Point along a bunting cord, including a parabolic sag. t in [0,1].
function ModelMapSpandukR8.buntingPoint(recipe, t: number)
	if type(recipe) ~= "table" or type(recipe.left) ~= "table" or type(recipe.right) ~= "table" then
		return nil
	end
	local clamped = math.max(0, math.min(1, t))
	local sag = ModelMapSpandukR8.BUNTING_SAG
	return {
		x = recipe.left.x + (recipe.right.x - recipe.left.x) * clamped,
		z = recipe.left.z + (recipe.right.z - recipe.left.z) * clamped,
		drop = 4 * sag * clamped * (1 - clamped),
	}
end

-- Per-kind counts from the staged recipes, for specs and the harness detail.
function ModelMapSpandukR8.counts(groups: any): { [string]: number }
	local out = { sign = 0, spanduk = 0, bunting = 0, flags = 0, textPanels = 0 }
	if type(groups) ~= "table" then
		return out
	end
	out.sign = #(groups.signs or {})
	out.spanduk = #(groups.spanduks or {})
	out.bunting = #(groups.bunting or {})
	out.flags = #(groups.flags or {})
	out.textPanels = #(groups.textPanels or {})
	return out
end

return ModelMapSpandukR8
