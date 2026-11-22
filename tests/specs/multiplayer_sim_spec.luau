--!nocheck
-- Q5 (soak / ten-player session), Lune side. Ten fake players run plant / harvest / sell /
-- buy / raid / debt interleaved on the REAL services with Fakes for infrastructure. The point
-- is cross-player isolation: module-level state and shared config may exist (MarketService
-- pressure is per-crop by design, RaidService.nextToken is a global counter), but no player's
-- cash, items, tiles, debt or raid state may leak into another player's.
--
-- The live ten-client Studio half stays BLOCKED on the designer (Studio MCP has no Local
-- Server / team-test tool; evidence docs/v2/evidence/h/2026-11-19-q5-multiclient/). This spec
-- is the scriptable substitute for the state-isolation and no-stuck-state part of Q5.

return function(t, Env, Fakes)
	local expect = t.expect
	local PLAYERS = 10

	local function finite(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end
	local function isInt(n)
		return finite(n) and n == math.floor(n)
	end

	-- Fake world parts so the REAL FarmService doPlant / doHarvest can build visuals.
	local function makePartFactory(env)
		local cf = setmetatable({}, { __mul = function() return cf end })
		local function newPart(name)
			local node = { Name = name, _children = {}, _attributes = {}, CFrame = cf }
			function node:SetAttribute(key, value) self._attributes[key] = value end
			function node:GetAttribute(key) return self._attributes[key] end
			function node:FindFirstChild(childName) return self._children[childName] end
			function node:Destroy() end
			return node
		end
		env.globals.Instance = { new = function(className) return newPart(className) end }
		env.globals.CFrame = { new = function() return cf end }
		env.globals.Color3.fromHex = function() return {} end
		local vectorMeta = getmetatable(env.Vector3.new(0, 0, 0))
		vectorMeta.__mul = function(a, b)
			return env.Vector3.new(a.X * b, a.Y * b, a.Z * b)
		end
		return newPart
	end

	-- -------------------------------------------------------------------------------------
	-- World A: real EconomyService + MarketService + DebtService, shared by ten players.
	-- -------------------------------------------------------------------------------------
	local function makeMoneyWorld()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Events/CabaiEvent", {
			multiplier = function() return 1 end,
			isActive = function() return false end,
			start = function() end,
		})
		local PASAR = env.Vector3.new(0, 0, 0)
		env:mock("server/World/Village", {
			getPosition = function() return PASAR end,
			onPasar = function() end,
		})

		local Economy = env:require("server/Economy/EconomyService")
		local Market = env:require("server/Economy/MarketService")
		local Debt = env:require("server/Economy/DebtService")
		local Inventory = env:require("shared/Inventory")
		local Produce = env:require("shared/Produce")
		local Crops = env:require("shared/Config/Crops")

		local players, datas = {}, {}
		for i = 1, PLAYERS do
			local p = Fakes.player(env, { name = "P" .. i, position = PASAR })
			players[i] = p
			datas[i] = playerData.set(p, Fakes.newData(env))
		end
		return {
			env = env, playerData = playerData, remotes = remotes,
			Economy = Economy, Market = Market, Debt = Debt,
			Inventory = Inventory, Produce = Produce, Crops = Crops,
			players = players, datas = datas, PASAR = PASAR,
		}
	end

	t:describe("Multiplayer sim — money, items and debt isolation (10 players)", function()
		t:it("an interleaved addCash grant touches only the target player's cash", function()
			local w = makeMoneyWorld()
			local before = {}
			for i = 1, PLAYERS do before[i] = w.datas[i].cash end

			for _, i in ipairs({ 2, 5, 9 }) do
				w.Economy.addCash(w.players[i], 1000, false, { sku = "sim_grant" })
			end
			for i = 1, PLAYERS do
				local expected = before[i] + ((i == 2 or i == 5 or i == 9) and 1000 or 0)
				expect(w.datas[i].cash):toBe(expected)
				expect(finite(w.datas[i].cash)):toBe(true)
			end
		end)

		t:it("ten interleaved buySeed calls spend and grant exactly, with no duplicated seeds", function()
			local w = makeMoneyWorld()
			local cost = w.Crops.list.padi.seedCost
			for i = 1, PLAYERS do
				w.datas[i].cash = 100000
				w.datas[i].items.seed_padi = 0
			end
			for i = 1, PLAYERS do
				expect(w.Economy.buySeed(w.players[i], "padi", 3)):toBe(true)
			end
			for i = 1, PLAYERS do
				expect(w.Inventory.getSeed(w.datas[i], "padi")):toBe(3)
				expect(w.datas[i].cash):toBe(100000 - cost * 3)
				expect(isInt(w.datas[i].cash)):toBe(true)
				expect(isInt(w.Inventory.getSeed(w.datas[i], "padi"))):toBe(true)
			end
		end)

		t:it("NaN, negative and infinite money never poison a player or overflow to others", function()
			local w = makeMoneyWorld()
			local before = {}
			for i = 1, PLAYERS do before[i] = w.datas[i].cash end

			w.Economy.addCash(w.players[1], 0 / 0, false)
			w.Economy.addCash(w.players[1], -50, false)
			w.Economy.addCash(w.players[1], math.huge, false)
			expect(w.datas[1].cash):toBe(before[1])
			expect(w.Economy.trySpend(w.players[1], 0 / 0)):toBe(false)
			expect(w.Economy.trySpend(w.players[1], -50)):toBe(false)
			expect(w.datas[1].cash):toBe(before[1])
			for i = 1, PLAYERS do
				expect(finite(w.datas[i].cash)):toBe(true)
				expect(w.datas[i].cash >= 0):toBe(true)
			end
		end)

		t:it("selling only empties the seller's sack and never another player's", function()
			local w = makeMoneyWorld()
			for i = 1, PLAYERS do
				w.Economy.addHarvest(w.players[i], "padi", 1)
				w.Economy.addHarvest(w.players[i], "padi", 1)
			end
			local cashBefore = {}
			for i = 1, PLAYERS do cashBefore[i] = w.datas[i].cash end

			for _, i in ipairs({ 4, 7, 10 }) do
				w.Economy.sellAll(w.players[i], "pasar")
			end
			for i = 1, PLAYERS do
				local sold = (i == 4 or i == 7 or i == 10)
				expect(w.datas[i].cash > cashBefore[i]):toBe(sold)
				expect(finite(w.datas[i].cash)):toBe(true)
				expect(w.Produce.count(w.datas[i].produce)):toBe(if sold then 0 else 2)
			end
		end)

		t:it("ten independent loans: borrowing and repaying one player never touches another", function()
			local w = makeMoneyWorld()
			for i = 1, PLAYERS do
				expect(w.Debt.borrow(w.players[i], 400)):toBe(true)
			end
			local owed = {}
			for i = 1, PLAYERS do
				expect(w.datas[i].debt.active):toBe(true)
				expect(finite(w.datas[i].debt.owed)):toBe(true)
				owed[i] = w.datas[i].debt.owed
			end
			expect(w.Debt.repay(w.players[6])):toBe(true)
			expect(w.datas[6].debt.active):toBe(false)
			expect(w.datas[6].debt.owed):toBe(0)
			for i = 1, PLAYERS do
				if i ~= 6 then
					expect(w.datas[i].debt.active):toBe(true)
					expect(w.datas[i].debt.owed):toBe(owed[i])
				end
			end
		end)
	end)

	-- -------------------------------------------------------------------------------------
	-- World B: real RaidService state machine, ten players, mocked economy/farm edges.
	-- -------------------------------------------------------------------------------------
	local function makeRaidWorld()
		local env = Env.new()
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local plot = { index = 1, spawnCFrame = { Position = env.Vector3.new(0, 0, 0) }, tiles = {} }

		env.globals.CFrame = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
		env.globals.task.spawn = function() end -- timers still run via task.delay / env:advance

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Analytics/Analytics", Fakes.analytics())
		env:mock("server/Progression/BadgeService", { award = function() end })
		env:mock("server/Progression/RankService", { addNamaBaik = function() end })
		env:mock("server/Farm/FarmService", { confiscateHotTiles = function() return 0 end })
		env:mock("server/Farm/PlotService", {
			getPlotOf = function() return plot end,
			getPlot = function() return plot end,
		})
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount)
				local data = playerData.get(player)
				if data == nil or data.cash < amount then return false end
				data.cash -= amount
				return true
			end,
			removeHotHarvest = function() return 0 end,
		})
		env:mock("server/Npc/CutsceneHooks", { emitRaid = function() end })
		env:mock("server/World/Village", {
			police = {},
			getPosition = function() return env.Vector3.new(0, 0, 20) end,
		})

		local Raid = env:require("server/Law/RaidService")
		Raid.bindSus({ set = function() end, add = function() end })
		Raid.init()

		local players, datas = {}, {}
		for i = 1, PLAYERS do
			local p = Fakes.player(env, { name = "R" .. i, position = env.Vector3.new(0, 0, 0) })
			p.Character.FindFirstChildOfClass = function() return nil end
			players[i] = p
			local d = playerData.set(p, Fakes.newData(env))
			d.cash = 10000
			datas[i] = d
		end
		return { env = env, remotes = remotes, Raid = Raid, players = players, datas = datas }
	end

	t:describe("Multiplayer sim — raid state isolation (10 players)", function()
		t:it("raids on a subset never mark the others InRaid or give them a raid state", function()
			local w = makeRaidWorld()
			local active = { [1] = true, [3] = true, [5] = true }
			for i = 1, PLAYERS do
				if active[i] then w.Raid.start(w.players[i], false) end
			end
			w.env:advance(w.Raid.INCOMING_SECONDS)

			for i = 1, PLAYERS do
				if active[i] then
					expect(w.Raid.getState(w.players[i])):toBe("choosing")
					expect(w.players[i]:GetAttribute("InRaid")):toBe(true)
				else
					expect(w.Raid.isBusy(w.players[i])):toBe(false)
					expect(w.players[i]:GetAttribute("InRaid")).never:toBe(true)
				end
			end
		end)

		t:it("interleaved choices resolve each raid exactly once; no stuck choosing state", function()
			local w = makeRaidWorld()
			for i = 1, PLAYERS do w.Raid.start(w.players[i], false) end
			w.env:advance(w.Raid.INCOMING_SECONDS)
			for i = 1, PLAYERS do
				expect(w.Raid.getState(w.players[i])):toBe("choosing")
			end

			-- Deliberately out of order, one choice per raider.
			for _, i in ipairs({ 10, 2, 8, 1, 6, 4, 9, 3, 7, 5 }) do
				w.remotes.Raid_Choose.OnServerEvent:Fire(w.players[i], "denda")
			end
			for i = 1, PLAYERS do
				expect(w.Raid.isBusy(w.players[i])):toBe(false)
				expect(w.datas[i].cash):toBeLessThan(10000)
				expect(finite(w.datas[i].cash)):toBe(true)
				expect(w.datas[i].cash >= 0):toBe(true)
			end

			-- A late duplicate choice must not take money twice or re-stick the state.
			local cashAfter = {}
			for i = 1, PLAYERS do cashAfter[i] = w.datas[i].cash end
			w.remotes.Raid_Choose.OnServerEvent:Fire(w.players[1], "denda")
			for i = 1, PLAYERS do
				expect(w.datas[i].cash):toBe(cashAfter[i])
				expect(w.Raid.isBusy(w.players[i])):toBe(false)
			end
		end)
	end)

	-- -------------------------------------------------------------------------------------
	-- World C: real FarmService commitAttempt, ten players with ten distinct plots.
	-- -------------------------------------------------------------------------------------
	local function makeFarmWorld()
		local env = Env.new()
		local newPart = makePartFactory(env)
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local plots, plotsByIndex = {}, {}

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", Fakes.notify())
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))
		env:mock("server/Net/State", { touch = function() end })
		env:mock("server/Live/LiveConfig", {
			getRuntime = function() return { musim = "kemarau", anomali = "none", cuaca = "cerah" } end,
		})
		env:mock("server/Analytics/Analytics", { track = function() end, log = function() end })
		env:mock("server/Economy/EconomyService", {
			hasRank = function() return true end,
			sync = function() end,
			near = function() return true end,
			refreshRank = function() end,
			addCash = function() end,
			trySpend = function() return true end,
			addHarvest = function(player, cropId, quality, options)
				local Produce = env:require("shared/Produce")
				Produce.add(playerData.get(player).produce, cropId, quality, options)
			end,
		})
		env:mock("server/Progression/AlmanakService", { record = function() end })
		env:mock("server/Progression/BadgeService", { award = function() end })
		env:mock("server/Progression/OnboardingService", { advance = function() return true end })
		env:mock("server/Progression/QuestService", { progress = function() end })
		env:mock("server/Farm/PlotService", {
			getPlotOf = function(player) return plots[player] end,
			getPlot = function(index) return plotsByIndex[index] end,
			onTilePrompt = function() end,
		})
		env:mock("server/World/Village", { getPosition = function() return env.Vector3.new(0, 0, 0) end })

		local Farm = env:require("server/Farm/FarmService")
		local players, datas = {}, {}
		for i = 1, PLAYERS do
			local p = Fakes.player(env, { name = "F" .. i })
			local tile1 = newPart("Tile_1")
			tile1.Size = env.Vector3.new(6, 0.5, 6)
			tile1.Position = env.Vector3.new(0, 0, 0)
			tile1._children.Prompt = { Enabled = false }
			local plot = {
				index = i, owner = p, tiles = { [1] = tile1 },
				spawnCFrame = { Position = env.Vector3.new(0, 0, 0) },
			}
			plots[p] = plot
			plotsByIndex[i] = plot
			players[i] = p
			local d = playerData.set(p, Fakes.newData(env))
			d.tilesOwned = 6
			d.items.seed_padi = 5
			d.items.seed_cabai = 5
			datas[i] = d
		end
		return { env = env, Farm = Farm, players = players, datas = datas }
	end

	t:describe("Multiplayer sim — farm / minigame state isolation (10 players)", function()
		t:it("ten interleaved plants write only to each player's own tile table", function()
			local w = makeFarmWorld()
			for i = 1, PLAYERS do
				local crop = if i % 2 == 0 then "cabai" else "padi"
				expect(w.Farm.commitAttempt(w.players[i], { tile = 1, action = "plant", cropId = crop }, 0.9)):toBe(true)
			end
			for i = 1, PLAYERS do
				local crop = if i % 2 == 0 then "cabai" else "padi"
				local _, entry = next(w.datas[i].tiles)
				expect(entry):toBeTruthy()
				expect(entry.crop):toBe(crop)
			end
			-- Distinct tables: one player's tiles are not shared storage.
			expect(w.datas[1].tiles == w.datas[2].tiles):toBe(false)
			expect(w.datas[1].produce == w.datas[2].produce):toBe(false)
		end)

		t:it("a rejected minigame attempt never wedges later plant or harvest for anyone", function()
			local w = makeFarmWorld()
			-- A malformed attempt is refused without leaving pending state behind.
			expect(w.Farm.commitAttempt(w.players[1], { tile = 1, action = "plant", cropId = "padi" }, 0 / 0)):toBe(false)
			-- A valid plant on tile 1 for every player still works after the rejection.
			for i = 1, PLAYERS do
				expect(w.Farm.commitAttempt(w.players[i], { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(true)
			end
			-- A second plant on the same tile is refused (tile already occupied) and is not stuck.
			for i = 1, PLAYERS do
				expect(w.Farm.commitAttempt(w.players[i], { tile = 1, action = "plant", cropId = "padi" }, 0.9)):toBe(false)
			end
			-- Growing finishes; every player can harvest their own crop.
			w.env:advance(3600)
			for i = 1, PLAYERS do
				expect(w.Farm.commitAttempt(w.players[i], { tile = 1, action = "harvest" }, 0.9)):toBe(true)
			end
			for i = 1, PLAYERS do
				local _, entry = next(w.datas[i].produce)
				expect(entry):toBeTruthy()
				expect(entry.crop):toBe("padi")
			end
		end)
	end)
end
