--!nocheck
-- Landscape spec: the hill ring stays far from the village, the river and the sawah terraces,
-- apply clears with Air before filling, and a rebuild makes the same calls again.

return function(t, Env)
	local expect = t.expect
	local env, Landscape

	-- Volumes Greybox owns (Greybox.terrainBlocks): the river, then four terrace rows.
	-- Copied as centre and size so this spec does not need the whole Greybox module.
	local OWNED = {
		{ c = { 0, -4, 110 }, s = { 220, 8, 100 } },
	}
	for row = 0, 3 do
		table.insert(OWNED, { c = { 0, -1.5 + row * 1.5, -100 + row * 14 }, s = { 120 - row * 22, 3, 18 } })
	end

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
			Landscape = env:require("server/World/Landscape")
		end)

		t:it("keeps every hill at least 150 studs from the origin", function()
			for _, volume in Landscape.hillBlocks() do
				expect(nearOriginDistance(volume) >= 150):toBe(true)
			end
		end)

		t:it("keeps every hill top at most 22 studs above ground (GROUND_Y 0.5)", function()
			for _, volume in Landscape.hillBlocks() do
				local top = volume.shape == "ball" and volume.position.Y + volume.radius
					or volume.position.Y + volume.size.Y / 2
				expect(top <= 0.5 + 22):toBe(true)
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

		t:it("never writes Decoration from script and stays within 40 terrain operations", function()
			local terrain = recorder()
			Landscape.apply(terrain)
			expect(terrain.Decoration):toBe(false)
			expect(#terrain.calls <= 40):toBe(true)
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
	end)
end
