--!nocheck
-- WORK_QUEUE section M item 78: the OFF-BY-DEFAULT "facades_r8" SERVER candidate. Locks the pure-data
-- facade recipes for all six Greybox hubs, the avatar-fit door gauges, the server applier contract,
-- the two new harness checks and the registry/review/bootstrap/gallery wiring. No Studio run, no
-- visual verdict: those belong to the main session. Procedural parts only, so there are no IDs.

local fs = require("@lune/fs")

local RENDER = "docs/v2/visual/art/models_r8/facades/README.md"
local KINDS = { "shuttered_window", "porch_roof", "ridge_cap", "lantern_bracket", "doorstep", "eave" }
local HUB_KEYS = { "pasar", "gelap", "warung", "ronda", "polisi", "pakrt" }

local function closeTo(value, target, epsilon)
	return type(value) == "number" and math.abs(value - target) <= (epsilon or 1e-9)
end

return function(t, Env)
	local expect = t.expect

	local dataSrc = fs.readFile("src/shared/ModelMapFacadesR8.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevFacadesR8.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local candidatesSrc = fs.readFile("docs/v2/visual/CANDIDATES.md")

	local Data = Env.new():require("shared/ModelMapFacadesR8")
	local LookDev = Env.new():require("shared/LookDev")
	local Review = Env.new():require("shared/LookDevReview")
	local MapSpec = Env.new():require("server/World/MapSpec")

	t:describe("ModelMapFacadesR8 pure data", function()
		t:it("covers all six Greybox hub Models", function()
			expect(Data.id):toBe("facades_r8")
			expect(Data.folderName):toBe("LookDevFacadesR8_facades_r8")
			expect(Data.gaugeName):toBe("FacadeDoorGauge")
			expect(Data.minPartsPerHub):toBe(10)
			expect(Data.HUB_KEYS):toEqual(HUB_KEYS)
			expect(Data.KINDS):toEqual(KINDS)
			for _, key in ipairs(HUB_KEYS) do
				local entry = Data.hubs[key]
				expect(entry ~= nil):toBe(true)
				local mapped = MapSpec.hub(key)
				expect(mapped ~= nil):toBe(true)
				expect(entry.model):toBe(mapped.model)
				expect(entry.width):toBe(mapped.width)
				expect(entry.depth):toBe(mapped.depth)
			end
		end)

		t:it("gives every hub >=10 stable recipes spanning all six kinds", function()
			for _, key in ipairs(HUB_KEYS) do
				local entry = Data.hubs[key]
				expect(#entry.parts >= 10):toBe(true)
				local names, kinds = {}, {}
				for _, recipe in ipairs(entry.parts) do
					expect(type(recipe.name)):toBe("string")
					expect(#recipe.name > 0):toBe(true)
					expect(names[recipe.name]):toBe(nil)
					names[recipe.name] = true
					expect(type(recipe.kind)):toBe("string")
					kinds[recipe.kind] = true
					expect(#recipe.size):toBe(3)
					expect(#recipe.color):toBe(3)
					expect(type(recipe.material)):toBe("string")
					expect(LookDev.isBuiltinMaterial(recipe.material)):toBe(true)
					for _, value in ipairs(recipe.size) do
						expect(type(value)):toBe("number")
						expect(value > 0):toBe(true)
					end
					for _, channel in ipairs(recipe.color) do
						expect(type(channel)):toBe("number")
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
				for _, kind in ipairs(KINDS) do
					expect(kinds[kind]):toBe(true)
				end
			end
		end)

		t:it("uses the exact 7x10.5 pakrt gauge and 6x9 for the other five", function()
			for _, key in ipairs(HUB_KEYS) do
				local g = Data.hubs[key].gauge
				local expected = if key == "pakrt" then { 7, 10.5, 2 } else { 6, 9, 2 }
				expect(closeTo(g.w, expected[1])):toBe(true)
				expect(closeTo(g.h, expected[2])):toBe(true)
				expect(closeTo(g.d, expected[3])):toBe(true)
				expect(type(g.lx)):toBe("number")
				expect(type(g.lz)):toBe("number")
				expect(g.base >= 0.8):toBe(true)
			end
		end)

		t:it("keeps every recipe centre out of its own door gauge footprint", function()
			for _, key in ipairs(HUB_KEYS) do
				local entry = Data.hubs[key]
				local g = entry.gauge
				for _, recipe in ipairs(entry.parts) do
					local inside = math.abs(recipe.lx - g.lx) < g.w / 2 and math.abs(recipe.lz - g.lz) < g.d / 2
					expect(inside):toBe(false)
				end
			end
		end)

		t:it("is pure data with no game APIs and no asset-ID literals", function()
			expect(string.find(dataSrc, "game.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Instance.new", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "Enum.", 1, true) ~= nil):toBe(false)
			expect(string.find(dataSrc, "rbxassetid://%d") ~= nil):toBe(false)
			expect(string.find(dataSrc, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)
	end)

	t:describe("facades_r8 server applier", function()
		t:it("stages tagged anchored non-collidable parts welded to the hub anchor", function()
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MapSpec.hubPoint(hub, lx, lz)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("math.rad(hub.yaw)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.Anchored = true", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("part.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("FacadePart", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("FacadeKind", recipe.kind)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("HubKey", hubKey)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("WeldConstraint")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("weld.Part0 = part", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("weld.Part1 = anchor", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("HubKey", hubKey)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("FacadeDoorGauge", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"DoorW"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"DoorH"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('"DoorD"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevFailures.set(FAMILY_ID, failures)", 1, true) ~= nil):toBe(true)
		end)

		t:it("destroys every staged instance on restore", function()
			expect(applierSrc:find("staged[#staged + 1] = instance", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("staged[index]:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("table.clear(staged)", 1, true) ~= nil):toBe(true)
			local restoreAt = string.find(applierSrc, "local function restore()", 1, true)
			local clearAt = restoreAt and string.find(applierSrc, "clearActive()", restoreAt, true) or nil
			expect(restoreAt ~= nil and clearAt ~= nil):toBe(true)
			expect(string.find(mainSrc, "pcall(require, script.Parent.World.LookDevFacadesR8)", 1, true) ~= nil):toBe(
				true
			)
		end)
	end)

	t:describe("facades_r8 harness", function()
		t:it("registers FACADE_PARTS and DOOR_CLEAR with unweakened targets", function()
			expect(harnessSrc:find('"FACADE_PARTS"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find('"DOOR_CLEAR"', 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("FACADE_MIN_PARTS = 10", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("workspace:GetPartsInPart(probe, params)", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("Enum.RaycastFilterType.Exclude", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("facadePartsOk == #hubOrder", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("facadeDoorOk == #hubOrder", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("sx > 0.5", 1, true) ~= nil):toBe(true)
			expect(harnessSrc:find("sy > 1.5", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("facades_r8 registry, review and gallery", function()
		t:it("ships candidate 56 with a plan and a server review path", function()
			expect(#LookDev.IDS):toBe(56)
			expect(LookDev.IDS[56]):toBe("facades_r8")
			expect(LookDev.candidates.facades_r8.status):toBe("candidate, awaiting designer yes")
			expect(LookDev.candidates.facades_r8.idsSource):toBe("Shared.ModelMapFacadesR8")
			expect(LookDev.candidates.facades_r8.hubCount):toBe(6)
			local plan = LookDev.plan("facades_r8")
			expect(plan ~= nil):toBe(true)
			expect(plan.id):toBe("facades_r8")
			expect(plan.idsSource):toBe("Shared.ModelMapFacadesR8")
			expect(plan.render):toBe(RENDER)
			expect(plan.hubCount):toBe(6)
			local entry = Review.paths.facades_r8
			expect(entry ~= nil):toBe(true)
			expect(entry.datamodel):toBe("server")
			expect(entry.path):toEqual({ "World", "LookDevFacadesR8" })
		end)

		t:it("has a gallery row with an existing render and an fps cost", function()
			local row = nil
			for line in string.gmatch(candidatesSrc, "[^\n]+") do
				if string.find(line, "`facades_r8`", 1, true) then
					row = line
				end
			end
			expect(row ~= nil):toBe(true)
			expect(string.find(row, 'LookDev.enable("facades_r8")', 1, true) ~= nil):toBe(true)
			expect(string.find(row, "`" .. RENDER .. "`", 1, true) ~= nil):toBe(true)
			expect(fs.isFile(RENDER) or fs.isDir(RENDER)):toBe(true)
			expect(string.find(string.lower(row), "fps", 1, true) ~= nil):toBe(true)
			expect(string.find(row, "pending", 1, true) ~= nil):toBe(true)
		end)
	end)
end
