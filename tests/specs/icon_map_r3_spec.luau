--!nocheck
-- WORK_QUEUE round 3 item 22 (icon half): the real r3 icon ID map for the OFF-BY-DEFAULT
-- "icons_r3" LookDev candidate. No visual verdict and no Studio claim here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env, IconMapR3

	t:describe("IconMapR3 candidate IDs", function()
		t:beforeEach(function()
			env = Env.new()
			IconMapR3 = env:require("shared/IconMapR3")
		end)

		t:it("has 27 unique real-ID-shaped values", function()
			local seen = {}
			local count = 0
			for key, id in IconMapR3.ids do
				count += 1
				expect(type(key)):toBe("string")
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(27)
		end)

		t:it("exports 27 ordered slots that all exist in ids", function()
			expect(#IconMapR3.slots):toBe(27)
			expect(IconMapR3.count()):toBe(27)
			local listed = {}
			for _, slot in ipairs(IconMapR3.slots) do
				expect(type(slot)):toBe("string")
				expect(listed[slot]):toBe(nil)
				listed[slot] = true
				expect(type(IconMapR3.ids[slot])):toBe("number")
			end
			local count = 0
			for key in IconMapR3.ids do
				count += 1
				expect(listed[key]):toBe(true)
			end
			expect(count):toBe(27)
		end)

		t:it("apply(on) writes ids and off restores captured originals", function()
			local visuals = { icons = {} }
			local originals = {}
			for i, slot in ipairs(IconMapR3.slots) do
				local original = if i % 3 == 0 then 0 elseif i % 3 == 1 then 900 + i else nil
				visuals.icons[slot] = { id = original, text = "?" }
				originals[slot] = original
			end

			expect(IconMapR3.usingCandidates()):toBe(false)
			IconMapR3.apply(visuals, true)
			expect(IconMapR3.usingCandidates()):toBe(true)
			for _, slot in ipairs(IconMapR3.slots) do
				expect(visuals.icons[slot].id):toBe(IconMapR3.ids[slot])
				expect(visuals.icons[slot].text):toBe("?")
			end

			-- A second enable must not re-capture the r3 ids as the "original" values.
			IconMapR3.apply(visuals, true)
			IconMapR3.apply(visuals, false)
			expect(IconMapR3.usingCandidates()):toBe(false)
			for _, slot in ipairs(IconMapR3.slots) do
				expect(visuals.icons[slot].id):toBe(originals[slot])
			end
		end)

		t:it("creates missing icon entries and restores their nil ids", function()
			local visuals = { icons = {} }
			IconMapR3.apply(visuals, true)
			for _, slot in ipairs(IconMapR3.slots) do
				expect(type(visuals.icons[slot])):toBe("table")
				expect(visuals.icons[slot].id):toBe(IconMapR3.ids[slot])
			end
			IconMapR3.apply(visuals, false)
			for _, slot in ipairs(IconMapR3.slots) do
				expect(visuals.icons[slot].id):toBe(nil)
			end
		end)

		t:it("rejects malformed visuals without toggling state", function()
			IconMapR3.apply(nil, true)
			expect(IconMapR3.usingCandidates()):toBe(false)
			IconMapR3.apply({}, true)
			expect(IconMapR3.usingCandidates()):toBe(false)
			IconMapR3.apply({ icons = "no" }, true)
			expect(IconMapR3.usingCandidates()):toBe(false)
		end)

		t:it("adapter registers literal icons_r3 and holds no asset ID literals", function()
			local adapter = fs.readFile("src/client/UI/LookDevIconsR3.luau")
			expect(
				string.find(adapter, 'LookDev.register("icons_r3", { apply = apply, restore = restore })', 1, true)
					~= nil
			):toBe(true)
			expect(string.find(adapter, "IconMapR3.apply(Visuals, true)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "IconMapR3.apply(Visuals, false)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)

		t:it("upload manifest has 27 ROBLOX_API_KEY rows matching the ids", function()
			local raw = fs.readFile("docs/v2/visual/art/icons/render_r3/upload_manifest.json")
			expect(#raw > 1000):toBe(true)
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, slotsInFile = string.gsub(raw, '"slot":', "")
			expect(routes):toBe(27)
			expect(slotsInFile):toBe(27)

			local rows = {}
			for slot, id in string.gmatch(raw, '"slot":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"') do
				rows[slot] = tonumber(id)
			end
			local count = 0
			for slot, id in rows do
				count += 1
				expect(type(slot)):toBe("string")
				expect(IconMapR3.ids[slot]):toBe(id)
			end
			expect(count):toBe(27)
		end)
	end)
end
