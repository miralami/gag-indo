--!strict
-- LookDevBambooBridgeR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "bamboo_bridge_r10"
-- candidate (WORK_QUEUE item 204, SPRINT 1). Stages bamboo-coloured planks, two round rails, rope
-- ties and four end posts in their own Workspace folder. Every staged Part is Anchored and
-- non-collidable: the underlying river bridge stays untouched and walkable.
-- Geometry and colours come only from Shared.ModelMapBambooBridgeR10; no asset IDs or visual verdict.
-- apply/restore are idempotent; restore is LIFO over everything created or saved here, destroys only
-- created instances, and is pcall-guarded throughout.
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("bamboo_bridge_r10", game)

type SavedProp = { target: any, prop: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevBambooBridgeR10] missing service " .. name)
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
	warn("[LookDevBambooBridgeR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapBambooBridgeR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevBambooBridgeR10] could not require LookDev / ModelMapBambooBridgeR10 / LookDevFailures")
	return {}
end

local LookDevBambooBridgeR10 = {}

local FAMILY_ID = Data.id
local STAGE_ATTR = "LookDevStage"

local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevBambooBridgeR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- Save an existing folder attribute once before overwriting it, so restore can put it back.
local function saveAttribute(target: any, attr: string): boolean
	local key = "Folder." .. attr
	for _, entry in ipairs(savedOrder) do
		if entry.key == key then
			return true
		end
	end
	local okRead, value = pcall(function()
		return target:GetAttribute(attr)
	end)
	if not okRead then
		fail("could not read " .. key .. ": " .. tostring(value))
		return false
	end
	savedOrder[#savedOrder + 1] = { target = target, prop = attr, key = key, value = value }
	return true
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
		if saveAttribute(existing, STAGE_ATTR) then
			local okSet, why = pcall(function()
				existing:SetAttribute(STAGE_ATTR, FAMILY_ID)
			end)
			if not okSet then
				fail("could not tag existing folder: " .. tostring(why))
			end
		end
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
		instance:SetAttribute(STAGE_ATTR, FAMILY_ID)
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
		local shape = Enum.PartType.Block
		local okShape, resolved = pcall(function()
			return (Enum :: any).PartType[descriptor.shape]
		end)
		if okShape and resolved then
			shape = resolved
		end
		instance.Shape = shape
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		local position = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		-- A Cylinder's height is local Y; lay the two rails along the bridge's Z axis.
		if descriptor.kind == "rail_left" or descriptor.kind == "rail_right" then
			position *= CFrame.Angles(math.pi / 2, 0, 0)
		end
		instance.CFrame = position
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		instance:SetAttribute("BambooBridge", true)
		instance:SetAttribute("role", descriptor.kind)
		instance:SetAttribute(STAGE_ATTR, FAMILY_ID)
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
		return
	end
	failures = 0

	stageFolder()
	local root = folder
	if root then
		local okParts, parts = pcall(function()
			return (Data :: any).parts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read part descriptors: " .. tostring(parts))
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
	if not active and #savedOrder == 0 and #created == 0 then
		return
	end
	for index = #savedOrder, 1, -1 do
		local entry = savedOrder[index]
		local ok, why = pcall(function()
			entry.target:SetAttribute(entry.prop, entry.value)
		end)
		if not ok then
			fail("could not restore " .. entry.key .. ": " .. tostring(why))
		end
		savedOrder[index] = nil
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

LookDevBambooBridgeR10.apply = apply
LookDevBambooBridgeR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevBambooBridgeR10
