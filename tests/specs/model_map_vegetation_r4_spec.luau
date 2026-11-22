--!nocheck
-- WORK_QUEUE round 4 item 31: real textured vegetation_r4 Model IDs, real-terrain staging and
-- SERVER adapter shape. Static coverage only: no Studio claim and no visual verdict here.
-- Main session owns central registry/CANDIDATES/ASSET_MANIFEST/tests/run.luau wiring.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local ModelMapVegetationR4 = env:require("shared/ModelMapVegetationR4")
	local MapSpec = env:require("server/World/MapSpec")
	local adapterPath = "src/server/World/LookDevModelsVegetationR4.luau"
	local manifestPath = "docs/v2/visual/art/models_r4/vegetation/upload_manifest.json"
	local sourcesPath = "docs/v2/visual/art/models_r4/vegetation/sources.json"
	local family = ModelMapVegetationR4.families.vegetation_r4
	local heightRange = { kelapa = { 25, 35 }, pisang = { 10, 14 }, bambu = { 18, 25 } }

	t:describe("ModelMapVegetationR4 real IDs", function()
		t:it("has five unique numeric real-ID-shaped values", function()
			local seen = {}
			local count = 0
			for slot, id in pairs(family.ids) do
				count += 1
				expect(type(slot)):toBe("string")
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(5)
			expect(ModelMapVegetationR4.count()):toBe(5)
		end)

		t:it("registers one vegetation_r4 family with five slots and matching ids", function()
			local families = ModelMapVegetationR4.familyIds()
			expect(#families):toBe(1)
			expect(families[1]):toBe("vegetation_r4")
			expect(family.id):toBe("vegetation_r4")
			expect(type(family.title)):toBe("string")
			expect(#family.slots):toBe(5)
			local listed = {}
			for _, slot in ipairs(family.slots) do
				expect(type(slot.slot)):toBe("string")
				expect(listed[slot.slot]):toBe(nil)
				listed[slot.slot] = true
				expect(type(family.ids[slot.slot])):toBe("number")
			end
			local idCount = 0
			for key in pairs(family.ids) do
				idCount += 1
				expect(listed[key]):toBe(true)
			end
			expect(idCount):toBe(5)
			expect(ModelMapVegetationR4.idsFor("vegetation_r4")):toBe(family.ids)
			expect(ModelMapVegetationR4.idsFor("not_a_family")):toBe(nil)
		end)

		t:it("uses the brief target heights and explicit Y-up rotX", function()
			local heights = {}
			for _, slot in ipairs(family.slots) do
				heights[slot.slot] = slot.targetHeight
				expect(type(slot.targetHeight)):toBe("number")
				expect(type(slot.rotX)):toBe("number")
				-- All five downloaded GLBs were measured Y-up; no Z-up rotation is needed.
				expect(slot.rotX):toBe(0)
				expect(type(slot.ry)):toBe("number")
				local range = heightRange[slot.slot]
				if range then
					expect(slot.targetHeight >= range[1] and slot.targetHeight <= range[2]):toBe(true)
				end
			end
			expect(heights.kelapa):toBe(30)
			expect(heights.pisang):toBe(12)
			expect(heights.bambu):toBe(21)
			expect(heights.mangga):toBe(22)
			expect(heights.shrubs):toBe(3)
		end)
	end)

	t:describe("vegetation_r4 real-terrain review camera", function()
		t:it("stages slots on the real MapSpec lapangan and keeps the camera in the ground footprint", function()
			expect(family.camera.footprint):toBe("MapSpec.LAPANGAN")
			local lap = MapSpec.LAPANGAN
			for i, slot in ipairs(family.slots) do
				expect(math.abs(slot.x - lap.x) <= lap.width / 2):toBe(true)
				expect(math.abs(slot.z - lap.z) <= lap.depth / 2):toBe(true)
				for j = i + 1, #family.slots do
					local other = family.slots[j]
					local dx, dz = slot.x - other.x, slot.z - other.z
					expect(math.sqrt(dx * dx + dz * dz) >= 12):toBe(true)
				end
			end
			local p, target = family.camera.position, family.camera.target
			expect(#p):toBe(3)
			expect(#target):toBe(3)
			for _, point in { p, target } do
				expect(math.abs(point[1]) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(point[3]) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(point[2] >= MapSpec.GROUND_Y):toBe(true)
			end
			expect(math.abs(target[1] - lap.x) <= lap.width / 2):toBe(true)
			expect(math.abs(target[3] - lap.z) <= lap.depth / 2):toBe(true)
		end)
	end)

	t:describe("vegetation_r4 provenance and licence", function()
		t:it("upload manifest has five real ROBLOX_API_KEY rows matching the mapped slots", function()
			local raw = fs.readFile(manifestPath)
			expect(#raw > 1000):toBe(true)
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, slots = string.gsub(raw, '"slot":', "")
			expect(routes):toBe(5)
			expect(slots):toBe(5)
			local rows = {}
			for slot, id in string.gmatch(raw, '"slot":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"') do
				rows[slot] = tonumber(id)
			end
			for slot, id in pairs(family.ids) do
				expect(rows[slot]):toBe(id)
			end
		end)

		t:it("records exact CC BY 3.0 attribution and bans QAL/NC/ND/standard sources", function()
			local raw = fs.readFile(manifestPath)
			local _, by3 = string.gsub(raw, "CC BY 3.0", "")
			local _, links = string.gsub(raw, "https://creativecommons.org/licenses/by/3.0/", "")
			local _, attributions = string.gsub(raw, '"attribution":', "")
			expect(by3):toBe(5 * 2) -- licence field plus attribution string on each row
			expect(links):toBe(5)
			expect(attributions):toBe(5)
			local lower = string.lower(raw)
			for _, banned in
				{ "quaternius", "qal", "free standard", "creator store", "by-nc", "by-nd", "all rights reserved" }
			do
				expect(string.find(lower, banned, 1, true) == nil):toBe(true)
			end
			for _, slot in ipairs({ "kelapa", "pisang", "bambu", "mangga", "shrubs" }) do
				local pattern = '"slot": "' .. slot .. '".-"attribution": "(.-)",'
				local attribution = string.match(raw, pattern)
				expect(attribution ~= nil):toBe(true)
				expect(string.find(attribution, "Poly by Google", 1, true) ~= nil):toBe(true)
				expect(string.find(attribution, "CC BY 3.0", 1, true) ~= nil):toBe(true)
				expect(string.find(attribution, "https://poly.pizza/m/", 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("source manifest proves every staged GLB is textured", function()
			local raw = fs.readFile(sourcesPath)
			local _, textured = string.gsub(raw, '"textured": true', "")
			local _, pages = string.gsub(raw, '"page": "https://poly.pizza/m/', "")
			expect(textured):toBe(5)
			expect(pages):toBe(5)
			expect(string.find(raw, '"vertex_color": true', 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("vegetation_r4 designer-build gaps and no-ID guard", function()
		t:it("keeps unsourced plants out of the staged id map", function()
			local gaps = ModelMapVegetationR4.designerBuilds
			expect(#gaps):toBe(4)
			local names = {}
			for _, gap in ipairs(gaps) do
				expect(gap.id):toBe(nil) -- no invented placeholder ID
				expect(type(gap.slot)):toBe("string")
				expect(type(gap.targetHeight)):toBe("number")
				expect(type(gap.reason)):toBe("string")
				expect(#gap.reason > 20):toBe(true)
				expect(#gap.references > 0):toBe(true)
				expect(family.ids[gap.slot]):toBe(nil)
				names[gap.slot] = true
				for _, slot in ipairs(family.slots) do
					expect(slot.slot ~= gap.slot):toBe(true)
				end
			end
			expect(names.mangga_true):toBe(true)
			expect(names.padi_bibit):toBe(true)
			expect(names.padi_tumbuh):toBe(true)
			expect(names.padi_siap):toBe(true)
		end)

		t:it("skips ID-less slots before LoadAsset and embeds no asset IDs in the applier", function()
			local adapter = fs.readFile(adapterPath)
			local guardAt = string.find(adapter, 'type(modelId) ~= "number"', 1, true)
			local loadAt = string.find(adapter, "return InsertService:LoadAsset(modelId)", 1, true)
			expect(guardAt ~= nil):toBe(true)
			expect(loadAt ~= nil):toBe(true)
			expect(guardAt < loadAt):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("registers one server-only applier that anchors, scales and restores", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'LookDev.register("vegetation_r4"', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'GetService("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "return InsertService:LoadAsset(modelId)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "model:ScaleTo(slot.targetHeight / bodyY)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "part.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CFrame.Angles(slot.rotX or 0, slot.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "restore = function()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "pcall(", 1, true) ~= nil):toBe(true)
		end)
	end)
end
