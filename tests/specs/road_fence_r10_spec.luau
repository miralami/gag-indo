--!nocheck
-- selene: allow(incorrect_standard_library_use) -- Lune's @lune/fs uses a string require key.
-- WORK_QUEUE item 201: LUNE-ONLY pure-data contract for "road_fence_r10".
-- Studio staging (ROAD_FENCE / JUNCTION_GAPS / PATH_REACH) belongs to check_q201.luau; LookDev IDS
-- and review wiring belong to the wiring lane. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapRoadFenceR10")
	local pureSrc = fs.readFile("src/shared/ModelMapRoadFenceR10.luau")

	t:describe("road_fence_r10 pure data", function()
		t:it("stays pure: no engine calls, no asset IDs, exact id and folder", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("road_fence_r10")
			expect(Data.folderName):toBe("LookDevRoadFenceR10_road_fence_r10")
			expect(Data.FENCE_HEIGHT):toBe(1.2)
			expect(Data.BAMBOO_COLOR):toEqual({ r = 180, g = 165, b = 90 })
			expect(Data.RING_CENTRE):toBe(144)
			expect(Data.GATE_RADIUS):toBe(152)
			expect(Data.GAP_MIN):toBe(8)
		end)

		t:it("declares at least six road stretches, all inside radius 60..120", function()
			local stretches = Data.stretches()
			expect(#stretches >= 6):toBe(true)
			for _, stretch in ipairs(stretches) do
				expect(type(stretch.name)):toBe("string")
				expect(stretch.side == 1 or stretch.side == -1):toBe(true)
				expect(stretch.radiusFrom >= 60):toBe(true)
				expect(stretch.radiusTo <= 120):toBe(true)
				expect(stretch.radiusTo > stretch.radiusFrom):toBe(true)
				expect(type(stretch.gaps)):toBe("table")
				expect(#stretch.gaps >= 1):toBe(true)
				for _, gap in ipairs(stretch.gaps) do
					expect(gap.from >= 120):toBe(true)
					expect(gap.to >= gap.from):toBe(true)
					expect(gap.from > stretch.radiusTo):toBe(true)
				end
			end
		end)

		t:it("emits post/rail descriptors 1.2 studs tall in the bamboo colour", function()
			local parts = Data.parts()
			expect(#parts > 0):toBe(true)
			local posts, rails, stretchesSeen = 0, 0, {}
			for _, part in ipairs(parts) do
				expect(part.kind == "post" or part.kind == "rail"):toBe(true)
				expect(part.size[2] <= Data.FENCE_HEIGHT):toBe(true)
				expect(part.color):toEqual({ r = 180, g = 165, b = 90 })
				expect(part.position[2] >= Data.GROUND_Y):toBe(true)
				stretchesSeen[part.stretch] = true
				if part.kind == "post" then
					posts += 1
					expect(part.size[2]):toBe(1.2)
				else
					rails += 1
				end
			end
			expect(posts > 0):toBe(true)
			expect(rails > 0):toBe(true)
			local count = 0
			for _ in pairs(stretchesSeen) do
				count += 1
			end
			expect(count >= 6):toBe(true)
		end)

		t:it("keeps all parts at least 8 studs from every junction and plot gate", function()
			local violations = 0
			for _, part in ipairs(Data.parts()) do
				local x, z = part.position[1], part.position[3]
				for _, angle in ipairs({ 0, 90, 180, 270 }) do
					local radians = math.rad(angle)
					local dx, dz = x - math.cos(radians) * 144, z - math.sin(radians) * 144
					if dx * dx + dz * dz < 64 then
						violations += 1
					end
				end
				local radius = math.sqrt(x * x + z * z)
				expect(radius <= 121):toBe(true)
			end
			expect(violations):toBe(0)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapRoadFenceR10")
			expect(fresh.id):toBe(Data.id)
			expect(serialize(fresh.stretches())):toBe(serialize(Data.stretches()))
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
		end)
	end)
end
