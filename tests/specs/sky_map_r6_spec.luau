--!nocheck
-- WORK_QUEUE section J item 44: the six round-6 Creator Store sky candidates.
-- Locks the exact real face/model IDs, the shared atmosphere/effects/camera data,
-- the applier mechanics (face application, sun, effect/cloud save+restore, no
-- parts), and the registry/review wiring. No visual verdict and no Studio claim.

local fs = require("@lune/fs")

local FACES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

local MODELS = {
	a = { 4607457995, "Realistic Sky", "Xeksworld08" },
	b = { 10256505900, "Sky-Realistic", "Dev_Flowey" },
	c = { 9589448285, "Realistic Clear Sky", "HeyItzDaredevil" },
	d = { 11219565245, "Realistic Clear Skies (SKYBOX)", "TrainMaker6" },
	e = { 71778157196658, "Blue Sky W Scattered Clouds Daytime Skybox Light", "Rozosere48" },
	f = { 79778158338852, "Sunless blue sky skybox realistic clouds", "f0xz08" },
}

local IDS = {
	a = { 150335574, 150335585, 150335628, 150335620, 150335610, 150335642 },
	b = { 144933338, 144931530, 144933262, 144933244, 144933299, 144931564 },
	c = { 9544505500, 9544547905, 9544504852, 9544547694, 9544547542, 9544547398 },
	d = { 91458002, 91457980, 91458024, 91458024, 91458024, 91458002 },
	e = { 2835173905, 2493829793, 2835177931, 2835174704, 2835177433, 2835175409 },
	f = { 591058823, 591059876, 591058104, 591057861, 591057625, 591059642 },
}

return function(t, Env, _Fakes)
	local expect = t.expect

	t:describe("SkyMapR6 pure data", function()
		local SkyMapR6
		t:beforeEach(function()
			SkyMapR6 = Env.new():require("shared/SkyMapR6")
		end)

		t:it("locks the six real Creator Store models, names, creators and URLs", function()
			local count = 0
			for _, key in ipairs(SkyMapR6.order) do
				count += 1
				expect(SkyMapR6.sets[key] ~= nil):toBe(true)
				local model = MODELS[key]
				expect(model ~= nil):toBe(true)
				local set = SkyMapR6.sets[key]
				expect(set.modelId):toBe(model[1])
				expect(set.label):toBe(model[2])
				expect(set.creator):toBe(model[3])
				expect(set.storeUrl):toBe("https://create.roblox.com/store/asset/" .. tostring(model[1]))
				expect(set.source):toBe("Creator Store free Model")
				expect(string.find(set.licence, "free", 1, true) ~= nil):toBe(true)
			end
			expect(count):toBe(6)
			expect(#SkyMapR6.order):toBe(6)
			expect(SkyMapR6.sets.g):toBe(nil)
		end)

		t:it("locks all 36 exact face IDs, including the repeated d faces", function()
			for key, expected in IDS do
				local set = SkyMapR6.sets[key]
				local faces = 0
				for index, face in ipairs(FACES) do
					local id = set.ids[face]
					expect(id):toBe(expected[index])
					expect(type(id)):toBe("number")
					expect(id > 0):toBe(true)
					faces += 1
				end
				expect(faces):toBe(6)
			end
			expect(SkyMapR6.faceCount()):toBe(6)
			expect(SkyMapR6.faceKeys):toEqual(FACES)
			-- d really repeats Ft/Lf/Rt; this is the loaded model, not a bug to fix.
			expect(SkyMapR6.sets.d.ids.SkyboxFt):toBe(SkyMapR6.sets.d.ids.SkyboxLf)
			expect(SkyMapR6.sets.d.ids.SkyboxLf):toBe(SkyMapR6.sets.d.ids.SkyboxRt)
		end)

		t:it("holds the shared atmosphere, effects and camera, with no engine API", function()
			expect(SkyMapR6.atmosphere.Density):toBe(0.30)
			expect(SkyMapR6.atmosphere.Haze):toBe(1.6)
			expect(SkyMapR6.atmosphere.Color):toEqual({ 240, 236, 224 })
			expect(SkyMapR6.atmosphere.Decay):toEqual({ 150, 190, 220 })
			expect(SkyMapR6.atmosphere.Offset):toBe(0.65)
			expect(SkyMapR6.atmosphere.Glare):toBe(1.2)
			expect(SkyMapR6.cloudCover):toBe(0.5)

			local fx = SkyMapR6.effects
			expect(fx.celestialBodiesShown):toBe(true)
			expect(fx.sunRays):toEqual({ Intensity = 0.18, Spread = 0.35, Enabled = true })
			expect(fx.bloom):toEqual({ Intensity = 0.12, Threshold = 0.95, Size = 18, Enabled = true })
			expect(fx.colorCorrection):toEqual({
				Saturation = 0.08,
				Contrast = 0.02,
				TintColor = { 1, 1, 1 },
				Brightness = 0,
				Enabled = true,
			})

			local eye, look = SkyMapR6.savedCamera.eye, SkyMapR6.savedCamera.look
			expect(eye):toEqual({ -14, 9, 42 })
			expect(look):toEqual({ -14, 28.6, -12 })
			local horizontal = math.sqrt((look[1] - eye[1]) ^ 2 + (look[3] - eye[3]) ^ 2)
			local pitch = math.deg(math.atan2(look[2] - eye[2], horizontal))
			expect(pitch >= 18 and pitch <= 22):toBe(true)

			local src = fs.readFile("src/shared/SkyMapR6.luau")
			expect(string.find(src, "rbxasset", 1, true)):toBe(nil)
			expect(string.find(src, "Color3", 1, true)):toBe(nil)
			expect(string.find(src, "Vector3", 1, true)):toBe(nil)
			expect(string.find(src, "Instance", 1, true)):toBe(nil)
			expect(string.find(src, "game:", 1, true)):toBe(nil)
			expect(string.find(src, "SkyboxImage", 1, true)):toBe(nil)
			expect(string.find(src, "tostring(", 1, true)):toBe(nil) -- no ID construction
		end)
	end)

	t:describe("LookDevSkyR6 appliers", function()
		local env, SkyMapR6, instances, Lighting, Workspace, registered, thrownSkyFace
		local terrain, clouds, oldSky, oldAtmosphere, oldSunRays, oldBloom, oldCC

		local function newInstance(className)
			local fields = {
				ClassName = className,
				Name = className,
				Parent = nil,
				Destroyed = false,
				CelestialBodiesShown = false,
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
			terrain, clouds = nil, nil
			oldSky, oldAtmosphere, oldSunRays, oldBloom, oldCC = nil, nil, nil, nil, nil

			Lighting = service("Lighting")
			Workspace = service("Workspace")
			env.services.Lighting = Lighting
			env.services.Workspace = Workspace

			env.globals.Color3 = {
				fromRGB = function(r, g, b)
					return { R = r / 255, G = g / 255, B = b / 255 }
				end,
				new = function(r, g, b)
					return { R = r, G = g, B = b }
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
				oldSky = newInstance("Sky")
				oldSky.Name = "OriginalSky"
				oldSky.Parent = Lighting
				for _, face in ipairs(FACES) do
					oldSky[face] = "rbxassetid://original-" .. face
				end
				oldAtmosphere = newInstance("Atmosphere")
				oldAtmosphere.Parent = Lighting
				oldAtmosphere.Density = 0.9
				oldAtmosphere.Haze = 7.5
				oldAtmosphere.Color = { R = 1, G = 0, B = 0 }
				oldAtmosphere.Decay = { R = 0.5, G = 0.5, B = 0.5 }
				oldAtmosphere.Offset = 0.2
				oldAtmosphere.Glare = 3.1
				oldSunRays = newInstance("SunRaysEffect")
				oldSunRays.Parent = Lighting
				oldSunRays.Intensity = 0.7
				oldSunRays.Spread = 0.9
				oldSunRays.Enabled = false
				oldBloom = newInstance("BloomEffect")
				oldBloom.Parent = Lighting
				oldBloom.Intensity = 0.6
				oldBloom.Threshold = 1.1
				oldBloom.Size = 22
				oldBloom.Enabled = false
				oldCC = newInstance("ColorCorrectionEffect")
				oldCC.Parent = Lighting
				oldCC.Saturation = 0.5
				oldCC.Contrast = 0.3
				oldCC.TintColor = { R = 0.8, G = 0.8, B = 0.8 }
				oldCC.Brightness = 0.4
				oldCC.Enabled = false
			end

			SkyMapR6 = env:require("shared/SkyMapR6")
			env:require("client/World/LookDevSkyR6")
		end

		t:beforeEach(function()
			mount(true, true)
		end)

		t:it("registers exactly six candidates, via a make factory, with no ID literal", function()
			local count = 0
			for id in registered do
				count += 1
				expect(string.sub(id, 1, 7)):toBe("sky_r6_")
				expect(type(registered[id].apply)):toBe("function")
				expect(type(registered[id].restore)):toBe("function")
			end
			expect(count):toBe(6)
			for _, key in ipairs(SkyMapR6.order) do
				expect(registered["sky_r6_" .. key] ~= nil):toBe(true)
			end
			local src = fs.readFile("src/client/World/LookDevSkyR6.luau")
			expect(string.find(src, "local function make(", 1, true) ~= nil):toBe(true)
			expect(string.find(src, 'LookDev.register("sky_r6_" .. key', 1, true) ~= nil):toBe(true)
			expect(string.find(src, "applyCubeTopFaceSeamFix", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "CelestialBodiesShown", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "SunRaysEffect", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "BloomEffect", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "ColorCorrectionEffect", 1, true) ~= nil):toBe(true)
			expect(string.find(src, "%d%d%d%d%d%d%d")):toBe(nil)
			expect(string.find(src, "rbxassetid://%d")):toBe(nil)
			expect(string.find(src, "SkyboxImage", 1, true)):toBe(nil)
			expect(string.find(src, 'Instance.new("Part"', 1, true)):toBe(nil)
			expect(string.find(src, "ridgeAt", 1, true)):toBe(nil)
		end)

		t:it("applies all six faces, the seam fix and the sun flag for every candidate", function()
			for _, key in ipairs(SkyMapR6.order) do
				local applier = registered["sky_r6_" .. key]
				applier.apply(nil)
				local sky = find(Lighting, "Sky", "SkyR6_" .. key)
				expect(sky ~= nil):toBe(true)
				local set = SkyMapR6.sets[key]
				for _, face in ipairs(FACES) do
					expect(sky[face]):toBe("rbxassetid://" .. tostring(set.ids[face]))
				end
				expect(sky.SkyboxUp):toBe("rbxassetid://" .. tostring(set.ids.SkyboxUp))
				expect(sky.CelestialBodiesShown):toBe(true)
				expect(oldSky.Parent):toBe(nil)
				expect(countParts()):toBe(0)
				applier.restore()
				expect(oldSky.Parent):toBe(Lighting)
				expect(find(Lighting, "Sky", "SkyR6_" .. key)):toBe(nil)
			end
		end)

		t:it("applies the shared atmosphere + effect stack and restores every touched property", function()
			local applier = registered.sky_r6_a
			applier.apply(nil)

			local atmosphere = find(Lighting, "Atmosphere")
			expect(atmosphere.Density):toBe(SkyMapR6.atmosphere.Density)
			expect(atmosphere.Haze):toBe(SkyMapR6.atmosphere.Haze)
			expect(atmosphere.Color):toEqual({ R = 240 / 255, G = 236 / 255, B = 224 / 255 })
			expect(atmosphere.Decay):toEqual({ R = 150 / 255, G = 190 / 255, B = 220 / 255 })
			expect(atmosphere.Offset):toBe(0.65)
			expect(atmosphere.Glare):toBe(1.2)

			local fx = SkyMapR6.effects
			expect(oldSunRays.Intensity):toBe(fx.sunRays.Intensity)
			expect(oldSunRays.Spread):toBe(fx.sunRays.Spread)
			expect(oldSunRays.Enabled):toBe(fx.sunRays.Enabled)
			expect(oldBloom.Intensity):toBe(fx.bloom.Intensity)
			expect(oldBloom.Threshold):toBe(fx.bloom.Threshold)
			expect(oldBloom.Size):toBe(fx.bloom.Size)
			expect(oldBloom.Enabled):toBe(fx.bloom.Enabled)
			expect(oldCC.Saturation):toBe(fx.colorCorrection.Saturation)
			expect(oldCC.Contrast):toBe(fx.colorCorrection.Contrast)
			expect(oldCC.TintColor):toEqual({ R = 1, G = 1, B = 1 })
			expect(oldCC.Brightness):toBe(fx.colorCorrection.Brightness)
			expect(oldCC.Enabled):toBe(fx.colorCorrection.Enabled)

			applier.restore()
			expect(atmosphere.Density):toBe(0.9)
			expect(atmosphere.Haze):toBe(7.5)
			expect(atmosphere.Color):toEqual({ R = 1, G = 0, B = 0 })
			expect(atmosphere.Decay):toEqual({ R = 0.5, G = 0.5, B = 0.5 })
			expect(atmosphere.Offset):toBe(0.2)
			expect(atmosphere.Glare):toBe(3.1)
			expect(oldSunRays.Intensity):toBe(0.7)
			expect(oldSunRays.Spread):toBe(0.9)
			expect(oldSunRays.Enabled):toBe(false)
			expect(oldBloom.Intensity):toBe(0.6)
			expect(oldBloom.Threshold):toBe(1.1)
			expect(oldBloom.Size):toBe(22)
			expect(oldBloom.Enabled):toBe(false)
			expect(oldCC.Saturation):toBe(0.5)
			expect(oldCC.Contrast):toBe(0.3)
			expect(oldCC.TintColor):toEqual({ R = 0.8, G = 0.8, B = 0.8 })
			expect(oldCC.Brightness):toBe(0.4)
			expect(oldCC.Enabled):toBe(false)
			expect(pcall(applier.restore)):toBe(true)
		end)

		t:it("reuses existing effect instances and destroys only created ones", function()
			local applier = registered.sky_r6_b
			local effectCount = 3
			applier.apply(nil)
			expect(find(Lighting, "SunRaysEffect") ~= nil):toBe(true)
			expect(find(Lighting, "BloomEffect") ~= nil):toBe(true)
			expect(find(Lighting, "ColorCorrectionEffect") ~= nil):toBe(true)
			local reusedCount = 0
			for _, object in ipairs(instances) do
				if
					not object.Destroyed
					and (
						object.ClassName == "SunRaysEffect"
						or object.ClassName == "BloomEffect"
						or object.ClassName == "ColorCorrectionEffect"
					)
				then
					reusedCount += 1
				end
			end
			expect(reusedCount):toBe(effectCount)
			applier.restore()
			expect(oldSunRays.Destroyed):toBe(false)
			expect(oldBloom.Destroyed):toBe(false)
			expect(oldCC.Destroyed):toBe(false)
			expect(find(Lighting, "Sky", "SkyR6_b")):toBe(nil)
			-- created Sky/Atmosphere were destroyed, originals remain
			expect(oldAtmosphere.Destroyed):toBe(false)
		end)

		t:it("lowers Terrain Clouds.Cover while active and restores the exact prior value", function()
			expect(clouds.Cover):toBe(0.85)
			local applier = registered.sky_r6_c
			applier.apply(nil)
			expect(clouds.Cover):toBe(SkyMapR6.cloudCover)
			expect(clouds.Cover):toBe(0.5)
			applier.restore()
			expect(clouds.Cover):toBe(0.85)
		end)

		t:it("warns but does not throw on a failing Sky setter", function()
			thrownSkyFace = "SkyboxFt"
			local applier = registered.sky_r6_d
			local ok = pcall(function()
				applier.apply(nil)
			end)
			expect(ok):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			local sky = find(Lighting, "Sky", "SkyR6_d")
			expect(sky ~= nil):toBe(true)
			expect(sky.SkyboxFt):toBe(nil)
			expect(sky.SkyboxUp):toBe("rbxassetid://" .. tostring(SkyMapR6.sets.d.ids.SkyboxUp))
			expect(pcall(applier.restore)):toBe(true)
		end)

		t:it("is a graceful no-op for missing Terrain/Clouds and missing effects", function()
			mount(false, false)
			expect(terrain):toBe(nil)
			expect(clouds):toBe(nil)
			local applier = registered.sky_r6_e
			expect(pcall(applier.apply, nil)):toBe(true)
			expect(find(Lighting, "Sky", "SkyR6_e") ~= nil):toBe(true)
			expect(find(Lighting, "SunRaysEffect") ~= nil):toBe(true)
			expect(find(Lighting, "BloomEffect") ~= nil):toBe(true)
			expect(find(Lighting, "ColorCorrectionEffect") ~= nil):toBe(true)
			expect(countParts()):toBe(0)
			expect(pcall(applier.restore)):toBe(true)
			expect(find(Lighting, "SunRaysEffect")):toBe(nil)
			expect(find(Lighting, "BloomEffect")):toBe(nil)
			expect(find(Lighting, "ColorCorrectionEffect")):toBe(nil)
		end)
	end)

	t:describe("round-6 registry and review wiring", function()
		t:it("registers 57 candidates including all six round-6 skies", function()
			local env = Env.new()
			local LookDev = env:require("shared/LookDev")
			local Review = env:require("shared/LookDevReview")
			expect(#LookDev.IDS):toBe(90)
			for _, key in ipairs({ "a", "b", "c", "d", "e", "f" }) do
				local id = "sky_r6_" .. key
				expect(LookDev.isCandidate(id)):toBe(true)
				expect(LookDev.candidates[id].status):toBe("candidate, awaiting designer yes")
				local plan = LookDev.plan(id)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.SkyMapR6.sets." .. key .. ".ids")
				expect(plan.faceCount):toBe(6)
				local entry = Review.pathsFor(id)
				expect(entry.datamodel):toBe("client")
				expect(entry.path):toEqual({ "World", "LookDevSkyR6" })
			end
			local count = 0
			for _ in Review.paths do
				count += 1
			end
			expect(count):toBe(90)
			expect(count):toBe(#LookDev.IDS)
		end)

		t:it("wires the applier into Main.client with a failure-isolating pcall", function()
			local src = fs.readFile("src/client/Main.client.luau")
			expect(string.find(src, "pcall(require, script.Parent.World.LookDevSkyR6)", 1, true) ~= nil):toBe(true)
		end)

		t:it("documents provenance, camera, stack and blank verdicts", function()
			local readme = fs.readFile("docs/v2/visual/art/sky_r6/README.md")
			for key, model in pairs(MODELS) do
				expect(string.find(readme, tostring(model[1]), 1, true) ~= nil):toBe(true)
				expect(string.find(readme, model[2], 1, true) ~= nil):toBe(true)
				expect(string.find(readme, model[3], 1, true) ~= nil):toBe(true)
				expect(
					string.find(readme, "https://create.roblox.com/store/asset/" .. tostring(model[1]), 1, true) ~= nil
				):toBe(true)
				local setIds = IDS[key]
				for _, id in ipairs(setIds) do
					expect(string.find(readme, tostring(id), 1, true) ~= nil):toBe(true)
				end
				expect(string.find(readme, 'LookDev.enable("sky_r6_' .. key .. '")', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(readme, 'LookDevReview.enable("sky_r6_a", game)', 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "-14, 9, 42", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "-14, 28.6, -12", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "was graded", 1, true) ~= nil):toBe(true)
			expect(string.find(readme, "blank", 1, true) ~= nil):toBe(true)
		end)
	end)
end
