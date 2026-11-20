--!nocheck
-- tools/studio/review_check_r8.luau — WORK_QUEUE section M item 68 (round 9). Paste the WHOLE
-- file into Studio `execute_luau`.
--
-- Server datamodel: run during real Play after the Edit-mode bake (step 1 of REVIEW_ROUND9.md).
-- It emits the eleven r7 server scene lines plus LOOKDEV_LEAK:
--   LOAD_FAILURES, SKY_DEFAULT, GRASS_ON_BEDS, HATS, PROPS_VISIBLE, PROPS_ON_GRASS,
--   VEG_COUNT, VEG_SPECIES, BED_FLUSH, VEG_NEAR, PROP_SIZE, LOOKDEV_LEAK.
-- It also emits the r8 hub-vegetation family (WORK_QUEUE item 70): VEG_HUB_<hub> (one per
-- MapSpec.HUB_ORDER key), VEG_SPECIES_HUB and VEG_OVERLAP. All three FAIL at measured 0 when the
-- hubveg_r8 candidate is not staged. It also emits the r8 plots family (WORK_QUEUE item 71):
-- PLOT_FENCE and GATE_CLEAR. Both FAIL when the plots_r8 candidate is not staged.
-- Client datamodel: same lines plus CLOUD_COVER (the client LocalScript owns Terrain.Clouds.Cover);
-- the Server datamodel cannot observe that tween. Run client-owned candidates (water, grade,
-- sounds, clouds) in the Client datamodel.
--
-- All checks except LOOKDEV_LEAK are read-only. LOOKDEV_LEAK calls enable(id)/disable() for every
-- id in LookDev.IDS and restores the prior active candidate at the end; it is safe to repeat.
-- Every line is
--   CHECK <name> PASS|FAIL <measured> <target>
-- and the file returns a results table. A missing folder, attribute, service or failed read is a
-- FAIL, never a skip. No visual verdict is made here.
--
-- Grass cell: y = 4 (4-stud Region3 spanning y ~= 2..6) for both beds and props.

local ORDER = {
	"LOAD_FAILURES",
	"SKY_DEFAULT",
	"GRASS_ON_BEDS",
	"HATS",
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
	"VEG_OVERLAP",
	"PLOT_FENCE",
	"GATE_CLEAR",
	"VEG_NEAR",
	"PROP_SIZE",
	"CLOUD_COVER",
	"CAMERA_CLEAR",
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

-- 1. LOAD_FAILURES: sum of the three r7 counters, PASS only at 0.
local failureCounts = {}
local failureOk = true
local okModule, Failures = pcall(function()
	return require(game.ReplicatedStorage.Shared.LookDevFailures)
end)
if not okModule or type(Failures) ~= "table" then
	failureOk = false
else
	for _, id in ipairs({ "vegetation_r7", "npcs_r7", "props_r7" }) do
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

-- 9b. r8 hub-vegetation family (WORK_QUEUE item 70). Three CHECK families over the staged
-- LookDevModelsVegetationHubR8_hubveg_r8 folder. Hub keys come from MapSpec.HUB_ORDER (fallback
-- listed below so the same six FAIL lines are emitted even when MapSpec cannot be required).
-- Every game API is pcall-guarded; a missing folder / module is a FAIL at measured 0, never a skip.
local FALLBACK_HUB_ORDER = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }
local HUB_VEG_FOLDER = "LookDevModelsVegetationHubR8_hubveg_r8"
local HUB_VEG_RADIUS = 40
local HUB_VEG_MIN_COUNT = 12
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
for _, model in ipairs(childList(vegR8Folder)) do
	if attr(model, "LookDevHubVegR8") == "hubveg_r8" then
		staged[#staged + 1] = {
			hub = attr(model, "Hub"),
			species = attr(model, "Species"),
			centre = bboxCentre(model),
			aabb = bboxAABB(model),
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

-- 9c. r8 plots family (WORK_QUEUE item 71). Two CHECK families over the staged
-- LookDevPlotsR8_plots_r8 folder. PLOT_FENCE counts fence segments per plot (min decides, never
-- an average); GATE_CLEAR casts a 6x8x1 overlap box at every gate marker and requires zero
-- CanCollide=true hits. Every game API is pcall-guarded; a missing folder, marker or API is a
-- FAIL, never a skip.
local PLOTS_FOLDER = "LookDevPlotsR8_plots_r8"
local PLOT_COUNT = 10
local FENCE_MIN = 6
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
-- PlotIndex; a missing folder gives every plot 0, hence min=0 and a FAIL.
local fenceCounts = {}
for i = 1, PLOT_COUNT do
	fenceCounts[i] = 0
end
for _, part in ipairs(plotParts) do
	if attr(part, "Kind") == "fence" then
		local index = attr(part, "PlotIndex")
		if type(index) == "number" and fenceCounts[index] ~= nil then
			fenceCounts[index] = fenceCounts[index] + 1
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
