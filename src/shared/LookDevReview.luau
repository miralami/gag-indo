--!strict
-- LookDevReview: ONE-CALL Studio review toggles (WORK_QUEUE round 4 item 28, round-3 bug 7).
--
-- A `require(game.ReplicatedStorage.Shared.LookDev)` from the command bar / execute_luau VM gets a
-- FRESH LookDev with no appliers registered, so .enable("id") silently does nothing. This helper
-- first pcall(require)s the applier module(s) for the chosen candidate from the supplied root
-- (ServerScriptService.Server for server candidates, PlayerScripts.Client for client ones), so
-- the registration side effects happen in that same VM, and only then calls LookDev.enable.
--
-- PURE: no game API and no require at load. One line from the Studio command bar (Client or Server
-- datamodel both work; pass `game`):
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("sky_r3", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r3", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).disable()
-- Additive review staging (WORK_QUEUE item 136): enableAdditive stages without disabling anything
-- else, and disableAll restores every staged candidate plus the single enabled one:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("hubveg_r8", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("plots_r8", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("facades_r8", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("hubs_real_r9", game)
--   require(game.ReplicatedStorage.Shared.LookDevReview).disableAll()
-- Restore with the same module instance; IDs are the existing Shared.LookDev.IDS only.

local LookDevReview = {}

-- Every candidate in Shared.LookDev.IDS. `datamodel` selects the container under `root`;
-- `path` is the module path relative to that container.
LookDevReview.paths = {
	plaza_lighting = { datamodel = "client", path = { "World", "LookDevPlaza" } },
	police_walkin = { datamodel = "server", path = { "World", "LookDevWalkin" } },
	icons = { datamodel = "client", path = { "UI", "LookDevIcons" } },
	textures = { datamodel = "client", path = { "World", "LookDevTextures" } },
	npcs = { datamodel = "client", path = { "World", "LookDevNpcs" } },
	crops = { datamodel = "client", path = { "World", "LookDevCrops" } },
	hubprops = { datamodel = "client", path = { "World", "LookDevHubProps" } },
	sounds = { datamodel = "client", path = { "World", "LookDevSounds" } },
	corner = { datamodel = "client", path = { "World", "LookDevCorner" } },
	textures_r3 = { datamodel = "client", path = { "World", "LookDevTexturesR3" } },
	day_cycle = { datamodel = "client", path = { "World", "LookDevDayCycle" } },
	icons_r3 = { datamodel = "client", path = { "UI", "LookDevIconsR3" } },
	buildings_r3 = { datamodel = "server", path = { "World", "LookDevModelsR3" } },
	vegetation_r3 = { datamodel = "server", path = { "World", "LookDevModelsR3" } },
	props_r3 = { datamodel = "server", path = { "World", "LookDevModelsR3" } },
	npcs_r3 = { datamodel = "server", path = { "World", "LookDevModelsR3" } },
	sky_r3 = { datamodel = "client", path = { "World", "LookDevSkyR3" } },
	textures_r4 = { datamodel = "client", path = { "World", "LookDevTexturesR4" } },
	sky_r4_a = { datamodel = "client", path = { "World", "LookDevSkyR4" } },
	sky_r4_b = { datamodel = "client", path = { "World", "LookDevSkyR4" } },
	sky_r4_c = { datamodel = "client", path = { "World", "LookDevSkyR4" } },
	buildings_r4 = { datamodel = "server", path = { "World", "LookDevModelsBuildingsR4" } },
	vegetation_r4 = { datamodel = "server", path = { "World", "LookDevModelsVegetationR4" } },
	props_r4 = { datamodel = "server", path = { "World", "LookDevModelsPropsR4" } },
	npcs_r4 = { datamodel = "server", path = { "World", "LookDevModelsNpcsR4" } },
	spawn_ground_r5 = { datamodel = "server", path = { "World", "LookDevSpawnGroundR5" } },
	vegetation_r5 = { datamodel = "server", path = { "World", "LookDevModelsVegetationR5" } },
	sky_r5 = { datamodel = "client", path = { "World", "LookDevSkyR5" } },
	props_r5 = { datamodel = "server", path = { "World", "LookDevModelsPropsR5" } },
	npcs_r5 = { datamodel = "server", path = { "World", "LookDevModelsNpcsR5" } },
	spawn_r5 = { datamodel = "server", path = { "World", "LookDevSpawnDressingR5" } },
	sky_r6_a = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	sky_r6_b = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	sky_r6_c = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	sky_r6_d = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	sky_r6_e = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	sky_r6_f = { datamodel = "client", path = { "World", "LookDevSkyR6" } },
	spawn_ground_r6 = { datamodel = "server", path = { "World", "LookDevSpawnGroundR6" } },
	terrain_r6_a = { datamodel = "client", path = { "World", "LookDevTerrainR6" } },
	terrain_r6_b = { datamodel = "client", path = { "World", "LookDevTerrainR6" } },
	vegetation_r6 = { datamodel = "server", path = { "World", "LookDevModelsVegetationR6" } },
	npcs_r6 = { datamodel = "server", path = { "World", "LookDevModelsNpcsR6" } },
	props_r6 = { datamodel = "server", path = { "World", "LookDevModelsPropsR6" } },
	vegetation_r7 = { datamodel = "server", path = { "World", "LookDevModelsVegetationR7" } },
	npcs_r7 = { datamodel = "server", path = { "World", "LookDevModelsNpcsR7" } },
	props_r7 = { datamodel = "server", path = { "World", "LookDevModelsPropsR7" } },
	hubveg_r8 = { datamodel = "server", path = { "World", "LookDevModelsVegetationHubR8" } },
	plots_r8 = { datamodel = "server", path = { "World", "LookDevPlotsR8" } },
	sawah_r8 = { datamodel = "server", path = { "World", "LookDevSawahR8" } },
	river_r8 = { datamodel = "server", path = { "World", "LookDevRiverR8" } },
	pathedge_r8 = { datamodel = "server", path = { "World", "LookDevPathEdgeR8" } },
	water_r8_a = { datamodel = "client", path = { "World", "LookDevWaterR8" } },
	water_r8_b = { datamodel = "client", path = { "World", "LookDevWaterR8" } },
	water_r8_c = { datamodel = "client", path = { "World", "LookDevWaterR8" } },
	buildings_r8 = { datamodel = "server", path = { "World", "LookDevBuildingsR8" } },
	facades_r8 = { datamodel = "server", path = { "World", "LookDevFacadesR8" } },
	hubprops_r8 = { datamodel = "server", path = { "World", "LookDevHubPropsR8" } },
	forest_pines_legacy = { datamodel = "server", path = { "World", "LookDevForestPinesLegacy" } },
	blocks_r9 = { datamodel = "server", path = { "World", "LookDevBlocksR9" } },
	hubs_real_r9 = { datamodel = "server", path = { "World", "LookDevHubsRealR9" } },
	pasar_awnings_r8 = { datamodel = "server", path = { "World", "LookDevPasarAwningsR8" } },
	plaza_r9 = { datamodel = "server", path = { "World", "LookDevPlazaR9" } },
	ronda_tower_r9 = { datamodel = "server", path = { "World", "LookDevRondaTowerR9" } },
	rocks_r9 = { datamodel = "server", path = { "World", "LookDevRocksR9" } },
	streetfurn_r8 = { datamodel = "server", path = { "World", "LookDevStreetFurnR8" } },
	spanduk_r8 = { datamodel = "server", path = { "World", "LookDevSpandukR8" } },
	animals_r8 = { datamodel = "client", path = { "World", "LookDevAnimalsR8" } },
	flyers_r8 = { datamodel = "client", path = { "World", "LookDevFlyersR8" } },
	smoke_r8 = { datamodel = "client", path = { "World", "LookDevSmokeR8" } },
	wind_r8 = { datamodel = "client", path = { "World", "LookDevWindR8" } },
	npcs_r8 = { datamodel = "server", path = { "World", "LookDevModelsNpcsR8" } },
	npcs_idle_r8 = { datamodel = "server", path = { "World", "LookDevNpcsIdleR8" } },
	ambient_walkers_r8 = { datamodel = "server", path = { "World", "LookDevAmbientWalkersR8" } },
	day_cycle_r8 = { datamodel = "client", path = { "World", "LookDevDayCycleR8" } },
	night_r8 = { datamodel = "server", path = { "World", "LookDevNightR8" } },
	grade_r8_a = { datamodel = "server", path = { "World", "LookDevGradeR8" } },
	grade_r8_b = { datamodel = "server", path = { "World", "LookDevGradeR8" } },
	grade_r8_c = { datamodel = "server", path = { "World", "LookDevGradeR8" } },
	sounds_r8 = { datamodel = "server", path = { "World", "LookDevSoundsR8" } },
	lapangan_r8 = { datamodel = "server", path = { "World", "LookDevLapanganR8" } },
	pasar_ground_r8 = { datamodel = "server", path = { "World", "LookDevPasarGroundR8" } },
	musala_r8 = { datamodel = "server", path = { "World", "LookDevMusalaR8" } },
	lumbung_r8 = { datamodel = "server", path = { "World", "LookDevLumbungR8" } },
	perahu_r8 = { datamodel = "server", path = { "World", "LookDevPerahuR8" } },
	irrigation_r8 = { datamodel = "server", path = { "World", "LookDevIrrigationR8" } },
}

function LookDevReview.pathsFor(id: string): any?
	return LookDevReview.paths[id]
end

-- Resolve the datamodel container. Direct fields make a one-call command-bar helper possible with
-- `game` itself; the short aliases also let tests pass tiny fake roots.
-- Member reads are individually pcall-guarded: on a real DataModel, indexing a service that is not
-- a member throws (e.g. PlayerScripts on the Client DataModel), which must not abort resolution.
local function get(obj: any, key: string): any?
	if type(obj) ~= "table" and typeof(obj) ~= "Instance" then
		return nil
	end
	local ok, value = pcall(function()
		return obj[key]
	end)
	if ok then
		return value
	end
	return nil
end

function LookDevReview.resolveContainer(datamodel: string, root: any): any?
	if type(root) ~= "table" and typeof(root) ~= "Instance" then
		return nil
	end
	if datamodel == "server" then
		local sss = get(root, "ServerScriptService")
		return get(sss, "Server") or get(root, "Server") or nil
	end
	local players = get(root, "Players")
	local localPlayer = get(players, "LocalPlayer")
	local playerScripts = get(localPlayer, "PlayerScripts")
	local client = get(playerScripts, "Client")
	if not client then
		local directScripts = get(root, "PlayerScripts")
		client = get(directScripts, "Client")
	end
	if not client then
		local starterPlayer = get(root, "StarterPlayer")
		local starterScripts = get(starterPlayer, "StarterPlayerScripts")
		client = get(starterScripts, "Client")
	end
	if not client then
		client = get(root, "Client")
	end
	return client or nil
end

local function dataModel(): any?
	local ok, gameModel = pcall(function()
		return game
	end)
	return if ok then gameModel else nil
end

local function sharedLookDev(): any
	-- Lazy: keeps this module pure at load, and `script.Parent.LookDev` is the same shared module
	-- instance every applier registered into at boot or during prepare().
	return require(script.Parent.LookDev)
end

-- Require the applier module(s) for this candidate in THIS VM, before .enable() is called.
function LookDevReview.prepare(id: string, root: any?): (boolean, string?)
	local entry = LookDevReview.pathsFor(id)
	if not entry then
		return false, "unknown review candidate"
	end
	root = if root == nil then dataModel() else root
	local container = LookDevReview.resolveContainer(entry.datamodel, root)
	if not container then
		return false, "missing " .. entry.datamodel .. " container"
	end
	local node = container
	for _, segment in entry.path do
		node = node[segment]
		if not node then
			return false, "missing applier module " .. table.concat(entry.path, ".")
		end
	end
	local ok, result = pcall(require, node)
	if not ok then
		return false, "applier require failed: " .. tostring(result)
	end
	return true, nil
end

-- One command: prepare (register in this VM) first, then the shared dot-syntax toggle.
function LookDevReview.enable(id: string, root: any?, opts: any?): (boolean, string?)
	local prepared, why = LookDevReview.prepare(id, root)
	if not prepared then
		return false, why
	end
	local LookDev = sharedLookDev()
	return LookDev.enable(id, opts)
end

function LookDevReview.disable(): boolean
	return sharedLookDev().disable()
end

-- Additive review staging (WORK_QUEUE item 136): prepare (register in this VM) first, then stage
-- without touching any other candidate. Existing enable/disable are unchanged.
function LookDevReview.enableAdditive(id: string, root: any?, opts: any?): (boolean, string?)
	local prepared, why = LookDevReview.prepare(id, root)
	if not prepared then
		return false, why
	end
	return sharedLookDev().enableAdditive(id, opts)
end

function LookDevReview.disableAll(): boolean
	return sharedLookDev().disableAll()
end

return LookDevReview
