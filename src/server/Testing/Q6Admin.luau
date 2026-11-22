-- Q6Admin: read-only Q6 capture/compare that works in a PUBLISHED place (WORK_QUEUE item 0a).
--
-- AdminService calls this through handle() for the q6Capture / q6Compare remote actions. Unlike
-- server/Testing/Persistence.luau (Studio harness only), this builds the status snapshot directly
-- from the real services and never saves or dispatches. The before snapshot lives in module memory
-- keyed by UserId, so a leave → rejoin on the same running server keeps it; a full server restart
-- loses it, in which case the designer pastes the printed Q6_BEFORE_JSON back as `value`.
--
-- The only permission check lives in Q6AdminGate (admin + rate limit). Both entry points print the
-- same Q6_BEFORE_JSON / Q6_RESULT_JSON lines as the Studio driver, for the same evidence path.

local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Crops = require(Shared.Config.Crops)
local GameConfig = require(Shared.Config.Game)
local Inventory = require(Shared.Inventory)
local Produce = require(Shared.Produce)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local PlotService = require(script.Parent.Parent.Farm.PlotService)
local StorageService = require(script.Parent.Parent.Farm.StorageService)
local ShopService = require(script.Parent.Parent.Economy.ShopService)
local OnboardingService = require(script.Parent.Parent.Progression.OnboardingService)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Admins = require(script.Parent.Parent.Live.Admins)
local PersistenceCheck = require(script.Parent.PersistenceCheck)
local Q6AdminGate = require(script.Parent.Q6AdminGate)

local Q6Admin = {}

local before: { [number]: any } = {}
Q6Admin.lastResult = nil
Q6Admin.canUse = Q6AdminGate.canUse

-- Same shape as Harness.snapshot (Harness.luau lines 51-98); read-only, no Harness.dispatch.
local function snapshot(player): any?
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

function Q6Admin.capture(player): (any?, string?)
	local state = snapshot(player)
	if not state then
		return nil, "Q6 capture could not read this player's data."
	end
	before[player.UserId] = state
	print("Q6_BEFORE_JSON=" .. HttpService:JSONEncode(state))
	return state, nil
end

function Q6Admin.compare(player, beforeOverride: string?): (any?, string?)
	local past = before[player.UserId]
	if beforeOverride ~= nil then
		if type(beforeOverride) ~= "string" then
			return nil, "Q6 compare needs the Q6_BEFORE_JSON string."
		end
		-- JSONDecode throws on a paste typo; pcall keeps one bad character from aborting the command.
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(beforeOverride)
		end)
		if not ok or type(decoded) ~= "table" then
			return nil, "Q6 compare could not decode the pasted JSON: " .. tostring(decoded)
		end
		past = decoded
	end
	if type(past) ~= "table" then
		return nil, "Q6 compare needs a capture first (or a pasted Q6_BEFORE_JSON value)."
	end
	local after = snapshot(player)
	if not after then
		return nil, "Q6 compare could not read this player's data."
	end
	local results = PersistenceCheck.compare(past, after)
	Q6Admin.lastResult = results
	for _, line in PersistenceCheck.lines(results) do
		print(line)
	end
	print("Q6_RESULT_JSON=" .. HttpService:JSONEncode(results))
	return results, nil
end

-- The single entry point AdminService calls. The gate is re-checked here, not just on the remote.
function Q6Admin.handle(player, action: string, value: any): (any?, string?)
	local allowed = Q6AdminGate.canUse({
		admin = Admins.isAdmin(player.UserId),
		rateAllowed = RateLimit.allow(player, "Q6_Command", 2),
		action = action,
	})
	if not allowed then
		return nil, "Q6 command refused: admin only, rate limited."
	end
	if action == "q6Capture" then
		return Q6Admin.capture(player)
	end
	return Q6Admin.compare(player, value)
end

return Q6Admin
