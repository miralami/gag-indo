-- MultiClientCheck: pure comparator for the Q5 multi-client harness run (WORK_QUEUE item 22).
--
-- No game APIs here on purpose: tests/specs/multiclient_spec.luau drives every branch under Lune,
-- while the live ten-player half stays BLOCKED on a human at Studio's Test tab. The Studio driver
-- (server/Testing/MultiClient.luau) runs the HARNESS.md section 2-4 loop for every player and
-- hands the per-player records to `check`; this module only compares and formats them.

local MultiClientCheck = {}

-- Snapshot fields that must agree across clients which ran the identical loop from identical
-- fresh saves. Excluded on purpose:
--   name / userId / position  - player identity and where their character happens to stand;
--   shop                      - ShopStock.roll is seeded by player.UserId, so two players can
--                               legitimately have different shelves (a buy refusal is expected);
--   tutorialId                - the onboarding hint id is a UI detail, tutorialStep is the state.
-- A cash/seeds difference can still come from that per-player shelf; the REPORT tells the reader
-- to check `shop` before calling it a bug (same rule as HARNESS.md section 11).
MultiClientCheck.STATE_FIELDS = {
	"cash",
	"lifetimeEarned",
	"rank",
	"seeds",
	"tilesOwned",
	"tiles",
	"sack",
	"gudang",
	"tutorialStep",
	"quests",
}

-- Stable, human-readable fingerprint. Keys are sorted so two tables with the same contents
-- always encode the same string no matter what order Lua iterated them in.
local function encode(value: any, out: { string })
	local kind = type(value)
	if kind == "nil" then
		out[#out + 1] = "nil"
	elseif kind == "number" then
		-- NaN/inf cannot appear in a healthy save, but print them instead of hiding them so a
		-- damaged value is visible in the results table.
		if value ~= value then
			out[#out + 1] = "nan"
		elseif value == math.huge then
			out[#out + 1] = "inf"
		elseif value == -math.huge then
			out[#out + 1] = "-inf"
		else
			out[#out + 1] = tostring(value)
		end
	elseif kind == "string" then
		out[#out + 1] = string.format("%q", value)
	elseif kind == "boolean" then
		out[#out + 1] = if value then "true" else "false"
	elseif kind == "table" then
		local keys = {}
		for key in value do
			keys[#keys + 1] = key
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		out[#out + 1] = "{"
		for _, key in keys do
			out[#out + 1] = tostring(key)
			out[#out + 1] = "="
			encode(value[key], out)
			out[#out + 1] = ","
		end
		out[#out + 1] = "}"
	else
		-- Functions, threads and userdata are not expected in a snapshot; show the type rather
		-- than erroring so one odd field cannot abort the whole comparison.
		out[#out + 1] = "<" .. kind .. ">"
	end
end

function MultiClientCheck.digest(value: any): string
	local out: { string } = {}
	encode(value, out)
	return table.concat(out)
end

-- Compare one field across all players. Returns nil when every player agrees, otherwise a row
-- { field = ..., values = { [name] = value } } with one entry per player.
local function diffField(field: string, records: { any }): any?
	local first = records[1]
	if not first or not first.final then
		return nil
	end
	local baseline = first.final[field]
	local baselineDigest = MultiClientCheck.digest(baseline)
	local values: { [any]: any } = {}
	values[first.name or "player1"] = baseline
	local differs = false
	for index = 2, #records do
		local record = records[index]
		local name = record.name or ("player" .. index)
		local value = record.final and record.final[field]
		values[name] = value
		if MultiClientCheck.digest(value) ~= baselineDigest then
			differs = true
		end
	end
	if differs then
		return { field = field, values = values }
	end
	return nil
end

-- The one results table. `records` is one row per player from the driver:
--   { name = <string>, steps = { { action, ok, critical?, error? }, ... }, final = <snapshot?> }
-- A step with critical == false (only `save` in the driver) is recorded but cannot mark a player
-- stuck: persistence is Q6, not Q5.
function MultiClientCheck.check(records: { any }): any
	local stuck = {}
	local complete = {}
	for index, record in records do
		local name = record.name or ("player" .. index)
		if record.final == nil then
			stuck[#stuck + 1] = { name = name, reason = "no save snapshot (save not loaded or player left)" }
		else
			local failed = {}
			for _, step in ipairs(record.steps or {}) do
				if not step.ok and step.critical ~= false then
					failed[#failed + 1] = tostring(step.action) .. (step.error and (": " .. tostring(step.error)) or "")
				end
			end
			if #failed > 0 then
				stuck[#stuck + 1] = { name = name, reason = table.concat(failed, "; ") }
			else
				complete[#complete + 1] = name
			end
		end
	end

	local desync = {}
	for _, field in ipairs(MultiClientCheck.STATE_FIELDS) do
		local row = diffField(field, records)
		if row then
			desync[#desync + 1] = row
		end
	end

	return {
		playerCount = #records,
		stuck = stuck,
		desync = desync,
		complete = complete,
		ok = #stuck == 0 and #desync == 0,
	}
end

-- Human-readable lines for Output / REPORT.md. Kept here, not in the driver, so Lune can prove
-- the exact wording; the driver only prints these and stores the raw results table.
function MultiClientCheck.lines(results: any): { string }
	local out: { string } = {
		`Q5 multi-client: {results.playerCount} player(s); {if results.ok then "PASS" else "FAIL"}`,
	}
	for _, item in ipairs(results.stuck) do
		out[#out + 1] = `  STUCK {item.name}: {item.reason}`
	end
	for _, item in ipairs(results.desync) do
		local parts = {}
		for name, value in item.values do
			parts[#parts + 1] = tostring(name) .. "=" .. MultiClientCheck.digest(value)
		end
		table.sort(parts)
		out[#out + 1] = `  DESYNC {item.field}: {table.concat(parts, " | ")}`
	end
	for _, name in ipairs(results.complete) do
		out[#out + 1] = `  OK {name}`
	end
	return out
end

return MultiClientCheck
