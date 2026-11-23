--!nocheck
-- WORK_QUEUE items 243 + 251 + 260 (terrain rebuild): LUNE-ONLY contract for "mountains_r10".
-- The candidate is three terrain ridge bands outside the forest ring; no BaseParts. This spec reads
-- the pure data and the applier source. Studio measurement is check_q260.luau.

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
	local pureSrc = fs.readFile("src/shared/ModelMapMountainsR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevMountainsR10.luau")

	local function bandPeaks(id)
		return Data.BAND_PEAKS[id]
	end

	-- Union length (degrees) of the angular intervals each peak footprint covers at its band distance.
	local function coverage(spec)
		local intervals = {}
		for _, peak in ipairs(bandPeaks(spec.id)) do
			local half = math.deg(math.asin(math.min(1, peak.radius / spec.distance)))
			local lo, hi = peak.angle - half, peak.angle + half
			if lo < 0 then
				intervals[#intervals + 1] = { lo + 360, 360 }
				lo = 0
			end
			if hi > 360 then
				intervals[#intervals + 1] = { 0, hi - 360 }
				hi = 360
			end
			intervals[#intervals + 1] = { lo, hi }
		end
		table.sort(intervals, function(a, b)
			return a[1] < b[1]
		end)
		local total, cursor = 0, 0
		for _, interval in ipairs(intervals) do
			local lo, hi = math.max(interval[1], cursor), interval[2]
			if hi > lo then
				total += hi - lo
				cursor = hi
			end
		end
		return total
	end

	t:describe("mountains_r10 terrain ridges (pure data)", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Vector3", "CFrame", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("mountains_r10")
			expect(Data.PERF_TARGET):toBe(500)
			expect(Data.PERF_RADIUS):toBe(100)
			expect(Data.MIN_RADIUS >= 480):toBe(true)
		end)

		t:it("has three bands with increasing distance, all outside radius 480", function()
			expect(#Data.BANDS):toBe(3)
			local previous = 0
			for _, spec in ipairs(Data.BANDS) do
				expect(spec.distance > previous):toBe(true)
				previous = spec.distance
				expect(spec.distance - spec.jitter - spec.radiusMax >= 480):toBe(true)
			end
		end)

		t:it("keeps every peak and every shape footprint outside radius 480", function()
			for _, peak in ipairs(Data.PEAKS) do
				local radial = math.sqrt(peak.x ^ 2 + peak.z ^ 2)
				expect(radial - peak.radius * 1.25 >= 480):toBe(true)
			end
			for _, shape in ipairs(Data.shapes()) do
				if shape.band ~= "foot" then
					local radial = math.sqrt(shape.x ^ 2 + shape.z ^ 2)
					local reach = shape.radius or math.max(shape.sx or 0, shape.sz or 0)
					expect(radial - reach >= 480):toBe(true)
				end
			end
		end)

		t:it("raises peak heights band by band within the authored ranges", function()
			local meanHeight = {}
			for _, spec in ipairs(Data.BANDS) do
				local peaks = bandPeaks(spec.id)
				expect(#peaks >= 20):toBe(true)
				local sum = 0
				for _, peak in ipairs(peaks) do
					expect(peak.height >= spec.heightMin and peak.height <= spec.heightMax):toBe(true)
					sum += peak.height
				end
				meanHeight[#meanHeight + 1] = sum / #peaks
			end
			local near = Data.BANDS[1]
			expect(near.heightMin >= 60 and near.heightMax <= 120):toBe(true)
			expect(Data.BANDS[2].heightMin >= 120 and Data.BANDS[2].heightMax <= 260):toBe(true)
			expect(Data.BANDS[3].heightMin >= 120 and Data.BANDS[3].heightMax <= 260):toBe(true)
			expect(meanHeight[1] < meanHeight[2] and meanHeight[2] < meanHeight[3]):toBe(true)
		end)

		t:it("closes at least 300 of 360 degrees per band and keeps the sunset and valley gaps open", function()
			for _, spec in ipairs(Data.BANDS) do
				local covered = coverage(spec)
				expect(covered >= 300):toBe(true)
				expect(covered <= 345):toBe(true)
				for _, peak in ipairs(bandPeaks(spec.id)) do
					local half = math.deg(math.asin(peak.radius / spec.distance))
					local lo, hi = peak.angle - half, peak.angle + half
					expect(hi <= Data.SUNSET_GAP[1] or lo >= Data.SUNSET_GAP[2]):toBe(true)
					expect(hi <= spec.valley[1] or lo >= spec.valley[2]):toBe(true)
				end
			end
		end)

		t:it("joins neighbouring peaks with lower saddle balls so the skyline is one ridgeline", function()
			for _, spec in ipairs(Data.BANDS) do
				local peaks = bandPeaks(spec.id)
				local joined, saddles = 0, 0
				for index = 1, #peaks - 1 do
					local a, b = peaks[index], peaks[index + 1]
					local dx, dz = b.x - a.x, b.z - a.z
					local span = math.sqrt(dx * dx + dz * dz)
					if span <= (a.radius + b.radius) * 1.15 then
						joined += 1
						local low = math.min(a.height, b.height)
						local found = false
						for _, shape in ipairs(Data.BAND_SHAPES[spec.id]) do
							if shape.kind == "Ball" then
								local mx, mz = a.x + dx * 0.5, a.z + dz * 0.5
								local near = math.sqrt((shape.x - mx) ^ 2 + (shape.z - mz) ^ 2) <= span * 0.25
								if
									near
									and shape.y + shape.radius < low * 0.8
									and shape.radius < math.min(a.radius, b.radius)
								then
									found = true
									break
								end
							end
						end
						if found then
							saddles += 1
						end
					end
				end
				expect(joined >= 20):toBe(true)
				expect(saddles):toBe(joined)
			end
		end)

		t:it("varies peak shape: sharp, broad and twin crowns all occur", function()
			local sharp, broad, twin = 0, 0, 0
			for _, peak in ipairs(Data.PEAKS) do
				if peak.style < 0.4 then
					sharp += 1
				elseif peak.style < 0.75 then
					broad += 1
				else
					twin += 1
				end
			end
			expect(sharp >= 10 and broad >= 10 and twin >= 5):toBe(true)
		end)

		t:it("rolls low foothills between the plateau and the first band without a gap", function()
			expect(#Data.FOOTHILLS >= 60):toBe(true)
			expect(Data.BAND_SHAPES.foot ~= nil):toBe(true)
			local covered = {}
			for _, shape in ipairs(Data.FOOTHILLS) do
				expect(shape.kind):toBe("Ball")
				expect(shape.material == "Grass" or shape.material == "LeafyGrass"):toBe(true)
				local radial = math.sqrt(shape.x ^ 2 + shape.z ^ 2)
				local top = shape.y + shape.radius
				expect(top >= 12 and top <= 45):toBe(true)
				-- Ground-level footprint starts outside radius 410.
				local cut = math.sqrt(math.max(0, shape.radius ^ 2 - shape.y ^ 2))
				expect(radial - cut >= 410):toBe(true)
				-- Nothing taller than 25 inside radius 470.
				local s = math.max(0, radial - 470)
				if s < shape.radius then
					expect(shape.y + math.sqrt(shape.radius ^ 2 - s ^ 2) <= 25.001):toBe(true)
				end
				local bearing = math.deg(math.atan2(shape.z, shape.x)) % 360
				local half = math.deg(math.asin(math.min(1, cut / radial)))
				for sector = 0, 71 do
					local delta = math.abs((sector * 5 + 2.5 - bearing + 180) % 360 - 180)
					if delta <= half then
						covered[sector] = true
					end
				end
			end
			for sector = 0, 71 do
				expect(covered[sector] == true):toBe(true)
			end
		end)

		t:it("describes terrain shapes with rock, slate and grass materials only", function()
			local kinds = {}
			local allowed = { Rock = true, Slate = true, Grass = true, LeafyGrass = true, Ground = true }
			for _, shape in ipairs(Data.shapes()) do
				kinds[shape.kind] = (kinds[shape.kind] or 0) + 1
				expect(allowed[shape.material] == true):toBe(true)
				expect(shape.kind ~= "Block"):toBe(true)
			end
			expect((kinds.Ball or 0) > 100):toBe(true)
			expect((kinds.Cylinder or 0) > 20):toBe(true)
			expect((kinds.Wedge or 0) > 5):toBe(true)
			expect(#Data.mountainParts()):toBe(0)
			expect(#Data.smokeParts()):toBe(0)
		end)

		t:it("greens the near band and blues the far band", function()
			expect(Data.BANDS[1].slope):toBe("LeafyGrass")
			expect(Data.BANDS[2].slope):toBe("Grass")
			expect(Data.BANDS[3].slope):toBe("Slate")
			local atmosphere = Data.ATMOSPHERE
			expect(atmosphere.color.b > atmosphere.color.r):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapMountainsR10")
			expect(serialize(fresh.shapes())):toBe(serialize(Data.shapes()))
		end)
	end)

	t:describe("mountains_r10 terrain applier source", function()
		t:it("creates no parts and keeps NO_BOX_MOUNTAIN semantics", function()
			expect(applierSrc:find('Instance :: any).new("Part")', 1, true) == nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part")', 1, true) == nil):toBe(true)
			expect(applierSrc:find("PartType", 1, true) == nil):toBe(true)
			expect(applierSrc:find("SmoothPlastic", 1, true) == nil):toBe(true)
		end)

		t:it("writes terrain with FillBall, FillCylinder and FillWedge", function()
			expect(applierSrc:find(":FillBall(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find(":FillCylinder(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find(":FillWedge(", 1, true) ~= nil):toBe(true)
		end)

		t:it("restores by filling the same shapes with Air, in yielding chunks", function()
			expect(applierSrc:find("Material.Air", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("fillShape(target, pending[index], true)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("task.wait()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("count % chunk == 0", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
		end)

		t:it("stores and restores the Atmosphere it touches", function()
			expect(applierSrc:find("savedAtmosphere", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("restoreAtmosphere()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("createdAtmosphere", 1, true) ~= nil):toBe(true)
		end)
	end)
end
