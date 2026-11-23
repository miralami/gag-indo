--!strict
-- LookDevTerraceWallsQ214: SERVER-ONLY additive overlay for WORK_QUEUE item 271. The DEFAULT
-- single Block retaining wall from ModelMapTerraceWallsQ214.parts() is untouched. This applier
-- stages three low baked rock-model courses per wall, each stepping down along the terrace face,
-- using only the rocks_r9 IDs already recorded in ASSET_MANIFEST. OFF by default; restore is LIFO.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevTerraceWallsQ214] missing service " .. name)
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
	warn("[LookDevTerraceWallsQ214] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Loader, MapSpec = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapTerraceWallsQ214),
		require(script.Parent.LookDevAssetLoader),
		require(script.Parent.MapSpec)
end)
if not okModules or not LookDev or not Data or not Loader or not MapSpec then
	warn("[LookDevTerraceWallsQ214] could not require LookDev / ModelMapTerraceWallsQ214 / asset loader / MapSpec")
	return {}
end

local LookDevTerraceWallsQ214 = {}
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevTerraceWallsQ214] " .. message)
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

local function stageStep(def: any, parent: any): boolean
	local okLoad, model = pcall(function()
		return (Loader :: any).baked(def.assetId)
	end)
	if not okLoad or not model then
		fail("baked rock unavailable for step " .. tostring(def.name))
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
		fail("invalid baked rock bounds for step " .. tostring(def.name))
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
		fail("baked rock has no BasePart for step " .. tostring(def.name))
		return false
	end
	local scale = Vector3.new(def.sx / size.X, def.sy / size.Y, def.sz / size.Z)
	local target = Vector3.new(def.x, def.y, def.z)
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
			part:SetAttribute("StepTier", def.tier)
			part:SetAttribute("TopY", def.topY)
			part:SetAttribute("TerraceIndex", def.terrace)
			part:SetAttribute("ModelAssetId", def.assetId)
			part:SetAttribute("CandidateId", Data.id)
			part.Parent = parent
		end
	end)
	if not okStage then
		fail("could not stage baked step " .. tostring(def.name))
		return false
	end
	return true
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		local steps = Data.stepParts(MapSpec)
		if #steps < Data.MIN_WALLS * Data.STEP_COUNT then
			fail("only " .. #steps .. " step courses from MapSpec")
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
			made:SetAttribute("StepCount", #steps)
			return made
		end)
		if not okFolder or not folder then
			fail("could not create staging folder")
			return
		end
		activeFolder = folder
		staged[#staged + 1] = folder
		local placed = 0
		for _, def in ipairs(steps) do
			if stageStep(def, folder) then
				placed += 1
			end
		end
		pcall(function()
			folder:SetAttribute("PlacedSteps", placed)
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

LookDevTerraceWallsQ214.apply = applier.apply
LookDevTerraceWallsQ214.restore = applier.restore
LookDevTerraceWallsQ214.failures = function()
	return failures
end

LookDev.register(Data.id, applier)

return LookDevTerraceWallsQ214
