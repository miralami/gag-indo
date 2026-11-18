--!nocheck
-- WORK_QUEUE item 11: rank_spec covered promotion and Nama Baik accounting but not a damaged
-- saved value. RankService already guards NaN/non-number Nama Baik and a damaged cooldown table;
-- these cases lock those recovery paths so a corrupt save can never publish NaN or lose the cap.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Law, RankService, playerData, notify, analytics, player, data

	t:describe("RankService damaged-data failure paths (item 11)", function()
		t:beforeEach(function()
			env = Env.new()
			Law = env:require("shared/Config/Law")
			playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Analytics/Analytics", analytics)
			RankService = env:require("server/Progression/RankService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("reads a damaged saved Nama Baik as the starting value", function()
			data.namaBaik = 0 / 0
			expect(RankService.getNamaBaik(player)):toBe(Law.namaBaikStart)
			data.namaBaik = "broken"
			expect(RankService.getNamaBaik(player)):toBe(Law.namaBaikStart)
		end)

		t:it("never mirrors a NaN Nama Baik to the attribute", function()
			data.namaBaik = 0 / 0
			RankService.sync(player)
			expect(player:GetAttribute("NamaBaik")):toBe(Law.namaBaikStart)
		end)

		t:it("recovers from a NaN Nama Baik when points are added", function()
			data.namaBaik = 0 / 0
			local applied = RankService.addNamaBaik(player, 5)
			expect(applied):toBe(5)
			expect(data.namaBaik):toBe(Law.namaBaikStart + 5)
		end)

		t:it("rebuilds a damaged cooldowns table before applying a daily cap", function()
			data.cooldowns = "broken"
			local applied = RankService.addNamaBaik(player, 3, "report")
			expect(applied):toBe(3)
			expect(type(data.cooldowns)):toBe("table")
			expect(data.cooldowns.nbCount_report):toBe(3)
		end)
	end)
end
