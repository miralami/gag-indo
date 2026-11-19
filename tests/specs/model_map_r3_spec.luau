--!nocheck
-- WORK_QUEUE round 3 item 23: real round-3 Model ID map, corner staging and SERVER adapter
-- shape for the "buildings_r3" / "vegetation_r3" / "props_r3" / "npcs_r3" LookDev candidates.
-- Static coverage only: no Studio claim and no visual verdict here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local ModelMapR3 = env:require("shared/ModelMapR3")
	local adapterPath = "src/server/World/LookDevModelsR3.luau"
	local manifestPath = "docs/v2/visual/art/models_r3/upload_manifest.json"
	local order = { "buildings_r3", "vegetation_r3", "props_r3", "npcs_r3" }
	local slotCounts = { buildings_r3 = 3, vegetation_r3 = 6, props_r3 = 5, npcs_r3 = 6 }

	t:describe("ModelMapR3 candidate IDs", function()
		t:it("has 20 unique numeric real-ID-shaped values", function()
			local seen = {}
			local count = 0
			for _, familyId in ipairs(order) do
				for slot, id in pairs(ModelMapR3.families[familyId].ids) do
					count += 1
					expect(type(slot)):toBe("string")
					expect(type(id)):toBe("number")
					expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
					expect(seen[id]):toBe(nil)
					seen[id] = true
				end
			end
			expect(count):toBe(20)
			expect(ModelMapR3.count()):toBe(20)
		end)

		t:it("has four families with 3/6/5/6 ordered slots and matching ids", function()
			local families = ModelMapR3.familyIds()
			expect(#families):toBe(4)
			for i, familyId in ipairs(order) do
				expect(families[i]):toBe(familyId)
				local family = ModelMapR3.families[familyId]
				expect(type(family.title)):toBe("string")
				expect(family.id):toBe(familyId)
				expect(#family.slots):toBe(slotCounts[familyId])
				local listed = {}
				for _, slot in ipairs(family.slots) do
					expect(type(slot.slot)):toBe("string")
					expect(listed[slot.slot]):toBe(nil)
					listed[slot.slot] = true
					expect(type(family.ids[slot.slot])):toBe("number")
				end
				expect(ModelMapR3.idsFor(familyId)):toBe(family.ids)
				local idCount = 0
				for key in pairs(family.ids) do
					idCount += 1
					expect(listed[key]):toBe(true)
				end
				expect(idCount):toBe(slotCounts[familyId])
			end
			expect(ModelMapR3.idsFor("not_a_family")):toBe(nil)
		end)

		t:it("keeps every slot inside the 60x60 corner and at least 4 studs apart", function()
			for _, familyId in ipairs(order) do
				local family = ModelMapR3.families[familyId]
				for i, slot in ipairs(family.slots) do
					expect(slot.x >= 470 and slot.x <= 530):toBe(true)
					expect(slot.z >= 470 and slot.z <= 530):toBe(true)
					expect(type(slot.ry)):toBe("number")
					for j = i + 1, #family.slots do
						local other = family.slots[j]
						local dx, dz = slot.x - other.x, slot.z - other.z
						expect(math.sqrt(dx * dx + dz * dz) >= 4):toBe(true)
					end
				end
			end
		end)

		t:it("upload manifest has 20 ROBLOX_API_KEY rows matching the mapped slots", function()
			local raw = fs.readFile(manifestPath)
			expect(#raw > 1000):toBe(true)
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, slots = string.gsub(raw, '"slot":', "")
			expect(routes):toBe(20)
			expect(slots):toBe(20)

			local rows = {}
			for slot, id in string.gmatch(raw, '"slot":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"') do
				rows[slot] = tonumber(id)
			end
			local matched = 0
			for _, familyId in ipairs(order) do
				for slot, id in pairs(ModelMapR3.families[familyId].ids) do
					matched += 1
					expect(rows[familyId .. "/" .. slot]):toBe(id)
				end
			end
			expect(matched):toBe(20)
		end)
	end)

	t:describe("LookDevModelsR3 server adapter", function()
		t:it("registers all four literal family ids and embeds no asset IDs", function()
			local adapter = fs.readFile(adapterPath)
			for _, familyId in ipairs(order) do
				expect(string.find(adapter, 'LookDev.register("' .. familyId .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("loads through InsertService on the server and restores its folder", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'GetService("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "InsertService:LoadAsset", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "warn(", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "restore = function()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
		end)
	end)
end
