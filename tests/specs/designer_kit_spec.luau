--!nocheck
-- WORK_QUEUE item 49: designer kit (no spawn dressing). Source/data assertions only:
-- every id and height resolves from the existing source maps, the builder is Studio-only
-- and manually invoked, and the two advice docs carry the required lines. No Studio claim,
-- no screenshot, no visual verdict. Not registered in tests/run.luau; main session wires it.

local fs = require("@lune/fs")

local DATA = "src/shared/DesignerKitMap.luau"
local BUILDER = "src/server/World/DesignerKitBuilder.luau"
local KIT_DOC = "docs/v2/visual/DESIGNER_KIT.md"
local TERRAIN_DOC = "docs/v2/visual/TERRAIN_BRIEF.md"

local EXPECTED_NAMES = {
	"Pisang",
	"Mangga",
	"Bambu",
	"Jemuran",
	"Karung semen",
	"Gerobak",
	"Sumur",
	"Alat tani",
	"Rumah panggung",
	"Kandang ayam",
	"Gudang",
	"Warung",
	"Petani",
	"Pedagang",
	"Petani wanita",
	"Tukang peci",
	"Polisi",
}

local function hasLongId(text)
	return string.match(text, "%d%d%d%d%d%d%d%d%d%d%d%d") ~= nil
end

local function contains(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local map = env:require("shared/DesignerKitMap")
	local vegetation = env:require("shared/ModelMapVegetationR4")
	local props = env:require("shared/ModelMapPropsR4")
	local buildings = env:require("shared/ModelMapBuildingsR4")
	local npcs = env:require("shared/ModelMapNpcsR5")

	local dataSrc = fs.readFile(DATA)
	local builderSrc = fs.readFile(BUILDER)
	local kitDoc = fs.readFile(KIT_DOC)
	local terrainDoc = fs.readFile(TERRAIN_DOC)

	local sources = {
		ModelMapVegetationR4 = vegetation,
		ModelMapPropsR4 = props,
		ModelMapBuildingsR4 = buildings,
		ModelMapNpcsR5 = npcs,
	}

	local function slotFor(source, family, key)
		for _, slot in ipairs(source.families[family].slots) do
			if slot.slot == key then
				return slot
			end
		end
		return nil
	end

	t:describe("DesignerKitMap data", function()
		t:it("exposes one tidy folder in ServerStorage", function()
			expect(map.folderName):toBe("DesignerKit")
			expect(map.storage):toBe("ServerStorage")
			expect(type(map.storageNote)):toBe("string")
			expect(contains(map.storageNote, "nothing is dressed, saved or published")):toBe(true)
			expect(contains(dataSrc, 'folderName = "DesignerKit"')):toBe(true)
			expect(contains(dataSrc, 'storage = "ServerStorage"')):toBe(true)
		end)

		t:it("has exactly the 17 Indonesian-named kit items", function()
			expect(#map.items):toBe(#EXPECTED_NAMES)
			local seen = {}
			for _, item in ipairs(map.items) do
				expect(seen[item.name]):toBe(nil)
				seen[item.name] = true
				expect(type(item.name)):toBe("string")
				expect(type(item.source)):toBe("string")
				expect(type(item.note)):toBe("string")
			end
			for _, name in ipairs(EXPECTED_NAMES) do
				expect(seen[name]):toBe(true)
			end
		end)

		t:it("uses only the existing source maps, never kelapa or pine", function()
			for _, item in ipairs(map.items) do
				local mapName = string.match(item.source, "^(%w+)")
				expect(sources[mapName] ~= nil):toBe(true)
				local haystack = item.name .. " " .. item.source
				expect(contains(string.lower(haystack), "kelapa")):toBe(false)
				expect(contains(string.lower(haystack), "pine")):toBe(false)
				if item.id ~= nil then
					expect(item.id).never:toBe(vegetation.families.vegetation_r4.ids.kelapa)
				end
			end
		end)

		t:it("resolves every model id and height by requiring the source map", function()
			local modelCount = 0
			for _, item in ipairs(map.items) do
				local mapName, family, key = string.match(item.source, "^(%w+)%.families%.([%w_]+)%.ids%.([%w_]+)")
				if mapName then
					modelCount += 1
					local source = sources[mapName]
					expect(source ~= nil):toBe(true)
					expect(type(item.id)):toBe("number")
					expect(source.families[family].ids[key]):toBe(item.id)
					local slotKey = string.match(item.source, "slots%.([%w_]+)%.targetHeight")
					expect(slotKey):toBe(key)
					local slot = slotFor(source, family, slotKey)
					expect(slot ~= nil):toBe(true)
					expect(item.targetHeight):toBe(slot.targetHeight)
					expect(item.role):toBe(nil)
				end
			end
			expect(modelCount):toBe(12)
		end)

		t:it("resolves every villager by role body colours only", function()
			local roleCount = 0
			for _, item in ipairs(map.items) do
				local mapName, family, roleKey =
					string.match(item.source, "^(%w+)%.families%.([%w_]+)%.roles%.([%w_]+)")
				if mapName then
					roleCount += 1
					expect(mapName):toBe("ModelMapNpcsR5")
					expect(item.id):toBe(nil)
					expect(item.targetHeight):toBe(nil)
					expect(item.role):toBe(sources.ModelMapNpcsR5.families[family].roles[roleKey])
					expect(contains(item.source, "body colours only, R15 rig")):toBe(true)
				end
			end
			expect(roleCount):toBe(5)
		end)

		t:it("marks buildings temporary and states the item notes", function()
			local temporary = 0
			for _, item in ipairs(map.items) do
				expect(contains(item.note, "Anchored")):toBe(true)
				expect(contains(item.note, "base pivot at y=0")):toBe(true)
				expect(contains(item.note, "true to source scale")):toBe(true)
				if item.tier == "temporary" then
					temporary += 1
				end
			end
			expect(temporary):toBe(4)
		end)

		t:it("carries terrain advice only", function()
			expect(type(map.terrain)):toBe("table")
			expect(#map.terrain):toBe(5)
			local advice = table.concat(map.terrain, "\n")
			expect(contains(advice, "Sawah: 1-2 studs lower than the yard.")):toBe(true)
			expect(contains(advice, "Yards: at grade with the main paths.")):toBe(true)
			expect(contains(advice, "Warung and pasar: a slight rise toward both.")):toBe(true)
			expect(contains(advice, "Drainage ditches: along the paths.")):toBe(true)
			expect(contains(advice, "Advice only")):toBe(true)
			expect(contains(dataSrc, "GetService")):toBe(false)
			expect(contains(dataSrc, "Instance.new")):toBe(false)
		end)
	end)

	t:describe("DesignerKitBuilder source", function()
		t:it("is a pure, manually invoked module with build and clear", function()
			expect(contains(builderSrc, "function DesignerKitBuilder.build(")):toBe(true)
			expect(contains(builderSrc, "function DesignerKitBuilder.clear(")):toBe(true)
			expect(contains(builderSrc, "require(game.ServerScriptService.Server.World.DesignerKitBuilder).build()")):toBe(
				true
			)
			expect(contains(builderSrc, "map.folderName")):toBe(true)
			expect(contains(builderSrc, '"DesignerKit"')):toBe(false)
			expect(contains(builderSrc, 'service("ServerStorage")')):toBe(true)
			expect(contains(builderSrc, "Requiring this module does nothing")):toBe(true)
		end)

		t:it("carries no new id literal, LookDev registration or world write", function()
			expect(hasLongId(dataSrc)):toBe(false)
			expect(hasLongId(builderSrc)):toBe(false)
			expect(contains(dataSrc, "LookDev.register")):toBe(false)
			expect(contains(dataSrc, "LookDev.enable")):toBe(false)
			expect(contains(builderSrc, "LookDev.register")):toBe(false)
			expect(contains(builderSrc, "LookDev.enable")):toBe(false)
			expect(contains(builderSrc, "register(")):toBe(false)
			expect(contains(builderSrc, "Workspace")):toBe(false)
			expect(contains(builderSrc, "FillBlock")):toBe(false)
			expect(contains(builderSrc, "PublishPlace")):toBe(false)
		end)

		t:it("guards engine calls with pcall throughout", function()
			local _, calls = string.gsub(builderSrc, "pcall%(", "")
			expect(calls >= 20):toBe(true)
			for _, token in ipairs({
				"game:GetService",
				":WaitForChild",
				"require((shared :: any).DesignerKitMap)",
				":LoadAsset(",
				"GetDescendants",
				"LuaSourceContainer",
				"Anchored = true",
				"CanCollide = false",
				"GetBoundingBox",
				"GetPivot",
				"PivotTo(target)",
				"ScaleTo(target / height)",
				'Instance.new("HumanoidDescription")',
				"CreateHumanoidModelFromDescription",
				"Enum.HumanoidRigType.R15",
				"Destroy()",
			}) do
				expect(contains(builderSrc, token)):toBe(true)
			end
		end)

		t:it("grounds every item by bounding-box bottom at y=0", function()
			expect(contains(builderSrc, "local bottomY = boxCFrame.Y - height * 0.5")):toBe(true)
			expect(contains(builderSrc, "pivot - Vector3.new(0, bottomY, 0)")):toBe(true)
			expect(contains(builderSrc, "no target: keep the source scale")):toBe(true)
			expect(contains(builderSrc, "nil for R15 rigs")):toBe(false) -- comment lives in the data map
		end)

		t:it("clear() destroys only the exact named folder", function()
			expect(contains(builderSrc, ":FindFirstChild(map.folderName)")):toBe(true)
			expect(contains(builderSrc, "(folder :: any):Destroy()")):toBe(true)
			expect(contains(builderSrc, "GetChildren")):toBe(false)
		end)
	end)

	t:describe("designer docs", function()
		t:it("explains the manual kit run and every Indonesian name", function()
			expect(fs.isFile(KIT_DOC)):toBe(true)
			expect(contains(kitDoc, "require(game.ServerScriptService.Server.World.DesignerKitBuilder).build()")):toBe(
				true
			)
			expect(contains(kitDoc, "ServerStorage.DesignerKit")):toBe(true)
			expect(contains(kitDoc, 'LookDev.enable("id")')):toBe(true)
			expect(contains(kitDoc, "drag-source")):toBe(true)
			for _, name in ipairs(EXPECTED_NAMES) do
				expect(contains(kitDoc, name)):toBe(true)
			end
		end)

		t:it("states the anchored, base-pivot and drag-only contract", function()
			expect(contains(kitDoc, "Anchored")):toBe(true)
			expect(contains(kitDoc, "y=0")):toBe(true)
			expect(contains(kitDoc, "true to source scale")):toBe(true)
			expect(contains(kitDoc, "no spawn dressing")):toBe(true)
			expect(contains(kitDoc, "no place save")):toBe(true)
			expect(contains(kitDoc, "no visual verdict")):toBe(true)
		end)

		t:it("keeps the terrain brief one page of advice with no sculpt claim", function()
			expect(fs.isFile(TERRAIN_DOC)):toBe(true)
			for _, line in ipairs(map.terrain) do
				expect(contains(terrainDoc, line)):toBe(true)
			end
			expect(contains(terrainDoc, "Advice only")):toBe(true)
			expect(contains(terrainDoc, "No agent sculpted or dressed spawn")):toBe(true)
			expect(contains(terrainDoc, "no visual was graded")):toBe(true)
		end)
	end)
end
