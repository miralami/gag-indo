--!strict
-- WorldConstants: world values that both server and client need. Pure data, no requires, so it is safe
-- on the client. MapSpec re-exports these; nothing else keeps its own copy.

local WorldConstants = {}

-- Golden hour: canonical world lighting window (Config/Seasons sky presets target this range).
WorldConstants.GOLDEN_HOUR = { minClock = 16.0, maxClock = 17.0 }

-- Three in-world season presets (musim ids). Config/Seasons owns the full sky/growth data.
WorldConstants.SEASON_PRESETS = { "hujan", "kemarau", "pancaroba" }

return WorldConstants
