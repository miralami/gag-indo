--!nocheck
-- WORK_QUEUE section P item 182: LUNE-ONLY pure-data contract for the blocks_r9 village-ring band.
-- NOT registered in tests/run.luau here; the main session registers new specs in one pass.
-- The Studio staging / PERF_BUDGET / WALKABLE / GATE_CLEAR evidence belongs to
-- tools/studio/check_p182.luau. No visual verdict is made here.
--
-- Measured at HEAD (before this fix): 72 trees total but only 4 inside radius 60..140, with 16
-- shrubs and no alang-alang grass there. After the ring-band pass: 68 band trees, 40 band shrubs.
-- The assertion below is the real gap, not a weakened global ">=60 trees" count.

local fs = require("@lune/fs")

local BAND_MIN, BAND_MAX = 60, 140
local BAND_TREE_TARGET = 60
local BAND_SHRUB_TARGET = 20

local function inBand(slot)
	local radius = math.sqrt(slot.x * slot.x + slot.z * slot.z)
	return radius >= BAND_MIN and radius <= BAND_MAX
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapBlocksR9")
	local R5 = env:require("shared/ModelMapVegetationR5")
	local R7 = env:require("shared/ModelMapVegetationR7")
	local zones = Data.exclusionZones()
	local slots, trees, shrubs = Data.slots(), Data.trees(), Data.shrubs()
	local bandTrees, bandShrubs, bandGrass = {}, {}, {}
	for _, slot in ipairs(trees) do
		if inBand(slot) then
			bandTrees[#bandTrees + 1] = slot
		end
	end
	for _, slot in ipairs(shrubs) do
		if inBand(slot) then
			bandShrubs[#bandShrubs + 1] = slot
			if slot.species == "alang-alang" then
				bandGrass[#bandGrass + 1] = slot
			end
		end
	end
	local applierSrc = fs.readFile("src/server/World/LookDevBlocksR9.luau")
	local dataSrc = fs.readFile("src/shared/ModelMapBlocksR9.luau")

	t:describe("item 182 blocks_r9 village-ring band", function()
		t:it("fills the empty radius 60..140 ring with at least 60 baked trees", function()
			expect(#bandTrees):toBeAtLeast(BAND_TREE_TARGET)
			if type(Data.bandTreeCount) == "function" then
				expect(Data.bandTreeCount()):toBe(#bandTrees)
			end
			expect(Data.MIN_BAND_TREES):toBe(BAND_TREE_TARGET)
			expect(Data.BAND_MIN_RADIUS):toBe(BAND_MIN)
			expect(Data.BAND_MAX_RADIUS):toBe(BAND_MAX)
			for _, slot in ipairs(bandTrees) do
				expect(slot.kind):toBe("tree")
				expect(slot.height >= 6 and slot.height <= 12):toBe(true)
				expect(type(R7.ids[slot.slot])):toBe("number")
			end
		end)

		t:it("adds grassy decoration in the same band", function()
			expect(#bandShrubs):toBeAtLeast(BAND_SHRUB_TARGET)
			expect(#bandGrass):toBeAtLeast(4)
			for _, slot in ipairs(bandGrass) do
				expect(slot.species):toBe("alang-alang")
			end
		end)

		t:it("keeps every item-145 placement guard for the new slots", function()
			expect(#slots):toBe(#trees + #shrubs)
			expect(#trees):toBeAtLeast(Data.MIN_TREES)
			expect(#shrubs):toBeAtLeast(Data.MIN_SHRUBS)
			expect(Data.speciesCount("tree")):toBeAtLeast(Data.MIN_SPECIES)
			expect(Data.minSpacing()):toBeAtLeast(Data.MIN_SPACING)
			for _, slot in ipairs(slots) do
				expect(R5.slotAllowed(slot, zones)):toBe(true)
				expect(Data.slotAllowed(slot, zones)):toBe(true)
				expect(Data.cameraClear(slot)):toBe(true)
			end
			for i = 1, #slots do
				for j = i + 1, #slots do
					local a, b = slots[i], slots[j]
					local disjoint = math.abs(a.x - b.x) >= a.footprint.halfX + b.footprint.halfX
						or math.abs(a.z - b.z) >= a.footprint.halfZ + b.footprint.halfZ
					expect(disjoint):toBe(true)
				end
			end
		end)

		t:it("stages band and grass markers with a non-vacuous applier guard", function()
			expect(applierSrc:find('SetAttribute("BlockBand", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("BlockGrass", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("bandTrees < Data.MIN_BAND_TREES", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("BAND_RADII", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
