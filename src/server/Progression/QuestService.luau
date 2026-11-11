-- QuestService: manages daily tasks and 7-day login streak calendar (v2 PLAN §3.6).
--
-- Features:
-- - 7-day login streak tracking with missed-day reset (>48h gap)
-- - Claim login reward remote
-- - Deterministic daily task pool generation based on UTC date
-- - Quest action hooks: plant, harvest, sell, water, store
-- - Claim completed task remote (cash + Nama Baik reward)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local State = require(script.Parent.Parent.Net.State)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local RankService = require(script.Parent.RankService)

local QuestService = {}

local CLAIM_RATE = 2

local function blank(): { loginStreak: number, lastLoginAt: number, loginClaimedToday: boolean, lastDayKey: string, tasks: { [string]: any } }
	return {
		loginStreak = 0,
		lastLoginAt = 0,
		loginClaimedToday = false,
		lastDayKey = "",
		tasks = {},
	}
end

function QuestService.ensure(data): any
	if not data then
		return nil
	end
	local quests = data.quests
	if type(quests) ~= "table" then
		quests = blank()
		data.quests = quests
	end
	quests.loginStreak = tonumber(quests.loginStreak) or 0
	quests.lastLoginAt = tonumber(quests.lastLoginAt) or 0
	if type(quests.loginClaimedToday) ~= "boolean" then
		quests.loginClaimedToday = false
	end
	if type(quests.lastDayKey) ~= "string" then
		quests.lastDayKey = ""
	end
	if type(quests.tasks) ~= "table" then
		quests.tasks = {}
	end

	-- Daily rollover check
	local currentDayKey = Quests.dayKey()
	if quests.lastDayKey ~= currentDayKey then
		quests.lastDayKey = currentDayKey
		quests.loginClaimedToday = false
		local dayNum = Quests.dayNumber()
		quests.tasks = Quests.rollDailyTasks(dayNum)
	end

	return quests
end

function QuestService.publish(player: Player, data)
	local quests = QuestService.ensure(data)
	player:SetAttribute("LoginStreak", quests.loginStreak)
	player:SetAttribute("LoginClaimed", quests.loginClaimedToday)
end

function QuestService.handleLogin(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local quests = QuestService.ensure(data)
	local now = os.time()

	if quests.lastLoginAt == 0 then
		-- First login ever
		quests.loginStreak = 1
	else
		local elapsed = now - quests.lastLoginAt
		if elapsed > 172800 then
			-- > 48 hours without login, streak resets
			quests.loginStreak = 1
		elseif elapsed >= 86400 then
			-- Next day consecutive login
			quests.loginStreak += 1
		end
	end
	quests.lastLoginAt = now

	QuestService.publish(player, data)
	State.touch(player, "quests")
end

function QuestService.claimDaily(player: Player): boolean
	if not RateLimit.allow(player, "Quest_ClaimDaily", CLAIM_RATE) then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local quests = QuestService.ensure(data)
	if quests.loginClaimedToday then
		Notify.send(player, "n_login_already_claimed")
		return false
	end

	quests.loginClaimedToday = true
	local dayIndex = ((quests.loginStreak - 1) % Quests.LOGIN_STREAK_DAYS) + 1
	local reward = Quests.loginRewards[dayIndex]

	if reward then
		if reward.type == "cash" then
			EconomyService.addCash(player, reward.amount, false)
			Notify.send(player, "n_login_reward_cash", reward.amount)
		elseif reward.type == "seeds" then
			data.items = data.items or {}
			local key = "seed_" .. reward.crop
			data.items[key] = (data.items[key] or 0) + reward.amount
			State.touch(player, "items")
			Notify.send(player, "n_login_reward_seeds", reward.amount, reward.crop)
		elseif reward.type == "item" then
			data.items = data.items or {}
			data.items[reward.item] = (data.items[reward.item] or 0) + reward.amount
			State.touch(player, "items")
			Notify.send(player, "n_login_reward_item", reward.amount, reward.item)
		end
	end

	QuestService.publish(player, data)
	State.touch(player, "quests")
	return true
end

function QuestService.progress(player: Player, action: string, amount: number?, crop: string?)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local quests = QuestService.ensure(data)
	local delta = amount or 1
	local changed = false

	for taskId, task in quests.tasks do
		if not task.done then
			local def = nil
			for _, p in Quests.taskPool do
				if p.id == taskId then
					def = p
					break
				end
			end
			if def and def.action == action then
				if not def.crop or def.crop == crop then
					task.progress = math.min(task.target, (task.progress or 0) + delta)
					changed = true
					if task.progress >= task.target then
						Notify.send(player, "n_task_completed", def.labelKey)
					end
				end
			end
		end
	end

	if changed then
		State.touch(player, "quests")
	end
end

function QuestService.claimTask(player: Player, taskId: any): boolean
	if not RateLimit.allow(player, "Quest_ClaimTask", CLAIM_RATE) then
		return false
	end
	if type(taskId) ~= "string" then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local quests = QuestService.ensure(data)
	local task = quests.tasks[taskId]
	if not task or task.done or (task.progress or 0) < (task.target or 1) then
		return false
	end

	local def = nil
	for _, p in Quests.taskPool do
		if p.id == taskId then
			def = p
			break
		end
	end
	if not def then
		return false
	end

	task.done = true
	if def.rewardCash and def.rewardCash > 0 then
		EconomyService.addCash(player, def.rewardCash, false)
	end
	if def.rewardNamaBaik and def.rewardNamaBaik > 0 then
		RankService.addNamaBaik(player, def.rewardNamaBaik)
	end

	Notify.send(player, "n_task_claimed", def.rewardCash or 0, def.rewardNamaBaik or 0)
	State.touch(player, "quests")
	return true
end

function QuestService.start()
	local StorageService = require(script.Parent.Parent.Farm.StorageService)

	EconomyService.onSale(function(player, count)
		QuestService.progress(player, "sell", count)
	end)

	StorageService.onDeposit(function(player, count)
		QuestService.progress(player, "store", count)
	end)

	Remotes.Quest_ClaimDaily.OnServerEvent:Connect(function(player)
		QuestService.claimDaily(player)
	end)

	Remotes.Quest_ClaimTask.OnServerEvent:Connect(function(player, taskId)
		QuestService.claimTask(player, taskId)
	end)

	PlayerData.onLoaded(function(player, _data)
		QuestService.handleLogin(player)
	end)
end

return QuestService
