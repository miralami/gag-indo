--!strict
-- GreyboxTerrainConfig: pure-data switches for base terrain decoration and appearance.
-- WORK_QUEUE item 266: short grass everywhere the camera looks.

local GreyboxTerrainConfig = {
	-- When false, Terrain.Decoration (tall grass blades) is disabled, keeping short turf.
	-- Designer choice: flip back to true if grass blades are desired in future passes.
	GRASS_DECORATION = false,

	-- WORK_QUEUE item 268: dome hills render as dark specks on the clean horizon.
	-- When false, Greybox gates Landscape's hill FillBall pass off; clearBlocks and the
	-- item 242 horizon fill stay on, so the horizon remains closed. Designer choice:
	-- flip back to true if dome hills are wanted in a future pass.
	DOME_HILLS = false,
}

return GreyboxTerrainConfig
