--!strict
-- LookDevLampsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "lamps_r10" candidate
-- (WORK_QUEUE item 202). Stages twelve anchored, non-collidable warm-wood poles with glowing
-- lanterns around the ring road, one shadowless PointLight per lantern. Every light is enabled
-- only at night, decided from Lighting.ClockTime at apply time via setClockTime(). All geometry
-- and colour values come from Shared.ModelMapLampsR10; no asset IDs or visual verdict live here.
-- Overwritten props are saved once and restored LIFO; only instances created here are destroyed.
--
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("lamps_r10", game)

type SavedProp = { target: any, prop: string, key: string, value: any, kind: string }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevLampsR10] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local Lighting = service("Lighting")
if not ReplicatedStorage or not Workspace or not Lighting then
	return {}
end

local Shared: any? = nil
local okShared, sharedFolder = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedFolder then
	Shared = sharedFolder
else
	warn("[LookDevLampsR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapLampsR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevLampsR10] could not require LookDev / ModelMapLampsR10 / LookDevFailures")
	return {}
end

local LookDevLampsR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local lights: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevLampsR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- Only a pre-existing staging folder can have a property of ours overwritten: its LookDevStage
-- attribute. Save that one value before writing, restore it LIFO on teardown.
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
	savedOrder[#savedOrder + 1] = { target = target, prop = name, key = key, value = value, kind = "attribute" }
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

local function isNight(clock: any?): boolean
	if type(clock) ~= "number" then
		return false
	end
	return clock >= (Data :: any).NIGHT_ON or clock < (Data :: any).NIGHT_OFF
end

-- Public so a harness can simulate a clock without staging a second copy of the lamps.
function LookDevLampsR10.setClockTime(t: any)
	local enabled = isNight(t)
	for index = #lights, 1, -1 do
		local light = lights[index]
		pcall(function()
			light.Enabled = enabled
		end)
	end
end

local function tagPart(part: any, index: number)
	local ok, why = pcall(function()
		part:SetAttribute("StreetLamp", true)
		part:SetAttribute("lamp", index)
		part:SetAttribute("LookDevStage", FAMILY_ID)
	end)
	if not ok then
		fail("could not tag lamp " .. tostring(index) .. ": " .. tostring(why))
	end
end

local function parentPart(part: any, parent: any, label: string)
	created[#created + 1] = part
	local ok, why = pcall(function()
		part.Parent = parent
	end)
	if not ok then
		fail("could not parent " .. label .. ": " .. tostring(why))
	end
end

local function stageLamp(descriptor: any, parent: any)
	local okPole, pole = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = Enum.PartType.Block
		instance.Size = Vector3.new(descriptor.pole.size[1], descriptor.pole.size[2], descriptor.pole.size[3])
		instance.CFrame = CFrame.new(
			descriptor.position.x,
			descriptor.position.y + descriptor.pole.size[2] / 2,
			descriptor.position.z
		)
		instance.Color = Color3.fromRGB(descriptor.pole.color.r, descriptor.pole.color.g, descriptor.pole.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name .. "_Pole"
		return instance
	end)
	if not okPole or not pole then
		fail("could not build pole " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(pole))
		return
	end
	tagPart(pole, descriptor.index)
	parentPart(pole, parent, descriptor.name .. "_Pole")

	local okLantern, lantern = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = Enum.PartType.Ball
		instance.Size = Vector3.new(descriptor.lantern.size[1], descriptor.lantern.size[2], descriptor.lantern.size[3])
		instance.CFrame = CFrame.new(
			descriptor.position.x,
			descriptor.position.y + descriptor.pole.size[2] + descriptor.lantern.size[2] / 2,
			descriptor.position.z
		)
		instance.Color =
			Color3.fromRGB(descriptor.lantern.color.r, descriptor.lantern.color.g, descriptor.lantern.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name .. "_Lantern"
		return instance
	end)
	if not okLantern or not lantern then
		fail("could not build lantern " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(lantern))
		return
	end
	tagPart(lantern, descriptor.index)
	parentPart(lantern, parent, descriptor.name .. "_Lantern")

	local okLight, light = pcall(function()
		local instance = (Instance :: any).new("PointLight")
		instance.Range = (Data :: any).LIGHT_RANGE
		instance.Color =
			Color3.fromRGB((Data :: any).LIGHT_COLOR.r, (Data :: any).LIGHT_COLOR.g, (Data :: any).LIGHT_COLOR.b)
		instance.Shadows = false
		instance.Enabled = false
		instance.Name = descriptor.name .. "_Light"
		return instance
	end)
	if not okLight or not light then
		fail("could not build light " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(light))
		return
	end
	created[#created + 1] = light
	lights[#lights + 1] = light
	local okParent, why = pcall(function()
		light.Parent = lantern
	end)
	if not okParent then
		fail("could not parent light " .. tostring(descriptor.name) .. ": " .. tostring(why))
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
		local okLamps, lamps = pcall(function()
			return (Data :: any).lamps()
		end)
		if not okLamps or type(lamps) ~= "table" then
			fail("could not read lamp descriptors: " .. tostring(lamps))
		else
			for _, descriptor in ipairs(lamps) do
				pcall(stageLamp, descriptor, root)
			end
		end
	end

	local okClock, clock = pcall(function()
		return (Lighting :: any).ClockTime
	end)
	if not okClock then
		fail("could not read Lighting.ClockTime: " .. tostring(clock))
	else
		LookDevLampsR10.setClockTime(clock)
	end

	active = true
	publishFailures()
end

local function restore()
	if not active and #savedOrder == 0 and #created == 0 and #lights == 0 then
		return
	end
	for index = #savedOrder, 1, -1 do
		local entry = savedOrder[index]
		local ok, why = pcall(function()
			if entry.kind == "attribute" then
				entry.target:SetAttribute(entry.prop, entry.value)
			else
				entry.target[entry.prop] = entry.value
			end
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
	for index = #lights, 1, -1 do
		lights[index] = nil -- lights die with their parent; never write to them here
	end
	folder = nil
	active = false
	publishFailures()
end

LookDevLampsR10.apply = apply
LookDevLampsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevLampsR10
