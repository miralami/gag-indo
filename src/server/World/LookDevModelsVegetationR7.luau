--!strict
-- LookDevModelsVegetationR7: SERVER-ONLY applier for the OFF-BY-DEFAULT "vegetation_r7"
-- candidate (WORK_QUEUE section K item 58). Enable from the Studio Server command bar;
-- restore() destroys only the folder this candidate created and reattaches any prior folder.
--
-- Every ID comes from Shared.ModelMapVegetationR7, which references only the already-approved R4
-- CC BY vegetation IDs and the real R6 Creator Store shortlist. Assets are fetched clone-first via
-- LookDevAssetLoader (ServerStorage.LookDevAssets -> LoadAsset fallback ONLY inside the loader).
-- Any missing ID, failed load or missing model increments the shared failure counter and warns.
-- Placement, random yaw, +/-15% scale jitter, species tags and the pure cone helper come from data.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsVegetationR7] missing service " .. name)
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
	warn("[LookDevModelsVegetationR7] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapVegetationR7),
		require(script.Parent.LookDevAssetLoader)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader then
	warn("[LookDevModelsVegetationR7] could not require LookDev / ModelMapVegetationR7 / LookDevAssetLoader")
	return {}
end

local LookDevModelsVegetationR7 = {}

local FAMILY_ID = "vegetation_r7"
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

-- The Studio check reads the same counter in the Server VM. Publish on every exit path.
local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevModelsVegetationR7] " .. message)
end

local function folderName(): string
	return "LookDevModelsVegetationR7_" .. FAMILY_ID
end

-- A baked asset may be a Model OR a single BasePart/MeshPart (teh-tehan is a MeshPart).
-- GetBoundingBox and ScaleTo exist only on Model, so both bounds and scaling have to branch.
local function bounds(root: any): (CFrame?, Vector3?)
	local ok, centre, size = pcall(function()
		if root:IsA("Model") then
			return root:GetBoundingBox()
		end
		if root:IsA("BasePart") then
			return root.CFrame, root.Size
		end
		return nil, nil
	end)
	if ok then
		return centre, size
	end
	return nil, nil
end

-- Jitter is baked into slot.targetHeight; this only scales and grounds the model. VEG_NEAR needs a
-- >=2-stud bbox, so near slots get a floor even if a future data edit lowers their base height.
local MIN_NEAR_HEIGHT = 2.05

local function placeAndScale(model: any, slot: any)
	local _, boxSize = bounds(model)
	local bodyY = if boxSize and boxSize.Y > 0 then boxSize.Y else 1
	local targetHeight = if slot.nearGround then math.max(slot.targetHeight, MIN_NEAR_HEIGHT) else slot.targetHeight
	local factor = targetHeight / bodyY
	local scaled = false
	if model:IsA("Model") then
		scaled = pcall(function()
			model:ScaleTo(factor)
		end)
	elseif model:IsA("BasePart") then
		scaled = pcall(function()
			model.Size = model.Size * factor
		end)
	end
	if not scaled then
		fail("ScaleTo failed for " .. tostring(slot.species))
	end

	local okDescendants, parts = pcall(function()
		return model:GetDescendants()
	end)
	if okDescendants and parts then
		for _, part in ipairs(parts) do
			pcall(function()
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end)
		end
	end

	local y = 0
	local bottomCFrame, bottomSize = bounds(model)
	if bottomCFrame and bottomSize then
		local okPivot, pivot = pcall(function()
			return model:GetPivot()
		end)
		if okPivot and pivot then
			y = pivot.Y - bottomCFrame.Y + bottomSize.Y * 0.5
		end
	end
	local target = CFrame.new(slot.x, y, slot.z) * CFrame.Angles(slot.rotX or 0, slot.ry, 0)
	if pcall(function()
		model:PivotTo(target)
	end) then
		return
	end
	pcall(function()
		model:SetPrimaryPartCFrame(target)
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
				table.insert(out, {
					x = position.X,
					z = position.Z,
					halfX = size.X / 2,
					halfZ = size.Z / 2,
				})
			end
		end
	end
	return out
end

local function apply()
	failures = 0
	if activeFolder then
		return
	end

	local previous: any? = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(folderName())
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
			folder.Name = folderName()
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local okZones, zones = pcall(function()
		return Data.exclusionZones(require(script.Parent.MapSpec), plotRects())
	end)
	if not okZones or type(zones) ~= "table" then
		fail("could not build exclusion zones")
		publishFailures()
		return
	end

	local placed = 0
	for _, group in ipairs(Data.groups) do
		for index, slot in ipairs(group.slots) do
			local okSlot, allowed = pcall(function()
				return Data.slotAllowed(slot, zones)
			end)
			if not okSlot or not allowed then
				continue
			end
			local modelId = Data.ids[slot.slot]
			if type(modelId) ~= "number" or modelId <= 0 then
				fail("no asset ID for " .. group.id .. "/" .. tostring(slot.species))
				continue
			end
			-- Clone-first retrieval; the loader owns the LoadAsset fallback and its own counter.
			local okLoad, model = pcall(function()
				return LookDevAssetLoader.get(modelId, FAMILY_ID)
			end)
			if not okLoad or not model then
				fail(
					"load failed for "
						.. group.id
						.. "/"
						.. tostring(slot.species)
						.. " (asset "
						.. tostring(modelId)
						.. "): "
						.. tostring(model)
				)
				continue
			end
			pcall(function()
				model.Name = "R7_" .. group.id .. "_" .. tostring(slot.species) .. "_" .. index
				model:SetAttribute("LookDevR7", FAMILY_ID)
				model:SetAttribute("Species", slot.species)
				if slot.nearGround then
					model:SetAttribute("NearGround", true)
				end
			end)
			placeAndScale(model, slot)
			pcall(function()
				model.Parent = folder
			end)
			placed += 1
		end
	end
	if placed == 0 then
		fail("no vegetation placed; check the Edit-mode asset bake")
	end
	publishFailures()
end

local function restore()
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

-- Pure helper mirroring the Studio VEG_COUNT/VEG_SPECIES contract.
function LookDevModelsVegetationR7.countInCone()
	return Data.countInCone()
end

LookDevModelsVegetationR7.apply = apply
LookDevModelsVegetationR7.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevModelsVegetationR7
