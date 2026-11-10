--!nocheck
return function(t, Env, Fakes)
	local expect = t.expect
	local env, RateLimit, player

	t:describe("RateLimit", function()
		t:beforeEach(function()
			env = Env.new()
			RateLimit = env:require("server/Net/RateLimit")
			player = Fakes.player(env)
		end)

		t:it("allows a full burst, then refuses", function()
			expect(RateLimit.allow(player, "act", 2)):toBe(true)
			expect(RateLimit.allow(player, "act", 2)):toBe(true)
			expect(RateLimit.allow(player, "act", 2)):toBe(false)
		end)

		t:it("refills over time at the given rate", function()
			RateLimit.allow(player, "act", 2)
			RateLimit.allow(player, "act", 2)
			expect(RateLimit.allow(player, "act", 2)):toBe(false)
			env:advance(0.5) -- 2/s * 0.5s = 1 token
			expect(RateLimit.allow(player, "act", 2)):toBe(true)
			expect(RateLimit.allow(player, "act", 2)):toBe(false)
		end)

		t:it("never stores more than the burst size", function()
			env:advance(1000)
			expect(RateLimit.allow(player, "act", 1)):toBe(true)
			expect(RateLimit.allow(player, "act", 1)):toBe(false)
		end)

		t:it("honours a larger burst than the refill rate", function()
			for _ = 1, 5 do
				expect(RateLimit.allow(player, "act", 1, 5)):toBe(true)
			end
			expect(RateLimit.allow(player, "act", 1, 5)):toBe(false)
		end)

		t:it("keeps separate buckets per action", function()
			expect(RateLimit.allow(player, "a", 1)):toBe(true)
			expect(RateLimit.allow(player, "a", 1)):toBe(false)
			expect(RateLimit.allow(player, "b", 1)):toBe(true)
		end)

		t:it("keeps separate buckets per player", function()
			local other = Fakes.player(env)
			expect(RateLimit.allow(player, "act", 1)):toBe(true)
			expect(RateLimit.allow(player, "act", 1)):toBe(false)
			expect(RateLimit.allow(other, "act", 1)):toBe(true)
		end)

		t:it("forgets a player who leaves", function()
			expect(RateLimit.allow(player, "act", 1)):toBe(true)
			expect(RateLimit.allow(player, "act", 1)):toBe(false)
			env.services.Players.PlayerRemoving:Fire(player)
			expect(RateLimit.allow(player, "act", 1)):toBe(true)
		end)
	end)
end
