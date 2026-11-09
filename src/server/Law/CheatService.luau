-- CheatService: applies the three shortcuts (GDD §4) and logs evidence for witnesses.
-- Money/tiles are still owned elsewhere: this module only orchestrates checks + calls.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cheats = require(Shared.Config.Cheats)
local GameConfig = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local FarmService = require(script.Parent.Parent.Farm.FarmService)
local PlotService = require(script.Parent.Parent.Farm.PlotService)
local SusService = require(script.Parent.SusService)
local EvidenceService = require(script.Parent.EvidenceService)
local Analytics = require(script.Parent.Parent.Analytics.Analytics)

local CheatService = {}

local function applyOplosan(player: Player, data, tileIndex: number)
	local plot = PlotService.getPlotOf(player)
	if not plot then
		return
	end
	local tile = plot.tiles[tileIndex]
	if not tile then
		return
	end
	if not EconomyService.near(player, tile.Position, GameConfig.interactDistance) then
		Notify.send(player, "n_too_far")
		return
	end
	local entry = FarmService.getTileEntry(player, tileIndex)
	if not entry or entry.hot or os.time() >= entry.plantedAt + entry.growSeconds then
		Notify.send(player, "n_oplosan_fail")
		return
	end

	local cheat = Cheats.list.oplosan
	if not EconomyService.trySpend(player, cheat.cost) then
		return
	end
	if not FarmService.applyOplosan(player, tileIndex) then
		EconomyService.addCash(player, cheat.cost, false) -- refund: nothing was applied
		Notify.send(player, "n_oplosan_fail")
		return
	end

	SusService.add(player, cheat.sus, "oplosan")
	EvidenceService.logCheat(player, "oplosan", cheat.evidenceValue, tile.Position)
	Notify.send(player, "n_oplosan_ok")
	Analytics.log(player, "cheat_used", 1)
end

local function applyCuriAir(player: Player, data, targetUserId: number)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		return
	end
	local targetData = PlayerData.get(target)
	local myPlot = PlotService.getPlotOf(player)
	local theirPlot = PlotService.getPlotOf(target)
	if not targetData or not myPlot or not theirPlot then
		Notify.send(player, "n_steal_fail")
		return
	end
	if not PlotService.isNeighbor(myPlot.index, theirPlot.index) then
		Notify.send(player, "n_not_neighbor")
		return
	end

	local cooldownKey = "steal_" .. targetUserId
	if os.time() < (data.cooldowns[cooldownKey] or 0) then
		Notify.send(player, "n_steal_cooldown")
		return
	end

	local cheat = Cheats.list.curi_air
	local ok = FarmService.stealWater(player, target)
	if not ok then
		Notify.send(player, "n_steal_fail")
		return
	end

	data.cooldowns[cooldownKey] = os.time() + (cheat.cooldown or 300)
	SusService.add(player, cheat.sus, "curi_air")
	EvidenceService.logCheat(player, "curi_air", cheat.evidenceValue, PlotService.getPlotPosition(theirPlot), target)
	Notify.send(player, "n_steal_ok", cheat.sus)
	Analytics.log(player, "cheat_used", 2)
end

-- Registered with EconomyService: a black-market sale is a cheat event too.
function CheatService.handleSale(player: Player, cheatId: string, value: number, position: Vector3)
	if cheatId ~= "gelap" then
		return
	end
	local cheat = Cheats.list.gelap
	SusService.add(player, cheat.sus, "gelap")
	EvidenceService.logCheat(player, "gelap", value, position)
	Notify.send(player, "n_sus_up", cheat.sus)
	Analytics.log(player, "cheat_used", 3)
end

local function onApply(player: Player, cheatId: any, tile: any, targetUserId: any)
	if not RateLimit.allow(player, "Cheat_Apply", 1) then
		return
	end
	if type(cheatId) ~= "string" then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if cheatId == "oplosan" then
		if type(tile) ~= "number" or tile ~= math.floor(tile) or tile < 1 or tile > GameConfig.tilesBuilt then
			return
		end
		applyOplosan(player, data, tile)
	elseif cheatId == "curi_air" then
		if type(targetUserId) ~= "number" then
			return
		end
		applyCuriAir(player, data, targetUserId)
	end
end

function CheatService.start()
	Remotes.Cheat_Apply.OnServerEvent:Connect(onApply)
	EconomyService.onCheatSale(CheatService.handleSale)
end

return CheatService
