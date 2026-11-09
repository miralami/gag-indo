-- Law & order tuning (GDD §5, §6, §7.2). Edit numbers here to rebalance.
-- Shared so the client can show prices and countdowns without a round trip.

local Law = {}

-- Sus meter ---------------------------------------------------------------
Law.susMax = 100
Law.susDecaySeconds = 20 -- one decay tick
Law.susDecayAmount = 1

Law.gossipSus = 30 -- Pak RT starts gossiping
Law.letterSus = 60 -- Surat Panggilan warning
Law.raidChanceSus = 80 -- random raid rolls start here
Law.raidChance = 0.10 -- per 20 s tick
Law.raidResetSus = 30 -- Sus after a raid ends
Law.raidCooldown = 180 -- seconds of raid immunity after a raid
Law.raidChoiceTimeout = 20 -- auto-fine after this long

-- Raid payouts ------------------------------------------------------------
Law.finePercent = 0.20
Law.fineMin = 50
Law.fineMax = 5000
Law.amplopPercent = 0.10
Law.amplopSuccess = 0.75
Law.amplopFailMultiplier = 1.5
Law.jailSeconds = 45

-- Pak RT bribe -----------------------------------------------------------
Law.bribeBasePrice = 100
Law.bribeGrowth = 1.5 -- price multiplier per repeat bribe inside the window
Law.bribeWindow = 600 -- 10 minutes
Law.bribeCooldown = 180 -- 3 minutes
Law.bribeSusReduction = 10

-- Evidence / Lapor -------------------------------------------------------
Law.evidenceRadius = 40 -- studs
Law.evidenceTokenSeconds = 180
Law.reportCooldown = 60
Law.cheaterSusPerReport = 25
Law.reporterRewardShare = 0.5 -- of the cheat's value, paid from the cheater
Law.viralReporters = 2 -- distinct reporters...
Law.viralWindow = 300 -- ...within 5 minutes

-- Nama Baik --------------------------------------------------------------
Law.namaBaikStart = 50
Law.namaBaikMax = 100
Law.namaBaikCaught = -10
Law.namaBaikViral = -20
Law.namaBaikPerReport = 2
Law.namaBaikReportDailyCap = 10
Law.namaBaikWater = 1
Law.namaBaikWaterDailyCap = 10

-- Monetization guardrails (GDD §9.2) -------------------------------------
Law.amplopPremiumSus = -20
Law.amplopPremiumCooldown = 600

return Law
