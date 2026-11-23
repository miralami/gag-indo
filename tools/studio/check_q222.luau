--!nocheck
-- check_q222: WORK_QUEUE item 222, self-contained SERVER-VM Studio check. Paste the whole file into
-- execute_luau in a fresh Play session. It reads the LIVE ReplicatedStorage.Shared.Strings module at
-- runtime, validates every raw entry into a COPY, and never writes to the real module or the place.
--
--   STRINGS_BOTH_VARIANTS  every raw key has non-empty id and en, no placeholder / translator note
--   STRINGS_NEW_KEYS       the six section-P/Q sign strings are present and valid (6)
--   CAL_STRINGS_BOTH_VARIANTS_FAIL  inject one bad key into a copy; the validator must reject it
--
-- The six keys are the four item-203 junction signposts plus the two "Pasar"/"Market" signs
-- (sign_pasar from the streetfurn/spanduk signage, sign_pasar_board from item 209). Sprint 3 added
-- no Strings keys. No check target is lowered when calibration fails.

local CHECK_NAMES = {
	"STRINGS_BOTH_VARIANTS",
	"STRINGS_NEW_KEYS",
	"CAL_STRINGS_BOTH_VARIANTS_FAIL",
}
local CHECK_TARGETS = {
	STRINGS_BOTH_VARIANTS = "0/0",
	STRINGS_NEW_KEYS = 0,
	CAL_STRINGS_BOTH_VARIANTS_FAIL = 0,
}

-- Item 203 (4 junction boards) + item 81/209 Pasar signs (2 boards). Sprint 3: no new text.
local NEW_KEYS = {
	"signpost_pasar",
	"signpost_plot",
	"signpost_sungai",
	"signpost_sawah",
	"sign_pasar",
	"sign_pasar_board",
}

local MARKERS = {
	"TODO",
	"TBD",
	"XXX",
	"FIXME",
	"LOREM",
	"IPSUM",
	"DOLOR",
	"SIT AMET",
	"PLACEHOLDER",
	"TRANSLATOR",
	"TRANSLATE",
	"TERJEMAHKAN",
	"CATATAN",
}

local CAL_KEY = "__q222_calibration_bad_key"

local results = { checks = {}, byName = {} }

local function emit(name, passed, measured, target, detail)
	local line = "CHECK "
		.. name
		.. " "
		.. (passed and "PASS" or "FAIL")
		.. " "
		.. tostring(measured)
		.. " "
		.. tostring(target)
	results.checks[#results.checks + 1] = line
	results.byName[name] = { line = line, passed = passed, measured = measured, target = target, detail = detail }
	print(line)
end

local function emitOnce(name, passed, measured, target, detail)
	if not results.byName[name] then
		emit(name, passed, measured, target, detail)
	end
end

-- Copy the table AND each entry. Calibration only ever touches the copy.
local function copyRaw(raw)
	local copy = {}
	for key, entry in pairs(raw) do
		if type(entry) == "table" then
			local fields = {}
			for field, value in pairs(entry) do
				fields[field] = value
			end
			copy[key] = fields
		else
			copy[key] = entry
		end
	end
	return copy
end

-- One key is good only when both variants are strings, non-empty, unpadded and marker-free.
local function keyProblems(entry)
	if type(entry) ~= "table" then
		return { "entry is not a table" }
	end
	local problems = {}
	for _, field in ipairs({ "id", "en" }) do
		local text = entry[field]
		if type(text) ~= "string" then
			problems[#problems + 1] = `missing {field}`
		else
			if string.match(text, "^%s*$") then
				problems[#problems + 1] = `{field} is empty`
			end
			if string.match(text, "^%s") or string.match(text, "%s$") then
				problems[#problems + 1] = `{field} has padding`
			end
			local upper = string.upper(text)
			for _, marker in ipairs(MARKERS) do
				if string.find(upper, marker, 1, true) then
					problems[#problems + 1] = `{field} contains "{marker}"`
				end
			end
		end
	end
	return problems
end

local function validate(raw)
	local good, total = 0, 0
	local bad = {}
	for key, entry in pairs(raw) do
		total += 1
		if #keyProblems(entry) == 0 then
			good += 1
		else
			bad[#bad + 1] = key
		end
	end
	table.sort(bad)
	return good, total, bad
end

local ok, err = pcall(function()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local okRequire, Strings = pcall(function()
		return require(shared:WaitForChild("Strings"))
	end)
	if not okRequire or type(Strings) ~= "table" or type(Strings.raw) ~= "table" then
		error("ReplicatedStorage.Shared.Strings.raw is missing: " .. tostring(Strings))
	end

	-- LIVE module read once, then snapshotted. The real raw table is never assigned to.
	local liveRaw = Strings.raw
	local snapshot = copyRaw(liveRaw)

	local good, total, bad = validate(snapshot)
	emit("STRINGS_BOTH_VARIANTS", total > 0 and good == total, `{good}/{total}`, tostring(total), {
		source = "ReplicatedStorage.Shared.Strings.raw",
		badKeys = bad,
		keyCount = total,
	})

	local present, missing = 0, {}
	for _, key in ipairs(NEW_KEYS) do
		local newGood = validate({ [key] = snapshot[key] })
		if newGood == 1 then
			present += 1
		else
			missing[#missing + 1] = key
		end
	end
	emit("STRINGS_NEW_KEYS", present == #NEW_KEYS, present, #NEW_KEYS, {
		keys = NEW_KEYS,
		missingOrBad = missing,
	})

	-- CALIBRATION ANCHOR: the same validator must reject a bad key injected into a COPY.
	-- "en" is blank and "id" carries a translator note, so both variant and marker rules bite.
	local calibration = copyRaw(snapshot)
	calibration[CAL_KEY] = { id = "TODO translator note", en = "" }
	local calGood, calTotal, calBad = validate(calibration)
	local detected = calTotal == total + 1
		and calGood == good
		and table.find(calBad, CAL_KEY) ~= nil
		and calGood ~= calTotal
	emit("CAL_STRINGS_BOTH_VARIANTS_FAIL", detected, detected and 1 or 0, 1, {
		injectedKey = CAL_KEY,
		baseline = `{good}/{total}`,
		afterInjection = `{calGood}/{calTotal}`,
		badKeysAdded = calTotal - total - (calGood - good),
		liveModuleUntouched = liveRaw[CAL_KEY] == nil,
	})
end)

if not ok then
	local reason = { reason = "item 222 strings audit error: " .. tostring(err) }
	for _, name in ipairs(CHECK_NAMES) do
		emitOnce(name, false, name == "STRINGS_BOTH_VARIANTS" and "0/0" or 0, CHECK_TARGETS[name], reason)
	end
end

return results
