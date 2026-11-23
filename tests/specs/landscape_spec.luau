--!nocheck
-- Landscape spec: the hill ring stays outside the playable rectangle, the river and the sawah
-- terraces; apply clears retired footprints and current volumes with Air before filling; a rebuild
-- makes the same calls again.

return function(t, Env)
	local expect = t.expect
	local env, Landscape

	-- Volumes Greybox owns: the river carve strips and one box per terrace lane, filled from
	-- MapSpec in beforeEach so this spec follows the layout instead of copying numbers.
	local OWNED = {}
	local MapSpec

	-- Axis-aligned bounds of a hill volume: ball = centre +/- radius, block = centre +/- size/2.
	local function bounds(volume)
		local p = volume.position
		local h = volume.shape == "ball" and { volume.radius, volume.radius, volume.radius }
			or { volume.size.X / 2, volume.size.Y / 2, volume.size.Z / 2 }
		return { p.X - h[1], p.X + h[1] }, { p.Y - h[2], p.Y + h[2] }, { p.Z - h[3], p.Z + h[3] }
	end

	-- Conservative distance from the origin to the nearest point of a volume's bounding sphere.
	local function nearOriginDistance(volume)
		local p = volume.position
		local centre = math.sqrt(p.X * p.X + p.Y * p.Y + p.Z * p.Z)
		local reach
		if volume.shape == "ball" then
			reach = volume.radius
		else
			reach = math.sqrt((volume.size.X / 2) ^ 2 + (volume.size.Y / 2) ^ 2 + (volume.size.Z / 2) ^ 2)
		end
		return centre - reach
	end

	local function overlapsBox(volume, box)
		local bx, by, bz = bounds(volume)
		local hx, hy, hz = box.s[1] / 2, box.s[2] / 2, box.s[3] / 2
		local function hit(lo, hi, centre, half)
			return lo < centre + half and hi > centre - half
		end
		return hit(bx[1], bx[2], box.c[1], hx) and hit(by[1], by[2], box.c[2], hy) and hit(bz[1], bz[2], box.c[3], hz)
	end

	-- Part of a volume that rises above GROUND_Y, as an XZ footprint. Nil when fully buried.
	local function aboveGroundFootprint(volume)
		local p = volume.position
		local ground = Landscape.GROUND_Y
		if volume.shape == "ball" then
			local top = p.Y + volume.radius
			if top <= ground then
				return nil
			end
			local cap = math.sqrt(volume.radius ^ 2 - (ground - p.Y) ^ 2)
			return { p.X - cap, p.X + cap, p.Z - cap, p.Z + cap }
		end
		local top = p.Y + volume.size.Y / 2
		if top <= ground then
			return nil
		end
		return {
			p.X - volume.size.X / 2,
			p.X + volume.size.X / 2,
			p.Z - volume.size.Z / 2,
			p.Z + volume.size.Z / 2,
		}
	end

	-- A footprint is outside the playable square when one axis clears it completely.
	local function outsidePlayable(footprint)
		local half = Landscape.PLAYABLE_HALF
		return footprint[2] <= -half or footprint[1] >= half or footprint[4] <= -half or footprint[3] >= half
	end

	-- Records every terrain call in order. Each entry is a plain string so two runs can be compared.
	local function recorder()
		local log = {}
		local terrain = { Decoration = false, calls = log }
		function terrain:FillBlock(cframe, size, material)
			table.insert(log, "FillBlock " .. tostring(material) .. " " .. cframe.position.X .. "," .. cframe.position.Y .. "," .. cframe.position.Z .. " " .. size.X .. "x" .. size.Y .. "x" .. size.Z)
		end
		function terrain:FillBall(center, radius, material)
			table.insert(log, "FillBall " .. tostring(material) .. " " .. center.X .. "," .. center.Y .. "," .. center.Z .. " r" .. radius)
		end
		function terrain:SetMaterialColor(material, colour)
			table.insert(log, "SetMaterialColor " .. tostring(material) .. " " .. colour.hex)
		end
		return terrain
	end

	t:describe("Landscape hills", function()
		t:beforeEach(function()
			env = Env.new()
			env.globals.CFrame = {
				new = function(x, y, z)
					if type(x) == "table" then
						return { position = x }
					end
					return { position = Env.Vector3.new(x, y, z) }
				end,
			}
			env.globals.Color3 = {
				fromHex = function(hex)
					return { hex = hex }
				end,
			}
			-- Minimal Instance fake so applyHorizonFill can be exercised by the switch spec.
			env.madeInstances = {}
			env.globals.Instance = {
				new = function(className)
					local object = { className = className }
					function object:SetAttribute(name, value)
						object[name] = value
					end
					env.madeInstances[#env.madeInstances + 1] = object
					return object
				end,
			}
			Landscape = env:require("server/World/Landscape")
			MapSpec = env:require("server/World/MapSpec")
			OWNED = {}
			for _, carve in MapSpec.river().carves do
				table.insert(OWNED, { c = carve.centre, s = carve.size })
			end
			for _, terrace in MapSpec.TERRACES do
				for _, side in MapSpec.TERRACE_SIDES do
					local height = terrace.top - MapSpec.TERRAIN_BASE_Y
					table.insert(OWNED, {
						c = { (side.x0 + side.x1) / 2, MapSpec.TERRAIN_BASE_Y + height / 2, (terrace.z0 + terrace.z1) / 2 },
						s = { side.x1 - side.x0, height, terrace.z1 - terrace.z0 },
					})
				end
			end
		end)

		t:it("keeps every hill at least 150 studs from the origin", function()
			for _, volume in Landscape.hillBlocks() do
				expect(nearOriginDistance(volume) >= 150):toBe(true)
			end
		end)

		t:it("keeps every hill top at most MAX_HILL_HEIGHT above ground, and the ring is tall", function()
			expect(Landscape.MAX_HILL_HEIGHT >= 40 and Landscape.MAX_HILL_HEIGHT <= 80):toBe(true)
			local tallest = 0
			for _, volume in Landscape.hillBlocks() do
				local top = volume.shape == "ball" and volume.position.Y + volume.radius
					or volume.position.Y + volume.size.Y / 2
				expect(top <= Landscape.GROUND_Y + Landscape.MAX_HILL_HEIGHT):toBe(true)
				tallest = math.max(tallest, top - Landscape.GROUND_Y)
			end
			expect(tallest >= 40):toBe(true)
		end)

		t:it("ball algebra: top is GROUND_Y + height and cap radius follows from centre and radius", function()
			for _, volume in Landscape.hillBlocks() do
				if volume.shape == "ball" then
					local top = volume.position.Y + volume.radius
					local cap = math.sqrt(volume.radius ^ 2 - (Landscape.GROUND_Y - volume.position.Y) ^ 2)
					expect(top):toBeNear(Landscape.GROUND_Y + volume.height, 1e-9)
					expect(cap):toBeGreaterThan(0)
					-- Cap of a ball cut at ground: h * (2r - h). Equal to the radius for a hemisphere
					-- (height == radius), smaller when the ball bulges (height > radius).
					expect(cap * cap):toBeNear(volume.height * (2 * volume.radius - volume.height), 1e-6)
					expect(cap <= volume.radius + 1e-9):toBe(true)
				end
			end
		end)

		t:it("keeps every above-ground footprint outside the playable square", function()
			for _, volume in Landscape.hillBlocks() do
				local footprint = aboveGroundFootprint(volume)
				if footprint then
					expect(outsidePlayable(footprint)):toBe(true)
				end
			end
		end)

		t:it("never overlaps the river or a sawah terrace block", function()
			for _, volume in Landscape.hillBlocks() do
				for _, box in OWNED do
					expect(overlapsBox(volume, box)):toBe(false)
				end
			end
		end)

		t:it("uses only the requested materials and produces a varied ring", function()
			local seen = {}
			local count = 0
			for _, volume in Landscape.hillBlocks() do
				seen[volume.material] = true
				count += 1
			end
			expect(count >= 9):toBe(true)
			expect(seen["Material.Grass"]):toBe(true)
			expect(seen["Material.Ground"]):toBe(true)
			expect(seen["Material.Rock"]):toBe(true)
			expect(seen["Material.Mud"]):toBe(true)
		end)

		t:it("clears the retired above-ground footprint before filling the new hills", function()
			local clear = Landscape.clearBlocks()
			local ground = Landscape.GROUND_Y
			-- Retired hills as { x, z, radius, height }, both earlier ring generations. Each footprint is
			-- a square of side 2 * cap (cap^2 = h * (2r - h)), height h above ground, possibly split into
			-- 40-stud strips, so check that the strips tile the footprint rather than match one block.
			local retiredHills = {
				{ 190, 0, 32, 14 }, -- half-scale east hill
				{ 0, -190, 30, 15 }, -- half-scale north hill
				{ 245, 0, 42, 40 }, -- first doubled-square east hill
			}
			for _, old in retiredHills do
				local cap = math.sqrt(old[4] * (2 * old[3] - old[4]))
				local area, minX, maxX, minZ, maxZ = 0, math.huge, -math.huge, math.huge, -math.huge
				for _, volume in clear do
					local p = volume.position
					if
						volume.shape == "block"
						and math.abs(p.Y - (ground + old[4] / 2)) < 1e-9
						and volume.size.Y == old[4]
						and math.abs(p.X - old[1]) <= cap
						and math.abs(p.Z - old[2]) <= cap
					then
						area += volume.size.X * volume.size.Z
						minX, maxX = math.min(minX, p.X - volume.size.X / 2), math.max(maxX, p.X + volume.size.X / 2)
						minZ, maxZ = math.min(minZ, p.Z - volume.size.Z / 2), math.max(maxZ, p.Z + volume.size.Z / 2)
					end
				end
				expect(area):toBeNear(4 * cap * cap, 1e-6)
				expect(minX):toBeNear(old[1] - cap, 1e-6)
				expect(maxX):toBeNear(old[1] + cap, 1e-6)
				expect(minZ):toBeNear(old[2] - cap, 1e-6)
				expect(maxZ):toBeNear(old[2] + cap, 1e-6)
			end
			-- Retired outcrop blocks as { x, centre Y, z, height }: cleared whole (none exceeds 40 wide).
			local retiredBlocks = {
				{ -160, 3.5, 25, 6 },
				{ -150, 1.5, -60, 2 },
				{ -232, 4.5, 22, 8 },
				{ -230, 2, 108, 3 },
			}
			for _, old in retiredBlocks do
				local found = false
				for _, volume in clear do
					if
						volume.shape == "block"
						and volume.position.X == old[1]
						and volume.position.Y == old[2]
						and volume.position.Z == old[3]
						and volume.size.Y == old[4]
					then
						found = true
					end
				end
				expect(found):toBe(true)
			end
		end)

		t:it("clears every owned volume with Air before any fill", function()
			local terrain = recorder()
			Landscape.apply(terrain)
			local lastAir, firstFill = 0, math.huge
			for index, call in terrain.calls do
				if string.find(call, "FillBlock Material.Air", 1, true) or string.find(call, "FillBall Material.Air", 1, true) then
					lastAir = index
				elseif string.find(call, "Material.Air", 1, true) == nil and (string.sub(call, 1, 4) == "Fill") then
					firstFill = math.min(firstFill, index)
				end
			end
			expect(lastAir > 0):toBe(true)
			expect(lastAir < firstFill):toBe(true)
		end)

		t:it("never colours Water through SetMaterialColor (Studio rejects it as unsupported)", function()
			local terrain = recorder()
			Landscape.apply(terrain)
			for _, call in terrain.calls do
				if string.sub(call, 1, 16) == "SetMaterialColor" then
					expect(string.find(call, "Water", 1, true)):toBe(nil)
				end
			end
		end)

		t:it("never writes Decoration from script and keeps terrain operations within budget", function()
			local terrain = recorder()
			Landscape.apply(terrain)
			expect(terrain.Decoration):toBe(false)
			-- Operations are exactly: one Air clear per retired strip, one SetMaterialColor per palette
			-- material, one fill per current hill strip or ball. The old 40-operation cap was for a single
			-- 9-hill ring; the scaled world retires two ring generations (about 97 clear strips) and fills
			-- 16 hills, about 113 in all. 128 leaves a little headroom without letting it double silently.
			local colours = 0
			for _, call in terrain.calls do
				if string.sub(call, 1, 16) == "SetMaterialColor" then
					colours += 1
				end
			end
			-- Item 268: hill fills are gated by the reversible DOME_HILLS switch; in the spec env the
			-- shared config now drives the gate off, so only Air clears + palette colours are emitted.
			local hillFills = Landscape.DOME_HILLS_ENABLED == false and 0 or #Landscape.hillBlocks()
			expect(#terrain.calls):toBe(#Landscape.clearBlocks() + colours + hillFills)
			expect(#terrain.calls <= 128):toBe(true)
		end)

		t:it("produces the same terrain calls when apply runs twice", function()
			local first = recorder()
			Landscape.apply(first)
			local second = recorder()
			Landscape.apply(second)
			expect(#first.calls):toBe(#second.calls)
			for index, call in first.calls do
				expect(second.calls[index]):toBe(call)
			end
		end)

		t:it("with DOME_HILLS_ENABLED=false skips hill fills but still clears Air and applies horizon fill", function()
			local terrain = recorder()
			local world = {}
			function world:FindFirstChild()
				return nil
			end
			terrain.Parent = world
			local previous = Landscape.DOME_HILLS_ENABLED
			Landscape.DOME_HILLS_ENABLED = false
			Landscape.apply(terrain)
			Landscape.DOME_HILLS_ENABLED = previous

			local air, hillBalls, colours = 0, 0, 0
			for _, call in terrain.calls do
				if string.find(call, "Material.Air", 1, true) then
					air += 1
				elseif string.sub(call, 1, 8) == "FillBall" then
					hillBalls += 1
				elseif string.sub(call, 1, 16) == "SetMaterialColor" then
					colours += 1
				end
			end
			expect(air):toBe(#Landscape.clearBlocks())
			expect(colours):toBeGreaterThan(0)
			expect(hillBalls):toBe(0)

			local folders, fillParts = 0, 0
			for _, object in ipairs(env.madeInstances) do
				if object.className == "Folder" then
					folders += 1
				elseif object.className == "Part" and object.HorizonFill == true then
					fillParts += 1
				end
			end
			expect(folders):toBe(1)
			expect(fillParts):toBe(4)
		end)
	end)
end
