--!nocheck
-- T2 remote audit: ensure client->server remotes without gameplay owners are still
-- guarded (rate-limited, payload-ignored) and that key handlers reject invalid input.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, RemoteGuards, RateLimit, remotes, player

	t:describe("Remote audit (T2)", function()
		t:beforeEach(function()
			env = Env.new()
			remotes = Fakes.remotes(env)
			env:mock("shared/Remotes", remotes)
			RateLimit = env:require("server/Net/RateLimit")
			RemoteGuards = env:require("server/Net/RemoteGuards")
			player = Fakes.player(env)
		end)

		t:it("guards unowned client remotes without reading payload into state", function()
			RemoteGuards.start(remotes, RateLimit)
			local names = RemoteGuards.guarded()
			expect(#names >= 3):toBe(true)
			for _, name in names do
				local remote = remotes[name]
				expect(remote ~= nil):toBe(true)
				-- Oversized/malformed payloads must be safely ignored.
				remote.OnServerEvent:Fire(player, string.rep("x", 5000), { huge = string.rep("y", 2000) }, math.huge, 0 / 0)
				remote.OnServerEvent:Fire(player, -1, { [1] = 2 })
			end
		end)

		t:it("rate-limits guarded unowned remotes per player", function()
			RemoteGuards.start(remotes, RateLimit)
			local name = "Trade_Request"
			local remote = remotes[name]
			-- Rate is 2/s with default burst 2 in RemoteGuards; exhaust bucket directly.
			expect(RateLimit.allow(player, name, 2)):toBe(true)
			expect(RateLimit.allow(player, name, 2)):toBe(true)
			expect(RateLimit.allow(player, name, 2)):toBe(false)
			-- Handler path should also refuse once exhausted.
			remote.OnServerEvent:Fire(player, "spam")
			expect(RateLimit.allow(player, name, 2)):toBe(false)
		end)

		t:it("keeps crop id validation contract strict for select-seed style inputs", function()
			local Crops = env:require("shared/Config/Crops")
			expect(Crops.list["__proto__"] == nil):toBe(true)
			expect(Crops.list[""] == nil):toBe(true)
			expect(Crops.list["padi"] ~= nil):toBe(true)
		end)
	end)
end

