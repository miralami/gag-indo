-- Client bootstrap: mount the HUD, tile presentation, phone, minigame and raid overlay.
--
-- Every mount/start is isolated: one failing UI or feel module must never abort the rest of
-- the bootstrap. Each failure is warned exactly once, then the next module still runs.

local LocalizationService = game:GetService("LocalizationService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local Hud = require(script.Parent.UI.Hud)
local Tiles = require(script.Parent.UI.Tiles)
local Evidence = require(script.Parent.UI.Evidence)
local Phone = require(script.Parent.UI.Phone)
local Minigame = require(script.Parent.UI.Minigame)
local RaidOverlay = require(script.Parent.UI.RaidOverlay)
local Admin = require(script.Parent.UI.Admin)
local Leaderboard = require(script.Parent.UI.Leaderboard)
local NavBridge = require(script.Parent.UI.NavBridge)
local Sky = require(script.Parent.World.Sky)
local Wind = require(script.Parent.World.Wind)
local CameraFeel = require(script.Parent.Feel.CameraFeel)
local ActionFeel = require(script.Parent.Feel.ActionFeel)
local FidelityRuntime = require(script.Parent.Feel.FidelityRuntime)
local FpsSampler = require(script.Parent.Feel.FpsSampler)
local Audio = require(script.Parent.Audio)
local State = require(script.Parent.State)
local Tags = require(script.Parent.Chat.Tags)

local lang = Strings.langFor(LocalizationService.RobloxLocaleId)

-- Per-module error boundary. `reported` makes the "log once" guarantee explicit even if a
-- name is ever guarded twice; the failed module is skipped and the next one still mounts.
local reported = {}
local function guarded(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok and not reported[name] then
		reported[name] = true
		warn(`[Main.client] {name} failed to start: {tostring(err)}`)
	end
end

guarded("State.mount", function()
	State.mount()
end)
guarded("Audio.start", function()
	Audio.start()
end)
guarded("Sky.mount", function()
	Sky.mount()
end)
guarded("Wind.start", function()
	Wind.start()
end)
guarded("CameraFeel.start", function()
	CameraFeel.start()
end)
guarded("FidelityRuntime.start", function()
	FidelityRuntime.start()
end)
-- Studio-only: publishes ClientFps; no-op in a published place
guarded("FpsSampler.start", function()
	FpsSampler.start()
end)
guarded("ActionFeel.start", function()
	ActionFeel.start(lang)
end)

local hudGui
guarded("Hud.mount", function()
	hudGui = Hud.mount(lang)
end)
guarded("Evidence.mount", function()
	Evidence.mount(lang, hudGui)
end)
guarded("Phone.mount", function()
	Phone.mount(lang)
end)
guarded("Minigame.mount", function()
	Minigame.mount(lang)
end)
guarded("RaidOverlay.mount", function()
	RaidOverlay.mount(lang)
end)
guarded("Admin.mount", function()
	Admin.mount(lang)
end)
guarded("Leaderboard.mount", function()
	Leaderboard.mount(lang)
end)
guarded("Tags.mount", function()
	Tags.mount(lang)
end)
guarded("Tiles.mount", function()
	Tiles.mount(lang)
end)

-- B/Escape + default selection + hidden-frame rescue (WORK_QUEUE item 21). Start after all
-- screens have mounted and registered themselves with NavBridge.
guarded("NavBridge.start", function()
	NavBridge.start()
end)

-- Look-dev candidates (WORK_QUEUE item 9, round 2 item 4): register the OFF-BY-DEFAULT plaza
-- lighting and agent-made icon appliers. Isolated so a missing/failed candidate module can never
-- break the client bootstrap.
pcall(require, script.Parent.World.LookDevPlaza)
pcall(require, script.Parent.UI.LookDevIcons)
pcall(require, script.Parent.World.LookDevTextures)
pcall(require, script.Parent.World.LookDevNpcs)
pcall(require, script.Parent.World.LookDevCrops)
pcall(require, script.Parent.World.LookDevHubProps)
pcall(require, script.Parent.World.LookDevSounds)
pcall(require, script.Parent.World.LookDevCorner)
pcall(require, script.Parent.World.LookDevTexturesR3)
pcall(require, script.Parent.World.LookDevDayCycle)
pcall(require, script.Parent.UI.LookDevIconsR3)
pcall(require, script.Parent.World.LookDevSkyR3)
