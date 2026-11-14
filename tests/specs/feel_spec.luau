--!nocheck
-- ActionFeel unit tests: popScale, cashFlyTrajectory, shakeOffset, isSultan.

return function(t, Env)
	local expect = t.expect
	local env, ActionFeel

	t:describe("ActionFeel", function()
		t:beforeEach(function()
			env = Env.new()
			ActionFeel = env:require("client/Feel/ActionFeel")
		end)

		t:describe("popScale", function()
			t:it("starts at 0 or 1", function()
				expect(ActionFeel.popScale(0)):toBe(0)
				expect(ActionFeel.popScale(-1)):toBe(0)
			end)

			t:it("peaks above 1", function()
				local peak = 0
				for step = 0, 50 do
					local scale = ActionFeel.popScale(step / 50)
					if scale > peak then
						peak = scale
					end
				end
				expect(peak):toBeGreaterThan(1)
				expect(peak):toBeAtLeast(1.15)
			end)

			t:it("settles at 1", function()
				expect(ActionFeel.popScale(1)):toBe(1)
				expect(ActionFeel.popScale(1.2)):toBe(1)
				expect(ActionFeel.popScale(2.5)):toBe(1)
			end)
		end)

		t:describe("cashFlyTrajectory", function()
			t:it("progresses smoothly from start to end with arc", function()
				local Vector3 = env.Vector3
				local startPos = Vector3.new(0, 0, 0)
				local endPos = Vector3.new(10, 0, 10)

				-- Endpoints
				local p0 = ActionFeel.cashFlyTrajectory(startPos, endPos, 0)
				expect(p0.X):toBeNear(0)
				expect(p0.Y):toBeNear(0)
				expect(p0.Z):toBeNear(0)

				local p1 = ActionFeel.cashFlyTrajectory(startPos, endPos, 1)
				expect(p1.X):toBeNear(10)
				expect(p1.Y):toBeNear(0)
				expect(p1.Z):toBeNear(10)

				-- Upward arc at midpoint
				local mid = ActionFeel.cashFlyTrajectory(startPos, endPos, 0.5)
				local linearMidY = (startPos.Y + endPos.Y) / 2
				expect(mid.Y):toBeGreaterThan(linearMidY)

				-- Smooth progression along trajectory
				local prevX = -0.01
				for step = 0, 10 do
					local p = ActionFeel.cashFlyTrajectory(startPos, endPos, step / 10)
					expect(p.X):toBeAtLeast(prevX)
					prevX = p.X
				end

				-- 2D trajectory test
				local start2D = { X = 10, Y = 20 }
				local end2D = { X = 110, Y = 20 }
				local mid2D = ActionFeel.cashFlyTrajectory(start2D, end2D, 0.5)
				expect(mid2D.Y):toBeGreaterThan(20)
			end)
		end)

		t:describe("shakeOffset", function()
			t:it("is zero when intensity is 0", function()
				local offset = ActionFeel.shakeOffset(0, 1.5)
				expect(offset.X):toBe(0)
				expect(offset.Y):toBe(0)
				expect(offset.Z):toBe(0)

				local negOffset = ActionFeel.shakeOffset(-2, 1.5)
				expect(negOffset.X):toBe(0)
				expect(negOffset.Y):toBe(0)
				expect(negOffset.Z):toBe(0)
			end)

			t:it("is bounded by intensity", function()
				for _, intensity in { 0.1, 0.5, 1, 2.5 } do
					for step = 0, 20 do
						local time = step * 0.15
						local offset = ActionFeel.shakeOffset(intensity, time)
						local mag = math.sqrt(offset.X ^ 2 + offset.Y ^ 2 + offset.Z ^ 2)
						expect(mag):toBeAtMost(intensity + 1e-5)
					end
				end
			end)
		end)

		t:describe("isSultan", function()
			t:it("correctly identifies sultan tier", function()
				expect(ActionFeel.isSultan("sultan")):toBe(true)
				expect(ActionFeel.isSultan("Sultan")):toBe(true)
				expect(ActionFeel.isSultan("SULTAN")):toBe(true)
				expect(ActionFeel.isSultan("langka")):toBe(false)
				expect(ActionFeel.isSultan("super")):toBe(false)
				expect(ActionFeel.isSultan("biasa")):toBe(false)
				expect(ActionFeel.isSultan(nil)):toBe(false)
				expect(ActionFeel.isSultan(100)):toBe(false)
				expect(ActionFeel.isSultan(false)):toBe(false)
			end)
		end)
	end)
end
