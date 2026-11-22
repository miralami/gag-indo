--!strict
-- LookDevAmbientWalkersR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "ambient_walkers_r8"
-- candidate (WORK_QUEUE section M item 88). It stages up to 8 plain R15 villagers (skin-colour
-- HumanoidDescription, NO catalog outfit / asset ID) on MapSpec road centrelines and drives each
-- one around its looped route by calling the REAL NpcWalk.walkTo in a task.spawn loop with a
-- per-walker cancellation token. Ambient only: no interaction object, no conversation object,
-- no collision hook, no gameplay state. restore() is exact and idempotent.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevAmbientWalkersR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Players = service("Players")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and value then
		Shared = value
	else
		warn("[LookDevAmbientWalkersR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, NpcWalk, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapAmbientWalkersR8),
		require(script.Parent.NpcWalk),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not NpcWalk or not LookDevFailures then
	warn("[LookDevAmbientWalkersR8] could not require LookDev / walkers map / NpcWalk / LookDevFailures")
	return {}
end

local LookDevAmbientWalkersR8 = {}

local FAMILY_ID = Data.lookDevId
local activeFolder: any? = nil
local savedFolder: any? = nil
local applied = false
local failures = 0

local walkers: { any } = {}
local routes: { any } = {}
local basePivots: { [any]: any } = {}
local tokens: { [any]: { cancelled: boolean } } = {}
local threads: { any } = {}
local routeNames: { [any]: string } = {}
local reached: { [string]: number } = {}
local loopCountValue = 0

local function fail(routeName: string, message: string)
	failures += 1
	warn("[LookDevAmbientWalkersR8] " .. routeName .. ": " .. message)
end

local function findPrevious(): any?
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(Data.folder)
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	local ok, folder = pcall(Instance.new, "Folder")
	if not ok or not folder then
		warn("[LookDevAmbientWalkersR8] could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = Data.folder
		folder.Parent = Workspace
	end)
	return folder
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function resetDiagnostics()
	walkers, routes, threads = {}, {}, {}
	basePivots, tokens, routeNames, reached = {}, {}, {}, {}
	loopCountValue = 0
end

-- Plain R15 body: only skin colours, no Shirt/Pants/hat asset IDs.
local function buildRig(routeName: string, index: number): any?
	local okDescription, value = pcall(Instance.new, "HumanoidDescription")
	if not okDescription or not value then
		fail(routeName, "HumanoidDescription unavailable")
		return nil
	end
	local hd: any = value
	local tone = 150 + (index * 11) % 60
	local okColours, colourError = pcall(function()
		local skin = Color3.fromRGB(tone, math.max(90, tone - 42), math.max(70, tone - 68))
		hd.HeadColor = skin
		hd.LeftArmColor = skin
		hd.RightArmColor = skin
		hd.TorsoColor = skin
		hd.LeftLegColor = skin
		hd.RightLegColor = skin
	end)
	if not okColours then
		fail(routeName, "skin colours failed: " .. tostring(colourError))
		return nil
	end

	local rig = nil
	local okSync, syncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescription
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return create(Players, hd, Enum.HumanoidRigType.R15)
	end)
	if okSync and syncRig then
		rig = syncRig
	else
		local okAsync, asyncRig = pcall(function()
			local create = (Players :: any).CreateHumanoidModelFromDescriptionAsync
			if type(create) ~= "function" then
				error("CreateHumanoidModelFromDescriptionAsync unavailable")
			end
			return create(Players, hd, Enum.HumanoidRigType.R15)
		end)
		if okAsync and asyncRig then
			rig = asyncRig
		else
			fail(routeName, "R15 rig unavailable: " .. tostring(syncRig) .. " / " .. tostring(asyncRig))
			return nil
		end
	end
	return rig
end

local function configureRig(rig: any, routeName: string): boolean
	local okHumanoid, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if not okHumanoid or not humanoid then
		fail(routeName, "no Humanoid")
		return false
	end
	pcall(function()
		humanoid.WalkSpeed = Data.WALK_SPEED
		humanoid.AutoRotate = false -- PivotTo owns the facing; no rotation fight with the walk loop
	end)
	local okParts, parts = pcall(function()
		return rig:GetDescendants()
	end)
	if okParts and type(parts) == "table" then
		for _, part in ipairs(parts) do
			pcall(function()
				if (part :: any):IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end)
		end
	end
	return true
end

local function groundRig(rig: any, waypoint: any, routeName: string): boolean
	local okBox, boxCFrame, boxSize = pcall(function()
		return rig:GetBoundingBox()
	end)
	if not okBox or not boxCFrame or not boxSize then
		fail(routeName, "could not measure rig bounds")
		return false
	end
	local bottomOffset = boxCFrame.Y - boxSize.Y * 0.5 - Data.GROUND_Y
	local okPivot, pivot = pcall(function()
		return CFrame.new(waypoint.x, waypoint.y - bottomOffset, waypoint.z)
	end)
	if not okPivot or not pivot then
		fail(routeName, "could not build ground CFrame")
		return false
	end
	if pcall(function()
		rig:PivotTo(pivot)
	end) then
		return true
	end
	return pcall(function()
		rig:SetPrimaryPartCFrame(pivot)
	end)
end

-- One real NpcWalk loop per walker. walkTo yields via task.wait; the cancellation callback ends
-- the loop on restore without a fallback teleport (NpcWalk returns false without moving).
local function startLoop(rig: any, route: any, base: any, routeName: string)
	local token = { cancelled = false }
	tokens[rig] = token
	threads[#threads + 1] = task.spawn(function()
		local index = 2
		while applied and not token.cancelled do
			local point = route.waypoints[index]
			local target = Vector3.new(point.x, base.Position.Y, point.z)
			local okWalk, arrived = pcall(function()
				return NpcWalk.walkTo(rig, target, Data.WALK_SPEED, function()
					return token.cancelled or not applied
				end)
			end)
			if not okWalk or arrived ~= true then
				break
			end
			reached[routeName] = (reached[routeName] or 0) + 1
			loopCountValue += 1
			index = index % #route.waypoints + 1
		end
	end)
end

local function stopLoops()
	applied = false
	for _, token in pairs(tokens) do
		token.cancelled = true
	end
	for _, thread in ipairs(threads) do
		pcall(task.cancel, thread)
	end
	threads = {}
	tokens = {}
end

local function apply()
	if applied then
		return
	end
	clearActive()
	failures = 0
	pcall(function()
		(LookDevFailures :: any).reset(FAMILY_ID)
	end)
	resetDiagnostics()

	routes = Data.routes()
	local previous = findPrevious()
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end
	local folder = newFolder()
	if not folder then
		LookDevFailures.set(FAMILY_ID, failures)
		return
	end
	activeFolder = folder
	applied = true

	for index, route in ipairs(routes) do
		if index > Data.MAX_WALKERS then
			break
		end
		local routeName = route.name
		local rig = buildRig(routeName, index)
		if rig then
			pcall(function()
				rig.Name = "AmbientWalkerR8_" .. index .. "_" .. routeName
				rig:SetAttribute("LookDevWalkers", FAMILY_ID)
				rig:SetAttribute("Role", "villager")
				rig:SetAttribute("RouteName", routeName)
				rig:SetAttribute("WalkSpeed", Data.WALK_SPEED)
			end)
			if configureRig(rig, routeName) and groundRig(rig, route.waypoints[1], routeName) then
				pcall(function()
					rig.Parent = folder
				end)
				local okPivot, pivot = pcall(function()
					return rig:GetPivot()
				end)
				if okPivot and pivot then
					walkers[#walkers + 1] = rig
					basePivots[rig] = pivot
					routeNames[rig] = routeName
					reached[routeName] = 0
					startLoop(rig, route, pivot, routeName)
				else
					fail(routeName, "base pivot unreadable")
				end
			end
		end
	end

	if #walkers == 0 then
		fail("loop", "no villagers staged")
	end
	LookDevFailures.set(FAMILY_ID, failures)
end

local function restore()
	if not applied then
		return
	end
	stopLoops()

	for _, rig in ipairs(walkers) do
		local base = basePivots[rig]
		if base then
			pcall(function()
				rig:PivotTo(base)
			end)
		end
	end

	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	resetDiagnostics()
end

-- Diagnostics ---------------------------------------------------------------------------------
function LookDevAmbientWalkersR8.walkers(): { any }
	return table.clone(walkers)
end

function LookDevAmbientWalkersR8.walkSpeed(rig: any): number?
	local okHumanoid, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if not okHumanoid or not humanoid then
		return nil
	end
	local okSpeed, speed = pcall(function()
		return humanoid.WalkSpeed
	end)
	return if okSpeed and type(speed) == "number" then speed else nil
end

function LookDevAmbientWalkersR8.waypointsReached(): { [string]: number }
	return table.clone(reached)
end

function LookDevAmbientWalkersR8.basePivot(rig: any): any?
	return basePivots[rig]
end

function LookDevAmbientWalkersR8.routeName(rig: any): string?
	return routeNames[rig]
end

function LookDevAmbientWalkersR8.isApplied(): boolean
	return applied
end

function LookDevAmbientWalkersR8.loopCount(): number
	return loopCountValue
end

function LookDevAmbientWalkersR8.failureCount(): number
	return failures
end

LookDevAmbientWalkersR8.apply = apply
LookDevAmbientWalkersR8.restore = restore
LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevAmbientWalkersR8
