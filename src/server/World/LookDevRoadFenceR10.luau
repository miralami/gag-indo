--!strict
-- LookDevRoadFenceR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "road_fence_r10" candidate
-- (WORK_QUEUE item 201, rebuilt by item 262). Stages repeated baked bamboo-fence models (pick 1)
-- scaled to ~2.5 studs on grass-free road shoulders. Descriptors and shoulder bands come from
-- Shared.ModelMapRoadFenceR10; the real asset ID lives here. Every created instance and every terrain
-- snapshot is restored in LIFO order. apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("road_fence_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRoadFenceR10] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevRoadFenceR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures, LookDevAssetLoader = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRoadFenceR10),
		require((Shared :: any).LookDevFailures),
		require(script.Parent.LookDevAssetLoader)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevRoadFenceR10] could not require LookDev / ModelMapRoadFenceR10 / LookDevFailures")
	return {}
end

local LookDevRoadFenceR10 = {}

local FAMILY_ID = Data.id

-- Real pick-2 ID from ASSET_MANIFEST.md. Pick 1 `118708423521045` baked as an all-red "OOF!"
-- placeholder mesh (failed asset) that renders as red error boxes, so item 262 uses pick 2
-- `1158365955` (Chicao's Small Bamboo Fence, tan Union panels + dark posts). LookDevAssets is
-- empty for this id in an unbaked place, so only the baked() clone path is used: no runtime
-- LoadAsset, no invented IDs.
local ASSET_IDS: { [string]: number } = {
	fence_bamboo = 1158365955,
}

local TEXTURE_VOXEL = 4 -- Terrain authoring grid; ReadVoxels/WriteVoxels need this scalar resolution
local TEXTURE_Y0 = -TEXTURE_VOXEL
local TEXTURE_Y1 = TEXTURE_VOXEL * 8 -- grade through the shoulder; no fill, material only

local failures = 0
local active = false
local created: { any } = {}
local textureSaves: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevRoadFenceR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function stageFolder(): any?
	local okFind, existing = pcall(function()
		return (Workspace :: any):FindFirstChild((Data :: any).folderName)
	end)
	if not okFind then
		fail("could not look up staging folder: " .. tostring(existing))
		return nil
	end
	if existing then
		folder = existing
		return existing
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okNew or not instance then
		fail("could not create staging folder: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = (Data :: any).folderName
		instance.Parent = Workspace
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent staging folder: " .. tostring(why))
		return nil
	end
	created[#created + 1] = instance
	folder = instance
	return instance
end

local function setTags(part: any, descriptor: any, assetId: number)
	pcall(function()
		part:SetAttribute("RoadFence", true)
		part:SetAttribute("stretch", descriptor.stretch)
		part:SetAttribute("RoadFenceGroup", descriptor.group)
		part:SetAttribute("RoadFenceAssetId", assetId)
		part:SetAttribute("LookDevStage", FAMILY_ID)
	end)
end

local function bounds(instance: any)
	local ok, cframe, size = pcall(function()
		if instance:IsA("Model") then
			return instance:GetBoundingBox()
		end
		if instance:IsA("BasePart") then
			return instance.CFrame, instance.Size
		end
		return nil, nil
	end)
	if ok then
		return cframe, size
	end
	return nil, nil
end

local function scaleToHeight(instance: any, targetHeight: number): boolean
	local _, size = bounds(instance)
	local nativeY = if size and size.Y > 0 then size.Y else 1
	local factor = targetHeight / nativeY
	if factor <= 0 or factor > 10000 then
		return false
	end
	local ok = pcall(function()
		if instance:IsA("Model") then
			instance:ScaleTo(factor)
		elseif instance:IsA("BasePart") then
			instance.Size = instance.Size * factor
		end
	end)
	return ok
end

-- Baked models can still carry scripts and stale part flags. Strip LuaSourceContainers
-- defensively, neutralise every part and tag every descendant so the live checks can see the
-- real model signature rather than a hand-built Part proxy.
local function normaliseModel(model: any, descriptor: any, assetId: number)
	local okDescendants, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not okDescendants or type(descendants) ~= "table" then
		return
	end
	for _, child in ipairs(descendants) do
		pcall(function()
			if child:IsA("LuaSourceContainer") then
				child:Destroy()
			end
		end)
		-- Pick 1 bakes a broken "OOF!" MeshPart (a failed asset mesh, a flat 0.001-stud plane)
		-- that renders as a red error box. The real bamboo culms/rails are plain Parts, so drop
		-- any MeshPart with a near-zero axis — no valid fence geometry is lost.
		pcall(function()
			if child:IsA("MeshPart") then
				local s = child.Size
				if s.X < 0.01 or s.Y < 0.01 or s.Z < 0.01 then
					child:Destroy()
				end
			end
		end)
		local okBase, isBase = pcall(function()
			return child:IsA("BasePart")
		end)
		if okBase and isBase then
			pcall(function()
				child.Anchored = true
				child.CanCollide = false
				child.CastShadow = false
				child.CanQuery = true
			end)
			setTags(child, descriptor, assetId)
		end
	end
	pcall(function()
		model:SetAttribute("RoadFenceGroup", descriptor.group)
		model:SetAttribute("RoadFenceAssetId", assetId)
		model:SetAttribute("LookDevStage", FAMILY_ID)
		if model:IsA("BasePart") then
			model.Anchored = true
			model.CanCollide = false
			model.CastShadow = false
			setTags(model, descriptor, assetId)
		end
	end)
end

-- Put the model's bounding-box centre at the descriptor position (the review camera aims there),
-- with its long rails aligned to the road arm: local X maps to +X at angle 0 and to +Z at angle 90.
local function placeAt(model: any, descriptor: any)
	pcall(function()
		local desired = Vector3.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		local rotation = CFrame.Angles(0, math.rad(-descriptor.angle), 0)
		model:PivotTo(CFrame.new(desired) * rotation)
		local centre = select(1, model:GetBoundingBox()).Position
		local delta = desired - centre
		if delta.Magnitude > 0.0001 then
			model:PivotTo(model:GetPivot() + delta)
		end
	end)
end

local function stageModel(descriptor: any, parent: any): boolean
	if not LookDevAssetLoader then
		fail("LookDevAssetLoader unavailable for " .. tostring(descriptor.name))
		return false
	end
	local assetId = ASSET_IDS[descriptor.asset]
	if type(assetId) ~= "number" then
		fail("no baked asset for " .. tostring(descriptor.asset))
		return false
	end
	local okLoad, model = pcall(function()
		return (LookDevAssetLoader :: any).baked(assetId)
	end)
	if not okLoad or not model then
		fail("baked fence model missing for " .. tostring(assetId))
		return false
	end
	if not scaleToHeight(model, descriptor.height) then
		pcall(function()
			model:Destroy()
		end)
		fail("could not scale " .. tostring(descriptor.name))
		return false
	end
	normaliseModel(model, descriptor, assetId)
	placeAt(model, descriptor)
	local okParent, why = pcall(function()
		model.Name = descriptor.name
		model.Parent = parent
	end)
	if not okParent then
		pcall(function()
			model:Destroy()
		end)
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
		return false
	end
	created[#created + 1] = model
	return true
end

local function terrainOf(): any?
	if not Workspace then
		return nil
	end
	local ok, terrain = pcall(function()
		return (Workspace :: any):FindFirstChildOfClass("Terrain")
	end)
	return ok and terrain or nil
end

-- Snap outward to the 4-stud grid so ReadVoxels and WriteVoxels address the same cells.
local function shoulderRegion(patch: any): any?
	local ok, region = pcall(function()
		local minX = math.floor(patch.minX / TEXTURE_VOXEL) * TEXTURE_VOXEL
		local maxX = math.ceil(patch.maxX / TEXTURE_VOXEL) * TEXTURE_VOXEL
		local minZ = math.floor(patch.minZ / TEXTURE_VOXEL) * TEXTURE_VOXEL
		local maxZ = math.ceil(patch.maxZ / TEXTURE_VOXEL) * TEXTURE_VOXEL
		return Region3.new(Vector3.new(minX, TEXTURE_Y0, minZ), Vector3.new(maxX, TEXTURE_Y1, maxZ))
	end)
	return ok and region or nil
end

-- Item 262 / 255: repaint Grass shoulder voxels as Ground so the fence reads from road level.
-- Read the exact materials AND occupancies, clone the material grid, change only Grass cells with
-- occupancy > 0, then write both grids back. Occupancy is never changed. The untouched snapshot is
-- saved for a byte-exact LIFO restore.
local function paintShoulder(terrain: any, patch: any)
	local region = shoulderRegion(patch)
	if not region then
		fail("shoulder region failed at " .. tostring(patch.name))
		return
	end
	local okRead, materials, occupancies = pcall(function()
		return terrain:ReadVoxels(region, TEXTURE_VOXEL)
	end)
	if not okRead or type(materials) ~= "table" or type(occupancies) ~= "table" then
		fail("shoulder ReadVoxels failed at " .. tostring(patch.name))
		return
	end
	local painted = {}
	local okPaint = pcall(function()
		for ix, slab in ipairs(materials) do
			local outSlab = {}
			painted[ix] = outSlab
			for iy, row in ipairs(slab) do
				local outRow = {}
				outSlab[iy] = outRow
				local occRow = occupancies[ix] and occupancies[ix][iy]
				for iz, material in ipairs(row) do
					local occupancy = occRow and occRow[iz]
					local grass = material == Enum.Material.Grass or material == Enum.Material.LeafyGrass
					if occupancy ~= nil and occupancy > 0 and grass then
						outRow[iz] = Enum.Material.Ground
					else
						outRow[iz] = material
					end
				end
			end
		end
	end)
	if not okPaint then
		fail("shoulder material build failed at " .. tostring(patch.name))
		return
	end
	local okWrite = pcall(function()
		terrain:WriteVoxels(region, TEXTURE_VOXEL, painted, occupancies)
	end)
	if not okWrite then
		fail("shoulder WriteVoxels failed at " .. tostring(patch.name))
		return
	end
	textureSaves[#textureSaves + 1] = {
		terrain = terrain,
		region = region,
		materials = materials,
		occupancies = occupancies,
	}
end

local function restoreShoulder()
	for index = #textureSaves, 1, -1 do
		local entry = textureSaves[index]
		pcall(function()
			entry.terrain:WriteVoxels(entry.region, TEXTURE_VOXEL, entry.materials, entry.occupancies)
		end)
		textureSaves[index] = nil
	end
end

local function apply(_plan: any)
	if active then
		publishFailures()
		return
	end
	failures = 0
	pcall(function()
		LookDevFailures.reset(FAMILY_ID)
	end)

	stageFolder()
	local root = folder
	if root then
		local okParts, parts = pcall(function()
			return (Data :: any).parts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read fence descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stageModel(descriptor, root)
			end
		end
	end

	local terrain = terrainOf()
	if not terrain then
		fail("missing Terrain; shoulder grass not repainted")
	else
		local okPatches, patches = pcall(function()
			return (Data :: any).shoulderPatches()
		end)
		if not okPatches or type(patches) ~= "table" then
			fail("could not read shoulder patches: " .. tostring(patches))
		else
			for _, patch in ipairs(patches) do
				paintShoulder(terrain, patch)
			end
		end
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #created == 0 and #textureSaves == 0 then
		return
	end
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	restoreShoulder()
	folder = nil
	active = false
	publishFailures()
end

LookDevRoadFenceR10.apply = apply
LookDevRoadFenceR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevRoadFenceR10
