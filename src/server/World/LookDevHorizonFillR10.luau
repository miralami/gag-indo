--!strict
-- LookDevHorizonFillR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "horizon_fill_r10"
-- candidate (WORK_QUEUE item 197 lane 2). Stages one huge anchored, non-collidable sea-plane
-- skirt below terrain and matches it with an Atmosphere haze pair. All geometry and colour values
-- come from Shared.ModelMapHorizonFillR10; no asset IDs or visual verdict live here.
-- Every overwritten property is saved and restored byte-for-byte in LIFO order; only instances
-- created here are destroyed. apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("horizon_fill_r10", game)

type SavedProp = { target: any, prop: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevHorizonFillR10] missing service " .. name)
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
	warn("[LookDevHorizonFillR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapHorizonFillR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevHorizonFillR10] could not require LookDev / ModelMapHorizonFillR10 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevHorizonFillR10] optional MapSpec unavailable")
end

local LookDevHorizonFillR10 = {}

local FAMILY_ID = Data.id
local HAZE_PROPS = { "Haze", "Color" }

local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevHorizonFillR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- Reuse an existing Atmosphere, creating one under Lighting only when absent.
local function findAtmosphere(): any?
	local okFind, atmosphere = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("Atmosphere")
	end)
	if not okFind then
		fail("could not look up Atmosphere: " .. tostring(atmosphere))
		return nil
	end
	if atmosphere then
		return atmosphere
	end
	local okNew, instance = pcall(function()
		return (Instance :: any).new("Atmosphere")
	end)
	if not okNew or not instance then
		fail("could not create Atmosphere: " .. tostring(instance))
		return nil
	end
	local okParent, why = pcall(function()
		instance.Name = "LookDevHorizonFillR10_Atmosphere"
		instance.Parent = Lighting
	end)
	if not okParent then
		pcall(function()
			instance:Destroy()
		end)
		fail("could not parent Atmosphere: " .. tostring(why))
		return nil
	end
	created[#created + 1] = instance
	return instance
end

local function saveProp(target: any, prop: string): boolean
	local key = "Atmosphere." .. prop
	for _, entry in ipairs(savedOrder) do
		if entry.key == key then
			return true
		end
	end
	local okRead, value = pcall(function()
		return target[prop]
	end)
	if not okRead then
		fail("could not read " .. key .. ": " .. tostring(value))
		return false
	end
	savedOrder[#savedOrder + 1] = { target = target, prop = prop, key = key, value = value }
	return true
end

local function hazeTarget(prop: string, value: any): (any?, string?)
	if prop ~= "Color" then
		return value, nil
	end
	if type(value) ~= "table" then
		return nil, "expected an RGB table"
	end
	local ok, color = pcall(function()
		return Color3.fromRGB(value.r, value.g, value.b)
	end)
	if not ok or not color then
		return nil, tostring(color)
	end
	return color, nil
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
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		instance:SetAttribute("HorizonSkirt", true)
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
			return (Data :: any).skirtParts()
		end)
		if not okParts or type(parts) ~= "table" then
			fail("could not read skirt descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stagePart(descriptor, root)
			end
		end
	end

	local okValues, values = pcall(function()
		return (Data :: any).hazeValues()
	end)
	if not okValues or type(values) ~= "table" then
		fail("could not read haze values: " .. tostring(values))
	else
		local atmosphere = findAtmosphere()
		if atmosphere then
			for _, prop in ipairs(HAZE_PROPS) do
				if saveProp(atmosphere, prop) then
					local target, why = hazeTarget(prop, values[prop])
					if target == nil then
						fail("bad Atmosphere." .. prop .. ": " .. tostring(why))
					else
						local okSet, err = pcall(function()
							atmosphere[prop] = target
						end)
						if not okSet then
							fail("could not set Atmosphere." .. prop .. ": " .. tostring(err))
						end
					end
				end
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
			entry.target[entry.prop] = entry.value
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

LookDevHorizonFillR10.apply = apply
LookDevHorizonFillR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevHorizonFillR10
