-- Harness: test-only server hooks for the Studio playtest driver (MASTER_PLAN §3, task 0.3).
--
-- Why this exists: the 2026-11-13 Studio run could not trigger ProximityPrompts through the
-- bridge, so plant/harvest/sell/buy could not be driven at all. Every loop action is a server
-- call here instead, so the driver needs no key input. See docs/testing/HARNESS.md.
--
-- Gate: every hook needs RunService:IsStudio() AND the in-memory flag (only a Studio admin can
-- open it, same allowlist as AdminService) AND Admins.isAdmin. A published server fails the
-- Studio test, so the harness can never run there. Rate limited like every other remote.
--
-- It mints nothing: plant and harvest run FarmService.commitAttempt (the real resolver), sell
-- and buy are the real service calls, and saves still go through PlayerData.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Produce = require(Shared.Produce)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Admins = require(script.Parent.Parent.Live.Admins)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local ShopService = require(script.Parent.Parent.Economy.ShopService)
local FarmService = require(script.Parent.Parent.Farm.FarmService)
local StorageService = require(script.Parent.Parent.Farm.StorageService)
local PlotService = require(script.Parent.Parent.Farm.PlotService)
local QuestService = require(script.Parent.Parent.Progression.QuestService)
local OnboardingService = require(script.Parent.Parent.Progression.OnboardingService)
local Village = require(script.Parent.Parent.World.Village)
local Gate = require(script.Parent.Gate)

local Harness = {}

local RATE = 4 -- hooks per second per player, same shape as AdminService

local function reply(player: Player, payload: any)
	Remotes.Harness_Result:FireClient(player, payload)
end

local function fail(player: Player, message: string)
	reply(player, { ok = false, message = message })
end

-- Everything the driver may read back, in one table.
local function snapshot(player: Player): any?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local seeds = {}
	for _, cropId in Crops.order do
		seeds[cropId] = Inventory.getSeed(data, cropId)
	end
	local tiles = {}
	for index = 1, GameConfig.tilesBuilt do
		local entry = data.tiles["t" .. index]
		if entry then
			tiles[index] = {
				crop = entry.crop,
				ready = os.time() >= entry.plantedAt + entry.growSeconds,
				hot = entry.hot == true,
			}
		end
	end
	local tasks = {}
	for taskId, task in (data.quests and data.quests.tasks) or {} do
		tasks[taskId] = { progress = task.progress or 0, target = task.target or 1, done = task.done == true }
	end
	local plot = PlotService.getPlotOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local step = OnboardingService.current(data)

	return {
		name = player.Name,
		userId = player.UserId,
		cash = data.cash,
		lifetimeEarned = data.lifetimeEarned,
		rank = data.rank,
		seeds = seeds,
		tilesOwned = data.tilesOwned,
		tiles = tiles,
		sack = Produce.count(data.produce or {}),
		gudang = StorageService.used(data),
		plotIndex = plot and plot.index,
		tutorialStep = data.tutorial and data.tutorial.step,
		tutorialId = step and step.id,
		quests = tasks,
		shop = ShopService.stock(player),
		position = root and root.Position,
	}
end

-- Move the character so the real distance checks pass (Pasar, gudang, plot).
local function moveTo(player: Player, position: Vector3): boolean
	local character = player.Character
	if not character then
		return false
	end
	character:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	return true
end

local function firstEmptyTile(data): number?
	for index = 1, data.tilesOwned do
		if data.tiles["t" .. index] == nil then
			return index
		end
	end
	return nil
end

-- The decision is FarmService's (commitAttempt -> finish -> canPlant/doPlant). These two
-- helpers only explain a refusal after the fact; they never change state.
local function plantRefusal(data, index: number, cropId: string): string
	local crop = Crops.list[cropId]
	if not crop then
		return "unknown crop"
	end
	if index > data.tilesOwned then
		return `tile {index} is not owned`
	end
	if data.tiles["t" .. index] ~= nil then
		return `tile {index} is not empty`
	end
	if not EconomyService.hasRank(data, crop.rank) then
		return `rank locked: needs {crop.rank}`
	end
	if Inventory.getSeed(data, cropId) < 1 then
		return `no {cropId} seed`
	end
	return "plant refused"
end

local function plant(player: Player, value: any): (any?, string?)
	local data = PlayerData.get(player)
	if not data then
		return nil, "no save data yet"
	end
	local cropId = if type(value) == "table" and type(value.cropId) == "string" then value.cropId else "padi"
	if not Crops.list[cropId] then
		return nil, "unknown crop"
	end
	local index = if type(value) == "table" then tonumber(value.tile) else nil
	index = index or firstEmptyTile(data)
	if not index then
		return nil, "no empty owned tile"
	end
	-- The prompt path checks ownership before it opens an attempt; do the same.
	if index < 1 or index > data.tilesOwned then
		return nil, `tile {index} is not owned`
	end

	local planted = FarmService.commitAttempt(
		player,
		{ tile = index, action = "plant", cropId = cropId },
		GameConfig.autoQuality
	)
	if not planted then
		return nil, plantRefusal(data, index, cropId)
	end
	return snapshot(player)
end

-- The same seam covers harvest: finish re-checks the tile and runs the real doHarvest into
-- the sack, with the same rarity, traits, almanak, onboarding and quest hooks.
local function harvest(player: Player, value: any): (any?, string?)
	local data = PlayerData.get(player)
	if not data then
		return nil, "no save data yet"
	end
	local index = if type(value) == "table" then tonumber(value.tile) else nil
	index = index or FarmService.readyTiles(player)[1]
	if not index then
		return nil, "no ready tile"
	end
	if index > data.tilesOwned then
		return nil, `tile {index} is not owned`
	end

	local harvested = FarmService.commitAttempt(player, { tile = index, action = "harvest" }, GameConfig.autoQuality)
	if not harvested then
		return nil, `harvest refused on tile {index} (empty, still growing, or the sack is full)`
	end
	return snapshot(player)
end

local function sell(player: Player, value: any): (any?, string?)
	local channel = if type(value) == "table" and value.channel == "gelap" then "gelap" else "pasar"
	local data = PlayerData.get(player)
	if not data then
		return nil, "no save data yet"
	end
	if Produce.count(data.produce or {}) <= 0 then
		return nil, "sack is empty"
	end
	if not moveTo(player, Village.getPosition(channel)) then
		return nil, "no character to move"
	end
	EconomyService.sellAll(player, channel)
	return snapshot(player)
end

local function buy(player: Player, value: any): (any?, string?)
	if type(value) ~= "table" or type(value.cropId) ~= "string" then
		return nil, "need { cropId, amount }"
	end
	local amount = tonumber(value.amount) or 1
	if not ShopService.buy(player, value.cropId, amount) then
		return nil, `shop refused {value.cropId} x{amount} (stock, rank or cash)`
	end
	return snapshot(player)
end

local function quest(player: Player, value: any): (any?, string?)
	local taskId = if type(value) == "table" then value.taskId else nil
	if type(taskId) == "string" then
		if not QuestService.claimTask(player, taskId) then
			return nil, `task {taskId} is not claimable`
		end
	elseif not QuestService.claimDaily(player) then
		return nil, "daily reward already claimed"
	end
	return snapshot(player)
end

-- Screenshot staging: stand somewhere worth looking at.
local function goto(player: Player, value: any): (any?, string?)
	local name = if type(value) == "table" then value.name else nil
	local position: Vector3?
	if name == "plot" or name == "tile" then
		local plot = PlotService.getPlotOf(player)
		if not plot then
			return nil, "no plot yet"
		end
		if name == "plot" then
			position = plot.spawnCFrame.Position
		else
			local index = if type(value) == "table" then tonumber(value.tile) else nil
			local tile = plot.tiles[index or 1]
			position = tile and (tile.Position + Vector3.new(0, 3, 8))
		end
	elseif type(name) == "string" and Village.positions[name] then
		position = Village.getPosition(name)
	end
	if not position then
		return nil, "unknown place (plot, tile, pasar, gelap, pakrt, polisi, ronda, warung)"
	end
	if not moveTo(player, position) then
		return nil, "no character to move"
	end
	return snapshot(player)
end

-- Make every growing crop ready now, so the driver never waits out a grow timer.
local function ready(player: Player): (any?, string?)
	local data = PlayerData.get(player)
	if not data then
		return nil, "no save data yet"
	end
	local now = os.time()
	local shifted = 0
	for _, entry in data.tiles do
		if now < entry.plantedAt + entry.growSeconds then
			entry.plantedAt = now - entry.growSeconds
			shifted += 1
		end
	end
	FarmService.refresh(player)
	local state = snapshot(player)
	if state then
		state.shifted = shifted
	end
	return state
end

-- Save now and report, so persistence evidence does not depend on the driver leaving cleanly.
local function save(player: Player): (any?, string?)
	local profile = PlayerData.getProfile(player)
	if not profile then
		return nil, "no profile"
	end
	local ok = pcall(function()
		profile:Save()
	end)
	if not ok then
		return nil, "save failed (API services off?)"
	end
	return snapshot(player)
end

local handlers = {
	status = function(player)
		return snapshot(player)
	end,
	plant = plant,
	harvest = harvest,
	sell = sell,
	buy = buy,
	quest = quest,
	goto = goto,
	ready = ready,
	save = save,
}

local function enabled(player: Player): boolean
	return Gate.canCall({ studio = RunService:IsStudio(), admin = Admins.isAdmin(player.UserId) })
end

local function onCommand(player: Player, payload: any)
	if type(payload) ~= "table" or type(payload.action) ~= "string" then
		return
	end
	if not RateLimit.allow(player, "Harness_Command", RATE) then
		return
	end

	-- Opening the gate is its own guard: Studio + admin, no flag needed yet.
	if payload.action == "enable" then
		local ok = Gate.enable({ studio = RunService:IsStudio(), admin = Admins.isAdmin(player.UserId) })
		reply(player, {
			ok = ok,
			message = if ok then "Harness on." else "Refused: a Studio admin must enable it.",
		})
		return
	end
	if payload.action == "disable" then
		Gate.close()
		reply(player, { ok = true, message = "Harness off." })
		return
	end

	if not enabled(player) then
		fail(player, "Harness is off. Enable it from a Studio admin first.")
		return
	end
	local handler = handlers[payload.action]
	if not handler then
		fail(player, `Unknown action "{payload.action}".`)
		return
	end
	local result, err = handler(player, payload.value)
	if result then
		reply(player, { ok = true, data = result })
	else
		fail(player, err or "refused")
	end
end

function Harness.start()
	Remotes.Harness_Command.OnServerEvent:Connect(onCommand)
	Players.PlayerRemoving:Connect(function(player)
		-- one player's flag never leaks to the next session
		Gate.close()
	end)
end

return Harness
