--!strict
-- LookDevCropStagesGoldenQ247: SERVER-ONLY additive overlay for WORK_QUEUE item 271. Restages the
-- three item-247 crop stages in a golden-ripe palette and gives the "siap" stage the already-baked
-- padi mesh (ASSET_MANIFEST slot `padi_model`). No new candidate id, no registry count change, no
-- change to crop_stages_r10. OFF by default; restore is LIFO; no place save or publish.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevCropStagesGoldenQ247] missing service " .. name)
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
	warn("[LookDevCropStagesGoldenQ247] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Base, Loader, Sawah = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapCropStagesGoldenQ247),
		require((Shared :: any).ModelMapCropStagesR10),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).ModelMapSawahR8)
end)
if not okModules or not LookDev or not Data or not Base or not Loader or not Sawah then
	warn(
		"[LookDevCropStagesGoldenQ247] could not require LookDev / ModelMapCropStagesGoldenQ247 / base stages / asset loader"
	)
	return {}
end

local PADI_ID = Sawah.PADI_ASSET_ID

local LookDevCropStagesGoldenQ247 = {}
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevCropStagesGoldenQ247] " .. message)
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

local function shapeFor(name: string): any
	if name == "Wedge" then
		return Enum.PartType.Wedge
	end
	return Enum.PartType.Cylinder
end

local function stagePrimitive(descriptor: any, sample: any, parent: any)
	local okPart, part = pcall(function()
		local made = Instance.new("Part")
		made.Name = descriptor.name
		made.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		local position, rotation = descriptor.position, descriptor.rotation or { 0, 0, 0 }
		made.CFrame = CFrame.new(position[1], position[2], position[3])
			* CFrame.Angles(rotation[1], rotation[2], rotation[3])
		made.Shape = shapeFor(descriptor.shape)
		made.Color = Color3.fromRGB(sample.color.r, sample.color.g, sample.color.b)
		made.Anchored = true
		made.CanCollide = false
		made.CanQuery = false
		made.CastShadow = false
		made:SetAttribute("CropStage", true)
		made:SetAttribute("GoldenStage", true)
		made:SetAttribute("stage", sample.stage)
		made:SetAttribute("StageRole", descriptor.role)
		made:SetAttribute("CandidateId", Data.id)
		return made
	end)
	if not okPart or not part then
		fail("could not stage golden part " .. tostring(descriptor.name))
		return
	end
	staged[#staged + 1] = part
	pcall(function()
		part.Parent = parent
	end)
end

-- Baked padi, scaled to the golden stage's declared width/height. The mesh keeps its baked
-- geometry; only scripts are removed (the loader already strips them, this is belt-and-braces).
local function stageRipeModel(sample: any, parent: any)
	local okLoad, model = pcall(function()
		return (Loader :: any).baked(PADI_ID)
	end)
	if not okLoad or not model then
		fail("baked padi unavailable for the golden ripe stage")
		return
	end
	staged[#staged + 1] = model
	pcall(function()
		(Loader :: any).stripScripts(model)
	end)
	local okBox, centre, size = pcall(function()
		return (model :: any):GetBoundingBox()
	end)
	if not okBox or not centre or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		fail("invalid baked padi bounds for the golden ripe stage")
		return
	end
	-- GetBoundingBox returns (CFrame centre, Vector3 size); arithmetic needs the Vector3 position.
	local centrePos = centre.Position
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
		fail("baked padi has no BasePart for the golden ripe stage")
		return
	end
	local scale = Vector3.new(
		Data.MODEL_TARGET_WIDTH / size.X,
		Data.MODEL_TARGET_HEIGHT / size.Y,
		Data.MODEL_TARGET_WIDTH / size.Z
	)
	local stem = sample.parts[1].position
	local target = Vector3.new(stem[1], Base.GROUND_Y + Data.MODEL_TARGET_HEIGHT / 2, stem[3])
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
			part.Color = Color3.fromRGB(sample.color.r, sample.color.g, sample.color.b)
			part:SetAttribute("CropStage", true)
			part:SetAttribute("GoldenStage", true)
			part:SetAttribute("stage", sample.stage)
			part:SetAttribute("StageRole", "model")
			part:SetAttribute("ModelAssetId", PADI_ID)
			part:SetAttribute("CandidateId", Data.id)
			part.Parent = parent
		end
	end)
	if not okStage then
		fail("could not stage baked padi for the golden ripe stage")
	end
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		local samples = Data.samples()
		if #samples == 0 then
			fail("no golden stage descriptors")
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
			made:SetAttribute("StageCount", #samples)
			return made
		end)
		if not okFolder or not folder then
			fail("could not create staging folder")
			return
		end
		activeFolder = folder
		staged[#staged + 1] = folder
		for _, sample in ipairs(samples) do
			for _, descriptor in ipairs(sample.parts) do
				stagePrimitive(descriptor, sample, folder)
			end
			if sample.modelSource == Data.MODEL_SOURCE then
				stageRipeModel(sample, folder)
			end
		end
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

LookDevCropStagesGoldenQ247.apply = applier.apply
LookDevCropStagesGoldenQ247.restore = applier.restore
LookDevCropStagesGoldenQ247.failures = function()
	return failures
end

LookDev.register(Data.id, applier)

return LookDevCropStagesGoldenQ247
