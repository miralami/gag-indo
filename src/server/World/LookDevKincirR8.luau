--!strict
-- LookDevKincirR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "kincir_r8" candidate
-- (WORK_QUEUE section N item 114). Stages one folder of original Parts: one wooden waterwheel with
-- a hub, axle, eight spokes and eight paddles around a rotating root, plus two static support posts
-- on the north river bank. Every part is anchored, non-collidable and tagged. ONE RunService
-- Heartbeat connection turns the whole wheel at Data.DEG_PER_SEC degrees per second and publishes
-- the live angle as a numeric WheelAngle attribute on the root. No Terrain read or write. Game APIs
-- are pcall guarded and failures pad the published LookDevFailures counter. Enable from the Server
-- command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("kincir_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevKincirR8] missing service " .. name)
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
		warn("[LookDevKincirR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapKincirR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevKincirR8] could not require LookDev / ModelMapKincirR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevKincirR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevKincirR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local applied = false
local connection: any = nil
local wheelRoot: any? = nil
local rotating: { any } = {}
local baseFrames: { [any]: any } = {}
local angle = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevKincirR8] " .. message)
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
	wheelRoot = nil
	rotating = {}
	baseFrames = {}
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

local function mapGeometry()
	if
		not MapSpec
		or type((MapSpec :: any).riverCentreZ) ~= "function"
		or type((MapSpec :: any).GROUND_Y) ~= "number"
	then
		fail("MapSpec riverCentreZ / GROUND_Y unavailable")
		return nil, nil
	end
	return (MapSpec :: any).riverCentreZ, (MapSpec :: any).GROUND_Y
end

-- The shared loop body. Also exposed as pump(dt) so the review harness can drive the exact same
-- function deterministically without waiting on wall-clock Heartbeat ticks.
local function tick(dt: number)
	if not applied then
		return
	end
	angle = (angle + Data.DEG_PER_SEC * dt) % 360
	for _, part in ipairs(rotating) do
		local base = baseFrames[part]
		if base then
			local turned = base * CFrame.Angles(0, 0, math.rad(angle))
			pcall(function()
				part.CFrame = turned
			end)
		end
	end
	local root = wheelRoot
	if root then
		pcall(function()
			root:SetAttribute(Data.angleAttribute, angle)
		end)
	end
end

local function addPart(folder: any, recipe: any, x: number, y: number, z: number): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Kincir_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(x, y, z) * CFrame.Angles(math.rad(recipe.rx), 0, math.rad(recipe.roll))
		if recipe.shape == "cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
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
	angle = 0
	if not Workspace then
		fail("missing Workspace")
		publishFailures()
		return
	end
	local centreFn, groundY = mapGeometry()
	if not centreFn or not groundY then
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
		local x, z = Data.worldXZ(Data.SITE, recipe.lx, recipe.lz, centreFn)
		local part = addPart(folder, recipe, x, groundY + Data.WHEEL_CENTRE_LY + recipe.ly, z)
		if part then
			if recipe.kind == Data.WHEELROOT_KIND then
				wheelRoot = part
				pcall(function()
					part:SetAttribute(Data.angleAttribute, angle)
				end)
			end
		end
	end

	-- Parent every rotating piece under the single wheel root, then cache its angle-zero world
	-- CFrame. Anchored children do not follow a parent's CFrame, so the loop rewrites each one.
	for _, part in ipairs(staged) do
		if part ~= folder and part ~= wheelRoot then
			local okKind, kind = pcall(function()
				return part:GetAttribute(Data.kindAttribute)
			end)
			if okKind and kind == Data.SUPPORT_KIND then
				continue
			end
			pcall(function()
				part.Parent = wheelRoot
			end)
		end
	end
	for _, part in ipairs(staged) do
		if part ~= folder then
			local okKind, kind = pcall(function()
				return part:GetAttribute(Data.kindAttribute)
			end)
			if okKind and kind ~= Data.SUPPORT_KIND then
				local okFrame, frame = pcall(function()
					return part.CFrame
				end)
				if okFrame and frame then
					rotating[#rotating + 1] = part
					baseFrames[part] = frame
				end
			end
		end
	end

	if wheelRoot and #rotating > 0 then
		local okConnect, result = pcall(function()
			return (RunService :: any).Heartbeat:Connect(tick)
		end)
		if okConnect then
			connection = result
		else
			fail("Heartbeat connect failed: " .. tostring(result))
		end
	else
		fail("no wheel root staged")
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
function LookDevKincirR8.wheelRoot(): any?
	return wheelRoot
end

function LookDevKincirR8.connectionCount(): number
	return connection and 1 or 0
end

function LookDevKincirR8.isApplied(): boolean
	return applied
end

function LookDevKincirR8.pump(dt: number?): number
	local stepDt = type(dt) == "number" and dt or 1 / 60
	tick(stepDt)
	return angle
end

LookDevKincirR8.apply = apply
LookDevKincirR8.restore = restore

LookDev.register(Data.familyId, { apply = apply, restore = restore })

return LookDevKincirR8
