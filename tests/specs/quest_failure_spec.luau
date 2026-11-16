--!nocheck
-- QuestService failure-path specs. A refused claim never pays, a reward is paid exactly once,
-- progress never exceeds its target, and a damaged or rolled-over save never errors.
-- Happy-path behaviour lives in quest_spec.luau.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeQuests(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(options.allow ~= false))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/World/Village", {
			getPosition = function() return env.Vector3.new(0, 0, 0) end,
			onPasar = function() end,
		})
		local EconomyService = env:require("server/Economy/EconomyService")
		EconomyService.start()
		local QuestService = env:require("server/Progression/QuestService")
		local Quests = env:require("shared/Config/Quests")
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = 0
		data.namaBaik = 50
		data.items = {}
		return {
			env = env,
			QuestService = QuestService,
			Quests = Quests,
			data = data,
			player = player,
			notify = notify,
		}
	end

	-- Ensure the save first so the day rollover does not overwrite the task we set.
	local function setTask(fx, id, progress, target, done)
		fx.QuestService.ensure(fx.data)
		fx.data.quests.tasks[id] = {
			id = id,
			target = target or 10,
			progress = progress,
			done = done or false,
		}
	end

	t:describe("QuestService failure paths", function()
		t:it("claiming a task below its target is refused and pays nothing", function()
			local fx = makeQuests()
			setTask(fx, "harvest_any", 9, 10)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(false)
			expect(fx.data.cash):toBe(0)
			expect(fx.data.namaBaik):toBe(50)
			expect(fx.data.quests.tasks.harvest_any.done):toBe(false)
		end)

		t:it("claiming a completed task twice pays the reward once", function()
			local fx = makeQuests()
			setTask(fx, "harvest_any", 10, 10)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(true)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(false)
			expect(fx.data.cash):toBe(150)
			expect(fx.data.namaBaik):toBe(52)
		end)

		t:it("a task id that is not in the pool is refused even with full progress", function()
			local fx = makeQuests()
			setTask(fx, "ghost_task", 1, 1)
			expect(fx.QuestService.claimTask(fx.player, "ghost_task")):toBe(false)
			expect(fx.data.cash):toBe(0)
			expect(fx.notify.keys(fx.player)).never:toContain("n_task_claimed")
		end)

		t:it("non-string task ids from the remote are refused without error", function()
			local fx = makeQuests()
			setTask(fx, "harvest_any", 10, 10)
			local ok1, r1 = pcall(fx.QuestService.claimTask, fx.player, nil)
			local ok2, r2 = pcall(fx.QuestService.claimTask, fx.player, 42)
			local ok3, r3 = pcall(fx.QuestService.claimTask, fx.player, {})
			local ok4, r4 = pcall(fx.QuestService.claimTask, fx.player, true)
			expect(ok1 and ok2 and ok3 and ok4):toBe(true)
			expect(r1 == false and r2 == false and r3 == false and r4 == false):toBe(true)
			expect(fx.data.cash):toBe(0)
		end)

		t:it("a rate-limited claim is refused and pays nothing", function()
			local fx = makeQuests({ allow = false })
			setTask(fx, "harvest_any", 10, 10)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(false)
			expect(fx.QuestService.claimDaily(fx.player)):toBe(false)
			expect(fx.data.cash):toBe(0)
			expect(fx.data.quests.tasks.harvest_any.done):toBe(false)
		end)

		t:it("progress is clamped to the target however large the delta", function()
			local fx = makeQuests()
			setTask(fx, "harvest_any", 0, 10)
			fx.QuestService.progress(fx.player, "harvest", 999, "padi")
			expect(fx.data.quests.tasks.harvest_any.progress):toBe(10)
		end)

		t:it("progress does not change a task that is already claimed", function()
			local fx = makeQuests()
			setTask(fx, "harvest_any", 10, 10, true)
			fx.QuestService.progress(fx.player, "harvest", 5, "padi")
			expect(fx.data.quests.tasks.harvest_any.progress):toBe(10)
			expect(fx.data.quests.tasks.harvest_any.done):toBe(true)
		end)

		t:it("a NaN progress delta is ignored and cannot complete a task", function()
			-- Known risk: math.min(target, NaN) returns target, so a NaN delta completes the task.
			local fx = makeQuests()
			setTask(fx, "harvest_any", 0, 10)
			fx.QuestService.progress(fx.player, "harvest", 0 / 0, "padi")
			expect(fx.data.quests.tasks.harvest_any.progress):toBe(0)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(false)
			expect(fx.data.cash):toBe(0)
		end)

		t:it("a missing quests table in the save is rebuilt and claims do not error", function()
			local fx = makeQuests()
			fx.data.quests = nil
			local ok, result = pcall(fx.QuestService.claimTask, fx.player, "harvest_any")
			expect(ok):toBe(true)
			expect(result):toBe(false)
			expect(type(fx.data.quests)):toBe("table")
			expect(fx.data.cash):toBe(0)
		end)

		t:it("damaged save fields are normalised to safe defaults", function()
			local fx = makeQuests()
			fx.data.quests = {
				loginStreak = "lots",
				lastLoginAt = "soon",
				loginClaimedToday = "yes",
				lastDayKey = 5,
				tasks = "broken",
			}
			local quests = fx.QuestService.ensure(fx.data)
			expect(quests.loginStreak):toBe(0)
			expect(quests.lastLoginAt):toBe(0)
			expect(quests.loginClaimedToday):toBe(false)
			expect(type(quests.lastDayKey)):toBe("string")
			expect(type(quests.tasks)):toBe("table")
		end)

		t:it("a NaN login streak is normalised to 0 instead of propagating", function()
			-- Known risk: tonumber(NaN) returns NaN, so the streak keeps NaN.
			local fx = makeQuests()
			fx.data.quests = { loginStreak = 0 / 0, lastLoginAt = 0 }
			local quests = fx.QuestService.ensure(fx.data)
			expect(quests.loginStreak == quests.loginStreak):toBe(true)
		end)

		t:it("a day rollover re-rolls tasks and a stale completed task cannot be cashed", function()
			local fx = makeQuests()
			fx.data.quests = {
				loginStreak = 3,
				lastLoginAt = 0,
				loginClaimedToday = true,
				lastDayKey = "1999-01-01",
				tasks = { harvest_any = { id = "harvest_any", target = 10, progress = 10, done = false } },
			}
			local quests = fx.QuestService.ensure(fx.data)
			expect(quests.lastDayKey):toBe(fx.Quests.dayKey())
			expect(quests.loginClaimedToday):toBe(false)
			local count = 0
			for _ in quests.tasks do
				count += 1
			end
			expect(count):toBe(3)
			expect(fx.QuestService.claimTask(fx.player, "harvest_any")):toBe(false)
			expect(fx.data.cash):toBe(0)
		end)

		t:it("a clock that moves backwards re-rolls the day without erroring", function()
			local fx = makeQuests()
			fx.QuestService.ensure(fx.data)
			fx.env.wallTime -= 2 * 86400
			local ok, quests = pcall(fx.QuestService.ensure, fx.data)
			expect(ok):toBe(true)
			expect(quests.lastDayKey):toBe(fx.Quests.dayKey(fx.env.wallTime))
		end)

		t:it("a login with a last-login time in the future does not grow the streak", function()
			local fx = makeQuests()
			local quests = fx.QuestService.ensure(fx.data)
			quests.loginStreak = 3
			quests.lastLoginAt = fx.env.wallTime + 3600
			fx.QuestService.handleLogin(fx.player)
			expect(fx.data.quests.loginStreak):toBe(3)
		end)

		t:it("the daily login reward is paid exactly once across repeated claims", function()
			local fx = makeQuests()
			fx.QuestService.handleLogin(fx.player)
			expect(fx.QuestService.claimDaily(fx.player)):toBe(true)
			expect(fx.QuestService.claimDaily(fx.player)):toBe(false)
			expect(fx.QuestService.claimDaily(fx.player)):toBe(false)
			expect(fx.data.cash):toBe(100)
			expect(fx.notify.keys(fx.player)):toContain("n_login_already_claimed")
		end)

		t:it("a seed login reward is granted once and not doubled by repeat claims", function()
			local fx = makeQuests()
			local quests = fx.QuestService.ensure(fx.data)
			quests.loginStreak = 2
			expect(fx.QuestService.claimDaily(fx.player)):toBe(true)
			expect(fx.QuestService.claimDaily(fx.player)):toBe(false)
			expect(fx.data.items.seed_padi):toBe(5)
		end)
	end)
end
