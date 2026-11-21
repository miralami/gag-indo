--!nocheck
-- WORK_QUEUE section M6 item 93: crop stage audit. These are PURE Lune checks over the shared
-- model map (the rescale fix + the check plumbing). The live 12x3 GetBoundingBox measurement and
-- the verbatim `CHECK CROP_GROWTH ...` line are engine-only and live in
-- tools/studio/crop_growth_check.luau + CHECK_093.txt; this spec locks the data and plumbing so the
-- Studio PASS cannot silently regress. The 0.5..6 stud and 15% thresholds are declared here AND in
-- the Studio script and are never weakened.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/CropModelCandidates")
	local auditSrc = fs.readFile("tools/studio/crop_growth_check.luau")

	-- Thresholds are the item's verbatim bounds, stated in both files, never weakened.
	expect(auditSrc:find("MIN_H = 0.5", 1, true) ~= nil):toBe(true)
	expect(auditSrc:find("MAX_H = 6.0", 1, true) ~= nil):toBe(true)
	expect(auditSrc:find("MIN_GROWTH = 15.0", 1, true) ~= nil):toBe(true)

	-- The check measures the ENGINE bounding box (not the pure descriptor approximation) and freezes
	-- the unanchored showcase parts in the same call, before any physics step can drift them.
	expect(auditSrc:find("GetBoundingBox()", 1, true) ~= nil):toBe(true)
	expect(auditSrc:find("o.Anchored = true", 1, true) ~= nil):toBe(true)
	expect(auditSrc:find('S:FindFirstChild("LookDevCropsInjected")', 1, true) ~= nil):toBe(true)
	expect(auditSrc:find('LD.enable("crops"', 1, true) ~= nil):toBe(true)
	expect(auditSrc:find('emit("CROP_GROWTH"', 1, true) ~= nil):toBe(true)
	expect(auditSrc:find('(passed and "PASS" or "FAIL")', 1, true) ~= nil):toBe(true)

	-- 12 crops x 3 stages, in order.
	expect(#Data.cropIds):toBe(12)
	expect(#Data.stages):toBe(3)
	expect(Data.stages[1]):toBe("bibit")
	expect(Data.stages[2]):toBe("tumbuh")
	expect(Data.stages[3]):toBe("siap")
	local expectIds = {
		"padi",
		"singkong",
		"jagung",
		"bawang",
		"cabai",
		"tembakau",
		"kopi",
		"tebu",
		"kakao",
		"cengkeh",
		"durian",
		"sawit",
	}
	for i, id in ipairs(expectIds) do
		expect(Data.cropIds[i]):toBe(id)
	end

	-- The item-93 rescale: bawang stem size[2] 0.8 -> 1.4. Locks the fix so it cannot regress.
	expect(Data.archetypes.bawang.stem.size[2]):toBe(1.4)

	-- Every archetype still yields strict stem-height growth for all three stages and sizes within
	-- the model map's own 8-stud part cap (kept intact; the growth check threshold is separate).
	for _, id in ipairs(Data.cropIds) do
		local heights = {}
		for _, stage in ipairs(Data.stages) do
			local parts = Data.partsFor(id, stage)
			expect(parts ~= nil):toBe(true)
			local stem = parts[1]
			heights[#heights + 1] = stem.size[2]
			for _, p in ipairs(parts) do
				for _, s in ipairs(p.size) do
					expect(s > 0):toBe(true)
					expect(s <= 8):toBe(true)
				end
			end
		end
		expect(heights[1] < heights[2]):toBe(true)
		expect(heights[2] < heights[3]):toBe(true)
	end
end
