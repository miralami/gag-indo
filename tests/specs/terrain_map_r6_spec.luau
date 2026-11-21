--!nocheck
-- WORK_QUEUE section J item 46: the two OFF-BY-DEFAULT terrain_r6 client
-- candidates. Locks the exact palettes, the part/mesh-only override set, the
-- saved camera, exact set/restore semantics, no Terrain texture override, no ID
-- literals, and registry/review/bootstrap wiring. No visual verdict, no Studio
-- claim, no screenshot claim.

local fs = require("@lune/fs")

local ROOT = "docs/v2/visual/art/terrain_r6/"
local PALETTES = {
	a = {
		Grass = { 74, 148, 62 },
		Ground = { 140, 104, 72 },
		Mud = { 72, 60, 44 },
	},
	b = {
		Grass = { 118, 158, 66 },
		Ground = { 176, 148, 106 },
		Mud = { 104, 88, 66 },
	},
}
local PART_VARIANTS = {
	Brick = "brick",
	Concrete = "plaster",
	Slate = "clay_tile",
	Metal = "corrugated_metal",
	Wood = "bilik",
	WoodPlanks = "weathered_planks",
}
local CANDIDATES = { "terrain_r6_a", "terrain_r6_b" }
local INITIAL_COLORS = {
	Grass = { R = 0.11, G = 0.12, B = 0.13 },
	Ground = { R = 0.21, G = 0.22, B = 0.23 },
	Mud = { R = 0.31, G = 0.32, B = 0.33 },
}

return function(t, Env)
	local expect = t.expect

	local dataSrc = fs.readFile("src/shared/TerrainMapR6.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevTerrainR6.luau")
	local readme = fs.readFile(ROOT .. "README.md")
	local candidatesSrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
	local mainSrc = fs.readFile("src/client/Main.client.luau")

	local LookDevPure = Env.new():require("shared/LookDev")
	local TextureMapR4 = Env.new():require("shared/TextureMapR4")

	-- Fake MaterialService + Terrain so the REAL applier can be exercised, not
	-- just scanned as source. `throwing` makes the Grass setter fail.
	local function mount(withTerrain, withMaterialService, throwing)
		local env = Env.new()
		local registered = {}
		local variants = {}
		local colorSets = {}
		local overrideSets = {}
		local current = {}
		local overrides = {}
		local priorOverrides = {
			Brick = "R4_OldBrick",
			Concrete = "R4_OldConcrete",
			Slate = "",
			Metal = "R4_OldMetal",
			Wood = "",
			WoodPlanks = "R4_OldWoodPlanks",
		}
		for base, color in INITIAL_COLORS do
			current[base] = color
		end
		for base, old in priorOverrides do
			overrides[base] = old
		end

		env.globals.Color3 = {
			fromRGB = function(r, g, b)
				return { R = r / 255, G = g / 255, B = b / 255 }
			end,
		}
		env.globals.Instance = {
			new = function(className)
				local object = {
					ClassName = className,
					Name = className,
					Destroyed = false,
				}
				object.Destroy = function(self)
					self.Destroyed = true
					self.Parent = nil
				end
				table.insert(variants, object)
				return object
			end,
		}
		env:mock("shared/LookDev", {
			isBuiltinMaterial = function(name)
				return LookDevPure.isBuiltinMaterial(name)
			end,
			register = function(id, applierTable)
				registered[id] = applierTable
			end,
		})

		if withMaterialService then
			env.services.MaterialService = {
				GetBaseMaterialOverride = function(_, base)
					return overrides[tostring(base):gsub("Material%.", "")]
				end,
				SetBaseMaterialOverride = function(_, base, name)
					local key = tostring(base):gsub("Material%.", "")
					table.insert(overrideSets, { base = key, name = name })
					overrides[key] = name
				end,
			}
		end

		local terrain = nil
		if withTerrain then
			terrain = {
				GetMaterialColor = function(_, base)
					return current[tostring(base):gsub("Material%.", "")]
				end,
				SetMaterialColor = function(_, base, color)
					local key = tostring(base):gsub("Material%.", "")
					if throwing and key == "Grass" then
						error("blocked Terrain setter")
					end
					colorSets[key] = color
					current[key] = color
				end,
			}
		end
		env.services.Workspace = {
			FindFirstChildOfClass = function(_, className)
				return if className == "Terrain" then terrain else nil
			end,
		}

		env:require("client/World/LookDevTerrainR6")
		return env,
			{
				registered = registered,
				variants = variants,
				colorSets = colorSets,
				overrideSets = overrideSets,
				current = current,
				overrides = overrides,
				priorOverrides = priorOverrides,
				initialColors = INITIAL_COLORS,
			}
	end

	t:describe("TerrainMapR6 pure data", function()
		local map = Env.new():require("shared/TerrainMapR6")

		t:it("locks the two exact Terrain palettes and the spawn camera", function()
			expect(map.idPrefix):toBe("terrain_r6_")
			expect(map.order):toEqual({ "a", "b" })
			expect(map.palettes.a):toEqual(PALETTES.a)
			expect(map.palettes.b):toEqual(PALETTES.b)
			expect(map.palettes.a):toEqual({
				Grass = { 74, 148, 62 },
				Ground = { 140, 104, 72 },
				Mud = { 72, 60, 44 },
			})
			expect(map.palettes.b):toEqual({
				Grass = { 118, 158, 66 },
				Ground = { 176, 148, 106 },
				Mud = { 104, 88, 66 },
			})
			expect(map.palettes.a.Grass[1]):toBeLessThan(map.palettes.b.Grass[1])
			expect(map.savedCamera.eye):toEqual({ 0, 20, 72 })
			expect(map.savedCamera.look):toEqual({ 0, 5, 14 })
		end)

		t:it("keeps Grass/Ground/Mud out of the part/mesh override set", function()
			expect(map.terrainMaterials):toEqual({ "Grass", "Ground", "Mud" })
			for _, name in ipairs({ "Grass", "Ground", "Mud" }) do
				expect(map.isTerrainMaterial(name)):toBe(true)
				expect(map.partOverrides[name]):toBe(nil)
			end
			expect(map.isTerrainMaterial("Water")):toBe(false)
			expect(map.isTerrainMaterial("Brick")):toBe(false)
			expect(#map.partOrder):toBe(6)
			local count = 0
			for base, key in map.partOverrides do
				count += 1
				expect(PART_VARIANTS[base]):toBe(key)
				expect(map.isTerrainMaterial(base)):toBe(false)
				expect(map.variantKeyFor(base)):toBe(key)
			end
			expect(count):toBe(6)
		end)

		t:it("reads every map URL only through TextureMapR4.assetUrl", function()
			for base, key in PART_VARIANTS do
				local variant = TextureMapR4.variants[key]
				local color, normal, rough = map.mapsFor(base)
				expect(color):toBe(TextureMapR4.assetUrl(variant.diff))
				expect(normal):toBe(TextureMapR4.assetUrl(variant.nor))
				expect(rough):toBe(TextureMapR4.assetUrl(variant.rough))
				expect(map.variantNameFor(base)):toBe(variant.name)
				expect(map.studsFor(base)):toBe(variant.studsPerTile)
			end
			local color, normal, rough = map.mapsFor("Grass")
			expect(color):toBe(nil)
			expect(normal):toBe(nil)
			expect(rough):toBe(nil)
			expect(dataSrc:find("TextureMapR4.assetUrl", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("rbxassetid", 1, true)):toBe(nil)
			expect(dataSrc:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(dataSrc:find("Color3", 1, true)):toBe(nil)
			expect(dataSrc:find("GetService", 1, true)):toBe(nil)
			expect(dataSrc:find("Instance.new", 1, true)):toBe(nil)
		end)
	end)

	t:describe("LookDevTerrainR6 appliers", function()
		t:it("registers both variants via one make factory with no ID literal or Part", function()
			local env, f = mount(true, true, false)
			expect(env ~= nil):toBe(true)
			local count = 0
			for id, applierTable in f.registered do
				count += 1
				expect(id == "terrain_r6_a" or id == "terrain_r6_b"):toBe(true)
				expect(type(applierTable.apply)):toBe("function")
				expect(type(applierTable.restore)):toBe("function")
			end
			expect(count):toBe(2)
			expect(applierSrc:find("local function make(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(TerrainMapR6.idPrefix .. key", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("TerrainMapR6.partOrder", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("TerrainMapR6.isTerrainMaterial(baseName)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('baseName == "Water"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("TextureMapR4.terrainTint", 1, true)):toBe(nil)
			expect(applierSrc:find('Instance.new("Part"', 1, true)):toBe(nil)
			expect(applierSrc:find("rbxassetid://%d")):toBe(nil)
			expect(applierSrc:find("%d%d%d%d%d%d%d")):toBe(nil)
			expect(applierSrc:find('Instance.new("MaterialVariant")', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MaterialService:GetBaseMaterialOverride(base)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("MaterialService:SetBaseMaterialOverride(base, variantName)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("MaterialService:SetBaseMaterialOverride(base, previous)", 1, true) ~= nil):toBe(
				true
			)
			expect(applierSrc:find("terrain:GetMaterialColor(base)", 1, true) ~= nil):toBe(true)
			expect(
				applierSrc:find("terrain:SetMaterialColor(base, Color3.fromRGB(rgb[1], rgb[2], rgb[3]))", 1, true)
					~= nil
			):toBe(true)
			expect(applierSrc:find("terrain:SetMaterialColor(base, previous)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("variant:Destroy()", 1, true) ~= nil):toBe(true)
		end)

		t:it("sets only the three Terrain colours and six part overrides, then restores exactly", function()
			local _, f = mount(true, true, false)
			local applier = f.registered.terrain_r6_a
			applier.apply(nil)

			local colorCount = 0
			for base, color in f.colorSets do
				colorCount += 1
				local rgb = PALETTES.a[base]
				expect(type(rgb)):toBe("table")
				expect(color):toEqual({ R = rgb[1] / 255, G = rgb[2] / 255, B = rgb[3] / 255 })
			end
			expect(colorCount):toBe(3)
			expect(f.colorSets.Water):toBe(nil)

			expect(#f.overrideSets):toBe(6)
			local partCount = 0
			for _, entry in ipairs(f.overrideSets) do
				expect(PART_VARIANTS[entry.base]):toBeTruthy()
				expect(entry.name):toBe(TextureMapR4.variants[PART_VARIANTS[entry.base]].name)
				partCount += 1
			end
			expect(partCount):toBe(6)
			expect(#f.variants):toBe(6)
			for _, variant in ipairs(f.variants) do
				expect(variant.ClassName):toBe("MaterialVariant")
				expect(variant.Parent ~= nil):toBe(true)
			end

			applier.restore()
			for base, initial in INITIAL_COLORS do
				expect(f.current[base]):toBe(initial)
			end
			for base, old in f.priorOverrides do
				expect(f.overrides[base]):toBe(old)
			end
			for _, variant in ipairs(f.variants) do
				expect(variant.Destroyed):toBe(true)
			end
			expect(pcall(applier.restore)):toBe(true)
		end)

		t:it("applies a distinct palette for b over the same part/mesh texture set", function()
			local _, f = mount(true, true, false)
			local a, b = f.registered.terrain_r6_a, f.registered.terrain_r6_b
			table.clear(f.overrideSets)
			a.apply(nil)
			expect(f.colorSets.Grass):toEqual({ R = 74 / 255, G = 148 / 255, B = 62 / 255 })
			local aNames = {}
			for _, entry in ipairs(f.overrideSets) do
				table.insert(aNames, entry.base .. "=" .. entry.name)
			end
			a.restore()
			table.clear(f.overrideSets)

			b.apply(nil)
			expect(f.colorSets.Grass):toEqual({ R = 118 / 255, G = 158 / 255, B = 66 / 255 })
			expect(f.colorSets.Ground):toEqual({ R = 176 / 255, G = 148 / 255, B = 106 / 255 })
			expect(f.colorSets.Mud):toEqual({ R = 104 / 255, G = 88 / 255, B = 66 / 255 })
			local bNames = {}
			for _, entry in ipairs(f.overrideSets) do
				table.insert(bNames, entry.base .. "=" .. entry.name)
			end
			expect(bNames):toEqual(aNames)
			b.restore()
			expect(f.current.Grass):toBe(INITIAL_COLORS.Grass)
		end)

		t:it("is a graceful no-op for missing Terrain and missing MaterialService", function()
			local env, f = mount(false, false, false)
			local applier = f.registered.terrain_r6_a
			expect(pcall(applier.apply, nil)):toBe(true)
			expect(env ~= nil):toBe(true)
			expect(#f.colorSets):toBe(0)
			expect(#f.overrideSets):toBe(0)
			expect(#f.variants):toBe(0)
			expect(pcall(applier.restore)):toBe(true)

			local env2, f2 = mount(true, false, false)
			expect(pcall(f2.registered.terrain_r6_b.apply, nil)):toBe(true)
			expect(env2 ~= nil):toBe(true)
			expect(f2.colorSets.Grass ~= nil):toBe(true)
			expect(#f2.overrideSets):toBe(0)
			expect(#f2.variants):toBe(0)
			expect(pcall(f2.registered.terrain_r6_b.restore)):toBe(true)

			local env3, f3 = mount(false, true, false)
			expect(pcall(f3.registered.terrain_r6_a.apply, nil)):toBe(true)
			expect(env3 ~= nil):toBe(true)
			expect(#f3.colorSets):toBe(0)
			expect(#f3.overrideSets):toBe(6)
			expect(pcall(f3.registered.terrain_r6_a.restore)):toBe(true)
		end)

		t:it("warns but does not throw on a failing Terrain setter", function()
			local env, f = mount(true, true, true)
			local applier = f.registered.terrain_r6_a
			expect(pcall(applier.apply, nil)):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			expect(f.colorSets.Grass):toBe(nil)
			expect(f.current.Grass):toBe(INITIAL_COLORS.Grass)
			expect(f.colorSets.Ground ~= nil):toBe(true)
			expect(pcall(applier.restore)):toBe(true)
			expect(f.current.Ground):toBe(INITIAL_COLORS.Ground)
		end)
	end)

	t:describe("round-6 terrain registry, review and handoff", function()
		t:it("reaches 57 candidates with both terrain variants wired", function()
			local env = Env.new()
			local LookDev = env:require("shared/LookDev")
			local Review = env:require("shared/LookDevReview")
			expect(#LookDev.IDS):toBe(67)
			expect(LookDev.IDS[38]):toBe("spawn_ground_r6")
			expect(LookDev.IDS[39]):toBe("terrain_r6_a")
			expect(LookDev.IDS[40]):toBe("terrain_r6_b")
			local count = 0
			for _ in Review.paths do
				count += 1
			end
			expect(count):toBe(67)
			expect(count):toBe(#LookDev.IDS)
			for _, id in CANDIDATES do
				expect(LookDev.isCandidate(id)):toBe(true)
				expect(LookDev.candidates[id].status):toBe("candidate, awaiting designer yes")
				local plan = LookDev.plan(id)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.TerrainMapR6")
				expect(plan.render):toBe(ROOT .. "README.md")
				local entry = Review.pathsFor(id)
				expect(entry.datamodel):toBe("client")
				expect(entry.path):toEqual({ "World", "LookDevTerrainR6" })
				local row
				for line in string.gmatch(candidatesSrc, "[^\n]+") do
					if string.find(line, "| `" .. id .. "` |", 1, true) then
						row = line
					end
				end
				expect(type(row)):toBe("string")
				expect(string.sub(row, -4) == "|  |" or string.find(row, "| %*%*[yn][eo]") ~= nil):toBe(true) -- verdict blank or a designer verdict
			end
			expect(mainSrc:find("pcall(require, script.Parent.World.LookDevTerrainR6)", 1, true) ~= nil):toBe(true)
		end)

		t:it("documents both palettes, the camera and the main-session shot handoff", function()
			for key, palette in PALETTES do
				for base, rgb in palette do
					expect(readme:find("`" .. base .. "`", 1, true) ~= nil):toBe(true)
					expect(readme:find("`terrain_r6_" .. key .. "`", 1, true) ~= nil):toBe(true)
					expect(readme:find("{ " .. rgb[1] .. ", " .. rgb[2] .. ", " .. rgb[3] .. " }", 1, true) ~= nil):toBe(
						true
					)
				end
				expect(readme:find('LookDev.enable("terrain_r6_' .. key .. '")', 1, true) ~= nil):toBe(true)
			end
			expect(readme:find("{ 0, 20, 72 }", 1, true) ~= nil):toBe(true)
			expect(readme:find("{ 0, 5, 14 }", 1, true) ~= nil):toBe(true)
			expect(readme:find("MAIN SESSION", 1, true) ~= nil):toBe(true)
			expect(readme:find("No screenshot was captured or graded", 1, true) ~= nil):toBe(true)
			expect(readme:find("blank", 1, true) ~= nil):toBe(true)
		end)
	end)
end
