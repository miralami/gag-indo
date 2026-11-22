--!nocheck
-- CameraFeel (RESEARCH_VISUAL_TIPS: FOV polish). The pure helpers decide the field of view, so
-- they are pinned here: clamped to 72..76, rest at 72, never decreasing as speed grows.

return function(t, Env)
	local expect = t.expect
	local env, CameraFeel

	t:describe("CameraFeel", function()
		t:beforeEach(function()
			env = Env.new()
			CameraFeel = env:require("client/Feel/CameraFeel")
		end)

		t:describe("targetFov", function()
			t:it("rests at 72 when idle", function()
				expect(CameraFeel.targetFov(0)):toBe(72)
			end)

			t:it("reaches 76 at full speed", function()
				expect(CameraFeel.targetFov(1)):toBe(76)
			end)

			t:it("clamps ratios below 0 to 72", function()
				expect(CameraFeel.targetFov(-5)):toBe(72)
			end)

			t:it("clamps ratios above 1 to 76", function()
				expect(CameraFeel.targetFov(3)):toBe(76)
			end)

			t:it("treats NaN as idle", function()
				expect(CameraFeel.targetFov(0 / 0)):toBe(72)
			end)

			t:it("stays within 72..76 across a sweep", function()
				for step = -10, 20 do
					local fov = CameraFeel.targetFov(step / 10)
					expect(fov):toBeAtLeast(72)
					expect(fov):toBeAtMost(76)
				end
			end)

			t:it("never decreases as the ratio grows", function()
				local previous = CameraFeel.targetFov(0)
				for step = 1, 20 do
					local fov = CameraFeel.targetFov(step / 20)
					expect(fov):toBeAtLeast(previous)
					previous = fov
				end
			end)
		end)

		t:describe("ratioFor", function()
			t:it("is 0 when not moving, even when fast", function()
				expect(CameraFeel.ratioFor(24, false)):toBe(0)
			end)

			t:it("is 0 at or below the default WalkSpeed of 16", function()
				expect(CameraFeel.ratioFor(16, true)):toBe(0)
				expect(CameraFeel.ratioFor(10, true)):toBe(0)
			end)

			t:it("is 1 at a full run (WalkSpeed 24) and above", function()
				expect(CameraFeel.ratioFor(24, true)):toBe(1)
				expect(CameraFeel.ratioFor(40, true)):toBe(1)
			end)

			t:it("rises between 16 and 24 when moving", function()
				expect(CameraFeel.ratioFor(20, true)):toBe(0.5)
			end)
			t:describe("pause and resume override", function()
				t:it("is not paused by default", function()
					expect(CameraFeel.isPaused()):toBe(false)
				end)

				t:it("pauses while any owner holds it", function()
					CameraFeel.pause("cutscene")
					expect(CameraFeel.isPaused()):toBe(true)
					CameraFeel.resume("cutscene")
					expect(CameraFeel.isPaused()):toBe(false)
				end)

				t:it("counts one owner once however often it pauses", function()
					CameraFeel.pause("a")
					CameraFeel.pause("a")
					CameraFeel.resume("a")
					expect(CameraFeel.isPaused()):toBe(false)
				end)

				t:it("stays paused until every owner has resumed, in any order", function()
					CameraFeel.pause("a")
					CameraFeel.pause("b")
					CameraFeel.resume("a")
					expect(CameraFeel.isPaused()):toBe(true)
					CameraFeel.resume("b")
					expect(CameraFeel.isPaused()):toBe(false)
				end)

				t:it("ignores a resume without a hold and a nil owner", function()
					CameraFeel.resume("nobody")
					CameraFeel.pause(nil)
					CameraFeel.resume(nil)
					expect(CameraFeel.isPaused()):toBe(false)
					CameraFeel.pause("a")
					CameraFeel.resume("someone else")
					expect(CameraFeel.isPaused()):toBe(true)
				end)

				t:it("never throws when resumed without a camera or TweenService", function()
					CameraFeel.pause("a")
					expect(function()
						CameraFeel.resume("a")
					end).never:toThrow()
				end)
			end)
		end)
	end)
end
