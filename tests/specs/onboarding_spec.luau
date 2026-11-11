--!nocheck
-- Onboarding and tutorial flow (v2 PLAN §3.1).
--
-- Steps must advance only in the configured order, only when the action really succeeded on the
-- server, and never regress or advance twice.

return function(t, Env, Fakes)
	local expect = t.expect
	local env, Onboarding, OnboardingService
	local playerData, notify, player, data

	t:describe("Onboarding config", function()
		t:beforeEach(function()
			env = Env.new()
			Onboarding = env:require("shared/Config/Onboarding")
		end)

		t:it("has the four launch steps in the canonical order", function()
			expect(Onboarding.total):toBe(4)
			expect(Onboarding.steps[1].id):toBe("plant")
			expect(Onboarding.steps[2].id):toBe("harvest")
			expect(Onboarding.steps[3].id):toBe("sell")
			expect(Onboarding.steps[4].id):toBe("buy")
		end)

		t:it("resolves valid steps and rejects unknown ids", function()
			expect(Onboarding.exists("plant")):toBe(true)
			expect(Onboarding.exists("harvest")):toBe(true)
			expect(Onboarding.exists("cheat")):toBe(false)
			expect(Onboarding.exists(nil)):toBe(false)
		end)
	end)

	t:describe("OnboardingService", function()
		t:beforeEach(function()
			env = Env.new()
			Onboarding = env:require("shared/Config/Onboarding")

			playerData = Fakes.playerData()
			notify = Fakes.notify()

			env:mock("shared/Remotes", Fakes.remotes(env))
			env:mock("server/Data/PlayerData", playerData)
			env:mock("server/Net/Notify", notify)

			OnboardingService = env:require("server/Progression/OnboardingService")
			player = Fakes.player(env)
			data = playerData.set(player, Fakes.newData(env))
		end)

		t:describe("ensure", function()
			t:it("defaults a new player to step 1", function()
				local tutorial = OnboardingService.ensure(data)
				expect(tutorial.step):toBe(1)
				expect(next(tutorial.done)):toBeNil()
				expect(OnboardingService.current(data).id):toBe("plant")
				expect(OnboardingService.finished(data)):toBe(false)
			end)

			t:it("repairs malformed saves without dropping finished status", function()
				data.tutorial = { step = "nope", done = "invalid" }
				local tutorial = OnboardingService.ensure(data)
				expect(tutorial.step):toBe(1)
				expect(type(tutorial.done)):toBe("table")

				data.tutorial = { step = 99, done = {} }
				tutorial = OnboardingService.ensure(data)
				expect(tutorial.step):toBe(Onboarding.total + 1)
				expect(OnboardingService.finished(data)):toBe(true)
				expect(OnboardingService.current(data)):toBeNil()
			end)
		end)

		t:describe("advance", function()
			t:it("advances when the expected step is performed", function()
				expect(OnboardingService.advance(player, "plant")):toBe(true)
				expect(data.tutorial.step):toBe(2)
				expect(data.tutorial.done.plant):toBe(true)
				expect(player:GetAttribute("TutorialStep")):toBe("harvest")
				expect(notify.keys(player)):toContain("n_tutorial_step")
			end)

			t:it("refuses steps out of order", function()
				OnboardingService.publish(player, data)
				expect(OnboardingService.advance(player, "sell")):toBe(false)
				expect(data.tutorial.step):toBe(1)
				expect(data.tutorial.done.sell):toBeNil()
				expect(player:GetAttribute("TutorialStep")):toBe("plant")
			end)

			t:it("walks the full tutorial to completion", function()
				expect(OnboardingService.advance(player, "plant")):toBe(true)
				expect(OnboardingService.advance(player, "harvest")):toBe(true)
				expect(OnboardingService.advance(player, "sell")):toBe(true)
				expect(OnboardingService.advance(player, "buy")):toBe(true)

				expect(OnboardingService.finished(data)):toBe(true)
				expect(OnboardingService.current(data)):toBeNil()
				expect(player:GetAttribute("TutorialStep")):toBe("")
				expect(notify.keys(player)):toContain("n_tutorial_finished")
			end)

			t:it("ignores calls after completion", function()
				data.tutorial = { step = Onboarding.total + 1, done = {} }
				expect(OnboardingService.advance(player, "plant")):toBe(false)
				expect(OnboardingService.advance(player, "buy")):toBe(false)
			end)

			t:it("refuses unknown step ids", function()
				expect(OnboardingService.advance(player, "hack")):toBe(false)
				expect(data.tutorial.step):toBe(1)
			end)
		end)

		t:describe("publish", function()
			t:it("mirrors the active step onto TutorialStep", function()
				OnboardingService.publish(player, data)
				expect(player:GetAttribute("TutorialStep")):toBe("plant")

				data.tutorial.step = 3
				OnboardingService.publish(player, data)
				expect(player:GetAttribute("TutorialStep")):toBe("sell")

				data.tutorial.step = Onboarding.total + 1
				OnboardingService.publish(player, data)
				expect(player:GetAttribute("TutorialStep")):toBe("")
			end)
		end)
	end)
end
