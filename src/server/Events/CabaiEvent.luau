-- CabaiEvent: "Harga Cabai Meroket" (GDD §3.2). Cabai sells x3 for a few minutes, then
-- goes back to normal. The event flag is a ReplicatedStorage attribute so the HUD can show
-- its banner without another remote, and joining players see the current state for free.
-- EconomyService is the only reader; this module never touches cash.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)

local Notify = require(script.Parent.Parent.Net.Notify)

local CabaiEvent = {}

local activeUntil = 0

-- Multiplier for one crop at the current moment (1 when the event is off).
function CabaiEvent.multiplier(cropId: string): number
	if cropId == "cabai" and os.time() < activeUntil then
		return GameConfig.cabaiEventMultiplier
	end
	return 1
end

function CabaiEvent.isActive(): boolean
	return os.time() < activeUntil
end

local function start()
	activeUntil = os.time() + GameConfig.cabaiEventDuration
	ReplicatedStorage:SetAttribute("CabaiEvent", true)
	Notify.broadcast("event_cabai_start", GameConfig.cabaiEventMultiplier)
end

local function stop()
	activeUntil = 0
	ReplicatedStorage:SetAttribute("CabaiEvent", false)
	Notify.broadcast("event_cabai_end")
end

function CabaiEvent.start()
	task.spawn(function()
		task.wait(GameConfig.cabaiEventFirstDelay)
		while true do
			start()
			task.wait(GameConfig.cabaiEventDuration)
			stop()
			task.wait(math.max(30, GameConfig.cabaiEventInterval - GameConfig.cabaiEventDuration))
		end
	end)
end

return CabaiEvent
