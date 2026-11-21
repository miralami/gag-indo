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
-- All checks except LOOKDEV_LEAK, ADDITIVE_STAGE, WATER_SAFE, WATER_RESTORE, WIND_SET,
-- SWAY_TWEENS and WIND_RESTORE are read-only. The mutating checks call enable(id)/disable() and
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
	"LOOKDEV_LEAK",
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
	for _, id in ipairs({ "vegetation_r7", "npcs_r7", "props_r7", "npcs_r8", "npcs_idle_r8" }) do
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
