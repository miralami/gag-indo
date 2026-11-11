-- PlayerData: the ONLY owner of player profiles (TECH.md §4).
-- Other services read/write `PlayerData.get(player)` but never load or release profiles.
--
-- Schema history:
--   v1  one harvest sack per crop (clean + hot quality folded together)
--   v2  clean and hot (oplosan) quality split apart
--   v3  v2 PLAN §7.1 foundation: produce as stacks keyed by crop + tier + trait,
--       generic items[itemId] = count, plus tools/gudang/debt/quests/almanak/story and
--       reserved housing/prestige fields so v2.1-v2.3 need no migration.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Law = require(Shared.Config.Law)
local Produce = require(Shared.Produce)

local CURRENT_VERSION = 3
local LOAD_TIMEOUT = 30 -- seconds; we supply Cancel, which disables ProfileStore's own timeout

-- Studio writes go to a separate store so tests never touch live data.
-- (If Studio API access is off, ProfileStore falls back to a mock store and prints a notice.)
-- The name deliberately stays PlayerData_v1: saves are migrated in place, never dropped.
local STORE_NAME = if RunService:IsStudio() then "PlayerData_v1_Studio" else "PlayerData_v1"

local function startingItems(): { [string]: number }
	local items = { amplopPremium = 0, jaminanKilat = 0 }
	for cropId, count in GameConfig.startSeeds do
		items["seed_" .. cropId] = count
	end
	return items
end

local TEMPLATE = {
	version = CURRENT_VERSION,
	cash = GameConfig.startCash,
	lifetimeEarned = 0,
	tilesOwned = GameConfig.startTiles,
	-- STRING keys only: ["t1"] = { crop, plantedAt, growSeconds, quality, hot }. Empty tile = key absent.
	tiles = {},
	-- Produce stacks, see shared/Produce.luau: ["padi|biasa|"] = { crop, tier, traits, count, qualitySum }
	produce = {},
	-- Generic bag: consumables (amplopPremium) and seeds (seed_padi).
	items = startingItems(),
	-- Permanent tools bought with cash.
	tools = {},
	-- Toko Bibit shelves (v2 PLAN §3.4): deterministic per restock cycle, per player.
	shop = { cycle = 0, restockAt = 0, musim = "", stock = {} },
	-- Hired buruh tani (v2 PLAN §3.4): unix time the shift ends.
	worker = { hiredUntil = 0 },
	gudang = { capacity = GameConfig.gudangBaseCapacity, stacks = {} },
	debt = { active = false, principal = 0, owed = 0, takenAt = 0, dueAt = 0 },
	quests = { daily = {}, loginStreak = 0, lastLoginDay = 0 },
	almanak = {},
	story = { chapter = 0, flags = {} },
	-- Guided first session (v2 PLAN §3.1): next step index and the steps already done.
	tutorial = { step = 1, done = {} },
	-- Reserved for later releases (v2.2 housing, v3 prestige): never migrate for these.
	housing = {},
	prestige = { level = 0 },
	sus = 0,
	namaBaik = Law.namaBaikStart,
	rank = "gurem",
	timesElected = 0,
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

local function count(value: any): number
	local n = tonumber(value) or 0
	if n ~= n or n < 0 then
		return 0
	end
	return math.floor(n)
end

-- v1/v2 harvest sack -> v3 produce stacks.
-- v2 keeps clean and hot quality apart; v1 folded them together, so run the v2 split first.
local function migrateProduce(data): { [string]: any }
	local produce = {}
	local old = if type(data.harvest) == "table" then data.harvest else {}
	for cropId, sack in old do
		if type(cropId) == "string" and type(sack) == "table" then
			local totalCount = count(sack.count)
			local hotCount = math.min(count(sack.hotCount), totalCount)
			local cleanCount = totalCount - hotCount
			local cleanQuality = tonumber(sack.qualitySum) or 0
			local hotQuality = tonumber(sack.hotQualitySum) or 0

			if cleanCount > 0 then
				produce[Produce.key(cropId, "biasa", {})] = {
					crop = cropId,
					tier = "biasa",
					traits = {},
					count = cleanCount,
					qualitySum = cleanQuality,
				}
			end
			if hotCount > 0 then
				produce[Produce.key(cropId, "biasa", { "oplosan" })] = {
					crop = cropId,
					tier = "biasa",
					traits = { "oplosan" },
					count = hotCount,
					qualitySum = hotQuality,
				}
			end
		end
	end
	return produce
end

-- v2 `inventory` + `seeds` -> v3 generic `items`.
-- ProfileStore:Reconcile() adds the v3 TEMPLATE defaults (including `items`) to an old
-- profile before this runs, so the old counts are the only truth here: build the bag from
-- `inventory` + `seeds` and ignore the reconciled defaults, or every veteran would get a
-- free stack of starting seeds.
local function migrateItems(data): { [string]: number }
	local items = { amplopPremium = 0, jaminanKilat = 0 }
	for itemId, amount in (if type(data.inventory) == "table" then data.inventory else {}) do
		if type(itemId) == "string" then
			items[itemId] = (tonumber(items[itemId]) or 0) + count(amount)
		end
	end
	for cropId, amount in (if type(data.seeds) == "table" then data.seeds else {}) do
		if type(cropId) == "string" then
			local itemId = "seed_" .. cropId
			items[itemId] = (tonumber(items[itemId]) or 0) + count(amount)
		end
	end
	return items
end

-- Schema migrations. Add a branch each time CURRENT_VERSION goes up.
local function migrate(data)
	if type(data.version) ~= "number" then
		data.version = 1
	end
	if data.version < 2 then
		-- v2 split the sack into normal and "hot" (oplosan) produce so the market can
		-- refuse the hot stuff while the black market buys it.
		for _, sack in data.harvest or {} do
			if type(sack) == "table" then
				local hot = sack.hotCount or 0
				if sack.hotQualitySum == nil then
					sack.hotQualitySum = 0
				end
				-- Older saves folded hot quality into qualitySum; move the average over.
				if hot > 0 and sack.hotQualitySum == 0 and (sack.count or 0) > 0 then
					local avg = sack.qualitySum / sack.count
					sack.hotQualitySum = avg * hot
					sack.qualitySum -= sack.hotQualitySum
				end
			end
		end
		data.version = 2
	end
	if data.version < 3 then
		-- v3 foundation (v2 PLAN §7.1).
		data.produce = migrateProduce(data)
		data.harvest = nil
		data.items = migrateItems(data)
		data.inventory = nil
		data.seeds = nil

		if type(data.tools) ~= "table" then
			data.tools = {}
		end
		if type(data.shop) ~= "table" then
			data.shop = { cycle = 0, restockAt = 0, musim = "", stock = {} }
		end
		if type(data.worker) ~= "table" then
			data.worker = { hiredUntil = 0 }
		end
		if type(data.gudang) ~= "table" then
			data.gudang = { capacity = GameConfig.gudangBaseCapacity, stacks = {} }
		end
		data.gudang.capacity = tonumber(data.gudang.capacity) or GameConfig.gudangBaseCapacity
		if type(data.gudang.stacks) ~= "table" then
			data.gudang.stacks = {}
		end
		if type(data.debt) ~= "table" then
			data.debt = { active = false, principal = 0, owed = 0, takenAt = 0, dueAt = 0 }
		end
		if type(data.quests) ~= "table" then
			data.quests = { daily = {}, loginStreak = 0, lastLoginDay = 0 }
		end
		if type(data.almanak) ~= "table" then
			data.almanak = {}
		end
		if type(data.story) ~= "table" then
			data.story = { chapter = 0, flags = {} }
		end
		if type(data.tutorial) ~= "table" then
			data.tutorial = { step = 1, done = {} }
		end
		if type(data.tutorial.done) ~= "table" then
			data.tutorial.done = {}
		end
		if type(data.housing) ~= "table" then
			data.housing = {}
		end
		if type(data.prestige) ~= "table" then
			data.prestige = { level = 0 }
		end

		data.version = 3
	end
end

-- Exposed so tests/specs/playerdata_spec.luau can check old saves upgrade correctly.
PlayerData.migrate = migrate
PlayerData.CURRENT_VERSION = CURRENT_VERSION

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
