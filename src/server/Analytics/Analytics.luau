-- Analytics: tiny wrapper so gameplay events don't crash when API access is off
-- (Studio without "Enable Studio Access to API Services" would otherwise error).

local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

function Analytics.log(player: Player, eventName: string, value: number?)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 0)
	end)
	if not ok then
		-- Silent: analytics must never break gameplay.
		local _ = err
	end
end

return Analytics
