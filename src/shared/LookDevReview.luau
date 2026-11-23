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
	kincir_r8 = { datamodel = "server", path = { "World", "LookDevKincirR8" } },
	laundry_r8 = { datamodel = "server", path = { "World", "LookDevLaundryR8" } },
	layangan_r8 = { datamodel = "server", path = { "World", "LookDevLayanganR8" } },
	seated_r8 = { datamodel = "server", path = { "World", "LookDevSeatedR8" } },
	crops_showcase_r8 = { datamodel = "server", path = { "World", "LookDevCropsShowcaseR8" } },
	season_r8_hujan = { datamodel = "client", path = { "World", "LookDevSeasonR8" } },
	season_r8_kemarau = { datamodel = "client", path = { "World", "LookDevSeasonR8" } },
	season_r8_panen = { datamodel = "client", path = { "World", "LookDevSeasonR8" } },
	rain_r8 = { datamodel = "client", path = { "World", "LookDevRainR8" } },
	subuh_r8 = { datamodel = "client", path = { "World", "LookDevSubuhR8" } },
	balai_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	hub_canopy_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	blocks_shrubs_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	pasar_roof_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	warung_cluster_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	polisi_roof_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	pakrt_roof_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	sawah_gubuk_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	plots_mailbox_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	river_palms_r10 = { datamodel = "server", path = { "World", "LookDevCanonicalR10" } },
	meadow_r10 = { datamodel = "server", path = { "World", "LookDevMeadowR10" } },
	ground_variation_r10 = { datamodel = "server", path = { "World", "LookDevGroundVariationR10" } },
	paths_curved_r10 = { datamodel = "server", path = { "World", "LookDevPathsCurvedR10" } },
	horizon_fill_r10 = { datamodel = "server", path = { "World", "LookDevHorizonFillR10" } },
	mountains_r10 = { datamodel = "server", path = { "World", "LookDevMountainsR10" } },
	hill_dressing_r10 = { datamodel = "server", path = { "World", "LookDevHillDressingR10" } },
	kampung_r10 = { datamodel = "server", path = { "World", "LookDevKampungR10" } },
	road_fence_r10 = { datamodel = "server", path = { "World", "LookDevRoadFenceR10" } },
	lamps_r10 = { datamodel = "server", path = { "World", "LookDevLampsR10" } },
	signposts_r10 = { datamodel = "server", path = { "World", "LookDevSignpostsR10" } },
	bamboo_bridge_r10 = { datamodel = "server", path = { "World", "LookDevBambooBridgeR10" } },
	furrows_r10 = { datamodel = "server", path = { "World", "LookDevFurrowsR10" } },
	crop_stages_r10 = { datamodel = "server", path = { "World", "LookDevCropStagesR10" } },
	ditch_water_r10 = { datamodel = "server", path = { "World", "LookDevDitchWaterR10" } },
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

-- Review-capture HUD helper (WORK_QUEUE item 238). hideHud records the exact prior Enabled of every
-- ScreenGui under the player's PlayerGui and sets them all to false; restoreHud writes the saved
-- values back and clears the snapshot. No game API is touched at load. The root defaults to `game`;
-- in the SERVER VM Players.LocalPlayer is nil, so resolution falls back to GetPlayers()[1].
type HudEntry = { gui: any, enabled: any }
type HudState = { playerGui: any?, entries: { HudEntry } }
local hudState: HudState? = nil

local function resolveReviewPlayerGui(root: any): any?
	local players = get(root, "Players")
	if not players then
		local getService = get(root, "GetService")
		if type(getService) == "function" then
			local ok, service = pcall(getService, root, "Players")
			if ok then
				players = service
			end
		end
	end
	if not players then
		return nil
	end
	local localPlayer = get(players, "LocalPlayer")
	local playerGui = get(localPlayer, "PlayerGui")
	if playerGui then
		return playerGui
	end
	-- SERVER VM fallback: no LocalPlayer, use the first connected player's PlayerGui.
	local getPlayers = get(players, "GetPlayers")
	if type(getPlayers) ~= "function" then
		return nil
	end
	local ok, list = pcall(getPlayers, players)
	if not ok or type(list) ~= "table" then
		return nil
	end
	return get(list[1], "PlayerGui")
end

local function reviewScreenGuis(playerGui: any): { any }
	local all: { any } = {}
	local ok, list = pcall(function()
		return playerGui:GetDescendants()
	end)
	if ok and type(list) == "table" then
		for _, instance in ipairs(list) do
			all[#all + 1] = instance
		end
	else
		-- Fake DataModels in the Lune specs expose children, not GetDescendants.
		local function walk(node: any)
			local okChildren, children = pcall(function()
				return node:GetChildren()
			end)
			if not okChildren or type(children) ~= "table" then
				return
			end
			for _, child in ipairs(children) do
				all[#all + 1] = child
				walk(child)
			end
		end
		walk(playerGui)
	end
	local found: { any } = {}
	for _, instance in ipairs(all) do
		local okClass, className = pcall(function()
			return instance.ClassName
		end)
		local isScreen = okClass and className == "ScreenGui"
		if not isScreen then
			local okIsA, result = pcall(function()
				return instance:IsA("ScreenGui")
			end)
			isScreen = okIsA and result == true
		end
		if isScreen then
			found[#found + 1] = instance
		end
	end
	return found
end

-- WORK_QUEUE item 267: the Roblox top bar lives in CoreGui, not PlayerGui, so hiding PlayerGui
-- alone still left the top bar in sprint-4 captures. Only these three named ScreenGuis are touched;
-- capture-internal guis (CaptureManager / CaptureOverlay / ScreenshotsCarousel) stay enabled so
-- screen_capture keeps working. Everything is pcall-guarded: the SERVER VM has no CoreGui and fake
-- DataModels in specs have no such member, so this is a no-op in both.
local TOP_BAR_NAMES = { RobloxGui = true, TopBarApp = true, TopBarScrim = true }

local function resolveReviewCoreGui(root: any): any?
	local coreGui = get(root, "CoreGui")
	if not coreGui then
		local getService = get(root, "GetService")
		if type(getService) == "function" then
			local ok, service = pcall(getService, root, "CoreGui")
			if ok then
				coreGui = service
			end
		end
	end
	return coreGui
end

local function reviewTopBarGuis(root: any): { any }
	local found: { any } = {}
	local coreGui = resolveReviewCoreGui(root)
	if not coreGui then
		return found
	end
	for _, gui in ipairs(reviewScreenGuis(coreGui)) do
		local okName, name = pcall(function()
			return gui.Name
		end)
		if okName and TOP_BAR_NAMES[name] then
			found[#found + 1] = gui
		end
	end
	return found
end

function LookDevReview.hideHud(root: any?): number
	root = if root == nil then dataModel() else root
	local playerGui = if root ~= nil then resolveReviewPlayerGui(root) else nil
	local topBar = reviewTopBarGuis(root or dataModel())
	-- Item 267: a caller with only a top bar (or only a PlayerGui) still hides what it can. Avoid a
	-- spurious empty snapshot when neither container resolves.
	if not playerGui and #topBar == 0 then
		return 0
	end
	local state = hudState
	if not state then
		state = { playerGui = playerGui, entries = {} }
		hudState = state
	end
	local candidates = {}
	if playerGui then
		for _, gui in ipairs(reviewScreenGuis(playerGui)) do
			candidates[#candidates + 1] = gui
		end
	end
	for _, gui in ipairs(topBar) do
		candidates[#candidates + 1] = gui
	end
	for _, gui in ipairs(candidates) do
		local found = false
		for _, existing in ipairs(state.entries) do
			if existing.gui == gui then
				found = true
				break
			end
		end
		if not found then
			local ok, enabled = pcall(function()
				return gui.Enabled
			end)
			-- A second hide must never overwrite the values saved by the first.
			state.entries[#state.entries + 1] = { gui = gui, enabled = if ok then enabled else nil }
		end
		pcall(function()
			gui.Enabled = false
		end)
	end
	return #state.entries
end

function LookDevReview.restoreHud(): boolean
	local state = hudState
	if not state then
		return false
	end
	hudState = nil
	for _, entry in ipairs(state.entries) do
		pcall(function()
			entry.gui.Enabled = entry.enabled
		end)
	end
	return true
end

return LookDevReview
