-- PlayerData: the ONLY owner of player profiles (TECH.md §4).
-- Other services read/write `PlayerData.get(player)` but never load or release profiles.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Law = require(Shared.Config.Law)

local CURRENT_VERSION = 2
local LOAD_TIMEOUT = 30 -- seconds; we supply Cancel, which disables ProfileStore's own timeout

-- Studio writes go to a separate store so tests never touch live data.
-- (If Studio API access is off, ProfileStore falls back to a mock store and prints a notice.)
local STORE_NAME = if RunService:IsStudio() then "PlayerData_v1_Studio" else "PlayerData_v1"

local TEMPLATE = {
	version = CURRENT_VERSION,
	cash = GameConfig.startCash,
	lifetimeEarned = 0,
	tilesOwned = GameConfig.startTiles,
	-- STRING keys only: ["t1"] = { crop, plantedAt, growSeconds, quality, hot }. Empty tile = key absent.
	tiles = {},
	seeds = table.clone(GameConfig.startSeeds),
	-- [cropId] = { count, qualitySum, hotCount, hotQualitySum }
	harvest = {},
	sus = 0,
	namaBaik = Law.namaBaikStart,
	rank = "gurem",
	timesElected = 0,
	inventory = { amplopPremium = 0, jaminanKilat = 0 },
	cooldowns = {},
	cosmetics = {},
	equipped = {},
	stats = { raids = 0, reportsMade = 0, timesReported = 0, cheats = 0 },
	receipts = {},
}

local store = ProfileStore.New(STORE_NAME, TEMPLATE)

local PlayerData = {}

local profiles: { [Player]: any } = {}
local loadedCallbacks: { (Player, any) -> () } = {}
local beforeReleaseCallbacks: { (Player, any) -> () } = {}

-- Schema migrations. Add a branch each time CURRENT_VERSION goes up.
local function migrate(data)
	if type(data.version) ~= "number" then
		data.version = 1
	end
	if data.version < 2 then
		-- v2 split the sack into normal and "hot" (oplosan) produce so the market can
		-- refuse the hot stuff while the black market buys it.
		for _, sack in data.harvest do
			if type(sack) == "table" then
				local hot = sack.hotCount or 0
				if sack.hotQualitySum == nil then
					sack.hotQualitySum = 0
				end
				-- Older saves folded hot quality into qualitySum; move the average over.
				if hot > 0 and sack.hotQualitySum == 0 and sack.count > 0 then
					local avg = sack.qualitySum / sack.count
					sack.hotQualitySum = avg * hot
					sack.qualitySum -= sack.hotQualitySum
				end
			end
		end
		data.version = 2
	end
end

-- Called after a profile is loaded and ready. Must not yield for long.
function PlayerData.onLoaded(callback: (Player, any) -> ())
	table.insert(loadedCallbacks, callback)
end

-- Called right before a profile is released on leave (e.g. RaidService fines a player who
-- leaves mid-raid). Callbacks run in order and MUST NOT yield.
function PlayerData.onBeforeRelease(callback: (Player, any) -> ())
	table.insert(beforeReleaseCallbacks, callback)
end

function PlayerData.get(player: Player): any?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

function PlayerData.getProfile(player: Player): any?
	return profiles[player]
end

-- Save now and wait (bounded) until a save containing `purchaseId` is confirmed.
-- Used by Receipts.luau: never acknowledge a Robux purchase before this returns true.
function PlayerData.saveAndConfirm(profile, purchaseId: string, timeoutSeconds: number): boolean
	if not profile:IsActive() then
		return false
	end
	local confirmed = false
	local connection = profile.OnAfterSave:Connect(function(lastSavedData)
		if confirmed or not profile:IsActive() then
			return
		end
		local receipts = if type(lastSavedData) == "table" then lastSavedData.receipts else nil
		if type(receipts) == "table" and table.find(receipts, purchaseId) then
			confirmed = true
		end
	end)

	local ok = pcall(function()
		profile:Save()
	end)
	if not ok then
		connection:Disconnect()
		return false
	end

	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline and not confirmed and profile:IsActive() do
		task.wait(0.1)
	end
	connection:Disconnect()
	return confirmed and profile:IsActive()
end

local function load(player: Player)
	local startedAt = os.clock()
	local profile = store:StartSessionAsync("player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players or os.clock() - startedAt > LOAD_TIMEOUT
		end,
	})

	if profile == nil then
		if player.Parent == Players then
			player:Kick("Gagal memuat data. Coba masuk lagi. / Couldn't load your data, please rejoin.")
		end
		return
	end

	profile:AddUserId(player.UserId) -- lets Roblox data-deletion requests find this profile
	profile:Reconcile() -- fills fields added to TEMPLATE after this profile was first saved
	migrate(profile.Data)

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Sesi data berakhir. Coba masuk lagi. / Data session ended, please rejoin.")
		end
	end)

	if player.Parent ~= Players then
		-- Player left while we were loading.
		profile:EndSession()
		return
	end

	profiles[player] = profile
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, profile.Data)
	end
end

local function release(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	for _, callback in beforeReleaseCallbacks do
		local ok, err = pcall(callback, player, profile.Data)
		if not ok then
			warn("[PlayerData] beforeRelease callback failed:", err)
		end
	end
	profile:EndSession() -- ProfileStore saves and releases the session lock
end

function PlayerData.start()
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	-- ProfileStore registers its own BindToClose and saves active profiles on shutdown.
end

return PlayerData
