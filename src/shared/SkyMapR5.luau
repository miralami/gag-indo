--!strict
-- SkyMapR5: pure data for the OFF-BY-DEFAULT "sky_r5" Indonesian bright/humid
-- candidate (WORK_QUEUE item 38). No asset ID literal lives here: both sets are
-- the two already-uploaded CC0 Poly Haven sets from Shared.SkyMapR4, referenced
-- directly so every ID provably comes from a completed Open Cloud upload. No
-- Roblox APIs, engine value types or instances: colours stay plain {r,g,b}
-- triples and become engine colours only in the client applier. No visual claim.

local SkyMapR4 = require(script.Parent.SkyMapR4)

local SkyMapR5 = {}

-- The six exact Roblox Sky face property names, inherited from the verified r4 data.
SkyMapR5.faceKeys = SkyMapR4.faceKeys

-- a = primary bright/humid coastal afternoon, b = alternate golden-hour beach.
-- Reuse the two real-ID CC0 sets; the two newly researched HDRIs in
-- docs/v2/visual/art/sky_r5/README.md are NOT uploaded and are not used here.
SkyMapR5.sets = {
	a = SkyMapR4.sets.a,
	b = SkyMapR4.sets.b,
}

SkyMapR5.primaryKey = "a"
SkyMapR5.alternateKey = "b"

-- Bright, humid grade for a high sun and a soft blue horizon. Haze/Decay are
-- plain numbers / {r,g,b} triples; Decay is a colour, not a number (r3 bug fix).
-- The sun-toggle property is deliberately absent: the day cycle still owns it.
SkyMapR5.atmosphere = {
	Density = 0.26,
	Color = { 232, 240, 244 },
	Decay = { 40, 58, 74 },
	Offset = 0.62,
	Glare = 1.4,
	Haze = 3.0,
}

-- Bug fix: the live scenes ship Clouds.Cover = 1, which hides every skybox.
-- This candidate lowers Terrain Clouds.Cover to this value while active and
-- restores the exact prior value on disable. Must stay within 0.3-0.5.
SkyMapR5.cloudCover = 0.4

-- Bug fix: r4's 12-wedge ridge sat in the middle of the spawn plaza as giant
-- black slabs. No ridge is built for r5. A horizon ridge belongs to a LATER LEVEL,
-- not to this sky candidate.
SkyMapR5.ridgeEnabled = false

function SkyMapR5.faceCount(): number
	return #SkyMapR5.faceKeys
end

return SkyMapR5
