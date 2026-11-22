--!nocheck
-- FpsSampler: pure rolling frame-time -> fps helper for the Studio-only perf sampling (V0.2).
-- Bad frame times are ignored; no Roblox APIs in the pure path so this runs under Lune.
return function(t, Env)
	local expect = t.expect
	local FpsSampler

	local function setup()
		FpsSampler = Env.new():require("client/Feel/FpsSampler")
	end

	t:describe("FpsSampler (pure)", function()
		t:beforeEach(setup)

		t:it("returns nil until enough clean samples, then reports fps", function()
			local s = FpsSampler.new(60, 3)
			expect(s.fps()):toBeNil()
			s.push(1 / 60); s.push(1 / 60)
			expect(s.fps()):toBeNil()
			s.push(1 / 60)
			expect(s.fps()):toBeNear(60, 1)
			expect(s.count()):toBe(3)
		end)

		t:it("ignores bad frame times (NaN, zero, negative, pause)", function()
			local s = FpsSampler.new(60, 2)
			s.push(0 / 0) -- NaN
			s.push(0)
			s.push(-0.016)
			s.push(5) -- a tab-out pause
			s.push("nope")
			expect(s.count()):toBe(0)
			expect(s.fps()):toBeNil()
		end)

		t:it("keeps a rolling window of the given size", function()
			local s = FpsSampler.new(3, 3)
			for _ = 1, 2 do s.push(0.1) end
			s.push(0.1)
			expect(s.fps()):toBeNear(10, 0.01)
			s.push(0.05) -- oldest 0.1 dropped; average (0.1+0.1+0.05)/3
			expect(s.count()):toBe(3)
			expect(s.fps()):toBeNear(1 / ((0.1 + 0.1 + 0.05) / 3), 0.01)
		end)

		t:it("reset clears samples", function()
			local s = FpsSampler.new(60, 1)
			s.push(1 / 30)
			expect(s.fps()):toBeNear(30, 0.01)
			s.reset()
			expect(s.count()):toBe(0)
			expect(s.fps()):toBeNil()
		end)
	end)

	t:describe("FpsSampler.start (runtime gate)", function()
		t:beforeEach(setup)

		t:it("does nothing and returns a no-op in a published place", function()
			local connected = false
			local fakeRun = {
				IsStudio = function() return false end,
				RenderStepped = { Connect = function() connected = true end },
			}
			local stop = FpsSampler.start({ runService = fakeRun, isStudio = false })
			expect(connected):toBe(false)
			expect(type(stop)):toBe("function")
			stop()
		end)

		t:it("connects RenderStepped in Studio and returns a disconnect", function()
			local connected = false
			local disconnected = false
			local fakeRun = {
				IsStudio = function() return true end,
				RenderStepped = { Connect = function()
					connected = true
					return { Disconnect = function() disconnected = true end }
				end },
			}
			local fakePlayer = { SetAttribute = function() end }
			local stop = FpsSampler.start({
				runService = fakeRun, isStudio = true,
				player = fakePlayer, players = { LocalPlayer = fakePlayer },
			})
			expect(connected):toBe(true)
			stop()
			expect(disconnected):toBe(true)
		end)
	end)
end
