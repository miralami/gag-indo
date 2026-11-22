--!nocheck
-- Cosmetics and LeaderboardService failure-path specs. A refused purchase or equip never spends
-- cash or changes ownership; a rate-limited call changes nothing; a failed DataStore read or write
-- never blanks or crashes the server; NaN, infinite or negative scores are never written.
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects (line numbers
-- are in the report that accompanies this spec). Do not edit Cosmetics or LeaderboardService to make
-- them pass in this file.
-- EconomyService.trySpend is mocked with the same guards as the real function (see the cheat spec),
-- so the NaN-cash test reflects the real guard. All ids and numbers here are fake test values.

return function(t, Env, Fakes)
	local expect = t.expect

	local function isFinite(n)
		return type(n) == "number" and n == n and n > -math.huge and n < math.huge
	end

	-- ---------------------------------------------------------------------------
	-- Cosmetics
	-- ---------------------------------------------------------------------------

	local function makeCosmetics(options)
		options = options or {}
		local env = Env.new()
		local playerData = Fakes.playerData()
		local notify = Fakes.notify()
		local remotes = Fakes.remotes(env)
		local rateLimit = Fakes.rateLimit(options.allow ~= false)
		local economy = { spent = {} }

		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/Notify", notify)
		env:mock("server/Net/RateLimit", rateLimit)
		env:mock("server/Economy/EconomyService", {
			trySpend = function(player, amount, opts)
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
				table.insert(economy.spent, { amount = amount, sku = opts and opts.sku })
				return true
			end,
		})

		local Cosmetics = env:require("server/Monetization/Cosmetics")
		Cosmetics.start()

		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		data.cash = options.cash or 1000

		return {
			env = env,
			Cosmetics = Cosmetics,
			player = player,
			data = data,
			notify = notify,
			rateLimit = rateLimit,
			economy = economy,
			buy = function(itemId)
				remotes.Cosmetic_Buy.OnServerEvent:Fire(player, itemId)
			end,
			equip = function(itemId)
				remotes.Cosmetic_Equip.OnServerEvent:Fire(player, itemId)
			end,
		}
	end

	t:describe("Cosmetics failure paths", function()
		t:it("bad equip ids change nothing and send no toast", function()
			local fx = makeCosmetics()
			fx.data.cosmetics.caping = true
			for _, bad in { 42, {}, true, "bogus", "CAPING" } do
				fx.equip(bad)
			end
			expect(fx.data.equipped.cosmetic):toBeNil()
			expect(#fx.notify.keys(fx.player)):toBe(0)
		end)

		t:it("equipping an unowned item is refused; an empty id unequips the owned one", function()
			local fx = makeCosmetics()
			fx.data.cosmetics.caping = true
			fx.equip("peci")
			expect(fx.data.equipped.cosmetic):toBeNil()
			expect(fx.player:GetAttribute("EquippedCosmetic")):toBeNil()

			fx.equip("caping")
			expect(fx.data.equipped.cosmetic):toBe("caping")
			expect(fx.player:GetAttribute("EquippedCosmetic")):toBe("caping")

			fx.equip("")
			expect(fx.data.equipped.cosmetic):toBeNil()
			expect(fx.player:GetAttribute("EquippedCosmetic")):toBe("")
		end)

		t:it("bad buy ids (wrong type, unknown, empty) spend nothing and grant nothing", function()
			local fx = makeCosmetics()
			fx.buy(42)
			fx.buy({})
			fx.buy(true)
			fx.buy("bogus")
			fx.buy("")
			expect(fx.data.cash):toBe(1000)
			expect(#fx.economy.spent):toBe(0)
			expect(next(fx.data.cosmetics)):toBeNil()
			expect(#fx.notify.keys(fx.player)):toBe(0)
		end)

		t:it("buying without enough cash is refused and grants nothing", function()
			local fx = makeCosmetics({ cash = 100 })
			fx.buy("peci") -- 750
			expect(fx.data.cash):toBe(100)
			expect(fx.data.cosmetics.peci):toBeNil()
			expect(fx.player:GetAttribute("Cosmetic_peci")):toBeNil()
			expect(#fx.economy.spent):toBe(0)
			expect(fx.notify.last().key):toBe("n_not_enough_cash")

			local short = makeCosmetics({ cash = 249 })
			short.buy("caping") -- 250
			expect(short.data.cash):toBe(249)
			expect(short.data.cosmetics.caping):toBeNil()
		end)

		t:it("buying with exactly enough cash ends at zero, never negative, and syncs the attribute", function()
			local fx = makeCosmetics({ cash = 250 })
			fx.buy("caping")
			expect(fx.data.cash):toBe(0)
			expect(fx.data.cash >= 0):toBe(true)
			expect(fx.data.cosmetics.caping):toBe(true)
			expect(fx.player:GetAttribute("Cosmetic_caping")):toBe(true)
			expect(fx.economy.spent[1].amount):toBe(250)
			expect(fx.economy.spent[1].sku):toBe("kosmetik_caping")
			expect(fx.notify.last().key):toBe("n_cosmetic_bought")
		end)

		t:it("a double purchase charges once and tells the player they already own it", function()
			local fx = makeCosmetics({ cash = 5000 })
			fx.buy("caping")
			fx.buy("caping")
			expect(#fx.economy.spent):toBe(1)
			expect(fx.data.cash):toBe(4750)
			expect(fx.notify.last().key):toBe("phone_owned")
		end)

		t:it("rate-limited buy and equip calls change nothing", function()
			local fx = makeCosmetics({ allow = false, cash = 5000 })
			fx.data.cosmetics.caping = true
			fx.buy("peci")
			fx.equip("caping")
			expect(fx.data.cash):toBe(5000)
			expect(fx.data.cosmetics.peci):toBeNil()
			expect(fx.data.equipped.cosmetic):toBeNil()
			expect(#fx.economy.spent):toBe(0)
			expect(#fx.notify.keys(fx.player)):toBe(0)
			expect(fx.rateLimit.calls[1]):toBe("Cosmetic_Buy")
			expect(fx.rateLimit.calls[2]):toBe("Cosmetic_Equip")
		end)

		t:it("a save with no cosmetics table does not throw on buy or on sync", function()
			-- Cosmetics.luau:97 and :130 index data.cosmetics with no nil guard (grant() at :109 does guard it).
			-- A damaged save throws inside the remote handler, and sync() runs on every load.
			local fx = makeCosmetics({ cash = 5000 })
			fx.data.cosmetics = nil
			local buyOk = pcall(fx.buy, "caping")
			expect(buyOk):toBe(true)
			local syncOk = pcall(fx.Cosmetics.sync, fx.player)
			expect(syncOk):toBe(true)
		end)

		t:it("a save with no equipped table does not throw on equip or on sync", function()
			-- Cosmetics.luau:99 (sync), :151 (unequip) and :161 (equip) index data.equipped with no nil guard.
			local fx = makeCosmetics()
			fx.data.cosmetics.caping = true
			fx.data.equipped = nil
			local equipOk = pcall(fx.equip, "caping")
			expect(equipOk):toBe(true)
			local syncOk = pcall(fx.Cosmetics.sync, fx.player)
			expect(syncOk):toBe(true)
		end)

		t:it("a NaN cash balance cannot buy a cosmetic", function()
			-- The NaN balance must be refused by the same guard as the real trySpend; nothing is granted.
			local fx = makeCosmetics()
			fx.data.cash = 0 / 0
			fx.buy("caping")
			expect(#fx.economy.spent):toBe(0)
			expect(fx.data.cosmetics.caping):toBeNil()
			expect(fx.data.cash ~= fx.data.cash):toBe(true)
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- LeaderboardService
	-- ---------------------------------------------------------------------------

	-- A fake OrderedDataStore. `failWrites` makes the next N SetAsync calls error; `failRead` makes
	-- GetSortedAsync error; `pageFn` (if set) replaces GetSortedAsync entirely.
	local function makeStore()
		local store = { attempts = 0, values = {}, failWrites = 0, failRead = false, pageFn = nil }
		function store:SetAsync(key, value)
			self.attempts += 1
			if self.failWrites > 0 then
				self.failWrites -= 1
				error("store write failed")
			end
			self.values[key] = value
		end
		function store:GetSortedAsync(ascending, pageSize)
			if self.pageFn then
				return self.pageFn()
			end
			if self.failRead then
				error("store read failed")
			end
			local rows = {}
			for key, value in self.values do
				table.insert(rows, { key = key, value = value })
			end
			table.sort(rows, function(a, b)
				return a.value > b.value
			end)
			local page = {}
			for index = 1, math.min(pageSize or #rows, #rows) do
				page[index] = rows[index]
			end
			return {
				GetCurrentPage = function()
					return page
				end,
			}
		end
		return store
	end

	local function makeBoard()
		local env = Env.new()
		local remotes = Fakes.remotes(env)
		local playerData = Fakes.playerData()
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		local LeaderboardService = env:require("server/Social/LeaderboardService")
		local store = makeStore()
		LeaderboardService.bindDataStore(function()
			return store
		end)
		return {
			env = env,
			remotes = remotes,
			playerData = playerData,
			LeaderboardService = LeaderboardService,
			store = store,
			newPlayer = function(lifetimeEarned, raids)
				local player = Fakes.player(env)
				local data = playerData.set(player, Fakes.newData(env))
				data.lifetimeEarned = lifetimeEarned or 0
				data.stats.raids = raids or 0
				return player, data
			end,
		}
	end

	t:describe("LeaderboardService failure paths", function()
		t:it("a nil, errored or malformed page gives an empty board and never throws", function()
			local fx = makeBoard()
			local pageVariants = {
				function()
					return nil
				end,
				function()
					return {
						GetCurrentPage = function()
							error("page broke")
						end,
					}
				end,
				function()
					return {
						GetCurrentPage = function()
							return "page"
						end,
					}
				end,
				function()
					return {
						GetCurrentPage = function()
							return nil
						end,
					}
				end,
			}
			for _, variant in pageVariants do
				fx.LeaderboardService.bindDataStore(function()
					return {
						GetSortedAsync = function()
							return variant()
						end,
					}
				end)
				local ok, rows = pcall(fx.LeaderboardService.fetchCategory, "richest")
				expect(ok):toBe(true)
				expect(#rows):toBe(0)
			end
		end)

		t:it("NaN, infinite, negative and oversized scores are never written", function()
			local fx = makeBoard()
			local cases = {
				{ lifetime = 0 / 0, raids = 0 },
				{ lifetime = math.huge, raids = -math.huge },
				{ lifetime = -500, raids = -3 },
				{ lifetime = 1e13, raids = 0 / 0 },
			}
			for _, case in cases do
				local player = fx.newPlayer(case.lifetime, case.raids)
				fx.LeaderboardService.record(player)
				fx.env:advance(60)
			end
			expect(fx.store.attempts):toBe(0)
			expect(next(fx.store.values)):toBeNil()
		end)

		t:it("a failed write is not cached, so the next record retries the same score", function()
			local fx = makeBoard()
			local player, data = fx.newPlayer(100, 0)
			fx.store.failWrites = 3 -- all three SetAsync tries fail
			fx.LeaderboardService.record(player)
			expect(fx.store.attempts):toBe(3)
			expect(fx.store.values[tostring(player.UserId)]):toBeNil()

			fx.env:advance(40) -- past the 30 second write throttle
			data.lifetimeEarned = 100
			fx.LeaderboardService.record(player)
			expect(fx.store.values[tostring(player.UserId)]):toBe(100)
		end)

		t:it("a write that succeeds on a later try is cached and not written again", function()
			local fx = makeBoard()
			local player = fx.newPlayer(100, 0)
			fx.store.failWrites = 2 -- first two tries fail, the third succeeds
			fx.LeaderboardService.record(player)
			expect(fx.store.attempts):toBe(3)
			expect(fx.store.values[tostring(player.UserId)]):toBe(100)

			fx.env:advance(40)
			fx.LeaderboardService.record(player)
			expect(fx.store.attempts):toBe(3)
		end)

		t:it("a departing player whose save is already gone is skipped without error", function()
			local fx = makeBoard()
			local player, data = fx.newPlayer(100, 0)
			fx.LeaderboardService.record(player, true)
			expect(fx.store.values[tostring(player.UserId)]):toBe(100)

			fx.playerData.get = function()
				return nil
			end
			data.lifetimeEarned = 900
			local ok = pcall(fx.LeaderboardService.record, player, true)
			expect(ok):toBe(true)
			expect(fx.store.values[tostring(player.UserId)]):toBe(100)
		end)

		t:it("refreshing twice with an unchanged store gives the same boards and no duplicate rows", function()
			local fx = makeBoard()
			fx.store.values["2001"] = 50
			fx.store.values["2002"] = 80
			local payloads = {}
			fx.remotes.Leaderboard_Data.FireAllClients = function(_, payload)
				table.insert(payloads, payload)
			end

			fx.LeaderboardService.refresh()
			local first = {}
			for index, row in fx.LeaderboardService.getBoards().richest do
				first[index] = { userId = row.userId, value = row.value }
			end
			fx.LeaderboardService.refresh()

			local second = fx.LeaderboardService.getBoards().richest
			expect(#second):toBe(2)
			expect(#first):toBe(2)
			for index, row in second do
				expect(row.userId):toBe(first[index].userId)
				expect(row.value):toBe(first[index].value)
			end
			expect(#payloads):toBe(2)
		end)

		t:it("one category whose read fails does not blank the other categories", function()
			local fx = makeBoard()
			local raidsStore = makeStore()
			raidsStore.values["3003"] = 4
			local richestStore = makeStore()
			richestStore.failRead = true
			fx.LeaderboardService.bindDataStore(function(category)
				if category == "richest" then
					return richestStore
				end
				return raidsStore
			end)
			fx.LeaderboardService.refresh()
			local boards = fx.LeaderboardService.getBoards()
			expect(#boards.richest):toBe(0)
			expect(#boards.raids):toBe(1)
			expect(boards.raids[1].userId):toBe(3003)
		end)

		t:it("huge player counts: writes every player once and the board keeps only the top ten", function()
			local fx = makeBoard()
			for index = 1, 300 do
				local player = fx.newPlayer(index * 10, 0)
				fx.LeaderboardService.record(player)
			end
			expect(fx.store.attempts):toBe(300)

			fx.LeaderboardService.refresh()
			local rows = fx.LeaderboardService.getBoards().richest
			expect(#rows):toBe(10)
			expect(rows[1].value):toBe(3000)
			expect(rows[10].value):toBe(2910)
			for index = 2, #rows do
				expect(rows[index - 1].value >= rows[index].value):toBe(true)
			end
		end)

		t:it("a non-table entry in a page does not abort the whole refresh", function()
			-- LeaderboardService.luau:160 reads item.key with no guard and refresh() (:172-179) has no
			-- pcall around fetchCategory, so one malformed entry throws out of refresh().
			local fx = makeBoard()
			fx.store.pageFn = function()
				return {
					GetCurrentPage = function()
						return { 5, { key = "4444", value = 7 } }
					end,
				}
			end
			local ok = pcall(fx.LeaderboardService.refresh)
			expect(ok):toBe(true)
		end)

		t:it("a failed refresh keeps the last good board instead of blanking it", function()
			-- LeaderboardService.luau:174 overwrites boards[category] with {} when the read fails, so a
			-- short DataStore outage empties the board for every client until the next good refresh.
			local fx = makeBoard()
			fx.store.values["4242"] = 3
			fx.LeaderboardService.refresh()

			local before = fx.LeaderboardService.getBoards().richest
			expect(#before):toBe(1)
			fx.store.failRead = true
			fx.LeaderboardService.refresh()
			expect(#fx.LeaderboardService.getBoards().richest):toBe(1)
		end)
	end)
end
