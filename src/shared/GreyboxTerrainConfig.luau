--!strict
-- GreyboxTerrainConfig: pure-data switches for base terrain decoration and appearance.
-- WORK_QUEUE item 266: short grass everywhere the camera looks.

local GreyboxTerrainConfig = {
	-- When false, Terrain.Decoration (tall grass blades) is disabled, keeping short turf.
	-- Designer choice: flip back to true if grass blades are desired in future passes.
	GRASS_DECORATION = false,
}

return GreyboxTerrainConfig
