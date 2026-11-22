--!nocheck
-- WORK_QUEUE item 38 (sky_r5): pure data, the client applier and the README.
-- Checks registry string, real-ID provenance, cloud-cover save/restore, no ridge
-- parts, the cube top-face seam fix and all six verified reference URLs.
-- No visual verdict and no Studio claim here.

local fs = require("@lune/fs")

local FACES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }
local URLS = {
	"https://www.pexels.com/photo/traditional-asian-village-surrounded-by-tropical-woods-5904965/",
	"https://www.pexels.com/photo/scenic-view-of-minangkabau-village-sumatra-34241020/",
	"https://www.pexels.com/photo/aerial-view-of-mount-salak-and-village-in-west-java-37224350/",
	"https://commons.wikimedia.org/wiki/File:Cumulus_humilis_clouds_over_Jakarta.jpg",
	"https://polyhaven.com/a/rustig_koppie_puresky",
	"https://polyhaven.com/a/kloppenheim_03_puresky",
}

return function(t, Env, _Fakes)
	local expect = t.expect

	t:describe("SkyMapR5 pure data", function()
		local SkyMapR5, SkyMapR4
		t:beforeEach(function()
			local env = Env.new()
			SkyMapR5 = env:require("shared/SkyMapR5")
			SkyMapR4 = env:require("shared/SkyMapR4")
		end)

		t:it("uses only the two real-ID CC0 sets from SkyMapR4, no invented IDs", function()
			local count = 0
			for key in SkyMapR5.sets do
				count += 1
				expect(key == "a" or key == "b"):toBe(true)
			end
			expect(count):toBe(2)
			for _, key in ipairs({ "a", "b" }) do
				local set = SkyMapR5.sets[key]
				expect(set.label):toBe(SkyMapR4.sets[key].label)
				expect(string.find(set.licence, "CC0", 1, true) ~= nil):toBe(true)
				local faces = 0
				for _, face in ipairs(FACES) do
					local id = set.ids[face]
					expect(id):toBe(SkyMapR4.sets[key].ids[face])
					expect(type(id)):toBe("number")
					expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
					faces += 1
				end
				expect(faces):toBe(6)
			end
			expect(SkyMapR5.faceCount()):toBe(6)
			expect(SkyMapR5.sets.c):toBe(nil)
		end)

		t:it("holds the bright/humid grade, cloud cover in range and ridge disabled", function()
			expect(SkyMapR5.primaryKey):toBe("a")
			expect(SkyMapR5.alternateKey):toBe("b")
			expect(SkyMapR5.atmosphere.Density):toBe(0.26)
			expect(SkyMapR5.atmosphere.Haze):toBe(3.0)
			expect(SkyMapR5.atmosphere.Color):toEqual({ 232, 240, 244 })
			expect(type(SkyMapR5.atmosphere.Decay)):toBe("table")
			expect(#SkyMapR5.atmosphere.Decay):toBe(3)
			expect(SkyMapR5.cloudCover):toBe(0.4)
			expect(SkyMapR5.cloudCover >= 0.3 and SkyMapR5.cloudCover <= 0.5):toBe(true)
			expect(SkyMapR5.ridgeEnabled):toBe(false)
			local src = fs.readFile("src/shared/SkyMapR5.luau")
			expect(string.find(src, "LATER LEVEL", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "%d%d%d%d%d%d%d%d%d%d%d%d")):toBe(nil)
			expect(string.find(src, "rbxasset", 1, true)):toBe(nil)
			expect(string.find(src, "Color3", 1, true)):toBe(nil)
			expect(string.find(src, "Vector3", 1, true)):toBe(nil)
			expect(string.find(src, "Instance.new", 1, true)):toBe(nil)
			expect(string.find(src, "SkyboxImage", 1, true)):toBe(nil)
			expect(string.find(src, "game:", 1, true)):toBe(nil)
		end)
	end)

	t:describe("LookDevSkyR5 applier", function()
		local env, SkyMapR5, applier, instances, Lighting, Workspace, terrain, clouds, registered
		local thrownSkyFace

		local function newInstance(className)
			local fields = {
				ClassName = className,
				Name = className,
				Parent = nil,
				Destroyed = false,
				CelestialBodiesShown = true,
			}
			fields.Destroy = function(self)
				self.Destroyed = true
				self.Parent = nil
			end
			local object = setmetatable({}, {
				__index = fields,
				__newindex = function(_, key, value)
					if className == "Sky" and key == thrownSkyFace then
						error("blocked Sky setter")
					end
					fields[key] = value
				end,
			})
			table.insert(instances, object)
			return object
		end

		local function find(parent, className, name)
			for _, object in ipairs(instances) do
				if
					not object.Destroyed
					and object.Parent == parent
					and object.ClassName == className
					and (name == nil or object.Name == name)
				then
					return object
				end
			end
			return nil
		end

		local function countParts()
			local count = 0
			for _, object in ipairs(instances) do
				if not object.Destroyed and object.ClassName == "Part" then
					count += 1
				end
			end
			return count
		end

		local function service(name)
			local object = { ClassName = name, Name = name }
			object.FindFirstChildOfClass = function(_, className)
				return find(object, className)
			end
			return object
		end

		local function mount(withOriginals, withClouds)
			env = Env.new()
			instances = {}
			registered = {}
			thrownSkyFace = nil
			terrain = nil
			clouds = nil

			Lighting = service("Lighting")
			Workspace = service("Workspace")
			env.services.Lighting = Lighting
			env.services.Workspace = Workspace

			env.globals.Color3 = {
				fromRGB = function(r, g, b)
					return { R = r / 255, G = g / 255, B = b / 255 }
				end,
			}
			env.globals.Instance = { new = newInstance }
			env:mock("shared/LookDev", {
				register = function(id, applierTable)
					registered[id] = applierTable
				end,
			})

			if withClouds then
				terrain = newInstance("Terrain")
				terrain.Name = "Terrain"
				terrain.Parent = Workspace
				terrain.FindFirstChildOfClass = function(_, className)
					return find(terrain, className)
				end
				clouds = newInstance("Clouds")
				clouds.Name = "Clouds"
				clouds.Parent = terrain
				clouds.Cover = 0.85
			end

			if withOriginals then
				local oldSky = newInstance("Sky")
				oldSky.Name = "OriginalSky"
				oldSky.Parent = Lighting
				for _, face in ipairs(FACES) do
					oldSky[face] = "rbxassetid://original-" .. face
				end
				local oldAtmosphere = newInstance("Atmosphere")
				oldAtmosphere.Parent = Lighting
				oldAtmosphere.Density = 0.9
				oldAtmosphere.Haze = 7.5
				oldAtmosphere.Color = { R = 1, G = 0, B = 0 }
				oldAtmosphere.Decay = { R = 0.5, G = 0.5, B = 0.5 }
			end

			SkyMapR5 = env:require("shared/SkyMapR5")
			env:require("client/World/LookDevSkyR5")
			applier = registered.sky_r5
		end

		t:beforeEach(function()
			mount(true, true)
		end)

		t:it("registers exactly sky_r5 by the requested call, with no ID or ridge literal", function()
			local src = fs.readFile("src/client/World/LookDevSkyR5.luau")
			expect(string.find(src, 'LookDev.register("sky_r5", { apply = apply, restore = restore })', 1, true) ~= nil):toBe(
				true
			)
			expect(type(applier)):toBe("table")
			expect(type(applier.apply)):toBe("function")
			expect(type(applier.restore)):toBe("function")
			expect(string.find(src, "%d%d%d%d%d%d%d%d%d%d%d%d")):toBe(nil)
			expect(string.find(src, "SkyboxImage", 1, true)):toBe(nil)
			expect(string.find(src, 'Instance.new("Part"', 1, true)):toBe(nil)
			expect(string.find(src, "ridgeAt", 1, true)):toBe(nil)
			expect(string.find(src, "applyCubeTopFaceSeamFix", 1, true) ~= nil):toBe(true)
		end)

		t:it("applies one CC0 set with all six faces, the top-face seam fix and no ridge", function()
			applier.apply(nil)
			local sky = find(Lighting, "Sky", "SkyR5_a")
			expect(sky ~= nil):toBe(true)
			local set = SkyMapR5.sets[SkyMapR5.primaryKey]
			for _, face in ipairs(FACES) do
				expect(sky[face]):toBe("rbxassetid://" .. tostring(set.ids[face]))
			end
			expect(sky.SkyboxUp):toBe("rbxassetid://" .. tostring(set.ids.SkyboxUp))
			expect(countParts()):toBe(0)
			expect(find(Workspace, "Folder")):toBe(nil)
			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere ~= nil):toBe(true)
			expect(atmosphere.Density):toBe(SkyMapR5.atmosphere.Density)
			expect(atmosphere.Haze):toBe(SkyMapR5.atmosphere.Haze)
			expect(atmosphere.Color):toEqual({ R = 232 / 255, G = 240 / 255, B = 244 / 255 })
			expect(atmosphere.Decay):toEqual({ R = 40 / 255, G = 58 / 255, B = 74 / 255 })
			applier.restore()
		end)

		t:it("lowers Terrain Clouds.Cover while active and restores the exact prior value", function()
			expect(clouds.Cover):toBe(0.85)
			applier.apply(nil)
			expect(clouds.Cover):toBe(SkyMapR5.cloudCover)
			expect(clouds.Cover):toBe(0.4)
			applier.restore()
			expect(clouds.Cover):toBe(0.85)
			expect(pcall(applier.restore)):toBe(true)
		end)

		t:it("restores the original Sky and Atmosphere and destroys created instances", function()
			local oldSky = find(Lighting, "Sky", "OriginalSky")
			expect(oldSky ~= nil):toBe(true)
			applier.apply(nil)
			expect(oldSky.Parent):toBe(nil)
			applier.restore()
			expect(oldSky.Parent):toBe(Lighting)
			for _, face in ipairs(FACES) do
				expect(oldSky[face]):toBe("rbxassetid://original-" .. face)
			end
			expect(find(Lighting, "Sky", "SkyR5_a")):toBe(nil)
			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere.Density):toBe(0.9)
			expect(atmosphere.Haze):toBe(7.5)
			expect(atmosphere.Color):toEqual({ R = 1, G = 0, B = 0 })
			expect(atmosphere.Decay):toEqual({ R = 0.5, G = 0.5, B = 0.5 })
			expect(countParts()):toBe(0)
		end)

		t:it("warns but does not throw on a failing Sky setter", function()
			thrownSkyFace = "SkyboxFt"
			local ok = pcall(function()
				applier.apply(nil)
			end)
			expect(ok):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			local sky = find(Lighting, "Sky", "SkyR5_a")
			expect(sky ~= nil):toBe(true)
			expect(sky.SkyboxFt):toBe(nil)
			expect(sky.SkyboxUp):toBe("rbxassetid://" .. tostring(SkyMapR5.sets.a.ids.SkyboxUp))
			expect(pcall(applier.restore)):toBe(true)
		end)

		t:it("is a no-op for cloud cover when Terrain or Clouds is missing", function()
			mount(true, false)
			expect(terrain):toBe(nil)
			expect(clouds):toBe(nil)
			expect(pcall(applier.apply, nil)):toBe(true)
			expect(find(Lighting, "Sky", "SkyR5_a") ~= nil):toBe(true)
			expect(countParts()):toBe(0)
			expect(pcall(applier.restore)):toBe(true)
		end)
	end)

	t:describe("sky_r5 README", function()
		t:it("carries the six verified URLs, the notes and no visual verdict", function()
			local readme = fs.readFile("docs/v2/visual/art/sky_r5/README.md")
			for _, url in ipairs(URLS) do
				expect(string.find(readme, url, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(readme, "Tom Fisk", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "nur ihsan", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "Ridwan Afriandy", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "Vitaium", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "future season event", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "not uploaded", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "visual was graded", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "SEEN-IN-STUDIO", 1, true)):toBe(nil)
		end)
	end)
end
