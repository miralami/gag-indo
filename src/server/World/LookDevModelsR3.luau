-- LookDevModelsR3: SERVER-ONLY appliers for the four OFF-BY-DEFAULT round-3 model
-- candidates (WORK_QUEUE item 23). InsertService:LoadAsset works in the Server datamodel
-- but is blocked on the client, so these appliers MUST be required from Main.server.luau
-- and toggled from the Studio command bar with the Server datamodel selected.
-- See docs/v2/visual/art/models_r3/INTEGRATION.md for the four toggles and cameras.
--
-- Eligibility is handled by Shared.LookDev: every candidate is off until .enable() is called
-- from Studio, and .disable() restores the previous look. No asset ID literals live here;
-- they all come from Shared.ModelMapR3 (which is also what the spec audits).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapR3 = require(Shared.ModelMapR3)
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local LookDevModelsR3 = {}

local active: { [string]: any } = {}
local saved: { [string]: any } = {}

local function folderName(family: string): string
	return "LookDevModelsR3_" .. family
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

-- Put the model's own bounding-box bottom on y=0. Fall back to the raw pivot if the loaded
-- asset is not a Model (or has no descendants to measure); never let this throw.
local function placeAtGround(model: any, slot: any)
	local y = 0
	local ok, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if ok and boxCFrame and boxSize then
		local pivotOk, pivot = pcall(function()
			return model:GetPivot()
		end)
		if pivotOk and pivot then
			y = pivot.Y - boxCFrame.Y + boxSize.Y * 0.5
		end
	end
	local target = CFrame.new(slot.x, y, slot.z) * CFrame.Angles(0, slot.ry, 0)
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
	local familyMap = ModelMapR3.families[family]
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
				local ok, model = pcall(function()
					return InsertService:LoadAsset(familyMap.ids[slot.slot])
				end)
				if not ok or not model then
					failures += 1
					warn(
						"[LookDevModelsR3] LoadAsset failed for "
							.. family
							.. "/"
							.. slot.slot
							.. ": "
							.. tostring(model)
					)
				else
					model.Name = "R3_" .. slot.slot
					placeAtGround(model, slot)
					model.Parent = folder
				end
			end
			if failures > 0 then
				warn(
					"[LookDevModelsR3] "
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

LookDev.register("buildings_r3", applierFor("buildings_r3"))
LookDev.register("vegetation_r3", applierFor("vegetation_r3"))
LookDev.register("props_r3", applierFor("props_r3"))
LookDev.register("npcs_r3", applierFor("npcs_r3"))

return LookDevModelsR3
