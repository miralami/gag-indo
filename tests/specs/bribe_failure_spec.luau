--!nocheck
-- T5 (Law, BribeService): failure-path specs. A refused bribe never moves money or the
-- counter, and a damaged save never errors.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeBribe()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local village = { onBribeCb = nil, pakrt = nil }
		local PASAR = env.Vector3.new(10, 0, 0)
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Law/SusService", { reduce = function() end })
		env:mock("server/World/Village", {
			getPosition = function() return PASAR end,
			onPasar = function() end,
			onBribe = function(cb) village.onBribeCb = cb end,
			pakrt = nil,
		})
		local EconomyService = env:require("server/Economy/EconomyService")
		local BribeService = env:require("server/Law/BribeService")
		local Law = env:require("shared/Config/Law")
		local player = Fakes.player(env, { position = PASAR })
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = 10_000_000
		env.globals.task.spawn = function() end
		BribeService.start()
		return {
			env = env,
			remotes = remotes,
			village = village,
			player = player,
			data = data,
			Law = Law,
			BribeService = BribeService,
			EconomyService = EconomyService,
			notify = notify,
		}
	end

	t:describe("Bribe failure paths (T5)", function()
		t:it("a bribe away from Pak RT is refused and changes nothing", function()
			local fx = makeBribe()
			fx.player.Character.HumanoidRootPart.Position = fx.env.Vector3.new(500, 0, 0)
			local cash = fx.data.cash
			fx.remotes.Bribe_RT.OnServerEvent:Fire(fx.player)
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.cooldowns.bribeCount):toBe(nil)
		end)

		t:it("a bribe during cooldown is refused", function()
			local fx = makeBribe()
			fx.data.cooldowns.bribeReadyAt = os.time() + 600
			local cash = fx.data.cash
			fx.remotes.Bribe_RT.OnServerEvent:Fire(fx.player)
			expect(fx.data.cash):toBe(cash)
			expect(fx.data.cooldowns.bribeCount):toBe(nil)
		end)

		t:it("a bribe without enough cash is refused and the counter does not rise", function()
			local fx = makeBribe()
			fx.data.cash = 1
			fx.remotes.Bribe_RT.OnServerEvent:Fire(fx.player)
			expect(fx.data.cash):toBe(1)
			expect(fx.data.cooldowns.bribeCount):toBe(nil)
		end)

		t:it("a successful bribe charges the current price exactly and starts cooldown", function()
			local fx = makeBribe()
			local before = fx.data.cash
			fx.remotes.Bribe_RT.OnServerEvent:Fire(fx.player)
			expect(fx.data.cash):toBe(before - fx.Law.bribeBasePrice)
			expect(fx.data.cooldowns.bribeCount):toBe(1)
			expect(fx.data.cooldowns.bribeReadyAt):toBe(fx.env.wallTime + fx.Law.bribeCooldown)
		end)

		t:it("a price that overflows to infinity is refused, not charged", function()
			local fx = makeBribe()
			fx.data.cooldowns.bribeWindowStart = os.time()
			fx.data.cooldowns.bribeCount = 100000
			local cash = fx.data.cash
			fx.village.onBribeCb(fx.player)
			expect(fx.data.cash):toBe(cash)
		end)

		t:it("a save with no cooldown table does not error on bribe or price sync", function()
			local fx = makeBribe()
			fx.data.cooldowns = nil
			local ok = pcall(fx.village.onBribeCb, fx.player)
			expect(ok):toBe(true)
			fx.data.cooldowns = nil
			local ok2 = pcall(fx.BribeService.syncPrice, fx.player)
			expect(ok2):toBe(true)
		end)
	end)
end
