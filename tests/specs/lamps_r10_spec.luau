--!nocheck
-- WORK_QUEUE items 202 + 246: LUNE-ONLY contract for "lamps_r10". Studio staging (LAMPS,
-- LAMP_NIGHT_ONLY, LIGHT_COST) belongs to check_q202.luau; item 246 adds LAMP_POOL plus its FAIL
-- calibrations in check_q246.luau. LookDev IDS and review wiring are owned by the main session.
-- This spec asserts neither an IDS count nor a visual verdict.

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
	local Data = env:require("shared/ModelMapLampsR10")
	local dataSrc = fs.readFile("src/shared/ModelMapLampsR10.luau")
	local applierSrc = fs.readFile("src/server/World/LookDevLampsR10.luau")

	t:describe("lamps_r10", function()
		t:it("keeps the data module pure and the identity exact", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(dataSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(dataSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("lamps_r10")
			expect(Data.folderName):toBe("LookDevLampsR10_lamps_r10")
			expect(Data.LAMP_COUNT):toBe(12)
			expect(Data.LIGHT_RANGE):toBe(16)
			expect(Data.LIGHT_RANGE <= 16):toBe(true)
			expect(Data.LIGHT_BRIGHTNESS > 0 and Data.LIGHT_BRIGHTNESS <= 3):toBe(true)
			expect(Data.RING_RADIUS):toBe(144)
			expect(Data.NIGHT_ON):toBe(18)
			expect(Data.NIGHT_OFF):toBe(6)
		end)

		t:it("places at least twelve lamps evenly on the ring road", function()
			local lamps = Data.lamps()
			expect(#lamps >= 12):toBe(true)
			expect(#lamps):toBe(12)
			local spacing = 2 * math.pi / #lamps
			for index, lamp in ipairs(lamps) do
				expect(lamp.name):toBe("StreetLamp_" .. string.format("%02d", index))
				expect(lamp.index):toBe(index)
				expect(lamp.radius):toBe(Data.RING_RADIUS)
				expect(lamp.position.y):toBe(Data.GROUND_Y)
				local distance = math.sqrt(lamp.position.x ^ 2 + lamp.position.z ^ 2)
				expect(math.abs(distance - Data.RING_RADIUS) < 1e-6):toBe(true)
				local angle = (index - 1) * spacing
				expect(math.abs(lamp.position.x - Data.RING_RADIUS * math.cos(angle)) < 1e-9):toBe(true)
				expect(math.abs(lamp.position.z - Data.RING_RADIUS * math.sin(angle)) < 1e-9):toBe(true)
			end
		end)

		t:it("describes a pole and a lantern with 0..255 colours", function()
			for _, lamp in ipairs(Data.lamps()) do
				for _, part in ipairs({ lamp.pole, lamp.lantern }) do
					expect(type(part)):toBe("table")
					expect(#part.size):toBe(3)
					for _, dimension in ipairs(part.size) do
						expect(dimension > 0):toBe(true)
					end
					for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
				expect(lamp.lantern.color.r > lamp.pole.color.r):toBe(true)
			end
			for _, channel in ipairs({ Data.LIGHT_COLOR.r, Data.LIGHT_COLOR.g, Data.LIGHT_COLOR.b }) do
				expect(channel >= 0 and channel <= 255):toBe(true)
			end
		end)

		t:it("derives light Enabled from ClockTime in the applier", function()
			expect(applierSrc:find("ClockTime", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("setClockTime", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("NIGHT_ON", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("NIGHT_OFF", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("light.Enabled = enabled", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Enabled = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Range = (Data :: any).LIGHT_RANGE", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Brightness = (Data :: any).LIGHT_BRIGHTNESS", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("light.Parent = pole", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Shadows = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("StreetLamp", true)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("lamp", index)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps bounded warm pools on the road, separated at lamp midpoints", function()
			local lamps = Data.lamps()
			local count = #lamps
			expect(count):toBe(12)
			expect(Data.LIGHT_COLOR.r > Data.LIGHT_COLOR.g and Data.LIGHT_COLOR.g > Data.LIGHT_COLOR.b):toBe(true)

			-- Item 246 mounts each PointLight at the pole centre (same x/z as the lamp).
			local drop = lamps[1].position.y + Data.POLE_SIZE[2] / 2 - Data.GROUND_Y
			local poolRadius = math.sqrt(Data.LIGHT_RANGE ^ 2 - drop ^ 2)
			expect(drop > 0 and drop < Data.LIGHT_RANGE):toBe(true)
			expect(poolRadius > 14):toBe(true) -- road pool, not just the lantern housing

			local good = 0
			for index, lamp in ipairs(lamps) do
				local nextLamp = lamps[index % count + 1]
				local prevLamp = lamps[(index - 2) % count + 1]
				local underInside = drop < Data.LIGHT_RANGE
				local midNext = {
					x = (lamp.position.x + nextLamp.position.x) / 2,
					z = (lamp.position.z + nextLamp.position.z) / 2,
				}
				local midPrev = {
					x = (lamp.position.x + prevLamp.position.x) / 2,
					z = (lamp.position.z + prevLamp.position.z) / 2,
				}
				local function midpointDistance(mid)
					local dx = lamp.position.x - mid.x
					local dz = lamp.position.z - mid.z
					return math.sqrt(dx * dx + dz * dz + drop * drop)
				end
				local nextOutside = midpointDistance(midNext) > Data.LIGHT_RANGE
				local prevOutside = midpointDistance(midPrev) > Data.LIGHT_RANGE
				expect(underInside and nextOutside and prevOutside):toBe(true)
				if underInside and nextOutside and prevOutside then
					good += 1
				end
			end
			expect(good >= 8):toBe(true)
			expect(good):toBe(12)
		end)

		t:it("returns fresh, identical descriptors across requires", function()
			local fresh = Env.new():require("shared/ModelMapLampsR10")
			expect(serialize(fresh.lamps())):toBe(serialize(Data.lamps()))
			local first, second = Data.lamps(), Data.lamps()
			expect(first ~= second):toBe(true)
			expect(first[1] ~= second[1]):toBe(true)
			expect(first[1].position ~= second[1].position):toBe(true)
			first[1].position.x = -1
			first[1].lantern.color.r = -1
			expect(second[1].position.x ~= -1):toBe(true)
			expect(second[1].lantern.color.r >= 0):toBe(true)
			expect(Data.lamps()[1].position.x ~= -1):toBe(true)
		end)
	end)
end
