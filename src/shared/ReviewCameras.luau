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
local KampungR10: any = require(script.Parent.ModelMapKampungR10)
local RoadFenceR10: any = require(script.Parent.ModelMapRoadFenceR10)
local SignpostsR10: any = require(script.Parent.ModelMapSignpostsR10)
local LampsR10: any = require(script.Parent.ModelMapLampsR10)
local CropStagesR10: any = require(script.Parent.ModelMapCropStagesR10)
local DitchWaterR10: any = require(script.Parent.ModelMapDitchWaterR10)
local HillDressing: any = require(script.Parent.ModelMapHillDressingR10)
local WorldConstants = require(script.Parent.Config.WorldConstants)

export type Vec3 = { number }
export type ReviewCamera = {
	name: string,
	position: Vec3,
	lookAt: Vec3,
	datamodel: "Client" | "Server",
	purpose: string,
	clockTime: number?,
}

local ReviewCameras = {}

-- The r8 CAMERA_CLEAR check casts this far toward lookAt; one terrain voxel plus one scale unit.
ReviewCameras.clearDistance = MapSpec.TERRAIN_VOXEL + MapSpec.S

local HUB_STANDOFF = 28 -- queue item 69: 3/4 view, 28 studs out
local HUB_RISE = 9 -- queue item 69: 9 studs above the ground plane
local DIAGONAL = 1 / math.sqrt(2)
-- Items 218/247: golden = midpoint of the canonical 16.0..17.0 window (LookDevCorner uses the same
-- convention); night = 21, the value lamp_night already carried from item 240.
local GOLDEN_CLOCK = (WorldConstants.GOLDEN_HOUR.minClock + WorldConstants.GOLDEN_HOUR.maxClock) / 2
local NIGHT_CLOCK = 21

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

local function add(
	name: string,
	position: Vec3,
	lookAt: Vec3,
	datamodel: "Client" | "Server",
	purpose: string,
	clockTime: number?
)
	table.insert(cameras, {
		name = name,
		position = position,
		lookAt = lookAt,
		datamodel = datamodel,
		purpose = purpose,
		clockTime = clockTime,
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
	if key == "warung" then
		-- Item 250: keep the hub-centre bearing (the item-205 recipe cones depend on it) but aim
		-- down at the dressed front age instead of up at the roof ridge. The 9-stud eye already
		-- stands 5..12 studs above grade; only the target height changes.
		look = vec(hub.x, MapSpec.GROUND_Y + MapSpec.S, hub.z)
	end
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
add(
	"pasar_awnings_golden",
	pasarApronEye,
	pasarApronLook,
	"Server",
	"Item-218 golden-hour Pasar awnings: same eye/target as pasar_awnings.",
	GOLDEN_CLOCK
)
add(
	"pasar_awnings_night",
	pasarApronEye,
	pasarApronLook,
	"Server",
	"Item-218 night Pasar awnings: same eye/target as pasar_awnings.",
	NIGHT_CLOCK
)

-- Plaza centre: above the fountain, looking down across the dressed Lapangan.
local plazaEye =
	vec(MapSpec.PLAZA.x + MapSpec.S, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, MapSpec.PLAZA.z + MapSpec.S * 3)
local plazaLook = vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM / 2, MapSpec.PLAZA.z)
add(
	"plaza_centre",
	plazaEye,
	plazaLook,
	"Server",
	"Fountain, benches, umbrellas and bunting at the MapSpec plaza centre, seen from above."
)
add(
	"plaza_centre_golden",
	plazaEye,
	plazaLook,
	"Server",
	"Item-218 golden-hour plaza centre: same eye/target as plaza_centre.",
	GOLDEN_CLOCK
)
add(
	"plaza_centre_night",
	plazaEye,
	plazaLook,
	"Server",
	"Item-218 night plaza centre: same eye/target as plaza_centre.",
	NIGHT_CLOCK
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

-- WORK_QUEUE item 216: twelve sprint-1 r10 review cameras. The two canonical overview flanks already
-- exist above (item 182), so this block adds ten registry entries and the docs add all twelve rows.
-- Item 240 re-aimed the four weak sprint-1 eyes below; they still stand in open air so the 6-stud
-- CAMERA_CLEAR ray starts in air. `lamp_night` now carries a real `clockTime = 21` field.
local connectorEyeZ = MapSpec.LAPANGAN.z + MapSpec.LAPANGAN.depth / 2
local meadowLookZ = connectorEyeZ - MapSpec.S * 2
local horizonLookY = MapSpec.GROUND_Y + MapSpec.HEADROOM * 3
local horizonFar = MapSpec.TERRAIN_HALF * 2.25

-- Item 240: close 3/4 of one road-fence stretch instead of the old far end-on sliver. The eye is
-- 16 studs outside the first authored stretch; the sightline and standoff come from its descriptor.
local fenceStretch = RoadFenceR10.stretches()[1]
local fenceAngle = math.rad(fenceStretch.angle)
local fenceMid = (fenceStretch.radiusFrom + fenceStretch.radiusTo) / 2
local fenceX = math.cos(fenceAngle) * fenceMid - math.sin(fenceAngle) * RoadFenceR10.SIDE_OFFSET * fenceStretch.side
local fenceZ = math.sin(fenceAngle) * fenceMid + math.cos(fenceAngle) * RoadFenceR10.SIDE_OFFSET * fenceStretch.side
local fenceEyeX = fenceX - math.sin(fenceAngle) * MapSpec.S * 8 * fenceStretch.side
local fenceEyeZ = fenceZ + math.cos(fenceAngle) * MapSpec.S * 8 * fenceStretch.side
-- Item 250: the old 5.25-stud eye grazed grass on the final approach. Raise it to a 10-stud eye
-- (5..12 above grade) so the whole finite look ray stays over 3 studs above the surface.
local pathEye = vec(fenceEyeX, MapSpec.GROUND_Y + MapSpec.HEADROOM, fenceEyeZ)
local pathLook = vec(fenceX, MapSpec.GROUND_Y + RoadFenceR10.FENCE_HEIGHT / 2, fenceZ)
add(
	"path_curve",
	pathEye,
	pathLook,
	"Server",
	"Item-250 downward close 3/4 of the first road_fence_r10 bamboo stretch, from outside the road shoulder."
)
add(
	"path_curve_golden",
	pathEye,
	pathLook,
	"Server",
	"Item-218 golden-hour path_curve: same eye/target as path_curve.",
	GOLDEN_CLOCK
)
add(
	"path_curve_night",
	pathEye,
	pathLook,
	"Server",
	"Item-218 night path_curve: same eye/target as path_curve.",
	NIGHT_CLOCK
)

-- Item 240: aim at the first real kampung cluster (four houses at radius 165) instead of the empty
-- gap between plots 1 and 2. The eye stands 36 studs radially outside that cluster's mean centre.
local kampungHouses = KampungR10.houses()
local kampungClusterX, kampungClusterZ = 0, 0
for index = 1, KampungR10.HOUSES_PER_CLUSTER do
	kampungClusterX += kampungHouses[index].position.x
	kampungClusterZ += kampungHouses[index].position.z
end
kampungClusterX /= KampungR10.HOUSES_PER_CLUSTER
kampungClusterZ /= KampungR10.HOUSES_PER_CLUSTER
local kampungRadius = math.sqrt(kampungClusterX * kampungClusterX + kampungClusterZ * kampungClusterZ)
local kampungUx, kampungUz = kampungClusterX / kampungRadius, kampungClusterZ / kampungRadius
add(
	"kampung_view",
	vec(
		kampungClusterX + kampungUx * MapSpec.S * 18,
		MapSpec.GROUND_Y + MapSpec.HEADROOM * 2,
		kampungClusterZ + kampungUz * MapSpec.S * 18
	),
	vec(kampungClusterX, MapSpec.GROUND_Y + KampungR10.BODY_SIZE[2] / 2, kampungClusterZ),
	"Server",
	"Item-240 close view of one four-house kampung_r10 cluster from outside the plot ring."
)
add(
	"bridge_side",
	vec(bridge.x + bridge.width * MapSpec.S + MapSpec.S, MapSpec.GROUND_Y + MapSpec.HEADROOM, bridgeZ),
	vec(bridge.x, deckY + bridge.railTop / 2, bridgeZ),
	"Server",
	"Side elevation of the river bridge deck and railing from the east bank."
)
add(
	"meadow_view",
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, MapSpec.LAPANGAN.z - MapSpec.S * 3),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.S / 4, meadowLookZ),
	"Server",
	"Open lawn between the Pasar ring and the plots, looking south across the meadow."
)
-- Item 250: the sprint-2 `terrace_wall` shot faced the village, so the hill_dressing_r10 rocks on the
-- north hill were behind the lens. Move to the south foot of hill 4 and aim down at the rocks/palms.
-- The eye sits 14 studs above the hill-dressing slope proxy (the same 3..12 band slopeY uses), so it
-- clears the grass at the eye and keeps the look ray above grade while the hill stays in frame. Same
-- registry name keeps the shot comparable.
local hillSubject = HillDressing.HILLS[4]
assert(hillSubject, "ReviewCameras: hill_dressing_r10 has no fourth hill")
local HILL_EYE_FRACTION = 0.9
local HILL_SLOPE_BASE = 3
local HILL_SLOPE_RISE = 9
local HILL_EYE_LIFT = 14
local hillSlopeY = HILL_SLOPE_BASE + (1 - HILL_EYE_FRACTION) * HILL_SLOPE_RISE
local terraceEyeY = hillSlopeY + HILL_EYE_LIFT
add(
	"terrace_wall",
	vec(hillSubject.x, terraceEyeY, hillSubject.z + hillSubject.radius * HILL_EYE_FRACTION),
	vec(hillSubject.x, terraceEyeY - MapSpec.HEADROOM / 2, hillSubject.z + hillSubject.radius * 0.35),
	"Server",
	"Item-250 downward view of hill_dressing_r10 rocks and palms on the north hill from its south foot."
)
-- Item 240: frame the real east-junction signpost board, 24 studs in front of it on the inward
-- normal. The old eye aimed at the ukur board instead, so no signpost was in frame.
local signDescriptor = SignpostsR10.SIGNS[1]
local signAngle = math.rad(signDescriptor.yaw)
local signEyeX = signDescriptor.position.x - math.sin(signAngle) * MapSpec.S * 12
local signEyeZ = signDescriptor.position.z - math.cos(signAngle) * MapSpec.S * 12
add(
	"signpost_pasar",
	vec(signEyeX, MapSpec.GROUND_Y + MapSpec.HEADROOM, signEyeZ),
	vec(signDescriptor.position.x, SignpostsR10.GROUND_Y + SignpostsR10.POST_SIZE[2], signDescriptor.position.z),
	"Server",
	"Item-240 close view of the east-junction signposts_r10 board and post from the plaza side."
)

-- Item 240: move off the ring centreline to a 3/4 eye 20 studs inside and 12 studs to the side of
-- the first lamp, so the pole and lantern read against the road. clockTime makes the night preset
-- real data; the main session sets Lighting.ClockTime from the registry field for the shot.
local lampDescriptor = LampsR10.lamps()[1]
local lampAngle = math.atan2(lampDescriptor.position.z, lampDescriptor.position.x)
local lampEyeX = lampDescriptor.position.x - math.cos(lampAngle) * MapSpec.S * 10 - math.sin(lampAngle) * MapSpec.S * 6
local lampEyeZ = lampDescriptor.position.z - math.sin(lampAngle) * MapSpec.S * 10 - math.cos(lampAngle) * MapSpec.S * 6
local lampEye = vec(lampEyeX, MapSpec.GROUND_Y + MapSpec.HEADROOM, lampEyeZ)
local lampLook =
	vec(lampDescriptor.position.x, lampDescriptor.position.y + LampsR10.POLE_SIZE[2] / 2, lampDescriptor.position.z)
add(
	"lamp_night",
	lampEye,
	lampLook,
	"Server",
	"Item-240 close 3/4 of the first lamps_r10 pole and lantern; ClockTime 21 night variant.",
	NIGHT_CLOCK
)
add(
	"lamp_night_golden",
	lampEye,
	lampLook,
	"Server",
	"Item-218 golden-hour lamp_night: same eye/target as lamp_night.",
	GOLDEN_CLOCK
)
add(
	"lamp_night_night",
	lampEye,
	lampLook,
	"Server",
	"Item-218 night lamp_night: same eye/target as lamp_night.",
	NIGHT_CLOCK
)
add(
	"horizon_north",
	vec(MapSpec.PLAZA.x, hillEyeY, -(MapSpec.TERRAIN_HALF + MapSpec.TERRAIN_VOXEL * 2)),
	vec(MapSpec.PLAZA.x, horizonLookY, -horizonFar),
	"Server",
	"North horizon over the hill and forest band from outside the playable square."
)
add(
	"horizon_south",
	vec(MapSpec.PLAZA.x, hillEyeY, MapSpec.TERRAIN_HALF - MapSpec.TERRAIN_VOXEL * 2),
	vec(MapSpec.PLAZA.x, horizonLookY, horizonFar),
	"Server",
	"South horizon over the bridge and river band from outside the playable square."
)
add(
	"fountain_close",
	vec(
		MapSpec.ROAD.halfWidth - MapSpec.S * 2,
		MapSpec.GROUND_Y + MapSpec.HEADROOM + MapSpec.S,
		MapSpec.SPAWN.z - MapSpec.S * 4
	),
	vec(MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.S * 1.25, MapSpec.PLAZA.z),
	"Server",
	"Close view of the plaza fountain and its basin from the north-east approach."
)

-- WORK_QUEUE item 240: two new close cameras for the sprint-1 subjects that had no dedicated eye.
-- `crop_stages_close` frames all three stage samples in the authored demo plot (plot 3); the old
-- plot_aerial_03 shot was too far for the 1.2/2.6/4.2-stud samples to read. `ditch_water_close`
-- looks down on one plot's two water strips from 12 studs outside the outer ditch, so each 2-stud
-- strip projects well over one 64x36 grid cell. Both eyes are in open air for the 6-stud ray.
local cropCentre = CropStagesR10.demoCentre()
local cropPlotX, cropPlotZ = Game.plotCenter(CropStagesR10.DEMO_PLOT)
local cropRadius = math.sqrt(cropPlotX * cropPlotX + cropPlotZ * cropPlotZ)
-- Item 250: a closer, higher eye so all three 1.2/2.6/4.2-stud samples read from above without the
-- sightline grazing grass within 12 studs. The target stays the demo plot centre.
local cropEye = vec(
	cropPlotX + cropPlotX / cropRadius * MapSpec.S * 10,
	MapSpec.GROUND_Y + MapSpec.HEADROOM + MapSpec.S / 2,
	cropPlotZ + cropPlotZ / cropRadius * MapSpec.S * 10
)
add(
	"crop_stages_close",
	cropEye,
	cropCentre,
	"Server",
	"Item-250 downward close view of one plot with all three crop_stages_r10 stages side by side."
)
add(
	"crop_stages_golden",
	cropEye,
	cropCentre,
	"Server",
	"Item-247 golden-hour crop stage close-up: same eye/target as crop_stages_close.",
	GOLDEN_CLOCK
)

local ditchParts = DitchWaterR10.parts()
local ditchX = (ditchParts[1].position[1] + ditchParts[2].position[1]) / 2
local ditchZ = (ditchParts[1].position[3] + ditchParts[2].position[3]) / 2
local ditchPlotX, ditchPlotZ = Game.plotCenter(ditchParts[1].plot)
local ditchRadius = math.sqrt(ditchPlotX * ditchPlotX + ditchPlotZ * ditchPlotZ)
-- Item 250: an 11-stud eye one voxel farther out than the old 10-stud / 12-stud-standoff pair;
-- at the 12-stud sample the old ray fell below 3 studs over grass. The water strips stay in frame.
add(
	"ditch_water_close",
	vec(
		ditchX + ditchPlotX / ditchRadius * MapSpec.S * 7,
		MapSpec.GROUND_Y + MapSpec.HEADROOM + MapSpec.S / 2,
		ditchZ + ditchPlotZ / ditchRadius * MapSpec.S * 7
	),
	vec(ditchX, DitchWaterR10.WATER_Y, ditchZ),
	"Server",
	"Item-250 close downward view of one plot's two ditch_water_r10 glass strips."
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
