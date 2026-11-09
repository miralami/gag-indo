-- RankService: the ONLY owner of rank and Nama Baik (GDD §7).
-- EconomyService calls refresh() after income/tile purchases; reports and watering call
-- addNamaBaik() with a daily cap key.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Law = require(Shared.Config.Law)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Notify = require(script.Parent.Parent.Net.Notify)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local RankService = {}

local RANK_LABELS = {
	gurem = "Petani Gurem",
	petani = "Petani",
	juragan = "Juragan",
}

local function clampNamaBaik(value: number): number
	return math.clamp(math.floor(value), 0, Law.namaBaikMax)
end

function RankService.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("Rank", data.rank)
	player:SetAttribute("NamaBaik", clampNamaBaik(data.namaBaik or Law.namaBaikStart))
end

-- Promote as far as the requirements allow. Never demotes.
function RankService.refresh(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local current = GameConfig.rankIndex[data.rank] or 1
	for i = current + 1, #GameConfig.rankOrder do
		local rank = GameConfig.rankOrder[i]
		local requirement = GameConfig.rankRequirements[rank]
		if requirement
			and data.lifetimeEarned >= requirement.lifetimeEarned
			and data.tilesOwned >= requirement.tilesOwned
		then
			data.rank = rank
			Notify.send(player, "n_rank_up", "@rank_" .. rank)
			Analytics.log(player, "rank_up", GameConfig.rankIndex[rank] or 0)
		else
			break
		end
	end

	RankService.sync(player)
end

-- Points left today for a capped source (e.g. "report", "water").
local function dailyAllowance(data, capKey: string, cap: number): number
	local day = math.floor(os.time() / 86400)
	local dayKey = "nbDay_" .. capKey
	local countKey = "nbCount_" .. capKey
	if data.cooldowns[dayKey] ~= day then
		data.cooldowns[dayKey] = day
		data.cooldowns[countKey] = 0
	end
	return math.max(0, cap - (data.cooldowns[countKey] or 0))
end

-- Returns the amount actually applied.
function RankService.addNamaBaik(player: Player, amount: number, capKey: string?): number
	local data = PlayerData.get(player)
	if not data or type(amount) ~= "number" or amount == 0 then
		return 0
	end

	local applied = amount
	if amount > 0 and capKey then
		local cap = if capKey == "report" then Law.namaBaikReportDailyCap else Law.namaBaikWaterDailyCap
		local allowance = dailyAllowance(data, capKey, cap)
		applied = math.min(amount, allowance)
		if applied > 0 then
			local countKey = "nbCount_" .. capKey
			data.cooldowns[countKey] = (data.cooldowns[countKey] or 0) + applied
		end
	end

	if applied == 0 then
		return 0
	end

	data.namaBaik = clampNamaBaik((data.namaBaik or Law.namaBaikStart) + applied)
	RankService.sync(player)
	return applied
end

function RankService.getNamaBaik(player: Player): number
	local data = PlayerData.get(player)
	return if data then clampNamaBaik(data.namaBaik or Law.namaBaikStart) else Law.namaBaikStart
end

function RankService.getRankLabel(rank: string): string
	return RANK_LABELS[rank] or rank
end

function RankService.start()
	PlayerData.onLoaded(function(player)
		RankService.refresh(player)
	end)
end

return RankService
