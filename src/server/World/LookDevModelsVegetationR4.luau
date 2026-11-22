-- LookDevModelsVegetationR4: SERVER-ONLY applier for the OFF-BY-DEFAULT round-4
-- "vegetation_r4" model candidate (WORK_QUEUE item 31). InsertService:LoadAsset works in the
-- Server datamodel but is blocked on the client, so require this from Main.server.luau and
-- toggle with the Server datamodel selected: LookDev.enable("vegetation_r4").
--
-- Eligibility is handled by Shared.LookDev: the family is off until .enable() is called from
-- Studio, and .disable() restores the exact previous folder. No asset ID literals live here;
-- every ID comes from Shared.ModelMapVegetationR4 (which the spec audits), and a slot without a
-- usable ID is skipped rather than passed to LoadAsset.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapVegetationR4 = require(Shared.ModelMapVegetationR4)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LookDevFailures = require(Shared.LookDevFailures)
local LookDevAssetLoader = require(script.Parent.LookDevAssetLoader)

local LookDevModelsVegetationR4 = {}

local active: { [string]: any } = {}
local saved: { [string]: any } = {}

local function folderName(family: string): string
	return "LookDevModelsVegetationR4_" .. family
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

-- Scale the loaded body to the slot's target stud height, then anchor every BasePart, disable
-- collision, rotate (rotX for any Z-up import, ry for facing) and drop its bounding-box bottom
-- onto y=0. Every engine call is pcall'd: a malformed asset must never break the toggle.
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
		warn("[LookDevModelsVegetationR4] ScaleTo failed for " .. slot.slot)
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

local function applierFor(family: string)
	local familyMap = ModelMapVegetationR4.families[family]
	return {
		apply = function()
			clearActive(family)
			local name = folderName(family)
			local previous = Workspace:FindFirstChild(name)
			if previous then
				-- Detach, not Destroy: restore() puts this exact folder back.
				previous.Parent = nil
				saved[family] = previous
			end

			local folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = Workspace
			active[family] = folder

			local failures = 0
			for _, slot in ipairs(familyMap.slots) do
				local modelId = familyMap.ids[slot.slot]
				if type(modelId) ~= "number" or modelId <= 0 then
					-- Designer-build gaps carry no ID; never call LoadAsset with a placeholder.
					failures += 1
					LookDevFailures.add(family, 1)
					warn("[LookDevModelsVegetationR4] no asset ID for " .. family .. "/" .. slot.slot)
					continue
				end
				-- Legacy runtime path was `return InsertService:LoadAsset(modelId)`;
				-- the loader clones the baked copy first and counts failures loudly.
				local model = LookDevAssetLoader.get(modelId, family)
				if not model then
					failures += 1
					warn(
						"[LookDevModelsVegetationR4] LoadAsset failed for "
							.. family
							.. "/"
							.. slot.slot
							.. ": "
							.. tostring(model)
					)
				else
					model.Name = "R4_" .. slot.slot
					placeAndScale(model, slot)
					model.Parent = folder
				end
			end
			if failures > 0 then
				warn(
					"[LookDevModelsVegetationR4] "
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

LookDev.register("vegetation_r4", applierFor("vegetation_r4"))

return LookDevModelsVegetationR4
