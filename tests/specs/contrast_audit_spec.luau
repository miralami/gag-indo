--!nocheck
-- WORK_QUEUE item 125: CHECK CONTRAST. LUNE-ONLY static token-pair audit.
-- Recomputes every ratio in docs/v2/visual/CONTRAST_AUDIT.md from the source palette hex
-- (src/shared/Config/Visuals.luau) with the same WCAG luminance used by Theme.contrastText.
-- A FAIL row must carry a resolution (fixed / stroke-backed / designer decision), never "-".

local fs = require("@lune/fs")

local DOC = "docs/v2/visual/CONTRAST_AUDIT.md"

-- Every token pair reported by the source-level proxy. The ratio is NOT hardcoded here.
local PAIRS = {
	{ "kertas", "kertas", 4.5 },
	{ "kunyit", "kertas", 4.5 },
	{ "kertas", "bambu", 4.5 },
	{ "tinta_lembut", "bambu", 4.5 },
	{ "merah", "padi", 4.5 },
	{ "daun", "kertas", 4.5 },
	{ "kertas", "padi", 4.5 },
	{ "senja", "merah", 4.5 },
	{ "genteng", "kertas", 4.5 },
	{ "tinta", "bambu", 4.5 },
	{ "merah", "kertas", 4.5 },
	{ "kertas", "merah", 4.5 },
	{ "tinta", "kunyit", 4.5 },
	{ "tinta", "padi", 4.5 },
	{ "tinta_lembut", "kertas", 4.5 },
	{ "kertas", "malam", 4.5 },
	{ "tinta", "kertas", 4.5 },
	{ "kertas", "tinta", 4.5 },
}

-- Fixed call sites: anchor line, offset to the TextColor3 line, new token, old token.
local FIXES = {
	{ "src/client/UI/Admin.luau", 'Text = t("admin_idle")', 1, "Theme.text", "Theme.accent" },
	{ "src/client/UI/Leaderboard.luau", "tabButton.TextColor3 =", 0, "Theme.text", "Theme.muted" },
	{ "src/client/UI/Hud.luau", 't("tutorial_card_title")', 2, "Theme.text", "Theme.merah" },
	{ "src/client/UI/Phone.luau", 't("phone_pinjol_clear")', 1, "Theme.text", "Theme.daun" },
	{ "src/client/UI/RaidOverlay.luau", 't("raid_title")', 1, "Theme.paper", "Theme.senja" },
}

local function channel(value: number): number
	return if value <= 0.03928 then value / 12.92 else ((value + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex: string): number
	local r = channel((tonumber(string.sub(hex, 1, 2), 16) :: number) / 255)
	local g = channel((tonumber(string.sub(hex, 3, 4), 16) :: number) / 255)
	local b = channel((tonumber(string.sub(hex, 5, 6), 16) :: number) / 255)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

local function contrast(a: string, b: string): number
	local la, lb = luminance(a), luminance(b)
	return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

local function trim(value: string): string
	return string.match(value, "^%s*(.-)%s*$")
end

local function rows(doc: string): { { string } }
	local out = {}
	for line in string.gmatch(doc, "[^\n]+") do
		local fg, bg, ratio, verdict, resolution =
			string.match(line, "^|%s*([%a_]+)%s*|%s*([%a_]+)%s*|%s*([%d%.]+)%s*|%s*(%a+)%s*|%s*([%a%s%-]+)%s*|")
		if fg then
			table.insert(out, { fg, bg, ratio, verdict, trim(resolution) })
		end
	end
	return out
end

local function contains(list: { { string } }, fg: string, bg: string): { string }?
	for _, row in list do
		if row[1] == fg and row[2] == bg then
			return row
		end
	end
	return nil
end

return function(t, Env)
	local expect = t.expect
	local Visits
	local doc, parsed

	t:describe("CONTRAST — token-pair audit", function()
		t:beforeEach(function()
			local env = Env.new()
			Visits = env:require("shared/Config/Visuals")
			doc = fs.readFile(DOC)
			parsed = rows(doc)
		end)

		t:it("reports the checked-in threshold and method", function()
			expect(string.find(doc, "4.5:1", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "3:1", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "no visual verdict", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "WCAG", 1, true) ~= nil):toBe(true)
		end)

		t:it("lists every audited token pair with its source-computed ratio", function()
			expect(#parsed):toBe(#PAIRS)
			for _, spec in PAIRS do
				local fg, bg, threshold = spec[1], spec[2], spec[3]
				local hexFg, hexBg = Visits.palette[fg], Visits.palette[bg]
				expect(type(hexFg)):toBe("string")
				expect(type(hexBg)):toBe("string")
				local value = contrast(hexFg, hexBg)
				local expected = string.format("%.2f", value)
				local verdict = if value >= threshold then "PASS" else "FAIL"
				local row = contains(parsed, fg, bg)
				expect(row ~= nil):toBe(true)
				if row then
					expect(row[3]):toBe(expected)
					expect(row[4]):toBe(verdict)
				end
			end
		end)

		t:it("never leaves a FAIL row without a documented resolution", function()
			for _, row in parsed do
				if row[4] == "FAIL" then
					local ok = row[5] == "fixed" or row[5] == "stroke-backed" or row[5] == "designer decision"
					expect(ok):toBe(true)
				end
			end
			expect(string.find(doc, "## Decisions for designer", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "## Fixes applied", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps each fixed swap at its call site and documents before/after", function()
			for _, fix in FIXES do
				local lines = {}
				for line in string.gmatch(fs.readFile(fix[1]), "[^\n]+") do
					table.insert(lines, line)
				end
				local found = false
				for i, line in lines do
					if string.find(line, fix[2], 1, true) then
						local target = lines[i + fix[3]]
						if
							target
							and string.find(target, fix[4], 1, true)
							and string.find(target, fix[5], 1, true) == nil
						then
							found = true
						end
					end
				end
				expect(found):toBe(true)
				expect(string.find(doc, fix[1], 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("records the before and after FAIL counts", function()
			expect(string.find(doc, "Before: 18 scored token pairs, 8 FAIL pairs", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "After: 18 scored token pairs, 3 FAIL pairs", 1, true) ~= nil):toBe(true)
		end)
	end)
end
