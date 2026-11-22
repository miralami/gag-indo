-- PersistenceCheck: pure before/after comparator for the Q6 save → leave → rejoin check
-- (WORK_QUEUE item 23). No game APIs here on purpose: tests/specs/persistence_check_spec.luau
-- drives every branch under Lune. The Studio driver (server/Testing/Persistence.luau) captures the
-- two snapshots and hands them to `compare`; this module only decides what must be identical.

local PersistenceCheck = {}

-- Q6 names cash / seeds / tiles; the rest are the same state fields the Q5 comparator watches,
-- so a save that silently drops progression is caught too. Identity, position, shop (UserId-seeded)
-- and the onboarding hint id are excluded for the same reasons as in MultiClientCheck.
PersistenceCheck.FIELDS = {
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

-- A stable fingerprint. Keys are sorted so table iteration order never changes the result.
local function encode(value: any, out: { string })
	local kind = type(value)
	if kind == "nil" then
		out[#out + 1] = "nil"
	elseif kind == "number" then
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
		out[#out + 1] = "<" .. kind .. ">"
	end
end

function PersistenceCheck.digest(value: any): string
	local out: { string } = {}
	encode(value, out)
	return table.concat(out)
end

-- `tiles[].ready` is derived from os.time(), so a crop that was growing at save time may legitimately
-- be ready after rejoin. Drop it before comparing; crop identity, count and hot state must persist.
local function normalize(field: string, value: any): any
	if field ~= "tiles" or type(value) ~= "table" then
		return value
	end
	local tiles = {}
	for index, entry in value do
		if type(entry) == "table" then
			tiles[index] = { crop = entry.crop, hot = entry.hot }
		else
			tiles[index] = entry
		end
	end
	return tiles
end

-- Compare the two snapshots. Returns:
--   { ok, missingBefore, missingAfter, matches = { field, ... }, mismatches = { { field, before, after }, ... } }
-- A missing snapshot is itself a failure: two absent saves agreeing on nil is not persistence.
function PersistenceCheck.compare(before: any?, after: any?): any
	local matches = {}
	local mismatches = {}
	for _, field in ipairs(PersistenceCheck.FIELDS) do
		local a = before and before[field]
		local b = after and after[field]
		if PersistenceCheck.digest(normalize(field, a)) == PersistenceCheck.digest(normalize(field, b)) then
			matches[#matches + 1] = field
		else
			mismatches[#mismatches + 1] = { field = field, before = a, after = b }
		end
	end
	local missingBefore = type(before) ~= "table"
	local missingAfter = type(after) ~= "table"
	return {
		ok = not missingBefore and not missingAfter and #mismatches == 0,
		missingBefore = missingBefore,
		missingAfter = missingAfter,
		matches = matches,
		mismatches = mismatches,
	}
end

-- Human-readable lines for Output / REPORT.md.
function PersistenceCheck.lines(results: any): { string }
	local out: { string } = {
		`Q6 persistence: {#results.matches}/{#results.matches + #results.mismatches} fields match; {if results.ok
			then "PASS"
			else "FAIL"}`,
	}
	if results.missingBefore then
		out[#out + 1] = "  NO BEFORE SNAPSHOT (capture before leaving)"
	end
	if results.missingAfter then
		out[#out + 1] = "  NO AFTER SNAPSHOT (status could not be read after rejoin)"
	end
	for _, item in ipairs(results.mismatches) do
		out[#out + 1] =
			`  LOST/CHANGED {item.field}: before={PersistenceCheck.digest(item.before)} after={PersistenceCheck.digest(
				item.after
			)}`
	end
	return out
end

return PersistenceCheck
