--!strict
-- SoundMap: free Creator Store music-bed CANDIDATES for the two empty music slots (WORK_QUEUE
-- round 2 item 9). Both are LookDev candidates AWAITING DESIGNER YES/NO — none approved, none
-- shipped on by default. The IDs live here, NOT in LookDev or its adapters, so LookDev's "no asset
-- IDs" spec guard still holds. See docs/v2/visual/CANDIDATES.md and ASSET_MANIFEST.md.
--
-- The shipping config keeps Config/Audio.sounds.music_sawah / music_hutan at id=0. Only
-- src/client/World/LookDevSounds.luau applies these IDs, and only while the Studio-only "sounds"
-- candidate is enabled; disable() stops and destroys those Sounds.

local SoundMap = {}

SoundMap.candidateIds = {
	music_sawah = 9042889348, -- Close Your Eyes - 60 - No Melody, APMOfficial, free, 58.59 s
	music_hutan = 9048807207, -- Cavernous Wonders 60 A, APMOfficial, free, 60.97 s
}

-- Stable review order (the adapter and gallery use this, not table iteration order).
SoundMap.candidateOrder = { "music_sawah", "music_hutan" }

-- Build a Roblox asset URL from a candidate id. Keeping the "rbxassetid://" literal here (and NOT
-- in the LookDev adapter) mirrors how Visuals.applySurface owns the image URL literal, so the
-- adapter stays free of IDs and asset-URL tokens for the no-ID guard.
function SoundMap.assetUrl(key: string): string?
	local id = SoundMap.candidateIds[key]
	if type(id) == "number" and id > 0 and id % 1 == 0 then
		return "rbxassetid://" .. id
	end
	return nil
end

-- Set of keys resolving to a real candidate id — feeds the round-1 AudioPolicy.new playable set.
function SoundMap.playable(): { [string]: boolean }
	local out = {}
	for key, id in SoundMap.candidateIds do
		if type(id) == "number" and id > 0 and id % 1 == 0 then
			out[key] = true
		end
	end
	return out
end

local useCandidates = false

function SoundMap.applyCandidates(on: boolean)
	useCandidates = on == true
end

function SoundMap.usingCandidates(): boolean
	return useCandidates
end

return SoundMap
