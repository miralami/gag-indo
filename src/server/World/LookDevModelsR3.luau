-- LookDevModelsR3: SERVER-ONLY appliers for the four OFF-BY-DEFAULT round-3 model
-- candidates (WORK_QUEUE item 23, bug fixes item 28). InsertService:LoadAsset works in the Server
-- datamodel but is blocked on the client, so these appliers MUST be required from Main.server.luau
-- and toggled from the Studio command bar with the Server datamodel selected.
-- See docs/v2/visual/art/models_r3/INTEGRATION.md for the four toggles and cameras.
--
-- Eligibility is handled by Shared.LookDev: every candidate is off until .enable() is called
-- from Studio, and .disable() restores the previous look. No asset ID literals live here;
-- they all come from Shared.ModelMapR3 (which is also what the spec audits).
--
-- ROUND-3 BUGS 3/4/5: after every LoadAsset the model is rotated (rotX for the Z-up CC0 imports),
-- normalised to the slot's targetHeight with Model:ScaleTo, then EVERY BasePart descendant is
-- anchored (so it cannot fall through the ground) with CanCollide=false — this staging sits on
-- real PLAZA ground near spawn, so a colliding display model would be an invisible player blocker.
-- Anchored + non-colliding is the safe staging combination; no shipping collision is changed.
-- Every Roblox call below is pcall'd: a bad asset warns and is skipped, never throws.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapR3 = require(Shared.ModelMapR3)
-- Legacy service handle kept for the documented runtime path below; LookDevAssetLoader owns the call.
local _InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LookDevFailures = require(Shared.LookDevFailures)
local LookDevAssetLoader = require(script.Parent.LookDevAssetLoader)

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

-- Rotate about the model's own pivot BEFORE measuring it: a Z-up import needs rotX = pi/2 first,
-- otherwise ScaleTo would normalise its depth instead of its upright height.
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

-- Put the model's own bounding-box bottom on y=0 at the slot, keeping rotX + ry in the target.
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

-- Scale every loaded model to its slot's targetHeight. Guard tiny/zero/NaN sizes so a broken
-- asset can never produce an infinite or negative scale.
local function normaliseScale(model: any, slot: any): boolean
	local ok, _, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not size or size.Y <= 0.01 or size.Y ~= size.Y then
		return false
	end
	return pcall(function()
		model:ScaleTo(slot.targetHeight / size.Y)
	end)
end

-- Review staging near spawn must be visible but inert: anchored so parts stay put on the plaza,
-- CanCollide=false so players can walk through them. Documented above; never a shipping change.
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
	orient(model, slot)
	if not normaliseScale(model, slot) then
		warn("[LookDevModelsR3] could not scale " .. slot.slot .. ": invalid bounding box")
	end
	anchorAndDisableCollision(model)
	placeAtGround(model, slot)
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
				pcall(function()
					previous.Parent = nil
				end)
				saved[family] = previous
			end

			local folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = Workspace
			active[family] = folder

			local failures = 0
			for _, slot in ipairs(familyMap.slots) do
				local id = familyMap.ids[slot.slot]
				if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
					failures += 1
					LookDevFailures.add(family, 1)
					warn("[LookDevModelsR3] no asset ID for " .. family .. "/" .. slot.slot)
					continue
				end
				-- Legacy runtime path was InsertService:LoadAsset(familyMap.ids[slot.slot]);
				-- the loader clones the baked copy first and counts failures loudly.
				local model = LookDevAssetLoader.get(id, family)
				if not model then
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
					pcall(function()
						model.Name = "R3_" .. slot.slot
					end)
					stage(model, slot)
					pcall(function()
						model.Parent = folder
					end)
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
