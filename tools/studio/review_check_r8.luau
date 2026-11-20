--!nocheck
-- tools/studio/review_check_r8.luau — WORK_QUEUE section M item 68 (round 9). Paste the WHOLE
-- file into Studio `execute_luau`.
--
-- Server datamodel: run during real Play after the Edit-mode bake (step 1 of REVIEW_ROUND9.md).
-- It emits the eleven r7 server scene lines plus LOOKDEV_LEAK:
--   LOAD_FAILURES, SKY_DEFAULT, GRASS_ON_BEDS, HATS, PROPS_VISIBLE, PROPS_ON_GRASS,
--   VEG_COUNT, VEG_SPECIES, BED_FLUSH, VEG_NEAR, PROP_SIZE, LOOKDEV_LEAK.
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
local function bboxCentre(inst)
	if not inst then
		return nil
	end
	local ok, cf = pcall(function()
		return inst:GetBoundingBox()
	end)
	if ok and cf then
		return cf.Position
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
