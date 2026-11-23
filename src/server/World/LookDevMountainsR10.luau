--!strict
-- LookDevMountainsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE items 243 + 251 + 260). Stages twelve blue-green Wedge rock ridges in three
-- distance bands (|z| = 300, 450, 600) plus one faint smoke Cylinder in an anchored, non-collidable
-- Folder. Rock/Slate only: no Block shape and no SmoothPlastic fallback. All geometry, colour and
-- material values come from Shared.ModelMapMountainsR10; no asset IDs or visual verdict live here.
-- No existing property is overwritten, so restore is LIFO destruction of only what was created here.
-- apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("mountains_r10", game)

type SavedProp = { target: any, prop: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevMountainsR10] missing service " .. name)
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
	warn("[LookDevMountainsR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapMountainsR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevMountainsR10] could not require LookDev / ModelMapMountainsR10 / LookDevFailures")
	return {}
end

local LookDevMountainsR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevMountainsR10] " .. message)
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

local function partShape(name: any): any?
	if name ~= "Wedge" and name ~= "Cylinder" then
		fail("unknown shape " .. tostring(name))
		return nil
	end
	local okShape, shape = pcall(function()
		return (Enum :: any).PartType[name]
	end)
	if not okShape or not shape then
		fail("could not resolve shape " .. tostring(name) .. ": " .. tostring(shape))
		return nil
	end
	return shape
end

local function partMaterial(name: any): any?
	if name ~= "Rock" and name ~= "Slate" then
		fail("mountain material must be Rock or Slate, got " .. tostring(name))
		return nil
	end
	local okMaterial, material = pcall(function()
		return (Enum :: any).Material[name]
	end)
	if okMaterial and material then
		return material
	end
	fail("could not resolve material " .. tostring(name))
	return nil
end

local function stagePart(descriptor: any, parent: any)
	local shape = partShape(descriptor and descriptor.shape)
	if not shape then
		return
	end
	local material = partMaterial(descriptor and descriptor.material)
	if not material then
		return
	end
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = shape
		instance.Material = material
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position[1], descriptor.position[2], descriptor.position[3])
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		if descriptor.transparency ~= nil then
			instance.Transparency = descriptor.transparency
		end
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		instance:SetAttribute("Mountain", true)
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

local function stageDescriptors(getParts: any, parent: any, label: string)
	local okParts, parts = pcall(getParts)
	if not okParts or type(parts) ~= "table" then
		fail("could not read " .. label .. " descriptors: " .. tostring(parts))
		return
	end
	for _, descriptor in ipairs(parts) do
		stagePart(descriptor, parent)
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
		stageDescriptors((Data :: any).mountainParts, root, "mountain")
		stageDescriptors((Data :: any).smokeParts, root, "smoke")
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

LookDevMountainsR10.apply = apply
LookDevMountainsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevMountainsR10
