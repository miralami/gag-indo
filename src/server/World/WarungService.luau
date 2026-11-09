-- WarungService: the warung is the village hangout (GDD §8). Nongkrong shows a random
-- rumor; the VIP Warung pass gets a VIP line. Pure flavor: no cash, no Sus, no saves.

local RateLimit = require(script.Parent.Parent.Net.RateLimit)
local Notify = require(script.Parent.Parent.Net.Notify)
local Village = require(script.Parent.Village)

local WarungService = {}

local RUMORS = {
	"warung_rumor_1",
	"warung_rumor_2",
	"warung_rumor_3",
	"warung_rumor_4",
}

local function onWarung(player: Player)
	if not RateLimit.allow(player, "Warung", 1, 1) then
		return
	end
	local key = if player:GetAttribute("Pass_VIPWarung")
		then "warung_vip"
		else RUMORS[math.random(#RUMORS)]
	Notify.send(player, key)
end

function WarungService.start()
	Village.onWarung(onWarung)
end

return WarungService
