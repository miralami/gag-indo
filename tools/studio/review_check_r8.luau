--!nocheck
-- tools/studio/review_check_r8.luau — WORK_QUEUE section M item 68 (round 9). Paste the WHOLE
-- file into Studio `execute_luau`.
--
-- Server datamodel: run during real Play after the Edit-mode bake (step 1 of REVIEW_ROUND9.md).
-- It emits the eleven r7 server scene lines plus LOOKDEV_LEAK:
--   LOAD_FAILURES, SKY_DEFAULT, GRASS_ON_BEDS, HATS, PROPS_VISIBLE, PROPS_ON_GRASS,
--   VEG_COUNT, VEG_SPECIES, BED_FLUSH, VEG_NEAR, PROP_SIZE, LOOKDEV_LEAK.
-- It also emits the r8 hub-vegetation family (WORK_QUEUE item 70, densified in item 144):
-- VEG_HUB_<hub> (one per MapSpec.HUB_ORDER key, target raised 12 -> 30), VEG_SPECIES_HUB,
-- HUB_TREES and VEG_OVERLAP. HUB_TREES is READ-ONLY: it counts staged instances tagged HubVegTree
-- with HubVegTreeHeight in 8..12, and the weakest hub decides (target >= 2). PATH_REACH is also
-- READ-ONLY and section-O's six-hub-door subset: a 6-stud corridor from each MapSpec hub front
-- outward 24 studs must hold no opaque staged hub-veg AABB (Part CFrame+Size corner math for
-- BaseParts; transparent parts ignored). It is NOT a PathfindingService audit -- item 105's full
-- 16/16 navigation audit stays a separate section-M item and no such success is claimed here.
-- All four family lines FAIL at measured 0 when the hubveg_r8 candidate is not staged. It also
-- emits the r8 plots family (WORK_QUEUE item 71,
-- redone in item 143): PLOT_FENCE, PLOT_FENCE_VISIBLE and GATE_CLEAR. All three FAIL when the
-- plots_r8 candidate is not staged. Item 143 adds READ-ONLY PLOT_FENCE_VISIBLE beside them: from
-- each plot_aerial_NN camera, raycast toward every Kind=="fence" segment centre and require that
-- the first opaque hit is that segment; a missing camera, folder, ray or zero segments FAILs at
-- measured 0, never a vacuous pass.
-- It also emits the r8 sawah family (WORK_QUEUE item 72): SAWAH_TOPS, SAWAH_WATER,
-- SAWAH_VERGE and GUBUK. All four FAIL when the sawah_r8 candidate is not staged.
-- Item 140 adds four READ-ONLY checks beside that block: TUFT_SHAPE (no PadiPart part longer than
-- 2.5 studs), PADI_ROWS (minimum distinct PadiRow ids per terrace), PADI_CLUMPS (minimum distinct
-- PadiClump ids per terrace) and SAWAH_GREEN (20x8 grid per terrace sampled from sawah_above by
-- downward rays, Include-filtered to PadiPart parts). All four FAIL at measured 0 when no candidate
-- is staged; a missing camera/Raycast is a FAIL with a reason, never a skip.
-- It also emits the r8 river family (WORK_QUEUE item 73, redone in item 141): RIVER_BANK_VEG,
-- BANK_PLANT_SHAPE, RIVER_ROCKS, BRIDGE_RAILS and BRIDGE_WALKABLE. All FAIL at measured 0 when the
-- river_r8 candidate is not staged or MapSpec.BRIDGE cannot be read (the Client VM cannot read
-- MapSpec). RIVER_BANK_VEG now targets >=40; BANK_PLANT_SHAPE and RIVER_ROCKS are item-141's new
-- READ-ONLY checks (plant base shape, bank boulder count). BRIDGE_RAILS / BRIDGE_WALKABLE unchanged.
-- It also emits the r8 path-edge family (WORK_QUEUE item 75): PATH_EDGE and PATH_CLEAR. Both FAIL
-- when the pathedge_r8 candidate is not staged or MapSpec's road geometry cannot be read.
-- PATH_EDGE_OFFSET (WORK_QUEUE item 142) is READ-ONLY and emitted beside them: every PathEdgePart's
-- tagged |Lateral| must be in [HalfWidth, HalfWidth + 3], its CFrame must agree with that lateral
-- about CentreX/CentreZ, and the recorded centre must lie on a readable MapSpec centreline. A
-- missing folder, tag or attribute FAILs at measured >= 1, never a vacuous pass.
-- It also emits the item-80 streetfurn_r8 family: STREETFURN (per-kind counts of the tagged staged
-- furniture), STRINGS_PARITY (the three signpost Strings keys have non-empty id and en) and
-- STREETFURN_CLEAR (no staged part sits within 6 studs of a MapSpec road centreline, except the
-- lampu/obor posts, gapura and pole line that are deliberately staged on the verge and tagged
-- VergePost). All three are SERVER-side and READ-ONLY, reuse the PATH_CLEAR centreline tables and
-- FAIL when the folder, tags, Strings or MapSpec are missing.
-- It also emits the item-81 spanduk_r8 family: SIGN_TEXT_PARITY and SIGN_FACING. Both are SERVER-side
-- and READ-ONLY, inspect only LookDevSpandukR8_spanduk_r8, and FAIL when the folder, Strings keys or
-- the named ReviewCameras are missing. SIGN_FACING measures each staged sign board's LookVector
-- (XZ) against the horizontal sign->camera direction and requires <= 30deg; the angle is not relaxed.
-- It also emits the item-82 animals_r8 family: ANIMAL_COUNT, ANIMAL_BOUNDS and ANIMAL_COST. All three
-- are READ-ONLY and run in the SERVER VM: they require pure Shared.ModelMapAnimalsR8 and the same
-- ServerScriptService.Server.World.MapSpec the other MapSpec checks use. No candidate is staged, no
-- folder is mutated, and the 60-second horizon is a deterministic pure simulation (no real wait).
-- Missing module or MapSpec FAILs every animal line, never a skip.
-- It also emits the item-83 flyers_r8 family: FLYER_COUNT and FLYER_COST. Both are READ-ONLY and
-- run in the SERVER VM: they require pure Shared.ModelMapFlyersR8 and the same MapSpec as above.
-- FLYER_COUNT spawns each FidelityTier tier and checks the per-kind cap (>=1 and <= cap for burung,
-- kupu and capung); FLYER_COST runs the largest tier's deterministic 60-second sim with os.clock.
-- No staging, no folder mutation and no real-time wait. Missing module FAILs both lines.
-- It also emits the r8 water family (WORK_QUEUE item 76): WATER_SAFE and WATER_RESTORE. Both are
-- CLIENT-only and mutate Terrain in one guarded enable/read/disable/compare cycle per variant,
-- restoring the prior active candidate at the end. WATER_DEFAULT (WORK_QUEUE item 137) is a
-- CLIENT-only, READ-ONLY check emitted before them: with no candidate enabled it compares all
-- five Terrain water properties against water_r8_a's values. It never enables a candidate.
-- It also emits the r8 buildings family (WORK_QUEUE item 77): BLDG_VISIBLE, BLDG_WIDTH and
-- BLDG_DOOR. All three FAIL at measured 0 when the buildings_r8 candidate is not staged.
-- BLDG_VISIBLE counts staged building Models inside the review camera cone; BLDG_WIDTH measures
-- each Model's world bounding-box width; BLDG_DOOR checks every DoorGauge for a >=7 clearance
-- with zero collidable building geometry overlapping its volume (the real avatar-fit test).
-- PIVOT_GROUND (WORK_QUEUE item 146) is READ-ONLY and emitted beside BLDG_VISIBLE: each staged
-- building's pivot must sit within 0.2 studs of its own world bbox bottom (ground base). Measured
-- is the number of failing Models (target 0); a missing folder, unreadable pivot or zero staged
-- Models FAIL at measured 6, never vacuously.
-- It also emits the r8 facades family (WORK_QUEUE item 78): FACADE_PARTS and DOOR_CLEAR. Both are
-- SERVER-side and FAIL at measured 0 when the LookDevFacadesR8_facades_r8 folder or its gauge Parts
-- are absent. FACADE_PARTS requires >=10 tagged decorative Parts and all six FacadeKind values per
-- hub; DOOR_CLEAR uses a rotation-aware GetPartsInPart probe at each FacadeDoorGauge's exact Size and
-- CFrame and requires zero collidable hub parts and zero FacadePart decorative hits. FACADE_STRAY
-- (WORK_QUEUE item 139) is READ-ONLY: each tagged Part's CFrame+Size corner AABB must fit its hub
-- Model's bbox grown 3 studs, stay at most 1 stud above the ridge, and have no side longer than 12. The
-- ridge is facadeData's per-hub `ridge` (above MapSpec.GROUND_Y) with the hub Model bbox top as the
-- fallback when the data module is missing. Missing folder, gauge, hub or read FAILs at measured >= 1.
-- It also emits the r8 hub-props family (WORK_QUEUE item 79): HUBPROPS_VISIBLE and
-- HUBPROPS_ON_GRASS. Both are SERVER-side and FAIL when the LookDevHubPropsR8_hubprops_r8 folder or
-- any hub_* ReviewCameras camera is absent. HUBPROPS_VISIBLE measures the MINIMUM number of tagged
-- props visible from their own hub camera (target >=5 in all six hubs); HUBPROPS_ON_GRASS counts
-- props whose Terrain voxel at GRASS_Y is Grass (target 0).
-- It also emits the O-section pasar_awnings_r8 family (WORK_QUEUE item 148): STALLS,
-- AWNING_STRIPES, LANE_CLEAR and PASAR_AWNING_ON_GRASS. All four are SERVER-side and READ-ONLY;
-- they inspect only LookDevPasarAwningsR8_pasar_awnings_r8 and FAIL when the folder, tags, lane data
-- or MapSpec are missing. LANE_CLEAR uses the 6-stud lane rectangle from the pure data module and
-- per-Part CFrame+Size AABBs; PASAR_AWNING_ON_GRASS samples GRASS_Y=4 under each staged stall.
-- It also emits the O-section plaza_r9 family (WORK_QUEUE item 149): PLAZA_FOUNTAIN,
-- PLAZA_BENCHES, PLAZA_UMBRELLAS, PLAZA_BUNTING, PLAZA_SHADE_TREE, PLAZA_LANE_CLEAR and
-- PLAZA_PATH_REACH. All seven are SERVER-side and READ-ONLY; they inspect only the folder
-- LookDevPlazaR9_plaza_r9 and FAIL at measured 0 (counts) / 1..4 (clearance) when the folder, tags,
-- pure data or MapSpec.PLAZA are missing. The lane and path checks use per-Part CFrame+Size AABBs
-- against 6-stud rectangles built from plaza-local lane data plus MapSpec.PLAZA; the path corridors
-- run from each of the four road-arm mouths at the plaza edge to the centre fountain rim.
-- It also emits the O-section DEFAULT-LOOK forest checks (WORK_QUEUE item 138): NO_PINES,
-- RING_COUNT, RING_SPECIES and PERF_BUDGET. All four are READ-ONLY and stage no candidate, so they
-- grade the shipping tropical backdrop itself. NO_PINES counts workspace descendants whose Name
-- contains "Pine"; RING_COUNT counts ForestTree==true instances; RING_SPECIES counts distinct
-- ForestSpecies strings; PERF_BUDGET counts BaseParts within 100 studs of (0,0,0) as the
-- VISUAL_MASTER_PLAN §6 "under about 500 draw calls" proxy, matching the recorded census method in
-- evidence/h/2026-11-19-budget-check/REPORT.md (the forest at 260-460 studs is outside it).
-- Client datamodel: same lines plus CLOUD_COVER (the client LocalScript owns Terrain.Clouds.Cover);
-- the Server datamodel cannot observe that tween. Run client-owned candidates (water, grade,
-- sounds, clouds) in the Client datamodel.
--
-- It also emits ADDITIVE_STAGE (WORK_QUEUE item 136): SERVER-only and mutating. It calls
-- disableAll() for a clean base, stages hubveg_r8 + plots_r8 + facades_r8 with enableAdditive(),
-- requires each staged folder to still hold its tagged parts, then calls disableAll() again.
-- LOOKDEV_LEAK runs after it and proves no folders leaked.
--
-- Item 90 adds the mutating SERVER-only NIGHT_WINDOWS and NIGHT_LIGHTS pair, emitted from their own
-- do...end scope just before LOOKDEV_LEAK. It stages night_r8, drives the applier's deterministic
-- setClockForCheck(20) / setClockForCheck(13) override (never mutating Lighting.ClockTime), reads the
-- staged panes and PointLights, then clears the override, disables and re-enables the prior candidate.
-- NIGHT_WINDOWS requires >=12 lit at 20:00 and 0 at 13:00; NIGHT_LIGHTS requires 1..24 enabled
-- shadowless lights. Missing folder/module or any read error FAILs loudly; both lines always emit.
-- Item 91 adds the mutating SERVER-only GRADE_SAFE, GRADE_RESTORE and GRADE_NO_DOF trio, emitted
-- from their own do...end scope just before LOOKDEV_LEAK. It enables grade_r8_a/b/c in turn and
-- reads the live Lighting effects on the SERVER (effects created here replicate to clients).
-- GRADE_SAFE compares every touched value against ModelMapGradeR8.safeRanges inclusive;
-- GRADE_RESTORE requires every property and the Lighting descendant count to match the baseline
-- after disable; GRADE_NO_DOF requires 0 depth-of-field effects at baseline and after each enable.
-- Any missing effect/range or failed read FAILs loudly; all three always emit.
-- Item 112 adds PERAHU_PARTS and PERAHU_RIVER_CLEAR (WORK_QUEUE section N, perahu_r8), both
-- SERVER-side. PERAHU_PARTS counts the staged original-Part kinds against the pure data module.
-- PERAHU_RIVER_CLEAR is mutating: it stages perahu_r8, reads every tagged part's rotation-aware XZ
-- box and fails any box that intersects the water channel while its x-range is inside the bridge's
-- 56-stud crossing interval (derived from MapSpec.BRIDGE.z1-z0, mapped to X around BRIDGE.x=0).
-- The names are distinct: BRIDGE_WALKABLE (ORDER 205) stays READ-ONLY and byte-identical, and no
-- river check or full_r9 entry is touched. Both lines FAIL at measured 0 when folder/data/MapSpec
-- are missing; the prior candidate is restored on every path.
-- Item 113 adds IRRIGATION_PARTS and IRRIGATION_WATER_ON_TERRACE (WORK_QUEUE section N,
-- irrigation_r8), both SERVER-side and appended at the very END of ORDER after LOOKDEV_LEAK so
-- every existing contiguous ORDER literal stays byte-identical. IRRIGATION_PARTS counts the staged
-- original-Part kinds against Shared.ModelMapIrrigationR8.counts(). IRRIGATION_WATER_ON_TERRACE is
-- mutating: it stages irrigation_r8, reads every tagged watersheet's CFrame+Size top face and
-- requires its distance to the live MapSpec.TERRACES top (Terrace attribute, z-band fallback) to be
-- <= 0.3 studs. No CanCollide filter, no Terrain write; SAWAH_TOPS / SAWAH_WATER / river checks and
-- full_r9 stay READ-ONLY and byte-identical. All-FAIL paths emit BOTH new names at measured 0.
-- Item 92 adds the mutating SERVER-only SOUND_LOADED, SOUND_VOLUME and SOUND_RESTORE trio, emitted
-- from their own do...end scope just before LOOKDEV_LEAK. It stages sounds_r8 via an explicit
-- SERVER applier require (saved-place boots may predate the module), then polls IsLoaded for at most
-- Shared.ModelMapSoundsR8.LOAD_TIMEOUT_S seconds. "not authorized" has no Luau signal, so a bed
-- that never loads is the only available proxy. SOUND_VOLUME also requires positional Sounds in a
-- SoundGroup with Volume <= 0.5 and RollOffMaxDistance <= 80; SOUND_RESTORE requires exact
-- SoundService/group/folder restore and the prior candidate back. All three always emit.
-- All checks except LOOKDEV_LEAK, ADDITIVE_STAGE, WATER_SAFE, WATER_RESTORE, WIND_SET,
-- SWAY_TWEENS, WIND_RESTORE, NIGHT_WINDOWS, NIGHT_LIGHTS, GRADE_SAFE, GRADE_RESTORE,
-- GRADE_NO_DOF, SOUND_LOADED, SOUND_VOLUME, SOUND_RESTORE, PERAHU_PARTS, IRRIGATION_PARTS,
-- LAUNDRY_PARTS, LAUNDRY_CLOTH_CLEAR, KITE_COUNT, KITE_COST, KITE_STRING_CLEAR, SEATED_COUNT and
-- SEATED_ON_BENCH are read-only.
-- IRRIGATION_WATER_ON_TERRACE joins the mutating set; it saves and restores the prior candidate.
-- Item 114 adds KINCIR_ROT, a mutating SERVER block that stages kincir_r8, checks its one rotating
-- root / one Heartbeat / 3..9-degree deterministic pump rate, disables it and re-enables it, then
-- restores the prior candidate on every path. It is appended at the very END of ORDER.
-- Item 115 adds LAUNDRY_PARTS and LAUNDRY_CLOTH_CLEAR, one mutating SERVER block that stages
-- laundry_r8, counts every tagged original-Part kind against Shared.ModelMapLaundryR8.counts(),
-- and probes EVERY tagged cloth with a temporary GetPartsInPart Part against the two hub wall
-- parts. No decal/brand/material verdict, no Terrain write; all earlier checks, full_r9 and the
-- candidate set stay READ-ONLY and byte-identical. Both new names are appended AFTER KINCIR_ROT
-- and every failing path emits BOTH of them at measured 0. CLOTH_SWAY is intentionally NOT checked:
-- item 85 (wind_r8) owns sway, is off by default and candidates are single-active.
-- Item 116 adds KITE_COUNT, KITE_COST and KITE_STRING_CLEAR, one mutating SERVER block that stages
-- layangan_r8, counts its four tagged kite roots / Beams / anchors under one Heartbeat connection,
-- times a deterministic 3600-step applier pump, and raycasts each kite down to its anchor to prove
-- no string crosses a collidable hub building. All three join the mutating set and are appended at
-- the very END of ORDER; every failing path emits ALL THREE at measured 0 / ERR / 0.
-- Item 117 adds SEATED_COUNT and SEATED_ON_BENCH, one mutating SERVER block that stages seated_r8,
-- seats four catalog R15 rigs via real Seat Parts, waits a real 3 s and then probes representative
-- body Parts for collidable Bench hits. Both join the mutating set and are appended at the very END
-- of ORDER; every failing path emits BOTH at measured 0. No visual/material verdict, no Terrain
-- write; all earlier checks, FLYER_COST, IDLE_COST and full_r9 stay READ-ONLY and byte-identical.
-- The mutating checks call enable(id)/disable() and
-- restore the prior active candidate at the end; ADDITIVE_STAGE uses enableAdditive(id)/
-- disableAll(). All are safe to repeat.
-- Every line is
--   CHECK <name> PASS|FAIL <measured> <target>
-- and the file returns a results table. A missing folder, attribute, service or failed read is a
-- FAIL, never a skip. No visual verdict is made here.
--
-- Grass cell: y = 4 (4-stud Region3 spanning y ~= 2..6) for both beds and props.

-- stylua: ignore start
local ORDER = {
	"LOAD_FAILURES",
	"NO_PINES",
	"RING_COUNT",
	"RING_SPECIES",
	"PERF_BUDGET",
	"SKY_DEFAULT",
	"GRASS_ON_BEDS",
	"HATS",
	"NPC8_ROLES",
	"NPC8_OUTFITS",
	"IDLE_TRACKS",
	"IDLE_SWAY",
	"IDLE_COST",
	"WALKER_SPEED",
	"WALKER_MOVE",
	"WALKER_WAYPOINTS",
	"WALKER_STUCK",
	"WALKER_ROAD",
	"PROPS_VISIBLE",
	"PROPS_ON_GRASS",
	"VEG_COUNT",
	"VEG_SPECIES",
	"BED_FLUSH",
	"VEG_HUB_pasar",
	"VEG_HUB_gelap",
	"VEG_HUB_warung",
	"VEG_HUB_ronda",
	"VEG_HUB_polisi",
	"VEG_HUB_pakrt",
	"VEG_SPECIES_HUB",
	"HUB_TREES",
	"VEG_OVERLAP",
	"PATH_REACH",
	"BLOCK_TREES",
	"BLOCK_SPECIES",
	"AVATAR_FIT",
	"HUB_FIT",
	"PLOT_FENCE",
	"PLOT_FENCE_VISIBLE",
	"GATE_CLEAR",
	"SAWAH_TOPS",
	"SAWAH_WATER",
	"SAWAH_VERGE",
	"GUBUK",
	"TUFT_SHAPE",
	"PADI_ROWS",
	"PADI_CLUMPS",
	"SAWAH_GREEN",
	"RIVER_BANK_VEG",
	"BANK_PLANT_SHAPE",
	"RIVER_ROCKS",
	"BRIDGE_RAILS",
	"BRIDGE_WALKABLE",
	"PATH_EDGE",
	"STREETFURN",
	"STRINGS_PARITY",
	"STREETFURN_CLEAR",
	"SIGN_TEXT_PARITY",
	"SIGN_FACING",
	"ANIMAL_COUNT",
	"ANIMAL_BOUNDS",
	"ANIMAL_COST",
	"PATH_CLEAR",
	"PATH_EDGE_OFFSET",
	"ROCK_COUNT",
	"ROCK_SPECIES",
	"ROCK_PATH_CLEAR",
	"ROCK_GATE_CLEAR",
	"BLDG_VISIBLE",
	"PIVOT_GROUND",
	"BLDG_WIDTH",
	"BLDG_DOOR",
	"FACADE_PARTS",
	"DOOR_CLEAR",
	"FACADE_STRAY",
	"HUBPROPS_VISIBLE",
	"HUBPROPS_ON_GRASS",
	"STALLS",
	"AWNING_STRIPES",
	"LANE_CLEAR",
	"PASAR_AWNING_ON_GRASS",
	"PLAZA_FOUNTAIN",
	"PLAZA_BENCHES",
	"PLAZA_UMBRELLAS",
	"PLAZA_BUNTING",
	"PLAZA_SHADE_TREE",
	"PLAZA_LANE_CLEAR",
	"PLAZA_PATH_REACH",
	"TOWER_HEIGHT",
	"TOWER_BASE",
	"TOWER_PATH_CLEAR",
	"VEG_NEAR",
	"PROP_SIZE",
	"CLOUD_COVER",
	"WATER_DEFAULT",
	"WATER_SAFE",
	"WATER_RESTORE",
	"WIND_SET",
	"SWAY_TWEENS",
	"WIND_RESTORE",
	"CAMERA_CLEAR",
	"FLYER_COUNT",
	"FLYER_COST",
	"EMITTERS",
	"LIGHTS",
	"TORCH_NIGHT",
	"ADDITIVE_STAGE",
	"DAY_PHASES_MONOTONIC",
	"DAY_1600_CONTRAST",
	"DAY_MAGHRIB_UNCHANGED",
	"NIGHT_WINDOWS",
	"NIGHT_LIGHTS",
	"GRADE_SAFE",
	"GRADE_RESTORE",
	"GRADE_NO_DOF",
	"PERAHU_PARTS",
	"PERAHU_RIVER_CLEAR",
	"PASAR_PAVING",
	"PASAR_GROUND_LANE_CLEAR",
	"SOUND_LOADED",
	"SOUND_VOLUME",
	"SOUND_RESTORE",
	"LAPANGAN_PARTS",
	"LAPANGAN_PATH_REACH",
	"LAPANGAN_GOAL_SIZE",
	"MUSALA_PARTS",
	"MUSALA_DOOR_CLEAR",
	"MUSALA_PATH_REACH",
	"LUMBUNG_PARTS",
	"LUMBUNG_DOOR_CLEAR",
	"LUMBUNG_PROPS_ON_GRASS",
	"LOOKDEV_LEAK",
	"IRRIGATION_PARTS",
	"IRRIGATION_WATER_ON_TERRACE",
	"KINCIR_ROT",
	"LAUNDRY_PARTS",
	"LAUNDRY_CLOTH_CLEAR",
	"KITE_COUNT",
	"KITE_COST",
	"KITE_STRING_CLEAR",
	"SEATED_COUNT",
	"SEATED_ON_BENCH",
	"CROPS_STAGED",
	"SEASON_SAFE",
	"SEASON_RESTORE",
	"SEASON_DISTINCT",
	"RAIN_EMITTERS",
	"RAIN_OFF_CERAH",
	"RAIN_COST",
	"DAWN_PHASES_MONOTONIC",
	"DAWN_SAFE",
}

local GRASS_Y = 4
local CONE_COS = math.cos(math.rad(35)) -- 70-degree full cone
local VEG_EYE = Vector3.new(0, 20, 150)
local VEG_LOOK = Vector3.new(0, 8, 96)
local PROP_SLOTS = { "gerobak", "sumur", "lapak", "pagar_bambu", "alat_tani", "jemuran" }
local HAT_ROLES = { "petani", "petani_wanita", "polisi", "pak_rt" }
local ALL_NPC_ROLES = { "petani", "petani_wanita", "polisi", "pak_rt", "pedagang" }
local FALLBACK_BEDS = {
	{ x = 30, z = 52 },
	{ x = 52, z = 30 },
	{ x = -30, z = 52 },
	{ x = -52, z = 30 },
	{ x = -52, z = -30 },
	{ x = 52, z = -30 },
}
local FALLBACK_SKY_FT = 2835177931 -- Shared.SkyMapR6.sets.e.ids.SkyboxFt

local results = {}

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	print(line)
	results[#results + 1] = {
		name = name,
		passed = passed,
		measured = measured,
		target = target,
		line = line,
		detail = detail,
	}
end

local function service(name)
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return value
	end
	return nil
end

local function attr(inst, key)
	if not inst then
		return nil
	end
	local ok, value = pcall(function()
		return inst:GetAttribute(key)
	end)
	if ok then
		return value
	end
	return nil
end

local function childList(inst)
	if not inst then
		return {}
	end
	local ok, list = pcall(function()
		return inst:GetChildren()
	end)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

-- Item 144: group members live under one anchor Model, so the vegetation census walks descendants.
local function descendantList(inst)
	if not inst then
		return {}
	end
	local ok, list = pcall(function()
		return inst:GetDescendants()
	end)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

local function folderNamed(name)
	local ok, folder = pcall(function()
		return workspace:FindFirstChild(name)
	end)
	if ok then
		return folder
	end
	return nil
end

local function asVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if
		type(value) == "table"
		and type(value.x) == "number"
		and type(value.y) == "number"
		and type(value.z) == "number"
	then
		return Vector3.new(value.x, value.y, value.z)
	end
	-- ReviewCameras exports Vec3 as an array { x, y, z } (type { number }).
	if
		type(value) == "table"
		and type(value[1]) == "number"
		and type(value[2]) == "number"
		and type(value[3]) == "number"
	then
		return Vector3.new(value[1], value[2], value[3])
	end
	return nil
end

-- Exact for Models/Parts; the manual union is only a fallback for an unusual staged instance.
-- A baked asset may be a Model OR a single BasePart/MeshPart (teh-tehan): GetBoundingBox is
-- Model-only, so a BasePart is measured from its own CFrame.
local function bboxCentre(inst)
	if not inst then
		return nil
	end
	local okModel, isModel = pcall(function()
		return inst:IsA("Model")
	end)
	if okModel and isModel then
		local ok, cf = pcall(function()
			return inst:GetBoundingBox()
		end)
		if ok and cf then
			return cf.Position
		end
	end
	local okPart, isPart = pcall(function()
		return inst:IsA("BasePart")
	end)
	if okPart and isPart then
		local ok, cf = pcall(function()
			return inst.CFrame
		end)
		if ok and cf then
			return cf.Position
		end
	end
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local found = false
	local okParts, parts = pcall(function()
		return inst:GetDescendants()
	end)
	if okParts then
		for _, part in ipairs(parts) do
			local okPart, isPart = pcall(function()
				return part:IsA("BasePart")
			end)
			if okPart and isPart then
				local half = part.Size / 2
				local centre = part.CFrame.Position
				minV = Vector3.new(
					math.min(minV.X, centre.X - half.X),
					math.min(minV.Y, centre.Y - half.Y),
					math.min(minV.Z, centre.Z - half.Z)
				)
				maxV = Vector3.new(
					math.max(maxV.X, centre.X + half.X),
					math.max(maxV.Y, centre.Y + half.Y),
					math.max(maxV.Z, centre.Z + half.Z)
				)
				found = true
			end
		end
	end
	if not found then
		return nil
	end
	return (minV + maxV) / 2
end

-- Same bounding box, but the SIZE Vector3. Used by VEG_NEAR (bbox height) and PROP_SIZE.
local function bboxSize(inst)
	if not inst then
		return nil
	end
	local ok, cf, size = pcall(function()
		return inst:GetBoundingBox()
	end)
	if ok and cf and size then
		return size
	end
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local found = false
	local okParts, parts = pcall(function()
		return inst:GetDescendants()
	end)
	if okParts then
		for _, part in ipairs(parts) do
			local okPart, isPart = pcall(function()
				return part:IsA("BasePart")
			end)
			if okPart and isPart then
				local okBox, boxCf, boxSize = pcall(function()
					return part:GetBoundingBox()
				end)
				if okBox and boxCf and boxSize then
					local half = boxSize / 2
					local centre = boxCf.Position
					minV = Vector3.new(
						math.min(minV.X, centre.X - half.X),
						math.min(minV.Y, centre.Y - half.Y),
						math.min(minV.Z, centre.Z - half.Z)
					)
					maxV = Vector3.new(
						math.max(maxV.X, centre.X + half.X),
						math.max(maxV.Y, centre.Y + half.Y),
						math.max(maxV.Z, centre.Z + half.Z)
					)
					found = true
				end
			end
		end
	end
	if not found then
		return nil
	end
	return maxV - minV
end

-- Surface height of the terrain column at (x,z). Terrain-only ray so a staged prop or a player
-- can never be mistaken for grade. Returns nil when Terrain or the ray is unavailable (= failure).
local function terrainSurfaceY(x, z)
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		return nil
	end
	local okParams, params = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = { terrain }
		p.IgnoreWater = false
		return p
	end)
	if not okParams then
		return nil
	end
	local okRay, hit = pcall(function()
		return workspace:Raycast(Vector3.new(x, 256, z), Vector3.new(0, -512, 0), params)
	end)
	if okRay and hit and hit.Instance == terrain then
		return hit.Position.Y
	end
	return nil
end

local function insideCone(centre, eye, lookAt)
	local dir = centre - eye
	local look = lookAt - eye
	if dir.Magnitude <= 0 or look.Magnitude <= 0 then
		return false
	end
	return dir:Dot(look) / (dir.Magnitude * look.Magnitude) >= CONE_COS
end

local function visibleFrom(subject, centre, eye, lookAt)
	if not insideCone(centre, eye, lookAt) then
		return false
	end
	local okParams, params = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		local filter = { subject }
		local Players = service("Players")
		if Players then
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					filter[#filter + 1] = player.Character
				end
			end
		end
		p.FilterDescendantsInstances = filter
		return p
	end)
	if not okParams then
		return false
	end
	local okRay, hit = pcall(function()
		return workspace:Raycast(eye, centre - eye, params)
	end)
	if not okRay then
		return false
	end
	return hit == nil
end

-- r7 helper: count subjects visible from a camera CFrame (70-degree cone + one ray per subject).
-- A missing camera or bbox is not visible; failed params/ray are not visible.
local function visibleCount(subjects, cameraCF)
	if not cameraCF or type(subjects) ~= "table" then
		return 0
	end
	local eye = cameraCF.Position
	local lookAt = eye + cameraCF.LookVector
	local count = 0
	for _, subject in ipairs(subjects) do
		local centre = bboxCentre(subject)
		if centre and visibleFrom(subject, centre, eye, lookAt) then
			count += 1
		end
	end
	return count
end

-- r7 helper: instances with a CollectionService tag inside radius, optionally inside the
-- 70-degree cone toward lookAt. bboxCentre first, GetPivot fallback, failed reads excluded.
local function taggedNear(tag, origin, radius, lookAt)
	if type(tag) ~= "string" or not origin or type(radius) ~= "number" then
		return {}
	end
	local CollectionService = service("CollectionService")
	if not CollectionService then
		return {}
	end
	local okTagged, tagged = pcall(function()
		return CollectionService:GetTagged(tag)
	end)
	if not okTagged or type(tagged) ~= "table" then
		return {}
	end
	local found = {}
	for _, inst in ipairs(tagged) do
		local centre = bboxCentre(inst)
		if not centre then
			local okPos, position = pcall(function()
				return inst:GetPivot().Position
			end)
			if okPos then
				centre = position
			end
		end
		if centre and (centre - origin).Magnitude <= radius and (not lookAt or insideCone(centre, origin, lookAt)) then
			found[#found + 1] = inst
		end
	end
	return found
end

local function countNear(tag, origin, radius, lookAt)
	return #taggedNear(tag, origin, radius, lookAt)
end

-- A sample PASSES only when at least one returned material is not Grass. Failed read = failure.
local function voxelHasNonGrass(x, y, z)
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		return false
	end
	local okRead, materials = pcall(function()
		-- ReadVoxels requires grid-aligned bounds. Pick the exact 4-stud voxel cell containing
		-- the sample rather than a ±2 region that can straddle the grid and throw.
		local cellX = math.floor(x / 4) * 4
		local cellY = math.floor(y / 4) * 4
		local cellZ = math.floor(z / 4) * 4
		local region = Region3.new(Vector3.new(cellX, cellY, cellZ), Vector3.new(cellX + 4, cellY + 4, cellZ + 4))
		return terrain:ReadVoxels(region, 4)
	end)
	if not okRead or type(materials) ~= "table" then
		return false
	end
	for _, slab in ipairs(materials) do
		if type(slab) == "table" then
			for _, row in ipairs(slab) do
				if type(row) == "table" then
					for _, material in ipairs(row) do
						if material ~= Enum.Material.Grass then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- r7 helper: true when the sampled voxel is all Grass. Accepts Vector3 or {x=,y=,z=}; y
-- defaults to GRASS_Y. A failed read returns false from voxelHasNonGrass, so grassAt is true
-- and the caller counts it as a failure, not a skip.
local function grassAt(pos)
	local x, y, z
	if typeof(pos) == "Vector3" then
		x, y, z = pos.X, pos.Y, pos.Z
	elseif type(pos) == "table" then
		x, y, z = pos.x, pos.y or GRASS_Y, pos.z
	end
	if type(x) ~= "number" or type(z) ~= "number" then
		return true
	end
	if type(y) ~= "number" then
		y = GRASS_Y
	end
	return not voxelHasNonGrass(x, y, z)
end

-- 1. LOAD_FAILURES: sum of the three r7 counters plus npcs_r8, PASS only at 0.
local failureCounts = {}
local failureOk = true
local okModule, Failures = pcall(function()
	return require(game.ReplicatedStorage.Shared.LookDevFailures)
end)
if not okModule or type(Failures) ~= "table" then
	failureOk = false
else
	for _, id in ipairs({ "vegetation_r7", "npcs_r7", "props_r7", "npcs_r8", "npcs_idle_r8", "ambient_walkers_r8" }) do
		local okGet, count = pcall(function()
			return Failures.get(id)
		end)
		if not okGet or type(count) ~= "number" then
			failureOk = false
			break
		end
		failureCounts[id] = count
	end
end
local failureTotal = 0
for _, count in pairs(failureCounts) do
	failureTotal += count
end
if failureOk then
	emit("LOAD_FAILURES", failureTotal == 0, failureTotal, 0, failureCounts)
else
	emit("LOAD_FAILURES", false, "ERR", 0, { reason = "LookDevFailures not readable" })
end

-- 1b. O-section default-look forest checks (WORK_QUEUE item 138). READ-ONLY: no candidate is
-- enabled or staged here. NO_PINES is the CHECK_74 rule: count workspace descendants whose Name
-- contains "Pine" (case-sensitive substring), PASS iff zero. RING_COUNT counts descendants with
-- ForestTree == true (PASS iff >=250); RING_SPECIES counts the distinct ForestSpecies strings on
-- those trees (PASS iff >=4). PERF_BUDGET is the spawn-view draw-call proxy for VISUAL_MASTER_PLAN
-- §6 "under about 500 draw calls": count BaseParts whose world position is within 100 studs of
-- (0,0,0), PASS iff <=500. That is the recorded census method in
-- evidence/h/2026-11-19-budget-check/REPORT.md (pasar baseline 335 parts; current default 334).
-- The default forest sits at 260-460 studs, outside the census.
-- A failed workspace read is a recorded FAIL, never a vacuous pass.
do
local pineOffenders, pineCount, forestCount = {}, 0, 0
local forestSpecies, speciesList = {}, {}
local perfParts, perfReadErrors = 0, 0
local okScene, sceneDescendants = pcall(function()
	return workspace:GetDescendants()
end)
if type(sceneDescendants) ~= "table" then
	okScene = false
	sceneDescendants = {}
end
for _, inst in ipairs(sceneDescendants) do
	local okName, name = pcall(function()
		return inst.Name
	end)
	if okName and type(name) == "string" and string.find(name, "Pine", 1, true) then
		pineCount += 1
		if #pineOffenders < 10 then
			pineOffenders[#pineOffenders + 1] = name
		end
	end

	if attr(inst, "ForestTree") == true then
		forestCount += 1
		local species = attr(inst, "ForestSpecies")
		if type(species) == "string" and species ~= "" and not forestSpecies[species] then
			forestSpecies[species] = true
			speciesList[#speciesList + 1] = species
		end
	end

	local okPart, isPart = pcall(function()
		return inst:IsA("BasePart")
	end)
	if okPart and isPart then
		local okCentre, centre = pcall(function()
			return select(1, inst:GetBoundingBox()).Position
		end)
		if not okCentre or typeof(centre) ~= "Vector3" then
			okCentre, centre = pcall(function()
				return inst.CFrame.Position
			end)
		end
		if okCentre and typeof(centre) == "Vector3" then
			if centre.X * centre.X + centre.Y * centre.Y + centre.Z * centre.Z <= 100 * 100 then
				perfParts += 1
			end
		else
			perfReadErrors += 1
		end
	elseif not okPart then
		perfReadErrors += 1
	end
end
table.sort(speciesList)
emit("NO_PINES", okScene and pineCount == 0, pineCount, 0, {
	measurement = "workspace descendants whose Name contains 'Pine'",
	sample = pineOffenders,
	readError = not okScene,
})
emit("RING_COUNT", okScene and forestCount >= 250, forestCount, 250, {
	measurement = "workspace descendants with ForestTree == true",
	readError = not okScene,
})
emit("RING_SPECIES", okScene and #speciesList >= 4, #speciesList, 4, {
	species = speciesList,
	readError = not okScene,
})
emit("PERF_BUDGET", okScene and perfReadErrors == 0 and perfParts <= 500, perfParts, 500, {
	proxy = "spawn-view BasePart count within 100 studs of (0,0,0)",
	readErrors = perfReadErrors,
	reference = "VISUAL_MASTER_PLAN section 6 under about 500 draw calls",
})
end

-- 2. SKY_DEFAULT: fresh Play, no enable call. Accept asset URL or plain integer form.
local skyFtId = FALLBACK_SKY_FT
local okSkyMap, SkyMap = pcall(function()
	return require(game.ReplicatedStorage.Shared.SkyMapR6)
end)
if okSkyMap and type(SkyMap) == "table" and type(SkyMap.sets) == "table" then
	local e = SkyMap.sets.e
	if type(e) == "table" and type(e.ids) == "table" and type(e.ids.SkyboxFt) == "number" then
		skyFtId = e.ids.SkyboxFt
	end
end
local expectedSky = "rbxassetid://" .. tostring(skyFtId)
local Lighting = service("Lighting")
local sky = nil
if Lighting then
	local okSky, found = pcall(function()
		return Lighting:FindFirstChildOfClass("Sky")
	end)
	if okSky then
		sky = found
	end
end
local actualSky = "MISSING"
if sky then
	local okFt, ft = pcall(function()
		return tostring(sky.SkyboxFt)
	end)
	if okFt then
		actualSky = ft
	end
end
emit("SKY_DEFAULT", actualSky == expectedSky or actualSky == tostring(skyFtId), actualSky, expectedSky)

-- 3. GRASS_ON_BEDS: six flower beds from the shared map plus every PlotAnchor centre.
local samples = {}
local okBeds, Beds = pcall(function()
	return require(game.ReplicatedStorage.Shared.SpawnGroundMapR6).flowerBeds
end)
local beds = FALLBACK_BEDS
if okBeds and type(Beds) == "table" and #Beds > 0 then
	beds = Beds
end
for index, bed in ipairs(beds) do
	if type(bed) == "table" and type(bed.x) == "number" and type(bed.z) == "number" then
		samples[#samples + 1] = { name = "bed:" .. index, x = bed.x, z = bed.z }
	end
end
local plotAnchors = taggedNear("PlotAnchor", Vector3.new(0, 0, 0), math.huge)
for index, anchor in ipairs(plotAnchors) do
	local okPos, position = pcall(function()
		return anchor:GetPivot().Position
	end)
	if okPos then
		samples[#samples + 1] = { name = "plot:" .. index, x = position.X, z = position.Z }
	end
end
local grassFailures = {}
for _, sample in ipairs(samples) do
	if grassAt(sample) then
		grassFailures[#grassFailures + 1] = sample.name
	end
end
emit("GRASS_ON_BEDS", #grassFailures == 0, #grassFailures, 0, {
	voxelY = GRASS_Y,
	samples = #samples,
	plotAnchors = countNear("PlotAnchor", Vector3.new(0, 0, 0), math.huge),
	failed = grassFailures,
})

-- 4. HATS: each of four required roles needs >=1 Accessory descendant; missing rig = 0.
do
local npcFolder = folderNamed("LookDevModelsNpcsR7_npcs_r7")
local accessories = {}
local rigs = {}
for _, role in ipairs(ALL_NPC_ROLES) do
	accessories[role] = 0
	rigs[role] = 0
end
for _, rig in ipairs(childList(npcFolder)) do
	if attr(rig, "LookDevR7") == "npcs_r7" then
		local role = attr(rig, "Role")
		if type(role) == "string" and accessories[role] ~= nil then
			rigs[role] += 1
			local okDescendants, descendants = pcall(function()
				return rig:GetDescendants()
			end)
			if okDescendants then
				for _, descendant in ipairs(descendants) do
					local okAccessory, isAccessory = pcall(function()
						return descendant:IsA("Accessory")
					end)
					if okAccessory and isAccessory then
						accessories[role] += 1
					end
				end
			end
		end
	end
end
local rolesWithHats = 0
for _, role in ipairs(HAT_ROLES) do
	if accessories[role] >= 1 then
		rolesWithHats += 1
	end
end
emit(
	"HATS",
	rolesWithHats == #HAT_ROLES,
	rolesWithHats,
	#HAT_ROLES,
	{ accessories = accessories, rigs = rigs, folderPresent = npcFolder ~= nil }
)
end

-- 4b. npcs_r8 roles and outfits (WORK_QUEUE item 86). Own do...end scope: the harness
-- already hit the 200-local-register limit before this family. Both checks are
-- SERVER-side and READ-ONLY. A missing folder/rig/attribute FAILs at measured <5,
-- never a skip; all reads are pcall-guarded and both lines always emit.
do
local NPC8_ROLES = { "tengkulak", "debt_collector", "ibu_warung", "anak_anak", "bapak_ojek" }
local npc8Folder = folderNamed("LookDevModelsNpcsR8_npcs_r8")
local npc8Rigs, npc8RigCount, npc8ReadErrors = {}, {}, 0
for _, role in ipairs(NPC8_ROLES) do
	npc8Rigs[role] = {}
	npc8RigCount[role] = 0
end
local okChildren, children = pcall(function()
	return childList(npc8Folder)
end)
if not okChildren or type(children) ~= "table" then
	npc8ReadErrors += 1
	children = {}
end
for _, rig in ipairs(children) do
	if attr(rig, "LookDevR8") == "npcs_r8" then
		local role = attr(rig, "Role")
		if type(role) == "string" and npc8Rigs[role] ~= nil then
			npc8RigCount[role] += 1
			npc8Rigs[role][#npc8Rigs[role] + 1] = rig
		end
	end
end
local npc8WithHats = 0
for _, role in ipairs(NPC8_ROLES) do
	if npc8RigCount[role] == 1 then
		local okDesc, descendants = pcall(function()
			return npc8Rigs[role][1]:GetDescendants()
		end)
		if okDesc and type(descendants) == "table" then
			for _, descendant in ipairs(descendants) do
				local okHat, isHat = pcall(function()
					return descendant:IsA("Accessory")
				end)
				if okHat and isHat then
					npc8WithHats += 1
					break
				end
			end
		else
			npc8ReadErrors += 1
		end
	end
end
emit("NPC8_ROLES", npc8WithHats == #NPC8_ROLES, npc8WithHats, #NPC8_ROLES, {
	rigs = npc8RigCount,
	folderPresent = npc8Folder ~= nil,
	readErrors = npc8ReadErrors,
})

local npc8Pairs, npc8Hats = {}, {}
for _, role in ipairs(NPC8_ROLES) do
	if npc8RigCount[role] == 1 then
		local rig = npc8Rigs[role][1]
		local shirtId, pantsId, hatIds = attr(rig, "ShirtId"), attr(rig, "PantsId"), attr(rig, "HatIds")
		if type(shirtId) == "number" and type(pantsId) == "number" and type(hatIds) == "string" and #hatIds > 0 then
			npc8Pairs[role] = tostring(shirtId) .. ":" .. tostring(pantsId)
			npc8Hats[role] = true
		end
	end
end
local npc8Seen, npc8UniqueCount, npc8HatCount = {}, 0, 0
for role, pair in pairs(npc8Pairs) do
	if not npc8Seen[pair] then
		npc8Seen[pair] = role
		npc8UniqueCount += 1
	end
end
for _, role in ipairs(NPC8_ROLES) do
	if npc8Hats[role] then
		npc8HatCount += 1
	end
end
emit(
	"NPC8_OUTFITS",
	npc8UniqueCount == #NPC8_ROLES and npc8HatCount == #NPC8_ROLES,
	npc8UniqueCount,
	#NPC8_ROLES,
	{ pairs = npc8Pairs, hats = npc8HatCount, folderPresent = npc8Folder ~= nil }
)
end

-- 5/6. PROPS_VISIBLE and PROPS_ON_GRASS: six fixed slots from the tagged folder.
local propFolder = folderNamed("LookDevModelsPropsR7_props_r7")
local propsBySlot = {}
for _, model in ipairs(childList(propFolder)) do
	if attr(model, "LookDevR7") == "props_r7" then
		local slot = attr(model, "PropSlot")
		if type(slot) == "string" and propsBySlot[slot] == nil then
			propsBySlot[slot] = model
		end
	end
end
do
local propEye = asVector3(attr(propFolder, "ReviewCameraPos"))
local propLook = asVector3(attr(propFolder, "ReviewLookAt"))
local propCameraCF = nil
if propEye and propLook then
	local okCF, cf = pcall(function()
		return CFrame.lookAt(propEye, propLook)
	end)
	if okCF then
		propCameraCF = cf
	end
end
local propSubjects = {}
local onGrassCount = 0
local propDetail = {}
for _, slot in ipairs(PROP_SLOTS) do
	local subject = propsBySlot[slot]
	local centre = bboxCentre(subject)
	local seen = false
	local grassy = true -- absent subject is a failing grass sample, not a skip
	if subject then
		propSubjects[#propSubjects + 1] = subject
		if centre then
			grassy = grassAt({ x = centre.X, z = centre.Z }) -- fixed GRASS_Y, as in r7
		end
	end
	if grassy then
		onGrassCount += 1
	end
	propDetail[slot] = {
		visible = seen, -- filled from visibleCount below, per slot
		onGrass = grassy,
		centre = centre and { centre.X, centre.Y, centre.Z } or nil,
	}
end
local visibleCountValue = visibleCount(propSubjects, propCameraCF)
if propCameraCF then
	local eye = propCameraCF.Position
	local lookAt = eye + propCameraCF.LookVector
	for _, slot in ipairs(PROP_SLOTS) do
		local subject = propsBySlot[slot]
		local centre = bboxCentre(subject)
		propDetail[slot].visible = subject ~= nil and centre ~= nil and visibleFrom(subject, centre, eye, lookAt)
	end
end
emit("PROPS_VISIBLE", visibleCountValue == #PROP_SLOTS, visibleCountValue, #PROP_SLOTS, {
	folderPresent = propFolder ~= nil,
	cameraPos = propEye and { propEye.X, propEye.Y, propEye.Z } or nil,
	lookAt = propLook and { propLook.X, propLook.Y, propLook.Z } or nil,
	slots = propDetail,
})
emit("PROPS_ON_GRASS", onGrassCount == 0, onGrassCount, 0, { voxelY = GRASS_Y, slots = propDetail })
end

-- 7/8. VEG_COUNT and VEG_SPECIES: fixed camera, 100 studs, 70-degree cone.
local vegFolder = folderNamed("LookDevModelsVegetationR7_vegetation_r7")
local vegModels = {}
for _, model in ipairs(childList(vegFolder)) do
	if attr(model, "LookDevR7") == "vegetation_r7" then
		vegModels[#vegModels + 1] = model
	end
end
local vegCount = 0
local speciesSeen = {}
for _, model in ipairs(vegModels) do
	local centre = bboxCentre(model)
	if centre and (centre - VEG_EYE).Magnitude <= 100 and insideCone(centre, VEG_EYE, VEG_LOOK) then
		vegCount += 1
		local species = attr(model, "Species")
		if type(species) == "string" and species ~= "" then
			speciesSeen[species] = true
		end
	end
end
local speciesNames = {}
for name in pairs(speciesSeen) do
	speciesNames[#speciesNames + 1] = name
end
table.sort(speciesNames)
emit("VEG_COUNT", vegCount >= 60, vegCount, 60, {
	folderPresent = vegFolder ~= nil,
	eye = { VEG_EYE.X, VEG_EYE.Y, VEG_EYE.Z },
	look = { VEG_LOOK.X, VEG_LOOK.Y, VEG_LOOK.Z },
})
emit("VEG_SPECIES", #speciesNames >= 8, #speciesNames, 8, { species = speciesNames })

-- 9. BED_FLUSH: repainted beds must sit at grade. Compare each flower-bed centre's terrain
-- surface against points 6 studs outside the 5.6-stud bed radius. Four cardinal samples, using
-- the closest outside height, so natural slope cannot fake a failure; the old FillBlock mound
-- was 4 studs tall across the whole 12x12 bed, so every outside sample stayed at grade.
do
local bedRadius = 5.6
local okBedMap, BedMap = pcall(function()
	return require(game.ReplicatedStorage.Shared.SpawnGroundMapR6)
end)
if okBedMap and type(BedMap) == "table" and type(BedMap.flowerBedRadius) == "number" then
	bedRadius = BedMap.flowerBedRadius
end
local outsideDist = bedRadius + 6
local flushFailures = {}
local worstFlush = 0
for index, bed in ipairs(beds) do
	if type(bed) == "table" and type(bed.x) == "number" and type(bed.z) == "number" then
		local centreY = terrainSurfaceY(bed.x, bed.z)
		local bestDiff = math.huge
		if centreY then
			for _, dir in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
				local outsideY = terrainSurfaceY(bed.x + dir[1] * outsideDist, bed.z + dir[2] * outsideDist)
				if outsideY then
					bestDiff = math.min(bestDiff, math.abs(centreY - outsideY))
				end
			end
		end
		if bestDiff == math.huge then
			flushFailures[#flushFailures + 1] = "bed:" .. index .. ":no-read"
			worstFlush = 999
		else
			worstFlush = math.max(worstFlush, bestDiff)
			if bestDiff > 0.5 then
				flushFailures[#flushFailures + 1] = "bed:" .. index .. ":" .. string.format("%.2f", bestDiff)
			end
		end
	end
end
emit("BED_FLUSH", #flushFailures == 0, math.floor(worstFlush * 100) / 100, 0.5, {
	beds = #beds,
	outside = outsideDist,
	failed = flushFailures,
})
end

-- 9b. r8 hub-vegetation family (WORK_QUEUE item 70). Three CHECK families over the staged
-- LookDevModelsVegetationHubR8_hubveg_r8 folder. Hub keys come from MapSpec.HUB_ORDER (fallback
-- listed below so the same six FAIL lines are emitted even when MapSpec cannot be required).
-- Every game API is pcall-guarded; a missing folder / module is a FAIL at measured 0, never a skip.
local FALLBACK_HUB_ORDER = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }
local HUB_VEG_FOLDER = "LookDevModelsVegetationHubR8_hubveg_r8"
local HUB_VEG_RADIUS = 40
local HUB_VEG_MIN_COUNT = 30
local HUB_VEG_MIN_SPECIES = 4
local OVERLAP_TOL = 0.05

-- Model: GetBoundingBox. Single BasePart/MeshPart (teh-tehan): project the part's CFrame basis
-- onto world X/Z. Anything else: manual BasePart union fallback. Returns the instance's XZ AABB.
local function bboxAABB(inst)
	if not inst then
		return nil
	end
	local okModel, isModel = pcall(function()
		return inst:IsA("Model")
	end)
	if okModel and isModel then
		local ok, cf, size = pcall(function()
			return inst:GetBoundingBox()
		end)
		if ok and cf and size then
			return {
				minX = cf.Position.X - size.X / 2,
				maxX = cf.Position.X + size.X / 2,
				minZ = cf.Position.Z - size.Z / 2,
				maxZ = cf.Position.Z + size.Z / 2,
			}
		end
	end
	local okPart, isPart = pcall(function()
		return inst:IsA("BasePart")
	end)
	if okPart and isPart then
		local ok, cf, size = pcall(function()
			return inst.CFrame, inst.Size
		end)
		if ok and cf and size then
			local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
			local extentX = math.abs(cf.RightVector.X) * hx
				+ math.abs(cf.UpVector.X) * hy
				+ math.abs(cf.LookVector.X) * hz
			local extentZ = math.abs(cf.RightVector.Z) * hx
				+ math.abs(cf.UpVector.Z) * hy
				+ math.abs(cf.LookVector.Z) * hz
			return {
				minX = cf.Position.X - extentX,
				maxX = cf.Position.X + extentX,
				minZ = cf.Position.Z - extentZ,
				maxZ = cf.Position.Z + extentZ,
			}
		end
	end
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local found = false
	local okParts, parts = pcall(function()
		return inst:GetDescendants()
	end)
	if okParts then
		for _, part in ipairs(parts) do
			local okPart, isPart = pcall(function()
				return part:IsA("BasePart")
			end)
			if okPart and isPart then
				local okBox, boxCf, boxSize = pcall(function()
					return part:GetBoundingBox()
				end)
				if okBox and boxCf and boxSize then
					local half = boxSize / 2
					local centre = boxCf.Position
					minV = Vector3.new(
						math.min(minV.X, centre.X - half.X),
						math.min(minV.Y, centre.Y - half.Y),
						math.min(minV.Z, centre.Z - half.Z)
					)
					maxV = Vector3.new(
						math.max(maxV.X, centre.X + half.X),
						math.max(maxV.Y, centre.Y + half.Y),
						math.max(maxV.Z, centre.Z + half.Z)
					)
					found = true
				end
			end
		end
	end
	if not found then
		return nil
	end
	return { minX = minV.X, maxX = maxV.X, minZ = minV.Z, maxZ = maxV.Z }
end

-- MapSpec lives under ServerScriptService.Server.World; FindFirstChild (not WaitForChild) so the
-- Client VM cannot block. Pure data modules; ModelMapVegetationR5 supplies pathZones(mapSpec),
-- which already includes roadArms + ringSegments + roadContinuations.
local okMapSpec, MapSpec = pcall(function()
	local sss = game:GetService("ServerScriptService")
	local server = sss:FindFirstChild("Server")
	if not server then
		return nil
	end
	local world = server:FindFirstChild("World")
	if not world then
		return nil
	end
	local module = world:FindFirstChild("MapSpec")
	if not module then
		return nil
	end
	return require(module)
end)
if not okMapSpec or type(MapSpec) ~= "table" then
	MapSpec = nil
end
local okVegR5, VegR5 = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapVegetationR5)
end)
if not okVegR5 or type(VegR5) ~= "table" or type(VegR5.pathZones) ~= "function" then
	VegR5 = nil
end
local mapSpecReady = MapSpec ~= nil

local hubOrder = FALLBACK_HUB_ORDER
if mapSpecReady and type(MapSpec.HUB_ORDER) == "table" and #MapSpec.HUB_ORDER > 0 then
	hubOrder = MapSpec.HUB_ORDER
end

local vegR8Folder = folderNamed(HUB_VEG_FOLDER)
local staged = {}
for _, model in ipairs(descendantList(vegR8Folder)) do
	if
		attr(model, "LookDevHubVegR8") == "hubveg_r8"
		and attr(model, "HubVegGroupAnchor") ~= true -- count real instances, not empty group anchors
	then
		staged[#staged + 1] = {
			inst = model,
			hub = attr(model, "Hub"),
			species = attr(model, "Species"),
			centre = bboxCentre(model),
			aabb = bboxAABB(model),
			tree = attr(model, "HubVegTree") == true,
			treeHeight = attr(model, "HubVegTreeHeight"),
			group = attr(model, "HubVegGroup"),
			groupKind = attr(model, "HubVegGroupKind"),
			culmHeight = attr(model, "HubVegCulmHeight"),
		}
	end
end

-- Count staged instances per hub inside HUB_VEG_RADIUS, and their distinct species there.
local hubCounts = {}
local hubSpecies = {}
local hubCentres = {}
for _, key in ipairs(hubOrder) do
	hubCounts[key] = 0
	hubSpecies[key] = {}
	local hub = nil
	if mapSpecReady and type(MapSpec.hub) == "function" then
		local okHub, found = pcall(function()
			return MapSpec.hub(key)
		end)
		if okHub then
			hub = found
		end
	end
	hubCentres[key] = hub
end
for _, entry in ipairs(staged) do
	local key = entry.hub
	if type(key) == "string" and hubCounts[key] ~= nil and entry.centre then
		local hub = hubCentres[key]
		if hub and type(hub.x) == "number" and type(hub.z) == "number" then
			local dx = entry.centre.X - hub.x
			local dz = entry.centre.Z - hub.z
			if dx * dx + dz * dz <= HUB_VEG_RADIUS * HUB_VEG_RADIUS then
				hubCounts[key] = hubCounts[key] + 1
				if type(entry.species) == "string" and entry.species ~= "" then
					hubSpecies[key][entry.species] = true
				end
			end
		end
	end
end

-- VEG_HUB_<hub>: one line per MapSpec.HUB_ORDER key, PASS iff that hub has >= 12 in-radius models.
for _, key in ipairs(hubOrder) do
	local detail = {
		counts = hubCounts,
		radius = HUB_VEG_RADIUS,
		folderPresent = vegR8Folder ~= nil,
		staged = #staged,
	}
	if not mapSpecReady then
		detail.reason = "MapSpec not readable"
	end
	emit(
		"VEG_HUB_" .. key,
		mapSpecReady and hubCounts[key] >= HUB_VEG_MIN_COUNT,
		hubCounts[key],
		">=" .. HUB_VEG_MIN_COUNT,
		detail
	)
end

-- VEG_SPECIES_HUB: weakest hub decides. Never an average; a missing MapSpec/folder gives min=0.
local speciesCounts = {}
local weakest, weakestKey = math.huge, "?"
local speciesParts = {}
for _, key in ipairs(hubOrder) do
	local n = 0
	for _ in pairs(hubSpecies[key]) do
		n += 1
	end
	speciesCounts[key] = n
	speciesParts[#speciesParts + 1] = key .. ":" .. n
	if n < weakest then
		weakest, weakestKey = n, key
	end
end
if weakest == math.huge then
	weakest = 0
end
local speciesDetail = { perHub = speciesCounts, weakest = weakestKey, radius = HUB_VEG_RADIUS }
if not mapSpecReady then
	speciesDetail.reason = "MapSpec not readable"
end
emit(
	"VEG_SPECIES_HUB",
	mapSpecReady and weakest >= HUB_VEG_MIN_SPECIES,
	string.format("min=%d (%s)", weakest, table.concat(speciesParts, " ")),
	">=" .. HUB_VEG_MIN_SPECIES .. " each",
	speciesDetail
)

-- HUB_TREES (section-O item 144, READ-ONLY): at least two staged HubVegTree instances per hub
-- inside HUB_VEG_RADIUS whose recorded height is in [8,12]. Missing tags/height FAIL at measured 0.
local HUB_TREE_MIN, TREE_HEIGHT_MIN, TREE_HEIGHT_MAX = 2, 8, 12
local hubTreeCounts, treeParts = {}, {}
for _, key in ipairs(hubOrder) do
	hubTreeCounts[key] = 0
end
for _, entry in ipairs(staged) do
	local key = entry.hub
	if entry.tree and type(key) == "string" and hubTreeCounts[key] ~= nil and entry.centre then
		local hub = hubCentres[key]
		if
			hub
			and type(hub.x) == "number"
			and type(hub.z) == "number"
			and type(entry.treeHeight) == "number"
			and entry.treeHeight >= TREE_HEIGHT_MIN
			and entry.treeHeight <= TREE_HEIGHT_MAX
		then
			local dx, dz = entry.centre.X - hub.x, entry.centre.Z - hub.z
			if dx * dx + dz * dz <= HUB_VEG_RADIUS * HUB_VEG_RADIUS then
				hubTreeCounts[key] += 1
			end
		end
	end
end
local weakestTrees = math.huge
for _, key in ipairs(hubOrder) do
	weakestTrees = math.min(weakestTrees, hubTreeCounts[key])
	treeParts[#treeParts + 1] = key .. ":" .. hubTreeCounts[key]
end
if weakestTrees == math.huge then
	weakestTrees = 0
end
local treeDetail = { perHub = hubTreeCounts, staged = #staged, folderPresent = vegR8Folder ~= nil }
if not mapSpecReady then
	treeDetail.reason = "MapSpec not readable"
end
emit(
	"HUB_TREES",
	mapSpecReady and vegR8Folder ~= nil and #staged > 0 and weakestTrees >= HUB_TREE_MIN,
	weakestTrees,
	">=" .. HUB_TREE_MIN,
	treeDetail
)

-- VEG_OVERLAP: strict XZ AABB overlap against every building footprint (MapSpec.hubBounds) and
-- every path rectangle (ModelMapVegetationR5.pathZones). Touching edges are NOT an intersection.
-- PASS iff zero offending instances AND the candidate/data were actually readable, so a clean
-- Play with no staged folder emits FAIL at measured 0 instead of a vacuous pass.
local zones = {}
local dataOk = mapSpecReady and VegR5 ~= nil
local dataReason = nil
if not mapSpecReady then
	dataReason = "MapSpec not readable"
elseif VegR5 == nil then
	dataReason = "ModelMapVegetationR5 not readable"
end
if dataOk then
	for _, key in ipairs(hubOrder) do
		local hub = hubCentres[key]
		if hub and type(MapSpec.hubBounds) == "function" then
			local okBounds, b = pcall(function()
				return MapSpec.hubBounds(hub)
			end)
			if
				okBounds
				and type(b) == "table"
				and type(b.minX) == "number"
				and type(b.maxX) == "number"
				and type(b.minZ) == "number"
				and type(b.maxZ) == "number"
			then
				zones[#zones + 1] = {
					name = "hub:" .. key,
					minX = b.minX,
					maxX = b.maxX,
					minZ = b.minZ,
					maxZ = b.maxZ,
				}
			else
				dataOk, dataReason = false, "hubBounds failed:" .. key
			end
		else
			dataOk, dataReason = false, "hub missing:" .. key
		end
	end
end
if dataOk then
	local okPaths, paths = pcall(function()
		return VegR5.pathZones(MapSpec)
	end)
	if okPaths and type(paths) == "table" then
		for _, p in ipairs(paths) do
			if
				type(p.name) == "string"
				and type(p.x) == "number"
				and type(p.z) == "number"
				and type(p.halfX) == "number"
				and type(p.halfZ) == "number"
			then
				zones[#zones + 1] = {
					name = p.name,
					minX = p.x - p.halfX,
					maxX = p.x + p.halfX,
					minZ = p.z - p.halfZ,
					maxZ = p.z + p.halfZ,
				}
			end
		end
	else
		dataOk, dataReason = false, "pathZones not readable"
	end
end
local overlapCount = 0
local unreadable = 0
local offenders = {}
for _, entry in ipairs(staged) do
	if not entry.aabb then
		unreadable += 1
	else
		for _, zone in ipairs(zones) do
			local ox = math.min(entry.aabb.maxX, zone.maxX) - math.max(entry.aabb.minX, zone.minX)
			local oz = math.min(entry.aabb.maxZ, zone.maxZ) - math.max(entry.aabb.minZ, zone.minZ)
			if ox > OVERLAP_TOL and oz > OVERLAP_TOL then
				overlapCount += 1
				if #offenders < 10 then
					offenders[#offenders + 1] = tostring(entry.hub)
						.. "/"
						.. tostring(entry.species)
						.. " vs "
						.. zone.name
				end
				break -- count the instance once, not once per zone
			end
		end
	end
end
emit(
	"VEG_OVERLAP",
	vegR8Folder ~= nil and #staged > 0 and dataOk and #zones > 0 and unreadable == 0 and overlapCount == 0,
	overlapCount,
	0,
	{ zones = #zones, staged = #staged, unreadable = unreadable, offenders = offenders, reason = dataReason }
)

do
-- PATH_REACH (section-O item 144, READ-ONLY). Six-hub-door subset only: for every MapSpec hub a
-- 6-stud lane runs from the documented local +Z facade plane outward 24 studs toward the road.
-- All six hub yaws are multiples of 90 degrees, so the four local corners fold to an exact world
-- AABB; staged veg AABBs are compared against it (Part CFrame+Size corners, transparent ignored).
-- PASS iff all six lanes are clear. No PathfindingService claim: item 105's full 16/16 audit is a
-- separate section-M item. A missing folder / MapSpec / hub geometry FAILs at measured 6.
local PATH_LANE_HALF, PATH_LANE_LENGTH = 3, 24
local function isOpaqueStaged(inst)
	if attr(inst, "Transparent") == true then
		return false
	end
	local candidates = { inst }
	for _, part in ipairs(descendantList(inst)) do
		candidates[#candidates + 1] = part
	end
	for _, part in ipairs(candidates) do
		local okPart, isPart = pcall(function()
			return part:IsA("BasePart")
		end)
		if okPart and isPart then
			local okT, transparency = pcall(function()
				return part.Transparency
			end)
			if okT and type(transparency) == "number" and transparency < 1 then
				return true
			end
		end
	end
	return false
end

local pathLanes = {}
local pathLaneOk = mapSpecReady and vegR8Folder ~= nil and #staged > 0 and type(MapSpec.hubPoint) == "function"
for _, key in ipairs(hubOrder) do
	local hub = hubCentres[key]
	if pathLaneOk and hub and type(hub.depth) == "number" then
		local corners = {
			{ -PATH_LANE_HALF, hub.depth / 2 },
			{ PATH_LANE_HALF, hub.depth / 2 },
			{ -PATH_LANE_HALF, hub.depth / 2 + PATH_LANE_LENGTH },
			{ PATH_LANE_HALF, hub.depth / 2 + PATH_LANE_LENGTH },
		}
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, corner in ipairs(corners) do
			local okPoint, x, z = pcall(function()
				return MapSpec.hubPoint(hub, corner[1], corner[2])
			end)
			if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
				pathLaneOk = false
				break
			end
			minX, maxX = math.min(minX, x), math.max(maxX, x)
			minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
		end
		if pathLaneOk then
			pathLanes[#pathLanes + 1] = {
				hub = key,
				minX = minX,
				maxX = maxX,
				minZ = minZ,
				maxZ = maxZ,
			}
		end
	else
		pathLaneOk = false
	end
end
local blockedLanes, blockedByHub = 0, {}
for _, key in ipairs(hubOrder) do
	blockedByHub[key] = 0
end
if pathLaneOk and #pathLanes == #hubOrder then
	for _, lane in ipairs(pathLanes) do
		for _, entry in ipairs(staged) do
			local box = entry.aabb
			if box and isOpaqueStaged(entry.inst) then
				local ox = math.min(box.maxX, lane.maxX) - math.max(box.minX, lane.minX)
				local oz = math.min(box.maxZ, lane.maxZ) - math.max(box.minZ, lane.minZ)
				if ox > OVERLAP_TOL and oz > OVERLAP_TOL then
					blockedByHub[lane.hub] += 1
					blockedLanes += 1
					break -- one blocked lane counts once
				end
			end
		end
	end
else
	blockedLanes = #hubOrder
end
local pathDetail = { blockedByHub = blockedByHub, lanes = #pathLanes, staged = #staged }
if not pathLaneOk then
	pathDetail.reason = "MapSpec / hubveg folder not readable"
end
emit("PATH_REACH", pathLaneOk and blockedLanes == 0, blockedLanes, 0, pathDetail)

-- BLOCK_TREES / BLOCK_SPECIES / AVATAR_FIT (section-O item 145, all READ-ONLY). They inspect only
-- the staged LookDevBlocksR9_blocks_r9 folder, stage nothing, and FAIL at measured 0/6 when that
-- folder or its tags are missing. AVATAR_FIT reuses PATH_REACH's six local +Z door corridors but
-- checks a 7 x 7.25 x 4 avatar gauge against COLLIDABLE staged block parts. All blocks_r9 parts are
-- non-collidable by construction (see the applier), so a correctly staged candidate measures 0.
-- This is the section-O block subset only: item 106's full 16/16 PathfindingService audit stays a
-- separate item and no such claim is made here. The Studio VM has no Part.GetBoundingBox, so all
-- part boxes are CFrame+Size corner math.
local BLOCKS_FOLDER = "LookDevBlocksR9_blocks_r9"
local blocksFolder = folderNamed(BLOCKS_FOLDER)
local blockInstances, blockTrees, blockSpeciesSeen = {}, {}, {}
for _, inst in ipairs(descendantList(blocksFolder)) do
	if attr(inst, "LookDevBlocksR9") == "blocks_r9" then
		blockInstances[#blockInstances + 1] = inst
		if attr(inst, "BlockTree") == true then
			local height = attr(inst, "BlockTreeHeight")
			if type(height) == "number" and height >= 6 and height <= 12 then
				blockTrees[#blockTrees + 1] = inst
			end
			local species = attr(inst, "BlockSpecies")
			if type(species) == "string" and species ~= "" then
				blockSpeciesSeen[species] = true
			end
		end
	end
end
local blockTreeCount = #blockTrees
local blockSpeciesCount = 0
for _ in pairs(blockSpeciesSeen) do
	blockSpeciesCount += 1
end
emit(
	"BLOCK_TREES",
	blocksFolder ~= nil and blockTreeCount >= 60,
	blockTreeCount,
	60,
	{ folder = blocksFolder ~= nil, staged = #blockInstances, speciesSeen = blockSpeciesCount }
)
emit(
	"BLOCK_SPECIES",
	blocksFolder ~= nil and blockTreeCount > 0 and blockSpeciesCount >= 4,
	blockSpeciesCount,
	4,
	{ folder = blocksFolder ~= nil, trees = blockTreeCount }
)

-- PATH_REACH computes the same lanes but requires the hubveg folder to be staged; rebuild the
-- identical six-lane geometry here so blocks_r9 alone can still be graded.
local avatarLanes = {}
if #pathLanes == #hubOrder then
	avatarLanes = pathLanes
elseif mapSpecReady and type(MapSpec.hubPoint) == "function" then
	for _, key in ipairs(hubOrder) do
		local hub = hubCentres[key]
		if hub and type(hub.depth) == "number" then
			local corners = {
				{ -PATH_LANE_HALF, hub.depth / 2 },
				{ PATH_LANE_HALF, hub.depth / 2 },
				{ -PATH_LANE_HALF, hub.depth / 2 + PATH_LANE_LENGTH },
				{ PATH_LANE_HALF, hub.depth / 2 + PATH_LANE_LENGTH },
			}
			local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
			local okLane = true
			for _, corner in ipairs(corners) do
				local okPoint, x, z = pcall(function()
					return MapSpec.hubPoint(hub, corner[1], corner[2])
				end)
				if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
					okLane = false
					break
				end
				minX, maxX = math.min(minX, x), math.max(maxX, x)
				minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
			end
			if okLane then
				avatarLanes[#avatarLanes + 1] = { hub = key, minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
			end
		end
	end
end

local function partAABB(part)
	local ok, box = pcall(function()
		if not part:IsA("BasePart") then
			return nil
		end
		local cf, size = part.CFrame, part.Size
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local corner = cf * Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2)
					minX, maxX = math.min(minX, corner.X), math.max(maxX, corner.X)
					minY, maxY = math.min(minY, corner.Y), math.max(maxY, corner.Y)
					minZ, maxZ = math.min(minZ, corner.Z), math.max(maxZ, corner.Z)
				end
			end
		end
		return { minX = minX, maxX = maxX, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ }
	end)
	if ok then
		return box
	end
	return nil
end

local avatarGroundY = if mapSpecReady and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
local avatarGaugeWidth, avatarGaugeHeight, avatarGaugeDepth = 7, 7.25, 4
local collidableBoxes, unreadableParts = {}, 0
if blocksFolder and #blockInstances > 0 then
	for _, inst in ipairs(descendantList(blocksFolder)) do
		local okCollide, collides = pcall(function()
			return inst:IsA("BasePart") and inst.CanCollide == true
		end)
		if okCollide and collides then
			local box = partAABB(inst)
			if box then
				collidableBoxes[#collidableBoxes + 1] = box
			else
				unreadableParts += 1
			end
		end
	end
end
local avatarBlocked, avatarErrors = 0, 0
if blocksFolder and #blockInstances > 0 and #avatarLanes == #hubOrder then
	for _, lane in ipairs(avatarLanes) do
		local alongX = lane.maxX - lane.minX > lane.maxZ - lane.minZ
		local start = if alongX then lane.minX else lane.minZ
		local span = if alongX then lane.maxX - lane.minX else lane.maxZ - lane.minZ
		local crossMin = if alongX then lane.minZ else lane.minX
		local crossMax = if alongX then lane.maxZ else lane.maxX
		local crossCentre = (crossMin + crossMax) / 2
		local gauges = math.max(1, math.floor(span / avatarGaugeDepth))
		local hit = false
		for index = 0, gauges - 1 do
			local centre = start + (index + 0.5) * avatarGaugeDepth
			local gauge = if alongX
				then {
					minX = centre - avatarGaugeDepth / 2,
					maxX = centre + avatarGaugeDepth / 2,
					minZ = crossCentre - avatarGaugeWidth / 2,
					maxZ = crossCentre + avatarGaugeWidth / 2,
				}
				else {
					minX = crossCentre - avatarGaugeWidth / 2,
					maxX = crossCentre + avatarGaugeWidth / 2,
					minZ = centre - avatarGaugeDepth / 2,
					maxZ = centre + avatarGaugeDepth / 2,
				}
			gauge.minY, gauge.maxY = avatarGroundY, avatarGroundY + avatarGaugeHeight
			for _, box in ipairs(collidableBoxes) do
				local ox = math.min(box.maxX, gauge.maxX) - math.max(box.minX, gauge.minX)
				local oy = math.min(box.maxY, gauge.maxY) - math.max(box.minY, gauge.minY)
				local oz = math.min(box.maxZ, gauge.maxZ) - math.max(box.minZ, gauge.minZ)
				if ox > OVERLAP_TOL and oy > OVERLAP_TOL and oz > OVERLAP_TOL then
					hit = true
					break
				end
			end
			if hit then
				break
			end
		end
		if hit then
			avatarBlocked += 1
		end
	end
else
	avatarErrors = 1
	avatarBlocked = #hubOrder
end
emit("AVATAR_FIT", avatarErrors == 0 and unreadableParts == 0 and avatarBlocked == 0, avatarBlocked, 0, {
	lanes = #avatarLanes,
	gauge = { avatarGaugeWidth, avatarGaugeHeight, avatarGaugeDepth },
	collidableParts = #collidableBoxes,
	unreadable = unreadableParts,
	reason = if avatarErrors > 0 then "blocks folder / lanes not readable" else nil,
})
end

-- HUB_FIT (section-O item 147, READ-ONLY). Each staged hubs_real_r9 building must sit inside its
-- MapSpec hub footprint grown by HUBS_REAL_MARGIN studs on each side, and every mapped hub must
-- have a staged building. A missing folder / tag / MapSpec / unreadable bbox FAILs at measured 6,
-- never a vacuous pass. The greybox restore is graded separately by LOOKDEV_LEAK (see recipe §18).
do
local HUBS_REAL_FOLDER = "LookDevHubsRealR9_hubs_real_r9"
local HUBS_REAL_MARGIN = 2
local hubsRealFolder = folderNamed(HUBS_REAL_FOLDER)
local hubsRealByHub = {}
local hubsRealCount = {}
local hubsRealOffenders = {}
local hubsRealBad, hubsRealUnreadable = 0, 0
if mapSpecReady and hubsRealFolder and type(MapSpec.hubBounds) == "function" and type(MapSpec.hub) == "function" then
	for _, child in ipairs(descendantList(hubsRealFolder)) do
		local okModel, isModel = pcall(function()
			return child:IsA("Model")
		end)
		if okModel and isModel and attr(child, "HubRealR9") == "hubs_real_r9" then
			local key = attr(child, "HubRealR9Hub")
			if type(key) == "string" then
				hubsRealByHub[key] = hubsRealByHub[key] or {}
				hubsRealCount[key] = (hubsRealCount[key] or 0) + 1
				table.insert(hubsRealByHub[key], child)
				local okHub, hub = pcall(function()
					return MapSpec.hub(key)
				end)
				local box = bboxAABB(child)
				local okBounds, bounds = false, nil
				if okHub and hub then
					okBounds, bounds = pcall(function()
						return MapSpec.hubBounds(hub)
					end)
				end
				if not okHub or not hub or not okBounds or type(bounds) ~= "table" or not box then
					hubsRealUnreadable += 1
					table.insert(hubsRealOffenders, { hub = key, reason = "MapSpec / bbox not readable" })
				elseif
					box.minX < bounds.minX - HUBS_REAL_MARGIN
					or box.maxX > bounds.maxX + HUBS_REAL_MARGIN
					or box.minZ < bounds.minZ - HUBS_REAL_MARGIN
					or box.maxZ > bounds.maxZ + HUBS_REAL_MARGIN
				then
					hubsRealBad += 1
					table.insert(hubsRealOffenders, { hub = key, box = box, bounds = bounds })
				end
			else
				hubsRealBad += 1
				table.insert(hubsRealOffenders, { reason = "missing HubRealR9Hub" })
			end
		end
	end
else
	hubsRealUnreadable = #hubOrder
end
local hubsRealMissing = 0
for _, key in ipairs(hubOrder) do
	if not hubsRealCount[key] or hubsRealCount[key] == 0 then
		hubsRealMissing += 1
	end
end
local hubsRealMeasured = hubsRealBad + hubsRealUnreadable + hubsRealMissing
emit("HUB_FIT", hubsRealMeasured == 0, hubsRealMeasured, 0, {
	perHub = hubsRealCount,
	offenders = hubsRealOffenders,
	missing = hubsRealMissing,
	reason = if hubsRealUnreadable > 0 then "hubs_real_r9 folder / MapSpec / bbox not readable" else nil,
})
end

-- 9c. r8 plots family (WORK_QUEUE item 71). Two CHECK families over the staged
-- LookDevPlotsR8_plots_r8 folder. PLOT_FENCE counts fence segments per plot (min decides, never
-- an average); GATE_CLEAR casts a 6x8x1 overlap box at every gate marker and requires zero
-- CanCollide=true hits. Every game API is pcall-guarded; a missing folder, marker or API is a
-- FAIL, never a skip.
local PLOTS_FOLDER = "LookDevPlotsR8_plots_r8"
local PLOT_COUNT = 10
local FENCE_MIN = 8
local GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH = 6, 8, 1
-- Ground-contact tolerance: a box whose bottom sits exactly on the ground surface still reports
-- the collidable ground slab, so lift the opening box by this much. Target stays 6x8, zero hits.
local GROUND_CONTACT_EPS = 0.05

local plotsFolder = folderNamed(PLOTS_FOLDER)
local plotParts = {}
local okPlotParts, plotDescendants = pcall(function()
	if not plotsFolder then
		return {}
	end
	return plotsFolder:GetDescendants()
end)
if okPlotParts and type(plotDescendants) == "table" then
	for _, part in ipairs(plotDescendants) do
		if attr(part, "LookDevPlotsR8") == "plots_r8" then
			plotParts[#plotParts + 1] = part
		end
	end
end

-- PLOT_FENCE: the weakest plot decides. Count only Kind=="fence" with an in-range numeric
-- PlotIndex; a missing folder gives every plot 0, hence min=0 and a FAIL. fencePartsByPlot is
-- reused by PLOT_FENCE_VISIBLE so both checks measure the exact same rail pieces.
local fenceCounts, fencePartsByPlot = {}, {}
for i = 1, PLOT_COUNT do
	fenceCounts[i] = 0
	fencePartsByPlot[i] = {}
end
for _, part in ipairs(plotParts) do
	if attr(part, "Kind") == "fence" then
		local index = attr(part, "PlotIndex")
		if type(index) == "number" and fenceCounts[index] ~= nil then
			fenceCounts[index] = fenceCounts[index] + 1
			fencePartsByPlot[index][#fencePartsByPlot[index] + 1] = part
		end
	end
end
local fenceMin = math.huge
local fenceParts = {}
for i = 1, PLOT_COUNT do
	fenceParts[#fenceParts + 1] = "P" .. i .. ":" .. fenceCounts[i]
	if fenceCounts[i] < fenceMin then
		fenceMin = fenceCounts[i]
	end
end
if fenceMin == math.huge then
	fenceMin = 0
end
emit(
	"PLOT_FENCE",
	plotsFolder ~= nil and #plotParts > 0 and fenceMin >= FENCE_MIN,
	string.format("min=%d (%s)", fenceMin, table.concat(fenceParts, " ")),
	">=" .. FENCE_MIN .. " each",
	{ counts = fenceCounts, folderPresent = plotsFolder ~= nil, staged = #plotParts }
)

-- GATE_CLEAR: one 6x8x1 overlap box per Kind=="gate_marker", lifted into the opening above ground
-- and oriented by the marker's own CFrame. PASS only with all ten markers present exactly once,
-- no API error and zero CanCollide=true hits. Missing markers, duplicate markers and bad PlotIndex
-- values all become offenders.
local markers = {}
for _, part in ipairs(plotParts) do
	if attr(part, "Kind") == "gate_marker" then
		local index = attr(part, "PlotIndex")
		local okName, name = pcall(function()
			return part.Name
		end)
		markers[#markers + 1] = {
			part = part,
			index = type(index) == "number" and index or nil,
			name = okName and tostring(name) or "?",
		}
	end
end
do
local gateOffenders = {}
local gateErrors = {}
local gateHits = 0
for _, marker in ipairs(markers) do
	local label = marker.index and ("P" .. marker.index) or ("marker:" .. marker.name)
	-- Measure the opening in the marker's OWN frame: its CFrame carries the plot yaw, so the
	-- 6-wide axis spans the gate and the 1-deep axis points through it. CFrame.new(position) would
	-- be world-aligned and reach back into the rotated plot's Base/SignPost. A missing marker
	-- CFrame throws inside the pcall and is recorded as a FAIL for that gate.
	local okCF, cf = pcall(function()
		return marker.part.CFrame * CFrame.new(0, GATE_HEIGHT / 2 + GROUND_CONTACT_EPS, 0)
	end)
	local okParams, params = pcall(function()
		local p = OverlapParams.new()
		p.CollisionGroup = "Default"
		return p
	end)
	local okSize, size = pcall(function()
		return Vector3.new(GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH)
	end)
	local okBox, hits = false, nil
	if okCF and okParams and okSize then
		okBox, hits = pcall(function()
			return workspace:GetPartBoundsInBox(cf, size, params)
		end)
	end
	if not okBox or type(hits) ~= "table" then
		gateErrors[#gateErrors + 1] = label
	else
		for _, hit in ipairs(hits) do
			local okCollide, collide = pcall(function()
				return hit.CanCollide
			end)
			if okCollide and collide == true then
				gateHits += 1
				local okName, hitName = pcall(function()
					return hit.Name
				end)
				gateOffenders[#gateOffenders + 1] = label .. ":" .. (okName and tostring(hitName) or "?")
			end
		end
	end
end
local gateIndexCounts = {}
for i = 1, PLOT_COUNT do
	gateIndexCounts[i] = 0
end
for _, marker in ipairs(markers) do
	if marker.index and gateIndexCounts[marker.index] ~= nil then
		gateIndexCounts[marker.index] += 1
	else
		gateOffenders[#gateOffenders + 1] = "marker:" .. marker.name .. ":bad-index"
	end
end
local missingGates = {}
for i = 1, PLOT_COUNT do
	if gateIndexCounts[i] == 0 then
		missingGates[#missingGates + 1] = "P" .. i
		gateOffenders[#gateOffenders + 1] = "P" .. i .. ":missing-marker"
	elseif gateIndexCounts[i] > 1 then
		gateOffenders[#gateOffenders + 1] = "P" .. i .. ":duplicate-marker"
	end
end
local gateDetail = {
	markers = #markers,
	hits = gateHits,
	box = { GATE_WIDTH, GATE_HEIGHT, GATE_DEPTH },
	offenders = gateOffenders,
	missing = missingGates,
	errors = gateErrors,
	folderPresent = plotsFolder ~= nil,
}
if #gateErrors > 0 then
	gateDetail.reason = "GetPartBoundsInBox/OverlapParams unavailable: " .. table.concat(gateErrors, ",")
end
emit(
	"GATE_CLEAR",
	plotsFolder ~= nil
		and #plotParts > 0
		and #markers == PLOT_COUNT
		and #missingGates == 0
		and #gateErrors == 0
		and gateHits == 0,
	string.format("%d hits/%d gates", gateHits, #markers),
	"0",
	gateDetail
)
end

-- 9c-2. PLOT_FENCE_VISIBLE (WORK_QUEUE item 143). READ-ONLY and SERVER-only: ReviewCameras
-- requires MapSpec from ServerScriptService. For each plot i, use plot_aerial_NN's eye and cast
-- toward the centre of each Kind=="fence" rail. Transparent hits (thin ditch water) are skipped
-- by re-casting with that instance added to the exclude filter; the first hit with
-- Transparency < 0.5 must be the target rail itself (or a descendant of it). Each plot's own
-- Kind=="fence_post" parts are excluded: the ray to a rail centre passes through the fence's
-- 3-stud posts standing along that same rail, which is self-occlusion of the assembly, not an
-- obstruction. Terrain, trees, buildings and other world geometry still count as opaque blockers.
-- A missing camera, staging folder, ray, unreadable transparency or zero segments is a FAIL at
-- measured 0.
do
local PLOT_FENCE_VISIBLE_MIN = 70
local visibleRun = service("RunService")
local visibleServer = false
if visibleRun then
	local okServer, flag = pcall(function()
		return visibleRun:IsServer()
	end)
	if okServer then
		visibleServer = flag
	end
end

local visibleCams = nil
local visibleReason = nil
if not visibleServer then
	visibleReason = "ReviewCameras requires the Server VM"
elseif not plotsFolder then
	visibleReason = "plots_r8 staging folder absent"
elseif #plotParts == 0 then
	visibleReason = "no tagged plots_r8 Parts staged"
else
	local okCams, loaded = pcall(function()
		return require(game.ReplicatedStorage.Shared.ReviewCameras)
	end)
	if not okCams or type(loaded) ~= "table" or type(loaded.get) ~= "function" then
		visibleReason = "ReviewCameras not readable"
	else
		visibleCams = loaded
	end
end

local visiblePcts, visibleDetail = {}, {}
local visibleSummary = {}
local visiblePercent = 0
local visibleOk = false
local visibleErrors = 0

if visibleCams then
	for i = 1, PLOT_COUNT do
		local label = "P" .. i
		local segments = fencePartsByPlot[i]
		local total = #segments
		local seen, reason = 0, nil
		local cameraName = "plot_aerial_" .. string.format("%02d", i)
		local eye = nil
		local okCam, camera = pcall(function()
			return visibleCams.get(cameraName)
		end)
		if not okCam or type(camera) ~= "table" then
			reason = "camera missing"
		else
			eye = asVector3(camera.position)
			if not eye then
				reason = "camera coords unreadable"
			end
		end

		if not reason and total == 0 then
			reason = "zero fence segments"
		end

		if not reason then
			local ignore = {}
			local okPlayers, players = pcall(function()
				local Players = service("Players")
				return Players and Players:GetPlayers() or {}
			end)
			if okPlayers and type(players) == "table" then
				for _, player in ipairs(players) do
					local okCharacter, character = pcall(function()
						return player.Character
					end)
					if okCharacter and character then
						ignore[#ignore + 1] = character
					end
				end
			end
			-- Exclude this plot's own posts: the aerial ray to a rail centre crosses the
			-- fence assembly's 3-stud posts standing along that same rail. That is self-occlusion,
			-- not an obstruction; terrain, trees, buildings and other world geometry still count.
			for _, part in ipairs(plotParts) do
				if attr(part, "Kind") == "fence_post" and attr(part, "PlotIndex") == i then
					ignore[#ignore + 1] = part
				end
			end

			for _, segment in ipairs(segments) do
				local centre = bboxCentre(segment)
				if not centre then
					visibleErrors += 1 -- unreadable target is not visible, never a free pass
					if #visibleDetail < 10 then
						visibleDetail[#visibleDetail + 1] = label .. ":unreadable-segment"
					end
				else
					local delta = centre - eye
					if delta.Magnitude <= 0 then
						visibleErrors += 1
					else
						local hitInst = nil
						-- Raycast returns only the nearest hit: peel transparent hits off the
						-- filter until an opaque one (or nothing) remains. Bounded to stop a
						-- broken filter from looping forever.
						for _ = 1, 16 do
							local okParams, params = pcall(function()
								local p = RaycastParams.new()
								p.FilterType = Enum.RaycastFilterType.Exclude
								p.FilterDescendantsInstances = ignore
								return p
							end)
							if not okParams or not params then
								visibleErrors += 1
								break
							end
							local okRay, hit = pcall(function()
								return workspace:Raycast(eye, delta, params)
							end)
							if not okRay then
								visibleErrors += 1
								break
							end
							if not hit then
								break
							end
							if not hit.Instance then
								visibleErrors += 1
								break
							end
							local okTrans, transparency = pcall(function()
								if hit.Instance:IsA("BasePart") then
									return hit.Instance.Transparency
								end
								return 0
							end)
							if not okTrans or type(transparency) ~= "number" then
								visibleErrors += 1
								break
							end
							if transparency < 0.5 then
								hitInst = hit.Instance
								break
							end
							ignore[#ignore + 1] = hit.Instance
						end
						if hitInst then
							local okRel, related = pcall(function()
								return hitInst == segment or hitInst:IsDescendantOf(segment)
							end)
							if okRel and related then
								seen += 1
							elseif #visibleDetail < 10 then
								local okName, name = pcall(function()
									return hitInst.Name
								end)
								visibleDetail[#visibleDetail + 1] = label
									.. ":blocked-by:"
									.. (okName and tostring(name) or "?")
							end
						end
					end
				end
			end
		end

		local pct = reason and 0 or (total > 0 and math.floor(seen * 100 / total) or 0)
		visiblePcts[i] = pct
		visibleSummary[#visibleSummary + 1] = label .. ":" .. pct .. "%"
		if reason and #visibleDetail < 10 then
			visibleDetail[#visibleDetail + 1] = label .. ":" .. reason
		end
	end
end

if visibleCams then
	visiblePercent = 100
	for i = 1, PLOT_COUNT do
		visiblePercent = math.min(visiblePercent, visiblePcts[i] or 0)
	end
	visibleOk = visibleErrors == 0 and visiblePercent >= PLOT_FENCE_VISIBLE_MIN
else
	visiblePercent = 0
end

emit("PLOT_FENCE_VISIBLE", visibleOk, visiblePercent, ">=" .. PLOT_FENCE_VISIBLE_MIN, {
	method = "plot_aerial_NN eye -> each Kind=='fence' centre; first opaque hit must be that rail; own fence_post parts excluded as self-occlusion",
	perPlot = visiblePcts,
	summary = table.concat(visibleSummary, " "),
	rayErrors = visibleErrors,
	camera = "plot_aerial_01..10",
	reasons = visibleDetail,
	reason = visibleReason,
})
end

-- 9d. r8 sawah family (WORK_QUEUE item 72). Four CHECK families over the staged
-- LookDevSawahR8_sawah_r8 folder: SAWAH_TOPS (Terrain-only raycasts at the eight
-- MapSpec.paddyWater pane centres), SAWAH_WATER (four water_sheet groups of two valid panes),
-- SAWAH_VERGE (>=40 verge tufts) and GUBUK (one terrace-2 roof with four posts + one bench
-- sharing its Gubuk id). Every game API is pcall-guarded; a missing folder, MapSpec, Terrain or
-- failed read is a FAIL, never a skip.
do
local SAWAH_FOLDER = "LookDevSawahR8_sawah_r8"
local SAWAH_KEY = "sawah_r8"
local SAWAH_TOP_TOL = 0.5
local WATER_ALPHA = 0.55
local WATER_ALPHA_TOL = 0.02
local WATER_BAND_TOL = 0.5

local sawahFolder = folderNamed(SAWAH_FOLDER)
local sawahParts = {}
local okSawahParts, sawahDescendants = pcall(function()
	if not sawahFolder then
		return {}
	end
	return sawahFolder:GetDescendants()
end)
if okSawahParts and type(sawahDescendants) == "table" then
	for _, part in ipairs(sawahDescendants) do
		if attr(part, "LookDevSawahR8") == SAWAH_KEY then
			sawahParts[#sawahParts + 1] = part
		end
	end
end

-- MapSpec lives under ServerScriptService.Server.World. FindFirstChild (not WaitForChild) so the
-- Client VM cannot block; require is cached from the item-70 family. A failed load fails both
-- MapSpec-dependent checks with a reason instead of emitting a vacuous pass.
local sawahMapReady = false
local SawahMapSpec = nil
local okSawahMap, loadedSawahMap = pcall(function()
	local sss = game:GetService("ServerScriptService")
	local server = sss and sss:FindFirstChild("Server")
	if not server then
		return nil
	end
	local world = server:FindFirstChild("World")
	if not world then
		return nil
	end
	local module = world:FindFirstChild("MapSpec")
	if not module then
		return nil
	end
	return require(module)
end)
if
	okSawahMap
	and type(loadedSawahMap) == "table"
	and type(loadedSawahMap.TERRACES) == "table"
	and type(loadedSawahMap.TERRACE_SIDES) == "table"
	and type(loadedSawahMap.paddyWater) == "function"
then
	sawahMapReady = true
	SawahMapSpec = loadedSawahMap
end
local sawahMapReason = sawahMapReady and nil or "MapSpec not readable"

-- SAWAH_TOPS: terrain only. Raycast at each of the eight paddyWater pane centres and compare the
-- Terrain hit to that pane's terrace top. Panes come in terrace order, two per terrace, so pane i
-- belongs to terrace floor((i-1)/2)+1. A missing Terrain or failed ray sets worst = 999 and FAILs.
local topFailed = {}
local topWorst = 0
local topSamples = 0
if sawahMapReady then
	local okPanes, panes = pcall(function()
		return SawahMapSpec.paddyWater()
	end)
	if not okPanes or type(panes) ~= "table" or #panes == 0 then
		sawahMapReady = false
		sawahMapReason = "paddyWater not readable"
	end
	if sawahMapReady then
		for index, pane in ipairs(panes) do
			topSamples += 1
			local label = "pane:" .. index
			local terrace = SawahMapSpec.TERRACES[math.floor((index - 1) / 2) + 1]
			local x = type(pane) == "table" and type(pane.centre) == "table" and pane.centre[1] or nil
			local z = type(pane) == "table" and type(pane.centre) == "table" and pane.centre[3] or nil
			if
				type(x) ~= "number"
				or type(z) ~= "number"
				or type(terrace) ~= "table"
				or type(terrace.top) ~= "number"
			then
				topFailed[#topFailed + 1] = label .. ":bad-spec"
				topWorst = 999
			else
				local y = terrainSurfaceY(x, z)
				if type(y) ~= "number" then
					topFailed[#topFailed + 1] = label .. ":no-terrain-read"
					topWorst = 999
				else
					local diff = math.abs(y - terrace.top)
					topWorst = math.max(topWorst, diff)
					if diff > SAWAH_TOP_TOL then
						topFailed[#topFailed + 1] =
							string.format("%s:y=%.2f want=%.2f d=%.2f", label, y, terrace.top, diff)
					end
				end
			end
		end
	end
end
local topDetail = {
	samples = topSamples,
	terrainOnly = true,
	tolerance = SAWAH_TOP_TOL,
	failed = topFailed,
}
if not sawahMapReady then
	topDetail.reason = sawahMapReason
end
emit(
	"SAWAH_TOPS",
	sawahMapReady and topSamples == 8 and #topFailed == 0,
	sawahMapReady and math.floor(topWorst * 100) / 100 or 999,
	SAWAH_TOP_TOL,
	topDetail
)

-- SAWAH_WATER: collect water_sheet groups by Terrace, then validate the two water_pane children of
-- the one sheet on each of terraces 1..4. A pane needs Transparency ~0.55, a green-brown tint far
-- from pure blue, and a centre inside that terrace's z band and one of MapSpec.TERRACE_SIDES.
local sheetsByTerrace = {}
for _, part in ipairs(sawahParts) do
	if attr(part, "Kind") == "water_sheet" then
		local terrace = attr(part, "Terrace")
		if type(terrace) == "number" then
			sheetsByTerrace[terrace] = sheetsByTerrace[terrace] or {}
			sheetsByTerrace[terrace][#sheetsByTerrace[terrace] + 1] = part
		end
	end
end

local function sawahPaneStatus(pane, terrace, sides)
	local info = {}
	local okTrans, transparency = pcall(function()
		return pane.Transparency
	end)
	if not okTrans or type(transparency) ~= "number" then
		info.error = "transparency-read"
		return false, info
	end
	info.transparency = math.floor(transparency * 1000) / 1000
	local okColour, colour = pcall(function()
		return pane.Color
	end)
	local r, g, b = -1, -1, -1
	if okColour and typeof(colour) == "Color3" then
		r, g, b = colour.R, colour.G, colour.B
	end
	info.colour = { math.floor(r * 100) / 100, math.floor(g * 100) / 100, math.floor(b * 100) / 100 }
	local distBlue = math.sqrt(r * r + g * g + (b - 1) * (b - 1))
	info.distBlue = math.floor(distBlue * 100) / 100
	local okPos, pos = pcall(function()
		return pane.CFrame.Position
	end)
	if not okPos or typeof(pos) ~= "Vector3" then
		info.error = "cframe-read"
		return false, info
	end
	info.position = { math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100 }
	local alphaOk = math.abs(transparency - WATER_ALPHA) <= WATER_ALPHA_TOL
	local colourOk = r > 0.05 and g > 0.05 and b < math.max(r, g) and distBlue > 0.5
	local zOk = type(terrace) == "table"
		and type(terrace.z0) == "number"
		and type(terrace.z1) == "number"
		and pos.Z >= terrace.z0 - WATER_BAND_TOL
		and pos.Z <= terrace.z1 + WATER_BAND_TOL
	local xOk = false
	for _, side in ipairs(sides) do
		if
			type(side.x0) == "number"
			and type(side.x1) == "number"
			and pos.X >= side.x0 - WATER_BAND_TOL
			and pos.X <= side.x1 + WATER_BAND_TOL
		then
			xOk = true
			break
		end
	end
	if not (alphaOk and colourOk and zOk and xOk) then
		info.reasons = {}
		if not alphaOk then
			info.reasons[#info.reasons + 1] = "transparency"
		end
		if not colourOk then
			info.reasons[#info.reasons + 1] = "colour"
		end
		if not zOk then
			info.reasons[#info.reasons + 1] = "z-band"
		end
		if not xOk then
			info.reasons[#info.reasons + 1] = "x-band"
		end
	end
	return alphaOk and colourOk and zOk and xOk, info
end

local waterDetail = { sheets = {}, failures = {} }
local validSheets = 0
if sawahMapReady then
	for terraceIndex = 1, 4 do
		local terrace = SawahMapSpec.TERRACES[terraceIndex]
		local group = sheetsByTerrace[terraceIndex] or {}
		local entry = { sheets = #group, panes = {}, paneInfo = {} }
		if #group ~= 1 then
			entry.reason = "expected 1 sheet, got " .. #group
			waterDetail.failures[#waterDetail.failures + 1] = "T" .. terraceIndex .. ":" .. entry.reason
		else
			local panes = {}
			for _, child in ipairs(childList(group[1])) do
				if attr(child, "LookDevSawahR8") == SAWAH_KEY and attr(child, "Kind") == "water_pane" then
					panes[#panes + 1] = child
				end
			end
			entry.panes = #panes
			if #panes ~= 2 then
				entry.reason = "expected 2 panes, got " .. #panes
				waterDetail.failures[#waterDetail.failures + 1] = "T" .. terraceIndex .. ":" .. entry.reason
			else
				local panesOk = true
				for paneIndex, pane in ipairs(panes) do
					local paneOk, info = sawahPaneStatus(pane, terrace, SawahMapSpec.TERRACE_SIDES)
					entry.paneInfo[paneIndex] = info
					if not paneOk then
						panesOk = false
						local reason = info.reasons and table.concat(info.reasons, ",") or (info.error or "invalid")
						waterDetail.failures[#waterDetail.failures + 1] = "T"
							.. terraceIndex
							.. ":pane"
							.. paneIndex
							.. ":"
							.. reason
					end
				end
				entry.ok = panesOk
				if panesOk then
					validSheets += 1
				end
			end
		end
		waterDetail.sheets[terraceIndex] = entry
	end
else
	waterDetail.reason = sawahMapReason
end
emit("SAWAH_WATER", sawahMapReady and validSheets == 4, validSheets, "4 sheets", waterDetail)

-- SAWAH_VERGE: count every staged verge tuft and break the count down by terrace. Missing folder
-- yields 0 and a FAIL, never a vacuous pass.
local vergeByTerrace = {}
local vergeCount = 0
for _, part in ipairs(sawahParts) do
	if attr(part, "Kind") == "verge" then
		vergeCount += 1
		local terrace = attr(part, "Terrace")
		local key = type(terrace) == "number" and ("T" .. terrace) or "none"
		vergeByTerrace[key] = (vergeByTerrace[key] or 0) + 1
	end
end
emit("SAWAH_VERGE", vergeCount >= 40, vergeCount, ">=40", {
	perTerrace = vergeByTerrace,
	staged = #sawahParts,
	folderPresent = sawahFolder ~= nil,
})

-- GUBUK: exactly one roof, on terrace 2, with four posts and one bench carrying the same Gubuk id.
-- Measured is the roof count, so no candidate gives 0/FAIL and a wrong structure still gives 1/FAIL.
local roofs, posts, benches = {}, {}, {}
for _, part in ipairs(sawahParts) do
	local kind = attr(part, "Kind")
	local entry = { part = part, terrace = attr(part, "Terrace"), id = attr(part, "Gubuk") }
	if kind == "gubuk_roof" then
		roofs[#roofs + 1] = entry
	elseif kind == "gubuk_post" then
		posts[#posts + 1] = entry
	elseif kind == "gubuk_bench" then
		benches[#benches + 1] = entry
	end
end
local gubukPass = false
local gubukReason = nil
local matchedPosts, matchedBenches = 0, 0
local roofTerrace, roofId = nil, nil
if #roofs == 1 then
	roofTerrace = roofs[1].terrace
	roofId = roofs[1].id
	if roofTerrace == 2 and roofId ~= nil and roofId ~= "" then
		for _, post in ipairs(posts) do
			if post.id == roofId then
				matchedPosts += 1
			end
		end
		for _, bench in ipairs(benches) do
			if bench.id == roofId then
				matchedBenches += 1
			end
		end
		gubukPass = matchedPosts == 4 and matchedBenches == 1
		if not gubukPass then
			gubukReason = "members " .. matchedPosts .. "p/" .. matchedBenches .. "b"
		end
	else
		gubukReason = "bad roof terrace/id"
	end
elseif #roofs == 0 then
	gubukReason = "no roof"
else
	gubukReason = "multiple roofs"
end
emit("GUBUK", gubukPass, #roofs, 1, {
	roofs = #roofs,
	terrace = roofTerrace,
	gubukId = roofId,
	posts = #posts,
	benches = #benches,
	matchedPosts = matchedPosts,
	matchedBenches = matchedBenches,
	folderPresent = sawahFolder ~= nil,
	reason = gubukReason,
})

-- 9d-2. WORK_QUEUE section O item 140: four READ-ONLY checks on the new padi dressing. The caller
-- stages sawah_r8 exactly as for SAWAH_TOPS; nothing here enables, disables or mutates anything.
-- Method notes:
--   TUFT_SHAPE  every instance with PadiPart == true has all three Size axes <= 2.5.
--   PADI_ROWS   a row is one X column of clumps; each clump's numeric PadiRow is its row id. The
--               MINIMUM count of distinct PadiRow ids over terraces 1..4 decides.
--   PADI_CLUMPS a clump is a Model with a numeric PadiClump id, shared by its blade Parts. The
--               MINIMUM count of distinct PadiClump ids over terraces 1..4 decides, so 3-5 blades
--               cannot inflate the count.
--   SAWAH_GREEN for each terrace, a 20 x 8 grid (10 X columns per water pane x 8 Z rows) is sampled
--               inside the two panes. From the sawah_above ReviewCamera eye, one ray is cast per
--               sample toward the sample point (all samples are below the eye); the ray uses an
--               Include filter on the staged sawah folder and PASSES only when the first hit is a
--               PadiPart. The MINIMUM integer percentage over terraces 1..4 decides. Missing
--               camera, MapSpec, folder, RaycastParams or Raycast, or any ray error, is a FAIL with
--               a reason in the detail — never a skip and never a vacuous pass.
local PADI_MAX_PART = 2.5
local GREEN_COLUMNS_PER_PANE, GREEN_ROWS = 10, 8
local TUFT_SHAPE_TOTAL = 0
local PADI_ROWS_TOTAL = 10
local PADI_CLUMPS_TOTAL = 250
local SAWAH_GREEN_TOTAL = 40

local padiParts = {}
local shapeOffenders, shapeErrors = {}, 0
for _, part in ipairs(sawahParts) do
	if attr(part, "PadiPart") == true then
		padiParts[#padiParts + 1] = part
		-- The clump Model carries PadiPart for grouping but has no Size property; only BaseParts
		-- (the blades and bund tufts) are measured by TUFT_SHAPE.
		local okPart, isPart = pcall(function()
			return part:IsA("BasePart")
		end)
		if not okPart then
			shapeErrors += 1
		elseif isPart then
			local okSize, size = pcall(function()
				return part.Size
			end)
			if not okSize or typeof(size) ~= "Vector3" then
				shapeErrors += 1
			elseif size.X > PADI_MAX_PART or size.Y > PADI_MAX_PART or size.Z > PADI_MAX_PART then
				local okName, name = pcall(function()
					return part.Name
				end)
				shapeOffenders[#shapeOffenders + 1] = (okName and tostring(name) or "?")
					.. ":"
					.. string.format("%.2f/%.2f/%.2f", size.X, size.Y, size.Z)
			end
		end
	end
end
local shapeDetail = {
	method = "all PadiPart instances: Size.X/Y/Z <= 2.5",
	padiParts = #padiParts,
	readErrors = shapeErrors,
	sample = shapeOffenders,
	folderPresent = sawahFolder ~= nil,
}
if #padiParts == 0 then
	shapeDetail.reason = "sawah_r8 folder or PadiPart parts absent"
end
local tuftShapePass = sawahFolder ~= nil and #padiParts > 0 and shapeErrors == 0 and #shapeOffenders == 0
emit("TUFT_SHAPE", tuftShapePass, #shapeOffenders, 0, shapeDetail)

local rowsByTerrace, clumpsByTerrace = {}, {}
for terrace = 1, 4 do
	rowsByTerrace[terrace] = {}
	clumpsByTerrace[terrace] = {}
end
for _, part in ipairs(padiParts) do
	local terrace = attr(part, "TerraceIndex")
	local row = attr(part, "PadiRow")
	local clump = attr(part, "PadiClump")
	if type(terrace) == "number" and rowsByTerrace[terrace] then
		if type(row) == "number" then
			rowsByTerrace[terrace][row] = true
		end
		if type(clump) == "number" then
			clumpsByTerrace[terrace][clump] = true
		end
	end
end
local function distinctCount(set)
	local n = 0
	for _ in pairs(set) do
		n += 1
	end
	return n
end
local rowCounts, clumpCounts, rowParts, clumpParts = {}, {}, {}, {}
local minRows, minClumps = math.huge, math.huge
for terrace = 1, 4 do
	rowCounts[terrace] = distinctCount(rowsByTerrace[terrace])
	clumpCounts[terrace] = distinctCount(clumpsByTerrace[terrace])
	rowParts[#rowParts + 1] = "T" .. terrace .. ":" .. rowCounts[terrace]
	clumpParts[#clumpParts + 1] = "T" .. terrace .. ":" .. clumpCounts[terrace]
	minRows = math.min(minRows, rowCounts[terrace])
	minClumps = math.min(minClumps, clumpCounts[terrace])
end
if minRows == math.huge then
	minRows = 0
end
if minClumps == math.huge then
	minClumps = 0
end
emit("PADI_ROWS", minRows >= PADI_ROWS_TOTAL, minRows, 10, {
	method = "MINIMUM distinct numeric PadiRow ids per terrace (one X column of clumps per row)",
	perTerrace = rowCounts,
	detail = table.concat(rowParts, " "),
	padiParts = #padiParts,
})
emit("PADI_CLUMPS", minClumps >= PADI_CLUMPS_TOTAL, minClumps, 250, {
	method = "MINIMUM distinct numeric PadiClump ids per terrace (shared by that clump's blades)",
	perTerrace = clumpCounts,
	detail = table.concat(clumpParts, " "),
	padiParts = #padiParts,
})

-- SAWAH_GREEN: camera + Raycast are mandatory. The Client VM cannot require ReviewCameras (it
-- requires MapSpec from ServerScriptService with WaitForChild), so it records a FAIL reason here.
local greenServer = false
local greenRun = service("RunService")
if greenRun then
	local okServer, flag = pcall(function()
		return greenRun:IsServer()
	end)
	if okServer then
		greenServer = flag
	end
end
local greenEye = nil
local greenReason = nil
if not greenServer then
	greenReason = "ReviewCameras / sawah_above camera unavailable (Server VM required)"
elseif not sawahMapReady then
	greenReason = sawahMapReason or "MapSpec not readable"
elseif not sawahFolder then
	greenReason = "sawah_r8 staging folder absent"
elseif #padiParts == 0 then
	greenReason = "no PadiPart parts staged"
else
	local okGreenCam, Cameras = pcall(function()
		return require(game.ReplicatedStorage.Shared.ReviewCameras)
	end)
	if not okGreenCam or type(Cameras) ~= "table" or type(Cameras.all) ~= "function" then
		greenReason = "ReviewCameras not readable"
	else
		for _, camera in ipairs(Cameras.all()) do
			if camera.name == "sawah_above" then
				greenEye = asVector3(camera.position)
				break
			end
		end
		if not greenEye then
			greenReason = "sawah_above camera missing or bad coords"
		end
	end
end

local greenPcts, greenSamples, greenHits, greenErrors = {}, {}, {}, 0
local greenOk = false
if greenEye and sawahMapReady and sawahFolder then
	local okPanes, greenPanes = pcall(function()
		return SawahMapSpec.paddyWater()
	end)
	local okParams, params = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Include
		p.FilterDescendantsInstances = { sawahFolder }
		p.IgnoreWater = false
		return p
	end)
	if not okPanes or type(greenPanes) ~= "table" or #greenPanes < 8 then
		greenReason = "paddyWater panes not readable"
	elseif not okParams or not params then
		greenReason = "RaycastParams unavailable"
	else
		for terrace = 1, 4 do
			local pair = { greenPanes[(terrace - 1) * 2 + 1], greenPanes[terrace * 2] }
			local hits, samples = 0, 0
			for _, pane in ipairs(pair) do
				if
					type(pane) == "table"
					and type(pane.centre) == "table"
					and type(pane.size) == "table"
					and type(pane.top) == "number"
				then
					local x0 = pane.centre[1] - pane.size[1] / 2
					local z0 = pane.centre[3] - pane.size[3] / 2
					for column = 1, GREEN_COLUMNS_PER_PANE do
						local x = x0 + (column - 0.5) * pane.size[1] / GREEN_COLUMNS_PER_PANE
						for row = 1, GREEN_ROWS do
							local z = z0 + (row - 0.5) * pane.size[3] / GREEN_ROWS
							local sample = Vector3.new(x, pane.top + 0.2, z)
							local delta = sample - greenEye
							samples += 1
							local okRay, hit = pcall(function()
								return workspace:Raycast(greenEye, delta.Unit * (delta.Magnitude + 2), params)
							end)
							if not okRay then
								greenErrors += 1
							elseif hit and hit.Instance and attr(hit.Instance, "PadiPart") == true then
								hits += 1
							end
						end
					end
				end
			end
			greenSamples[terrace] = samples
			greenHits[terrace] = hits
			greenPcts[terrace] = samples > 0 and math.floor(hits * 100 / samples) or 0
		end
		greenOk = greenErrors == 0
			and greenSamples[1] > 0
			and greenSamples[2] > 0
			and greenSamples[3] > 0
			and greenSamples[4] > 0
	end
elseif not greenReason then
	greenReason = "camera, MapSpec or folder unavailable"
end

local greenWorst = 100
for terrace = 1, 4 do
	greenWorst = math.min(greenWorst, greenPcts[terrace] or 0)
end
if not greenOk then
	greenWorst = 0
end
local greenDetail = {
	method = "20x8 grid per terrace (10 X columns per pane x 8 Z rows), sawah_above eye, downward rays, Include sawah folder, first hit PadiPart",
	perTerrace = greenPcts,
	hits = greenHits,
	samples = greenSamples,
	rayErrors = greenErrors,
	camera = greenEye and { greenEye.X, greenEye.Y, greenEye.Z } or nil,
	grid = { GREEN_COLUMNS_PER_PANE * 2, GREEN_ROWS },
	padiParts = #padiParts,
	folderPresent = sawahFolder ~= nil,
	reason = greenReason,
}
emit("SAWAH_GREEN", greenOk and greenWorst >= SAWAH_GREEN_TOTAL, greenWorst, 40, greenDetail)
end

-- 9e. r8 river family (WORK_QUEUE item 73, redone in item 141). Five CHECK families over the staged
-- LookDevRiverR8_river_r8 folder, all read around MapSpec.BRIDGE (bridge centre + deck span):
--   RIVER_BANK_VEG   >=40 bank_veg within 40 studs (XZ) of the bridge centre, both banks present
--   BANK_PLANT_SHAPE every BankPlant base Part >=0.8 studs in X/Z and >=1.5 studs tall (0 offenders)
--   RIVER_ROCKS     >=12 BankRock Parts within 40 studs of the bridge, each axis 1..4 studs
--   BRIDGE_RAILS    each side has a rail spanning the deck and >=4 posts
--   BRIDGE_WALKABLE no rail/post intrudes into the |x|<4 deck corridor, both sides present
-- BANK_PLANT_SHAPE and RIVER_ROCKS are READ-ONLY (stage nothing). A missing folder / part /
-- attribute / MapSpec or a failed read is a FAIL, never a vacuous pass. No GetBoundingBox on Part
-- is used: plant/rock geometry is read from each Part's own CFrame + Size.
-- MapSpec lives under ServerScriptService.Server.World; the require is pcall-guarded and the
-- Client VM cannot read it. Every game API read below is pcall-wrapped.
do
local RIVER_FOLDER = "LookDevRiverR8_river_r8"
local RIVER_KEY = "river_r8"
local RIVER_BANK_VEG_RADIUS = 40
local RIVER_BANK_VEG_MIN = 40
local BANK_PLANT_MIN_WIDTH = 0.8
local BANK_PLANT_MIN_HEIGHT = 1.5
local RIVER_ROCK_MIN = 12
local RIVER_ROCK_MIN_SIZE = 1
local RIVER_ROCK_MAX_SIZE = 4
local RAIL_SPAN_TOL = 4
local POSTS_PER_SIDE_MIN = 4
local WALK_CLEAR_MIN = 4
local WALK_WIDTH_MIN = 8

local riverFolder = folderNamed(RIVER_FOLDER)
local riverParts = {}
local okRiverParts, riverDescendants = pcall(function()
	if not riverFolder then
		return {}
	end
	return riverFolder:GetDescendants()
end)
if okRiverParts and type(riverDescendants) == "table" then
	for _, part in ipairs(riverDescendants) do
		if attr(part, "LookDevRiverR8") == RIVER_KEY then
			riverParts[#riverParts + 1] = part
		end
	end
end

-- MapSpec.BRIDGE supplies the bridge centre (x, (z0+z1)/2) and the deck span [z0,z1]. A failed
-- load fails all three checks with a reason instead of emitting a vacuous pass.
local riverMapReady = false
local bridge = nil
local riverMapReason = nil
local okRiverMap, loadedRiverMap = pcall(function()
	local sss = game:GetService("ServerScriptService")
	local server = sss and sss:FindFirstChild("Server")
	if not server then
		return nil
	end
	local world = server:FindFirstChild("World")
	if not world then
		return nil
	end
	local module = world:FindFirstChild("MapSpec")
	if not module then
		return nil
	end
	return require(module)
end)
if
	okRiverMap
	and type(loadedRiverMap) == "table"
	and type(loadedRiverMap.BRIDGE) == "table"
	and type(loadedRiverMap.BRIDGE.x) == "number"
	and type(loadedRiverMap.BRIDGE.z0) == "number"
	and type(loadedRiverMap.BRIDGE.z1) == "number"
then
	riverMapReady = true
	bridge = loadedRiverMap.BRIDGE
else
	riverMapReason = "MapSpec.BRIDGE not readable"
end
local bridgeCX = riverMapReady and bridge.x or 0
local bridgeCZ = riverMapReady and (bridge.z0 + bridge.z1) / 2 or 0

-- RIVER_BANK_VEG: numeric VegX/VegZ, falling back to part.Position, then distance in the XZ
-- plane. South/north counts are taken over the in-radius veg, so one bank alone cannot pass.
local vegTotal, vegNear, vegSouth, vegNorth = 0, 0, 0, 0
for _, part in ipairs(riverParts) do
	if attr(part, "Kind") == "bank_veg" then
		vegTotal += 1
		local vx, vz = attr(part, "VegX"), attr(part, "VegZ")
		if type(vx) ~= "number" or type(vz) ~= "number" then
			local okPos, pos = pcall(function()
				return part.Position
			end)
			if okPos and typeof(pos) == "Vector3" then
				vx, vz = pos.X, pos.Z
			end
		end
		if type(vx) == "number" and type(vz) == "number" then
			local dx, dz = vx - bridgeCX, vz - bridgeCZ
			if dx * dx + dz * dz <= RIVER_BANK_VEG_RADIUS * RIVER_BANK_VEG_RADIUS then
				vegNear += 1
				local side = attr(part, "Side")
				if side == "south" then
					vegSouth += 1
				elseif side == "north" then
					vegNorth += 1
				end
			end
		end
	end
end
local vegDetail = {
	near = riverMapReady and vegNear or 0,
	south = vegSouth,
	north = vegNorth,
	totalVeg = vegTotal,
	staged = #riverParts,
	radius = RIVER_BANK_VEG_RADIUS,
	centre = riverMapReady and { bridgeCX, bridgeCZ } or nil,
	folderPresent = riverFolder ~= nil,
}
if not riverMapReady then
	vegDetail.reason = riverMapReason
end
emit(
	"RIVER_BANK_VEG",
	riverMapReady and vegNear >= RIVER_BANK_VEG_MIN and vegSouth >= 1 and vegNorth >= 1,
	riverMapReady and vegNear or 0,
	">=" .. RIVER_BANK_VEG_MIN,
	vegDetail
)

-- BANK_PLANT_SHAPE (WORK_QUEUE item 141). READ-ONLY: no candidate is enabled/staged here. Every
-- BankPlant base Part must be >=0.8 studs in both horizontal Size axes and >=1.5 studs tall.
-- A missing folder or zero tagged plants FAILs (never a vacuous pass); a failed Size/IsA read is an
-- offender, not a skip. Part.Size is read directly — no GetBoundingBox on Part in this environment.
local plantTotal, plantOffenders, plantReadErrors = 0, 0, 0
local plantOffenderList = {}
for _, part in ipairs(riverParts) do
	if attr(part, "BankPlant") == true then
		plantTotal += 1
		local okRead, isPart, size = pcall(function()
			return part:IsA("BasePart"), part.Size
		end)
		local bad = not okRead or isPart ~= true or typeof(size) ~= "Vector3"
		if not bad then
			bad = size.X < BANK_PLANT_MIN_WIDTH or size.Z < BANK_PLANT_MIN_WIDTH or size.Y < BANK_PLANT_MIN_HEIGHT
		end
		if bad then
			plantOffenders += 1
			if #plantOffenderList < 10 then
				local okName, name = pcall(function()
					return part.Name
				end)
				local dims = typeof(size) == "Vector3" and string.format("%.2fx%.2fx%.2f", size.X, size.Y, size.Z)
					or "unreadable"
				plantOffenderList[#plantOffenderList + 1] = (okName and tostring(name) or "?") .. ":" .. dims
			end
			if not okRead or isPart ~= true then
				plantReadErrors += 1
			end
		end
	end
end
local plantDetail = {
	plants = plantTotal,
	offenders = plantOffenderList,
	readErrors = plantReadErrors,
	minWidth = BANK_PLANT_MIN_WIDTH,
	minHeight = BANK_PLANT_MIN_HEIGHT,
	folderPresent = riverFolder ~= nil,
}
emit(
	"BANK_PLANT_SHAPE",
	riverFolder ~= nil and plantTotal > 0 and plantReadErrors == 0 and plantOffenders == 0,
	plantOffenders,
	0,
	plantDetail
)

-- RIVER_ROCKS (WORK_QUEUE item 141). READ-ONLY: count BankRock Parts within RIVER_BANK_VEG_RADIUS
-- (XZ) of the bridge centre whose three Size axes are each in [1, 4] studs. A missing folder or
-- zero tagged rocks FAILs; a failed CFrame/Size/IsA read is an error, never a skip.
local rockTotal, rockNear, rockReadErrors = 0, 0, 0
local rockOffenderList = {}
for _, part in ipairs(riverParts) do
	if attr(part, "BankRock") == true then
		rockTotal += 1
		local okRead, isPart, pos, size = pcall(function()
			return part:IsA("BasePart"), part.CFrame.Position, part.Size
		end)
		if not okRead or isPart ~= true or typeof(pos) ~= "Vector3" or typeof(size) ~= "Vector3" then
			rockReadErrors += 1
		else
			local inBand = size.X >= RIVER_ROCK_MIN_SIZE
				and size.X <= RIVER_ROCK_MAX_SIZE
				and size.Y >= RIVER_ROCK_MIN_SIZE
				and size.Y <= RIVER_ROCK_MAX_SIZE
				and size.Z >= RIVER_ROCK_MIN_SIZE
				and size.Z <= RIVER_ROCK_MAX_SIZE
			local dx, dz = pos.X - bridgeCX, pos.Z - bridgeCZ
			if inBand and dx * dx + dz * dz <= RIVER_BANK_VEG_RADIUS * RIVER_BANK_VEG_RADIUS then
				rockNear += 1
			elseif #rockOffenderList < 10 then
				local okName, name = pcall(function()
					return part.Name
				end)
				rockOffenderList[#rockOffenderList + 1] = string.format(
					"%s:d=%.1f:%.2fx%.2fx%.2f",
					okName and tostring(name) or "?",
					math.sqrt(dx * dx + dz * dz),
					size.X,
					size.Y,
					size.Z
				)
			end
		end
	end
end
local rockDetail = {
	total = rockTotal,
	near = riverMapReady and rockNear or 0,
	readErrors = rockReadErrors,
	offenders = rockOffenderList,
	radius = RIVER_BANK_VEG_RADIUS,
	sizeBand = { RIVER_ROCK_MIN_SIZE, RIVER_ROCK_MAX_SIZE },
	centre = riverMapReady and { bridgeCX, bridgeCZ } or nil,
	folderPresent = riverFolder ~= nil,
}
if not riverMapReady then
	rockDetail.reason = riverMapReason
end
emit(
	"RIVER_ROCKS",
	riverMapReady and riverFolder ~= nil and rockTotal > 0 and rockReadErrors == 0 and rockNear >= RIVER_ROCK_MIN,
	riverMapReady and rockNear or 0,
	">=" .. RIVER_ROCK_MIN,
	rockDetail
)

-- BRIDGE_RAILS: group rails/posts by Side. A rail spans the deck when its CFrame/Size Z interval
-- reaches both deck ends within tolerance. The weakest side decides; missing sides give 0.
local railsBySide, postsBySide = { left = {}, right = {} }, { left = {}, right = {} }
for _, part in ipairs(riverParts) do
	local kind = attr(part, "Kind")
	local side = attr(part, "Side")
	if side == "left" or side == "right" then
		if kind == "bridge_rail" then
			railsBySide[side][#railsBySide[side] + 1] = part
		elseif kind == "bridge_post" then
			postsBySide[side][#postsBySide[side] + 1] = part
		end
	end
end
local function railCoversDeck(part)
	local okRead, posZ, sizeZ = pcall(function()
		return part.CFrame.Position.Z, part.Size.Z
	end)
	if not okRead or type(posZ) ~= "number" or type(sizeZ) ~= "number" then
		return false
	end
	local minZ, maxZ = posZ - sizeZ / 2, posZ + sizeZ / 2
	return minZ <= bridge.z0 + RAIL_SPAN_TOL and maxZ >= bridge.z1 - RAIL_SPAN_TOL
end
local railSidesPassed = 0
local railDetail = {
	sides = {},
	deck = riverMapReady and { bridge.z0, bridge.z1 } or nil,
	tolerance = RAIL_SPAN_TOL,
	folderPresent = riverFolder ~= nil,
}
for _, side in ipairs({ "left", "right" }) do
	local covered = false
	if riverMapReady then
		for _, rail in ipairs(railsBySide[side]) do
			if railCoversDeck(rail) then
				covered = true
				break
			end
		end
	end
	local postCount = #postsBySide[side]
	local sidePass = riverMapReady and covered and postCount >= POSTS_PER_SIDE_MIN
	if sidePass then
		railSidesPassed += 1
	end
	railDetail.sides[side] = {
		rails = #railsBySide[side],
		railCovered = covered,
		posts = postCount,
		pass = sidePass,
	}
end
if not riverMapReady then
	railDetail.reason = riverMapReason
end
emit("BRIDGE_RAILS", railSidesPassed == 2, railSidesPassed, 2, railDetail)

-- BRIDGE_WALKABLE: the inner face is the edge nearest x=0 (left rails reach +X, right rails
-- reach -X). Every rail/post must keep that face at |x|>=4, both sides must exist and the
-- walkable width 2*min(|innerFaceX|) must be >=8. Any API read error fails the check.
local sideInnerX, sideClear = { left = nil, right = nil }, { left = math.huge, right = math.huge }
local walkOffenders, walkErrors = {}, {}
for _, part in ipairs(riverParts) do
	local kind = attr(part, "Kind")
	if kind == "bridge_rail" or kind == "bridge_post" then
		local side = attr(part, "Side")
		local okRead, centreX, sizeX = pcall(function()
			return part.CFrame.Position.X, part.Size.X
		end)
		if not okRead or type(centreX) ~= "number" or type(sizeX) ~= "number" then
			walkErrors[#walkErrors + 1] = tostring(kind) .. ":" .. tostring(side) .. ":read"
		elseif side == "left" or side == "right" then
			local innerFaceX = side == "left" and (centreX + sizeX / 2) or (centreX - sizeX / 2)
			local clearance = math.abs(innerFaceX)
			if clearance < WALK_CLEAR_MIN then
				walkOffenders[#walkOffenders + 1] =
					string.format("%s:%s:x=%.2f", tostring(kind), tostring(side), innerFaceX)
			end
			if clearance < sideClear[side] then
				sideClear[side] = clearance
				sideInnerX[side] = innerFaceX
			end
		else
			walkErrors[#walkErrors + 1] = tostring(kind) .. ":bad-side:" .. tostring(side)
		end
	end
end
local bothSides = sideInnerX.left ~= nil and sideInnerX.right ~= nil
local minClear = math.min(sideClear.left, sideClear.right)
local walkableWidth = (riverMapReady and bothSides and minClear ~= math.huge) and (2 * minClear) or 0
local walkPass = riverMapReady
	and bothSides
	and #walkOffenders == 0
	and #walkErrors == 0
	and walkableWidth >= WALK_WIDTH_MIN
local walkDetail = {
	leftInnerX = sideInnerX.left and math.floor(sideInnerX.left * 100) / 100 or nil,
	rightInnerX = sideInnerX.right and math.floor(sideInnerX.right * 100) / 100 or nil,
	walkableWidth = math.floor(walkableWidth * 100) / 100,
	offenders = walkOffenders,
	errors = walkErrors,
	folderPresent = riverFolder ~= nil,
}
if not riverMapReady then
	walkDetail.reason = riverMapReason
end
emit("BRIDGE_WALKABLE", walkPass, math.floor(walkableWidth * 100) / 100, ">=" .. WALK_WIDTH_MIN, walkDetail)
end

-- 9f. r8 path-edge family (WORK_QUEUE item 75). Two CHECK families over the staged
-- LookDevPathEdgeR8_pathedge_r8 folder: PATH_EDGE (part count) and PATH_CLEAR (no staged part sits
-- in the central 6 studs of any real MapSpec road arm, continuation or ring segment). MapSpec lives
-- under ServerScriptService.Server.World; the require is pcall-guarded and the Client VM cannot read
-- it. A missing folder / MapSpec / failed read is a FAIL, never a vacuous pass.
local PATH_EDGE_FOLDER = "LookDevPathEdgeR8_pathedge_r8"
local PATH_EDGE_KEY = "pathedge_r8"
local PATH_EDGE_MIN = 120
local CENTRAL_HALF = 3

local pathEdgeFolder = folderNamed(PATH_EDGE_FOLDER)
local pathEdgeParts = {}
local okPathEdgeParts, pathEdgeDescendants = pcall(function()
	if not pathEdgeFolder then
		return {}
	end
	return pathEdgeFolder:GetDescendants()
end)
if okPathEdgeParts and type(pathEdgeDescendants) == "table" then
	for _, inst in ipairs(pathEdgeDescendants) do
		local okPart, isPart = pcall(function()
			return inst:IsA("BasePart")
		end)
		-- The folder and its path subfolders carry the same tag; only real Parts are candidates.
		if okPart and isPart and attr(inst, "LookDevPathEdgeR8") == PATH_EDGE_KEY then
			pathEdgeParts[#pathEdgeParts + 1] = inst
		end
	end
end

-- PATH_EDGE: count staged Parts, with Kind and Path breakdowns for a failing run. A missing folder
-- gives 0 and a FAIL, never a skip.
local pathEdgeByKind = { grass_tuft = 0, pebble = 0, puddle = 0 }
local pathEdgeByPath = {}
for _, part in ipairs(pathEdgeParts) do
	local kind = attr(part, "Kind")
	if pathEdgeByKind[kind] ~= nil then
		pathEdgeByKind[kind] += 1
	end
	local key = attr(part, "Path")
	key = type(key) == "string" and key or "?"
	pathEdgeByPath[key] = (pathEdgeByPath[key] or 0) + 1
end
emit("PATH_EDGE", #pathEdgeParts >= PATH_EDGE_MIN, #pathEdgeParts, ">=" .. PATH_EDGE_MIN, {
	total = #pathEdgeParts,
	perKind = pathEdgeByKind,
	perPath = pathEdgeByPath,
	folderPresent = pathEdgeFolder ~= nil,
})

-- PATH_CLEAR: build every real path from MapSpec. Rectangles cover the four arms and two
-- continuations; rotated chords cover the 56 ring segments. Ring convention matches
-- ModelMapPathEdgeR8.ringPieces: local tangent = (cos(yaw), -sin(yaw)), local normal =
-- (sin(yaw), cos(yaw)); a world offset inverts by dotting with those two axes. The central
-- corridor is |perpendicular| < 3 and |tangent| < length/2 on a ring chord.
local function addPathRect(list, item)
	if type(item) ~= "table" then
		return false
	end
	local name, x, z, sx, sz = item.name, item.x, item.z, item.sx, item.sz
	if
		type(name) ~= "string"
		or type(x) ~= "number"
		or type(z) ~= "number"
		or type(sx) ~= "number"
		or type(sz) ~= "number"
		or sx <= 0
		or sz <= 0
	then
		return false
	end
	list[#list + 1] = { name = name, x = x, z = z, halfX = sx / 2, halfZ = sz / 2, horizontal = sx > sz }
	return true
end
local function addPathSegment(list, item)
	if
		type(item) ~= "table"
		or type(item.x) ~= "number"
		or type(item.z) ~= "number"
		or type(item.yaw) ~= "number"
		or type(item.length) ~= "number"
	then
		return false
	end
	local a = math.rad(item.yaw)
	list[#list + 1] = {
		x = item.x,
		z = item.z,
		tx = math.cos(a),
		tz = -math.sin(a),
		nx = math.sin(a),
		nz = math.cos(a),
		halfLen = item.length / 2,
	}
	return true
end
local pathRects, pathSegments = {}, {}
local pathMapReady = false
local pathMapReason = nil
local okPathMap, loadedPathMap = pcall(function()
	local sss = game:GetService("ServerScriptService")
	local server = sss and sss:FindFirstChild("Server")
	if not server then
		return nil
	end
	local world = server:FindFirstChild("World")
	if not world then
		return nil
	end
	local module = world:FindFirstChild("MapSpec")
	if not module then
		return nil
	end
	return require(module)
end)
if
	okPathMap
	and type(loadedPathMap) == "table"
	and type(loadedPathMap.ROAD) == "table"
	and type(loadedPathMap.roadArms) == "function"
	and type(loadedPathMap.roadContinuations) == "function"
	and type(loadedPathMap.ringSegments) == "function"
then
	local okArms, arms = pcall(function()
		return loadedPathMap.roadArms()
	end)
	local okConts, continuations = pcall(function()
		return loadedPathMap.roadContinuations()
	end)
	local okRing, ring = pcall(function()
		return loadedPathMap.ringSegments()
	end)
	if not okArms or type(arms) ~= "table" then
		pathMapReason = "roadArms not readable"
	elseif not okConts or type(continuations) ~= "table" then
		pathMapReason = "roadContinuations not readable"
	elseif not okRing or type(ring) ~= "table" then
		pathMapReason = "ringSegments not readable"
	else
		local rectsOk = true
		for _, item in ipairs(arms) do
			rectsOk = addPathRect(pathRects, item) and rectsOk
		end
		for _, item in ipairs(continuations) do
			rectsOk = addPathRect(pathRects, item) and rectsOk
		end
		local segmentsOk = true
		for _, item in ipairs(ring) do
			segmentsOk = addPathSegment(pathSegments, item) and segmentsOk
		end
		if not rectsOk or #pathRects == 0 then
			pathMapReason = "road rectangles malformed"
		elseif not segmentsOk or #pathSegments == 0 then
			pathMapReason = "ring segments malformed"
		else
			pathMapReady = true
		end
	end
else
	pathMapReason = "MapSpec not readable"
end

local function insideCentralCorridor(px, pz)
	for _, rect in ipairs(pathRects) do
		if rect.horizontal then
			if math.abs(pz - rect.z) < CENTRAL_HALF and px >= rect.x - rect.halfX and px <= rect.x + rect.halfX then
				return rect.name
			end
		elseif math.abs(px - rect.x) < CENTRAL_HALF and pz >= rect.z - rect.halfZ and pz <= rect.z + rect.halfZ then
			return rect.name
		end
	end
	for index, seg in ipairs(pathSegments) do
		local dx, dz = px - seg.x, pz - seg.z
		local tangent = dx * seg.tx + dz * seg.tz
		local perpendicular = dx * seg.nx + dz * seg.nz
		if math.abs(perpendicular) < CENTRAL_HALF and math.abs(tangent) < seg.halfLen then
			return "RingRoad:" .. index
		end
	end
	return nil
end

-- Count each intruding part once. A failed CanCollide read is conservatively counted as a
-- collidable intruder, and a failed CFrame read is a recorded error, so an unreadable folder can
-- never vacuously pass.
local allIntruders, collidableIntruders = 0, 0
local pathOffenders, pathReadErrors = {}, {}
for _, part in ipairs(pathEdgeParts) do
	local okPos, pos = pcall(function()
		return part.CFrame.Position
	end)
	if not okPos or typeof(pos) ~= "Vector3" then
		pathReadErrors[#pathReadErrors + 1] = tostring(attr(part, "Path")) .. ":cframe"
	elseif pathMapReady then
		local hitPath = insideCentralCorridor(pos.X, pos.Z)
		if hitPath then
			allIntruders += 1
			local okCollide, collide = pcall(function()
				return part.CanCollide
			end)
			if not okCollide or collide == true then
				collidableIntruders += 1
				if #pathOffenders < 10 then
					pathOffenders[#pathOffenders + 1] =
						string.format("%s:%s:%.2f,%.2f", tostring(hitPath), tostring(attr(part, "Kind")), pos.X, pos.Z)
				end
			end
		end
	end
end
local clearDetail = {
	allIntruders = allIntruders,
	total = #pathEdgeParts,
	pathsChecked = pathMapReady and (#pathRects + #pathSegments) or 0,
	rects = #pathRects,
	segments = #pathSegments,
	offenders = pathOffenders,
	readErrors = pathReadErrors,
	folderPresent = pathEdgeFolder ~= nil,
}
if not pathMapReady then
	clearDetail.reason = pathMapReason
elseif #pathEdgeParts == 0 then
	clearDetail.reason = "no candidate parts"
end
emit(
	"PATH_CLEAR",
	pathMapReady and #pathEdgeParts > 0 and collidableIntruders == 0 and #pathReadErrors == 0,
	collidableIntruders,
	0,
	clearDetail
)

-- 9f-2. WORK_QUEUE section O item 142: PATH_EDGE_OFFSET. READ-ONLY: reads the item-142 tags
-- written by LookDevPathEdgeR8 and reuses the MapSpec centreline table built for PATH_CLEAR.
-- Every tagged piece must carry a signed Lateral whose absolute value lies in
-- [HalfWidth, HalfWidth + PATH_EDGE_GROW]; its CFrame distance from the recorded CentreX/CentreZ
-- must agree, and that centre must sit on a real road arm, continuation or ring chord. A missing
-- folder, tag or numeric attribute is an offender, never a skip. No candidate is staged here.
do
local PATH_EDGE_GROW = 3
local PATH_EDGE_TOL = 0.25

local function nearestPathCentreDistance(px, pz)
	local best = math.huge
	for _, rect in ipairs(pathRects) do
		local along, perpendicular
		if rect.horizontal then
			local clamped = math.max(rect.x - rect.halfX, math.min(px, rect.x + rect.halfX))
			along, perpendicular = clamped - px, pz - rect.z
		else
			local clamped = math.max(rect.z - rect.halfZ, math.min(pz, rect.z + rect.halfZ))
			along, perpendicular = px - rect.x, clamped - pz
		end
		best = math.min(best, math.sqrt(along * along + perpendicular * perpendicular))
	end
	for _, seg in ipairs(pathSegments) do
		local dx, dz = px - seg.x, pz - seg.z
		local tangent = dx * seg.tx + dz * seg.tz
		local perpendicular = dx * seg.nx + dz * seg.nz
		local clamped = math.max(-seg.halfLen, math.min(tangent, seg.halfLen))
		local dt = tangent - clamped
		best = math.min(best, math.sqrt(dt * dt + perpendicular * perpendicular))
	end
	return best
end

local offsetOffenders, offsetReadErrors = {}, {}
local offsetChecked = 0
for _, part in ipairs(pathEdgeParts) do
	offsetChecked += 1
	local okName, partName = pcall(function()
		return part.Name
	end)
	local name = okName and tostring(partName) or "?"
	local lateral = attr(part, "Lateral")
	local halfWidth = attr(part, "HalfWidth")
	local centreX = attr(part, "CentreX")
	local centreZ = attr(part, "CentreZ")
	local measured, lower, upper = nil, nil, nil
	local reason = nil
	if attr(part, "PathEdgePart") ~= true then
		reason = "missing PathEdgePart tag"
	elseif
		type(lateral) ~= "number"
		or type(halfWidth) ~= "number"
		or type(centreX) ~= "number"
		or type(centreZ) ~= "number"
	then
		reason = "missing/non-numeric item-142 attributes"
	else
		measured, lower, upper = math.abs(lateral), halfWidth, halfWidth + PATH_EDGE_GROW
		if measured < lower or measured > upper then
			reason = "lateral outside band"
		end
		local okPos, pos = pcall(function()
			return part.CFrame.Position
		end)
		if not okPos or typeof(pos) ~= "Vector3" then
			reason = reason or "unreadable CFrame"
			offsetReadErrors[#offsetReadErrors + 1] = name .. ":cframe"
		else
			local fromCentre = math.sqrt((pos.X - centreX) ^ 2 + (pos.Z - centreZ) ^ 2)
			if math.abs(fromCentre - measured) > PATH_EDGE_TOL then
				reason = reason or "CFrame disagrees with Lateral/Centre"
			end
			if pathMapReady then
				local centreGap = nearestPathCentreDistance(centreX, centreZ)
				if centreGap > PATH_EDGE_TOL then
					reason = reason or "centre off MapSpec centreline"
				end
			end
		end
	end
	if reason then
		if measured == nil then
			measured = type(lateral) == "number" and math.abs(lateral) or -1
		end
		if lower == nil then
			lower = type(halfWidth) == "number" and halfWidth or -1
		end
		if upper == nil then
			upper = type(halfWidth) == "number" and halfWidth + PATH_EDGE_GROW or -1
		end
		offsetOffenders[#offsetOffenders + 1] =
			string.format("%s measured=%.2f allowed=[%.2f,%.2f] reason=%s", name, measured, lower, upper, reason)
	end
end
local offsetStructural = pathEdgeFolder == nil or offsetChecked == 0 or not okPathEdgeParts
local offsetPass = not offsetStructural and #offsetOffenders == 0 and #offsetReadErrors == 0
local offsetMeasured = #offsetOffenders
if offsetMeasured == 0 and not offsetPass then
	offsetMeasured = 1
end
local offsetDetail = {
	checked = offsetChecked,
	offenderCount = #offsetOffenders,
	offenders = offsetOffenders,
	readErrors = offsetReadErrors,
	band = { min = 0, grow = PATH_EDGE_GROW },
	tolerance = PATH_EDGE_TOL,
	centrelineChecked = pathMapReady,
	folderPresent = pathEdgeFolder ~= nil,
}
if not pathMapReady then
	offsetDetail.reason = pathMapReason
elseif offsetStructural then
	offsetDetail.reason = "no candidate parts"
end
emit("PATH_EDGE_OFFSET", offsetPass, offsetMeasured, 0, offsetDetail)
end

-- 9g. r8 buildings family (WORK_QUEUE item 77). Three CHECK families over the staged
-- LookDevBuildingsR8_buildings_r8 folder: BLDG_VISIBLE (six building Models inside the review
-- camera cone), BLDG_WIDTH (each world bbox width in [12,60]) and BLDG_DOOR (each DoorGauge >=7
-- tall with zero collidable building geometry overlapping its volume — the avatar-fit test).
-- Every game API is pcall-guarded; a missing folder / camera / model / gauge / failed read is a
-- FAIL at measured 0, never a skip.
do
local BUILDINGS_FOLDER = "LookDevBuildingsR8_buildings_r8"
local BUILDINGS_KEY = "buildings_r8"
local BUILDING_SLOTS = {
	"indonesian_house",
	"rumah_4",
	"rumah_joglo",
	"pendopo_jawa",
	"warung_penyetan",
	"nipa_hut",
}
local BLDG_MIN_WIDTH, BLDG_MAX_WIDTH = 12, 60
local MIN_DOOR = 7

local buildingsFolder = folderNamed(BUILDINGS_FOLDER)
local buildingsBySlot = {}
do
	local buildingModels = {}
	for _, model in ipairs(childList(buildingsFolder)) do
		local okModel, isModel = pcall(function()
			return model:IsA("Model")
		end)
		if okModel and isModel and attr(model, "LookDevBuildingsR8") == BUILDINGS_KEY then
			local slot = attr(model, "BuildingSlot")
			if type(slot) == "string" then
				if buildingsBySlot[slot] == nil then
					buildingsBySlot[slot] = model
				end
				buildingModels[#buildingModels + 1] = model
			end
		end
	end

	-- BLDG_VISIBLE: reuse the r7 cone helpers (CONE_COS + one occlusion ray per subject).
	-- A missing folder, camera attribute or CFrame gives visibleCount 0, hence a FAIL at 0.
	local bldgEye = asVector3(attr(buildingsFolder, "ReviewCameraPos"))
	local bldgLook = asVector3(attr(buildingsFolder, "ReviewLookAt"))
	local bldgCameraCF = nil
	if bldgEye and bldgLook then
		local okCF, cf = pcall(function()
			return CFrame.lookAt(bldgEye, bldgLook)
		end)
		if okCF then
			bldgCameraCF = cf
		end
	end
	local bldgVisibleCount = visibleCount(buildingModels, bldgCameraCF)
	local bldgVisibleBySlot = {}
	for _, slot in ipairs(BUILDING_SLOTS) do
		bldgVisibleBySlot[slot] = false
	end
	if bldgCameraCF then
		local eye = bldgCameraCF.Position
		local lookAt = eye + bldgCameraCF.LookVector
		for _, slot in ipairs(BUILDING_SLOTS) do
			local subject = buildingsBySlot[slot]
			local centre = subject and bboxCentre(subject) or nil
			bldgVisibleBySlot[slot] = subject ~= nil and centre ~= nil and visibleFrom(subject, centre, eye, lookAt)
		end
	end
	emit("BLDG_VISIBLE", bldgVisibleCount == #BUILDING_SLOTS, bldgVisibleCount, #BUILDING_SLOTS, {
		folderPresent = buildingsFolder ~= nil,
		eye = bldgEye and { bldgEye.X, bldgEye.Y, bldgEye.Z } or nil,
		lookAt = bldgLook and { bldgLook.X, bldgLook.Y, bldgLook.Z } or nil,
		slots = bldgVisibleBySlot,
	})

	-- PIVOT_GROUND (WORK_QUEUE item 146; READ-ONLY). Kit convention: pivot at the ground base,
	-- footprint centre, facing -Z. This grades only the Y equality (0.2-stud tolerance); X/Z and
	-- facing are stage-time conventions documented in docs/v2/visual/art/BUILDING_KIT.md.
	-- GetBoundingBox is exposed on Model in this Studio; bboxCentre/bboxSize carry the CFrame+Size
	-- corner-math fallback. A missing folder, unreadable pivot or zero staged Models FAIL at 6.
	local PIVOT_TOL = 0.2
	local pivotDetail = {}
	local pivotFailures = 0
	for _, slot in ipairs(BUILDING_SLOTS) do
		local model = buildingsBySlot[slot]
		local pivotY, bottomY = nil, nil
		if model then
			local okPivot, pivot = pcall(function()
				return model:GetPivot()
			end)
			if okPivot and pivot then
				pivotY = pivot.Position.Y
			end
			local okBox, boxCF, boxSize = pcall(function()
				return model:GetBoundingBox()
			end)
			if okBox and boxCF and boxSize and boxSize.Y > 0 then
				bottomY = boxCF.Position.Y - boxSize.Y / 2
			else
				local centre, size = bboxCentre(model), bboxSize(model)
				if centre and size and size.Y > 0 then
					bottomY = centre.Y - size.Y / 2
				end
			end
		end
		local delta = nil
		if type(pivotY) == "number" and type(bottomY) == "number" then
			delta = math.abs(pivotY - bottomY)
		end
		local pass = delta ~= nil and delta <= PIVOT_TOL
		if not pass then
			pivotFailures += 1
		end
		pivotDetail[slot] = {
			pivotY = pivotY,
			bottomY = bottomY,
			delta = type(delta) == "number" and math.floor(delta * 1000) / 1000 or nil,
			pass = pass,
		}
	end
	local pivotReadable = buildingsFolder ~= nil and #buildingModels > 0
	local pivotMeasured = if pivotReadable then pivotFailures else #BUILDING_SLOTS
	emit("PIVOT_GROUND", pivotReadable and pivotFailures == 0, pivotMeasured, 0, {
		folderPresent = buildingsFolder ~= nil,
		staged = #buildingModels,
		tolerance = PIVOT_TOL,
		slots = pivotDetail,
	})
end

-- BLDG_WIDTH: measure each staged Model's world GetBoundingBox().Size.X; no hardcoded widths.
-- A missing model or failed bbox read leaves that slot out of range.
local bldgWidthDetail = {}
local bldgWidthOk = 0
for _, slot in ipairs(BUILDING_SLOTS) do
	local model = buildingsBySlot[slot]
	local size = model and bboxSize(model) or nil
	local width = size and size.X or nil
	local inRange = type(width) == "number" and width >= BLDG_MIN_WIDTH and width <= BLDG_MAX_WIDTH
	if inRange then
		bldgWidthOk += 1
	end
	bldgWidthDetail[slot] = {
		width = type(width) == "number" and math.floor(width * 100) / 100 or nil,
		inRange = inRange,
	}
end
emit("BLDG_WIDTH", bldgWidthOk == #BUILDING_SLOTS, bldgWidthOk, #BUILDING_SLOTS, {
	folderPresent = buildingsFolder ~= nil,
	range = { BLDG_MIN_WIDTH, BLDG_MAX_WIDTH },
	slots = bldgWidthDetail,
})

-- Full 3D world AABB from a BasePart's Size/CFrame using the VectorToWorldSpace absolute-extent
-- technique. The 1.5-stud door offset is already baked into the gauge CFrame by the applier, so
-- this is a raw extent computation with no extra offset.
local function partAABB3D(part)
	local ok, box = pcall(function()
		local cf = part.CFrame
		local size = part.Size
		local ax = cf:VectorToWorldSpace(Vector3.new(size.X / 2, 0, 0))
		local ay = cf:VectorToWorldSpace(Vector3.new(0, size.Y / 2, 0))
		local az = cf:VectorToWorldSpace(Vector3.new(0, 0, size.Z / 2))
		local ex = math.abs(ax.X) + math.abs(ay.X) + math.abs(az.X)
		local ey = math.abs(ax.Y) + math.abs(ay.Y) + math.abs(az.Y)
		local ez = math.abs(ax.Z) + math.abs(ay.Z) + math.abs(az.Z)
		local p = cf.Position
		return {
			minX = p.X - ex,
			maxX = p.X + ex,
			minY = p.Y - ey,
			maxY = p.Y + ey,
			minZ = p.Z - ez,
			maxZ = p.Z + ez,
		}
	end)
	if ok and type(box) == "table" then
		return box
	end
	return nil
end

-- Raw AABB intersection: touching faces are not an overlap.
local function aabb3DOverlap(a, b)
	return a.minX < b.maxX
		and a.maxX > b.minX
		and a.minY < b.maxY
		and a.maxY > b.minY
		and a.minZ < b.maxZ
		and a.maxZ > b.minZ
end

-- The DoorGauge must be a direct child of its own staged building Model, tagged and slot-matched.
local function doorGaugeFor(model, slot)
	if not model then
		return nil
	end
	local okChildren, children = pcall(function()
		return model:GetChildren()
	end)
	if not okChildren or type(children) ~= "table" then
		return nil
	end
	for _, child in ipairs(children) do
		local okName, name = pcall(function()
			return child.Name
		end)
		if
			okName
			and name == "DoorGauge"
			and attr(child, "LookDevBuildingsR8") == BUILDINGS_KEY
			and attr(child, "BuildingSlot") == slot
			and attr(child, "GaugeKind") == "DoorClearance"
		then
			local okPart, isPart = pcall(function()
				return child:IsA("BasePart")
			end)
			if okPart and isPart then
				return child
			end
		end
	end
	return nil
end

-- BLDG_DOOR: a slot passes only when its gauge is >=7 tall AND rotation-aware
-- workspace:GetPartsInPart finds zero collidable building parts with Size.X > 0.5 and
-- Size.Y > 1.5 intersecting the gauge volume. World AABBs of rotated roof panels (joglo Union,
-- pendopo Unions) false-positive on the 7x7.25x2 gauge even though their real geometry misses it;
-- GetPartsInPart tests the actual oriented shape. This is a correctness fix, NOT a relaxed target:
-- measured stays the integer count of passing gauges out of 6; overlaps = -1 means read failure.
local bldgDoorDetail = {}
local bldgDoorOk = 0
for _, slot in ipairs(BUILDING_SLOTS) do
	local model = buildingsBySlot[slot]
	local gauge = doorGaugeFor(model, slot)
	local height, facade = nil, nil
	local overlaps = 0
	local pass = false
	if gauge then
		local okHeight, h = pcall(function()
			return gauge.Size.Y
		end)
		if okHeight and type(h) == "number" then
			height = h
		end
		local okFacade, f = pcall(function()
			return gauge:GetAttribute("Facade")
		end)
		if okFacade and (f == "front" or f == "back") then
			facade = f
		end
		local okProbe, probe = pcall(function()
			return Instance.new("Part")
		end)
		if not okProbe or not probe then
			overlaps = -1
		else
			local okSetup = pcall(function()
				local size = gauge.Size
				probe.Size = Vector3.new(size.X, size.Y, size.Z) -- the gauge's actual Size
				probe.CanCollide = false
				probe.Transparency = 1
				probe.Anchored = false
				probe.CFrame = gauge.CFrame
				probe.Parent = workspace
			end)
			local okParams, params = pcall(function()
				local p = OverlapParams.new()
				p.FilterType = Enum.RaycastFilterType.Exclude
				p.FilterDescendantsInstances = { probe }
				return p
			end)
			local okHits, hits = false, nil
			if okSetup and okParams and params then
				okHits, hits = pcall(function()
					return workspace:GetPartsInPart(probe, params)
				end)
			end
			if not okHits or type(hits) ~= "table" then
				overlaps = -1
			else
				for _, part in ipairs(hits) do
					local okDesc, descendant = pcall(function()
						return part:IsDescendantOf(model)
					end)
					local okCollide, collide = pcall(function()
						return part.CanCollide
					end)
					local okSize, sx, sy = pcall(function()
						return part.Size.X, part.Size.Y
					end)
					if
						okDesc
						and descendant
						and okCollide
						and collide == true
						and okSize
						and type(sx) == "number"
						and type(sy) == "number"
						and sx > 0.5
						and sy > 1.5
					then
						overlaps += 1
					end
				end
			end
			pcall(function()
				probe:Destroy()
			end)
		end
		pass = type(height) == "number" and height >= MIN_DOOR and overlaps == 0
	end
	if pass then
		bldgDoorOk += 1
	end
	bldgDoorDetail[slot] = {
		gaugeHeight = type(height) == "number" and math.floor(height * 100) / 100 or nil,
		overlaps = overlaps,
		facade = facade,
		pass = pass,
	}
end
emit("BLDG_DOOR", bldgDoorOk == #BUILDING_SLOTS, bldgDoorOk, #BUILDING_SLOTS, {
	folderPresent = buildingsFolder ~= nil,
	minDoor = MIN_DOOR,
	slots = bldgDoorDetail,
})
end

-- 9h. r8 facades family (WORK_QUEUE item 78). Two SERVER-side CHECK families over the staged
-- LookDevFacadesR8_facades_r8 folder. A missing folder, per-hub folder, gauge, hub Model, or failed
-- read is a FAIL at measured 0, never a skip. FACADE_PARTS counts tagged decorative Parts and checks
-- that all six FacadeKind values are present in every hub. DOOR_CLEAR probes each gauge's exact
-- oriented volume with workspace:GetPartsInPart (the BLDG_DOOR method) and requires zero collidable
-- hub parts and zero FacadePart decorative hits. No target is weakened for a missing candidate.
do
local FACADE_FOLDER = "LookDevFacadesR8_facades_r8"
local FACADE_KINDS = {
	"shuttered_window",
	"porch_roof",
	"ridge_cap",
	"lantern_bracket",
	"doorstep",
	"eave",
}
local FACADE_MIN_PARTS = 10
local FACADE_MODEL_NAMES = {
	pasar = "Pasar",
	gelap = "TengkulakGelap",
	warung = "Warung",
	ronda = "PosRonda",
	polisi = "PosPolisi",
	pakrt = "RumahPakRT",
}
-- Exact pure-data gauges: pakrt is the 7 x 10.5 map reference, the other five are 6 x 9.
local FACADE_GAUGE_SIZES = {
	pasar = { 6, 9, 2 },
	gelap = { 6, 9, 2 },
	warung = { 6, 9, 2 },
	ronda = { 6, 9, 2 },
	polisi = { 6, 9, 2 },
	pakrt = { 7, 10.5, 2 },
}

-- Prefer the live pure-data module; the literal table above is the exact fallback if it cannot be
-- read. Either way the numbers checked below are identical.
local facadeData = nil
pcall(function()
	local okShared, shared = pcall(function()
		return game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	end)
	if okShared and shared then
		local okModule, module = pcall(function()
			return shared:FindFirstChild("ModelMapFacadesR8")
		end)
		if okModule and module then
			facadeData = require(module)
		end
	end
end)

local facadesFolder = folderNamed(FACADE_FOLDER)
local facadeHubFolders = {}
for _, child in ipairs(childList(facadesFolder)) do
	local okFolder, isFolder = pcall(function()
		return child:IsA("Folder")
	end)
	local key = attr(child, "HubKey")
	if okFolder and isFolder and type(key) == "string" then
		if facadeHubFolders[key] == nil then
			facadeHubFolders[key] = child
		end
	end
end

local function facadeGaugeIn(folder, hubKey)
	if not folder then
		return nil
	end
	local ok, descendants = pcall(function()
		return folder:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return nil
	end
	for _, part in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return part:IsA("BasePart")
		end)
		local okName, name = pcall(function()
			return part.Name
		end)
		if okPart and isPart and okName and name == "FacadeDoorGauge" and attr(part, "HubKey") == hubKey then
			return part
		end
	end
	return nil
end

-- FACADE_PARTS: every hub must have >= 10 tagged Parts and all six kinds.
local facadePartsDetail = {}
local facadePartsOk = 0
for _, hubKey in ipairs(hubOrder) do
	local folder = facadeHubFolders[hubKey]
	local count = 0
	local kinds = {}
	local kindList = {}
	if folder then
		local ok, descendants = pcall(function()
			return folder:GetDescendants()
		end)
		if ok and type(descendants) == "table" then
			for _, part in ipairs(descendants) do
				local okPart, isPart = pcall(function()
					return part:IsA("BasePart")
				end)
				if okPart and isPart and attr(part, "FacadePart") == true then
					count += 1
					local kind = attr(part, "FacadeKind")
					if type(kind) == "string" and not kinds[kind] then
						kinds[kind] = true
						kindList[#kindList + 1] = kind
					end
				end
			end
		end
	end
	local allKinds = true
	for _, kind in ipairs(FACADE_KINDS) do
		if not kinds[kind] then
			allKinds = false
		end
	end
	local pass = folder ~= nil and count >= FACADE_MIN_PARTS and allKinds
	if pass then
		facadePartsOk += 1
	end
	facadePartsDetail[hubKey] = {
		folderPresent = folder ~= nil,
		count = count,
		kinds = kindList,
		allKinds = allKinds,
		pass = pass,
	}
end
emit("FACADE_PARTS", facadePartsOk == #hubOrder, facadePartsOk, #hubOrder, {
	folderPresent = facadesFolder ~= nil,
	minParts = FACADE_MIN_PARTS,
	kinds = FACADE_KINDS,
	hubs = facadePartsDetail,
})

local function facadeHubModel(hubKey)
	local wanted = FACADE_MODEL_NAMES[hubKey]
	if facadeData and facadeData.hubs and facadeData.hubs[hubKey] then
		wanted = facadeData.hubs[hubKey].model
	end
	if type(wanted) ~= "string" then
		return nil
	end
	local ok, found = pcall(function()
		local world = workspace:FindFirstChild("World")
		local roots = world and { world, workspace } or { workspace }
		for _, root in ipairs(roots) do
			for _, instance in ipairs(root:GetDescendants()) do
				if instance:IsA("Model") and instance.Name == wanted then
					return instance
				end
			end
		end
		return nil
	end)
	return if ok then found else nil
end

-- DOOR_CLEAR: mirror BLDG_DOOR. The probe is an unparented Part until configured, then matches the
-- gauge's exact Size/CFrame, excludes itself, and counts collidable hub geometry plus FacadeParts.
local facadeDoorDetail = {}
local facadeDoorOk = 0
for _, hubKey in ipairs(hubOrder) do
	local gauge = facadeGaugeIn(facadeHubFolders[hubKey], hubKey)
	local model = facadeHubModel(hubKey)
	local expected = FACADE_GAUGE_SIZES[hubKey]
	if facadeData and facadeData.hubs and facadeData.hubs[hubKey] then
		local g = facadeData.hubs[hubKey].gauge
		if type(g) == "table" then
			expected = { g.w, g.h, g.d }
		end
	end
	local dims = {}
	local dimsMatch = false
	local hubCollisions, facadeHits = 0, 0
	if gauge and expected then
		local okDims, w, h, d = pcall(function()
			local size = gauge.Size
			return size.X, size.Y, size.Z
		end)
		local okAttrs, aw, ah, ad = pcall(function()
			return gauge:GetAttribute("DoorW"), gauge:GetAttribute("DoorH"), gauge:GetAttribute("DoorD")
		end)
		if okDims then
			dims = { w, h, d }
		end
		dimsMatch = okDims
			and okAttrs
			and type(w) == "number"
			and type(h) == "number"
			and type(d) == "number"
			and math.abs(w - expected[1]) < 1e-6
			and math.abs(h - expected[2]) < 1e-6
			and math.abs(d - expected[3]) < 1e-6
			and type(aw) == "number"
			and type(ah) == "number"
			and type(ad) == "number"
			and math.abs(aw - expected[1]) < 1e-6
			and math.abs(ah - expected[2]) < 1e-6
			and math.abs(ad - expected[3]) < 1e-6
		local okProbe, probe = pcall(function()
			return Instance.new("Part")
		end)
		if not okProbe or not probe then
			hubCollisions, facadeHits = -1, -1
		else
			local okSetup = pcall(function()
				local size = gauge.Size
				probe.Size = Vector3.new(size.X, size.Y, size.Z)
				probe.CanCollide = false
				probe.Transparency = 1
				probe.Anchored = false
				probe.CFrame = gauge.CFrame
				probe.Parent = workspace
			end)
			local okParams, params = pcall(function()
				local p = OverlapParams.new()
				p.FilterType = Enum.RaycastFilterType.Exclude
				p.FilterDescendantsInstances = { probe }
				return p
			end)
			local okHits, hits = false, nil
			if okSetup and okParams and params then
				okHits, hits = pcall(function()
					return workspace:GetPartsInPart(probe, params)
				end)
			end
			if not okHits or type(hits) ~= "table" then
				hubCollisions, facadeHits = -1, -1
			else
				for _, part in ipairs(hits) do
					local okFacade, isFacade = pcall(function()
						return part:GetAttribute("FacadePart") == true
					end)
					if okFacade and isFacade then
						facadeHits += 1
					end
					local okDesc, descendant = pcall(function()
						return model ~= nil and part:IsDescendantOf(model)
					end)
					local okCollide, collide = pcall(function()
						return part.CanCollide
					end)
					local okSize, sx, sy = pcall(function()
						return part.Size.X, part.Size.Y
					end)
					if
						okDesc
						and descendant
						and okCollide
						and collide == true
						and okSize
						and type(sx) == "number"
						and type(sy) == "number"
						and sx > 0.5
						and sy > 1.5
					then
						hubCollisions += 1
					end
				end
			end
			pcall(function()
				probe:Destroy()
			end)
		end
	end
	local pass = gauge ~= nil and model ~= nil and dimsMatch and hubCollisions == 0 and facadeHits == 0
	if pass then
		facadeDoorOk += 1
	end
	facadeDoorDetail[hubKey] = {
		gaugePresent = gauge ~= nil,
		hubModelPresent = model ~= nil,
		expected = expected,
		measured = dims,
		dimsMatch = dimsMatch,
		hubCollisions = hubCollisions,
		facadeHits = facadeHits,
		pass = pass,
	}
end
emit("DOOR_CLEAR", facadeDoorOk == #hubOrder, facadeDoorOk, #hubOrder, {
	folderPresent = facadesFolder ~= nil,
	hubs = facadeDoorDetail,
})

-- FACADE_STRAY (WORK_QUEUE item 139). READ-ONLY; the caller stages facades_r8. Three rules per tagged
-- Part: its rotation-aware world AABB (eight local Size corners transformed by CFrame; GetBoundingBox
-- is unavailable in this Studio/MCP environment) fits the hub Model bbox grown 3 on every axis, its top
-- is <= ridge + 1, and no bbox side is longer than 12. Ridge = facadeData.hubs[key].ridge above
-- MapSpec.GROUND_Y; if that data cannot be read, the hub Model bbox top is the documented fallback.
-- A missing folder, gauge, hub Model or failed bbox read is an offence, never a vacuous pass.
local FACADE_GROW = 3
local FACADE_MAX_SIDE = 12
local FACADE_RIDGE_HEADROOM = 1
local FACADE_EPS = 1e-3

local function facadeBBox(instance)
	local ok, cf, size = pcall(function()
		return instance.CFrame, instance.Size
	end)
	if not ok or not cf or not size then
		return nil
	end
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for _, sx in ipairs({ -hx, hx }) do
		for _, sy in ipairs({ -hy, hy }) do
			for _, sz in ipairs({ -hz, hz }) do
				local p = cf * Vector3.new(sx, sy, sz)
				minX = math.min(minX, p.X)
				maxX = math.max(maxX, p.X)
				minY = math.min(minY, p.Y)
				maxY = math.max(maxY, p.Y)
				minZ = math.min(minZ, p.Z)
				maxZ = math.max(maxZ, p.Z)
			end
		end
	end
	if minX == math.huge then
		return nil
	end
	return {
		minX = minX,
		maxX = maxX,
		minY = minY,
		maxY = maxY,
		minZ = minZ,
		maxZ = maxZ,
		longest = math.max(size.X, size.Y, size.Z),
	}
end

-- A Model has no CFrame/Size of its own: union the corner AABBs of its descendant BaseParts.
local function facadeModelBBox(model)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return nil
	end
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local readable = false
	for _, child in ipairs(descendants) do
		local okPart, isPart = pcall(function()
			return child:IsA("BasePart")
		end)
		if okPart and isPart then
			local box = facadeBBox(child)
			if box then
				readable = true
				minX = math.min(minX, box.minX)
				maxX = math.max(maxX, box.maxX)
				minY = math.min(minY, box.minY)
				maxY = math.max(maxY, box.maxY)
				minZ = math.min(minZ, box.minZ)
				maxZ = math.max(maxZ, box.maxZ)
			end
		end
	end
	if not readable then
		return nil
	end
	return {
		minX = minX,
		maxX = maxX,
		minY = minY,
		maxY = maxY,
		minZ = minZ,
		maxZ = maxZ,
		longest = math.max(maxX - minX, maxY - minY, maxZ - minZ),
	}
end

local facadeStrayOffenders = {}
local facadeStrayCount = 0
local function facadeStrayOffend(message)
	facadeStrayCount += 1
	facadeStrayOffenders[#facadeStrayOffenders + 1] = message
end

local facadeGroundY = nil
if MapSpec and type(MapSpec.GROUND_Y) == "number" then
	facadeGroundY = MapSpec.GROUND_Y
end

for _, hubKey in ipairs(hubOrder) do
	local folder = facadeHubFolders[hubKey]
	local model = facadeHubModel(hubKey)
	local gauge = facadeGaugeIn(folder, hubKey)
	if not folder then
		facadeStrayOffend(hubKey .. ": missing staging folder")
	end
	if not gauge then
		facadeStrayOffend(hubKey .. ": missing FacadeDoorGauge")
	end
	if not model then
		facadeStrayOffend(hubKey .. ": missing hub Model " .. tostring(FACADE_MODEL_NAMES[hubKey]))
	end
	if folder and model then
		local hubBox = facadeModelBBox(model)
		if not hubBox then
			facadeStrayOffend(hubKey .. ": hub Model bbox unreadable")
		else
			local ridgeY = hubBox.maxY
			local entry = facadeData and facadeData.hubs and facadeData.hubs[hubKey] or nil
			if entry and type(entry.ridge) == "number" and facadeGroundY then
				ridgeY = facadeGroundY + entry.ridge
			end
			local okParts, descendants = pcall(function()
				return folder:GetDescendants()
			end)
			if not okParts or type(descendants) ~= "table" then
				facadeStrayOffend(hubKey .. ": staged parts unreadable")
			else
				for _, part in ipairs(descendants) do
					local okPart, isPart = pcall(function()
						return part:IsA("BasePart")
					end)
					if okPart and isPart and attr(part, "FacadePart") == true then
						local okName, value = pcall(function()
							return part.Name
						end)
						local partName = if okName and type(value) == "string" then value else "unnamed"
						local partBox = facadeBBox(part)
						if not partBox then
							facadeStrayOffend(hubKey .. " " .. partName .. ": bbox unreadable")
						else
							local rules = {}
							if
								partBox.minX < hubBox.minX - FACADE_GROW - FACADE_EPS
								or partBox.maxX > hubBox.maxX + FACADE_GROW + FACADE_EPS
								or partBox.minY < hubBox.minY - FACADE_GROW - FACADE_EPS
								or partBox.maxY > hubBox.maxY + FACADE_GROW + FACADE_EPS
								or partBox.minZ < hubBox.minZ - FACADE_GROW - FACADE_EPS
								or partBox.maxZ > hubBox.maxZ + FACADE_GROW + FACADE_EPS
							then
								rules[#rules + 1] = "outside hub bbox+3"
							end
							if partBox.maxY > ridgeY + FACADE_RIDGE_HEADROOM + FACADE_EPS then
								rules[#rules + 1] = "top>ridge+1"
							end
							if partBox.longest > FACADE_MAX_SIDE + FACADE_EPS then
								rules[#rules + 1] = "side>12"
							end
							for _, rule in ipairs(rules) do
								facadeStrayOffend(hubKey .. " " .. partName .. ": " .. rule)
							end
						end
					end
				end
			end
		end
	end
end
emit("FACADE_STRAY", facadeStrayCount == 0, facadeStrayCount, 0, {
	folderPresent = facadesFolder ~= nil,
	grow = FACADE_GROW,
	maxSide = FACADE_MAX_SIDE,
	ridgeHeadroom = FACADE_RIDGE_HEADROOM,
	offenders = facadeStrayOffenders,
})
end

-- 9i. r8 hub props family (WORK_QUEUE item 79). SERVER-only: ReviewCameras requires MapSpec from
-- ServerScriptService.Server.World, so the Client VM cannot read it. Both checks FAIL at measured 0
-- (visible) / measured >0 (grass) when the staging folder or a hub camera is missing — never a skip.
do
local HUBPROPS_FOLDER = "LookDevHubPropsR8_hubprops_r8"
local HUBPROPS_MIN_VISIBLE = 5
local hubPropsFolder = folderNamed(HUBPROPS_FOLDER)
local hubPropsFolders, hubPropsByHub = {}, {}
for _, folder in ipairs(childList(hubPropsFolder)) do
	local key = attr(folder, "HubKey")
	if type(key) == "string" then
		hubPropsFolders[key] = folder
		local list = {}
		for _, model in ipairs(childList(folder)) do
			if attr(model, "HubProp") == true then
				list[#list + 1] = model
			end
		end
		hubPropsByHub[key] = list
	end
end
local hubPropsServer = false
local hubPropsRun = service("RunService")
if hubPropsRun then
	pcall(function()
		hubPropsServer = hubPropsRun:IsServer() == true
	end)
end
local hubPropsCamera = {}
if hubPropsServer then
	local okCameras, Cameras = pcall(function()
		return require(game.ReplicatedStorage.Shared.ReviewCameras)
	end)
	if okCameras and type(Cameras) == "table" and type(Cameras.get) == "function" then
		for _, key in ipairs(hubOrder) do
			local okCam, camera = pcall(function()
				return Cameras.get("hub_" .. key)
			end)
			if okCam and camera then
				local eye, look = asVector3(camera.position), asVector3(camera.lookAt)
				if eye and look then
					hubPropsCamera[key] = { eye, look }
				end
			end
		end
	end
end
local hubPropsMinVisible = math.huge
local hubPropsGrass = 0
local hubPropsDetail = {}
for _, key in ipairs(hubOrder) do
	local props = hubPropsByHub[key] or {}
	local camera = hubPropsCamera[key]
	local visible, grassy = 0, 0
	for _, prop in ipairs(props) do
		local centre = bboxCentre(prop)
		if centre then
			if camera and visibleFrom(prop, centre, camera[1], camera[2]) then
				visible += 1
			end
			if grassAt({ x = centre.X, z = centre.Z }) then -- fixed GRASS_Y, as in r7
				grassy += 1
			end
		else
			grassy += 1 -- an unmeasurable prop is a grass failure, not a skip
		end
	end
	if not hubPropsFolder or not camera then
		visible = 0
	end
	if not hubPropsFolder or #props == 0 then
		grassy = math.max(grassy, 1) -- a missing folder/hub cannot pass a 0-target
	end
	hubPropsMinVisible = math.min(hubPropsMinVisible, visible)
	hubPropsGrass += grassy
	hubPropsDetail[key] = {
		folderPresent = hubPropsFolders[key] ~= nil,
		cameraPresent = camera ~= nil,
		props = #props,
		visible = visible,
		onGrass = grassy,
	}
end
if hubPropsMinVisible == math.huge then
	hubPropsMinVisible = 0
end
emit(
	"HUBPROPS_VISIBLE",
	hubPropsServer and hubPropsFolder ~= nil and hubPropsMinVisible >= HUBPROPS_MIN_VISIBLE,
	hubPropsMinVisible,
	HUBPROPS_MIN_VISIBLE,
	{ folderPresent = hubPropsFolder ~= nil, serverOnly = hubPropsServer, hubs = hubPropsDetail }
)
emit("HUBPROPS_ON_GRASS", hubPropsFolder ~= nil and hubPropsGrass == 0, hubPropsGrass, 0, {
	folderPresent = hubPropsFolder ~= nil,
	voxelY = GRASS_Y,
	hubs = hubPropsDetail,
})
end

-- STALLS / AWNING_STRIPES / LANE_CLEAR / PASAR_AWNING_ON_GRASS (WORK_QUEUE item 148, all
-- READ-ONLY). They stage nothing and inspect only the pasar_awnings_r8 folder. No part-lane
-- intersection uses GetPartsInPart: every staged part is non-collidable by construction, so the
-- audit uses explicit per-Part CFrame+Size AABBs against the lane rectangle in the pure data module.
local AWNING_FOLDER = "LookDevPasarAwningsR8_pasar_awnings_r8"
local awningFolder = folderNamed(AWNING_FOLDER)
local okAwningData, AwningData = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapPasarAwningsR8)
end)
if not okAwningData or type(AwningData) ~= "table" then
	AwningData = nil
end
local minStalls = if AwningData and type(AwningData.MIN_STALLS) == "number" then AwningData.MIN_STALLS else 10
local minStripes = if AwningData and type(AwningData.MIN_STRIPES) == "number" then AwningData.MIN_STRIPES else 30
local stallModels, awningStripes = {}, {}
for _, inst in ipairs(descendantList(awningFolder)) do
	local okModel, isModel = pcall(function()
		return inst:IsA("Model")
	end)
	if okModel and isModel and attr(inst, "PasarStall") == true then
		stallModels[#stallModels + 1] = inst
	end
	if attr(inst, "AwningStripe") == true then
		local colour = attr(inst, "StripeColour")
		if colour == "red" or colour == "white" or colour == "blue" then
			awningStripes[#awningStripes + 1] = { inst = inst, colour = colour }
		end
	end
end
emit("STALLS", awningFolder ~= nil and #stallModels >= minStalls, #stallModels, ">=" .. minStalls, {
	folderPresent = awningFolder ~= nil,
	stalls = #stallModels,
	dataPresent = AwningData ~= nil,
})
local stripeColours = { red = 0, white = 0, blue = 0 }
for _, stripe in ipairs(awningStripes) do
	stripeColours[stripe.colour] += 1
end
emit(
	"AWNING_STRIPES",
	awningFolder ~= nil and #awningStripes >= minStripes,
	#awningStripes,
	">=" .. minStripes,
	{ folderPresent = awningFolder ~= nil, colours = stripeColours }
)

local laneBox, laneWidth = nil, nil
local laneReady = awningFolder ~= nil
	and AwningData ~= nil
	and mapSpecReady
	and type(AwningData.lane) == "function"
	and type(AwningData.stalls) == "function"
	and type(MapSpec.hub) == "function"
	and type(MapSpec.hubPoint) == "function"
if laneReady then
	local okLane, lane = pcall(function()
		return AwningData.lane()
	end)
	local okHub, hub = pcall(function()
		return MapSpec.hub("pasar")
	end)
	laneReady = okLane
		and okHub
		and hub ~= nil
		and type(lane) == "table"
		and type(lane.lx) == "number"
		and type(lane.lz) == "number"
		and type(lane.width) == "number"
		and type(lane.depth) == "number"
	if laneReady then
		laneWidth = lane.width
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, corner in ipairs({
			{ lane.lx - lane.width / 2, lane.lz - lane.depth / 2 },
			{ lane.lx + lane.width / 2, lane.lz - lane.depth / 2 },
			{ lane.lx - lane.width / 2, lane.lz + lane.depth / 2 },
			{ lane.lx + lane.width / 2, lane.lz + lane.depth / 2 },
		}) do
			local okPoint, x, z = pcall(function()
				return MapSpec.hubPoint(hub, corner[1], corner[2])
			end)
			if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
				laneReady = false
				break
			end
			minX, maxX = math.min(minX, x), math.max(maxX, x)
			minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
		end
		if laneReady and minX < maxX and minZ < maxZ then
			laneBox = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
		end
	end
end
local laneBlockers = 0
if not laneBox then
	laneBlockers = 1
else
	for _, stall in ipairs(stallModels) do
		for _, part in ipairs(descendantList(stall)) do
			local okPart, isPart = pcall(function()
				return part:IsA("BasePart")
			end)
			if okPart and isPart then
				local okTransparency, transparency = pcall(function()
					return part.Transparency
				end)
				local box = bboxAABB(part)
				if box and okTransparency and type(transparency) == "number" and transparency < 1 then
					local ox = math.min(box.maxX, laneBox.maxX) - math.max(box.minX, laneBox.minX)
					local oz = math.min(box.maxZ, laneBox.maxZ) - math.max(box.minZ, laneBox.minZ)
					if ox > OVERLAP_TOL and oz > OVERLAP_TOL then
						laneBlockers += 1
					end
				end
			end
		end
	end
end
emit("LANE_CLEAR", laneBox ~= nil and laneBlockers == 0, laneBlockers, 0, {
	folderPresent = awningFolder ~= nil,
	lane = laneBox,
	laneWidth = laneWidth,
	blockingParts = laneBlockers,
})

local awningGrass = 0
local awningStallDetail = {}
for _, stall in ipairs(stallModels) do
	local centre = bboxCentre(stall)
	local grassy = not centre or grassAt({ x = centre.X, z = centre.Z })
	if grassy then
		awningGrass += 1
	end
	awningStallDetail[#awningStallDetail + 1] = {
		id = attr(stall, "StallId"),
		onGrass = grassy,
		centre = centre and { centre.X, centre.Y, centre.Z } or nil,
	}
end
if not awningFolder or #stallModels == 0 then
	awningGrass = math.max(awningGrass, 1) -- a missing folder cannot pass a 0-target
end
emit("PASAR_AWNING_ON_GRASS", awningFolder ~= nil and awningGrass == 0, awningGrass, 0, {
	folderPresent = awningFolder ~= nil,
	voxelY = GRASS_Y,
	stalls = awningStallDetail,
})

-- PLAZA_FOUNTAIN / PLAZA_BENCHES / PLAZA_UMBRELLAS / PLAZA_BUNTING / PLAZA_SHADE_TREE /
-- PLAZA_LANE_CLEAR / PLAZA_PATH_REACH (WORK_QUEUE item 149, all SERVER-side and READ-ONLY). They
-- stage nothing and inspect only LookDevPlazaR9_plaza_r9. No intersection uses GetPartsInPart: all
-- staged parts are non-collidable by construction, so both clearance checks use per-Part
-- CFrame+Size AABBs (bboxAABB) against 6-stud rectangles derived from the pure lane data plus
-- MapSpec.PLAZA. A missing folder, tag, data module or MapSpec FAILs at measured 0 (counts) or a
-- positive blocked count (clearance), never a vacuous pass.
local PLAZA_FOLDER = "LookDevPlazaR9_plaza_r9"
local plazaFolder = folderNamed(PLAZA_FOLDER)
local okPlazaData, PlazaData = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapPlazaR9)
end)
if not okPlazaData or type(PlazaData) ~= "table" then
	PlazaData = nil
end

local plazaFountains, plazaBenches, plazaUmbrellas = {}, {}, {}
local plazaBuntings, plazaTrees = {}, {}
local fountainDiscs, plazaPoles, plazaFlags, plazaLines = {}, {}, {}, {}
local umbrellaStripes, plazaParts = {}, {}
for _, inst in ipairs(descendantList(plazaFolder)) do
	local okModel, isModel = pcall(function()
		return inst:IsA("Model")
	end)
	if okModel and isModel then
		if attr(inst, "PlazaFountain") == "plaza_r9" then
			plazaFountains[#plazaFountains + 1] = inst
		end
		if attr(inst, "PlazaBench") == true then
			plazaBenches[#plazaBenches + 1] = inst
		end
		if attr(inst, "PlazaUmbrella") == true then
			plazaUmbrellas[#plazaUmbrellas + 1] = inst
			local stripes = {}
			for _, part in ipairs(descendantList(inst)) do
				if attr(part, "UmbrellaStripe") == true then
					local colour = attr(part, "StripeColour")
					if colour == "red" or colour == "white" or colour == "blue" then
						stripes[#stripes + 1] = colour
					end
				end
			end
			umbrellaStripes[#umbrellaStripes + 1] = stripes
		end
		if attr(inst, "PlazaBunting") == true then
			plazaBuntings[#plazaBuntings + 1] = inst
		end
		if attr(inst, "PlazaShadeTree") == true then
			plazaTrees[#plazaTrees + 1] = inst
		end
	end
	if attr(inst, "FountainWater") == true and attr(inst, "WaterColour") == "water" then
		fountainDiscs[#fountainDiscs + 1] = inst
	end
	if attr(inst, "BuntingPole") == true then
		plazaPoles[#plazaPoles + 1] = inst
	end
	if attr(inst, "BuntingFlag") == true then
		plazaFlags[#plazaFlags + 1] = inst
	end
	if attr(inst, "BuntingLine") == true then
		plazaLines[#plazaLines + 1] = inst
	end
	local okPart, isPart = pcall(function()
		return inst:IsA("BasePart")
	end)
	if okPart and isPart then
		local okT, transparency = pcall(function()
			return inst.Transparency
		end)
		if okT and type(transparency) == "number" and transparency < 1 then
			plazaParts[#plazaParts + 1] = inst
		end
	end
end

local plazaExpected = if PlazaData and type(PlazaData.counts) == "function" then PlazaData.counts() else nil
local plazaReady = plazaFolder ~= nil and PlazaData ~= nil and type(plazaExpected) == "table"

emit(
	"PLAZA_FOUNTAIN",
	plazaReady and #plazaFountains == plazaExpected.fountains and #fountainDiscs >= 1,
	#plazaFountains,
	if plazaExpected then plazaExpected.fountains else 1,
	{ folderPresent = plazaFolder ~= nil, fountains = #plazaFountains, waterDiscs = #fountainDiscs }
)
emit(
	"PLAZA_BENCHES",
	plazaReady and #plazaBenches == plazaExpected.benches,
	#plazaBenches,
	if plazaExpected then plazaExpected.benches else 4,
	{ folderPresent = plazaFolder ~= nil, benches = #plazaBenches }
)

local order = if PlazaData and type(PlazaData.STRIPE_ORDER) == "table"
	then PlazaData.STRIPE_ORDER
	else { "red", "white", "blue" }
local badUmbrellas, stripedCount = 0, 0
for _, stripes in ipairs(umbrellaStripes) do
	local good = #stripes >= 3
	for stripeIndex, colour in ipairs(stripes) do
		if colour ~= order[((stripeIndex - 1) % #order) + 1] then
			good = false
		end
	end
	if good then
		stripedCount += 1
	else
		badUmbrellas += 1
	end
end
emit(
	"PLAZA_UMBRELLAS",
	plazaReady and #plazaUmbrellas == plazaExpected.umbrellas and stripedCount == #plazaUmbrellas,
	#plazaUmbrellas,
	if plazaExpected then plazaExpected.umbrellas else 4,
	{ folderPresent = plazaFolder ~= nil, umbrellas = #plazaUmbrellas, striped = stripedCount, bad = badUmbrellas }
)

-- The line must actually span the two poles: its XZ AABB covers both pole centres (the bunting
-- recipe runs along X; the same min/max test also holds for a diagonal string).
local lineBox = plazaLines[1] and bboxAABB(plazaLines[1]) or nil
local poleXs = {}
for _, pole in ipairs(plazaPoles) do
	local centre = bboxCentre(pole)
	if centre then
		poleXs[#poleXs + 1] = centre.X
	end
end
local lineSpans = false
if lineBox and #poleXs >= 2 then
	local minX, maxX = math.huge, -math.huge
	for _, value in ipairs(poleXs) do
		minX, maxX = math.min(minX, value), math.max(maxX, value)
	end
	lineSpans = lineBox.minX <= minX + OVERLAP_TOL and lineBox.maxX >= maxX - OVERLAP_TOL
end
emit(
	"PLAZA_BUNTING",
	plazaReady
		and #plazaBuntings >= 1
		and #plazaPoles == plazaExpected.buntingPoles
		and #plazaFlags >= plazaExpected.buntingFlags
		and #plazaLines >= 1
		and lineSpans,
	#plazaBuntings,
	1,
	{
		folderPresent = plazaFolder ~= nil,
		buntings = #plazaBuntings,
		poles = #plazaPoles,
		flags = #plazaFlags,
		lines = #plazaLines,
		lineSpans = lineSpans,
	}
)

local treeHeight = 0
local treeAtEdge = false
local treeCentre = plazaTrees[1] and bboxCentre(plazaTrees[1]) or nil
local treeSize = plazaTrees[1] and bboxSize(plazaTrees[1]) or nil
if treeSize and type(treeSize.Y) == "number" then
	treeHeight = treeSize.Y
end
if treeCentre and mapSpecReady and type(MapSpec.PLAZA) == "table" then
	local dx = math.abs(treeCentre.X - MapSpec.PLAZA.x)
	local dz = math.abs(treeCentre.Z - MapSpec.PLAZA.z)
	treeAtEdge = math.max(dx, dz) >= 8
end
if plazaTrees[1] then
	local attrHeight = attr(plazaTrees[1], "TreeHeight")
	if type(attrHeight) == "number" and attrHeight > treeHeight then
		treeHeight = attrHeight
	end
end
emit(
	"PLAZA_SHADE_TREE",
	plazaReady and #plazaTrees == plazaExpected.shadeTrees and treeHeight >= 10 and treeAtEdge,
	#plazaTrees,
	if plazaExpected then plazaExpected.shadeTrees else 1,
	{
		folderPresent = plazaFolder ~= nil,
		trees = #plazaTrees,
		height = treeHeight,
		atPlazaEdge = treeAtEdge,
	}
)

-- World XZ rectangles from plaza-local lane data. Plaza is axis-aligned in MapSpec, so no yaw.
do
local laneBoxes, corridorBoxes = {}, {}
local lanesReady = plazaReady
	and mapSpecReady
	and type(MapSpec.PLAZA) == "table"
	and type(PlazaData.lanes) == "function"
local laneData = {}
if lanesReady then
	local okLanes, rows = pcall(function()
		return PlazaData.lanes()
	end)
	lanesReady = okLanes and type(rows) == "table" and #rows > 0
	if lanesReady then
		laneData = rows
		local px, pz = MapSpec.PLAZA.x, MapSpec.PLAZA.z
		local halfW, halfD = MapSpec.PLAZA.width / 2, MapSpec.PLAZA.depth / 2
		for _, lane in ipairs(rows) do
			if
				type(lane) ~= "table"
				or type(lane.x) ~= "number"
				or type(lane.z) ~= "number"
				or type(lane.width) ~= "number"
				or type(lane.depth) ~= "number"
			then
				lanesReady = false
				break
			end
			local box = {
				minX = px + lane.x - lane.width / 2,
				maxX = px + lane.x + lane.width / 2,
				minZ = pz + lane.z - lane.depth / 2,
				maxZ = pz + lane.z + lane.depth / 2,
			}
			laneBoxes[#laneBoxes + 1] = box
			local corridor = {
				minX = box.minX,
				maxX = box.maxX,
				minZ = box.minZ,
				maxZ = box.maxZ,
			}
			if lane.name == "north" then
				corridor.minZ = pz - halfD
			elseif lane.name == "south" then
				corridor.maxZ = pz + halfD
			elseif lane.name == "east" then
				corridor.maxX = px + halfW
			elseif lane.name == "west" then
				corridor.minX = px - halfW
			end
			corridorBoxes[#corridorBoxes + 1] = corridor
		end
	end
end

local function overlapsLane(box, rect)
	if not box then
		return false
	end
	local ox = math.min(box.maxX, rect.maxX) - math.max(box.minX, rect.minX)
	local oz = math.min(box.maxZ, rect.maxZ) - math.max(box.minZ, rect.minZ)
	return ox > OVERLAP_TOL and oz > OVERLAP_TOL
end

local laneBlockers = 0
if not lanesReady then
	laneBlockers = 1
else
	for _, part in ipairs(plazaParts) do
		local box = bboxAABB(part)
		for _, rect in ipairs(laneBoxes) do
			if overlapsLane(box, rect) then
				laneBlockers += 1
				break -- one part blocking any lane counts once
			end
		end
	end
end
emit("PLAZA_LANE_CLEAR", lanesReady and laneBlockers == 0, laneBlockers, 0, {
	folderPresent = plazaFolder ~= nil,
	lanes = #laneBoxes,
	visibleParts = #plazaParts,
	blockingParts = laneBlockers,
})

local plazaBlockedCorridors = 0
local plazaBlockersByCorridor = {}
for _, lane in ipairs(laneData) do
	plazaBlockersByCorridor[tostring(lane.name)] = 0
end
if not lanesReady then
	plazaBlockedCorridors = math.max(#laneData, 1)
else
	for index, corridor in ipairs(corridorBoxes) do
		for _, part in ipairs(plazaParts) do
			if overlapsLane(bboxAABB(part), corridor) then
				plazaBlockedCorridors += 1
				local name = tostring(laneData[index] and laneData[index].name or index)
				plazaBlockersByCorridor[name] = (plazaBlockersByCorridor[name] or 0) + 1
				break -- one blocked corridor counts once
			end
		end
	end
end
emit(
	"PLAZA_PATH_REACH",
	lanesReady and #corridorBoxes == #laneData and plazaBlockedCorridors == 0,
	plazaBlockedCorridors,
	0,
	{
		folderPresent = plazaFolder ~= nil,
		corridors = #corridorBoxes,
		blockedByCorridor = plazaBlockersByCorridor,
		reason = if lanesReady then nil else "folder / data / MapSpec.PLAZA not readable",
	}
)
end

-- 9h. WORK_QUEUE section O item 150: the OFF-BY-DEFAULT ronda_tower_r9 candidate. Three NEW
-- READ-ONLY checks over the staged LookDevRondaTowerR9_ronda_tower_r9 folder. TOWER_HEIGHT reads
-- the staged Model's world GetBoundingBox Y size (28..32 inclusive). TOWER_BASE measures the four
-- TowerLeg Parts' collective XZ AABB (8x8 brief + 1 tolerance). TOWER_PATH_CLEAR intersects every
-- staged Part's CFrame+Size AABB with the SAME MapSpec path table built for PATH_CLEAR. Missing
-- folder / model / MapSpec is a FAIL, never a skip. LOOKDEV_LEAK stays the shared restore proof.
do
local TOWER_FOLDER = "LookDevRondaTowerR9_ronda_tower_r9"
local TOWER_ID = "ronda_tower_r9"
local TOWER_HEIGHT_MIN, TOWER_HEIGHT_MAX = 28, 32
local TOWER_BASE_MAX = 9 -- 8x8 brief plus 1 stud tolerance

local towerFolder = folderNamed(TOWER_FOLDER)
local towerParts = {}
do
	local towerModel = nil
	local towerReadErrors = {}
	for _, inst in ipairs(descendantList(towerFolder)) do
		local okPart, isPart = pcall(function()
			return inst:IsA("BasePart")
		end)
		if attr(inst, "RondaTower") == TOWER_ID then
			if okPart and isPart then
				towerParts[#towerParts + 1] = inst
			else
				local okModel, isModel = pcall(function()
					return inst:IsA("Model")
				end)
				if okModel and isModel and not towerModel then
					towerModel = inst
				end
			end
		end
	end

	-- TOWER_HEIGHT: world Model bbox height, NOT the greybox tower's 36-stud MapSpec height.
	local towerHeight = 0
	local heightReadOk = false
	if towerModel then
		local size = bboxSize(towerModel)
		if size and size.Y > 0 then
			towerHeight = size.Y
			heightReadOk = true
		else
			towerReadErrors[#towerReadErrors + 1] = "bbox"
		end
	end
	emit(
		"TOWER_HEIGHT",
		heightReadOk and towerHeight >= TOWER_HEIGHT_MIN and towerHeight <= TOWER_HEIGHT_MAX,
		math.floor(towerHeight * 100 + 0.5) / 100,
		"28..32",
		{
			folderPresent = towerFolder ~= nil,
			modelFound = towerModel ~= nil,
			readErrors = towerReadErrors,
		}
	)

	-- TOWER_BASE: collective AABB of the four TowerLeg Parts, including their own sizes.
	local towerLegs = {}
	for _, part in ipairs(towerParts) do
		if attr(part, "TowerLeg") == true then
			towerLegs[#towerLegs + 1] = part
		end
	end
	local baseWidth, baseDepth = 0, 0
	local baseReadOk = #towerLegs > 0
	if baseReadOk then
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, leg in ipairs(towerLegs) do
			local box = bboxAABB(leg)
			if box then
				minX, maxX = math.min(minX, box.minX), math.max(maxX, box.maxX)
				minZ, maxZ = math.min(minZ, box.minZ), math.max(maxZ, box.maxZ)
			else
				baseReadOk = false
				towerReadErrors[#towerReadErrors + 1] = "leg-cframe"
			end
		end
		if baseReadOk then
			baseWidth, baseDepth = maxX - minX, maxZ - minZ
		end
	end
	local towerBaseFootprint = math.max(baseWidth, baseDepth)
	emit(
		"TOWER_BASE",
		baseReadOk and towerBaseFootprint <= TOWER_BASE_MAX,
		math.floor(towerBaseFootprint * 100 + 0.5) / 100,
		"<=" .. TOWER_BASE_MAX,
		{
			folderPresent = towerFolder ~= nil,
			legs = #towerLegs,
			width = math.floor(baseWidth * 100 + 0.5) / 100,
			depth = math.floor(baseDepth * 100 + 0.5) / 100,
			readErrors = towerReadErrors,
		}
	)
end

-- TOWER_PATH_CLEAR: no staged tower Part's XZ AABB touches a MapSpec road arm, continuation or
-- ring chord. Arms/continuations are full rectangles; ring chords use PATH_CLEAR's CENTRAL_HALF
-- corridor with the same chord axes and half-length. Exact AABB-overlap, no raycast or visual grade.
local function towerAabbHitsPath(box)
	for _, rect in ipairs(pathRects) do
		if
			box.maxX > rect.x - rect.halfX
			and box.minX < rect.x + rect.halfX
			and box.maxZ > rect.z - rect.halfZ
			and box.minZ < rect.z + rect.halfZ
		then
			return rect.name
		end
	end
	local centreX, centreZ = (box.minX + box.maxX) / 2, (box.minZ + box.maxZ) / 2
	local halfX, halfZ = (box.maxX - box.minX) / 2, (box.maxZ - box.minZ) / 2
	for index, seg in ipairs(pathSegments) do
		local dx, dz = centreX - seg.x, centreZ - seg.z
		local tangent = dx * seg.tx + dz * seg.tz
		local perpendicular = dx * seg.nx + dz * seg.nz
		local tangentExtent = math.abs(seg.tx) * halfX + math.abs(seg.tz) * halfZ
		local normalExtent = math.abs(seg.nx) * halfX + math.abs(seg.nz) * halfZ
		if
			math.abs(tangent) < seg.halfLen + tangentExtent
			and math.abs(perpendicular) < CENTRAL_HALF + normalExtent
		then
			return "RingRoad:" .. index
		end
	end
	return nil
end

local towerPathOverlaps, towerReadErrorCount = 0, 0
local towerPathOffenders, towerPathReadErrors = {}, {}
for _, part in ipairs(towerParts) do
	local box = bboxAABB(part)
	if not box then
		towerReadErrorCount += 1
		if #towerPathReadErrors < 10 then
			towerPathReadErrors[#towerPathReadErrors + 1] = tostring(part.Name) .. ":cframe"
		end
	elseif pathMapReady then
		local hit = towerAabbHitsPath(box)
		if hit then
			towerPathOverlaps += 1
			if #towerPathOffenders < 10 then
				towerPathOffenders[#towerPathOffenders + 1] = string.format(
					"%s:%s:%.2f,%.2f",
					hit,
					tostring(part.Name),
					(box.minX + box.maxX) / 2,
					(box.minZ + box.maxZ) / 2
				)
			end
		end
	end
end
local towerPathReason = nil
if not towerFolder then
	towerPathReason = "staging folder missing"
elseif not pathMapReady then
	towerPathReason = pathMapReason or "MapSpec paths not readable"
elseif #towerParts == 0 then
	towerPathReason = "no staged tower parts"
end
emit(
	"TOWER_PATH_CLEAR",
	towerFolder ~= nil and pathMapReady and #towerParts > 0 and towerPathOverlaps == 0 and towerReadErrorCount == 0,
	towerPathOverlaps + towerReadErrorCount,
	0,
	{
		folderPresent = towerFolder ~= nil,
		parts = #towerParts,
		pathsChecked = pathMapReady and (#pathRects + #pathSegments) or 0,
		offenders = towerPathOffenders,
		readErrors = towerPathReadErrors,
		reason = towerPathReason,
	}
)
end

-- 9g. WORK_QUEUE section O item 151: rocks_r9. Four NEW READ-ONLY checks over the staged
-- LookDevRocksR9_rocks_r9 folder. ROCK_PATH_CLEAR reuses pathRects/pathSegments from PATH_CLEAR and
-- the same CFrame+Size AABB math (GetBoundingBox is Model-only here). ROCK_GATE_CLEAR reads the real
-- plot gate markers when staged, then tagged PlotAnchor parts, then Config.Game.plotCenter; zero
-- readable gates is a FAIL, never a vacuous pass. The existing PATH_CLEAR / GATE_CLEAR are untouched.
do
local ROCK_FOLDER = "LookDevRocksR9_rocks_r9"
local ROCK_KEY = "rocks_r9"
local ROCK_MIN = 25
local ROCK_SPECIES_MIN = 2
local ROCK_GATE_CLEAR = 2
local ROCK_GATE_EXPECTED = 10

local rockFolder = folderNamed(ROCK_FOLDER)
local rockModels, rockParts = {}, {}
local okRocks, rockDescendants = pcall(function()
	if not rockFolder then
		return {}
	end
	return rockFolder:GetDescendants()
end)
if okRocks and type(rockDescendants) == "table" then
	for _, inst in ipairs(rockDescendants) do
		if attr(inst, "RockR9") == ROCK_KEY then
			local okModel, isModel = pcall(function()
				return inst:IsA("Model")
			end)
			local okPart, isPart = pcall(function()
				return inst:IsA("BasePart")
			end)
			if okModel and isModel then
				rockModels[#rockModels + 1] = inst
			elseif okPart and isPart then
				rockParts[#rockParts + 1] = inst
			end
		end
	end
end

local rockKindCounts = {}
for _, model in ipairs(rockModels) do
	local kind = attr(model, "RockKind")
	kind = type(kind) == "string" and kind or "?"
	rockKindCounts[kind] = (rockKindCounts[kind] or 0) + 1
end
emit(
	"ROCK_COUNT",
	rockFolder ~= nil and #rockModels >= ROCK_MIN,
	#rockModels,
	">=" .. ROCK_MIN,
	{ models = #rockModels, parts = #rockParts, perKind = rockKindCounts, folderPresent = rockFolder ~= nil }
)
local species = 0
for _ in pairs(rockKindCounts) do
	species += 1
end
emit(
	"ROCK_SPECIES",
	species >= ROCK_SPECIES_MIN,
	species,
	">=" .. ROCK_SPECIES_MIN,
	{ kinds = rockKindCounts, models = #rockModels }
)

local function rockHitsPath(box)
	for _, rect in ipairs(pathRects) do
		if
			box.maxX > rect.x - rect.halfX
			and box.minX < rect.x + rect.halfX
			and box.maxZ > rect.z - rect.halfZ
			and box.minZ < rect.z + rect.halfZ
		then
			return rect.name
		end
	end
	local centreX, centreZ = (box.minX + box.maxX) / 2, (box.minZ + box.maxZ) / 2
	local halfX, halfZ = (box.maxX - box.minX) / 2, (box.maxZ - box.minZ) / 2
	for index, seg in ipairs(pathSegments) do
		local dx, dz = centreX - seg.x, centreZ - seg.z
		local tangent = dx * seg.tx + dz * seg.tz
		local normal = dx * seg.nx + dz * seg.nz
		local tangentExtent = math.abs(seg.tx) * halfX + math.abs(seg.tz) * halfZ
		local normalExtent = math.abs(seg.nx) * halfX + math.abs(seg.nz) * halfZ
		if math.abs(tangent) < seg.halfLen + tangentExtent and math.abs(normal) < CENTRAL_HALF + normalExtent then
			return "RingRoad:" .. index
		end
	end
	return nil
end

local rockPathOverlaps, rockPathReadErrors = 0, 0
local rockPathOffenders, rockPathErrorNames = {}, {}
for _, part in ipairs(rockParts) do
	local box = bboxAABB(part)
	if not box then
		rockPathReadErrors += 1
		if #rockPathErrorNames < 10 then
			rockPathErrorNames[#rockPathErrorNames + 1] = tostring(part.Name) .. ":aabb"
		end
	elseif pathMapReady then
		local hit = rockHitsPath(box)
		if hit then
			rockPathOverlaps += 1
			if #rockPathOffenders < 10 then
				rockPathOffenders[#rockPathOffenders + 1] = string.format(
					"%s:%s:%.2f,%.2f",
					hit,
					tostring(part.Name),
					(box.minX + box.maxX) / 2,
					(box.minZ + box.maxZ) / 2
				)
			end
		end
	end
end
local rockPathReason = nil
if not rockFolder then
	rockPathReason = "staging folder missing"
elseif not pathMapReady then
	rockPathReason = pathMapReason or "MapSpec paths not readable"
elseif #rockParts == 0 then
	rockPathReason = "no staged rock parts"
end
emit(
	"ROCK_PATH_CLEAR",
	rockFolder ~= nil and pathMapReady and #rockParts > 0 and rockPathOverlaps == 0 and rockPathReadErrors == 0,
	rockPathOverlaps + rockPathReadErrors,
	0,
	{
		folderPresent = rockFolder ~= nil,
		parts = #rockParts,
		pathsChecked = pathMapReady and (#pathRects + #pathSegments) or 0,
		offenders = rockPathOffenders,
		readErrors = rockPathErrorNames,
		reason = rockPathReason,
	}
)

-- Prefer the real gate markers from plots_r8. Fall back to live PlotAnchor parts (their -Z side
-- is the entrance), then to Config.Game.plotCenter + ModelMapPlotsR8 plot depth.
do
	local rockGates = {}
	for _, part in ipairs(plotParts) do
		if attr(part, "Kind") == "gate_marker" then
			local okPos, pos = pcall(function()
				return part.CFrame.Position
			end)
			if okPos then
				rockGates[#rockGates + 1] = { x = pos.X, z = pos.Z, source = "marker" }
			end
		end
	end
	if #rockGates == 0 then
		for _, anchor in ipairs(taggedNear("PlotAnchor", Vector3.new(0, 0, 0), math.huge)) do
			local okGate, x, z = pcall(function()
				local cf, size = anchor:GetPivot(), anchor.Size
				local gate = cf * CFrame.new(0, 0, -(size.Z / 2 + 3))
				return gate.Position.X, gate.Position.Z
			end)
			if okGate then
				rockGates[#rockGates + 1] = { x = x, z = z, source = "PlotAnchor" }
			end
		end
	end
	if #rockGates == 0 then
		local okFallback, Plots, Game = pcall(function()
			return require(game.ReplicatedStorage.Shared.ModelMapPlotsR8),
				require(game.ReplicatedStorage.Shared.Config.Game)
		end)
		if okFallback and Plots and Game then
			for index = 1, Plots.PLOT_COUNT do
				local okCentre, x, z = pcall(Game.plotCenter, index)
				if okCentre and type(x) == "number" and type(z) == "number" then
					local frame = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.zero)
					local gate = frame * CFrame.new(0, 0, -(Plots.PLOT_DEPTH / 2 + 3))
					rockGates[#rockGates + 1] = { x = gate.Position.X, z = gate.Position.Z, source = "plotCenter" }
				end
			end
		end
	end

	local rockGateOffenders, rockGateErrors = {}, {}
	local rockGateHits, rockGateReadErrors = 0, 0
	local gateSource = rockGates[1] and rockGates[1].source or "none"
	for _, model in ipairs(rockModels) do
		local centre = bboxCentre(model)
		if not centre then
			rockGateReadErrors += 1
			if #rockGateErrors < 10 then
				rockGateErrors[#rockGateErrors + 1] = tostring(model.Name) .. ":bbox"
			end
		else
			for index, gate in ipairs(rockGates) do
				local dx, dz = centre.X - gate.x, centre.Z - gate.z
				if dx * dx + dz * dz < ROCK_GATE_CLEAR * ROCK_GATE_CLEAR then
					rockGateHits += 1
					if #rockGateOffenders < 10 then
						rockGateOffenders[#rockGateOffenders + 1] =
							string.format("gate%d:%s:%.2f,%.2f", index, tostring(model.Name), centre.X, centre.Z)
					end
					break
				end
			end
		end
	end
	local rockGateReason = nil
	if not rockFolder then
		rockGateReason = "staging folder missing"
	elseif #rockGates < ROCK_GATE_EXPECTED then
		rockGateReason = "only " .. #rockGates .. "/" .. ROCK_GATE_EXPECTED .. " plot gates readable"
	elseif #rockModels == 0 then
		rockGateReason = "no staged rock models"
	end
	emit(
		"ROCK_GATE_CLEAR",
		rockFolder ~= nil
			and #rockModels > 0
			and #rockGates >= ROCK_GATE_EXPECTED
			and rockGateHits == 0
			and rockGateReadErrors == 0,
		rockGateHits + rockGateReadErrors,
		0,
		{
			gates = #rockGates,
			gateSource = gateSource,
			clear = ROCK_GATE_CLEAR,
			models = #rockModels,
			offenders = rockGateOffenders,
			readErrors = rockGateErrors,
			reason = rockGateReason,
		}
	)
end

-- 9h. WORK_QUEUE section M item 80: streetfurn_r8. Three NEW READ-ONLY checks over the staged
-- LookDevStreetFurnR8_streetfurn_r8 folder. They reuse the PATH_CLEAR rectangle/chord tables and
-- bboxAABB CFrame+Size math; VergePost-tagged fixtures are the only clearance exemption, because
-- lampu/obor posts, the gapura and the pole line are DESIGNED to stand at the road verge.
do
	local SF_FOLDER = "LookDevStreetFurnR8_streetfurn_r8"
	local SF_KEY = "streetfurn_r8"
	local SF_CLEAR = 6
	local SF_MIN_POSTS = 18
	local SF_MIN_PER_POST_KIND = 8
	local SF_SIGN_EXPECTED = 3
	local SF_GAPURA_EXPECTED = 1
	local SF_POLE_MIN = 1
	local SF_CABLE_MIN = 1
	local SF_BALE_EXPECTED = 2

	local sfFolder = folderNamed(SF_FOLDER)
	local sfModels, sfParts = {}, {}
	local okSfDescendants, sfDescendants = pcall(function()
		if not sfFolder then
			return {}
		end
		return sfFolder:GetDescendants()
	end)
	if okSfDescendants and type(sfDescendants) == "table" then
		for _, inst in ipairs(sfDescendants) do
			if attr(inst, "StreetFurnR8") == SF_KEY then
				local okModel, isModel = pcall(function()
					return inst:IsA("Model")
				end)
				local okPart, isPart = pcall(function()
					return inst:IsA("BasePart")
				end)
				if okModel and isModel then
					sfModels[#sfModels + 1] = inst
				elseif okPart and isPart then
					sfParts[#sfParts + 1] = inst
				end
			end
		end
	end

	local sfKindCounts = { lampu = 0, obor = 0, sign = 0, gapura = 0, pole = 0, cable = 0, bale = 0 }
	for _, model in ipairs(sfModels) do
		local kind = attr(model, "StreetFurnKind")
		kind = type(kind) == "string" and kind or "?"
		sfKindCounts[kind] = (sfKindCounts[kind] or 0) + 1
	end
	local sfCableParts = 0
	for _, part in ipairs(sfParts) do
		if attr(part, "StreetFurnKind") == "cable" then
			sfCableParts += 1
		end
	end
	local sfPostTotal = sfKindCounts.lampu + sfKindCounts.obor
	emit(
		"STREETFURN",
		sfFolder ~= nil
			and sfPostTotal >= SF_MIN_POSTS
			and sfKindCounts.lampu >= SF_MIN_PER_POST_KIND
			and sfKindCounts.obor >= SF_MIN_PER_POST_KIND
			and sfKindCounts.sign == SF_SIGN_EXPECTED
			and sfKindCounts.gapura == SF_GAPURA_EXPECTED
			and sfKindCounts.pole >= SF_POLE_MIN
			and sfCableParts >= SF_CABLE_MIN
			and sfKindCounts.bale == SF_BALE_EXPECTED,
		sfPostTotal + sfKindCounts.sign + sfKindCounts.gapura + sfKindCounts.pole + sfCableParts + sfKindCounts.bale,
		">=" .. SF_MIN_POSTS .. " posts + all kinds",
		{
			folderPresent = sfFolder ~= nil,
			models = #sfModels,
			parts = #sfParts,
			perKind = sfKindCounts,
			cableParts = sfCableParts,
		}
	)

	-- STRINGS_PARITY: read the sign keys from Shared.Strings itself; no staged text literal is trusted.
	local SF_SIGN_KEYS = { "sign_pasar", "sign_sawah", "sign_balai" }
	local okSfStrings, sfStrings = pcall(function()
		return require(game.ReplicatedStorage.Shared.Strings)
	end)
	local sfValidKeys, sfKeyDetail = 0, {}
	if okSfStrings and sfStrings and type(sfStrings.raw) == "table" then
		for _, key in ipairs(SF_SIGN_KEYS) do
			local entry = sfStrings.raw[key]
			local valid = false
			if type(entry) == "table" and type(entry.id) == "string" and type(entry.en) == "string" then
				local id, en = entry.id, entry.en
				valid = id ~= ""
					and en ~= ""
					and string.match(id, "^%s") == nil
					and string.match(id, "%s$") == nil
					and string.match(en, "^%s") == nil
					and string.match(en, "%s$") == nil
					and string.find(string.upper(id .. " " .. en), "TODO", 1, true) == nil
					and id ~= en
				if valid then
					sfValidKeys += 1
				end
			else
				valid = false
			end
			sfKeyDetail[#sfKeyDetail + 1] = { key = key, valid = valid }
		end
	else
		sfKeyDetail[#sfKeyDetail + 1] = {
			key = "Shared.Strings",
			valid = false,
			reason = okSfStrings and "missing Strings.raw" or "Strings require failed",
		}
	end
	emit(
		"STRINGS_PARITY",
		sfValidKeys == #SF_SIGN_KEYS,
		sfValidKeys,
		#SF_SIGN_KEYS,
		{ keys = sfKeyDetail, stringsReadable = okSfStrings == true }
	)

	-- STREETFURN_CLEAR: distance from each non-exempt staged part's XZ AABB to a MapSpec road
	-- centreline. Rectangles cover the four arms and two continuations; ring chords use the same axes
	-- as PATH_CLEAR/ROCK_PATH_CLEAR. VergePost is set only on posts, gapura and the pole/cable line.
	local function sfAabbDistanceToRoad(box)
		local best = math.huge
		for _, rect in ipairs(pathRects) do
			local gapX, gapZ
			if rect.horizontal then
				gapX = math.max(rect.x - rect.halfX - box.maxX, box.minX - (rect.x + rect.halfX), 0)
				gapZ = math.max(box.minZ - rect.z, rect.z - box.maxZ, 0)
			else
				gapX = math.max(box.minX - rect.x, rect.x - box.maxX, 0)
				gapZ = math.max(rect.z - rect.halfZ - box.maxZ, box.minZ - (rect.z + rect.halfZ), 0)
			end
			best = math.min(best, math.sqrt(gapX * gapX + gapZ * gapZ))
		end
		local centreX, centreZ = (box.minX + box.maxX) / 2, (box.minZ + box.maxZ) / 2
		local halfX, halfZ = (box.maxX - box.minX) / 2, (box.maxZ - box.minZ) / 2
		for _, seg in ipairs(pathSegments) do
			local dx, dz = centreX - seg.x, centreZ - seg.z
			local tangent = dx * seg.tx + dz * seg.tz
			local perpendicular = dx * seg.nx + dz * seg.nz
			local tangentExtent = math.abs(seg.tx) * halfX + math.abs(seg.tz) * halfZ
			local normalExtent = math.abs(seg.nx) * halfX + math.abs(seg.nz) * halfZ
			local along = math.max(math.abs(tangent) - seg.halfLen - tangentExtent, 0)
			local across = math.max(math.abs(perpendicular) - normalExtent, 0)
			best = math.min(best, math.sqrt(along * along + across * across))
		end
		return best
	end

	local sfOffenders, sfReadErrors = {}, {}
	local sfChecked, sfExempt, sfNearHits = 0, { lampu = 0, obor = 0, gapura = 0, pole = 0, cable = 0 }, 0
	for _, part in ipairs(sfParts) do
		local kind = attr(part, "StreetFurnKind")
		kind = type(kind) == "string" and kind or "?"
		if attr(part, "VergePost") == true then
			sfExempt[kind] = (sfExempt[kind] or 0) + 1
		else
			sfChecked += 1
			local box = bboxAABB(part)
			if not box then
				sfReadErrors[#sfReadErrors + 1] = tostring(part.Name) .. ":aabb"
			elseif pathMapReady then
				local distance = sfAabbDistanceToRoad(box)
				if distance < SF_CLEAR then
					sfNearHits += 1
					if #sfOffenders < 10 then
						sfOffenders[#sfOffenders + 1] = string.format(
							"%s:%s:%.2f,%.2f:d=%.2f",
							kind,
							tostring(part.Name),
							(box.minX + box.maxX) / 2,
							(box.minZ + box.maxZ) / 2,
							distance
						)
					end
				end
			end
		end
	end
	local sfClearReason = nil
	if not sfFolder then
		sfClearReason = "staging folder missing"
	elseif not pathMapReady then
		sfClearReason = pathMapReason or "MapSpec paths not readable"
	elseif sfChecked == 0 then
		sfClearReason = "no non-exempt staged parts"
	end
	emit(
		"STREETFURN_CLEAR",
		sfFolder ~= nil and pathMapReady and sfChecked > 0 and sfNearHits == 0 and #sfReadErrors == 0,
		sfNearHits + #sfReadErrors,
		0,
		{
			folderPresent = sfFolder ~= nil,
			checkedParts = sfChecked,
			pathsChecked = pathMapReady and (#pathRects + #pathSegments) or 0,
			clear = SF_CLEAR,
			exempt = sfExempt,
			exemptWhy = "lampu/obor posts, gapura and the pole/cable line are staged on the road verge by item 80",
			offenders = sfOffenders,
			readErrors = sfReadErrors,
			reason = sfClearReason,
		}
	)
end

do
-- 9h-2. WORK_QUEUE section M item 81: spanduk_r8. Two NEW READ-ONLY checks over the staged
-- LookDevSpandukR8_spanduk_r8 folder. SIGN_TEXT_PARITY reads every item-81 Strings key (plus the
-- staged SignKey attributes) from Shared.Strings; SIGN_FACING measures each staged sign board's
-- board LookVector against the horizontal direction to its named approach camera. Both FAIL when
-- the folder, tags, Strings or ReviewCameras (Server VM) are missing; no check is weakened.
local SD_FOLDER = "LookDevSpandukR8_spanduk_r8"
local SD_KEY = "spanduk_r8"
local SD_EXPECTED_KEYS = {
	"spanduk_selamat_datang",
	"sign_warung",
	"spanduk_pasar",
	"bunting_mampir",
	"bunting_belanja",
}
local SD_MAX_ANGLE = 30

local sdFolder = folderNamed(SD_FOLDER)
local sdModels = {}
local okSd, sdDescendants = pcall(function()
	if not sdFolder then
		return {}
	end
	return sdFolder:GetDescendants()
end)
if okSd and type(sdDescendants) == "table" then
	for _, inst in ipairs(sdDescendants) do
		if attr(inst, "SpandukR8") == SD_KEY then
			local okModel, isModel = pcall(function()
				return inst:IsA("Model")
			end)
			if okModel and isModel then
				sdModels[#sdModels + 1] = inst
			end
		end
	end
end

-- SIGN_TEXT_PARITY: every expected Strings key has a non-empty id AND en, every staged sign's
-- SignKey is one of those keys, and at least one sign is staged. No staged text literal is trusted.
local okSdStrings, sdStrings = pcall(function()
	return require(game.ReplicatedStorage.Shared.Strings)
end)
local sdValidKeys, sdKeyDetail = 0, {}
if okSdStrings and sdStrings and type(sdStrings.raw) == "table" then
	for _, key in ipairs(SD_EXPECTED_KEYS) do
		local entry = sdStrings.raw[key]
		local valid = false
		if type(entry) == "table" and type(entry.id) == "string" and type(entry.en) == "string" then
			local id, en = entry.id, entry.en
			valid = id ~= ""
				and en ~= ""
				and string.match(id, "^%s") == nil
				and string.match(id, "%s$") == nil
				and string.match(en, "^%s") == nil
				and string.match(en, "%s$") == nil
				and string.find(string.upper(id .. " " .. en), "TODO", 1, true) == nil
				and id ~= en
			if valid then
				sdValidKeys += 1
			end
		end
		sdKeyDetail[#sdKeyDetail + 1] = { key = key, valid = valid }
	end
else
	sdKeyDetail[#sdKeyDetail + 1] = {
		key = "Shared.Strings",
		valid = false,
		reason = okSdStrings and "missing Strings.raw" or "Strings require failed",
	}
end
local sdStagedKeys, sdUnknownKeys = {}, {}
local sdSignCount = 0
for _, model in ipairs(sdModels) do
	if attr(model, "ApproachCamera") then
		sdSignCount += 1
		local key = attr(model, "SignKey")
		if type(key) == "string" then
			sdStagedKeys[#sdStagedKeys + 1] = key
			local known = false
			for _, expected in ipairs(SD_EXPECTED_KEYS) do
				if expected == key then
					known = true
					break
				end
			end
			if not known then
				sdUnknownKeys[#sdUnknownKeys + 1] = key
			end
		end
	end
end
emit(
	"SIGN_TEXT_PARITY",
	okSdStrings == true
		and sdFolder ~= nil
		and sdSignCount > 0
		and sdValidKeys == #SD_EXPECTED_KEYS
		and #sdUnknownKeys == 0,
	sdValidKeys,
	#SD_EXPECTED_KEYS,
	{
		keys = sdKeyDetail,
		stagedKeys = sdStagedKeys,
		unknownStagedKeys = sdUnknownKeys,
		stagedSigns = sdSignCount,
		stringsReadable = okSdStrings == true,
	}
)

-- SIGN_FACING: for each staged sign Model with an ApproachCamera attribute, require that named
-- camera to be readable (Server VM), take the board's front normal from its cf.LookVector
-- projected to XZ, and require the angle to the horizontal sign->camera direction to be <= 30deg.
local sdServer = false
do
	local okRs, rs = pcall(function()
		return game:GetService("RunService")
	end)
	if okRs and rs then
		local okFlag, flag = pcall(function()
			return rs:IsServer()
		end)
		sdServer = okFlag and flag == true
	end
end
local okSdCameras, sdCameras = false, nil
if sdServer then
	okSdCameras, sdCameras = pcall(function()
		return require(game.ReplicatedStorage.Shared.ReviewCameras)
	end)
end

local sdAngles, sdFacingFails = {}, {}
local sdFacingChecked = 0
for _, model in ipairs(sdModels) do
	local camName = attr(model, "ApproachCamera")
	if type(camName) == "string" and camName ~= "" then
		sdFacingChecked += 1
		local centre = bboxCentre(model)
		local board = nil
		for _, child in ipairs(descendantList(model)) do
			local okPart, isPart = pcall(function()
				return child:IsA("BasePart")
			end)
			if okPart and isPart and child.Name == "Board" then
				board = child
				break
			end
		end
		local camera = nil
		if okSdCameras and sdCameras and type(sdCameras.get) == "function" then
			local okGet, got = pcall(function()
				return sdCameras.get(camName)
			end)
			if okGet then
				camera = got
			end
		end
		local eye = camera and asVector3(camera.position) or nil
		local angle = nil
		if board and centre and eye then
			local okCf, cf = pcall(function()
				return board.CFrame
			end)
			if okCf and cf then
				local look = cf.LookVector
				local nx, nz = look.X, look.Z
				local nlen = math.sqrt(nx * nx + nz * nz)
				local dx, dz = eye.X - centre.X, eye.Z - centre.Z
				local dlen = math.sqrt(dx * dx + dz * dz)
				if nlen > 1e-6 and dlen > 1e-6 then
					local dot = (nx * dx + nz * dz) / (nlen * dlen)
					dot = math.max(-1, math.min(1, dot))
					angle = math.deg(math.acos(dot))
				end
			end
		end
		if angle == nil then
			sdFacingFails[#sdFacingFails + 1] = camName .. ":unreadable"
		else
			sdAngles[#sdAngles + 1] = { camera = camName, angle = math.floor(angle * 100) / 100 }
			if angle > SD_MAX_ANGLE then
				sdFacingFails[#sdFacingFails + 1] = string.format("%s:%.1f", camName, angle)
			end
		end
	end
end
local sdWorst = 0
for _, entry in ipairs(sdAngles) do
	sdWorst = math.max(sdWorst, entry.angle)
end
local sdFacingReason = nil
if not sdFolder then
	sdFacingReason = "staging folder missing"
elseif not sdServer or not okSdCameras then
	sdFacingReason = "ReviewCameras not readable (Server VM required)"
elseif sdFacingChecked == 0 then
	sdFacingReason = "no staged sign with ApproachCamera"
end
emit(
	"SIGN_FACING",
	sdFolder ~= nil and sdServer and okSdCameras and sdFacingChecked > 0 and #sdFacingFails == 0,
	#sdAngles > 0 and math.floor(sdWorst * 100) / 100 or "ERR",
	"<=" .. SD_MAX_ANGLE .. "deg",
	{ checked = sdFacingChecked, angles = sdAngles, failures = sdFacingFails, reason = sdFacingReason }
)
end

do
-- 9h-3. WORK_QUEUE section M item 82: animals_r8. Three NEW READ-ONLY checks in the SERVER VM.
-- MapSpec lives under ServerScriptService.Server.World and the shared animal module is pure, so
-- requiring both fails in the Client VM. No staging, no folder mutation and no 60-second wait:
-- the horizon is a deterministic stepAll() simulation measured with os.clock.
local AR8_MODULE = nil
local okAr8Module, ar8Module = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapAnimalsR8)
end)
if okAr8Module and type(ar8Module) == "table" then
	AR8_MODULE = ar8Module
end
local AR8_BOUNDS = nil
if AR8_MODULE and mapSpecReady and type(AR8_MODULE.bounds) == "function" then
	local okBounds, built = pcall(function()
		return AR8_MODULE.bounds(MapSpec)
	end)
	if okBounds and type(built) == "table" then
		AR8_BOUNDS = built
	end
end
local AR8_STATES = {}
local ar8Reason = nil
if not AR8_MODULE then
	ar8Reason = "Shared.ModelMapAnimalsR8 not readable"
elseif not AR8_BOUNDS then
	ar8Reason = "MapSpec bounds not readable (Server VM required)"
else
	local okSpawn, spawned = pcall(function()
		return AR8_MODULE.spawn(MapSpec)
	end)
	if okSpawn and type(spawned) == "table" and #spawned > 0 then
		AR8_STATES = spawned
	else
		ar8Reason = "spawn failed: " .. tostring(spawned)
	end
end

-- ANIMAL_COUNT: 1..14 animals, each with a known kind. Detail carries per-kind counts.
local ar8ValidKinds = 0
local ar8Counts = {}
if AR8_MODULE then
	for _, kind in ipairs(AR8_MODULE.KINDS or {}) do
		ar8Counts[kind] = 0
	end
end
for _, state in ipairs(AR8_STATES) do
	local kind = state.kind
	if ar8Counts[kind] == nil then
		ar8Counts[kind] = 0
	end
	ar8Counts[kind] += 1
	local known = false
	if AR8_MODULE then
		for _, expected in ipairs(AR8_MODULE.KINDS or {}) do
			if expected == kind then
				known = true
				break
			end
		end
	end
	if known then
		ar8ValidKinds += 1
	end
end
local ar8CountPass = AR8_MODULE ~= nil
	and #AR8_STATES > 0
	and #AR8_STATES <= AR8_MODULE.MAX_ANIMALS
	and ar8ValidKinds == #AR8_STATES
emit(
	"ANIMAL_COUNT",
	ar8CountPass,
	#AR8_STATES,
	"1.." .. tostring(AR8_MODULE and AR8_MODULE.MAX_ANIMALS or 14),
	{ counts = ar8Counts, validKinds = ar8ValidKinds, reason = ar8Reason }
)

-- ANIMAL_BOUNDS + ANIMAL_COST: one 60-second deterministic sim (3600 steps at 1/60 s). Track every
-- intermediate position, never only the final one; measure the whole loop with os.clock.
local AR8_SECONDS = AR8_MODULE and AR8_MODULE.SIM_SECONDS or 60
local AR8_DT = AR8_MODULE and AR8_MODULE.DT or (1 / 60)
local AR8_TOL = AR8_MODULE and AR8_MODULE.BOUND_TOLERANCE or 0.05
local ar8Steps = math.max(1, math.ceil(AR8_SECONDS / AR8_DT))
local ar8MinX, ar8MaxX = math.huge, -math.huge
local ar8MinZ, ar8MaxZ = math.huge, -math.huge
local ar8MinY, ar8MaxY = math.huge, -math.huge
local ar8Offenders = {}
local function ar8Track()
	for _, state in ipairs(AR8_STATES) do
		local p = state.position
		ar8MinX, ar8MaxX = math.min(ar8MinX, p.x), math.max(ar8MaxX, p.x)
		ar8MinZ, ar8MaxZ = math.min(ar8MinZ, p.z), math.max(ar8MaxZ, p.z)
		ar8MinY, ar8MaxY = math.min(ar8MinY, p.y), math.max(ar8MaxY, p.y)
		if
			math.abs(p.x) > MapSpec.TERRAIN_HALF + AR8_TOL
			or math.abs(p.z) > MapSpec.TERRAIN_HALF + AR8_TOL
			or p.y < MapSpec.GROUND_Y - AR8_TOL
		then
			if #ar8Offenders < 8 then
				ar8Offenders[#ar8Offenders + 1] = string.format(
					"%s@%.2f,%.2f,%.2f",
					tostring(state.id),
					p.x,
					p.y,
					p.z
				)
			end
		end
	end
end
local ar8Elapsed = 0
local ar8SimOk = AR8_MODULE ~= nil and AR8_BOUNDS ~= nil and #AR8_STATES > 0 and mapSpecReady
if ar8SimOk then
	ar8Track()
	local started = os.clock()
	for _ = 1, ar8Steps do
		AR8_MODULE.stepAll(AR8_STATES, AR8_DT, AR8_BOUNDS)
		ar8Track()
	end
	ar8Elapsed = os.clock() - started
end
emit(
	"ANIMAL_BOUNDS",
	ar8SimOk and #ar8Offenders == 0,
	#ar8Offenders,
	0,
	{
		seconds = AR8_SECONDS,
		dt = AR8_DT,
		steps = ar8Steps,
		tolerance = AR8_TOL,
		minX = ar8MinX == math.huge and "ERR" or math.floor(ar8MinX * 100) / 100,
		maxX = ar8MaxX == -math.huge and "ERR" or math.floor(ar8MaxX * 100) / 100,
		minZ = ar8MinZ == math.huge and "ERR" or math.floor(ar8MinZ * 100) / 100,
		maxZ = ar8MaxZ == -math.huge and "ERR" or math.floor(ar8MaxZ * 100) / 100,
		minY = ar8MinY == math.huge and "ERR" or math.floor(ar8MinY * 100) / 100,
		maxY = ar8MaxY == -math.huge and "ERR" or math.floor(ar8MaxY * 100) / 100,
		offenders = ar8Offenders,
		reason = ar8Reason,
	}
)
local ar8MsPerStep = ar8SimOk and (ar8Elapsed * 1000 / ar8Steps) or math.huge
emit(
	"ANIMAL_COST",
	ar8SimOk and ar8MsPerStep < (AR8_MODULE and AR8_MODULE.MAX_STEP_MS or 0.3),
	math.floor(ar8MsPerStep * 10000) / 10000,
	"<" .. tostring(AR8_MODULE and AR8_MODULE.MAX_STEP_MS or 0.3) .. "ms",
	{
		totalMs = math.floor(ar8Elapsed * 1000 * 100) / 100,
		steps = ar8Steps,
		animals = #AR8_STATES,
		msPerStep = ar8MsPerStep,
		reason = ar8Reason,
	}
)
end

do
-- 9h-4. WORK_QUEUE section M item 83: flyers_r8. Two NEW READ-ONLY checks in the SERVER VM.
-- MapSpec lives under ServerScriptService.Server.World and the shared flyer module is pure, so
-- requiring either fails in the Client VM. No staging and no 60-second real-time wait.
local FR8 = nil
local okF8, f8Module = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapFlyersR8)
end)
if okF8 and type(f8Module) == "table" then
	FR8 = f8Module
end
local FR8_TIERS = FR8 and FR8.TIERS or { "Rendah", "Sedang", "Tinggi" }
local fr8Tiers, fr8Bad = {}, {}
local fr8Reason = nil
if not FR8 then
	fr8Reason = "Shared.ModelMapFlyersR8 not readable"
elseif not mapSpecReady then
	fr8Reason = "MapSpec not readable (Server VM required)"
else
	for _, tier in ipairs(FR8_TIERS) do
		local okSpawn, spawned = pcall(function()
			return FR8.spawn(MapSpec, tier)
		end)
		local okCaps, cap = pcall(function()
			return FR8.caps(tier)
		end)
		local okCounts, counts = pcall(function()
			if type(spawned) ~= "table" then
				return nil
			end
			return FR8.kindCounts(spawned)
		end)
		fr8Tiers[tier] = {
			counts = okCounts and type(counts) == "table" and counts or "ERR",
			caps = type(cap) == "table" and cap or "ERR",
			total = type(spawned) == "table" and #spawned or "ERR",
		}
		if
			not okSpawn
			or type(spawned) ~= "table"
			or #spawned == 0
			or not okCaps
			or type(cap) ~= "table"
			or not okCounts
			or type(counts) ~= "table"
		then
			fr8Bad[#fr8Bad + 1] = tier .. ":spawn"
		else
			for _, kind in ipairs(FR8.KINDS or {}) do
				local n, limit = counts[kind] or 0, cap[kind] or 0
				if n < 1 or n > limit then
					fr8Bad[#fr8Bad + 1] = string.format("%s:%s=%d/%d", tostring(tier), tostring(kind), n, limit)
				end
			end
		end
	end
end
emit(
	"FLYER_COUNT",
	FR8 ~= nil and #fr8Bad == 0,
	#fr8Bad,
	"0 invalid tiers",
	{ tiers = fr8Tiers, failures = fr8Bad, reason = fr8Reason }
)

-- FLYER_COST: 60 seconds at 1/60 s on the largest tier's flyers, timed with os.clock.
local FR8_BOUNDS, FR8_STATES = nil, {}
if FR8 and mapSpecReady then
	local okBounds, built = pcall(function()
		return FR8.bounds(MapSpec)
	end)
	if okBounds and type(built) == "table" then
		FR8_BOUNDS = built
	end
	local okSpawn, spawned = pcall(function()
		return FR8.spawn(MapSpec, FR8_TIERS[#FR8_TIERS])
	end)
	if okSpawn and type(spawned) == "table" then
		FR8_STATES = spawned
	else
		fr8Reason = "largest-tier spawn failed: " .. tostring(spawned)
	end
end
local FR8_SECONDS = FR8 and FR8.SIM_SECONDS or 60
local FR8_DT = FR8 and FR8.DT or (1 / 60)
local fr8Steps = math.max(1, math.ceil(FR8_SECONDS / FR8_DT))
local fr8Elapsed = 0
local fr8Ok = FR8 ~= nil and FR8_BOUNDS ~= nil and #FR8_STATES > 0 and mapSpecReady
if fr8Ok then
	local started = os.clock()
	local okSim, simErr = pcall(function()
		for _ = 1, fr8Steps do
			FR8.stepAll(FR8_STATES, FR8_DT, FR8_BOUNDS)
		end
	end)
	fr8Elapsed = os.clock() - started
	if not okSim then
		fr8Ok = false
		fr8Reason = "stepAll failed: " .. tostring(simErr)
	end
end
local fr8Limit = FR8 and FR8.MAX_STEP_MS or 0.3
local fr8Ms = fr8Ok and (fr8Elapsed * 1000 / fr8Steps) or math.huge
emit(
	"FLYER_COST",
	fr8Ok and fr8Ms < fr8Limit,
	math.floor(fr8Ms * 10000) / 10000,
	"<" .. tostring(fr8Limit) .. "ms",
	{
		totalMs = math.floor(fr8Elapsed * 1000 * 100) / 100,
		steps = fr8Steps,
		flyers = #FR8_STATES,
		msPerStep = fr8Ms,
		reason = fr8Reason,
	}
)
end

do
-- 9h-5. WORK_QUEUE section M item 84: smoke_r8. Three NEW READ-ONLY pure-data checks.
-- Shared.ModelMapSmokeR8 is pure and MapSpec lives in ServerScriptService.Server.World, so all
-- three lines run in the SERVER VM with no staged candidate, no folder mutation and no real wait.
-- A missing module or MapSpec FAILs at measured >= 1, never a vacuous pass.
local SR8 = nil
local okS8, s8Module = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapSmokeR8)
end)
if okS8 and type(s8Module) == "table" then
	SR8 = s8Module
end
local SR8_BUILT, SR8_REASON = nil, nil
if not SR8 then
	SR8_REASON = "Shared.ModelMapSmokeR8 not readable"
elseif not mapSpecReady then
	SR8_REASON = "MapSpec not readable (Server VM required)"
else
	local okBuilt, built = pcall(function()
		return SR8.recipes(MapSpec)
	end)
	if
		okBuilt
		and type(built) == "table"
		and type(built.emitters) == "table"
		and type(built.lights) == "table"
	then
		SR8_BUILT = built
	else
		SR8_REASON = "recipes failed: " .. tostring(built)
	end
end

-- EMITTERS: <= 12 total, every Rate <= 12, at least two chimneys, one steam and one torch flame.
local SR8_EMITTERS = SR8_BUILT and SR8_BUILT.emitters or {}
local SR8_KINDS = { chimney = 0, steam = 0, torch_flame = 0 }
local SR8_BAD_EMITTERS = {}
local SR8_MAX_RATE = 0
for _, spec in ipairs(SR8_EMITTERS) do
	local kind = type(spec) == "table" and spec.kind or "unknown"
	SR8_KINDS[kind] = (SR8_KINDS[kind] or 0) + 1
	local rate = type(spec) == "table" and spec.rate or math.huge
	if type(rate) == "number" then
		SR8_MAX_RATE = math.max(SR8_MAX_RATE, rate)
	end
	local position = type(spec) == "table" and spec.position or nil
	if
		not SR8_BUILT
		or type(spec) ~= "table"
		or type(rate) ~= "number"
		or rate <= 0
		or rate > (SR8 and SR8.MAX_RATE or 12)
		or type(position) ~= "table"
		or type(position.x) ~= "number"
		or type(position.y) ~= "number"
		or type(position.z) ~= "number"
	then
		SR8_BAD_EMITTERS[#SR8_BAD_EMITTERS + 1] = tostring(kind) .. ":rate=" .. tostring(rate)
	end
end
local SR8_EMITTER_VIOLATIONS = #SR8_BAD_EMITTERS
if SR8_BUILT then
	if #SR8_EMITTERS > (SR8 and SR8.MAX_EMITTERS or 12) then
		SR8_EMITTER_VIOLATIONS += 1
	end
	if SR8_KINDS.chimney < 2 then
		SR8_EMITTER_VIOLATIONS += 1
	end
	if SR8_KINDS.steam < 1 then
		SR8_EMITTER_VIOLATIONS += 1
	end
	if SR8_KINDS.torch_flame < 1 then
		SR8_EMITTER_VIOLATIONS += 1
	end
else
	SR8_EMITTER_VIOLATIONS += 1
end
emit(
	"EMITTERS",
	SR8_EMITTER_VIOLATIONS == 0,
	SR8_EMITTER_VIOLATIONS,
	"0 violations",
	{
		count = #SR8_EMITTERS,
		chimney = SR8_KINDS.chimney,
		steam = SR8_KINDS.steam,
		torchFlame = SR8_KINDS.torch_flame,
		maxRate = SR8_MAX_RATE,
		failures = SR8_BAD_EMITTERS,
		reason = SR8_REASON,
	}
)

-- LIGHTS: <= 24 total, every Range <= 30, at least one light, deterministic per-light seed.
local SR8_LIGHTS = SR8_BUILT and SR8_BUILT.lights or {}
local SR8_BAD_LIGHTS = {}
local SR8_MAX_RANGE = 0
for _, spec in ipairs(SR8_LIGHTS) do
	local range = type(spec) == "table" and spec.range or math.huge
	if type(range) == "number" then
		SR8_MAX_RANGE = math.max(SR8_MAX_RANGE, range)
	end
	if
		not SR8_BUILT
		or type(spec) ~= "table"
		or type(range) ~= "number"
		or range <= 0
		or range > (SR8 and SR8.MAX_RANGE or 30)
		or type(spec.seed) ~= "number"
	then
		SR8_BAD_LIGHTS[#SR8_BAD_LIGHTS + 1] = tostring(spec and spec.id or "?") .. ":range=" .. tostring(range)
	end
end
local SR8_LIGHT_VIOLATIONS = #SR8_BAD_LIGHTS
if SR8_BUILT then
	if #SR8_LIGHTS > (SR8 and SR8.MAX_LIGHTS or 24) then
		SR8_LIGHT_VIOLATIONS += 1
	end
	if #SR8_LIGHTS < 1 then
		SR8_LIGHT_VIOLATIONS += 1
	end
else
	SR8_LIGHT_VIOLATIONS += 1
end
emit(
	"LIGHTS",
	SR8_LIGHT_VIOLATIONS == 0,
	SR8_LIGHT_VIOLATIONS,
	"0 violations",
	{ count = #SR8_LIGHTS, maxRange = SR8_MAX_RANGE, failures = SR8_BAD_LIGHTS, reason = SR8_REASON }
)

-- TORCH_NIGHT: the pure day-off predicate. ClockTime 13 must be false, 20 and 5 true.
local SR8_CLOCKS = { day13 = "ERR", night20 = "ERR", preDawn5 = "ERR" }
local SR8_NIGHT_OK = false
if SR8 and type(SR8.isNight) == "function" then
	local ok13, day13 = pcall(function()
		return SR8.isNight(13)
	end)
	local ok20, night20 = pcall(function()
		return SR8.isNight(20)
	end)
	local ok5, preDawn5 = pcall(function()
		return SR8.isNight(5)
	end)
	SR8_CLOCKS.day13 = ok13 and tostring(day13) or "ERR"
	SR8_CLOCKS.night20 = ok20 and tostring(night20) or "ERR"
	SR8_CLOCKS.preDawn5 = ok5 and tostring(preDawn5) or "ERR"
	SR8_NIGHT_OK = ok13 and day13 == false and ok20 and night20 == true and ok5 and preDawn5 == true
end
emit(
	"TORCH_NIGHT",
	SR8_NIGHT_OK,
	string.format(
		"13=%s 20=%s 5=%s",
		SR8_CLOCKS.day13,
		SR8_CLOCKS.night20,
		SR8_CLOCKS.preDawn5
	),
	"13 off / 20 on / 5 on",
	{ readings = SR8_CLOCKS, reason = SR8_REASON }
)
end

do
-- 9i. WORK_QUEUE section N item 108: lapangan_r8. THREE checks over the staged
-- LookDevLapanganR8_lapangan_r8 folder: LAPANGAN_PARTS counts every tagged part per kind against
-- Shared.ModelMapLapanganR8.counts(); LAPANGAN_PATH_REACH builds five MapSpec.LAPANGAN/ROAD walking
-- corridors and requires zero staged parts inside them (stricter than a collidable-only test
-- because all staged parts are non-collidable by construction); LAPANGAN_GOAL_SIZE measures the two
-- goal Models' bbox height against GOAL_HEIGHT = 15.95 with 0.5 stud tolerance. This block stages
-- the candidate and restores the prior single candidate at the end; every failure path emits all
-- three lines, so none is a vacuous pass.
local LAPANGAN_FOLDER = "LookDevLapanganR8_lapangan_r8"
local LAPANGAN_ID = "lapangan_r8"
local LAPANGAN_GOAL_TOL = 0.5
local LAPANGAN_FALLBACK_KINDS = { "goal", "flagpole", "bench", "stone", "sand" }

local okLapanganModules, lapanganModules = pcall(function()
	return {
		data = require(game.ReplicatedStorage.Shared.ModelMapLapanganR8),
		look = require(game.ReplicatedStorage.Shared.LookDev),
		review = require(game.ReplicatedStorage.Shared.LookDevReview),
	}
end)
local lapanganData: any? = nil
if okLapanganModules and type(lapanganModules) == "table" and type(lapanganModules.data) == "table" then
	lapanganData = lapanganModules.data
end
local lapanganExpected: any? = nil
if lapanganData and type(lapanganData.counts) == "function" then
	local okCounts, counts = pcall(function()
		return (lapanganData :: any).counts()
	end)
	if okCounts and type(counts) == "table" then
		lapanganExpected = counts
	end
end

local function lapanganFail(reason)
	local measuredParts, targetParts = {}, {}
	local kinds = LAPANGAN_FALLBACK_KINDS
	if lapanganData and type((lapanganData :: any).KINDS) == "table" then
		kinds = (lapanganData :: any).KINDS
	end
	for _, kind in ipairs(kinds) do
		measuredParts[#measuredParts + 1] = kind .. "=0"
		targetParts[#targetParts + 1] = kind .. "=" .. tostring(lapanganExpected and lapanganExpected[kind] or "?")
	end
	local detail = { reason = reason, folderPresent = folderNamed(LAPANGAN_FOLDER) ~= nil }
	emit("LAPANGAN_PARTS", false, table.concat(measuredParts, " "), table.concat(targetParts, " "), detail)
	emit("LAPANGAN_PATH_REACH", false, 1, 0, detail)
	emit("LAPANGAN_GOAL_SIZE", false, 0, lapanganData and (lapanganData :: any).GOAL_HEIGHT or 15.95, detail)
end

local lapanganRunService = service("RunService")
local okLapanganServer, lapanganIsServer = false, false
if lapanganRunService then
	okLapanganServer, lapanganIsServer = pcall(function()
		return (lapanganRunService :: any):IsServer()
	end)
end
local lapanganLook = okLapanganModules and (lapanganModules :: any).look or nil
local lapanganReview = okLapanganModules and (lapanganModules :: any).review or nil
if
	not lapanganData
	or not lapanganExpected
	or not okLapanganServer
	or not lapanganIsServer
	or type(lapanganLook) ~= "table"
	or type(lapanganLook.enable) ~= "function"
	or type(lapanganLook.disable) ~= "function"
	or type(lapanganReview) ~= "table"
	or type(lapanganReview.enable) ~= "function"
then
	lapanganFail("server VM / lapangan modules / counts not readable")
else
	local okPrior, priorId = pcall(function()
		return (lapanganLook :: any).current and (lapanganLook :: any).current() or nil
	end)
	if not okPrior then
		priorId = nil
	end
	local function restoreLapanganPrior()
		pcall(function()
			(lapanganLook :: any).disable()
		end)
		if type(priorId) == "string" then
			pcall(function()
				(lapanganLook :: any).enable(priorId)
			end)
		end
	end
	local okEnable, enabled, whyEnable = pcall(function()
		return (lapanganReview :: any).enable("lapangan_r8", game, { studio = true })
	end)
	if not okEnable or enabled == false then
		restoreLapanganPrior()
		lapanganFail("enable:" .. tostring(whyEnable or enabled))
	else
		local lapanganFolder = folderNamed(LAPANGAN_FOLDER)
		local taggedParts, goalModels = {}, {}
		local countsByKind = {}
		for _, kind in ipairs((lapanganData :: any).KINDS) do
			countsByKind[kind] = 0
		end
		for _, inst in ipairs(descendantList(lapanganFolder)) do
			local kind = attr(inst, (lapanganData :: any).kindAttribute)
			if type(kind) == "string" and countsByKind[kind] ~= nil then
				local okPart, isPart = pcall(function()
					return (inst :: any):IsA("BasePart")
				end)
				if okPart and isPart then
					countsByKind[kind] += 1
					taggedParts[#taggedParts + 1] = inst
				end
			end
			local okModel, isModel = pcall(function()
				return (inst :: any):IsA("Model")
			end)
			if okModel and isModel and attr(inst, (lapanganData :: any).goalAttribute) == LAPANGAN_ID then
				goalModels[#goalModels + 1] = inst
			end
		end
		local measuredParts, targetParts = {}, {}
		local partsPass = lapanganFolder ~= nil
		for _, kind in ipairs((lapanganData :: any).KINDS) do
			local got, want = countsByKind[kind] or 0, (lapanganExpected :: any)[kind] or 0
			measuredParts[#measuredParts + 1] = kind .. "=" .. tostring(got)
			targetParts[#targetParts + 1] = kind .. "=" .. tostring(want)
			if got ~= want then
				partsPass = false
			end
		end
		emit(
			"LAPANGAN_PARTS",
			partsPass,
			table.concat(measuredParts, " "),
			table.concat(targetParts, " "),
			{
				folderPresent = lapanganFolder ~= nil,
				parts = #taggedParts,
				goals = #goalModels,
				byKind = countsByKind,
			}
		)

		-- MapSpec.LAPANGAN is axis-aligned; the pure rectangles are field-local, so add its centre.
		local corridorBoxes = {}
		local okCorridors, rows = pcall(function()
			return (lapanganData :: any).corridors()
		end)
		local corridorsReady = okCorridors and type(rows) == "table" and #rows > 0 and mapSpecReady and type(MapSpec.LAPANGAN) == "table"
		if corridorsReady then
			for _, row in ipairs(rows) do
				if
					type(row) ~= "table"
					or type(row.minX) ~= "number"
					or type(row.maxX) ~= "number"
					or type(row.minZ) ~= "number"
					or type(row.maxZ) ~= "number"
				then
					corridorsReady = false
					break
				end
				corridorBoxes[#corridorBoxes + 1] = {
					name = tostring(row.name or #corridorBoxes + 1),
					minX = MapSpec.LAPANGAN.x + row.minX,
					maxX = MapSpec.LAPANGAN.x + row.maxX,
					minZ = MapSpec.LAPANGAN.z + row.minZ,
					maxZ = MapSpec.LAPANGAN.z + row.maxZ,
				}
			end
		end
		local blockedCorridors = 0
		local blockedByCorridor = {}
		if not corridorsReady or lapanganFolder == nil or #taggedParts == 0 or #corridorBoxes == 0 then
			blockedCorridors = math.max(1, blockedCorridors)
		else
			for _, corridor in ipairs(corridorBoxes) do
				blockedByCorridor[corridor.name] = 0
				for _, part in ipairs(taggedParts) do
					local box = bboxAABB(part)
					if
						box
						and math.min(box.maxX, corridor.maxX) - math.max(box.minX, corridor.minX) > OVERLAP_TOL
						and math.min(box.maxZ, corridor.maxZ) - math.max(box.minZ, corridor.minZ) > OVERLAP_TOL
					then
						blockedCorridors += 1
						blockedByCorridor[corridor.name] += 1
						break
					end
				end
			end
		end
		emit(
			"LAPANGAN_PATH_REACH",
			corridorsReady and lapanganFolder ~= nil and #taggedParts > 0 and #corridorBoxes > 0 and blockedCorridors == 0,
			blockedCorridors,
			0,
			{
				folderPresent = lapanganFolder ~= nil,
				parts = #taggedParts,
				corridors = #corridorBoxes,
				blockedByCorridor = blockedByCorridor,
				reason = if corridorsReady then nil else "folder / data / MapSpec.LAPANGAN not readable",
			}
		)

		local goalHeights = {}
		for _, model in ipairs(goalModels) do
			local size = bboxSize(model)
			if size and type(size.Y) == "number" then
				goalHeights[#goalHeights + 1] = size.Y
			end
		end
		local goalHeightTarget = (lapanganData :: any).GOAL_HEIGHT
		local goalPass = #goalModels == (lapanganExpected :: any).goals and #goalHeights == (lapanganExpected :: any).goals
		local measuredGoalHeight = 0
		for _, height in ipairs(goalHeights) do
			measuredGoalHeight = math.max(measuredGoalHeight, height)
			if math.abs(height - goalHeightTarget) > LAPANGAN_GOAL_TOL then
				goalPass = false
			end
		end
		emit(
			"LAPANGAN_GOAL_SIZE",
			goalPass,
			math.floor(measuredGoalHeight * 100) / 100,
			goalHeightTarget,
			{
				folderPresent = lapanganFolder ~= nil,
				goalModels = #goalModels,
				heights = goalHeights,
				avatarHeight = (lapanganData :: any).AVATAR_HEIGHT,
				ratio = (lapanganData :: any).GOAL_RATIO,
				tolerance = LAPANGAN_GOAL_TOL,
			}
		)
		restoreLapanganPrior()
	end
end
end

do
-- 9j. WORK_QUEUE section N item 109: pasar_ground_r8. TWO checks over the staged
-- LookDevPasarGroundR8_pasar_ground_r8 folder. PASAR_PAVING counts flat paving+cobble pieces
-- (target >= 60) and measures every slab's bbox BOTTOM against MapSpec.GROUND_Y with a 0.15-stud
-- tolerance. PASAR_GROUND_LANE_CLEAR checks EVERY tagged part - collidable or not; all staged parts
-- are non-collidable by construction, so a collidable-only test would be vacuous - against the
-- 6-stud lane rectangle translated through MapSpec.hubPoint(MapSpec.hub("pasar"), ...). This block
-- stages the candidate and restores the prior single candidate; every failure path emits BOTH lines
-- FAIL. Item 148's LANE_CLEAR and the full_r9 list stay untouched.
local PG_FOLDER = "LookDevPasarGroundR8_pasar_ground_r8"
local PG_ID = "pasar_ground_r8"
local PAVING_TOL = 0.15
local PG_MIN_PAVING = 60
local PG_FALLBACK_KINDS = { "paving", "cobble", "gutter" }

local okPgModules, pgModules = pcall(function()
	return {
		data = require(game.ReplicatedStorage.Shared.ModelMapPasarGroundR8),
		look = require(game.ReplicatedStorage.Shared.LookDev),
		review = require(game.ReplicatedStorage.Shared.LookDevReview),
	}
end)
local pgData: any? = nil
if okPgModules and type(pgModules) == "table" and type((pgModules :: any).data) == "table" then
	pgData = (pgModules :: any).data
end
local pgExpected: any? = nil
if pgData and type((pgData :: any).counts) == "function" then
	local okCounts, counts = pcall(function()
		return (pgData :: any).counts()
	end)
	if okCounts and type(counts) == "table" then
		pgExpected = counts
	end
end

-- The measured surface is the part's bottom face. Project the CFrame basis onto world Y so a
-- rotated slab would still be measured correctly.
local function pgBottomY(inst)
	local ok, cf, size = pcall(function()
		return (inst :: any).CFrame, (inst :: any).Size
	end)
	if not ok or not cf or not size then
		return nil
	end
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local extentY = math.abs(cf.RightVector.Y) * hx
		+ math.abs(cf.UpVector.Y) * hy
		+ math.abs(cf.LookVector.Y) * hz
	return cf.Position.Y - extentY
end

local function pgFail(reason)
	local kinds = PG_FALLBACK_KINDS
	if pgData and type((pgData :: any).KINDS) == "table" then
		kinds = (pgData :: any).KINDS
	end
	local byKind, targets = {}, {}
	for _, kind in ipairs(kinds) do
		byKind[#byKind + 1] = kind .. "=0"
		targets[#targets + 1] = kind .. "=?"
	end
	local detail = {
		reason = reason,
		folderPresent = folderNamed(PG_FOLDER) ~= nil,
		parts = 0,
		byKind = table.concat(byKind, " "),
		kindTargets = table.concat(targets, " "),
		pavingLike = 0,
		laneBoxes = 0,
		tolerance = PAVING_TOL,
		antiVac = "all tagged parts tested; none collidable by design",
	}
	emit("PASAR_PAVING", false, 0, ">=" .. PG_MIN_PAVING, detail)
	emit("PASAR_GROUND_LANE_CLEAR", false, 1, 0, detail)
end

local pgRunService = service("RunService")
local okPgServer, pgIsServer = false, false
if pgRunService then
	okPgServer, pgIsServer = pcall(function()
		return (pgRunService :: any):IsServer()
	end)
end
local pgLook = okPgModules and (pgModules :: any).look or nil
local pgReview = okPgModules and (pgModules :: any).review or nil
if
	not pgData
	or not pgExpected
	or not okPgServer
	or not pgIsServer
	or type(pgLook) ~= "table"
	or type(pgLook.enable) ~= "function"
	or type(pgLook.disable) ~= "function"
	or type(pgReview) ~= "table"
	or type(pgReview.enable) ~= "function"
then
	pgFail("server VM / pasar ground modules / counts not readable")
else
	local okPrior, priorId = pcall(function()
		return (pgLook :: any).current and (pgLook :: any).current() or nil
	end)
	if not okPrior then
		priorId = nil
	end
	local function restorePgPrior()
		pcall(function()
			(pgLook :: any).disable()
		end)
		if type(priorId) == "string" then
			pcall(function()
				(pgLook :: any).enable(priorId)
			end)
		end
	end
	local okEnable, enabled, whyEnable = pcall(function()
		return (pgReview :: any).enable(PG_ID, game, { studio = true })
	end)
	if not okEnable or enabled == false then
		restorePgPrior()
		pgFail("enable:" .. tostring(whyEnable or enabled))
	else
		local pgFolder = folderNamed(PG_FOLDER)
		local taggedParts = {}
		local countsByKind = {}
		for _, kind in ipairs((pgData :: any).KINDS) do
			countsByKind[kind] = 0
		end
		for _, inst in ipairs(descendantList(pgFolder)) do
			local kind = attr(inst, (pgData :: any).kindAttribute)
			if type(kind) == "string" and countsByKind[kind] ~= nil then
				local okPart, isPart = pcall(function()
					return (inst :: any):IsA("BasePart")
				end)
				if okPart and isPart then
					countsByKind[kind] += 1
					taggedParts[#taggedParts + 1] = inst
				end
			end
		end
		local pavingLike = (countsByKind.paving or 0) + (countsByKind.cobble or 0)
		local groundY = if mapSpecReady and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
		local badBottoms, maxBottomDelta = 0, 0
		for _, part in ipairs(taggedParts) do
			local kind = attr(part, (pgData :: any).kindAttribute)
			if kind == "paving" or kind == "cobble" then
				local bottom = pgBottomY(part)
				if type(bottom) ~= "number" then
					badBottoms += 1
				else
					local delta = math.abs(bottom - groundY)
					maxBottomDelta = math.max(maxBottomDelta, delta)
					if delta > PAVING_TOL then
						badBottoms += 1
					end
				end
			end
		end
		emit(
			"PASAR_PAVING",
			pgFolder ~= nil
				and #taggedParts > 0
				and pavingLike >= PG_MIN_PAVING
				and badBottoms == 0,
			pavingLike,
			">=" .. PG_MIN_PAVING,
			{
				folderPresent = pgFolder ~= nil,
				parts = #taggedParts,
				byKind = countsByKind,
				pavingLike = pavingLike,
				groundY = groundY,
				tolerance = PAVING_TOL,
				maxBottomDelta = math.floor(maxBottomDelta * 10000) / 10000,
				badBottoms = badBottoms,
				measuredSurface = "slab bbox bottom",
			}
		)

		-- The pure lane rectangle is Pasar-local; map all four corners through MapSpec.hubPoint so
		-- a rotated hub would still produce the correct world AABB.
		local laneBoxes = {}
		local laneWidth, laneDepth = nil, nil
		local laneReady = pgFolder ~= nil
			and #taggedParts > 0
			and mapSpecReady
			and type((pgData :: any).lane) == "function"
			and type(MapSpec.hub) == "function"
			and type(MapSpec.hubPoint) == "function"
		if laneReady then
			local okLane, lane = pcall(function()
				return (pgData :: any).lane()
			end)
			local okHub, hub = pcall(function()
				return MapSpec.hub("pasar")
			end)
			laneReady = okLane
				and okHub
				and hub ~= nil
				and type(lane) == "table"
				and type(lane.lx) == "number"
				and type(lane.lz) == "number"
				and type(lane.width) == "number"
				and type(lane.depth) == "number"
			if laneReady then
				laneWidth, laneDepth = lane.width, lane.depth
				local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
				for _, corner in ipairs({
					{ lane.lx - lane.width / 2, lane.lz - lane.depth / 2 },
					{ lane.lx + lane.width / 2, lane.lz - lane.depth / 2 },
					{ lane.lx - lane.width / 2, lane.lz + lane.depth / 2 },
					{ lane.lx + lane.width / 2, lane.lz + lane.depth / 2 },
				}) do
					local okPoint, x, z = pcall(function()
						return MapSpec.hubPoint(hub, corner[1], corner[2])
					end)
					if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
						laneReady = false
						break
					end
					minX, maxX = math.min(minX, x), math.max(maxX, x)
					minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
				end
				if laneReady and minX < maxX and minZ < maxZ then
					laneBoxes[1] = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
				end
			end
		end
		local laneOverlaps = 0
		if not laneReady or #laneBoxes == 0 then
			laneOverlaps = math.max(1, laneOverlaps)
		else
			for _, box in ipairs(laneBoxes) do
				for _, part in ipairs(taggedParts) do
					local partBox = bboxAABB(part)
					if
						partBox
						and math.min(partBox.maxX, box.maxX) - math.max(partBox.minX, box.minX) > OVERLAP_TOL
						and math.min(partBox.maxZ, box.maxZ) - math.max(partBox.minZ, box.minZ) > OVERLAP_TOL
					then
						laneOverlaps += 1
					end
				end
			end
		end
		emit(
			"PASAR_GROUND_LANE_CLEAR",
			laneReady and folderNamed(PG_FOLDER) ~= nil and #taggedParts > 0 and #laneBoxes > 0 and laneOverlaps == 0,
			laneOverlaps,
			0,
			{
				folderPresent = folderNamed(PG_FOLDER) ~= nil,
				parts = #taggedParts,
				laneBoxes = #laneBoxes,
				lane = laneBoxes[1],
				laneWidth = laneWidth,
				laneDepth = laneDepth,
				blockingParts = laneOverlaps,
				antiVac = "all tagged parts tested; none collidable by design",
				reason = if laneReady then nil else "folder / data / MapSpec.hub(pasar) not readable",
			}
		)
		restorePgPrior()
	end
end
end

do
-- 9k. WORK_QUEUE section N item 110: musala_r8. THREE checks over the staged
-- LookDevMusalaR8_musala_r8 folder, run in the SERVER VM. MUSALA_PARTS counts architecture Parts
-- by kind against Shared.ModelMapMusalaR8.counts() (invisible door gauge excluded). MUSALA_DOOR_CLEAR
-- stages one tagged MusalaDoorGauge at the door CFrame and counts collidable SHIPPING-world hits
-- with GetPartBoundsInBox (all musala parts are non-collidable, so the test is about blockers, not
-- self-overlap). MUSALA_PATH_REACH maps the pure local approach corridor from the door outward to
-- the ring and tests EVERY tagged musala AABB, collidable or not; a collidable-only corridor test
-- would be vacuous. Naming: bare DOOR_CLEAR already belongs to the six facades (ORDER 226) and bare
-- PATH_REACH to the six-hub read-only veg check (ORDER 185), so these are distinct names. Every
-- failure path emits ALL THREE lines FAIL. No full_r9 list, existing check or shipping default is
-- touched; there is no visual verdict here.
local MS_FOLDER_FALLBACK = "LookDevMusalaR8_musala_r8"
local MS_ID = "musala_r8"
local MS_MIN_PARTS = 25
local MS_GAUGE_FALLBACK = "MusalaDoorGauge"
local MS_FALLBACK_DIMS = { 3, 5.4, 2 }
local MS_FALLBACK_KINDS = { "base", "wall", "post", "door", "window", "roof", "horn", "wudhu", "shoes" }

local okMsModules, msModules = pcall(function()
	return {
		data = require(game.ReplicatedStorage.Shared.ModelMapMusalaR8),
		look = require(game.ReplicatedStorage.Shared.LookDev),
		review = require(game.ReplicatedStorage.Shared.LookDevReview),
	}
end)
local msData: any? = nil
if okMsModules and type(msModules) == "table" and type((msModules :: any).data) == "table" then
	msData = (msModules :: any).data
end
local msExpected: any? = nil
if msData and type((msData :: any).counts) == "function" then
	local okCounts, counts = pcall(function()
		return (msData :: any).counts()
	end)
	if okCounts and type(counts) == "table" and type(counts.total) == "number" then
		msExpected = counts
	end
end

local function msFail(reason)
	local kinds = MS_FALLBACK_KINDS
	if msData and type((msData :: any).KINDS) == "table" then
		kinds = (msData :: any).KINDS
	end
	local byKind, targets = {}, {}
	for _, kind in ipairs(kinds) do
		byKind[#byKind + 1] = kind .. "=0"
		targets[#targets + 1] = kind .. "=?"
	end
	local detail = {
		reason = reason,
		folderPresent = folderNamed(if msData then (msData :: any).folderName else MS_FOLDER_FALLBACK) ~= nil,
		parts = 0,
		byKind = table.concat(byKind, " "),
		kindTargets = table.concat(targets, " "),
		gauge = 0,
		collidableHits = -1,
		corridorOverlaps = -1,
		antiVac = "all tagged parts tested; none collidable by design",
	}
	emit("MUSALA_PARTS", false, 0, ">=" .. MS_MIN_PARTS, detail)
	emit("MUSALA_DOOR_CLEAR", false, 0, 0, detail)
	emit("MUSALA_PATH_REACH", false, 1, 0, detail)
end

local msRunService = service("RunService")
local okMsServer, msIsServer = false, false
if msRunService then
	okMsServer, msIsServer = pcall(function()
		return (msRunService :: any):IsServer()
	end)
end
local msLook = okMsModules and (msModules :: any).look or nil
local msReview = okMsModules and (msModules :: any).review or nil
if
	not msData
	or not msExpected
	or not mapSpecReady
	or not okMsServer
	or not msIsServer
	or type(msLook) ~= "table"
	or type(msLook.enable) ~= "function"
	or type(msLook.disable) ~= "function"
	or type(msReview) ~= "table"
	or type(msReview.enable) ~= "function"
	or type((msData :: any).KINDS) ~= "table"
	or type((msData :: any).KIND) ~= "table"
	or type((msData :: any).centre) ~= "function"
	or type((msData :: any).sitePoint) ~= "function"
	or type((msData :: any).corridorCorners) ~= "function"
	or type((msData :: any).gaugeDims) ~= "function"
then
	msFail("server VM / musala modules / MapSpec / counts not readable")
else
	local okPrior, priorId = pcall(function()
		return (msLook :: any).current and (msLook :: any).current() or nil
	end)
	if not okPrior then
		priorId = nil
	end
	local function restoreMsPrior()
		pcall(function()
			(msLook :: any).disable()
		end)
		if type(priorId) == "string" then
			pcall(function()
				(msLook :: any).enable(priorId)
			end)
		end
	end
	local okEnable, enabled, whyEnable = pcall(function()
		return (msReview :: any).enable(MS_ID, game, { studio = true })
	end)
	if not okEnable or enabled == false then
		restoreMsPrior()
		msFail("enable:" .. tostring(whyEnable or enabled))
	else
		local msFolder = folderNamed((msData :: any).folderName)
		local tagged, allTagged, gauges = {}, {}, {}
		local countsByKind = {}
		for _, kind in ipairs((msData :: any).KINDS) do
			countsByKind[kind] = 0
		end
		for _, inst in ipairs(descendantList(msFolder)) do
			local okPart, isPart = pcall(function()
				return (inst :: any):IsA("BasePart")
			end)
			local kind = attr(inst, (msData :: any).kindAttribute)
			local stage = attr(inst, (msData :: any).stageAttribute)
			if okPart and isPart and type(kind) == "string" and stage == (msData :: any).familyId then
				allTagged[#allTagged + 1] = inst
				if kind == (msData :: any).KIND.gauge then
					gauges[#gauges + 1] = inst
				elseif countsByKind[kind] ~= nil then
					countsByKind[kind] += 1
					tagged[#tagged + 1] = inst
				end
			end
		end
		local byKindMismatch = {}
		local expectedCounts = (msExpected :: any)
		for _, kind in ipairs((msData :: any).KINDS) do
			if countsByKind[kind] ~= expectedCounts[kind] then
				byKindMismatch[#byKindMismatch + 1] = kind .. "=" .. tostring(countsByKind[kind])
			end
		end
		local partsOk = msFolder ~= nil
			and #tagged >= MS_MIN_PARTS
			and #tagged == expectedCounts.total
			and #byKindMismatch == 0
		emit(
			"MUSALA_PARTS",
			partsOk,
			#tagged,
			">=" .. MS_MIN_PARTS,
			{
				folderPresent = msFolder ~= nil,
				parts = #tagged,
				byKind = countsByKind,
				expected = expectedCounts,
				byKindMismatch = byKindMismatch,
				gauges = #gauges,
				antiVac = "architecture tagged Parts only; door gauge excluded",
			}
		)

		-- Pure site: MapSpec.ROAD constants -> centre/yaw; MapSpec.GROUND_Y -> centre.y only.
		local road = if type(MapSpec.ROAD) == "table" then MapSpec.ROAD else nil
		local groundY = if type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
		local centre = (msData :: any).centre(road)
		centre.y = groundY

		-- Door gauge: exactly one, exact Size + DoorW/H/D attributes, exact site pose, then a
		-- collidable-only SHIPPING-world overlap probe excluding every musala folder descendant.
		local expectedDims = (msData :: any).gaugeDims()
		if type(expectedDims) ~= "table" or #expectedDims ~= 3 then
			expectedDims = MS_FALLBACK_DIMS
		end
		local gauge = gauges[1]
		local dimsMatch, poseMatch = false, false
		local measuredDims = {}
		if #gauges == 1 and gauge then
			local okDims, w, h, d = pcall(function()
				local size = (gauge :: any).Size
				return size.X, size.Y, size.Z
			end)
			local okAttrs, aw, ah, ad = pcall(function()
				return (gauge :: any):GetAttribute((msData :: any).doorWidthAttribute),
					(gauge :: any):GetAttribute((msData :: any).doorHeightAttribute),
					(gauge :: any):GetAttribute((msData :: any).doorDepthAttribute)
			end)
			if okDims then
				measuredDims = { w, h, d }
			end
			dimsMatch = okDims
				and okAttrs
				and type(w) == "number"
				and type(h) == "number"
				and type(d) == "number"
				and type(aw) == "number"
				and type(ah) == "number"
				and type(ad) == "number"
				and math.abs(w - expectedDims[1]) < 1e-4
				and math.abs(h - expectedDims[2]) < 1e-4
				and math.abs(d - expectedDims[3]) < 1e-4
				and math.abs(aw - expectedDims[1]) < 1e-4
				and math.abs(ah - expectedDims[2]) < 1e-4
				and math.abs(ad - expectedDims[3]) < 1e-4
			local okDoor, dx, dy, dz = pcall(function()
				return (msData :: any).sitePoint(
					centre,
					centre.yaw,
					(msData :: any).DOOR.lx,
					(msData :: any).DOOR.ly,
					(msData :: any).DOOR.lz
				)
			end)
			local okPose, px, py, pz, lookX, lookZ = false, 0, 0, 0, 0, 0
			if gauge then
				okPose, px, py, pz, lookX, lookZ = pcall(function()
					local cf = (gauge :: any).CFrame
					return cf.Position.X, cf.Position.Y, cf.Position.Z, cf.LookVector.X, cf.LookVector.Z
				end)
			end
			poseMatch = okDoor
				and okPose
				and type(dx) == "number"
				and type(dy) == "number"
				and type(dz) == "number"
				and math.abs(px - dx) < 1e-3
				and math.abs(py - dy) < 1e-3
				and math.abs(pz - dz) < 1e-3
				-- Roblox LookVector is a Part's local -Z. Staging rotates local +Z radially
				-- outward, so -LookVector (not LookVector) must match that outward direction.
				and math.abs(-lookX - math.sin(math.rad(centre.yaw))) < 1e-3
				and math.abs(-lookZ - math.cos(math.rad(centre.yaw))) < 1e-3
		end
		local collidableHits, apiOk = -1, false
		if #gauges == 1 and dimsMatch and poseMatch then
			local okParams, params = pcall(function()
				local p = OverlapParams.new()
				p.CollisionGroup = "Default"
				p.FilterType = Enum.RaycastFilterType.Exclude
				p.FilterDescendantsInstances = { msFolder }
				return p
			end)
			local okHits, hits = false, nil
			if okParams and params then
				okHits, hits = pcall(function()
					return workspace:GetPartBoundsInBox((gauge :: any).CFrame, (gauge :: any).Size, params)
				end)
			end
			if okHits and type(hits) == "table" then
				collidableHits = 0
				apiOk = true
				for _, hit in ipairs(hits) do
					local okDesc, descendant = pcall(function()
						return msFolder ~= nil and (hit :: any):IsDescendantOf(msFolder)
					end)
					local okCollide, collide = pcall(function()
						return (hit :: any).CanCollide
					end)
					if (not okDesc or descendant == false) and okCollide and collide == true then
						collidableHits += 1
					end
				end
			end
		end
		emit(
			"MUSALA_DOOR_CLEAR",
			#gauges == 1 and dimsMatch and poseMatch and apiOk and collidableHits == 0,
			collidableHits,
			0,
			{
				folderPresent = msFolder ~= nil,
				gauges = #gauges,
				expectedDims = expectedDims,
				measuredDims = measuredDims,
				dimsMatch = dimsMatch,
				poseMatch = poseMatch,
				apiOk = apiOk,
				collidableHits = collidableHits,
				site = { x = centre.x, y = centre.y, z = centre.z, yaw = centre.yaw },
				measuredSurface = "door gauge GetPartBoundsInBox, collidable shipping geometry only",
			}
		)

		-- The approach lane is tested in SITE-LOCAL space. The whole musala is rotated by
		-- centre.yaw, so a world-axis AABB of a rotated slab is larger than its real footprint and
		-- false-positives (base platform, roof tiers, etc.). Convert each tagged part back into the
		-- site frame and compare its local XZ box to Data.CORRIDOR. Every tagged part, including the
		-- gauge, is tested, so non-collidable staging cannot make the check vacuous.
		local corridor, corridorReady = nil, msFolder ~= nil and #allTagged > 0
		if corridorReady then
			local okCorr, c = pcall(function()
				return (msData :: any).CORRIDOR
			end)
			corridorReady = okCorr
				and type(c) == "table"
				and type(c.minLx) == "number"
				and type(c.maxLx) == "number"
				and type(c.minLz) == "number"
				and type(c.maxLz) == "number"
				and c.maxLx > c.minLx
				and c.maxLz > c.minLz
			if corridorReady then
				corridor = { minX = c.minLx, maxX = c.maxLx, minZ = c.minLz, maxZ = c.maxLz }
			end
		end
		local cosYaw, sinYaw = math.cos(math.rad(centre.yaw)), math.sin(math.rad(centre.yaw))
		local overlaps = -1
		if corridorReady and corridor then
			overlaps = 0
			for _, part in ipairs(allTagged) do
				local okBox, box = pcall(function()
					local cf = (part :: any).CFrame
					local size = (part :: any).Size
					local dx, dz = cf.Position.X - centre.x, cf.Position.Z - centre.z
					-- Inverse of sitePoint's XZ rotation.
					local lx = dx * cosYaw - dz * sinYaw
					local lz = dx * sinYaw + dz * cosYaw
					local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
					local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
					-- Site-local +X maps to world (cos, 0, -sin); +Z maps to (sin, 0, cos).
					local ex = math.abs(right.X * cosYaw - right.Z * sinYaw) * hx
						+ math.abs(up.X * cosYaw - up.Z * sinYaw) * hy
						+ math.abs(look.X * cosYaw - look.Z * sinYaw) * hz
					local ez = math.abs(right.X * sinYaw + right.Z * cosYaw) * hx
						+ math.abs(up.X * sinYaw + up.Z * cosYaw) * hy
						+ math.abs(look.X * sinYaw + look.Z * cosYaw) * hz
					return { minX = lx - ex, maxX = lx + ex, minZ = lz - ez, maxZ = lz + ez }
				end)
				if
					okBox
					and box
					and math.min(box.maxX, corridor.maxX) - math.max(box.minX, corridor.minX) > OVERLAP_TOL
					and math.min(box.maxZ, corridor.maxZ) - math.max(box.minZ, corridor.minZ) > OVERLAP_TOL
				then
					overlaps += 1
				end
			end
		end
		emit(
			"MUSALA_PATH_REACH",
			corridorReady and corridor ~= nil and overlaps == 0,
			overlaps,
			0,
			{
				folderPresent = msFolder ~= nil,
				taggedParts = #allTagged,
				corridor = corridor,
				blockingParts = overlaps,
				site = { x = centre.x, y = centre.y, z = centre.z, yaw = centre.yaw },
				outerRadius = centre.radius + (msData :: any).CORRIDOR.maxLz,
				ringInner = if road then road.ringCentre - road.ringWidth / 2 else nil,
				antiVac = "all tagged parts tested; none collidable by design",
				reason = if corridorReady then nil else "folder / data / MapSpec.ROAD not readable",
			}
		)
		restoreMsPrior()
	end
end
end

do
-- 9l. WORK_QUEUE section N item 111: lumbung_r8. THREE checks over the staged
-- LookDevLumbungR8_lumbung_r8 folder, run in the SERVER VM. LUMBUNG_PARTS counts architecture Parts
-- by kind against Shared.ModelMapLumbungR8.counts() (the invisible door gauge is excluded).
-- LUMBUNG_DOOR_CLEAR stages one tagged LumbungDoorGauge at the lumbung door and counts collidable
-- SHIPPING-world hits with GetPartBoundsInBox, excluding every descendant of the staged folder.
-- LUMBUNG_PROPS_ON_GRASS reads the three yard pads from pure yard sample centres and their snapped
-- 4-stud cells; the applier paints real Ground voxels there, this harness only samples them.
-- Naming matters: bare DOOR_CLEAR belongs to the six facades (ORDER 226) and bare PROPS_ON_GRASS to
-- the six r7 props (ORDER 172), so these are distinct names. No existing check, full_r9 list or
-- shipping default is touched; no visual verdict is made here.
local LB_FOLDER_FALLBACK = "LookDevLumbungR8_lumbung_r8"
local LB_ID = "lumbung_r8"
local LB_MIN_PARTS = 80
local LB_GAUGE_FALLBACK = "LumbungDoorGauge"
local LB_FALLBACK_DIMS = { 3.2, 4.8, 2 }
local LB_FALLBACK_KINDS = {
	"stilt",
	"floor",
	"wall",
	"door",
	"roof",
	"ladder",
	"vent",
	"fence",
	"toga",
	"chilli",
	"mat",
	"rake",
}
local LB_HOUSE_KEYS = { "pasar", "gelap", "pakrt" }

local okLbModules, lbModules = pcall(function()
	return {
		data = require(game.ReplicatedStorage.Shared.ModelMapLumbungR8),
		look = require(game.ReplicatedStorage.Shared.LookDev),
		review = require(game.ReplicatedStorage.Shared.LookDevReview),
	}
end)
local lbData: any? = nil
if okLbModules and type(lbModules) == "table" and type((lbModules :: any).data) == "table" then
	lbData = (lbModules :: any).data
end
local lbExpected: any? = nil
if lbData and type((lbData :: any).counts) == "function" then
	local okCounts, counts = pcall(function()
		return (lbData :: any).counts()
	end)
	if okCounts and type(counts) == "table" and type(counts.total) == "number" then
		lbExpected = counts
	end
end

local function lbFail(reason)
	local kinds = LB_FALLBACK_KINDS
	if lbData and type((lbData :: any).KINDS) == "table" then
		kinds = (lbData :: any).KINDS
	end
	local byKind, targets = {}, {}
	for _, kind in ipairs(kinds) do
		byKind[#byKind + 1] = kind .. "=0"
		targets[#targets + 1] = kind .. "=?"
	end
	local detail = {
		reason = reason,
		folderPresent = folderNamed(if lbData then (lbData :: any).folderName else LB_FOLDER_FALLBACK) ~= nil,
		parts = 0,
		byKind = table.concat(byKind, " "),
		kindTargets = table.concat(targets, " "),
		gauge = 0,
		collidableHits = -1,
		grassyCells = -1,
		yardSamples = 0,
		antiVac = "pure yard samples + snapped cells; missing folder/data fails all three",
	}
	emit("LUMBUNG_PARTS", false, 0, ">=" .. LB_MIN_PARTS, detail)
	emit("LUMBUNG_DOOR_CLEAR", false, 0, 0, detail)
	emit("LUMBUNG_PROPS_ON_GRASS", false, 1, 0, detail)
end

local lbRunService = service("RunService")
local okLbServer, lbIsServer = false, false
if lbRunService then
	okLbServer, lbIsServer = pcall(function()
		return (lbRunService :: any):IsServer()
	end)
end
local lbLook = okLbModules and (lbModules :: any).look or nil
local lbReview = okLbModules and (lbModules :: any).review or nil
if
	not lbData
	or not lbExpected
	or not mapSpecReady
	or not okLbServer
	or not lbIsServer
	or type(lbLook) ~= "table"
	or type(lbLook.enable) ~= "function"
	or type(lbLook.disable) ~= "function"
	or type(lbReview) ~= "table"
	or type(lbReview.enable) ~= "function"
	or type((lbData :: any).KINDS) ~= "table"
	or type((lbData :: any).KIND) ~= "table"
	or type((lbData :: any).HOUSE_KEYS) ~= "table"
	or type((lbData :: any).BARN) ~= "table"
	or type((lbData :: any).DOOR) ~= "table"
	or type((lbData :: any).sitePoint) ~= "function"
	or type((lbData :: any).gaugeDims) ~= "function"
	or type((lbData :: any).yards) ~= "function"
	or type((lbData :: any).yardRegion) ~= "function"
	or type(MapSpec.hub) ~= "function"
	or type(MapSpec.hubPoint) ~= "function"
	or type(MapSpec.GROUND_Y) ~= "number"
then
	lbFail("server VM / lumbung modules / MapSpec / counts not readable")
else
	local okPrior, priorId = pcall(function()
		return (lbLook :: any).current and (lbLook :: any).current() or nil
	end)
	if not okPrior then
		priorId = nil
	end
	local function restoreLbPrior()
		pcall(function()
			(lbLook :: any).disable()
		end)
		if type(priorId) == "string" then
			pcall(function()
				(lbLook :: any).enable(priorId)
			end)
		end
	end
	local okEnable, enabled, whyEnable = pcall(function()
		return (lbReview :: any).enable(LB_ID, game, { studio = true })
	end)
	if not okEnable or enabled == false then
		restoreLbPrior()
		lbFail("enable:" .. tostring(whyEnable or enabled))
	else
		local lbFolder = folderNamed((lbData :: any).folderName)
		local tagged, allTagged, gauges = {}, {}, {}
		local countsByKind = {}
		for _, kind in ipairs((lbData :: any).KINDS) do
			countsByKind[kind] = 0
		end
		for _, inst in ipairs(descendantList(lbFolder)) do
			local okPart, isPart = pcall(function()
				return (inst :: any):IsA("BasePart")
			end)
			local kind = attr(inst, (lbData :: any).kindAttribute)
			local stage = attr(inst, (lbData :: any).stageAttribute)
			if okPart and isPart and type(kind) == "string" and stage == (lbData :: any).familyId then
				allTagged[#allTagged + 1] = inst
				if kind == (lbData :: any).KIND.gauge then
					gauges[#gauges + 1] = inst
				elseif countsByKind[kind] ~= nil then
					countsByKind[kind] += 1
					tagged[#tagged + 1] = inst
				end
			end
		end
		local byKindMismatch = {}
		local expectedCounts = (lbExpected :: any)
		for _, kind in ipairs((lbData :: any).KINDS) do
			if countsByKind[kind] ~= expectedCounts[kind] then
				byKindMismatch[#byKindMismatch + 1] = kind .. "=" .. tostring(countsByKind[kind])
			end
		end
		local partsOk = lbFolder ~= nil
			and #tagged >= LB_MIN_PARTS
			and #tagged == expectedCounts.total
			and #byKindMismatch == 0
		emit(
			"LUMBUNG_PARTS",
			partsOk,
			#tagged,
			">=" .. LB_MIN_PARTS,
			{
				folderPresent = lbFolder ~= nil,
				parts = #tagged,
				byKind = countsByKind,
				expected = expectedCounts,
				byKindMismatch = byKindMismatch,
				gauges = #gauges,
				antiVac = "architecture tagged Parts only; door gauge excluded",
			}
		)

		-- Barn site: MapSpec.hub(pasar) + hubPoint with pure hub-local barn offsets.
		local barnHub = MapSpec.hub((lbData :: any).BARN.hubKey)
		local bx, bz = MapSpec.hubPoint(barnHub, (lbData :: any).BARN.lx, (lbData :: any).BARN.lz)
		local centre = {
			x = bx,
			y = MapSpec.GROUND_Y,
			z = bz,
			yaw = barnHub.yaw + (lbData :: any).BARN.yawOffsetDeg,
		}

		-- Exactly one gauge: exact Size + DoorW/H/D attrs, exact site pose, then a collidable-only
		-- SHIPPING-world overlap probe excluding every staged-folder descendant.
		local expectedDims = (lbData :: any).gaugeDims()
		if type(expectedDims) ~= "table" or #expectedDims ~= 3 then
			expectedDims = LB_FALLBACK_DIMS
		end
		local gauge = gauges[1]
		local dimsMatch, poseMatch = false, false
		local measuredDims = {}
		if #gauges == 1 and gauge then
			local okDims, w, h, d = pcall(function()
				local size = (gauge :: any).Size
				return size.X, size.Y, size.Z
			end)
			local okAttrs, aw, ah, ad = pcall(function()
				return (gauge :: any):GetAttribute((lbData :: any).doorWidthAttribute),
					(gauge :: any):GetAttribute((lbData :: any).doorHeightAttribute),
					(gauge :: any):GetAttribute((lbData :: any).doorDepthAttribute)
			end)
			if okDims then
				measuredDims = { w, h, d }
			end
			dimsMatch = okDims
				and okAttrs
				and type(w) == "number"
				and type(h) == "number"
				and type(d) == "number"
				and type(aw) == "number"
				and type(ah) == "number"
				and type(ad) == "number"
				and math.abs(w - expectedDims[1]) < 1e-4
				and math.abs(h - expectedDims[2]) < 1e-4
				and math.abs(d - expectedDims[3]) < 1e-4
				and math.abs(aw - expectedDims[1]) < 1e-4
				and math.abs(ah - expectedDims[2]) < 1e-4
				and math.abs(ad - expectedDims[3]) < 1e-4
			local okDoor, dx, dy, dz = pcall(function()
				local door = (lbData :: any).DOOR
				return (lbData :: any).sitePoint(centre, door.lx, door.ly, door.lz)
			end)
			local okPose, px, py, pz, lookX, lookZ = false, 0, 0, 0, 0, 0
			if gauge then
				okPose, px, py, pz, lookX, lookZ = pcall(function()
					local cf = (gauge :: any).CFrame
					return cf.Position.X, cf.Position.Y, cf.Position.Z, cf.LookVector.X, cf.LookVector.Z
				end)
			end
			poseMatch = okDoor
				and okPose
				and type(dx) == "number"
				and type(dy) == "number"
				and type(dz) == "number"
				and math.abs(px - dx) < 1e-3
				and math.abs(py - dy) < 1e-3
				and math.abs(pz - dz) < 1e-3
				-- Roblox LookVector is a Part's local -Z. Local +Z is the barn's outward door side,
				-- so -LookVector (NOT LookVector) must match the rotated outward direction.
				and math.abs(-lookX - math.sin(math.rad(centre.yaw))) < 1e-3
				and math.abs(-lookZ - math.cos(math.rad(centre.yaw))) < 1e-3
		end
		local collidableHits, apiOk = -1, false
		if #gauges == 1 and dimsMatch and poseMatch then
			local okParams, params = pcall(function()
				local p = OverlapParams.new()
				p.CollisionGroup = "Default"
				p.FilterType = Enum.RaycastFilterType.Exclude
				p.FilterDescendantsInstances = { lbFolder }
				return p
			end)
			local okHits, hits = false, nil
			if okParams and params then
				okHits, hits = pcall(function()
					return workspace:GetPartBoundsInBox((gauge :: any).CFrame, (gauge :: any).Size, params)
				end)
			end
			if okHits and type(hits) == "table" then
				collidableHits = 0
				apiOk = true
				for _, hit in ipairs(hits) do
					local okDesc, descendant = pcall(function()
						return lbFolder ~= nil and (hit :: any):IsDescendantOf(lbFolder)
					end)
					local okCollide, collide = pcall(function()
						return (hit :: any).CanCollide
					end)
					if (not okDesc or descendant == false) and okCollide and collide == true then
						collidableHits += 1
					end
				end
			end
		end
		emit(
			"LUMBUNG_DOOR_CLEAR",
			#gauges == 1 and dimsMatch and poseMatch and apiOk and collidableHits == 0,
			collidableHits,
			0,
			{
				folderPresent = lbFolder ~= nil,
				gauges = #gauges,
				expectedDims = expectedDims,
				measuredDims = measuredDims,
				dimsMatch = dimsMatch,
				poseMatch = poseMatch,
				apiOk = apiOk,
				collidableHits = collidableHits,
				site = { x = centre.x, y = centre.y, z = centre.z, yaw = centre.yaw },
				measuredSurface = "door gauge GetPartBoundsInBox, collidable shipping geometry only",
			}
		)

		-- Yard samples come from pure data, one per house. Every snapped 4-stud cell must be
		-- readable and non-Grass; grassAt true or a failed voxelHasNonGrass read is a failure.
		local hubs = {}
		for _, key in ipairs((lbData :: any).HOUSE_KEYS) do
			local okHub, hub = pcall(function()
				return MapSpec.hub(key)
			end)
			if okHub and hub then
				hubs[key] = hub
			end
		end
		local yards, yardDetail = {}, {}
		local grassyCells, unreadableCells, nonGrassCells, totalCells = 0, 0, 0, 0
		local okYards, yardsResult = pcall(function()
			return (lbData :: any).yards(hubs)
		end)
		if okYards and type(yardsResult) == "table" then
			yards = yardsResult
		end
		for _, yard in ipairs(yards) do
			local region = nil
			local okRegion, regionResult = pcall(function()
				return (lbData :: any).yardRegion(yard.x, yard.z, yard.sx, yard.sz)
			end)
			if okRegion and type(regionResult) == "table" then
				region = regionResult
			end
			local cells = if region and type(region.cells) == "table" then region.cells else {}
			local grassy, unreadable, nonGrass = 0, 0, 0
			for _, cell in ipairs(cells) do
				totalCells += 1
				local sample = { x = cell.x, z = cell.z }
				if grassAt(sample) then
					grassy += 1
					grassyCells += 1
				end
				if voxelHasNonGrass(cell.x, GRASS_Y, cell.z) then
					nonGrass += 1
					nonGrassCells += 1
				else
					unreadable += 1
					unreadableCells += 1
				end
			end
			yardDetail[yard.key] = {
				centre = { x = yard.x, z = yard.z },
				region = region,
				cells = #cells,
				grassy = grassy,
				unreadable = unreadable,
				nonGrass = nonGrass,
			}
		end
		local expectedYardCount = if type((lbData :: any).YARD_COUNT) == "number" then (lbData :: any).YARD_COUNT else 3
		local yardOk = lbFolder ~= nil
			and #yards == expectedYardCount
			and expectedYardCount > 0
			and totalCells > 0
			and unreadableCells == 0
			and nonGrassCells == totalCells
			and grassyCells == 0
		emit(
			"LUMBUNG_PROPS_ON_GRASS",
			yardOk,
			grassyCells,
			0,
			{
				folderPresent = lbFolder ~= nil,
				voxelY = GRASS_Y,
				yardSamples = #yards,
				expectedYardSamples = expectedYardCount,
				totalCells = totalCells,
				nonGrassCells = nonGrassCells,
				unreadableCells = unreadableCells,
				houses = yardDetail,
				antiVac = "pure yard list must be non-empty and exact; every snapped cell must read non-Grass",
				reason = if yardOk then nil else "missing folder / wrong yard count / unreadable or Grass cell",
			}
		)
		restoreLbPrior()
	end
end
end

do
-- 9m. WORK_QUEUE section N item 112: perahu_r8. Two checks over the staged
-- LookDevPerahuR8_perahu_r8 folder, run in the SERVER VM. PERAHU_PARTS counts the original Parts
-- by kind against Shared.ModelMapPerahuR8.counts(). PERAHU_RIVER_CLEAR stages the candidate itself,
-- reads every tagged part's rotation-aware XZ box and fails any box that meets the water channel
-- while its x-range is inside the bridge's 56-stud crossing interval. The river runs along X and
-- the bridge crosses along Z at x=0, so the 56-stud span (BRIDGE.z1-z0) is mapped to X:
-- [BRIDGE.x - 28, BRIDGE.x + 28]. BRIDGE_WALKABLE (ORDER 205) and every river check stay READ-ONLY
-- and byte-identical; these names are distinct and neither check touches the Terrain.
local PH_FOLDER_FALLBACK = "LookDevPerahuR8_perahu_r8"
local PH_ID = "perahu_r8"
local PH_MIN_PARTS = 35
local PH_FALLBACK_KINDS = {
	"hull",
	"gunwale",
	"seat",
	"netframe",
	"netmesh",
	"stageplank",
	"stagepile",
	"basket",
}
local PH_TOL = 1e-4

local okPhModules, phModules = pcall(function()
	return {
		data = require(game.ReplicatedStorage.Shared.ModelMapPerahuR8),
		look = require(game.ReplicatedStorage.Shared.LookDev),
		review = require(game.ReplicatedStorage.Shared.LookDevReview),
	}
end)
local phData: any? = nil
if okPhModules and type(phModules) == "table" and type((phModules :: any).data) == "table" then
	phData = (phModules :: any).data
end
local phExpected: any? = nil
if phData and type((phData :: any).counts) == "function" then
	local okCounts, counts = pcall(function()
		return (phData :: any).counts()
	end)
	if okCounts and type(counts) == "table" and type(counts.total) == "number" then
		phExpected = counts
	end
end

local phFolderName = if phData then (phData :: any).folderName else PH_FOLDER_FALLBACK
local function phFail(reason)
	local kinds = PH_FALLBACK_KINDS
	if phData and type((phData :: any).KINDS) == "table" then
		kinds = (phData :: any).KINDS
	end
	local byKind = {}
	for _, kind in ipairs(kinds) do
		byKind[kind] = 0
	end
	local detail = {
		reason = reason,
		folderPresent = folderNamed(phFolderName) ~= nil,
		tagged = 0,
		byKind = byKind,
		span = nil,
		crossing = nil,
		centreFnReady = false,
		overlaps = -1,
		antiVac = "folder / pure data / MapSpec required; missing input fails both checks",
	}
	emit("PERAHU_PARTS", false, 0, ">=" .. PH_MIN_PARTS, detail)
	emit("PERAHU_RIVER_CLEAR", false, -1, 0, detail)
end

-- Exact XZ-overlap test for one part box against the union of channel corridors over the mapped
-- crossing interval. centreZ is sinusoidal: checking both interval ends plus its stationary points
-- (x = 80 + 160k) catches every crossing of the |z-centre| <= half band.
local function phChannelOverlap(box: any, spanMin: number, spanMax: number, centreFn: any, half: number): any?
	local lo, hi = math.max(box.minX, spanMin), math.min(box.maxX, spanMax)
	if hi <= lo then
		return false
	end
	local xs = { lo, hi }
	local first, last = math.ceil((lo - 80) / 160), math.floor((hi - 80) / 160)
	for k = first, last do
		local sx = 80 + k * 160
		if sx >= lo and sx <= hi then
			xs[#xs + 1] = sx
		end
	end
	for _, x in ipairs(xs) do
		local okC, centre = pcall(centreFn, x)
		if not okC or type(centre) ~= "number" then
			return nil
		end
		if math.min(box.maxZ, centre + half) - math.max(box.minZ, centre - half) > PH_TOL then
			return true
		end
	end
	return false
end

local phRunService = service("RunService")
local okPhServer, phIsServer = false, false
if phRunService then
	okPhServer, phIsServer = pcall(function()
		return (phRunService :: any):IsServer()
	end)
end
local phLook = okPhModules and (phModules :: any).look or nil
local phReview = okPhModules and (phModules :: any).review or nil
if
	not phData
	or not phExpected
	or not mapSpecReady
	or not okPhServer
	or not phIsServer
	or type(phLook) ~= "table"
	or type(phLook.enable) ~= "function"
	or type(phLook.disable) ~= "function"
	or type(phReview) ~= "table"
	or type(phReview.enable) ~= "function"
	or type((phData :: any).KINDS) ~= "table"
	or type((phData :: any).KIND) ~= "table"
	or type((phData :: any).RIVER_HALF) ~= "number"
	or type((phData :: any).BRIDGE_CROSS_MIN) ~= "number"
	or type((phData :: any).BRIDGE_CROSS_MAX) ~= "number"
	or type((phData :: any).riverCentreZ) ~= "function"
	or type(MapSpec.BRIDGE) ~= "table"
	or type(MapSpec.riverCentreZ) ~= "function"
then
	phFail("server VM / perahu modules / MapSpec / counts not readable")
else
	local okPrior, priorId = pcall(function()
		return (phLook :: any).current and (phLook :: any).current() or nil
	end)
	if not okPrior then
		priorId = nil
	end
	local function restorePhPrior()
		pcall(function()
			(phLook :: any).disable()
		end)
		if type(priorId) == "string" then
			pcall(function()
				(phLook :: any).enable(priorId)
			end)
		end
	end
	local okEnable, enabled, whyEnable = pcall(function()
		return (phReview :: any).enable(PH_ID, game, { studio = true })
	end)
	if not okEnable or enabled == false then
		restorePhPrior()
		phFail("enable:" .. tostring(whyEnable or enabled))
	else
		local phFolder = folderNamed((phData :: any).folderName)
		local tagged, byKind = {}, {}
		for _, kind in ipairs((phData :: any).KINDS) do
			byKind[kind] = 0
		end
		for _, inst in ipairs(descendantList(phFolder)) do
			local okPart, isPart = pcall(function()
				return (inst :: any):IsA("BasePart")
			end)
			local kind = attr(inst, (phData :: any).kindAttribute)
			local stage = attr(inst, (phData :: any).stageAttribute)
			if okPart and isPart and type(kind) == "string" and byKind[kind] ~= nil and stage == (phData :: any).familyId then
				byKind[kind] += 1
				tagged[#tagged + 1] = inst
			end
		end
		local mismatch, expectedCounts = {}, (phExpected :: any)
		for _, kind in ipairs((phData :: any).KINDS) do
			if byKind[kind] ~= expectedCounts[kind] then
				mismatch[#mismatch + 1] = kind .. "=" .. tostring(byKind[kind])
			end
		end
		local partsOk = phFolder ~= nil
			and #tagged > 0
			and #tagged >= PH_MIN_PARTS
			and #tagged == expectedCounts.total
			and #mismatch == 0
		emit(
			"PERAHU_PARTS",
			partsOk,
			#tagged,
			">=" .. PH_MIN_PARTS,
			{
				folderPresent = phFolder ~= nil,
				tagged = #tagged,
				byKind = byKind,
				expected = expectedCounts,
				byKindMismatch = mismatch,
				antiVac = "all tagged Parts counted by kind; missing folder/data fails at 0",
				reason = if partsOk then nil else "missing folder / wrong kind counts",
			}
		)

		-- Derive the 56-stud crossing interval from the live bridge and cross-check the pure mirror.
		local span, spanMin, spanMax = -1, nil, nil
		local okSpan = false
		local okSpanCall, spanResult, minResult, maxResult = pcall(function()
			local bridge = (MapSpec :: any).BRIDGE
			local length = bridge.z1 - bridge.z0
			return length, bridge.x - length / 2, bridge.x + length / 2
		end)
		if okSpanCall and type(spanResult) == "number" and type(minResult) == "number" and type(maxResult) == "number" then
			span, spanMin, spanMax = spanResult, minResult, maxResult
			okSpan = spanResult > 0
				and math.abs(spanResult - (phData :: any).BRIDGE_SPAN) < PH_TOL
				and math.abs(minResult - (phData :: any).BRIDGE_CROSS_MIN) < PH_TOL
				and math.abs(maxResult - (phData :: any).BRIDGE_CROSS_MAX) < PH_TOL
		end
		local centreFn, centreFnReady = nil, false
		local okCentre, c = pcall(function()
			return (MapSpec :: any).riverCentreZ(0)
		end)
		if okCentre and type(c) == "number" then
			centreFn = (MapSpec :: any).riverCentreZ
			centreFnReady = math.abs(c - (phData :: any).RIVER_CENTRE) < PH_TOL
		end
		local mapReady = okSpan and centreFnReady
		local overlaps, offenders = -1, {}
		if mapReady and phFolder ~= nil and #tagged > 0 then
			overlaps = 0
			for _, part in ipairs(tagged) do
				local okBox, box = pcall(function()
					local cf = (part :: any).CFrame
					local size = (part :: any).Size
					local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
					local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
					local ex = math.abs(right.X) * hx + math.abs(up.X) * hy + math.abs(look.X) * hz
					local ez = math.abs(right.Z) * hx + math.abs(up.Z) * hy + math.abs(look.Z) * hz
					return {
						minX = cf.Position.X - ex,
						maxX = cf.Position.X + ex,
						minZ = cf.Position.Z - ez,
						maxZ = cf.Position.Z + ez,
					}
				end)
				local hit, why = false, "unreadable"
				if okBox and box then
					hit = phChannelOverlap(box, spanMin, spanMax, centreFn, (phData :: any).RIVER_HALF)
					why = "channel/bridge overlap"
				end
				if hit == nil or hit == true then
					overlaps += 1
					local okName, name = pcall(function()
						return (part :: any).Name
					end)
					offenders[#offenders + 1] = {
						name = okName and name or "?",
						box = if okBox then box else nil,
						why = why,
					}
				end
			end
		end
		local clearOk = mapReady and phFolder ~= nil and #tagged > 0 and overlaps == 0
		emit(
			"PERAHU_RIVER_CLEAR",
			clearOk,
			overlaps,
			0,
			{
				folderPresent = phFolder ~= nil,
				tagged = #tagged,
				expected = expectedCounts.total,
				span = span,
				crossing = { min = spanMin, max = spanMax },
				centreFnReady = centreFnReady,
				overlaps = overlaps,
				offenders = offenders,
				antiVac = "every tagged Part tested (all CanCollide=false); exact total + map readability required",
				reason = if clearOk then nil else "missing folder/data/map or part in channel within bridge span",
			}
		)
		restorePhPrior()
	end
end
end

do
-- 9n. WORK_QUEUE section N item 113: irrigation_r8. Two checks over the staged
-- LookDevIrrigationR8_irrigation_r8 folder, run in the SERVER VM. IRRIGATION_PARTS counts the
-- original Parts by kind against Shared.ModelMapIrrigationR8.counts(). IRRIGATION_WATER_ON_TERRACE
-- stages the candidate itself, reads each tagged watersheet's CFrame.Position + Size, resolves the
-- terrace top from MapSpec.TERRACES by the Terrace attribute (z-band fallback) and fails any top
-- face more than 0.3 studs from that top. SAWAH_TOPS, SAWAH_WATER, every river check and full_r9
-- are READ-ONLY and byte-identical. The two names are distinct and appended after LOOKDEV_LEAK;
-- neither check reads or writes Terrain.
	local IR_FOLDER_FALLBACK = "LookDevIrrigationR8_irrigation_r8"
	local IR_ID = "irrigation_r8"
	local IR_MIN_PARTS = 40
	local IR_TOL = 0.3
	local IR_FALLBACK_KINDS = {
		"scarecpole",
		"crossbar",
		"shirt",
		"head",
		"hat",
		"flume",
		"watersheet",
		"clapper",
		"sheaf",
	}

	local okIrModules, irModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapIrrigationR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local irData: any? = nil
	if okIrModules and type(irModules) == "table" and type((irModules :: any).data) == "table" then
		irData = (irModules :: any).data
	end
	local irExpected: any? = nil
	if irData and type((irData :: any).counts) == "function" then
		local okCounts, counts = pcall(function()
			return (irData :: any).counts()
		end)
		if okCounts and type(counts) == "table" and type(counts.total) == "number" then
			irExpected = counts
		end
	end
	local irFolderName = if irData then (irData :: any).folderName else IR_FOLDER_FALLBACK

	local function irFail(reason)
		local kinds = IR_FALLBACK_KINDS
		if irData and type((irData :: any).KINDS) == "table" then
			kinds = (irData :: any).KINDS
		end
		local byKind = {}
		for _, kind in ipairs(kinds) do
			byKind[kind] = 0
		end
		local detail = {
			reason = reason,
			folderPresent = folderNamed(irFolderName) ~= nil,
			tagged = 0,
			byKind = byKind,
			mapReady = false,
			sheets = 0,
			worstDelta = -1,
			failed = {},
			antiVac = "folder / pure data / MapSpec / exact watersheet count required; missing input fails both checks",
		}
		emit("IRRIGATION_PARTS", false, 0, ">=" .. IR_MIN_PARTS, detail)
		emit("IRRIGATION_WATER_ON_TERRACE", false, -1, 0, detail)
	end

	local irRunService = service("RunService")
	local okIrServer, irIsServer = false, false
	if irRunService then
		okIrServer, irIsServer = pcall(function()
			return (irRunService :: any):IsServer()
		end)
	end
	local irLook = okIrModules and (irModules :: any).look or nil
	local irReview = okIrModules and (irModules :: any).review or nil
	local terracesReady = mapSpecReady
		and type(MapSpec.TERRACES) == "table"
		and #MapSpec.TERRACES > 0
	if terracesReady then
		for _, terrace in ipairs(MapSpec.TERRACES) do
			if type(terrace) ~= "table" or type(terrace.top) ~= "number" then
				terracesReady = false
			end
		end
	end
	if
		not irData
		or not irExpected
		or not terracesReady
		or not okIrServer
		or not irIsServer
		or type(irLook) ~= "table"
		or type(irLook.enable) ~= "function"
		or type(irLook.disable) ~= "function"
		or type(irReview) ~= "table"
		or type(irReview.enable) ~= "function"
		or type((irData :: any).KINDS) ~= "table"
		or type((irData :: any).KIND) ~= "table"
		or type((irData :: any).WATERSHEET_KIND) ~= "string"
		or type((irData :: any).terraceAttribute) ~= "string"
		or type((irData :: any).WATER_TOL) ~= "number"
	then
		irFail("server VM / irrigation modules / MapSpec TERRACES / counts not readable")
	else
		local okPrior, priorId = pcall(function()
			return (irLook :: any).current and (irLook :: any).current() or nil
		end)
		if not okPrior then
			priorId = nil
		end
		local function restoreIrPrior()
			pcall(function()
				(irLook :: any).disable()
			end)
			if type(priorId) == "string" then
				pcall(function()
					(irLook :: any).enable(priorId)
				end)
			end
		end
		local okEnable, enabled, whyEnable = pcall(function()
			return (irReview :: any).enable(IR_ID, game, { studio = true })
		end)
		if not okEnable or enabled == false then
			restoreIrPrior()
			irFail("enable:" .. tostring(whyEnable or enabled))
		else
			local irFolder = folderNamed((irData :: any).folderName)
			local tagged, watersheets, byKind = {}, {}, {}
			for _, kind in ipairs((irData :: any).KINDS) do
				byKind[kind] = 0
			end
			for _, inst in ipairs(descendantList(irFolder)) do
				local okPart, isPart = pcall(function()
					return (inst :: any):IsA("BasePart")
				end)
				local kind = attr(inst, (irData :: any).kindAttribute)
				local stage = attr(inst, (irData :: any).stageAttribute)
				if
					okPart
					and isPart
					and type(kind) == "string"
					and byKind[kind] ~= nil
					and stage == (irData :: any).familyId
				then
					byKind[kind] += 1
					tagged[#tagged + 1] = inst
					if kind == (irData :: any).WATERSHEET_KIND then
						watersheets[#watersheets + 1] = inst
					end
				end
			end
			local mismatch, expectedCounts = {}, (irExpected :: any)
			for _, kind in ipairs((irData :: any).KINDS) do
				if byKind[kind] ~= expectedCounts[kind] then
					mismatch[#mismatch + 1] = kind .. "=" .. tostring(byKind[kind])
				end
			end
			local partsOk = irFolder ~= nil
				and #tagged > 0
				and #tagged >= IR_MIN_PARTS
				and #tagged == expectedCounts.total
				and #mismatch == 0
			emit(
				"IRRIGATION_PARTS",
				partsOk,
				#tagged,
				">=" .. IR_MIN_PARTS,
				{
					folderPresent = irFolder ~= nil,
					tagged = #tagged,
					byKind = byKind,
					expected = expectedCounts,
					byKindMismatch = mismatch,
					antiVac = "all tagged Parts counted by kind; missing folder/data fails at 0",
					reason = if partsOk then nil else "missing folder / wrong kind counts",
				}
			)

			-- Water height: resolve the live MapSpec top for every tagged sheet. No CanCollide filter:
			-- every staged part is non-collidable, so only the exact tag + count + map read count.
			local worstDelta, failed = -1, {}
			for _, sheet in ipairs(watersheets) do
				local okRead, pos, size = pcall(function()
					return (sheet :: any).CFrame.Position, (sheet :: any).Size
				end)
				local terraceIndex = attr(sheet, (irData :: any).terraceAttribute)
				local topY = if okRead and pos and size then pos.Y + size.Y / 2 else nil
				local terraceTop = nil
				if
					type(terraceIndex) == "number"
					and terraceIndex >= 1
					and terraceIndex <= #MapSpec.TERRACES
					and math.floor(terraceIndex) == terraceIndex
				then
					local terrace = MapSpec.TERRACES[terraceIndex]
					if type(terrace) == "table" and type(terrace.top) == "number" then
						terraceTop = terrace.top
					end
				end
				if terraceTop == nil and okRead and pos then
					for _, terrace in ipairs(MapSpec.TERRACES) do
						if
							type(terrace) == "table"
							and type(terrace.z0) == "number"
							and type(terrace.z1) == "number"
							and pos.Z >= terrace.z0
							and pos.Z <= terrace.z1
						then
							terraceTop = terrace.top
							break
						end
					end
				end
				local delta = -1
				if topY ~= nil and terraceTop ~= nil then
					delta = math.abs(topY - terraceTop)
					if delta > worstDelta then
						worstDelta = delta
					end
				end
				if delta < 0 or delta > IR_TOL then
					local okName, name = pcall(function()
						return (sheet :: any).Name
					end)
					failed[#failed + 1] = {
						name = okName and name or "?",
						topY = topY,
						terrace = terraceIndex,
						terraceTop = terraceTop,
						delta = delta,
					}
				end
			end
			local expectedSheets = expectedCounts[(irData :: any).WATERSHEET_KIND]
			local waterOk = terracesReady
				and irFolder ~= nil
				and #watersheets > 0
				and type(expectedSheets) == "number"
				and #watersheets == expectedSheets
				and worstDelta >= 0
				and #failed == 0
			emit(
				"IRRIGATION_WATER_ON_TERRACE",
				waterOk,
				#failed,
				0,
				{
					mapReady = terracesReady,
					folderPresent = irFolder ~= nil,
					sheets = #watersheets,
					expectedSheets = expectedSheets,
					worstDelta = worstDelta,
					tolerance = IR_TOL,
					failed = failed,
					antiVac = "every tagged watersheet tested (all CanCollide=false); exact count + MapSpec readability required",
					reason = if waterOk
						then nil
						else "missing folder/data/map or a sheet top > 0.3 from its terrace top",
				}
			)
			restoreIrPrior()
		end
	end
end

do
-- 9o. WORK_QUEUE section N item 114: kincir_r8, the rotating river-bank waterwheel. ONE mutating
-- SERVER check, KINCIR_ROT. It stages the candidate itself, requires exactly one tagged wheelroot
-- and one Heartbeat connection, drives the applier's own pump(1) to read a deterministic 3..9-degree
-- step, disables the candidate (folder gone, loop disconnected), re-enables it and checks a fresh
-- root with the same rate. The prior candidate is restored on every path. IRRIGATION_* and every
-- earlier check, full_r9 and Terrain stay READ-ONLY and byte-identical. No CanCollide filter: all
-- staged parts are non-collidable; the exact root/folder counts and data/service reads are the
-- anti-vacuity guard. The name is appended after IRRIGATION_WATER_ON_TERRACE.
	local KC_ID = "kincir_r8"
	local KC_FOLDER_FALLBACK = "LookDevKincirR8_kincir_r8"
	local KC_MIN, KC_MAX = 3, 9

	local okKcModules, kcModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapKincirR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local kcData: any? = nil
	local kcLook: any? = nil
	local kcReview: any? = nil
	if okKcModules and type(kcModules) == "table" then
		if type((kcModules :: any).data) == "table" then
			kcData = (kcModules :: any).data
		end
		if type((kcModules :: any).look) == "table" then
			kcLook = (kcModules :: any).look
		end
		if type((kcModules :: any).review) == "table" then
			kcReview = (kcModules :: any).review
		end
	end
	local kcFolderName = KC_FOLDER_FALLBACK
	if kcData and type((kcData :: any).folderName) == "string" then
		kcFolderName = (kcData :: any).folderName
	end
	local kcStage: any? = if kcData then (kcData :: any).familyId else nil
	local kcKind: any? = if kcData then (kcData :: any).kindAttribute else nil
	local kcWheelKind: any? = if kcData and type((kcData :: any).KIND) == "table" then (kcData :: any).KIND.wheelroot else nil
	local kcAngleAttr: any? = if kcData then (kcData :: any).angleAttribute else nil

	local function kcFail(reason, extra)
		local detail = {
			reason = reason,
			folderPresent = folderNamed(kcFolderName) ~= nil,
			rootCount = 0,
			connectionCount = -1,
			t0 = nil,
			t1 = nil,
			delta = -1,
			teardownOk = false,
			reenableOk = false,
			antiVac = "exact one tagged root + one folder + one Heartbeat connection + readable data/service/rate required; missing input fails",
		}
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				detail[key] = value
			end
		end
		emit("KINCIR_ROT", false, 0, "3..9", detail)
	end

	local kcRunService = service("RunService")
	local okKcServer, kcIsServer = false, false
	if kcRunService then
		okKcServer, kcIsServer = pcall(function()
			return (kcRunService :: any):IsServer()
		end)
	end

	-- The review helper already resolves and requires the applier in this VM; reuse its path so
	-- the diagnostics come from the SAME module instance that LookDev.enable() registered.
	local function kcApplier(): any?
		if not kcReview or type((kcReview :: any).resolveContainer) ~= "function" then
			return nil
		end
		local ok, module = pcall(function()
			local container = (kcReview :: any).resolveContainer("server", game)
			if not container then
				return nil
			end
			local entry = (kcReview :: any).paths and (kcReview :: any).paths[KC_ID]
			if type(entry) ~= "table" or type(entry.path) ~= "table" then
				return nil
			end
			local node = container
			for _, segment in ipairs(entry.path) do
				node = node[segment]
				if not node then
					return nil
				end
			end
			return require(node)
		end)
		if not ok or not module then
			return nil
		end
		return module
	end

	local function kcTaggedRoots()
		local roots = {}
		for _, inst in ipairs(descendantList(workspace)) do
			local okPart, isPart = pcall(function()
				return (inst :: any):IsA("BasePart")
			end)
			if
				okPart
				and isPart
				and attr(inst, kcStage) == (kcData and (kcData :: any).familyId or nil)
				and attr(inst, kcKind) == kcWheelKind
			then
				roots[#roots + 1] = inst
			end
		end
		return roots
	end

	local function kcFolders()
		local folders = {}
		for _, inst in ipairs(childList(workspace)) do
			local okName, name = pcall(function()
				return (inst :: any).Name
			end)
			if okName and name == kcFolderName then
				folders[#folders + 1] = inst
			end
		end
		return folders
	end

	local function kcRate(applier, root)
		local ok0, t0 = pcall(function()
			return (root :: any):GetAttribute(kcAngleAttr)
		end)
		local okPump = pcall(function()
			(applier :: any).pump(1)
		end)
		local ok1, t1 = pcall(function()
			return (root :: any):GetAttribute(kcAngleAttr)
		end)
		if not ok0 or not ok1 or not okPump or type(t0) ~= "number" or type(t1) ~= "number" then
			return -1, t0, t1
		end
		return ((t1 - t0 + 180) % 360) - 180, t0, t1
	end

	if
		not kcData
		or not kcLook
		or not kcReview
		or not okKcServer
		or not kcIsServer
		or type((kcLook :: any).enable) ~= "function"
		or type((kcLook :: any).disable) ~= "function"
		or type((kcLook :: any).current) ~= "function"
		or type((kcReview :: any).enable) ~= "function"
		or type(kcWheelKind) ~= "string"
		or type(kcAngleAttr) ~= "string"
		or type(kcStage) ~= "string"
		or type(kcKind) ~= "string"
		or type((kcData :: any).DEG_PER_SEC) ~= "number"
		or (kcData :: any).DEG_PER_SEC ~= 6
	then
		kcFail("server VM / kincir data / LookDev / review modules not readable")
	else
		local applier = kcApplier()
		if
			not applier
			or type((applier :: any).connectionCount) ~= "function"
			or type((applier :: any).isApplied) ~= "function"
			or type((applier :: any).wheelRoot) ~= "function"
			or type((applier :: any).pump) ~= "function"
		then
			kcFail("kincir applier diagnostics not readable")
		else
			local okPrior, priorId = pcall(function()
				return (kcLook :: any).current()
			end)
			if not okPrior then
				priorId = nil
			end
			local function restoreKcPrior()
				pcall(function()
					(kcLook :: any).disable()
				end)
				if type(priorId) == "string" then
					pcall(function()
						(kcLook :: any).enable(priorId)
					end)
				end
			end
			local okEnable, enabled, whyEnable = pcall(function()
				return (kcReview :: any).enable(KC_ID, game, { studio = true })
			end)
			if not okEnable or enabled == false then
				restoreKcPrior()
				kcFail("enable:" .. tostring(whyEnable or enabled))
			else
				local folders = kcFolders()
				local roots = kcTaggedRoots()
				local okConn, connCount = pcall(function()
					return (applier :: any).connectionCount()
				end)
				local okApplied, isApplied = pcall(function()
					return (applier :: any).isApplied()
				end)
				local okRoot, root = pcall(function()
					return (applier :: any).wheelRoot()
				end)
				local detail = {
					folderPresent = #folders == 1,
					folders = #folders,
					rootCount = #roots,
					connectionCount = if okConn then connCount else -1,
					isApplied = if okApplied then isApplied else false,
					rootMatches = false,
					t0 = nil,
					t1 = nil,
					delta = -1,
					teardownOk = false,
					reenableOk = false,
					antiVac = "exact one folder/tagged root, one connection, readable attr and pump required",
				}
				if okRoot and root and #roots == 1 then
					local okSame = pcall(function()
						return roots[1] == root
					end)
					detail.rootMatches = okSame and roots[1] == root or false
				end
				if
					#folders ~= 1
					or #roots ~= 1
					or not okConn
					or connCount ~= 1
					or not okApplied
					or isApplied ~= true
					or not okRoot
					or not root
					or not detail.rootMatches
					or folderNamed(kcFolderName) == nil
				then
					restoreKcPrior()
					kcFail("staging needs one folder, one tagged wheelroot and one Heartbeat", detail)
				else
					local delta, t0, t1 = kcRate(applier, root)
					detail.t0, detail.t1, detail.delta = t0, t1, delta
					if delta < KC_MIN or delta > KC_MAX then
						restoreKcPrior()
						kcFail("pump(1) delta outside 3..9", detail)
					else
						local okDisable = pcall(function()
							(kcLook :: any).disable()
						end)
						local okConnAfter, connAfter = pcall(function()
							return (applier :: any).connectionCount()
						end)
						local teardownOk = okDisable
							and okConnAfter
							and connAfter == 0
							and #kcFolders() == 0
							and #kcTaggedRoots() == 0
							and folderNamed(kcFolderName) == nil
						detail.teardownOk = teardownOk
						detail.connectionCountAfter = if okConnAfter then connAfter else -1
						if not teardownOk then
							restoreKcPrior()
							kcFail("disable did not remove folder/loop", detail)
						else
							local okEnable2, enabled2, whyEnable2 = pcall(function()
								return (kcReview :: any).enable(KC_ID, game, { studio = true })
							end)
							local freshRoot = nil
							if okEnable2 and enabled2 ~= false then
								local okFresh, value = pcall(function()
									return (applier :: any).wheelRoot()
								end)
								if okFresh then
									freshRoot = value
								end
							end
							local freshFolders, freshRoots = kcFolders(), kcTaggedRoots()
							local okConn2, conn2 = pcall(function()
								return (applier :: any).connectionCount()
							end)
							local freshDelta, t0b, t1b = -1, nil, nil
							if freshRoot then
								freshDelta, t0b, t1b = kcRate(applier, freshRoot)
							end
							local freshDistinct = false
							if freshRoot and root then
								local okDistinct = pcall(function()
									return freshRoot ~= root
								end)
								freshDistinct = okDistinct and freshRoot ~= root or false
							end
							detail.reenableOk = okEnable2
								and enabled2 ~= false
								and freshDistinct
								and #freshFolders == 1
								and #freshRoots == 1
								and okConn2
								and conn2 == 1
								and freshDelta >= KC_MIN
								and freshDelta <= KC_MAX
							detail.freshDelta = freshDelta
							detail.freshT0 = t0b
							detail.freshT1 = t1b
							detail.freshRoots = #freshRoots
							detail.freshFolders = #freshFolders
							detail.freshConnectionCount = if okConn2 then conn2 else -1
							local passed = detail.reenableOk
							restoreKcPrior()
							if passed then
								emit("KINCIR_ROT", true, delta, "3..9", {
									rootCount = 1,
									connectionCount = 1,
									t0 = t0,
									t1 = t1,
									delta = delta,
									freshDelta = freshDelta,
									teardownOk = true,
									antiVac = detail.antiVac,
								})
							else
								kcFail("re-enable did not yield one fresh wheel with a 3..9 pump step", detail)
							end
						end
					end
				end
			end
		end
	end
end

do
-- 9p. WORK_QUEUE section N item 115: laundry_r8, hanging laundry behind two houses. ONE mutating
-- SERVER block emits LAUNDRY_PARTS and LAUNDRY_CLOTH_CLEAR. It stages laundry_r8 once, counts every
-- tagged original-Part kind against Shared.ModelMapLaundryR8.counts(), then probes EVERY tagged
-- cloth (sarung/batik/kebaya) with a temporary GetPartsInPart Part against the collidable wall
-- parts of the two hub Models. The staged folder and the probe are excluded from the overlap; all
-- probes are destroyed in a pcall path; the prior candidate is restored on every staging path.
-- Anti-vacuity: missing folder/data, zero cloths, unreadable walls or any failed probe is a FAIL.
-- CLOTH_SWAY is intentionally NOT checked here: item 85 (wind_r8) owns sway, is off by default and
-- candidates are single-active. No decal/brand/material verdict, no Terrain write; all earlier
-- checks, DOOR_CLEAR, BLDG_DOOR and full_r9 stay READ-ONLY and byte-identical.
	local LY_ID = "laundry_r8"
	local LY_FOLDER_FALLBACK = "LookDevLaundryR8_laundry_r8"

	local function lyFail(partsDetail, clearDetail)
		emit("LAUNDRY_PARTS", false, 0, ">=40", partsDetail)
		emit("LAUNDRY_CLOTH_CLEAR", false, 0, "0", clearDetail)
	end

	local okLyModules, lyModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapLaundryR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local lyData, lyLook, lyReview = nil, nil, nil
	if okLyModules and type(lyModules) == "table" then
		if type(lyModules.data) == "table" then
			lyData = lyModules.data
		end
		if type(lyModules.look) == "table" then
			lyLook = lyModules.look
		end
		if type(lyModules.review) == "table" then
			lyReview = lyModules.review
		end
	end
	local lyFolderName = LY_FOLDER_FALLBACK
	if lyData and type(lyData.folderName) == "string" then
		lyFolderName = lyData.folderName
	end

	local lyRunService = service("RunService")
	local okLyServer, lyIsServer = false, false
	if lyRunService then
		okLyServer, lyIsServer = pcall(function()
			return (lyRunService :: any):IsServer()
		end)
	end

	if
		not lyData
		or not lyLook
		or not lyReview
		or not okLyServer
		or not lyIsServer
		or type(lyLook.enable) ~= "function"
		or type(lyLook.disable) ~= "function"
		or type(lyLook.current) ~= "function"
		or type(lyReview.enable) ~= "function"
		or type(lyData.counts) ~= "function"
		or type(lyData.folderName) ~= "string"
		or type(lyData.familyId) ~= "string"
		or type(lyData.stageAttribute) ~= "string"
		or type(lyData.kindAttribute) ~= "string"
		or type(lyData.MIN_PARTS) ~= "number"
		or type(lyData.KINDS) ~= "table"
		or type(lyData.CLOTH_KINDS) ~= "table"
		or type(lyData.WALL_NAMES) ~= "table"
		or type(lyData.HUB_MODELS) ~= "table"
	then
		lyFail(
			{ reason = "server VM / laundry data / LookDev / review modules not readable", folderPresent = folderNamed(lyFolderName) ~= nil },
			{ reason = "server VM / laundry data / LookDev / review modules not readable", antiVac = "readable data + folder + cloths + walls + 0 wall hits required" }
		)
	else
		local priorId = nil
		local okPrior, value = pcall(function()
			return lyLook.current()
		end)
		if okPrior then
			priorId = value
		end
		local function lyRestorePrior()
			pcall(function()
				lyLook.disable()
			end)
			if type(priorId) == "string" then
				pcall(function()
					lyLook.enable(priorId)
				end)
			end
		end

		local okEnable, enabled, whyEnable = pcall(function()
			return lyReview.enable(LY_ID, game, { studio = true })
		end)
		if not okEnable or enabled == false then
			lyRestorePrior()
			lyFail(
				{ reason = "enable:" .. tostring(whyEnable or enabled) },
				{ reason = "enable:" .. tostring(whyEnable or enabled) }
			)
		else
			local lyFolders = {}
			for _, inst in ipairs(childList(workspace)) do
				local okName, name = pcall(function()
					return (inst :: any).Name
				end)
				if okName and name == lyFolderName then
					lyFolders[#lyFolders + 1] = inst
				end
			end
			local folder = lyFolders[1]
			local folderPresent = #lyFolders == 1 and folderNamed(lyFolderName) ~= nil

			-- Wall parts live under workspace.World hub Models named in the pure data module.
			local wallSet = {}
			for _, name in ipairs(lyData.WALL_NAMES) do
				wallSet[name] = true
			end
			local models = {}
			local walls = {}
			local world = nil
			pcall(function()
				world = workspace:FindFirstChild("World")
			end)
			if world then
				for _, name in pairs(lyData.HUB_MODELS) do
					local model = nil
					pcall(function()
						model = world:FindFirstChild(name)
					end)
					if model then
						models[#models + 1] = model
						for _, inst in ipairs(descendantList(model)) do
							local okName, partName = pcall(function()
								return (inst :: any).Name
							end)
							if okName and wallSet[partName] then
								local okBase, isBase = pcall(function()
									return (inst :: any):IsA("BasePart")
								end)
								if okBase and isBase then
									walls[#walls + 1] = inst
								end
							end
						end
					end
				end
			end

			local clothSet = {}
			for _, kind in ipairs(lyData.CLOTH_KINDS) do
				clothSet[kind] = true
			end
			local expected = lyData.counts()
			local measured = {}
			for _, kind in ipairs(lyData.KINDS) do
				measured[kind] = 0
			end
			local tagged, cloths = {}, {}
			local total = 0
			for _, inst in ipairs(descendantList(workspace)) do
				local okBase, isBase = pcall(function()
					return (inst :: any):IsA("BasePart")
				end)
				if okBase and isBase and attr(inst, lyData.stageAttribute) == lyData.familyId then
					local okKind, kind = pcall(function()
						return (inst :: any):GetAttribute(lyData.kindAttribute)
					end)
					tagged[#tagged + 1] = inst
					total += 1
					if okKind and type(kind) == "string" then
						if measured[kind] ~= nil then
							measured[kind] += 1
						end
						if clothSet[kind] then
							cloths[#cloths + 1] = inst
						end
					end
				end
			end
			local kindsExact = true
			for _, kind in ipairs(lyData.KINDS) do
				if measured[kind] ~= expected[kind] then
					kindsExact = false
				end
			end
			local partsPass = folderPresent
				and total >= lyData.MIN_PARTS
				and total == expected.total
				and #tagged == total
				and kindsExact

			-- One temporary probe per cloth. Size/CFrame come from the real staged cloth; the
			-- staged folder AND the probe are excluded, and the probe is destroyed on every path.
			local function lyProbe(cloth)
				local probe = nil
				local params = nil
				local okSetup, setupErr = pcall(function()
					probe = Instance.new("Part")
					local size = cloth.Size
					probe.Size = Vector3.new(size.X, size.Y, size.Z)
					probe.CFrame = cloth.CFrame
					probe.CanCollide = false
					probe.Transparency = 1
					probe.Anchored = false
					probe.Parent = workspace
					params = OverlapParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					local excludes = { probe }
					if folder then
						excludes[#excludes + 1] = folder
					end
					params.FilterDescendantsInstances = excludes
				end)
				if not okSetup then
					pcall(function()
						if probe then
							probe:Destroy()
						end
					end)
					return nil, tostring(setupErr)
				end
				local okHits, hits = pcall(function()
					return workspace:GetPartsInPart(probe, params)
				end)
				pcall(function()
					probe:Destroy()
				end)
				if not okHits or type(hits) ~= "table" then
					return nil, "GetPartsInPart failed"
				end
				local count = 0
				for _, hit in ipairs(hits) do
					local okCollide, collide = pcall(function()
						return (hit :: any).CanCollide
					end)
					if okCollide and collide == true then
						local okName, partName = pcall(function()
							return (hit :: any).Name
						end)
						if okName and wallSet[partName] then
							for _, model in ipairs(models) do
								local okDesc, desc = pcall(function()
									return (hit :: any):IsDescendantOf(model)
								end)
								if okDesc and desc then
									count += 1
									break
								end
							end
						end
					end
				end
				return count, nil
			end

			local probed, wallHits = 0, 0
			local probeErrors = {}
			for _, cloth in ipairs(cloths) do
				local n, err = lyProbe(cloth)
				if type(n) == "number" then
					probed += 1
					wallHits += n
				else
					probeErrors[#probeErrors + 1] = tostring(err)
				end
			end
			local clearPass = folderPresent
				and #cloths > 0
				and #walls > 0
				and probed == #cloths
				and wallHits == 0

			lyRestorePrior()
			emit("LAUNDRY_PARTS", partsPass, total, ">=40", {
				reason = if partsPass then nil else "kind counts / folder mismatch",
				folders = #lyFolders,
				folderPresent = folderPresent,
				total = total,
				expectedTotal = expected.total,
				tagged = #tagged,
				minParts = lyData.MIN_PARTS,
				measured = measured,
				expected = expected,
				kindsExact = kindsExact,
				antiVac = "one exact folder + total >= MIN_PARTS + every kind exact",
			})
			emit("LAUNDRY_CLOTH_CLEAR", clearPass, wallHits, "0", {
				reason = if clearPass then nil else "cloth / wall / probe anti-vacuity failed",
				clothCount = #cloths,
				probed = probed,
				wallModels = #models,
				wallParts = #walls,
				wallHits = wallHits,
				probeErrors = probeErrors,
				antiVac = "every tagged cloth probed + readable wall parts + 0 wall hits",
			})
		end
	end
end

do
-- 9q. WORK_QUEUE section N item 116: layangan_r8, four kites over the Lapangan field. ONE mutating
-- SERVER block emits KITE_COUNT, KITE_COST and KITE_STRING_CLEAR. It stages layangan_r8, requires
-- exactly four tagged kite roots / Beams / anchors under one Heartbeat connection with a numeric
-- KiteAngle attribute each, times a deterministic pump(SIM_SECONDS / DT) loop with os.clock, then
-- raycasts each kite down to its matched ground anchor with the staged folder excluded. Every
-- failing path emits ALL THREE checks at measured 0 / ERR / 0 and restores the prior candidate.
-- No decal/brand/material verdict and no Terrain write; all earlier checks, FLYER_COST, IDLE_COST,
-- ROCK_*, DOOR_CLEAR, BLDG_DOOR, full_r9 and the candidate set stay READ-ONLY and byte-identical.
	local KT_ID = "layangan_r8"
	local KT_FOLDER_FALLBACK = "LookDevLayanganR8_layangan_r8"

	local function ktFail(reason, extra)
		local detail = {
			reason = reason,
			folderPresent = folderNamed(KT_FOLDER_FALLBACK) ~= nil,
			rootCount = 0,
			beamCount = 0,
			anchorCount = 0,
			connectionCount = -1,
			ms = -1,
			rays = 0,
			buildingHits = 0,
			antiVac = "exact 4 roots / 4 Beams / 4 anchors / 1 connection / 4 rays + readable data and World required",
		}
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				detail[key] = value
			end
		end
		emit("KITE_COUNT", false, 0, 4, detail)
		emit("KITE_COST", false, "ERR", "<0.2ms", detail)
		emit("KITE_STRING_CLEAR", false, 0, "0", detail)
	end

	local okKtModules, ktModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapLayanganR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local ktData, ktLook, ktReview = nil, nil, nil
	if okKtModules and type(ktModules) == "table" then
		if type(ktModules.data) == "table" then
			ktData = ktModules.data
		end
		if type(ktModules.look) == "table" then
			ktLook = ktModules.look
		end
		if type(ktModules.review) == "table" then
			ktReview = ktModules.review
		end
	end
	local ktFolderName = KT_FOLDER_FALLBACK
	if ktData and type(ktData.folderName) == "string" then
		ktFolderName = ktData.folderName
	end

	local ktRunService = service("RunService")
	local okKtServer, ktIsServer = false, false
	if ktRunService then
		okKtServer, ktIsServer = pcall(function()
			return (ktRunService :: any):IsServer()
		end)
	end

	-- The same module instance LookDev.enable() registered: resolve the applier through the
	-- review path so the diagnostics describe the live staged kites.
	local function ktApplier(): any?
		if not ktReview or type((ktReview :: any).resolveContainer) ~= "function" then
			return nil
		end
		local ok, module = pcall(function()
			local container = (ktReview :: any).resolveContainer("server", game)
			if not container then
				return nil
			end
			local entry = (ktReview :: any).paths and (ktReview :: any).paths[KT_ID]
			if type(entry) ~= "table" or type(entry.path) ~= "table" then
				return nil
			end
			local node = container
			for _, segment in ipairs(entry.path) do
				node = node[segment]
				if not node then
					return nil
				end
			end
			return require(node)
		end)
		if not ok or not module then
			return nil
		end
		return module
	end

	if
		not ktData
		or not ktLook
		or not ktReview
		or not okKtServer
		or not ktIsServer
		or not mapSpecReady
		or type(ktLook.enable) ~= "function"
		or type(ktLook.disable) ~= "function"
		or type(ktLook.current) ~= "function"
		or type(ktReview.enable) ~= "function"
		or type(ktData.parts) ~= "function"
		or type(ktData.counts) ~= "function"
		or type(ktData.KINDS) ~= "table"
		or type(ktData.HUB_MODELS) ~= "table"
		or #ktData.HUB_MODELS ~= 6
		or type(ktData.BEAM) ~= "table"
		or type(ktData.BEAM.faceColour) ~= "table"
		or type(ktData.folderName) ~= "string"
		or type(ktData.familyId) ~= "string"
		or type(ktData.stageAttribute) ~= "string"
		or type(ktData.kindAttribute) ~= "string"
		or type(ktData.angleAttribute) ~= "string"
		or type(ktData.ROOT_KIND) ~= "string"
		or type(ktData.ANCHOR_KIND) ~= "string"
		or type(ktData.BEAM_KIND) ~= "string"
		or type(ktData.SIM_SECONDS) ~= "number"
		or type(ktData.DT) ~= "number"
		or type(ktData.MAX_STEP_MS) ~= "number"
		or ktData.MAX_STEP_MS ~= 0.2
		or type(ktData.KITE_ALT_MIN) ~= "number"
		or type(ktData.KITE_ALT_MAX) ~= "number"
	then
		ktFail("server VM / layangan data / LookDev / review / MapSpec not readable")
	else
		local applier = ktApplier()
		if
			not applier
			or type((applier :: any).kiteRoots) ~= "function"
			or type((applier :: any).anchors) ~= "function"
			or type((applier :: any).beams) ~= "function"
			or type((applier :: any).connectionCount) ~= "function"
			or type((applier :: any).isApplied) ~= "function"
			or type((applier :: any).pump) ~= "function"
		then
			ktFail("layangan applier diagnostics not readable")
		else
			local priorId = nil
			local okPrior, value = pcall(function()
				return (ktLook :: any).current()
			end)
			if okPrior then
				priorId = value
			end
			local function ktRestorePrior()
				pcall(function()
					(ktLook :: any).disable()
				end)
				if type(priorId) == "string" then
					pcall(function()
						(ktLook :: any).enable(priorId)
					end)
				end
			end
			local okEnable, enabled, whyEnable = pcall(function()
				return (ktReview :: any).enable(KT_ID, game, { studio = true })
			end)
			if not okEnable or enabled == false then
				ktRestorePrior()
				ktFail("enable:" .. tostring(whyEnable or enabled))
			else
				local folders = {}
				for _, inst in ipairs(childList(workspace)) do
					local okName, name = pcall(function()
						return (inst :: any).Name
					end)
					if okName and name == ktFolderName then
						folders[#folders + 1] = inst
					end
				end
				local folder = folders[1]
				local folderPresent = #folders == 1 and folderNamed(ktFolderName) ~= nil

				local function ktTagged(kind: string)
					local found = {}
					for _, inst in ipairs(descendantList(workspace)) do
						local okBase, isBase = pcall(function()
							return (inst :: any):IsA("BasePart")
						end)
						if
							okBase
							and isBase
							and attr(inst, ktData.stageAttribute) == ktData.familyId
							and attr(inst, ktData.kindAttribute) == kind
						then
							found[#found + 1] = inst
						end
					end
					return found
				end
				local roots = ktTagged(ktData.ROOT_KIND)
				local anchors = ktTagged(ktData.ANCHOR_KIND)
				local beams = {}
				if folder then
					for _, inst in ipairs(descendantList(folder)) do
						local okBeam, isBeam = pcall(function()
							return (inst :: any):IsA("Beam")
						end)
						if
							okBeam
							and isBeam
							and attr(inst, ktData.stageAttribute) == ktData.familyId
							and attr(inst, ktData.kindAttribute) == ktData.BEAM_KIND
						then
							beams[#beams + 1] = inst
						end
					end
				end

				local okApiRoots, apiRoots = pcall(function()
					return (applier :: any).kiteRoots()
				end)
				local okApiAnchors, apiAnchors = pcall(function()
					return (applier :: any).anchors()
				end)
				local okApiBeams, apiBeams = pcall(function()
					return (applier :: any).beams()
				end)
				local okConn, connCount = pcall(function()
					return (applier :: any).connectionCount()
				end)
				local okApplied, isApplied = pcall(function()
					return (applier :: any).isApplied()
				end)
				local apiReady = okApiRoots
					and okApiAnchors
					and okApiBeams
					and type(apiRoots) == "table"
					and type(apiAnchors) == "table"
					and type(apiBeams) == "table"
					and #apiRoots == 4
					and #apiAnchors == 4
					and #apiBeams == 4

				local function ktIn(list, item)
					for _, candidate in ipairs(list) do
						if candidate == item then
							return true
						end
					end
					return false
				end

				local anglesOk, altitudesOk, stringsMatched = true, true, true
				local groundY = if mapSpecReady and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else nil
				if apiReady then
					for index = 1, 4 do
						local root = apiRoots[index]
						local anchor = apiAnchors[index]
						local beam = apiBeams[index]
						if
							not ktIn(roots, root)
							or not ktIn(anchors, anchor)
							or not ktIn(beams, beam)
						then
							stringsMatched = false
						end
						local okAngle, angleValue = pcall(function()
							return (root :: any):GetAttribute(ktData.angleAttribute)
						end)
						if not okAngle or type(angleValue) ~= "number" then
							anglesOk = false
						end
						local okPos, position = pcall(function()
							return (root :: any).CFrame.Position
						end)
						if not okPos or not groundY then
							altitudesOk = false
						else
							local altitude = position.Y - groundY
							if altitude < ktData.KITE_ALT_MIN or altitude > ktData.KITE_ALT_MAX then
								altitudesOk = false
							end
						end
						local okA0, a0 = pcall(function()
							return (beam :: any).Attachment0
						end)
						local okA1, a1 = pcall(function()
							return (beam :: any).Attachment1
						end)
						local okTop, top = false, nil
						if okA0 and a0 then
							okTop, top = pcall(function()
								return (a0 :: any).Parent
							end)
						end
						local okFoot, foot = false, nil
						if okA1 and a1 then
							okFoot, foot = pcall(function()
								return (a1 :: any).Parent
							end)
						end
						if not okA0 or not okA1 or not okTop or not okFoot or top ~= root or foot ~= anchor then
							stringsMatched = false
						end
					end
				end

				local countPass = folderPresent
					and #folders == 1
					and #roots == 4
					and #anchors == 4
					and #beams == 4
					and apiReady
					and okConn
					and connCount == 1
					and okApplied
					and isApplied == true
					and anglesOk
					and altitudesOk
					and stringsMatched
					and folderNamed(ktFolderName) ~= nil

				-- Raycast from each kite to its matched ground anchor. The staged folder is excluded;
				-- only a collidable BasePart inside one of the six hub Models counts as a building hit.
				local world = nil
				pcall(function()
					world = workspace:FindFirstChild("World")
				end)
				local hubModels = {}
				if world then
					for _, name in ipairs(ktData.HUB_MODELS) do
						local model = nil
						pcall(function()
							model = world:FindFirstChild(name)
						end)
						if model then
							hubModels[#hubModels + 1] = model
						end
					end
				end
				local rays, buildingHits, rayErrors = 0, 0, {}
				if countPass and world then
					for index = 1, 4 do
						local from, to = nil, nil
						local okFrom = pcall(function()
							from = (apiRoots[index] :: any).CFrame.Position
						end)
						local okTo = pcall(function()
							to = (apiAnchors[index] :: any).CFrame.Position
						end)
						local okParams, params = pcall(function()
							local p = RaycastParams.new()
							p.FilterType = Enum.RaycastFilterType.Exclude
							p.FilterDescendantsInstances = { folder }
							return p
						end)
						if not okFrom or not okTo or not okParams or not params or (to - from).Magnitude <= 0 then
							rayErrors[#rayErrors + 1] = "kite " .. index .. " ray setup failed"
						else
							local okRay, hit = pcall(function()
								return workspace:Raycast(from, to - from, params)
							end)
							if not okRay then
								rayErrors[#rayErrors + 1] = "kite " .. index .. " raycast failed"
							else
								rays += 1
								if hit then
									local instance = hit.Instance
									local okBase, isBase = pcall(function()
										return (instance :: any):IsA("BasePart")
									end)
									local okCollide, collide = false, false
									if okBase and isBase then
										okCollide, collide = pcall(function()
											return (instance :: any).CanCollide
										end)
									end
									if okCollide and collide == true then
										for _, model in ipairs(hubModels) do
											local okDesc, desc = pcall(function()
												return (instance :: any):IsDescendantOf(model)
											end)
											if okDesc and desc then
												buildingHits += 1
												break
											end
										end
									end
								end
							end
						end
					end
				end
				local clearPass = countPass
					and world ~= nil
					and #hubModels == 6
					and rays == 4
					and #rayErrors == 0
					and buildingHits == 0

				-- Deterministic cost: the SAME applier function the Heartbeat callback calls.
				local steps = math.max(1, math.ceil(ktData.SIM_SECONDS / ktData.DT))
				local started = os.clock()
				local okSim, simErr = pcall(function()
					for _ = 1, steps do
						(applier :: any).pump(ktData.DT)
					end
				end)
				local totalElapsed = os.clock() - started
				local ms = okSim and (totalElapsed * 1000 / steps) or math.huge
				local costPass = okSim and ms >= 0 and ms < ktData.MAX_STEP_MS and ktData.MAX_STEP_MS == 0.2
				local measuredMs = if okSim then math.floor(ms * 10000) / 10000 else "ERR"

				ktRestorePrior()
				emit("KITE_COUNT", countPass, #roots, 4, {
					reason = if countPass then nil else "folder / root / Beam / anchor / angle / altitude mismatch",
					folders = #folders,
					folderPresent = folderPresent,
					rootCount = #roots,
					beamCount = #beams,
					anchorCount = #anchors,
					connectionCount = if okConn then connCount else -1,
					isApplied = if okApplied then isApplied else false,
					anglesOk = anglesOk,
					altitudesOk = altitudesOk,
					stringsMatched = stringsMatched,
					antiVac = "exact 4 roots / 4 Beams / 4 anchors / 1 connection / one numeric KiteAngle each",
				})
				emit("KITE_COST", costPass, measuredMs, "<0.2ms", {
					reason = if costPass then nil else "pump failed or ms per step >= limit: " .. tostring(simErr),
					totalMs = math.floor(totalElapsed * 1000 * 100) / 100,
					steps = steps,
					kites = #apiRoots,
					msPerStep = ms,
					limitMs = ktData.MAX_STEP_MS,
					simSeconds = ktData.SIM_SECONDS,
					dt = ktData.DT,
				})
				emit("KITE_STRING_CLEAR", clearPass, buildingHits, "0", {
					reason = if clearPass then nil else "missing World / hubs / rays or a string crosses a building",
					worldPresent = world ~= nil,
					hubModels = #hubModels,
					rays = rays,
					buildingHits = buildingHits,
					rayErrors = rayErrors,
					antiVac = "4 matched kites / 4 rays / 6 hub Models / 0 collidable building hits",
				})
			end
		end
	end
end

do
-- 9r. WORK_QUEUE section N item 117: seated_r8, four catalog R15 villagers seated on the two Warung
-- benches. ONE mutating SERVER block emits SEATED_COUNT and SEATED_ON_BENCH. It stages seated_r8,
-- waits a real 3 s, counts live Humanoid.Sit on real rig Models with a HumanoidRootPart, then probes
-- representative body Parts of every rig for collidable Bench hits under the Warung Model. Every
-- failing path emits BOTH checks at measured 0 and restores the prior candidate. No visual/material
-- verdict and no Terrain write; all earlier checks, FLYER_COST, IDLE_COST and full_r9 stay READ-ONLY.
	local SR_ID = "seated_r8"
	local SR_FOLDER_FALLBACK = "LookDevSeatedR8_seated_r8"

	local function srFail(reason, extra)
		local detail = {
			reason = reason,
			folderPresent = folderNamed(SR_FOLDER_FALLBACK) ~= nil,
			rigCount = 0,
			seatCount = 0,
			seatedCount = 0,
			benchCount = 0,
			probed = 0,
			partsProbed = 0,
			benchHits = 0,
			antiVac = "1..4 real R15 rig Models with Humanoid + HumanoidRootPart, 4 Seats, 2 Bench parts, every rig probed, 0 Bench hits",
		}
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				detail[key] = value
			end
		end
		emit("SEATED_COUNT", false, 0, 4, detail)
		emit("SEATED_ON_BENCH", false, 0, "0", detail)
	end

	local okSrModules, srModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapSeatedR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local srData, srLook, srReview = nil, nil, nil
	if okSrModules and type(srModules) == "table" then
		if type(srModules.data) == "table" then
			srData = srModules.data
		end
		if type(srModules.look) == "table" then
			srLook = srModules.look
		end
		if type(srModules.review) == "table" then
			srReview = srModules.review
		end
	end
	local srFolderName = SR_FOLDER_FALLBACK
	if srData and type(srData.folderName) == "string" then
		srFolderName = srData.folderName
	end

	local srRunService = service("RunService")
	local srPlayers = service("Players")
	local okSrServer, srIsServer = false, false
	if srRunService then
		okSrServer, srIsServer = pcall(function()
			return (srRunService :: any):IsServer()
		end)
	end

	-- Resolve the same applier instance LookDev.enable() registered, so diagnostics describe the
	-- live staged rigs rather than a second require of the module.
	local function srApplier(): any?
		if not srReview or type((srReview :: any).resolveContainer) ~= "function" then
			return nil
		end
		local ok, module = pcall(function()
			local container = (srReview :: any).resolveContainer("server", game)
			if not container then
				return nil
			end
			local entry = (srReview :: any).paths and (srReview :: any).paths[SR_ID]
			if type(entry) ~= "table" or type(entry.path) ~= "table" then
				return nil
			end
			local node = container
			for _, segment in ipairs(entry.path) do
				node = node[segment]
				if not node then
					return nil
				end
			end
			return require(node)
		end)
		if not ok or not module then
			return nil
		end
		return module
	end

	if
		not srData
		or not srLook
		or not srReview
		or not srPlayers
		or not okSrServer
		or not srIsServer
		or not mapSpecReady
		or type(srLook.enable) ~= "function"
		or type(srLook.disable) ~= "function"
		or type(srLook.current) ~= "function"
		or type(srReview.enable) ~= "function"
		or type(srData.folderName) ~= "string"
		or type(srData.familyId) ~= "string"
		or type(srData.stageAttribute) ~= "string"
		or type(srData.kindAttribute) ~= "string"
		or type(srData.SEAT_KIND) ~= "string"
		or type(srData.PROBE_PARTS) ~= "table"
		or type(srData.OUTFITS) ~= "table"
		or #srData.OUTFITS ~= 4
		or type(srData.SITES) ~= "table"
		or #srData.SITES ~= 4
		or type(srData.WARUNG) ~= "table"
		or type(srData.WARUNG.model) ~= "string"
	then
		srFail("server VM / seated data / LookDev / review / MapSpec not readable")
	else
		local applier = srApplier()
		if
			not applier
			or type((applier :: any).rigs) ~= "function"
			or type((applier :: any).seatCount) ~= "function"
			or type((applier :: any).isApplied) ~= "function"
			or type((applier :: any).sitStates) ~= "function"
		then
			srFail("seated applier diagnostics not readable")
		else
			local priorId = nil
			local okPrior, value = pcall(function()
				return (srLook :: any).current()
			end)
			if okPrior then
				priorId = value
			end
			local function srRestorePrior()
				pcall(function()
					(srLook :: any).disable()
				end)
				if type(priorId) == "string" then
					pcall(function()
						(srLook :: any).enable(priorId)
					end)
				end
			end
			local okEnable, enabled, whyEnable = pcall(function()
				return (srReview :: any).enable(SR_ID, game, { studio = true })
			end)
			if not okEnable or enabled == false then
				srRestorePrior()
				srFail("enable:" .. tostring(whyEnable or enabled))
			else
				local folders = {}
				for _, inst in ipairs(childList(workspace)) do
					local okName, name = pcall(function()
						return (inst :: any).Name
					end)
					if okName and name == srFolderName then
						folders[#folders + 1] = inst
					end
				end
				local folder = folders[1]
				local folderPresent = #folders == 1 and folderNamed(srFolderName) ~= nil

				-- Real wait: the rigs are created by an async catalog call and Sit settles after the
				-- engine has welded the accessory hierarchy. Read Sit only after 3 real seconds.
				local okWait, waitError = pcall(function()
					task.wait(3)
				end)
				if not okWait then
					srRestorePrior()
					srFail("real wait failed: " .. tostring(waitError))
				else
					local okRigs, apiRigs = pcall(function()
						return (applier :: any).rigs()
					end)
					local okSeats, apiSeats = pcall(function()
						return (applier :: any).seatCount()
					end)
					local okStates, apiStates = pcall(function()
						return (applier :: any).sitStates()
					end)
					local okApplied, apiApplied = pcall(function()
						return (applier :: any).isApplied()
					end)
					local rigs = (okRigs and type(apiRigs) == "table") and apiRigs or {}
					local states = (okStates and type(apiStates) == "table") and apiStates or {}

					local function srIn(list, item)
						for _, candidate in ipairs(list) do
							if candidate == item then
								return true
							end
						end
						return false
					end

					-- Anti-vacuity: only real R15 rig Models with a Humanoid AND a HumanoidRootPart
					-- count. Dummy Parts or a folder with bare meshes cannot pass.
					local tagged = {}
					local seatParts = {}
					if folder then
						for _, inst in ipairs(descendantList(folder)) do
							local okTagged = pcall(function()
								return attr(inst, srData.stageAttribute) == srData.familyId
							end)
							if okTagged and attr(inst, srData.stageAttribute) == srData.familyId then
								local okModel, isModel = pcall(function()
									return (inst :: any):IsA("Model")
								end)
								if okModel and isModel then
									local okHumanoid, humanoid = pcall(function()
										return (inst :: any):FindFirstChildOfClass("Humanoid")
									end)
									local okRoot, root = pcall(function()
										return (inst :: any):FindFirstChild("HumanoidRootPart")
									end)
									if okHumanoid and humanoid and okRoot and root then
										tagged[#tagged + 1] = inst
									end
								end
								local okPart, isPart = pcall(function()
									return (inst :: any):IsA("BasePart")
								end)
								if okPart and isPart and attr(inst, srData.kindAttribute) == srData.SEAT_KIND then
									seatParts[#seatParts + 1] = inst
								end
							end
						end
					end

					local seatedCount = 0
					local stateMismatch = false
					local rigsMatched = true
					for index, entry in ipairs(rigs) do
						if type(entry) ~= "table" then
							rigsMatched = false
						else
							local okModel = pcall(function()
								return (entry.model :: any):IsA("Model")
							end)
							local okHumanoid = pcall(function()
								return (entry.humanoid :: any):IsA("Humanoid")
							end)
							if
								not okModel
								or not okHumanoid
								or not srIn(tagged, entry.model)
								or not srIn(seatParts, entry.seat)
							then
								rigsMatched = false
							end
							local okLive, liveSit = pcall(function()
								return (entry.humanoid :: any).Sit
							end)
							-- Count only a Sit that is still true after the real wait.
							if okLive and liveSit == true then
								seatedCount += 1
							end
							if states[index] ~= (okLive and liveSit == true) then
								stateMismatch = true
							end
						end
					end

					local countPass = folderPresent
						and #folders == 1
						and #rigs >= 1
						and #rigs <= 4
						and #tagged == #rigs
						and #seatParts == 4
						and okSeats
						and apiSeats == 4
						and okApplied
						and apiApplied == true
						and #states == #rigs
						and not stateMismatch
						and rigsMatched
						and seatedCount >= 1
						and seatedCount <= 4

					-- SEATED_ON_BENCH: a temporary Part at each representative body Part's real
					-- CFrame/Size, with the probe, the staged folder and the owning rig excluded.
					local world = nil
					pcall(function()
						world = workspace:FindFirstChild("World")
					end)
					local warung = nil
					if world then
						pcall(function()
							warung = world:FindFirstChild(srData.WARUNG.model)
						end)
					end
					local benchParts = {}
					if warung then
						for _, inst in ipairs(descendantList(warung)) do
							local okBase, isBase = pcall(function()
								return (inst :: any):IsA("BasePart")
							end)
							local okName, name = pcall(function()
								return (inst :: any).Name
							end)
							local okCollide, collide = pcall(function()
								return (inst :: any).CanCollide
							end)
							if okBase and isBase and okName and name == "Bench" and okCollide and collide == true then
								benchParts[#benchParts + 1] = inst
							end
						end
					end

					local function srProbe(part, rig)
						local probe, params = nil, nil
						local okSetup, setupError = pcall(function()
							probe = Instance.new("Part")
							local size = part.Size
							probe.Size = Vector3.new(size.X, size.Y, size.Z)
							probe.CFrame = part.CFrame
							probe.CanCollide = false
							probe.Transparency = 1
							probe.Anchored = false
							probe.Parent = workspace
							params = OverlapParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							local excludes = { probe }
							if folder then
								excludes[#excludes + 1] = folder
							end
							if rig then
								excludes[#excludes + 1] = rig
							end
							params.FilterDescendantsInstances = excludes
						end)
						local function destroyProbe()
							pcall(function()
								if probe then
									probe:Destroy()
								end
							end)
						end
						if not okSetup or not params then
							destroyProbe()
							return nil, tostring(setupError)
						end
						local okHits, hits = pcall(function()
							return workspace:GetPartsInPart(probe, params)
						end)
						destroyProbe()
						if not okHits or type(hits) ~= "table" then
							return nil, "GetPartsInPart failed"
						end
						local hitsOnBench = 0
						for _, hit in ipairs(hits) do
							local okName, name = pcall(function()
								return (hit :: any).Name
							end)
							local okCollide, collide = pcall(function()
								return (hit :: any).CanCollide
							end)
							local okDesc, desc = pcall(function()
								return (hit :: any):IsDescendantOf(warung)
							end)
							if okName and name == "Bench" and okCollide and collide == true and okDesc and desc then
								hitsOnBench += 1
							end
						end
						return hitsOnBench, nil
					end

					local probed, partsProbed, benchHits = 0, 0, 0
					local probeErrors = {}
					if countPass and warung then
						for _, entry in ipairs(rigs) do
							local rig = entry.model
							local bodyParts = {}
							local okDescendants, descendants = pcall(function()
								return rig:GetDescendants()
							end)
							if okDescendants and descendants then
								for _, partName in ipairs(srData.PROBE_PARTS) do
									for _, part in ipairs(descendants) do
										local okName, name = pcall(function()
											return (part :: any).Name
										end)
										local okBase, isBase = pcall(function()
											return (part :: any):IsA("BasePart")
										end)
										if okName and name == partName and okBase and isBase then
											bodyParts[#bodyParts + 1] = part
											break
										end
									end
								end
							end
							local rigProbed = #bodyParts >= 4
							for _, part in ipairs(bodyParts) do
								local hits, err = srProbe(part, rig)
								if type(hits) == "number" then
									partsProbed += 1
									benchHits += hits
								else
									rigProbed = false
									probeErrors[#probeErrors + 1] = err
								end
							end
							if rigProbed then
								probed += 1
							end
						end
					end
					local benchPass = countPass
						and folderPresent
						and warung ~= nil
						and #benchParts == 2
						and probed == #rigs
						and #probeErrors == 0
						and benchHits == 0

					srRestorePrior()
					emit("SEATED_COUNT", countPass, seatedCount, 4, {
						reason = if countPass then nil else "folder / rig / seat / Sit anti-vacuity failed",
						folders = #folders,
						folderPresent = folderPresent,
						rigCount = #rigs,
						taggedModels = #tagged,
						seatCount = if okSeats then apiSeats else -1,
						seatParts = #seatParts,
						seatedCount = seatedCount,
						sitStates = states,
						stateMismatch = stateMismatch,
						isApplied = if okApplied then apiApplied else false,
						antiVac = "1..4 real R15 rig Models with Humanoid + HumanoidRootPart matched to 4 Seats; live Sit true after 3 s",
					})
					emit("SEATED_ON_BENCH", benchPass, benchHits, "0", {
						reason = if benchPass then nil else "missing Warung / Bench parts or a seated body Part clips a Bench",
						folderPresent = folderPresent,
						warungPresent = warung ~= nil,
						benchCount = #benchParts,
						rigs = #rigs,
						probed = probed,
						partsProbed = partsProbed,
						benchHits = benchHits,
						probeErrors = probeErrors,
						antiVac = "2 collidable Bench parts / all 4 rigs probed at representative body Parts / 0 Bench hits",
					})
				end
			end
		end
	end
end

do
-- 9s. WORK_QUEUE section N item 118: crops_showcase_r8, three stage plots (bibit, tumbuh, siap)
-- with all 12 crops in a row per plot. ONE mutating SERVER block emits CROPS_STAGED. It stages the
-- candidate, then counts only tagged Models named with the crop+stage convention inside the staged
-- folder, requires 3 stage plots each holding 12 distinct crops, and rejects any staged state-holding
-- object. Every failing path emits CROPS_STAGED at measured 0 and restores the prior candidate.
-- No Terrain read/write and no visual verdict; all earlier checks, FLYER_COST, IDLE_COST and full_r9
-- stay READ-ONLY.
	local CS_ID = "crops_showcase_r8"
	local CS_FOLDER_FALLBACK = "LookDevCropsShowcaseR8_crops_showcase_r8"

	local function csFail(reason, extra)
		local detail = {
			reason = reason,
			folderPresent = folderNamed(CS_FOLDER_FALLBACK) ~= nil,
			plots = 0,
			taggedCrops = 0,
			duplicates = 0,
			parts = 0,
			stateObjects = 0,
			antiVac = "1 staged folder / 3 named stage plots x 12 named crop Models / 36 total / 0 state objects",
		}
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				detail[key] = value
			end
		end
		emit("CROPS_STAGED", false, 0, 36, detail)
	end

	local okCsModules, csModules = pcall(function()
		return {
			data = require(game.ReplicatedStorage.Shared.ModelMapCropsShowcaseR8),
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
		}
	end)
	local csData, csLook, csReview = nil, nil, nil
	if okCsModules and type(csModules) == "table" then
		if type(csModules.data) == "table" then
			csData = csModules.data
		end
		if type(csModules.look) == "table" then
			csLook = csModules.look
		end
		if type(csModules.review) == "table" then
			csReview = csModules.review
		end
	end
	local csFolderName = CS_FOLDER_FALLBACK
	if csData and type(csData.folderName) == "string" then
		csFolderName = csData.folderName
	end

	local csRunService = service("RunService")
	local okCsServer, csIsServer = false, false
	if csRunService then
		okCsServer, csIsServer = pcall(function()
			return (csRunService :: any):IsServer()
		end)
	end

	-- Resolve the SAME applier instance LookDev.enable() registered, so diagnostics describe the
	-- live staged geometry rather than a second require of the module.
	local function csApplier(): any?
		if not csReview or type((csReview :: any).resolveContainer) ~= "function" then
			return nil
		end
		local ok, module = pcall(function()
			local container = (csReview :: any).resolveContainer("server", game)
			if not container then
				return nil
			end
			local entry = (csReview :: any).paths and (csReview :: any).paths[CS_ID]
			if type(entry) ~= "table" or type(entry.path) ~= "table" then
				return nil
			end
			local node = container
			for _, segment in ipairs(entry.path) do
				node = node[segment]
				if not node then
					return nil
				end
			end
			return require(node)
		end)
		if not ok or not module then
			return nil
		end
		return module
	end

	if
		not csData
		or not csLook
		or not csReview
		or not okCsServer
		or not csIsServer
		or not mapSpecReady
		or type(csLook.enable) ~= "function"
		or type(csLook.disable) ~= "function"
		or type(csLook.current) ~= "function"
		or type(csReview.enable) ~= "function"
		or type(csData.folderName) ~= "string"
		or type(csData.familyId) ~= "string"
		or type(csData.stageAttribute) ~= "string"
		or type(csData.kindAttribute) ~= "string"
		or type(csData.CROP_PREFIX) ~= "string"
		or type(csData.CROPS) ~= "table"
		or #csData.CROPS ~= 12
		or type(csData.STAGES) ~= "table"
		or #csData.STAGES ~= 3
		or type(csData.PLOTS) ~= "table"
		or #csData.PLOTS ~= 3
		or type(csData.COUNTS) ~= "table"
		or csData.COUNTS.models ~= 36
		or type(csData.PLOT_KIND) ~= "string"
		or type(csData.CROP_KIND) ~= "string"
	then
		csFail("server VM / crop data / LookDev / review / MapSpec not readable")
	else
		local applier = csApplier()
		if
			not applier
			or type((applier :: any).plotModels) ~= "function"
			or type((applier :: any).cropModels) ~= "function"
			or type((applier :: any).counts) ~= "function"
			or type((applier :: any).isApplied) ~= "function"
		then
			csFail("crops showcase applier diagnostics not readable")
		else
			local priorId = nil
			local okPrior, value = pcall(function()
				return (csLook :: any).current()
			end)
			if okPrior then
				priorId = value
			end
			local priorFolderExisted = folderNamed(csFolderName) ~= nil
			local function csRestorePrior()
				pcall(function()
					(csLook :: any).disable()
				end)
				if type(priorId) == "string" then
					pcall(function()
						(csLook :: any).enable(priorId)
					end)
				end
			end
			local okEnable, enabled, whyEnable = pcall(function()
				return (csReview :: any).enable(CS_ID, game, { studio = true })
			end)
			if not okEnable or enabled == false then
				csRestorePrior()
				csFail("enable:" .. tostring(whyEnable or enabled))
			else
				local folders = {}
				for _, inst in ipairs(childList(workspace)) do
					local okName, name = pcall(function()
						return (inst :: any).Name
					end)
					if okName and name == csFolderName then
						folders[#folders + 1] = inst
					end
				end
				local folder = folders[1]
				local folderPresent = #folders == 1 and folderNamed(csFolderName) ~= nil

				local okPlots, apiPlots = pcall(function()
					return (applier :: any).plotModels()
				end)
				local okCrops, apiCrops = pcall(function()
					return (applier :: any).cropModels()
				end)
				local okCounts, apiCounts = pcall(function()
					return (applier :: any).counts()
				end)
				local okApplied, apiApplied = pcall(function()
					return (applier :: any).isApplied()
				end)

				local expected = {}
				for _, crop in ipairs(csData.CROPS) do
					for _, stage in ipairs(csData.STAGES) do
						expected[csData.CROP_PREFIX .. crop .. "_" .. stage] = { crop = crop, stage = stage }
					end
				end

				-- Anti-vacuity: only tagged MODELS with an exact crop+stage name count. A dummy Part,
				-- a bare mesh, a wrong name or a crop staged twice cannot pass.
				local taggedCrops, plotModels = {}, {}
				local stateObjects, partCount, duplicates = 0, 0, 0
				local stageCounts, cropNamesSeen = {}, {}
				if folder then
					for _, inst in ipairs(descendantList(folder)) do
						local okTagged = pcall(function()
							return attr(inst, csData.stageAttribute) == csData.familyId
						end)
						if okTagged and attr(inst, csData.stageAttribute) == csData.familyId then
							local okBase, isBase = pcall(function()
								return (inst :: any):IsA("BasePart")
							end)
							if okBase and isBase then
								partCount += 1
							end
							local okModel, isModel = pcall(function()
								return (inst :: any):IsA("Model")
							end)
							if okModel and isModel then
								local okName, name = pcall(function()
									return (inst :: any).Name
								end)
								local kind = attr(inst, csData.kindAttribute)
								if okName and kind == csData.CROP_KIND and expected[name] then
									if cropNamesSeen[name] then
										duplicates += 1
									end
									cropNamesSeen[name] = true
									taggedCrops[#taggedCrops + 1] = inst
									stageCounts[expected[name].stage] = (stageCounts[expected[name].stage] or 0) + 1
								elseif okName and kind == csData.PLOT_KIND then
									plotModels[#plotModels + 1] = inst
								end
							end
							-- No Script, ValueBase or Remote object may be staged: geometry only.
							local okState, isState = pcall(function()
								return (inst :: any):IsA("ValueBase")
									or (inst :: any):IsA("LuaSourceContainer")
									or (inst :: any):IsA("RemoteEvent")
									or (inst :: any):IsA("RemoteFunction")
							end)
							if okState and isState then
								stateObjects += 1
							end
						end
					end
				end

				local plotShapeOk = true
				for _, plot in ipairs(csData.PLOTS) do
					local found = nil
					for _, model in ipairs(plotModels) do
						local okName, name = pcall(function()
							return (model :: any).Name
						end)
						if okName and name == "Plot_" .. plot.stage then
							found = model
							break
						end
					end
					if not found then
						plotShapeOk = false
					else
						local cropsHere, namesHere = 0, {}
						for _, child in ipairs(childList(found)) do
							local kind = attr(child, csData.kindAttribute)
							if kind == csData.CROP_KIND then
								local okName, name = pcall(function()
									return (child :: any).Name
								end)
								if
									okName
									and expected[name]
									and expected[name].stage == plot.stage
									and not namesHere[name]
								then
									namesHere[name] = true
									cropsHere += 1
								end
							end
						end
						if cropsHere ~= csData.COUNTS.crops then
							plotShapeOk = false
						end
					end
				end

				csRestorePrior()
				local leftover = folderNamed(csFolderName) ~= nil
				local restoreOk = leftover == priorFolderExisted
				local measured = #taggedCrops
				local csPass = folderPresent
					and #folders == 1
					and #plotModels == csData.COUNTS.plots
					and plotShapeOk
					and measured == csData.COUNTS.models
					and duplicates == 0
					and partCount >= 303
					and partCount <= 340
					and stateObjects == 0
					and okPlots
					and type(apiPlots) == "table"
					and #apiPlots == 3
					and okCrops
					and type(apiCrops) == "table"
					and #apiCrops == 36
					and okCounts
					and type(apiCounts) == "table"
					and apiCounts.plots == 3
					and apiCounts.models == 36
					and okApplied
					and apiApplied == true
					and restoreOk
				emit("CROPS_STAGED", csPass, measured, 36, {
					reason = if csPass then nil else "folder / plot / crop-model / anti-vacuity check failed",
					folders = #folders,
					folderPresent = folderPresent,
					plots = #plotModels,
					stageCounts = stageCounts,
					taggedCrops = #taggedCrops,
					duplicates = duplicates,
					apiPlots = if okPlots and type(apiPlots) == "table" then #apiPlots else -1,
					apiCrops = if okCrops and type(apiCrops) == "table" then #apiCrops else -1,
					apiModels = if okCounts and type(apiCounts) == "table" then apiCounts.models else -1,
					parts = partCount,
					stateObjects = stateObjects,
					isApplied = if okApplied then apiApplied else false,
					restoreOk = restoreOk,
					antiVac = "1 staged folder / 3 named stage plots x 12 named crop Models / 36 total / 0 state objects",
				})
			end
		end
	end
end

-- 9t. WORK_QUEUE section N item 119: season_r8_* seasonal look. THREE MUTATING CLIENT checks.
-- SEASON_SAFE reads every touched Lighting/Atmosphere/Clouds value after each enable against the
-- pure season-safe ranges. SEASON_RESTORE compares every touched value, tinted decor colour and the
-- Workspace descendant count to the captured baseline after each disable. SEASON_DISTINCT computes
-- the item's pairwise >=10% clause from pure data (target 2 differing values per pair). The prior
-- candidate id is captured and re-enabled on EVERY path. Own do...end + inner function: the harness
-- is near the 200-local cap. No existing check is touched.
do
local function seasonFailAll(reason)
	emit("SEASON_SAFE", false, 0, 3, { reason = reason })
	emit("SEASON_RESTORE", false, 0, 3, { reason = reason })
	emit("SEASON_DISTINCT", false, 0, 2, { reason = reason })
end

local function runSeasonChecks()
	-- Own RunService gate: the shared isClient local is declared LATER in this harness. Clouds and
	-- Atmosphere exist only in the Client VM (Sky creates them), and Sky tweens Cover for 4 s on
	-- mount, so ONE bounded wait settles it before the baseline is captured. No polling loop.
	local okRun, run = pcall(function()
		return game:GetService("RunService")
	end)
	local seasonIsClient = okRun and run and run:IsClient() or false
	if not seasonIsClient then
		seasonFailAll("client VM required")
		return
	end
	task.wait(5)
	-- Client container exactly as LookDevReview.resolveContainer("client", game): LocalPlayer's
	-- PlayerScripts.Client, with the harness-friendly game.PlayerScripts.Client fallback.
	local function seasonApplier()
		local okLocal, localModule = pcall(function()
			return require(game.Players.LocalPlayer.PlayerScripts.Client.World.LookDevSeasonR8)
		end)
		if okLocal and type(localModule) == "table" then
			return localModule
		end
		local okDirect, directModule = pcall(function()
			return require(game.PlayerScripts.Client.World.LookDevSeasonR8)
		end)
		return if okDirect then directModule else nil
	end
	local okMods, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			map = require(game.ReplicatedStorage.Shared.ModelMapSeasonR8),
			-- Registration happens at module load; a saved place's boot script may predate this one.
			applier = seasonApplier(),
		}
	end)
	if
		not okMods
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.disable) ~= "function"
		or type(mods.look.current) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.order) ~= "table"
		or type(mods.map.safeRanges) ~= "table"
		or type(mods.applier) ~= "table"
		or type(mods.applier.appliedKey) ~= "function"
		or type(mods.applier.isApplied) ~= "function"
	then
		seasonFailAll("modules unreadable: " .. tostring(mods))
		return
	end
	local look, seasonMap, seasonApi = mods.look, mods.map, mods.applier
	local Workspace = workspace -- harness has no uppercase Workspace local
	local errors, readings, safeFails, restoreFails = {}, {}, {}, {}
	local safeCount, restoredCount = 0, 0

	local function seasonFail(reason)
		errors[#errors + 1] = reason
	end
	local function readProp(className, prop)
		if className == "Lighting" then
			return pcall(function()
				return Lighting[prop]
			end)
		end
		if className == "Atmosphere" then
			return pcall(function()
				local effect = Lighting:FindFirstChildOfClass("Atmosphere")
				return if effect then effect[prop] else nil
			end)
		end
		return pcall(function()
			local terrain = Workspace:FindFirstChild("Terrain")
			local clouds = if terrain then terrain:FindFirstChildOfClass("Clouds") else nil
			return if clouds then clouds[prop] else nil
		end)
	end
	local function snapshotAll()
		local out = {}
		for _, className in ipairs({ "Lighting", "Atmosphere", "Clouds" }) do
			out[className] = {}
			for _, prop in ipairs(seasonMap.properties[className]) do
				local ok, value = readProp(className, prop)
				if not ok then
					seasonFail("baseline:" .. className .. "." .. prop .. ":" .. tostring(value))
				end
				out[className][prop] = value
			end
		end
		return out
	end
	local function equalVal(a, b)
		if typeof(a) == "Color3" or typeof(b) == "Color3" then
			if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
				return false
			end
			return a.R == b.R and a.G == b.G and a.B == b.B
		end
		return a == b
	end
	local function equalSnapshot(a, b)
		for _, className in ipairs({ "Lighting", "Atmosphere", "Clouds" }) do
			for _, prop in ipairs(seasonMap.properties[className]) do
				if not equalVal(a[className][prop], b[className][prop]) then
					return false, className .. "." .. prop
				end
			end
		end
		return true
	end
	local function inBand(range, value)
		if type(range) ~= "table" or type(range.min) ~= "number" or type(value) ~= "number" then
			return false, "bad range"
		end
		if value < range.min or value > range.max then
			return false, tostring(value)
		end
		return true
	end
	local function valueInBand(className, prop, value, ranges)
		local range = ranges and ranges[prop]
		if prop == "Color" or prop == "Decay" or prop == "Ambient" or prop == "OutdoorAmbient"
			or prop == "ColorShift_Top" or prop == "ColorShift_Bottom" or prop == "FogColor" then
			if typeof(value) ~= "Color3" then
				return false, "type=" .. typeof(value)
			end
			for _, channel in ipairs({ "R", "G", "B" }) do
				local ok, why = inBand(range and range[channel], value[channel] * 255)
				if not ok then
					return false, channel .. "=" .. tostring(why)
				end
			end
			if className == "Atmosphere" and prop == "Color"
				and not (value.R >= value.G and value.G >= value.B) then
				return false, "not warm white"
			end
			if className == "Atmosphere" and prop == "Decay"
				and not (value.B >= value.G and value.G >= value.R) then
				return false, "not light blue"
			end
			return true
		end
		return inBand(range, value)
	end
	local function matchingParts(selector)
		local found = {}
		local okList, list = pcall(function()
			return Workspace:GetDescendants()
		end)
		if not okList or type(list) ~= "table" then
			return found
		end
		for _, instance in ipairs(list) do
			if #found >= selector.max then
				break
			end
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				local use = true
				if selector.namePrefix then
					local okName, name = pcall(function()
						return instance.Name
					end)
					use = okName and string.sub(name, 1, #selector.namePrefix) == selector.namePrefix
				end
				if use then
					local okAttr, value = pcall(function()
						return instance:GetAttribute(selector.attribute)
					end)
					use = okAttr and value ~= nil
				end
				if use then
					found[#found + 1] = instance
				end
			end
		end
		return found
	end
	local function decorSnapshot()
		local out = {}
		for _, selector in ipairs(seasonMap.TINT_SELECTORS) do
			for index, part in ipairs(matchingParts(selector)) do
				local okColor, color = pcall(function()
					return part.Color
				end)
				if okColor then
					out[selector.key .. ":" .. index] = color
				end
			end
		end
		return out
	end
	local function equalDecor(a, b)
		for key, color in pairs(a) do
			if not equalVal(color, b[key]) then
				return false, key
			end
		end
		for key in pairs(b) do
			if a[key] == nil then
				return false, key .. ":added"
			end
		end
		return true
	end
	local function countDesc()
		local ok, list = pcall(function()
			return Workspace:GetDescendants()
		end)
		return if ok and type(list) == "table" then #list else nil
	end
	local function puddleFolder()
		local ok, folder = pcall(function()
			return Workspace:FindFirstChild(seasonMap.PUDDLE_FOLDER)
		end)
		return if ok then folder else nil
	end
	local function flatten(value, out)
		if type(value) == "table" then
			for _, channel in ipairs({ "r", "g", "b" }) do
				if type(value[channel]) == "number" then
					out[#out + 1] = value[channel]
				end
			end
		elseif type(value) == "number" then
			out[#out + 1] = value
		end
	end
	local function numbersFor(key)
		local out, values = {}, seasonMap.valuesFor(key)
		for _, className in ipairs({ "Lighting", "Atmosphere", "Clouds" }) do
			for _, prop in ipairs(seasonMap.properties[className]) do
				flatten(values[className][prop], out)
			end
		end
		local tints = seasonMap.tintsFor(key)
		for _, selector in ipairs(seasonMap.TINT_SELECTORS) do
			flatten(tints[selector.key], out)
		end
		return out
	end
	local function diffCount(a, b)
		local count = 0
		for index, left in ipairs(a) do
			local right = b[index]
			local scale = math.max(math.abs(left), math.abs(right), 0.001)
			if math.abs(left - right) / scale * 100 >= seasonMap.DISTINCT_PCT then
				count += 1
			end
		end
		return count
	end

	local priorId = nil
	local okPrior, current = pcall(function()
		return look.current()
	end)
	if okPrior and type(current) == "string" then
		priorId = current
	end
	local baseline = snapshotAll()
	local baseDecor = decorSnapshot()
	local baseDesc = countDesc()
	local basePuddles = puddleFolder() ~= nil
	local variantCount = #seasonMap.order
	if not baseDesc then
		seasonFail("baseline Workspace descendant count unreadable")
	end

	for _, key in ipairs(seasonMap.order) do
		local id = seasonMap.idPrefix .. key
		local okEnable, enabled, enableErr = pcall(function()
			return look.enable(id, { studio = true })
		end)
		if not okEnable or enabled == false then
			seasonFail(id .. ":enable:" .. tostring(enableErr or enabled))
		else
			local safe = true
			for _, className in ipairs({ "Lighting", "Atmosphere", "Clouds" }) do
				for _, prop in ipairs(seasonMap.properties[className]) do
					local okRead, value = readProp(className, prop)
					readings[#readings + 1] = id .. "." .. className .. "." .. prop .. "=" .. tostring(value)
					if not okRead then
						safe = false
						safeFails[#safeFails + 1] = id .. "." .. className .. "." .. prop .. ":read"
					else
						local inBandNow, why = valueInBand(
							className,
							prop,
							value,
							seasonMap.safeRanges[className]
						)
						if not inBandNow then
							safe = false
							safeFails[#safeFails + 1] = id .. "." .. className .. "." .. prop .. ":" .. tostring(why)
						end
					end
				end
			end
			local appliedKey = seasonApi.appliedKey()
			if appliedKey ~= key or seasonApi.isApplied() ~= true then
				safe = false
				safeFails[#safeFails + 1] = id .. ":plan-key:" .. tostring(appliedKey)
			end
			if seasonMap.puddlesFor(key) > 0 then
				local folder = puddleFolder()
				local sheets = 0
				if folder then
					local okChildren, children = pcall(function()
						return folder:GetChildren()
					end)
					if okChildren then
						sheets = #children
					end
				end
				if sheets ~= #seasonMap.PUDDLE_SHEETS then
					safe = false
					safeFails[#safeFails + 1] = id .. ":puddle-sheets:" .. sheets
				end
			end
			if safe then
				safeCount += 1
			end
		end

		local okDisable, disabled = pcall(function()
			return look.disable()
		end)
		if not okDisable then
			seasonFail(id .. ":disable:" .. tostring(disabled))
		end
		local after = snapshotAll()
		local same, why = equalSnapshot(baseline, after)
		local sameDecor, decorWhy = equalDecor(baseDecor, decorSnapshot())
		local afterDesc = countDesc()
		local afterPuddles = puddleFolder() ~= nil
		if not same or not sameDecor or afterDesc ~= baseDesc or afterPuddles ~= basePuddles or not okDisable then
			local reason = if not same
				then tostring(why)
				elseif not sameDecor then "decor:" .. tostring(decorWhy)
				elseif afterDesc ~= baseDesc then "descendants " .. tostring(baseDesc) .. "->" .. tostring(afterDesc)
				elseif afterPuddles ~= basePuddles then "puddle folder persisted"
				else "disable failed"
			restoreFails[#restoreFails + 1] = id .. ":" .. reason
		else
			restoredCount += 1
		end
	end

	local minDiff = math.huge
	local pairCounts = {}
	for index = 1, #seasonMap.order - 1 do
		for other = index + 1, #seasonMap.order do
			local left, right = seasonMap.order[index], seasonMap.order[other]
			local count = diffCount(numbersFor(left), numbersFor(right))
			pairCounts[left .. "-" .. right] = count
			if count < minDiff then
				minDiff = count
			end
		end
	end
	if minDiff == math.huge then
		minDiff = 0
	end

	if priorId then
		local okRestore, restored = pcall(function()
			return look.enable(priorId, { studio = true })
		end)
		if not okRestore or restored == false then
			seasonFail("restore-prior:" .. priorId .. ":" .. tostring(restored))
		end
	end

	emit(
		"SEASON_SAFE",
		#errors == 0 and variantCount > 0 and safeCount == variantCount,
		safeCount,
		variantCount,
		{ readings = readings, failures = safeFails, errors = errors, restoredPrior = priorId }
	)
	emit(
		"SEASON_RESTORE",
		#errors == 0 and variantCount > 0 and restoredCount == variantCount,
		restoredCount,
		variantCount,
		{
			baselineDescendants = baseDesc,
			tintedBaseline = #baseDecor,
			failures = restoreFails,
			errors = errors,
			restoredPrior = priorId,
		}
	)
	emit(
		"SEASON_DISTINCT",
		#errors == 0 and minDiff >= seasonMap.DISTINCT_TARGET,
		minDiff,
		seasonMap.DISTINCT_TARGET,
		{
			pairs = pairCounts,
			pct = seasonMap.DISTINCT_PCT,
			valuesPerPreset = #numbersFor(seasonMap.order[1]),
			errors = errors,
			restoredPrior = priorId,
		}
	)
end
runSeasonChecks()
end

-- 9u. WORK_QUEUE section N item 120: rain_r8, a client rain ring of at most three textureless
-- ParticleEmitters plus a bounded morning-mist Atmosphere bump, gated on the live Cuaca weather.
-- THREE MUTATING CLIENT checks, appended last in ORDER. RAIN_EMITTERS counts live emitter Parts
-- while cuaca=hujan and validates Rate/Lifetime/Speed (the two ranges must be NumberRange).
-- RAIN_OFF_CERAH proves both gate directions with pump(dt) called between them, so a pump cannot
-- silently re-enable rain. RAIN_COST times the SAME applier.pump(dt) the Heartbeat calls. The prior
-- candidate is re-enabled, the check override cleared and the rain folder destroyed on EVERY path.
-- Own do...end + inner function: the harness is near the 200-local cap. No existing check is touched.
do
local function rainFailAll(reason)
	emit("RAIN_EMITTERS", false, 0, 3, { reason = reason })
	emit("RAIN_OFF_CERAH", false, 0, 0, { reason = reason })
	emit("RAIN_COST", false, "ERR", "<0.5ms", { reason = reason })
end

local function runRainChecks()
	-- Own RunService gate: the shared isClient local is declared LATER in this harness.
	local okRun, run = pcall(function()
		return game:GetService("RunService")
	end)
	local rainIsClient = okRun and run and run:IsClient() or false
	if not rainIsClient then
		rainFailAll("client VM required")
		return
	end
	-- Client container exactly as LookDevReview.resolveContainer("client", game), with the
	-- harness-friendly game.PlayerScripts.Client fallback used by the other client blocks.
	local function rainApplier()
		local okLocal, localModule = pcall(function()
			return require(game.Players.LocalPlayer.PlayerScripts.Client.World.LookDevRainR8)
		end)
		if okLocal and type(localModule) == "table" then
			return localModule
		end
		local okDirect, directModule = pcall(function()
			return require(game.PlayerScripts.Client.World.LookDevRainR8)
		end)
		return if okDirect then directModule else nil
	end
	local look, rainMap, api = nil, nil, nil
	local priorId = nil
	local function cleanup()
		-- Disable first: restore clears the override and destroys every emitter Part. Then clear
		-- again through the public helper so no check override can leak into the next candidate.
		if look then
			pcall(function()
				look.disable()
			end)
		end
		if api then
			pcall(function()
				api.clearCuacaForCheck()
			end)
		end
		if look and priorId then
			pcall(function()
				look.enable(priorId, { studio = true })
			end)
		end
	end
	local function failAll(reason)
		cleanup()
		rainFailAll(reason)
	end

	local okMods, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			map = require(game.ReplicatedStorage.Shared.ModelMapRainR8),
			-- Registration happens at module load; a saved place's boot script may predate this one.
			applier = rainApplier(),
		}
	end)
	if
		not okMods
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.disable) ~= "function"
		or type(mods.look.current) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.EMITTERS) ~= "table"
		or type(mods.map.weatherIsRain) ~= "function"
		or type(mods.map.MAX_EMITTERS) ~= "number"
		or type(mods.map.MAX_RATE) ~= "number"
		or type(mods.map.DT) ~= "number"
		or type(mods.map.SIM_SECONDS) ~= "number"
		or type(mods.map.MAX_STEP_MS) ~= "number"
		or type(mods.applier) ~= "table"
		or type(mods.applier.emitterCount) ~= "function"
		or type(mods.applier.isApplied) ~= "function"
		or type(mods.applier.currentWeather) ~= "function"
		or type(mods.applier.pump) ~= "function"
		or type(mods.applier.lastCostMs) ~= "function"
		or type(mods.applier.setCuacaForCheck) ~= "function"
		or type(mods.applier.clearCuacaForCheck) ~= "function"
	then
		failAll("modules unreadable: " .. tostring(mods))
		return
	end
	look, rainMap, api = mods.look, mods.map, mods.applier
	local okPrior, current = pcall(function()
		return look.current()
	end)
	if okPrior and type(current) == "string" then
		priorId = current
	end

	local liveEmitters = {}
	local function readLiveEmitters()
		local found = {}
		local okFolder, foundFolder = pcall(function()
			return workspace:FindFirstChild(rainMap.FOLDER)
		end)
		if not okFolder or not foundFolder then
			return found
		end
		local okList, list = pcall(function()
			return foundFolder:GetDescendants()
		end)
		if not okList or type(list) ~= "table" then
			return found
		end
		for _, instance in ipairs(list) do
			local okKind, pe = pcall(function()
				return if instance:IsA("ParticleEmitter") then instance else nil
			end)
			if okKind and pe then
				local okParent, part = pcall(function()
					return pe.Parent
				end)
				if okParent and part then
					local okPart, isPart = pcall(function()
						return part:IsA("BasePart")
					end)
					if okPart and isPart then
						found[#found + 1] = { part = part, emitter = pe }
					end
				end
			end
		end
		return found
	end
	local function emitterValid(entry)
		local okRate, rate = pcall(function()
			return entry.emitter.Rate
		end)
		local okLife, life = pcall(function()
			return entry.emitter.Lifetime
		end)
		local okSpeed, speed = pcall(function()
			return entry.emitter.Speed
		end)
		return okRate
			and okLife
			and okSpeed
			and type(rate) == "number"
			and rate >= 0
			and rate <= rainMap.MAX_RATE
			and typeof(life) == "NumberRange"
			and typeof(speed) == "NumberRange"
	end
	local errors = {}
	local function runPumps(count)
		for _ = 1, count do
			local okPump, pumpErr = pcall(function()
				api.pump(rainMap.DT)
			end)
			if not okPump then
				errors[#errors + 1] = "pump:" .. tostring(pumpErr)
				return
			end
		end
	end

	local okEnable, enabled, enableErr = pcall(function()
		return look.enable(rainMap.id, { studio = true })
	end)
	if not okEnable or enabled == false then
		errors[#errors + 1] = "enable:" .. tostring(enableErr or enabled)
	end

	local okHujan, setHujanErr = pcall(function()
		return api.setCuacaForCheck(rainMap.WEATHER_RAIN)
	end)
	if not okHujan or setHujanErr == false then
		errors[#errors + 1] = "set hujan:" .. tostring(setHujanErr)
	end
	runPumps(2)
	liveEmitters = readLiveEmitters()
	local okDiagnostic, diagnosticCount = pcall(function()
		return api.emitterCount()
	end)
	local okApplied, appliedNow = pcall(function()
		return api.isApplied()
	end)
	local okWeather, weatherNow = pcall(function()
		return api.currentWeather()
	end)
	local invalidEmitters = 0
	for _, entry in ipairs(liveEmitters) do
		if not emitterValid(entry) then
			invalidEmitters += 1
		end
	end
	local emitterPass = #errors == 0
		and okDiagnostic
		and okApplied
		and okWeather
		and appliedNow == true
		and weatherNow == rainMap.WEATHER_RAIN
		and #liveEmitters >= 1
		and #liveEmitters <= rainMap.MAX_EMITTERS
		and #liveEmitters == diagnosticCount
		and invalidEmitters == 0

	local okCerah, setCerahErr = pcall(function()
		return api.setCuacaForCheck(rainMap.WEATHER_CLEAR)
	end)
	if not okCerah or setCerahErr == false then
		errors[#errors + 1] = "set cerah:" .. tostring(setCerahErr)
	end
	runPumps(3)
	local offCount, onCount = 0, 0
	for _, entry in ipairs(readLiveEmitters()) do
		local okOff, isOff = pcall(function()
			return entry.emitter.Enabled == false
		end)
		if okOff and isOff then
			offCount += 1
		end
	end
	local okClearWeather, clearWeather = pcall(function()
		return api.currentWeather()
	end)
	local okHujanAgain, setAgainErr = pcall(function()
		return api.setCuacaForCheck(rainMap.WEATHER_RAIN)
	end)
	if not okHujanAgain or setAgainErr == false then
		errors[#errors + 1] = "set hujan again:" .. tostring(setAgainErr)
	end
	runPumps(3)
	for _, entry in ipairs(readLiveEmitters()) do
		local okOn, isOn = pcall(function()
			return entry.emitter.Enabled == true
		end)
		if okOn and isOn then
			onCount += 1
		end
	end
	local gatePass = #errors == 0
		and okClearWeather
		and clearWeather == rainMap.WEATHER_CLEAR
		and #liveEmitters > 0
		and offCount == #liveEmitters
		and onCount == #liveEmitters

	local steps = math.max(1, math.ceil(rainMap.SIM_SECONDS / rainMap.DT))
	local started = os.clock()
	local okSim, simErr = pcall(function()
		for _ = 1, steps do
			api.pump(rainMap.DT)
		end
	end)
	local totalElapsed = os.clock() - started
	local ms = okSim and (totalElapsed * 1000 / steps) or math.huge
	local costPass = #errors == 0
		and okSim
		and ms >= 0
		and ms < rainMap.MAX_STEP_MS
		and rainMap.MAX_STEP_MS == 0.5
	local measuredMs = if okSim then math.floor(ms * 10000) / 10000 else "ERR"

	cleanup()
	emit("RAIN_EMITTERS", emitterPass, #liveEmitters, rainMap.MAX_EMITTERS, {
		reason = if emitterPass then nil else "emitter count / rate / NumberRange / diagnostic mismatch",
		diagnosticCount = diagnosticCount,
		invalidEmitters = invalidEmitters,
		rateMax = rainMap.MAX_RATE,
		errors = errors,
		restoredPrior = priorId,
	})
	emit("RAIN_OFF_CERAH", gatePass, offCount, #liveEmitters, {
		reason = if gatePass then nil else "a pump re-enabled rain or a gate direction failed",
		cerahDisabled = offCount,
		hujanEnabled = onCount,
		liveEmitters = #liveEmitters,
		clearWeather = clearWeather,
		errors = errors,
		restoredPrior = priorId,
	})
	emit("RAIN_COST", costPass, measuredMs, "<0.5ms", {
		reason = if costPass then nil else "pump failed or ms per step >= limit: " .. tostring(simErr),
		totalMs = math.floor(totalElapsed * 1000 * 100) / 100,
		steps = steps,
		msPerStep = ms,
		limitMs = rainMap.MAX_STEP_MS,
		simSeconds = rainMap.SIM_SECONDS,
		dt = rainMap.DT,
		lastCostMsDiagnostic = if okDiagnostic then api.lastCostMs() else "ERR",
		errors = errors,
		restoredPrior = priorId,
	})
end
runRainChecks()
end

-- 9v. WORK_QUEUE section N item 121: subuh_r8 dawn look. TWO MUTATING CLIENT checks appended
-- LAST in ORDER. DAWN_PHASES_MONOTONIC proves three strict warm-up steps on top.R, its warmth
-- (R-B) and luminance, with a bounded per-step jump and a strictly positive base jump. DAWN_SAFE
-- reads the LIVE Lighting/effects/Clouds/lamp values at all four phase clocks through the
-- override-first direct-write diagnostics (no 30 s tween wait), checks every band and confirms
-- birds are inaudible before 06:00 (no Sound is staged). The prior candidate is re-enabled and
-- the clock override cleared on EVERY path. Own do...end + inner function: near the 200-local
-- cap. No existing check is touched.
do
local function dawnFailAll(reason)
	emit("DAWN_PHASES_MONOTONIC", false, 0, 3, { reason = reason })
	emit("DAWN_SAFE", false, 0, 4, { reason = reason })
end

local function runDawnChecks()
	-- Own RunService gate: the shared isClient local is declared LATER in this harness. Sky tweens
	-- the client atmosphere for 4 s on mount, so ONE bounded wait settles it before direct writes.
	local okRun, run = pcall(function()
		return game:GetService("RunService")
	end)
	local dawnIsClient = okRun and run and run:IsClient() or false
	if not dawnIsClient then
		dawnFailAll("client VM required")
		return
	end
	task.wait(5)

	local function dawnApplier()
		local okLocal, localModule = pcall(function()
			return require(game.Players.LocalPlayer.PlayerScripts.Client.World.LookDevSubuhR8)
		end)
		if okLocal and type(localModule) == "table" then
			return localModule
		end
		local okDirect, directModule = pcall(function()
			return require(game.PlayerScripts.Client.World.LookDevSubuhR8)
		end)
		return if okDirect then directModule else nil
	end

	local look, dawnMap, api = nil, nil, nil
	local priorId = nil
	local function cleanup()
		-- Clear the check override first, then restore LIFO through LookDev and re-enable the
		-- previous candidate. restore() also clears it, but no override may leak either way.
		if api then
			pcall(function()
				api.clearClockForCheck()
			end)
		end
		if look then
			pcall(function()
				look.disable()
			end)
		end
		if look and priorId then
			pcall(function()
				look.enable(priorId, { studio = true })
			end)
		end
	end
	local function failAll(reason)
		cleanup()
		dawnFailAll(reason)
	end

	local okMods, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			map = require(game.ReplicatedStorage.Shared.ModelMapSubuhR8),
			-- Registration happens at module load; a saved place's boot script may predate this one.
			applier = dawnApplier(),
		}
	end)
	if
		not okMods
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.disable) ~= "function"
		or type(mods.look.current) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.PHASES) ~= "table"
		or type(mods.map.safeRanges) ~= "table"
		or type(mods.map.monotonic) ~= "function"
		or type(mods.map.checkReadings) ~= "function"
		or type(mods.map.birdsAudible) ~= "function"
		or type(mods.applier) ~= "table"
		or type(mods.applier.setClockForCheck) ~= "function"
		or type(mods.applier.applyPhaseNowForCheck) ~= "function"
		or type(mods.applier.clearClockForCheck) ~= "function"
		or type(mods.applier.safeReadings) ~= "function"
		or type(mods.applier.isApplied) ~= "function"
		or type(mods.applier.phaseCount) ~= "function"
		or type(mods.applier.appliedPhase) ~= "function"
	then
		failAll("modules unreadable: " .. tostring(mods))
		return
	end
	look, dawnMap, api = mods.look, mods.map, mods.applier
	local okPrior, current = pcall(function()
		return look.current()
	end)
	if okPrior and type(current) == "string" then
		priorId = current
	end

	local mono = dawnMap.monotonic()
	local monoPass = type(mono) == "table"
		and mono.pass == true
		and mono.steps == 3
		and type(mono.baseJump) == "number"
		and mono.baseJump > 0
		and type(mono.maxJump) == "number"
		and type(mono.limit) == "number"
		and mono.maxJump <= mono.limit
		and type(mono.clocks) == "table"
		and #mono.clocks == 4

	local okEnable, enableResult = pcall(function()
		return look.enable("subuh_r8", { studio = true })
	end)
	if not okEnable or enableResult == false then
		failAll("enable failed: " .. tostring(enableResult))
		return
	end

	local errors, readings, safeFails = {}, {}, {}
	local safeCount, phaseCount = 0, #dawnMap.PHASES
	for index, phase in ipairs(dawnMap.PHASES) do
		local clock = phase.clock
		local okWrite, wrote = pcall(function()
			return api.setClockForCheck(clock) and api.applyPhaseNowForCheck(clock)
		end)
		if not okWrite or wrote ~= true then
			errors[#errors + 1] = "phase " .. index .. " direct write:" .. tostring(wrote)
		else
			local okRead, live = pcall(function()
				return api.safeReadings()
			end)
			if not okRead then
				errors[#errors + 1] = "phase " .. index .. " readings:" .. tostring(live)
			else
				local fails = dawnMap.checkReadings(live)
				if #fails == 0 then
					safeCount += 1
				else
					safeFails[#safeFails + 1] = { clock = clock, failures = fails }
				end
				readings[#readings + 1] = { clock = clock, values = live, failures = fails }
			end
		end
		pcall(function()
			api.clearClockForCheck()
		end)
	end

	-- No Sound is staged by this candidate: the bed is silent while subuh_r8 is active. The pure
	-- predicate records the 06:00 boundary; no asset id and no bird volume is written anywhere.
	local birdsBefore = dawnMap.birdsAudible(dawnMap.PHASES[#dawnMap.PHASES - 1].clock)
	local birdsAtSix = dawnMap.birdsAudible(dawnMap.PHASES[#dawnMap.PHASES].clock)
	local birdsPass = birdsBefore == false and birdsAtSix == true
	local safePass = #errors == 0 and phaseCount == 4 and safeCount == 4 and birdsPass

	cleanup()
	emit(
		"DAWN_PHASES_MONOTONIC",
		monoPass and #errors == 0,
		(if type(mono) == "table" then mono.steps else 0),
		3,
		{
			clocks = if type(mono) == "table" then mono.clocks else {},
			top = if type(mono) == "table" then mono.top else {},
			warmth = if type(mono) == "table" then mono.warmth else {},
			maxJump = if type(mono) == "table" then mono.maxJump else 0,
			limit = if type(mono) == "table" then mono.limit else 0,
			baseJump = if type(mono) == "table" then mono.baseJump else 0,
			factor = if type(mono) == "table" then mono.factor else 0,
			errors = errors,
			restoredPrior = priorId,
		}
	)
	emit("DAWN_SAFE", safePass, safeCount, 4, {
		readings = readings,
		bands = dawnMap.safeRanges,
		birdsAudibleBeforeSix = birdsBefore,
		birdsAudibleAtSix = birdsAtSix,
		birdVolume = 0,
		failures = safeFails,
		errors = errors,
		restoredPrior = priorId,
	})
end
runDawnChecks()
end

-- 10. VEG_NEAR: dense near layer at the saved camera (45 studs, 70-degree cone). A model only
-- counts when its bbox centre is inside the cone AND its bbox is >=2 studs tall; species and
-- undersize are checked as well as the instance count.
local NEAR_RADIUS = 45
local NEAR_MIN_HEIGHT = 2
local nearCount = 0
local nearSpeciesSeen = {}
local nearUndersized = {}
for _, model in ipairs(vegModels) do
	local centre = bboxCentre(model)
	local size = bboxSize(model)
	if centre and size and (centre - VEG_EYE).Magnitude <= NEAR_RADIUS and insideCone(centre, VEG_EYE, VEG_LOOK) then
		nearCount += 1
		local species = attr(model, "Species")
		if type(species) == "string" and species ~= "" then
			nearSpeciesSeen[species] = true
		end
		if size.Y < NEAR_MIN_HEIGHT then
			nearUndersized[#nearUndersized + 1] = { species = species, height = size.Y }
		end
	end
end
local nearSpeciesCount = 0
for _ in pairs(nearSpeciesSeen) do
	nearSpeciesCount += 1
end
emit(
	"VEG_NEAR",
	nearCount >= 25 and nearSpeciesCount >= 6 and #nearUndersized == 0,
	string.format("%d inst/%d sp/%d small", nearCount, nearSpeciesCount, #nearUndersized),
	">=25 inst/>=6 sp/0 small",
	{ radius = NEAR_RADIUS, minHeight = NEAR_MIN_HEIGHT, folderPresent = vegFolder ~= nil, undersized = nearUndersized }
)
end

-- 11. PROP_SIZE: the three round-8 replacement models at real size. gerobak and pagar are
-- measured by their longest horizontal axis (max of bbox X/Z); cangkul by its bbox height.
-- A missing model yields -1 and fails its band.
local gLen, cHeight, pLen = -1, -1, -1
local gSize = bboxSize(propsBySlot["gerobak"])
if gSize then
	gLen = math.max(gSize.X, gSize.Z)
end
local cSize = bboxSize(propsBySlot["alat_tani"])
if cSize then
	cHeight = cSize.Y
end
local pSize = bboxSize(propsBySlot["pagar_bambu"])
if pSize then
	pLen = math.max(pSize.X, pSize.Z)
end
local sizePass = gLen >= 4 and gLen <= 6 and cHeight >= 3.5 and cHeight <= 4.5 and pLen >= 8
emit(
	"PROP_SIZE",
	sizePass,
	string.format("g=%.2f c=%.2f p=%.2f", gLen, cHeight, pLen),
	"g[4-6] c[3.5-4.5] p[>=8]",
	{ gerobak = gLen, alat_tani = cHeight, pagar_bambu = pLen, folderPresent = propFolder ~= nil }
)

-- 12. CLOUD_COVER: client only. The client Sky LocalScript owns Terrain.Clouds.Cover and the
-- Server datamodel cannot observe that tween, so this check is emitted only when IsClient().
local RunService = service("RunService")
local isClient = false
if RunService then
	local okClient, flag = pcall(function()
		return RunService:IsClient()
	end)
	if okClient then
		isClient = flag
	end
end
if isClient then
	local cover, clockTime = -1, -1
	local okTerrain, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	local cloud = nil
	if okTerrain and terrain then
		local okCloud, found = pcall(function()
			return terrain:FindFirstChildOfClass("Clouds")
		end)
		if okCloud then
			cloud = found
		end
	end
	if cloud then
		local okCover, value = pcall(function()
			return cloud.Cover
		end)
		if okCover and type(value) == "number" then
			cover = value
		end
	end
	if Lighting then
		local okClock, value = pcall(function()
			return Lighting.ClockTime
		end)
		if okClock and type(value) == "number" then
			clockTime = value
		end
	end
	emit(
		"CLOUD_COVER",
		cover >= 0.4 and cover <= 0.6,
		string.format("%.3f@ct%.2f", cover, clockTime),
		"0.4-0.6",
		{ cover = cover, clockTime = clockTime, cloudPresent = cloud ~= nil }
	)
end

-- 12a-pre. WATER_DEFAULT (WORK_QUEUE item 137): CLIENT only and READ-ONLY. In a fresh Play with
-- no candidate enabled, the boot-applied water_r8_a default must be on Terrain. No enable call
-- is made here; the later WATER_SAFE/WATER_RESTORE block owns all mutation.
if isClient then
	local function defaultFail(reason)
		emit("WATER_DEFAULT", false, 0, 5, { reason = reason })
	end

	local okDefaultMap, defaultMap = pcall(function()
		return require(game.ReplicatedStorage.Shared.ModelMapWaterR8)
	end)
	if
		not okDefaultMap
		or type(defaultMap) ~= "table"
		or type(defaultMap.valuesFor) ~= "function"
		or type(defaultMap.properties) ~= "table"
	then
		defaultFail("water map not readable")
	else
		local okValues, expected = pcall(function()
			return defaultMap.valuesFor("a")
		end)
		if not okValues or type(expected) ~= "table" or type(expected.WaterColor) ~= "table" then
			defaultFail("variant a values not readable")
		else
			local okTerrain, terrain = pcall(function()
				return workspace:FindFirstChildOfClass("Terrain")
			end)
			if not okTerrain or not terrain then
				defaultFail("Terrain missing")
			else
				local function channel255(component: number): number
					return math.floor(component * 255 + 0.5)
				end

				local matched, readings, mismatches = 0, {}, {}
				for _, property in ipairs(defaultMap.properties) do
					local okRead, value = pcall(function()
						return terrain[property]
					end)
					if not okRead then
						mismatches[#mismatches + 1] = property .. ":read:" .. tostring(value)
					else
						local equal = false
						local target = expected[property]
						if property == "WaterColor" then
							if typeof(value) == "Color3" and type(target) == "table" then
								equal = channel255(value.R) == target.r
									and channel255(value.G) == target.g
									and channel255(value.B) == target.b
								readings[#readings + 1] = property
									.. "=("
									.. channel255(value.R)
									.. ","
									.. channel255(value.G)
									.. ","
									.. channel255(value.B)
									.. ")"
							else
								readings[#readings + 1] = property .. ":type=" .. typeof(value)
							end
						else
							if type(value) == "number" and type(target) == "number" then
								equal = math.abs(value - target) <= 0.01
							end
							readings[#readings + 1] = property .. "=" .. tostring(value)
						end
						if equal then
							matched += 1
						else
							mismatches[#mismatches + 1] = property .. "=" .. tostring(value)
						end
					end
				end
				emit(
					"WATER_DEFAULT",
					matched == 5,
					matched,
					5,
					{ variant = "water_r8_a", readings = readings, mismatches = mismatches, noEnable = true }
				)
			end
		end
	end
end

-- 12a. WATER_SAFE / WATER_RESTORE (WORK_QUEUE item 76): CLIENT only. One mutating cycle over
-- water_r8_a/b/c reads all five Terrain water properties before and after each enable/disable.
-- WATER_SAFE checks every reading against ModelMapWaterR8.safeRanges; WATER_RESTORE checks exact
-- equality with the baseline captured before any enable. Both emit even on error. The prior
-- candidate is re-enabled at the end, so a staged toggle is left intact.
if isClient then
	local function waterFail(reason)
		emit("WATER_SAFE", false, 0, 3, { reason = reason })
		emit("WATER_RESTORE", false, 0, 3, { reason = reason })
	end

	local okWater, water = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
			map = require(game.ReplicatedStorage.Shared.ModelMapWaterR8),
		}
	end)
	if not okWater or type(water) ~= "table" then
		waterFail("water modules not readable")
	else
		local look, review, map = water.look, water.review, water.map
		if
			type(look) ~= "table"
			or type(look.enable) ~= "function"
			or type(look.disable) ~= "function"
			or type(look.current) ~= "function"
			or type(review) ~= "table"
			or type(review.enable) ~= "function"
			or type(map) ~= "table"
			or type(map.properties) ~= "table"
			or type(map.safeRanges) ~= "table"
			or type(map.variants) ~= "table"
			or type(map.order) ~= "table"
		then
			waterFail("water map or LookDev API incomplete")
		else
			local okTerrain, terrain = pcall(function()
				return workspace:FindFirstChildOfClass("Terrain")
			end)
			if not okTerrain or not terrain then
				waterFail("Terrain missing")
			else
				local function readWater()
					local snapshot = {}
					for _, property in ipairs(map.properties) do
						local ok, value = pcall(function()
							return terrain[property]
						end)
						if not ok then
							return nil, property .. ":" .. tostring(value)
						end
						snapshot[property] = value
					end
					return snapshot
				end

				local function describe(property, value)
					if property == "WaterColor" and typeof(value) == "Color3" then
						return string.format("(%0.3f,%0.3f,%0.3f)", value.R * 255, value.G * 255, value.B * 255)
					end
					return tostring(value)
				end

				local function inRange(property, value)
					local range = map.safeRanges[property]
					if type(range) ~= "table" then
						return false, "no range"
					end
					if property == "WaterColor" then
						if typeof(value) ~= "Color3" then
							return false, "type=" .. typeof(value)
						end
						for _, channel in ipairs({ "R", "G", "B" }) do
							local channelRange = range[channel]
							local scaled = value[channel] * 255
							if
								type(channelRange) ~= "table"
								or type(scaled) ~= "number"
								or scaled < channelRange.min
								or scaled > channelRange.max
							then
								return false, channel .. "=" .. tostring(scaled)
							end
						end
						return true
					end
					if type(value) ~= "number" or value < range.min or value > range.max then
						return false, tostring(value)
					end
					return true
				end

				local function exactlyEqual(property, before, after)
					if property == "WaterColor" then
						if typeof(before) ~= "Color3" or typeof(after) ~= "Color3" then
							return false
						end
						return before.R == after.R and before.G == after.G and before.B == after.B
					end
					return before == after
				end

				local baseline, baselineErr = readWater()
				if not baseline then
					waterFail("baseline read failed:" .. tostring(baselineErr))
				else
					local priorId = nil
					local okCurrent, current = pcall(function()
						return look.current()
					end)
					if okCurrent and type(current) == "string" then
						priorId = current
					end

					local safeCount, restoredCount = 0, 0
					local safeFails, restoreFails, readings, cycleErrors = {}, {}, {}, {}
					local variantCount = 0
					for _, key in ipairs(map.order) do
						variantCount += 1
						local variant = map.variants[key]
						local id = variant and variant.id or (map.idPrefix .. key)
						local okEnable, enabled, enableErr = pcall(function()
							return review.enable(id, game)
						end)
						if not okEnable or enabled == false then
							cycleErrors[#cycleErrors + 1] = id .. ":enable:" .. tostring(enableErr or enabled)
						else
							local applied, appliedErr = readWater()
							if not applied then
								cycleErrors[#cycleErrors + 1] = id .. ":read:" .. tostring(appliedErr)
							else
								local safe = true
								for _, property in ipairs(map.properties) do
									local inBand, why = inRange(property, applied[property])
									readings[#readings + 1] = id
										.. "."
										.. property
										.. "="
										.. describe(property, applied[property])
									if not inBand then
										safe = false
										safeFails[#safeFails + 1] = id .. "." .. property .. ":" .. tostring(why)
									end
								end
								if safe then
									safeCount += 1
								end
							end
						end

						local okDisable, disabled = pcall(function()
							return look.disable()
						end)
						if not okDisable then
							cycleErrors[#cycleErrors + 1] = id .. ":disable:" .. tostring(disabled)
						end

						local after, afterErr = readWater()
						if not after then
							cycleErrors[#cycleErrors + 1] = id .. ":read-after:" .. tostring(afterErr)
						else
							local exact = okDisable
							for _, property in ipairs(map.properties) do
								if not exactlyEqual(property, baseline[property], after[property]) then
									exact = false
									restoreFails[#restoreFails + 1] = id
										.. "."
										.. property
										.. ":"
										.. describe(property, baseline[property])
										.. "->"
										.. describe(property, after[property])
								end
							end
							if exact then
								restoredCount += 1
							end
						end
					end

					if priorId then
						local okRestore, restored = pcall(function()
							return look.enable(priorId)
						end)
						if not okRestore or restored == false then
							cycleErrors[#cycleErrors + 1] = "restore:" .. priorId .. ":" .. tostring(restored)
						end
					end

					local baselineDetail = {}
					for _, property in ipairs(map.properties) do
						baselineDetail[#baselineDetail + 1] = property .. "=" .. describe(property, baseline[property])
					end
					emit(
						"WATER_SAFE",
						#cycleErrors == 0 and variantCount > 0 and safeCount == variantCount,
						safeCount,
						3,
						{
							baseline = baselineDetail,
							readings = readings,
							failures = safeFails,
							errors = cycleErrors,
							restoredPrior = priorId,
						}
					)
					emit(
						"WATER_RESTORE",
						#cycleErrors == 0 and variantCount > 0 and restoredCount == variantCount,
						restoredCount,
						3,
						{
							baseline = baselineDetail,
							failures = restoreFails,
							errors = cycleErrors,
							restoredPrior = priorId,
						}
					)
				end
			end
		end
	end
end

do -- 12a-wind. WORK_QUEUE section M item 85 (CLIENT, MUTATING): one enable/read/disable cycle.
	-- WIND_SET measures the live workspace.GlobalWind; SWAY_TWEENS reads the applier diagnostic;
	-- WIND_RESTORE compares the captured baseline and every staged target's saved CFrame/pivot
	-- after disable. All three emit even on error; a prior active candidate is re-enabled at the end.
	local function windFail(reason)
		emit("WIND_SET", false, -1, "0 < M <= 12", { reason = reason })
		emit("SWAY_TWEENS", false, -1, 30, { reason = reason })
		emit("WIND_RESTORE", false, 1, 0, { reason = reason })
	end

	if isClient then
		local okModules, modules = pcall(function()
			return {
				look = require(game.ReplicatedStorage.Shared.LookDev),
				review = require(game.ReplicatedStorage.Shared.LookDevReview),
				map = require(game.ReplicatedStorage.Shared.ModelMapWindR8),
			}
		end)
		if not okModules or type(modules) ~= "table" then
			windFail("wind modules not readable")
		else
			local look, review, map = modules.look, modules.review, modules.map
			if
				type(look) ~= "table"
				or type(look.enable) ~= "function"
				or type(look.disable) ~= "function"
				or type(look.current) ~= "function"
				or type(review) ~= "table"
				or type(review.enable) ~= "function"
				or type(review.pathsFor) ~= "function"
				or type(review.resolveContainer) ~= "function"
				or type(map) ~= "table"
				or type(map.MAX_WIND) ~= "number"
				or type(map.MAX_TWEENS) ~= "number"
			then
				windFail("wind map or LookDev API incomplete")
			else
				local okWorkspace, workspaceService = pcall(function()
					return game:GetService("Workspace")
				end)
				if not okWorkspace or not workspaceService then
					windFail("Workspace missing")
				else
					local okBaseline, baseline = pcall(function()
						return workspaceService.GlobalWind
					end)
					if not okBaseline or typeof(baseline) ~= "Vector3" then
						windFail("GlobalWind baseline read failed")
					else
						local priorId = nil
						local okCurrent, current = pcall(function()
							return look.current()
						end)
						if okCurrent and type(current) == "string" then
							priorId = current
						end

						local function frameOf(target)
							if typeof(target) ~= "Instance" then
								return nil
							end
							local okFrame, frame = pcall(function()
								if target:IsA("Model") then
									return target:GetPivot()
								elseif target:IsA("BasePart") then
									return target.CFrame
								end
								return nil
							end)
							return if okFrame then frame else nil
						end

						local function windMatches(a, b)
							if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
								return false
							end
							return math.abs(a.X - b.X) <= 1e-4
								and math.abs(a.Y - b.Y) <= 1e-4
								and math.abs(a.Z - b.Z) <= 1e-4
						end

						local function frameMatches(a, b)
							if typeof(a) ~= "CFrame" or typeof(b) ~= "CFrame" then
								return false
							end
							local okComponents, ac, bc = pcall(function()
								return { a:GetComponents() }, { b:GetComponents() }
							end)
							if not okComponents or #ac ~= 12 or #bc ~= 12 then
								return false
							end
							for index = 1, 12 do
								if math.abs(ac[index] - bc[index]) > 1e-4 then
									return false
								end
							end
							return true
						end

						local windAfter, tweenCount, tiltActive = nil, -1, false
						local savedTargets, errors = {}, {}
						local okCycle, cycleErr = pcall(function()
							local okEnable, enabled, why = review.enable("wind_r8", game)
							if not okEnable or enabled == false then
								error("enable:" .. tostring(why or enabled))
							end
							local okAfter, value = pcall(function()
								return workspaceService.GlobalWind
							end)
							if not okAfter then
								error("read-after-enable:" .. tostring(value))
							end
							windAfter = value

							local entry = review.pathsFor("wind_r8")
							if not entry then
								error("no review path for wind_r8")
							end
							local container = review.resolveContainer("client", game)
							if not container then
								error("no client container")
							end
							local node = container
							for _, segment in ipairs(entry.path) do
								node = node[segment]
								if not node then
									error("missing applier module " .. tostring(segment))
								end
							end
							local applier = require(node)
							if
								type(applier) ~= "table"
								or type(applier.tweenCount) ~= "function"
								or type(applier.stageTargets) ~= "function"
								or type(applier.baseCFrame) ~= "function"
								or type(applier.tiltActive) ~= "function"
							then
								error("applier diagnostics incomplete")
							end
							tweenCount = applier.tweenCount()
							tiltActive = applier.tiltActive()
							local stage = applier.stageTargets()
							for _, target in ipairs(stage) do
								local base = applier.baseCFrame(target)
								if typeof(base) ~= "CFrame" then
									error("missing saved base CFrame")
								end
								savedTargets[#savedTargets + 1] = { target = target, base = base }
							end
							if #savedTargets == 0 then
								error("no staged targets")
							end
						end)
						if not okCycle then
							errors[#errors + 1] = tostring(cycleErr)
						end

						local okDisable, disableErr = pcall(function()
							return look.disable()
						end)
						if not okDisable then
							errors[#errors + 1] = "disable:" .. tostring(disableErr)
						end
						local okAfter, afterWind = pcall(function()
							return workspaceService.GlobalWind
						end)
						if not okAfter then
							errors[#errors + 1] = "read-after-disable:" .. tostring(afterWind)
						end

						local magnitude = -1
						if typeof(windAfter) == "Vector3" then
							magnitude = math.sqrt(windAfter.X ^ 2 + windAfter.Y ^ 2 + windAfter.Z ^ 2)
						end
						local windPass = magnitude > 0 and magnitude <= map.MAX_WIND

						local mismatches = {}
						for _, entry in ipairs(savedTargets) do
							local current = frameOf(entry.target)
							if not frameMatches(entry.base, current) then
								mismatches[#mismatches + 1] = tostring(entry.target) .. ":CFrame"
							end
						end
						local windRestored = windMatches(baseline, afterWind)
						if not windRestored then
							mismatches[#mismatches + 1] = "GlobalWind"
						end

						if priorId then
							local okRestore, restored = pcall(function()
								return look.enable(priorId)
							end)
							if not okRestore or restored == false then
								errors[#errors + 1] = "restore:" .. priorId .. ":" .. tostring(restored)
							end
						end

						emit(
							"WIND_SET",
							okCycle and windPass,
							magnitude,
							"0 < M <= 12",
							{
								vector = typeof(windAfter) == "Vector3"
										and string.format(
											"(%.3f,%.3f,%.3f)",
											windAfter.X,
											windAfter.Y,
											windAfter.Z
										)
									or "nil",
								magnitude = magnitude,
								baseline = string.format("(%.3f,%.3f,%.3f)", baseline.X, baseline.Y, baseline.Z),
								errors = errors,
							}
						)
						emit(
							"SWAY_TWEENS",
							okCycle and tweenCount > 0 and tweenCount <= map.MAX_TWEENS,
							tweenCount,
							30,
							{
								count = tweenCount,
								maxTweens = map.MAX_TWEENS,
								targetCount = #savedTargets,
								tiltActive = tiltActive,
								errors = errors,
							}
						)
						emit(
							"WIND_RESTORE",
							#errors == 0 and #mismatches == 0 and okCycle and okDisable,
							#mismatches,
							0,
							{
								mismatches = mismatches,
								windBefore = string.format("(%.3f,%.3f,%.3f)", baseline.X, baseline.Y, baseline.Z),
								windAfter = typeof(afterWind) == "Vector3"
										and string.format(
											"(%.3f,%.3f,%.3f)",
											afterWind.X,
											afterWind.Y,
											afterWind.Z
										)
									or "nil",
								targetCount = #savedTargets,
								baseSource = "applier.savedCFrames",
								errors = errors,
								restoredPrior = priorId,
							}
						)
					end
				end
			end
		end
	end
end

-- 12b. CAMERA_CLEAR (WORK_QUEUE item 69): for every named review camera, raycast from position
-- toward look-at and require that no opaque part is hit within the first 6 studs. A camera that
-- starts inside a wall, tree or terrain voxel is a FAIL. Uses ReviewCameras.clearDistance (6).
-- SERVER ONLY: ReviewCameras requires MapSpec from ServerScriptService.Server.World, so requiring
-- it in the Client VM would block on WaitForChild. The datamodel field on each camera is for the
-- shooter; this geometry check runs wherever the registry can load (Server / Lune Env).
local isServer = false
if RunService then
	local okServer, flag = pcall(function()
		return RunService:IsServer()
	end)
	if okServer then
		isServer = flag
	end
end
local okCameras, Cameras = false, nil
if isServer then
	okCameras, Cameras = pcall(function()
		return require(game.ReplicatedStorage.Shared.ReviewCameras)
	end)
	local clearFails = {}
	local clearChecked = 0
	if not okCameras or type(Cameras) ~= "table" or type(Cameras.all) ~= "function" then
		emit("CAMERA_CLEAR", false, "ERR", "0 blocked", { reason = "ReviewCameras not readable" })
	else
		local clearDistance = tonumber(Cameras.clearDistance) or 6
		for _, camera in ipairs(Cameras.all()) do
			clearChecked += 1
			local eye = asVector3(camera.position)
			local look = asVector3(camera.lookAt)
			local blocked, reason = false, ""
			if not eye or not look or (look - eye).Magnitude <= 0 then
				blocked, reason = true, "bad coords"
			else
				local okParams, params = pcall(function()
					local p = RaycastParams.new()
					p.FilterType = Enum.RaycastFilterType.Exclude
					local filter = {}
					local Players = service("Players")
					if Players then
						for _, player in ipairs(Players:GetPlayers()) do
							if player.Character then
								filter[#filter + 1] = player.Character
							end
						end
					end
					p.FilterDescendantsInstances = filter
					return p
				end)
				local okRay, hit = false, nil
				if okParams then
					local rayDir = (look - eye).Unit * clearDistance
					local rayOk, result = pcall(function()
						return workspace:Raycast(eye, rayDir, params)
					end)
					okRay, hit = rayOk, result
				end
				if not okParams or not okRay then
					blocked, reason = true, "ray error"
				elseif hit and hit.Instance then
					local inst = hit.Instance
					local opaque = true
					local okOpacity, value = pcall(function()
						if inst:IsA("BasePart") then
							return inst.Transparency < 0.5
						end
						return true
					end)
					if okOpacity then
						opaque = value
					end
					if opaque then
						blocked, reason = true, inst.Name .. "@" .. string.format("%.2f", hit.Distance)
					end
				end
			end
			if blocked then
				clearFails[#clearFails + 1] = tostring(camera.name) .. ":" .. reason
			end
		end
		emit(
			"CAMERA_CLEAR",
			#clearFails == 0,
			#clearFails .. " blocked/" .. clearChecked .. " checked",
			"0 blocked",
			{ failed = clearFails, checked = clearChecked }
		)
	end
end

-- 12c. ADDITIVE_STAGE (WORK_QUEUE item 136): SERVER-only, mutating. Clean base via disableAll(),
-- stage the three accepted round-9 r8 candidates additively, count how many staged folders hold
-- their tagged parts, then disableAll() again. measured = number of candidates present (0..3),
-- target = 3. LOOKDEV_LEAK runs after this and proves zero leaked folders.
local STAGE_FOLDERS = {
	{
		id = "hubveg_r8",
		folder = "LookDevModelsVegetationHubR8_hubveg_r8",
		attribute = "LookDevHubVegR8",
		value = "hubveg_r8",
	},
	{
		id = "plots_r8",
		folder = "LookDevPlotsR8_plots_r8",
		attribute = "LookDevPlotsR8",
		value = "plots_r8",
	},
	{
		id = "facades_r8",
		folder = "LookDevFacadesR8_facades_r8",
		attribute = "FacadePart",
		value = true,
	},
}
local stagePresent, stageLeaked = 0, 0
local stageParts, stageErrors, stageDetail = {}, {}, {}
if not isServer then
	stageErrors[#stageErrors + 1] = "server VM required"
else
	local okReview, Review = pcall(function()
		return require(game.ReplicatedStorage.Shared.LookDevReview)
	end)
	if
		not okReview
		or type(Review) ~= "table"
		or type(Review.enableAdditive) ~= "function"
		or type(Review.disableAll) ~= "function"
	then
		stageErrors[#stageErrors + 1] = "LookDevReview additive API missing"
	else
		local function stagedCount(entry)
			local folder = folderNamed(entry.folder)
			if not folder then
				return 0
			end
			local ok, descendants = pcall(function()
				return folder:GetDescendants()
			end)
			if not ok or type(descendants) ~= "table" then
				return 0
			end
			local count = 0
			for _, item in ipairs(descendants) do
				if attr(item, entry.attribute) == entry.value then
					count += 1
				end
			end
			return count
		end

		local function clearAll()
			local okClear, result = pcall(function()
				return Review.disableAll()
			end)
			if not okClear then
				stageErrors[#stageErrors + 1] = "disableAll:" .. tostring(result)
			end
		end

		clearAll() -- clean base: no prior single or additive candidate
		for _, entry in ipairs(STAGE_FOLDERS) do
			local okStage, result, why = pcall(function()
				return Review.enableAdditive(entry.id, game, { studio = true })
			end)
			if not okStage or result == false then
				stageErrors[#stageErrors + 1] = entry.id .. ":stage:" .. tostring(why or result)
			end
		end
		for _, entry in ipairs(STAGE_FOLDERS) do
			local count = stagedCount(entry)
			stageParts[entry.id] = count
			stageDetail[#stageDetail + 1] = entry.id .. ":" .. count
			if count > 0 then
				stagePresent += 1
			end
		end
		clearAll()
		for _, entry in ipairs(STAGE_FOLDERS) do
			if stagedCount(entry) > 0 then
				stageLeaked += 1
			end
		end
	end
end

emit(
	"ADDITIVE_STAGE",
	stagePresent == #STAGE_FOLDERS and stageLeaked == 0 and #stageErrors == 0,
	stagePresent,
	#STAGE_FOLDERS,
	{ parts = stageParts, measured = table.concat(stageDetail, " "), leaked = stageLeaked, errors = stageErrors }
)

-- 12d. WORK_QUEUE item 87, npcs_idle_r8: SERVER-VM, MUTATING. Its own do...end scope (the harness
-- already hit Luau's 200-local-register limit). One guarded enable/read/pump/disable cycle stages
-- ten R15 villagers with a REAL catalog Standing Idle track (71483261700852) plus a shared <=1deg
-- sine sway. IDLE_TRACKS requires all ten playing Animator tracks; IDLE_SWAY requires the single
-- loop and at least one rig tilted away from its saved pivot, then verifies exact pivot restore;
-- IDLE_COST runs the same pure 3600-step function the loop calls and measures os.clock ms/step.
-- All three always emit, never skip; the prior active candidate is re-enabled at the end.
do
local function idleFail(reason)
	emit("IDLE_TRACKS", false, 0, 10, { reason = reason })
	emit("IDLE_SWAY", false, 0, 10, { reason = reason })
	emit("IDLE_COST", false, "ERR", "<0.3ms", { reason = reason })
end

if not isServer then
	idleFail("server VM required")
else
	local okModules, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
			map = require(game.ReplicatedStorage.Shared.ModelMapNpcsIdleR8),
			applier = require(game.ServerScriptService.Server.World.LookDevNpcsIdleR8),
		}
	end)
	if
		not okModules
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.current) ~= "function"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.disable) ~= "function"
		or type(mods.review) ~= "table"
		or type(mods.review.enable) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.step) ~= "function"
		or type(mods.map.simulate) ~= "function"
		or type(mods.map.entries) ~= "function"
		or type(mods.applier) ~= "table"
		or type(mods.applier.tracks) ~= "function"
		or type(mods.applier.stageTargets) ~= "function"
		or type(mods.applier.basePivot) ~= "function"
		or type(mods.applier.swayActive) ~= "function"
		or type(mods.applier.connectionCount) ~= "function"
		or type(mods.applier.restoreAudit) ~= "function"
		or type(mods.applier.pump) ~= "function"
	then
		idleFail("idle modules or applier diagnostics missing")
	else
		local look, review, map, applier = mods.look, mods.review, mods.map, mods.applier
		local priorId = nil
		local okCurrent, current = pcall(function()
			return look.current()
		end)
		if okCurrent and type(current) == "string" then
			priorId = current
		end

		-- Keep the staged work in its own function: the harness is one very long chunk and Luau
		-- caps a single function at 200 registers.
		local function runIdleStaged()
		local okEnable, enabled, enableWhy = pcall(function()
			return review.enable("npcs_idle_r8", game, { studio = true })
		end)
		if not okEnable or enabled == false then
			idleFail("enable:" .. tostring(enableWhy or enabled))
		else
			local idleErrors, rigs, playing, withAnimator = {}, {}, 0, 0
			local okTargets, staged = pcall(function()
				return applier.stageTargets()
			end)
			if okTargets and type(staged) == "table" then
				rigs = staged
			else
				idleErrors[#idleErrors + 1] = "stageTargets unreadable"
			end
			local okTracks, liveTracks = pcall(function()
				return applier.tracks()
			end)
			if okTracks and type(liveTracks) == "table" then
				for _, track in ipairs(liveTracks) do
					local okPlaying, isPlaying = pcall(function()
						return track.IsPlaying
					end)
					if okPlaying and isPlaying == true then
						playing += 1
					end
				end
			else
				idleErrors[#idleErrors + 1] = "tracks unreadable"
			end
			for _, rig in ipairs(rigs) do
				local okDesc, descendants = pcall(function()
					return rig:GetDescendants()
				end)
				if okDesc and type(descendants) == "table" then
					for _, descendant in ipairs(descendants) do
						local okAnimator, isAnimator = pcall(function()
							return descendant:IsA("Animator")
						end)
						if okAnimator and isAnimator then
							withAnimator += 1
							break
						end
					end
				end
			end
			emit(
				"IDLE_TRACKS",
				#rigs == 10 and withAnimator == 10 and playing == 10 and #idleErrors == 0,
				playing,
				10,
				{
					rigs = #rigs,
					animators = withAnimator,
					errors = idleErrors,
					animation = "real catalog animation " .. tostring(map.animationId) .. " " .. map.animationAsset,
				}
			)

			-- Drive the exact shared loop function a few times; the real Heartbeat connection is
			-- also checked. UpVector tilt is the observable sway (PivotTo keeps Position fixed).
			local okPump = pcall(function()
				for _ = 1, 3 do
					applier.pump(1 / 60)
				end
			end)
			local active, swayErrors = 0, {}
			if not okPump then
				swayErrors[#swayErrors + 1] = "pump failed"
			end
			local tiltBound = 1 - math.cos(math.rad(map.MAX_SWAY_DEG)) + 1e-6
			for _, rig in ipairs(rigs) do
				local base = applier.basePivot(rig)
				local okPivot, pivot = pcall(function()
					return rig:GetPivot()
				end)
				if base and okPivot and pivot then
					local tilt = math.abs(pivot.UpVector.Y - base.UpVector.Y)
					if tilt > 1e-6 and tilt <= tiltBound then
						active += 1
					end
				else
					swayErrors[#swayErrors + 1] = "pivot unreadable"
				end
			end
			local okSwayLoop, swayActiveFlag = pcall(function()
				return applier.swayActive()
			end)
			local okConn, connections = pcall(function()
				return applier.connectionCount()
			end)
			local okDisable, disabled = pcall(function()
				return look.disable()
			end)
			if not okDisable then
				swayErrors[#swayErrors + 1] = "disable:" .. tostring(disabled)
			end
			local okAudit, audit = pcall(function()
				return applier.restoreAudit()
			end)
			local restored = okDisable and okAudit and type(audit) == "table"
				and audit.count == 10
				and audit.mismatches == 0
				and audit.maxDelta <= 1e-4
			if not restored then
				swayErrors[#swayErrors + 1] = "base pivots not restored"
			end
			emit(
				"IDLE_SWAY",
				okPump and okSwayLoop and swayActiveFlag == true and okConn and connections == 1
					and active >= 1 and restored and #swayErrors == 0,
				active,
				10,
				{
					swayActive = swayActiveFlag,
					heartbeats = connections,
					maxSwayDeg = map.MAX_SWAY_DEG,
					tiltBound = tiltBound,
					restore = audit,
					errors = swayErrors,
				}
			)

			local simEntries = map.entries()
			local steps = map.STEPS
			local started = os.clock()
			map.simulate(simEntries, map.SIM_SECONDS, map.DT)
			local elapsed = os.clock() - started
			local msPerStep = elapsed * 1000 / steps
			emit(
				"IDLE_COST",
				msPerStep >= 0 and msPerStep < map.MAX_STEP_MS,
				math.floor(msPerStep * 10000) / 10000,
				"<" .. tostring(map.MAX_STEP_MS) .. "ms",
				{
					totalMs = math.floor(elapsed * 1000 * 100) / 100,
					steps = steps,
					villagers = #simEntries,
					msPerStep = msPerStep,
				}
			)
		end
		end
		runIdleStaged()

		if priorId then
			pcall(function()
				return look.enable(priorId)
			end)
		end
	end
end
end

-- 12e. WORK_QUEUE item 88, ambient_walkers_r8: SERVER-VM, MUTATING. Its own do...end scope (the
-- harness already hit Luau's 200-local-register limit). One guarded enable/read/disable cycle
-- stages up to 8 plain R15 strollers driven by the REAL NpcWalk.walkTo loop. WALKER_SPEED reads
-- each live rig's Humanoid.WalkSpeed; WALKER_MOVE lets the real loops run up to 6 s (polling until
-- one full waypoint leg completes, the shortest is ~3 s) then measures displacement from each saved
-- base pivot (proof the loop is actually wired);
-- WALKER_WAYPOINTS/STUCK/ROAD run the pure 90 s deterministic sim (NpcWalk yields via task.wait,
-- so real 90 s cannot be pumped synchronously). All five always emit, never skip, and the prior
-- active candidate is re-enabled at the end.
do
local function walkerFail(reason)
	emit("WALKER_SPEED", false, 0, 8, { reason = reason })
	emit("WALKER_MOVE", false, 0, ">=1", { reason = reason })
	emit("WALKER_WAYPOINTS", false, 0, 3, { reason = reason })
	emit("WALKER_STUCK", false, "ERR", 10, { reason = reason })
	emit("WALKER_ROAD", false, "ERR", 8, { reason = reason })
end

if not isServer then
	walkerFail("server VM required")
else
	local okModules, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			review = require(game.ReplicatedStorage.Shared.LookDevReview),
			map = require(game.ReplicatedStorage.Shared.ModelMapAmbientWalkersR8),
			applier = require(game.ServerScriptService.Server.World.LookDevAmbientWalkersR8),
		}
	end)
	if
		not okModules
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.current) ~= "function"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.disable) ~= "function"
		or type(mods.review) ~= "table"
		or type(mods.review.enable) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.routes) ~= "function"
		or type(mods.map.simulate) ~= "function"
		or type(mods.map.routes()) ~= "table"
		or type(mods.applier) ~= "table"
		or type(mods.applier.walkers) ~= "function"
		or type(mods.applier.walkSpeed) ~= "function"
		or type(mods.applier.basePivot) ~= "function"
		or type(mods.applier.loopCount) ~= "function"
	then
		walkerFail("walker modules or applier diagnostics missing")
	else
		local look, review, map, applier = mods.look, mods.review, mods.map, mods.applier
		local priorId = nil
		local okCurrent, current = pcall(function()
			return look.current()
		end)
		if okCurrent and type(current) == "string" then
			priorId = current
		end

		-- Keep the staged work in its own function: the harness is one very long chunk and Luau
		-- caps a single function at 200 registers.
		local function runWalkersStaged()
		local okEnable, enabled, enableWhy = pcall(function()
			return review.enable("ambient_walkers_r8", game, { studio = true })
		end)
		if not okEnable or enabled == false then
			walkerFail("enable:" .. tostring(enableWhy or enabled))
		else
			local rigs, speedErrors = {}, {}
			local okTargets, staged = pcall(function()
				return applier.walkers()
			end)
			if okTargets and type(staged) == "table" then
				rigs = staged
			else
				speedErrors[#speedErrors + 1] = "walkers unreadable"
			end
			local folderPresent = false
			pcall(function()
				folderPresent = game.Workspace:FindFirstChild(map.folder) ~= nil
			end)
			if not folderPresent then
				speedErrors[#speedErrors + 1] = "staging folder missing"
			end
			local maxSpeed = 0
			for _, rig in ipairs(rigs) do
				local okSpeed, speed = pcall(function()
					return applier.walkSpeed(rig)
				end)
				if not okSpeed or type(speed) ~= "number" then
					speedErrors[#speedErrors + 1] = "WalkSpeed unreadable"
				elseif speed > maxSpeed then
					maxSpeed = speed
				end
			end
			emit(
				"WALKER_SPEED",
				#rigs > 0 and #rigs <= map.MAX_WALKERS and folderPresent and maxSpeed <= 8 and #speedErrors == 0,
				maxSpeed,
				8,
				{ rigs = #rigs, folder = map.folder, errors = speedErrors }
			)

			-- The real NpcWalk loops run in task.spawn threads; a short REAL wait proves movement.
			local bases, moveErrors = {}, {}
			for _, rig in ipairs(rigs) do
				local okBase, base = pcall(function()
					return applier.basePivot(rig)
				end)
				if okBase and base then
					bases[rig] = base
				else
					moveErrors[#moveErrors + 1] = "base pivot unreadable"
				end
			end
			-- NpcWalk.walkTo yields task.wait(0.05) per step; the shortest waypoint leg is ~3 s real
			-- time, so poll up to 6 s until at least one full leg completes (loopCount > 0). Rigs
			-- move from the first step, so displacement is visible well before the first arrival.
			local okWait = pcall(function()
				for _ = 1, 120 do
					if applier.loopCount() > 0 then
						break
					end
					task.wait(0.05)
				end
			end)
			if not okWait then
				moveErrors[#moveErrors + 1] = "real wait failed"
			end
			local moved = 0
			for _, rig in ipairs(rigs) do
				local base = bases[rig]
				local okPivot, pivot = pcall(function()
					return rig:GetPivot()
				end)
				if base and okPivot and pivot then
					if (pivot.Position - base.Position).Magnitude > 0.05 then
						moved += 1
					end
				else
					moveErrors[#moveErrors + 1] = "pivot unreadable"
				end
			end
			local okLoops, loops = pcall(function()
				return applier.loopCount()
			end)
			emit(
				"WALKER_MOVE",
				okLoops and loops > 0 and moved >= 1 and #moveErrors == 0,
				moved,
				#rigs,
				{ loops = loops, rigs = #rigs, errors = moveErrors }
			)

			-- One pure 90 s sim drives the last three checks; no real-time wait is possible here.
			local okSim, sim = pcall(function()
				return map.simulate(map.SIM_SECONDS, map.routes())
			end)
			local simOk = okSim and type(sim) == "table" and type(sim.walkers) == "table"
				and #sim.walkers == map.MAX_WALKERS
			local detail = {}
			if simOk then
				for _, walkerResult in ipairs(sim.walkers) do
					detail[#detail + 1] = string.format(
						"%s=%d/%.3f/%.3f",
						tostring(walkerResult.name),
						walkerResult.waypointsReached,
						walkerResult.maxStuckSeconds,
						walkerResult.maxRoadDeviation
					)
				end
			else
				detail[#detail + 1] = "sim failed: " .. tostring(sim)
			end
			emit(
				"WALKER_WAYPOINTS",
				simOk and sim.minWaypointsReached >= 3,
				simOk and sim.minWaypointsReached or 0,
				3,
				{ walkers = detail, seconds = map.SIM_SECONDS }
			)
			emit(
				"WALKER_STUCK",
				simOk and sim.maxStuckSeconds <= map.MAX_STUCK_SECONDS,
				simOk and sim.maxStuckSeconds or "ERR",
				map.MAX_STUCK_SECONDS,
				{ walkers = detail }
			)
			emit(
				"WALKER_ROAD",
				simOk and sim.maxRoadDeviation <= map.MAX_ROAD_DEVIATION,
				simOk and sim.maxRoadDeviation or "ERR",
				map.MAX_ROAD_DEVIATION,
				{ walkers = detail }
			)
		end
		end
		runWalkersStaged()

		pcall(function()
			return look.disable()
		end)
		if priorId then
			pcall(function()
				return look.enable(priorId)
			end)
		end
	end
end
end

-- 12f. Item 89: three PURE day-cycle checks, no engine calls beyond the guarded require and no
-- staging. Shared.ModelMapDayCycleR8 owns the tuned phases and the documented numeric limits
-- (DAY_CYCLE.md): a normalized adjacent-channel jump <= 1.25x the original table's own maximum,
-- a 16:00 sun-vs-ambient luminance ratio >= 1.20x the original, and a field-for-field unchanged
-- Maghrib. These are VM-agnostic: they emit three FAIL lines when the module is missing, never skip.
do
local dayOk, Day = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapDayCycleR8)
end)
if not dayOk or type(Day) ~= "table" then
	local reason = "ModelMapDayCycleR8 not readable: " .. tostring(Day)
	emit("DAY_PHASES_MONOTONIC", false, "ERR", "<= documented limit", { reason = reason })
	emit("DAY_1600_CONTRAST", false, "ERR", ">= 1.20x base", { reason = reason })
	emit("DAY_MAGHRIB_UNCHANGED", false, 0, 1, { reason = reason })
else
	local function call(fn, ...)
		local ok, value = pcall(fn, ...)
		return ok, value
	end

	local okBaseJump, baseJump = call(Day.adjacentJumps, Day.BASE_PHASES)
	local okTunedJump, tunedJump = call(Day.adjacentJumps, Day.PHASES)
	local okLimit, limit = pcall(function()
		return Day.PHASE_JUMP_FACTOR * baseJump
	end)
	-- baseJump > 0 is a non-vacuity guard: if colours are unreadable (e.g. userdata mishandled)
	-- both base and tuned jump collapse to 0 and 0 <= limit would PASS with no evidence.
	local monotone = okBaseJump and okTunedJump and okLimit
		and type(baseJump) == "number" and baseJump > 0
		and type(tunedJump) == "number"
		and type(limit) == "number"
		and tunedJump <= limit
	emit(
		"DAY_PHASES_MONOTONIC",
		monotone,
		type(tunedJump) == "number" and string.format("%.6f", tunedJump) or "ERR",
		type(limit) == "number" and "<=" .. string.format("%.6f", limit) or "<= documented limit",
		{
			baseMax = okBaseJump and baseJump or "ERR",
			tunedMax = okTunedJump and tunedJump or "ERR",
			factor = Day.PHASE_JUMP_FACTOR,
			moduleLimit = Day.documentedLimit,
		}
	)

	local okBaseRatio, baseRatio = call(Day.contrastAt1600, Day.BASE_PHASES)
	local okTunedRatio, tunedRatio = call(Day.contrastAt1600, Day.PHASES)
	local okTarget, target = pcall(function()
		return 1.2 * baseRatio
	end)
	-- baseRatio > 0 is a non-vacuity guard: if Color3 channels are unreadable (userdata handled as
	-- a table) both ratios become 0 and 0 >= 0 would PASS with no evidence.
	local contrast = okBaseRatio and okTunedRatio and okTarget
		and type(baseRatio) == "number" and baseRatio > 0
		and type(tunedRatio) == "number"
		and type(target) == "number"
		and tunedRatio >= target
	emit(
		"DAY_1600_CONTRAST",
		contrast,
		type(tunedRatio) == "number" and string.format("%.6f", tunedRatio) or "ERR",
		type(target) == "number" and ">=" .. string.format("%.6f", target) or ">= 1.20x base",
		{
			baseRatio = okBaseRatio and baseRatio or "ERR",
			tunedRatio = okTunedRatio and tunedRatio or "ERR",
			upliftPct = okTarget and type(baseRatio) == "number" and baseRatio > 0
					and type(tunedRatio) == "number"
					and string.format("%.2f%%", (tunedRatio / baseRatio - 1) * 100)
				or "ERR",
		}
	)

	local okMaghrib, unchanged = pcall(Day.maghribUnchanged)
	local okChanges, changes = pcall(Day.maghribChanges)
	local pass = okMaghrib and unchanged == true
	emit("DAY_MAGHRIB_UNCHANGED", pass, pass and 1 or 0, 1, {
		changed = okChanges and changes or "ERR",
		reason = okMaghrib and nil or tostring(unchanged),
	})
end
end

-- 12g. Item 90: night_r8. Own do...end scope (the harness is near the 200-local-register cap).
-- Both lines are MUTATING and SERVER-only: stage night_r8, use the applier's deterministic clock
-- override for 20:00 and 13:00, read the real staged parts, then restore the prior candidate.
do
local nightErrors = {}
local nightModel, nightApplier, nightLook = nil, nil, nil
local okNightModel, modelValue = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapNightR8)
end)
if okNightModel and type(modelValue) == "table" then
	nightModel = modelValue
else
	nightErrors[#nightErrors + 1] = "pure model unreadable"
end
local okNightApplier, applierValue = pcall(function()
	return require(game.ServerScriptService.Server.World.LookDevNightR8)
end)
if
	okNightApplier
	and type(applierValue) == "table"
	and type(applierValue.setClockForCheck) == "function"
	and type(applierValue.clearClockForCheck) == "function"
	and type(applierValue.diagnostics) == "function"
then
	nightApplier = applierValue
else
	nightErrors[#nightErrors + 1] = "server applier unreadable"
end
local okNightLook, lookValue = pcall(function()
	return require(game.ReplicatedStorage.Shared.LookDev)
end)
if okNightLook and type(lookValue) == "table" and type(lookValue.enable) == "function" then
	nightLook = lookValue
else
	nightErrors[#nightErrors + 1] = "LookDev unreadable"
end

local lit20, lit13, windowParts, glowLights, shadowOffenders = 0, 0, 0, 0, 0
local nightPriorId = nil
local nightClockAtCheck = "ERR"

local function measureNight(folder)
	local lit, parts, lights, shadows = 0, 0, 0, 0
	local okDesc, descendants = pcall(function()
		return folder:GetDescendants()
	end)
	if not okDesc or type(descendants) ~= "table" then
		nightErrors[#nightErrors + 1] = "folder descendants unreadable"
		return lit, parts, lights, shadows
	end
	for _, instance in ipairs(descendants) do
		if attr(instance, "NightR8") == "window" then
			parts += 1
			local okMat, material = pcall(function()
				return instance.Material
			end)
			local okCol, colour = pcall(function()
				return instance.Color
			end)
			local warm = false
			if okMat and okCol and material == Enum.Material.Neon then
				local okChannels, r, g, b = pcall(function()
					return colour.R, colour.G, colour.B
				end)
				if okChannels then
					-- #FFCB7A -> normalized 1, 203/255, 122/255; small tolerance for float storage.
					warm = math.abs(r - 1) <= 0.02
						and math.abs(g - 203 / 255) <= 0.02
						and math.abs(b - 122 / 255) <= 0.02
				end
			end
			if warm and attr(instance, "Lit") == true then
				lit += 1
			end
		end
		local okLight, isLight = pcall(function()
			return instance:IsA("PointLight")
		end)
		if okLight and isLight then
			local okEnabled, enabledNow = pcall(function()
				return instance.Enabled
			end)
			if okEnabled and enabledNow == true then
				lights += 1
			end
			local okShadows, castsShadows = pcall(function()
				return instance.Shadows
			end)
			if okShadows and castsShadows == true then
				shadows += 1
			end
		end
	end
	return lit, parts, lights, shadows
end

local function runNightStaged()
	local okCur, current = pcall(function()
		return nightLook.current()
	end)
	if okCur and type(current) == "string" then
		nightPriorId = current
	end
	local okEnable, enabled, why = pcall(function()
		return nightLook.enable("night_r8", { studio = true })
	end)
	if not okEnable or enabled == false then
		nightErrors[#nightErrors + 1] = "enable:" .. tostring(why or enabled)
		return
	end
	local ok20 = pcall(function()
		return nightApplier.setClockForCheck(20)
	end)
	if not ok20 then
		nightErrors[#nightErrors + 1] = "setClockForCheck(20) failed"
		return
	end
	local okDiag, diag = pcall(function()
		return nightApplier.diagnostics()
	end)
	if okDiag and type(diag) == "table" then
		nightClockAtCheck = tostring(diag.clock)
	else
		nightErrors[#nightErrors + 1] = "diagnostics unreadable"
	end
	local okFind, stagedFolder = pcall(function()
		return workspace:FindFirstChild(nightModel.folder)
	end)
	if not okFind or not stagedFolder then
		nightErrors[#nightErrors + 1] = "staging folder missing"
		return
	end
	lit20, windowParts, glowLights, shadowOffenders = measureNight(stagedFolder)
	local ok13 = pcall(function()
		return nightApplier.setClockForCheck(13)
	end)
	if not ok13 then
		nightErrors[#nightErrors + 1] = "setClockForCheck(13) failed"
		return
	end
	lit13 = measureNight(stagedFolder)
end

local okRun, runErr = pcall(runNightStaged)
if not okRun then
	nightErrors[#nightErrors + 1] = "run:" .. tostring(runErr)
end
pcall(function()
	return nightApplier and nightApplier.clearClockForCheck()
end)
if nightLook then
	pcall(function()
		return nightLook.disable()
	end)
	if nightPriorId then
		pcall(function()
			return nightLook.enable(nightPriorId)
		end)
	end
end

local nightReady = #nightErrors == 0 and windowParts >= 12 and glowLights >= 1
emit(
	"NIGHT_WINDOWS",
	nightReady and lit20 >= 12 and lit13 == 0,
	lit20,
	12,
	{
		lit13 = lit13,
		panes = windowParts,
		clockAtCheck = nightClockAtCheck,
		hex = nightModel and nightModel.WINDOW_COLOR_HEX or nil,
		errors = nightErrors,
	}
)
emit(
	"NIGHT_LIGHTS",
	nightReady and glowLights >= 1 and glowLights <= 24 and shadowOffenders == 0,
	glowLights,
	24,
	{
		shadowOffenders = shadowOffenders,
		clockAtCheck = nightClockAtCheck,
		budget = nightModel and nightModel.MAX_LIGHTS or nil,
		errors = nightErrors,
	}
)
end

-- 12h. Item 91: grade_r8_a/b/c. Own do...end scope (the harness is near the 200-local cap).
-- Three MUTATING, SERVER-only checks: enable each grade, read the live Lighting effects on the
-- SERVER (effects created there replicate to clients), compare to the documented safeRanges,
-- disable, then compare every touched property and the Lighting descendant count to the baseline.
-- GRADE_NO_DOF counts depth-of-field effects at baseline and after each enable. All three always
-- emit; a missing effect/range or a failed read FAILs loudly, never skips.
do
-- The whole grade cycle lives in its own function so its locals get a fresh 200-register budget.
local function runGradeChecks()
local gradeErrors, gradeReadings, gradeSafeFails, gradeRestoreFails = {}, {}, {}, {}
local gradeLook, gradeMap, gradePriorId = nil, nil, nil
local safeCount, restoredCount, dofChecked, dofViolations = 0, 0, 0, 0

local function gradeFail(reason)
	gradeErrors[#gradeErrors + 1] = reason
end
local okGradeLook, lookValue = pcall(function()
	return require(game.ReplicatedStorage.Shared.LookDev)
end)
if
	okGradeLook
	and type(lookValue) == "table"
	and type(lookValue.enable) == "function"
	and type(lookValue.disable) == "function"
	and type(lookValue.current) == "function"
then
	gradeLook = lookValue
else
	gradeFail("LookDev unreadable")
end
local okGradeMap, mapValue = pcall(function()
	return require(game.ReplicatedStorage.Shared.ModelMapGradeR8)
end)
if
	okGradeMap
	and type(mapValue) == "table"
	and type(mapValue.order) == "table"
	and type(mapValue.properties) == "table"
	and type(mapValue.safeRanges) == "table"
	and type(mapValue.TOUCHED_EFFECTS) == "table"
then
	gradeMap = mapValue
else
	gradeFail("pure grade model unreadable")
end
-- The appliers register with LookDev only when the module is loaded. The saved place's boot script
-- may predate this candidate, so require it here explicitly; without this, enable() is a silent
-- no-op and GRADE_SAFE would compare unchanged baseline values for all three variants.
local okApplier, applierValue = pcall(function()
	return require(game.ServerScriptService.Server.World.LookDevGradeR8)
end)
if
	not okApplier
	or type(applierValue) ~= "table"
	or type(applierValue.appliers) ~= "table"
then
	gradeFail("server applier unreadable: " .. tostring(applierValue))
end

local function countLightingDesc()
	local ok, list = pcall(function()
		return Lighting:GetDescendants()
	end)
	if not ok or type(list) ~= "table" then
		return nil
	end
	return #list
end

local function countDof()
	local ok, effect = pcall(function()
		return Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	end)
	if not ok then
		return nil
	end
	return if effect then 1 else 0
end

local function readEffects(allowMissing)
	local snapshot = {}
	for _, className in ipairs(gradeMap.TOUCHED_EFFECTS) do
		local okFind, effect = pcall(function()
			return Lighting:FindFirstChildOfClass(className)
		end)
		if not okFind then
			return nil, className .. ":find:" .. tostring(effect)
		end
		if not effect then
			if allowMissing then
				continue
			end
			return nil, className .. ":missing"
		end
		local props = {}
		for _, prop in ipairs(gradeMap.properties[className]) do
			local okRead, value = pcall(function()
				return effect[prop]
			end)
			if not okRead then
				return nil, className .. "." .. prop .. ":read:" .. tostring(value)
			end
			props[prop] = value
		end
		snapshot[className] = props
	end
	return snapshot
end

local function equalValue(before, after)
	if typeof(before) == "Color3" or typeof(after) == "Color3" then
		if typeof(before) ~= "Color3" or typeof(after) ~= "Color3" then
			return false
		end
		return before.R == after.R and before.G == after.G and before.B == after.B
	end
	return before == after
end

local function equalSnapshot(before, after)
	if before == nil or after == nil then
		return before == after
	end
	for _, className in ipairs(gradeMap.TOUCHED_EFFECTS) do
		local a, b = before[className], after[className]
		if (a == nil) ~= (b == nil) then
			return false, className .. ":presence"
		end
		if a then
			for _, prop in ipairs(gradeMap.properties[className]) do
				if not equalValue(a[prop], b[prop]) then
					return false, className .. "." .. prop
				end
			end
		end
	end
	return true
end

local function numberInRange(range, value)
	if type(range) ~= "table" or type(range.min) ~= "number" or type(range.max) ~= "number" then
		return false, "missing range"
	end
	if type(value) ~= "number" or value ~= value then
		return false, "not a number"
	end
	if value < range.min or value > range.max then
		return false, tostring(value)
	end
	return true
end

local function inRange(className, prop, value)
	local ranges = gradeMap.safeRanges[className]
	if type(ranges) ~= "table" then
		return false, "missing effect range"
	end
	local range = ranges[prop]
	if prop == "TintColor" or prop == "Color" or prop == "Decay" then
		if typeof(value) ~= "Color3" then
			return false, "type=" .. typeof(value)
		end
		local scale = if prop == "TintColor" then 1 else 255
		for _, channel in ipairs({ "R", "G", "B" }) do
			local ok, why = numberInRange(range and range[channel], value[channel] * scale)
			if not ok then
				return false, channel .. "=" .. tostring(why)
			end
		end
		if className == "Atmosphere" and prop == "Color" and not (value.R >= value.G and value.G >= value.B) then
			return false, "not warm white"
		end
		if className == "Atmosphere" and prop == "Decay" and not (value.B >= value.G and value.G >= value.R) then
			return false, "not light blue"
		end
		return true
	end
	local ok, why = numberInRange(range, value)
	if not ok then
		return false, tostring(why)
	end
	return true
end

if gradeLook then
	local okCurrent, current = pcall(function()
		return gradeLook.current()
	end)
	if okCurrent and type(current) == "string" then
		gradePriorId = current
	end
end

local baseline, baselineErr = readEffects(true)
local baselineDesc = countLightingDesc()
local baselineDof = countDof()
if not baseline then
	gradeFail("baseline:" .. tostring(baselineErr))
end
if not baselineDesc then
	gradeFail("baseline Lighting descendant count unreadable")
end
if baselineDof == nil then
	gradeFail("baseline depth-of-field count unreadable")
else
	dofChecked += 1
	if baselineDof ~= 0 then
		dofViolations += 1
	end
end

if gradeLook and gradeMap and baseline then
	for _, key in ipairs(gradeMap.order) do
		local id = gradeMap.idPrefix .. key
		local okEnable, enabled, enableErr = pcall(function()
			return gradeLook.enable(id, { studio = true })
		end)
		if not okEnable or enabled == false then
			gradeFail(id .. ":enable:" .. tostring(enableErr or enabled))
		else
			local applied, appliedErr = readEffects(false)
			if not applied then
				gradeFail(id .. ":read:" .. tostring(appliedErr))
			else
				local safe = true
				for _, className in ipairs(gradeMap.TOUCHED_EFFECTS) do
					for _, prop in ipairs(gradeMap.properties[className]) do
						local inBand, why = inRange(className, prop, applied[className][prop])
						gradeReadings[#gradeReadings + 1] = id
							.. "."
							.. className
							.. "."
							.. prop
							.. "="
							.. tostring(applied[className][prop])
						if not inBand then
							safe = false
							gradeSafeFails[#gradeSafeFails + 1] = id
								.. "."
								.. className
								.. "."
								.. prop
								.. ":"
								.. tostring(why)
						end
					end
				end
				if safe then
					safeCount += 1
				end
			end
			local dof = countDof()
			dofChecked += 1
			if dof == nil then
				gradeFail(id .. ":depth-of-field count unreadable")
				dofViolations += 1
			elseif dof ~= 0 then
				dofViolations += 1
			end
		end

		local okDisable, disabled = pcall(function()
			return gradeLook.disable()
		end)
		if not okDisable then
			gradeFail(id .. ":disable:" .. tostring(disabled))
		end
		local after, afterErr = readEffects(true)
		local afterDesc = countLightingDesc()
		if not after then
			gradeFail(id .. ":read-after:" .. tostring(afterErr))
		else
			local same, why = equalSnapshot(baseline, after)
			if not same or afterDesc ~= baselineDesc or not okDisable then
				local reason = if not same
					then tostring(why)
					elseif afterDesc ~= baselineDesc then "descendants " .. tostring(baselineDesc) .. "->" .. tostring(afterDesc)
					else "disable failed"
				gradeRestoreFails[#gradeRestoreFails + 1] = id .. ":" .. reason
			else
				restoredCount += 1
			end
		end
	end
end

if gradePriorId and gradeLook then
	local okRestore, restored = pcall(function()
		return gradeLook.enable(gradePriorId, { studio = true })
	end)
	if not okRestore or restored == false then
		gradeFail("restore-prior:" .. gradePriorId .. ":" .. tostring(restored))
	end
end

local gradeVariantCount = if gradeMap then #gradeMap.order else 3
emit(
	"GRADE_SAFE",
	#gradeErrors == 0 and gradeVariantCount > 0 and safeCount == gradeVariantCount,
	safeCount,
	gradeVariantCount,
	{
		readings = gradeReadings,
		failures = gradeSafeFails,
		errors = gradeErrors,
		restoredPrior = gradePriorId,
	}
)
emit(
	"GRADE_RESTORE",
	#gradeErrors == 0 and gradeVariantCount > 0 and restoredCount == gradeVariantCount,
	restoredCount,
	gradeVariantCount,
	{
		baselineDescendants = baselineDesc,
		failures = gradeRestoreFails,
		errors = gradeErrors,
		restoredPrior = gradePriorId,
	}
)
emit(
	"GRADE_NO_DOF",
	#gradeErrors == 0 and dofChecked == gradeVariantCount + 1 and dofViolations == 0,
	dofViolations,
	0,
	{ checked = dofChecked, errors = gradeErrors }
)
end
runGradeChecks()
end

-- 12i. Item 92: sounds_r8. Own do...end scope with an inner function (the harness is near the
-- 200-local-register cap). MUTATING SERVER-only: enable the candidate, poll IsLoaded for at most
-- Data.LOAD_TIMEOUT_S seconds (no "not authorized" Luau signal exists — never-loaded is the proxy),
-- read Volume/RollOffMaxDistance/SoundGroup/parent on all six beds, disable, and require exact
-- SoundService/group/folder restore plus the prior candidate. All three lines always emit.
do
local function soundFailAll(reason)
	emit("SOUND_LOADED", false, 0, 6, { reason = reason })
	emit("SOUND_VOLUME", false, 0, 6, { reason = reason })
	emit("SOUND_RESTORE", false, 0, 1, { reason = reason })
end

local function runSoundChecks()
	if not isServer then
		soundFailAll("server VM required")
		return
	end
	local okModules, mods = pcall(function()
		return {
			look = require(game.ReplicatedStorage.Shared.LookDev),
			map = require(game.ReplicatedStorage.Shared.ModelMapSoundsR8),
			soundService = game:GetService("SoundService"),
			-- The appliers register at module load; a saved place's boot script may predate this one.
			applier = require(game.ServerScriptService.Server.World.LookDevSoundsR8),
		}
	end)
	if
		not okModules
		or type(mods) ~= "table"
		or type(mods.look) ~= "table"
		or type(mods.look.enable) ~= "function"
		or type(mods.look.current) ~= "function"
		or type(mods.map) ~= "table"
		or type(mods.map.BEDS) ~= "table"
		or type(mods.map.folder) ~= "string"
		or type(mods.map.groupName) ~= "string"
		or type(mods.applier) ~= "table"
	then
		soundFailAll("modules unreadable: " .. tostring(mods))
		return
	end
	local Look, Data = mods.look, mods.map
	local errors = {}
	local function soundFail(reason)
		errors[#errors + 1] = reason
	end

	local okCur, current = pcall(function()
		return Look.current()
	end)
	local priorId = if okCur and type(current) == "string" then current else nil
	local function disableActive()
		pcall(function()
			return Look.disable()
		end)
	end
	local function restorePrior()
		if not priorId then
			return
		end
		pcall(function()
			return Look.enable(priorId, { studio = true })
		end)
	end

	local function groupNames()
		local okList, list = pcall(function()
			return mods.soundService:GetChildren()
		end)
		local names = {}
		if okList and type(list) == "table" then
			for _, inst in ipairs(list) do
				local okGroup, isGroup = pcall(function()
					return inst:IsA("SoundGroup")
				end)
				if okGroup and isGroup then
					names[#names + 1] = inst.Name
				end
			end
		end
		table.sort(names)
		return names
	end

	local function soundDescCount()
		local okList, list = pcall(function()
			return mods.soundService:GetDescendants()
		end)
		if okList and type(list) == "table" then
			return #list
		end
		return nil
	end

	disableActive()
	local baselineDesc = soundDescCount()
	local baselineGroups = groupNames()
	local baselineKey = table.concat(baselineGroups, "|")
	if baselineDesc == nil then
		soundFail("baseline SoundService descendants unreadable")
	end
	local okBaselineFolder, baselineFolder = pcall(function()
		return workspace:FindFirstChild(Data.folder)
	end)
	if not okBaselineFolder then
		soundFail("baseline folder read failed")
	end

	local okEnable, enabled, enableErr = pcall(function()
		return Look.enable(Data.id, { studio = true })
	end)
	if not okEnable or enabled == false then
		soundFail("enable:" .. tostring(enableErr or enabled))
	end

	local sounds = {}
	local okFolder, stagedFolder = pcall(function()
		return workspace:FindFirstChild(Data.folder)
	end)
	if not okFolder or not stagedFolder then
		soundFail("staged folder missing")
	else
		local okDesc, descendants = pcall(function()
			return stagedFolder:GetDescendants()
		end)
		if not okDesc or type(descendants) ~= "table" then
			soundFail("staged descendants unreadable")
		else
			for _, inst in ipairs(descendants) do
				local okSound, isSound = pcall(function()
					return inst:IsA("Sound")
				end)
				if okSound and isSound then
					sounds[#sounds + 1] = inst
				end
			end
		end
	end

	local function soundByKey(key)
		for _, sound in ipairs(sounds) do
			local okName, name = pcall(function()
				return sound.Name
			end)
			if okName and name == key then
				return sound
			end
		end
		return nil
	end

	local expected = #Data.BEDS
	local timeout = type(Data.LOAD_TIMEOUT_S) == "number" and Data.LOAD_TIMEOUT_S or 10
	local started = os.clock()
	local loadedCount, detail = 0, {}
	while true do
		loadedCount = 0
		detail = {}
		for _, bed in ipairs(Data.BEDS) do
			local sound = soundByKey(bed.key)
			local loaded, length = false, nil
			if sound then
				local okLoad, value = pcall(function()
					return sound.IsLoaded
				end)
				if okLoad then
					loaded = value == true
				end
				local okLength, seconds = pcall(function()
					return sound.TimeLength
				end)
				if okLength then
					length = seconds
				end
			end
			if loaded then
				loadedCount += 1
			end
			detail[#detail + 1] = bed.key
				.. "="
				.. tostring(loaded)
				.. "/"
				.. (type(length) == "number" and string.format("%.3f", length) or "no-length")
		end
		local elapsed = os.clock() - started
		if loadedCount == expected or elapsed >= timeout then
			break
		end
		pcall(function()
			task.wait(0.25)
		end)
	end
	local elapsed = os.clock() - started
	emit(
		"SOUND_LOADED",
		#errors == 0 and #sounds >= expected and loadedCount == expected,
		loadedCount,
		expected,
		{
			beds = expected,
			stagedSounds = #sounds,
			elapsed = math.floor(elapsed * 100) / 100,
			timeout = timeout,
			detail = table.concat(detail, " "),
			errors = errors,
			proxy = "never-loaded IsLoaded is the only available not-authorized signal",
		}
	)

	local compliant, offenders = 0, {}
	for _, bed in ipairs(Data.BEDS) do
		local sound = soundByKey(bed.key)
		if sound then
			local okRead, volume, rollOff, soundGroup, parent = pcall(function()
				return sound.Volume, sound.RollOffMaxDistance, sound.SoundGroup, sound.Parent
			end)
			local positional = false
			if okRead and parent then
				local okParent, isPositional = pcall(function()
					return parent:IsA("BasePart") or parent:IsA("Attachment")
				end)
				positional = okParent and isPositional == true
			end
			if
				okRead
				and type(volume) == "number"
				and volume <= Data.MAX_VOLUME
				and type(rollOff) == "number"
				and rollOff <= Data.MAX_ROLLOFF
				and soundGroup ~= nil
				and positional
			then
				compliant += 1
			else
				offenders[#offenders + 1] = bed.key
					.. ":volume="
					.. tostring(volume)
					.. ",rollOff="
					.. tostring(rollOff)
					.. ",group="
					.. tostring(soundGroup ~= nil)
					.. ",positional="
					.. tostring(positional)
			end
		else
			offenders[#offenders + 1] = bed.key .. ":missing"
		end
	end
	emit(
		"SOUND_VOLUME",
		#errors == 0 and #sounds >= expected and compliant == expected and #offenders == 0,
		compliant,
		expected,
		{
			maxVolume = Data.MAX_VOLUME,
			maxRollOff = Data.MAX_ROLLOFF,
			groupName = Data.groupName,
			stagedSounds = #sounds,
			offenders = offenders,
			errors = errors,
		}
	)

	local captured = {}
	for _, sound in ipairs(sounds) do
		captured[#captured + 1] = sound
	end
	local okDisable, disabled = pcall(function()
		return Look.disable()
	end)
	if not okDisable then
		soundFail("disable:" .. tostring(disabled))
	end
	local restoreFails = {}
	local afterDesc = soundDescCount()
	if afterDesc ~= baselineDesc then
		restoreFails[#restoreFails + 1] = "descendants " .. tostring(baselineDesc) .. "->" .. tostring(afterDesc)
	end
	local afterGroups = groupNames()
	if table.concat(afterGroups, "|") ~= baselineKey then
		restoreFails[#restoreFails + 1] = "groups " .. baselineKey .. "->" .. table.concat(afterGroups, "|")
	end
	local okAfterFolder, afterFolder = pcall(function()
		return workspace:FindFirstChild(Data.folder)
	end)
	if not okAfterFolder then
		restoreFails[#restoreFails + 1] = "folder-read"
	elseif (baselineFolder ~= nil) ~= (afterFolder ~= nil) then
		restoreFails[#restoreFails + 1] = "folder-restored=" .. tostring(afterFolder ~= nil)
	end
	for _, sound in ipairs(captured) do
		local okParent, parent = pcall(function()
			return sound.Parent
		end)
		if not okParent or parent ~= nil then
			restoreFails[#restoreFails + 1] = "sound-parent=" .. tostring(okParent and parent or "read-error")
		end
		local okPlaying, playing = pcall(function()
			return sound.IsPlaying
		end)
		if not okPlaying or playing == true then
			restoreFails[#restoreFails + 1] = "sound-playing"
		end
	end
	local okCurAfter, currentAfter = pcall(function()
		return Look.current()
	end)
	if not okCurAfter or currentAfter ~= nil then
		restoreFails[#restoreFails + 1] = "still-enabled"
	end
	restorePrior()
	local okRestored, restoredId = pcall(function()
		return Look.current()
	end)
	if not okRestored or restoredId ~= priorId then
		restoreFails[#restoreFails + 1] = "prior=" .. tostring(priorId)
	end
	emit(
		"SOUND_RESTORE",
		#errors == 0 and #restoreFails == 0,
		#restoreFails == 0 and 1 or 0,
		1,
		{
			baselineDescendants = baselineDesc,
			afterDescendants = afterDesc,
			createdGroup = Data.groupName,
			prior = priorId,
			failures = restoreFails,
			errors = errors,
		}
	)
end
runSoundChecks()
end

-- 13. LOOKDEV_LEAK: mutating, run last. For every LookDev.IDS entry, count workspace and
-- Lighting descendants, enable(id), disable(), count again. PASS only when both counts are
-- unchanged for every id. The prior active candidate is restored at the end, so repeated runs
-- leave the same toggle state they found.
local function descendantCount(inst)
	if not inst then
		return nil
	end
	local ok, list = pcall(function()
		return inst:GetDescendants()
	end)
	if not ok or type(list) ~= "table" then
		return nil
	end
	return #list
end

local okLookDev, LookDev = pcall(function()
	return require(game.ReplicatedStorage.Shared.LookDev)
end)
local leakErrors = {}
local leakEntries = {}
local priorId = nil
if not okLookDev or type(LookDev) ~= "table" or type(LookDev.IDS) ~= "table" then
	leakErrors[#leakErrors + 1] = "LookDev not readable"
elseif
	type(LookDev.enable) ~= "function"
	or type(LookDev.disable) ~= "function"
	or type(LookDev.current) ~= "function"
then
	leakErrors[#leakErrors + 1] = "LookDev API incomplete"
else
	local okCur, current = pcall(function()
		return LookDev.current()
	end)
	if okCur and type(current) == "string" then
		priorId = current
	end

	local function clearActive()
		local okDisable, changed = pcall(function()
			return LookDev.disable()
		end)
		if not okDisable then
			leakErrors[#leakErrors + 1] = "disable:" .. tostring(changed)
		end
	end

	local function restorePrior()
		if not priorId then
			return
		end
		local okEnable, result = pcall(function()
			return LookDev.enable(priorId)
		end)
		if not okEnable or result == false then
			leakErrors[#leakErrors + 1] = "restore:" .. priorId .. ":" .. tostring(result)
		end
	end

	clearActive()
	for _, id in ipairs(LookDev.IDS) do
		local beforeWorkspace = descendantCount(workspace)
		local beforeLighting = descendantCount(Lighting)
		if beforeWorkspace == nil or beforeLighting == nil then
			leakErrors[#leakErrors + 1] = id .. ":count-before"
			clearActive()
		else
			local okEnable, result, enableErr = pcall(function()
				return LookDev.enable(id)
			end)
			if not okEnable or result == false then
				leakErrors[#leakErrors + 1] = id .. ":enable:" .. tostring(enableErr or result)
			end
			clearActive()

			local afterWorkspace = descendantCount(workspace)
			local afterLighting = descendantCount(Lighting)
			if afterWorkspace == nil or afterLighting == nil then
				leakErrors[#leakErrors + 1] = id .. ":count-after"
			else
				local deltaWorkspace = afterWorkspace - beforeWorkspace
				local deltaLighting = afterLighting - beforeLighting
				if deltaWorkspace ~= 0 or deltaLighting ~= 0 then
					leakEntries[#leakEntries + 1] = string.format(
						"%s(w%d->%d %+d,l%d->%d %+d)",
						id,
						beforeWorkspace,
						afterWorkspace,
						deltaWorkspace,
						beforeLighting,
						afterLighting,
						deltaLighting
					)
				end
			end
		end
	end
	clearActive()
	restorePrior()
end

local leakMeasured = "0 leaks"
if #leakEntries > 0 then
	leakMeasured = #leakEntries .. " leaks: " .. table.concat(leakEntries, ",")
end
if #leakErrors > 0 then
	leakMeasured = "ERR " .. table.concat(leakErrors, ",") .. " | " .. leakMeasured
end
emit("LOOKDEV_LEAK", #leakEntries == 0 and #leakErrors == 0, leakMeasured, "0 leaks", {
	candidateCount = type(LookDev) == "table" and type(LookDev.IDS) == "table" and #LookDev.IDS or 0,
	leaks = leakEntries,
	errors = leakErrors,
	restored = priorId,
})

local byName = {}
for _, result in ipairs(results) do
	byName[result.name] = result
end

return { order = ORDER, checks = results, byName = byName }
-- stylua: ignore end
