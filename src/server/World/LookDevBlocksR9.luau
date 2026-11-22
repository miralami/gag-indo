--!strict
-- LookDevBlocksR9: SERVER-ONLY applier for the OFF-BY-DEFAULT "blocks_r9" candidate
-- (WORK_QUEUE section O item 145). Enable from the Studio Server command bar with LookDevReview;
-- restore() destroys only the folder this candidate created and reattaches any prior folder.
--
-- Slots and asset keys come from Shared.ModelMapBlocksR9 (R7's verified IDs only). Assets are
-- fetched clone-first via LookDevAssetLoader (ServerStorage.LookDevAssets -> LoadAsset fallback
-- ONLY inside the loader). Static zones plus live tagged PlotAnchors are re-evaluated at apply
-- time. Every staged part is anchored and non-collidable, so none of the six hub-door corridors
-- used by PATH_REACH / AVATAR_FIT is narrowed.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevBlocksR9] missing service " .. name)
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
	warn("[LookDevBlocksR9] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, MapSpec = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapBlocksR9),
		require(script.Parent.LookDevAssetLoader),
		require(script.Parent.MapSpec)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not MapSpec then
	warn("[LookDevBlocksR9] could not require LookDev / ModelMapBlocksR9 / LookDevAssetLoader / MapSpec")
	return {}
end

local FAMILY_ID = "blocks_r9"
local GROUND_Y = if type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

local LookDevBlocksR9 = {}

local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevBlocksR9] " .. message)
end

-- This Studio has no GetBoundingBox on plain Parts; branch Model and BasePart explicitly.
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

local function placeAndScale(model: any, slot: any)
	local _, nativeSize = bounds(model)
	local nativeY = if nativeSize and nativeSize.Y > 0 then nativeSize.Y else 1
	local factor = slot.height / nativeY
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
		fail("scale failed for " .. tostring(slot.species))
	end

	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if okParts and parts then
		for _, part in ipairs(parts) do
			pcall(function()
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end)
		end
	end

	-- Carry the measured bbox-centre offset (rotated by slot yaw) so the slot lands at the
	-- instance's centre with its base on GROUND_Y, even for assets with an off-centre pivot.
	local bboxCFrame, bboxSize = bounds(model)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	local rot = CFrame.Angles(0, slot.yaw, 0)
	local target: CFrame
	if bboxCFrame and bboxSize and okPivot and pivot then
		local rotatedOffset = rot:VectorToWorldSpace(bboxCFrame.Position - pivot.Position)
		local centre = Vector3.new(slot.x, GROUND_Y + bboxSize.Y * 0.5, slot.z)
		target = CFrame.new(centre - rotatedOffset) * rot
	else
		target = CFrame.new(slot.x, GROUND_Y + (bboxSize and bboxSize.Y or 1) * 0.5, slot.z) * rot
	end
	if not pcall(function()
		model:PivotTo(target)
	end) then
		pcall(function()
			model:SetPrimaryPartCFrame(target)
		end)
	end
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
		return Data.exclusionZones(plotRects())
	end)
	if not okZones or type(zones) ~= "table" then
		fail("could not build exclusion zones")
		publishFailures()
		return
	end

	local placed, bandTrees = 0, 0
	for _, slot in ipairs(Data.slots()) do
		local okSlot, allowed = pcall(function()
			return Data.slotAllowed(slot, zones)
		end)
		if not okSlot or not allowed then
			continue
		end
		local modelId = Data.ids[slot.slot]
		if type(modelId) ~= "number" or modelId <= 0 then
			fail("no asset ID for " .. tostring(slot.species))
			continue
		end
		local okLoad, model = pcall(function()
			return LookDevAssetLoader.get(modelId, FAMILY_ID)
		end)
		if not okLoad or not model then
			fail("load failed for " .. tostring(slot.species) .. " (asset " .. tostring(modelId) .. ")")
			continue
		end
		pcall(function()
			model.Name = "R9_" .. slot.kind .. "_" .. tostring(slot.species) .. "_" .. slot.index
			model:SetAttribute("LookDevBlocksR9", FAMILY_ID)
			model:SetAttribute("BlockSpecies", slot.species)
			model:SetAttribute("BlockKind", slot.kind)
			model:SetAttribute("BlockHeight", slot.height)
			model:SetAttribute("BlockYaw", slot.yaw)
			model:SetAttribute("BlockScale", slot.scale)
			if slot.kind == "tree" then
				model:SetAttribute("BlockTree", true)
				model:SetAttribute("BlockTreeHeight", slot.height)
			else
				model:SetAttribute("BlockShrub", true)
			end
			-- Item 182 markers: the village-ring band and the baked alang-alang grass dressing.
			-- Both are derived from the accepted slot, not invented IDs or measured screenshots.
			local radius = math.sqrt(slot.x * slot.x + slot.z * slot.z)
			if radius >= Data.BAND_MIN_RADIUS and radius <= Data.BAND_MAX_RADIUS then
				model:SetAttribute("BlockBand", true)
				if slot.kind == "tree" then
					bandTrees += 1
				end
			end
			if slot.species == "alang_alang" then
				model:SetAttribute("BlockGrass", true)
			end
		end)
		placeAndScale(model, slot)
		pcall(function()
			model.Parent = folder
		end)
		placed += 1
	end
	if placed < Data.MIN_TREES + Data.MIN_SHRUBS then
		fail("too few block plants staged: " .. tostring(placed))
	end
	if bandTrees < Data.MIN_BAND_TREES then
		fail("too few village-ring trees staged: " .. tostring(bandTrees))
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

LookDevBlocksR9.apply = apply
LookDevBlocksR9.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevBlocksR9
