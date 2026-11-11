-- Pinjol (peer-to-peer lending) config (v2 PLAN §3.5).
--
-- Borrow up to a limit set by rank and Nama Baik. A fixed fee is added immediately; interest
-- accrues on active and offline time up to a hard cap at 3x principal. Overdue loans trigger
-- progressive harassment: notification spam, plot visitor, public shaming, then gudang seizure.
--
-- Guardrails: one loan at a time; no borrowing during a raid.

local Pinjol = {}

-- Base borrowing limit per rank (Rp).
Pinjol.baseLimitByRank = {
	gurem = 500,
	petani = 1500,
	juragan = 5000,
	tuanTanah = 15000,
	sultan = 50000,
}

Pinjol.adminFeePercent = 0.10 -- 10% fee added to debt on borrow
Pinjol.interestRatePerHour = 0.05 -- 5% interest per hour while online/playing
Pinjol.offlineInterestRatePerHour = 0.02 -- 2% interest per hour while offline
Pinjol.maxDebtMultiplier = 3.0 -- hard ceiling: total debt never exceeds 3x principal
Pinjol.dueSeconds = 600 -- 10 minutes from borrow until marked overdue

-- Overdue stages (seconds after dueAt):
Pinjol.OVERDUE_STAGE_NOTIFY = 0 -- stage 1: notification warning
Pinjol.OVERDUE_STAGE_SHAME = 180 -- stage 2: 3 min overdue, public chat/ticker callout + Nama Baik hit
Pinjol.OVERDUE_STAGE_SEIZE = 360 -- stage 3: 6 min overdue, debt collector seizes crops from gudang

Pinjol.shameNamaBaikPenalty = 5

function Pinjol.calcLimit(rank: string, namaBaik: number): number
	local base = Pinjol.baseLimitByRank[rank] or Pinjol.baseLimitByRank.gurem
	-- Nama Baik scales limit 0.5x .. 1.5x (around baseline 50)
	local scale = math.clamp(namaBaik / 50, 0.5, 1.5)
	return math.floor(base * scale)
end

return Pinjol
