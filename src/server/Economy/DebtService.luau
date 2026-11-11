-- DebtService: owns `data.debt` and handles Pinjol loans (v2 PLAN §3.5).
--
-- Features:
-- - Borrow cash up to rank-and-reputation-based limit
-- - Admin fee added upfront
-- - Offline and online interest accrual with 3x ceiling
-- - Repayment (partial or full)
-- - Overdue handling: harassment toasts, shaming, gudang crop seizure
-- - Award badge upon debt clearance

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Pinjol = require(Shared.Config.Pinjol)
local Remotes = require(Shared.Remotes)
local _Produce = require(Shared.Produce)
local Crops = require(Shared.Config.Crops)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local RankService = require(script.Parent.Parent.Progression.RankService)
local StorageService = require(script.Parent.Parent.Farm.StorageService)
local BadgeService = require(script.Parent.Parent.Progression.BadgeService)

local DebtService = {}

local BORROW_RATE = 2
local REPAY_RATE = 2
local TICK_INTERVAL = 30 -- check overdue & interest every 30s

local function blank(): { active: boolean, principal: number, owed: number, takenAt: number, dueAt: number, lastInterestAt: number, stage: number }
	return { active = false, principal = 0, owed = 0, takenAt = 0, dueAt = 0, lastInterestAt = 0, stage = 0 }
end

function DebtService.ensure(data): any
	if not data then
		return nil
	end
	local debt = data.debt
	if type(debt) ~= "table" then
		debt = blank()
		data.debt = debt
	end
	if type(debt.active) ~= "boolean" then
		debt.active = false
	end
	debt.principal = tonumber(debt.principal) or 0
	debt.owed = tonumber(debt.owed) or 0
	debt.takenAt = tonumber(debt.takenAt) or 0
	debt.dueAt = tonumber(debt.dueAt) or 0
	debt.lastInterestAt = tonumber(debt.lastInterestAt) or debt.takenAt or os.time()
	debt.stage = tonumber(debt.stage) or 0
	return debt
end

function DebtService.publish(player: Player, data)
	local debt = DebtService.ensure(data)
	player:SetAttribute("DebtActive", debt.active == true and debt.owed > 0)
	player:SetAttribute("DebtOwed", math.floor(debt.owed or 0))
	player:SetAttribute("DebtDueAt", debt.dueAt or 0)
end

-- Accrues interest between lastInterestAt and now
function DebtService.accrueInterest(data, now: number, isOffline: boolean?)
	local debt = DebtService.ensure(data)
	if not debt.active or debt.owed <= 0 or debt.principal <= 0 then
		return
	end
	local elapsed = math.max(0, now - debt.lastInterestAt)
	if elapsed <= 0 then
		return
	end

	local hours = elapsed / 3600
	local rate = if isOffline then Pinjol.offlineInterestRatePerHour else Pinjol.interestRatePerHour
	local interest = debt.principal * rate * hours
	local ceiling = debt.principal * Pinjol.maxDebtMultiplier

	debt.owed = math.min(ceiling, debt.owed + interest)
	debt.lastInterestAt = now
end

function DebtService.borrow(player: Player, amount: any): boolean
	if not RateLimit.allow(player, "Debt_Borrow", BORROW_RATE) then
		return false
	end
	if type(amount) ~= "number" or amount ~= math.floor(amount) or amount <= 0 then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end

	-- Cannot borrow if active loan already exists
	local debt = DebtService.ensure(data)
	if debt.active and debt.owed > 0 then
		Notify.send(player, "n_debt_already_active")
		return false
	end

	-- Check limit
	local maxLimit = Pinjol.calcLimit(data.rank or "gurem", data.namaBaik or 50)
	if amount > maxLimit then
		Notify.send(player, "n_debt_limit_exceeded", maxLimit)
		return false
	end

	local fee = math.floor(amount * Pinjol.adminFeePercent)
	local now = os.time()

	debt.active = true
	debt.principal = amount
	debt.owed = amount + fee
	debt.takenAt = now
	debt.dueAt = now + Pinjol.dueSeconds
	debt.lastInterestAt = now
	debt.stage = 0

	EconomyService.addCash(player, amount, false)
	DebtService.publish(player, data)
	State.touch(player, "debt")

	Notify.send(player, "n_debt_borrowed", amount, fee, math.floor(debt.owed))
	return true
end

function DebtService.repay(player: Player, amount: any): boolean
	if not RateLimit.allow(player, "Debt_Repay", REPAY_RATE) then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local debt = DebtService.ensure(data)
	if not debt.active or debt.owed <= 0 then
		return false
	end

	local now = os.time()
	DebtService.accrueInterest(data, now, false)

	-- Default amount to full owed if amount is nil or <= 0
	local payAmount = debt.owed
	if type(amount) == "number" and amount > 0 and amount < debt.owed then
		payAmount = math.floor(amount)
	end

	if not EconomyService.trySpend(player, payAmount) then
		return false
	end

	debt.owed -= payAmount
	if debt.owed <= 0 then
		local hadOverdue = debt.stage > 0
		debt.active = false
		debt.owed = 0
		debt.principal = 0
		debt.stage = 0
		Notify.send(player, "n_debt_cleared")
		if not hadOverdue then
			BadgeService.award(player, "debt_free")
		end
	else
		Notify.send(player, "n_debt_repaid", payAmount, math.floor(debt.owed))
	end

	DebtService.publish(player, data)
	State.touch(player, "debt")
	return true
end

-- Seize crops from gudang to repay overdue debt
local function seizeGudang(player: Player, data, debt)
	local gudang = data.gudang
	if not gudang or not gudang.stacks then
		return
	end

	local recovered = 0
	for key, stack in gudang.stacks do
		if debt.owed <= 0 then
			break
		end
		if stack and stack.count > 0 then
			local crop = Crops.list[stack.crop]
			local unitVal = (crop and crop.sellPrice or 5) * 0.5 -- forced seizure pays half base value
			local needed = math.ceil(debt.owed / unitVal)
			local take = math.min(stack.count, needed)
			stack.count -= take
			if stack.count <= 0 then
				gudang.stacks[key] = nil
			end
			local value = take * unitVal
			debt.owed = math.max(0, debt.owed - value)
			recovered += value
		end
	end

	if recovered > 0 then
		Notify.send(player, "n_debt_seized", math.floor(recovered), math.floor(debt.owed))
		StorageService.publish(player, data)
		State.touch(player, "gudang")
	end
end

function DebtService.tick(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local debt = DebtService.ensure(data)
	if not debt.active or debt.owed <= 0 then
		return
	end

	local now = os.time()
	DebtService.accrueInterest(data, now, false)

	-- Overdue escalation check
	local overdueSeconds = now - debt.dueAt
	if overdueSeconds > Pinjol.OVERDUE_STAGE_NOTIFY and debt.stage == 0 then
		debt.stage = 1
		Notify.send(player, "n_debt_overdue_warning")
	elseif overdueSeconds > Pinjol.OVERDUE_STAGE_SHAME and debt.stage == 1 then
		debt.stage = 2
		-- Hit Nama Baik
		RankService.addNamaBaik(player, -Pinjol.shameNamaBaikPenalty)
		Notify.send(player, "n_debt_shamed", Pinjol.shameNamaBaikPenalty)
	elseif overdueSeconds > Pinjol.OVERDUE_STAGE_SEIZE and debt.stage == 2 then
		debt.stage = 3
		seizeGudang(player, data, debt)
	end

	DebtService.publish(player, data)
end

function DebtService.start()
	Remotes.Debt_Borrow.OnServerEvent:Connect(function(player, amount)
		DebtService.borrow(player, amount)
	end)

	Remotes.Debt_Repay.OnServerEvent:Connect(function(player, amount)
		DebtService.repay(player, amount)
	end)

	PlayerData.onLoaded(function(player, data)
		-- Accrue offline interest
		local debt = DebtService.ensure(data)
		if debt.active and debt.owed > 0 then
			DebtService.accrueInterest(data, os.time(), true)
		end
		DebtService.publish(player, data)
		State.touch(player, "debt")
	end)

	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			for _, player in Players:GetPlayers() do
				DebtService.tick(player)
			end
		end
	end)
end

return DebtService
