-- Server bootstrap. Starts services in a fixed order (TECH.md §3).
-- Requiring a module must not yield; all work happens in start().

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
require(Shared.Remotes) -- creates the RemoteEvents before any client asks for them

local PlayerData = require(script.Parent.Data.PlayerData)
local LiveConfig = require(script.Parent.Live.LiveConfig)
local SeasonService = require(script.Parent.Season.SeasonService)
local AdminService = require(script.Parent.Live.AdminService)
local State = require(script.Parent.Net.State)
local RemoteGuards = require(script.Parent.Net.RemoteGuards)
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
local FirstSession = require(script.Parent.Progression.FirstSession)
local QuestService = require(script.Parent.Progression.QuestService)
local DebtService = require(script.Parent.Economy.DebtService)
local DebtCollector = require(script.Parent.Economy.DebtCollector)
local WarungService = require(script.Parent.World.WarungService)
local CabaiEvent = require(script.Parent.Events.CabaiEvent)
local Passes = require(script.Parent.Monetization.Passes)
local Receipts = require(script.Parent.Monetization.Receipts)
local Items = require(script.Parent.Monetization.Items)
local Cosmetics = require(script.Parent.Monetization.Cosmetics)
local LeaderboardService = require(script.Parent.Social.LeaderboardService)

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

-- Pinjol guardrails: no borrowing during a raid, and a visible collector at the plot.
DebtService.bindRaid({
	isBusy = function(player)
		return RaidService.isBusy(player)
	end,
})
DebtService.bindCollector({
	summon = function(player)
		DebtCollector.summon(player)
	end,
	dismiss = function(player)
		DebtCollector.dismiss(player)
	end,
})

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
FirstSession.start()
QuestService.start()
DebtService.start()
WarungService.start()
CabaiEvent.start()
RemoteGuards.start()
State.start()
AdminService.start()
require(script.Parent.Testing.Harness).start() -- Studio-only playtest hooks (docs/testing/HARNESS.md)
Passes.start()
Receipts.start()
Items.start()
Cosmetics.start()
LeaderboardService.start()
PlayerData.start() -- last: loads profiles, which fires onLoaded callbacks registered above

-- Look-dev candidates (WORK_QUEUE item 9, round 3 item 23): register the OFF-BY-DEFAULT police
-- walk-in and model-family appliers. Isolated so a missing/failed candidate module can never break
-- the server bootstrap. Model families use InsertService, which is server-only.
pcall(require, script.Parent.World.LookDevWalkin)
pcall(require, script.Parent.World.LookDevModelsR3)
pcall(require, script.Parent.World.LookDevModelsBuildingsR4)
pcall(require, script.Parent.World.LookDevModelsVegetationR4)
pcall(require, script.Parent.World.LookDevModelsPropsR4)
pcall(require, script.Parent.World.LookDevModelsNpcsR4)
pcall(require, script.Parent.World.LookDevSpawnGroundR5)
pcall(require, script.Parent.World.LookDevSpawnGroundR6)
pcall(require, script.Parent.World.LookDevModelsVegetationR5)
pcall(require, script.Parent.World.LookDevModelsVegetationR6)
pcall(require, script.Parent.World.LookDevModelsPropsR5)
pcall(require, script.Parent.World.LookDevModelsNpcsR5)
pcall(require, script.Parent.World.LookDevModelsNpcsR6)
pcall(require, script.Parent.World.LookDevModelsPropsR6)
pcall(require, script.Parent.World.LookDevSpawnDressingR5)

-- Round 7: shipping sky/ground default (no enable call) and OFF-by-default model candidates.
pcall(require, script.Parent.World.ShippingLookR7)
pcall(require, script.Parent.World.LookDevModelsVegetationR7)
pcall(require, script.Parent.World.LookDevModelsNpcsR7)
pcall(require, script.Parent.World.LookDevModelsPropsR7)
pcall(require, script.Parent.World.LookDevModelsVegetationHubR8)
pcall(require, script.Parent.World.LookDevPlotsR8)
pcall(require, script.Parent.World.LookDevSawahR8)
pcall(require, script.Parent.World.LookDevRiverR8)
pcall(require, script.Parent.World.LookDevPathEdgeR8)
pcall(require, script.Parent.World.LookDevMeadowR10)
pcall(require, script.Parent.World.LookDevGroundVariationR10)
pcall(require, script.Parent.World.LookDevBuildingsR8)
pcall(require, script.Parent.World.LookDevFacadesR8)
pcall(require, script.Parent.World.LookDevNightR8)
pcall(require, script.Parent.World.LookDevGradeR8)
pcall(require, script.Parent.World.LookDevSoundsR8)
pcall(require, script.Parent.World.LookDevHubPropsR8)
pcall(require, script.Parent.World.LookDevForestPinesLegacy)
pcall(require, script.Parent.World.LookDevCanonicalR10)

print("[JuraganDesa] server started")
