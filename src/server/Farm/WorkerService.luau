-- WorkerService: the hired buruh tani (v2 PLAN §3.4).
--
-- Owns `data.worker.hiredUntil` and the wage. On every pass he asks FarmService for ready
-- tiles and harvests up to a few of them straight into the gudang, charging per item. He stops
-- when the shift ends, the gudang is full, or the cash runs out.
--
-- Start order: after FarmService (tile data) and StorageService (gudang capacity).

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Worker = require(Shared.Config.Worker)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local FarmService = require(script.Parent.FarmService)
local StorageService = require(script.Parent.StorageService)

local WorkerService = {}

local HIRE_RATE = 2

function WorkerService.endsAt(data): number
	return tonumber((data.worker or {}).hiredUntil) or 0
end

function WorkerService.active(data, now: number?): boolean
	return WorkerService.endsAt(data) > (now or os.time())
end

function WorkerService.publish(player: Player, data)
	player:SetAttribute("WorkerUntil", WorkerService.endsAt(data))
	player:SetAttribute("WorkerActive", WorkerService.active(data))
end

function WorkerService.hire(player: Player): boolean
	if not RateLimit.allow(player, "Worker_Hire", HIRE_RATE) then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if WorkerService.active(data) then
		Notify.send(player, "n_worker_busy")
		return false
	end
	if not EconomyService.trySpend(player, Worker.hireCost) then
		return false
	end
	data.worker = data.worker or { hiredUntil = 0 }
	data.worker.hiredUntil = os.time() + Worker.hireSeconds
	WorkerService.publish(player, data)
	Notify.send(player, "n_worker_hired", math.floor(Worker.hireSeconds / 60), Worker.hireCost, Worker.wagePerItem)
	return true
end

-- One pass for one player. Returns how many items the buruh harvested.
function WorkerService.tick(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local now = os.time()
	if not WorkerService.active(data, now) then
		if player:GetAttribute("WorkerActive") then
			WorkerService.publish(player, data)
		end
		return 0
	end

	local wage = Worker.wagePerItem
	local affordable = math.min(Worker.maxItemsPerPass, math.floor(data.cash / wage))
	if affordable <= 0 then
		-- No cash for the wage: the buruh goes home.
		data.worker.hiredUntil = 0
		Notify.send(player, "n_worker_unpaid")
		WorkerService.publish(player, data)
		return 0
	end

	local harvested = 0
	for _, index in FarmService.readyTiles(player) do
		if harvested >= affordable then
			break
		end
		if StorageService.used(data) >= StorageService.capacity(player, data) then
			Notify.send(player, "n_gudang_full")
			break
		end
		if FarmService.harvestToStorage(player, index) then
			harvested += 1
		end
	end

	if harvested > 0 then
		EconomyService.trySpend(player, harvested * Worker.wagePerItem)
		Notify.send(player, "n_worker_harvested", harvested, Worker.wagePerItem * harvested)
	end
	WorkerService.publish(player, data)
	return harvested
end

function WorkerService.start()
	Remotes.Worker_Hire.OnServerEvent:Connect(function(player)
		WorkerService.hire(player)
	end)

	PlayerData.onLoaded(function(player, data)
		WorkerService.publish(player, data)
	end)

	task.spawn(function()
		while true do
			task.wait(Worker.intervalSeconds)
			for _, player in Players:GetPlayers() do
				WorkerService.tick(player)
			end
		end
	end)
end

return WorkerService
