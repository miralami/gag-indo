-- BribeService: Pak RT's "uang rokok" sink (GDD §5.2, TECH.md §6).
-- Price = 100 * 1.5^(bribes in the last 10 minutes); 3 minute cooldown.
-- This is the economy's main money sink, so tune Law.luau, not this file.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Law = require(Shared.Config.Law)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local SusService = require(script.Parent.SusService)
local Village = require(script.Parent.Parent.World.Village)

local BribeService = {}

-- Rolls the 10-minute window if needed and returns the current price.
local function currentPrice(data): (number, number)
	local now = os.time()
	local windowStart = data.cooldowns.bribeWindowStart or 0
	if now - windowStart > Law.bribeWindow then
		data.cooldowns.bribeWindowStart = now
		data.cooldowns.bribeCount = 0
	end
	local count = data.cooldowns.bribeCount or 0
	return math.floor(Law.bribeBasePrice * Law.bribeGrowth ^ count), count
end

function BribeService.syncPrice(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local price = currentPrice(data)
	local cooldownLeft = math.max(0, (data.cooldowns.bribeReadyAt or 0) - os.time())
	player:SetAttribute("BribePrice", price)
	player:SetAttribute("BribeCooldown", cooldownLeft)
end

local function tryBribe(player: Player)
	if not RateLimit.allow(player, "Bribe_RT", 1) then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if not EconomyService.near(player, Village.getPosition("pakrt"), GameConfig.npcDistance) then
		Notify.send(player, "n_too_far")
		return
	end
	if os.time() < (data.cooldowns.bribeReadyAt or 0) then
		Notify.send(player, "n_bribe_cooldown")
		return
	end

	local price = currentPrice(data)
	if not EconomyService.trySpend(player, price) then
		return
	end

	data.cooldowns.bribeCount = (data.cooldowns.bribeCount or 0) + 1
	data.cooldowns.bribeReadyAt = os.time() + Law.bribeCooldown
	SusService.reduce(player, Law.bribeSusReduction, "bribe")
	Notify.send(player, "n_bribe_ok", Law.bribeSusReduction, price)
	if Village.pakrt then
		Village.pakrt:say("Ya sudahlah, urusan beres.", 4)
	end
	BribeService.syncPrice(player)
end

function BribeService.start()
	Remotes.Bribe_RT.OnServerEvent:Connect(tryBribe)
	Village.onBribe(tryBribe)
	PlayerData.onLoaded(function(player)
		BribeService.syncPrice(player)
	end)

	-- Keep the displayed price honest after the 10 minute window rolls over.
	task.spawn(function()
		while true do
			task.wait(30)
			for _, player in Players:GetPlayers() do
				BribeService.syncPrice(player)
			end
		end
	end)
end

return BribeService
