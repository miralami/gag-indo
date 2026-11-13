-- LeaderboardService: local server and global OrderedDataStore leaderboards (v2 PLAN §3.6).
--
-- Three categories: richest (lifetimeEarned), sultan (Sultan-tier crops in the almanak) and
-- raids (raids survived). The server is the only writer: values come from save data, never
-- from a client. Every DataStore call is wrapped and retried a bounded number of times, and
-- writes are throttled so a busy server cannot burn the DataStore budget.
--
-- Start order: after PlayerData (it reads save data), before PlayerData.start() so the first
-- PlayerRemoving is already covered.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Strings = require(Shared.Strings)
local Leaderboard = require(Shared.Leaderboard)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)

local LeaderboardService = {}

local UPDATE_INTERVAL = 60 -- seconds between global refreshes
local WRITE_INTERVAL = 30 -- minimum seconds between two writes for one player
local MAX_ATTEMPTS = 3 -- DataStore SetAsync tries before giving up
local TOP_COUNT = Leaderboard.topCount

local boards: { [string]: { { userId: number, name: string, value: number } } } = Leaderboard.emptyBoards()
local nameCache: { [number]: string } = {}
local lastWriteAt: { [number]: number } = {}
local lastValues: { [number]: { [string]: number } } = {}

-- Tests inject a store provider; production resolves the real OrderedDataStore lazily.
local storeProvider: ((category: string) -> any?)? = nil

function LeaderboardService.bindDataStore(provider: ((category: string) -> any?)?)
	storeProvider = provider
end

local function defaultStore(category: string): any?
	if not RunService:IsServer() then
		return nil
	end
	local ok, store = pcall(function()
		local prefix = if RunService:IsStudio() then "Leaderboard_Studio_" else "Leaderboard_"
		return DataStoreService:GetOrderedDataStore(prefix .. category)
	end)
	return if ok then store else nil
end

local function getStore(category: string): any?
	if storeProvider then
		local ok, store = pcall(storeProvider, category)
		return if ok then store else nil
	end
	return defaultStore(category)
end

local function displayName(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" and name ~= "" then
		nameCache[userId] = name
		return name
	end
	return Strings.get("id", "lb_anonymous", userId)
end

-- SetAsync with a bounded retry. Returns true only when a write really succeeded.
local function writeValue(store: any, key: string, value: number): boolean
	for attempt = 1, MAX_ATTEMPTS do
		local ok = pcall(function()
			store:SetAsync(key, value)
		end)
		if ok then
			return true
		end
		if attempt < MAX_ATTEMPTS then
			task.wait(0.5 * attempt)
		end
	end
	return false
end

local function playerValues(data): { [string]: number }
	local richest = math.floor(data.lifetimeEarned or 0)
	local raids = math.floor((data.stats and (data.stats.raidsCaught or data.stats.raids)) or 0)
	local sultan = 0
	if data.almanak and data.almanak.crops then
		for _, cropRecord in data.almanak.crops do
			if cropRecord.tiers and cropRecord.tiers.sultan then
				sultan += 1
			end
		end
	end
	return { richest = richest, sultan = sultan, raids = raids }
end

-- `force` skips the throttle (used when a player leaves, so the final score is not lost).
function LeaderboardService.record(player: Player, force: boolean?)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local userId = player.UserId
	if userId <= 0 then
		return
	end

	local now = os.time()
	local previousAt = lastWriteAt[userId]
	if not force and previousAt and now - previousAt < WRITE_INTERVAL then
		return
	end
	lastWriteAt[userId] = now

	task.spawn(function()
		local values = playerValues(data)
		local cached = lastValues[userId] or {}
		for _, category in Leaderboard.categories do
			local value = Leaderboard.sanitizeValue(values[category])
			if value and cached[category] ~= value then
				local store = getStore(category)
				if store and writeValue(store, tostring(userId), value) then
					cached[category] = value
				end
			end
		end
		lastValues[userId] = cached
	end)
end

function LeaderboardService.fetchCategory(category: string): { { userId: number, name: string, value: number } }
	local store = getStore(category)
	if not store then
		return {}
	end

	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_COUNT)
	end)
	if not ok or not pages then
		return {}
	end

	local okPage, current = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not okPage or type(current) ~= "table" then
		return {}
	end

	local rows = {}
	for _, item in current do
		local userId = tonumber(item.key)
		if userId then
			table.insert(rows, {
				userId = userId,
				name = displayName(userId),
				value = item.value,
			})
		end
	end
	return Leaderboard.top(rows, TOP_COUNT)
end

function LeaderboardService.refresh()
	for _, category in Leaderboard.categories do
		boards[category] = LeaderboardService.fetchCategory(category)
	end
	pcall(function()
		Remotes.Leaderboard_Data:FireAllClients(boards)
	end)
end

function LeaderboardService.getBoards()
	return boards
end

function LeaderboardService.start()
	Players.PlayerRemoving:Connect(function(player)
		LeaderboardService.record(player, true)
	end)

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			LeaderboardService.refresh()
		end
	end)
end

return LeaderboardService
