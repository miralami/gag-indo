--!nocheck
-- Item 6 perf/cleanup specs. Two bounded fixes are locked here:
--   * Wind resolved FidelityRuntime (a fresh pcall closure + require) on every 20 Hz tick. It now
--     resolves once at start(); settings() is still read each tick, so tier changes still land.
--     Wind.resolveCount() proves resolution is per-start, not per-frame.
--   * Wind and CameraFeel owned RunService/CollectionService/Player signals with no teardown.
--     Both now expose stop() that disconnects every signal they own and are restart-safe.

return function(t, Env, Fakes)
	local expect = t.expect

	local function installCFrame(env)
		local meta = {}
		meta.__mul = function(a, _b)
			return setmetatable({ Position = a.Position }, meta)
		end
		local function makeCF(pos)
			return setmetatable({ Position = pos }, meta)
		end
		env.globals.CFrame = {
			new = function(x, y, z)
				return makeCF(Env.Vector3.new(x, y, z))
			end,
			Angles = function()
				return makeCF(Env.Vector3.new(0, 0, 0))
			end,
		}
		return makeCF
	end

	-- A Wind setup with one tagged, in-range BasePart and a settings() we can count.
	local function windSetup()
		local env = Env.new()
		local makeCF = installCFrame(env)
		local heartbeat = Env.newSignal()
		local tagRemoved = Env.newSignal()
		local tagged = {}
		local settingsCalls = 0
		env.services.RunService.Heartbeat = heartbeat
		env.services.CollectionService = {
			GetInstanceRemovedSignal = function(_, _tag)
				return tagRemoved
			end,
			GetTagged = function()
				return tagged
			end,
		}
		env:mock("client/Feel/FidelityRuntime", {
			settings = function()
				settingsCalls += 1
				return { foliageSwayRange = 1000 }
			end,
		})
		env.globals.workspace = {
			CurrentCamera = { CFrame = makeCF(Env.Vector3.new(0, 0, 0)) },
		}
		local part = {
			ClassName = "BasePart",
			Position = Env.Vector3.new(1, 0, 1),
			CFrame = makeCF(Env.Vector3.new(1, 0, 1)),
			Anchored = true,
			Parent = {},
			_attrs = { WindSeed = 1 },
		}
		function part:IsA(cls)
			return cls == "BasePart"
		end
		function part:GetAttribute(k)
			return self._attrs[k]
		end
		tagged[1] = part
		local Wind = env:require("client/World/Wind")
		return Wind, { heartbeat = heartbeat, tagRemoved = tagRemoved, part = part }, function()
			return settingsCalls
		end
	end

	t:describe("Wind hot path", function()
		t:it("resolves FidelityRuntime once per start, not once per tick", function()
			local Wind, s, settingsCalls = windSetup()
			expect(Wind.resolveCount()):toBe(0)
			Wind.start()
			expect(Wind.resolveCount()):toBe(1)
			for _ = 1, 50 do
				s.heartbeat:Fire(1)
			end
			-- Resolution happened once; settings() is still read on every tick, so a tier change
			-- made after start still lands on the next tick.
			expect(Wind.resolveCount()):toBe(1)
			expect(settingsCalls()):toBe(50)
		end)

		t:it("start is idempotent - one heartbeat and one tag-removed handler", function()
			local Wind, s = windSetup()
			Wind.start()
			Wind.start()
			expect(#s.heartbeat._handlers):toBe(1)
			expect(#s.tagRemoved._handlers):toBe(1)
		end)

		t:it("stop disconnects both signals, restores swayed parts and allows a clean restart", function()
			local Wind, s = windSetup()
			local original = s.part.CFrame
			Wind.start()
			s.heartbeat:Fire(1)
			expect(s.part.CFrame == original):toBe(false) -- it was swayed
			Wind.stop()
			expect(#s.heartbeat._handlers):toBe(0)
			expect(#s.tagRemoved._handlers):toBe(0)
			expect(Wind.isStarted()):toBe(false)
			expect(s.part.CFrame == original):toBe(true) -- restored on teardown
			Wind.start()
			expect(#s.heartbeat._handlers):toBe(1)
			expect(Wind.isStarted()):toBe(true)
			expect(Wind.resolveCount()):toBe(2)
		end)

		t:it("stop before start is safe", function()
			local Wind = windSetup()
			expect(function()
				Wind.stop()
			end).never:toThrow()
			expect(Wind.isStarted()):toBe(false)
		end)
	end)

	t:describe("CameraFeel connection cleanup", function()
		local function cameraSetup()
			local env = Env.new()
			env.globals.TweenInfo = { new = function()
				return {}
			end }
			env.services.TweenService = {
				Create = function()
					return { Play = function() end, Cancel = function() end }
				end,
			}
			local heartbeat = Env.newSignal()
			env.services.RunService.Heartbeat = heartbeat
			local characterAdded = Env.newSignal()
			local characterRemoving = Env.newSignal()
			env.services.Players.LocalPlayer = {
				Character = nil,
				CharacterAdded = characterAdded,
				CharacterRemoving = characterRemoving,
			}
			local CameraFeel = env:require("client/Feel/CameraFeel")
			return CameraFeel, {
				heartbeat = heartbeat,
				characterAdded = characterAdded,
				characterRemoving = characterRemoving,
			}
		end

		t:it("start is idempotent - three owned signals connect once", function()
			local CameraFeel, s = cameraSetup()
			CameraFeel.start()
			CameraFeel.start()
			expect(CameraFeel.isStarted()):toBe(true)
			expect(#s.heartbeat._handlers):toBe(1)
			expect(#s.characterAdded._handlers):toBe(1)
			expect(#s.characterRemoving._handlers):toBe(1)
		end)

		t:it("stop disconnects every owned signal and is safe to repeat", function()
			local CameraFeel, s = cameraSetup()
			CameraFeel.start()
			CameraFeel.stop()
			expect(#s.heartbeat._handlers):toBe(0)
			expect(#s.characterAdded._handlers):toBe(0)
			expect(#s.characterRemoving._handlers):toBe(0)
			expect(CameraFeel.isStarted()):toBe(false)
			expect(function()
				CameraFeel.stop()
			end).never:toThrow()
			CameraFeel.start()
			expect(#s.heartbeat._handlers):toBe(1)
		end)

		t:it("stop before start is safe", function()
			local CameraFeel = cameraSetup()
			expect(function()
				CameraFeel.stop()
			end).never:toThrow()
			expect(CameraFeel.isStarted()):toBe(false)
		end)
	end)
end
