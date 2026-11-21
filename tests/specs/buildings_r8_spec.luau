--!nocheck
-- WORK_QUEUE section M item 77: the OFF-BY-DEFAULT "buildings_r8" SERVER candidate. Locks the six
-- real Creator Store IDs/names/scales, the 12..60 staged-width band (incl. joglo's required 0.75),
-- the 7 x 7.25 x 2 door gauge, and registry/review/bootstrap/gallery/manifest wiring. No Studio,
-- no visual verdict, no screenshot claim.

local fs = require("@lune/fs")

local EXPECTED = {
	{ slot = "indonesian_house", id = 81909711760416, name = "indonesian_house", scale = 1.0 },
	{ slot = "rumah_4", id = 140621903274156, name = "rumah_4", scale = 1.0 },
	{ slot = "rumah_joglo", id = 4820552419, name = "rumah_joglo", scale = 0.75 },
	{ slot = "pendopo_jawa", id = 136417251697510, name = "pendopo_jawa", scale = 1.0 },
	{ slot = "warung_penyetan", id = 118767493095408, name = "warung_penyetan", scale = 1.0 },
	{ slot = "nipa_hut", id = 167594119, name = "nipa_hut", scale = 1.0 },
}

local RENDER = "docs/v2/visual/art/models_r8/buildings/README.md"

local function closeTo(value, target, epsilon)
	return type(value) == "number" and math.abs(value - target) <= (epsilon or 1e-9)
end

local function countOf(text, needle)
	local count, from = 0, 1
	while true do
		local at = string.find(text, needle, from, true)
		if not at then
			break
		end
		count += 1
		from = at + #needle
	end
	return count
end

return function(t, Env)
	local expect = t.expect

	local dataSrc = fs.readFile("src/shared/ModelMapBuildingsR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevBuildingsR8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local bakeSrc = fs.readFile("tools/studio/bake_lookdev_assets.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local candidatesSrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
	local manifestSrc = fs.readFile("docs/v2/visual/art/ASSET_MANIFEST.md")

	local Data = Env.new():require("shared/ModelMapBuildingsR8")
	local LookDev = Env.new():require("shared/LookDev")
	local Review = Env.new():require("shared/LookDevReview")

	local bySlot = {}
	for _, entry in ipairs(Data.slots) do
		bySlot[entry.slot] = entry
	end

	t:describe("ModelMapBuildingsR8 pure data", function()
		t:it("exports six slots with the exact IDs, names and scales", function()
			expect(Data.familyId):toBe("buildings_r8")
			expect(Data.folderName):toBe("LookDevBuildingsR8_buildings_r8")
			expect(Data.tagAttribute):toBe("LookDevBuildingsR8")
			expect(Data.slotAttribute):toBe("BuildingSlot")
			expect(Data.gap):toBe(20)
			expect(#Data.order):toBe(6)
			expect(#Data.slots):toBe(6)
			expect(Data.count()):toBe(6)
			for index, rule in ipairs(EXPECTED) do
				expect(Data.order[index]):toBe(rule.slot)
				local entry = Data.slots[index]
				expect(entry.slot):toBe(rule.slot)
				expect(entry.id):toBe(rule.id)
				expect(entry.name):toBe(rule.name)
				expect(closeTo(entry.scale, rule.scale)):toBe(true)
				expect(Data.ids[rule.slot]):toBe(rule.id)
				expect(type(entry.creator)):toBe("string")
				expect(#entry.creator > 0):toBe(true)
				expect(string.find(entry.source, "Creator Store", 1, true) ~= nil):toBe(true)
			end
			-- The rejected asset is deliberately absent.
			expect(string.find(dataSrc, "10019841237", 1, true) ~= nil):toBe(false)
		end)

		t:it("scales joglo by 0.75 and keeps every staged width in 12..60", function()
			local joglo = bySlot.rumah_joglo
			expect(joglo ~= nil):toBe(true)
			expect(closeTo(joglo.scale, 0.75)):toBe(true)
			expect(closeTo(joglo.nativeWidth * joglo.scale, 57.6525, 0.0001)):toBe(true)
			expect(closeTo(joglo.stagedWidth, 57.66, 0.02)):toBe(true)
			expect(joglo.stagedWidth >= Data.MIN_WIDTH and joglo.stagedWidth <= Data.MAX_WIDTH):toBe(true)
			for _, entry in ipairs(Data.slots) do
				expect(entry.stagedWidth >= Data.MIN_WIDTH and entry.stagedWidth <= Data.MAX_WIDTH):toBe(true)
				expect(entry.stagedWidth > 0 and entry.stagedHeight > 0 and entry.stagedDepth > 0):toBe(true)
			end
			expect(Data.MIN_WIDTH):toBe(12)
			expect(Data.MAX_WIDTH):toBe(60)
		end)

		t:it("stages an avatar-fit 7 x 7.25 x 2 gauge with a 7-stud minimum door", function()
			local gauge = Data.gauge
			expect(gauge.width):toBe(7)
			expect(closeTo(gauge.height, 7.25)):toBe(true)
			expect(gauge.depth):toBe(2)
			expect(gauge.floorOffset):toBe(1.5)
			expect(Data.MIN_DOOR):toBe(7)
			expect(Data.AVATAR_HEIGHT):toBe(7.25)
			expect(gauge.width >= Data.MIN_DOOR):toBe(true)
			expect(gauge.height >= Data.AVATAR_HEIGHT):toBe(true)
			expect(gauge.height >= Data.MIN_DOOR):toBe(true)
		end)

		t:it("uses a 20-stud clear gap, a model-free site box and a verified min-Z review camera", function()
			local offsets = Data.rowOffsets()
			expect(#offsets):toBe(6)
			expect(closeTo(offsets[1], 0)):toBe(true)
			for index = 2, 6 do
				local previous = Data.slots[index - 1]
				local current = Data.slots[index]
				local expected = offsets[index - 1] + previous.stagedWidth / 2 + Data.gap + current.stagedWidth / 2
				expect(closeTo(offsets[index], expected, 1e-6)):toBe(true)
			end
			expect(closeTo(offsets[2], 57.14, 0.01)):toBe(true)
			expect(closeTo(offsets[6], 279.485, 0.01)):toBe(true)
			local centres = Data.rowCentres(300)
			expect(#centres):toBe(6)
			expect(closeTo(centres[1], 163.745, 0.02)):toBe(true)
			expect(closeTo(centres[6], 443.23, 0.02)):toBe(true)
			expect(closeTo(Data.rowOffset(1), centres[1] - 300, 1e-6)):toBe(true)

			expect(Data.siteWidth):toBe(340)
			expect(Data.siteDepth):toBe(80)
			expect(Data.siteHeight):toBe(70)
			expect(Data.siteProbeY):toBe(25)
			-- Negative front = camera on the min-Z (facade) side, verified clear by harness sweep.
			expect(Data.cameraRule.front):toBe(-228)
			expect(Data.cameraRule.up):toBe(60)
			expect(Data.cameraRule.lookY):toBe(16)
			local rule = Data.cameraFor(300, 0)
			expect(rule.position.x):toBe(300)
			expect(rule.position.y):toBe(60)
			expect(rule.position.z):toBe(-228)
			expect(rule.target.x):toBe(300)
			expect(rule.target.y):toBe(16)
			expect(rule.target.z):toBe(0)
		end)

		t:it("is pure data and free of game APIs at load", function()
			expect(dataSrc:find("game.", 1, true) == nil):toBe(true)
			expect(dataSrc:find("Instance.new", 1, true) == nil):toBe(true)
			expect(dataSrc:find("Enum.", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("buildings_r8 applier contract", function()
		t:it("scales before measuring and places one tagged DoorGauge per building", function()
			expect(applierSrc:find("LookDev.register(FAMILY_ID, applier)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevAssetLoader.get(id, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("model:ScaleTo(entry.scale)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ModelMapBuildingsR8.gaugeName", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"DoorClearance"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('LookDevFailures.set("buildings_r8", failures)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"front"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"back"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("GetPartBoundsInBox", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("GetPartsInPart", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ModelMapBuildingsR8.rowCentres", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Transparent = 1", 1, true) == nil):toBe(true)
			expect(countOf(applierSrc, "part.CanCollide = false")):toBe(1)
		end)

		t:it("parents each model into the staged folder before its gauge search", function()
			local parentAt = string.find(applierSrc, "model.Parent = folder", 1, true)
			local stageAt = string.find(applierSrc, "stage(model,", 1, true)
			expect(parentAt ~= nil):toBe(true)
			expect(stageAt ~= nil):toBe(true)
			expect(parentAt < stageAt):toBe(true)
			expect(applierSrc:find('fail("could not parent "', 1, true) ~= nil):toBe(true)
		end)

		t:it("sets a ground-base (x, baseY, z) WorldPivot after worldBox placement under pcall", function()
			local placedAt = string.find(applierSrc, "local placedBox, placedSize = worldBox(model)", 1, true)
			local baseAt = string.find(applierSrc, "local baseY = placedBox.Position.Y - placedSize.Y * 0.5", 1, true)
			local assignAt = string.find(applierSrc, "model.WorldPivot = CFrame.new(x, baseY, z)", 1, true)
			expect(placedAt ~= nil):toBe(true)
			expect(baseAt ~= nil):toBe(true)
			expect(assignAt ~= nil):toBe(true)
			expect(placedAt < baseAt):toBe(true)
			expect(baseAt < assignAt):toBe(true)
			expect(applierSrc:find("model.PrimaryPart = nil", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('fail("could not set ground pivot for "', 1, true) ~= nil):toBe(true)
			expect(string.sub(applierSrc, baseAt, assignAt):find("pcall(function()", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("buildings_r8 rotation-aware door harness", function()
		t:it("measures BLDG_DOOR with GetPartsInPart and keeps the 6/6 target", function()
			expect(harnessSrc:find('"BLDG_DOOR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("MIN_DOOR = 7", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("workspace:GetPartsInPart(probe, params)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Enum.RaycastFilterType.Exclude", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("bldgDoorOk == #BUILDING_SLOTS", 1, true) ~= nil):toBe(true)
		end)

		t:it("emits read-only PIVOT_GROUND with target 0 and 0.2-stud tolerance", function()
			expect(harnessSrc:find('"PIVOT_GROUND"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('emit("PIVOT_GROUND"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("PIVOT_TOL = 0.2", 1, true) ~= nil):toBe(true)
			expect(
				harnessSrc:find('"PIVOT_GROUND", pivotReadable and pivotFailures == 0, pivotMeasured, 0,', 1, true)
					~= nil
			):toBe(true)
			expect(harnessSrc:find("model:GetPivot()", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("model:GetBoundingBox()", 1, true) ~= nil):toBe(true)
			local visibleAt = string.find(harnessSrc, '"BLDG_VISIBLE",', 1, true)
			local pivotAt = string.find(harnessSrc, '"PIVOT_GROUND",', 1, true)
			expect(visibleAt ~= nil and pivotAt ~= nil and visibleAt < pivotAt):toBe(true)
		end)
	end)

	t:describe("buildings_r8 registry, review, bake and handoff", function()
		t:it("ships candidate 55 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(69)
			expect(LookDev.IDS[55]):toBe("buildings_r8")
			expect(LookDev.candidates.buildings_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.buildings_r8.idsSource):toBe("Shared.ModelMapBuildingsR8")
			local plan = LookDev.plan("buildings_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("buildings_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapBuildingsR8")
			local entry = Review.paths.buildings_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevBuildingsR8" })
		end)

		t:it("is required at server boot and baked with all six IDs", function()
			expect(mainSrc:find("pcall(require, script.Parent.World.LookDevBuildingsR8)", 1, true) ~= nil):toBe(true)
			expect(bakeSrc:find("buildings_r8", 1, true) ~= nil):toBe(true)
			for _, rule in ipairs(EXPECTED) do
				expect(string.find(bakeSrc, tostring(rule.id), 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("has a gallery row with an existing render and an fps cost", function()
			local row = nil
			for line in string.gmatch(candidatesSrc, "[^\n]+") do
				if string.find(line, "`buildings_r8`", 1, true) then
					row = line
				end
			end
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("buildings_r8")', 1, true) ~= nil):toBe(true)
			expect(string.find(row, "`" .. RENDER .. "`", 1, true) ~= nil):toBe(true)
			expect(fs.isFile(RENDER) or fs.isDir(RENDER)):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
			expect(
				string.find(row, "pending", 1, true) ~= nil
					or string.find(row, "| **yes", 1, true) ~= nil
					or string.find(row, "| **no", 1, true) ~= nil
			):toBe(true)
		end)

		t:it("records all six IDs in the asset manifest", function()
			expect(string.find(manifestSrc, "### buildings_r8", 1, true) ~= nil):toBe(true)
			for _, rule in ipairs(EXPECTED) do
				expect(string.find(manifestSrc, tostring(rule.id), 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
