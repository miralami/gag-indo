--!nocheck
-- WORK_QUEUE section Q item 197 lane 1: LUNE-ONLY pure-data contract for "horizon_fill_r10".
-- Studio staging (HORIZON_FILL / PERF_BUDGET / HAZE_MATCH) belongs to check_q197.luau; LookDev IDS
-- and review wiring belong to lane 2. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapHorizonFillR10")
	local pureSrc = fs.readFile("src/shared/ModelMapHorizonFillR10.luau")
	local eye, look = { 0, 100, 392 }, { 0, 10, 0 }

	t:describe("horizon_fill_r10 pure data", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("horizon_fill_r10")
			expect(Data.folderName):toBe("LookDevHorizonFillR10_horizon_fill_r10")
			expect(Data.CAMERA_NAMES):toEqual({ "canonical_overview", "spawn", "hill_ring_in" })
			expect(Data.HORIZON_DISTANCE):toBe(1200)
			expect(Data.YAW_OFFSETS):toEqual({ -0.35, -0.175, 0, 0.175, 0.35 })
			expect(Data.SKIRT_HALF):toBe(1024)
			expect(Data.SKIRT_Z):toBe(-128)
			expect(Data.SKIRT_Y):toBe(-8)
			expect(Data.SKIRT_THICKNESS):toBe(1)
			expect(Data.SKIRT_COLOR):toEqual({ r = 128, g = 158, b = 150 })
			expect(Data.HAZE):toBe(2.0)
			expect(Data.HAZE_COLOR):toEqual({ r = 214, g = 226, b = 220 })
			expect(Data.PERF_TARGET):toBe(500)
			expect(Data.PERF_RADIUS):toBe(100)
		end)

		t:it("builds one anchored skirt below terrain with the haze-blue colour", function()
			local parts = Data.skirtParts()
			expect(#parts):toBe(1)
			local part = parts[1]
			expect(part.name):toBe("HorizonSkirt")
			expect(part.size):toEqual({ 2048, 1, 2048 })
			expect(part.position):toEqual({ 0, -8, -128 })
			expect(part.color):toEqual({ r = 128, g = 158, b = 150 })
			expect(part.size[1]):toBe(Data.SKIRT_HALF * 2)
			expect(part.size[3]):toBe(Data.SKIRT_HALF * 2)
			expect(part.size[1] <= 2048):toBe(true) -- Roblox Part size cap
			expect(Data.SKIRT_HALF):toBe(1024)
			expect(Data.SKIRT_Y < -3.5):toBe(true)
		end)

		t:it("samples five horizontal horizon points at the exact reach", function()
			local points = Data.horizonPoints(eye, look)
			expect(#points):toBe(#Data.YAW_OFFSETS)
			expect(#points):toBe(5)
			for index, point in ipairs(points) do
				expect(point.y):toBe(eye[2])
				local dx, dz = point.x - eye[1], point.z - eye[3]
				local distance = math.sqrt(dx * dx + dz * dz)
				expect(math.abs(distance - 1200) < 1e-6):toBe(true)
				expect(math.abs(point.x) <= Data.SKIRT_HALF):toBe(true)
				expect(math.abs(point.z - Data.SKIRT_Z) <= Data.SKIRT_HALF):toBe(true)
				if index > 1 then
					expect(point.x ~= points[1].x or point.z ~= points[1].z):toBe(true)
				end
			end
			expect(Data.horizonPoint(eye, eye, 0).z):toBe(eye[3] + 1200)
		end)

		t:it("returns valid, fresh haze tables inside the grade bounds", function()
			local first, second = Data.hazeValues(), Data.hazeValues()
			expect(first.Haze):toBe(2.0)
			expect(first.Haze >= 1.0 and first.Haze <= 2.4):toBe(true)
			expect(first.Color):toEqual({ r = 214, g = 226, b = 220 })
			for _, channel in ipairs({ first.Color.r, first.Color.g, first.Color.b }) do
				expect(channel >= 0 and channel <= 255):toBe(true)
			end
			expect(first ~= second):toBe(true)
			expect(first.Color ~= second.Color):toBe(true)
			first.Color.r = -1
			expect(second.Color.r):toBe(214)
			expect(Data.HAZE_COLOR.r):toBe(214)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapHorizonFillR10")
			expect(serialize(fresh.skirtParts())):toBe(serialize(Data.skirtParts()))
			expect(serialize(fresh.horizonPoints(eye, look))):toBe(serialize(Data.horizonPoints(eye, look)))
			expect(serialize(fresh.hazeValues())):toBe(serialize(Data.hazeValues()))
		end)
	end)
end
