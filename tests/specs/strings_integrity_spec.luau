--!nocheck
-- Integrity rules for the player-facing string table (src/shared/Strings.luau).
--
-- * Every key has a non-empty `id` and `en`.
-- * Placeholders (%s, %d, {name}) match between id and en.
-- * No leading/trailing whitespace, no TODO/TBD/XXX or lorem/placeholder leftovers.
-- * Long strings where id == en (>= 12 chars) are FLAGGED, never failed: they are usually loanwords
--   or proper nouns left to the designer (item 95). Watch for "[STRINGS FLAG]" in the Lune output.
-- * Every literal key sent via Notify.send / Notify.broadcast, read via Strings.get or the
--   client `t(...)` helper, or passed as an "@key" argument, exists in the table.
--   Concatenated prefixes such as "@crop_" .. id must match at least one real key.
-- * No word-like string literal is written directly to a *Text property anywhere in src/; only
--   documented glyphs (empty, "-", "<", "X", "[L]", the mock signal bar) are exempt.
--
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects
-- (the message lists the exact keys). Strings.luau itself is never edited by this spec.

local fs = require("@lune/fs")

local MAX_LISTED = 12

-- Item 95: a string is "long" for the id==en loanword flag at this length or above.
local LONG_ID_EQ_EN_MIN = 12

-- Long entries whose id and en are byte-identical are almost always loanwords / proper nouns.
-- Flag them for the designer instead of failing the spec. Sorted by key for deterministic output.
local function longIdEqualsEn(S: { [string]: any }): { { key: string, value: string } }
	local flags = {}
	for key, entry in S do
		if type(entry) == "table" then
			local id, en = entry.id, entry.en
			if type(id) == "string" and type(en) == "string" and id == en and #id >= LONG_ID_EQ_EN_MIN then
				table.insert(flags, { key = key, value = id })
			end
		end
	end
	table.sort(flags, function(a, b)
		return a.key < b.key
	end)
	return flags
end

-- Recursively collect every .luau file under a directory.
local function listLuau(dir: string, out: { string })
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			listLuau(full, out)
		elseif string.match(entry, "%.luau$") then
			table.insert(out, full)
		end
	end
	return out
end

-- Symbolic labels are not words: a close button "X", the "[L]" keycap hint and the mock signal bar
-- "|||| 4G [===]". Empty strings and strings with no ASCII letters are also glyphs (e.g. "-", "<").
-- Everything else assigned to a *Text property must come from Strings.get / the client `t(...)`.
local ALLOWED_LITERAL_TEXT = {
	["X"] = "close button glyph",
	["[L]"] = "keycap hint",
	["|||| 4G [===]"] = "signal-strength mock glyph",
}

-- Word-like string literals written directly to a *Text property in this source. gmatch returns
-- only the captured literal, so the property name is intentionally not part of the result.
local function hardcodedTextIn(src: string): { string }
	local found = {}
	for literal in string.gmatch(src, '[%w_]*Text%s*=%s*"([^"]*)"') do
		if string.find(literal, "%a") and not ALLOWED_LITERAL_TEXT[literal] then
			table.insert(found, literal)
		end
	end
	return found
end

-- Run the hardcoded-text scanner over every module except Strings.luau itself (its table entries
-- are the source of truth, not stragglers).
local function scanHardcodedText(): { { path: string, literal: string } }
	local found = {}
	for _, path in listLuau("src", {}) do
		if not string.match(path, "shared/Strings%.luau$") then
			for _, literal in hardcodedTextIn(fs.readFile(path)) do
				table.insert(found, { path = path, literal = literal })
			end
		end
	end
	table.sort(found, function(a, b)
		if a.path == b.path then
			return a.literal < b.literal
		end
		return a.path < b.path
	end)
	return found
end

local function sortedKeys(set: { [string]: any }): { string }
	local list = {}
	for key in set do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

-- Placeholder directives like %s, %d, %.1f (not %%) and {name} tokens, as sorted strings.
local function placeholdersOf(text: string): string
	local found = {}
	for directive in string.gmatch(text, "%%[%-%+ #0]*%d*%.?%d*[%a%%]") do
		if directive ~= "%%" then
			table.insert(found, directive)
		end
	end
	for token in string.gmatch(text, "{[%w_]+}") do
		table.insert(found, token)
	end
	table.sort(found)
	return table.concat(found, " ")
end

-- Every literal key referenced from src/, with where it was found.
local function scanReferences(): ({ [string]: { string } }, { [string]: { string } })
	local keyRefs: { [string]: { string } } = {}
	local atRefs: { [string]: { string } } = {}
	local files = listLuau("src", {})

	local function addTo(map, key, where)
		map[key] = map[key] or {}
		table.insert(map[key], where)
	end

	-- Literal first arg after `(`, or after the first comma when `afterComma` is set.
	local function literalArg(src: string, openPos: number, afterComma: boolean): string?
		local pos = openPos
		if afterComma then
			local comma = string.find(src, ",", pos, true)
			if not comma then
				return nil
			end
			pos = comma + 1
		end
		local _, e = string.find(src, '^%s*"', pos)
		if not e then
			return nil
		end
		local close = string.find(src, '"', e + 1, true)
		if not close then
			return nil
		end
		return string.sub(src, e + 1, close - 1)
	end

	for _, path in files do
		local src = fs.readFile(path)
		local isStringsModule = string.match(path, "shared/Strings%.luau$") ~= nil
		if not isStringsModule then
			local function scanCalls(pattern: string, afterComma: boolean)
				local pos = 1
				while true do
					local s, e = string.find(src, pattern, pos)
					if not s then
						break
					end
					local key = literalArg(src, e + 1, afterComma)
					if key and key ~= "" then
						-- "admin_perf_" .. x is a prefix: it only has to match some real key.
						local _, closeQuote = string.find(src, '"', string.find(src, key, e + 1, true) + #key, true)
						local concatenated = closeQuote and string.find(src, "^%s*%.%.", closeQuote + 1) ~= nil
						if concatenated then
							addTo(keyRefs, "prefix:" .. key, path)
						else
							addTo(keyRefs, key, path)
						end
					end
					pos = e + 1
				end
			end
			scanCalls("Notify%.send%(", true)
			scanCalls("Notify%.broadcast%(", false)
			scanCalls("Strings%.get%(", true)
			scanCalls("%f[%w_]t%(", false)

			local pos = 1
			while true do
				local s, e, name = string.find(src, '"@([%w_]*)"', pos)
				if not s then
					break
				end
				-- "@crop_" .. id is a prefix: it only has to match some real key.
				local concatenated = string.find(src, "^%s*%.%.", e + 1) ~= nil
				if name ~= "" then
					local key = if concatenated then "@prefix:" .. name else "@" .. name
					addTo(atRefs, key, path)
				end
				pos = e + 1
			end
		end
	end
	return keyRefs, atRefs
end

return function(t, Env, Fakes)
	local expect = t.expect

	-- Load Strings once at definition time so test names can say which keys are broken.
	local probe = Env.new()
	local Strings = probe:require("shared/Strings")
	local S = Strings.raw

	-- Item 95: build once, sorted, then emit the observable non-failing flag lines.
	local longFlags = longIdEqualsEn(S)
	for _, flag in ipairs(longFlags) do
		print("[STRINGS FLAG] id==en long key=" .. flag.key .. " value=" .. flag.value)
	end

	local function entryProblems(key: string): { string }
		local entry = S[key]
		local problems = {}
		if type(entry) ~= "table" then
			return { "entry is not a table" }
		end
		for _, lang in { "id", "en" } do
			local text = entry[lang]
			if type(text) ~= "string" then
				table.insert(problems, `missing {lang}`)
			else
				if string.match(text, "^%s*$") then
					table.insert(problems, `{lang} is empty`)
				end
				if string.match(text, "^%s") or string.match(text, "%s$") then
					table.insert(problems, `{lang} has leading/trailing whitespace`)
				end
				local upper = string.upper(text)
				-- Item 95: also reject lorem-ipsum / placeholder filler in either language.
				for _, word in { "TODO", "TBD", "XXX", "LOREM", "IPSUM", "DOLOR", "SIT AMET", "PLACEHOLDER" } do
					if string.find(upper, word, 1, true) then
						table.insert(problems, `{lang} contains "{word}"`)
					end
				end
			end
		end
		if type(entry.id) == "string" and type(entry.en) == "string" then
			local idPh, enPh = placeholdersOf(entry.id), placeholdersOf(entry.en)
			if idPh ~= enPh then
				table.insert(problems, `placeholders differ: id [{idPh}] vs en [{enPh}]`)
			end
		end
		return problems
	end

	local function prefixed(problems: { string }): string
		return table.concat(problems, "; ")
	end

	local keyRefs, atRefs = scanReferences()
	local hardcoded = scanHardcodedText()

	t:describe("Strings integrity", function()
		t:describe("entry format", function()
			for _, key in sortedKeys(S) do
				local problems = entryProblems(key)
				local name = if #problems > 0 then `[BUG] {key}: {prefixed(problems)}` else `{key} is well-formed`
				t:it(name, function()
					expect(#problems):toBe(0)
				end)
			end
		end)

		t:describe("references from src/", function()
			-- Plain literal keys: Notify.send / Notify.broadcast / Strings.get / t(...).
			for _, ref in sortedKeys(keyRefs) do
				local files = keyRefs[ref]
				if string.sub(ref, 1, 7) == "prefix:" then
					local prefix = string.sub(ref, 8)
					local matched = false
					for key in S do
						if string.sub(key, 1, #prefix) == prefix then
							matched = true
							break
						end
					end
					local name = if matched
						then `dynamic key "{prefix}" .. x has real keys`
						else `[BUG] no key starts with "{prefix}" for dynamic key "{prefix}" .. x, e.g. {files[1]}`
					t:it(name, function()
						expect(matched):toBeTruthy()
					end)
				else
					local exists = S[ref] ~= nil
					local name = if exists
						then `{ref} is defined`
						else `[BUG] missing key "{ref}" referenced by {#files} call site(s), e.g. {files[1]}`
					t:it(name, function()
						expect(exists):toBeTruthy()
					end)
				end
			end

			-- "@key" arguments are resolved as keys by Strings.get.
			for _, ref in sortedKeys(atRefs) do
				local isPrefix = string.sub(ref, 1, 8) == "@prefix:"
				if isPrefix then
					local prefix = string.sub(ref, 9)
					local base = "@" .. prefix
					local matched = false
					for key in S do
						if string.sub(key, 1, #prefix) == prefix then
							matched = true
							break
						end
					end
					local name = if matched
						then `"{base}" .. x has real keys`
						else `[BUG] no key starts with "{prefix}" for dynamic "{base}" .. x args`
					t:it(name, function()
						expect(matched):toBeTruthy()
					end)
				else
					local key = string.sub(ref, 2)
					local exists = S[key] ~= nil
					local files = atRefs[ref]
					local name = if exists
						then `"{ref}" argument resolves`
						else `[BUG] missing key "{key}" passed as "{ref}" by {#files} call site(s), e.g. {files[1]}`
					t:it(name, function()
						expect(exists):toBeTruthy()
					end)
				end
			end
		end)

		-- Item 95 re-audited all 32 `Text = "..."` hits across src/client: every one is empty, a
		-- documented glyph/technical label ("X", "[L]", "-", "<", "|||| 4G [===]") or non-word-like.
		-- Zero word-like player-facing literals to move, so Strings.luau and src/client were untouched.
		t:describe("hardcoded player text in src/", function()
			-- One [BUG] case per straggler so a failure names the exact literal and file.
			for _, hit in ipairs(hardcoded) do
				t:it(`[BUG] hardcoded .Text literal "{hit.literal}" in {hit.path}`, function()
					expect(hit.literal .. " in " .. hit.path):toBe("routed through Strings")
				end)
			end
			t:it("no hardcoded word-like .Text literals outside the glyph allowlist", function()
				expect(#hardcoded):toBe(0)
			end)
			-- Proves the scanner would actually catch a straggler (it scans src/, not this spec).
			t:it("scanner catches words and ignores empty / glyph / numeric labels", function()
				expect(#hardcodedTextIn('label.Text = "Selamat pagi"')):toBe(1)
				expect(#hardcodedTextIn('label.PlaceholderText = "Nama"')):toBe(1)
				expect(#hardcodedTextIn('label.Text = ""')):toBe(0)
				expect(#hardcodedTextIn('button.Text = "X"')):toBe(0)
				expect(#hardcodedTextIn('hint.Text = "[L]"')):toBe(0)
				expect(#hardcodedTextIn('signal.Text = "|||| 4G [===]"')):toBe(0)
				expect(#hardcodedTextIn('count.Text = "42"')):toBe(0)
			end)
		end)

		t:describe("id==en long-string flag", function()
			-- Non-failing by design: the lines are printed above, this only proves determinism.
			t:it("flag list is rebuilt sorted, identical to the printed list", function()
				local fresh = longIdEqualsEn(S)
				expect(#fresh):toBe(#longFlags)
				for i, flag in ipairs(fresh) do
					expect(flag.key):toBe(longFlags[i].key)
					expect(flag.value):toBe(longFlags[i].value)
					if i > 1 then
						expect(longFlags[i - 1].key < flag.key):toBeTruthy()
					end
				end
			end)
		end)

		t:it("finds a non-trivial number of references (scanner sanity)", function()
			expect(#sortedKeys(keyRefs)):toBeAtLeast(20)
			expect(#sortedKeys(S)):toBeAtLeast(100)
		end)
	end)
end
