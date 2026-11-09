-- Server bootstrap. Starts services in a fixed order (TECH.md §3).
-- Requiring a module must not yield; all work happens in start().

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
require(Shared.Remotes) -- creates the RemoteEvents before any client asks for them

local PlayerData = require(script.Parent.Data.PlayerData)
local PlotService = require(script.Parent.Farm.PlotService)
local EconomyService = require(script.Parent.Economy.EconomyService)
local FarmService = require(script.Parent.Farm.FarmService)

PlotService.build()
EconomyService.start()
FarmService.start()
PlayerData.start() -- last: loads profiles, which fires onLoaded callbacks registered above

print("[JuraganDesa] server started")
