--!strict
-- LookDevFurrowsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "furrows_r10" candidate
-- (WORK_QUEUE item 205). Stages five thin anchored, non-collidable Ground-coloured furrow strips
-- per plot, from Shared.ModelMapFurrowsR10. Nothing is repainted and no crop is touched: the only
-- overwritten property is a pre-existing staging folder's LookDevStage attribute, saved once and
-- restored LIFO; only instances created here are destroyed. pcall-guarded and idempotent.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("furrows_r10", game)

type SavedProp = { target: any, prop: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevFurrowsR10] missing service " .. name)
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
	warn("[LookDevFurrowsR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapFurrowsR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevFurrowsR10] could not require LookDev / ModelMapFurrowsR10 / LookDevFailures")
	return {}
end

local LookDevFurrowsR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevFurrowsR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- A pre-existing staging folder is the only thing whose attribute we overwrite.
local function saveAttribute(target: any, name: string): boolean
	local key = "Stage." .. name
	for _, entry in ipairs(savedOrder) do
		if entry.key == key then
			return true
		end
	end
	local okRead, value = pcall(function()
		return target:GetAttribute(name)
	end)
	if not okRead then
		fail("could not read " .. key .. ": " .. tostring(value))
		return false
	end
	savedOrder[#savedOrder + 1] = { target = target, prop = name, key = key, value = value }
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
		folder = existing
		if saveAttribute(existing, "LookDevStage") then
			local okTag, why = pcall(function()
				existing:SetAttribute("LookDevStage", FAMILY_ID)
			end)
			if not okTag then
				fail("could not tag staging folder: " .. tostring(why))
			end
		end
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
		instance:SetAttribute("LookDevStage", FAMILY_ID)
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

local function stageStrip(descriptor: any, parent: any)
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Name = descriptor.name
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance:SetAttribute("Furrow", true)
		instance:SetAttribute("plot", descriptor.plot)
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
			fail("could not read furrow descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stageStrip(descriptor, root)
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

LookDevFurrowsR10.apply = apply
LookDevFurrowsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevFurrowsR10
