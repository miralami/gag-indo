-- Daily tasks and 7-day login streak calendar (v2 PLAN §3.6).
--
-- Tasks are rolled deterministically per UTC day from the pool.
-- Login streak resets if the gap between logins exceeds 48 hours (allows 1 missed day).

local Quests = {}

Quests.DAILY_TASK_COUNT = 3
Quests.LOGIN_STREAK_DAYS = 7

-- 7-day reward track (index 1..7). Repeats after day 7.
Quests.loginRewards = {
	{ type = "cash", amount = 100 },
	{ type = "seeds", crop = "padi", amount = 5 },
	{ type = "cash", amount = 250 },
	{ type = "item", item = "amplopPremium", amount = 1 },
	{ type = "seeds", crop = "cabai", amount = 4 },
	{ type = "cash", amount = 600 },
	{ type = "item", item = "jaminanKilat", amount = 1 },
}

-- Task pool: id, target, rewardCash, rewardNamaBaik
Quests.taskPool = {
	{ id = "harvest_any", action = "harvest", target = 10, rewardCash = 150, rewardNamaBaik = 2, labelKey = "task_harvest_any" },
	{ id = "plant_padi", action = "plant", crop = "padi", target = 5, rewardCash = 100, rewardNamaBaik = 1, labelKey = "task_plant_padi" },
	{ id = "sell_pasar", action = "sell", target = 8, rewardCash = 120, rewardNamaBaik = 2, labelKey = "task_sell_pasar" },
	{ id = "water_crops", action = "water", target = 3, rewardCash = 150, rewardNamaBaik = 3, labelKey = "task_water_crops" },
	{ id = "store_gudang", action = "store", target = 5, rewardCash = 80, rewardNamaBaik = 1, labelKey = "task_store_gudang" },
}

function Quests.dayKey(timestamp: number?): string
	local t = timestamp or os.time()
	return os.date("!%Y-%m-%d", t)
end

function Quests.dayNumber(timestamp: number?): number
	local t = timestamp or os.time()
	return math.floor(t / 86400)
end

-- Deterministic daily selection of 3 tasks from pool using dayNumber as seed.
function Quests.rollDailyTasks(dayNum: number): { [string]: { id: string, target: number, progress: number, done: boolean } }
	local tasks = {}
	local count = #Quests.taskPool
	local picked = {}
	local state = (dayNum * 1664525 + 1013904223) % 4294967296

	for _ = 1, Quests.DAILY_TASK_COUNT do
		state = (state * 1664525 + 1013904223) % 4294967296
		local idx = (state % count) + 1
		local attempts = 0
		while picked[idx] and attempts < count do
			idx = (idx % count) + 1
			attempts += 1
		end
		picked[idx] = true
		local def = Quests.taskPool[idx]
		tasks[def.id] = {
			id = def.id,
			target = def.target,
			progress = 0,
			done = false,
		}
	end

	return tasks
end

return Quests
