--!strict
-- LookDevDitchWaterR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "ditch_water_r10" candidate
-- (WORK_QUEUE items 207 / 263). Stages an anchored, non-collidable irrigation channel per plot: a
-- dark Mud bed, two Mud banks and a teal Glass water sheet. Geometry, teal and tolerance all come
-- from Shared.ModelMapDitchWaterR10; no
-- asset IDs or visual verdict live here. Every created instance is tracked once and destroyed in
-- LIFO order; apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("ditch_water_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevDitchWaterR10] missing service " .. name)
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
	warn("[LookDevDitchWaterR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapDitchWaterR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevDitchWaterR10] could not require LookDev / ModelMapDitchWaterR10 / LookDevFailures")
	return {}
end

local LookDevDitchWaterR10 = {}

local FAMILY_ID = Data.id
local failures = 0
local active = false
local created: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevDitchWaterR10] " .. message)
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
	return instance
end

local function materialFor(name: any): any
	local ok, material = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and material then
		return material
	end
	return Enum.Material.Mud
end

local function stagePart(descriptor: any, parent: any)
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Name = descriptor.name
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
			* CFrame.Angles(0, descriptor.yaw, 0)
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Transparency = descriptor.transparency
		instance.Material = materialFor(descriptor.material)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		if descriptor.kind == "ditch_water" then
			instance:SetAttribute("DitchWater", true)
			instance:SetAttribute("colorTolerance", (Data :: any).COLOR_TOLERANCE)
		elseif descriptor.kind == "ditch_bank" then
			instance:SetAttribute("DitchBank", true)
		else
			instance:SetAttribute("DitchBed", true)
		end
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

	local root = stageFolder()
	if root then
		-- Earthworks first so the water sheet is created (and destroyed) after them.
		for _, builder in ipairs({ "banks", "parts" }) do
			local okParts, parts = pcall(function()
				return (Data :: any)[builder]()
			end)
			if not okParts or type(parts) ~= "table" then
				fail("could not read ditch descriptors: " .. tostring(parts))
			else
				for _, descriptor in ipairs(parts) do
					stagePart(descriptor, root)
				end
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
	-- LIFO: destroy only what this applier created, never a pre-existing folder.
	for index = #created, 1, -1 do
		local instance = created[index]
		pcall(function()
			instance:Destroy()
		end)
		created[index] = nil
	end
	active = false
	publishFailures()
end

LookDevDitchWaterR10.apply = apply
LookDevDitchWaterR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevDitchWaterR10
