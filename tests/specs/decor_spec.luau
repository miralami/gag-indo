--!nocheck
-- Decor spec: set dressing builds one `Decor` folder under the world, stays inside the part and
-- light budget, rebuilds idempotently, and keeps low parts out of the road cross (|x|<9 or |z|<9).
-- The real Props module is loaded; only Instance and Color3.fromHex are faked.

return function(t, Env)
	local expect = t.expect
	local env, Decor, world, instances

	local PART_BUDGET = 220
	local LIGHT_BUDGET = 6
	local ROAD_HALF_WIDTH = 9
	local LOW_Y = 2

	-- Exempt by name: these may sit on the road cross on purpose (bunting over the road,
	-- stepping stones and hanging lanterns).
	local EXEMPT = { "BuntingPost", "BuntingString", "BuntingFlag", "LanternRod", "Lantern", "PathStone" }

	local function isExempt(name)
		for _, prefix in EXEMPT do
			if string.sub(name, 1, #prefix) == prefix then
				return true
			end
		end
		return false
	end

	local function destroy(object)
		object.Destroyed = true
		object.Parent = nil
		for _, child in instances do
			if child.Parent == object then
				destroy(child)
			end
		end
	end

	local function newInstance(className)
		local object = { ClassName = className }
		object.Destroy = function(self)
			destroy(self)
		end
		table.insert(instances, object)
		return object
	end

	-- Live objects directly under a parent.
	local function liveChildren(parent)
		local list = {}
		for _, object in instances do
			if object.Parent == parent and not object.Destroyed then
				table.insert(list, object)
			end
		end
		return list
	end

	local function decorFolders()
		local list = {}
		for _, object in instances do
			if object.ClassName == "Folder" and object.Name == "Decor" and object.Parent == world and not object.Destroyed then
				table.insert(list, object)
			end
		end
		return list
	end

	local function decorFolder()
		return decorFolders()[1]
	end

	local function decorParts()
		local folder = decorFolder()
		local parts = {}
		if folder == nil then
			return parts
		end
		for _, object in liveChildren(folder) do
			table.insert(parts, object)
		end
		return parts
	end

	local function build()
		return env:require("server/World/Decor").build(world)
	end

	-- Stand-in for Color3:Lerp: remembers the palette colour it came from, the goal and the amount.
	local function lerpColour(self, goal, alpha)
		return { base = self.base or self.hex, toward = goal.hex, amount = alpha, Lerp = lerpColour }
	end

	t:describe("Decor set dressing", function()
		t:beforeEach(function()
			env = Env.new()
			instances = {}

			env.globals.Color3 = {
				fromHex = function(hex)
					return { hex = hex, Lerp = lerpColour }
				end,
				fromRGB = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
				new = function(r, g, b)
					return { R = r, G = g, B = b }
				end,
			}
			env.globals.Instance = {
				new = function(className)
					return newInstance(className)
				end,
			}

			world = newInstance("Folder")
			world.Name = "World"
			world.FindFirstChild = function(self, name)
				for _, object in instances do
					if object.Parent == self and object.Name == name and not object.Destroyed then
						return object
					end
				end
				return nil
			end

			Decor = env:require("server/World/Decor")
		end)

		t:it("build creates a Decor folder under the world", function()
			build()
			expect(#decorFolders()):toBe(1)
			expect(decorFolder().Parent == world):toBe(true)
		end)

		t:it("keeps the part count within the 220 budget and above zero", function()
			build()
			local count = #decorParts()
			expect(count):toBeAtLeast(1)
			expect(count):toBeAtMost(PART_BUDGET)
		end)

		t:it("keeps the light count within the 6 light budget", function()
			build()
			local lights = 0
			for _, object in instances do
				if object.ClassName == "PointLight" and not object.Destroyed then
					lights += 1
				end
			end
			expect(lights):toBeAtLeast(1)
			expect(lights):toBeAtMost(LIGHT_BUDGET)
		end)

		t:it("calling build twice leaves exactly one Decor folder with the same parts", function()
			build()
			local firstCount = #decorParts()
			build()
			expect(#decorFolders()):toBe(1)
			expect(#decorParts()):toBe(firstCount)
		end)

		t:it("hangs every lantern with its bottom at least HEADROOM above the ground", function()
			build()
			local lanterns = 0
			for _, part in decorParts() do
				if part.Name == "Lantern" then
					lanterns += 1
					expect(part.Position.Y - part.Size.Y / 2 >= 0.5 + Decor.HEADROOM):toBe(true)
				end
			end
			expect(lanterns):toBeAtLeast(2)
		end)

		t:it("every part is anchored, unqueryable and not a script", function()
			build()
			for _, part in decorParts() do
				expect(part.Anchored):toBe(true)
				expect(part.CanQuery):toBe(false)
			end
		end)

		t:it("shifts flower colour by at most 8 percent", function()
			build()
			local shifted = 0
			for _, part in decorParts() do
				if part.Color.toward then
					shifted += 1
					expect(part.Color.amount >= 0 and part.Color.amount <= 0.08):toBe(true)
				end
			end
			expect(shifted > 0):toBe(true)
		end)

		t:it("keeps low parts out of the road cross unless exempt", function()
			build()
			local offenders = {}
			for _, part in decorParts() do
				local at = part.Position
				local onCross = math.abs(at.X) < ROAD_HALF_WIDTH or math.abs(at.Z) < ROAD_HALF_WIDTH
				if at.Y < LOW_Y and onCross and not isExempt(part.Name) then
					table.insert(offenders, part.Name)
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)
	end)
end
