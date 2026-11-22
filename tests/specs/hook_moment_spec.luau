--!nocheck
-- MomentGuard: the begin/end balancing helper behind the rarity reveal (Hud) and the raid overlay.
-- Hud and RaidOverlay need real Instances and cannot load under Lune, so the guard is tested
-- directly, plus small replays of the exact call patterns those two files use.

return function(t, Env)
	local expect = t.expect
	local env, Guard

	local function fakeRuntime()
		local rt = { depth = 0, begins = 0, ends = 0, minDepth = 0 }
		function rt.beginMoment()
			rt.begins += 1
			rt.depth += 1
		end
		function rt.endMoment()
			rt.ends += 1
			rt.depth -= 1
			rt.minDepth = math.min(rt.minDepth, rt.depth)
		end
		return rt
	end

	t:describe("MomentGuard", function()
		t:beforeEach(function()
			env = Env.new()
			Guard = env:require("client/Feel/MomentGuard")
		end)

		t:it("begin then finish balances once", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			g.begin()
			expect(g.isOpen()):toBe(true)
			expect(rt.depth):toBe(1)
			g.finish()
			expect(g.isOpen()):toBe(false)
			expect(rt.depth):toBe(0)
		end)

		t:it("finish without begin and double finish are harmless", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			g.finish()
			g.begin()
			g.finish()
			g.finish()
			expect(rt.begins):toBe(1)
			expect(rt.ends):toBe(1)
			expect(rt.minDepth):toBe(0)
		end)

		t:it("repeated begin never leaks a count", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			g.begin()
			g.begin()
			g.begin()
			expect(rt.depth):toBe(1)
			g.finish()
			expect(rt.depth):toBe(0)
			expect(rt.begins):toBe(rt.ends)
		end)

		t:it("repeated show/hide cycles stay balanced", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			for _ = 1, 5 do
				g.begin()
				g.finish()
			end
			expect(rt.depth):toBe(0)
			expect(rt.begins):toBe(5)
			expect(rt.ends):toBe(5)
		end)

		t:it("teardown after a show closes the moment (Destroying path)", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			g.begin()
			g.finish() -- gui.Destroying
			g.finish() -- a later hide()
			expect(rt.depth):toBe(0)
		end)

		t:it("rarity reveal pattern: a newer reveal supersedes the older timer", function()
			local rt = fakeRuntime()
			local g = Guard.new(rt)
			local token = 0
			local function reveal()
				token += 1
				local mine = token
				g.begin()
				env.globals.task.delay(3.6, function()
					if mine == token then
						g.finish()
					end
				end)
			end
			reveal()
			env:advance(1)
			reveal() -- supersedes; first timer must not end the second reveal
			expect(rt.depth):toBe(1)
			env:advance(2.7) -- first timer fires (t=3.6) and is ignored
			expect(rt.depth):toBe(1)
			env:advance(1) -- second timer fires (t=4.6)
			expect(rt.depth):toBe(0)
			expect(rt.begins):toBe(rt.ends)
			expect(rt.minDepth):toBe(0)
		end)

		t:it("drives the real FidelityRuntime: tier is frozen until the moment ends", function()
			local Runtime = env:require("client/Feel/FidelityRuntime")
			local signal = Env.newSignal()
			Runtime.start({
				heartbeat = {
					Connect = function(_, handler)
						return signal:Connect(handler)
					end,
				},
				player = { SetAttribute = function() end },
				clock = function()
					return env.now
				end,
				setting = "Tinggi",
			})
			local g = Guard.new() -- default runtime
			g.begin()
			for _ = 1, 600 do
				env:advance(1 / 30)
				signal:Fire(1 / 30)
			end
			expect(Runtime.get()):toBe("Tinggi")
			g.finish()
			g.finish()
			Runtime.endMoment() -- unbalanced extra end stays harmless
			Runtime.stop()
		end)
	end)
end
