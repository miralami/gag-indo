--!nocheck
-- WORK_QUEUE item 22: pure audio hygiene policy (LUNE-ONLY). src/client/AudioPolicy.luau has no
-- Roblox globals, so the config audit, the looping-role state machine and the one-shot pool rule
-- run under Lune. The Studio bridge (client/Audio.luau) owns Sound objects and Tweens; the
-- audio_wiring_spec + Studio Sound census cover that half.

return function(t, Env)
	local expect = t.expect
	local AudioPolicy

	t:describe("Audio hygiene policy", function()
		t:beforeEach(function()
			AudioPolicy = Env.new():require("client/AudioPolicy")
		end)

		t:describe("config audit", function()
			t:it("accepts the shipped audio config", function()
				local Config = Env.new():require("shared/Config/Audio")
				expect(#AudioPolicy.audit(Config.groups, Config.sounds)):toBe(0)
			end)

			t:it("flags a sound whose group is not registered", function()
				local problems = AudioPolicy.audit({ music = 0.5 }, { s = { group = "nope", volume = 0.5, id = 1 } })
				expect(#problems):toBeGreaterThan(0)
				expect(string.find(table.concat(problems, " "), "group", 1, true) ~= nil):toBe(true)
			end)

			t:it("flags invalid volume and asset id", function()
				local problems = AudioPolicy.audit(
					{ music = 0.5 },
					{
						badvol = { group = "music", volume = 1.5, id = 1 },
						badid = { group = "music", volume = 0.5, id = 1.5 },
					}
				)
				expect(#problems):toBe(2)
			end)

			t:it("flags a looping one-shot (non music/ambience group)", function()
				local problems = AudioPolicy.audit(
					{ music = 0.5, ui = 0.7 },
					{ click = { group = "ui", volume = 0.5, id = 1, looped = true } }
				)
				expect(#problems):toBeGreaterThan(0)
				expect(string.find(table.concat(problems, " "), "loops", 1, true) ~= nil):toBe(true)
			end)

			t:it("flags a group with no valid volume", function()
				local problems = AudioPolicy.audit({ music = "loud" }, {})
				expect(#problems):toBe(1)
			end)
		end)

		t:describe("playable set", function()
			t:it("includes only positive whole ids", function()
				local playable = AudioPolicy.playable({
					ok = { id = 83077123902599 },
					zero = { id = 0 },
					frac = { id = 1.5 },
					negative = { id = -2 },
					missing = {},
				})
				expect(playable.ok):toBe(true)
				expect(playable.zero):toBeNil()
				expect(playable.frac):toBeNil()
				expect(playable.negative):toBeNil()
				expect(playable.missing):toBeNil()
			end)
		end)

		t:describe("loop transitions", function()
			t:it("ignores a repeat of the current key", function()
				local policy = AudioPolicy.new({ a = true, b = true })
				local first = policy:transition("music", "a")
				expect(first.changed):toBe(true)
				expect(first.from):toBeNil()
				expect(first.to):toBe("a")
				expect(policy:transition("music", "a")):toBeNil()
				expect(policy:generation("music")):toBe(1)
			end)

			t:it("records outgoing/incoming and bumps the generation on a change", function()
				local policy = AudioPolicy.new({ a = true, b = true })
				policy:transition("music", "a")
				local change = policy:transition("music", "b")
				expect(change.from):toBe("a")
				expect(change.to):toBe("b")
				expect(change.gen):toBe(2)
				expect(policy:current("music")):toBe("b")
			end)

			t:it("treats a non-playable key and nil as stop", function()
				local policy = AudioPolicy.new({ a = true })
				policy:transition("music", "a")
				local stop = policy:transition("music", "not_registered")
				expect(stop.to):toBeNil()
				expect(stop.from):toBe("a")
				expect(policy:current("music")):toBeNil()
				expect(policy:transition("music", nil)):toBeNil()
			end)

			t:it("keeps music and ambience roles independent", function()
				local policy = AudioPolicy.new({ music = true, rain = true })
				policy:transition("music", "music")
				policy:transition("ambience", "rain")
				expect(policy:current("music")):toBe("music")
				expect(policy:current("ambience")):toBe("rain")
				expect(policy:generation("music")):toBe(1)
				expect(policy:generation("ambience")):toBe(1)
			end)

			t:it("rejects a stale fade generation but accepts the current one", function()
				local policy = AudioPolicy.new({ a = true, b = true })
				local c1 = policy:transition("music", "a")
				local c2 = policy:transition("music", "b")
				expect(policy:isCurrent("music", c1.gen)):toBe(false)
				expect(policy:isCurrent("music", c2.gen)):toBe(true)
			end)

			t:it("never holds more than one current key per role over a long sequence", function()
				local policy = AudioPolicy.new({ a = true, b = true, c = true, d = true })
				local keys = { "a", "b", "c", "d", nil, "not_registered" }
				local musicGen, ambienceGen = 0, 0
				-- deterministic LCG so the sequence is reproducible and spec-only
				local seed = 12345
				for _ = 1, 500 do
					seed = (1103515245 * seed + 12345) % 2147483648
					local role = if seed % 2 == 0 then "music" else "ambience"
					local key = keys[(seed // 7) % #keys + 1]
					local before = policy:generation(role)
					local change = policy:transition(role, key)
					if change then
						expect(change.gen):toBe(before + 1)
						if role == "music" then
							musicGen = change.gen
						else
							ambienceGen = change.gen
						end
					end
					local active = policy:activeLoops()
					-- at most one per role, and every active key is playable
					for activeKey in pairs(active) do
						expect(policy:isPlayable(activeKey)):toBe(true)
					end
					expect(active.a ~= nil and active.b ~= nil):toBe(false) -- not two music-role beds
				end
				expect(policy:generation("music")):toBe(musicGen)
				expect(policy:generation("ambience")):toBe(ambienceGen)
			end)
		end)

		t:describe("one-shot pool", function()
			t:it("never grows no matter how many plays", function()
				local playable = { ui_click = true, ui_open = true, sting_raid = true }
				local policy = AudioPolicy.new(playable)
				local size = policy:poolSize()
				for _ = 1, 200 do
					expect(policy:poolSize()):toBe(size) -- play() reuses a pooled Sound
				end
				expect(size):toBe(3)
				expect(policy:poolSize({ a = true, b = true })):toBe(2)
			end)
		end)
	end)
end
