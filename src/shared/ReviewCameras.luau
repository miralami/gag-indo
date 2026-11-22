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
local CropsShowcase: any = require(script.Parent.ModelMapCropsShowcaseR8)
local Lapangan: any = require(script.Parent.ModelMapLapanganR8)
local Musala: any = require(script.Parent.ModelMapMusalaR8)
local Lumbung: any = require(script.Parent.ModelMapLumbungR8)
local Perahu: any = require(script.Parent.ModelMapPerahuR8)
local Irrigation: any = require(script.Parent.ModelMapIrrigationR8)
local Kincir: any = require(script.Parent.ModelMapKincirR8)
local Laundry: any = require(script.Parent.ModelMapLaundryR8)
local Layangan: any = require(script.Parent.ModelMapLayanganR8)
local Seated: any = require(script.Parent.ModelMapSeatedR8)

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

-- Pos Ronda tower (WORK_QUEUE item 180). The old eye stood east of the tower centre, behind the
-- Pos Polisi roofline, so the tower read half hidden. Both eyes now stand on the open NORTH-WEST
-- diagonal (negative local X and Z), with the hut and Polisi roofs behind the subject. Every number
-- is MapSpec-derived; only the dimensionless diagonal fraction and the rise factor are fixed here.
local tower = MapSpec.RONDA_TOWER
local TOWER_STANDOFF = HUB_STANDOFF
local TOWER_WIDE_STANDOFF = HUB_STANDOFF + MapSpec.PLAZA.width / MapSpec.S
local TOWER_LOOK_Y = MapSpec.GROUND_Y + tower.height / 2
local towerEyeX = tower.x - TOWER_STANDOFF * DIAGONAL
local towerEyeZ = tower.z - TOWER_STANDOFF * DIAGONAL
local towerWideEyeX = tower.x - TOWER_WIDE_STANDOFF * DIAGONAL
local towerWideEyeZ = tower.z - TOWER_WIDE_STANDOFF * DIAGONAL
add(
	"ronda_tower",
	vec(towerEyeX, MapSpec.GROUND_Y + tower.height * 0.75 + MapSpec.S, towerEyeZ),
	vec(tower.x, TOWER_LOOK_Y, tower.z),
	"Server",
	"Bamboo watchtower at MapSpec.RONDA_TOWER, framed whole from the open north-west side."
)
add(
	"ronda_tower_wide",
	vec(towerWideEyeX, MapSpec.GROUND_Y + tower.height + MapSpec.HEADROOM / 2, towerWideEyeZ),
	vec(tower.x, TOWER_LOOK_Y, tower.z),
	"Server",
	"Wider 3/4 of the whole Pos Ronda watchtower from farther out on the same open north-west side."
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
local overviewEyeX = bridge.x + bridge.width * MapSpec.S * 2
local overviewEyeY = MapSpec.GROUND_Y + MapSpec.TERRAIN_HALF / (MapSpec.S * MapSpec.S)
local overviewEyeZ = bridge.z1 + bridge.width * MapSpec.S * 3
local overviewLookY = MapSpec.GROUND_Y + MapSpec.HEADROOM
local overviewLookZ = MapSpec.PLAZA.z + MapSpec.LAPANGAN.depth
add(
	"canonical_overview",
	vec(overviewEyeX, overviewEyeY, overviewEyeZ),
	vec(MapSpec.PLAZA.x, overviewLookY, MapSpec.PLAZA.z),
	"Server",
	"High 3/4 canonical-style overview from the south over the bridge toward the whole village."
)

-- WORK_QUEUE item 182: flanking eyes for the empty west / middle ring between the Pasar ring and the
-- river. Same height and standoff as the canonical overview, shifted laterally by one plaza width;
-- each aims at the ring flank so blocks_r9 dressing reads in the default-look shot.
local OVERVIEW_FLANK = MapSpec.PLAZA.width * MapSpec.S
local overviewFlankX = MapSpec.PLAZA.width
add(
	"canonical_overview_left",
	vec(overviewEyeX - OVERVIEW_FLANK, overviewEyeY, overviewEyeZ),
	vec(MapSpec.PLAZA.x - overviewFlankX, overviewLookY, overviewLookZ),
	"Server",
	"Left flank of the canonical overview: village ring and river band west of the Pasar."
)
add(
	"canonical_overview_right",
	vec(overviewEyeX + OVERVIEW_FLANK, overviewEyeY, overviewEyeZ),
	vec(MapSpec.PLAZA.x + overviewFlankX, overviewLookY, overviewLookZ),
	"Server",
	"Right flank of the canonical overview: village ring and river band east of the Pasar."
)

-- Lighting variants: same framing as their base camera; the name selects the lighting preset.
local pasar = MapSpec.hub("pasar")
assert(pasar, "ReviewCameras: MapSpec has no pasar hub")
local pasarEye, pasarLook = hubCamera(pasar, hubSides.pasar)
add("spawn_golden", spawnEye, spawnLook, "Client", "Spawn at golden hour: warm light on sky and vegetation.")
add("spawn_night", spawnEye, spawnLook, "Client", "Spawn at night: lanterns, sky and dark-road legibility.")
add("pasar_golden", pasarEye, pasarLook, "Client", "Pasar at golden hour: awnings, stalls and spanduk in warm light.")
add("pasar_night", pasarEye, pasarLook, "Client", "Pasar at night: lantern and stall lighting.")

-- WORK_QUEUE section N item 118: one camera per crops_showcase_r8 stage plot. Plot centres share the
-- stage offsets the server applier uses, relative to MapSpec.LAPANGAN; the eye stands 22 studs south
-- and 12 studs above the ground plane, aimed at the row centre 3 studs up, clear of the other plots.
local function cropPlotCamera(zOffset: number): (Vec3, Vec3)
	local centreZ = MapSpec.LAPANGAN.z + zOffset
	local offset = CropsShowcase.CAMERA
	return vec(MapSpec.LAPANGAN.x, MapSpec.GROUND_Y + offset.rise, centreZ - offset.standoff),
		vec(MapSpec.LAPANGAN.x, MapSpec.GROUND_Y + offset.lookRise, centreZ)
end
local cropBibitEye, cropBibitLook = cropPlotCamera(CropsShowcase.PLOTS[1].zOffset)
local cropTumbuhEye, cropTumbuhLook = cropPlotCamera(CropsShowcase.PLOTS[2].zOffset)
local cropSiapEye, cropSiapLook = cropPlotCamera(CropsShowcase.PLOTS[3].zOffset)
add(
	"crop_bibit",
	cropBibitEye,
	cropBibitLook,
	"Server",
	"Item-118 crops_showcase_r8 bibit plot: 12 crop Models in a row at the MapSpec Lapangan field."
)
add(
	"crop_tumbuh",
	cropTumbuhEye,
	cropTumbuhLook,
	"Server",
	"Item-118 crops_showcase_r8 tumbuh plot: 12 crop Models in a row at the MapSpec Lapangan field."
)
add(
	"crop_siap",
	cropSiapEye,
	cropSiapLook,
	"Server",
	"Item-118 crops_showcase_r8 siap plot: 12 crop Models in a row at the MapSpec Lapangan field."
)

-- WORK_QUEUE item 133: one camera for each remaining round-10 scene item. Item 118 already added the
-- three crops_showcase_r8 cameras above, so this block adds nine, not twelve. Every eye/look below is
-- derived from the item's authored data module plus MapSpec; the literals are stand-offs and rises.
-- Each eye sits high outside the subject so the 6-stud CAMERA_CLEAR ray starts in air.
local field = MapSpec.LAPANGAN
add(
	"lapangan_view",
	vec(field.x, MapSpec.GROUND_Y + MapSpec.HEADROOM * 3, field.z + field.depth / 2 + MapSpec.TERRAIN_VOXEL * 7),
	vec(field.x, MapSpec.GROUND_Y + Lapangan.GOAL_HEIGHT / 2, field.z),
	"Server",
	"Item-108 lapangan goals, flagpole, benches and stone edge from the south end of the field."
)

local musalaCentre = Musala.centre(MapSpec.ROAD)
musalaCentre.y = MapSpec.GROUND_Y
local mex, mey, mez = Musala.sitePoint(
	musalaCentre,
	musalaCentre.yaw,
	-MapSpec.S * 4,
	MapSpec.HEADROOM * 2,
	Musala.CORRIDOR.maxLz + MapSpec.TERRAIN_VOXEL * 3
)
local mlx, mly, mlz = Musala.sitePoint(musalaCentre, musalaCentre.yaw, Musala.DOOR.lx, Musala.DOOR.ly, Musala.DOOR.lz)
add(
	"musala_view",
	vec(mex, mey, mez),
	vec(mlx, mly, mlz),
	"Server",
	"Item-110 musala door, wudhu and shoe rack from the front-left approach."
)

local barn = Lumbung.barnCentre(pasar)
barn.y = MapSpec.GROUND_Y
local lbex, lbey, lbez =
	Lumbung.sitePoint(barn, MapSpec.S * 5, MapSpec.HEADROOM * 2, Lumbung.DOOR.lz + MapSpec.TERRAIN_VOXEL * 5)
local lblx, lbly, lblz = Lumbung.sitePoint(barn, Lumbung.DOOR.lx, Lumbung.DOOR.ly, Lumbung.DOOR.lz)
add(
	"lumbung_view",
	vec(lbex, lbey, lbez),
	vec(lblx, lbly, lblz),
	"Server",
	"Item-111 lumbung padi, ladder and drying yard from the front-right of the Pasar barn."
)

local boatSite = Perahu.siteByKey("perahu_a")
assert(boatSite, "ReviewCameras: Perahu has no perahu_a site")
local pex, pez = Perahu.worldXZ(boatSite, -MapSpec.S * 6, MapSpec.TERRAIN_VOXEL * 5, MapSpec.riverCentreZ)
local plx, plz = Perahu.worldXZ(boatSite, 0, 0, MapSpec.riverCentreZ)
add(
	"perahu_view",
	vec(pex, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, pez),
	vec(plx, MapSpec.GROUND_Y + MapSpec.S / 2, plz),
	"Server",
	"Item-112 perahu hull and gunwales on the south river bank, 3/4 from upstream."
)

local channelSite = Irrigation.siteByKey("channel_a")
assert(channelSite, "ReviewCameras: Irrigation has no channel_a site")
local channelTop = Irrigation.terraceTop(channelSite.terrace)
assert(channelTop, "ReviewCameras: irrigation channel terrace has no top")
add(
	"irrigation_view",
	vec(channelSite.x - MapSpec.S * 8, channelTop + MapSpec.HEADROOM * 2, channelSite.z - MapSpec.TERRAIN_VOXEL * 5),
	vec(channelSite.x, channelTop + Irrigation.WATER_TOP_DELTA + MapSpec.S, channelSite.z),
	"Server",
	"Item-113 bamboo irrigation flume and water sheet on the second sawah terrace."
)

local wheelSite = Kincir.SITE
local kx, kz = Kincir.worldXZ(wheelSite, MapSpec.S * 6, -MapSpec.TERRAIN_VOXEL * 4, MapSpec.riverCentreZ)
local klx, klz = Kincir.worldXZ(wheelSite, 0, 0, MapSpec.riverCentreZ)
add(
	"kincir_view",
	vec(kx, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, kz),
	vec(klx, MapSpec.GROUND_Y + Kincir.WHEEL_CENTRE_LY, klz),
	"Server",
	"Item-114 waterwheel blades and support posts from the river side, 3/4 east."
)

local washZ = Laundry.behindZ("pasar")
local lex, lez = MapSpec.hubPoint(pasar, MapSpec.S * 10, washZ - MapSpec.TERRAIN_VOXEL * 5)
local llx, llz = MapSpec.hubPoint(pasar, 0, washZ + Laundry.LINE_SPACING / 2)
add(
	"laundry_view",
	vec(lex, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, lez),
	vec(llx, MapSpec.GROUND_Y + MapSpec.HEADROOM * 0.7, llz),
	"Server",
	"Item-115 Pasar washing lines with sarung, batik and kebaya behind the back wall."
)

local kiteSite = Layangan.SITES[4]
assert(kiteSite, "ReviewCameras: Layangan has no fourth site")
local kiteX, kiteZ = Layangan.kiteXZ(kiteSite)
add(
	"kite_sky",
	vec(
		kiteX + MapSpec.TERRAIN_VOXEL * 6,
		MapSpec.GROUND_Y + kiteSite.altitude + MapSpec.HEADROOM * 2,
		kiteZ + MapSpec.TERRAIN_VOXEL * 6
	),
	vec(kiteX, MapSpec.GROUND_Y + kiteSite.altitude, kiteZ),
	"Server",
	"Item-116 kites over the Lapangan, framed on the highest sail from above."
)

local warung = MapSpec.hub("warung")
assert(warung, "ReviewCameras: MapSpec has no warung hub")
local sex, sez =
	MapSpec.hubPoint(warung, -MapSpec.S * 6, warung.depth / 2 + MapSpec.AWNING_REACH + MapSpec.TERRAIN_VOXEL * 2)
local slx, slz = MapSpec.hubPoint(warung, 0, Seated.BENCH.localZ + Seated.SEAT.zLift)
add(
	"warung_seated",
	vec(sex, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, sez),
	vec(slx, Seated.BENCH.topY + Seated.SEAT.lift + MapSpec.S * 2, slz),
	"Server",
	"Item-117 seated villagers, glasses and plates on the Warung benches from the front-left apron."
)

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
