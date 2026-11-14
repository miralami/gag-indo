--!nocheck
-- Flora spec: bushes, rocks and grass tufts stay inside the 200-part budget, keep off the road cross,
-- the river, the sawah, the hub rings and the tree trunks, use palette colours only, and rebuild
-- idempotently. Canopies of Tree_N models are tagged WindShake with a WindSeed in range. The pure
-- Wind.offsetFor helper stays inside its limits. The real Props, Flora and Wind modules run; only
-- Instance, Color3.fromHex and CollectionService are faked.

return function(t, Env)
	local expect = t.expect
	local env, Flora, world, instances, tags

	local PART_BUDGET = 200
	local ROAD_HALF_WIDTH = 9
	local HUB_RADIUS = 8
	local TREE_CLEAR = 5
	local HUBS = { { 0, 0 }, { 30, 26 }, { 30, -26 }, { -30, -26 }, { -30, 26 }, { 0, -16 } }
	local SEED_MAX = 6.28
	local ROT_MAX = 3
	local OFFSET_MAX = 0.25

	local PALETTE_HEX = {
		"f3e9d2", "2b2118", "5b4a38", "f6c97a", "9bb25a", "6f8a3f", "a8452f",
		"a83226", "b98a5a", "c99a2e", "3b4f6b", "1f4e6b", "7652a8",
	}
	local PALETTE_SET = {}
	for _, hex in PALETTE_HEX do
		PALETTE_SET[hex] = true
	end

	-- Same tree spots as Greybox.TREE_XZ, so the trunk clearance is exercised with real positions.
	local TREE_XZ = {
		{ 20, 40 }, { 44, 40 }, { 54, 16 }, { 56, -18 }, { 48, -40 }, { 20, -40 }, { -20, -40 },
		{ -48, -36 }, { -56, 18 }, { -52, 36 }, { -20, 40 }, { -46, -18 }, { -24, 46 }, { 40, 52 },
	}

	local function destroy(object)
		object.Destroyed = true
		object.Parent = nil
		for _, child in instances do
			if child.Parent == object then
				destroy(child)
			end
		end
	end

	local function liveChildren(parent)
		local list = {}
		for _, object in instances do
			if object.Parent == parent and not object.Destroyed then
				table.insert(list, object)
			end
		end
		return list
	end

	local function newInstance(className)
		local object = { ClassName = className, Name = className, _attributes = {} }
		object.Destroy = function(self)
			destroy(self)
		end
		object.GetChildren = function(self)
			return liveChildren(self)
		end
		object.FindFirstChild = function(self, name)
			for _, child in liveChildren(self) do
				if child.Name == name then
					return child
				end
			end
			return nil
		end
		object.SetAttribute = function(self, name, value)
			self._attributes[name] = value
		end
		object.GetAttribute = function(self, name)
			return self._attributes[name]
		end
		table.insert(instances, object)
		return object
	end

	local function floraFolders()
		local list = {}
		for _, object in instances do
			if object.ClassName == "Folder" and object.Name == "Flora" and object.Parent == world and not object.Destroyed then
				table.insert(list, object)
			end
		end
		return list
	end

	local function floraParts()
		local folders = floraFolders()
		if folders[1] == nil then
			return {}
		end
		return liveChildren(folders[1])
	end

	local function addTree(index, spot)
		local tree = newInstance("Model")
		tree.Name = "Tree_" .. index
		tree.Parent = world
		local trunk = newInstance("Part")
		trunk.Name = "Trunk"
		trunk.Position = Env.Vector3.new(spot[1], 7, spot[2])
		trunk.Parent = tree
		for canopy = 1, 3 do
			local part = newInstance("Part")
			part.Name = "Canopy_" .. canopy
			part.Position = Env.Vector3.new(spot[1], 11, spot[2])
			part.Parent = tree
		end
		return tree
	end

	local function addTrees()
		for index, spot in TREE_XZ do
			addTree(index, spot)
		end
	end

	local function build()
		return env:require("server/World/Flora").build(world)
	end

	local function tagged(tag)
		local list = {}
		for _, entry in tags do
			if entry.tag == tag then
				table.insert(list, entry.object)
			end
		end
		return list
	end

	t:describe("Flora layered nature", function()
		t:beforeEach(function()
			env = Env.new()
			instances = {}
			tags = {}

			local colours = {}
			env.globals.Color3 = {
				fromHex = function(hex)
					colours[hex] = colours[hex] or { hex = hex }
					return colours[hex]
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
			env.services.CollectionService = {
				AddTag = function(_, object, tag)
					table.insert(tags, { object = object, tag = tag })
				end,
				GetTagged = function(_, tag)
					return tagged(tag)
				end,
			}

			world = newInstance("Folder")
			world.Name = "World"

			Flora = env:require("server/World/Flora")
		end)

		t:it("build creates one Flora folder under the world", function()
			build()
			expect(#floraFolders()):toBe(1)
			expect(floraFolders()[1].Parent == world):toBe(true)
		end)

		t:it("keeps the part count within the 200 budget and above zero", function()
			addTrees()
			build()
			local count = #floraParts()
			expect(count):toBeAtLeast(1)
			expect(count):toBeAtMost(PART_BUDGET)
		end)

		t:it("is idempotent: a second build leaves one folder with the same parts in the same places", function()
			addTrees()
			local function signature()
				local rows = {}
				for _, part in floraParts() do
					table.insert(rows, `{part.Name}@{part.Position.X},{part.Position.Z}`)
				end
				return table.concat(rows, ";")
			end
			build()
			local first = signature()
			local firstCount = #floraParts()
			build()
			expect(#floraFolders()):toBe(1)
			expect(#floraParts()):toBe(firstCount)
			expect(signature()):toBe(first)
		end)

		t:it("every part is anchored, not collidable, not queryable, casts no shadow and is not a light", function()
			addTrees()
			build()
			for _, part in floraParts() do
				expect(part.Anchored):toBe(true)
				expect(part.CanCollide):toBe(false)
				expect(part.CanQuery):toBe(false)
				expect(part.CastShadow):toBe(false)
			end
			for _, object in instances do
				expect(object.ClassName == "PointLight" or object.ClassName == "ParticleEmitter"):toBe(false)
			end
		end)

		t:it("uses only palette colours", function()
			addTrees()
			build()
			for _, part in floraParts() do
				expect(PALETTE_SET[part.Color.hex] == true):toBe(true)
			end
		end)

		t:it("keeps every part out of the 18-wide road cross, footprint included", function()
			addTrees()
			build()
			local offenders = {}
			for _, part in floraParts() do
				local at = part.Position
				local r = math.max(part.Size.X, part.Size.Z) / 2
				if math.abs(at.X) - r < ROAD_HALF_WIDTH or math.abs(at.Z) - r < ROAD_HALF_WIDTH then
					table.insert(offenders, part.Name)
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps every part outside the 8-stud ring of every hub centre, footprint included", function()
			addTrees()
			build()
			local offenders = {}
			for _, part in floraParts() do
				local r = math.max(part.Size.X, part.Size.Z) / 2
				for _, hub in HUBS do
					local dx, dz = part.Position.X - hub[1], part.Position.Z - hub[2]
					if math.sqrt(dx * dx + dz * dz) - r < HUB_RADIUS then
						table.insert(offenders, part.Name)
					end
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps every part off the owned hub footprints, yard fences, stacks, beds and stones", function()
			addTrees()
			build()
			local rects = Flora.KEEP_OUT_RECTS
			local discs = Flora.KEEP_OUT_DISCS
			local offenders = {}
			for _, part in floraParts() do
				local r = math.max(part.Size.X, part.Size.Z) / 2
				local x, z = part.Position.X, part.Position.Z
				for _, rect in rects do
					if math.abs(x - rect[1]) < rect[3] + r and math.abs(z - rect[2]) < rect[4] + r then
						table.insert(offenders, part.Name)
					end
				end
				for _, disc in discs do
					local dx, dz = x - disc[1], z - disc[2]
					if math.sqrt(dx * dx + dz * dz) < disc[3] + r then
						table.insert(offenders, part.Name)
					end
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps every part clear of every tree trunk", function()
			addTrees()
			build()
			local offenders = {}
			for _, part in floraParts() do
				local r = math.max(part.Size.X, part.Size.Z) / 2
				for _, spot in TREE_XZ do
					local dx, dz = part.Position.X - spot[1], part.Position.Z - spot[2]
					if math.sqrt(dx * dx + dz * dz) < TREE_CLEAR + r then
						table.insert(offenders, part.Name)
					end
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("keeps every part off the river and the sawah terraces", function()
			addTrees()
			build()
			local offenders = {}
			for _, part in floraParts() do
				local at = part.Position
				if (at.Z > 60 and math.abs(at.X) < 110) or at.Z < -85 then
					table.insert(offenders, part.Name)
				end
			end
			expect(table.concat(offenders, ",")):toBe("")
		end)

		t:it("builds the layers: bushes, rocks and grass tufts are all present", function()
			addTrees()
			build()
			local names = {}
			for _, part in floraParts() do
				names[part.Name] = true
			end
			expect(names.FloraBush == true):toBe(true)
			expect(names.FloraRock == true):toBe(true)
			expect(names.FloraGrass == true):toBe(true)
		end)

		t:it("tags every Canopy part of each Tree model with WindShake and a WindSeed in range", function()
			addTrees()
			build()
			local canopies = tagged("WindShake")
			expect(#canopies):toBe(#TREE_XZ * 3)
			for _, canopy in canopies do
				expect(string.sub(canopy.Name, 1, 7)):toBe("Canopy_")
				local seed = canopy:GetAttribute("WindSeed")
				expect(type(seed) == "number"):toBe(true)
				expect(seed >= 0 and seed <= SEED_MAX):toBe(true)
			end
		end)

		t:it("does not tag trunks, and tags nothing when no trees exist", function()
			addTrees()
			build()
			for _, object in tagged("WindShake") do
				expect(object.Name == "Trunk"):toBe(false)
			end
			tags = {}
			local emptyWorld = newInstance("Folder")
			emptyWorld.Name = "World"
			world = emptyWorld
			build()
			expect(#tagged("WindShake")):toBe(0)
			expect(#floraParts() >= 1):toBe(true)
		end)
	end)

	t:describe("Wind sway helper", function()
		t:beforeEach(function()
			env = Env.new()
		end)

		t:it("offsetFor stays inside 3 degrees and 0.25 studs for any seed and time", function()
			local Wind = env:require("client/World/Wind")
			for seed = 0, SEED_MAX, 0.31 do
				for time = 0, 120, 0.7 do
					local rotation, offset = Wind.offsetFor(seed, time)
					expect(type(rotation) == "number" and type(offset) == "number"):toBe(true)
					expect(math.abs(rotation) <= ROT_MAX):toBe(true)
					expect(math.abs(offset) <= OFFSET_MAX):toBe(true)
				end
			end
		end)

		t:it("offsetFor changes over time, so the sway is visible", function()
			local Wind = env:require("client/World/Wind")
			local a = Wind.offsetFor(1, 0)
			local b = Wind.offsetFor(1, 1.7)
			expect(a == b):toBe(false)
		end)
	end)
end
