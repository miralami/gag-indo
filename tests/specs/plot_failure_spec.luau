--!nocheck
-- PlotService failure-path specs. The REAL PlotService runs here (Props/Map are faked so the
-- plot models can be built under Lune). Claims, releases and rejoins are checked for one owner
-- per plot and exactly one free per leave. Tile buying lives in FarmService.buyTile, so those
-- tests drive the real FarmService tile-prompt handler (captured through PlotService.onTilePrompt)
-- against the real PlotService. Tests whose name starts with "[BUG]" are expected to fail: they
-- reveal real defects. Do not edit PlotService or FarmService to make them pass in this file.
-- EconomyService.trySpend is mocked with the same guards as the real function
-- (EconomyService.luau lines 111-118), like cheat_failure_spec does.

return function(t, Env, Fakes)
	local expect = t.expect
	local Strings = Env.new():require("shared/Strings")

	-- Fakes.player has no DisplayName; the real Player always does (PlotService.claim reads it).
	local function mkPlayer(env, name)
		local player = Fakes.player(env)
		player.DisplayName = name or player.Name
		return player
		end

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	local function makeWorld(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local economy = { near = true, spent = {} }

		local cf = setmetatable({}, { __mul = function(a) return a end })
		local function newNode(name, className)
			local node = { Name = name, ClassName = className, Position = env.Vector3.new(0, 0, 0), _children = {}, _attributes = {}, Transparency = 0 }
			function node:SetAttribute(k, v) self._attributes[k] = v end
			function node:GetAttribute(k) return self._attributes[k] end
			function node:FindFirstChild(n) return self._children[n] end
			function node:Destroy() end
			function node:IsA(cls) return cls == self.ClassName end
			return node
		end

		env.globals.CFrame = {
			new = function() return cf end,
			lookAt = function() return cf end,
			Angles = function() return cf end,
		}
		env.globals.Instance = { new = function(className) return newNode(className, className) end }
		env.globals.workspace = { FindFirstChild = function() return nil end }
		env.globals.Vector2 = { new = function(x, y) return { X = x, Y = y } end }
		env.services.CollectionService = { AddTag = function() end, GetTagged = function() return {} end }

		env:mock("server/World/Props", {
			part = function(props)
				local part = newNode(props.Name, "BasePart")
				part.CFrame = props.CFrame
				part.Color = props.Color
				part.Transparency = props.Transparency or 0
				return part
			end,
			prompt = function(parent)
				local prompt = { Enabled = false, Triggered = env.newSignal() }
				parent._children.Prompt = prompt
				return prompt
			end,
			billboard = function() return { Text = "" } end,
			palette = function() return {} end,
		})
		env:mock("server/World/Map", {
			TAGS = { World = "VillageWorld", PlotAnchor = "PlotAnchor", Tile = "Tile" },
			first = function() return nil end,
			all = function() return {} end,
			has = function() return false end,
		})
		env:mock("shared/Remotes", Fakes.remotes(env))
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Live/LiveConfig", { getRuntime = function() return { musim = "kemarau", anomali = "none", cuaca = "cerah" } end })
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount)
				local data = playerData.get(player)
				if not data or not isFinite(amount) or amount < 0 then
					return false
				end
				amount = math.floor(amount)
				if not isFinite(data.cash) or data.cash < amount then
					notify.send(player, "n_not_enough_cash")
					return false
				end
				data.cash -= amount
				table.insert(economy.spent, amount)
				return true
			end,
			near = function() return economy.near end,
			hasRank = function() return true end,
			sync = function() end,
			refreshRank = function() end,
			addCash = function() end,
			addHarvest = function() end,
		})
		env:mock("server/Progression/AlmanakService", { record = function() end })
		env:mock("server/Progression/BadgeService", { award = function() end })
		env:mock("server/Progression/OnboardingService", { advance = function() end })
		env:mock("server/Progression/QuestService", { progress = function() end })

		local PlotService = env:require("server/Farm/PlotService")
		local FarmService = env:require("server/Farm/FarmService")
		local Game = env:require("shared/Config/Game")

		-- Capture the tile-prompt handler FarmService registers, so bad indexes can be sent directly.
		local tileHandler
		PlotService.onTilePrompt = function(cb) tileHandler = cb end
		env.globals.task.spawn = function() end
		PlotService.build()
		FarmService.start()

		local fx = {
			env = env,
			Game = Game,
			PlotService = PlotService,
			FarmService = FarmService,
			playerData = playerData,
			notify = notify,
			rateLimit = rateLimit,
			economy = economy,
			handler = function(...) return tileHandler(...) end,
		}

		-- Join a player: fresh save (optionally with cash), no plot yet.
		function fx.join(cash)
			local player = mkPlayer(env)
			local data = playerData.set(player, Fakes.newData(env))
			if cash ~= nil then
				data.cash = cash
			end
			return player, data
		end

		return fx
	end

	local function ownedBy(fx, player)
		local count = 0
		for i = 1, fx.Game.plotCount do
			local plot = fx.PlotService.getPlot(i)
			if plot and plot.owner == player then
				count += 1
			end
		end
		return count
	end

	t:describe("PlotService failure paths", function()
		t:it("claim hands out each plot once and returns nil when every plot is taken", function()
			local fx = makeWorld()
			local seen = {}
			for _ = 1, fx.Game.plotCount do
				local plot = fx.PlotService.claim(mkPlayer(fx.env))
				expect(plot ~= nil):toBe(true)
				expect(seen[plot.index]):toBe(nil)
				seen[plot.index] = true
			end
			expect(fx.PlotService.claim(mkPlayer(fx.env))):toBe(nil)
		end)

		t:it("a second claim by the same player returns the same plot and takes no other", function()
			local fx = makeWorld()
			local player = mkPlayer(fx.env)
			local first = fx.PlotService.claim(player)
			local second = fx.PlotService.claim(player)
			expect(second):toBe(first)
			expect(ownedBy(fx, player)):toBe(1)
			local other = fx.PlotService.claim(mkPlayer(fx.env))
			expect(other ~= first):toBe(true)
			expect(first.owner):toBe(player)
		end)

		t:it("release frees the plot exactly once and leaves other owners untouched", function()
			local fx = makeWorld()
			local p1, p2, p3 = mkPlayer(fx.env), mkPlayer(fx.env), mkPlayer(fx.env)
			local a = fx.PlotService.claim(p1)
			local b = fx.PlotService.claim(p2)
			fx.PlotService.release(p1)
			fx.PlotService.release(p1) -- second release must do nothing
			fx.PlotService.release(mkPlayer(fx.env)) -- stranger with no plot: no-op
			expect(a.owner):toBe(nil)
			expect(b.owner):toBe(p2)
			expect(fx.PlotService.getPlotOf(p2)):toBe(b)
			-- Exactly one plot is free: p3 gets it, and the next claimant gets a different one.
			expect(fx.PlotService.claim(p3)):toBe(a)
			local p4 = mkPlayer(fx.env)
			local d = fx.PlotService.claim(p4)
			expect(d ~= a):toBe(true)
			expect(d ~= b):toBe(true)
		end)

		t:it("leaving resets the plot sign, owner attribute and tile states", function()
			local fx = makeWorld()
			local player = mkPlayer(fx.env, "Pak Tani")
			local plot = fx.PlotService.claim(player)
			expect(plot.sign.Text):toBe(Strings.get("id", "plot_owned", player.DisplayName))
			plot.tiles[1]:SetAttribute("State", "ready")
			fx.env.services.Players.PlayerRemoving:Fire(player)
			expect(plot.owner):toBe(nil)
			expect(plot.model:GetAttribute("OwnerUserId")):toBe(0)
			expect(plot.sign.Text):toBe(Strings.get("id", "plot_empty"))
			expect(plot.tiles[1]:GetAttribute("State")):toBe("noowner")
			expect(fx.PlotService.getPlotOf(player)):toBe(nil)
			-- Leaving twice (duplicate PlayerRemoving) is harmless.
			fx.env.services.Players.PlayerRemoving:Fire(player)
			expect(ownedBy(fx, player)):toBe(0)
		end)

		t:it("rejoining after leaving claims a plot again and holds exactly one", function()
			local fx = makeWorld()
			local player = mkPlayer(fx.env)
			local before = fx.PlotService.claim(player)
			fx.env.services.Players.PlayerRemoving:Fire(player)
			local after = fx.PlotService.claim(player)
			expect(after ~= nil):toBe(true)
			expect(fx.PlotService.getPlotOf(player)):toBe(after)
			expect(ownedBy(fx, player)):toBe(1)
			expect(before.owner):toBe(player)
		end)

		t:it("getPlot returns nil for bad indexes instead of erroring", function()
			local fx = makeWorld()
			local bad = { 0, -1, 0 / 0, 1.5, math.huge, -math.huge, fx.Game.plotCount + 1, "1" }
			for _, value in bad do
				local ok, result = pcall(fx.PlotService.getPlot, value)
				expect(ok):toBe(true)
				expect(result):toBe(nil)
			end
			local ok, result = pcall(fx.PlotService.getPlot, nil)
			expect(ok):toBe(true)
			expect(result):toBe(nil)
		end)

		t:it("buying a tile with too little cash changes nothing", function()
			local fx = makeWorld()
			local player, data = fx.join(99) -- tile 7 costs 100
			fx.PlotService.claim(player)
			fx.handler(player, 1, 7)
			expect(data.tilesOwned):toBe(fx.Game.startTiles)
			expect(data.cash):toBe(99)
			expect(#fx.economy.spent):toBe(0)
			expect(data.tiles.t7):toBe(nil)
		end)

		t:it("buying with exact cash ends at zero and a further unaffordable buy keeps cash at zero", function()
			local fx = makeWorld()
			local player, data = fx.join(100)
			fx.PlotService.claim(player)
			fx.handler(player, 1, 7)
			expect(data.tilesOwned):toBe(fx.Game.startTiles + 1)
			expect(data.cash):toBe(0)
			fx.handler(player, 1, 8) -- tile 8 costs 200
			expect(data.tilesOwned):toBe(fx.Game.startTiles + 1)
			expect(data.cash):toBe(0)
		end)

		t:it("buying beyond maxTiles is refused even with plenty of cash", function()
			local fx = makeWorld()
			local player, data = fx.join(1000000000)
			fx.PlotService.claim(player)
			data.tilesOwned = fx.Game.maxTiles
			fx.handler(player, 1, fx.Game.maxTiles + 1)
			expect(data.tilesOwned):toBe(fx.Game.maxTiles)
			expect(data.cash):toBe(1000000000)
		end)

		t:it("bad tile indexes (nil, 0, NaN, 1.5, huge) never buy, plant or error", function()
			local fx = makeWorld()
			local player, data = fx.join(1000000)
			fx.PlotService.claim(player)
			local function attempt(index)
				local ok = pcall(fx.handler, player, 1, index)
				expect(ok):toBe(true)
			end
			attempt(nil)
			attempt(0)
			attempt(0 / 0)
			attempt(1.5)
			attempt(math.huge)
			attempt(-3)
			expect(data.tilesOwned):toBe(fx.Game.startTiles)
			expect(data.cash):toBe(1000000)
			expect(next(data.tiles) == nil):toBe(true)
		end)

		t:it("a rate-limited tile prompt changes nothing even with cash to spare", function()
			local fx = makeWorld({ allow = false })
			local player, data = fx.join(1000)
			fx.PlotService.claim(player)
			fx.handler(player, 1, 7)
			fx.handler(player, 1, 1)
			expect(data.tilesOwned):toBe(fx.Game.startTiles)
			expect(data.cash):toBe(1000)
			expect(next(data.tiles) == nil):toBe(true)
		end)

		t:it("a NaN tilesOwned in a damaged save lets no locked or owned tile be bought or planted", function()
			local fx = makeWorld()
			local player, data = fx.join(1000)
			fx.PlotService.claim(player)
			data.tilesOwned = 0 / 0
			fx.handler(player, 1, 7)
			fx.handler(player, 1, 1)
			expect(data.tiles.t7):toBe(nil)
			expect(data.tiles.t1):toBe(nil)
			expect(data.cash):toBe(1000)
		end)

		t:it("a damaged save with nil tilesOwned does not throw from the tile prompt (tile 7)", function()
			local fx = makeWorld()
			local player, data = fx.join(1000)
			fx.PlotService.claim(player)
			data.tilesOwned = nil
			local ok, err = pcall(fx.handler, player, 1, 7)
			expect(err):toBe(nil)
			expect(ok):toBe(true)
		end)

		t:it("a damaged save with a missing tiles table does not throw from the tile prompt (tile 1)", function()
			local fx = makeWorld()
			local player, data = fx.join(1000)
			fx.PlotService.claim(player)
			data.tiles = nil
			local ok, err = pcall(fx.handler, player, 1, 1)
			expect(err):toBe(nil)
			expect(ok):toBe(true)
		end)

		t:it("NaN cash refuses every purchase and is never replaced with a negative or spent value", function()
			local fx = makeWorld()
			local player, data = fx.join(0 / 0)
			fx.PlotService.claim(player)
			fx.handler(player, 1, 7)
			expect(#fx.economy.spent):toBe(0)
			expect(data.tilesOwned):toBe(fx.Game.startTiles)
			expect(data.cash ~= data.cash):toBe(true) -- still NaN, not silently turned into a number
		end)
	end)
end
