--!strict
-- LookDevHubsRealR9: SERVER-ONLY applier for the OFF-BY-DEFAULT "hubs_real_r9" candidate
-- (WORK_QUEUE section O item 147). Main.server wires the candidate; this file only registers it.
-- InsertService is never called here: every building comes through
-- LookDevAssetLoader.get(id, "hubs_real_r9") (baked clone first, LoadAsset only as its fallback).
--
-- apply() stages one real Creator Store building per MapSpec hub, scaled from the R8 staged bbox to
-- fit inside that hub's footprint. The building is yawed so its local +Z facade faces the plaza;
-- the final WorldPivot is the item-146 ground-base convention (identity rotation at the footprint
-- centre, cleared PrimaryPart first). The greybox hub body is hidden while its Sign part and
-- children stay visible. restore() destroys the staged folder and puts every exact prior
-- Transparency/CanCollide back before restoring any previous staging folder.
--
-- Every failure is counted and warned, then published to Shared.LookDevFailures.set("hubs_real_r9",
-- failures) at the END of apply(). No matching hub (or a failed load) is skipped and named.
-- No place is saved or published.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevHubsRealR9] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevHubsRealR9] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapHubsRealR9),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not LookDevFailures then
	warn("[LookDevHubsRealR9] could not require LookDev / ModelMapHubsRealR9 / LookDevAssetLoader / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevHubsRealR9] could not require MapSpec; staging will be skipped")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevHubsRealR9 = {}

local FAMILY_ID: string = Data.familyId
local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local hiddenParts: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevHubsRealR9] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- A Sign part and anything under it must stay readable while the rest of the hub body is hidden.
local function isSignPart(part: any, hubModel: any): boolean
	local current: any? = part
	while current do
		local okName, name = pcall(function()
			return current.Name
		end)
		if okName and name == "Sign" then
			return true
		end
		if current == hubModel then
			break
		end
		local okParent, parent = pcall(function()
			return current.Parent
		end)
		current = if okParent then parent else nil
	end
	return false
end

local function restoreBodies()
	for _, part in ipairs(hiddenParts) do
		pcall(function()
			local oldT = part:GetAttribute(Data.prevTransparencyAttribute)
			local oldC = part:GetAttribute(Data.prevCollideAttribute)
			if type(oldT) == "number" then
				part.Transparency = oldT
			end
			if type(oldC) == "boolean" then
				part.CanCollide = oldC
			end
			part:SetAttribute(Data.prevTransparencyAttribute, nil)
			part:SetAttribute(Data.prevCollideAttribute, nil)
		end)
	end
	hiddenParts = {}
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
	restoreBodies()
end

local function findPrevious(): any?
	if not Workspace then
		return nil
	end
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	if not Workspace then
		return nil
	end
	local ok, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not ok or not folder then
		fail("could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = Data.folderName
		folder.Parent = Workspace
	end)
	return folder
end

-- Prefer a Model inside a GreyboxWorld-tagged Folder; fall back to a workspace name match.
local function findHubModel(hub: any): any?
	if not Workspace then
		return nil
	end
	local collection = service("CollectionService")
	local okAll, all = pcall(function()
		return (Workspace :: any):GetDescendants()
	end)
	if not okAll or not all then
		return nil
	end
	if collection then
		for _, instance in ipairs(all) do
			local okTag, tagged = pcall(function()
				return collection:HasTag(instance, Data.greyboxTag)
			end)
			if okTag and tagged then
				local okDesc, descendants = pcall(function()
					return instance:GetDescendants()
				end)
				if okDesc and descendants then
					for _, child in ipairs(descendants) do
						local okModel, isModel = pcall(function()
							return child:IsA("Model")
						end)
						local okName, name = pcall(function()
							return child.Name
						end)
						if okModel and isModel and okName and name == hub.model then
							return child
						end
					end
				end
			end
		end
	end
	for _, instance in ipairs(all) do
		local okModel, isModel = pcall(function()
			return instance:IsA("Model")
		end)
		local okName, name = pcall(function()
			return instance.Name
		end)
		if okModel and isModel and okName and name == hub.model then
			return instance
		end
	end
	return nil
end

local function hideHubBody(hubModel: any, hubKey: string)
	local okParts, parts = pcall(function()
		return hubModel:GetDescendants()
	end)
	if not okParts or not parts then
		fail("could not enumerate greybox body for " .. hubKey)
		return
	end
	for _, part in ipairs(parts) do
		local okPart, isPart = pcall(function()
			return part:IsA("BasePart")
		end)
		if okPart and isPart and not isSignPart(part, hubModel) then
			local okHide = pcall(function()
				if type(part:GetAttribute(Data.prevTransparencyAttribute)) ~= "number" then
					part:SetAttribute(Data.prevTransparencyAttribute, part.Transparency)
				end
				if type(part:GetAttribute(Data.prevCollideAttribute)) ~= "boolean" then
					part:SetAttribute(Data.prevCollideAttribute, part.CanCollide)
				end
				part.Transparency = 1
				part.CanCollide = false
			end)
			if not okHide then
				fail("could not hide greybox part on " .. hubKey)
				continue
			end
			local seen = false
			for _, old in ipairs(hiddenParts) do
				if old == part then
					seen = true
					break
				end
			end
			if not seen then
				hiddenParts[#hiddenParts + 1] = part
			end
		end
	end
end

local function worldBox(instance: any): (any?, any?)
	local ok, boxCFrame, size = pcall(function()
		return instance:GetBoundingBox()
	end)
	if not ok or not boxCFrame or not size or size.X ~= size.X or size.Z ~= size.Z then
		return nil, nil
	end
	return boxCFrame, size
end

local function stage(model: any, plan: any): boolean
	-- Clear PrimaryPart first: WorldPivot with one set would move the geometry.
	if
		not pcall(function()
			if model.PrimaryPart then
				model.PrimaryPart = nil
			end
			model:ScaleTo(plan.scale)
		end)
	then
		fail("ScaleTo / PrimaryPart failed for " .. plan.hub)
		return false
	end
	local boxCFrame, boxSize = worldBox(model)
	if not boxCFrame or not boxSize or boxSize.Y <= 0.01 then
		fail("invalid bounding box for " .. plan.hub)
		return false
	end

	local groundY = if type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
	-- Rotate about the bbox centre so local +Z faces the plaza, then drop the base onto GROUND_Y.
	-- Setting WorldPivot to the measured centre first is pivot-only (no PrimaryPart), so it does
	-- not disturb the geometry the rotation applies to.
	if
		not pcall(function()
			model.WorldPivot = CFrame.new(boxCFrame.Position)
			local rot = CFrame.Angles(0, math.rad(plan.yaw), 0)
			model:PivotTo(CFrame.new(plan.centreX, groundY + boxSize.Y * 0.5, plan.centreZ) * rot)
		end)
	then
		fail("could not place building for " .. plan.hub)
		return false
	end
	local placedCFrame, placedSize = worldBox(model)
	if not placedCFrame or not placedSize then
		fail("post-placement bounding box failed for " .. plan.hub)
		return false
	end
	local bounds = nil
	if type(MapSpec.hubBounds) == "function" then
		local okBounds, value = pcall(function()
			return MapSpec.hubBounds(MapSpec.hub(plan.hub))
		end)
		if okBounds and type(value) == "table" then
			bounds = value
		end
	end
	if not bounds or not Data.fits(plan, bounds) then
		fail("staged building outside " .. plan.hub .. " footprint + " .. tostring(Data.FIT_MARGIN))
		return false
	end

	-- Item-146 pivot convention: identity facing -Z at the ground-base footprint centre.
	if not pcall(function()
		model.WorldPivot = CFrame.new(plan.centreX, groundY, plan.centreZ)
	end) then
		fail("could not set ground pivot for " .. plan.hub)
		return false
	end

	pcall(function()
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part:SetAttribute(Data.tagAttribute, FAMILY_ID)
			end
		end
		model:SetAttribute(Data.tagAttribute, FAMILY_ID)
		model:SetAttribute(Data.hubAttribute, plan.hub)
		model:SetAttribute(Data.slotAttribute, plan.slot)
		model:SetAttribute(Data.scaleAttribute, plan.scale)
		model:SetAttribute(Data.proposalAttribute, Data.proposal)
	end)
	return true
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		local previous = findPrevious()
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder()
		if not folder then
			publishFailures()
			return
		end
		activeFolder = folder

		if not MapSpec or type(MapSpec.HUBS) ~= "table" or #MapSpec.HUBS == 0 then
			fail("MapSpec.HUBS unavailable; no hub staged")
			publishFailures()
			return
		end
		local okStaging = pcall(function()
			for _, hub in ipairs(MapSpec.HUBS) do
				local plan = Data.plan(hub)
				if not plan then
					fail("no good match / verified id for hub " .. tostring(hub.key) .. "; skipping")
					continue
				end
				local model = LookDevAssetLoader.get(plan.id, FAMILY_ID)
				if not model then
					fail("asset load failed for " .. FAMILY_ID .. "/" .. plan.hub .. " (" .. plan.slot .. "); skipping")
					continue
				end
				local hubModel = findHubModel(hub)
				if not hubModel then
					fail("greybox hub model missing for " .. plan.hub .. "; skipping")
					pcall(function()
						model:Destroy()
					end)
					continue
				end
				local okParent = pcall(function()
					model.Name = "R9_" .. plan.hub .. "_" .. plan.slot
					model.Parent = folder
				end)
				if not okParent then
					fail("could not parent building for " .. plan.hub)
					continue
				end
				if stage(model, plan) then
					hideHubBody(hubModel, plan.hub)
				end
			end
		end)
		if not okStaging then
			fail("staging pass aborted unexpectedly")
		end
		publishFailures()
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

LookDev.register(FAMILY_ID, applier)

return LookDevHubsRealR9
