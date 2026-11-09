-- Per-player, per-action token bucket. Use at the top of every remote / prompt handler.
--   if not RateLimit.allow(player, "Shop_BuySeed", 2) then return end

local Players = game:GetService("Players")

local RateLimit = {}

local buckets: { [Player]: { [string]: { tokens: number, last: number } } } = {}

-- perSecond = refill rate; burst = max tokens (defaults to perSecond)
function RateLimit.allow(player: Player, key: string, perSecond: number, burst: number?): boolean
	local maxTokens = burst or perSecond
	local now = os.clock()
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local bucket = playerBuckets[key]
	if not bucket then
		bucket = { tokens = maxTokens, last = now }
		playerBuckets[key] = bucket
	end
	bucket.tokens = math.min(maxTokens, bucket.tokens + (now - bucket.last) * perSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

return RateLimit
