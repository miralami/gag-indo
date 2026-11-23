--!strict
-- LookDevKampungR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "kampung_r10" candidate
-- (WORK_QUEUE item 200; item 253 replaced the yard Ball with hedge clusters). Stages 12 primitive
-- background houses in 3 outskirt clusters. Each yard has two fence Blocks and two hedge-shrub
-- anchors: the old green Ball is gone. In this Studio place ServerStorage.LookDevAssets has no bake
-- for the item-241 shrub IDs, so the applier stages an explicit Wedge/Cylinder cluster instead —
-- no asset ID and no runtime asset loading. Every staged part is anchored, non-collidable and
-- non-interactive; all instances here are destroyed on restore. No prompts or click detectors;
-- no gameplay state. All placement comes from Shared.ModelMapKampungR10. Overwritten attributes are
-- saved once and restored LIFO; apply/restore are idempotent and pcall-guarded throughout.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("kampung_r10", game)

type SavedProp = { target: any, attr: string, key: string, value: any }

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevKampungR10] missing service " .. name)
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
	warn("[LookDevKampungR10] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapKampungR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevKampungR10] could not require LookDev / ModelMapKampungR10 / LookDevFailures")
	return {}
end

local LookDevKampungR10 = {}

local FAMILY_ID = Data.id
local failures = 0
local active = false
local created: { any } = {}
local savedOrder: { SavedProp } = {}
local folder: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevKampungR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

-- Save the prior attribute value once per target+key, then set it. New instances still take part so
-- the save/restore contract is uniform; their saved values are void when they are destroyed.
local function setAttribute(target: any, key: string, value: any)
	local attrKey = tostring(target) .. "." .. key
	local seen = false
	for _, entry in ipairs(savedOrder) do
		if entry.key == attrKey then
			seen = true
			break
		end
	end
	if not seen then
		local okRead, prior = pcall(function()
			return target:GetAttribute(key)
		end)
		if not okRead then
			fail("could not read attribute " .. key .. ": " .. tostring(prior))
			return
		end
		savedOrder[#savedOrder + 1] = { target = target, attr = key, key = attrKey, value = prior }
	end
	local okSet, why = pcall(function()
		target:SetAttribute(key, value)
	end)
	if not okSet then
		fail("could not set attribute " .. key .. ": " .. tostring(why))
	end
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

local function stagePart(descriptor: any, parent: any, houseIndex: number, role: string, shape: string?)
	local okPart, part = pcall(function()
		local instance = (Instance :: any).new("Part")
		local partType = (Enum.PartType :: any)[shape or "Block"] or (Enum.PartType :: any).Block
		instance.Shape = partType
		instance.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
		instance.CFrame = CFrame.new(descriptor.position.x, descriptor.position.y, descriptor.position.z)
			* CFrame.Angles(0, math.rad(descriptor.yaw or 0), 0)
		instance.Color = Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)
		instance.Anchored = true
		instance.CanCollide = false
		instance.CastShadow = false
		instance.Name = descriptor.name
		return instance
	end)
	if not okPart or not part then
		fail("could not build " .. tostring(descriptor and descriptor.name) .. ": " .. tostring(part))
		return
	end
	created[#created + 1] = part

	setAttribute(part, (Data :: any).tagAttribute, true)
	setAttribute(part, "house", houseIndex)
	setAttribute(part, "role", role)
	setAttribute(part, (Data :: any).stageAttribute, FAMILY_ID)
	if role == "shrub" then
		setAttribute(part, "cluster", descriptor.cluster)
		setAttribute(part, "shrubCluster", descriptor.name)
		setAttribute(part, "HedgeShrub", true)
	end

	local okParent, why = pcall(function()
		part.Parent = parent
	end)
	if not okParent then
		fail("could not parent " .. tostring(descriptor.name) .. ": " .. tostring(why))
	end
end

local function stageHouses(root: any)
	local okHouses, houses = pcall(function()
		return (Data :: any).houses()
	end)
	if not okHouses or type(houses) ~= "table" then
		fail("could not read house descriptors: " .. tostring(houses))
		return
	end
	for index, house in ipairs(houses) do
		local okBuild, why = pcall(function()
			local body = {
				name = house.name .. "_body",
				size = house.body.size,
				color = house.body.color,
				yaw = house.yaw,
				position = {
					x = house.position.x,
					y = house.position.y + house.body.size[2] / 2,
					z = house.position.z,
				},
			}
			local roof = {
				name = house.name .. "_roof",
				size = house.roof.size,
				color = house.roof.color,
				yaw = house.yaw,
				position = {
					x = house.position.x,
					y = house.position.y + house.body.size[2] + house.roof.size[2] / 2,
					z = house.position.z,
				},
			}
			stagePart(body, root, index, "house", "Block")
			stagePart(roof, root, index, "house", "Wedge")
		end)
		if not okBuild then
			fail("could not stage house " .. index .. ": " .. tostring(why))
		end
	end
end

-- Item 253 hedge fallback: no bake exists in this place, so each yard anchor becomes three Wedge
-- blades and one low Cylinder base. All four stay inside the old 4-stud Ball footprint and are
-- tagged role="shrub" / HedgeShrub / shrubCluster for the SERVER-VM check.
local HEDGE_BLADES = {
	{ radial = -0.6, tangential = 0, yaw = 0 },
	{ radial = 0.6, tangential = -0.5, yaw = 110 },
	{ radial = 0.6, tangential = 0.5, yaw = 250 },
}

local function stageHedgeShrub(descriptor: any, parent: any, houseIndex: number)
	local px, pz = descriptor.position.x, descriptor.position.z
	local base = {
		name = descriptor.name .. "_base",
		size = { 0.8, 1.2, 0.8 },
		position = { x = px, y = descriptor.position.y + 0.6, z = pz },
		color = descriptor.color,
		cluster = descriptor.cluster,
		yaw = descriptor.yaw or 0,
	}
	stagePart(base, parent, houseIndex, "shrub", "Cylinder")
	for index, blade in ipairs(HEDGE_BLADES) do
		local bx, bz = px + blade.radial, pz + blade.tangential
		stagePart({
			name = descriptor.name .. "_wedge_" .. index,
			size = { 1.6, (Data :: any).SHRUB_HEIGHT, 1.6 },
			position = { x = bx, y = descriptor.position.y + (Data :: any).SHRUB_HEIGHT / 2, z = bz },
			color = descriptor.color,
			cluster = descriptor.cluster,
			yaw = (descriptor.yaw or 0) + blade.yaw,
		}, parent, houseIndex, "shrub", "Wedge")
	end
end

local function stageYards(root: any)
	local okYards, yards = pcall(function()
		return (Data :: any).yardParts()
	end)
	if not okYards or type(yards) ~= "table" then
		fail("could not read yard descriptors: " .. tostring(yards))
		return
	end
	for _, part in ipairs(yards) do
		local okBuild, why = pcall(function()
			if part.kind == "shrub" then
				stageHedgeShrub(part, root, part.house)
			else
				stagePart(part, root, part.house, part.kind, part.shape)
			end
		end)
		if not okBuild then
			fail("could not stage yard part " .. tostring(part.name) .. ": " .. tostring(why))
		end
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
		stageHouses(root)
		stageYards(root)
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
			entry.target:SetAttribute(entry.attr, entry.value)
		end)
		if not ok then
			fail("could not restore attribute " .. entry.key .. ": " .. tostring(why))
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

LookDevKampungR10.apply = apply
LookDevKampungR10.restore = restore

local okRegister, whyRegister = pcall(function()
	LookDev.register(FAMILY_ID, { apply = apply, restore = restore })
end)
if not okRegister then
	warn("[LookDevKampungR10] could not register applier: " .. tostring(whyRegister))
end

return LookDevKampungR10
