--!strict
-- LookDevRiverFoamQ212: SERVER-ONLY additive overlay for WORK_QUEUE item 271. Reworks the sprint-3
-- "floating" foam: every strip is centred on the live river water surface from ModelMapRiverR8 and
-- uses the baked padi mesh published as ModelMapRiverFoamQ212.MODEL_ID, squashed into a thin foam
-- line. ponytail: the manicured lily pad (5044238410) is not baked; the designer must bake it into
-- ServerStorage.LookDevAssets before MODEL_ID can point at it. Nothing is on by default;
-- LookDev.register is a no-op until the main session registers the candidate id, and the harness
-- stages/restores the applier directly. No place save, no publish.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRiverFoamQ212] missing service " .. name)
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
	warn("[LookDevRiverFoamQ212] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Loader, RiverR8 = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRiverFoamQ212),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).ModelMapRiverR8)
end)
if not okModules or not LookDev or not Data or not Loader or not RiverR8 then
	warn("[LookDevRiverFoamQ212] could not require LookDev / ModelMapRiverFoamQ212 / asset loader")
	return {}
end

-- Baked provenance lives in the pure data module; the applier never invents an ID.
local FOAM_MODEL_ID = Data.MODEL_ID

local LookDevRiverFoamQ212 = {}
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevRiverFoamQ212] " .. message)
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

-- Component-wise scale of a baked mesh into a 16 x 0.08 x 0.8 foam strip. The mesh's own pivot is
-- irrelevant: every descendant is repositioned relative to the bake's bounding-box centre.
local function stageStrip(def: any, parent: any): boolean
	local okLoad, model = pcall(function()
		return (Loader :: any).baked(FOAM_MODEL_ID)
	end)
	if not okLoad or not model then
		fail("baked foam model unavailable for " .. tostring(def.name))
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
		fail("invalid baked foam bounds for " .. tostring(def.name))
		return false
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
		fail("baked foam has no BasePart for " .. tostring(def.name))
		return false
	end
	local scale = Vector3.new(def.size[1] / size.X, def.size[2] / size.Y, def.size[3] / size.Z)
	local target = Vector3.new(def.x, Data.FOAM_Y, def.z)
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
			part.Material = Enum.Material.SmoothPlastic
			part.Transparency = Data.TRANSPARENCY
			part:SetAttribute(Data.TAG, true)
			part:SetAttribute(Data.KIND_ATTR, def.kind)
			part:SetAttribute("ModelAssetId", FOAM_MODEL_ID)
			part:SetAttribute("CandidateId", Data.id)
			part:SetAttribute("FoamOnWater", true)
			part.Parent = parent
		end
	end)
	if not okStage then
		fail("could not stage baked foam for " .. tostring(def.name))
		return false
	end
	return true
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
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
			made:SetAttribute("WaterSurfaceY", RiverR8.WATER_SURFACE_Y)
			return made
		end)
		if not okFolder or not folder then
			fail("could not create staging folder")
			return
		end
		activeFolder = folder
		staged[#staged + 1] = folder
		local stagedStrips = 0
		for _, def in ipairs(Data.parts()) do
			if stageStrip(def, folder) then
				stagedStrips += 1
			end
		end
		pcall(function()
			folder:SetAttribute("FoamStrips", stagedStrips)
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

LookDevRiverFoamQ212.apply = applier.apply
LookDevRiverFoamQ212.restore = applier.restore
LookDevRiverFoamQ212.failures = function()
	return failures
end

LookDev.register(Data.id, applier) -- no-op until the id is added to LookDev.IDS by the main session

return LookDevRiverFoamQ212
