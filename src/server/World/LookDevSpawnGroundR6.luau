--!nocheck
-- LookDevSpawnGroundR6: SERVER-ONLY applier for the OFF-BY-DEFAULT "spawn_ground_r6" candidate
-- (WORK_QUEUE item 45). Server-created Parts replicate to the Client viewport; no client hook.
--
-- Nothing happens until LookDev.enable("spawn_ground_r6") is called from Studio. apply() hides the
-- Greybox road/arm/ring/continuation/RoadEdge Parts, overlapping MudPatches and any FloraGrass
-- wedge whose XZ footprint touches a flower bed or a tagged plot. It records the EXACT prior
-- Visible/CanCollide of every hidden Instance, then builds tanah Parts over the FULL road corridor
-- footprint (including the 30-wide Terrain ring strip R5 left dark) in its own Workspace Folder.
-- restore() restores every recorded state exactly and destroys everything it created. The default
-- buildRoads / MapSpec / Greybox / Flora / Decor code stays untouched.
--
-- No asset IDs live here: colours/materials/heights/margins come from Shared.SpawnGroundMapR6.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SpawnGroundMapR6 = require(Shared.SpawnGroundMapR6)
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local MapSpec = require(script.Parent.MapSpec)
local Map = require(script.Parent.Map)

local LookDevSpawnGroundR6 = {}

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
-- rotated off-axis can never slip past the rectangle mask.
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
	for _, path in ipairs(SpawnGroundMapR6.pathRects(MapSpec)) do
		names[path.name] = true
	end
	return names
end

local function hideExisting(all: { Instance }, paths: { any }, covers: { any })
	local names = roadNames()
	for _, instance in ipairs(all) do
		if instance:IsA("BasePart") and names[instance.Name] then
			hide(instance)
		end
	end
	-- A MudPatch disc is Size.Y x Size.Z in world XZ (cylinder laid on its side); max component
	-- plus slack covers any author rotation. Hide it under either tanah layer.
	local slack = SpawnGroundMapR6.exclusionMargins.mud
	for _, instance in ipairs(all) do
		if instance:IsA("BasePart") and instance.Name == "MudPatch" then
			local okPart, position, size = pcall(function()
				return instance.Position, instance.Size
			end)
			if okPart then
				local radius = math.max(size.X, size.Y, size.Z) / 2 + slack
				local disc = { x = position.X, z = position.Z, halfX = radius, halfZ = radius }
				local blocked = false
				for _, path in ipairs(paths) do
					if SpawnGroundMapR6.intersects(disc, SpawnGroundMapR6.featherRect(path)) then
						blocked = true
						break
					end
				end
				if not blocked then
					for _, cover in ipairs(covers) do
						if SpawnGroundMapR6.intersects(disc, cover) then
							blocked = true
							break
						end
					end
				end
				if blocked then
					hide(instance)
				end
			end
		end
	end
end

-- Mask, not a generator edit: only the offending wedges are hidden, and their exact prior state is
-- restored on disable. Flower beds and tagged plots keep every other Flora part unchanged.
local function hideMaskedGrass(all: { Instance }, anchors: { any })
	local zones = SpawnGroundMapR6.grassExclusionRects(MapSpec, anchors)
	if #zones == 0 then
		return
	end
	for _, instance in ipairs(all) do
		if instance:IsA("WedgePart") and instance.Name == "FloraGrass" then
			local okPart, position, size = pcall(function()
				return instance.Position, instance.Size
			end)
			if okPart then
				local footprint = SpawnGroundMapR6.grassRect(position.X, position.Z, size.X, size.Z)
				if SpawnGroundMapR6.grassBlocked(footprint, zones) then
					hide(instance)
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
	local name = SpawnGroundMapR6.folderName
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
	prefix: string,
	label: string,
	x: number,
	z: number,
	yaw: number,
	width: number,
	depth: number,
	height: number,
	thickness: number,
	colour: { number },
	materialName: string,
	transparency: number
)
	local part = Instance.new("Part")
	part.Name = "R6_" .. prefix .. "_" .. label
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(width, thickness, depth)
	part.CFrame = CFrame.new(x, MapSpec.GROUND_Y + height, z) * CFrame.Angles(0, math.rad(yaw), 0)
	part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
	part.Material = Enum.Material[materialName]
	part.Transparency = transparency
	part.Parent = folder
end

local function buildCovers(covers: { any })
	local folder = makeFolder()
	local heights = SpawnGroundMapR6.heights
	for index, cover in ipairs(covers) do
		addPart(
			folder,
			"Corridor",
			cover.name,
			cover.x,
			cover.z,
			0,
			cover.sx,
			cover.sz,
			heights.corridorLift + (index % 8) * heights.corridorStagger,
			heights.corridorThickness,
			SpawnGroundMapR6.colours.corridor,
			SpawnGroundMapR6.materials.corridor,
			0
		)
	end
end

local function buildPaths(paths: { any })
	local folder = makeFolder()
	local heights = SpawnGroundMapR6.heights
	local feather = SpawnGroundMapR6.feather
	for _, path in ipairs(paths) do
		local underlay = SpawnGroundMapR6.featherRect(path)
		addPart(
			folder,
			"Feather",
			path.name,
			path.x,
			path.z,
			path.yaw,
			underlay.sx,
			underlay.sz,
			heights.featherLift,
			heights.featherThickness,
			SpawnGroundMapR6.colours.feather,
			SpawnGroundMapR6.materials.feather,
			feather.transparency
		)
		addPart(
			folder,
			"Path",
			path.name,
			path.x,
			path.z,
			path.yaw,
			path.sx,
			path.sz,
			heights.pathLift,
			heights.pathThickness,
			SpawnGroundMapR6.colours.path,
			SpawnGroundMapR6.materials.path,
			0
		)
	end
end

local function apply()
	clearCreated()
	local anchors = anchorRects()
	local paths = SpawnGroundMapR6.allowedRects(MapSpec, anchors)
	local covers = SpawnGroundMapR6.coverRects(MapSpec, anchors)
	local all = descendants()
	hideExisting(all, paths, covers)
	hideMaskedGrass(all, anchors)
	buildCovers(covers)
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

LookDev.register("spawn_ground_r6", { apply = apply, restore = restore })

LookDevSpawnGroundR6.apply = apply
LookDevSpawnGroundR6.restore = restore

return LookDevSpawnGroundR6
