-- CabaiEvent: "Harga Cabai Meroket" (GDD §3.2). Cabai sells x3 for a few minutes, then
-- goes back to normal. The event flag is a ReplicatedStorage attribute so the HUD can show
-- its banner without another remote, and joining players see the current state for free.
-- EconomyService is the only reader; this module never touches cash.
--
-- v2: LiveConfig can force the event on or off (admin panel). "auto" keeps the v1 timer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local LiveConfig = require(script.Parent.Parent.Live.LiveConfig)

local Notify = require(script.Parent.Parent.Net.Notify)

local CabaiEvent = {}

local activeUntil = 0
local lastEffective = false

local function mode(): string
	local config = LiveConfig.get()
	local events = if type(config) == "table" then config.events else nil
	local cabai = if type(events) == "table" then events.cabai else nil
	return if cabai == "on" or cabai == "off" then cabai else "auto"
end

-- Multiplier for one crop at the current moment (1 when the event is off).
function CabaiEvent.multiplier(cropId: string): number
	if cropId == "cabai" and CabaiEvent.isActive() then
		return GameConfig.cabaiEventMultiplier
	end
	return 1
end

function CabaiEvent.isActive(): boolean
	local current = mode()
	if current == "off" then
		return false
	end
	if current == "on" then
		return true
	end
	return os.time() < activeUntil
end

-- Push the effective state to the attribute and announce transitions once.
local function syncFlag()
	local active = CabaiEvent.isActive()
	ReplicatedStorage:SetAttribute("CabaiEvent", active)
	if active == lastEffective then
		return
	end
	lastEffective = active
	if active then
		Notify.broadcast("event_cabai_start", GameConfig.cabaiEventMultiplier)
	else
		Notify.broadcast("event_cabai_end")
	end
end

local function startTimer()
	activeUntil = os.time() + GameConfig.cabaiEventDuration
	syncFlag()
end

local function stopTimer()
	activeUntil = 0
	syncFlag()
end

function CabaiEvent.start()
	LiveConfig.onChanged(function()
		syncFlag()
	end)
	syncFlag()

	task.spawn(function()
		task.wait(GameConfig.cabaiEventFirstDelay)
		while true do
			if mode() == "auto" then
				startTimer()
				task.wait(GameConfig.cabaiEventDuration)
				if mode() == "auto" then
					stopTimer()
				end
				task.wait(math.max(30, GameConfig.cabaiEventInterval - GameConfig.cabaiEventDuration))
			else
				-- An admin has taken over; poll until the event is back on auto.
				task.wait(5)
			end
		end
	end)
end

return CabaiEvent
