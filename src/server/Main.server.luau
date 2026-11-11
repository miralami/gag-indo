-- Server bootstrap. Starts services in a fixed order (TECH.md §3).
-- Requiring a module must not yield; all work happens in start().

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
require(Shared.Remotes) -- creates the RemoteEvents before any client asks for them

local PlayerData = require(script.Parent.Data.PlayerData)
local LiveConfig = require(script.Parent.Live.LiveConfig)
local SeasonService = require(script.Parent.Season.SeasonService)
local AdminService = require(script.Parent.Live.AdminService)
local State = require(script.Parent.Net.State)
local Village = require(script.Parent.World.Village)
local PlotService = require(script.Parent.Farm.PlotService)
local RankService = require(script.Parent.Progression.RankService)
local EconomyService = require(script.Parent.Economy.EconomyService)
local MarketService = require(script.Parent.Economy.MarketService)
local ShopService = require(script.Parent.Economy.ShopService)
local ToolService = require(script.Parent.Farm.ToolService)
local StorageService = require(script.Parent.Farm.StorageService)
local WorkerService = require(script.Parent.Farm.WorkerService)
local FarmService = require(script.Parent.Farm.FarmService)
local SusService = require(script.Parent.Law.SusService)
local CheatService = require(script.Parent.Law.CheatService)
local EvidenceService = require(script.Parent.Law.EvidenceService)
local RaidService = require(script.Parent.Law.RaidService)
local BribeService = require(script.Parent.Law.BribeService)
local NeighborService = require(script.Parent.Progression.NeighborService)
local OnboardingService = require(script.Parent.Progression.OnboardingService)
local WarungService = require(script.Parent.World.WarungService)
local CabaiEvent = require(script.Parent.Events.CabaiEvent)
local Passes = require(script.Parent.Monetization.Passes)
local Receipts = require(script.Parent.Monetization.Receipts)
local Items = require(script.Parent.Monetization.Items)
local Cosmetics = require(script.Parent.Monetization.Cosmetics)

-- World first: plots are added to the folder Village creates.
LiveConfig.start() -- attributes + admin state exist before any service reads them
SeasonService.start() -- growth multipliers for the current season/anomaly
Village.build()
PlotService.build()

-- RaidService must not require SusService (SusService already requires RaidService),
-- so the reset is injected once here.
RaidService.bindSus({
	set = SusService.setSus,
	add = SusService.add,
})

-- Raids resolve as a fine when a player leaves, before the profile is released.
RaidService.init()

MarketService.start() -- price board before anyone can sell
EconomyService.start()
ShopService.start() -- shelves must exist before State's first snapshot
ToolService.start()
StorageService.start()
FarmService.start()
WorkerService.start()
RankService.start()
SusService.start()
CheatService.start()
EvidenceService.start()
BribeService.start()
NeighborService.start()
OnboardingService.start()
WarungService.start()
CabaiEvent.start()
State.start()
AdminService.start()
Passes.start()
Receipts.start()
Items.start()
Cosmetics.start()
PlayerData.start() -- last: loads profiles, which fires onLoaded callbacks registered above

print("[JuraganDesa] server started")
