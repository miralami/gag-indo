-- BadgeService: awards Roblox badges safely (v2 PLAN §3.6).
--
-- BadgeService.award(player, badgeKey) verifies the badge exists, checks if id > 0,
-- and uses BadgeService:AwardBadge with pcall so network hiccups never break gameplay.

local BadgeServiceRoblox = game:GetService("BadgeService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Badges = require(Shared.Config.Badges)

local BadgeService = {}

function BadgeService.award(player: Player, badgeKey: string): boolean
	if not Badges.exists(badgeKey) then
		return false
	end
	local def = Badges.list[badgeKey]
	if not def or def.id <= 0 then
		-- In dev / studio with id 0, skip quietly
		return false
	end

	local ok, awarded = pcall(function()
		return BadgeServiceRoblox:AwardBadge(player.UserId, def.id)
	end)

	return ok and awarded == true
end

return BadgeService
