-- RaidTrigger: pure policy for the Studio-only force-raid test hook.
--
-- The hook itself lives in Harness.luau (`raid` action) and is gated by the exact same allowlist
-- as every other harness hook: RunService:IsStudio() AND the in-memory flag AND Admins.isAdmin.
-- The flag is never written to a DataStore and the studio condition is impossible in a published
-- server, so a forced raid can never ship enabled. This module holds the decision + payload policy
-- as pure functions so tests/specs/raid_trigger_spec.luau can prove the gate without a game. It also
-- owns the temporary cooldown override used by `force` so that hook never mutates saved data.

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

-- Only a literal `force = true` asks for the cooldown override below. Everything else leaves the
-- saved cooldown alone. Pure so the harness handler's branch is testable without the game.
function RaidTrigger.force(value): boolean
	return type(value) == "table" and value.force == true
end

-- Applies a temporary `raidSafeUntil = 0` for the duration of `start`, then restores the exact
-- previous cooldown table and value — even if `start` throws — so the Studio-only force hook never
-- writes a zero cooldown into real save data. `data` is the live profile.Data table (PlayerData.get
-- returns it by reference), which is what makes the override visible to RaidService.start's cooldown
-- check. `start` is injected so tests can observe the value it saw and simulate an error.
function RaidTrigger.withTemporaryCooldown(data, start)
	if type(data) ~= "table" then
		start()
		return
	end
	local oldCooldowns = data.cooldowns -- may be nil or a non-table: restore it verbatim
	local cooldowns = if type(oldCooldowns) == "table" then oldCooldowns else {}
	data.cooldowns = cooldowns
	local oldValue = cooldowns.raidSafeUntil
	cooldowns.raidSafeUntil = 0
	local ok, err = pcall(start)
	-- Restore on both the success and error paths. Assigning nil removes the injected key so a
	-- cooldown that was absent stays absent.
	cooldowns.raidSafeUntil = oldValue
	data.cooldowns = oldCooldowns
	if not ok then
		error(err, 0)
	end
end

return RaidTrigger
