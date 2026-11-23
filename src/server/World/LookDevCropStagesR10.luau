--!strict
-- LookDevCropStagesR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "crop_stages_r10" reference-stage
-- overlay (WORK_QUEUE items 206 / 254). It stages three anchored, non-collidable crop plants
-- (Cylinder stem + Wedge leaves + Cylinder produce) per plot from Shared.ModelMapCropStagesR10.
-- No Ball part is created: item 254 replaced the old lollipop canopy. The shipped crop models are
-- never read, modified or destroyed; only Parts created here are removed.
-- Every created instance is saved once in creation order and restored LIFO; apply/restore are
-- idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("crop_stages_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevCropStagesR10] missing service " .. name)
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
	warn("[LookDevCropStagesR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapCropStagesR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevCropStagesR10] could not require LookDev / ModelMapCropStagesR10 / LookDevFailures")
	return {}
end

local LookDevCropStagesR10 = {}

local FAMILY_ID = Data.id

local failures = 0
local active = false
local created: { any } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevCropStagesR10] " .. message)
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
	-- Save-once: every instance created here is recorded exactly once for LIFO restore.
	created[#created + 1] = instance
	folder = instance
	return instance
end

local function shapeFor(shapeName: string): any
	if shapeName == "Wedge" then
		return Enum.PartType.Wedge
	end
	if shapeName == "Cylinder" then
		return Enum.PartType.Cylinder
	end
	return Enum.PartType.Block
end

local function frameFor(descriptor: any): any
	local position = descriptor.position
	local rotation = descriptor.rotation or { 0, 0, 0 }
	return CFrame.new(position[1], position[2], position[3])
		* CFrame.Angles(rotation[1], rotation[2], rotation[3])
end

local function stagePart(descriptor: any, sample: any, parent: any)
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Name = descriptor.name
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = frameFor(descriptor)
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Shape = shapeFor(descriptor.shape)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance:SetAttribute("CropStage", true)
		instance:SetAttribute("stage", sample.stage)
		instance:SetAttribute("plot", sample.plot)
		instance:SetAttribute("height", sample.height)
		instance:SetAttribute("CropStageRole", descriptor.role)
		instance:SetAttribute("crop", (Data :: any).REFERENCE_CROP)
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
		local okSamples, samples = pcall(function()
			return (Data :: any).stageParts()
		end)
		if not okSamples or type(samples) ~= "table" then
			fail("could not read stage descriptors: " .. tostring(samples))
		else
			for _, sample in ipairs(samples) do
				for _, descriptor in ipairs(sample.parts) do
					stagePart(descriptor, sample, root)
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

LookDevCropStagesR10.apply = apply
LookDevCropStagesR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevCropStagesR10
