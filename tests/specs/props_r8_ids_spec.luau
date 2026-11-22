--!nocheck
-- WORK_QUEUE item 64: pure-data locks for the three R7-only prop replacements.
-- No Studio, no visual verdict, no applier execution. Main session wires the runner.

local fs = require("@lune/fs")

local DATA_PATH = "src/shared/ModelMapPropsR7.luau"
local BAKE_PATH = "tools/studio/bake_lookdev_assets.luau"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local R4 = env:require("shared/ModelMapPropsR4")
	local R6 = env:require("shared/ModelMapPropsR6")
	local R7 = env:require("shared/ModelMapPropsR7")
	local family = R7.families[R7.familyId]
	local data = fs.readFile(DATA_PATH)
	local bake = fs.readFile(BAKE_PATH)
	local r4ids = R4.idsFor("props_r4")

	local r6slots = {}
	for _, slot in ipairs(R6.families[R6.familyId].slots) do
		r6slots[slot.slot] = slot
	end

	local function findSlot(name)
		for _, slot in ipairs(family.slots) do
			if slot.slot == name then
				return slot
			end
		end
		return nil
	end

	local function closeTo(value, target)
		return type(value) == "number" and math.abs(value - target) < 1e-9
	end

	-- Verified in Edit mode on 2026-11-21 with GetObjects; native bbox measured in Studio.
	local replacements = {
		alat_tani = { id = 4951145641, old = 109848917287023, height = 4 },
		gerobak = { id = 10506531785, old = 119426685469058, height = 3.33 },
		pagar_bambu = { id = 85094565897097, old = 103341007913673, height = 3.05 },
	}

	t:describe("props_r8 R7-only id replacements", function()
		t:it("uses exactly the three verified ids and drops the weak R4 ids", function()
			expect(R7.slotOrder):toEqual({ "gerobak", "sumur", "lapak", "pagar_bambu", "alat_tani", "jemuran" })
			expect(#family.slots):toBe(6)
			for slotName, rule in pairs(replacements) do
				expect(family.ids[slotName]):toBe(rule.id)
				expect(r4ids[slotName]):toBe(rule.old)
				expect(family.ids[slotName] ~= r4ids[slotName]):toBe(true)
				local entry = findSlot(slotName)
				expect(entry ~= nil):toBe(true)
				expect(closeTo(entry.height, rule.height)):toBe(true)
				expect(closeTo(entry.height, entry.targetHeight * entry.scale)):toBe(true)
			end
			expect(string.find(data, "WORK_QUEUE item 64", 1, true) ~= nil):toBe(true)
			for _, old in ipairs({ 109848917287023, 119426685469058, 103341007913673 }) do
				expect(string.find(data, tostring(old), 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("meets the item 64 size bands and keeps non-fence rotations", function()
			local cangkul = findSlot("alat_tani")
			expect(cangkul.height >= 3.5 and cangkul.height <= 4.5):toBe(true)
			expect(cangkul.ry):toBe(r6slots.alat_tani.ry)

			-- "Gerobak" native bbox 5.5 x 9 x 13.5: long axis Z, so it scales with Y=9.
			local gerobak = findSlot("gerobak")
			local longAxis = gerobak.height * (13.5 / 9)
			expect(longAxis >= 4 and longAxis <= 6):toBe(true)
			expect(gerobak.ry):toBe(r6slots.gerobak.ry)

			-- R3 fence native bbox 4.1 x 1.5 x 0.1: long axis X, ry must keep it on X.
			local pagar = findSlot("pagar_bambu")
			expect(pagar.ry):toBe(0)
			expect(pagar.height * (4.1 / 1.5) >= 8):toBe(true)
		end)

		t:it("leaves sumur, lapak and jemuran on their R6 ids, sizes and rotations", function()
			for _, slotName in ipairs({ "sumur", "lapak", "jemuran" }) do
				expect(family.ids[slotName]):toBe(r4ids[slotName])
				local entry, r6 = findSlot(slotName), r6slots[slotName]
				expect(closeTo(entry.height, R6.effectiveHeight(r6))):toBe(true)
				expect(closeTo(entry.targetHeight, r6.targetHeight)):toBe(true)
				expect(closeTo(entry.scale, r6.scale)):toBe(true)
				expect(entry.ry):toBe(r6.ry)
			end
		end)

		t:it("bakes all three new ids without removing the old ones", function()
			expect(string.find(bake, "props_r8 (WORK_QUEUE item 64)", 1, true) ~= nil):toBe(true)
			for _, id in ipairs({ 4951145641, 10506531785, 85094565897097 }) do
				expect(string.find(bake, tostring(id), 1, true) ~= nil):toBe(true)
			end
			for _, old in ipairs({ 109848917287023, 119426685469058, 103341007913673 }) do
				expect(string.find(bake, tostring(old), 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
