--!strict
-- LookDevModelsPropsR4: SERVER-ONLY applier for the OFF-BY-DEFAULT "props_r4" candidate
-- (WORK_QUEUE round 4 item 31, props lane). InsertService:LoadAsset works in the Server datamodel
-- but is blocked on the client, so require this from Main.server.luau and toggle from a Server
-- command bar. No asset ID literals live here; every ID comes from Shared.ModelMapPropsR4.
--
-- Every engine call is pcall'd: a missing service, a missing/invalid asset ID or a failed insert
-- warns and is skipped, never throws. apply() saves any same-named Workspace folder and restore()
-- puts that exact folder back. Every loaded BasePart is anchored with CanCollide=false: this
-- staging sits on real playable ground near spawn, so a colliding display model would be an
-- invisible player blocker. No shipping collision is changed.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsPropsR4] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = service("InsertService")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and value then
		Shared = value
	else
		warn("[LookDevModelsPropsR4] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, ModelMapPropsR4 = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapPropsR4)
end)
if not okModules or not LookDev or not ModelMapPropsR4 then
	warn("[LookDevModelsPropsR4] could not require LookDev / ModelMapPropsR4")
	return {}
end

local okLoaders, loadedFailures, loadedAssetLoader = pcall(function()
	return require((Shared :: any).LookDevFailures), require(script.Parent.LookDevAssetLoader)
end)
if not okLoaders or not loadedFailures or not loadedAssetLoader then
	warn("[LookDevModelsPropsR4] could not require LookDevFailures / LookDevAssetLoader")
	return {}
end
local LookDevFailures = loadedFailures
local LookDevAssetLoader = loadedAssetLoader

local LookDevModelsPropsR4 = {}

local FAMILY_ID = "props_r4"
local activeFolder: any? = nil
local savedFolder: any? = nil

local function folderName(): string
	return "LookDevModelsPropsR4_" .. FAMILY_ID
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(): any?
	local ok, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not ok or not folder then
		warn("[LookDevModelsPropsR4] could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = folderName()
	end)
	pcall(function()
		folder.Parent = Workspace
	end)
	return folder
end

local function findPrevious(): any?
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(folderName())
	end)
	return if ok then previous else nil
end

-- Rotate about the model's own pivot BEFORE measuring it: a Z-up import needs rotX first,
-- otherwise ScaleTo would normalise its depth instead of its upright height. This batch is Y-up
-- (rotX = 0) but the applier still honours any non-zero rotX from the map.
local function orient(model: any, slot: any): boolean
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not ok or not pivot then
		return false
	end
	return pcall(function()
		model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(slot.rotX or 0, slot.ry, 0))
	end)
end

local function measure(model: any): (any?, number?)
	local ok, boxCFrame, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not boxCFrame or not size then
		return nil, nil
	end
	local bodySizeY = size.Y
	if bodySizeY <= 0.01 or bodySizeY ~= bodySizeY then
		return boxCFrame, nil
	end
	return boxCFrame, bodySizeY
end

-- Scale every loaded model to its slot's targetHeight. Guard tiny/zero/NaN sizes so a broken
-- asset can never produce an infinite or negative scale.
local function normaliseScale(model: any, slot: any, bodySizeY: number): boolean
	local target = slot.targetHeight
	if type(target) ~= "number" or target <= 0.01 or target ~= target then
		return false
	end
	return pcall(function()
		model:ScaleTo(slot.targetHeight / bodySizeY)
	end)
end

-- Put the model's bounding-box bottom on y=0 at the slot, keeping rotX + ry in the target.
local function placeAtGround(model: any, slot: any, boxCFrame: any?, bodySizeY: number?): boolean
	local y = 0
	if boxCFrame and bodySizeY then
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok and pivot then
			y = pivot.Y - boxCFrame.Y + bodySizeY * 0.5
		end
	end
	local okTarget, target = pcall(function()
		return CFrame.new(slot.x, y, slot.z) * CFrame.Angles(slot.rotX or 0, slot.ry, 0)
	end)
	if not okTarget or not target then
		return false
	end
	if pcall(function()
		model:PivotTo(target)
	end) then
		return true
	end
	return pcall(function()
		model:SetPrimaryPartCFrame(target)
	end)
end

local function anchorAndDisableCollision(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in descendants do
		pcall(function()
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end)
	end
end

local function stage(model: any, slot: any)
	if not orient(model, slot) then
		warn("[LookDevModelsPropsR4] could not orient " .. slot.slot)
	end
	local boxCFrame, bodySizeY = measure(model)
	if not bodySizeY then
		warn("[LookDevModelsPropsR4] could not scale " .. slot.slot .. ": invalid bounding box")
		return
	end
	if not normaliseScale(model, slot, bodySizeY) then
		warn("[LookDevModelsPropsR4] could not scale " .. slot.slot .. ": invalid targetHeight")
	end
	-- Re-measure after ScaleTo so the bottom lands on the ground at the NEW size.
	local scaledBox, scaledBodySizeY = measure(model)
	anchorAndDisableCollision(model)
	placeAtGround(model, slot, scaledBox or boxCFrame, scaledBodySizeY or bodySizeY)
end

local applier = {
	apply = function()
		clearActive()
		local familyMap = ModelMapPropsR4.families[FAMILY_ID]
		if type(familyMap) ~= "table" or type(familyMap.slots) ~= "table" or type(familyMap.ids) ~= "table" then
			warn("[LookDevModelsPropsR4] missing family map for " .. FAMILY_ID)
			return
		end

		local previous = findPrevious()
		if previous then
			-- Detach, not Destroy: restore() puts this exact folder back.
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end

		local folder = newFolder()
		if not folder then
			return
		end
		activeFolder = folder

		local failures = 0
		for _, slot in ipairs(familyMap.slots) do
			local id = familyMap.ids[slot.slot]
			-- No-ID guard: never pass a missing, zero, fractional or negative value to LoadAsset.
			if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
				failures += 1
				LookDevFailures.add(FAMILY_ID, 1)
				warn(
					"[LookDevModelsPropsR4] missing or invalid asset ID for " .. FAMILY_ID .. "/" .. tostring(slot.slot)
				)
				continue
			end
			-- Legacy runtime path was InsertService:LoadAsset(id); the loader clones the bake first.
			local model = LookDevAssetLoader.get(id, FAMILY_ID)
			if not model then
				failures += 1
				warn(
					"[LookDevModelsPropsR4] LoadAsset failed for "
						.. FAMILY_ID
						.. "/"
						.. slot.slot
						.. ": "
						.. tostring(model)
				)
			else
				pcall(function()
					model.Name = "R4_" .. slot.slot
				end)
				stage(model, slot)
				pcall(function()
					model.Parent = folder
				end)
			end
		end
		if failures > 0 then
			warn(
				"[LookDevModelsPropsR4] "
					.. FAMILY_ID
					.. " placed "
					.. (#familyMap.slots - failures)
					.. "/"
					.. #familyMap.slots
					.. " models"
			)
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

LookDev.register("props_r4", applier)

return LookDevModelsPropsR4
