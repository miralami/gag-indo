--!nocheck
-- WORK_QUEUE item 3 (data pass): ProfileStore session locking, the migrate -> SaveSanitize
-- order on load, and DataStore/profile failures at load and at save. The load/release/save
-- paths in PlayerData had no behavioural spec (migrations did). These drive the REAL
-- PlayerData with a fake ProfileStore so no DataStore or real profile is ever touched.

return function(t, Env, Fakes)
	local expect = t.expect

	local function finite(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end

	local function makeWorld()
		local env = Env.new()
		local starts = {}
		local factory = function() return nil end
		local store = {}
		function store.StartSessionAsync(_, key, opts)
			table.insert(starts, { key = key, opts = opts })
			return factory()
		end
		env:mock("server/Packages/ProfileStore", { New = function() return store end })

		local PlayerData = env:require("server/Data/PlayerData")
		local loaded = {}
		PlayerData.onLoaded(function(player, data)
			table.insert(loaded, { player = player, data = data })
		end)
		PlayerData.start()
		return {
			env = env, store = store, PlayerData = PlayerData,
			starts = starts, loaded = loaded,
			setProfile = function(fn) factory = fn end,
		}
	end

	local function makeProfile(env, data)
		local p = {
			Data = data,
			_active = true,
			OnAfterSave = env.newSignal(),
			OnSessionEnd = env.newSignal(),
			addedUsers = {}, reconciled = 0, saves = 0, ended = 0,
		}
		function p:IsActive() return self._active end
		function p:AddUserId(userId) table.insert(self.addedUsers, userId) end
		function p:Reconcile() self.reconciled += 1 end
		function p:Save() self.saves += 1 end
		function p:EndSession()
			self.ended += 1
			self._active = false
			self.OnSessionEnd:Fire()
		end
		return p
	end

	t:describe("Data pass — load / session lock / save failures", function()
		t:it("uses the Studio store key and passes a Cancel that trips on timeout or leave", function()
			local w = makeWorld()
			w.setProfile(function() return nil end)
			local player = Fakes.player(w.env)
			w.env.services.Players.PlayerAdded:Fire(player)

			expect(#w.starts):toBe(1)
			expect(w.starts[1].key):toBe("player_" .. player.UserId)
			expect(type(w.starts[1].opts.Cancel)):toBe("function")
			-- Cancel is false while the player is still present and time is fine.
			expect(w.starts[1].opts.Cancel()):toBe(false)
			player.Parent = nil
			expect(w.starts[1].opts.Cancel()):toBe(true)
		end)

		t:it("migrates then sanitizes on load, before firing the loaded callbacks", function()
			local w = makeWorld()
			local data = Fakes.newData(w.env)
			data.version = 1
			data.cash = 0 / 0 -- damaged: sanitize must repair it after migrate
			local profile = makeProfile(w.env, data)
			w.setProfile(function() return profile end)

			local player = Fakes.player(w.env)
			w.env.services.Players.PlayerAdded:Fire(player)

			expect(data.version):toBe(3)
			expect(finite(data.cash)):toBe(true)
			expect(profile.reconciled):toBe(1) -- Reconcile ran before migrate
			expect(profile.addedUsers[1]):toBe(player.UserId)
			expect(w.PlayerData.get(player)):toBeTruthy()
			expect(#w.loaded):toBe(1)
			expect(w.loaded[1].player):toBe(player)
		end)

		t:it("a failed load (nil profile) kicks the player and registers nothing", function()
			local w = makeWorld()
			w.setProfile(function() return nil end)
			local player = Fakes.player(w.env)
			w.env.services.Players.PlayerAdded:Fire(player)
			expect(player.kicked):toBeTruthy()
			expect(w.PlayerData.get(player)):toBeNil()
			expect(#w.loaded):toBe(0)
		end)

		t:it("a session ending (lost lock / collision) clears the profile and kicks", function()
			local w = makeWorld()
			local profile = makeProfile(w.env, Fakes.newData(w.env))
			w.setProfile(function() return profile end)
			local player = Fakes.player(w.env)
			w.env.services.Players.PlayerAdded:Fire(player)
			expect(w.PlayerData.get(player)):toBeTruthy()

			profile.OnSessionEnd:Fire()
			expect(w.PlayerData.get(player)):toBeNil()
			expect(player.kicked):toBeTruthy()
		end)

		t:it("a player who leaves mid-load ends the session and is never registered", function()
			local w = makeWorld()
			local profile = makeProfile(w.env, Fakes.newData(w.env))
			w.setProfile(function() return profile end)
			local player = Fakes.player(w.env)
			player.Parent = nil -- left while StartSessionAsync was in flight
			w.env.services.Players.PlayerAdded:Fire(player)
			expect(profile.ended):toBe(1)
			expect(w.PlayerData.get(player)):toBeNil()
			expect(#w.loaded):toBe(0)
		end)

		t:it("saveAndConfirm confirms only the matching receipt and fails on save error or timeout", function()
			local w = makeWorld()

			local okProfile = makeProfile(w.env, Fakes.newData(w.env))
			okProfile.Save = function(self)
				self.saves += 1
				self.OnAfterSave:Fire({ receipts = { "R-match" } })
			end
			expect(w.PlayerData.saveAndConfirm(okProfile, "R-match", 1)):toBe(true)

			local errProfile = makeProfile(w.env, Fakes.newData(w.env))
			errProfile.Save = function() error("DataStore down") end
			expect(w.PlayerData.saveAndConfirm(errProfile, "R-match", 1)):toBe(false)

			local quietProfile = makeProfile(w.env, Fakes.newData(w.env))
			quietProfile.Save = function() end
			expect(w.PlayerData.saveAndConfirm(quietProfile, "R-match", 0.3)):toBe(false)
		end)

		-- WORK_QUEUE item 14 mutation S25: dropping the IsActive guard makes an inactive profile
		-- subscribe to OnAfterSave and call Save() before the bounded wait immediately returns false.
		t:it("saveAndConfirm on an inactive profile saves nothing and subscribes to no save event", function()
			local w = makeWorld()
			local profile = makeProfile(w.env, Fakes.newData(w.env))
			profile._active = false
			local connected = 0
			local signal = w.env.newSignal()
			local baseConnect = signal.Connect
			function signal:Connect(fn)
				connected += 1
				return baseConnect(self, fn)
			end
			profile.OnAfterSave = signal
			expect(w.PlayerData.saveAndConfirm(profile, "R-match", 1)):toBe(false)
			expect(connected):toBe(0)
			expect(profile.saves):toBe(0)
		end)

		t:it("release isolates a throwing beforeRelease callback, still ends the session", function()
			local w = makeWorld()
			local profile = makeProfile(w.env, Fakes.newData(w.env))
			w.setProfile(function() return profile end)
			local player = Fakes.player(w.env)
			w.env.services.Players.PlayerAdded:Fire(player)

			local called = false
			w.PlayerData.onBeforeRelease(function() error("boom") end)
			w.PlayerData.onBeforeRelease(function() called = true end)
			w.env.services.Players.PlayerRemoving:Fire(player)

			expect(called):toBe(true)
			expect(profile.ended):toBe(1)
			expect(w.PlayerData.get(player)):toBeNil()
			expect(#w.env.warnings > 0):toBe(true)
		end)
	end)
end
