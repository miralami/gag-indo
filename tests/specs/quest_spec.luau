--!nocheck
-- QuestService unit spec (v2 PLAN §3.6).

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Quests, QuestService
	local playerData, notify, state, player, data

	t:describe("QuestService", function()
		t:beforeEach(function()
			env = Env.new()
			Quests = env:require("shared/Config/Quests")
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Net/State", {
				touch = function() end,
			})
			env:mock("server/World/Village", {
				getPosition = function()
					return Vector3.new(0, 0, 0)
				end,
				onPasar = function() end,
			})

			local EconomyService = env:require("server/Economy/EconomyService")
			EconomyService.start()
			QuestService = env:require("server/Progression/QuestService")

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			data.cash = 0
			data.namaBaik = 50
			data.items = {}
		end)

		t:it("rolls 3 daily tasks deterministically per day", function()
			local day1Tasks = Quests.rollDailyTasks(100)
			local count = 0
			for _ in day1Tasks do
				count += 1
			end
			expect(count):toBe(3)

			local day1TasksAgain = Quests.rollDailyTasks(100)
			for id in day1Tasks do
				expect(day1TasksAgain[id]):toBeTruthy()
			end
		end)

		t:it("handles login streaks and calendar reward claims", function()
			QuestService.handleLogin(player)
			expect(data.quests.loginStreak):toBe(1)
			expect(player:GetAttribute("LoginStreak")):toBe(1)

			-- Claim reward day 1 (cash = 100)
			local ok = QuestService.claimDaily(player)
			expect(ok):toBe(true)
			expect(data.cash):toBe(100)
			expect(data.quests.loginClaimedToday):toBe(true)
			expect(player:GetAttribute("LoginClaimed")):toBe(true)

			-- Second claim blocked
			expect(QuestService.claimDaily(player)):toBe(false)
		end)

		t:it("progresses matching tasks and rewards claiming", function()
			QuestService.ensure(data)
			-- Force a specific harvest task in quests
			data.quests.tasks["harvest_any"] = {
				id = "harvest_any",
				target = 10,
				progress = 0,
				done = false,
			}

			QuestService.progress(player, "harvest", 5, "padi")
			expect(data.quests.tasks["harvest_any"].progress):toBe(5)

			-- Unfinished task cannot be claimed
			expect(QuestService.claimTask(player, "harvest_any")):toBe(false)

			QuestService.progress(player, "harvest", 5, "padi")
			expect(data.quests.tasks["harvest_any"].progress):toBe(10)
			expect(notify.keys(player)):toContain("n_task_completed")

			-- Finish claim
			local ok = QuestService.claimTask(player, "harvest_any")
			expect(ok):toBe(true)
			expect(data.quests.tasks["harvest_any"].done):toBe(true)
			expect(data.cash):toBe(150) -- harvest_any rewardCash = 150
			expect(data.namaBaik):toBe(52) -- harvest_any rewardNamaBaik = 2
		end)
	end)
end
