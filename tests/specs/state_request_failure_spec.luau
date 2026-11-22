--!nocheck
-- Item 2 (security pass): State_Request is the one C->S remote whose handler had a rate-limit
-- assertion in the static remote audit but no behavioural failure-path spec. The client sends
-- no payload and may ask for its own snapshot only; a flood or a malformed payload must not
-- crash the handler, mutate save data, or send another player's snapshot.

return function(t, Env, Fakes)
	local expect = t.expect

	local function makeState()
		local env = Env.new()
		env.globals.task.spawn = function() end -- State.start() spins a patch loop via task.spawn
		local playerData = Fakes.playerData()
		local remotes = Fakes.remotes(env)
		local sent = {}
		remotes.State_Snapshot.FireClient = function(_, player, snapshot)
			table.insert(sent, { player = player, snapshot = snapshot })
		end
		env:mock("shared/Remotes", remotes)
		env:mock("server/Data/PlayerData", playerData)
		env:mock("server/Net/RateLimit", Fakes.rateLimit(true))

		local State = env:require("server/Net/State")
		local player = Fakes.player(env)
		local data = playerData.set(player, Fakes.newData(env))
		State.start()
		return { env = env, remotes = remotes, playerData = playerData, State = State, player = player, data = data, sent = sent }
	end

	t:describe("State_Request failure paths (item 2 security pass)", function()
		t:it("ignores a malicious payload and sends only the caller's own snapshot", function()
			local fx = makeState()
			local other = Fakes.player(fx.env)
			fx.playerData.set(other, Fakes.newData(fx.env))

			fx.remotes.State_Request.OnServerEvent:Fire(
				fx.player,
				string.rep("x", 5000),
				{ huge = string.rep("y", 2000) },
				math.huge,
				0 / 0
			)
			expect(#fx.sent):toBe(1)
			expect(fx.sent[1].player):toBe(fx.player)
		end)

		t:it("an unloaded player's request sends nothing and never errors", function()
			local fx = makeState()
			local ghost = Fakes.player(fx.env)
			fx.remotes.State_Request.OnServerEvent:Fire(ghost, "anything")
			expect(#fx.sent):toBe(0)
		end)

		t:it("a request flood is rate-limited to one snapshot per second", function()
			local env = Env.new()
			env.globals.task.spawn = function() end
			local playerData = Fakes.playerData()
			local remotes = Fakes.remotes(env)
			local sent = {}
			remotes.State_Snapshot.FireClient = function()
				table.insert(sent, true)
			end
			local rate = { calls = {} }
			function rate.allow(_, key, limit)
				table.insert(rate.calls, key)
				-- Allow only the first call in each one-second window, like RateLimit(1/s).
				if not rate._window or env.now >= rate._window + 1 then
					rate._window = env.now
					rate._allowed = 0
				end
				rate._allowed += 1
				return rate._allowed <= (limit or 1)
			end
			env:mock("shared/Remotes", remotes)
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/RateLimit", rate)

			local State = env:require("server/Net/State")
			local player = Fakes.player(env)
			playerData.set(player, Fakes.newData(env))
			State.start()

			for _ = 1, 20 do
				remotes.State_Request.OnServerEvent:Fire(player)
			end
			expect(#sent):toBe(1)
			expect(rate.calls[1]):toBe("State_Request")

			env:advance(1.5)
			remotes.State_Request.OnServerEvent:Fire(player)
			expect(#sent):toBe(2)
		end)
	end)
end
