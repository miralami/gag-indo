--!strict
-- LookDevSawahDressingQ215: SERVER-ONLY additive overlay for WORK_QUEUE item 271. The DEFAULT
-- primitive gubuk/scarecrow/ribbon dressing stays as authored; this stages a baked nipa hut per
-- terrace plus baked padi accents so the sawah reads properly. Only IDs already in ASSET_MANIFEST
-- and sibling ModelMaps are used. OFF by default; restore is LIFO; nothing is saved or published.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSawahDressingQ215] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevSawahDressingQ215] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Loader, MapSpec = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSawahDressingQ215),
		require(script.Parent.LookDevAssetLoader),
		require(script.Parent.MapSpec)
end)
if not okModules or not LookDev or not Data or not Loader or not MapSpec then
	warn("[LookDevSawahDressingQ215] could not require LookDev / ModelMapSawahDressingQ215 / asset loader / MapSpec")
	return {}
end

-- ponytail: the real nipa hut (167594119) is not baked; the baked house stands in at small scale
-- until the designer bakes the hut. Padi accents reuse the baked padi from crop_stages_r10.
local MODEL_IDS = {
	nipa_hut = Data.BAKED_IDS.gubuk_model,
	padi_model = Data.BAKED_IDS.padi_accent,
}

local LookDevSawahDressingQ215 = {}
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevSawahDressingQ215] " .. message)
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

local function stageModel(def: any, parent: any): boolean
	local assetId = MODEL_IDS[def.modelSource]
	if type(assetId) ~= "number" then
		fail("unknown baked model source " .. tostring(def.modelSource))
		return false
	end
	local okLoad, model = pcall(function()
		return (Loader :: any).baked(assetId)
	end)
	if not okLoad or not model then
		fail("baked model unavailable for " .. tostring(def.name))
		return false
	end
	staged[#staged + 1] = model
	pcall(function()
		(Loader :: any).stripScripts(model)
	end)
	local okBox, centre, size = pcall(function()
		return (model :: any):GetBoundingBox()
	end)
	if not okBox or not centre or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		fail("invalid baked bounds for " .. tostring(def.name))
		return false
	end
	-- GetBoundingBox returns (CFrame centre, Vector3 size); arithmetic needs the Vector3 position.
	local centrePos = centre.Position
	local depth = if def.kind == "gubuk_model" then def.targetWidth * 0.75 else def.targetWidth
	local scale = Vector3.new(def.targetWidth / size.X, def.targetHeight / size.Y, depth / size.Z)
	local target = Vector3.new(def.x, def.y + def.targetHeight / 2, def.z)
	local parts = {}
	local okParts, descendants = pcall(function()
		return (model :: any):GetDescendants()
	end)
	if okParts and type(descendants) == "table" then
		for _, part in ipairs(descendants) do
			local isPart = false
			pcall(function()
				isPart = part:IsA("BasePart")
			end)
			if isPart then
				parts[#parts + 1] = part
			end
		end
	end
	if #parts == 0 then
		fail("baked model has no BasePart for " .. tostring(def.name))
		return false
	end
	local okStage = pcall(function()
		for _, part in ipairs(parts) do
			local cf, partSize = part.CFrame, part.Size
			local offset = cf.Position - centrePos
			part.Size = Vector3.new(partSize.X * scale.X, partSize.Y * scale.Y, partSize.Z * scale.Z)
			part.CFrame = CFrame.new(target + Vector3.new(offset.X * scale.X, offset.Y * scale.Y, offset.Z * scale.Z))
				* cf.Rotation
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CastShadow = false
			part:SetAttribute(Data.TAG, true)
			part:SetAttribute(Data.KIND_ATTR, def.kind)
			part:SetAttribute(Data.GROUP_ATTR, def.group)
			part:SetAttribute("ModelAssetId", assetId)
			part:SetAttribute("CandidateId", Data.id)
			part.Parent = parent
		end
	end)
	if not okStage then
		fail("could not stage baked model for " .. tostring(def.name))
		return false
	end
	return true
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		local defs = Data.modelParts(MapSpec.paddyWater())
		if #defs == 0 then
			fail("no sawah dressing descriptors from MapSpec")
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
		local okFolder, folder = pcall(function()
			local made = Instance.new("Folder")
			made.Name = Data.folderName
			made.Parent = Workspace
			made:SetAttribute("CandidateId", Data.id)
			made:SetAttribute("ModelParts", #defs)
			return made
		end)
		if not okFolder or not folder then
			fail("could not create staging folder")
			return
		end
		activeFolder = folder
		staged[#staged + 1] = folder
		local placed = 0
		for _, def in ipairs(defs) do
			if stageModel(def, folder) then
				placed += 1
			end
		end
		pcall(function()
			folder:SetAttribute("PlacedModels", placed)
		end)
	end,

	restore = function()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
	end,
}

LookDevSawahDressingQ215.apply = applier.apply
LookDevSawahDressingQ215.restore = applier.restore
LookDevSawahDressingQ215.failures = function()
	return failures
end

LookDev.register(Data.id, applier)

return LookDevSawahDressingQ215
