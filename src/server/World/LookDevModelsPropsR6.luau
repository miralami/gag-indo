--!strict
-- LookDevModelsPropsR6: SERVER-ONLY applier for the OFF-BY-DEFAULT "props_r6" candidate
-- (WORK_QUEUE item 50, props at real size). InsertService:LoadAsset works in the Server datamodel but
-- is blocked on the client, so require this from Main.server.luau and toggle from a Server command bar.
-- No asset ID literals live here: every ID comes from Shared.ModelMapPropsR6, which reuses
-- ModelMapPropsR4's real CC0/CC BY IDs.
--
-- Mechanics are the proven R5 applier: pcall every engine call, skip missing/invalid assets with a
-- warn, anchor + CanCollide=false on real playable ground, detach (not destroy) any same-named
-- folder on apply and put that exact folder back on restore. R6 uses the corrected per-slot
-- effective height (ModelMapPropsR6.effectiveHeight) so the round-5 tools reach their real-size
-- targets. Nothing here changes shipping collision and nothing is applied until LookDev.enable().

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsPropsR6] missing service " .. name)
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
		warn("[LookDevModelsPropsR6] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, ModelMapPropsR6 = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapPropsR6)
end)
if not okModules or not LookDev or not ModelMapPropsR6 then
	warn("[LookDevModelsPropsR6] could not require LookDev / ModelMapPropsR6")
	return {}
end

local okLoaders, loadedFailures, loadedAssetLoader = pcall(function()
	return require((Shared :: any).LookDevFailures), require(script.Parent.LookDevAssetLoader)
end)
if not okLoaders or not loadedFailures or not loadedAssetLoader then
	warn("[LookDevModelsPropsR6] could not require LookDevFailures / LookDevAssetLoader")
	return {}
end
local LookDevFailures = loadedFailures
local LookDevAssetLoader = loadedAssetLoader

local LookDevModelsPropsR6 = {}

local FAMILY_ID = "props_r6"
local activeFolder: any? = nil
local savedFolder: any? = nil

local function folderName(): string
	return "LookDevModelsPropsR6_" .. FAMILY_ID
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
		warn("[LookDevModelsPropsR6] could not create staging folder")
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

-- Turn one stacked-sack offset into the same flat entry shape the normal slots use, so the
-- load/scale/place path stays identical. yOffset lifts the top sack onto the others.
local function karungEntries(group: any): { any }
	local list = {}
	for _, sack in ipairs(group.stack) do
		list[#list + 1] = {
			slot = group.slot,
			x = group.x + sack.dx,
			z = group.z + sack.dz,
			ry = group.ry + sack.ry,
			rotX = group.rotX,
			targetHeight = group.targetHeight,
			scale = group.scale,
			yOffset = sack.dy,
		}
	end
	return list
end

-- Rotate about the model's own pivot BEFORE measuring it: a Z-up import needs rotX first,
-- otherwise ScaleTo would normalise its depth instead of its upright height. This batch is Y-up
-- (rotX = 0) but the applier still honours any non-zero rotX from the map.
local function orient(model: any, entry: any): boolean
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not ok or not pivot then
		return false
	end
	return pcall(function()
		model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(entry.rotX or 0, entry.ry, 0))
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

-- Post-ScaleTo bounding-box size, for tests that read the actual measured stud dimensions and
-- compare them with ModelMapPropsR6.targets. Returns nil when the engine call fails.
local function measuredBox(model: any): any?
	local ok, _, size = pcall(function()
		return model:GetBoundingBox()
	end)
	return if ok then size else nil
end

-- Scale to the slot's R6 effective height (R4 targetHeight * scale). Guard tiny/zero/NaN
-- sizes so a broken asset can never produce an infinite or negative scale.
local function normaliseScale(model: any, entry: any, bodySizeY: number): boolean
	local target = ModelMapPropsR6.effectiveHeight(entry)
	if type(target) ~= "number" or target <= 0.01 or target ~= target then
		return false
	end
	return pcall(function()
		model:ScaleTo(target / bodySizeY)
	end)
end

-- Put the model's bounding-box bottom on y=0 at the slot (plus a stacked-sack yOffset),
-- keeping rotX + ry in the target.
local function placeAtGround(model: any, entry: any, boxCFrame: any?, bodySizeY: number?): boolean
	local y = entry.yOffset or 0
	if boxCFrame and bodySizeY then
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok and pivot then
			y += pivot.Y - boxCFrame.Y + bodySizeY * 0.5
		end
	end
	local okTarget, target = pcall(function()
		return CFrame.new(entry.x, y, entry.z) * CFrame.Angles(entry.rotX or 0, entry.ry, 0)
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

local function stage(model: any, entry: any)
	if not orient(model, entry) then
		warn("[LookDevModelsPropsR6] could not orient " .. entry.slot)
	end
	local boxCFrame, bodySizeY = measure(model)
	if not bodySizeY then
		warn("[LookDevModelsPropsR6] could not scale " .. entry.slot .. ": invalid bounding box")
		return
	end
	if not normaliseScale(model, entry, bodySizeY) then
		warn("[LookDevModelsPropsR6] could not scale " .. entry.slot .. ": invalid effectiveHeight")
	end
	-- Re-measure after ScaleTo so the bottom lands on the ground at the NEW size.
	local scaledBox, scaledBodySizeY = measure(model)
	anchorAndDisableCollision(model)
	placeAtGround(model, entry, scaledBox or boxCFrame, scaledBodySizeY or bodySizeY)
end

local applier = {
	apply = function()
		clearActive()
		local familyMap = ModelMapPropsR6.families[FAMILY_ID]
		if type(familyMap) ~= "table" or type(familyMap.slots) ~= "table" or type(familyMap.ids) ~= "table" then
			warn("[LookDevModelsPropsR6] missing family map for " .. FAMILY_ID)
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

		local entries = {}
		for _, slot in ipairs(familyMap.slots) do
			entries[#entries + 1] = slot
		end
		for _, sack in ipairs(karungEntries(familyMap.karung)) do
			entries[#entries + 1] = sack
		end

		local failures = 0
		for index, entry in ipairs(entries) do
			local id = familyMap.ids[entry.slot]
			-- No-ID guard: never pass a missing, zero, fractional or negative value to LoadAsset.
			if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
				failures += 1
				LookDevFailures.add(FAMILY_ID, 1)
				warn(
					"[LookDevModelsPropsR6] missing or invalid asset ID for "
						.. FAMILY_ID
						.. "/"
						.. tostring(entry.slot)
				)
				continue
			end
			-- Legacy runtime path was InsertService:LoadAsset(id); the loader clones the bake first.
			local model = LookDevAssetLoader.get(id, FAMILY_ID)
			if not model then
				failures += 1
				warn(
					"[LookDevModelsPropsR6] LoadAsset failed for "
						.. FAMILY_ID
						.. "/"
						.. entry.slot
						.. ": "
						.. tostring(model)
				)
			else
				pcall(function()
					model.Name = "R6_" .. entry.slot .. "_" .. index
				end)
				stage(model, entry)
				pcall(function()
					model.Parent = folder
				end)
			end
		end
		if failures > 0 then
			warn(
				"[LookDevModelsPropsR6] "
					.. FAMILY_ID
					.. " placed "
					.. (#entries - failures)
					.. "/"
					.. #entries
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

-- Test hook: expose the raw measurement so a spec can re-read the post-ScaleTo GetBoundingBox
-- heights without starting Studio. Production behaviour is unchanged.
LookDevModelsPropsR6._measure = measure
LookDevModelsPropsR6._measuredBox = measuredBox

LookDev.register("props_r6", applier)

return LookDevModelsPropsR6
