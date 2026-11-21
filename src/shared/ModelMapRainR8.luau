-- ModelMapRainR8: pure data for the OFF-BY-DEFAULT "rain_r8" LookDev look (WORK_QUEUE section N
-- item 120). A client rain ring of at most three textureless ParticleEmitter Parts plus a morning
-- mist bump on the existing Atmosphere. Rain is gated on the live weather string "hujan"; "cerah"
-- leaves every emitter disabled. No asset IDs, no brand, no decal, no player-facing text.
--
-- SCOPE: the applier owns one Folder of its own Parts, the existing Atmosphere.Density scalar and
-- one Heartbeat that follows CurrentCamera. No Terrain voxel edit, no DataStore/player/crop state,
-- no ColorCorrection/Bloom/SunRays/ClockTime write. The client applier converts these plain values
-- at apply time and restores every overwritten scalar exactly.
--
-- SPLASH_Y is the documented client-side ground height (Ground.Y 0.5 + 0.03). MapSpec is not
-- reachable from the Client VM, so the splash Part uses this constant instead of a runtime lookup.

local ModelMapRainR8 = {}

ModelMapRainR8.id = "rain_r8"
ModelMapRainR8.FOLDER = "LookDevRainR8_rain_r8"
ModelMapRainR8.MAX_EMITTERS = 3
ModelMapRainR8.MAX_RATE = 60

-- Two camera-following ring emitters and one ground splash. Ring offsets are camera-local; the
-- splash uses SPLASH_Y as its world Y and only borrows the camera's horizontal position.
ModelMapRainR8.SPLASH_Y = 0.53
ModelMapRainR8.EMITTERS = {
	{
		id = "ring_front",
		kind = "ring",
		offset = { x = -8, y = 5, z = -12 },
		rate = 50,
		lifetime = { 0.8, 1.4 },
		speed = { 14, 20 },
		size = { 0.09, 0.05 },
		spread = { x = 2, y = 2 },
		color = { r = 180, g = 205, b = 232 },
	},
	{
		id = "ring_back",
		kind = "ring",
		offset = { x = 8, y = 5, z = 12 },
		rate = 50,
		lifetime = { 0.8, 1.4 },
		speed = { 14, 20 },
		size = { 0.09, 0.05 },
		spread = { x = 2, y = 2 },
		color = { r = 180, g = 205, b = 232 },
	},
	{
		id = "ground_splash",
		kind = "splash",
		offset = { x = 0, y = 0, z = -6 },
		rate = 44,
		lifetime = { 0.3, 0.6 },
		speed = { 2, 4 },
		size = { 0.06, 0.03 },
		spread = { x = 35, y = 35 },
		color = { r = 198, g = 214, b = 226 },
	},
}

-- Morning mist: a bounded additive bump on the existing Atmosphere.Density, never an unbounded
-- write. The applier clamps to MIST_MAX and snapshots the original value for exact LIFO restore.
ModelMapRainR8.MIST_DELTA = 0.05
ModelMapRainR8.MIST_MAX = 0.35

-- Deterministic cost proxy: the harness times the very same pump(dt) the Heartbeat calls. The
-- literal bound is kept here so the check and the spec cannot drift apart.
ModelMapRainR8.MAX_STEP_MS = 0.5
ModelMapRainR8.SIM_SECONDS = 60
ModelMapRainR8.DT = 1 / 60

ModelMapRainR8.WEATHER_RAIN = "hujan"
ModelMapRainR8.WEATHER_CLEAR = "cerah"

function ModelMapRainR8.emitterCount(): number
	return #ModelMapRainR8.EMITTERS
end

function ModelMapRainR8.maxRate(): number
	local highest = 0
	for _, spec in ipairs(ModelMapRainR8.EMITTERS) do
		if spec.rate > highest then
			highest = spec.rate
		end
	end
	return highest
end

function ModelMapRainR8.weatherIsRain(cuaca: any): boolean
	return cuaca == ModelMapRainR8.WEATHER_RAIN
end

return ModelMapRainR8
