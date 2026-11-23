--!nocheck
-- Item 222 data-only guard for the live strings audit. The Studio run reads
-- ReplicatedStorage.Shared.Strings at runtime (tools/studio/check_q222.luau); this spec reads the
-- same source module under Lune and guards the check's check names, key list and copy semantics.

local fs = require("@lune/fs")

local CHECK = "tools/studio/check_q222.luau"

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

local function problems(entry)
	if type(entry) ~= "table" then
		return { "not a table" }
	end
	local found = {}
	for _, field in ipairs({ "id", "en" }) do
		local text = entry[field]
		if type(text) ~= "string" then
			found[#found + 1] = "missing " .. field
		else
			if string.match(text, "^%s*$") then
				found[#found + 1] = field .. " empty"
			end
			if string.match(text, "^%s") or string.match(text, "%s$") then
				found[#found + 1] = field .. " padded"
			end
			local upper = string.upper(text)
			for _, marker in ipairs(MARKERS) do
				if string.find(upper, marker, 1, true) then
					found[#found + 1] = field .. " has " .. marker
				end
			end
		end
	end
	return found
end

return function(t, Env)
	local expect = t.expect
	local checkSrc = fs.readFile(CHECK)
	local Strings = Env.new():require("shared/Strings")
	local S = Strings.raw

	t:describe("item 222 strings both variants", function()
		t:it("every source key has id and en, non-empty and marker-free", function()
			local total, good, bad = 0, 0, {}
			for key, entry in pairs(S) do
				total += 1
				if #problems(entry) == 0 then
					good += 1
				else
					bad[#bad + 1] = key
				end
			end
			table.sort(bad)
			expect(total > 300):toBe(true)
			expect(good):toBe(total)
			expect(#bad):toBe(0)
		end)

		t:it("all six section-P/Q sign strings are present and clean", function()
			expect(#NEW_KEYS):toBe(6)
			local seen = {}
			for _, key in ipairs(NEW_KEYS) do
				expect(seen[key]):toBe(nil)
				seen[key] = true
				expect(#problems(S[key])):toBe(0)
			end
			expect(S.signpost_pasar.id):toBe("Pasar")
			expect(S.signpost_pasar.en):toBe("Market")
			expect(S.signpost_plot.id):toBe("Plot")
			expect(S.signpost_sungai.id):toBe("Sungai")
			expect(S.signpost_sawah.id):toBe("Sawah")
			expect(S.sign_pasar_board.id):toBe("Pasar")
			expect(S.sign_pasar_board.en):toBe("Market")
		end)

		t:it("validator mirror rejects missing, blank and note-bearing variants", function()
			expect(#problems({ id = "Pasar", en = "Market" })):toBe(0)
			expect(#problems({ id = "Pasar" })):toBe(1)
			expect(#problems({ id = "Pasar", en = "" })):toBe(1)
			expect(#problems({ id = "Pasar", en = "  " }) > 0):toBe(true)
			expect(#problems({ id = "TODO Pasar", en = "Market" })):toBe(1)
			expect(#problems({ id = "Pasar", en = "translator note" })):toBe(1)
			expect(#problems(nil)):toBe(1)
		end)

		t:it("harness reads live Strings, copies before calibration and keeps three checks", function()
			for _, token in ipairs({
				'"STRINGS_BOTH_VARIANTS"',
				'"STRINGS_NEW_KEYS"',
				'"CAL_STRINGS_BOTH_VARIANTS_FAIL"',
				'game:GetService("ReplicatedStorage")',
				'shared:WaitForChild("Strings")',
				"local liveRaw = Strings.raw",
				"local function copyRaw",
				"local snapshot = copyRaw(liveRaw)",
				"local function validate",
				"local calibration = copyRaw(snapshot)",
				"table.sort(bad)",
				"#NEW_KEYS",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			for _, key in ipairs(NEW_KEYS) do
				expect(checkSrc:find('"' .. key .. '"', 1, true) ~= nil):toBe(true)
			end
			-- Calibration must never write to the live module or stage anything in the place.
			expect(checkSrc:find("liveRaw[CAL_KEY] = {", 1, true) == nil):toBe(true)
			expect(checkSrc:find("Strings.raw[CAL_KEY]", 1, true) == nil):toBe(true)
			expect(checkSrc:find("Instance.new", 1, true) == nil):toBe(true)
			expect(checkSrc:find("require(game", 1, true) == nil):toBe(true)
		end)
	end)
end
