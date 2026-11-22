--!nocheck
-- FidelityRuntime (V0.2): the thin client wiring. A fake Heartbeat drives the real controller and
-- a fake player records the "FidelityTier" attribute.

return function(t, Env)
	local expect = t.expect
	local env, Runtime
	local BAD = 1 / 30

	local function fakePlayer()
		local attrs = {}
		return {
			attrs = attrs,
			SetAttribute = function(_, name, value)
				attrs[name] = value
			end,
		}
	end

	local function fakeHeartbeat()
		local signal = Env.newSignal()
		return {
			signal = signal,
			Connect = function(_, handler)
				return signal:Connect(handler)
			end,
		}
	end

	-- Fires `seconds` of frames at dt, moving the fake os.clock the injected clock reads.
	local function frames(hb, dt, seconds)
		for _ = 1, math.ceil(seconds / dt) do
			env:advance(dt)
			hb.signal:Fire(dt)
		end
	end

	t:describe("FidelityRuntime", function()
		local hb, player
		local function start(extra)
			local deps = {
				heartbeat = hb,
				player = player,
				clock = function()
					return env.now
				end,
			}
			for key, value in extra or {} do
				deps[key] = value
			end
			return Runtime.start(deps)
		end

		t:beforeEach(function()
			env = Env.new()
			Runtime = env:require("client/Feel/FidelityRuntime")
			hb = fakeHeartbeat()
			player = fakePlayer()
		end)

		t:it("answers with the default tier before start", function()
			expect(Runtime.get()):toBe("Sedang")
			expect(Runtime.isStarted()):toBe(false)
			Runtime.beginMoment() -- harmless no-ops
			Runtime.endMoment()
			Runtime.setOverride("Rendah")
			expect(Runtime.get()):toBe("Sedang")
		end)

		t:it("publishes the starting tier as a player attribute", function()
			start({ setting = "Tinggi" })
			expect(Runtime.get()):toBe("Tinggi")
			expect(player.attrs.FidelityTier):toBe("Tinggi")
		end)

		t:it("start is idempotent and keeps one controller", function()
			local first = start()
			local second = Runtime.start({ heartbeat = fakeHeartbeat(), player = fakePlayer() })
			expect(second):toBe(first)
			expect(#hb.signal._handlers):toBe(1)
		end)

		t:it("steps down on slow Heartbeat frames and updates the attribute and listeners", function()
			start({ setting = "Tinggi" })
			local seen = {}
			Runtime.onChanged(function(new, old)
				table.insert(seen, { new, old })
			end)
			frames(hb, BAD, 3)
			expect(Runtime.get()):toBe("Sedang")
			expect(player.attrs.FidelityTier):toBe("Sedang")
			expect(#seen):toBe(1)
			expect(seen[1][1]):toBe("Sedang")
			expect(seen[1][2]):toBe("Tinggi")
			expect(Runtime.settings().particleRate):toBe(0.7)
		end)

		t:it("freezes during a hook moment and lands the change on endMoment", function()
			start({ setting = "Tinggi" })
			Runtime.beginMoment()
			frames(hb, BAD, 5)
			expect(Runtime.get()):toBe("Tinggi")
			Runtime.setOverride("Rendah")
			expect(Runtime.get()):toBe("Tinggi")
			Runtime.endMoment()
			expect(Runtime.get()):toBe("Rendah")
			expect(player.attrs.FidelityTier):toBe("Rendah")
		end)

		t:it("setOverride(nil) hands control back to auto", function()
			start({ setting = "Tinggi" })
			Runtime.setOverride("Rendah")
			expect(Runtime.get()):toBe("Rendah")
			Runtime.setOverride(nil)
			expect(Runtime.get()):toBe("Tinggi")
		end)

		t:it("ignores bad Heartbeat values", function()
			start({ setting = "Tinggi" })
			for _, bad in { 0 / 0, -1, 0, 99, math.huge } do
				for _ = 1, 40 do
					hb.signal:Fire(bad)
				end
			end
			env:advance(10)
			hb.signal:Fire(BAD)
			expect(Runtime.get()):toBe("Tinggi")
		end)

		t:it("survives a player without SetAttribute", function()
			start({ player = {} })
			expect(Runtime.get()):toBe("Sedang")
		end)

		t:it("stop disconnects Heartbeat and allows a fresh start", function()
			start({ setting = "Tinggi" })
			Runtime.stop()
			expect(#hb.signal._handlers):toBe(0)
			expect(Runtime.isStarted()):toBe(false)
			start({ setting = "Rendah" })
			expect(Runtime.get()):toBe("Rendah")
		end)
	end)
end
