--!strict
-- LookDevHillDressingR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "hill_dressing_r10"
-- candidate (WORK_QUEUE item 199). Stages anchored, non-collidable rock, palm and terrace parts
-- on the four hill domes. Geometry and colour values come from Shared.ModelMapHillDressingR10;
-- no asset IDs or visual verdict live here. Palm trunks and crowns are separate parts but share
-- the hill and kind tags. Every created instance is saved once and restored in LIFO order; only
-- instances created here are destroyed. apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("hill_dressing_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevHillDressingR10] missing service " .. name)
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
	warn("[LookDevHillDressingR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapHillDressingR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevHillDressingR10] could not require LookDev / ModelMapHillDressingR10 / LookDevFailures")
	return {}
end

local LookDevHillDressingR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevHillDressingR10] " .. message)
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

local function partType(shapeName: string): any?
	local ok, partTypeValue = pcall(function()
		return (Enum :: any).PartType[shapeName]
	end)
	if not ok or not partTypeValue then
		fail("unknown part shape " .. shapeName)
		return nil
	end
	return partTypeValue
end

local function stagePart(
	name: string,
	shapeName: string,
	position: { number },
	size: { number },
	color: any,
	descriptor: any,
	parent: any
)
	local shape = partType(shapeName)
	if not shape then
		return
	end
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = shape
		instance.Size = Vector3.new(size[1], size[2], size[3])
		instance.CFrame = CFrame.new(position[1], position[2], position[3])
		instance.Color = Color3.fromRGB(color.r, color.g, color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = name
		instance:SetAttribute("HillDressing", true)
		instance:SetAttribute("hill", descriptor.hill)
		instance:SetAttribute("kind", descriptor.kind)
		instance:SetAttribute("LookDevStage", FAMILY_ID)
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. name .. ": " .. tostring(part))
		return
	end
	created[#created + 1] = part
	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. name .. ": " .. tostring(why))
	end
end

local function stageDescriptor(descriptor: any, parent: any)
	local position = descriptor.position
	stagePart(descriptor.name, descriptor.shape, position, descriptor.size, descriptor.color, descriptor, parent)
	if descriptor.kind == "palm" and descriptor.crownOffset and descriptor.crownSize and descriptor.crownColor then
		local offset, crownSize = descriptor.crownOffset, descriptor.crownSize
		stagePart(
			descriptor.name .. "_Crown",
			"Ball",
			{ position[1] + offset[1], position[2] + offset[2], position[3] + offset[3] },
			crownSize,
			descriptor.crownColor,
			descriptor,
			parent
		)
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
			fail("could not read hill descriptors: " .. tostring(parts))
		else
			for _, descriptor in ipairs(parts) do
				stageDescriptor(descriptor, root)
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

LookDevHillDressingR10.apply = apply
LookDevHillDressingR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevHillDressingR10
