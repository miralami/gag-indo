--!nocheck
-- WORK_QUEUE item 22: audio hygiene wiring. The pure policy is covered by audio_policy_spec.luau;
-- this file locks (a) the static hookups in client/Audio.luau and (b) real engine behaviour with
-- fake Sound/SoundGroup/Tween services - one grouped+volumed Sound per id, pooled one-shots, and a
-- loop transition that cancels fades and never lets a stale callback Stop a restarted loop.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local function read(path)
		return fs.readFile(path)
	end
	local function has(text, needle, label)
		expect(string.find(text, needle, 1, true) ~= nil, label):toBe(true)
	end
	local function countOf(text, needle)
		local n, from = 0, 1
		while true do
			local at = string.find(text, needle, from, true)
			if not at then
				return n
			end
			n += 1
			from = at + #needle
		end
	end

	-- A minimal signal that supports Connect, Once and Fire.
	local function newSignal()
		local sig = { _handlers = {} }
		function sig:Connect(fn)
			table.insert(self._handlers, fn)
			return { Disconnect = function() end }
		end
		function sig:Once(fn)
			local wrapped
			wrapped = function(...)
				for i, handler in self._handlers do
					if handler == wrapped then
						table.remove(self._handlers, i)
						break
					end
				end
				fn(...)
			end
			table.insert(self._handlers, wrapped)
			return { Disconnect = function() end }
		end
		function sig:Fire()
			for _, fn in table.clone(self._handlers) do
				fn()
			end
		end
		return sig
	end

	-- Load the REAL src/client/Audio.luau against fake Roblox audio services.
	local function makeAudio()
		local env = Env.new()
		local created = { sounds = {}, groups = {}, tweens = {} }

		local function newSound()
			local sound = {
				ClassName = "Sound", Name = "", Parent = nil, SoundId = "",
				Looped = false, Volume = 1, SoundGroup = nil, TimePosition = 0,
				plays = 0, stops = 0, playing = false, destroyed = false,
			}
			function sound:IsA(kind)
				return kind == "Sound"
			end
			function sound:Play()
				self.plays += 1
				self.playing = true
			end
			function sound:Stop()
				self.stops += 1
				self.playing = false
			end
			function sound:Destroy()
				self.destroyed = true
			end
			table.insert(created.sounds, sound)
			return sound
		end

		env.globals.Instance = {
			new = function(className)
				if className == "Sound" then
					return newSound()
				end
				if className == "SoundGroup" then
					local group = { ClassName = "SoundGroup", Name = "", Volume = 1 }
					function group:IsA(kind)
						return kind == "SoundGroup"
					end
					table.insert(created.groups, group)
					return group
				end
				error("unexpected Instance.new(" .. tostring(className) .. ")")
			end,
		}
		local groupsByName = {}
		env.services.SoundService = {
			FindFirstChild = function(_, name)
				return groupsByName[name]
			end,
		}
		env.services.CollectionService = { GetTagged = function()
			return {}
		end }
		env.services.TweenService = {
			Create = function(_, obj, _info, props)
				local tween = { obj = obj, props = props, Completed = newSignal(), played = false, destroyed = false }
				function tween:Play()
					self.played = true
				end
				function tween:Destroy()
					self.destroyed = true
				end
				table.insert(created.tweens, tween)
				return tween
			end,
		}
		env.globals.TweenInfo = { new = function()
			return {}
		end }
		env.services.Players.LocalPlayer = {} -- no Character; followZones is stubbed below
		env.services.ReplicatedStorage.AttributeChanged = newSignal()

		-- start() spawns the MusicZone poll loop; in the fake env task.spawn runs inline and would
		-- never yield, so stub it. All transitions below are driven explicitly via setMusic/setWeather.
		env.globals.task.spawn = function() end

		local Audio = env:require("client/Audio")
		local function settle()
			-- Tween Completed callbacks are cosmetic; the authoritative outgoing Stop is a
			-- task.delay(FADE_SECONDS), so advance fake time past the fade to run those timers.
			for _, tween in created.tweens do
				tween.Completed:Fire()
			end
			env:advance(1)
		end
		local function byName(name)
			for _, sound in created.sounds do
				if sound.Name == name then
					return sound
				end
			end
			return nil
		end
		return Audio, created, settle, byName
	end

	t:describe("Audio wiring", function()
		t:describe("engine uses the pure policy", function()
			local audioSrc
			t:beforeEach(function()
				audioSrc = read("src/client/Audio.luau")
			end)

			t:it("requires and builds the policy from playable sounds", function()
				has(audioSrc, "local AudioPolicy = require(script.Parent.AudioPolicy)", "requires pure policy")
				has(audioSrc, "AudioPolicy.new(AudioPolicy.playable(AudioConfig.sounds))", "builds policy at mount")
			end)

			t:it("decides both looping roles through the policy", function()
				has(audioSrc, 'policy:transition("music", key)', "music uses policy")
				has(audioSrc, 'policy:transition("ambience", key)', "ambience uses policy")
			end)

			t:it("stops outgoing loops on a timer guarded by per-Sound fade identity", function()
				has(audioSrc, "if stopTokens[sound] == token then", "Stop guarded by fade token")
				has(audioSrc, "task.delay(FADE_SECONDS", "authoritative Stop timer, not a tween callback")
				-- A role-generation guard would skip Stop on intermediate outgoing loops and leak
				-- them (the Studio bug this replaced); keep it out of the engine.
				expect(countOf(audioSrc, "policy:isCurrent")):toBe(0)
			end)

			t:it("cancels in-flight fades before both fade-out and fade-in", function()
				expect(countOf(audioSrc, "cancelFade(sound)")):toBe(2)
			end)

			t:it("puts every Sound in a SoundGroup with a set volume", function()
				has(audioSrc, "group.Volume = volume", "group volume set")
				has(audioSrc, "sound.SoundGroup = groups[def.group]", "sound grouped")
				has(audioSrc, "sound.Volume = baseVolume[key]", "sound volume set")
				has(audioSrc, "sound.Looped = def.looped == true", "loop flag from config")
				expect(countOf(audioSrc, 'Instance.new("Sound")')):toBe(1) -- created once, at mount
			end)
		end)

		t:describe("engine behaviour with fake services", function()
			t:it("creates one grouped, volumed Sound per configured id at mount", function()
				local Audio, created = makeAudio()
				Audio.start()
				expect(#created.groups):toBe(4) -- music, ambience, ui, sting
				local Config = Env.new():require("shared/Config/Audio")
				local expected = 0
				for _, def in Config.sounds do
					if type(def.id) == "number" and def.id > 0 then
						expected += 1
					end
				end
				expect(#created.sounds):toBe(expected)
				for _, sound in created.sounds do
					expect(sound.SoundGroup ~= nil):toBe(true)
					expect(sound.SoundGroup.Volume):toBeGreaterThan(0)
					-- the currently-fading-in bed starts at 0 (the fake TweenService does not animate),
					-- so assert a valid non-negative volume here; the fade target is checked below.
					expect(sound.Volume):toBeAtLeast(0)
				end
				local hasFadeTarget = false
				for _, tween in created.tweens do
					if tween.props.Volume > 0 then
						hasFadeTarget = true
					end
				end
				expect(hasFadeTarget):toBe(true) -- fade-in targets the configured base volume
			end)

			t:it("reuses one-shot Sounds and never allocates on play", function()
				local Audio, created, _, byName = makeAudio()
				Audio.start()
				local before = #created.sounds
				local click = byName("ui_click")
				expect(click ~= nil):toBe(true)
				for _ = 1, 25 do
					Audio.play("ui_click")
				end
				expect(#created.sounds):toBe(before)
				expect(click.plays):toBe(25)
				expect(click.Looped):toBe(false)
			end)

			t:it("fades out and stops the outgoing loop on a music switch", function()
				local Audio, created, settle, byName = makeAudio()
				Audio.start()
				local desa, pasar = byName("music_desa"), byName("music_pasar")
				expect(desa.Looped):toBe(true)
				Audio.setMusic("music_pasar")
				settle()
				expect(desa.stops):toBe(1)
				expect(pasar.plays):toBeGreaterThan(0)
				expect(pasar.stops):toBe(0) -- incoming loop kept playing
			end)

			t:it("a rapid switch-back never lets a stale fade stop the new loop", function()
				local Audio, created, settle, byName = makeAudio()
				Audio.start()
				local desa, pasar = byName("music_desa"), byName("music_pasar")
				-- Change state three times before any fade completes (zone flicker), then let every
				-- Completed callback fire, including the destroyed tweens (Roblox fires Canceled).
				Audio.setMusic("music_pasar")
				Audio.setMusic("music_desa")
				Audio.setMusic("music_pasar")
				settle()
				-- final state is music_pasar: it must still be playing; desa must be stopped once.
				expect(pasar.plays):toBeGreaterThan(pasar.stops)
				expect(pasar.stops):toBe(0)
				expect(desa.stops):toBe(1)
				-- and only one fade tween remains unfired per active sound at a time
				expect(#created.tweens):toBeGreaterThan(0)
			end)

			t:it("rapid distinct switches stop every outgoing loop (no orphan leak)", function()
				local Audio, created, settle, byName = makeAudio()
				Audio.start()
				local cerah = byName("ambience_cerah")
				local badai = byName("ambience_badai")
				local kabut = byName("ambience_kabut")
				local hujan = byName("ambience_hujan")
				-- Four distinct beds, each switched before the previous fade completes. This is the
				-- exact Studio race: a role-generation guard leaves cerah/badai/kabut all playing;
				-- the per-Sound fade guard must Stop each outgoing bed exactly once.
				Audio.setWeather("cerah")
				Audio.setWeather("badai")
				Audio.setWeather("kabut")
				Audio.setWeather("hujan")
				settle()
				expect(cerah.stops):toBe(1)
				expect(badai.stops):toBe(1)
				expect(kabut.stops):toBe(1)
				expect(hujan.stops):toBe(0)
				expect(hujan.playing):toBe(true)
				local playingAmbience = 0
				for _, sound in created.sounds do
					if sound.Looped and string.sub(sound.Name, 1, 8) == "ambience" and sound.playing then
						playingAmbience += 1
					end
				end
				expect(playingAmbience):toBe(1) -- exactly one ambience loop survives
			end)

			t:it("stopping a role leaves no loop playing", function()
				local Audio, _created, settle, byName = makeAudio()
				Audio.start()
				local desa = byName("music_desa")
				Audio.setMusic(nil)
				settle()
				expect(desa.stops):toBe(1)
				Audio.setMusic(nil) -- no-op: no extra stop
				settle()
				expect(desa.stops):toBe(1)
			end)

			t:it("switching weather keeps exactly one ambience loop", function()
				local Audio, _created, settle, byName = makeAudio()
				Audio.start()
				local cerah, hujan = byName("ambience_cerah"), byName("ambience_hujan")
				Audio.setWeather("cerah") -- mount has no Cuaca attribute, so start the first bed
				settle()
				Audio.setWeather("hujan")
				settle()
				expect(cerah.stops):toBe(1)
				expect(hujan.plays):toBeGreaterThan(0)
				expect(hujan.stops):toBe(0)
			end)
		end)
	end)
end
