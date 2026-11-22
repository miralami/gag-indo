--!nocheck
-- WORK_QUEUE item 29: coverage-first r4 texture candidate. No visual verdict,
-- no Studio claim. The applier is checked as source because it needs Roblox APIs.

local fs = require("@lune/fs")

local ROOT = "docs/v2/visual/art/textures_r4/"

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local TextureMapR4 = env:require("shared/TextureMapR4")
	local LookDev = env:require("shared/LookDev")

	local manifest = fs.readFile(ROOT .. "MANIFEST.md")
	local downloads = fs.readFile(ROOT .. "download_manifest.json")
	local uploads = fs.readFile(ROOT .. "upload_manifest.json")
	local applier = fs.readFile("src/client/World/LookDevTexturesR4.luau")
	local data = fs.readFile("src/shared/TextureMapR4.luau")

	local function idsIn(text: string, field: string)
		local found = {}
		for value in string.gmatch(text, '"' .. field .. '":%s*"([%d]+)"') do
			found[value] = true
		end
		return found
	end

	t:describe("TextureMapR4 coverage", function()
		t:it("has 12 variants with one allowed base material each", function()
			local count = 0
			local bases = {}
			for slot, variant in TextureMapR4.variants do
				count += 1
				expect(type(slot)):toBe("string")
				expect(type(variant.name)):toBe("string")
				expect(LookDev.isBuiltinMaterial(variant.baseMaterial)):toBe(true)
				expect(bases[variant.baseMaterial]):toBe(nil)
				bases[variant.baseMaterial] = slot
				expect(TextureMapR4.baseMaterials[variant.baseMaterial]):toBe(slot)
			end
			expect(count):toBe(12)
			expect(TextureMapR4.slotCount()):toBe(12)
		end)

		t:it("covers every required built-in surface family", function()
			local required = {
				"Grass",
				"Ground",
				"Mud",
				"Cobblestone",
				"WoodPlanks",
				"Wood",
				"Brick",
				"Concrete",
				"Slate",
				"Metal",
				"Rock",
				"Sand",
			}
			for _, base in ipairs(required) do
				local slot = TextureMapR4.baseMaterials[base]
				expect(type(slot)):toBe("string")
				expect(TextureMapR4.variants[slot]):toBeTruthy()
			end
		end)

		t:it("names paddy mud, laterite, bilik, clay tile, plaster and dry grass explicitly", function()
			local required = {
				"grass",
				"dry_grass",
				"ground",
				"laterite",
				"mud",
				"paddy_mud",
				"cobblestone",
				"wood",
				"weathered_planks",
				"brick",
				"plaster",
				"slate",
				"clay_tile",
				"corrugated_metal",
				"bilik",
				"riverbank",
				"sand",
			}
			for _, surface in ipairs(required) do
				local slot = TextureMapR4.surfaces[surface]
				expect(type(slot)):toBe("string")
				expect(TextureMapR4.variants[slot]):toBeTruthy()
			end
		end)

		t:it("sets a positive studsPerTile per surface", function()
			for slot, variant in TextureMapR4.variants do
				expect(type(variant.studsPerTile)):toBe("number")
				expect(variant.studsPerTile > 0 and variant.studsPerTile <= 32):toBe(true)
			end
			expect(TextureMapR4.variants.dry_grass.studsPerTile):toBeGreaterThan(0)
			expect(TextureMapR4.variants.bilik.studsPerTile):toBeLessThan(TextureMapR4.variants.riverbank.studsPerTile)
		end)
	end)

	t:describe("TextureMapR4 IDs and provenance", function()
		t:it("holds 36 unique real-ID-shaped values", function()
			local seen = {}
			local count = 0
			for key, id in TextureMapR4.ids do
				count += 1
				expect(type(key)):toBe("string")
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			expect(count):toBe(36)
			expect(TextureMapR4.mapCount()):toBe(36)
		end)

		t:it("ties every variant to three existing maps", function()
			for slot, variant in TextureMapR4.variants do
				for _, key in ipairs({ variant.diff, variant.nor, variant.rough }) do
					expect(type(TextureMapR4.ids[key])):toBe("number")
				end
				expect(type(variant.source)):toBe("string")
				expect(manifest:find(variant.sourcePage, 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("matches exactly the IDs returned by completed Open Cloud operations", function()
			local uploaded = idsIn(uploads, "asset_id")
			local mapped = {}
			for _, id in TextureMapR4.ids do
				mapped[tostring(id)] = true
			end
			local count = 0
			for value in uploaded do
				count += 1
				expect(mapped[value]):toBe(true)
			end
			expect(count):toBe(36)
			expect(uploads:find('"asset_type": "Image"', 1, true) ~= nil):toBe(true)
			expect(uploads:find('"upload_route": "ROBLOX_API_KEY"', 1, true) ~= nil):toBe(true)
			expect(uploads:find('"licence": "CC0"', 1, true) ~= nil):toBe(true)
			expect(uploads:find('"operation_id"', 1, true) ~= nil):toBe(true)
		end)

		t:it("records CC0 source text, author and licence evidence", function()
			expect(downloads:find('"licence": "CC0"', 1, true) ~= nil):toBe(true)
			expect(downloads:find("https://polyhaven.com/a/", 1, true) ~= nil):toBe(true)
			expect(downloads:find("https://ambientcg.com/a/", 1, true) ~= nil):toBe(true)
			expect(downloads:find('"md5_source": "Poly Haven files API"', 1, true) ~= nil):toBe(true)
			expect(downloads:find("computed locally", 1, true) ~= nil):toBe(true)
			expect(manifest:find("Our assets are all licensed as CC0", 1, true) ~= nil):toBe(true)
			expect(manifest:find("Creative Commons CC0 1.0 Universal License", 1, true) ~= nil):toBe(true)
			expect(manifest:find("You do not need to give credit", 1, true) ~= nil):toBe(true)
			expect(manifest:find("You can copy, modify, distribute and perform the assets", 1, true) ~= nil):toBe(true)
			expect(manifest:find("Charlotte Baglioni", 1, true) ~= nil):toBe(true)
			expect(manifest:find("ambientCG", 1, true) ~= nil):toBe(true)
		end)

		t:it("builds asset URLs at call time and stays pure data", function()
			local key = TextureMapR4.variants.cobblestone.diff
			expect(TextureMapR4.assetUrl(key)):toBe("rbxassetid://" .. tostring(TextureMapR4.ids[key]))
			expect(TextureMapR4.assetUrl("not_a_real_map")):toBe(nil)
			expect(data:find("GetService", 1, true)):toBe(nil)
			expect(data:find("Instance.new", 1, true)):toBe(nil)
		end)
	end)

	t:describe("TextureMapR4 terrain tint", function()
		t:it("covers the terrain materials the overrides affect", function()
			for _, base in ipairs({ "Grass", "Ground", "Mud", "Cobblestone", "Slate", "Brick" }) do
				expect(type(TextureMapR4.terrainTint[base])):toBe("string")
			end
			expect(TextureMapR4.terrainTint.Water):toBe(nil)
		end)

		t:it("uses bright warm-neutral hex values", function()
			for _, hex in TextureMapR4.terrainTint do
				expect(string.match(hex, "^#%x%x%x%x%x%x$")):toBeTruthy()
				local r = tonumber(string.sub(hex, 2, 3), 16) / 255
				local g = tonumber(string.sub(hex, 4, 5), 16) / 255
				local b = tonumber(string.sub(hex, 6, 7), 16) / 255
				expect(r >= 0.85 and g >= 0.85 and b >= 0.85):toBe(true)
				expect(r >= g and g >= b):toBe(true)
			end
		end)
	end)

	t:describe("LookDevTexturesR4 applier source", function()
		t:it("registers textures_r4 without embedding asset IDs", function()
			expect(applier:find('LookDev.register("textures_r4"', 1, true) ~= nil):toBe(true)
			expect(applier:find("TextureMapR4.assetUrl", 1, true) ~= nil):toBe(true)
			expect(applier:find("rbxassetid", 1, true)):toBe(nil)
			expect(applier:find("%d%d%d%d%d%d%d")):toBe(nil)
		end)

		t:it("sets base-material overrides on variants with BaseMaterial", function()
			expect(applier:find('Instance.new("MaterialVariant")', 1, true) ~= nil):toBe(true)
			expect(applier:find("mv.BaseMaterial = base", 1, true) ~= nil):toBe(true)
			expect(applier:find("mv.StudsPerTile = variant.studsPerTile", 1, true) ~= nil):toBe(true)
			expect(applier:find("MaterialService:GetBaseMaterialOverride(entry.base)", 1, true) ~= nil):toBe(true)
			expect(applier:find("MaterialService:SetBaseMaterialOverride(entry.base, entry.name)", 1, true) ~= nil):toBe(
				true
			)
		end)

		t:it("restores every saved override and destroys its variants on disable", function()
			expect(applier:find("local function restore()", 1, true) ~= nil):toBe(true)
			expect(applier:find("MaterialService:SetBaseMaterialOverride(base, previous)", 1, true) ~= nil):toBe(true)
			expect(applier:find("variant:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applier:find("previousOverrides = {}", 1, true) ~= nil):toBe(true)
		end)

		t:it("captures and restores Terrain material colours around the overrides", function()
			expect(applier:find("TextureMapR4.terrainTint", 1, true) ~= nil):toBe(true)
			expect(applier:find("previousTerrainColors", 1, true) ~= nil):toBe(true)
			expect(applier:find("terrain:GetMaterialColor(base)", 1, true) ~= nil):toBe(true)
			expect(applier:find("terrain:SetMaterialColor(base, Color3.fromHex(tint))", 1, true) ~= nil):toBe(true)
			expect(applier:find("terrain:SetMaterialColor(base, previous)", 1, true) ~= nil):toBe(true)
			expect(applier:find("previousTerrainColors = {}", 1, true) ~= nil):toBe(true)
		end)

		t:it("never targets Water with SetMaterialColor", function()
			expect(applier:find('baseName == "Water"', 1, true) ~= nil):toBe(true)
			expect(TextureMapR4.terrainTint.Water):toBe(nil)
		end)
	end)
end
