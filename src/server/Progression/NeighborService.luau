-- NeighborService: gotong royong (watering a neighbor's crops) for Nama Baik.
-- No growth effect in v1; it exists so reputation has a friendly source (GDD §7.2).

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Law = require(Shared.Config.Law)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local RankService = require(script.Parent.RankService)
local PlotService = require(script.Parent.Parent.Farm.PlotService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local QuestService = require(script.Parent.QuestService)

local NeighborService = {}

local WATER_DISTANCE = 40

local function onWater(player: Player, targetUserId: any)
	if not RateLimit.allow(player, "Water_Neighbor", 1) then
		return
	end
	if type(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player or not PlayerData.get(target) then
		return
	end
	local myPlot = PlotService.getPlotOf(player)
	local theirPlot = PlotService.getPlotOf(target)
	if not myPlot or not theirPlot or not PlotService.isNeighbor(myPlot.index, theirPlot.index) then
		Notify.send(player, "n_not_neighbor")
		return
	end
	if not EconomyService.near(player, PlotService.getPlotPosition(theirPlot), WATER_DISTANCE) then
		Notify.send(player, "n_too_far")
		return
	end

	local gained = RankService.addNamaBaik(player, Law.namaBaikWater, "water")
	if gained <= 0 then
		Notify.send(player, "n_busy")
		return
	end
	Notify.send(player, "n_water_ok", target.DisplayName, gained)
	QuestService.progress(player, "water", 1)
end

function NeighborService.start()
	Remotes.Water_Neighbor.OnServerEvent:Connect(onWater)
end

return NeighborService
