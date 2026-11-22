-- LookDevModelsVegetationR5: SERVER-ONLY applier for the OFF-BY-DEFAULT round-5
-- "vegetation_r5" candidate (WORK_QUEUE item 37). InsertService:LoadAsset works in the Server
-- datamodel but is blocked on the client, so require this from Main.server.luau and toggle with the
-- Server datamodel selected: LookDev.enable("vegetation_r5").
--
-- Every ID comes from Shared.ModelMapVegetationR5 (which reads the real R4 IDs). No ID literal is
-- embedded here. Plot rectangles come from Map.TAGS.PlotAnchor parts; path/hub/open zones and all
-- margins come from the data module. A slot whose footprint overlaps any zone is skipped before
-- LoadAsset. The dedicated Folder exists only while enabled; restore() destroys it.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapVegetationR5 = require(Shared.ModelMapVegetationR5)
local MapSpec = require(script.Parent.MapSpec)
local Map = require(script.Parent.Map)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LookDevFailures = require(Shared.LookDevFailures)
local LookDevAssetLoader = require(script.Parent.LookDevAssetLoader)

local LookDevModelsVegetationR5 = {}

local active: any = nil
local saved: any = nil

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

-- Scale the loaded body to the slot's target stud height, anchor every BasePart, disable collision,
-- rotate and drop its bounding-box bottom onto y=0. Every engine call is pcall'd: a malformed asset
-- must never break the toggle. Same proven pattern as LookDevModelsVegetationR4.
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
		warn("[LookDevModelsVegetationR5] ScaleTo failed for " .. tostring(slot.slot))
	end

	local anchored, parts = pcall(function()
		return model:GetDescendants()
	end)
	if anchored and parts then
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") then
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

local function apply()
	if active then
		return
	end
	local name = ModelMapVegetationR5.folderName
	local previous = Workspace:FindFirstChild(name)
	if previous then
		-- Detach, not Destroy: restore() puts this exact pre-existing folder back.
		previous.Parent = nil
		saved = previous
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	active = folder

	local zones = ModelMapVegetationR5.exclusionZones(MapSpec, plotRects())
	for _, group in ipairs(ModelMapVegetationR5.groups) do
		for index, slot in ipairs(group.slots) do
			if not ModelMapVegetationR5.slotAllowed(slot, zones) then
				continue
			end
			local modelId = ModelMapVegetationR5.ids[slot.slot]
			if type(modelId) ~= "number" or modelId <= 0 then
				-- No ID means no LoadAsset: never invent a stand-in ID.
				LookDevFailures.add("vegetation_r5", 1)
				warn("[LookDevModelsVegetationR5] no asset ID for " .. group.id .. "/" .. slot.slot)
				continue
			end
			-- Legacy runtime path was InsertService:LoadAsset(modelId); loader clones the bake first.
			local model = LookDevAssetLoader.get(modelId, "vegetation_r5")
			if not model then
				warn(
					"[LookDevModelsVegetationR5] LoadAsset failed for "
						.. group.id
						.. "/"
						.. slot.slot
						.. ": "
						.. tostring(model)
				)
			else
				model.Name = "R5_" .. group.id .. "_" .. slot.slot .. "_" .. index
				placeAndScale(model, slot)
				model.Parent = folder
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

LookDev.register("vegetation_r5", { apply = apply, restore = restore })

return LookDevModelsVegetationR5
