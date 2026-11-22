--!strict
-- LookDevRoadFenceR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "road_fence_r10"
-- candidate (WORK_QUEUE item 201). Stages short anchored, non-collidable bamboo fence parts beside
-- the main roads. Geometry and colour come from Shared.ModelMapRoadFenceR10; no asset IDs or visual
-- verdict live here. No pre-existing property is overwritten, so the saved-property stack is empty
-- by construction and restore is a pure LIFO teardown of the instances created here.
-- apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("road_fence_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRoadFenceR10] missing service " .. name)
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
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevRoadFenceR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRoadFenceR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevRoadFenceR10] could not require LookDev / ModelMapRoadFenceR10 / LookDevFailures")
	return {}
end

local LookDevRoadFenceR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevRoadFenceR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function stageFolder(): any?
	local okFind, existing = pcall(function()
		return (Workspace :: any):FindFirstChild((Data :: any).folderName)
	end)
	if not okFind then
		fail("could not look up staging folder: " .. tostring(existing))
		return nil
	end
	if existing then
		folder = existing
		return existing
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okNew or not instance then
		fail("could not create staging folder: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = (Data :: any).folderName
		instance.Parent = Workspace
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent staging folder: " .. tostring(why))
		return nil
	end
	created[#created + 1] = instance
	folder = instance
	return instance
end

local function stagePart(descriptor: any, parent: any)
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = (Enum :: any).PartType.Block
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		instance:SetAttribute("RoadFence", true)
		instance:SetAttribute("stretch", descriptor.stretch)
		instance:SetAttribute("LookDevStage", FAMILY_ID)
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(part))
		return
	end
	created[#created + 1] = part
	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
	end
end

local function apply(_plan: any)
	if active then
		publishFailures()
		return
	end
	failures = 0
	pcall(function()
		LookDevFailures.reset(FAMILY_ID)
	end)

	stageFolder()
	local root = folder
	if root then
		local okParts, parts = pcall(function()
			return (Data :: any).parts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read fence descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stagePart(descriptor, root)
			end
		end
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #created == 0 then
		return
	end
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	folder = nil
	active = false
	publishFailures()
end

LookDevRoadFenceR10.apply = apply
LookDevRoadFenceR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevRoadFenceR10
