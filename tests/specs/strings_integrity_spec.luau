--!nocheck
-- Integrity rules for the player-facing string table (src/shared/Strings.luau).
--
-- * Every key has a non-empty `id` and `en`.
-- * Placeholders (%s, %d, {name}) match between id and en.
-- * No leading/trailing whitespace, no TODO/TBD/xxx leftovers.
-- * Every literal key sent via Notify.send / Notify.broadcast, read via Strings.get or the
--   client `t(...)` helper, or passed as an "@key" argument, exists in the table.
--   Concatenated prefixes such as "@crop_" .. id must match at least one real key.
--
-- Tests whose name starts with "[BUG]" are expected to fail: they reveal real defects
-- (the message lists the exact keys). Strings.luau itself is never edited by this spec.

local fs = require("@lune/fs")

local MAX_LISTED = 12

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
		local _, e = string.find(src, "^%s*\"", pos)
		if not e then
			return nil
		end
		local close = string.find(src, "\"", e + 1, true)
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
						local _, closeQuote = string.find(src, "\"", string.find(src, key, e + 1, true) + #key, true)
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
				local s, e, name = string.find(src, "\"@([%w_]*)\"", pos)
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
				for _, word in { "TODO", "TBD", "XXX" } do
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
					local name = if matched then `dynamic key "{prefix}" .. x has real keys` else `[BUG] no key starts with "{prefix}" for dynamic key "{prefix}" .. x, e.g. {files[1]}`
					t:it(name, function()
						expect(matched):toBeTruthy()
					end)
				else
					local exists = S[ref] ~= nil
					local name = if exists then `{ref} is defined` else `[BUG] missing key "{ref}" referenced by {#files} call site(s), e.g. {files[1]}`
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
					local name = if matched then `"{base}" .. x has real keys` else `[BUG] no key starts with "{prefix}" for dynamic "{base}" .. x args`
					t:it(name, function()
						expect(matched):toBeTruthy()
					end)
				else
					local key = string.sub(ref, 2)
					local exists = S[key] ~= nil
					local files = atRefs[ref]
					local name = if exists then `"{ref}" argument resolves` else `[BUG] missing key "{key}" passed as "{ref}" by {#files} call site(s), e.g. {files[1]}`
					t:it(name, function()
						expect(exists):toBeTruthy()
					end)
				end
			end
		end)

		t:it("finds a non-trivial number of references (scanner sanity)", function()
			expect(#sortedKeys(keyRefs)):toBeAtLeast(20)
			expect(#sortedKeys(S)):toBeAtLeast(100)
		end)
	end)
end
