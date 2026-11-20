--!strict
-- LookDevPathEdgeR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "pathedge_r8" candidate
-- (WORK_QUEUE section M item 75). Dirt-path edge dressing: grass tufts, pebbles and flat puddles
-- along both edges of every road arm, ring segment and continuation.
--
-- PROCEDURAL PARTS, NO ASSET IDS. Terrain, road slabs, RoadEdge strips, RingRoad pieces, buildings
-- and the ford are never edited: every piece is a plain Part built from pure data in
-- Shared.ModelMapPathEdgeR8 using the real MapSpec road geometry. All Parts are anchored,
-- non-collidable, tagged, and removed by restore() (which reattaches any prior folder).
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("pathedge_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPathEdgeR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedValue = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedValue then
	Shared = sharedValue
else
	warn("[LookDevPathEdgeR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapPathEdgeR8)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevPathEdgeR8] could not require LookDev / ModelMapPathEdgeR8")
	return {}
end

local MapSpec: any? = nil
local okSpec, specValue = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and specValue and type(specValue.roadArms) == "function" and type(specValue.ROAD) == "table" then
	MapSpec = specValue
else
	warn("[LookDevPathEdgeR8] could not require MapSpec")
end

local LookDevPathEdgeR8 = {}

local FAMILY_ID = Data.id
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

-- Procedural parts only: a clean apply publishes 0. Geometry failures move the counter.
local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevPathEdgeR8] " .. message)
end

local function taggedFolder(name: string, parent: any): any?
	local folder: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Folder")
	end)
	if ok and created then
		folder = created
	end
	if not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
		folder.Parent = parent
	end)
	return folder
end

local function taggedPart(kind: string, name: string, path: string, side: string, parent: any): any?
	local part: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Part")
	end)
	if ok and created then
		part = created
	end
	if not part then
		return nil
	end
	pcall(function()
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
		part:SetAttribute("Kind", kind)
		part:SetAttribute("Path", path)
		part:SetAttribute("Side", side)
		part.Parent = parent
	end)
	return part
end

local function place(part: any?, centre: { number }, size: { number }): boolean
	if not part then
		return false
	end
	local ok = pcall(function()
		part.Size = Vector3.new(size[1], size[2], size[3])
		part.CFrame = CFrame.new(centre[1], centre[2], centre[3])
	end)
	return ok
end

local function apply()
	failures = 0
	if activeFolder then
		publishFailures()
		return
	end

	local previous: any? = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder: any? = nil
	local okNew, created = pcall(function()
		return Instance.new("Folder")
	end)
	if okNew and created then
		folder = created
		pcall(function()
			folder.Name = Data.folderName
			folder:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	if not MapSpec then
		fail("missing MapSpec road geometry")
		publishFailures()
		return
	end

	local arms = MapSpec.roadArms()
	local ring = MapSpec.ringSegments()
	local continuations = MapSpec.roadContinuations()
	local pieces = Data.allPieces(arms, ring, continuations)
	if #pieces < Data.MIN_EDGE_PIECES then
		fail("only " .. #pieces .. " edge pieces")
	end

	local roadY = MapSpec.ROAD.y
	local pathFolders: { [string]: any } = {}
	for index, piece in ipairs(pieces) do
		local pathFolder = pathFolders[piece.path]
		if not pathFolder then
			pathFolder = taggedFolder(piece.path, folder)
			pathFolders[piece.path] = pathFolder
		end
		local part = taggedPart(
			piece.kind,
			piece.kind .. "_" .. piece.path .. "_" .. index,
			piece.path,
			piece.side,
			pathFolder or folder
		)
		if part then
			pcall(function()
				if piece.kind == "puddle" then
					part.Material = Enum.Material.SmoothPlastic
					part.Transparency = Data.PUDDLE_TRANSPARENCY
					part.Color = Color3.fromRGB(72, 112, 138)
				elseif piece.kind == "pebble" then
					part.Material = Enum.Material.Rock
					part.Color = Color3.fromRGB(136, 132, 122)
				else
					part.Material = Enum.Material.Grass
					part.Color = Color3.fromRGB(106, 138, 62)
				end
			end)
		end
		local centre, size
		if piece.kind == "puddle" then
			centre = { piece.x, roadY + 0.06, piece.z }
			size = { 2, 0.05, 1.2 }
		elseif piece.kind == "pebble" then
			centre = { piece.x, roadY + 0.15, piece.z }
			size = { 0.4, 0.3, 0.4 }
		else
			centre = { piece.x, roadY + 0.4, piece.z }
			size = { 0.5, 0.8, 0.5 }
		end
		if not place(part, centre, size) then
			fail("could not place edge piece " .. index)
		end
	end

	publishFailures()
end

local function restore()
	if activeFolder then
		pcall(function()
			activeFolder:Destroy()
		end)
		activeFolder = nil
	end
	if savedFolder then
		pcall(function()
			savedFolder.Parent = Workspace
		end)
		savedFolder = nil
	end
end

LookDevPathEdgeR8.apply = apply
LookDevPathEdgeR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevPathEdgeR8
