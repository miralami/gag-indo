-- LookDevModelsNpcsR4: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_r4"
-- candidate (WORK_QUEUE round 4 item 31). InsertService:LoadAsset works in the
-- Server datamodel but is blocked on the client, so this MUST be required from
-- Main.server.luau and toggled from the Studio Server command bar.
--
-- Eligibility is handled by Shared.LookDev: off until .enable("npcs_r4") is
-- called, and .disable() restores the previous look. No asset ID literal lives
-- here; all IDs, slots, targetHeight and rotX come from Shared.ModelMapNpcsR4.
-- Every engine call is pcall-guarded. No visual verdict is claimed here.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapNpcsR4 = require(Shared.ModelMapNpcsR4)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LookDevFailures = require(Shared.LookDevFailures)
local LookDevAssetLoader = require(script.Parent.LookDevAssetLoader)

local LookDevModelsNpcsR4 = {}

local FAMILY = "npcs_r4"
local familyMap = ModelMapNpcsR4.families[FAMILY]
local active: any = nil
local saved: any = nil

local function folderName(): string
	return "LookDevModelsNpcsR4_" .. FAMILY
end

local function clearActive()
	if active then
		pcall(function()
			active:Destroy()
		end)
	end
	active = nil
end

-- Anchor every loaded BasePart and switch collision off: these are review dummies,
-- never gameplay NPCs. A failed setter is warned, never thrown.
local function configureParts(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or type(descendants) ~= "table" then
		return
	end
	for _, instance in ipairs(descendants) do
		local isPartOk, isPart = pcall(function()
			return instance:IsA("BasePart")
		end)
		if isPartOk and isPart then
			pcall(function()
				instance.Anchored = true
			end)
			pcall(function()
				instance.CanCollide = false
			end)
		end
	end
end

-- Measure the source bounding box, scale it to targetHeight, then put the
-- model's own bounding-box bottom on the slot's real-terrain ground height.
-- rotX lifts Z-up sources into Y-up; ry turns the front toward the review camera.
local function placeAtGround(model: any, slot: any)
	local ok, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local bodySizeY = if ok and boxSize then boxSize.Y else 0
	if bodySizeY > 0 then
		local scaleOk = pcall(function()
			model:ScaleTo(slot.targetHeight / bodySizeY)
		end)
		if not scaleOk then
			warn("[LookDevModelsNpcsR4] ScaleTo failed for " .. slot.slot)
		end
	end

	local pivotY = 0
	local pivotOk, pivot = pcall(function()
		return model:GetPivot()
	end)
	if pivotOk and pivot then
		pivotY = pivot.Y
	end
	if ok and boxCFrame and boxSize then
		pivotY -= boxCFrame.Y - boxSize.Y * 0.5
	end

	local target = CFrame.new(slot.x, slot.y + pivotY, slot.z) * CFrame.Angles(slot.rotX or 0, slot.ry or 0, 0)
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
	clearActive()
	local name = folderName()
	local previous = Workspace:FindFirstChild(name)
	if previous then
		-- Detach, not Destroy: restore() puts this exact folder back.
		previous.Parent = nil
		saved = previous
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	active = folder

	local failures = 0
	for _, slot in ipairs(familyMap.slots) do
		local id = familyMap.ids[slot.slot]
		if type(id) ~= "number" or id <= 0 then
			failures += 1
			LookDevFailures.add(FAMILY, 1)
			warn("[LookDevModelsNpcsR4] no asset ID for " .. FAMILY .. "/" .. slot.slot)
			continue
		end
		-- Legacy runtime path was InsertService:LoadAsset(id); the loader clones the bake first.
		local model = LookDevAssetLoader.get(id, FAMILY)
		if not model then
			failures += 1
			warn("[LookDevModelsNpcsR4] LoadAsset failed for " .. FAMILY .. "/" .. slot.slot .. ": " .. tostring(model))
		else
			pcall(function()
				model.Name = "R4_" .. slot.slot
			end)
			configureParts(model)
			placeAtGround(model, slot)
			model.Parent = folder
		end
	end
	if failures > 0 then
		warn("[LookDevModelsNpcsR4] placed " .. (#familyMap.slots - failures) .. "/" .. #familyMap.slots .. " models")
	end
end

local function restore()
	clearActive()
	if saved then
		pcall(function()
			saved.Parent = Workspace
		end)
		saved = nil
	end
end

LookDev.register("npcs_r4", { apply = apply, restore = restore })

return LookDevModelsNpcsR4
