--!nocheck
-- LookDevSpawnGroundR5: SERVER-ONLY applier for the OFF-BY-DEFAULT "spawn_ground_r5" candidate
-- (WORK_QUEUE item 36). Server-created Parts replicate to the Client viewport; no client hook.
--
-- Nothing happens until LookDev.enable("spawn_ground_r5") is called from Studio. apply() hides the
-- Greybox road/arm/ring/continuation/RoadEdge Parts and any MudPatch whose footprint overlaps a
-- path, records their EXACT prior Visible/CanCollide, then builds soft-edged tanah paths from
-- MapSpec geometry in its own Workspace Folder. restore() restores every recorded state exactly and
-- destroys everything it created. The default buildRoads code stays untouched.
--
-- No asset IDs live here: colours/materials/heights/margins come from Shared.SpawnGroundMapR5.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SpawnGroundMapR5 = require(Shared.SpawnGroundMapR5)
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local MapSpec = require(script.Parent.MapSpec)
local Map = require(script.Parent.Map)

local LookDevSpawnGroundR5 = {}

local saved: { [Instance]: { visible: boolean, canCollide: boolean } } = {}
local savedFolder: Instance? = nil
local savedFolderParent: Instance? = nil
local createdFolder: Folder? = nil

local function remember(part: Instance)
	if saved[part] ~= nil then
		return
	end
	local ok, visible, canCollide = pcall(function()
		return part.Visible, part.CanCollide
	end)
	if ok then
		saved[part] = { visible = visible, canCollide = canCollide }
	end
end

local function hide(part: Instance)
	remember(part)
	pcall(function()
		part.Visible = false
		part.CanCollide = false
	end)
end

-- Tagged designer plot anchors are BaseParts. Use a conservative square around each so an anchor
-- rotated off-axis can never slip past the rectangle exclusion test.
local function anchorRects()
	local rects = {}
	local ok, tagged = pcall(function()
		return CollectionService:GetTagged(Map.TAGS.PlotAnchor)
	end)
	if not ok then
		return rects
	end
	for _, anchor in ipairs(tagged) do
		if anchor:IsA("BasePart") then
			local okPart, position, size = pcall(function()
				return anchor.Position, anchor.Size
			end)
			if okPart then
				local radius = math.max(size.X, size.Y, size.Z) / 2
				table.insert(rects, { x = position.X, z = position.Z, halfX = radius, halfZ = radius })
			end
		end
	end
	return rects
end

local function descendants()
	local ok, list = pcall(function()
		return Workspace:GetDescendants()
	end)
	return if ok then list else {}
end

-- Names come from MapSpec (via the pure data module); "RoadEdge" is the old Slate kerb name.
local function roadNames()
	local names = { RoadEdge = true }
	for _, path in ipairs(SpawnGroundMapR5.pathRects(MapSpec)) do
		names[path.name] = true
	end
	return names
end

local function hideExisting(all: { Instance }, paths: { any })
	local names = roadNames()
	for _, instance in ipairs(all) do
		if instance:IsA("BasePart") and names[instance.Name] then
			hide(instance)
		end
	end
	if #paths == 0 then
		return
	end
	-- A MudPatch disc is Size.Y x Size.Z in world XZ (cylinder laid on its side); max component
	-- plus slack covers any author rotation.
	local slack = SpawnGroundMapR5.exclusionMargins.mud
	for _, instance in ipairs(all) do
		if instance:IsA("BasePart") and instance.Name == "MudPatch" then
			local okPart, position, size = pcall(function()
				return instance.Position, instance.Size
			end)
			if okPart then
				local radius = math.max(size.X, size.Y, size.Z) / 2 + slack
				local disc = { x = position.X, z = position.Z, halfX = radius, halfZ = radius }
				for _, path in ipairs(paths) do
					if SpawnGroundMapR5.intersects(disc, SpawnGroundMapR5.featherRect(path)) then
						hide(instance)
						break
					end
				end
			end
		end
	end
end

local function clearCreated()
	if createdFolder then
		pcall(function()
			createdFolder:Destroy()
		end)
		createdFolder = nil
	end
end

local function makeFolder()
	local name = SpawnGroundMapR5.folderName
	if not savedFolder then
		local previous = Workspace:FindFirstChild(name)
		if previous then
			local okParent, parent = pcall(function()
				return previous.Parent
			end)
			if okParent then
				savedFolder = previous
				savedFolderParent = parent
				pcall(function()
					previous.Parent = nil
				end)
			end
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	createdFolder = folder
	return folder
end

local function addPart(
	folder: Folder,
	suffix: string,
	path: any,
	rect: any,
	height: any,
	thickness: number,
	colour: { number },
	materialName: string,
	transparency: number
)
	local part = Instance.new("Part")
	part.Name = "R5_" .. suffix .. "_" .. path.name
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(rect.sx, thickness, rect.sz)
	part.CFrame = CFrame.new(path.x, MapSpec.GROUND_Y + height, path.z) * CFrame.Angles(0, math.rad(path.yaw), 0)
	part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
	part.Material = Enum.Material[materialName]
	part.Transparency = transparency
	part.Parent = folder
end

local function buildPaths(paths: { any })
	local folder = makeFolder()
	local heights = SpawnGroundMapR5.heights
	local feather = SpawnGroundMapR5.feather
	for _, path in ipairs(paths) do
		-- Underlay first: wider, thinner, low-opacity, below the solid core so the two never
		-- share a plane. Both sit above the old MudPatch top and above visible terrain.
		addPart(
			folder,
			"Feather",
			path,
			SpawnGroundMapR5.featherRect(path),
			heights.featherLift,
			heights.featherThickness,
			SpawnGroundMapR5.colours.feather,
			SpawnGroundMapR5.materials.feather,
			feather.transparency
		)
		addPart(
			folder,
			"Path",
			path,
			path,
			heights.pathLift,
			heights.pathThickness,
			SpawnGroundMapR5.colours.path,
			SpawnGroundMapR5.materials.path,
			0
		)
	end
end

local function apply()
	clearCreated()
	local paths = SpawnGroundMapR5.allowedRects(MapSpec, anchorRects())
	hideExisting(descendants(), paths)
	buildPaths(paths)
end

local function restore()
	clearCreated()
	for part, state in pairs(saved) do
		pcall(function()
			part.Visible = state.visible
		end)
		pcall(function()
			part.CanCollide = state.canCollide
		end)
	end
	saved = {}
	local folder = savedFolder
	if folder then
		pcall(function()
			folder.Parent = savedFolderParent
		end)
		savedFolder = nil
		savedFolderParent = nil
	end
end

LookDev.register("spawn_ground_r5", { apply = apply, restore = restore })

LookDevSpawnGroundR5.apply = apply
LookDevSpawnGroundR5.restore = restore

return LookDevSpawnGroundR5
