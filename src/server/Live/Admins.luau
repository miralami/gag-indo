-- Admins: in-game admin allowlist (v2 PLAN §7.1). Server-only, never replicated.
--
-- Put real Roblox user IDs in `userIds`. Names are shown in the panel only; IDs decide.
-- Empty by default, so a published place has no admins until you add yourself.

local Admins = {}

Admins.userIds = {
	-- 123456789, -- your Roblox UserId
}

function Admins.isAdmin(userId: number): boolean
	return table.find(Admins.userIds, userId) ~= nil
end

return Admins
