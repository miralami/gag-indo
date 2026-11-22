--!nocheck
-- Sky spec (BUG-001): Roblox only renders Clouds parented under workspace.Terrain. Sky must create
-- or migrate the Clouds instance there, never leave one under Lighting, and skip the tween when
-- Terrain never appears.

return function(t, Env)
	local expect = t.expect
	local env, Lighting, Workspace, terrain, instances, tweens

	local function newInstance(className)
		local object = { ClassName = className }
		table.insert(instances, object)
		return object
	end

	local function findChild(parent, className)
		for _, object in instances do
			if object.Parent == parent and object.ClassName == className then
				return object
			end
		end
		return nil
	end

	local function countClass(className)
		local count = 0
		for _, object in instances do
			if object.ClassName == className then
				count += 1
			end
		end
		return count
	end

	local function cloudTweens()
		local list = {}
		for _, tween in tweens do
			if tween.object.ClassName == "Clouds" then
				table.insert(list, tween)
			end
		end
		return list
	end

	local function mountSky()
		local Sky = env:require("client/World/Sky")
		Sky.mount()
	end

	t:describe("Sky clouds (BUG-001)", function()
		t:beforeEach(function()
			env = Env.new()
			instances = {}
			tweens = {}

			Lighting = { ClassName = "Lighting", Name = "Lighting" }
			Lighting.FindFirstChildOfClass = function(self, className)
				return findChild(self, className)
			end

			Workspace = { ClassName = "Workspace", Name = "Workspace" }
			Workspace.FindFirstChildOfClass = function(self, className)
				return findChild(self, className)
			end
			Workspace.WaitForChild = function(self, name)
				if name == "Terrain" and terrain.Parent == self then
					return terrain
				end
				return nil
			end

			terrain = newInstance("Terrain")
			terrain.Parent = Workspace
			terrain.FindFirstChildOfClass = function(self, className)
				return findChild(self, className)
			end

			env.services.Lighting = Lighting
			env.services.Workspace = Workspace
			env.services.TweenService = {
				Create = function(_, object, _, goal)
					table.insert(tweens, { object = object, goal = goal })
					return { Play = function() end }
				end,
			}
			env.services.ReplicatedStorage.GetAttributeChangedSignal = function()
				return Env.newSignal()
			end
			env.globals.Instance = {
				new = function(className)
					return newInstance(className)
				end,
			}
			env.globals.TweenInfo = {
				new = function()
					return {}
				end,
			}
			env:mock("shared/Config/Seasons", {
				skyFor = function()
					return {
						clockTime = 14,
						brightness = 2,
						fogEnd = 500,
						fogColor = {},
						ambient = {},
						outdoorAmbient = {},
						colorShiftTop = {},
						colorShiftBottom = {},
						atmosphereDensity = 0.3,
						atmosphereHaze = 1,
						atmosphereColor = {},
						atmosphereDecay = {},
						tint = {},
						saturation = 0,
						contrast = 0,
						bloom = 1,
						sunRays = 0.2,
						cloudCover = 0.55,
					}
				end,
			})
		end)

		t:it("creates Clouds under workspace.Terrain and never under Lighting", function()
			mountSky()

			expect(countClass("Clouds")):toBe(1)
			local clouds = findChild(terrain, "Clouds")
			expect(clouds ~= nil):toBe(true)
			expect(findChild(Lighting, "Clouds")):toBe(nil)
		end)

		t:it("tweens the Terrain-parented Clouds to the preset cover", function()
			mountSky()

			local list = cloudTweens()
			expect(#list):toBe(1)
			expect(list[1].object.Parent == terrain):toBe(true)
			expect(list[1].goal.Cover):toBe(0.55)
		end)

		t:it("migrates a legacy Clouds from Lighting instead of creating a second one", function()
			local legacy = newInstance("Clouds")
			legacy.Parent = Lighting

			mountSky()

			expect(countClass("Clouds")):toBe(1)
			expect(legacy.Parent == terrain):toBe(true)
			expect(findChild(Lighting, "Clouds")):toBe(nil)
			expect(#cloudTweens()):toBe(1)
			expect(cloudTweens()[1].object == legacy):toBe(true)
		end)

		t:it("creates no Clouds and skips the tween when Terrain never appears", function()
			terrain.Parent = nil

			mountSky()

			expect(countClass("Clouds")):toBe(0)
			expect(findChild(Lighting, "Clouds")):toBe(nil)
			expect(#cloudTweens()):toBe(0)
		end)

		t:it("creates and maintains a Sky instance under Lighting with the approved sky_r6_e faces", function()
			mountSky()

			local sky = findChild(Lighting, "Sky")
			local ids = env:require("shared/SkyMapR6").sets.e.ids
			expect(sky ~= nil):toBe(true)
			expect(sky.SkyboxBk):toBe("rbxassetid://" .. ids.SkyboxBk)
			expect(sky.SkyboxDn):toBe("rbxassetid://" .. ids.SkyboxDn)
			expect(sky.SkyboxFt):toBe("rbxassetid://" .. ids.SkyboxFt)
			expect(sky.SkyboxLf):toBe("rbxassetid://" .. ids.SkyboxLf)
			expect(sky.SkyboxRt):toBe("rbxassetid://" .. ids.SkyboxRt)
			expect(sky.SkyboxUp):toBe("rbxassetid://" .. ids.SkyboxUp)
			expect(sky.CelestialBodiesShown):toBe(true)
			expect(Lighting.ExposureCompensation):toBe(0.08)
		end)

		t:it("tweens atmosphere Glare in apply", function()
			mountSky()

			local atmoTween
			for _, tween in tweens do
				if tween.object.ClassName == "Atmosphere" then
					atmoTween = tween
					break
				end
			end
			expect(atmoTween ~= nil):toBe(true)
			expect(atmoTween.goal.Glare ~= nil):toBe(true)
		end)
	end)
end
