-- RarityService: the server-side rarity roll on harvest (v2 PLAN §3.2).
--
-- Pure and rng-injected so tests can pin the boundaries:
--   RarityService.roll(quality, rng) -> tierId
--
-- Base weights come from Config/Tiers. Minigame quality does not multiply the price directly;
-- it nudges the roll by adding weight to the rare tiers (super and up), roughly doubling them
-- for a perfect plant and harvest.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tiers = require(Shared.Config.Tiers)
local GameConfig = require(Shared.Config.Game)

local RarityService = {}

local function clampQuality(quality: any): number
	if type(quality) ~= "number" or quality ~= quality then
		return 0
	end
	return math.clamp(quality, 0, 3)
end

-- One tier's weight for a given quality. Exposed so the balance sheet can print the odds.
function RarityService.weight(tierId: string, quality: number?): number
	local tier = Tiers.list[tierId]
	if not tier then
		return 0
	end
	local weight = tier.chance
	if Tiers.isRare(tierId) then
		weight *= 1 + clampQuality(quality) * GameConfig.rarityQualityBoost
	end
	return weight
end

function RarityService.roll(quality: number?, rng: (() -> number)?): string
	local random = rng or math.random
	local weights = {}
	local total = 0
	for index, tierId in Tiers.order do
		local weight = RarityService.weight(tierId, quality)
		weights[index] = weight
		total += weight
	end
	local point = math.clamp(random(), 0, 0.999999) * total
	local acc = 0
	for index, tierId in Tiers.order do
		acc += weights[index] or 0
		if point < acc then
			return tierId
		end
	end
	return Tiers.default
end

return RarityService
