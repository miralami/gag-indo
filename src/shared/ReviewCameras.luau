--!strict
-- ReviewCameras: named Studio review cameras for WORK_QUEUE section M item 69.
--
-- Every world coordinate is derived from MapSpec (or the two shared data modules it delegates to:
-- Config.Game for the plot ring and ModelMapVegetationR7 for the current saved spawn camera).
-- No literal world position is written here. The only literals are the review offsets fixed by the
-- queue item (a hub camera 28 studs out and 9 studs up), dimensionless fractions (diagonal halves,
-- lane midpoints) and sign choices that put a 3/4 view outside a neighbouring building.
--
-- PURE DATA: no Instance creation, no Enum lookups at load. MapSpec lives under
-- ServerScriptService.Server.World, so require this registry from the Server datamodel (or the
-- Lune Env harness). The `datamodel` field tells the main session which VM to shoot each view in.

local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)
local Game = require(script.Parent.Config.Game)
local VegR7 = require(script.Parent.ModelMapVegetationR7)

export type Vec3 = { number }
export type ReviewCamera = {
	name: string,
	position: Vec3,
	lookAt: Vec3,
	datamodel: "Client" | "Server",
	purpose: string,
}

local ReviewCameras = {}

-- The r8 CAMERA_CLEAR check casts this far toward lookAt; one terrain voxel plus one scale unit.
ReviewCameras.clearDistance = MapSpec.TERRAIN_VOXEL + MapSpec.S

local HUB_STANDOFF = 28 -- queue item 69: 3/4 view, 28 studs out
local HUB_RISE = 9 -- queue item 69: 9 studs above the ground plane
local DIAGONAL = 1 / math.sqrt(2)

local function vec(x: number, y: number, z: number): Vec3
	return { x, y, z }
end

-- 3/4 view from just outside the front corner: `side` picks the free side of the building so the
-- eye never starts inside a neighbouring hub (Gelap vs Pasar, Ronda vs Pasar/Polisi).
local function hubCamera(hub, side: number): (Vec3, Vec3)
	local outX = (hub.width / 2 + HUB_STANDOFF * DIAGONAL) * side
	local outZ = hub.depth / 2 + HUB_STANDOFF * DIAGONAL
	local x, z = MapSpec.hubPoint(hub, outX, outZ)
	return vec(x, MapSpec.GROUND_Y + HUB_RISE, z), vec(hub.x, MapSpec.GROUND_Y + hub.ridge / 2, hub.z)
end

-- Item 153: 3/4 view of a hub's dressed front apron. `apronLz` is a hub-local distance past the
-- front wall (the item-148 stalls stand 16 studs out from the Pasar footprint); the eye stands off
-- from that apron on the same diagonal as hubCamera, but higher so the first 6-stud ray stays clear.
local function hubApronCamera(
	hub,
	side: number,
	apronLz: number,
	standoff: number,
	rise: number,
	lookRise: number
): (Vec3, Vec3)
	local eyeLx = (hub.width / 2 + standoff * DIAGONAL) * side
	local eyeLz = apronLz + standoff * DIAGONAL
	local ex, ez = MapSpec.hubPoint(hub, eyeLx, eyeLz)
	local lx, lz = MapSpec.hubPoint(hub, 0, apronLz)
	return vec(ex, MapSpec.GROUND_Y + rise, ez), vec(lx, MapSpec.GROUND_Y + lookRise, lz)
end

-- MAP_SPEC §4 puts plot gates on the inner side of the plot ring, just outside the connector road.
-- Config.Game owns the ring radius/angles; MapSpec owns the road that fixes the gate radius.
local function plotGate(index: number): (Vec3, Vec3)
	local px, pz = Game.plotCenter(index)
	local plotRadius = math.sqrt(px * px + pz * pz)
	local ux, uz = px / plotRadius, pz / plotRadius
	local gateRadius = MapSpec.ROAD.ringCentre + MapSpec.ROAD.ringWidth / 2 + MapSpec.S
	local gx, gz = ux * gateRadius, uz * gateRadius
	local standOff = MapSpec.ROAD.halfWidth
	local gateY = MapSpec.GROUND_Y + MapSpec.HEADROOM
	return vec(gx - ux * standOff, gateY + MapSpec.S, gz - uz * standOff), vec(gx, gateY, gz)
end

-- WORK_QUEUE item 143: 30 studs up, 40 studs back along the connector-road radial. Same
-- Config.Game + MapSpec.ROAD radial frame as plotGate; only the fixed queue offsets differ.
local PLOT_AERIAL_RISE = 30
local PLOT_AERIAL_BACK = 40

local function plotAerial(index: number): (Vec3, Vec3)
	local px, pz = Game.plotCenter(index)
	local plotRadius = math.sqrt(px * px + pz * pz)
	local ux, uz = px / plotRadius, pz / plotRadius
	return vec(px - ux * PLOT_AERIAL_BACK, MapSpec.GROUND_Y + PLOT_AERIAL_RISE, pz - uz * PLOT_AERIAL_BACK),
		vec(px, MapSpec.GROUND_Y, pz)
end

local cameras: { ReviewCamera } = {}

local function add(name: string, position: Vec3, lookAt: Vec3, datamodel: "Client" | "Server", purpose: string)
	table.insert(cameras, {
		name = name,
		position = position,
		lookAt = lookAt,
		datamodel = datamodel,
		purpose = purpose,
	})
end

-- Spawn: reuse the exact saved camera from the vegetation R7 map / r7 check harness.
local savedEye = VegR7.savedCamera.eye
local savedLook = VegR7.savedCamera.look
local spawnEye = vec(savedEye[1], savedEye[2], savedEye[3])
local spawnLook = vec(savedLook[1], savedLook[2], savedLook[3])
add("spawn", spawnEye, spawnLook, "Server", "Current saved spawn camera: near vegetation, ground and sky.")

-- Hubs: hub centre, yaw and footprint come straight from MapSpec.HUBS.
local hubSides: { [string]: number } = { pasar = 1, gelap = -1, warung = 1, ronda = -1, polisi = 1, pakrt = 1 }
for _, key in MapSpec.HUB_ORDER do
	local hub = MapSpec.hub(key)
	assert(hub, `ReviewCameras: MapSpec.HUB_ORDER names missing hub {key}`)
	local eye, look = hubCamera(hub, hubSides[key])
	add(`hub_{key}`, eye, look, "Server", `3/4 view of {hub.model} from outside its front corner.`)
end

-- Plot gates: one per configured plot, from Config.Game.plotCenter and MapSpec.ROAD.
for index = 1, Game.plotCount do
	local eye, look = plotGate(index)
	add(
		`plot_gate_{string.format("%02d", index)}`,
		eye,
		look,
		"Server",
		`Gate of plot P{index} from the connector-road side.`
	)
end

-- Plot aerials: one per configured plot, for the item-143 PLOT_FENCE_VISIBLE raycast check.
for index = 1, Game.plotCount do
	local eye, look = plotAerial(index)
	add(
		`plot_aerial_{string.format("%02d", index)}`,
		eye,
		look,
		"Server",
		`Fence and gate of plot P{index} from 30 studs up and 40 studs back along the connector road.`
	)
end

-- River bridge: both approaches, from MapSpec.BRIDGE and MapSpec.GROUND_Y.
local bridge = MapSpec.BRIDGE
local bridgeZ = (bridge.z0 + bridge.z1) / 2
local deckY = MapSpec.GROUND_Y + bridge.top
local bridgeEyeY = deckY + MapSpec.HEADROOM
local bridgeLook = vec(bridge.x, deckY + bridge.railTop, bridgeZ)
local bridgeStandOff = bridge.rampLength * MapSpec.S
local bridgeLateral = bridge.width * MapSpec.S
add(
	"bridge_north_bank",
	vec(bridge.x + bridgeLateral, bridgeEyeY, bridge.z0 - bridgeStandOff),
	bridgeLook,
	"Server",
	"Bridge deck and railing from the north approach."
)
add(
	"bridge_south_bank",
	vec(bridge.x - bridgeLateral, bridgeEyeY, bridge.z1 + bridgeStandOff),
	bridgeLook,
	"Server",
	"Bridge deck and railing from the south approach."
)

-- Sawah terraces: the first and last terrace bound the below/above framing.
local terraces = MapSpec.TERRACES
local lowTerrace = terraces[1]
local highTerrace = terraces[#terraces]
local midTerrace = terraces[math.ceil(#terraces / 2)]
local lane = MapSpec.TERRACE_SIDES[2]
local laneX = (lane.x0 + lane.x1) / 2
local lowZ = (lowTerrace.z0 + lowTerrace.z1) / 2
local midZ = (midTerrace.z0 + midTerrace.z1) / 2
add(
	"sawah_below",
	vec(laneX, MapSpec.GROUND_Y + MapSpec.S, lowTerrace.z1 + MapSpec.RAMP_WIDTH / 2),
	vec(laneX, lowTerrace.top + MapSpec.S, lowZ),
	"Server",
	"Low view up the terrace bunds and paddy water."
)
add(
	"sawah_above",
	vec(-laneX, highTerrace.top + MapSpec.HEADROOM * MapSpec.S, highTerrace.z0 - MapSpec.RAMP_WIDTH / 2),
	vec(-laneX, midTerrace.top, midZ),
	"Server",
	"High view down the full sawah band."
)

-- Hill ring: from outside the playable square, looking back at the plaza.
local hillZ = -(MapSpec.TERRAIN_HALF + MapSpec.TERRACE_STEP * MapSpec.S)
-- Above the documented 40..80-stud hill band; a lower eye would start inside opaque terrain.
local hillEyeY = MapSpec.GROUND_Y + MapSpec.TERRAIN_HALF / (MapSpec.S * MapSpec.S)
add(
	"hill_ring_in",
	vec(MapSpec.PLAZA.x, hillEyeY, hillZ),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM, MapSpec.PLAZA.z),
	"Server",
	"Hill/forest backdrop looking in across the village."
)

-- Item 153 dressing cameras. Every offset below is a MapSpec-derived length or a dimensionless
-- fraction; each eye stands off and rises enough that the 6-stud CAMERA_CLEAR ray starts in air.
local pasarHub = MapSpec.hub("pasar")
assert(pasarHub, "ReviewCameras: MapSpec has no pasar hub")
local stallApronLz = pasarHub.depth / 2 + MapSpec.S * 8
local pasarApronEye, pasarApronLook =
	hubApronCamera(pasarHub, hubSides.pasar, stallApronLz, HUB_STANDOFF, HUB_RISE + MapSpec.S * 2, MapSpec.S)
add(
	"pasar_awnings",
	pasarApronEye,
	pasarApronLook,
	"Server",
	"Item-148 lapak stalls and striped awnings on the Pasar front apron, from the front-right 3/4."
)

-- Plaza centre: above the fountain, looking down across the dressed Lapangan.
add(
	"plaza_centre",
	vec(MapSpec.PLAZA.x + MapSpec.S, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, MapSpec.PLAZA.z + MapSpec.S * 3),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM / 2, MapSpec.PLAZA.z),
	"Server",
	"Fountain, benches, umbrellas and bunting at the MapSpec plaza centre, seen from above."
)

-- Pos Ronda tower: back off the north shoulder and rise above the greybox roof to frame the tower.
local tower = MapSpec.RONDA_TOWER
add(
	"ronda_tower",
	vec(tower.x + tower.deck / 2, MapSpec.GROUND_Y + tower.height / 2 + MapSpec.S * 2, tower.z - HUB_STANDOFF),
	vec(tower.x, MapSpec.GROUND_Y + (tower.height - tower.deck) / 2, tower.z),
	"Server",
	"Bamboo watchtower at MapSpec.RONDA_TOWER, 3/4 from the north shoulder at mid-height."
)

-- River rocks: bank standoff and lateral step come from the bridge; sight down the river centreline.
local rockX = bridge.x + bridge.width * MapSpec.S * 2
local rockLookX = rockX + bridge.width * MapSpec.S * 2
local rockBankOffset = bridge.rampLength * MapSpec.S + MapSpec.S * 2
add(
	"river_rocks",
	vec(rockX, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, MapSpec.riverCentreZ(rockX) - rockBankOffset),
	vec(rockLookX, MapSpec.GROUND_Y + bridge.top, MapSpec.riverCentreZ(rockLookX)),
	"Server",
	"Bank boulders and plants along MapSpec.riverCentreZ, looking downstream from the south bank."
)

-- Forest wall: from the playable edge out toward the hills. Eye sits in the 380..400 gap between the
-- ring and hill tree bands and well above the canopy, so no tree is inside the clear ray.
add(
	"forest_wall",
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM * 4, -(MapSpec.TERRAIN_HALF - MapSpec.TERRAIN_VOXEL * 2)),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, -(MapSpec.TERRAIN_HALF + MapSpec.TERRAIN_VOXEL * 4)),
	"Server",
	"Tree wall beyond the village edge, looking north from MapSpec.TERRAIN_HALF toward the hills."
)

-- Canonical overview: high 3/4 from the south of the bridge, looking north over it to the plaza.
add(
	"canonical_overview",
	vec(
		bridge.x + bridge.width * MapSpec.S * 2,
		MapSpec.GROUND_Y + MapSpec.TERRAIN_HALF / (MapSpec.S * MapSpec.S),
		bridge.z1 + bridge.width * MapSpec.S * 3
	),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM, MapSpec.PLAZA.z),
	"Server",
	"High 3/4 canonical-style overview from the south over the bridge toward the whole village."
)

-- Lighting variants: same framing as their base camera; the name selects the lighting preset.
local pasar = MapSpec.hub("pasar")
assert(pasar, "ReviewCameras: MapSpec has no pasar hub")
local pasarEye, pasarLook = hubCamera(pasar, hubSides.pasar)
add("spawn_golden", spawnEye, spawnLook, "Client", "Spawn at golden hour: warm light on sky and vegetation.")
add("spawn_night", spawnEye, spawnLook, "Client", "Spawn at night: lanterns, sky and dark-road legibility.")
add("pasar_golden", pasarEye, pasarLook, "Client", "Pasar at golden hour: awnings, stalls and spanduk in warm light.")
add("pasar_night", pasarEye, pasarLook, "Client", "Pasar at night: lantern and stall lighting.")

local byName: { [string]: ReviewCamera } = {}
for _, camera in cameras do
	byName[camera.name] = camera
end

function ReviewCameras.all(): { ReviewCamera }
	return table.clone(cameras)
end

function ReviewCameras.get(name: string): ReviewCamera?
	return byName[name]
end

function ReviewCameras.names(): { string }
	local names = {}
	for _, camera in cameras do
		table.insert(names, camera.name)
	end
	return names
end

return ReviewCameras
