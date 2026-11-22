--!nocheck
-- tools/studio/smoke_play.luau — WORK_QUEUE section N item 107: clean-Play smoke test.
-- Run once for the default look and once for full_r9. CHECK SMOKE_CLEAN = 0 violations.
--
-- Luau cannot call the Roblox Studio MCP tool get_console_output (main-session only), so the
-- main session drives this harness:
--   1. snapshot get_console_output() right before a fresh Play (the Output log ACCUMULATES and
--      there is no clear-console tool);
--   2. start a fresh Play — default look, or stage full_r9 via 13 LookDevReview.enableAdditive
--      calls in the Server VM;
--   3. wait 60 s;
--   4. snapshot get_console_output() again and take the MULTISET DELTA (lines emitted during the
--      window; old stale lines are excluded, not hidden);
--   5. set _G.SMOKE_CONSOLE_LINES = { "<delta line>", ... } and paste this WHOLE file into
--      execute_luau (Server or Client VM — no engine APIs used; safe in either).
--
-- Every non-allowlisted line is a violation (an error or an unapproved warning) and fails the
-- check. Nothing is classified as "info and ignored": lines are either allowlisted WITH a reason
-- below, or they fail. NEVER add a line here to hide a real error — fix the error instead. The
-- allowlist is deliberately short; each entry is a documented, pre-existing, external or
-- environment-specific message, not game-code output introduced by a candidate.

local ORDER = { "SMOKE_CLEAN" }
local results = {}

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	print(line)
	results[#results + 1] = {
		name = name,
		passed = passed,
		measured = measured,
		target = target,
		line = line,
		detail = detail,
	}
end

-- { text = <literal substring, matched with plain-find>, reason = "<one line>" }.
-- Keep this list short. One line per known noise source, with the reason it is not a regression.
local ALLOWLIST = {
	{
		text = "[JuraganDesa] server started",
		reason = "normal server boot info line",
	},
	{
		text = "[ProfileStore]: Roblox API services available - data will be saved",
		reason = "normal ProfileStore boot info; data store is available",
	},
	{
		text = "Assistant plugin version changed from",
		reason = "external Studio Assistant plugin self-notice, not game code",
	},
	{
		text = "ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type",
		reason = "D-G4 / BUG-003 documented wrong-asset-type warning; external asset, tracked, pre-existing",
	},
	{
		text = "ShippingLookR7: no PlotAnchor parts within 10 s; only flower beds painted",
		reason = "pre-existing shipping ground-look notice: dev place has no PlotAnchor parts; unrelated to lookdev staging",
	},
}

local function allowReason(line)
	for _, entry in ipairs(ALLOWLIST) do
		if string.find(line, entry.text, 1, true) then
			return entry.reason
		end
	end
	return nil
end

local function run()
	local lines = _G.SMOKE_CONSOLE_LINES or {}
	local violations = {}
	local allowed = {}
	local considered = 0
	for _, raw in ipairs(lines) do
		local line = tostring(raw)
		if string.find(line, "%S") then
			considered += 1
			local reason = allowReason(line)
			if reason then
				allowed[#allowed + 1] = { line = line, reason = reason }
			else
				violations[#violations + 1] = line
			end
		end
	end

	local ok = (#violations == 0)
	emit("SMOKE_CLEAN", ok, #violations, 0, {
		considered = considered,
		allowed = allowed,
		violations = violations,
		allowlistSize = #ALLOWLIST,
	})
	return ok
end

local ok = run()
local byName = {}
for _, result in ipairs(results) do
	byName[result.name] = result
end
return { order = ORDER, checks = results, byName = byName, ok = ok }
