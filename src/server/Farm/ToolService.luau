-- ToolService: owns `data.tools` (v2 PLAN §3.4).
--
-- Each line (cangkul, gembor, karung, traktor) holds one tier id. The effects are read here and
-- applied by the owner of the thing they change: FarmService asks for grow seconds, plant bonus
-- and sack capacity at the exact moment it needs them, so a tool purchase takes effect at once.
--
-- Start order: after EconomyService (purchases spend cash), before FarmService's first plant.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tools = require(Shared.Config.Tools)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local SeasonService = require(script.Parent.Parent.Season.SeasonService)

local ToolService = {}

local BUY_RATE = 3

-- The owned tier table for one line, or nil.
function ToolService.tier(data, lineId: string): any?
	if not data or not Tools.exists(lineId) then
		return nil
	end
	return Tools.tier(lineId, (data.tools or {})[lineId])
end

-- Growth multiplier from every owned line (1 when nothing is owned).
function ToolService.growMultiplier(data): number
	local multiplier = 1
	for _, lineId in Tools.order do
		local tier = ToolService.tier(data, lineId)
		if tier and tier.grow then
			multiplier *= tier.grow
		end
	end
	return multiplier
end

-- Planting quality bonus, added before the rarity roll.
function ToolService.plantBonus(data): number
	local bonus = 0
	for _, lineId in Tools.order do
		local tier = ToolService.tier(data, lineId)
		if tier and tier.plantBonus then
			bonus += tier.plantBonus
		end
	end
	return bonus
end

-- How many items the carried sack may hold.
function ToolService.sackCapacity(data): number
	local bonus = 0
	for _, lineId in Tools.order do
		local tier = ToolService.tier(data, lineId)
		if tier and tier.sack then
			bonus += tier.sack
		end
	end
	return GameConfig.sackBaseCapacity + bonus
end

-- Season growth, then the tool speed-up, never below 5 s.
function ToolService.growSeconds(baseSeconds: number, family: string?, data): number
	local seasonSeconds = SeasonService.growSeconds(baseSeconds, family)
	return math.max(5, math.floor(seasonSeconds / ToolService.growMultiplier(data) + 0.5))
end

-- The next tier a player can buy, or nil when the line is maxed.
function ToolService.nextTier(data, lineId: string): any?
	if not data or not Tools.exists(lineId) then
		return nil
	end
	return Tools.next(lineId, (data.tools or {})[lineId])
end

function ToolService.publish(player: Player, data)
	for _, lineId in Tools.order do
		player:SetAttribute("Tool_" .. lineId, (data.tools or {})[lineId])
	end
	player:SetAttribute("SackCapacity", ToolService.sackCapacity(data))
end

-- Buys the next tier of one line. Every refusal explains itself.
function ToolService.buy(player: Player, lineId: any): boolean
	if not RateLimit.allow(player, "Tool_Buy", BUY_RATE) then
		return false
	end
	if not Tools.exists(lineId) then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local line = Tools.list[lineId]
	if not EconomyService.hasRank(data, line.rank) then
		Notify.send(player, "n_rank_locked", "@rank_" .. line.rank)
		return false
	end

	local tier = ToolService.nextTier(data, lineId)
	if not tier then
		Notify.send(player, "n_tool_maxed", "@" .. line.label)
		return false
	end
	if not EconomyService.trySpend(player, tier.cost) then
		return false
	end

	data.tools = data.tools or {}
	data.tools[lineId] = tier.id
	ToolService.publish(player, data)
	State.touch(player, "tools")
	Notify.send(player, "n_tool_bought", "@" .. line.label, "@tool_tier_" .. tier.id)
	return true
end

function ToolService.start()
	Remotes.Tool_Buy.OnServerEvent:Connect(function(player, lineId)
		ToolService.buy(player, lineId)
	end)

	PlayerData.onLoaded(function(player, data)
		ToolService.publish(player, data)
		State.touch(player, "tools")
	end)
end

return ToolService
