--!nocheck
-- Papan Desa (v2 PLAN §3.6): shared scoring rules + the server OrderedDataStore wrapper.
--
-- Two layers are tested separately:
--   * shared/Leaderboard is pure, so it pins sanitising, tie-breaks and the payload guard.
--   * server/Social/LeaderboardService talks to a fake OrderedDataStore: writes are throttled,
--     failures never crash the server, and the client never supplies a score.

return function(t, Env, Fakes)
	local expect = t.expect

	t:describe("Leaderboard", function()
		local env, Leaderboard

		t:beforeEach(function()
			env = Env.new()
			Leaderboard = env:require("shared/Leaderboard")
		end)

		t:describe("sanitizeValue", function()
			t:it("keeps whole positive numbers", function()
				expect(Leaderboard.sanitizeValue(1)):toBe(1)
				expect(Leaderboard.sanitizeValue(4200)):toBe(4200)
				expect(Leaderboard.sanitizeValue(12.9)):toBe(12)
			end)

			t:it("drops zero, negatives, NaN and infinity", function()
				expect(Leaderboard.sanitizeValue(0)):toBeNil()
				expect(Leaderboard.sanitizeValue(-5)):toBeNil()
				expect(Leaderboard.sanitizeValue(0 / 0)):toBeNil()
				expect(Leaderboard.sanitizeValue(math.huge)):toBeNil()
				expect(Leaderboard.sanitizeValue(-math.huge)):toBeNil()
			end)

			t:it("drops non-numbers and absurd values", function()
				expect(Leaderboard.sanitizeValue("100")):toBeNil()
				expect(Leaderboard.sanitizeValue(nil)):toBeNil()
				expect(Leaderboard.sanitizeValue({})):toBeNil()
				expect(Leaderboard.sanitizeValue(Leaderboard.maxValue + 1)):toBeNil()
			end)
		end)

		t:describe("sanitizeName", function()
			t:it("trims surrounding whitespace", function()
				expect(Leaderboard.sanitizeName("  Tani  ")):toBe("Tani")
			end)

			t:it("drops empty names and non-strings", function()
				expect(Leaderboard.sanitizeName("   ")):toBeNil()
				expect(Leaderboard.sanitizeName(nil)):toBeNil()
				expect(Leaderboard.sanitizeName(42)):toBeNil()
			end)

			t:it("caps the length so one row cannot stretch the panel", function()
				local long = string.rep("a", Leaderboard.maxNameLength + 20)
				expect(#Leaderboard.sanitizeName(long)):toBe(Leaderboard.maxNameLength)
			end)
		end)

		t:describe("sort", function()
			t:it("orders by value descending", function()
				local rows = Leaderboard.sort({
					{ userId = 1, name = "a", value = 10 },
					{ userId = 2, name = "b", value = 30 },
					{ userId = 3, name = "c", value = 20 },
				})
				expect(rows[1].userId):toBe(2)
				expect(rows[2].userId):toBe(3)
				expect(rows[3].userId):toBe(1)
			end)

			t:it("breaks ties on the lower UserId so every client agrees", function()
				local rows = Leaderboard.sort({
					{ userId = 900, name = "late", value = 50 },
					{ userId = 100, name = "early", value = 50 },
				})
				expect(rows[1].userId):toBe(100)
				expect(rows[2].userId):toBe(900)
			end)

			t:it("drops broken rows instead of clamping them", function()
				local rows = Leaderboard.sort({
					{ userId = 1, name = "ok", value = 10 },
					{ userId = 0, name = "no id", value = 999 },
					{ userId = 2, name = "", value = 999 },
					{ userId = 3, name = "negative", value = -1 },
					{ userId = 4, name = "string", value = "999" },
					"not a row",
				})
				expect(#rows):toBe(1)
				expect(rows[1].name):toBe("ok")
			end)

			t:it("accepts a nil list", function()
				expect(#Leaderboard.sort(nil)):toBe(0)
			end)
		end)

		t:describe("top", function()
			t:it("keeps at most topCount rows by default", function()
				local rows = {}
				for index = 1, Leaderboard.topCount + 5 do
					rows[index] = { userId = index, name = "p" .. index, value = index }
				end
				local top = Leaderboard.top(rows)
				expect(#top):toBe(Leaderboard.topCount)
				expect(top[1].value):toBe(Leaderboard.topCount + 5)
			end)

			t:it("honours an explicit count", function()
				local rows = {}
				for index = 1, 5 do
					rows[index] = { userId = index, name = "p" .. index, value = index }
				end
				expect(#Leaderboard.top(rows, 2)):toBe(2)
				expect(#Leaderboard.top(rows, 0)):toBe(0)
			end)
		end)

		t:describe("validatePayload", function()
			t:it("returns sanitised boards for a good payload", function()
				local boards = Leaderboard.validatePayload({
					richest = {
						{ userId = 2, name = "b", value = 20 },
						{ userId = 1, name = "a", value = 10 },
					},
					sultan = {},
					raids = { { userId = 3, name = "c", value = 1 } },
				})
				expect(boards):toBeTruthy()
				expect(boards.richest[1].userId):toBe(2)
				expect(#boards.raids):toBe(1)
				expect(#boards.sultan):toBe(0)
			end)

			t:it("fills missing categories with empty boards", function()
				local boards = Leaderboard.validatePayload({ richest = {} })
				expect(boards):toBeTruthy()
				for _, category in Leaderboard.categories do
					expect(boards[category]):toBeTruthy()
				end
			end)

			t:it("rejects non-tables, empty payloads and wrong category types", function()
				expect(Leaderboard.validatePayload(nil)):toBeNil()
				expect(Leaderboard.validatePayload("boards")):toBeNil()
				expect(Leaderboard.validatePayload({})):toBeNil()
				expect(Leaderboard.validatePayload({ richest = "nope" })):toBeNil()
			end)
		end)

		t:describe("emptyBoards", function()
			t:it("has one empty list per category", function()
				local boards = Leaderboard.emptyBoards()
				for _, category in Leaderboard.categories do
					expect(#boards[category]):toBe(0)
				end
			end)
		end)
	end)

	t:describe("LeaderboardService", function()
		local env, LeaderboardService, player, data, playerData, stores, remotes

		local function fakeStore()
			local store = { writes = {}, values = {} }
			function store:SetAsync(key, value)
				table.insert(self.writes, { key = key, value = value })
				self.values[key] = value
			end
			function store:GetSortedAsync(ascending, pageSize)
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

		local function setup(options)
			options = options or {}
			env = Env.new()
			remotes = Fakes.remotes(env)
			env:mock("shared/Remotes", remotes)
			stores = {}
			if not options.noStore then
				env.services.DataStoreService = {
					GetOrderedDataStore = function(_, name)
						stores[name] = stores[name] or fakeStore()
						return stores[name]
					end,
				}
				for _, category in { "richest", "sultan", "raids" } do
					stores["Leaderboard_" .. category] = fakeStore()
				end
			end
			playerData = Fakes.playerData()
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
			env:mock("server/Data/PlayerData", playerData)
			if options.nameError then
				env.services.Players.GetNameFromUserIdAsync = function()
					error("name lookup failed")
				end
			end
			LeaderboardService = env:require("server/Social/LeaderboardService")
			LeaderboardService.bindDataStore(function(category)
				return env.services.DataStoreService:GetOrderedDataStore("Leaderboard_" .. category)
			end)
			return LeaderboardService
		end

		t:beforeEach(function()
			setup()
		end)

		t:it("starts with empty boards cache", function()
			local boards = LeaderboardService.getBoards()
			expect(boards.richest):toBeTruthy()
			expect(boards.sultan):toBeTruthy()
			expect(boards.raids):toBeTruthy()
			expect(#boards.richest):toBe(0)
		end)

		t:it("safely handles record call for a player", function()
			data.lifetimeEarned = 5000
			LeaderboardService.record(player)
		end)

		t:it("writes each score from save data, never from a client", function()
			data.lifetimeEarned = 5000
			data.stats.raids = 4
			data.almanak = {
				crops = {
					padi = { tiers = { sultan = 2 } },
					jagung = { tiers = { biasa = 1 } },
				},
			}
			LeaderboardService.record(player)
			local userId = tostring(player.UserId)
			expect(stores.Leaderboard_richest.values[userId]):toBe(5000)
			expect(stores.Leaderboard_raids.values[userId]):toBe(4)
			expect(stores.Leaderboard_sultan.values[userId]):toBe(1)
		end)

		t:it("reads raidsCaught when the newer stat exists", function()
			data.stats.raids = 2
			data.stats.raidsCaught = 7
			LeaderboardService.record(player)
			expect(stores.Leaderboard_raids.values[tostring(player.UserId)]):toBe(7)
		end)

		t:it("does not write zero scores, so an empty save keeps no board row", function()
			data.lifetimeEarned = 0
			LeaderboardService.record(player)
			expect(#(stores.Leaderboard_richest or { writes = {} }).writes):toBe(0)
		end)

		t:it("throttles repeat writes for one player", function()
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			expect(#stores.Leaderboard_richest.writes):toBe(1)

			env:advance(10)
			data.lifetimeEarned = 200
			LeaderboardService.record(player)
			expect(#stores.Leaderboard_richest.writes):toBe(1)

			env:advance(25)
			LeaderboardService.record(player)
			expect(#stores.Leaderboard_richest.writes):toBe(2)
		end)

		t:it("force skips the throttle so the last score is not lost", function()
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			data.lifetimeEarned = 200
			LeaderboardService.record(player, true)
			expect(#stores.Leaderboard_richest.writes):toBe(2)
			expect(stores.Leaderboard_richest.values[tostring(player.UserId)]):toBe(200)
		end)

		t:it("skips a write when the value has not changed", function()
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			env:advance(60)
			LeaderboardService.record(player)
			expect(#stores.Leaderboard_richest.writes):toBe(1)
		end)

		t:it("ignores a player with no save data", function()
			local stranger = Fakes.player(env)
			LeaderboardService.record(stranger)
			expect(#(stores.Leaderboard_richest or { writes = {} }).writes):toBe(0)
		end)

		t:it("ignores a non-positive UserId", function()
			player.UserId = 0
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			expect(#(stores.Leaderboard_richest or { writes = {} }).writes):toBe(0)
		end)

		t:it("survives a dead store and retries a bounded number of times", function()
			local attempts = 0
			LeaderboardService.bindDataStore(function()
				return {
					SetAsync = function()
						attempts += 1
						error("store down")
					end,
				}
			end)
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			expect(attempts):toBe(3)
		end)

		t:it("survives a store provider that throws", function()
			LeaderboardService.bindDataStore(function()
				error("no store")
			end)
			data.lifetimeEarned = 100
			LeaderboardService.record(player)
			expect(LeaderboardService.getBoards().richest):toBeTruthy()
		end)

		t:it("fetches rows with display names, sorted and capped", function()
			local store = stores.Leaderboard_richest
			store.values["2000"] = 50
			store.values["1000"] = 50
			store.values["3000"] = 90
			local rows = LeaderboardService.fetchCategory("richest")
			expect(#rows):toBe(3)
			expect(rows[1].userId):toBe(3000)
			expect(rows[2].userId):toBe(1000)
			expect(rows[3].userId):toBe(2000)
			expect(rows[1].name):toBe("User3000")
		end)

		t:it("falls back to an anonymous name when lookup fails", function()
			setup({ nameError = true })
			stores.Leaderboard_richest.values["1234"] = 10
			local rows = LeaderboardService.fetchCategory("richest")
			expect(#rows):toBe(1)
			expect(rows[1].name):toBe("Warga #1.234")
		end)

		t:it("drops rows with a broken key or value", function()
			local store = stores.Leaderboard_richest
			store.values["not-a-user"] = 10
			store.values["1234"] = -5
			store.values["5678"] = 20
			local rows = LeaderboardService.fetchCategory("richest")
			expect(#rows):toBe(1)
			expect(rows[1].userId):toBe(5678)
		end)

		t:it("returns an empty board when there is no store", function()
			setup({ noStore = true })
			expect(#LeaderboardService.fetchCategory("richest")):toBe(0)
		end)

		t:it("returns an empty board when GetSortedAsync fails", function()
			LeaderboardService.bindDataStore(function()
				return {
					GetSortedAsync = function()
						error("read failed")
					end,
				}
			end)
			expect(#LeaderboardService.fetchCategory("richest")):toBe(0)
		end)

		t:it("refresh fills the cache and pushes it to clients", function()
			local pushed = {}
			remotes.Leaderboard_Data.FireAllClients = function(_, payload)
				pushed = payload
			end
			stores.Leaderboard_raids.values["4242"] = 3
			LeaderboardService.refresh()
			local boards = LeaderboardService.getBoards()
			expect(#boards.raids):toBe(1)
			expect(boards.raids[1].value):toBe(3)
			expect(pushed.raids[1].userId):toBe(4242)
		end)
	end)
end
