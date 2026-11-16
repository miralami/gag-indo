--!nocheck
-- SusService and AlmanakService failure-path specs. Bad arguments change nothing, damaged or
-- missing save tables never error where the service can recover, Sus stays a finite number in
-- [0, Law.susMax], a departed player is ignored, and a discovery reward is granted exactly once.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects (line
-- numbers are in each comment). Do not edit SusService or AlmanakService to make them pass here.
-- Neither service exposes a remote, so the "rate-limited remote" case does not apply to them.

return function(t, Env, Fakes)
	local expect = t.expect

	local STOP = {}

	-- SusService.start() runs `while true do task.wait(...) end` inside task.spawn. Under the fake
	-- Env that would never return, so this builder swaps task.spawn/task.wait for a version that
	-- runs the loop body exactly `maxTicks` times and then stops it with STOP.
	local function buildSus(maxTicks)
		local env = Env.new()
		local ticks = 0
		local fx = { env = env, tickError = nil, beforeTick = nil, roll = 1 }
		if maxTicks then
			-- Lune's math table is read-only, so the service gets its own math with random pinned to
			-- fx.roll (1 never hits, 0 always hits). Only modules loaded after this line see it.
			env.globals.math = setmetatable({
				random = function()
					return fx.roll
				end,
			}, { __index = math })
			local realTask = env.globals.task
			env.globals.task = {
				spawn = function(fn)
					local ok, err = pcall(fn)
					if not ok and err ~= STOP then
						fx.tickError = err
					end
				end,
				defer = realTask.defer,
				delay = realTask.delay,
				wait = function(seconds)
					ticks += 1
					if ticks > maxTicks then
						error(STOP)
					end
					if fx.beforeTick then
						fx.beforeTick(ticks, env)
					end
					env:advance(seconds or 0)
					return seconds or 0
				end,
			}
		end

		local playerData = Fakes.playerData()
		fx.notify = Fakes.notify()
		fx.raid = { started = {} }
		function fx.raid.start(who, respectCooldown)
			table.insert(fx.raid.started, { player = who, respectCooldown = respectCooldown })
		end
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", fx.notify)
		env:mock("server/Law/RaidService", fx.raid)

		fx.Law = env:require("shared/Config/Law")
		fx.SusService = env:require("server/Law/SusService")
		fx.playerData = playerData
		fx.player = Fakes.player(env)
		fx.data = playerData.set(fx.player, Fakes.newData(env))
		fx.data.story.flags["sus_explained"] = true
		fx.data.sus = 40
		return fx
	end

	-- Starts the loop with every random roll succeeding (roll 0 is below every chance).
	local function startWithRollsAlwaysHitting(fx)
		fx.roll = 0
		fx.SusService.start()
	end

	local function buildAlmanak()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local fx = { env = env, touched = {}, grants = {} }
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/State", {
			touch = function(_, section)
				table.insert(fx.touched, section)
			end,
		})
		env:mock("server/Monetization/Cosmetics", {
			grant = function(_, itemId)
				fx.grants[itemId] = (fx.grants[itemId] or 0) + 1
				return true
			end,
		})
		fx.AlmanakService = env:require("server/Progression/AlmanakService")
		fx.Crops = env:require("shared/Config/Crops")
		fx.AlmanakConfig = env:require("shared/Config/Almanak")
		fx.playerData = playerData
		fx.player = Fakes.player(env)
		fx.data = playerData.set(fx.player, Fakes.newData(env))
		return fx
	end

	t:describe("SusService failure paths", function()
		t:it("non-number, NaN, nil and string amounts change nothing", function()
			local fx = buildSus()
			local player, data = fx.player, fx.data
			for _, bad in { 0 / 0, "20", nil, {}, true } do
				expect(fx.SusService.add(player, bad)):toBe(0)
			end
			for _, bad in { "5", nil, -5, 0 } do
				fx.SusService.reduce(player, bad)
			end
			expect(data.sus):toBe(40)
			expect(fx.SusService.get(player)):toBe(40)
			expect(#fx.notify.sent):toBe(0)
			expect(#fx.raid.started):toBe(0)
		end)

		t:it("infinite amounts clamp to the 0 and susMax bounds", function()
			local fx = buildSus()
			local player = fx.player
			expect(fx.SusService.add(player, math.huge)):toBe(fx.Law.susMax)
			expect(fx.SusService.add(player, -math.huge)):toBe(0)
			expect(fx.SusService.add(player, 1e300)):toBe(fx.Law.susMax)
			expect(fx.SusService.reduce(player, math.huge)):toBe(0)
			expect(fx.SusService.get(player)):toBe(0)
		end)

		t:it("reduce with NaN returns the current Sus, not 0", function()
			-- SusService.luau:40 returns 0 for any NaN passed to add, and reduce (line 61) forwards
			-- the NaN through add, so the return value is 0 while the real Sus stays 40.
			local fx = buildSus()
			expect(fx.SusService.reduce(fx.player, 0 / 0)):toBe(40)
			expect(fx.data.sus):toBe(40)
		end)

		t:it("get on a save with NaN sus never returns NaN", function()
			-- SusService.luau:21: math.clamp(NaN, 0, max) returns NaN because every comparison with
			-- NaN is false, so the HUD attribute and any caller receive NaN.
			local fx = buildSus()
			fx.data.sus = 0 / 0
			local value = fx.SusService.get(fx.player)
			expect(value == value):toBe(true)
			expect(value >= 0 and value <= fx.Law.susMax):toBe(true)
		end)

		t:it("add onto a save with NaN sus keeps Sus finite", function()
			-- SusService.luau:44 computes previous + amount from the NaN save and clamps it to NaN,
			-- which is then written back to data.sus (line 45) and the Sus attribute.
			local fx = buildSus()
			fx.data.sus = 0 / 0
			local value = fx.SusService.add(fx.player, 10)
			expect(value == value):toBe(true)
			expect(fx.data.sus == fx.data.sus):toBe(true)
		end)

		t:it("setSus repairs a NaN save, and a save with no sus field reads as zero", function()
			local fx = buildSus()
			fx.data.sus = 0 / 0
			fx.SusService.setSus(fx.player, 20)
			expect(fx.SusService.get(fx.player)):toBe(20)

			fx.data.sus = nil
			expect(fx.SusService.get(fx.player)):toBe(0)
			expect(fx.SusService.add(fx.player, 5)):toBe(5)
		end)

		t:it("a departed player is ignored by add, reduce, setSus and get without error", function()
			local fx = buildSus()
			local players = fx.env.services.Players._players
			table.remove(players, table.find(players, fx.player))
			fx.playerData.set(fx.player, nil)

			expect(fx.SusService.add(fx.player, 20)):toBe(0)
			expect(fx.SusService.reduce(fx.player, 5)):toBe(0)
			fx.SusService.setSus(fx.player, 90)
			expect(fx.SusService.get(fx.player)):toBe(0)
			expect(fx.data.sus):toBe(40)
			expect(#fx.notify.sent):toBe(0)
			expect(#fx.raid.started):toBe(0)
		end)

		t:it("decay tick lowers Sus by one per tick and stops at zero, even across a clock rewind and a huge gap", function()
			-- Tick decay is wait-driven, so one tick is one step regardless of the clock. The hook
			-- rewinds wallTime on tick 2 and jumps it by 1e9 seconds on tick 3; both must still cost
			-- exactly one step each.
			local fx = buildSus(4)
			fx.data.sus = 10
			fx.beforeTick = function(tick, env)
				if tick == 2 then
					env.wallTime = 0
				elseif tick == 3 then
					env.wallTime += 1e9
					env.now += 1e9
				end
			end
			fx.SusService.start()
			expect(fx.tickError):toBeNil()
			expect(fx.data.sus):toBe(6)
			expect(fx.SusService.get(fx.player)):toBe(6)

			local drain = buildSus(20)
			drain.data.sus = 2
			drain.SusService.start()
			expect(drain.tickError):toBeNil()
			expect(drain.data.sus):toBe(0)
			expect(drain.SusService.get(drain.player)):toBe(0)
		end)

		t:it("tick skips a player who left mid-session and starts no raid or gossip for them", function()
			local fx = buildSus(3)
			fx.data.sus = 85
			fx.beforeTick = function(tick)
				if tick == 1 then
					local players = fx.env.services.Players._players
					table.remove(players, table.find(players, fx.player))
					fx.playerData.set(fx.player, nil)
				end
			end
			fx.SusService.start()
			expect(fx.tickError):toBeNil()
			expect(#fx.raid.started):toBe(0)
			expect(#fx.notify.sent):toBe(0)
		end)

		t:it("80+ tick roll starts one raid without cooldown; Sus under 80 rolls no raid", function()
			local hot = buildSus(1)
			hot.data.sus = 85
			startWithRollsAlwaysHitting(hot)
			expect(hot.tickError):toBeNil()
			expect(#hot.raid.started):toBe(1)
			expect(hot.raid.started[1].player):toBe(hot.player)
			expect(hot.raid.started[1].respectCooldown):toBe(false)

			local cool = buildSus(1)
			cool.data.sus = 79
			startWithRollsAlwaysHitting(cool)
			expect(cool.tickError):toBeNil()
			expect(#cool.raid.started):toBe(0)
		end)
	end)

	t:describe("AlmanakService failure paths", function()
		t:it("bad crop ids return nil and create no almanak section", function()
			local fx = buildAlmanak()
			for _, bad in { nil, 42, 0 / 0, "", "NANGKA", {}, true } do
				expect(fx.AlmanakService.record(fx.player, bad, "biasa", { "basah" })):toBeNil()
			end
			-- Fakes.newData starts with an empty almanak section; a bad crop must not add to it.
			expect(next(fx.data.almanak)):toBeNil()
			expect(#fx.touched):toBe(0)
			expect(next(fx.grants)):toBeNil()
		end)

		t:it("bad tiers and bad traits are ignored, but the harvest still counts", function()
			local fx = buildAlmanak()
			for _, badTier in { 42, 0 / 0, "", "Biasa", {}, true } do
				local discovery = fx.AlmanakService.record(fx.player, "padi", badTier, {})
				expect(discovery.newTier):toBe(false)
			end
			expect(next(fx.data.almanak.crops.padi.tiers)):toBeNil()
			expect(fx.data.almanak.crops.padi.count):toBe(6)

			local discovery = fx.AlmanakService.record(fx.player, "padi", "biasa", { 42, true, 0 / 0, "", "BASAH", {} })
			expect(discovery.newTraits):toEqual({})
			expect(fx.data.almanak.crops.padi.tiers.biasa):toBe(true)
			expect(next(fx.data.almanak.crops.padi.traits)):toBeNil()
			expect(fx.data.almanak.crops.padi.count):toBe(7)
		end)

		t:it("a trait list that is a string does not throw", function()
			-- AlmanakService.luau:87 runs `for _, traitId in traitList`, which errors on a string
			-- instead of ignoring it. The harvest then fails after the crop entry is half-written.
			local fx = buildAlmanak()
			local ok = pcall(fx.AlmanakService.record, fx.player, "padi", "biasa", "basah")
			expect(ok):toBe(true)
		end)

		t:it("a damaged crop entry that is a string does not throw", function()
			-- AlmanakService.luau:73 assigns entry.tiers on a string entry, which raises instead of
			-- rebuilding the entry. The whole harvest is lost for that crop.
			local fx = buildAlmanak()
			fx.data.almanak = { crops = { padi = "oops" }, pages = {} }
			local ok = pcall(fx.AlmanakService.record, fx.player, "padi", "biasa", {})
			expect(ok):toBe(true)
		end)

		t:it("missing almanak, crops, pages or per-crop fields are rebuilt and the harvest counts", function()
			local fx = buildAlmanak()
			fx.data.almanak = nil
			expect(fx.AlmanakService.record(fx.player, "padi", "biasa", {}).first):toBe(true)

			fx.data.almanak = {}
			expect(fx.AlmanakService.record(fx.player, "padi", "biasa", {}).first):toBe(true)
			expect(fx.data.almanak.crops.padi.count):toBe(1)

			local kebunCrop = fx.Crops.families.kebun[1]
			fx.data.almanak = { crops = { [kebunCrop] = {} }, pages = nil }
			local discovery = fx.AlmanakService.record(fx.player, kebunCrop, "biasa", {})
			expect(discovery.first):toBe(false)
			expect(fx.data.almanak.crops[kebunCrop].count):toBe(1)
			expect(fx.data.almanak.pages.palawija):toBeNil()
		end)

		t:it("progress reads a damaged or missing almanak without error", function()
			local fx = buildAlmanak()
			local total = #fx.Crops.families.palawija
			fx.data.almanak = nil
			expect(fx.AlmanakService.progress(fx.data, "palawija")):toBe(0)
			local _, reported = fx.AlmanakService.progress(fx.data, "palawija")
			expect(reported):toBe(total)

			fx.data.almanak = { crops = nil }
			expect(fx.AlmanakService.progress(fx.data, "palawija")):toBe(0)

			-- A falsy entry is not a discovery.
			fx.data.almanak = { crops = { padi = false } }
			expect(fx.AlmanakService.progress(fx.data, "palawija")):toBe(0)

			expect(fx.AlmanakService.progress(fx.data, "tidakAda")):toBe(0)
			expect(fx.AlmanakService.isPageComplete(fx.data, nil)):toBe(false)
		end)

		t:it("a NaN harvest count in a damaged entry is not carried forward as NaN", function()
			-- AlmanakService.luau:77 does `entry.count += 1` with no finite check, so a NaN count
			-- stays NaN after every harvest and is saved that way.
			local fx = buildAlmanak()
			fx.data.almanak = { crops = { padi = { tiers = {}, traits = {}, count = 0 / 0 } }, pages = {} }
			fx.AlmanakService.record(fx.player, "padi", "biasa", {})
			local count = fx.data.almanak.crops.padi.count
			expect(count == count):toBe(true)
		end)

		t:it("a page completes once: its reward is granted once and later harvests report no page", function()
			local fx = buildAlmanak()
			local crops = fx.Crops.families.palawija
			for index = 1, #crops - 1 do
				fx.AlmanakService.record(fx.player, crops[index], "biasa", {})
			end
			expect(fx.grants[fx.AlmanakConfig.pages.palawija.reward]):toBeNil()

			-- The completing harvest is a multi-tier, multi-trait one, so the reward must not depend
			-- on the tier or traits it carries.
			local last = fx.AlmanakService.record(fx.player, crops[#crops], "sultan", { "basah", "organik" })
			expect(last.pageCompleted):toBe(true)
			expect(last.reward):toBe(fx.AlmanakConfig.pages.palawija.reward)
			expect(last.family):toBe("palawija")
			expect(fx.grants[fx.AlmanakConfig.pages.palawija.reward]):toBe(1)

			local again = fx.AlmanakService.record(fx.player, crops[1], "sultan", { "basah" })
			expect(again.pageCompleted):toBe(false)
			expect(again.reward):toBeNil()
			expect(fx.grants[fx.AlmanakConfig.pages.palawija.reward]):toBe(1)
			expect(fx.data.almanak.pages.palawija):toBe(true)
		end)

		t:it("a departed player records nothing, touches nothing and is granted nothing", function()
			local fx = buildAlmanak()
			fx.playerData.set(fx.player, nil)
			expect(fx.AlmanakService.record(fx.player, "padi", "biasa", { "basah" })):toBeNil()
			expect(#fx.touched):toBe(0)
			expect(next(fx.grants)):toBeNil()
			expect(fx.AlmanakService.isPageComplete(fx.data, "palawija")):toBe(false)
		end)
	end)
end
