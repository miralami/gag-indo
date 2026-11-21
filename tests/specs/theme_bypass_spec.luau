--!nocheck
-- WORK_QUEUE item 123: THEME_BYPASS source-level audit guard (LUNE-ONLY).
--
-- Scope, deliberately explicit:
--   AUDITED (gating): src/client/UI/** -- no Color3.fromRGB, no hardcoded Enum.Font.Name,
--     no exact palette-colour duplicate, and Theme.corner as the only UICorner constructor.
--   DUPLICATE-ONLY (gating): src/client/Feel/** -- world/feel VFX literals stay as-is; a new
--     literal exactly equal to a Visuals.palette token fails.
--   DOC-ONLY (not gated here): src/client/Minigames/** token-equal corners, Hud.luau's
--     Color3.new(0, 0, 0) Lerp dimmer, and src/client/World/** world colours.
-- Baseline 2026-11-22: 0 exact-colour token duplicates in UI before and after; no colour
-- code was changed. The radius multiset below locks the 6 non-token / 6 token-equal audit.

local fs = require("@lune/fs")

local UI_DIR = "src/client/UI"
local FEEL_DIR = "src/client/Feel"
local VISUALS = "src/shared/Config/Visuals.luau"
local THEME = "src/client/UI/Theme.luau"

-- Exact multiset of numeric Theme.corner radii in UI (doc tables b + c): 2:1, 3:2, 6:1,
-- 8:3, 10:2, 14:1, 18:1, 26:1 -- 13 sites total.
local EXPECTED_CORNER_COUNTS = {
	[2] = 1,
	[3] = 2,
	[6] = 1,
	[8] = 3,
	[10] = 2,
	[14] = 1,
	[18] = 1,
	[26] = 1,
}
local EXPECTED_NON_TOKEN_CORNERS = 6

-- The 6 non-token sites, matched by source anchor so an unrelated line shift does not
-- silently move the audited value.
local NON_TOKEN_SITES = {
	{ path = "src/client/UI/Theme.luau", needle = "Theme.corner(accent, 3)" },
	{ path = "src/client/UI/Phone.luau", needle = "Theme.corner(nil, 26)" },
	{ path = "src/client/UI/Phone.luau", needle = "Theme.corner(nil, 2)" },
	{ path = "src/client/UI/Phone.luau", needle = "Theme.corner(nil, 18)" },
	{ path = "src/client/UI/Phone.luau", needle = "Theme.corner(nil, 3)" },
	{ path = "src/client/UI/Phone.luau", needle = "Theme.corner(nil, 6)" },
}

local function read(path: string): string
	return fs.readFile(path)
end

local function collect(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			collect(path, out)
		elseif string.match(name, "%.luau$") then
			table.insert(out, path)
		end
	end
end

local function sourceFiles(dir: string): { string }
	local out = {}
	collect(dir, out)
	table.sort(out)
	return out
end

local function splitLines(src: string): { string }
	local out = {}
	for line in string.gmatch(src, "([^\n]*)") do
		out[#out + 1] = line
	end
	return out
end

-- Hex strings under Visuals.palette -> integer {r, g, b} triples, so the comparison with
-- Color3.fromRGB is exact (both are 0..255 integers at these call sites).
local function paletteTriples()
	local out = {}
	local block = string.match(read(VISUALS), "Visuals%.palette%s*=%s*{(.-)}")
	if not block then
		return out
	end
	for name, hex in string.gmatch(block, '(%w+)%s*=%s*"(%x%x%x%x%x%x)"') do
		out[name] = {
			tonumber(string.sub(hex, 1, 2), 16),
			tonumber(string.sub(hex, 3, 4), 16),
			tonumber(string.sub(hex, 5, 6), 16),
		}
	end
	return out
end

local function radiusTokens()
	local out = {}
	local block = string.match(read(VISUALS), "Visuals%.radius%s*=%s*{(.-)}")
	if not block then
		return out
	end
	for name, value in string.gmatch(block, "(%a+)%s*=%s*(%d+)") do
		out[tonumber(value)] = name
	end
	return out
end

local function fromRgbSites(path: string)
	local out = {}
	for lineno, line in ipairs(splitLines(read(path))) do
		for args in string.gmatch(line, "Color3%.fromRGB%(([^%)]*)%)") do
			local rgb = {}
			for raw in string.gmatch(args, "[%d%.]+") do
				rgb[#rgb + 1] = tonumber(raw)
			end
			if #rgb == 3 then
				table.insert(out, { line = lineno, rgb = rgb })
			end
		end
	end
	return out
end

local function cornerSites(path: string)
	local out = {}
	for lineno, line in ipairs(splitLines(read(path))) do
		for raw in string.gmatch(line, "Theme%.corner%([^,]+,%s*(%d+)%s*%)") do
			table.insert(out, { line = lineno, value = tonumber(raw) })
		end
	end
	return out
end

return function(t, Env, Fakes)
	local expect = t.expect

	t:describe("THEME_BYPASS theme token audit", function()
		t:it("reads the token sources and the audited UI scope", function()
			local ui = sourceFiles(UI_DIR)
			expect(fs.isDir(UI_DIR)):toBe(true)
			expect(fs.isDir(FEEL_DIR)):toBe(true)
			expect(#ui):toBeAtLeast(16)

			local palette = paletteTriples()
			local radii = radiusTokens()
			local count = 0
			for _ in palette do
				count += 1
			end
			expect(count):toBe(13)
			expect(radii[14]):toBe("card")
			expect(radii[10]):toBe("button")
			expect(radii[8]):toBe("chip")

			local theme = read(THEME)
			expect(string.find(theme, "Color3.fromHex(Visuals.palette[name])", 1, true) ~= nil):toBeTruthy()
			expect(string.find(theme, "Enum.Font[Visuals.fonts.body]", 1, true) ~= nil):toBeTruthy()
			expect(string.find(theme, "Enum.Font[Visuals.fonts.display]", 1, true) ~= nil):toBeTruthy()
		end)

		t:it("THEME_BYPASS: UI has no Color3.fromRGB and no hardcoded Enum.Font", function()
			local problems = {}
			local ctorCount = 0
			for _, path in sourceFiles(UI_DIR) do
				for lineno, line in ipairs(splitLines(read(path))) do
					if string.find(line, "Color3.fromRGB", 1, true) then
						table.insert(problems, `{path}:{lineno}: Color3.fromRGB`)
					end
					if string.find(line, "Enum.Font%.%a+") then
						table.insert(problems, `{path}:{lineno}: hardcoded Enum.Font`)
					end
					for _ in string.gmatch(line, "Instance%.new%([\"']UICorner[\"']%)") do
						ctorCount += 1
						if path ~= THEME then
							table.insert(problems, `{path}:{lineno}: direct UICorner constructor`)
						end
					end
				end
			end
			-- Theme.corner is the single UICorner constructor; nothing else builds one.
			expect(ctorCount):toBe(1)
			if #problems > 0 then
				error("THEME_BYPASS UI bypasses:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("THEME_BYPASS: 0 exact-colour theme-token duplicates, before and after", function()
			local palette = paletteTriples()
			local problems = {}
			for _, dir in { UI_DIR, FEEL_DIR } do
				for _, path in sourceFiles(dir) do
					for _, site in fromRgbSites(path) do
						for name, token in palette do
							if site.rgb[1] == token[1] and site.rgb[2] == token[2] and site.rgb[3] == token[3] then
								table.insert(
									problems,
									`{path}:{site.line}: ({site.rgb[1]}, {site.rgb[2]}, {site.rgb[3]}) duplicates {name}`
								)
							end
						end
					end
				end
			end
			if #problems > 0 then
				error("THEME_BYPASS token duplicates:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("THEME_BYPASS: corner radii stay at the audited 6 non-token literals", function()
			local radii = radiusTokens()
			local actual = {}
			local total = 0
			for _, path in sourceFiles(UI_DIR) do
				for _, site in cornerSites(path) do
					actual[site.value] = (actual[site.value] or 0) + 1
					total += 1
				end
			end
			local expectedTotal = 0
			for value, expected in EXPECTED_CORNER_COUNTS do
				expectedTotal += expected
				expect(actual[value] or 0):toBe(expected)
			end
			expect(total):toBe(expectedTotal)
			for value in actual do
				expect(EXPECTED_CORNER_COUNTS[value] ~= nil):toBeTruthy()
			end

			local nonToken = 0
			for value, count in actual do
				if radii[value] == nil then
					nonToken += count
				end
			end
			expect(nonToken):toBe(EXPECTED_NON_TOKEN_CORNERS)

			local missing = {}
			for _, site in NON_TOKEN_SITES do
				if string.find(read(site.path), site.needle, 1, true) == nil then
					table.insert(missing, `{site.path}: {site.needle}`)
				end
			end
			if #missing > 0 then
				error("THEME_BYPASS audited corner sites changed:\n  " .. table.concat(missing, "\n  "), 0)
			end
		end)
	end)
end
