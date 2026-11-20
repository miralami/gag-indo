--!nocheck
-- WORK_QUEUE round 4 item 31: real textured `buildings_r4` IDs, CC0 provenance, target heights,
-- SERVER applier shape and a saved camera on real MapSpec terrain. Static coverage only: no
-- Studio claim and no visual verdict here.

local fs = require("@lune/fs")

local ROOT = "docs/v2/visual/art/models_r4/buildings/"
local ADAPTER = "src/server/World/LookDevModelsBuildingsR4.luau"
local UPLOADS = ROOT .. "upload_manifest.json"
local SOURCES = ROOT .. "source_verification.json"
export type Vec3 = { x: number, y: number, z: number }

return function(t, Env)
	local expect = t.expect
	local env, MapSpec, ModelMapBuildingsR4, family

	local function slotBlock(report: string, name: string): string
		local start = string.find(report, '"slot": "' .. name .. '"', 1, true)
		expect(start ~= nil)
		local finish = string.find(report, '"slot":', start + 1, true)
		return string.sub(report, start, finish and finish - 1 or #report)
	end

	local function setup()
		env = Env.new()
		MapSpec = env:require("server/World/MapSpec")
		ModelMapBuildingsR4 = env:require("shared/ModelMapBuildingsR4")
		family = ModelMapBuildingsR4.families.buildings_r4
	end

	t:describe("ModelMapBuildingsR4 data", function()
		t:beforeEach(setup)
		t:it("registers only buildings_r4 with four matching real IDs and slots", function()
			expect(ModelMapBuildingsR4.familyId):toBe("buildings_r4")
			expect(ModelMapBuildingsR4.familyIds()):toEqual({ "buildings_r4" })
			expect(ModelMapBuildingsR4.count()):toBe(4)
			expect(family.id):toBe("buildings_r4")
			expect(type(family.title)):toBe("string")
			expect(#family.slots):toBe(4)
			local seen = {}
			for _, slot in ipairs(family.slots) do
				expect(seen[slot.slot]):toBe(nil)
				seen[slot.slot] = true
				expect(type(family.ids[slot.slot])):toBe("number")
			end
			local count = 0
			for key, id in pairs(family.ids) do
				count += 1
				expect(seen[key]):toBe(true)
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
			end
			expect(count):toBe(4)
			expect(ModelMapBuildingsR4.idsFor("buildings_r4")):toBe(family.ids)
			expect(ModelMapBuildingsR4.idsFor("nope")):toBe(nil)
			expect(#ModelMapBuildingsR4.slotsFor("buildings_r4")):toBe(4)
			expect(#ModelMapBuildingsR4.slotsFor("nope")):toBe(0)
		end)

		t:it("keeps target heights at 22/6/10/9 and the stilt-house door >=7 studs", function()
			local heights = { rumah = 22, kandang = 6, gudang = 10, warung = 9 }
			for _, slot in ipairs(family.slots) do
				expect(slot.targetHeight):toBe(heights[slot.slot])
				expect(slot.targetHeight > 0):toBe(true)
				expect(type(slot.ry)):toBe("number")
				expect(slot.rotX == nil or type(slot.rotX) == "number"):toBe(true)
			end

			local report = fs.readFile(ROOT .. "decimation_report.json")
			local rumah = slotBlock(report, "rumah")
			local door = tonumber(rumah:match('"door_height"%s*:%s*([%d%.]+)'))
			local modelHeight = tonumber(rumah:match('"bounds_max"%s*:%s*%[%s*[%-%d%.]+,%s*([%-%d%.]+)'))
			expect(door ~= nil and modelHeight ~= nil):toBe(true)
			expect(heights.rumah >= 18 and heights.rumah <= 24):toBe(true)
			expect(door * heights.rumah / modelHeight >= 7):toBe(true)
		end)

		t:it("stages every slot on real MapSpec terrain inside the playable square", function()
			local staging = ModelMapBuildingsR4.staging
			expect(staging.groundY):toBe(MapSpec.GROUND_Y)
			expect(staging.origin.x):toBe(MapSpec.SPAWN.x)
			expect(staging.origin.z):toBe(MapSpec.SPAWN.z - 8)
			for i, slot in ipairs(family.slots) do
				expect(math.abs(slot.x) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(slot.z) <= MapSpec.TERRAIN_HALF):toBe(true)
				for j = i + 1, #family.slots do
					local other = family.slots[j]
					local dx, dz = slot.x - other.x, slot.z - other.z
					expect(math.sqrt(dx * dx + dz * dz) >= 4):toBe(true)
				end
			end
		end)

		t:it("saves a review camera inside the real ground footprint, derived from SPAWN", function()
			local camera = ModelMapBuildingsR4.camera
			expect(type(camera.derivedFrom)):toBe("string")
			expect(type(camera.position.derivedFrom)):toBe("nil")
			for _, point in ipairs({ camera.position, camera.lookAt }) do
				expect(type(point.x)):toBe("number")
				expect(type(point.y)):toBe("number")
				expect(type(point.z)):toBe("number")
				expect(math.abs(point.x) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(math.abs(point.z) <= MapSpec.TERRAIN_HALF):toBe(true)
				expect(point.y > MapSpec.GROUND_Y):toBe(true)
			end
			expect(camera.position.x):toBe(MapSpec.SPAWN.x)
			expect(camera.lookAt.x):toBe(MapSpec.SPAWN.x)
			expect(camera.lookAt.z):toBe(MapSpec.SPAWN.z - 8)
			expect(camera.position.z):toBe(camera.lookAt.z + 64)
			expect(camera.position.y > camera.lookAt.y):toBe(true)
		end)
	end)

	t:describe("buildings_r4 provenance", function()
		t:beforeEach(setup)
		t:it("records CC0, author and source URL for every uploaded slot", function()
			local raw = fs.readFile(UPLOADS)
			local sources = fs.readFile(SOURCES)
			local licences = fs.readFile(ROOT .. "SOURCE_LICENCES.md")
			expect(#raw > 500):toBe(true)
			expect(string.find(sources, "CC0 1.0 Universal", 1, true) ~= nil):toBe(true)
			expect(string.find(sources, "No attribution, no account, no fees", 1, true) ~= nil):toBe(true)
			expect(string.find(licences, "CC0 1.0 Universal", 1, true) ~= nil):toBe(true)
			expect(string.find(licences, "Attribution string: not required", 1, true) ~= nil):toBe(true)
			for _, banned in ipairs({ "Quaternius", "Creator Store", "Attribution-NoDerivatives", "Free Standard" }) do
				expect(string.find(raw, banned, 1, true)):toBe(nil)
				expect(string.find(sources, banned, 1, true)):toBe(nil)
			end
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			expect(routes):toBe(4)
			local rows = {}
			for slot, id in string.gmatch(raw, '"slot"%s*:%s*"(buildings_r4/[^"]+)".-"asset_id"%s*:%s*"([^"]+)"') do
				rows[slot] = tonumber(id)
			end
			for _, slot in ipairs(family.slots) do
				local key = "buildings_r4/" .. slot.slot
				expect(rows[key]):toBe(family.ids[slot.slot])
			end
			for slot in pairs(rows) do
				expect(family.ids[string.match(slot, "buildings_r4/(.+)$")] ~= nil):toBe(true)
			end
		end)

		t:it("decimated every source below the landmark triangle budget and kept textures", function()
			local report = fs.readFile(ROOT .. "decimation_report.json")
			local count = 0
			for _, slot in ipairs(family.slots) do
				local block = slotBlock(report, slot.slot)
				local tris = tonumber(block:match('"final_triangles"%s*:%s*(%d+)'))
				local images = tonumber(block:match('"images"%s*:%s*(%d+)'))
				local textured = tonumber(block:match('"textured_materials"%s*:%s*(%d+)'))
				expect(tris ~= nil and images ~= nil and textured ~= nil):toBe(true)
				expect(tris <= 8000):toBe(true)
				expect(images >= 1):toBe(true)
				expect(textured >= 1):toBe(true)
				count += 1
			end
			expect(count):toBe(4)
		end)
	end)

	t:describe("LookDevModelsBuildingsR4 server adapter", function()
		t:beforeEach(setup)
		t:it("registers the literal family id and embeds no asset IDs", function()
			local adapter = fs.readFile(ADAPTER)
			expect(string.find(adapter, 'LookDev.register("buildings_r4"', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("loads on the server, anchors, disables collision and scales to targetHeight", function()
			local adapter = fs.readFile(ADAPTER)
			expect(string.find(adapter, 'GetService("InsertService")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "InsertService:LoadAsset", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "Anchored = true", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "ScaleTo(", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "slot.targetHeight", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CFrame.Angles(0, slot.ry, 0)", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "CFrame.Angles(slot.rotX or 0, 0, 0)", 1, true) ~= nil):toBe(true)
			local _, calls = string.gsub(adapter, "pcall", "")
			expect(calls >= 10):toBe(true)
		end)

		t:it("saves and restores the previous folder without throwing", function()
			local adapter = fs.readFile(ADAPTER)
			expect(string.find(adapter, 'Instance.new("Folder")', 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = nil", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "previous.Parent = Workspace", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "restore = function()", 1, true) ~= nil):toBe(true)
			expect(string.find(adapter, "saved[family] = nil", 1, true) ~= nil):toBe(true)
		end)
	end)
end
