-- TierThin: pure, deterministic decorative thinning by fidelity tier (WORK_QUEUE item 104).
--
-- No Roblox APIs, no Enum, no Instances: appliers pass a 1-based index and a structural flag, and
-- this module only decides keep/drop. Tier names follow Client.Feel.FidelityTier.
--
-- Ceiling: Rendah keeps at most 50% of DECORATIVE instances (floor(n/2) of n decoratives).
-- Structural instances (fences, bridge rails, doors, ...) are NEVER thinned at any tier.
-- Sedang currently keeps every instance; only Rendah thins. Unknown/nil tiers normalize to the
-- conservative Tinggi default (keep 100%), so existing behaviour and counts stay unchanged.

local TierThin = {}

TierThin.TIERS = { "Rendah", "Sedang", "Tinggi" }
TierThin.DEFAULT = "Tinggi"

local IS_TIER = {}
for _, tier in ipairs(TierThin.TIERS) do
	IS_TIER[tier] = true
end

-- Any unknown or nil value falls back to TierThin.DEFAULT ("Tinggi" = keep everything).
function TierThin.normalize(tier: any?): string
	return if type(tier) == "string" and IS_TIER[tier] then tier else TierThin.DEFAULT
end

-- `index` is 1-based. Deterministic: no RNG, no state, no clock.
function TierThin.shouldKeep(tier: any?, index: number, structural: boolean?): boolean
	if structural == true then
		return true
	end
	if TierThin.normalize(tier) ~= "Rendah" then
		return true
	end
	return index % 2 == 0
end

-- Pure arithmetic mirror of shouldKeep() over indexes 1..total, with the first `structuralCount`
-- entries structural. Rendah keeps every structural entry plus the even indexes among the rest:
-- floor(total/2) - floor(structural/2) decoratives, i.e. floor(total/2) + ceil(structural/2).
function TierThin.keptCount(tier: any?, total: number, structuralCount: number?): number
	if TierThin.normalize(tier) ~= "Rendah" then
		return total
	end
	local structural = math.max(0, math.min(type(structuralCount) == "number" and structuralCount or 0, total))
	return math.floor(total / 2) + math.ceil(structural / 2)
end

return TierThin
