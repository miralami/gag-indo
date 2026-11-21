-- Water: the client shipping default for river water (WORK_QUEUE section O item 137). The
-- designer chose water_r8_a; its five Terrain values are applied at boot next to the shipping
-- sky, with NO LookDev enable call. The r8 candidate appliers stay off by default and keep their
-- own save/restore state, so enabling/disabling one restores this default.
--
-- No instance is created and no asset ID appears here. Every engine read/write is pcall-guarded.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ModelMapWaterR8 = require(Shared.ModelMapWaterR8)

local Water = {}

-- Pure: a fresh copy of variant A's five values, so callers can mutate the result without
-- touching the shared data map. The nested WaterColor table is copied too.
function Water.defaultValues()
	local source = ModelMapWaterR8.valuesFor("a")
	return {
		WaterColor = {
			r = source.WaterColor.r,
			g = source.WaterColor.g,
			b = source.WaterColor.b,
		},
		WaterTransparency = source.WaterTransparency,
		WaterReflectance = source.WaterReflectance,
		WaterWaveSize = source.WaterWaveSize,
		WaterWaveSpeed = source.WaterWaveSpeed,
	}
end

-- Applied once from Main.client at startup. Independent of LookDevWaterR8.appliers.a: calling
-- that applier here would set its `applied` flag and break its later enable/disable round-trip.
function Water.mount()
	local okWorkspace, workspaceService = pcall(function()
		return game:GetService("Workspace")
	end)
	if not okWorkspace or not workspaceService then
		return -- no engine (e.g. a plain Lune harness); nothing to write
	end
	local okTerrain, terrain = pcall(function()
		return workspaceService:FindFirstChildOfClass("Terrain")
	end)
	if not okTerrain or not terrain then
		warn("water: could not find Terrain in Workspace: " .. tostring(terrain))
		return
	end

	local values = Water.defaultValues()
	for _, property in ipairs(ModelMapWaterR8.properties) do
		local target = values[property]
		if property == "WaterColor" then
			local okColor, color = pcall(function()
				return Color3.fromRGB(target.r, target.g, target.b)
			end)
			if not okColor or not color then
				warn("water: could not build WaterColor: " .. tostring(color))
				continue
			end
			target = color
		end
		local okSet, err = pcall(function()
			terrain[property] = target
		end)
		if not okSet then
			warn("water: could not set Terrain." .. property .. ": " .. tostring(err))
		end
	end
end

return Water
