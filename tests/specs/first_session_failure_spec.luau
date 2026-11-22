--!nocheck
-- WORK_QUEUE item 11: FirstSession had happy-path beat-sheet specs only. These lock the four
-- failure paths its orchestrator already guards: a nil player, a player who left (no loaded
-- data), damaged tutorial/story data, and a dependency that cannot supply growSeconds.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Law, Crops, FirstSession, playerData, notify, analytics, player, data

	t:describe("FirstSession failure paths (item 11)", function()
		t:beforeEach(function()
			env = Env.new()
			Law = env:require("shared/Config/Law")
			Crops = env:require("shared/Config/Crops")
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

		t:it("a nil player never throws and never notifies", function()
			expect(function()
				FirstSession.tick(nil, 9999)
				FirstSession.onSusChanged(nil, 50, 0)
				FirstSession.onRankUp(nil, "petani")
				FirstSession.getHarvestTier(nil, nil, "biasa")
			end).never:toThrow()
			expect(#notify.sent):toBe(0)
			expect(#analytics.funnelSteps):toBe(0)
		end)

		t:it("a player who left (no loaded data) is ignored on every entry point", function()
			local ghost = Fakes.player(env) -- created, but never registered in PlayerData
			expect(function()
				FirstSession.tick(ghost, 9999)
				FirstSession.onSusChanged(ghost, 100)
				FirstSession.onRankUp(ghost, "petani")
			end).never:toThrow()
			expect(#notify.sent):toBe(0)
			expect(#analytics.funnelSteps):toBe(0)
		end)

		t:it("a missing story and tutorial are rebuilt, not crashed", function()
			-- SaveSanitize guarantees loaded story/tutorial are tables; these are the missing-
			-- field cases the module's own `if not data.story` guards are written for.
			data.story = nil
			data.tutorial = nil
			expect(function()
				FirstSession.tick(player, 9999)
			end).never:toThrow()
			expect(type(data.story)):toBe("table")
			expect(data.story.flags.beat_bayarlater):toBe(true)
			expect(data.story.flags.beat_scripted_raid):toBe(true)
			expect(data.story.flags.beat_warung_rumour):toBe(true)
		end)

		t:it("a story without its flags table is repaired before a beat fires", function()
			data.story = { chapter = 0 }
			expect(function()
				FirstSession.onSusChanged(player, 50, 0)
			end).never:toThrow()
			expect(type(data.story.flags)):toBe("table")
			expect(data.story.flags.sus_explained):toBe(true)
		end)

		t:it("a null stats field is rebuilt before counting the next harvest", function()
			data.stats = nil
			expect(FirstSession.getHarvestTier(player, data, "biasa")):toBe("bagus")
			expect(data.stats.harvests):toBe(1)
		end)

		t:it("a ToolService without growSeconds falls back to the crop's own time", function()
			env:mock("server/Farm/ToolService", {})
			data.stats.harvests = 1 -- past the tutorial padi guarantee
			expect(FirstSession.getGrowSeconds(player, "padi", data)):toBe(Crops.list.padi.growSeconds)
			expect(Law.namaBaikStart > 0):toBe(true) -- guard the config used by other cases
		end)
	end)
end
