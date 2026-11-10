-- Items: using a purchased consumable (GDD §9.2). Buying only adds the item;
-- using it is this separate, guarded action, so a purchase is never wasted.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Law = require(Shared.Config.Law)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local SusService = require(script.Parent.Parent.Law.SusService)
local RaidService = require(script.Parent.Parent.Law.RaidService)

local Items = {}

local function useAmplopPremium(player: Player, data)
	if Inventory.get(data, "amplopPremium") < 1 then
		Notify.send(player, "n_item_none", "@item_amplopPremium")
		return
	end
	if os.time() < (data.cooldowns.amplopPremiumReadyAt or 0) then
		Notify.send(player, "n_item_cooldown", "@item_amplopPremium")
		return
	end
	if RaidService.isBusy(player) then
		Notify.send(player, "n_item_blocked", "@item_amplopPremium")
		return
	end
	Inventory.take(data, "amplopPremium", 1)
	data.cooldowns.amplopPremiumReadyAt = os.time() + Law.amplopPremiumCooldown
	SusService.add(player, Law.amplopPremiumSus, "amplopPremium")
	EconomyService.sync(player)
	State.touch(player, "items")
	Notify.send(player, "n_item_used", "@item_amplopPremium")
end

local function useJaminanKilat(player: Player, data)
	if Inventory.get(data, "jaminanKilat") < 1 then
		Notify.send(player, "n_item_none", "@item_jaminanKilat")
		return
	end
	if not RaidService.releaseFromJail(player) then
		Notify.send(player, "n_item_blocked", "@item_jaminanKilat")
		return
	end
	Inventory.take(data, "jaminanKilat", 1)
	EconomyService.sync(player)
	State.touch(player, "items")
	Notify.send(player, "n_item_used", "@item_jaminanKilat")
end

local function onUse(player: Player, item: any)
	if not RateLimit.allow(player, "Item_Use", 1) then
		return
	end
	if type(item) ~= "string" then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if item == "amplopPremium" then
		useAmplopPremium(player, data)
	elseif item == "jaminanKilat" then
		useJaminanKilat(player, data)
	end
end

function Items.start()
	Remotes.Item_Use.OnServerEvent:Connect(onUse)
end

return Items
