--!strict
-- LookDevLumbungR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "lumbung_r8" candidate
-- (WORK_QUEUE section N item 111). Stages one folder of original Parts: one lumbung padi on stilts
-- plus a bamboo fence, toga/chilli pots, a rice drying mat and rake marks at each of three house
-- yards. It also paints three real Ground voxel pads so the yards are not grass; every pad is
-- snapshotted first and restored in LIFO order on restore. All staged Parts are anchored and
-- non-collidable. Game APIs are pcall guarded and failures pad the published LookDevFailures
-- counter. Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("lumbung_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevLumbungR8] missing service " .. name)
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
		warn("[LookDevLumbungR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapLumbungR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevLumbungR8] could not require LookDev / ModelMapLumbungR8 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevLumbungR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevLumbungR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local savedVoxels: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevLumbungR8] " .. message)
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

local function restoreSavedVoxels()
	-- LIFO: later pads can overlap earlier ones, so write the newest snapshot first.
	for index = #savedVoxels, 1, -1 do
		local entry = savedVoxels[index]
		local ok = pcall(function()
			entry.terrain:WriteVoxels(entry.region, entry.voxel, entry.materials, entry.occupancies, entry.waterMask)
		end)
		if not ok then
			fail("WriteVoxels restore failed for " .. tostring(entry.label))
		end
	end
	table.clear(savedVoxels)
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
	restoreSavedVoxels()
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

local function hubMap(): any?
	if not MapSpec or type((MapSpec :: any).hub) ~= "function" then
		fail("missing MapSpec.hub")
		return nil
	end
	local out = {}
	for _, key in ipairs(Data.HOUSE_KEYS) do
		local okHub, hub = pcall(function()
			return (MapSpec :: any).hub(key)
		end)
		if not okHub or not hub then
			fail("missing MapSpec.hub(" .. key .. ")")
			return nil
		end
		out[key] = hub
	end
	return out
end

-- One anchored, non-collidable original Part. Barn parts use Data.sitePoint; yard parts use
-- MapSpec.hubPoint with yard-local offsets, so no world-coordinate literal lives here.
local function addPart(parent: any, recipe: any, x: number, y: number, z: number, yaw: number, label: string): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Lumbung_" .. recipe.name
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
		local colour = Data.COLOURS[recipe.colour] or Data.COLOURS.wood
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material] or "Wood"] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		if recipe.kind == Data.KIND.gauge then
			part.Transparency = 1
			part:SetAttribute(Data.doorWidthAttribute, Data.DOOR_W)
			part:SetAttribute(Data.doorHeightAttribute, Data.DOOR_H)
			part:SetAttribute(Data.doorDepthAttribute, Data.DOOR_D)
		end
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, recipe.kind)
		part.Parent = parent
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. tostring(recipe.name) .. " for " .. label)
		return nil
	end
	track(created)
	return created
end

local VOXEL = if MapSpec and type((MapSpec :: any).TERRAIN_VOXEL) == "number" then (MapSpec :: any).TERRAIN_VOXEL else 4

-- Snapshot the whole snapped cell box before any FillBlock. ReadVoxels and WriteVoxels use the same
-- Region3 and resolution so restore is byte-for-byte exact.
local function paintYardPad(yard: any, label: string)
	if not MapSpec or not Workspace then
		fail("missing MapSpec/Workspace; Ground pad skipped for " .. label)
		return
	end
	local terrain = (Workspace :: any):FindFirstChildOfClass("Terrain")
	if not terrain then
		fail("missing Terrain; Ground pad skipped for " .. label)
		return
	end
	local regionInfo = yard.region
	if type(regionInfo) ~= "table" then
		fail("missing snapped cells for " .. label)
		return
	end
	local bottom = (MapSpec :: any).GROUND_Y - VOXEL
	local cy, sy = (MapSpec :: any).volumeForTop(bottom, (MapSpec :: any).GROUND_Y)
	local sx, sz = regionInfo.maxX - regionInfo.minX, regionInfo.maxZ - regionInfo.minZ
	local cap = if type((MapSpec :: any).MAX_FILL_SPAN) == "number" then (MapSpec :: any).MAX_FILL_SPAN else 40
	if sx <= 0 or sz <= 0 or sx > cap or sz > cap then
		fail("Ground pad span rejected for " .. label)
		return
	end
	local minY = math.floor((cy - sy / 2) / VOXEL) * VOXEL
	local maxY = math.ceil((cy + sy / 2) / VOXEL) * VOXEL
	if maxY - minY < VOXEL then
		maxY = minY + VOXEL
	end
	local region = Region3.new(
		Vector3.new(regionInfo.minX, minY, regionInfo.minZ),
		Vector3.new(regionInfo.maxX, maxY, regionInfo.maxZ)
	)
	local okRead, materials, occupancies, waterMask = pcall(function()
		return terrain:ReadVoxels(region, VOXEL)
	end)
	if not okRead or type(materials) ~= "table" or type(occupancies) ~= "table" then
		fail("ReadVoxels snapshot failed for " .. label)
		return
	end
	savedVoxels[#savedVoxels + 1] = {
		terrain = terrain,
		region = region,
		voxel = VOXEL,
		materials = materials,
		occupancies = occupancies,
		waterMask = waterMask,
		label = label,
	}
	local px, pz = (regionInfo.minX + regionInfo.maxX) / 2, (regionInfo.minZ + regionInfo.maxZ) / 2
	local okFill = pcall(function()
		terrain:FillBlock(CFrame.new(px, cy, pz), Vector3.new(sx, sy, sz), Enum.Material.Ground)
	end)
	if not okFill then
		fail("Ground pad FillBlock failed for " .. label)
	end
end

local applier = {
	apply = function()
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace then
			fail("missing Workspace")
			publishFailures()
			return
		end
		local hubs = hubMap()
		if not hubs or type((MapSpec :: any).hubPoint) ~= "function" or type((MapSpec :: any).GROUND_Y) ~= "number" then
			fail("MapSpec hubPoint / GROUND_Y unavailable")
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
		pcall(function()
			folder:SetAttribute(Data.stageAttribute, Data.familyId)
		end)

		local groundY = (MapSpec :: any).GROUND_Y
		local barnHub = hubs[Data.BARN.hubKey]
		local bx, bz = (MapSpec :: any).hubPoint(barnHub, Data.BARN.lx, Data.BARN.lz)
		local centre = {
			x = bx,
			y = groundY,
			z = bz,
			yaw = barnHub.yaw + Data.BARN.yawOffsetDeg,
		}
		local yards = Data.yards(hubs)
		local yardByKey = {}
		for _, yard in ipairs(yards) do
			yardByKey[yard.key] = yard
		end
		if #yards ~= Data.YARD_COUNT then
			fail("yard sample count " .. tostring(#yards) .. " expected " .. tostring(Data.YARD_COUNT))
		end

		for _, recipe in ipairs(Data.parts()) do
			if recipe.scope == "barn" then
				local x, y, z = Data.sitePoint(centre, recipe.lx, recipe.ly, recipe.lz)
				addPart(folder, recipe, x, y, z, centre.yaw, "barn")
			else
				local yard = yardByKey[recipe.scope]
				local hub = hubs[recipe.scope]
				if yard and hub then
					local lx, lz = yard.lx + recipe.lx, yard.lz + recipe.lz
					local x, z = (MapSpec :: any).hubPoint(hub, lx, lz)
					addPart(folder, recipe, x, groundY + recipe.ly, z, hub.yaw, recipe.scope)
				end
			end
		end
		local gauge = Data.gauge()
		local gx, gy, gz = Data.sitePoint(centre, gauge.lx, gauge.ly, gauge.lz)
		addPart(folder, gauge, gx, gy, gz, centre.yaw, "door gauge")
		for _, yard in ipairs(yards) do
			paintYardPad(yard, yard.key)
		end
		publishFailures()
	end,

	restore = function()
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

LookDevLumbungR8.apply = applier.apply
LookDevLumbungR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevLumbungR8
