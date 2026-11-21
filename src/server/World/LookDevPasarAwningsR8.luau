--!strict
-- LookDevPasarAwningsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "pasar_awnings_r8" candidate
-- (WORK_QUEUE section O item 148). Builds twelve lapak stalls from original Parts around the Pasar
-- frontage: striped red/white/blue awnings, counters with crates/baskets/hanging cloth, and lamps.
-- No asset IDs and no real brand. Every recipe comes from Shared.ModelMapPasarAwningsR8 and every
-- position is resolved through MapSpec.hub("pasar") + MapSpec.hubPoint; no world-coordinate literals.
--
-- A Ground voxel pad is painted under EVERY stall: the review harness samples Terrain at GRASS_Y=4,
-- so a decorative base Part alone would not clear PASAR_AWNING_ON_GRASS. Before each fill the exact
-- grid-aligned voxel region (materials + occupancy + water mask) is read back; restore writes those
-- arrays over the same region LIFO so Terrain is byte-for-byte unchanged after disable. All game
-- APIs are pcall-guarded; any missing recipe/hub/voxel snapshot pads the failure counter and warns.
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("pasar_awnings_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPasarAwningsR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevPasarAwningsR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapPasarAwningsR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevPasarAwningsR8] could not require LookDev / ModelMapPasarAwningsR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevPasarAwningsR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevPasarAwningsR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local savedVoxels: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevPasarAwningsR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

local function worldBox(instance: any): (any?, any?)
	local ok, boxCFrame, size = pcall(function()
		return instance:GetBoundingBox()
	end)
	if
		not ok
		or not boxCFrame
		or not size
		or size.X ~= size.X
		or size.Y ~= size.Y
		or size.Z ~= size.Z
		or size.X <= 0
		or size.Y <= 0
		or size.Z <= 0
	then
		return nil, nil
	end
	return boxCFrame, size
end

-- Terrain's authoring grid is 4 studs. Snap OUTWARD with the same floor/ceil math the harness uses,
-- minimum one cell per axis, so the snapshot covers every voxel FillBlock can touch.
local VOXEL = if MapSpec then (MapSpec.TERRAIN_VOXEL or 4) else 4

local function voxelRegion(cx: number, cy: number, cz: number, sx: number, sy: number, sz: number): any
	local minX = math.floor((cx - sx / 2) / VOXEL) * VOXEL
	local maxX = math.ceil((cx + sx / 2) / VOXEL) * VOXEL
	local minY = math.floor((cy - sy / 2) / VOXEL) * VOXEL
	local maxY = math.ceil((cy + sy / 2) / VOXEL) * VOXEL
	local minZ = math.floor((cz - sz / 2) / VOXEL) * VOXEL
	local maxZ = math.ceil((cz + sz / 2) / VOXEL) * VOXEL
	if maxX - minX < VOXEL then
		maxX = minX + VOXEL
	end
	if maxY - minY < VOXEL then
		maxY = minY + VOXEL
	end
	if maxZ - minZ < VOXEL then
		maxZ = minZ + VOXEL
	end
	return Region3.new(Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ))
end

local function savePadVoxels(terrain: any, region: any, label: string): boolean
	local ok, materials, occupancies, waterMask = pcall(function()
		return terrain:ReadVoxels(region, VOXEL)
	end)
	if not ok or type(materials) ~= "table" or type(occupancies) ~= "table" then
		fail("ReadVoxels snapshot failed for " .. label)
		return false
	end
	savedVoxels[#savedVoxels + 1] = {
		terrain = terrain,
		region = region,
		materials = materials,
		occupancies = occupancies,
		waterMask = waterMask,
		label = label,
	}
	return true
end

local function restoreSavedVoxels()
	-- LIFO: neighbouring pads can overlap, so a later snapshot may contain an earlier pad's Ground.
	for index = #savedVoxels, 1, -1 do
		local entry = savedVoxels[index]
		local ok = pcall(function()
			entry.terrain:WriteVoxels(entry.region, VOXEL, entry.materials, entry.occupancies, entry.waterMask)
		end)
		if not ok then
			fail("WriteVoxels restore failed for " .. tostring(entry.label))
		end
	end
	table.clear(savedVoxels)
end

local function paintGroundPad(model: any, label: string)
	if not MapSpec or not Workspace then
		fail("missing MapSpec/Workspace; Ground pad skipped for " .. label)
		return
	end
	local terrain = (Workspace :: any):FindFirstChildOfClass("Terrain")
	if not terrain then
		fail("missing Terrain; Ground pad skipped for " .. label)
		return
	end
	local boxCFrame, size = worldBox(model)
	if not boxCFrame or not size then
		fail("could not measure pad footprint for " .. label)
		return
	end
	local bottom = MapSpec.GROUND_Y - MapSpec.TERRAIN_VOXEL
	local cy, sy = MapSpec.volumeForTop(bottom, MapSpec.GROUND_Y)
	local cap = MapSpec.MAX_FILL_SPAN or 40
	local px, pz = boxCFrame.Position.X, boxCFrame.Position.Z
	local sx = math.min(size.X + Data.padMargin, cap)
	local sz = math.min(size.Z + Data.padMargin, cap)
	local region = voxelRegion(px, cy, pz, sx, sy, sz)
	-- Never paint a pad we cannot restore byte-for-byte.
	if not savePadVoxels(terrain, region, label) then
		return
	end
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(px, cy, pz), Vector3.new(sx, sy, sz), Enum.Material.Ground)
	end)
	if not ok then
		fail("Ground pad FillBlock failed for " .. label)
	end
end

type Descriptor = {
	name: string,
	size: { number },
	offset: { number },
	colour: { number },
	material: string,
	shape: string?,
	collide: boolean?,
	stripe: boolean?,
	stripeColour: string?,
}

local SHAPE_NAMES = { Block = "Block", Cylinder = "Cylinder" }

-- One flat descriptor list per stall: base, counter, four posts, two crates with vegetables, one
-- basket, hanging cloth, lamp post and lamp, then the striped awning from Data.stripeParts().
local function partDescriptors(): { Descriptor }
	local parts: { Descriptor } = {}
	local add = function(d: Descriptor)
		parts[#parts + 1] = d
	end
	local wood, ground = Data.MATERIALS.wood, Data.MATERIALS.base
	add({
		name = "StallBase",
		size = { Data.STALL_SIZE.width, 0.4, Data.STALL_SIZE.depth },
		offset = { 0, 0.2, 0 },
		colour = { 132, 104, 72 },
		material = ground,
		collide = true,
	})
	local counter = Data.COUNTER
	add({
		name = "Counter",
		size = { counter.width, 0.6, counter.depth },
		offset = { 0, counter.y, counter.zOffset },
		colour = { 138, 92, 54 },
		material = wood,
		collide = true,
	})
	for index, offset in ipairs(Data.POSTS) do
		add({
			name = string.format("Post_%02d", index),
			size = { 0.6, 9, 0.6 },
			offset = offset,
			colour = { 116, 78, 46 },
			material = wood,
			collide = true,
		})
	end
	local crate = Data.CRATE
	for index, offset in ipairs(crate.offsets) do
		add({
			name = string.format("Crate_%02d", index),
			size = crate.size,
			offset = offset,
			colour = { 172, 130, 82 },
			material = Data.MATERIALS.crate,
			collide = true,
		})
		for vegetable = 1, crate.vegCount do
			add({
				name = string.format("Vegetable_%02d_%02d", index, vegetable),
				size = { 0.6, 0.6, 0.6 },
				offset = {
					offset[1] + (vegetable - 2) * 0.65,
					offset[2] + crate.size[2] / 2 + 0.3,
					offset[3],
				},
				colour = Data.VEGETABLE_COLOURS[vegetable],
				material = Data.MATERIALS.vegetable,
				collide = false,
			})
		end
	end
	add({
		name = "Basket",
		size = Data.BASKET.size,
		offset = Data.BASKET.offset,
		colour = { 184, 142, 78 },
		material = Data.MATERIALS.basket,
		shape = "Cylinder",
		collide = true,
	})
	add({
		name = "HangingCloth",
		size = Data.CLOTH.size,
		offset = Data.CLOTH.offset,
		colour = { 210, 178, 122 },
		material = Data.MATERIALS.cloth,
		collide = false,
	})
	add({
		name = "LampPost",
		size = Data.LAMP.postSize,
		offset = Data.LAMP.postOffset,
		colour = { 92, 86, 76 },
		material = Data.MATERIALS.wood,
		collide = true,
	})
	add({
		name = "Lamp",
		size = Data.LAMP.lampSize,
		offset = Data.LAMP.lampOffset,
		colour = { 255, 222, 120 },
		material = Data.MATERIALS.lamp,
		collide = false,
	})
	for _, stripe in ipairs(Data.stripeParts()) do
		add({
			name = stripe.name,
			size = stripe.size,
			offset = stripe.offset,
			colour = Data.COLOURS[stripe.colour],
			material = Data.MATERIALS.cloth,
			collide = false,
			stripe = true,
			stripeColour = stripe.colour,
		})
	end
	return parts
end

local function stageStall(hub: any, recipe: any, folder: any): boolean
	local label = "pasar/" .. tostring(recipe.name)
	local okPoint, x, z = pcall(function()
		return MapSpec.hubPoint(hub, recipe.lx, recipe.lz)
	end)
	if not okPoint or type(x) ~= "number" or type(z) ~= "number" then
		fail("could not resolve hub point for " .. label)
		return false
	end
	local okModel, stall = pcall(function()
		return Instance.new("Model")
	end)
	if not okModel or not stall then
		fail("could not create stall Model for " .. label)
		return false
	end
	track(stall)
	local okSet = pcall(function()
		stall.Name = "PasarStall_" .. recipe.name
		stall:SetAttribute(Data.stallAttribute, true)
		stall:SetAttribute(Data.idAttribute, recipe.name)
		stall.Parent = folder
	end)
	if not okSet then
		fail("could not configure stall Model for " .. label)
		return false
	end
	local angle = math.rad(hub.yaw + recipe.yaw)
	local okBase, base = pcall(function()
		return CFrame.new(x, MapSpec.GROUND_Y, z) * CFrame.Angles(0, angle, 0)
	end)
	if not okBase or not base then
		fail("could not build base CFrame for " .. label)
		return false
	end
	for _, descriptor in ipairs(partDescriptors()) do
		local okPart = pcall(function()
			local created = Instance.new("Part")
			created.Name = descriptor.name
			local shapeName = SHAPE_NAMES[descriptor.shape or "Block"]
			local okShape, shape = pcall(function()
				return (Enum :: any).PartType[shapeName]
			end)
			created.Shape = if okShape and shape then shape else Enum.PartType.Block
			created.Size = Vector3.new(descriptor.size[1], descriptor.size[2], descriptor.size[3])
			created.CFrame = base * CFrame.new(descriptor.offset[1], descriptor.offset[2], descriptor.offset[3])
			created.Color = Color3.fromRGB(descriptor.colour[1], descriptor.colour[2], descriptor.colour[3])
			created.Material = (Enum :: any).Material[descriptor.material] or Enum.Material.SmoothPlastic
			created.Anchored = true
			created.CanCollide = false
			created:SetAttribute(Data.partAttribute, true)
			created:SetAttribute(Data.collideAttribute, descriptor.collide == true)
			if descriptor.stripe then
				created:SetAttribute(Data.stripeAttribute, true)
				created:SetAttribute(Data.stripeColourAttribute, descriptor.stripeColour)
			end
			created.Parent = stall
			track(created)
		end)
		if not okPart then
			fail("could not stage part " .. descriptor.name .. " for " .. label)
		end
	end
	paintGroundPad(stall, label)
	return true
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		restoreSavedVoxels()
		clearActive()
		if not Workspace or not MapSpec then
			fail("missing Workspace/MapSpec")
			publishFailures()
			return
		end
		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)
		local okHub, hub = pcall(function()
			return MapSpec.hub("pasar")
		end)
		if not okHub or not hub then
			fail("no MapSpec hub for pasar")
			publishFailures()
			return
		end
		for _, recipe in ipairs(Data.stalls()) do
			stageStall(hub, recipe, folder)
		end
		publishFailures()
	end,

	restore = function()
		restoreSavedVoxels()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		publishFailures()
	end,
}

LookDevPasarAwningsR8.apply = applier.apply
LookDevPasarAwningsR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevPasarAwningsR8
