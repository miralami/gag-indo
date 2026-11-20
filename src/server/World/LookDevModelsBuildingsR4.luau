-- LookDevModelsBuildingsR4: SERVER-ONLY applier for the OFF-BY-DEFAULT `buildings_r4`
-- candidate (WORK_QUEUE round 4 item 31). InsertService:LoadAsset is blocked on the client,
-- so this module must be required from Main.server.luau and toggled from the Studio command
-- bar with the Server datamodel selected. Every engine call is pcall'd; no asset ID literal
-- lives here (all IDs come from Shared.ModelMapBuildingsR4).
--
-- Real CC0 textured GLBs are staged on MapSpec terrain near SPAWN, normalised with ScaleTo
-- to each slot's targetHeight, anchored, made non-colliding, and rotated by rotX + ry.

local ReplicatedStorageOk, ReplicatedStorage = pcall(function()
	return game:GetService("ReplicatedStorage")
end)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local InsertServiceOk, _InsertService = pcall(function()
	return game:GetService("InsertService")
end)
local WorkspaceOk, Workspace = pcall(function()
	return game:GetService("Workspace")
end)

local LookDev, ModelMapBuildingsR4
if ReplicatedStorageOk and ReplicatedStorage then
	local sharedOk, Shared = pcall(function()
		return ReplicatedStorage:WaitForChild("Shared")
	end)
	if sharedOk and Shared then
		local lookDevOk, loadedLookDev = pcall(function()
			return require(Shared.LookDev)
		end)
		local mapOk, loadedMap = pcall(function()
			return require(Shared.ModelMapBuildingsR4)
		end)
		if lookDevOk and mapOk then
			LookDev, ModelMapBuildingsR4 = loadedLookDev, loadedMap
		end
	end
end

if not (InsertServiceOk and _InsertService and WorkspaceOk and Workspace and LookDev and ModelMapBuildingsR4) then
	pcall(warn, "[LookDevModelsBuildingsR4] services or shared modules unavailable; candidate not registered")
	return {}
end

local okLoaders, loadedFailures, loadedAssetLoader = pcall(function()
	local sharedFolder = (ReplicatedStorage :: any):WaitForChild("Shared")
	return require((sharedFolder :: any).LookDevFailures), require(script.Parent.LookDevAssetLoader)
end)
if not okLoaders or not loadedFailures or not loadedAssetLoader then
	pcall(warn, "[LookDevModelsBuildingsR4] could not require LookDevFailures / LookDevAssetLoader")
	return {}
end
local LookDevFailures = loadedFailures
local LookDevAssetLoader = loadedAssetLoader

local LookDevModelsBuildingsR4 = {}

local active: { [string]: any } = {}
local saved: { [string]: any } = {}

local function folderName(family: string): string
	return "LookDevModelsBuildingsR4_" .. family
end

local function clearActive(family: string)
	local folder = active[family]
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	active[family] = nil
end

local function anchorParts(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	table.insert(descendants, model)
	for _, part in ipairs(descendants) do
		local isPart, isBasePart = pcall(function()
			return part:IsA("BasePart")
		end)
		if isPart and isBasePart then
			-- All settings in one pcall: a MeshPart with unusual permissions cannot abort the row.
			pcall(function()
				part.Anchored = true
				part.CanCollide = false
			end)
		end
	end
end

local function placeAtGround(model: any, slot: any)
	local originalOk, _, originalSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local scaleOk = false
	if originalOk and originalSize and originalSize.Y > 0 then
		scaleOk = pcall(function()
			model:ScaleTo(slot.targetHeight / originalSize.Y)
		end)
	end
	if not scaleOk then
		pcall(warn, "[LookDevModelsBuildingsR4] ScaleTo failed for " .. slot.slot)
	end

	local y = ModelMapBuildingsR4.staging.groundY
	local boxOk, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local pivotOk, pivot = pcall(function()
		return model:GetPivot()
	end)
	if boxOk and boxCFrame and boxSize and pivotOk and pivot then
		y = pivot.Y - boxCFrame.Y + boxSize.Y * 0.5
	end

	local rotationOk, rotation = pcall(function()
		return CFrame.Angles(0, slot.ry, 0) * CFrame.Angles(slot.rotX or 0, 0, 0)
	end)
	if not rotationOk or not rotation then
		return
	end
	local targetOk, target = pcall(function()
		return CFrame.new(slot.x, y, slot.z) * rotation
	end)
	if not targetOk or not target then
		return
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

local function applierFor(family: string)
	local familyMap = ModelMapBuildingsR4.families[family]
	return {
		apply = function()
			clearActive(family)

			local name = folderName(family)
			local found, previous = pcall(function()
				return Workspace:FindFirstChild(name)
			end)
			if found and previous then
				-- Detach, not Destroy: restore() puts this exact folder back.
				pcall(function()
					previous.Parent = nil
				end)
				saved[family] = previous
			end

			local created, folder = pcall(function()
				local instance = Instance.new("Folder")
				instance.Name = name
				instance.Parent = Workspace
				return instance
			end)
			if not created or not folder then
				pcall(warn, "[LookDevModelsBuildingsR4] could not create " .. name)
				return
			end
			active[family] = folder

			local failures = 0
			for _, slot in ipairs(familyMap.slots) do
				local id = familyMap.ids[slot.slot]
				if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
					failures += 1
					LookDevFailures.add(family, 1)
					pcall(warn, "[LookDevModelsBuildingsR4] no asset ID for " .. family .. "/" .. slot.slot)
					continue
				end
				-- Legacy runtime path was InsertService:LoadAsset(familyMap.ids[slot.slot]);
				-- the loader clones the baked copy first and counts failures loudly.
				local model = LookDevAssetLoader.get(id, family)
				if not model then
					failures += 1
					pcall(warn, "[LookDevModelsBuildingsR4] LoadAsset failed for " .. family .. "/" .. slot.slot)
				else
					pcall(function()
						model.Name = "R4_" .. slot.slot
					end)
					anchorParts(model)
					placeAtGround(model, slot)
					pcall(function()
						model.Parent = folder
					end)
				end
			end
			if failures > 0 then
				pcall(
					warn,
					"[LookDevModelsBuildingsR4] "
						.. family
						.. " placed "
						.. (#familyMap.slots - failures)
						.. "/"
						.. #familyMap.slots
						.. " models"
				)
			end
		end,

		restore = function()
			clearActive(family)
			local previous = saved[family]
			if previous then
				pcall(function()
					previous.Parent = Workspace
				end)
				saved[family] = nil
			end
		end,
	}
end

LookDev.register("buildings_r4", applierFor("buildings_r4"))

return LookDevModelsBuildingsR4
