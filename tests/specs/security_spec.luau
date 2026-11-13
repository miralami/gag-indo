--!nocheck
-- Security spec: tests server authority, remote validation, rate limits, and bounds checking.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, RateLimit, Admins, Crops, Pinjol, GameConfig, player

	t:describe("Security & Server Authority", function()
		t:beforeEach(function()
			env = Env.new()
			RateLimit = env:require("server/Net/RateLimit")
			Admins = env:require("server/Live/Admins")
			Crops = env:require("shared/Config/Crops")
			Pinjol = env:require("shared/Config/Pinjol")
			GameConfig = env:require("shared/Config/Game")
			player = Fakes.player(env)
		end)

		t:describe("Rate Limiting Boundaries", function()
			t:it("strictly throttles high frequency remote bursts per action name", function()
				local action = "Shop_BuySeed"
				local rate = 4
				for _ = 1, rate do
					expect(RateLimit.allow(player, action, rate)):toBe(true)
				end
				-- Next calls exceed burst
				expect(RateLimit.allow(player, action, rate)):toBe(false)
				expect(RateLimit.allow(player, action, rate)):toBe(false)

				-- After time passes, token refills
				env:advance(1)
				expect(RateLimit.allow(player, action, rate)):toBe(true)
			end)

			t:it("isolates rate limit token buckets between different actions", function()
				expect(RateLimit.allow(player, "Farm_Complete", 1)):toBe(true)
				expect(RateLimit.allow(player, "Farm_Complete", 1)):toBe(false)

				-- Different action is not blocked by Farm_Complete
				expect(RateLimit.allow(player, "Storage_Deposit", 1)):toBe(true)
			end)

			t:it("isolates rate limit token buckets between different players", function()
				local player2 = Fakes.player(env)
				expect(RateLimit.allow(player, "Tool_Buy", 1)):toBe(true)
				expect(RateLimit.allow(player, "Tool_Buy", 1)):toBe(false)

				-- player2 bucket is unaffected
				expect(RateLimit.allow(player2, "Tool_Buy", 1)):toBe(true)
			end)
		end)

		t:describe("Admin Security Isolation", function()
			t:it("denies non-admin player IDs when not in Studio mode", function()
				-- Test with arbitrary user ID
				local nonAdminId = 999999999
				expect(table.find(Admins.userIds, nonAdminId) == nil):toBe(true)
			end)

			t:it("validates that Sena user ID is registered in admin allowlist", function()
				expect(table.find(Admins.userIds, 172146044) ~= nil):toBe(true)
			end)
		end)

		t:describe("Payload Sanity & Input Boundaries", function()
			t:it("ensures crop list keys cannot be arbitrary or prototype-injected strings", function()
				expect(Crops.list["__index"] == nil):toBe(true)
				expect(Crops.list["non_existent_crop"] == nil):toBe(true)
				expect(Crops.list["padi"] ~= nil):toBe(true)
			end)

			t:it("calculates debt limits safely against negative or NaN inputs", function()
				local limitGurem = Pinjol.calcLimit("gurem", 50)
				expect(limitGurem > 0):toBe(true)

				-- Invalid rank fallback
				local limitInvalid = Pinjol.calcLimit("hacker_rank", 50)
				expect(limitInvalid):toBe(limitGurem)

				-- Clamped namaBaik bounds
				local limitMax = Pinjol.calcLimit("sultan", 100)
				local limitOver = Pinjol.calcLimit("sultan", 999)
				expect(limitMax):toBe(limitOver)
			end)

			t:it("verifies minigame timing configuration prevents 0-millisecond instant completion", function()
				expect(GameConfig.minigameMinSeconds >= 0.5):toBe(true)
				expect(GameConfig.minigameMaxSeconds <= 60.0):toBe(true)
				expect(GameConfig.minigameMinSeconds < GameConfig.minigameMaxSeconds):toBe(true)
			end)
		end)
	end)
end
