--!nocheck
-- WORK_QUEUE item 127: ASSET_MANIFEST_COVERAGE.
-- Source-level, no Studio: every 7-15 digit asset ID in src/shared/*Map*.luau must appear in
-- docs/v2/visual/art/ASSET_MANIFEST.md, and every manifest ID must resolve in src/ or be marked
-- `unused` in the manifest's coverage table. The scan reads source text, so `rbxassetid://<id>` and
-- store URLs count too. Nothing here edits code or deletes an ID to make a check pass.
--
-- Measured baseline 2026-11-22: 72 map modules / 297 map IDs (299 digit runs minus the two i32 RNG
-- moduli) / 324 src IDs / 328 manifest IDs / 10 map IDs added to the manifest / 24 marked unused.

local fs = require("@lune/fs")

local MANIFEST = "docs/v2/visual/art/ASSET_MANIFEST.md"
local SHARED = "src/shared"
local NON_ASSET = {
	[2147483646] = "i32 RNG modulus in the pure-data modules, not an asset ID",
	[2147483647] = "i32 RNG modulus in the pure-data modules, not an asset ID",
}

local function collectIds(text, out)
	for run in string.gmatch(text, "%d%d%d%d%d%d%d+") do
		if #run <= 15 then
			local id = tonumber(run)
			if id ~= nil and NON_ASSET[id] == nil then
				out[id] = true
			end
		end
	end
end

local function walk(dir, out)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			walk(path, out)
		elseif string.sub(name, -5) == ".luau" then
			collectIds(fs.readFile(path), out)
		end
	end
end

local function mapIds()
	local out, modules = {}, 0
	for _, name in fs.readDir(SHARED) do
		if string.find(name, "Map", 1, true) and string.sub(name, -5) == ".luau" then
			modules += 1
			collectIds(fs.readFile(SHARED .. "/" .. name), out)
		end
	end
	return out, modules
end

local function trim(s)
	return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

-- A markdown row `| 155440478 | ... | unused |` has an empty leading/trailing field; the marker is
-- the second-to-last cell. Only those rows count: prose about the convention never marks an ID.
local function markedUnused(raw)
	local out = {}
	for line in string.gmatch(raw, "[^\r\n]+") do
		local cells, start = {}, 1
		while true do
			local bar = string.find(line, "|", start, true)
			if bar == nil then
				cells[#cells + 1] = string.sub(line, start)
				break
			end
			cells[#cells + 1] = string.sub(line, start, bar - 1)
			start = bar + 1
		end
		if #cells >= 5 and trim(cells[#cells - 1]) == "unused" then
			local id = tonumber((trim(cells[2])))
			if id ~= nil then
				out[id] = true
			end
		end
	end
	return out
end

local function count(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function sortedKeys(t)
	local out = {}
	for key in t do
		out[#out + 1] = key
	end
	table.sort(out)
	return out
end

local code, modules = mapIds()
local src = {}
walk("src", src)
local raw = fs.readFile(MANIFEST)
local manifest = {}
collectIds(raw, manifest)
local marked = markedUnused(raw)

local missing = {}
for id in code do
	if manifest[id] == nil then
		missing[#missing + 1] = id
	end
end
table.sort(missing)

local unmarked = {}
for id in manifest do
	if src[id] == nil and marked[id] == nil then
		unmarked[#unmarked + 1] = id
	end
end
table.sort(unmarked)

print(
	"ASSET_MANIFEST_COVERAGE modules="
		.. modules
		.. " code="
		.. count(code)
		.. " src="
		.. count(src)
		.. " manifest="
		.. count(manifest)
		.. " missing="
		.. #missing
		.. " marked_unused="
		.. count(marked)
		.. " unmarked_without_use="
		.. #unmarked
)

return function(t)
	local expect = t.expect

	t:describe("ASSET_MANIFEST_COVERAGE", function()
		t:it("every numeric ID in src/shared/*Map*.luau is in ASSET_MANIFEST.md", function()
			-- Guard against a vacuous pass if the map directory or the ID pattern changes.
			expect(modules >= 60):toBe(true)
			expect(count(code) >= 250):toBe(true)
			expect(count(manifest) >= 300):toBe(true)
			expect(table.concat(missing, ", ")):toBe("")
			expect(#missing):toBe(0)
		end)

		t:it("every manifest ID is used in src/ or explicitly marked unused", function()
			expect(count(marked) >= 20):toBe(true)
			expect(table.concat(unmarked, ", ")):toBe("")
			expect(#unmarked):toBe(0)
			-- An ID used in code must not also claim the unused marker.
			local stale = {}
			for id in marked do
				if src[id] ~= nil then
					stale[#stale + 1] = tostring(id)
				end
			end
			table.sort(stale)
			expect(table.concat(stale, ", ")):toBe("")
		end)

		t:it("the marked-unused table carries one marker per ID with no code use", function()
			local expected, actual = {}, sortedKeys(marked)
			for id in manifest do
				if src[id] == nil then
					expected[#expected + 1] = id
				end
			end
			table.sort(expected)
			expect(table.concat(actual, ",")):toBe(table.concat(expected, ","))
			expect(#actual):toBe(29)
		end)
	end)
end
