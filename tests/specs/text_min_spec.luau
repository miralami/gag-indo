--!nocheck
-- WORK_QUEUE item 126: CHECK TEXT_MIN. LUNE-ONLY static source audit.
-- Every literal text size below 14 in src/client/UI/** must be listed in
-- docs/v2/visual/TEXT_MIN_AUDIT.md with a recorded disposition, and the existing
-- 11/13 type-scale and MinTextSize locks must remain unchanged (strengthening is fine).

local fs = require("@lune/fs")

local ROOT = "src/client/UI"
local DOC = "docs/v2/visual/TEXT_MIN_AUDIT.md"
local TYPE_LOCKS = "tests/specs/visuals_spec.luau"
local TOUCH_LOCKS = "tests/specs/ui_touch_text_audit_spec.luau"

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

local function uiFiles(): { string }
	local out = {}
	collect(ROOT, out)
	table.sort(out)
	return out
end

local function splitLines(src: string): { string }
	local out = {}
	for line in string.gmatch(src .. "\n", "([^\n]*)\n") do
		out[#out + 1] = line
	end
	return out
end

-- Returns { key, value } for any literal size <14 on this line. MaxTextSize is ignored;
-- MinTextSize is stripped before matching TextSize so the two never double-count.
local function smallSizes(line: string)
	local found = {}
	local clean = string.gsub(line, "MinTextSize", "MINSIZE")
	clean = string.gsub(clean, "MaxTextSize", "MAXSIZE")
	for raw in string.gmatch(clean, "TextSize%s*=%s*(%d+)") do
		local value = tonumber(raw) :: number
		if value < 14 then
			table.insert(found, { "TextSize", value })
		end
	end
	for raw in string.gmatch(line, "MinTextSize%s*=%s*(%d+)") do
		local value = tonumber(raw) :: number
		if value < 14 then
			table.insert(found, { "MinTextSize", value })
		end
	end
	for token in string.gmatch(clean, "TextSize%s*=%s*Visuals%.type%.([%a]+)") do
		if token == "small" then
			table.insert(found, { "TextSize", 11 })
		elseif token == "body" then
			table.insert(found, { "TextSize", 13 })
		end
	end
	return found
end

local function docRows(doc: string): { [string]: { string } }
	local out = {}
	for line in string.gmatch(doc, "[^\n]+") do
		local site, key, value, status, reason =
			string.match(line, "^|%s*`([^`]+)`%s*|%s*(%w+)%s*|%s*(%d+)%s*|%s*([%a%s%-]+)%s*|%s*([^|]+)|")
		if site then
			out[site] = {
				key,
				value,
				string.match(status, "^%s*(.-)%s*$"),
				string.match(reason, "^%s*(.-)%s*$"),
			}
		end
	end
	return out
end

return function(t, Env)
	local expect = t.expect
	local doc, listed, Visuals

	t:describe("TEXT_MIN — 14 px floor audit", function()
		t:beforeEach(function()
			doc = fs.readFile(DOC)
			listed = docRows(doc)
			Visuals = Env.new():require("shared/Config/Visuals")
		end)

		t:it("states the method, viewport and the unchanged-lock caveat", function()
			expect(string.find(doc, "375 px", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "could not be universally applied", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "no visual verdict", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "## Decisions for designer", 1, true) ~= nil):toBe(true)
		end)

		t:it("documents every literal sub-14 size in the audited scope", function()
			local files = uiFiles()
			expect(#files):toBeAtLeast(8)
			local count = 0
			for _, path in files do
				for lineno, line in splitLines(fs.readFile(path)) do
					for _, hit in smallSizes(line) do
						local site = path .. ":" .. lineno
						count += 1
						local row = listed[site]
						expect(row ~= nil):toBe(true)
						if row then
							expect(row[1]):toBe(hit[1])
							expect(row[2]):toBe(tostring(hit[2]))
							expect(row[3]):toBe("designer decision")
							expect(#row[4] > 0):toBe(true)
						end
					end
				end
			end
			expect(count):toBeAtLeast(18)
			local listedCount = 0
			for _ in listed do
				listedCount += 1
			end
			expect(listedCount):toBe(count)
		end)

		t:it("keeps the locked 11/13 type scale and the two phone minimums", function()
			expect(Visuals.type.body):toBe(13)
			expect(Visuals.type.small):toBe(11)
			local visualSpec = fs.readFile(TYPE_LOCKS)
			expect(string.find(visualSpec, "expect(Visuals.type.body):toBe(13)", 1, true) ~= nil):toBe(true)
			expect(string.find(visualSpec, "expect(Visuals.type.small):toBe(11)", 1, true) ~= nil):toBe(true)
			local touchSpec = fs.readFile(TOUCH_LOCKS)
			expect(string.find(touchSpec, "MinTextSize = 11, Parent = label", 1, true) ~= nil):toBe(true)
			expect(string.find(touchSpec, "MinTextSize = 11, Parent = litLabel", 1, true) ~= nil):toBe(true)
		end)

		t:it("reports the audit counts", function()
			expect(string.find(doc, "Fixed: 0", 1, true) ~= nil):toBe(true)
			expect(string.find(doc, "Left unchanged with a recorded designer-decision reason: 18", 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(doc, "Locks changed: 0", 1, true) ~= nil):toBe(true)
		end)
	end)
end
