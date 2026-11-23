--!strict
-- LookDevMountainsR10: SERVER-ONLY applier for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE items 243 + 251 + 260, rebuilt as terrain after the designer rejected the box wall).
-- The mountains are written into Workspace.Terrain with FillBall / FillCylinder / FillWedge in three
-- ridge bands outside the forest ring; no BaseParts are created. Shapes come from
-- Shared.ModelMapMountainsR10 and are written in yielding chunks (task.wait). Restore fills the exact
-- same shapes with Air; they never overlap the playable plateau (radius 400) or the forest ring, so
-- carving Air is safe. A mild bluish Atmosphere is applied only while enabled, and the previous
-- Atmosphere properties (or its absence) are restored. apply/restore are idempotent and pcall-guarded.
-- Enable from the Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("mountains_r10", game)

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
local Lighting = service("Lighting")
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
local ATMOSPHERE_PROPS = { "Color", "Density", "Haze" }

local failures = 0
local active = false
-- Bumped by every apply/restore so an older yielding pass stops as soon as a newer one starts.
local generation = 0
local written: { any } = {}
local createdAtmosphere: any? = nil
local savedAtmosphere: { [string]: any }? = nil
local atmosphereRef: any? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevMountainsR10] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(FAMILY_ID, failures)
	end)
end

local function terrain(): any?
	local ok, value = pcall(function()
		return (Workspace :: any).Terrain
	end)
	if ok and value then
		return value
	end
	fail("Workspace.Terrain is missing")
	return nil
end

local function resolveMaterial(name: string): any?
	local ok, material = pcall(function()
		return (Enum :: any).Material[name]
	end)
	if ok and material then
		return material
	end
	fail("could not resolve terrain material " .. tostring(name))
	return nil
end

-- One shape into the terrain. `air` writes Enum.Material.Air with the same geometry (restore).
local function fillShape(target: any, shape: any, air: boolean): boolean
	local material = if air then (Enum :: any).Material.Air else resolveMaterial(shape.material)
	if not material then
		return false
	end
	local ok, why = pcall(function()
		if shape.kind == "Ball" then
			target:FillBall(Vector3.new(shape.x, shape.y, shape.z), shape.radius, material)
		elseif shape.kind == "Cylinder" then
			target:FillCylinder(CFrame.new(shape.x, shape.y, shape.z), shape.height, shape.radius, material)
		elseif shape.kind == "Wedge" then
			target:FillWedge(
				CFrame.new(shape.x, shape.y, shape.z) * CFrame.Angles(0, shape.yaw, 0),
				Vector3.new(shape.sx, shape.sy, shape.sz),
				material
			)
		else
			error("unknown shape kind " .. tostring(shape.kind))
		end
	end)
	if not ok then
		fail("could not fill " .. tostring(shape.kind) .. ": " .. tostring(why))
		return false
	end
	return true
end

local function lightingAtmosphere(): any?
	if not Lighting then
		return nil
	end
	local ok, found = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("Atmosphere")
	end)
	if ok then
		return found
	end
	return nil
end

local function applyAtmosphere()
	if not Lighting then
		return
	end
	local config = (Data :: any).ATMOSPHERE
	local okColor, tint = pcall(function()
		return Color3.fromRGB(config.color.r, config.color.g, config.color.b)
	end)
	if not okColor then
		return
	end
	local existing = lightingAtmosphere()
	if existing then
		local saved: { [string]: any } = {}
		local okRead = pcall(function()
			for _, prop in ipairs(ATMOSPHERE_PROPS) do
				saved[prop] = existing[prop]
			end
		end)
		if not okRead then
			return
		end
		savedAtmosphere = saved
		atmosphereRef = existing
		pcall(function()
			existing.Color = existing.Color:Lerp(tint, 0.5)
			existing.Density = math.max(existing.Density, config.density)
			existing.Haze = math.max(existing.Haze, config.haze)
		end)
		return
	end
	local okNew, made = pcall(function()
		local atmosphere = (Instance :: any).new("Atmosphere")
		atmosphere.Name = "LookDevMountainsR10Atmosphere"
		atmosphere.Color = tint
		atmosphere.Density = config.density
		atmosphere.Haze = config.haze
		atmosphere.Parent = Lighting
		return atmosphere
	end)
	if okNew and made then
		createdAtmosphere = made
	end
end

local function restoreAtmosphere()
	if createdAtmosphere then
		local made = createdAtmosphere
		createdAtmosphere = nil
		pcall(function()
			(made :: any):Destroy()
		end)
	end
	local saved, ref = savedAtmosphere, atmosphereRef
	savedAtmosphere, atmosphereRef = nil, nil
	if saved and ref then
		for _, prop in ipairs(ATMOSPHERE_PROPS) do
			local ok, why = pcall(function()
				(ref :: any)[prop] = (saved :: any)[prop]
			end)
			if not ok then
				fail("could not restore Atmosphere." .. prop .. ": " .. tostring(why))
			end
		end
	end
end

local function apply(_plan: any)
	if active then
		return
	end
	failures = 0
	generation += 1
	local mine = generation
	active = true
	written = {}

	local target = terrain()
	if target then
		local list = (Data :: any).shapes()
		local chunk = (Data :: any).CHUNK
		local count = 0
		for _, shape in ipairs(list) do
			if mine ~= generation then
				return -- restore() ran while this pass was yielding
			end
			-- Recorded before the fill: a half-finished pass is still erased by restore.
			written[#written + 1] = shape
			fillShape(target, shape, false)
			count += 1
			if count % chunk == 0 then
				task.wait()
			end
		end
	end
	if mine ~= generation then
		return
	end
	applyAtmosphere()
	publishFailures()
end

local function restore()
	if not active and #written == 0 and not createdAtmosphere and not savedAtmosphere then
		return
	end
	generation += 1
	local target = terrain()
	if target then
		local chunk = (Data :: any).CHUNK
		local count = 0
		local pending = written
		written = {}
		for index = #pending, 1, -1 do
			fillShape(target, pending[index], true)
			count += 1
			if count % chunk == 0 then
				task.wait()
			end
		end
	else
		written = {}
	end
	restoreAtmosphere()
	active = false
	publishFailures()
end

LookDevMountainsR10.apply = apply
LookDevMountainsR10.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevMountainsR10
