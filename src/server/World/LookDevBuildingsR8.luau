--!strict
-- LookDevBuildingsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "buildings_r8" candidate
-- (WORK_QUEUE section M item 77). Main.server wires the candidate; this file only registers it.
-- InsertService is never called here: every asset comes through
-- LookDevAssetLoader.get(id, "buildings_r8") (baked clone first, LoadAsset only as its fallback).
--
-- apply() scans workspace for tree/pine models, picks the model-free site nearest spawn (a
-- 340x80 box probed with GetPartBoundsInBox, plus tree/keep-out filters), stages six Creator Store
-- buildings with 20 studs of CLEAR GAP between footprints (ScaleTo first for rumah_joglo), paints
-- a Ground voxel pad under each footprint, and stages ONE avatar-fit Part named "DoorGauge" per
-- building. The gauge is 7 x 7.25 x 2, CanCollide=false, Transparency=1, Anchored=true, parented
-- under the staged Model, with LookDevBuildingsR8/BuildingSlot/GaugeKind/Facade attributes. A single
-- temporary probe Part finds the first clear front/back opening with rotation-aware
-- GetPartsInPart AFTER the model is parented into the staged folder (so the probe sees the real
-- building geometry), then is destroyed. The folder LookDevBuildingsR8_buildings_r8 carries
-- ReviewCameraPos/LookAt.
-- Every failure is counted and warned, then published to Shared.LookDevFailures.set("buildings_r8",
-- failures) at the END of apply(). restore() detaches and restores the exact previous folder.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevBuildingsR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevBuildingsR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, ModelMapBuildingsR8, LookDevAssetLoader, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapBuildingsR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not ModelMapBuildingsR8 or not LookDevAssetLoader or not LookDevFailures then
	warn("[LookDevBuildingsR8] could not require LookDev / ModelMapBuildingsR8 / LookDevAssetLoader / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevBuildingsR8] could not require MapSpec; voxel pads will be skipped")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevBuildingsR8 = {}

local FAMILY_ID: string = ModelMapBuildingsR8.familyId
local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local cameraPos: Vector3? = nil
local cameraLook: Vector3? = nil
local lastCentre: { x: number, z: number }? = nil
local probePart: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevBuildingsR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set("buildings_r8", failures)
	end)
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function destroyProbe()
	local probe = probePart
	if probe then
		pcall(function()
			probe:Destroy()
		end)
		probePart = nil
	end
end

-- ONE rotation-aware probe reused for every gauge candidate; never parented to a staged model.
local function createProbe(): any?
	if not Workspace then
		return nil
	end
	local gauge = ModelMapBuildingsR8.gauge
	local ok, part = pcall(function()
		local created = Instance.new("Part")
		created.Size = Vector3.new(gauge.width, gauge.height, gauge.depth)
		created.CanCollide = false
		created.Transparency = 1
		created.Anchored = false
		created.Parent = Workspace
		return created
	end)
	if not ok or not part then
		fail("could not create gauge probe Part")
		return nil
	end
	probePart = part
	return part
end

local function findPrevious(): any?
	if not Workspace then
		return nil
	end
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(ModelMapBuildingsR8.folderName)
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	if not Workspace then
		return nil
	end
	local ok, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not ok or not folder then
		fail("could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = ModelMapBuildingsR8.folderName
		folder.Parent = Workspace
	end)
	return folder
end

-- Name match first (Tree_N, Pine_<angle>_<layer>, pohon/cemara imports); otherwise any Model with
-- four or more Part descendants is treated as a tree so a renamed trunk still blocks the yard.
local function looksLikeTree(model: any): boolean
	local okName, name = pcall(function()
		return string.lower(model.Name)
	end)
	if okName and type(name) == "string" then
		for _, keyword in ipairs({ "pine", "tree", "pohon", "cemara" }) do
			if string.find(name, keyword, 1, true) then
				return true
			end
		end
	end
	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if not okParts or not parts then
		return false
	end
	local count = 0
	for _, descendant in ipairs(parts) do
		if descendant:IsA("BasePart") then
			count += 1
			if count >= 4 then
				return true
			end
		end
	end
	return false
end

local function trunkXZ(model: any): (number?, number?)
	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if okParts and parts then
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") then
				local okName, name = pcall(function()
					return string.lower(part.Name)
				end)
				if
					okName
					and type(name) == "string"
					and (string.find(name, "trunk", 1, true) or string.find(name, "batang", 1, true))
				then
					local okPos, position = pcall(function()
						return part.Position
					end)
					if okPos and position then
						return position.X, position.Z
					end
				end
			end
		end
	end
	local okBox, boxCFrame = pcall(function()
		return model:GetBoundingBox()
	end)
	if okBox and boxCFrame then
		return boxCFrame.Position.X, boxCFrame.Position.Z
	end
	return nil, nil
end

local function treeTrunks(): { { number } }
	local trunks = {}
	if not Workspace then
		return trunks
	end
	local okAll, all = pcall(function()
		return (Workspace :: any):GetDescendants()
	end)
	if not okAll or not all then
		fail("workspace descendant scan failed")
		return trunks
	end
	for _, instance in ipairs(all) do
		local okModel = pcall(function()
			return instance:IsA("Model")
		end)
		if okModel and instance:IsA("Model") and looksLikeTree(instance) then
			local x, z = trunkXZ(instance)
			if type(x) == "number" and type(z) == "number" then
				trunks[#trunks + 1] = { x, z }
			end
		end
	end
	return trunks
end

-- A site is clear when no trunk is within 15 studs of ANY edge and the footprint misses every
-- MapSpec keep-out rect. Candidates are walked outward from spawn on a 10-stud grid.
local function yardClear(x: number, z: number, trunks: { { number } }, keepOut: { { number } }): boolean
	local halfX = ModelMapBuildingsR8.siteWidth / 2
	local halfZ = ModelMapBuildingsR8.siteDepth / 2
	local marginX = halfX + ModelMapBuildingsR8.trunkClearance
	local marginZ = halfZ + ModelMapBuildingsR8.trunkClearance
	for _, trunk in ipairs(trunks) do
		if math.abs(trunk[1] - x) < marginX and math.abs(trunk[2] - z) < marginZ then
			return false
		end
	end
	for _, rect in ipairs(keepOut) do
		if math.abs(x - rect[1]) < halfX + rect[3] and math.abs(z - rect[2]) < halfZ + rect[4] then
			return false
		end
	end
	return true
end

-- The 340x80 site must be free of existing World Models, not just trees: the old (0,-62) yard sat
-- on the shipping Pasar/Warung hubs. Terrain and this candidate's staged folder are excluded.
local function siteHasModels(x: number, z: number, stagedFolder: any?): boolean
	if not Workspace then
		return false
	end
	local okParams, params = pcall(function()
		local p = OverlapParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		local filters = {}
		local terrain = (Workspace :: any).Terrain
		if terrain then
			filters[#filters + 1] = terrain
		end
		if stagedFolder then
			filters[#filters + 1] = stagedFolder
		end
		p.FilterDescendantsInstances = filters
		return p
	end)
	if not okParams or not params then
		return true
	end
	local okBounds, parts = pcall(function()
		return (Workspace :: any):GetPartBoundsInBox(
			CFrame.new(x, ModelMapBuildingsR8.siteProbeY, z),
			Vector3.new(ModelMapBuildingsR8.siteWidth, ModelMapBuildingsR8.siteHeight, ModelMapBuildingsR8.siteDepth),
			params
		)
	end)
	if not okBounds or type(parts) ~= "table" then
		return true
	end
	local seen = {} :: { [any]: boolean }
	for _, part in ipairs(parts) do
		local okModel, model = pcall(function()
			local current: any? = part
			while current do
				if current:IsA("Model") then
					return current
				end
				current = current.Parent
			end
			return nil
		end)
		if okModel and model then
			seen[model] = true
		end
	end
	for _ in pairs(seen) do
		return true
	end
	return false
end

local function pickYard(trunks: { { number } }, stagedFolder: any?): (number, number)
	local spawnX, spawnZ = 0, 28
	local limit = 400
	local keepOut = {} :: { { number } }
	if MapSpec then
		if MapSpec.SPAWN then
			spawnX, spawnZ = MapSpec.SPAWN.x, MapSpec.SPAWN.z
		end
		if type(MapSpec.TERRAIN_HALF) == "number" then
			limit = MapSpec.TERRAIN_HALF
		end
		local okRects, rects = pcall(function()
			return MapSpec.keepOutRects()
		end)
		if okRects and type(rects) == "table" then
			keepOut = rects
		end
	end
	local halfX = ModelMapBuildingsR8.siteWidth / 2
	local halfZ = ModelMapBuildingsR8.siteDepth / 2
	local candidates = {}
	for dx = -240, 240, 10 do
		for dz = -240, 240, 10 do
			local x, z = spawnX + dx, spawnZ + dz
			if math.abs(x) <= limit - halfX and math.abs(z) <= limit - halfZ then
				candidates[#candidates + 1] = { x = x, z = z, d = dx * dx + dz * dz }
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.d < b.d
	end)
	for _, candidate in ipairs(candidates) do
		if
			yardClear(candidate.x, candidate.z, trunks, keepOut)
			and not siteHasModels(candidate.x, candidate.z, stagedFolder)
		then
			return candidate.x, candidate.z
		end
	end
	fail("no clear model-free site found; falling back to spawn")
	return spawnX, spawnZ
end

local function paintGroundPad(boxCFrame: any, boxSize: any)
	if not MapSpec or not Workspace then
		fail("missing MapSpec/Workspace; Ground pad skipped")
		return
	end
	local terrain = (Workspace :: any).Terrain
	if not terrain then
		fail("missing Terrain; Ground pad skipped")
		return
	end
	local bottom = MapSpec.GROUND_Y - MapSpec.TERRAIN_VOXEL
	local cy, sy = MapSpec.volumeForTop(bottom, MapSpec.GROUND_Y)
	local margin = ModelMapBuildingsR8.padMargin
	local cap = MapSpec.MAX_FILL_SPAN or 40
	local sx = math.min(boxSize.X + margin, cap)
	local sz = math.min(boxSize.Z + margin, cap)
	local ok = pcall(function()
		terrain:FillBlock(
			CFrame.new(boxCFrame.Position.X, cy, boxCFrame.Position.Z),
			Vector3.new(sx, sy, sz),
			Enum.Material.Ground
		)
	end)
	if not ok then
		fail("Ground pad FillBlock failed")
	end
end

local function worldBox(instance: any): (any?, any?)
	local ok, boxCFrame, size = pcall(function()
		return instance:GetBoundingBox()
	end)
	if not ok or not boxCFrame or not size or size.X ~= size.X or size.Y ~= size.Y or size.Z ~= size.Z then
		return nil, nil
	end
	return boxCFrame, size
end

local GAUGE_X_OFFSETS = { 0, -3, 3, -6, 6, -9, 9, -12, 12 }
local GAUGE_DEPTH_OFFSETS = { 2, 4, 6, 8, 10, 12, 14 }

-- Gauge centre for the chosen facade, from the staged (scaled) world bbox. floorOffset lifts the
-- box above the ground slab so the slab never counts as a blocked doorway. The centre-front
-- position (no X offset, depth 2) is also the honest fallback when no clear spot is found.
local function gaugePosition(boxCFrame: any, boxSize: any, facade: string, xOffset: number, depth: number): any?
	local gauge = ModelMapBuildingsR8.gauge
	local ok, position = pcall(function()
		local centre = boxCFrame.Position
		local y = centre.Y - boxSize.Y / 2 + gauge.floorOffset + gauge.height / 2
		local z = if facade == "front" then centre.Z - boxSize.Z / 2 + depth else centre.Z + boxSize.Z / 2 - depth
		return Vector3.new(centre.X + xOffset, y, z)
	end)
	return if ok then position else nil
end

-- Rotation-aware clearance test: world AABBs of rotated roof panels swallow the gauge even when
-- their actual geometry does not intersect it. GetPartsInPart tests the oriented shape instead.
-- Returns false when the candidate is blocked or unreadable; only a confirmed zero-overlap wins.
local function gaugeIsClear(probe: any, model: any, position: any): boolean
	if not Workspace or not pcall(function()
		probe.CFrame = CFrame.new(position)
	end) then
		return false
	end
	local okParams, params = pcall(function()
		local p = OverlapParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = { probe }
		return p
	end)
	if not okParams or not params then
		return false
	end
	local okHits, hits = pcall(function()
		return (Workspace :: any):GetPartsInPart(probe, params)
	end)
	if not okHits or type(hits) ~= "table" then
		return false
	end
	for _, part in ipairs(hits) do
		local okDesc, descendant = pcall(function()
			return part:IsDescendantOf(model)
		end)
		if okDesc and descendant then
			local okCollide, collide = pcall(function()
				return part.CanCollide
			end)
			local okSize, sx, sy = pcall(function()
				return part.Size.X, part.Size.Y
			end)
			if
				okCollide
				and collide == true
				and okSize
				and type(sx) == "number"
				and type(sy) == "number"
				and sx > 0.5
				and sy > 1.5
			then
				return false
			end
		end
	end
	return true
end

-- Front first, then back; prefer smaller X offsets and depth offsets. Returns the chosen position,
-- facade, and whether a genuinely clear spot was found (false means use the centre-front fallback
-- and fail the slot honestly).
local function findGaugePosition(probe: any, model: any, boxCFrame: any, boxSize: any): (any?, string, boolean)
	for _, facade in ipairs({ "front", "back" }) do
		for _, xOffset in ipairs(GAUGE_X_OFFSETS) do
			for _, depth in ipairs(GAUGE_DEPTH_OFFSETS) do
				local position = gaugePosition(boxCFrame, boxSize, facade, xOffset, depth)
				if position and gaugeIsClear(probe, model, position) then
					return position, facade, true
				end
			end
		end
	end
	return gaugePosition(boxCFrame, boxSize, "front", 0, 2), "front", false
end

local function tagParts(model: any, entry: any): boolean
	local ok, parts = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not parts then
		fail("could not enumerate parts for " .. tostring(entry.slot))
		return false
	end
	for _, part in ipairs(parts) do
		pcall(function()
			if part:IsA("BasePart") then
				part:SetAttribute(ModelMapBuildingsR8.tagAttribute, FAMILY_ID)
			end
		end)
	end
	return true
end

local function placeGauge(model: any, position: any?, facade: string, slotName: string): boolean
	if not position then
		fail("could not compute DoorGauge position for " .. slotName)
		return false
	end
	local gauge = ModelMapBuildingsR8.gauge
	local okCreate, part = pcall(function()
		return Instance.new("Part")
	end)
	if not okCreate or not part then
		fail("could not create DoorGauge for " .. slotName)
		return false
	end
	local okSet = pcall(function()
		part.Name = ModelMapBuildingsR8.gaugeName
		part.Size = Vector3.new(gauge.width, gauge.height, gauge.depth)
		part.CanCollide = false
		part.Transparency = 1
		part.Anchored = true
		part.Position = position
		part:SetAttribute(ModelMapBuildingsR8.tagAttribute, FAMILY_ID)
		part:SetAttribute(ModelMapBuildingsR8.slotAttribute, slotName)
		part:SetAttribute(ModelMapBuildingsR8.gaugeKindAttribute, "DoorClearance")
		part:SetAttribute(ModelMapBuildingsR8.facadeAttribute, facade)
		part.Parent = model
	end)
	if not okSet then
		pcall(function()
			part:Destroy()
		end)
		fail("could not configure DoorGauge for " .. slotName)
		return false
	end
	return true
end

local function stage(model: any, entry: any, x: number, z: number, probe: any): boolean
	local slotName = tostring(entry.slot)

	-- Scale FIRST: the staged bbox and the gauge both depend on the final size.
	if not pcall(function()
		model:ScaleTo(entry.scale)
	end) then
		fail("ScaleTo failed for " .. slotName)
		return false
	end
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not okPivot or not pivot then
		fail("could not read pivot for " .. slotName)
		return false
	end
	local boxCFrame, boxSize = worldBox(model)
	if not boxCFrame or not boxSize or boxSize.Y <= 0.01 then
		fail("invalid bounding box for " .. slotName)
		return false
	end
	if
		not pcall(function()
			model:PivotTo(CFrame.new(x, pivot.Y - boxCFrame.Position.Y + boxSize.Y * 0.5, z))
		end)
	then
		fail("could not place " .. slotName)
		return false
	end
	local placedBox, placedSize = worldBox(model)
	if not placedBox or not placedSize then
		fail("post-placement bounding box failed for " .. slotName)
		return false
	end

	-- Anchor parts after measurement. Authored CanCollide is deliberately PRESERVED: the harness's
	-- BLDG_DOOR check recomputes gauge-vs-collider overlap, so clearing colliders here would make
	-- the avatar-fit test vacuous. The gauge itself is the only non-collidable part we add.
	pcall(function()
		local parts = model:GetDescendants()
		for _, part in ipairs(parts) do
			pcall(function()
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end)
		end
	end)

	local position, facade, clear = findGaugePosition(probe, model, placedBox, placedSize)
	if not clear then
		fail("no clear DoorGauge opening for " .. slotName .. "; using centre-front")
	end
	if not placeGauge(model, position, facade, slotName) then
		return false
	end

	pcall(function()
		model:SetAttribute(ModelMapBuildingsR8.tagAttribute, FAMILY_ID)
		model:SetAttribute(ModelMapBuildingsR8.slotAttribute, slotName)
	end)
	tagParts(model, entry)

	local okPadBox, padBox, padSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if okPadBox and padBox and padSize then
		paintGroundPad(padBox, padSize)
	else
		fail("could not measure pad footprint for " .. slotName)
	end
	return true
end

local function setCameraAttributes(folder: any, centreX: number, centreZ: number)
	local rule = ModelMapBuildingsR8.cameraFor(centreX, centreZ)
	local ok, position, target = pcall(function()
		return Vector3.new(rule.position.x, rule.position.y, rule.position.z),
			Vector3.new(rule.target.x, rule.target.y, rule.target.z)
	end)
	if not ok or not position or not target then
		fail("could not build ReviewCamera vectors")
		return
	end
	cameraPos, cameraLook = position, target
	if
		not pcall(function()
			folder:SetAttribute(ModelMapBuildingsR8.cameraPosAttribute, position)
			folder:SetAttribute(ModelMapBuildingsR8.cameraLookAttribute, target)
		end)
	then
		fail("could not set camera attributes on staging folder")
	end
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		destroyProbe()
		local slots = ModelMapBuildingsR8.slots
		if type(slots) ~= "table" or #slots ~= 6 then
			fail("missing slot map for " .. FAMILY_ID)
			publishFailures()
			return
		end
		local previous = findPrevious()
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder()
		if not folder then
			publishFailures()
			return
		end
		activeFolder = folder
		local probe = createProbe()
		if not probe then
			destroyProbe()
			publishFailures()
			return
		end

		local centreX, centreZ = pickYard(treeTrunks(), folder)
		lastCentre = { x = centreX, z = centreZ }
		setCameraAttributes(folder, centreX, centreZ)
		local centres = ModelMapBuildingsR8.rowCentres(centreX)

		local okStaging = pcall(function()
			for index, entry in ipairs(slots) do
				local id = entry.id
				if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
					fail("missing or invalid asset ID for " .. FAMILY_ID .. "/" .. tostring(entry.slot))
					continue
				end
				local model = LookDevAssetLoader.get(id, FAMILY_ID)
				if not model then
					fail("asset load failed for " .. FAMILY_ID .. "/" .. tostring(entry.slot))
					continue
				end
				-- Parent BEFORE staging: gaugeIsClear uses workspace:GetPartsInPart, which sees no
				-- building parts while the model is still unparented and would accept the first
				-- ladder candidate. Fail the slot instead of staging an unparented model.
				if
					not pcall(function()
						model.Name = "R8_" .. entry.slot .. "_" .. index
						model.Parent = folder
					end)
				then
					fail("could not parent " .. tostring(entry.slot))
					continue
				end
				stage(model, entry, centres[index] or centreX, centreZ, probe)
			end
		end)
		if not okStaging then
			fail("staging pass aborted unexpectedly")
		end
		destroyProbe()
		publishFailures()
	end,

	restore = function()
		clearActive()
		destroyProbe()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		cameraPos, cameraLook, lastCentre = nil, nil, nil
	end,
}

-- Handoff: the saved camera for the last apply(), or the pure rule at the origin before one.
function LookDevBuildingsR8.camera(): (Vector3?, Vector3?)
	if cameraPos and cameraLook then
		return cameraPos, cameraLook
	end
	local ok, position, target = pcall(function()
		local rule = ModelMapBuildingsR8.cameraRule
		return Vector3.new(0, rule.up, rule.front), Vector3.new(0, rule.lookY, 0)
	end)
	if ok then
		return position, target
	end
	return nil, nil
end

function LookDevBuildingsR8.yard(): { x: number, z: number }?
	return lastCentre
end

LookDev.register(FAMILY_ID, applier)

return LookDevBuildingsR8
