--!nocheck
-- WORK_QUEUE item 217: LUNE-ONLY contract for the pure-data visual-risk audit and its bad fixture.
-- Studio emission lives in tools/studio/review_check_visual.luau; this spec asserts neither Studio
-- nor any visual verdict.

local fs = require("@lune/fs")

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Audit = env:require("shared/VisualRiskAudit")
	local Fixture = env:require("shared/ModelMapVisualFixtureBad")
	local pureSrc = fs.readFile("src/shared/VisualRiskAudit.luau")
	local good = {
		{ name = "Base", shape = "Ball", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
		{ name = "Neighbour", shape = "Ball", size = { 2, 2, 2 }, position = { 2, 0, 0 } },
	}

	t:describe("visual risk audit", function()
		t:it("stays pure: no engine calls in the audit module", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum.", "Vector3", "workspace" }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			expect(Fixture.id):toBe("visual_fixture_bad")
		end)

		t:it("passes the good touching cluster on all three checks", function()
			expect(#Audit.floaters(good)):toBe(0)
			expect(#Audit.cubeShrubs(good)):toBe(0)
			expect(#Audit.sizeSanity(good)):toBe(0)
		end)

		t:it("bad fixture trips all three checks on its named offenders", function()
			local parts = Fixture.parts()
			expect(Audit.floaters(parts)):toContain("FloatingRock")
			expect(Audit.cubeShrubs(parts)):toContain("CubeShrub")
			expect(Audit.sizeSanity(parts)):toContain("LongThinBar")
		end)

		t:it("exposes probeOk and flags an empty set", function()
			expect(Audit.probeOk):toBe(true)
			expect(Audit.emptyIsFailure):toBe(true)
			expect(#Audit.floaters({})):toBe(0)
			expect(#Audit.cubeShrubs({})):toBe(0)
			expect(#Audit.sizeSanity({})):toBe(0)
		end)

		t:it("counts invalid descriptors as failures, never skips", function()
			local parts = {
				good[1],
				{ name = "Broken", size = { 2 }, position = { 0, 0, 0 } },
				{ name = "NoPosition", size = { 2, 2, 2 } },
			}
			expect(Audit.floaters(parts)):toContain("Broken")
			expect(Audit.floaters(parts)):toContain("NoPosition")
			expect(Audit.cubeShrubs(parts)):toContain("Broken")
			expect(Audit.sizeSanity(parts)):toContain("Broken")
		end)

		t:it("honours the documented float and size exemptions", function()
			local exempt = {
				{ name = "RoofBase", shape = "Ball", size = { 2, 2, 2 }, position = { 0, 0, 0 } },
				{ name = "ridge_cap", size = { 2, 2, 2 }, position = { 50, 0, 0 } },
				{ name = "road_warning_sign", kind = "road", size = { 20, 0.4, 0.4 }, position = { 0, 0, 50 } },
			}
			expect(Audit.floaters(exempt)):toEqual({})
			expect(Audit.sizeSanity(exempt)):toEqual({})
		end)

		t:it("is deterministic across fresh requires", function()
			local fresh = Env.new():require("shared/VisualRiskAudit")
			local parts = Fixture.parts()
			expect(fresh.probeOk):toBe(true)
			expect(serialize(fresh.floaters(parts))):toBe(serialize(Audit.floaters(parts)))
			expect(serialize(fresh.cubeShrubs(parts))):toBe(serialize(Audit.cubeShrubs(parts)))
			expect(serialize(fresh.sizeSanity(parts))):toBe(serialize(Audit.sizeSanity(parts)))
		end)
	end)
end
