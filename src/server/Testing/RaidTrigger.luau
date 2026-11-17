-- RaidTrigger: pure policy for the Studio-only force-raid test hook.
--
-- The hook itself lives in Harness.luau (`raid` action) and is gated by the exact same allowlist
-- as every other harness hook: RunService:IsStudio() AND the in-memory flag AND Admins.isAdmin.
-- The flag is never written to a DataStore and the studio condition is impossible in a published
-- server, so a forced raid can never ship enabled. This module holds the decision + payload policy
-- as pure functions so tests/specs/raid_trigger_spec.luau can prove the gate without a game.

local Gate = require(script.Parent.Gate)

local RaidTrigger = {}

-- The gate policy, shared with the harness via Gate. All three conditions must be literal true:
-- a truthy-but-not-boolean value, a published server, a closed flag or a non-admin all refuse.
function RaidTrigger.allowed(opts): boolean
	return Gate.allowed(opts)
end

-- Normalize the optional hook payload. Only a literal `viral = true` forces a VIRAL raid;
-- everything else is a normal raid (which keeps the amplop choice available for the test).
function RaidTrigger.viral(value): boolean
	return type(value) == "table" and value.viral == true
end

return RaidTrigger
