--!strict
-- NextGoal: the one goal the HUD guide card shows. Pure: takes the player's attributes and
-- returns which goal applies and the Strings key + params to render it. The HUD does the drawing.
--
-- Order: the tutorial wins while it runs; then the next rank (money first, then plots);
-- on the top rank the player is pointed at the daily tasks in the phone.

local Shared = script.Parent
local GameConfig = require(Shared.Config.Game)

export type Attrs = {
	tutorialStep: string?,
	rank: string?,
	lifetimeEarned: number?,
	tilesOwned: number?,
}

export type Goal = {
	kind: "tutorial" | "rank_money" | "rank_tiles" | "daily",
	key: string,
	params: { any },
}

local NextGoal = {}

function NextGoal.pick(attrs: Attrs): Goal
	local step = attrs.tutorialStep
	if type(step) == "string" and step ~= "" then
		return { kind = "tutorial", key = "tutorial_" .. step, params = {} }
	end

	local rank = attrs.rank or "gurem"
	local index = GameConfig.rankIndex[rank] or 1
	local nextRank = GameConfig.rankOrder[index + 1]
	if nextRank == nil then
		return { kind = "daily", key = "goal_daily", params = {} }
	end

	local requirement = GameConfig.rankRequirements[nextRank]
	local earned = attrs.lifetimeEarned or 0
	local tiles = attrs.tilesOwned or 0
	local moneyTarget = requirement.lifetimeEarned
	local tilesTarget = requirement.tilesOwned

	if earned < moneyTarget or tiles >= tilesTarget then
		return {
			kind = "rank_money",
			key = "goal_rank_money",
			params = { math.min(earned, moneyTarget), moneyTarget, "@rank_" .. nextRank },
		}
	end
	return {
		kind = "rank_tiles",
		key = "goal_rank_tiles",
		params = { tiles, tilesTarget, "@rank_" .. nextRank },
	}
end

return NextGoal
