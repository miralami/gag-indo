-- LookDevModelsVegetationR6: SERVER-ONLY applier for the OFF-BY-DEFAULT round-6
-- "vegetation_r6" candidate (WORK_QUEUE section J item 47). InsertService:LoadAsset works in the
-- Server datamodel but is blocked on the client, so require this from Main.server.luau and toggle
-- with the Server datamodel selected: LookDev.enable("vegetation_r6").
--
-- Every ID comes from Shared.ModelMapVegetationR6 (R4 ids via require plus the real Creator Store
-- shortlist literals in that data module). No ID literal lives here. Zone rectangles and margins
-- come from the data module too. By default only `staged` clips in the saved camera band at the
-- Rendah tier are loaded; setTier("Sedang"|"Tinggi") and setIncludeUnstaged(true) widen the plan.
-- The Folder exists only while enabled; restore() destroys it and reattaches any prior folder.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapVegetationR6 = require(Shared.ModelMapVegetationR6)
local MapSpec = require(script.Parent.MapSpec)
local Map = require(script.Parent.Map)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LookDevFailures = require(Shared.LookDevFailures)
local LookDevAssetLoader = require(script.Parent.LookDevAssetLoader)

local LookDevModelsVegetationR6 = {}

local active: any = nil
local saved: any = nil
local selectedTier = "Rendah"
local includeUnstaged = false

function LookDevModelsVegetationR6.setTier(tier: string): string
	if ModelMapVegetationR6.tierRank(tier) > 0 then
		selectedTier = tier
	end
	return selectedTier
end

function LookDevModelsVegetationR6.setIncludeUnstaged(flag: boolean): boolean
	includeUnstaged = flag == true
	return includeUnstaged
end

local function plotRects()
	local out = {}
	local ok, anchors = pcall(function()
		return Map.all(Map.TAGS.PlotAnchor)
	end)
	if not ok or type(anchors) ~= "table" then
		return out
	end
	for _, anchor in ipairs(anchors) do
		local isPart, isBasePart = pcall(function()
			return anchor:IsA("BasePart")
		end)
		if isPart and isBasePart then
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

-- Scale to the slot's target stud height, anchor every BasePart, disable collision, rotate and drop
-- the bounding-box bottom onto y=0. Identical to the proven R5 transform; every engine call is
-- pcall'd so a malformed asset can never break the toggle.
local function placeAndScale(model: any, slot: any)
	local bodyY = 1
	local okBox, _, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if okBox and boxSize and boxSize.Y > 0 then
		bodyY = boxSize.Y
	end
	local scaleOk = pcall(function()
		model:ScaleTo(slot.targetHeight / bodyY)
	end)
	if not scaleOk then
		warn("[LookDevModelsVegetationR6] ScaleTo failed for " .. tostring(slot.slot))
	end

	local anchored, parts = pcall(function()
		return model:GetDescendants()
	end)
	if anchored and parts then
		for _, part in ipairs(parts) do
			local isPart = pcall(function()
				return part:IsA("BasePart")
			end)
			if isPart then
				pcall(function()
					part.Anchored = true
					part.CanCollide = false
				end)
			end
		end
	end

	local y = 0
	local okBottom, bottomCFrame, bottomSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if okBottom and bottomCFrame and bottomSize then
		local pivotOk, pivot = pcall(function()
			return model:GetPivot()
		end)
		if pivotOk and pivot then
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

local function tierAllowed(tier)
	local rank = ModelMapVegetationR6.tierRank(tier)
	return rank > 0 and rank <= ModelMapVegetationR6.tierRank(selectedTier)
end

local function apply()
	if active then
		return
	end
	local name = ModelMapVegetationR6.folderName
	local okFind, previous = pcall(function()
		return Workspace:FindFirstChild(name)
	end)
	if okFind and previous then
		-- Detach, not Destroy: restore() puts this exact pre-existing folder back.
		pcall(function()
			previous.Parent = nil
		end)
		saved = previous
	end

	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return
	end
	pcall(function()
		folder.Name = name
		folder.Parent = Workspace
	end)
	active = folder

	local zones = ModelMapVegetationR6.exclusionZones(MapSpec, plotRects())
	for _, group in ipairs(ModelMapVegetationR6.groups) do
		if group.staged or includeUnstaged then
			for index, slot in ipairs(group.slots) do
				if not tierAllowed(group.tier) then
					continue
				end
				if not ModelMapVegetationR6.slotAllowed(slot, zones) then
					continue
				end
				local modelId = ModelMapVegetationR6.ids[slot.slot]
				if type(modelId) ~= "number" or modelId <= 0 then
					LookDevFailures.add("vegetation_r6", 1)
					warn("[LookDevModelsVegetationR6] no asset ID for " .. group.id .. "/" .. slot.slot)
					continue
				end
				-- Legacy runtime path was InsertService:LoadAsset(modelId); loader clones the bake first.
				local model = LookDevAssetLoader.get(modelId, "vegetation_r6")
				if not model then
					warn(
						"[LookDevModelsVegetationR6] LoadAsset failed for "
							.. group.id
							.. "/"
							.. slot.slot
							.. ": "
							.. tostring(model)
					)
				else
					pcall(function()
						model.Name = "R6_" .. group.id .. "_" .. slot.slot .. "_" .. index
					end)
					placeAndScale(model, slot)
					pcall(function()
						model.Parent = folder
					end)
				end
			end
		end
	end
end

local function restore()
	if active then
		-- The folder created by this candidate and every model under it are removed exactly here.
		pcall(function()
			active:Destroy()
		end)
		active = nil
	end
	if saved then
		pcall(function()
			saved.Parent = Workspace
		end)
		saved = nil
	end
end

LookDev.register("vegetation_r6", { apply = apply, restore = restore })

return LookDevModelsVegetationR6
