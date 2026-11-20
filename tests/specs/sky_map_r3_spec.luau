--!nocheck
-- WORK_QUEUE round 3 item 24 (sky half), item 28 bug 2: the real six-face CC0 ID map keyed by the
-- real Roblox Sky properties, the pure sky/atmosphere/ridge recipe and the client adapter. The
-- upload manifest still labels rows by the old face-file names, so those are mapped separately.
-- No visual verdict or Studio claim.

local fs = require("@lune/fs")

return function(t, Env, Fakes)
	local expect = t.expect
	local REAL_SKY_KEYS = {
		"SkyboxBk",
		"SkyboxDn",
		"SkyboxFt",
		"SkyboxLf",
		"SkyboxRt",
		"SkyboxUp",
	}
	local MANIFEST_FACES = {
		"SkyboxImageBack",
		"SkyboxImageBottom",
		"SkyboxImageFront",
		"SkyboxImageLeft",
		"SkyboxImageRight",
		"SkyboxImageTop",
	}
	local FACE_TO_SKY = {
		SkyboxImageBack = "SkyboxBk",
		SkyboxImageBottom = "SkyboxDn",
		SkyboxImageFront = "SkyboxFt",
		SkyboxImageLeft = "SkyboxLf",
		SkyboxImageRight = "SkyboxRt",
		SkyboxImageTop = "SkyboxUp",
	}

	t:describe("SkyMapR3 recipe", function()
		local SkyMapR3, Visuals
		t:beforeEach(function()
			local env = Env.new()
			SkyMapR3 = env:require("shared/SkyMapR3")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("has exactly six unique numeric IDs keyed by the six real Sky properties", function()
			local count, seen = 0, {}
			for key, id in SkyMapR3.ids do
				count += 1
				expect(table.find(REAL_SKY_KEYS, key) ~= nil):toBe(true)
				expect(type(id)):toBe("number")
				expect(#tostring(id) >= 12 and tostring(id):match("^%d+$") ~= nil):toBe(true)
				expect(seen[id]):toBe(nil)
				seen[id] = true
			end
			for _, old in ipairs(MANIFEST_FACES) do
				expect(SkyMapR3.ids[old]):toBe(nil)
			end
			expect(count):toBe(6)
			expect(SkyMapR3.faceCount()):toBe(6)
		end)

		t:it("exports the proposed Atmosphere values as a non-empty pure table", function()
			local atmosphere = SkyMapR3.atmosphere
			expect(type(atmosphere)):toBe("table")
			expect(atmosphere.Density):toBe(0.22)
			expect(atmosphere.Decay):toEqual({ 120, 150, 160 })
			expect(atmosphere.Offset):toBe(0.55)
			expect(atmosphere.Glare):toBe(1.2)
			expect(atmosphere.Haze):toBe(2.4)
			expect(atmosphere.Color):toEqual({ 214, 223, 230 })
			local count = 0
			for key, value in atmosphere do
				count += 1
				expect(type(key) == "string" and #key > 0):toBe(true)
				expect(type(value) == "number" or type(value) == "table"):toBe(true)
				if type(value) == "table" then
					expect(#value):toBe(3)
					for _, channel in value do
						expect(type(channel)):toBe("number")
					end
				end
			end
			expect(count):toBe(6)
		end)

		t:it("exports a 12-wedge pure ridge inside the re-staged corner footprint", function()
			expect(#SkyMapR3.ridge):toBe(12)
			local origin = SkyMapR3.STAGING_ORIGIN
			expect(origin.x):toBe(-14)
			expect(origin.z):toBe(-12)
			local names = {}
			for _, wedge in ipairs(SkyMapR3.ridge) do
				expect(type(wedge.name) == "string" and #wedge.name > 0):toBe(true)
				expect(names[wedge.name]):toBe(nil)
				names[wedge.name] = true
				expect(wedge.shape):toBe("Wedge")
				expect(Visuals.palette[wedge.color] ~= nil):toBe(true)
				expect(#wedge.position):toBe(3)
				expect(#wedge.size):toBe(3)
				expect(wedge.position[1] >= origin.x - 30 and wedge.position[1] <= origin.x + 30):toBe(true)
				expect(wedge.position[2] >= 8 and wedge.position[2] <= 16):toBe(true)
				expect(wedge.position[3] >= origin.z - 30 and wedge.position[3] <= origin.z + 30):toBe(true)
				for _, n in wedge.size do
					expect(type(n) == "number"):toBe(true)
				end
				expect(type(wedge.yaw)):toBe("number")
			end
		end)

		t:it("keeps the pure module free of Roblox APIs and asset URLs", function()
			local src = fs.readFile("src/shared/SkyMapR3.luau")
			-- Comments document the intended Color3 conversion; guard the executable code only.
			local code = string.gsub(src, "%-%-[^\n]*", "")
			expect(string.find(code, "game:", 1, true)):toBe(nil)
			expect(string.find(code, "Instance.new", 1, true)):toBe(nil)
			expect(string.find(code, "Color3", 1, true)):toBe(nil)
			expect(string.find(code, "Vector3", 1, true)):toBe(nil)
			expect(string.find(code, "rbxasset", 1, true)):toBe(nil)
		end)
	end)

	t:describe("LookDevSkyR3 adapter", function()
		local env, SkyMapR3, adapter, instances, Lighting, Workspace, thrownSkyFace

		local function newInstance(className)
			local fields = {
				ClassName = className,
				Name = className,
				Parent = nil,
				Destroyed = false,
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

			if withOriginals then
				local oldSky = newInstance("Sky")
				oldSky.Name = "OriginalSky"
				oldSky.Parent = Lighting
				oldSky.SkyboxFt = "rbxassetid://original"
				local oldAtmosphere = newInstance("Atmosphere")
				oldAtmosphere.Parent = Lighting
				oldAtmosphere.Density = 0.9
				oldAtmosphere.Haze = 7.5
				oldAtmosphere.Color = { R = 1, G = 0, B = 0 }
			end

			SkyMapR3 = env:require("shared/SkyMapR3")
			adapter = env:require("client/World/LookDevSkyR3")
		end

		t:beforeEach(function()
			mount(true)
		end)

		t:it("registers the literal sky_r3 id and holds no asset ID literal", function()
			local src = fs.readFile("src/client/World/LookDevSkyR3.luau")
			expect(string.find(src, 'LookDev.register("sky_r3", { apply = apply, restore = restore })', 1, true) ~= nil):toBe(
				true
			)
			expect(string.find(src, "SkyMapR3.ids", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "SkyMapR3.atmosphere", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "SkyMapR3.ridge", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
		end)

		t:it("applies all six face URLs, the atmosphere values and the ridge parts", function()
			adapter.apply(nil)
			local sky = find(Lighting, "Sky", "SkyR3")
			expect(sky ~= nil):toBe(true)
			for _, key in ipairs(REAL_SKY_KEYS) do
				expect(sky[key]):toBe("rbxassetid://" .. tostring(SkyMapR3.ids[key]))
			end
			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere ~= nil):toBe(true)
			expect(atmosphere.Density):toBe(0.22)
			expect(atmosphere.Haze):toBe(2.4)
			expect(atmosphere.Color):toEqual({ R = 214 / 255, G = 223 / 255, B = 230 / 255 })
			expect(atmosphere.Decay):toEqual({ R = 120 / 255, G = 150 / 255, B = 160 / 255 })
			local folder = find(Workspace, "Folder", "SkyR3Ridge")
			expect(folder ~= nil):toBe(true)
			expect(countParts(folder)):toBe(#SkyMapR3.ridge)
		end)

		t:it("restores the original Sky child and every saved Atmosphere value on disable", function()
			local oldSky = find(Lighting, "Sky", "OriginalSky")
			expect(oldSky ~= nil):toBe(true)
			adapter.apply(nil)
			expect(oldSky.Parent):toBe(nil)
			adapter.restore()
			expect(oldSky.Parent):toBe(Lighting)
			expect(oldSky.SkyboxFt):toBe("rbxassetid://original")
			expect(find(Lighting, "Sky", "SkyR3")):toBe(nil)
			expect(find(Workspace, "Folder", "SkyR3Ridge")):toBe(nil)
			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere ~= nil):toBe(true)
			expect(atmosphere.Density):toBe(0.9)
			expect(atmosphere.Haze):toBe(7.5)
			expect(atmosphere.Color):toEqual({ R = 1, G = 0, B = 0 })
		end)

		t:it("creates and then destroys a missing Sky and Atmosphere", function()
			mount(false)
			adapter.apply(nil)
			expect(find(Lighting, "Sky", "SkyR3") ~= nil):toBe(true)
			expect(find(Lighting, "Atmosphere") ~= nil):toBe(true)
			adapter.restore()
			expect(find(Lighting, "Sky")):toBe(nil)
			expect(find(Lighting, "Atmosphere")):toBe(nil)
			expect(find(Workspace, "Folder", "SkyR3Ridge")):toBe(nil)
		end)

		t:it("warns but does not throw when a Roblox property setter fails", function()
			thrownSkyFace = "SkyboxFt"
			local ok = pcall(function()
				adapter.apply(nil)
			end)
			expect(ok):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			local sky = find(Lighting, "Sky", "SkyR3")
			expect(sky ~= nil):toBe(true)
			expect(sky.SkyboxFt):toBe(nil)
			expect(sky.SkyboxBk):toBe("rbxassetid://" .. tostring(SkyMapR3.ids.SkyboxBk))
			expect(find(Workspace, "Folder", "SkyR3Ridge") ~= nil):toBe(true)
			expect(pcall(adapter.restore)):toBe(true)
		end)
	end)

	t:describe("SkyMapR3 upload manifest", function()
		t:it("has six ROBLOX_API_KEY Image rows matching the six face IDs", function()
			local raw = fs.readFile("docs/v2/visual/art/sky_r3/upload_manifest.json")
			local _, routes = string.gsub(raw, '"upload_route": "ROBLOX_API_KEY"', "")
			local _, faces = string.gsub(raw, '"face":', "")
			local _, images = string.gsub(raw, '"asset_type": "Image"', "")
			expect(routes):toBe(6)
			expect(faces):toBe(6)
			expect(images):toBe(6)
			expect(string.find(raw, '"licence": "CC0', 1, true) ~= nil):toBe(true)
			local SkyMapR3 = Env.new():require("shared/SkyMapR3")
			local seen, seenCount = {}, 0
			for face, id in string.gmatch(raw, '"face":%s*"([^"]+)".-"asset_id":%s*"([^"]+)"') do
				expect(table.find(MANIFEST_FACES, face) ~= nil):toBe(true)
				expect(seen[face]):toBe(nil)
				seen[face] = true
				seenCount += 1
				expect(tonumber(id)):toBe(SkyMapR3.ids[FACE_TO_SKY[face]])
			end
			expect(seenCount):toBe(6)
		end)
	end)
end
