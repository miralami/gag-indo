--!nocheck
-- WORK_QUEUE items 243 + 251 + 260: LUNE-ONLY pure-data contract for "mountains_r10".
-- Item 260 replaces the old >=450 origin ring with three ridges at |z| = 300 / 450 / 600 and reads
-- the spawn camera's upper-third horizon band for SKYLINE_COVER. Studio staging is check_q260.luau;
-- this spec asserts neither that nor the LookDev IDS wiring.

local fs = require("@lune/fs")

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapMountainsR10")
	local Veg = env:require("shared/ModelMapVegetationR7")
	local MapSpec = env:require("server/World/MapSpec")
	local pureSrc = fs.readFile("src/shared/ModelMapMountainsR10.luau")

	local function nearestDistance(reference, descriptor)
		local function axis(delta, half)
			local outside = math.abs(delta) - half
			return outside > 0 and outside or 0
		end
		local dx = axis(reference[1] - descriptor.position[1], descriptor.size[1] / 2)
		local dy = axis(reference[2] - descriptor.position[2], descriptor.size[2] / 2)
		local dz = axis(reference[3] - descriptor.position[3], descriptor.size[3] / 2)
		return math.sqrt(dx * dx + dy * dy + dz * dz)
	end

	local function unit(v)
		local length = math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2)
		return { v[1] / length, v[2] / length, v[3] / length }
	end

	local function cross(a, b)
		return {
			a[2] * b[3] - a[3] * b[2],
			a[3] * b[1] - a[1] * b[3],
			a[1] * b[2] - a[2] * b[1],
		}
	end

	-- AABB slab test: the live Studio check raycasts Wedge geometry, so this is a planning proxy,
	-- not a substitute for the SEEN-IN-STUDIO SKYLINE_COVER line in CHECK_260.txt.
	local function hitsAabb(eye, direction, descriptor)
		local near, far = -math.huge, math.huge
		for axis = 1, 3 do
			local centre = descriptor.position[axis]
			local half = descriptor.size[axis] / 2
			local low, high = centre - half, centre + half
			if math.abs(direction[axis]) < 1e-9 then
				if eye[axis] < low or eye[axis] > high then
					return false
				end
			else
				local a, b = (low - eye[axis]) / direction[axis], (high - eye[axis]) / direction[axis]
				if a > b then
					a, b = b, a
				end
				near, far = math.max(near, a), math.min(far, b)
				if near > far then
					return false
				end
			end
		end
		return far > 0
	end

	local function skylineFraction(mountains)
		local eye, look = Veg.savedCamera.eye, Veg.savedCamera.look
		local forward = unit({ look[1] - eye[1], look[2] - eye[2], look[3] - eye[3] })
		local right = unit(cross(forward, { 0, 1, 0 }))
		local up = cross(right, forward)
		local tanV = math.tan(math.rad(70) / 2)
		local tanH = tanV * 16 / 9
		local hits, samples = 0, 8 * 8
		for iy = 0, 7 do
			local ny = 0.20 + 0.25 * iy / 7
			for ix = 0, 7 do
				local nx = 0.02 + 0.96 * ix / 7
				local sx, sy = (2 * nx - 1) * tanH, (1 - 2 * ny) * tanV
				local direction = unit({
					forward[1] + right[1] * sx + up[1] * sy,
					forward[2] + right[2] * sx + up[2] * sy,
					forward[3] + right[3] * sx + up[3] * sy,
				})
				for _, mountain in ipairs(mountains) do
					if hitsAabb(eye, direction, mountain) then
						hits += 1
						break
					end
				end
			end
		end
		return hits / samples
	end

	t:describe("mountains_r10 pure data", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new" }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("mountains_r10")
			expect(Data.folderName):toBe("LookDevMountainsR10_mountains_r10")
			expect(Data.PERF_TARGET):toBe(500)
			expect(Data.PERF_RADIUS):toBe(100)
			expect(Data.MIN_DISTANCE):toBe(250)
			expect(serialize(Data.RIDGE_BANDS)):toBe(serialize({ 300, 450, 600 }))
			expect(Data.BAND_TOLERANCE):toBe(60)
			expect(Data.SKYLINE_MIN):toBe(0.15)
			expect(Data.SKYLINE_MAX):toBe(0.40)
		end)

		t:it("places at least eight ridges in exactly three distance bands", function()
			local mountains = Data.MOUNTAINS
			expect(type(mountains)):toBe("table")
			expect(#mountains >= 8):toBe(true)
			expect(#Data.mountainParts()):toBe(#mountains)
			local layers = {}
			for _, mountain in ipairs(mountains) do
				expect(type(mountain.name)):toBe("string")
				expect(#mountain.name > 0):toBe(true)
				expect(#mountain.size):toBe(3)
				expect(#mountain.position):toBe(3)
				expect(mountain.shape == "Wedge" or mountain.shape == "Cylinder"):toBe(true)
				expect(mountain.shape ~= "Ball"):toBe(true)
				expect(type(mountain.material) == "string" and #mountain.material > 0):toBe(true)
				local radius = math.sqrt(mountain.position[1] ^ 2 + mountain.position[3] ^ 2)
				expect(radius >= Data.MIN_DISTANCE):toBe(true)
				expect(mountain.position[2] + mountain.size[2] / 2 >= 25):toBe(true)
				expect(mountain.position[3] <= -250):toBe(true)
				expect(mountain.size[2] <= 240):toBe(true)
				local band = nil
				for _, centre in ipairs(Data.RIDGE_BANDS) do
					if math.abs(math.abs(mountain.position[3]) - centre) <= Data.BAND_TOLERANCE then
						band = centre
						break
					end
				end
				expect(band ~= nil):toBe(true)
				layers[band] = true
			end
			local count = 0
			for _, centre in ipairs(Data.RIDGE_BANDS) do
				expect(layers[centre] == true):toBe(true)
				count += 1
			end
			expect(count):toBe(3)
			local tallPeaks = 0
			for _, mountain in ipairs(mountains) do
				if mountain.position[2] + mountain.size[2] / 2 >= 100 then
					tallPeaks += 1
				end
			end
			expect(tallPeaks >= 3):toBe(true)
		end)

		t:it("keeps the spawn skyline cover inside 15..40 percent", function()
			local fraction = skylineFraction(Data.MOUNTAINS)
			expect(fraction >= Data.SKYLINE_MIN):toBe(true)
			expect(fraction <= Data.SKYLINE_MAX):toBe(true)
		end)

		t:it("fades each ridge band lighter and bluer with distance", function()
			local darkest, middle, palest = nil, nil, nil
			for _, mountain in ipairs(Data.MOUNTAINS) do
				if mountain.position[3] == -300 then
					darkest = mountain.color
				elseif mountain.position[3] == -450 then
					middle = mountain.color
				elseif mountain.position[3] == -600 then
					palest = mountain.color
				end
			end
			expect(darkest ~= nil and middle ~= nil and palest ~= nil):toBe(true)
			expect(darkest.r < middle.r and middle.r < palest.r):toBe(true)
			expect(darkest.b < middle.b and middle.b < palest.b):toBe(true)
			expect(palest.b - palest.r > darkest.b - darkest.r):toBe(true)
		end)

		t:it("uses explicit blue-green materials, never a grey SmoothPlastic Ball", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					expect(type(descriptor.color)):toBe("table")
					expect(descriptor.shape ~= "Ball"):toBe(true)
					expect(type(descriptor.material) == "string" and #descriptor.material > 0):toBe(true)
					local spread = math.max(descriptor.color.r, descriptor.color.g, descriptor.color.b)
						- math.min(descriptor.color.r, descriptor.color.g, descriptor.color.b)
					expect(spread >= 18):toBe(true)
					expect(descriptor.color.b >= descriptor.color.r + 12):toBe(true)
					expect(descriptor.color.g >= descriptor.color.r + 12):toBe(true)
					for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
						expect(type(channel) == "number"):toBe(true)
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("keeps every staged Mountain shape and material rock-like", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					expect(descriptor.shape == "Wedge" or descriptor.shape == "Cylinder"):toBe(true)
					expect(descriptor.shape ~= "Block"):toBe(true)
					expect(descriptor.material == "Rock" or descriptor.material == "Slate"):toBe(true)
					expect(descriptor.material ~= "SmoothPlastic"):toBe(true)
				end
			end
			local applierSrc = fs.readFile("src/server/World/LookDevMountainsR10.luau")
			expect(string.find(applierSrc, 'name ~= "Rock" and name ~= "Slate"', 1, true) ~= nil):toBe(true)
			expect(string.find(applierSrc, "Material.SmoothPlastic", 1, true) == nil):toBe(true)
		end)

		t:it("keeps every staged part >=250 studs from the spawn eye and player spawn", function()
			local eye = Veg.savedCamera.eye
			-- Item 260 measures the spawn review eye and the player spawn; item 251's
			-- horizon_north eye sits inside the new 300-stud band and is superseded.
			local references = { eye, { MapSpec.SPAWN.x, MapSpec.SPAWN.y, MapSpec.SPAWN.z } }
			expect(#references >= 2):toBe(true)
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					for _, reference in ipairs(references) do
						expect(nearestDistance(reference, descriptor) >= Data.MIN_DISTANCE):toBe(true)
					end
				end
			end
		end)

		t:it("keeps every colour channel in 0..255", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					expect(type(descriptor.color)):toBe("table")
					for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
						expect(type(channel) == "number")
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("stages a faint smoke Cylinder above the far crest", function()
			local smoke = Data.SMOKE
			expect(type(smoke)):toBe("table")
			expect(#smoke >= 1):toBe(true)
			expect(#Data.smokeParts()):toBe(#smoke)
			local puff = smoke[1]
			expect(puff.shape):toBe("Cylinder")
			expect(type(puff.transparency)):toBe("number")
			expect(puff.transparency > 0 and puff.transparency < 1):toBe(true)
			expect(math.sqrt(puff.position[1] ^ 2 + puff.position[3] ^ 2) >= 250):toBe(true)
			local peak = nil
			for _, mountain in ipairs(Data.MOUNTAINS) do
				if mountain.position[1] == puff.position[1] and mountain.position[3] == puff.position[3] then
					peak = mountain
				end
			end
			expect(peak ~= nil):toBe(true)
			expect(puff.position[2] > peak.position[2] + peak.size[2] / 2):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapMountainsR10")
			expect(serialize(fresh.mountainParts())):toBe(serialize(Data.mountainParts()))
			expect(serialize(fresh.smokeParts())):toBe(serialize(Data.smokeParts()))
		end)
	end)
end
