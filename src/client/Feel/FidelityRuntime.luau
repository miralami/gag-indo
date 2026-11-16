-- FidelityRuntime (VISUAL_MASTER_PLAN section 6, V0.2): the live wiring around FidelityTier.
-- One controller per client, fed from RunService.Heartbeat, with the tier mirrored to the local
-- Player attribute "FidelityTier" for debugging. Visuals do not read it yet.
--
-- Roblox calls sit behind deps so a Lune spec can drive it:
--   start({ heartbeat = { Connect = fn }, player = { SetAttribute = fn }, clock = fn, setting = tier? })
-- When deps are omitted the real RunService.Heartbeat, Players.LocalPlayer and os.clock are used.

local FidelityTier = require(script.Parent.FidelityTier)

local FidelityRuntime = {}

local controller = nil
local connection = nil
local player = nil

local function publish(tier: string)
	if player and player.SetAttribute then
		pcall(player.SetAttribute, player, "FidelityTier", tier)
	end
end

-- Builds the singleton once; later calls return the same controller.
function FidelityRuntime.start(deps: any?)
	if controller then
		return controller
	end
	deps = deps or {}

	local heartbeat = deps.heartbeat
	if not heartbeat then
		heartbeat = game:GetService("RunService").Heartbeat
	end
	player = deps.player
	if not player then
		player = game:GetService("Players").LocalPlayer
	end

	controller = FidelityTier.new({
		clock = deps.clock or os.clock,
		setting = deps.setting,
		override = deps.override,
	})
	controller.onChanged(publish)
	publish(controller.get())

	connection = heartbeat:Connect(function(dt)
		controller.step(dt)
	end)
	return controller
end

-- Test and teardown helper: drops the singleton so start() can build a fresh one.
function FidelityRuntime.stop()
	if connection then
		connection:Disconnect()
	end
	connection = nil
	controller = nil
	player = nil
end

function FidelityRuntime.isStarted(): boolean
	return controller ~= nil
end

-- Before start() the answers are the default-start tier, so a caller never has to nil-check.
function FidelityRuntime.get(): string
	if controller then
		return controller.get()
	end
	return FidelityTier.DEFAULT_START
end

function FidelityRuntime.settings()
	if controller then
		return controller.settings()
	end
	return FidelityTier.settingsFor(FidelityTier.DEFAULT_START)
end

-- Returns a disconnect function (a no-op before start()).
function FidelityRuntime.onChanged(callback: (string, string, any) -> ()): () -> ()
	if controller then
		return controller.onChanged(callback)
	end
	return function() end
end

function FidelityRuntime.beginMoment()
	if controller then
		controller.beginMoment()
	end
end

function FidelityRuntime.endMoment()
	if controller then
		controller.endMoment()
	end
end

function FidelityRuntime.setOverride(tier: string?)
	if controller then
		controller.setOverride(tier)
	end
end

function FidelityRuntime.setSetting(setting: string?)
	if controller then
		controller.setSetting(setting)
	end
end

return FidelityRuntime
