--!strict
-- LookDevHubPropsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "hubprops_r8" candidate
-- (WORK_QUEUE section M item 79). Main.server wires the candidate; this file only registers it.
--
-- Every recipe comes from Shared.ModelMapHubPropsR8 and is placed in the live MapSpec.hub(key)
-- frame (hubPoint + hub.yaw), never at a hardcoded world position. Creator Store props come from
-- LookDevAssetLoader.get(id, "hubprops_r8") (baked clone first, LoadAsset only as its fallback);
-- step-(2) agent-generated props clone ServerStorage.LookDevAssets.<folder> directly with no ID and
-- no LoadAsset. Scripts are stripped, GetBoundingBox is measured and the model is non-uniformly
-- scaled to the recipe's real-world target before it is anchored. Procedural props are assembled
-- from the recipe's anchored Parts. Each prop is one Model named <HubKey>_<PropKind> under one
-- sub-Folder per hub, inside Workspace.LookDevHubPropsR8_hubprops_r8.
--
-- A small Ground voxel pad is painted under every prop's bbox: the reviewer's HUBPROPS_ON_GRASS
-- check samples TERRAIN at GRASS_Y=4, so a decorative base Part alone would not clear it. Before
-- each fill the exact grid-aligned voxel region (materials + occupancy + water mask) is read back;
-- restore writes those arrays over the same region so Terrain is byte-for-byte unchanged after
-- disable, with no drift across repeated apply/restore cycles. Every game API is pcall-guarded;
-- any missing recipe/hub/asset/voxel-snapshot pads the failure counter and is warned loudly, and a
-- hub is never silently skipped. Restore destroys the staged folder and restores the exact previous
-- folder. Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("hubprops_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevHubPropsR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local ServerStorage = service("ServerStorage")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevHubPropsR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapHubPropsR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not LookDevFailures then
	warn("[LookDevHubPropsR8] could not require LookDev / ModelMapHubPropsR8 / LookDevAssetLoader / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevHubPropsR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevHubPropsR8 = {}

local FAMILY_ID: string = Data.familyId
local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
-- Exact Terrain voxels overwritten by each Ground pad, restored byte-for-byte on disable.
local savedVoxels: { any } = {}

local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }
local SHAPE_NAMES = { Block = "Block", Cylinder = "Cylinder", Ball = "Ball", Wedge = "Wedge" }

local function fail(message: string)
	failures += 1
	warn("[LookDevHubPropsR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

local function stripScripts(root: any): boolean
	local ok, list = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or type(list) ~= "table" then
		return false
	end
	for _, instance in ipairs(list) do
		local okClass, className = pcall(function()
			return instance.ClassName
		end)
		if okClass and SCRIPT_CLASSES[className] then
			pcall(function()
				instance:Destroy()
			end)
		end
	end
	return true
end

local function partsOf(root: any): { any }
	local out = {} :: { any }
	local okSelf, isPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okSelf and isPart then
		out[#out + 1] = root
	end
	local ok, list = pcall(function()
		return root:GetDescendants()
	end)
	if ok and type(list) == "table" then
		for _, instance in ipairs(list) do
			local okPart, part = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and part then
				out[#out + 1] = instance
			end
		end
	end
	return out
end

local function worldBox(instance: any): (any?, any?)
	local ok, boxCFrame, size = pcall(function()
		return instance:GetBoundingBox()
	end)
	if
		not ok
		or not boxCFrame
		or not size
		or size.X ~= size.X
		or size.Y ~= size.Y
		or size.Z ~= size.Z
		or size.X <= 0
		or size.Y <= 0
		or size.Z <= 0
	then
		return nil, nil
	end
	return boxCFrame, size
end

-- Non-uniform scale around the measured bounding-box centre: each part's Size AND its offset from
-- that centre are multiplied per axis, so the staged bbox reaches the recipe's real-world target.
local function scaleModelToTarget(instance: any, target: { number }, label: string): boolean
	local boxCFrame, size = worldBox(instance)
	if not boxCFrame or not size then
		fail("invalid bounding box for " .. label)
		return false
	end
	local sx, sy, sz = target[1] / size.X, target[2] / size.Y, target[3] / size.Z
	local centre = boxCFrame.Position
	local ok = pcall(function()
		for _, part in ipairs(partsOf(instance)) do
			local beforeSize, beforeCFrame = part.Size, part.CFrame
			local position = beforeCFrame.Position
			local rotation = beforeCFrame - position
			part.Size = Vector3.new(beforeSize.X * sx, beforeSize.Y * sy, beforeSize.Z * sz)
			part.CFrame = CFrame.new(
				centre.X + (position.X - centre.X) * sx,
				centre.Y + (position.Y - centre.Y) * sy,
				centre.Z + (position.Z - centre.Z) * sz
			) * rotation
		end
	end)
	if not ok then
		fail("non-uniform scale failed for " .. label)
		return false
	end
	local _, after = worldBox(instance)
	if not after then
		fail("post-scale bounding box failed for " .. label)
		return false
	end
	local worst = math.max(
		math.abs(after.X - target[1]) / target[1],
		math.abs(after.Y - target[2]) / target[2],
		math.abs(after.Z - target[3]) / target[3]
	)
	if worst > 0.25 then
		fail("scaled bbox missed target by " .. string.format("%.0f%%", worst * 100) .. " for " .. label)
		return false
	end
	return true
end

-- Place by bbox bottom so the prop sits on the Ground pad, and correct the pivot-to-centre offset
-- so the recipe's local (lx,lz) lands on the prop's visual centre rather than its raw pivot.
local function placeModel(instance: any, hub: any, recipe: any, bottomY: number, label: string): boolean
	local okPoint, x, z = pcall(function()
		return MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
	end)
	local okPivot, pivot = pcall(function()
		return instance:GetPivot()
	end)
	local boxCFrame, size = worldBox(instance)
	if not okPoint or not okPivot or not pivot or not boxCFrame or not size then
		fail("could not measure placement for " .. label)
		return false
	end
	local offset = boxCFrame.Position - pivot.Position
	local angle = math.rad(hub.yaw + (recipe.yaw or 0))
	local cos, sin = math.cos(angle), math.sin(angle)
	local worldOffsetX = offset.X * cos + offset.Z * sin
	local worldOffsetZ = -offset.X * sin + offset.Z * cos
	local okPlace = pcall(function()
		instance:PivotTo(
			CFrame.new(x - worldOffsetX, bottomY + size.Y / 2 - offset.Y, z - worldOffsetZ) * CFrame.Angles(0, angle, 0)
		)
	end)
	if not okPlace then
		fail("could not place " .. label)
		return false
	end
	return true
end

local function anchorParts(instance: any, label: string)
	local ok = pcall(function()
		for _, part in ipairs(partsOf(instance)) do
			pcall(function()
				part.Anchored = true
				part.CanCollide = false
			end)
		end
	end)
	if not ok then
		fail("could not anchor parts for " .. label)
	end
end

-- ReadVoxels/WriteVoxels need grid-aligned bounds and matching resolution: Terrain's authoring grid
-- is 4 studs, so every region corner is snapped with the same math.floor(v / 4) * 4 rule the
-- studio harness uses. Snap OUTWARD so the snapshot covers every voxel FillBlock can touch, with a
-- one-cell minimum on each axis. Materials, occupancy and water mask are all saved so restore is
-- byte-for-byte exact and repeated apply/restore cycles never drift.
local VOXEL = if MapSpec then (MapSpec.TERRAIN_VOXEL or 4) else 4

local function voxelRegion(cx: number, cy: number, cz: number, sx: number, sy: number, sz: number): any
	local minX = math.floor((cx - sx / 2) / VOXEL) * VOXEL
	local maxX = math.ceil((cx + sx / 2) / VOXEL) * VOXEL
	local minY = math.floor((cy - sy / 2) / VOXEL) * VOXEL
	local maxY = math.ceil((cy + sy / 2) / VOXEL) * VOXEL
	local minZ = math.floor((cz - sz / 2) / VOXEL) * VOXEL
	local maxZ = math.ceil((cz + sz / 2) / VOXEL) * VOXEL
	if maxX - minX < VOXEL then
		maxX = minX + VOXEL
	end
	if maxY - minY < VOXEL then
		maxY = minY + VOXEL
	end
	if maxZ - minZ < VOXEL then
		maxZ = minZ + VOXEL
	end
	return Region3.new(Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ))
end

local function savePadVoxels(terrain: any, region: any, label: string): boolean
	local ok, materials, occupancies, waterMask = pcall(function()
		return terrain:ReadVoxels(region, VOXEL)
	end)
	if not ok or type(materials) ~= "table" or type(occupancies) ~= "table" then
		fail("ReadVoxels snapshot failed for " .. label)
		return false
	end
	savedVoxels[#savedVoxels + 1] = {
		terrain = terrain,
		region = region,
		materials = materials,
		occupancies = occupancies,
		waterMask = waterMask,
		label = label,
	}
	return true
end

local function restoreSavedVoxels()
	-- LIFO: neighbouring pads can overlap, so a later snapshot may contain an earlier pad's Ground.
	-- Writing snapshots back in reverse leaves every cell exactly as it was before the first fill.
	for index = #savedVoxels, 1, -1 do
		local entry = savedVoxels[index]
		local ok = pcall(function()
			entry.terrain:WriteVoxels(entry.region, VOXEL, entry.materials, entry.occupancies, entry.waterMask)
		end)
		if not ok then
			fail("WriteVoxels restore failed for " .. tostring(entry.label))
		end
	end
	table.clear(savedVoxels)
end

local function paintGroundPad(instance: any, label: string)
	if not MapSpec or not Workspace then
		fail("missing MapSpec/Workspace; Ground pad skipped for " .. label)
		return
	end
	local terrain = (Workspace :: any):FindFirstChildOfClass("Terrain")
	if not terrain then
		fail("missing Terrain; Ground pad skipped for " .. label)
		return
	end
	local boxCFrame, size = worldBox(instance)
	if not boxCFrame or not size then
		fail("could not measure pad footprint for " .. label)
		return
	end
	local bottom = MapSpec.GROUND_Y - MapSpec.TERRAIN_VOXEL
	local cy, sy = MapSpec.volumeForTop(bottom, MapSpec.GROUND_Y)
	local cap = MapSpec.MAX_FILL_SPAN or 40
	local px = boxCFrame.Position.X
	local pz = boxCFrame.Position.Z
	local sx = math.min(size.X + Data.padMargin, cap)
	local sz = math.min(size.Z + Data.padMargin, cap)
	local region = voxelRegion(px, cy, pz, sx, sy, sz)
	-- Never paint a pad we cannot restore byte-for-byte: an unsnapshotted fill would leak Terrain.
	if not savePadVoxels(terrain, region, label) then
		return
	end
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(px, cy, pz), Vector3.new(sx, sy, sz), Enum.Material.Ground)
	end)
	if not ok then
		fail("Ground pad FillBlock failed for " .. label)
	end
end

local function newPropModel(hubKey: string, recipe: any, folder: any): any?
	local ok, prop = pcall(function()
		return Instance.new("Model")
	end)
	if not ok or not prop then
		fail("could not create prop Model for " .. hubKey .. "/" .. tostring(recipe.kind))
		return nil
	end
	track(prop)
	local okSet = pcall(function()
		prop.Name = hubKey .. "_" .. recipe.kind
		prop:SetAttribute(Data.PROP_ATTRIBUTE, true)
		prop:SetAttribute(Data.HUB_ATTRIBUTE, hubKey)
		prop:SetAttribute(Data.KIND_ATTRIBUTE, recipe.kind)
		prop:SetAttribute(Data.SOURCE_ATTRIBUTE, recipe.source)
		prop.Parent = folder
	end)
	if not okSet then
		fail("could not configure prop Model for " .. hubKey .. "/" .. tostring(recipe.kind))
		return nil
	end
	return prop
end

-- Step-(2) D15 geometry is baked by the main session under ServerStorage.LookDevAssets.<folder>.
-- Clone it directly: there is no Creator Store asset ID and LoadAsset must never be called for it.
local function generatedModel(folderName: string, label: string): any?
	if not ServerStorage then
		fail("missing ServerStorage; generated model unavailable for " .. label)
		return nil
	end
	local okRoot, root = pcall(function()
		return (ServerStorage :: any):FindFirstChild("LookDevAssets")
	end)
	if not okRoot or not root then
		fail("missing LookDevAssets for generated model " .. label)
		return nil
	end
	local okSource, source = pcall(function()
		return root:FindFirstChild(folderName)
	end)
	if not okSource or not source then
		fail("missing baked generated folder " .. folderName .. " for " .. label)
		return nil
	end
	local okClone, clone = pcall(function()
		return source:Clone()
	end)
	if not okClone or not clone then
		fail("could not clone generated model " .. folderName .. " for " .. label)
		return nil
	end
	return clone
end

local function stageBaked(hub: any, hubKey: string, recipe: any, folder: any): boolean
	local label = hubKey .. "/" .. tostring(recipe.kind)
	local generated: string? = nil
	if recipe.baked ~= nil then
		if type(recipe.baked) ~= "string" or not Data.ALLOWED_GENERATED[recipe.baked] then
			fail("baked recipe uses an unverified generated folder for " .. label)
			return false
		end
		generated = recipe.baked
	elseif type(recipe.id) ~= "number" or not Data.ALLOWED_IDS[recipe.id] then
		fail("baked recipe uses an unverified ID for " .. label)
		return false
	end
	if type(recipe.target) ~= "table" or #recipe.target ~= 3 then
		fail("missing target bbox for " .. label)
		return false
	end
	local model = if generated then generatedModel(generated, label) else LookDevAssetLoader.get(recipe.id, FAMILY_ID)
	if not model then
		fail("asset load failed for " .. label)
		return false
	end
	if not stripScripts(model) then
		fail("could not strip scripts for " .. label)
		return false
	end
	if not scaleModelToTarget(model, recipe.target, label) then
		return false
	end
	local prop = newPropModel(hubKey, recipe, folder)
	if not prop then
		return false
	end
	if not pcall(function()
		model.Parent = prop
	end) then
		fail("could not parent baked model for " .. label)
		return false
	end
	track(model)
	anchorParts(model, label)
	if not placeModel(model, hub, recipe, MapSpec.GROUND_Y + Data.baseOffset, label) then
		return false
	end
	paintGroundPad(prop, label)
	return true
end

local function stageProcedural(hub: any, hubKey: string, recipe: any, folder: any): boolean
	local label = hubKey .. "/" .. tostring(recipe.kind)
	if type(recipe.parts) ~= "table" or #recipe.parts == 0 then
		fail("missing procedural parts for " .. label)
		return false
	end
	local prop = newPropModel(hubKey, recipe, folder)
	if not prop then
		return false
	end
	local okPoint, x, z = pcall(function()
		return MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
	end)
	if not okPoint then
		fail("could not resolve hub point for " .. label)
		return false
	end
	local angle = math.rad(hub.yaw + (recipe.yaw or 0))
	local okBase, base = pcall(function()
		return CFrame.new(x, MapSpec.GROUND_Y + Data.baseOffset, z) * CFrame.Angles(0, angle, 0)
	end)
	if not okBase or not base then
		fail("could not build base CFrame for " .. label)
		return false
	end
	for _, descriptor in ipairs(recipe.parts) do
		local ok = pcall(function()
			local created = Instance.new("Part")
			created.Name = descriptor.name
			local shape = ((Enum :: any).PartType)[SHAPE_NAMES[descriptor.shape] or "Block"]
			created.Shape = shape
			created.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
			created.CFrame = base * CFrame.new(descriptor.offset[1], descriptor.offset[2], descriptor.offset[3])
			created.Color = Color3.fromRGB(descriptor.color[1], descriptor.color[2], descriptor.color[3])
			created.Material = ((Enum :: any).Material)[descriptor.material] or Enum.Material.SmoothPlastic
			created.Anchored = true
			created.CanCollide = false
			created.Parent = prop
			track(created)
		end)
		if not ok then
			fail("could not stage part " .. tostring(descriptor.name) .. " for " .. label)
		end
	end
	paintGroundPad(prop, label)
	return true
end

local function stageHub(hubKey: string, folder: any): boolean
	local entry = Data.recipes[hubKey]
	if type(entry) ~= "table" or #entry < Data.minPropsPerHub or #entry > Data.maxPropsPerHub then
		fail("missing or out-of-range recipe list for " .. hubKey)
		return false
	end
	if not MapSpec then
		fail("missing MapSpec for " .. hubKey)
		return false
	end
	local okHub, hub = pcall(function()
		return MapSpec.hub(hubKey)
	end)
	if not okHub or not hub then
		fail("no MapSpec hub for " .. hubKey)
		return false
	end
	local hubFolder = newFolder(hubKey, folder)
	if not hubFolder then
		fail("could not create folder for " .. hubKey)
		return false
	end
	track(hubFolder)
	pcall(function()
		hubFolder:SetAttribute(Data.HUB_ATTRIBUTE, hubKey)
	end)
	local ok = true
	local names = {} :: { [string]: boolean }
	for _, recipe in ipairs(entry) do
		if type(recipe.name) ~= "string" or type(recipe.kind) ~= "string" or names[recipe.name] then
			fail("duplicate or invalid recipe for " .. hubKey)
			ok = false
		else
			names[recipe.name] = true
			local stagedOk = if recipe.source == "baked"
				then stageBaked(hub, hubKey, recipe, hubFolder)
				elseif recipe.source == "procedural" then stageProcedural(hub, hubKey, recipe, hubFolder)
				else false
			if not stagedOk then
				fail("unknown recipe source for " .. hubKey .. "/" .. tostring(recipe.kind))
				ok = false
			end
		end
	end
	return ok
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(FAMILY_ID)
		end)
		restoreSavedVoxels()
		clearActive()
		if not Workspace then
			fail("missing Workspace")
			publishFailures()
			return
		end
		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)
		for _, hubKey in ipairs(Data.HUB_KEYS) do
			stageHub(hubKey, folder)
		end
		publishFailures()
	end,

	restore = function()
		restoreSavedVoxels()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		publishFailures()
	end,
}

LookDevHubPropsR8.apply = applier.apply
LookDevHubPropsR8.restore = applier.restore

LookDev.register(FAMILY_ID, applier)

return LookDevHubPropsR8
