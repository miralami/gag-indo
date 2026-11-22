--!strict
-- LookDevFailures: per-family load-failure counters for round-7 Studio checks (WORK_QUEUE §K).
-- Pure table module: no engine API, no asset IDs. Appliers set their count at the end of apply();
-- review_check_r7.luau reads the same module instance in the Server VM and prints CHECK lines.
-- A count is never reset by a successful load inside the same apply() call: any failure is a FAIL.

local LookDevFailures = {}

LookDevFailures.counts = {} :: { [string]: number }

function LookDevFailures.reset(id: string)
	LookDevFailures.counts[id] = 0
end

function LookDevFailures.get(id: string): number
	return LookDevFailures.counts[id] or 0
end

function LookDevFailures.add(id: string, amount: number?)
	LookDevFailures.counts[id] = LookDevFailures.get(id) + (amount or 1)
end

function LookDevFailures.set(id: string, count: number)
	LookDevFailures.counts[id] = count
end

return LookDevFailures
