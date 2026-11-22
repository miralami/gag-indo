--!nocheck
-- WORK_QUEUE item 10: the candidate gallery (docs/v2/visual/CANDIDATES.md) must carry exactly one
-- row per LookDev candidate, with the toggle, a render/screenshot that exists on disk, the cost,
-- and a designer yes/no column that NO agent has filled. This spec locks the gallery against drift
-- as candidates are added; it never marks a candidate approved (that is the designer's decision).

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local GALLERY = "docs/v2/visual/CANDIDATES.md"

	local function trim(s)
		return string.gsub(s, "^%s*(.-)%s*$", "%1")
	end

	-- Split preserving empty fields, so a blank designer cell stays visible as "".
	local function splitPreserve(s, sep)
		local out = {}
		local i = 1
		while true do
			local j = string.find(s, sep, i, true)
			if not j then
				out[#out + 1] = string.sub(s, i)
				break
			end
			out[#out + 1] = string.sub(s, i, j - 1)
			i = j + #sep
		end
		return out
	end

	-- Parse every markdown table into { header = {cells}, rows = { {cells}, ... } }.
	local function parseTables(src)
		local groups, current = {}, nil
		for line in string.gmatch(src, "[^\r\n]+") do
			local t = trim(line)
			if string.sub(t, 1, 1) == "|" then
				current = current or {}
				current[#current + 1] = t
			elseif current then
				groups[#groups + 1] = current
				current = nil
			end
		end
		if current then
			groups[#groups + 1] = current
		end

		local tables = {}
		for _, group in groups do
			local lines = {}
			for _, line in group do
				local parts = splitPreserve(line, "|")
				local cells = {}
				for i = 2, #parts - 1 do -- drop leading/trailing pipe fields
					cells[#cells + 1] = trim(parts[i])
				end
				lines[#lines + 1] = cells
			end
			local tb = { header = lines[1], rows = {} }
			for i = 3, #lines do -- lines[2] is the |---| separator
				tb.rows[#tb.rows + 1] = lines[i]
			end
			tables[#tables + 1] = tb
		end
		return tables
	end

	local function findTable(tables, firstHeaderCell)
		for _, tb in tables do
			if tb.header and tb.header[1] == firstHeaderCell then
				return tb
			end
		end
		return nil
	end

	t:describe("Candidate gallery (one row per candidate, designer yes/no blank)", function()
		local src, LookDev, gallery
		t:beforeEach(function()
			src = fs.readFile(GALLERY)
			LookDev = Env.new():require("shared/LookDev")
			gallery = findTable(parseTables(src), "Candidate")
		end)

		t:it("exists with the toggle, render, cost and designer yes/no columns", function()
			expect(gallery ~= nil):toBe(true)
			expect(#gallery.header):toBe(6)
			expect(gallery.header[1]):toBe("Candidate")
			expect(gallery.header[3]):toBe("Toggle")
			expect(gallery.header[4]):toBe("Render / screenshot")
			expect(gallery.header[5]):toBe("Cost (instances / fps)")
			expect(gallery.header[6]):toBe("Designer yes/no")
		end)

		t:it("has exactly one row per LookDev candidate and no extras", function()
			local seen = {}
			for _, row in gallery.rows do
				local id = string.match(row[1], "^`(.-)`$")
				expect(id ~= nil):toBe(true)
				expect(seen[id]):toBe(nil) -- no duplicate rows
				seen[id] = true
			end
			for _, id in LookDev.IDS do
				expect(seen[id]):toBe(true)
			end
			local count = 0
			for _ in seen do
				count += 1
			end
			expect(count):toBe(#LookDev.IDS)
		end)

		t:it("each row has a matching toggle, an existing render and an fps cost", function()
			for _, row in gallery.rows do
				local id = string.match(row[1], "^`(.-)`$")
				expect(#row):toBe(6)
				-- toggle names the exact candidate
				expect(string.find(row[3], 'LookDev.enable("' .. id .. '")', 1, true) ~= nil):toBe(true)
				-- render / screenshot is a backtick-wrapped path that really exists
				local render = string.match(row[4], "^`(.-)`$")
				expect(render ~= nil):toBe(true)
				expect(fs.isFile(render) or fs.isDir(render)):toBe(true)
				-- cost states the fps impact
				expect(string.find(string.lower(row[5]), "fps", 1, true) ~= nil):toBe(true)
			end
		end)

		-- A designer cell is blank (undecided), "pending — ...", the item-110 cultural-review flag
		-- "needs designer review: cultural content", or a designer verdict starting with **yes /
		-- **no** (recorded from the designer's own answer, 2026-11-19 round-2 review).
		t:it("keeps every designer yes/no cell blank, pending or a designer verdict", function()
			local tables = parseTables(src)
			local checked = 0
			for _, tb in tables do
				if tb.header[#tb.header] == "Designer yes/no" then
					checked += 1
					for _, row in tb.rows do
						expect(#row):toBe(#tb.header)
						local cell = trim(row[#row])
						local ok = cell == ""
							or string.sub(cell, 1, #"pending") == "pending"
							or string.sub(cell, 1, #"needs designer review") == "needs designer review"
							or string.sub(cell, 1, 5) == "**yes"
							or string.sub(cell, 1, 6) == "**no**"
						expect(ok):toBe(true)
					end
				end
			end
			-- the gallery plus the icons and textures per-asset tables
			expect(checked):toBe(3)
		end)
	end)
end
