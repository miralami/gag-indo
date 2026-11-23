--!strict
-- LookDevMeadowR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "meadow_r10" candidate
-- (WORK_QUEUE item 194). Flower and tall-grass patches on the open lawns between the Pasar ring and
-- the plots. Patch centres and item scatter come from Shared.ModelMapMeadowR10; every plant is a real
-- scripts-stripped baked Creator Store model fetched by LookDevAssetLoader, never procedural parts.
-- Zones are re-checked at apply time with live MapSpec geometry and tagged plot anchors. restore()
-- destroys only what this applier created and reattaches any prior folder.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevMeadowR10] missing service " .. name)
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
local okShared, sharedValue = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedValue then
	Shared = sharedValue
else
	warn("[LookDevMeadowR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, VegR5, TierThin, MapSpec = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapMeadowR10),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).ModelMapVegetationR5),
		require((Shared :: any).TierThin),
		require(script.Parent.MapSpec)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not VegR5 or not TierThin or not MapSpec then
	warn("[LookDevMeadowR10] could not require LookDev / ModelMapMeadowR10 / loader / zones / MapSpec")
	return {}
end

local ReviewCameras: any? = nil
local okReview, reviewValue = pcall(function()
	return require((Shared :: any).ReviewCameras)
end)
if okReview and reviewValue then
	ReviewCameras = reviewValue
end

local LookDevMeadowR10 = {}

local FAMILY_ID = Data.id
local GROUND_Y = if type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else Data.GROUND_Y
local activeFolder: any? = nil
local savedFolder: any? = nil
local loadedModels: { any } = {}
local failures = 0

local function publishFailures()
	pcall(function()
		require((Shared :: any).LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevMeadowR10] " .. message)
end

local function taggedFolder(name: string, parent: any): any?
	local folder: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Folder")
	end)
	if ok and created then
		folder = created
	end
	if not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder:SetAttribute("LookDevMeadowR10", FAMILY_ID)
		folder.Parent = parent
	end)
	return folder
end

-- World AABB from every descendant BasePart's CFrame + Size corners; Model:GetBoundingBox fallback.
local function bounds(root: any): (Vector3?, Vector3?)
	local mins: Vector3? = nil
	local maxs: Vector3? = nil
	local function account(part: any)
		local ok, cf, sz = pcall(function()
			return part.CFrame, part.Size
		end)
		if not ok or not cf or not sz then
			return
		end
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz2 in ipairs({ -1, 1 }) do
					local okCorner, corner = pcall(function()
						return cf * Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)
					end)
					if okCorner and corner then
						if not mins then
							mins, maxs = corner, corner
						else
							mins = Vector3.new(
								math.min(mins.X, corner.X),
								math.min(mins.Y, corner.Y),
								math.min(mins.Z, corner.Z)
							)
							maxs = Vector3.new(
								math.max(maxs.X, corner.X),
								math.max(maxs.Y, corner.Y),
								math.max(maxs.Z, corner.Z)
							)
						end
					end
				end
			end
		end
	end
	local okRoot, rootIsPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okRoot and rootIsPart then
		account(root)
	end
	local okDesc, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if okDesc and descendants then
		for _, instance in ipairs(descendants) do
			local okPart, isPart = pcall(function()
				return instance:IsA("BasePart")
			end)
			if okPart and isPart then
				account(instance)
			end
		end
	end
	if mins and maxs then
		return (mins + maxs) / 2, maxs - mins
	end
	local okBox, boxCFrame, boxSize = pcall(function()
		if root:IsA("Model") then
			return root:GetBoundingBox()
		end
		return nil, nil
	end)
	if okBox and boxCFrame and boxSize then
		return boxCFrame.Position, boxSize
	end
	return nil, nil
end

-- Strip untrusted code before collecting real baked geometry.
local function bakedParts(root: any): { any }
	local parts: { any } = {}
	local okRoot, rootIsPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okRoot and rootIsPart then
		parts[#parts + 1] = root
	end
	local okDesc, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if okDesc and descendants then
		for _, instance in ipairs(descendants) do
			pcall(function()
				if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
					instance:Destroy()
				elseif instance:IsA("BasePart") then
					parts[#parts + 1] = instance
				end
			end)
		end
	end
	return parts
end

local function tag(instance: any, item: any, assetId: number)
	pcall(function()
		instance:SetAttribute("MeadowPlant", true)
		instance:SetAttribute("MeadowAssetId", assetId)
		instance:SetAttribute("PatchIndex", item.PatchIndex)
		instance:SetAttribute("ItemIndex", item.ItemIndex)
		instance:SetAttribute("VegX", item.VegX)
		instance:SetAttribute("VegZ", item.VegZ)
		instance:SetAttribute("Species", item.species)
		instance:SetAttribute("Kind", "meadow_plant")
		instance:SetAttribute("LookDevMeadowR10", FAMILY_ID)
		instance:SetAttribute("LookDevStage", FAMILY_ID)
		if instance:IsA("BasePart") then
			instance.CanCollide = false
			instance.Anchored = true
		end
	end)
end

-- Component-wise scale to item.height (footprint capped by Data.MAX_FOOTPRINT), bbox bottom on
-- GROUND_Y, deterministic yaw. Only baked BaseParts are touched; no procedural geometry is made.
local function placeModel(model: any, item: any, parts: { any }): boolean
	local centre, size = bounds(model)
	if not centre or not size or size.Y <= 0 or #parts == 0 then
		return false
	end
	local sy = item.height / size.Y
	local span = math.max(size.X, size.Z)
	local sh = span > 0 and math.min(1, Data.MAX_FOOTPRINT / span) or 1
	local rot = CFrame.Angles(0, item.yaw, 0)
	local target = Vector3.new(item.x, GROUND_Y + item.height / 2, item.z)
	return pcall(function()
		for _, part in ipairs(parts) do
			local cf, partSize = part.CFrame, part.Size
			local offset = rot:VectorToWorldSpace((cf.Position - centre) * Vector3.new(sh, sy, sh))
			part.Size = Vector3.new(partSize.X * sh, partSize.Y * sy, partSize.Z * sh)
			part.CFrame = CFrame.new(target + offset) * rot * (cf - cf.Position)
			part.CanCollide = false
			part.Anchored = true
		end
	end)
end

local function plotRects(): { any }
	local out = {}
	local ok, anchors = pcall(function()
		return require(script.Parent.Map).all(require(script.Parent.Map).TAGS.PlotAnchor)
	end)
	if not ok or type(anchors) ~= "table" then
		return out
	end
	for _, anchor in ipairs(anchors) do
		local okPart, isPart = pcall(function()
			return anchor:IsA("BasePart")
		end)
		if okPart and isPart then
			local okSize, size = pcall(function()
				return anchor.Size
			end)
			local okPosition, position = pcall(function()
				return anchor.Position
			end)
			if okSize and okPosition and size and position then
				out[#out + 1] = {
					x = position.X,
					z = position.Z,
					halfX = size.X / 2,
					halfZ = size.Z / 2,
				}
			end
		end
	end
	return out
end

local function cameraEyeClear(patch: any): boolean
	if not ReviewCameras or type(ReviewCameras.all) ~= "function" then
		return true
	end
	local clear = ReviewCameras.clearDistance or 0
	local ok, cameras = pcall(function()
		return ReviewCameras.all()
	end)
	if not ok or type(cameras) ~= "table" then
		return true
	end
	for _, camera in ipairs(cameras) do
		local eye = camera.position
		if eye and math.abs(patch.x - eye[1]) <= clear and math.abs(patch.z - eye[3]) <= clear then
			return false
		end
	end
	return true
end

local function apply(plan)
	failures = 0
	loadedModels = {}
	if activeFolder then
		publishFailures()
		return
	end

	local previous: any? = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder: any? = nil
	local okNew, created = pcall(function()
		return Instance.new("Folder")
	end)
	if okNew and created then
		folder = created
		pcall(function()
			folder.Name = Data.folderName
			folder:SetAttribute("LookDevMeadowR10", FAMILY_ID)
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local zones: any = nil
	local okZones, builtZones = pcall(function()
		return VegR5.exclusionZones(MapSpec, plotRects())
	end)
	if okZones and type(builtZones) == "table" then
		zones = builtZones
	else
		fail("could not build live exclusion zones")
	end

	local plants = taggedFolder("MeadowPlants_meadow_r10", folder)
	local tier = plan and plan.tier
	local patchCount, itemCount = 0, 0
	for _, patch in ipairs(Data.patches()) do
		if not TierThin.shouldKeep(tier, patch.index) then
			continue
		end
		if not Data.zoneClear(patch.x, patch.z) or not cameraEyeClear(patch) then
			continue
		end
		if
			zones
			and not VegR5.pointAllowed(patch.x, patch.z, {
				halfX = patch.radius,
				halfZ = patch.radius,
			}, zones)
		then
			continue
		end
		patchCount += 1
		for _, item in ipairs(patch.items) do
			local assetId = Data.ids[item.species]
			if type(assetId) ~= "number" then
				fail("no asset ID for " .. tostring(item.species))
				continue
			end
			local okLoad, model = pcall(function()
				return LookDevAssetLoader.get(Data.ids[item.species], FAMILY_ID)
			end)
			if not okLoad or not model then
				fail("load failed for " .. item.species .. " (asset " .. tostring(assetId) .. ")")
				continue
			end
			loadedModels[#loadedModels + 1] = model
			local parts = bakedParts(model)
			tag(model, item, assetId)
			for _, part in ipairs(parts) do
				tag(part, item, assetId)
			end
			if not placeModel(model, item, parts) then
				fail("placement failed for " .. item.species .. " (asset " .. tostring(assetId) .. ")")
			end
			pcall(function()
				model.Name = "Meadow_" .. item.species .. "_" .. patch.index .. "_" .. item.ItemIndex
				model.Parent = plants or folder
			end)
			itemCount += 1
		end
	end
	if patchCount < Data.MIN_PATCHES then
		fail("only " .. patchCount .. " meadow patches staged")
	end
	if itemCount < Data.MIN_PATCHES * Data.MIN_ITEMS_PER_PATCH then
		fail("only " .. itemCount .. " meadow plants staged")
	end
	publishFailures()
end

local function restore()
	for _, model in ipairs(loadedModels) do
		pcall(function()
			model:Destroy()
		end)
	end
	loadedModels = {}
	if activeFolder then
		pcall(function()
			activeFolder:Destroy()
		end)
		activeFolder = nil
	end
	if savedFolder then
		pcall(function()
			savedFolder.Parent = Workspace
		end)
		savedFolder = nil
	end
end

LookDevMeadowR10.apply = apply
LookDevMeadowR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevMeadowR10
