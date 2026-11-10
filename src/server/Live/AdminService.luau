-- AdminService (v2 PLAN §7.1): in-game panel backend, restricted to Live/Admins.luau.
--
-- Actions (validated by hand, no free-form strings reach gameplay):
--   inspect    { userId }                      -> summary of a player
--   setSeason  { value }                        -> override | auto
--   setAnomaly { value }                        -> none | elNino | laNina
--   setEvent   { event, mode }                  -> cabai on | off | auto
--   grantItem  { userId, itemId, amount }       -> testing only
--   getConfig  {}                               -> current LiveConfig + runtime
--   refresh    {}                               -> re-read the DataStore now
--
-- Every reply goes back on Admin_Result to the calling admin only.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Seasons = require(Shared.Config.Seasons)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Produce = require(Shared.Produce)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local LiveConfig = require(script.Parent.LiveConfig)
local Admins = require(script.Parent.Admins)

local AdminService = {}

local ACTIONS = {
	inspect = true,
	setSeason = true,
	setAnomaly = true,
	setEvent = true,
	grantItem = true,
	getConfig = true,
	refresh = true,
}

local function reply(player: Player, payload: any)
	Remotes.Admin_Result:FireClient(player, payload)
end

local function fail(player: Player, message: string)
	reply(player, { ok = false, message = message })
end

local function targetOf(userId: any): Player?
	if type(userId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function inspect(player: Player, value: any)
	local target = targetOf(value)
	local data = target and PlayerData.get(target)
	if not target or not data then
		fail(player, "Player is not online.")
		return
	end
	reply(player, {
		ok = true,
		data = {
			userId = target.UserId,
			name = target.Name,
			cash = data.cash,
			rank = data.rank,
			sus = data.sus,
			namaBaik = data.namaBaik,
			produce = Produce.count(data.produce or {}),
			items = Inventory.snapshot(data),
		},
	})
end

local function setSeason(player: Player, value: any)
	if value ~= "auto" and not Seasons.isMusim(value) then
		fail(player, "Unknown season.")
		return
	end
	LiveConfig.update({ seasonOverride = value }, player.UserId)
	reply(player, { ok = true, message = "Season: " .. tostring(value) })
end

local function setAnomaly(player: Player, value: any)
	if not Seasons.isAnomali(value) then
		fail(player, "Unknown anomaly.")
		return
	end
	LiveConfig.update({ anomaly = value }, player.UserId)
	reply(player, { ok = true, message = "Anomaly: " .. tostring(value) })
end

local function setEvent(player: Player, value: any)
	if type(value) ~= "table" or value.event ~= "cabai" then
		fail(player, "Unknown event.")
		return
	end
	local mode = value.mode
	if mode ~= "auto" and mode ~= "on" and mode ~= "off" then
		fail(player, "Mode must be auto, on or off.")
		return
	end
	LiveConfig.update({ events = { cabai = mode } }, player.UserId)
	reply(player, { ok = true, message = "Chili event: " .. mode })
end

local function grantItem(player: Player, value: any)
	if type(value) ~= "table" then
		fail(player, "Bad grant.")
		return
	end
	local target = targetOf(value.userId)
	local data = target and PlayerData.get(target)
	if not target or not data then
		fail(player, "Player is not online.")
		return
	end
	local itemId = value.itemId
	local amount = value.amount
	if type(itemId) ~= "string" or #itemId > 40 or type(amount) ~= "number" then
		fail(player, "Bad item or amount.")
		return
	end
	if amount ~= math.floor(amount) or amount < 1 or amount > 1000 then
		fail(player, "Amount must be 1..1000.")
		return
	end
	Inventory.add(data, itemId, amount)
	EconomyService.sync(target)
	State.touch(target, "items")
	reply(player, { ok = true, message = `Gave {amount}x {itemId} to {target.Name}` })
end

local function getConfig(player)
	reply(player, {
		ok = true,
		data = {
			config = LiveConfig.get(),
			runtime = LiveConfig.getRuntime(),
		},
	})
end

local function refresh(player)
	LiveConfig.refresh()
	reply(player, { ok = true, message = "Config refreshed." })
end

local handlers = {
	inspect = inspect,
	setSeason = setSeason,
	setAnomaly = setAnomaly,
	setEvent = setEvent,
	grantItem = grantItem,
	getConfig = function(player)
		getConfig(player)
	end,
	refresh = refresh,
}

local function onCommand(player: Player, payload: any)
	if not RateLimit.allow(player, "Admin_Command", 4) then
		return
	end
	if not Admins.isAdmin(player.UserId) then
		fail(player, "Access denied.")
		return
	end
	if type(payload) ~= "table" or type(payload.action) ~= "string" or not ACTIONS[payload.action] then
		fail(player, "Unknown action.")
		return
	end
	local handler = handlers[payload.action]
	if handler then
		handler(player, payload.value)
	end
end

local function markAdmin(player: Player)
	player:SetAttribute("IsAdmin", Admins.isAdmin(player.UserId))
end

function AdminService.start()
	Remotes.Admin_Command.OnServerEvent:Connect(onCommand)
	Players.PlayerAdded:Connect(markAdmin)
	Players.PlayerRemoving:Connect(function(player)
		player:SetAttribute("IsAdmin", false)
	end)
	for _, player in Players:GetPlayers() do
		markAdmin(player)
	end
end

return AdminService
