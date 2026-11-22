--!nocheck
-- WORK_QUEUE section M item 96: IconMap coverage.
-- Every IconMap slot resolves to a non-zero asset ID recorded in ASSET_MANIFEST.md,
-- and no ID appears twice by mistake.
--
-- CAVEAT, locked in here: IconMap entry.id is 0 BY DESIGN for all 27 slots (round-2
-- fallback slots). The non-zero IDs live in IconMap.candidateIds (the off-by-default
-- "icons" LookDev candidate). This spec checks candidateIds, never the zero entry.id.
--
-- Measured baseline: 27 slots / 27 candidate IDs (all unique) / 55 icon CSV rows in the
-- manifest (28 round-2 + 27 round-3) / 27 of 27 candidate IDs found / 0 duplicate IDs /
-- 0 overlap with IconMapR3.ids (separate uploads for the same slots, never a legitimate reuse).

local fs = require("@lune/fs")

local MANIFEST = "docs/v2/visual/art/ASSET_MANIFEST.md"

local function csvFields(line: string)
	local fields = {}
	local start = 1
	while true do
		local comma = string.find(line, ",", start, true)
		if comma then
			fields[#fields + 1] = string.sub(line, start, comma - 1)
			start = comma + 1
		else
			fields[#fields + 1] = string.sub(line, start)
			break
		end
	end
	return fields
end

-- Parse every fenced CSV icon row (slot,class,source,source_ref,licence,attribution,id,
-- approved_by,status); the asset ID is the 7th column. Unparseable rows are returned so the
-- caller can fail loudly instead of silently skipping them.
local function iconManifestIds(raw: string)
	local ids = {}
	local bad = {}
	local rows = 0
	for line in string.gmatch(raw, "[^\r\n]+") do
		local fields = csvFields(line)
		if #fields == 9 and string.match(fields[1], "^icon[._]") then
			local idText = fields[7]
			local id = tonumber(idText)
			if id == nil or tostring(id) ~= idText then
				bad[#bad + 1] = fields[1] .. "=" .. idText
			else
				ids[id] = true
			end
			rows += 1
		end
	end
	return ids, rows, bad
end

return function(t, Env)
	local expect = t.expect
	local env, IconMap, IconMapR3

	local function slotEntries()
		local out = {}
		local function add(family, entries)
			for key, entry in entries do
				out[#out + 1] = { slot = entry.slot, key = key, family = family, entryId = entry.id }
			end
		end
		add("crops", IconMap.crops)
		add("currency", IconMap.currency)
		add("tiers", IconMap.tiers)
		add("phoneApps", IconMap.phoneApps)
		return out
	end

	t:describe("IconMap coverage vs ASSET_MANIFEST", function()
		t:beforeEach(function()
			env = Env.new()
			IconMap = env:require("shared/IconMap")
			IconMapR3 = env:require("shared/IconMapR3")
		end)

		t:it("27 slots across four families each resolve to a non-zero candidate id", function()
			local slots = slotEntries()
			expect(#slots):toBe(27)

			local familyCounts = { crops = 0, currency = 0, tiers = 0, phoneApps = 0 }
			local seenSlot = {}
			for _, s in slots do
				expect(type(s.key) == "string" and #s.key > 0):toBe(true)
				expect(type(s.slot) == "string" and #s.slot > 0):toBe(true)
				expect(s.family ~= nil):toBe(true)
				familyCounts[s.family] += 1
				expect(seenSlot[s.slot]):toBe(nil)
				seenSlot[s.slot] = true

				-- entry.id zero is intentional; the candidate id is the resolved asset id.
				expect(s.entryId):toBe(0)
				local id = IconMap.candidateIds[s.slot]
				expect(type(id) == "number"):toBe(true)
				expect(id > 0):toBe(true)
				expect(tostring(id) ~= "0"):toBe(true)
				expect(string.match(tostring(id), "^%d+$") ~= nil):toBe(true)
			end
			expect(familyCounts.crops):toBe(12)
			expect(familyCounts.currency):toBe(2)
			expect(familyCounts.tiers):toBe(5)
			expect(familyCounts.phoneApps):toBe(8)

			local candidateCount = 0
			for slot in IconMap.candidateIds do
				candidateCount += 1
				expect(seenSlot[slot] == true):toBe(true) -- no candidate key outside the 4 families
			end
			expect(candidateCount):toBe(27)
		end)

		t:it("all 27 candidate ids appear in the manifest icon CSV rows", function()
			local raw = fs.readFile(MANIFEST)
			expect(#raw > 0):toBe(true)
			local ids, rows, bad = iconManifestIds(raw)
			expect(table.concat(bad, "; ")):toBe("")
			-- Guard against a vacuous pass if the CSV shape changes and parsing finds nothing.
			expect(rows >= 27):toBe(true)

			local missing = {}
			local found = 0
			for slot, id in IconMap.candidateIds do
				if ids[id] then
					found += 1
				else
					missing[#missing + 1] = slot .. "=" .. tostring(id)
				end
			end
			expect(table.concat(missing, ", ")):toBe("")
			expect(found):toBe(27)
		end)

		t:it("no id appears twice, including across the r2/r3 revisions", function()
			local seen = {}
			local duplicates = {}
			local uniqueIds = 0
			for slot, id in IconMap.candidateIds do
				if seen[id] then
					duplicates[#duplicates + 1] = slot .. "=" .. tostring(id)
				else
					seen[id] = true
					uniqueIds += 1
				end
			end
			expect(table.concat(duplicates, ", ")):toBe("")
			expect(uniqueIds):toBe(27)

			-- IconMapR3 is a separate LookDev candidate whose IDs are different uploads for
			-- the same slots; reuse of an ID across revisions would be a copy/paste mistake.
			local r3Seen = {}
			local overlap = {}
			local r3Count = 0
			for slot, id in IconMapR3.ids do
				r3Count += 1
				if seen[id] then
					overlap[#overlap + 1] = "r3." .. slot .. "=" .. tostring(id)
				end
				if r3Seen[id] then
					overlap[#overlap + 1] = "r3.dup." .. slot .. "=" .. tostring(id)
				end
				r3Seen[id] = true
			end
			expect(table.concat(overlap, ", ")):toBe("")
			expect(r3Count):toBe(27)
		end)
	end)
end
