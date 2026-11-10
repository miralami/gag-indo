--!nocheck
return function(t, Env, Fakes)
	local expect = t.expect
	local env, Game, Law, RankService, notify, analytics, player, data

	t:describe("RankService", function()
		t:beforeEach(function()
			env = Env.new()
			Game = env:require("shared/Config/Game")
			Law = env:require("shared/Config/Law")

			local playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Analytics/Analytics", analytics)
			RankService = env:require("server/Progression/RankService")

			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("refresh", function()
			t:it("keeps a new player at the first rank", function()
				RankService.refresh(player)
				expect(data.rank):toBe("gurem")
				expect(player:GetAttribute("Rank")):toBe("gurem")
			end)

			t:it("promotes to petani once lifetime income is enough", function()
				data.lifetimeEarned = Game.rankRequirements.petani.lifetimeEarned
				RankService.refresh(player)
				expect(data.rank):toBe("petani")
				expect(notify.keys(player)):toContain("n_rank_up")
				expect(analytics.events[1].name):toBe("rank_up")
			end)

			t:it("does not promote one coin short", function()
				data.lifetimeEarned = Game.rankRequirements.petani.lifetimeEarned - 1
				RankService.refresh(player)
				expect(data.rank):toBe("gurem")
			end)

			t:it("needs the tiles as well as the income for juragan", function()
				data.lifetimeEarned = Game.rankRequirements.juragan.lifetimeEarned
				data.tilesOwned = Game.rankRequirements.juragan.tilesOwned - 1
				RankService.refresh(player)
				expect(data.rank):toBe("petani")
				data.tilesOwned = Game.rankRequirements.juragan.tilesOwned
				RankService.refresh(player)
				expect(data.rank):toBe("juragan")
			end)

			t:it("can promote several ranks in one refresh", function()
				data.lifetimeEarned = Game.rankRequirements.juragan.lifetimeEarned
				data.tilesOwned = Game.rankRequirements.juragan.tilesOwned
				RankService.refresh(player)
				expect(data.rank):toBe("juragan")
			end)

			t:it("never demotes", function()
				data.rank = "juragan"
				data.lifetimeEarned = 0
				data.tilesOwned = 0
				RankService.refresh(player)
				expect(data.rank):toBe("juragan")
			end)

			t:it("does nothing for a player without loaded data", function()
				RankService.refresh(Fakes.player(env))
			end)
		end)

		t:describe("addNamaBaik", function()
			t:it("adds points and mirrors them to the attribute", function()
				expect(RankService.addNamaBaik(player, 5)):toBe(5)
				expect(data.namaBaik):toBe(Law.namaBaikStart + 5)
				expect(player:GetAttribute("NamaBaik")):toBe(Law.namaBaikStart + 5)
			end)

			t:it("clamps to the maximum", function()
				RankService.addNamaBaik(player, 9999)
				expect(RankService.getNamaBaik(player)):toBe(Law.namaBaikMax)
			end)

			t:it("clamps to zero", function()
				RankService.addNamaBaik(player, -9999)
				expect(RankService.getNamaBaik(player)):toBe(0)
			end)

			t:it("ignores zero and non-number amounts", function()
				expect(RankService.addNamaBaik(player, 0)):toBe(0)
				expect(RankService.addNamaBaik(player, "5")):toBe(0)
				expect(data.namaBaik):toBe(Law.namaBaikStart)
			end)

			t:it("stops paying out once the daily report cap is reached", function()
				local total = 0
				for _ = 1, Law.namaBaikReportDailyCap + 5 do
					total += RankService.addNamaBaik(player, 1, "report")
				end
				expect(total):toBe(Law.namaBaikReportDailyCap)
			end)

			t:it("tracks the report and water caps separately", function()
				RankService.addNamaBaik(player, Law.namaBaikReportDailyCap, "report")
				expect(RankService.addNamaBaik(player, 1, "report")):toBe(0)
				expect(RankService.addNamaBaik(player, 1, "water")):toBe(1)
			end)

			t:it("resets the daily cap on the next day", function()
				RankService.addNamaBaik(player, Law.namaBaikReportDailyCap, "report")
				expect(RankService.addNamaBaik(player, 1, "report")):toBe(0)
				env:advance(86400)
				expect(RankService.addNamaBaik(player, 1, "report")):toBe(1)
			end)

			t:it("only caps gains, not penalties", function()
				RankService.addNamaBaik(player, Law.namaBaikReportDailyCap, "report")
				expect(RankService.addNamaBaik(player, -5, "report")):toBe(-5)
			end)
		end)

		t:describe("getRankLabel", function()
			t:it("shows the Indonesian label and falls back to the id", function()
				expect(RankService.getRankLabel("gurem")):toBe("Petani Gurem")
				expect(RankService.getRankLabel("mystery")):toBe("mystery")
			end)
		end)
	end)
end
