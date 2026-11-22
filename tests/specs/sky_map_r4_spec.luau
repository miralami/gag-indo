--!nocheck
-- WORK_QUEUE round 4 item 30 (sky A/B/C): the three real CC0 HDRI ID sets, the
-- pure sky/atmosphere/ridge data, the client adapter and the upload manifest.
-- No visual verdict, no Studio claim and no ID invented here.

local fs = require("@lune/fs")

return function(t, Env, Fakes)
	local expect = t.expect
	local FACES = {
		"SkyboxBk",
		"SkyboxDn",
		"SkyboxFt",
		"SkyboxLf",
		"SkyboxRt",
		"SkyboxUp",
	}
	local OPTIONS = { "a", "b", "c" }
	local SOURCES = {
		a = "spiaggia_di_mondello",
		b = "umhlanga_sunrise",
		c = "overcast_soil_puresky",
	}

	t:describe("SkyMapR4 pure data", function()
		local SkyMapR4, Visuals
		t:beforeEach(function()
			local env = Env.new()
			SkyMapR4 = env:require("shared/SkyMapR4")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("has three sets, each with only the six real Roblox Sky face properties", function()
			local n = 0
			for key, set in SkyMapR4.sets do
				n += 1
				expect(table.find(OPTIONS, key) ~= nil):toBe(true)
				expect(type(set.label) == "string" and #set.label > 0):toBe(true)
				local count = 0
				for face, id in set.ids do
					count += 1
					expect(table.find(FACES, face) ~= nil):toBe(true)
					expect(string.find(face, "SkyboxImage", 1, true)):toBe(nil)
					expect(type(id)):toBe("number")
					expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				end
				expect(count):toBe(6)
				expect(SkyMapR4.faceCount()):toBe(6)
			end
			expect(n):toBe(3)
		end)

		t:it("holds exactly 18 unique numeric IDs, all backed by completed Image uploads", function()
			local seen, count = {}, 0
			for _, key in ipairs(OPTIONS) do
				for _, face in ipairs(FACES) do
					local id = SkyMapR4.sets[key].ids[face]
					expect(seen[id]):toBe(nil)
					seen[id] = true
					count += 1
				end
			end
			expect(count):toBe(18)

			local raw = fs.readFile("docs/v2/visual/art/sky_r4/upload_manifest.json")
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, images = string.gsub(raw, '"asset_type": "Image"', "")
			expect(routes):toBe(18)
			expect(images):toBe(18)
			local manifestCount, manifestSeen = 0, {}
			for option, face, id in
				string.gmatch(raw, '"option":%s*"([^"]+)".-"face":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"')
			do
				expect(table.find(OPTIONS, option) ~= nil):toBe(true)
				expect(table.find(FACES, face) ~= nil):toBe(true)
				expect(manifestSeen[option .. "/" .. face]):toBe(nil)
				manifestSeen[option .. "/" .. face] = true
				manifestCount += 1
				expect(tonumber(id)):toBe(SkyMapR4.sets[option].ids[face])
			end
			expect(manifestCount):toBe(18)
		end)

		t:it("records three distinct CC0 sources with author and licence text", function()
			local manifest = fs.readFile("docs/v2/visual/art/sky_r4/MANIFEST.md")
			local log = fs.readFile("docs/v2/visual/art/sky_r4/source/download_log.json")
			expect(string.find(manifest, "creativecommons.org/publicdomain/zero/1.0/", 1, true) ~= nil):toBe(true)
			expect(string.find(manifest, "CC0 1.0 Universal", 1, true) ~= nil):toBe(true)
			local _, marks = string.gsub(log, '"licence_mark_in_page": true', "")
			expect(marks):toBe(3)
			local _, notices = string.gsub(log, '"copyright_notice"', "")
			expect(notices):toBe(3)
			expect(
				string.find(
					log,
					'"copyright_notice": "CC0 1.0 Universal - public domain dedication, no attribution required"',
					1,
					true
				) ~= nil
			):toBe(true)
			for _, key in ipairs(OPTIONS) do
				local source = SOURCES[key]
				expect(string.find(manifest, source, 1, true) ~= nil):toBe(true)
				expect(string.find(log, source, 1, true) ~= nil):toBe(true)
				expect(string.find(SkyMapR4.sets[key].source, source, 1, true) ~= nil):toBe(true)
				expect(string.find(SkyMapR4.sets[key].licence, "CC0", 1, true) ~= nil):toBe(true)
				expect(type(SkyMapR4.sets[key].author) == "string" and #SkyMapR4.sets[key].author > 0):toBe(true)
			end
		end)

		t:it("keeps the haze grade and a plain r,g,b Decay without touching the sun", function()
			local atmosphere = SkyMapR4.atmosphere
			expect(atmosphere.Density):toBe(0.22)
			expect(atmosphere.Offset):toBe(0.55)
			expect(atmosphere.Glare):toBe(1.2)
			expect(atmosphere.Haze):toBe(2.4)
			expect(atmosphere.Color):toEqual({ 214, 223, 230 })
			expect(type(atmosphere.Decay)):toBe("table")
			expect(#atmosphere.Decay):toBe(3)
			for _, channel in ipairs(atmosphere.Decay) do
				expect(type(channel)):toBe("number")
				expect(channel >= 0 and channel <= 255):toBe(true)
			end
			local src = fs.readFile("src/shared/SkyMapR4.luau")
			expect(string.find(src, "CelestialBodiesShown", 1, true)):toBe(nil)
			expect(string.find(src, "game:", 1, true)):toBe(nil)
			expect(string.find(src, "Instance.new", 1, true)):toBe(nil)
			expect(string.find(src, "Color3", 1, true)):toBe(nil)
			expect(string.find(src, "Vector3", 1, true)):toBe(nil)
			expect(string.find(src, "rbxasset", 1, true)):toBe(nil)
		end)

		t:it("exposes twelve ridge wedges with a documented real-terrain offset seam", function()
			expect(#SkyMapR4.ridge):toBe(12)
			local names = {}
			for _, wedge in ipairs(SkyMapR4.ridge) do
				expect(names[wedge.name]):toBe(nil)
				names[wedge.name] = true
				expect(wedge.shape):toBe("Wedge")
				expect(Visuals.palette[wedge.color] ~= nil):toBe(true)
				expect(#wedge.offset):toBe(3)
				expect(#wedge.size):toBe(3)
				expect(math.abs(wedge.offset[1]) <= 27 and math.abs(wedge.offset[3]) <= 27):toBe(true)
				expect(type(wedge.yaw)):toBe("number")
			end
			expect(SkyMapR4.ridgeOrigin[1]):toBe(-14)
			expect(SkyMapR4.ridgeOrigin[3]):toBe(-12)
			local placed = SkyMapR4.ridgeAt()
			expect(#placed):toBe(12)
			expect(placed[1].position):toEqual({ 13, 11, -12 })
			-- Every wedge sits inside MapSpec.PLAZA (X -48..48, Z -42..42) on real ground.
			for _, wedge in ipairs(placed) do
				expect(wedge.position[1] >= -48 and wedge.position[1] <= 48):toBe(true)
				expect(wedge.position[3] >= -42 and wedge.position[3] <= 42):toBe(true)
			end
			local moved = SkyMapR4.ridgeAt({ 500, 0, 500 })
			expect(moved[1].position):toEqual({ 527, 11, 500 })
			expect(SkyMapR4.ridge[1].offset[1]):toBe(27)
		end)
	end)

	t:describe("LookDevSkyR4 adapter", function()
		local env, SkyMapR4, adapter, instances, Lighting, Workspace, registered, thrownSkyFace

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

		local function countParts(folder)
			local count = 0
			for _, object in ipairs(instances) do
				if object.ClassName == "Part" and object.Parent == folder then
					count += 1
				end
			end
			return count
		end

		local function mount(withOriginals)
			env = Env.new()
			instances = {}
			registered = {}
			thrownSkyFace = nil

			Lighting = { ClassName = "Lighting", Name = "Lighting" }
			Lighting.FindFirstChildOfClass = function(_, className)
				return find(Lighting, className)
			end
			Workspace = { ClassName = "Workspace", Name = "Workspace" }
			Workspace.FindFirstChildOfClass = function(_, className)
				return find(Workspace, className)
			end
			env.services.Lighting = Lighting
			env.services.Workspace = Workspace

			env.globals.Color3 = {
				fromRGB = function(r, g, b)
					return { R = r / 255, G = g / 255, B = b / 255 }
				end,
				fromHex = function(hex)
					return { hex = hex }
				end,
			}
			env.globals.Instance = { new = newInstance }
			env:mock("shared/LookDev", {
				register = function(id, applier)
					registered[id] = applier
				end,
			})

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

			SkyMapR4 = env:require("shared/SkyMapR4")
			adapter = env:require("client/World/LookDevSkyR4")
		end

		t:beforeEach(function()
			mount(true)
		end)

		t:it("registers exactly the three dot-syntax ids and holds no asset ID literal", function()
			local src = fs.readFile("src/client/World/LookDevSkyR4.luau")
			for _, key in ipairs(OPTIONS) do
				local id = "sky_r4_" .. key
				expect(string.find(src, 'LookDev.register("' .. id .. '"', 1, true) ~= nil):toBe(true)
				expect(type(registered[id])):toBe("table")
				expect(type(registered[id].apply)):toBe("function")
				expect(type(registered[id].restore)):toBe("function")
			end
			expect(string.find(src, "%d%d%d%d%d%d%d")):toBe(nil)
			expect(string.find(src, "SkyboxImage", 1, true)):toBe(nil)
			expect(string.find(src, "CelestialBodiesShown", 1, true)):toBe(nil)
			expect(string.find(src, "SkyMapR4.sets", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "SkyMapR4.ridgeAt", 1, true) ~= nil):toBe(true)
		end)

		t:it("applies all six real face URLs, the colour Decay and the ridge for each option", function()
			for _, key in ipairs(OPTIONS) do
				local applier = adapter.appliers[key]
				applier.apply(nil)
				local sky = find(Lighting, "Sky", "SkyR4_" .. key)
				expect(sky ~= nil):toBe(true)
				for _, face in ipairs(FACES) do
					expect(sky[face]):toBe("rbxassetid://" .. tostring(SkyMapR4.sets[key].ids[face]))
				end
				expect(sky.CelestialBodiesShown):toBe(true)
				local atmosphere = find(Lighting, "Atmosphere")
				expect(atmosphere ~= nil):toBe(true)
				expect(atmosphere.Density):toBe(SkyMapR4.atmosphere.Density)
				expect(atmosphere.Haze):toBe(SkyMapR4.atmosphere.Haze)
				expect(atmosphere.Color):toEqual({ R = 214 / 255, G = 223 / 255, B = 230 / 255 })
				expect(atmosphere.Decay):toEqual({ R = 32 / 255, G = 48 / 255, B = 64 / 255 })
				local folder = find(Workspace, "Folder", "SkyR4Ridge_" .. key)
				expect(folder ~= nil):toBe(true)
				expect(countParts(folder)):toBe(#SkyMapR4.ridge)
				applier.restore()
			end
		end)

		t:it("restores the original Sky URL strings and every Atmosphere value on disable", function()
			local oldSky = find(Lighting, "Sky", "OriginalSky")
			expect(oldSky ~= nil):toBe(true)
			adapter.appliers.a.apply(nil)
			expect(oldSky.Parent):toBe(nil)
			adapter.appliers.a.restore()
			expect(oldSky.Parent):toBe(Lighting)
			for _, face in ipairs(FACES) do
				expect(oldSky[face]):toBe("rbxassetid://original-" .. face)
			end
			expect(oldSky.CelestialBodiesShown):toBe(true)
			expect(find(Lighting, "Sky", "SkyR4_a")):toBe(nil)
			expect(find(Workspace, "Folder", "SkyR4Ridge_a")):toBe(nil)
			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere ~= nil):toBe(true)
			expect(atmosphere.Density):toBe(0.9)
			expect(atmosphere.Haze):toBe(7.5)
			expect(atmosphere.Color):toEqual({ R = 1, G = 0, B = 0 })
			expect(atmosphere.Decay):toEqual({ R = 0.5, G = 0.5, B = 0.5 })
			expect(pcall(adapter.appliers.a.restore)):toBe(true)
		end)

		t:it("creates then destroys a missing Sky and Atmosphere", function()
			mount(false)
			adapter.appliers.b.apply(nil)
			expect(find(Lighting, "Sky", "SkyR4_b") ~= nil):toBe(true)
			expect(find(Lighting, "Atmosphere") ~= nil):toBe(true)
			adapter.appliers.b.restore()
			expect(find(Lighting, "Sky")):toBe(nil)
			expect(find(Lighting, "Atmosphere")):toBe(nil)
			expect(find(Workspace, "Folder", "SkyR4Ridge_b")):toBe(nil)
		end)

		t:it("warns but does not throw when a Roblox face setter fails", function()
			thrownSkyFace = "SkyboxFt"
			local ok = pcall(function()
				adapter.appliers.c.apply(nil)
			end)
			expect(ok):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			local sky = find(Lighting, "Sky", "SkyR4_c")
			expect(sky ~= nil):toBe(true)
			expect(sky.SkyboxFt):toBe(nil)
			expect(sky.SkyboxBk):toBe("rbxassetid://" .. tostring(SkyMapR4.sets.c.ids.SkyboxBk))
			expect(find(Workspace, "Folder", "SkyR4Ridge_c") ~= nil):toBe(true)
			expect(pcall(adapter.appliers.c.restore)):toBe(true)
		end)
	end)
end
