--!strict
-- LookDevModelsVegetationHubR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "hubveg_r8" candidate
-- (WORK_QUEUE section M item 70). Enable from the Studio Server command bar; restore() destroys
-- only the folder this candidate created and reattaches any prior folder.
--
-- Every slot and every asset key comes from Shared.ModelMapVegetationHubR8, which reuses R7's
-- verified IDs. Assets are fetched clone-first via LookDevAssetLoader (ServerStorage.LookDevAssets
-- -> LoadAsset fallback ONLY inside the loader). Static and tagged-plot exclusion zones are
-- re-evaluated at apply time, so a baked slot that lands in a newly tagged plot is skipped.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsVegetationHubR8] missing service " .. name)
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
	warn("[LookDevModelsVegetationHubR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapVegetationHubR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not TierThin then
	warn(
		"[LookDevModelsVegetationHubR8] could not require LookDev / ModelMapVegetationHubR8 / LookDevAssetLoader / TierThin"
	)
	return {}
end

local GROUND_Y = 0.5
local okSpec, MapSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and type(MapSpec) == "table" and type(MapSpec.GROUND_Y) == "number" then
	GROUND_Y = MapSpec.GROUND_Y
end

local LookDevModelsVegetationHubR8 = {}

local FAMILY_ID = "hubveg_r8"
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
	warn("[LookDevModelsVegetationHubR8] " .. message)
end

local function folderName(): string
	return Data.folderName
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

local function placeAndScale(model: any, slot: any)
	local _, boxSize = bounds(model)
	local bodyY = if boxSize and boxSize.Y > 0 then boxSize.Y else 1
	local factor = slot.targetHeight / bodyY
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

	-- Measured bbox centre after ScaleTo, not the pivot: baked assets such as kembang sepatu
	-- have their geometry offset up to ~33 studs from the pivot. Carry that offset (rotated
	-- by the slot yaw) so the bbox centre lands on the slot with its base on GROUND_Y.
	local bboxCFrame, bboxSize = bounds(model)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	local rot = CFrame.Angles(slot.rotX or 0, slot.ry, 0)
	local target: CFrame
	if bboxCFrame and bboxSize and okPivot and pivot then
		local offset = bboxCFrame.Position - pivot.Position
		local rotatedOffset = rot:VectorToWorldSpace(offset)
		local bboxCentre = Vector3.new(slot.x, GROUND_Y + bboxSize.Y * 0.5, slot.z)
		target = CFrame.new(bboxCentre - rotatedOffset) * rot
	else
		target = CFrame.new(slot.x, GROUND_Y + (bboxSize and bboxSize.Y or 1) * 0.5, slot.z) * rot
	end
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

-- Item-144 grouped slots: one anchor Model per pisang group / bamboo clump, with each culm or
-- banana plant as its own tagged child Model. The harness counts children (not the empty anchor)
-- and reads HubVegGroup / HubVegGroupKind / HubVegCulmHeight from them.
-- ponytail: Rendah keeps <=50% of decorative vegetation; the first two HubVegTree anchors per hub
-- are structural. Upgrade by making protection data-driven if more protected kinds appear.
local function stageGroup(slot: any, modelId: number, folder: any, tier: any?, counter: { value: number }): number
	local anchor: any? = nil
	local okAnchor, created = pcall(function()
		return Instance.new("Model")
	end)
	if not okAnchor or not created then
		fail("could not create group anchor for " .. tostring(slot.group))
		return 0
	end
	anchor = created
	pcall(function()
		anchor.Name = "R8_Group_" .. tostring(slot.group)
		anchor:SetAttribute("LookDevHubVegR8", FAMILY_ID)
		anchor:SetAttribute("Hub", slot.hub)
		anchor:SetAttribute("Species", slot.species)
		anchor:SetAttribute("HubVegGroupAnchor", true)
		anchor:SetAttribute("HubVegGroup", slot.group)
		anchor:SetAttribute("HubVegGroupKind", slot.groupKind)
		anchor.Parent = folder
	end)

	local placed = 0
	for memberIndex, member in ipairs(slot.members or {}) do
		counter.value += 1
		if TierThin.shouldKeep(tier, counter.value + 1) then
			local okLoad, memberModel = pcall(function()
				return LookDevAssetLoader.get(modelId, FAMILY_ID)
			end)
			if not okLoad or not memberModel then
				fail("group member load failed for " .. tostring(slot.group) .. " #" .. memberIndex)
				continue
			end
			pcall(function()
				memberModel.Name = "R8_" .. tostring(slot.hub) .. "_" .. tostring(slot.groupKind) .. "_" .. memberIndex
				memberModel:SetAttribute("LookDevHubVegR8", FAMILY_ID)
				memberModel:SetAttribute("Hub", slot.hub)
				memberModel:SetAttribute("Species", slot.species)
				memberModel:SetAttribute("HubVegGroup", slot.group)
				memberModel:SetAttribute("HubVegGroupKind", slot.groupKind)
				if slot.groupKind == "bambu" then
					memberModel:SetAttribute("HubVegCulmHeight", member.targetHeight)
				end
			end)
			placeAndScale(memberModel, member)
			pcall(function()
				memberModel.Parent = anchor
			end)
			placed += 1
		end
	end
	if placed == 0 and tier ~= "Rendah" then
		fail("no group members placed for " .. tostring(slot.group))
	end
	return placed
end

local function apply(plan: any?)
	failures = 0
	local tier: any? = if plan then plan.tier else nil
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
	local counter = { value = 0 }
	local treeSeen = {}
	for _, slot in ipairs(Data.slots()) do
		local okSlot, allowed = pcall(function()
			return Data.slotAllowed(slot, zones)
		end)
		if not okSlot or not allowed then
			continue
		end
		local modelId = Data.ids[slot.slot]
		if type(modelId) ~= "number" or modelId <= 0 then
			fail("no asset ID for " .. tostring(slot.hub) .. "/" .. tostring(slot.species))
			continue
		end
		local structural = false
		if slot.kind == "tree" then
			treeSeen[slot.hub] = (treeSeen[slot.hub] or 0) + 1
			structural = treeSeen[slot.hub] <= 2
		end
		if not structural then
			counter.value += 1
		end
		if TierThin.shouldKeep(tier, counter.value + 1, structural) then
			if slot.kind == "pisang_group" or slot.kind == "bambu_clump" then
				placed += stageGroup(slot, modelId, folder, tier, counter)
			else
				-- Clone-first retrieval; the loader owns the LoadAsset fallback and its own counter.
				local okLoad, model = pcall(function()
					return LookDevAssetLoader.get(modelId, FAMILY_ID)
				end)
				if not okLoad or not model then
					fail(
						"load failed for "
							.. tostring(slot.hub)
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
					model.Name = "R8_" .. tostring(slot.hub) .. "_" .. tostring(slot.species) .. "_" .. slot.index
					model:SetAttribute("LookDevHubVegR8", FAMILY_ID)
					model:SetAttribute("Hub", slot.hub)
					model:SetAttribute("Species", slot.species)
					if slot.kind == "tree" then
						model:SetAttribute("HubVegTree", true)
						model:SetAttribute("HubVegTreeHeight", slot.targetHeight)
					end
				end)
				placeAndScale(model, slot)
				pcall(function()
					model.Parent = folder
				end)
				placed += 1
			end
		end
	end
	if placed == 0 and tier ~= "Rendah" then
		fail("no per-hub vegetation placed; check the Edit-mode asset bake")
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

LookDevModelsVegetationHubR8.apply = apply
LookDevModelsVegetationHubR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevModelsVegetationHubR8
