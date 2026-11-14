--!nocheck
-- Details spec: the goods, sightline and floor lane builds one `Details` folder under the world, stays
-- inside the 220 part budget, rebuilds idempotently, keeps ground-level parts out of the road cross
-- (|x|<9 or |z|<9), keeps breakers clear of the walkways and of every ProximityPrompt (3 studs), and
-- mixes at least five materials. The real Props module is loaded; only Instance and Color3 are faked.

return function(t, Env)
	local expect = t.expect
	local env, Details, world, instances

	local PART_BUDGET = 220
	local ROAD_HALF_WIDTH = 9
	local LOW_Y = 2
	local WALKWAY = 3
	local MIN_MATERIALS = 5
	local BREAKER_PREFIXES = { "Hedge", "BreakerWall", "StackCrate" }

	-- Prompt parents (x0, x1, z0, z1) from Greybox.luau: Pasar counter, TengkulakGelap counter,
	-- RumahPakRT table, PosPolisi desk, Warung table. PosRonda has no prompt.
	local PROMPT_BOXES = {
		{ -7, 7, -2.5, 2.5 },
		{ -5, 5, -18, -14 },
		{ 27.5, 32.5, 17.5, 20.5 },
		{ -33, -27, 18.5, 21.5 },
		{ 27.5, 32.5, -23.5, -20.5 },
	}

	-- Walkway strips from the road to the hub prompts (x0, x1, z0, z1). No breaker may touch them.
	local WALKWAYS = {
		{ 28.5, 31.5, -20.5, -9 }, -- Warung
		{ 28.5, 31.5, 9, 17.5 }, -- Rumah Pak RT
		{ -31.5, -28.5, 9, 18.5 }, -- Pos Polisi
	}

	local function isBreaker(name)
		for _, prefix in BREAKER_PREFIXES do
			if string.sub(name, 1, #prefix) == prefix then
				return true
			end
		end
		return false
	end

	-- Overlap of a part's XZ footprint (centre +/- half size) with a box grown by `grow` studs.
	local function footprintHits(part, box, grow)
		local hx = part.Size.X / 2
		local hz = part.Size.Z / 2
		local px, pz = part.Position.X, part.Position.Z
		return px + hx > box[1] - grow
			and px - hx < box[2] + grow
			and pz + hz > box[3] - grow
			and pz - hz < box[4] + grow
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

	local function detailsFolders()
		local list = {}
		for _, object in instances do
			if object.ClassName == "Folder" and object.Name == "Details" and object.Parent == world and not object.Destroyed then
				table.insert(list, object)
			end
		end
		return list
	end

	local function detailsParts()
		local folder = detailsFolders()[1]
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
		return env:require("server/World/Details").build(world)
	end

	t:describe("Details set dressing", function()
		t:beforeEach(function()
			env = Env.new()
			instances = {}

			env.globals.Color3 = {
				fromHex = function(hex)
					return { hex = hex }
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

			Details = env:require("server/World/Details")
		end)

		t:it("build creates one Details folder under the world", function()
			build()
			expect(#detailsFolders()):toBe(1)
			expect(detailsFolders()[1].Parent == world):toBe(true)
		end)

		t:it("keeps the part count within the 220 budget and above zero", function()
			build()
			local count = #detailsParts()
			expect(count):toBeAtLeast(1)
			expect(count):toBeAtMost(PART_BUDGET)
		end)

		t:it("calling build twice leaves exactly one Details folder with the same parts", function()
			build()
			local firstCount = #detailsParts()
			build()
			expect(#detailsFolders()):toBe(1)
			expect(#detailsParts()):toBe(firstCount)
		end)

		t:it("every part is anchored, unqueryable, and has no light, particle or script", function()
			build()
			for _, part in detailsParts() do
				expect(part.Anchored):toBe(true)
				expect(part.CanQuery):toBe(false)
				expect(part.ClassName == "PointLight" or part.ClassName == "ParticleEmitter" or part.ClassName == "Script"):toBe(false)
			end
		end)

		t:it("only hedges, walls and crate stacks collide", function()
			build()
			local wrong = {}
			for _, part in detailsParts() do
				local breaker = isBreaker(part.Name)
				if part.CanCollide ~= breaker then
					table.insert(wrong, part.Name)
				end
			end
			expect(table.concat(wrong, ",")):toBe("")
		end)

		t:it("keeps ground-level parts out of the road cross", function()
			build()
			local offenders = {}
			for _, part in detailsParts() do
				local at = part.Position
				local onCross = math.abs(at.X) < ROAD_HALF_WIDTH or math.abs(at.Z) < ROAD_HALF_WIDTH
				if at.Y < LOW_Y and onCross then
					table.insert(offenders, part.Name)
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps breakers out of every walkway strip", function()
			build()
			local offenders = {}
			for _, part in detailsParts() do
				if isBreaker(part.Name) then
					for _, box in WALKWAYS do
						if footprintHits(part, box, 0) then
							table.insert(offenders, part.Name)
						end
					end
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps breakers at least 3 studs from every ProximityPrompt parent", function()
			build()
			local offenders = {}
			for _, part in detailsParts() do
				if isBreaker(part.Name) then
					for _, box in PROMPT_BOXES do
						if footprintHits(part, box, WALKWAY) then
							table.insert(offenders, part.Name)
						end
					end
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("uses at least five distinct materials", function()
			build()
			local seen = {}
			local count = 0
			for _, part in detailsParts() do
				if not seen[part.Material] then
					seen[part.Material] = true
					count += 1
				end
			end
			expect(count):toBeAtLeast(MIN_MATERIALS)
		end)
	end)
end
