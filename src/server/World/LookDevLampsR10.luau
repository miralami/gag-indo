--!strict
-- LookDevLampsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "lamps_r10" candidate
-- (WORK_QUEUE items 202 + 246). Stages twelve anchored, non-collidable warm-wood poles with glowing
-- lanterns around the ring road, one shadowless PointLight at each pole centre. Item 246 moves the
-- light down from the lantern so its <=16 range reaches the road, with capped amber brightness.
-- Every light is enabled only at night, decided from Lighting.ClockTime at apply time via
-- setClockTime(). All geometry and colour values come from Shared.ModelMapLampsR10; no asset IDs
-- or visual verdict live here.
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
	local root = folder
	if root then
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") and string.find(d.Name, "Bulb", 1, true) then
				pcall(function()
					d.Material = if enabled then Enum.Material.Neon else Enum.Material.Glass
					d.Transparency = if enabled then 0 else 0.2
				end)
			end
		end
	end
end

-- Item 256: model-based old-style street lamp (ASSET_MANIFEST lamps_r10_model, asset 13869743481).
-- Baked clone from ServerStorage.LookDevAssets; scripts/light cone removed at bake time.
-- Warm PointLight at pole centre, night only.
local MODEL_ASSET_ID = 13869743481
local TEMPLATE_HEIGHT = 25.385473251342773

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

local function bakedTemplate(): any?
	local ok, loader = pcall(function()
		return require(script.Parent:WaitForChild("LookDevAssetLoader"))
	end)
	if ok and type(loader) == "table" and type(loader.baked) == "function" then
		local okBaked, model = pcall(loader.baked, MODEL_ASSET_ID)
		if okBaked and model then
			return model
		end
	end
	local okSS, ss = pcall(function()
		return game:GetService("ServerStorage")
	end)
	if not okSS or not ss then
		return nil
	end
	local okModel, model = pcall(function()
		local root = ss:FindFirstChild("LookDevAssets")
		local src = root and root:FindFirstChild(tostring(MODEL_ASSET_ID))
		return src and src:Clone()
	end)
	if okModel then
		return model
	end
	return nil
end

local function stageLamp(descriptor: any, parent: any)
	-- Invisible anchor at pole centre: keeps LAMP_POOL/LIGHT_COST checks and light positioning stable.
	local okPole, pole = pcall(function()
		local instance = (Instance :: any).new("Part")
		instance.Shape = Enum.PartType.Block
		instance.Size = Vector3.new(descriptor.pole.size[1], descriptor.pole.size[2], descriptor.pole.size[3])
		instance.CFrame = CFrame.new(
			descriptor.position.x,
			descriptor.position.y + descriptor.pole.size[2] / 2,
			descriptor.position.z
		)
		instance.Transparency = 1
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

	local targetHeight = 18
	local scale = targetHeight / TEMPLATE_HEIGHT
	local model = bakedTemplate()
	if model then
		local okStage, why = pcall(function()
			model.Name = descriptor.name .. "_Model"
			if model:IsA("Model") then
				pcall(function()
					model:ScaleTo(scale)
				end)
			end
			local bbCf, bbSize
			local okBB = pcall(function()
				bbCf, bbSize = model:GetBoundingBox()
			end)
			if okBB and bbCf and bbSize then
				local cf = bbCf :: CFrame
				local bottomY = cf.Position.Y - (bbSize :: Vector3).Y / 2
				local dy = descriptor.position.y - bottomY
				local dx = descriptor.position.x - cf.Position.X
				local dz = descriptor.position.z - cf.Position.Z
				local target = cf + Vector3.new(dx, dy, dz)
				model:PivotTo(target)
			end
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CastShadow = false
					tagPart(d, descriptor.index)
				end
			end
			model.Parent = parent
		end)
		if okStage then
			created[#created + 1] = model
		else
			pcall(function()
				model:Destroy()
			end)
			fail("could not stage model for " .. tostring(descriptor.name) .. ": " .. tostring(why))
		end
	else
		fail("missing baked lamp model " .. tostring(MODEL_ASSET_ID))
	end

	local okLight, light = pcall(function()
		local instance = (Instance :: any).new("PointLight")
		instance.Range = (Data :: any).LIGHT_RANGE
		instance.Brightness = (Data :: any).LIGHT_BRIGHTNESS
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
	-- Item 246: light at pole centre, not lantern centre, so the <=16 range throws a pool on
	-- the road instead of only lighting the lantern housing.
	local okParent, why = pcall(function()
		light.Parent = pole
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
