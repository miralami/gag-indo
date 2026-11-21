--!strict
-- LookDevLayanganR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "layangan_r8" candidate
-- (WORK_QUEUE section N item 116). Stages one folder of original Parts: four kites over the Lapangan
-- field, each a diamond sail with a spine, cross-spar and thin tail, plus a textureless Beam string
-- to a kid-sized ground anchor. Every BasePart is anchored, non-collidable and tagged. ONE
-- RunService.Heartbeat connection rocks the 28-part sail assemblies (root/spine/spar/sail) of all
-- four kites by a gentle sine tilt and publishes the live angle as a numeric KiteAngle attribute on
-- each root. Tails stay static: 44 distinct CFrame writes/step measure ~0.235ms (over the 0.2ms
-- budget) while 28 moving Parts measure ~0.14ms, so a tail hangs while its sail rocks. No Terrain
-- read or write, no asset IDs, no decals. Game APIs are pcall guarded and failures pad the
-- published LookDevFailures counter.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("layangan_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevLayanganR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local RunService = service("RunService")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevLayanganR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapLayanganR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevLayanganR8] could not require LookDev / ModelMapLayanganR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevLayanganR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevLayanganR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local applied = false
local connection: any = nil
local kiteRootsList: { any } = {}
local anchorList: { any } = {}
local beamList: { any } = {}
local moving: { [number]: { any } } = {}
local pivotFrames: { [any]: any } = {}
local baseFrames: { [any]: any } = {}
local elapsed = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevLayanganR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function disconnectLoop()
	local current = connection
	connection = nil
	if current then
		pcall(function()
			current:Disconnect()
		end)
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
	kiteRootsList = {}
	anchorList = {}
	beamList = {}
	moving = {}
	pivotFrames = {}
	baseFrames = {}
	elapsed = 0
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

-- The shared loop body, also exposed as pump(dt) so the review harness can drive the exact same
-- function deterministically with os.clock instead of noisy wall-clock Heartbeat timing. Only the
-- moving[site] sail Parts (28 total) get CFrame writes; tails and anchors stay static so the
-- per-step cost stays ~0.14ms instead of ~0.235ms for all 44 Parts.
local function tick(dt: number)
	if not applied then
		return
	end
	elapsed += dt
	for index, root in ipairs(kiteRootsList) do
		local pivot = pivotFrames[root]
		if pivot then
			local tilt = Data.ROCK_AMPLITUDE_DEG
				* math.sin(2 * math.pi * elapsed / Data.ROCK_PERIOD + (index - 1) * Data.ROCK_PHASE_STEP)
			local delta = pivot * CFrame.Angles(0, 0, math.rad(tilt)) * pivot:Inverse()
			for _, part in ipairs(moving[index] or {}) do
				local base = baseFrames[part]
				if base then
					pcall(function()
						part.CFrame = delta * base
					end)
				end
			end
			pcall(function()
				root:SetAttribute(Data.angleAttribute, tilt)
			end)
		end
	end
end

local function addPart(folder: any, recipe: any, groundY: number): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Layangan_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(recipe.lx, groundY + recipe.ly, recipe.lz) * CFrame.Angles(0, 0, math.rad(recipe.roll))
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.root
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Wood"] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, recipe.kind)
		part.Parent = folder
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. tostring(recipe.name))
		return nil
	end
	track(created)
	return created
end

local function addString(folder: any, index: number, root: any, anchor: any)
	local ok, beam = pcall(function()
		local top = Instance.new("Attachment")
		top.Name = "Layangan_StringTop_" .. index
		top.Parent = root
		track(top)
		local foot = Instance.new("Attachment")
		foot.Name = "Layangan_StringFoot_" .. index
		foot.Position = Vector3.new(0, 1.5, 0)
		foot.Parent = anchor
		track(foot)
		local created = Instance.new("Beam")
		created.Name = "Layangan_String_" .. index
		created.Color =
			ColorSequence.new(Color3.fromRGB(Data.BEAM.faceColour[1], Data.BEAM.faceColour[2], Data.BEAM.faceColour[3]))
		created.Width0 = Data.BEAM.width
		created.Width1 = Data.BEAM.width
		created.Segments = Data.BEAM.segments
		created.Attachment0 = top
		created.Attachment1 = foot
		created:SetAttribute(Data.stageAttribute, Data.familyId)
		created:SetAttribute(Data.kindAttribute, Data.BEAM_KIND)
		created.Parent = folder
		return created
	end)
	if not ok or not beam then
		fail("could not stage string " .. tostring(index) .. ": " .. tostring(beam))
		return
	end
	track(beam)
	beamList[index] = beam
end

local function groundYOf(): number?
	if not MapSpec or type((MapSpec :: any).GROUND_Y) ~= "number" then
		fail("MapSpec GROUND_Y unavailable")
		return nil
	end
	return (MapSpec :: any).GROUND_Y
end

local function apply()
	if applied then
		return
	end
	disconnectLoop()
	clearActive()
	failures = 0
	pcall(function()
		LookDevFailures.reset(Data.familyId)
	end)
	elapsed = 0
	if not Workspace then
		fail("missing Workspace")
		publishFailures()
		return
	end
	local groundY = groundYOf()
	if not groundY then
		publishFailures()
		return
	end
	local previous = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end
	local folder = newFolder(Data.folderName, Workspace)
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder
	track(folder)
	pcall(function()
		folder:SetAttribute(Data.stageAttribute, Data.familyId)
	end)

	for _, recipe in ipairs(Data.parts()) do
		local part = addPart(folder, recipe, groundY)
		if part then
			local site = recipe.site
			if recipe.kind == Data.ROOT_KIND then
				kiteRootsList[site] = part
				pcall(function()
					part:SetAttribute(Data.angleAttribute, 0)
				end)
			elseif recipe.kind == Data.ANCHOR_KIND then
				anchorList[site] = part
			end
			if recipe.kind ~= Data.ANCHOR_KIND and recipe.kind ~= Data.KIND.tail then
				if not moving[site] then
					moving[site] = {}
				end
				local list = moving[site]
				list[#list + 1] = part
				baseFrames[part] = part.CFrame
				if recipe.kind == Data.ROOT_KIND then
					pivotFrames[part] = part.CFrame
				end
			end
		end
	end

	for index, root in ipairs(kiteRootsList) do
		local anchor = anchorList[index]
		if root and anchor then
			addString(folder, index, root, anchor)
		end
	end

	if #kiteRootsList == 4 and #anchorList == 4 and #beamList == 4 then
		local okConnect, result = pcall(function()
			return (RunService :: any).Heartbeat:Connect(tick)
		end)
		if okConnect then
			connection = result
		else
			fail("Heartbeat connect failed: " .. tostring(result))
		end
	else
		fail("no complete kite set staged")
	end
	applied = true
	publishFailures()
end

local function restore()
	if not applied then
		return
	end
	applied = false
	disconnectLoop()
	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	publishFailures()
end

-- Diagnostics ---------------------------------------------------------------------------------
function LookDevLayanganR8.kiteRoots(): { any }
	return kiteRootsList
end

function LookDevLayanganR8.anchors(): { any }
	return anchorList
end

function LookDevLayanganR8.beams(): { any }
	return beamList
end

function LookDevLayanganR8.connectionCount(): number
	return connection and 1 or 0
end

function LookDevLayanganR8.isApplied(): boolean
	return applied
end

function LookDevLayanganR8.pump(dt: number?): number
	local stepDt = type(dt) == "number" and dt or Data.DT
	tick(stepDt)
	return elapsed
end

LookDevLayanganR8.apply = apply
LookDevLayanganR8.restore = restore

LookDev.register(Data.familyId, { apply = apply, restore = restore })

return LookDevLayanganR8
