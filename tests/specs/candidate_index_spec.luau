--!nocheck
-- WORK_QUEUE item 128: CANDIDATE_INDEX.
-- Focused parity check for docs/v2/visual/CANDIDATE_INDEX.md: one row per LookDev.IDS id, no extras,
-- verdict copied verbatim from CANDIDATES.md, datamodel/module from LookDevReview.paths, family from
-- the id prefix, and review camera taken only from documented SHOT_LIST.md / CANDIDATES.md text and
-- validated against REVIEW_CAMERAS.md. It does not duplicate the gallery's render/cost checks.

local fs = require("@lune/fs")

local INDEX = "docs/v2/visual/CANDIDATE_INDEX.md"
local GALLERY = "docs/v2/visual/CANDIDATES.md"
local SHOT_LIST = "docs/v2/visual/SHOT_LIST.md"
local CAMERA_DOC = "docs/v2/visual/REVIEW_CAMERAS.md"
local HEADER = { "id", "family", "datamodel", "review camera", "verdict", "module file" }

local function trim(s)
	return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

local function splitPreserve(s, sep)
	local out, i = {}, 1
	while true do
		local j = string.find(s, sep, i, true)
		if j == nil then
			out[#out + 1] = string.sub(s, i)
			break
		end
		out[#out + 1] = string.sub(s, i, j - 1)
		i = j + #sep
	end
	return out
end

local function parseTables(src)
	local groups, current = {}, nil
	for line in string.gmatch(src, "[^\r\n]+") do
		local t = trim(line)
		if string.sub(t, 1, 1) == "|" then
			current = current or {}
			current[#current + 1] = t
		elseif current ~= nil then
			groups[#groups + 1] = current
			current = nil
		end
	end
	if current ~= nil then
		groups[#groups + 1] = current
	end
	local tables = {}
	for _, group in groups do
		local lines = {}
		for _, line in group do
			local parts = splitPreserve(line, "|")
			local cells = {}
			for i = 2, #parts - 1 do
				cells[#cells + 1] = trim(parts[i])
			end
			lines[#lines + 1] = cells
		end
		local tb = { header = lines[1], rows = {} }
		for i = 3, #lines do
			tb.rows[#tb.rows + 1] = lines[i]
		end
		tables[#tables + 1] = tb
	end
	return tables
end

local function findTable(tables, first)
	for _, tb in tables do
		if tb.header ~= nil and tb.header[1] == first then
			return tb
		end
	end
	return nil
end

local function familyOf(id)
	return string.gsub(id, "_r%d+.*$", "")
end

-- Camera names are data from REVIEW_CAMERAS.md; no name may be invented by the index.
local function cameraNames()
	local names, order = {}, {}
	for line in string.gmatch(fs.readFile(CAMERA_DOC), "[^\r\n]+") do
		local name = string.match(line, "^|%s*`([%w_]+)`%s*|")
		if name ~= nil then
			names[name] = true
			order[#order + 1] = name
		end
	end
	return names, order
end

local function namesInCell(cell, names, order)
	local out, seen = {}, {}
	local function add(name)
		if names[name] and not seen[name] then
			seen[name] = true
			out[#out + 1] = name
		end
	end
	for a, b in string.gmatch(cell, "`([%w_]+)`%.%.`([%w_]+)`") do
		local active = false
		for _, name in order do
			if name == a then
				active = true
			end
			if active then
				add(name)
			end
			if active and name == b then
				break
			end
		end
	end
	local rest = string.gsub(cell, "`[%w_]+`%.%.`[%w_]+`", "")
	for name in string.gmatch(rest, "`([%w_]+)`") do
		add(name)
	end
	return out
end

local function expectedCameras(id, galleryRow, shotTable, names, order)
	local out, seen = {}, {}
	local function add(name)
		if not seen[name] then
			seen[name] = true
			out[#out + 1] = name
		end
	end
	for _, row in shotTable.rows do
		if string.find(row[2], "`" .. id .. "`", 1, true) ~= nil then
			for _, name in namesInCell(row[4], names, order) do
				add(name)
			end
		end
	end
	if galleryRow ~= nil then
		for _, col in ipairs({ galleryRow[2], galleryRow[5] }) do
			for _, name in namesInCell(col, names, order) do
				add(name)
			end
		end
	end
	return #out > 0 and table.concat(out, ", ") or "—"
end

return function(t, Env)
	local expect = t.expect
	local LookDev = Env.new():require("shared/LookDev")
	local LookDevReview = Env.new():require("shared/LookDevReview")
	local gallery = assert(findTable(parseTables(fs.readFile(GALLERY)), "Candidate"))
	local shotTable = assert(findTable(parseTables(fs.readFile(SHOT_LIST)), "Shot"))
	local index = findTable(parseTables(fs.readFile(INDEX)), "id")
	local names, order = cameraNames()

	local galleryRows, rows = {}, {}
	for _, row in gallery.rows do
		local id = string.match(row[1], "^`(.-)`$")
		galleryRows[id] = row
	end
	if index ~= nil then
		for _, row in index.rows do
			local id = string.match(row[1], "^`(.-)`$")
			rows[id] = row
		end
	end

	local missingGallery, missingPaths, missingRows = {}, {}, {}
	for _, id in LookDev.IDS do
		if galleryRows[id] == nil then
			missingGallery[#missingGallery + 1] = id
		end
		if LookDevReview.paths[id] == nil then
			missingPaths[#missingPaths + 1] = id
		end
		if rows[id] == nil then
			missingRows[#missingRows + 1] = id
		end
	end
	local extras = {}
	for id in rows do
		local known = false
		for _, candidate in LookDev.IDS do
			known = known or candidate == id
		end
		if not known then
			extras[#extras + 1] = id
		end
	end
	table.sort(extras)

	print(
		"CANDIDATE_INDEX ids="
			.. #LookDev.IDS
			.. " rows="
			.. (index ~= nil and #index.rows or 0)
			.. " gallery="
			.. #gallery.rows
			.. " cameras_documented="
			.. #order
			.. " missing_gallery="
			.. #missingGallery
			.. " missing_paths="
			.. #missingPaths
			.. " missing_rows="
			.. #missingRows
			.. " extras="
			.. #extras
	)

	t:describe("CANDIDATE_INDEX", function()
		t:it("has exactly one index row per LookDev id, no extras, and sources agree", function()
			expect(index ~= nil):toBe(true)
			expect(table.concat(HEADER, ",")):toBe(table.concat(index.header, ","))
			expect(table.concat(missingGallery, ", ")):toBe("")
			expect(table.concat(missingPaths, ", ")):toBe("")
			expect(table.concat(missingRows, ", ")):toBe("")
			expect(table.concat(extras, ", ")):toBe("")
			expect(#index.rows):toBe(#LookDev.IDS)
			expect(#LookDev.IDS):toBe(111)
		end)

		t:it("copies verdict, datamodel, module, family and documented camera per id", function()
			local bad = {}
			for _, id in LookDev.IDS do
				local row, galleryRow, path = rows[id], galleryRows[id], LookDevReview.paths[id]
				if row ~= nil and galleryRow ~= nil and path ~= nil then
					local module = "src/" .. path.datamodel .. "/" .. table.concat(path.path, "/") .. ".luau"
					local camera = expectedCameras(id, galleryRow, shotTable, names, order)
					local problems = {}
					if #row ~= #HEADER then
						problems[#problems + 1] = "fields=" .. #row
					end
					if row[2] ~= familyOf(id) then
						problems[#problems + 1] = "family=" .. tostring(row[2])
					end
					if row[3] ~= path.datamodel then
						problems[#problems + 1] = "datamodel=" .. tostring(row[3])
					end
					if row[4] ~= camera then
						problems[#problems + 1] = "camera=" .. tostring(row[4])
					end
					if row[5] ~= galleryRow[6] then
						problems[#problems + 1] = "verdict=" .. tostring(row[5])
					end
					local cellModule = string.match(row[6], "^`(.-)`$") or row[6]
					if cellModule ~= module then
						problems[#problems + 1] = "module=" .. tostring(row[6])
					end
					if #problems > 0 then
						bad[#bad + 1] = id .. ": " .. table.concat(problems, "; ")
					end
				end
			end
			table.sort(bad)
			expect(table.concat(bad, " | ")):toBe("")
		end)

		t:it("uses only documented camera names or the em-dash placeholder", function()
			local bad = {}
			for id, row in rows do
				if row[4] ~= "—" then
					for name in string.gmatch(row[4], "[%w_]+") do
						if names[name] == nil then
							bad[#bad + 1] = id .. "=" .. name
						end
					end
				end
			end
			table.sort(bad)
			expect(table.concat(bad, ", ")):toBe("")
			expect(#order >= 40):toBe(true)
		end)
	end)
end
