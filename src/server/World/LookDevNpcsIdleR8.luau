--!strict
-- LookDevNpcsIdleR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "npcs_idle_r8" candidate
-- (WORK_QUEUE section M item 87). It stages its OWN ten R15 villagers from the two verified pure
-- catalog maps (R7 + R8), gives each an Animator track of the real catalog "Standing Idle"
-- animation (rbxassetid://71483261700852) and drives a <=1 degree breathing sway from ONE
-- Heartbeat loop calling the shared pure ModelMapNpcsIdleR8.step(). No walking, no asset ID is
-- invented and no other candidate is required. restore() is exact and idempotent.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevNpcsIdleR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Players = service("Players")
local Workspace = service("Workspace")
local RunService = service("RunService")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and value then
		Shared = value
	else
		warn("[LookDevNpcsIdleR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, R7, R8, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapNpcsIdleR8),
		require((Shared :: any).ModelMapNpcsR7),
		require((Shared :: any).ModelMapNpcsR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not R7 or not R8 or not LookDevFailures then
	warn("[LookDevNpcsIdleR8] could not require LookDev / Idle map / R7 / R8 / LookDevFailures")
	return {}
end

local LookDevNpcsIdleR8 = {}

local FAMILY_ID = "npcs_idle_r8"
local activeFolder: any? = nil
local savedFolder: any? = nil
local applied = false
local connection: any = nil
local failures = 0

local targets: { any } = {}
local basePivots: { [any]: any } = {}
local tracks: { any } = {}
local animations: { any } = {}
local entries: { any } = {}
local swayActive = false
local restoreAudit = { count = 0, maxDelta = 0, mismatches = 0 }

local function fail(roleName: string, message: string)
	failures += 1
	warn("[LookDevNpcsIdleR8] " .. roleName .. ": " .. message)
end

local function warnRole(roleName: string, warned: { [string]: boolean }, message: string)
	if warned[roleName] then
		return
	end
	warned[roleName] = true
	warn("[LookDevNpcsIdleR8] " .. roleName .. ": " .. message)
end

local function folderName(): string
	return Data.folder
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

local function findPrevious(): any?
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(folderName())
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	local ok, folder = pcall(Instance.new, "Folder")
	if not ok or not folder then
		warn("[LookDevNpcsIdleR8] could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = folderName()
		folder.Parent = Workspace
	end)
	return folder
end

-- Same verified HumanoidDescription build path as the npcs_r8 applier: catalog shirt/pants,
-- layered shirt accessory, hats and (for the kid) authoritative rig scale writes.
local function buildRig(descriptor: any, warned: { [string]: boolean }): any?
	local roleName = descriptor.role
	local okDescription, value = pcall(Instance.new, "HumanoidDescription")
	if not okDescription or not value then
		warnRole(roleName, warned, "HumanoidDescription unavailable")
		return nil
	end
	local hd: any = value
	local colours = descriptor.colours or {}
	local skin = colours.skin or { r = 180, g = 138, b = 105 }
	local okColours = pcall(function()
		local colour = Color3.fromRGB(skin.r, skin.g, skin.b)
		hd.HeadColor = colour
		hd.LeftArmColor = colour
		hd.RightArmColor = colour
		hd.TorsoColor = colour
		hd.LeftLegColor = colour
		hd.RightLegColor = colour
	end)
	if not okColours then
		warnRole(roleName, warned, "could not set HumanoidDescription colours")
		return nil
	end

	local catalog = descriptor.catalog or {}
	local okCatalog, catalogError = pcall(function()
		if catalog.shirt then
			hd.Shirt = catalog.shirt
		end
		if catalog.pants then
			hd.Pants = catalog.pants
		end
		local accessories = {}
		for _, hatId in ipairs(catalog.hats or {}) do
			table.insert(accessories, { AccessoryType = Enum.AccessoryType.Hat, AssetId = hatId, IsLayered = false })
		end
		if catalog.layeredShirt then
			table.insert(accessories, {
				AccessoryType = Enum.AccessoryType.Shirt,
				AssetId = catalog.layeredShirt,
				IsLayered = true,
				Order = 1,
			})
		end
		hd:SetAccessories(accessories, true)
	end)
	if not okCatalog then
		fail(roleName, "catalog outfit failed: " .. tostring(catalogError))
	end

	for key, scale in pairs({ BodyHeightScale = descriptor.bodyHeightScale, HeadScale = descriptor.headScale }) do
		if scale ~= nil then
			pcall(function()
				hd[key] = scale
			end)
		end
	end

	local okAsync, asyncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescriptionAsync
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescriptionAsync unavailable")
		end
		return create(Players, hd, Enum.HumanoidRigType.R15)
	end)
	if okAsync and asyncRig then
		return asyncRig
	end
	local okSync, syncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescription
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return create(Players, hd, Enum.HumanoidRigType.R15)
	end)
	if okSync and syncRig then
		return syncRig
	end
	warnRole(roleName, warned, "R15 rig unavailable: " .. tostring(syncRig))
	return nil
end

local function scaleRig(rig: any, descriptor: any, roleName: string, warned: { [string]: boolean })
	if descriptor.bodyHeightScale == nil and descriptor.headScale == nil then
		return
	end
	local okHumanoid, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if not okHumanoid or not humanoid then
		warnRole(roleName, warned, "no Humanoid for scale")
		return
	end
	for key, value in pairs({ BodyHeightScale = descriptor.bodyHeightScale, HeadScale = descriptor.headScale }) do
		if value ~= nil then
			local okScale = pcall(function()
				local node = humanoid[key]
				if typeof(node) ~= "Instance" then
					error("scale node missing")
				end
				node.Value = value
			end)
			if not okScale then
				warnRole(roleName, warned, key .. " unsupported on rig")
			end
		end
	end
end

local function groundRig(model: any, slot: any, roleName: string, warned: { [string]: boolean }): boolean
	local okBox, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not okBox or not boxCFrame or not boxSize or not okPivot or not pivot then
		warnRole(roleName, warned, "could not measure rig bounds")
		return false
	end
	local bottomOffset = boxCFrame.Y - boxSize.Y * 0.5 - pivot.Y
	local okTarget, target = pcall(function()
		return CFrame.new(slot.x, slot.y - bottomOffset, slot.z) * CFrame.Angles(0, slot.ry, 0)
	end)
	if not okTarget or not target then
		warnRole(roleName, warned, "could not build ground CFrame")
		return false
	end
	if pcall(function()
		model:PivotTo(target)
	end) then
		return true
	end
	return pcall(function()
		model:SetPrimaryPartCFrame(target)
	end)
end

local function configureParts(model: any)
	local ok, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, descendant in ipairs(descendants) do
		pcall(function()
			if (descendant :: any):IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end)
	end
end

-- R15 rigs normally have an Animator, but create one under Humanoid when it is absent so every
-- staged villager always owns a playing track (the harness checks track.IsPlaying for all ten).
local function attachIdleTrack(rig: any, roleName: string, folder: any): any?
	local okHumanoid, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if not okHumanoid or not humanoid then
		fail(roleName, "no Humanoid for Animator")
		return nil
	end
	local animator = nil
	pcall(function()
		animator = humanoid:FindFirstChildOfClass("Animator")
	end)
	if not animator then
		local okAnimator, created = pcall(function()
			local a = Instance.new("Animator")
			a.Parent = humanoid
			return a
		end)
		if not okAnimator or not created then
			fail(roleName, "could not create Animator")
			return nil
		end
		animator = created
	end

	local okAnimation, animation = pcall(function()
		local a = Instance.new("Animation")
		a.Name = "StandingIdle"
		a.AnimationId = Data.animationAsset
		a.Parent = folder
		return a
	end)
	if not okAnimation or not animation then
		fail(roleName, "could not create Animation")
		return nil
	end

	local okLoad, track = pcall(function()
		return (animator :: any):LoadAnimation(animation)
	end)
	if not okLoad or not track then
		fail(roleName, "LoadAnimation failed: " .. tostring(track))
		return nil
	end
	local okPlay, playError = pcall(function()
		track.Looped = true
		track:Play()
	end)
	if not okPlay then
		fail(roleName, "track Play failed: " .. tostring(playError))
		return nil
	end
	animations[#animations + 1] = animation
	return track
end

-- The shared loop body. Also exposed as pump(dt) so the Studio harness can drive the exact same
-- function deterministically without relying on wall-clock waits.
local function tick(dt: number)
	if not applied then
		return
	end
	local angles = Data.step(entries, dt)
	for index, rig in ipairs(targets) do
		local base = basePivots[rig]
		if base and angles[index] ~= nil then
			-- base * Angles(...) leaves Position alone and tilts UpVector by <= MAX_SWAY_DEG.
			local swayed = base * CFrame.Angles(math.rad(angles[index]), 0, 0)
			pcall(function()
				rig:PivotTo(swayed)
			end)
		end
	end
	swayActive = true
end

local function resetDiagnostics()
	targets, tracks, animations, entries = {}, {}, {}, {}
	basePivots = {}
	swayActive = false
	restoreAudit = { count = 0, maxDelta = 0, mismatches = 0 }
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

local function stopTracks()
	for _, track in ipairs(tracks) do
		pcall(function()
			track:Stop()
		end)
		pcall(function()
			track:Destroy()
		end)
	end
	for _, animation in ipairs(animations) do
		pcall(function()
			animation:Destroy()
		end)
	end
	tracks, animations = {}, {}
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

	local roleList = Data.roles(R7, R8)
	local slotList = Data.slots(R7.slots, R8.slots)
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

	local warned: { [string]: boolean } = {}
	for index, slot in ipairs(slotList) do
		local descriptor = roleList[index]
		if type(descriptor) ~= "table" then
			fail(tostring(slot.slot), "missing role descriptor")
			continue
		end
		local rig = buildRig(descriptor, warned)
		if rig then
			scaleRig(rig, descriptor, descriptor.role, warned)
			pcall(function()
				rig.Name = "IdleR8_" .. descriptor.source .. "_" .. descriptor.role
				rig:SetAttribute("LookDevIdleR8", FAMILY_ID)
				rig:SetAttribute("Role", descriptor.role)
				rig:SetAttribute("Source", descriptor.source)
			end)
			if groundRig(rig, slot, descriptor.role, warned) then
				pcall(function()
					rig.Parent = folder
				end)
				configureParts(rig)
				local okPivot, pivot = pcall(function()
					return rig:GetPivot()
				end)
				if okPivot and pivot then
					basePivots[rig] = pivot
					targets[#targets + 1] = rig
					entries[#entries + 1] = { seed = index, slot = descriptor.role, t = 0, sway = 0 }
					local track = attachIdleTrack(rig, descriptor.role, folder)
					if track then
						tracks[#tracks + 1] = track
					end
				end
			end
		end
	end

	if #targets > 0 then
		local okConnect, result = pcall(function()
			return (RunService :: any).Heartbeat:Connect(tick)
		end)
		if okConnect then
			connection = result
		else
			fail("loop", "Heartbeat connect failed: " .. tostring(result))
		end
	else
		fail("loop", "no villagers staged")
	end
	applied = true
	LookDevFailures.set(FAMILY_ID, failures)
end

local function restore()
	if not applied then
		return
	end
	applied = false
	disconnectLoop()
	stopTracks()
	swayActive = false

	-- Restore the exact saved pivot of each still-live rig and record the worst error BEFORE the
	-- folder is destroyed. The harness reads this audit after LookDev.disable().
	local count, maxDelta, mismatches = 0, 0, 0
	for _, rig in ipairs(targets) do
		local base = basePivots[rig]
		if base then
			local okRestore = pcall(function()
				rig:PivotTo(base)
			end)
			local okPivot, pivot = pcall(function()
				return rig:GetPivot()
			end)
			if okRestore and okPivot and pivot then
				local delta = (pivot.Position - base.Position).Magnitude
				maxDelta = math.max(maxDelta, delta)
				count += 1
				if delta > 1e-4 then
					mismatches += 1
				end
			else
				mismatches += 1
			end
		end
	end
	restoreAudit = { count = count, maxDelta = maxDelta, mismatches = mismatches }

	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	-- Keep restoreAudit intact: the harness reads it AFTER disable(). apply() resets it on the
	-- next enable, so no stale state leaks into a later cycle.
end

-- Diagnostics ---------------------------------------------------------------------------------
function LookDevNpcsIdleR8.stageTargets()
	return table.clone(targets)
end

function LookDevNpcsIdleR8.basePivot(rig: any): any?
	return basePivots[rig]
end

function LookDevNpcsIdleR8.tracks()
	return table.clone(tracks)
end

function LookDevNpcsIdleR8.swayActive(): boolean
	return swayActive
end

function LookDevNpcsIdleR8.isApplied(): boolean
	return applied
end

function LookDevNpcsIdleR8.connectionCount(): number
	return connection and 1 or 0
end

function LookDevNpcsIdleR8.restoreAudit()
	return table.clone(restoreAudit)
end

function LookDevNpcsIdleR8.pump(dt: number?): any
	local stepDt = type(dt) == "number" and dt or Data.DT
	tick(stepDt)
	return table.clone(entries)
end

LookDevNpcsIdleR8.apply = apply
LookDevNpcsIdleR8.restore = restore
LookDev.register("npcs_idle_r8", { apply = apply, restore = restore })

return LookDevNpcsIdleR8
