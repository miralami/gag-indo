--!nocheck
return function(t, Env, Fakes)
	local expect = t.expect
	local env, FirstSession, FirstSessionConfig
	local playerData, notify, analytics, player, data

	t:describe("FirstSession", function()
		t:beforeEach(function()
			env = Env.new()
			FirstSessionConfig = env:require("shared/Config/FirstSession")

			playerData = Fakes.playerData()
			notify = Fakes.notify()
			analytics = Fakes.analytics()

			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)
			env:mock("server/Analytics/Analytics", analytics)

			FirstSession = env:require("server/Progression/FirstSession")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:it("returns 20 for tutorial padi growSeconds for new player", function()
			expect(FirstSession.getGrowSeconds(player, "padi", data)):toBe(20)
		end)

		t:it("returns 60 for regular padi growSeconds after first harvest or when finished", function()
			data.stats.harvests = 1
			expect(FirstSession.getGrowSeconds(player, "padi", data)):toBe(60)

			data.stats.harvests = 0
			data.tutorial.step = 5
			expect(FirstSession.getGrowSeconds(player, "padi", data)):toBe(60)
		end)

		t:it("returns bagus for harvest 1", function()
			local tier = FirstSession.getHarvestTier(player, data, "biasa")
			expect(tier):toBe("bagus")
			expect(data.stats.harvests):toBe(1)
		end)

		t:it("returns super for harvest 2", function()
			data.stats.harvests = 1
			local tier = FirstSession.getHarvestTier(player, data, "biasa")
			expect(tier):toBe("super")
			expect(data.stats.harvests):toBe(2)
		end)

		t:it("returns normal rolled tier for harvest 3", function()
			data.stats.harvests = 2
			local tier = FirstSession.getHarvestTier(player, data, "biasa")
			expect(tier):toBe("biasa")
			expect(data.stats.harvests):toBe(3)
		end)

		t:it("fires Sus explanation once on first Sus increase and sets flag", function()
			FirstSession.onSusChanged(player, 15, 0)
			expect(data.story.flags["sus_explained"]):toBe(true)
			expect(notify.keys(player)):toContain("sus_explain")

			local prevCount = #notify.keys(player)
			FirstSession.onSusChanged(player, 25, 15)
			expect(#notify.keys(player)):toBe(prevCount)
		end)

		t:it("triggers BayarLater offer at threshold or when onboarding finished and sets flag", function()
			FirstSession.tick(player, 100)
			expect(data.story.flags["beat_bayarlater"]):toBeFalsy()

			FirstSession.tick(player, 150)
			expect(data.story.flags["beat_bayarlater"]):toBe(true)
			expect(notify.keys(player)):toContain("bayarlater_offer")
			expect(analytics.funnelSteps[1].funnel):toBe("first_session")
			expect(analytics.funnelSteps[1].step):toBe(5)
			expect(analytics.funnelSteps[1].name):toBe("bayarlater_offer")

			-- Test onboarding finished path
			local player2 = Fakes.player(env)
			local data2 = playerData.set(player2, Fakes.newData(env))
			data2.tutorial.step = 5
			FirstSession.tick(player2, 10)
			expect(data2.story.flags["beat_bayarlater"]):toBe(true)
			expect(notify.keys(player2)):toContain("bayarlater_offer")
		end)

		t:it("triggers Scripted raid gossip at 330s and sets flag", function()
			FirstSession.tick(player, 300)
			expect(data.story.flags["beat_scripted_raid"]):toBeFalsy()

			FirstSession.tick(player, 330)
			expect(data.story.flags["beat_scripted_raid"]):toBe(true)
			expect(notify.keys(player)):toContain("scripted_raid_gossip")
			local last = analytics.funnelSteps[#analytics.funnelSteps]
			expect(last.funnel):toBe("first_session")
			expect(last.step):toBe(7)
			expect(last.name):toBe("scripted_raid")
		end)

		t:it("triggers Warung rumour at 420s and sets flag", function()
			FirstSession.tick(player, 400)
			expect(data.story.flags["beat_warung_rumour"]):toBeFalsy()

			FirstSession.tick(player, 420)
			expect(data.story.flags["beat_warung_rumour"]):toBe(true)
			expect(notify.keys(player)):toContain("warung_rumour")
			local last = analytics.funnelSteps[#analytics.funnelSteps]
			expect(last.funnel):toBe("first_session")
			expect(last.step):toBe(8)
			expect(last.name):toBe("warung_rumour")
		end)

		t:it("triggers Rank-up ceremony for petani and sets flag", function()
			FirstSession.onRankUp(player, "gurem")
			expect(data.story.flags["beat_ceremony"]):toBeFalsy()

			FirstSession.onRankUp(player, "petani")
			expect(data.story.flags["beat_ceremony"]):toBe(true)
			expect(notify.keys(player)):toContain("ceremony_petani")
			local last = analytics.funnelSteps[#analytics.funnelSteps]
			expect(last.funnel):toBe("first_session")
			expect(last.step):toBe(9)
			expect(last.name):toBe("rankup_petani")

			-- Doesn't fire again
			local count = #notify.keys(player)
			FirstSession.onRankUp(player, "petani")
			expect(#notify.keys(player)):toBe(count)
		end)
	end)
end
