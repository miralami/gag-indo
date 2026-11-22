--!nocheck
-- SoundMap spec (WORK_QUEUE round 2 item 9): two free Creator Store music-bed CANDIDATES behind
-- an off-by-default LookDev flag. The shipping Config/Audio slots for these keys stay id=0.
-- The IDs below are the real, verified-in-Studio values recorded in ASSET_MANIFEST.md.

return function(t, Env)
	local expect = t.expect
	local SoundMap, AudioConfig

	t:describe("SoundMap candidate registry", function()
		t:beforeEach(function()
			local env = Env.new()
			SoundMap = env:require("shared/SoundMap")
			AudioConfig = env:require("shared/Config/Audio")
		end)

		t:it("holds the two verified Creator Store IDs for the empty music slots", function()
			expect(SoundMap.candidateIds.music_sawah):toBe(9042889348)
			expect(SoundMap.candidateIds.music_hutan):toBe(9048807207)
			local count = 0
			for _ in SoundMap.candidateIds do
				count += 1
			end
			expect(count):toBe(2)
		end)

		t:it("has a stable review order covering exactly the candidate keys", function()
			expect(#SoundMap.candidateOrder):toBe(2)
			expect(SoundMap.candidateOrder[1]):toBe("music_sawah")
			expect(SoundMap.candidateOrder[2]):toBe("music_hutan")
			for _, key in SoundMap.candidateOrder do
				expect(type(SoundMap.candidateIds[key]) == "number"):toBe(true)
			end
		end)

		t:it("builds asset URLs only for real ids, keeping the literal out of the adapter", function()
			expect(SoundMap.assetUrl("music_sawah")):toBe("rbxassetid://9042889348")
			expect(SoundMap.assetUrl("music_hutan")):toBe("rbxassetid://9048807207")
			expect(SoundMap.assetUrl("no_such_sound")):toBe(nil)
		end)

		t:it("exposes a playable set for the round-1 AudioPolicy", function()
			local playable = SoundMap.playable()
			expect(playable.music_sawah):toBe(true)
			expect(playable.music_hutan):toBe(true)
			expect(playable.no_such_sound):toBe(nil)
		end)

		t:it("keeps both shipping config slots at id 0", function()
			expect(AudioConfig.sounds.music_sawah.id):toBe(0)
			expect(AudioConfig.sounds.music_hutan.id):toBe(0)
			-- Both are looping music beds so the round-1 policy can transition them.
			expect(AudioConfig.sounds.music_sawah.group):toBe("music")
			expect(AudioConfig.sounds.music_hutan.group):toBe("music")
			expect(AudioConfig.sounds.music_sawah.looped):toBe(true)
			expect(AudioConfig.sounds.music_hutan.looped):toBe(true)
		end)

		t:it("is off by default and toggles with applyCandidates", function()
			expect(SoundMap.usingCandidates()):toBe(false)
			SoundMap.applyCandidates(true)
			expect(SoundMap.usingCandidates()):toBe(true)
			SoundMap.applyCandidates(false)
			expect(SoundMap.usingCandidates()):toBe(false)
		end)
	end)
end
