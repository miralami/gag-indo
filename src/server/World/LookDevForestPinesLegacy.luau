--!strict
-- LookDevForestPinesLegacy: SERVER-ONLY applier for the OFF-BY-DEFAULT "forest_pines_legacy"
-- candidate (WORK_QUEUE section O item 138, doing item 102's comparison half). Main.server wires
-- the candidate; this file only registers it.
--
-- The shipping default background is a thick tropical wall (Models named
-- Tropical_<species>_<angle>_<layer>, ForestTree=true, ForestSpecies=<species>). On apply() this
-- applier moves every such tree out of workspace.World.BackgroundForest into a hold Folder under
-- ServerStorage, then rebuilds the OLD pine ring from the original Greybox buildBackgroundForest
-- algorithm (lines 793-869) into Workspace.LookDevForestPinesLegacy_forest_pines_legacy. It clones
-- ServerStorage."Realistic Pine Tree" when that baked template exists and falls back to a
-- procedural cylinder trunk + ball canopy otherwise. No new asset IDs. Every staged Model and
-- BasePart carries LookDevForestPinesLegacy = "forest_pines_legacy".
--
-- Restore destroys the staged pine folder, reparents every moved tree to the EXACT parent it came
-- from in the original child order, then destroys the hold Folder. apply() is repeat-safe: a
-- previous (possibly partial) staging is restored before a fresh one. All service / Instance
-- access is pcall-guarded; a real failure is counted and warned, never silently skipped.
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("forest_pines_legacy", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevForestPinesLegacy] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local ServerStorage = service("ServerStorage")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevForestPinesLegacy] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okLookDev, LookDev = pcall(function()
	return require((Shared :: any).LookDev)
end)
if not okLookDev or not LookDev then
	warn("[LookDevForestPinesLegacy] could not require LookDev")
	return {}
end

-- Greybox uses Ground.Y; MapSpec re-exports it as GROUND_Y. Fallback matches Ground.luau.
local GROUND_Y: number = 0.5
local okMapSpec, MapSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okMapSpec and MapSpec and type(MapSpec.GROUND_Y) == "number" then
	GROUND_Y = MapSpec.GROUND_Y
end

local CANDIDATE_ID = "forest_pines_legacy"
local STAGED_FOLDER = "LookDevForestPinesLegacy_forest_pines_legacy"
local HOLD_FOLDER = "LookDevForestPinesLegacy_hold_forest_pines_legacy"
local TAG_KEY = "LookDevForestPinesLegacy"

-- Exact Greybox FOREST_* constants: ring bands and the sawah / river gaps.
local FOREST_INNER = 260
local FOREST_OUTER = 380
local FOREST_MIDDLE = 300
local FOREST_SKIP_NORTH_Z = -260
local FOREST_SKIP_NORTH_X = 370
local FOREST_SKIP_SOUTH_Z = { 250, 364 }

local LookDevForestPinesLegacy = {}
local failures = 0
local state: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevForestPinesLegacy] " .. message)
end

local function forestSkip(x: number, z: number): boolean
	if z < FOREST_SKIP_NORTH_Z and math.abs(x) < FOREST_SKIP_NORTH_X then
		return true -- sawah terraces and the Balai Desa slot
	end
	if z > FOREST_SKIP_SOUTH_Z[1] and z < FOREST_SKIP_SOUTH_Z[2] then
		return true -- river channel, banks and bridge
	end
	return false
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		fail("could not create folder " .. name)
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

-- One tree from the original algorithm. The template path is measured once per staging and passed
-- in; everything that can throw is pcall-guarded.
local function stagePine(angleDeg: number, layer: number, folder: any, template: any?): boolean
	local baseDist = if layer == 1 then FOREST_OUTER elseif layer == 2 then FOREST_MIDDLE else FOREST_INNER
	local dist = baseDist + ((angleDeg * 7 + layer * 13) % 20)
	local a = math.rad(angleDeg) + math.rad((layer - 1) * 3)
	local x = math.cos(a) * dist
	local z = math.sin(a) * dist
	if forestSkip(x, z) then
		return true
	end

	local label = "Pine_" .. angleDeg .. "_" .. layer
	local scale = 0.8 + ((angleDeg * 5 + layer * 11) % 9) * 0.05
	local castShadow = (layer >= 2 and angleDeg % 2 == 0)
	local tree: any = nil

	if template then
		local okClone, clone = pcall(function()
			return template:Clone()
		end)
		if not okClone or not clone then
			fail("could not clone Realistic Pine Tree for " .. label)
			return false
		end
		tree = clone
		local okParts = pcall(function()
			for _, part in tree:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.CastShadow = castShadow
					part.Size = part.Size * scale
				end
			end
		end)
		if not okParts then
			fail("could not configure cloned parts for " .. label)
			return false
		end
		local okPivot = pcall(function()
			tree:PivotTo(CFrame.new(x, GROUND_Y, z) * CFrame.Angles(0, math.rad((angleDeg * 37 + layer * 73) % 360), 0))
		end)
		if not okPivot then
			fail("could not place " .. label)
			return false
		end
	else
		local okModel, model = pcall(function()
			return Instance.new("Model")
		end)
		if not okModel or not model then
			fail("could not create model for " .. label)
			return false
		end
		tree = model
		local okParts = pcall(function()
			local trunk = Instance.new("Part")
			trunk.Name = "Trunk"
			trunk.Shape = Enum.PartType.Cylinder
			trunk.Size = Vector3.new(45 * scale, 2.4 * scale, 2.4 * scale)
			trunk.CFrame = CFrame.new(x, 22 * scale, z) * CFrame.Angles(0, 0, math.pi / 2)
			trunk.Color = Color3.fromRGB(75, 52, 35)
			trunk.Material = Enum.Material.Wood
			trunk.Anchored = true
			trunk.CanCollide = false
			trunk.CanQuery = false
			trunk.CanTouch = false
			trunk.CastShadow = false
			trunk.Parent = tree

			local canopy = Instance.new("Part")
			canopy.Name = "Canopy"
			canopy.Shape = Enum.PartType.Ball
			canopy.Size = Vector3.new(24 * scale, 48 * scale, 24 * scale)
			canopy.CFrame = CFrame.new(x, 32 * scale, z)
			canopy.Color = Color3.fromRGB(44, 92, 40)
			canopy.Material = Enum.Material.Grass
			canopy.Anchored = true
			canopy.CanCollide = false
			canopy.CanQuery = false
			canopy.CanTouch = false
			canopy.CastShadow = castShadow
			canopy.Parent = tree
		end)
		if not okParts then
			fail("could not build procedural parts for " .. label)
			return false
		end
	end

	local okFinish = pcall(function()
		tree.Name = label
		tree:SetAttribute(TAG_KEY, CANDIDATE_ID)
		for _, part in tree:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetAttribute(TAG_KEY, CANDIDATE_ID)
			end
		end
		tree.Parent = folder
	end)
	if not okFinish then
		fail("could not stage " .. label)
		return false
	end
	return true
end

local function stageForest(folder: any)
	local template: any = nil
	if ServerStorage then
		local okTemplate, found = pcall(function()
			return (ServerStorage :: any):FindFirstChild("Realistic Pine Tree")
		end)
		if okTemplate then
			template = found
		end
	end
	for angleDeg = 0, 355, 6 do
		if not (angleDeg >= 130 and angleDeg <= 230) then -- sunset gap
			local layers = 2 + (angleDeg % 2)
			for layer = 1, layers do
				stagePine(angleDeg, layer, folder, template)
			end
		end
	end
end

local function isTropicalTree(child: any): boolean
	local okAttr, value = pcall(function()
		return child:GetAttribute("ForestTree")
	end)
	if okAttr and value == true then
		return true
	end
	local okName, name = pcall(function()
		return child.Name
	end)
	return okName and type(name) == "string" and string.sub(name, 1, 9) == "Tropical_"
end

local function restore()
	local snapshot = state
	if not snapshot then
		return
	end
	state = nil
	local folder = snapshot.folder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	-- Exact restore, in the order the trees were originally listed under BackgroundForest.
	for _, entry in ipairs(snapshot.moved) do
		pcall(function()
			entry.child.Parent = entry.parent
		end)
	end
	local hold = snapshot.hold
	if hold then
		pcall(function()
			hold:Destroy()
		end)
	end
end

local applier = {
	apply = function()
		failures = 0
		restore() -- repeat-safe: clear any previous (possibly partial) staging first
		if not Workspace or not ServerStorage then
			fail("missing Workspace/ServerStorage")
			return
		end
		local forest: any = nil
		local okForest, found = pcall(function()
			local world = (Workspace :: any):FindFirstChild("World")
			return world and world:FindFirstChild("BackgroundForest")
		end)
		if okForest then
			forest = found
		end
		if not forest then
			fail("missing workspace.World.BackgroundForest")
			return
		end

		local hold = newFolder(HOLD_FOLDER, ServerStorage)
		if not hold then
			return
		end
		local snapshot = { folder = nil, hold = hold, moved = {} }
		state = snapshot

		local okChildren, children = pcall(function()
			return forest:GetChildren()
		end)
		if not okChildren or type(children) ~= "table" then
			fail("could not read BackgroundForest children")
			return
		end
		for _, child in ipairs(children) do
			if isTropicalTree(child) then
				local parent: any = nil
				local okParent, saved = pcall(function()
					return child.Parent
				end)
				if okParent then
					parent = saved
				end
				snapshot.moved[#snapshot.moved + 1] = { child = child, parent = parent }
				local okMove = pcall(function()
					child.Parent = hold
				end)
				if not okMove then
					fail("could not move tropical tree " .. tostring(child.Name))
				end
			end
		end

		local folder = newFolder(STAGED_FOLDER, Workspace)
		if not folder then
			return
		end
		snapshot.folder = folder
		pcall(function()
			folder:SetAttribute(TAG_KEY, CANDIDATE_ID)
		end)
		stageForest(folder)
	end,

	restore = restore,
}

LookDevForestPinesLegacy.apply = applier.apply
LookDevForestPinesLegacy.restore = applier.restore

LookDev.register(CANDIDATE_ID, applier)

return LookDevForestPinesLegacy
