-- Pasar supply and demand (v2 PLAN §3.4). Server-wide, in memory, resets on restart.
--
-- Every legal sale adds pressure to that crop, and pressure decays over ~10 minutes. The price
-- multiplier can never rise above the legal ceiling (HET) or fall below the floor; the Tengkulak
-- Gelap ignores it entirely (that is his whole business).

local Market = {}

Market.decaySeconds = 600 -- pressure halves-ish over this window
Market.pressurePerItem = 0.003 -- 100 items sold => 0.70x at once
Market.minMultiplier = 0.6 -- the floor
Market.maxMultiplier = 1.25 -- the HET ceiling; never above this
Market.tickSeconds = 5

return Market
