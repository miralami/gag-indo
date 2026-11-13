--!nocheck
-- Balance & Economy Simulation Spec
-- Validates progression pacing, faucet/sink mechanics, and pinjol risk/reward models.

return function(t, Env)
	local expect = t.expect
	local env, Game, Crops, Tiers, Pinjol, Tools, Quests

	t:describe("Economy & Progression Balance Simulation", function()
		t:beforeEach(function()
			env = Env.new()
			Game = env:require("shared/Config/Game")
			Crops = env:require("shared/Config/Crops")
			Tiers = env:require("shared/Config/Tiers")
			Pinjol = env:require("shared/Config/Pinjol")
			Tools = env:require("shared/Config/Tools")
			Quests = env:require("shared/Config/Quests")
		end)

		t:describe("Progression Pacing", function()
			t:it("simulates Gurem to Petani progression in under 12 minutes of active farming", function()
				-- Starting state: 6 tiles of Padi
				local tileCount = Game.startTiles
				local padi = Crops.list.padi
				local cycleTime = padi.growSeconds + 5 -- 60s grow + 5s harvest/plant overhead
				local incomePerCycle = tileCount * padi.sellPrice -- Gross income counts toward lifetime earned

				local targetEarned = Game.rankRequirements.petani.lifetimeEarned -- 1000
				local cyclesNeeded = math.ceil(targetEarned / incomePerCycle)
				local totalSeconds = cyclesNeeded * cycleTime

				-- 1000 / (6 * 18 = 108) = 10 cycles * 65s = 650s (~10.8 minutes)
				expect(totalSeconds <= 12 * 60):toBe(true)
				expect(totalSeconds >= 5 * 60):toBe(true) -- Not trivial instant clicker
			end)

			t:it("simulates Petani to Juragan tile and cash requirement consistency", function()
				local juraganReq = Game.rankRequirements.juragan
				expect(juraganReq.lifetimeEarned):toBe(10000)
				expect(juraganReq.tilesOwned):toBe(12)

				-- Calculate cumulative tile expansion cost from startTiles (6) to 12
				local totalTileCost = 0
				for owned = Game.startTiles, 11 do
					totalTileCost += Game.tilePrice(owned)
				end
				-- 100 + 200 + 400 + 800 + 1600 + 3200 = 6300
				expect(totalTileCost):toBe(6300)

				-- Total tile cost must be comfortably affordably within the 10,000 lifetime earned
				expect(totalTileCost < juraganReq.lifetimeEarned):toBe(true)
			end)
		end)

		t:describe("Faucet vs Sink Dynamics", function()
			t:it("maintains net positive margin on base crops", function()
				for id, crop in Crops.list do
					local netMargin = crop.sellPrice - crop.seedCost
					local roi = netMargin / crop.seedCost
					expect(netMargin > 0):toBe(true)
					expect(roi >= 0.5):toBe(true) -- Minimum 50% ROI on seed cost
				end
			end)

			t:it("ensures expected value of rarity rolls strictly increases revenue", function()
				local expectedMultiplier = 0
				for _, tierId in Tiers.order do
					local tier = Tiers.list[tierId]
					expectedMultiplier += tier.chance * tier.valueMultiplier
				end
				-- Base is 1.0; weighted average should be ~1.3 - 1.5
				expect(expectedMultiplier > 1.2):toBe(true)
				expect(expectedMultiplier < 2.0):toBe(true)
			end)

			t:it("balances daily quest faucet with seed and tool sinks", function()
				local dailyQuestTotal = 0
				for _, task in Quests.taskPool do
					dailyQuestTotal += task.rewardCash
				end
				-- Pool average per 3 rolled tasks
				local avgDailyReward = (dailyQuestTotal / #Quests.taskPool) * 3
				expect(avgDailyReward >= 150):toBe(true)
				expect(avgDailyReward <= 600):toBe(true)
			end)
		end)

		t:describe("Pinjol Risk & Reward", function()
			t:it("enforces admin fee immediately as a credit sink", function()
				local loan = 1000
				local fee = math.floor(loan * Pinjol.adminFeePercent)
				expect(fee):toBe(100) -- 10% admin fee
				local initialOwed = loan + fee
				expect(initialOwed):toBe(1100)
			end)

			t:it("simulates debt accumulation ceiling at exactly 3x principal", function()
				local principal = 2000
				local ceiling = principal * Pinjol.maxDebtMultiplier -- 3x = 6000
				expect(ceiling):toBe(6000)

				-- 45 hours of online interest (5%/hour) -> interest = 45 * 0.05 * 2000 = 4500
				local hours = 45
				local accrued = principal + (principal * Pinjol.interestRatePerHour * hours)
				local capped = math.min(ceiling, accrued)
				expect(capped):toBe(ceiling)
			end)
		end)
	end)
end
