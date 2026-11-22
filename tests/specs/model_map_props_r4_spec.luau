--!nocheck
-- WORK_QUEUE round 4 item 31, props lane: static audit of the pure "props_r4" ID map, the
-- seven completed Open Cloud uploads, the exact licence/attribution chain and the SERVER-ONLY
-- adapter. No Studio claim and no visual verdict here.

local fs = require("@lune/fs")

local FAMILY_ID = "props_r4"
local manifestPath = "docs/v2/visual/art/models_r4/props/upload_manifest.json"
local reportPath = "docs/v2/visual/art/models_r4/props/prepare_report.json"
local sourcesPath = "docs/v2/visual/art/models_r4/props/SOURCE_LICENSES.md"
local handoffPath = "docs/v2/visual/art/models_r4/props/HANDOFF.md"
local adapterPath = "src/server/World/LookDevModelsPropsR4.luau"

-- IDs and attribution strings are from the completed operations / recorded source pages.
-- The map, manifest and report are all checked against these values; nothing is invented.
local EXPECTED = {
	gerobak = {
		id = 119426685469058,
		title = "Street Vendor Cart",
		author = "Alan Zimmerman",
		licenceKind = "CC BY 3.0",
		licenceUrl = "https://creativecommons.org/licenses/by/3.0/",
		page = "https://poly.pizza/m/f_LuAcP2_Yh",
		attribution = [["Street Vendor Cart" by Alan Zimmerman — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/f_LuAcP2_Yh]],
	},
	sumur = {
		id = 95025959179405,
		title = "Well",
		author = "Jarlan Perez",
		licenceKind = "CC BY 3.0",
		licenceUrl = "https://creativecommons.org/licenses/by/3.0/",
		page = "https://poly.pizza/m/1lK9mD0zDZw",
		attribution = [["Well" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/1lK9mD0zDZw]],
	},
	lapak = {
		id = 115924626989907,
		title = "Small stand with Wheels",
		author = "Peter Simcoe",
		licenceKind = "CC BY 3.0",
		licenceUrl = "https://creativecommons.org/licenses/by/3.0/",
		page = "https://poly.pizza/m/bwgNq3z2SQs",
		attribution = [["Small stand with Wheels" by Peter Simcoe — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/bwgNq3z2SQs]],
	},
	pagar_bambu = {
		id = 103341007913673,
		title = "Bamboo Fence Panel",
		author = "Jarlan Perez",
		licenceKind = "CC BY 3.0",
		licenceUrl = "https://creativecommons.org/licenses/by/3.0/",
		page = "https://poly.pizza/m/dVwByrifEmj",
		attribution = [["Bamboo Fence Panel" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/dVwByrifEmj]],
	},
	alat_tani = {
		id = 109848917287023,
		title = "Wooden Axe",
		author = "Ulan Cabanilla",
		licenceKind = "CC0",
		licenceUrl = "https://polyhaven.com/license",
		page = "https://polyhaven.com/a/wooden_axe",
		attribution = [["Wooden Axe" by Ulan Cabanilla — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/wooden_axe]],
	},
	karung = {
		id = 87487192428396,
		title = "Cement Bag",
		author = "PierreB3D",
		licenceKind = "CC0",
		licenceUrl = "https://polyhaven.com/license",
		page = "https://polyhaven.com/a/cement_bag",
		attribution = [["Cement Bag" by PierreB3D — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/cement_bag]],
	},
	jemuran = {
		id = 138444489439223,
		title = "Clothesline (light, 1K PBR)",
		author = "Grab3D",
		licenceKind = "CC0",
		licenceUrl = "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
		page = "https://grab3d.com/models/props/clothesline/",
		attribution = [["Clothesline" by Grab3D — CC0 1.0 Universal, no attribution required (https://creativecommons.org/publicdomain/zero/1.0/legalcode), source https://grab3d.com/models/props/clothesline/, licence text https://grab3d.com/dl/clothesline/LICENSE.txt]],
	},
}

-- Split a JSON-ish file into object chunks without a JSON dependency; every row in both files is
-- a flat object, so the nested arrays in prepare_report.json cannot contain braces.
local function objects(raw: string)
	return string.gmatch(raw, "%b{}")
end

local function field(chunk: string, key: string): string?
	return string.match(chunk, '"' .. key .. '"%s*:%s*"([^"]+)"')
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local ModelMapPropsR4 = env:require("shared/ModelMapPropsR4")
	local family = ModelMapPropsR4.families[FAMILY_ID]
	local adapter = fs.readFile(adapterPath)
	local manifest = fs.readFile(manifestPath)
	local report = fs.readFile(reportPath)
	local sources = fs.readFile(sourcesPath)
	local handoff = fs.readFile(handoffPath)

	t:describe("ModelMapPropsR4 real IDs", function()
		t:it("has seven unique numeric IDs matching the completed ROBLOX_API_KEY uploads", function()
			local rows = {}
			local uploadRoutes, slotRows = 0, 0
			for chunk in objects(manifest) do
				local slot = field(chunk, "slot")
				local id = field(chunk, "asset_id")
				local route = field(chunk, "upload_route")
				if route == "ROBLOX_API_KEY" then
					uploadRoutes += 1
				end
				if slot then
					slotRows += 1
					rows[slot] = tonumber(id)
				end
			end
			expect(uploadRoutes):toBe(7)
			expect(slotRows):toBe(7)

			local seen = {}
			local count = 0
			for slot, id in pairs(family.ids) do
				count += 1
				expect(type(slot)):toBe("string")
				expect(EXPECTED[slot] ~= nil):toBe(true)
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(id):toBe(EXPECTED[slot].id)
				expect(rows[slot]):toBe(id)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(7)
			expect(ModelMapPropsR4.count()):toBe(7)
			expect(ModelMapPropsR4.idsFor(FAMILY_ID)):toBe(family.ids)
			expect(ModelMapPropsR4.idsFor("not_a_family")):toBe(nil)

			local families = ModelMapPropsR4.familyIds()
			expect(#families):toBe(1)
			expect(families[1]):toBe(FAMILY_ID)
			expect(family.id):toBe(FAMILY_ID)
			expect(type(family.title)):toBe("string")
		end)

		t:it("has seven ordered slots with targetHeight, rotX and matching IDs", function()
			expect(#family.slots):toBe(7)
			local listed = {}
			for _, slot in ipairs(family.slots) do
				expect(type(slot.slot)):toBe("string")
				expect(EXPECTED[slot.slot] ~= nil):toBe(true)
				expect(listed[slot.slot]):toBe(nil)
				listed[slot.slot] = true
				expect(type(family.ids[slot.slot])):toBe("number")
				expect(type(slot.targetHeight)):toBe("number")
				expect(slot.targetHeight > 0 and slot.targetHeight == slot.targetHeight):toBe(true)
				expect(type(slot.ry)):toBe("number")
				expect(type(slot.rotX)):toBe("number")
				expect(slot.rotX):toBe(0) -- every source in this batch is Y-up
			end
			expect(family.slots[1].slot):toBe("gerobak")
			expect(family.slots[1].targetHeight):toBe(6) -- WORK_QUEUE gerobak target
			for slot in pairs(family.ids) do
				expect(listed[slot]):toBe(true)
			end
		end)
	end)

	t:describe("props_r4 licence and attribution chain", function()
		t:it("has a verified textured source row and exact attribution for all seven slots", function()
			local rows = {}
			for chunk in objects(report) do
				local slot = field(chunk, "slot")
				if slot then
					rows[slot] = chunk
				end
			end

			local checked = 0
			for slot, info in pairs(EXPECTED) do
				local chunk = rows[slot]
				expect(chunk ~= nil):toBe(true)
				local licence = field(chunk, "licence")
				local licenceUrl = field(chunk, "licence_url")
				local page = field(chunk, "page")
				local title = field(chunk, "title")
				local author = field(chunk, "author")
				local verified = string.match(chunk, '"verified_textured"%s*:%s*(%a+)')
				expect(licence ~= nil and string.find(licence, info.licenceKind, 1, true) ~= nil):toBe(true)
				expect(licenceUrl):toBe(info.licenceUrl)
				expect(page):toBe(info.page)
				expect(title):toBe(info.title)
				expect(author ~= nil and string.find(author, info.author, 1, true) ~= nil):toBe(true)
				expect(verified):toBe("true")
				expect(string.find(sources, info.attribution, 1, true) ~= nil):toBe(true)
				expect(string.find(sources, info.licenceUrl, 1, true) ~= nil):toBe(true)
				expect(string.find(sources, info.page, 1, true) ~= nil):toBe(true)
				checked += 1
			end
			expect(checked):toBe(7)
			expect(string.find(sources, "No designer builds needed", 1, true) ~= nil):toBe(true)
			expect(string.find(handoff, "No designer builds needed", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("LookDevModelsPropsR4 server adapter", function()
		t:it("registers props_r4 and embeds no asset ID literals", function()
			expect(string.find(adapter, 'LookDev.register("props_r4"', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("guards missing IDs, loads through InsertService and restores its folder", function()
			expect(string.find(adapter, 'service("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "local id = familyMap.ids[slot.slot]", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'if type(id) ~= "number"', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "InsertService:LoadAsset(id)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "restore = function()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "warn(", 1, true) ~= nil):toBe(true)
		end)

		t:it("orients, scales, anchors and disables collision on every staged model", function()
			expect(string.find(adapter, "CFrame.Angles(slot.rotX or 0, slot.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "model:ScaleTo(slot.targetHeight / bodySizeY)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "descendant.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "descendant.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "pcall(function()", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("props_r4 staging is on real MapSpec ground", function()
		t:it("keeps camera and all seven slots inside the 800x800 playable footprint", function()
			local MapSpec = env:require("server/World/MapSpec")
			local half = MapSpec.TERRAIN_HALF
			local function insideXZ(x, z)
				return math.abs(x) <= half and math.abs(z) <= half
			end

			expect(ModelMapPropsR4.groundY):toBe(MapSpec.GROUND_Y)
			expect(insideXZ(ModelMapPropsR4.staging.x, ModelMapPropsR4.staging.z)):toBe(true)

			local camera = ModelMapPropsR4.camera
			expect(insideXZ(camera.position.x, camera.position.z)):toBe(true)
			expect(insideXZ(camera.target.x, camera.target.z)):toBe(true)
			expect(camera.position.y > MapSpec.GROUND_Y):toBe(true)
			expect(camera.target.y > MapSpec.GROUND_Y):toBe(true)
			expect(camera.position.y > camera.target.y):toBe(true)

			for _, slot in ipairs(family.slots) do
				expect(insideXZ(slot.x, slot.z)):toBe(true)
			end
		end)
	end)
end
