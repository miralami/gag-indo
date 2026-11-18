--!nocheck
-- CutsceneSequencer (pure timeline player) and the default raid cutscene config.

return function(t, Env)
	local expect = t.expect
	local env, Seq, RaidCutscene, State, MapSpec

	local function shots(...)
		local list = {}
		for i, d in { ... } do
			table.insert(list, { id = "s" .. i, kind = "zoom", duration = d })
		end
		return list
	end

	-- Records onShot ids and finish count/skipped flags.
	local function record(seq)
		local log = { ids = {}, finished = 0, skipped = nil }
		seq.onShot(function(shot)
			table.insert(log.ids, shot.id)
		end)
		seq.onFinished(function(skipped)
			log.finished += 1
			log.skipped = skipped
		end)
		return log
	end

	t:describe("CutsceneSequencer", function()
		t:beforeEach(function()
			env = Env.new()
			Seq = env:require("client/Feel/CutsceneSequencer")
			RaidCutscene = env:require("shared/Config/RaidCutscene")
			State = env:require("client/Feel/CutsceneState")
			MapSpec = env:require("server/World/MapSpec")
		end)

		t:describe("playback", function()
			t:it("fires onShot in order and finishes once", function()
				local seq = Seq.new(shots(1, 2, 1))
				local log = record(seq)
				seq.play()
				expect(log.ids):toEqual({ "s1" })
				seq.step(1)
				expect(log.ids):toEqual({ "s1", "s2" })
				seq.step(2)
				expect(log.ids):toEqual({ "s1", "s2", "s3" })
				expect(log.finished):toBe(0)
				seq.step(1)
				expect(log.finished):toBe(1)
				expect(log.skipped):toBe(false)
				seq.step(5)
				expect(log.finished):toBe(1)
				expect(seq.isFinished()):toBeTruthy()
			end)

			t:it("reports current shot and progress", function()
				local seq = Seq.new(shots(2, 4))
				local shot, progress = seq.current()
				expect(shot):toBeNil()
				expect(progress):toBe(0)
				seq.play()
				seq.step(1)
				shot, progress = seq.current()
				expect(shot.id):toBe("s1")
				expect(progress):toBeNear(0.5)
				seq.step(2) -- 1s into shot 2
				shot, progress = seq.current()
				expect(shot.id):toBe("s2")
				expect(progress):toBeNear(0.25)
				seq.step(10)
				shot, progress = seq.current()
				expect(shot):toBeNil()
				expect(progress):toBe(1)
			end)

			t:it("passes several shots in one dt spike, firing each onShot in order", function()
				local seq = Seq.new(shots(1, 1, 1, 1))
				local log = record(seq)
				seq.play()
				seq.step(2.5)
				expect(log.ids):toEqual({ "s1", "s2", "s3" })
				local shot, progress = seq.current()
				expect(shot.id):toBe("s3")
				expect(progress):toBeNear(0.5)
				seq.step(100)
				expect(log.ids):toEqual({ "s1", "s2", "s3", "s4" })
				expect(log.finished):toBe(1)
			end)

			t:it("play is a no-op the second time", function()
				local seq = Seq.new(shots(1))
				local log = record(seq)
				seq.play()
				seq.play()
				expect(#log.ids):toBe(1)
			end)

			t:it("ignores step before play", function()
				local seq = Seq.new(shots(1))
				local log = record(seq)
				seq.step(5)
				expect(#log.ids):toBe(0)
				expect(log.finished):toBe(0)
			end)
		end)

		t:describe("clock-driven update", function()
			t:it("derives dt from the injected clock", function()
				local now = 100
				local seq = Seq.new(shots(2, 2), {
					clock = function()
						return now
					end,
				})
				local log = record(seq)
				seq.play()
				seq.update(101)
				local shot, progress = seq.current()
				expect(shot.id):toBe("s1")
				expect(progress):toBeNear(0.5)
				now = 103.5
				seq.update() -- reads the clock
				expect(log.ids):toEqual({ "s1", "s2" })
				seq.update(110)
				expect(log.finished):toBe(1)
			end)

			t:it("treats a backwards clock and junk as no time passing", function()
				local seq = Seq.new(shots(2), {
					clock = function()
						return 50
					end,
				})
				seq.play()
				seq.update(51)
				seq.update(40)
				seq.update(0 / 0)
				seq.update("x")
				local _, progress = seq.current()
				expect(progress):toBeNear(0.5)
			end)
		end)

		t:describe("robustness", function()
			t:it("finishes immediately on an empty list", function()
				local seq = Seq.new({})
				local log = record(seq)
				seq.play()
				expect(log.finished):toBe(1)
				expect(#log.ids):toBe(0)
				expect(seq.isFinished()):toBeTruthy()
			end)

			t:it("treats nil and non-table shot lists as empty", function()
				for _, bad in { "x", 5 } do
					local seq = Seq.new(bad)
					local log = record(seq)
					seq.play()
					expect(log.finished):toBe(1)
				end
				local seq = Seq.new(nil, nil)
				local log = record(seq)
				seq.play()
				expect(log.finished):toBe(1)
			end)

			t:it("turns bad durations into zero-length shots that still fire in order", function()
				local list = {
					{ id = "a", kind = "zoom", duration = 0 / 0 },
					{ id = "b", kind = "zoom", duration = -3 },
					{ id = "c", kind = "zoom", duration = "2" },
					{ id = "d", kind = "zoom", duration = math.huge },
					{ id = "e", kind = "zoom", duration = 1 },
				}
				local seq = Seq.new(list)
				local log = record(seq)
				seq.play()
				expect(log.ids):toEqual({ "a", "b", "c", "d", "e" })
				expect(seq.totalDuration()):toBe(1)
				seq.step(1)
				expect(log.finished):toBe(1)
			end)

			t:it("finishes inside play when every shot is zero-length", function()
				local seq = Seq.new(shots(0, 0 / 0, -1))
				local log = record(seq)
				seq.play()
				expect(log.ids):toEqual({ "s1", "s2", "s3" })
				expect(log.finished):toBe(1)
			end)

			t:it("ignores bad dt values", function()
				local seq = Seq.new(shots(2))
				seq.play()
				seq.step(0 / 0)
				seq.step(-5)
				seq.step(nil)
				seq.step("1")
				seq.step(math.huge)
				-- math.huge is not a finite dt, so nothing moved
				local _, progress = seq.current()
				expect(progress):toBe(0)
				expect(seq.isPlaying()):toBeTruthy()
			end)

			t:it("drops non-table shots and repairs ids and kinds without mutating the input", function()
				local input = { 5, "x", { duration = 1 }, { id = "", kind = "bogus", duration = 1 } }
				local seq = Seq.new(input)
				expect(seq.shotCount()):toBe(2)
				seq.play()
				local shot = seq.current()
				expect(shot.id):toBe("shot1")
				expect(shot.kind):toBe("establish")
				expect(input[3].id):toBeNil()
				expect(input[3].kind):toBeNil()
			end)

			t:it("keeps extra shot params", function()
				local seq = Seq.new({ { id = "z", kind = "zoom", duration = 1, fov = 30 } })
				seq.play()
				expect(seq.current().fov):toBe(30)
			end)

			t:it("survives throwing listeners", function()
				local seq = Seq.new(shots(1))
				seq.onShot(function()
					error("boom")
				end)
				seq.onFinished(function()
					error("boom")
				end)
				local log = record(seq)
				seq.play()
				seq.step(1)
				expect(log.ids):toEqual({ "s1" })
				expect(log.finished):toBe(1)
			end)

			t:it("lets a listener disconnect itself", function()
				local seq = Seq.new(shots(1, 1))
				local count = 0
				local off
				off = seq.onShot(function()
					count += 1
					off()
				end)
				seq.play()
				seq.step(1)
				expect(count):toBe(1)
			end)

			t:it("ignores re-entrant step from a listener", function()
				local seq = Seq.new(shots(1, 1))
				local log = record(seq)
				seq.onShot(function()
					seq.step(5)
				end)
				seq.play()
				expect(log.finished):toBe(0)
				seq.step(1)
				expect(log.ids):toEqual({ "s1", "s2" })
			end)
		end)

		t:describe("skip and cancel", function()
			t:it("does not skip unless skippable", function()
				local seq = Seq.new(shots(5))
				local log = record(seq)
				seq.play()
				expect(seq.skip()):toBe(false)
				expect(log.finished):toBe(0)
				expect(seq.isPlaying()):toBeTruthy()
			end)

			t:it("skips once when skippable and reports skipped", function()
				local seq = Seq.new(shots(5, 5), { skippable = true })
				local log = record(seq)
				seq.play()
				seq.step(1)
				expect(seq.skip()):toBe(true)
				expect(log.finished):toBe(1)
				expect(log.skipped):toBe(true)
				expect(seq.wasSkipped()):toBeTruthy()
				expect(seq.skip()):toBe(false)
				seq.step(100)
				expect(log.finished):toBe(1)
				expect(#log.ids):toBe(1)
			end)

			t:it("ignores skip before play and after natural finish", function()
				local seq = Seq.new(shots(1), { skippable = true })
				local log = record(seq)
				expect(seq.skip()):toBe(false)
				seq.play()
				seq.step(1)
				expect(seq.skip()):toBe(false)
				expect(log.finished):toBe(1)
				expect(log.skipped):toBe(false)
			end)

			t:it("only a literal true enables skippable", function()
				expect(Seq.new(shots(1), { skippable = "yes" }).isSkippable()):toBe(false)
				expect(Seq.new(shots(1), { skippable = true }).isSkippable()):toBe(true)
				expect(Seq.new(shots(1), "junk").isSkippable()):toBe(false)
			end)

			t:it("a listener may skip during onShot without double finishing", function()
				local seq = Seq.new(shots(1, 1, 1), { skippable = true })
				local log = record(seq)
				seq.onShot(function(shot)
					if shot.id == "s2" then
						seq.skip()
					end
				end)
				seq.play()
				seq.step(10)
				expect(log.finished):toBe(1)
				expect(log.skipped):toBe(true)
				expect(log.ids):toEqual({ "s1", "s2" })
			end)

			t:it("cancel stops silently without firing onFinished", function()
				local seq = Seq.new(shots(1, 1))
				local log = record(seq)
				seq.play()
				seq.cancel()
				seq.step(10)
				seq.update(1000)
				expect(log.finished):toBe(0)
				expect(#log.ids):toBe(1)
				expect(seq.isPlaying()):toBeFalsy()
				expect(seq.current()):toBeNil()
			end)

			t:it("cancel before play prevents play; cancel after finish is harmless", function()
				local a = Seq.new(shots(1))
				local logA = record(a)
				a.cancel()
				a.play()
				expect(#logA.ids):toBe(0)
				local b = Seq.new(shots(1))
				local logB = record(b)
				b.play()
				b.step(1)
				b.cancel()
				expect(logB.finished):toBe(1)
				expect(b.isFinished()):toBeTruthy()
			end)
		end)

		t:describe("skippableAfter", function()
			t:it("is true only after at least one completed viewing", function()
				expect(Seq.skippableAfter(nil)):toBe(false)
				expect(Seq.skippableAfter(false)):toBe(false)
				expect(Seq.skippableAfter(0)):toBe(false)
				expect(Seq.skippableAfter(-2)):toBe(false)
				expect(Seq.skippableAfter(0 / 0)):toBe(false)
				expect(Seq.skippableAfter("1")):toBe(false)
				expect(Seq.skippableAfter({})):toBe(false)
				expect(Seq.skippableAfter(1)):toBe(true)
				expect(Seq.skippableAfter(7)):toBe(true)
				expect(Seq.skippableAfter(true)):toBe(true)
			end)

			t:it("feeds the sequencer option", function()
				expect(Seq.new(shots(1), { skippable = Seq.skippableAfter(nil) }).isSkippable()):toBe(false)
				expect(Seq.new(shots(1), { skippable = Seq.skippableAfter(1) }).isSkippable()):toBe(true)
			end)
		end)

		t:describe("RaidCutscene config", function()
			t:it("has establish, three zooms, walkin, letter in order", function()
				local kinds = {}
				for _, shot in RaidCutscene.shots do
					table.insert(kinds, shot.kind)
				end
				expect(kinds):toEqual({ "establish", "zoom", "zoom", "zoom", "walkin", "letter" })
			end)

			t:it("has unique ids, valid kinds and positive finite durations", function()
				local seen = {}
				for _, shot in RaidCutscene.shots do
					expect(type(shot.id)):toBe("string")
					expect(seen[shot.id]):toBeNil()
					seen[shot.id] = true
					expect(Seq.KINDS[shot.kind]):toBe(true)
					expect(shot.duration > 0 and shot.duration < math.huge):toBeTruthy()
				end
				for _, kind in RaidCutscene.kinds do
					expect(Seq.KINDS[kind]):toBe(true)
				end
			end)

			t:it("totals roughly 6 to 8 seconds and ends on the letter with the choices", function()
				local total = RaidCutscene.totalDuration()
				expect(total):toBeAtLeast(6)
				expect(total):toBeAtMost(8)
				local last = RaidCutscene.shots[#RaidCutscene.shots]
				expect(last.kind):toBe("letter")
				expect(last.holdsChoices):toBe(true)
			end)

			t:it("plays through the sequencer to its last shot", function()
				local seq = Seq.new(RaidCutscene.shots)
				local log = record(seq)
				seq.play()
				seq.step(RaidCutscene.totalDuration() + 0.01)
				expect(log.ids[#log.ids]):toBe("letter")
				expect(#log.ids):toBe(#RaidCutscene.shots)
				expect(log.finished):toBe(1)
				expect(seq.totalDuration()):toBeNear(RaidCutscene.totalDuration(), 1e-9)
			end)

			t:it("names the seen attribute", function()
				expect(RaidCutscene.seenAttribute):toBe("RaidCutsceneSeen")
			end)

			t:it("exposes real world anchors for kades, police and road (Track F)", function()
				local a = RaidCutscene.focusAnchors
				for _, focus in ipairs({ "kades", "police_chief", "road" }) do
					expect(type(a[focus])):toBe("table")
					expect(type(a[focus].x)):toBe("number")
					expect(type(a[focus].y)):toBe("number")
					expect(type(a[focus].z)):toBe("number")
				end
				-- The anchors sit on the NPC front spots (MapSpec.NPC_SPOTS), NOT the building
				-- centres: the reviewer found the old hub-centre anchors filmed the back of the
				-- buildings. Pak RT NPC (68,47), Polisi NPC (-68,42), at head height (~5.7).
				expect(a.kades.x):toBe(68)
				expect(a.kades.z):toBe(47)
				expect(a.police_chief.x):toBe(-68)
				expect(a.police_chief.z):toBe(42)
				expect(a.kades.y):toBeAtLeast(5)
				expect(a.police_chief.y):toBeAtLeast(5)
			end)

			t:it("anchors match the MapSpec NPC front spots the buildings are fronted by", function()
				local spots = {}
				for _, spot in MapSpec.NPC_SPOTS do
					spots[spot.npc] = spot
				end
				expect(RaidCutscene.focusAnchors.kades.x):toBe(spots.pakrt.x)
				expect(RaidCutscene.focusAnchors.kades.z):toBe(spots.pakrt.z)
				expect(RaidCutscene.focusAnchors.police_chief.x):toBe(spots.polisi.x)
				expect(RaidCutscene.focusAnchors.police_chief.z):toBe(spots.polisi.z)
				-- The NPC spots must actually be on the -z side of their hub centres.
				expect(spots.pakrt.z):toBeLessThan(MapSpec.hub("pakrt").z)
				expect(spots.polisi.z):toBeLessThan(MapSpec.hub("polisi").z)
			end)

			t:it("anchorFor resolves known focuses and returns nil otherwise", function()
				expect(RaidCutscene.anchorFor("kades")):toBeTruthy()
				expect(RaidCutscene.anchorFor("road")):toBeTruthy()
				expect(RaidCutscene.anchorFor("player")):toBeNil() -- no anchor: caller uses player-relative fallback
				expect(RaidCutscene.anchorFor("mars")):toBeNil()
				expect(RaidCutscene.anchorFor(nil)):toBeNil()
				expect(RaidCutscene.anchorFor(42)):toBeNil()
			end)

			-- Pure camera framing (review finding: anchored shots filmed the wrong side of the
			-- buildings). Every anchored eye must sit on the -z front where the NPC stands and
			-- outside all six hub footprints, so no building blocks the shot.
			t:describe("cameraFor (front-side framing)", function()
				-- Axis-aligned footprint of a hub; yaw 90/270 swaps width and depth.
				local function insideHub(hub, p)
					local halfX, halfZ = hub.width / 2, hub.depth / 2
					if hub.yaw == 90 or hub.yaw == 270 then
						halfX, halfZ = halfZ, halfX
					end
					return math.abs(p.x - hub.x) <= halfX and math.abs(p.z - hub.z) <= halfZ
				end

				local function shots()
					return RaidCutscene.shots
				end

				t:it("returns nil for unanchored focuses, letter/establish kinds and junk", function()
					expect(RaidCutscene.cameraFor({ kind = "zoom", focus = "player" }, 0, 0)):toBeNil()
					expect(RaidCutscene.cameraFor({ kind = "establish", focus = "plot" }, 0, 0)):toBeNil()
					expect(RaidCutscene.cameraFor({ kind = "letter" }, 0, 0)):toBeNil()
					expect(RaidCutscene.cameraFor(nil, 0, 0)):toBeNil()
				end)

				t:it("frames kades and police from the -z front, targeting the NPC head", function()
					local zoom2 = shots()[3] -- kades, yaw -18
					local k = RaidCutscene.cameraFor(zoom2, 0, State.focusOffset("kades"))
					expect(k):toBeTruthy()
					expect(k.target.x):toBe(68)
					expect(k.target.z):toBe(47)
					expect(k.target.y):toBeNear(RaidCutscene.focusAnchors.kades.y, 1e-9)
					expect(k.eye.z):toBeLessThan(k.target.z) -- front side
					expect(k.eye.y):toBeGreaterThan(k.target.y)
					local zoom3 = shots()[4] -- police_chief, yaw 18
					local p = RaidCutscene.cameraFor(zoom3, 0, State.focusOffset("police_chief"))
					expect(p):toBeTruthy()
					expect(p.target.x):toBe(-68)
					expect(p.target.z):toBe(42)
					expect(p.eye.z):toBeLessThan(p.target.z)
				end)

				t:it("keeps the walk-in eye on the -z side across the whole dolly", function()
					local walkin = shots()[5]
					for _, progress in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
						local f = RaidCutscene.cameraFor(walkin, progress, State.focusOffset("road"))
						expect(f):toBeTruthy()
						expect(f.eye.z):toBeLessThan(f.target.z)
						expect(f.target.z):toBe(-28)
					end
				end)

				t:it("clamps junk/out-of-range walk-in progress to the 0..1 dolly", function()
					local walkin = shots()[5]
					local before = RaidCutscene.cameraFor(walkin, 0, 0)
					local junk = RaidCutscene.cameraFor(walkin, "x", 0)
					local over = RaidCutscene.cameraFor(walkin, 5, 0)
					expect(junk.eye.z):toBeNear(before.eye.z, 1e-9)
					expect(over.eye.z):toBeGreaterThan(before.eye.z) -- smaller stand-off, still -z
					expect(over.eye.z):toBeLessThan(over.target.z)
				end)

				t:it("puts every anchored shot's eye outside all six hub footprints at every progress", function()
					local anchored = 0
					for _, shot in shots() do
						for _, progress in ipairs({ 0, 0.5, 1 }) do
							local f = RaidCutscene.cameraFor(shot, progress, State.focusOffset(shot.focus))
							if f then
								anchored += 1
								for _, hub in MapSpec.HUBS do
									expect(insideHub(hub, f.eye)):toBe(false)
								end
							end
						end
					end
					expect(anchored):toBeAtLeast(9) -- kades + police (zoom) + road (walkin) x 3 progresses
				end)
			end)

			t:describe("CutsceneState (overlay wiring decisions)", function()
				-- Replays the raid shots through the sequencer and collects the ui flags per shot.
				local function uiPerShot()
					local seq = Seq.new(RaidCutscene.shots)
					local ui = nil
					local out = {}
					seq.onShot(function(shot)
						ui = State.uiFor(shot.kind, ui)
						out[shot.id] = ui
					end)
					seq.play()
					seq.step(RaidCutscene.totalDuration() + 0.01)
					return out
				end

				t:it("shows the lower third from the first zoom until the letter", function()
					local ui = uiPerShot()
					expect(ui.establish.lowerThird):toBe(false)
					expect(ui.zoom1.lowerThird):toBe(true)
					expect(ui.zoom2.lowerThird):toBe(true)
					expect(ui.zoom3.lowerThird):toBe(true)
					expect(ui.walkin.lowerThird):toBe(true)
					expect(ui.letter.lowerThird):toBe(false)
				end)

				t:it("shows the letter card only from the letter shot", function()
					local ui = uiPerShot()
					expect(ui.walkin.letter):toBe(false)
					expect(ui.letter.letter):toBe(true)
				end)

				t:it("copes with a missing previous state and junk kinds", function()
					local ui = State.uiFor("zoom", nil)
					expect(ui.lowerThird):toBe(true)
					expect(ui.letter):toBe(false)
					ui = State.uiFor(42, "junk")
					expect(ui.lowerThird):toBe(false)
					expect(ui.letter):toBe(false)
				end)

				t:it("ended ui has no lower third and the letter card up", function()
					local ui = State.endedUi()
					expect(ui.lowerThird):toBe(false)
					expect(ui.letter):toBe(true)
				end)

				t:it("counts viewings from the seen attribute", function()
					expect(State.nextSeen(nil)):toBe(1)
					expect(State.nextSeen(0)):toBe(1)
					expect(State.nextSeen(1)):toBe(2)
					expect(State.nextSeen(4.7)):toBe(5)
					expect(State.nextSeen(true)):toBe(2)
					expect(State.nextSeen(-3)):toBe(1)
					expect(State.nextSeen(0 / 0)):toBe(1)
					expect(State.nextSeen(math.huge)):toBe(1)
					expect(State.nextSeen("2")):toBe(1)
				end)

				t:it("a completed viewing makes the next one skippable, a cancelled one does not", function()
					local seen = nil
					local first = Seq.new(shots(1), { skippable = Seq.skippableAfter(seen) })
					expect(first.isSkippable()):toBe(false)
					first.onFinished(function()
						seen = State.nextSeen(seen)
					end)
					first.play()
					first.step(0.5)
					first.cancel()
					expect(seen):toBeNil()
					local second = Seq.new(shots(1))
					second.onFinished(function()
						seen = State.nextSeen(seen)
					end)
					second.play()
					second.step(1)
					expect(Seq.skippableAfter(seen)):toBe(true)
				end)

				t:it("camera restore keeps only the first capture until released", function()
					local restore = State.newCameraRestore()
					expect(restore.isCaptured()):toBe(false)
					expect(restore.release()):toBeNil()
					expect(restore.capture("Custom", 72)):toBe(true)
					expect(restore.capture("Scriptable", 30)):toBe(false)
					expect(restore.isCaptured()):toBe(true)
					local saved = restore.release()
					expect(saved.cameraType):toBe("Custom")
					expect(saved.fov):toBe(72)
					expect(restore.isCaptured()):toBe(false)
					expect(restore.release()):toBeNil()
					expect(restore.capture("Follow", 70)):toBe(true)
				end)

				t:it("gives each focus a yaw and unknown focus none", function()
					expect(State.focusOffset("kades")):toBe(-18)
					expect(State.focusOffset("police_chief")):toBe(18)
					expect(State.focusOffset("player")):toBe(0)
					expect(State.focusOffset(nil)):toBe(0)
					expect(State.focusOffset("mars")):toBe(0)
				end)
			end)
		end)
	end)
end
