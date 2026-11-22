-- LookDevWaterR8: client appliers for the OFF-BY-DEFAULT "water_r8_a/b/c" candidates
-- (WORK_QUEUE section M item 76). One make() factory, three palettes; each variant saves and
-- restores the exact Terrain water values it overwrites.
-- Every engine call is pcall-guarded. No Part or Instance is created, no asset ID literal appears
-- here, and no visual verdict is claimed.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local ModelMapWaterR8 = require(Shared.ModelMapWaterR8)

type Applier = { apply: (any) -> (), restore: () -> () }

local function findTerrain(): any?
	local ok, workspace = pcall(function()
		return game:GetService("Workspace")
	end)
	if not ok or not workspace then
		return nil
	end
	local okFind, terrain = pcall(function()
		return workspace:FindFirstChildOfClass("Terrain")
	end)
	return if okFind then terrain else nil
end

local function make(key: string): Applier
	local previous: { [string]: any } = {}
	local applied = false

	local function apply(_plan: any)
		if applied then
			return
		end
		previous = {}
		local values = ModelMapWaterR8.valuesFor(key)
		if not values then
			warn("water_r8: unknown palette " .. tostring(key))
			return
		end
		local terrain = findTerrain()
		if not terrain then
			warn("water_r8: no Terrain in Workspace")
			return
		end
		for _, property in ipairs(ModelMapWaterR8.properties) do
			local okRead, current = pcall(function()
				return terrain[property]
			end)
			if not okRead then
				warn("water_r8: could not read Terrain." .. property .. ": " .. tostring(current))
				continue
			end
			previous[property] = current
			local target = values[property]
			if property == "WaterColor" then
				local okColor, color = pcall(function()
					return Color3.fromRGB(target.r, target.g, target.b)
				end)
				if not okColor or not color then
					warn(
						"water_r8: could not build " .. property .. " for " .. tostring(key) .. ": " .. tostring(color)
					)
					continue
				end
				target = color
			end
			local okSet, err = pcall(function()
				terrain[property] = target
			end)
			if not okSet then
				warn("water_r8: could not set Terrain." .. property .. ": " .. tostring(err))
			end
		end
		applied = true
	end

	local function restore()
		if not applied then
			return
		end
		applied = false
		local terrain = findTerrain()
		if terrain then
			for property, value in pairs(previous) do
				local ok, err = pcall(function()
					terrain[property] = value
				end)
				if not ok then
					warn("water_r8: could not restore Terrain." .. property .. ": " .. tostring(err))
				end
			end
		end
		previous = {}
	end

	return { apply = apply, restore = restore }
end

local LookDevWaterR8 = {}

LookDevWaterR8.appliers = {
	a = make("a"),
	b = make("b"),
	c = make("c"),
}

for _, key in ipairs(ModelMapWaterR8.order) do
	LookDev.register(ModelMapWaterR8.idPrefix .. key, LookDevWaterR8.appliers[key])
end

return LookDevWaterR8
