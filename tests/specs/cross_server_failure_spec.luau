--!nocheck
-- WORK_QUEUE item 15: cross-server and leaderboard failures. OrderedDataStore backoff and
-- last-good fallback are already locked by leaderboard_spec + cosmetics_leaderboard_failure_spec;
-- this file covers the untested half: LiveConfig's DataStore and MessagingService failure paths,
-- plus the write-throttle budget surviving a failed burst. No MemoryStore exists in src/, so there
-- is no MemoryStore path to spec (see the item 15 evidence report).
--
-- LiveConfig is a singleton per require, so every case builds a fresh Env. Its start() owns an
-- infinite 60 s poll loop; the harness makes task.spawn synchronous, so a throwing task.wait
-- sentinel stops the loop after subscribe() has been captured (no real waiting, no real services).

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeWorld()
		local env = Env.new()

		local store = { reads = 0, writes = 0, raw = nil, readError = false, writeError = false }
		function store:GetAsync(_)
			self.reads += 1
			if self.readError then
				error("DataStore read down")
			end
			return self.raw
		end
		function store:SetAsync(_, value)
			self.writes += 1
			if self.writeError then
				error("DataStore write down")
			end
			self.raw = value
		end
		env.services.DataStoreService = {
			GetDataStore = function()
				return store
			end,
		}

		local messaging = { published = {}, subs = {}, publishError = false, subscribeError = false }
		function messaging:PublishAsync(topic, message)
			if self.publishError then
				error("MessagingService publish down")
			end
			table.insert(self.published, { topic = topic, message = message })
		end
		function messaging:SubscribeAsync(topic, callback)
			if self.subscribeError then
				error("MessagingService subscribe down")
			end
			table.insert(self.subs, { topic = topic, callback = callback })
			return { Disconnect = function() end }
		end
		env.services.MessagingService = messaging

		local LiveConfig = env:require("server/Live/LiveConfig")
		local w = { env = env, store = store, messaging = messaging, LiveConfig = LiveConfig }

		function w:start()
			local realWait = env.globals.task.wait
			local waits = 0
			env.globals.task.wait = function()
				waits += 1
				if waits >= 2 then
					error("__STOP_POLL_LOOP__")
				end
				return 60
			end
			local ok, err = pcall(LiveConfig.start)
			env.globals.task.wait = realWait
			-- The sentinel is how we stop the infinite poll loop in this synchronous harness;
			-- it is not a real failure. Any other error must still surface.
			if not ok and type(err) == "string" and err:find("__STOP_POLL_LOOP__", 1, true) then
				return true
			end
			return ok, err
		end

		function w:receive(data)
			expect(#self.messaging.subs):toBeGreaterThan(0)
			self.messaging.subs[1].callback({ Data = data, SentTime = self.env.wallTime })
		end

		return w
	end

	t:describe("LiveConfig cross-server failures (item 15)", function()
		t:it("a DataStore read error never throws and keeps the shipped defaults", function()
			local w = makeWorld()
			w.store.readError = true
			expect(w:start()):toBe(true)
			expect(w.LiveConfig.getRuntime().seasonSource):toBe("calendar")
			expect(w.LiveConfig.getRuntime().anomali):toBe("none")
			expect(w.LiveConfig.getRuntime().events.cabai):toBe("auto")
		end)

		t:it("a DataStore write error keeps the local change and never throws", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w.store.writeError = true
			local ok, config = pcall(w.LiveConfig.update, { seasonOverride = "kemarau" })
			expect(ok):toBe(true)
			expect(config.seasonOverride):toBe("kemarau")
			expect(w.LiveConfig.getRuntime().seasonSource):toBe("override")
			expect(w.store.raw):toBeNil() -- nothing was persisted, but the server keeps working
			-- A later successful write still lands; the failed one did not poison the document.
			w.store.writeError = false
			w.LiveConfig.update({ anomaly = "laNina" })
			expect(w.store.raw.anomaly):toBe("laNina")
			expect(w.store.raw.seasonOverride):toBe("kemarau")
		end)

		t:it("a MessagingService publish error never throws; the local change still applies", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w.messaging.publishError = true
			local ok = pcall(w.LiveConfig.update, { seasonOverride = "kemarau" })
			expect(ok):toBe(true)
			expect(w.LiveConfig.get().seasonOverride):toBe("kemarau")
			expect(w.LiveConfig.getRuntime().musim):toBe("kemarau")
			expect(#w.messaging.published):toBe(0)
		end)

		t:it("a MessagingService subscribe error never throws; local updates still work", function()
			local w = makeWorld()
			w.messaging.subscribeError = true
			expect(w:start()):toBe(true)
			expect(#w.messaging.subs):toBe(0)
			local ok = pcall(w.LiveConfig.update, { anomaly = "elNino" })
			expect(ok):toBe(true)
			expect(w.LiveConfig.getRuntime().anomali):toBe("elNino")
		end)

		t:it("a malformed incoming message is sanitized and never wipes the last good config", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w.LiveConfig.update({ seasonOverride = "kemarau", anomaly = "laNina", priceMultipliers = { padi = 2 } })

			w:receive({ seasonOverride = "kiamat", anomaly = "bogus", priceMultipliers = { jagung = "x" }, updatedAt = "bad" })
			w:receive(nil)
			w:receive({ Data = nil })

			local config = w.LiveConfig.get()
			expect(config.seasonOverride):toBe("kemarau")
			expect(config.anomaly):toBe("laNina")
			expect(config.priceMultipliers.padi):toBe(2)
			expect(config.priceMultipliers.jagung):toBeNil()
			expect(w.LiveConfig.getRuntime().musim):toBe("kemarau")
		end)

		t:it("a stale message delivered after a newer one does not roll the config back", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w:receive({ seasonOverride = "kemarau", updatedAt = 200 })
			expect(w.LiveConfig.get().seasonOverride):toBe("kemarau")
			-- MessagingService does not guarantee ordering: an older publish can arrive late.
			w:receive({ seasonOverride = "hujan", updatedAt = 100 })
			expect(w.LiveConfig.get().seasonOverride):toBe("kemarau")
			expect(w.LiveConfig.getRuntime().musim):toBe("kemarau")
			-- A genuinely newer change is still accepted.
			w:receive({ seasonOverride = "hujan", updatedAt = 300 })
			expect(w.LiveConfig.get().seasonOverride):toBe("hujan")
		end)

		t:it("a non-finite or negative updatedAt cannot freeze the config", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w:receive({ seasonOverride = "kemarau", updatedAt = 100 })
			-- Corrupt timestamps must never be stored as current.updatedAt. In particular
			-- math.huge would make every later finite message look stale and freeze the config.
			for _, bad in { 0 / 0, -math.huge, -5, math.huge } do
				w:receive({ seasonOverride = "hujan", updatedAt = bad })
			end
			expect(w.LiveConfig.get().seasonOverride):toBe("hujan")
			-- A real, finite newer timestamp must still win after the corrupt ones.
			w:receive({ seasonOverride = "pancaroba", updatedAt = 200 })
			expect(w.LiveConfig.get().seasonOverride):toBe("pancaroba")
		end)

		t:it("a stale DataStore poll cannot roll back a newer config", function()
			local w = makeWorld()
			expect(w:start()):toBe(true)
			w.LiveConfig.update({ seasonOverride = "kemarau" })
			local newer = w.LiveConfig.get().updatedAt
			-- Simulate an eventually-consistent replica still serving an older document.
			w.store.raw = {
				seasonOverride = "hujan",
				anomaly = "none",
				cuacaOverride = "auto",
				priceMultipliers = {},
				features = {},
				events = { cabai = "auto" },
				updatedAt = newer - 100,
			}
			w.LiveConfig.refresh() -- spawn(load) runs synchronously in the harness
			expect(w.LiveConfig.get().seasonOverride):toBe("kemarau")
			expect(w.LiveConfig.getRuntime().musim):toBe("kemarau")
		end)
	end)

	t:describe("OrderedDataStore write budget under failure (item 15)", function()
		t:it("a failed write burst stays inside the retry cap and the per-player throttle", function()
			local env = Env.new()
			local playerData = Fakes.playerData()
			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			local LeaderboardService = env:require("server/Social/LeaderboardService")
			local attempts = 0
			LeaderboardService.bindDataStore(function()
				return {
					SetAsync = function()
						attempts += 1
						error("OrderedDataStore down")
					end,
				}
			end)
			local player = Fakes.player(env)
			local data = playerData.set(player, Fakes.newData(env))
			data.lifetimeEarned = 5000

			LeaderboardService.record(player)
			expect(attempts):toBe(3) -- MAX_ATTEMPTS, no unbounded retry storm
			LeaderboardService.record(player) -- same throttle window
			expect(attempts):toBe(3) -- a failed burst does not bypass the budget
			env:advance(40)
			LeaderboardService.record(player) -- a later window may retry
			expect(attempts):toBe(6)
		end)
	end)
end
