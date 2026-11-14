--!nocheck
-- NextGoal (HUD guide card): the tutorial wins, then the next rank (money, then plots),
-- then the daily-task pointer on the top rank. Nil attributes default to gurem with 0.

return function(t, Env)
	local expect = t.expect
	local env, NextGoal

	t:describe("NextGoal", function()
		t:beforeEach(function()
			env = Env.new()
			NextGoal = env:require("shared/NextGoal")
		end)

		t:it("shows the tutorial step while one is running", function()
			local goal = NextGoal.pick({ tutorialStep = "plant", rank = "gurem", lifetimeEarned = 0, tilesOwned = 0 })
			expect(goal.kind):toBe("tutorial")
			expect(goal.key):toBe("tutorial_plant")
		end)

		t:it("treats an empty tutorial step as no tutorial", function()
			local goal = NextGoal.pick({ tutorialStep = "", rank = "gurem", lifetimeEarned = 400 })
			expect(goal.kind):toBe("rank_money")
		end)

		t:it("shows money progress toward petani for a gurem", function()
			local goal = NextGoal.pick({ rank = "gurem", lifetimeEarned = 400, tilesOwned = 0 })
			expect(goal.kind):toBe("rank_money")
			expect(goal.key):toBe("goal_rank_money")
			expect(goal.params[1]):toBe(400)
			expect(goal.params[2]):toBe(1000)
			expect(goal.params[3]):toBe("@rank_petani")
		end)

		t:it("caps the money shown at the requirement", function()
			local goal = NextGoal.pick({ rank = "gurem", lifetimeEarned = 5000 })
			expect(goal.params[1]):toBe(1000)
		end)

		t:it("shows plot progress toward juragan once money is met", function()
			local goal = NextGoal.pick({ rank = "petani", lifetimeEarned = 12000, tilesOwned = 8 })
			expect(goal.kind):toBe("rank_tiles")
			expect(goal.key):toBe("goal_rank_tiles")
			expect(goal.params[1]):toBe(8)
			expect(goal.params[2]):toBe(12)
			expect(goal.params[3]):toBe("@rank_juragan")
		end)

		t:it("points juragan to the daily tasks", function()
			local goal = NextGoal.pick({ rank = "juragan", lifetimeEarned = 99999, tilesOwned = 20 })
			expect(goal.kind):toBe("daily")
			expect(goal.key):toBe("goal_daily")
		end)

		t:it("defaults nil attributes to gurem with nothing earned", function()
			local goal = NextGoal.pick({})
			expect(goal.kind):toBe("rank_money")
			expect(goal.params[1]):toBe(0)
			expect(goal.params[2]):toBe(1000)
			expect(goal.params[3]):toBe("@rank_petani")
		end)
	end)
end
