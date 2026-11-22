--!strict
-- LookDevGroundVariationR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "ground_variation_r10"
-- candidate (WORK_QUEUE item 195). Repaints existing Terrain voxels on the playable lawns using
-- string tone keys from Shared.ModelMapGroundVariationR10. Cells outside Data.zoneClear, empty air
-- and water are never touched; occupancy is preserved byte-for-byte so walkable slopes stay exact.
-- The whole snapped region is snapshotted before painting and written back verbatim on restore.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("ground_variation_r10", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevGroundVariationR10] missing service " .. name)
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
		warn("[LookDevGroundVariationR10] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapGroundVariationR10),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevGroundVariationR10] could not require LookDev / ModelMapGroundVariationR10 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevGroundVariationR10] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevGroundVariationR10 = {}

local FAMILY_ID = Data.id
local VOXEL = 4 -- Studio probe: scalar resolution; Vector3.new(4,4,4) errors in ReadVoxels.
local HALF = 208

local failures = 0
local active = false
local saved: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevGroundVariationR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function terrainOf(): any?
	if not Workspace then
		return nil
	end
	local ok, terrain = pcall(function()
		return (Workspace :: any):FindFirstChildOfClass("Terrain")
	end)
	if not ok then
		return nil
	end
	return terrain
end

-- Snap outward to the 4-stud authoring grid. With GROUND_Y = 0.5 this is Region3(-208,-12,-208 ..
-- 208,20,208): 104 x 8 x 104 voxels (studio-probed 2026-11-22).
local function makeRegion(): any?
	if
		not MapSpec
		or type((MapSpec :: any).GROUND_Y) ~= "number"
		or type((MapSpec :: any).TERRAIN_BASE_Y) ~= "number"
	then
		return nil
	end
	local ok, region = pcall(function()
		return Region3.new(
			Vector3.new(-HALF, math.floor(((MapSpec :: any).TERRAIN_BASE_Y - 2 * VOXEL) / VOXEL) * VOXEL, -HALF),
			Vector3.new(HALF, math.ceil(((MapSpec :: any).GROUND_Y + 4 * VOXEL) / VOXEL) * VOXEL, HALF)
		)
	end)
	if not ok then
		return nil
	end
	return region
end

local function apply(_plan)
	failures = 0
	pcall(function()
		LookDevFailures.reset(FAMILY_ID)
	end)
	if active then
		publishFailures()
		return
	end

	local terrain = terrainOf()
	if not terrain then
		fail("missing Terrain")
		publishFailures()
		return
	end
	local region = makeRegion()
	if not region then
		fail("missing MapSpec bounds")
		publishFailures()
		return
	end

	-- Snapshot FIRST. ReadVoxels returns only materials + occupancy; do not invent a water table.
	local okRead, materials, occupancies = pcall(function()
		return terrain:ReadVoxels(region, VOXEL)
	end)
	if not okRead or type(materials) ~= "table" or type(occupancies) ~= "table" then
		fail("ReadVoxels snapshot failed")
		publishFailures()
		return
	end
	saved = {
		terrain = terrain,
		region = region,
		materials = materials,
		occupancies = occupancies,
	}

	-- Decide once per X/Z column: all Y layers share the same zone and tone.
	local tones = {}
	local okTones = pcall(function()
		for ix, slab in ipairs(materials) do
			tones[ix] = {}
			local firstRow = slab and slab[1]
			if type(firstRow) ~= "table" then
				continue
			end
			for iz = 1, #firstRow do
				local x = -HALF + (ix - 0.5) * VOXEL
				local z = -HALF + (iz - 0.5) * VOXEL
				if Data.zoneClear(x, z) then
					local tone = Data.toneAt(x, z)
					if type(tone) == "string" then
						-- LeafyGrass exists in Enum.Material but not in LookDev.BUILTIN_MATERIALS;
						-- that guard is for part materials, not for voxel painting.
						tones[ix][iz] = (Enum :: any).Material[tone]
					end
				end
			end
		end
	end)

	-- Clone into a NEW array so the snapshot stays byte-for-byte intact for restore.
	local painted = {}
	local okPaint = okTones
		and pcall(function()
			for ix, slab in ipairs(materials) do
				local outSlab = {}
				painted[ix] = outSlab
				for iy, row in ipairs(slab) do
					local outRow = {}
					outSlab[iy] = outRow
					local occRow = occupancies[ix] and occupancies[ix][iy]
					local column = tones[ix]
					for iz, material in ipairs(row) do
						local occupancy = occRow and occRow[iz]
						local replacement = column and column[iz]
						if
							replacement ~= nil
							and occupancy ~= nil
							and occupancy > 0
							and material ~= Enum.Material.Air
						then
							outRow[iz] = replacement
						else
							outRow[iz] = material
						end
					end
				end
			end
		end)
	if not okPaint then
		fail("tone sampling / material build failed")
		saved = nil
		publishFailures()
		return
	end

	local okWrite = pcall(function()
		terrain:WriteVoxels(region, VOXEL, painted, occupancies)
	end)
	if not okWrite then
		fail("WriteVoxels apply failed")
		saved = nil
		publishFailures()
		return
	end

	active = true
	publishFailures()
end

local function restore()
	if not active or not saved then
		return
	end
	local entry = saved
	local ok = pcall(function()
		entry.terrain:WriteVoxels(entry.region, VOXEL, entry.materials, entry.occupancies)
	end)
	if not ok then
		fail("WriteVoxels restore failed")
		publishFailures()
		return
	end
	active = false
	saved = nil
end

LookDevGroundVariationR10.apply = apply
LookDevGroundVariationR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevGroundVariationR10
