--!nocheck
-- WORK_QUEUE round 4 item 31, npcs_r4 lane: five real page-verified textured
-- model IDs, staging on the real MapSpec plaza, and the SERVER adapter shape.
-- Static coverage only: no Studio claim and no visual verdict here.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local ModelMapNpcsR4 = env:require("shared/ModelMapNpcsR4")
	local MapSpec = env:require("server/World/MapSpec")
	local adapterPath = "src/server/World/LookDevModelsNpcsR4.luau"
	local manifestPath = "docs/v2/visual/art/models_r4/npcs/upload_manifest.json"
	local sourcesPath = "docs/v2/visual/art/models_r4/npcs/sources.json"
	local slots = { "petani_caping", "pedagang", "petani_wanita", "tukang_peci", "polisi" }
	local family = ModelMapNpcsR4.families.npcs_r4
	local manifest = serde.decode("json", fs.readFile(manifestPath))
	local sources = serde.decode("json", fs.readFile(sourcesPath))

	t:describe("ModelMapNpcsR4 real IDs", function()
		t:it("has exactly five unique numeric real-ID-shaped values", function()
			local count, seen = 0, {}
			for slot, id in pairs(family.ids) do
				count += 1
				expect(table.find(slots, slot) ~= nil):toBe(true)
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(5)
			expect(ModelMapNpcsR4.count()):toBe(5)
			expect(ModelMapNpcsR4.familyIds()):toEqual({ "npcs_r4" })
			expect(ModelMapNpcsR4.idsFor("npcs_r4")):toBe(family.ids)
			expect(ModelMapNpcsR4.idsFor("not_a_family")):toBe(nil)
		end)

		t:it("upload manifest has five completed ROBLOX_API_KEY Model rows matching the map", function()
			local raw = fs.readFile(manifestPath)
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, models = string.gsub(raw, '"asset_type": "Model"', "")
			expect(routes):toBe(5)
			expect(models):toBe(5)
			expect(#manifest):toBe(5)
			local bySlot = {}
			for _, row in ipairs(manifest) do
				expect(row.family):toBe("npcs_r4")
				expect(row.slot:match("^npcs_r4/")):toBe("npcs_r4/")
				expect(bySlot[row.slot]):toBe(nil)
				bySlot[row.slot] = row
				expect(type(row.operation_id) == "string" and #row.operation_id > 0):toBe(true)
				expect(tonumber(row.asset_id)):toBe(family.ids[row.slot:sub(#"npcs_r4/" + 1)])
			end
			for _, slot in ipairs(slots) do
				expect(bySlot["npcs_r4/" .. slot] ~= nil):toBe(true)
			end
		end)
	end)

	t:describe("npcs_r4 licence and attribution", function()
		t:it("records verified CC0 / CC BY 3.0 sources with exact author, licence URL and page", function()
			expect(#sources):toBe(5)
			local seen = {}
			for _, row in ipairs(sources) do
				expect(table.find(slots, row.slot) ~= nil):toBe(true)
				expect(seen[row.slot]):toBe(nil)
				seen[row.slot] = true
				expect(type(row.author) == "string" and #row.author > 0):toBe(true)
				expect(row.author:lower()):toBe(row.author:lower():gsub("quaternius", ""))
				expect(row.licence == "CC0 1.0" or row.licence == "CC-BY 3.0"):toBe(true)
				expect(
					row.licence_url == "https://creativecommons.org/publicdomain/zero/1.0/"
						or row.licence_url == "https://creativecommons.org/licenses/by/3.0/"
				):toBe(true)
				expect(row.page:match("^https://poly.pizza/m/") ~= nil):toBe(true)
				expect(row.direct_url:match("^https://static.poly.pizza/.+%.glb$") ~= nil):toBe(true)
			end
		end)

		t:it("carries the exact CC BY attribution text into every upload row and bans bad licences", function()
			local raw = fs.readFile(manifestPath)
			for _, banned in ipairs({ "Quaternius", "NC", "ND", "Free Standard", "unknown" }) do
				if banned == "NC" or banned == "ND" then
					expect(string.find(raw, '"licence": "[^"]*' .. banned, 1, true) == nil):toBe(true)
				else
					expect(string.find(raw, banned, 1, true) == nil):toBe(true)
				end
			end
			local bySlot = {}
			for _, row in ipairs(sources) do
				bySlot[row.slot] = row
			end
			local attributed = 0
			for _, row in ipairs(manifest) do
				local slot = row.slot:sub(#"npcs_r4/" + 1)
				local source = bySlot[slot]
				expect(source ~= nil):toBe(true)
				expect(row.author):toBe(source.author)
				expect(row.licence):toBe(source.licence)
				expect(row.licence_url):toBe(source.licence_url)
				expect(row.source_page):toBe(source.page)
				expect(row.attribution):toBe(
					'"'
						.. source.title
						.. '" by '
						.. source.author
						.. " — "
						.. source.licence
						.. " ("
						.. source.licence_url
						.. "); source: "
						.. source.page
				)
				if source.licence == "CC-BY 3.0" then
					attributed += 1
				end
			end
			expect(attributed):toBe(3)
		end)
	end)

	t:describe("npcs_r4 staging, targetHeight and rotX", function()
		t:it("targets 5 studs on every slot with an 8-stud row on real plaza ground", function()
			expect(family.id):toBe("npcs_r4")
			expect(type(family.title) == "string" and #family.title > 0):toBe(true)
			expect(#family.slots):toBe(5)
			local listed = {}
			for _, slot in ipairs(family.slots) do
				expect(type(slot.slot) == "string" and #slot.slot > 0):toBe(true)
				expect(listed[slot.slot]):toBe(nil)
				listed[slot.slot] = true
				expect(type(family.ids[slot.slot])):toBe("number")
				expect(slot.targetHeight):toBe(5)
				expect(slot.y):toBe(MapSpec.GROUND_Y)
				expect(type(slot.ry)):toBe("number")
			end
			for _, slot in ipairs(family.slots) do
				for _, other in ipairs(family.slots) do
					if slot ~= other then
						local dx, dz = slot.x - other.x, slot.z - other.z
						expect(math.sqrt(dx * dx + dz * dz) >= 4):toBe(true)
					end
				end
			end
		end)

		t:it("uses rotX only for the Z-up source and applies it with ry in the adapter", function()
			local rotated = {}
			for _, slot in ipairs(family.slots) do
				if slot.rotX ~= nil then
					expect(slot.slot):toBe("petani_wanita")
					expect(slot.rotX):toBe(-math.pi / 2)
					rotated[#rotated + 1] = slot.slot
				end
			end
			expect(#rotated):toBe(1)
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, "slot.rotX or 0", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CFrame.Angles(slot.rotX or 0, slot.ry or 0, 0)", 1, true) ~= nil):toBe(true)
		end)

		t:it("saves a review camera inside the real MapSpec plaza and terrain footprint", function()
			local camera = family.camera
			expect(#camera.position):toBe(3)
			expect(#camera.lookAt):toBe(3)
			local halfX, halfZ = MapSpec.PLAZA.width / 2, MapSpec.PLAZA.depth / 2
			local points = { camera.position, camera.lookAt }
			for _, point in ipairs(points) do
				expect(point[1] >= -halfX and point[1] <= halfX):toBe(true)
				expect(point[3] >= -halfZ and point[3] <= halfZ):toBe(true)
				expect(math.abs(point[1]) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(point[3]) <= MapSpec.TERRAIN_HALF):toBe(true)
			end
			expect(camera.position[2] > MapSpec.GROUND_Y):toBe(true)
			expect(camera.position[1]):toBe(MapSpec.SPAWN.x)
			expect(camera.position[3]):toBe(MapSpec.SPAWN.z)
			for _, slot in ipairs(family.slots) do
				expect(slot.x >= -halfX and slot.x <= halfX):toBe(true)
				expect(slot.z >= -halfZ and slot.z <= halfZ):toBe(true)
			end
		end)
	end)

	t:describe("LookDevModelsNpcsR4 server adapter", function()
		t:it("registers the literal npcs_r4 id and embeds no asset IDs", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'LookDev.register("npcs_r4"', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(string.find(adapter, "rbxassetid://", 1, true) == nil):toBe(true)
			expect(string.find(adapter, "http", 1, true) == nil):toBe(true)
		end)

		t:it("loads through InsertService on the server with per-slot ID and scale guards", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'GetService("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "InsertService:LoadAsset", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, 'type(id) ~= "number" or id <= 0', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "no asset ID for", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "GetBoundingBox", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "model:ScaleTo(slot.targetHeight / bodySizeY)", 1, true) ~= nil):toBe(true)
		end)

		t:it("anchors every BasePart, disables collision and pcall-guards engine calls", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'instance:IsA("BasePart")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "instance.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "instance.CanCollide = false", 1, true) ~= nil):toBe(true)
			local _, pcalls = string.gsub(adapter, "pcall%(", "")
			expect(pcalls >= 8):toBe(true)
		end)

		t:it("saves and restores its folder and warns on partial placement", function()
			local adapter = fs.readFile(adapterPath)
			expect(string.find(adapter, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = nil", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "restore = restore", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "saved.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "warn(", 1, true) ~= nil):toBe(true)
		end)
	end)
end
