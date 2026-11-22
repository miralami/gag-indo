--!nocheck
-- tools/studio/review_check_r7.luau — WORK_QUEUE section K item 53, extended for section L
-- (round 8). Paste the WHOLE file into Studio `execute_luau`.
--
-- Server datamodel: run during real Play after the Edit-mode bake (item 54) and after enabling
-- vegetation_r7 / npcs_r7 / props_r7. It prints these eleven lines:
--   LOAD_FAILURES, SKY_DEFAULT, GRASS_ON_BEDS, HATS, PROPS_VISIBLE, PROPS_ON_GRASS,
--   VEG_COUNT, VEG_SPECIES, BED_FLUSH, VEG_NEAR, PROP_SIZE
-- Client datamodel: run in a FRESH Play with no enable call, at least 10 s after Start. It prints
-- the same lines plus CLOUD_COVER (the client LocalScript owns Terrain.Clouds.Cover); the Server
-- datamodel cannot observe that tween, so the check is deliberately emitted only on the client.
--
-- Read-only: it never enables or restores a candidate. Every line is
--   CHECK <name> PASS|FAIL <measured> <target>
-- and it returns a results table. A missing folder, attribute, service or failed read is a FAIL,
-- never a skip. No visual verdict is made here.
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
local CollectionService = service("CollectionService")
local okTagged, tagged = pcall(function()
	return CollectionService:GetTagged("PlotAnchor")
end)
if not okTagged then
	samples[#samples + 1] = { name = "plot:query-failed", x = 0, z = 0 }
else
	for index, anchor in ipairs(tagged) do
		local okPos, position = pcall(function()
			return anchor:GetPivot().Position
		end)
		if okPos then
			samples[#samples + 1] = { name = "plot:" .. index, x = position.X, z = position.Z }
		end
	end
end
local grassFailures = {}
for _, sample in ipairs(samples) do
	if not voxelHasNonGrass(sample.x, GRASS_Y, sample.z) then
		grassFailures[#grassFailures + 1] = sample.name
	end
end
emit(
	"GRASS_ON_BEDS",
	#grassFailures == 0,
	#grassFailures,
	0,
	{ voxelY = GRASS_Y, samples = #samples, failed = grassFailures }
)

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
local visibleCount = 0
local onGrassCount = 0
local propDetail = {}
for _, slot in ipairs(PROP_SLOTS) do
	local subject = propsBySlot[slot]
	local centre = bboxCentre(subject)
	local seen = false
	local grassy = true -- absent subject is a failing grass sample, not a skip
	if subject and centre then
		grassy = not voxelHasNonGrass(centre.X, GRASS_Y, centre.Z)
		if propEye and propLook then
			seen = visibleFrom(subject, centre, propEye, propLook)
		end
	end
	if seen then
		visibleCount += 1
	end
	if grassy then
		onGrassCount += 1
	end
	propDetail[slot] = {
		visible = seen,
		onGrass = grassy,
		centre = centre and { centre.X, centre.Y, centre.Z } or nil,
	}
end
emit("PROPS_VISIBLE", visibleCount == #PROP_SLOTS, visibleCount, #PROP_SLOTS, {
	folderPresent = propFolder ~= nil,
	cameraPos = propEye and { propEye.X, propEye.Y, propEye.Z } or nil,
	lookAt = propLook and { propLook.X, propLook.Y, propLook.Z } or nil,
	slots = propDetail,
})
emit("PROPS_ON_GRASS", onGrassCount == 0, onGrassCount, 0, { voxelY = GRASS_Y, slots = propDetail })

-- 7/8. VEG_COUNT and VEG_SPECIES: fixed camera, 100 studs, 70-degree cone.
local vegFolder = folderNamed("LookDevModelsVegetationR7_vegetation_r7")
local vegCount = 0
local speciesSeen = {}
for _, model in ipairs(childList(vegFolder)) do
	if attr(model, "LookDevR7") == "vegetation_r7" then
		local centre = bboxCentre(model)
		if centre and (centre - VEG_EYE).Magnitude <= 100 and insideCone(centre, VEG_EYE, VEG_LOOK) then
			vegCount += 1
			local species = attr(model, "Species")
			if type(species) == "string" and species ~= "" then
				speciesSeen[species] = true
			end
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
for _, model in ipairs(childList(vegFolder)) do
	if attr(model, "LookDevR7") == "vegetation_r7" then
		local centre = bboxCentre(model)
		local size = bboxSize(model)
		if
			centre
			and size
			and (centre - VEG_EYE).Magnitude <= NEAR_RADIUS
			and insideCone(centre, VEG_EYE, VEG_LOOK)
		then
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

local byName = {}
for _, result in ipairs(results) do
	byName[result.name] = result
end

return { order = ORDER, checks = results, byName = byName }
