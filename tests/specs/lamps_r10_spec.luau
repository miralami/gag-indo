--!nocheck
-- WORK_QUEUE items 202 + 246 + 270: LUNE-ONLY contract for "lamps_r10". Studio staging lives in
-- tools/studio/check_q246.luau (legacy item-246 pool) and check_q270.luau (item-270 rework).
-- The spec asserts no IDS count and no visual verdict. Item 270 turns the old twelve ring poles
-- into >=6 porch/eave bulbs plus 0..4 thick junction poles, night-only at >=20 / <=5.

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
			expect(Data.MAX_LIGHTS):toBe(12)
			expect(Data.LIGHT_RANGE):toBe(16)
			expect(Data.LIGHT_RANGE <= 16):toBe(true)
			expect(Data.LIGHT_BRIGHTNESS > 0 and Data.LIGHT_BRIGHTNESS <= 3):toBe(true)
			expect(Data.RING_RADIUS):toBe(144)
			expect(Data.NIGHT_ON):toBe(20)
			expect(Data.NIGHT_OFF):toBe(5)
			expect(Data.roleAttribute):toBe("role")
			expect(Data.porchRole):toBe("porchBulb")
			expect(Data.headRole):toBe("lampHead")
			expect(Data.poleRole):toBe("junctionPole")
		end)

		t:it("hangs at least six warm single bulbs at derived front-eave anchors", function()
			local bulbs = Data.porchBulbs()
			expect(#bulbs):toBe(6)
			expect(#bulbs >= Data.PORCH_BULB_COUNT and #bulbs >= 6):toBe(true)
			local hubs = Data.hubs()
			local anchors = {}
			for index, bulb in ipairs(bulbs) do
				expect(bulb.name):toBe("PorchBulb_" .. string.format("%02d", index))
				expect(bulb.index):toBe(index)
				expect(bulb.role):toBe(Data.porchRole)
				expect(type(hubs[bulb.anchor])):toBe("table")
				anchors[bulb.anchor] = (anchors[bulb.anchor] or 0) + 1
				expect(bulb.position.y):toBe(Data.GROUND_Y + Data.EAVE_OFFSET - Data.BULB_DROP)
				local hub = hubs[bulb.anchor]
				local a = math.rad(hub.yaw)
				local cos, sin = math.cos(a), math.sin(a)
				local dx, dz = bulb.position.x - hub.x, bulb.position.z - hub.z
				local lx, lz = dx * cos - dz * sin, dx * sin + dz * cos
				expect(math.abs(lz - (hub.depth * 0.5 + Data.ROOF_OVERHANG / 2)) < 1e-6):toBe(true)
				expect(math.abs(lx) <= hub.width * 0.5):toBe(true)
			end
			expect(anchors.warung):toBe(2)
			expect(anchors.ronda):toBe(2)
			expect((anchors.pakrt or 0) + (anchors.polisi or 0)):toBe(2)
		end)

		t:it("keeps 0..4 thick junction poles with heads on the ring", function()
			local poles = Data.junctionPoles()
			expect(#poles >= 0 and #poles <= Data.MAX_JUNCTIONS):toBe(true)
			expect(Data.MAX_JUNCTIONS <= 4):toBe(true)
			expect(#poles):toBe(Data.JUNCTION_COUNT)
			for index, pole in ipairs(poles) do
				expect(pole.name):toBe("JunctionPole_" .. string.format("%02d", index))
				expect(pole.index):toBe(Data.PORCH_BULB_COUNT + index)
				expect(pole.role):toBe(Data.poleRole)
				local distance = math.sqrt(pole.position.x ^ 2 + pole.position.z ^ 2)
				expect(math.abs(distance - Data.RING_RADIUS) < 1e-6):toBe(true)
				expect(pole.pole.size[1] >= Data.MIN_POLE_WIDTH and pole.pole.size[3] >= Data.MIN_POLE_WIDTH):toBe(true)
				expect(pole.head.size[2] > 0):toBe(true)
				expect(pole.head.color.r > pole.pole.color.r):toBe(true)
			end
		end)

		t:it("gates bulbs and heads to night with the 20 / 5 thresholds", function()
			expect(Data.isNight(20)):toBe(true)
			expect(Data.isNight(21)):toBe(true)
			expect(Data.isNight(5)):toBe(true)
			expect(Data.isNight(19.9)):toBe(false)
			expect(Data.isNight(13)):toBe(false)
			expect(Data.isNight(5.1)):toBe(false)
			expect(Data.isNight("21")):toBe(false)
			expect(Data.isNight(0 / 0)):toBe(false)
		end)

		t:it("stays inside the twelve-light budget", function()
			local total = #Data.porchBulbs() + #Data.junctionPoles()
			expect(total <= Data.MAX_LIGHTS):toBe(true)
			expect(Data.MAX_LIGHTS <= 12):toBe(true)
			expect(Data.LIGHT_RANGE <= 16):toBe(true)
			expect(Data.LIGHT_BRIGHTNESS <= 3):toBe(true)
			expect(Data.LIGHT_COLOR.r > Data.LIGHT_COLOR.g and Data.LIGHT_COLOR.g > Data.LIGHT_COLOR.b):toBe(true)
		end)

		t:it("describes bounded, warm part colours", function()
			for _, bulb in ipairs(Data.porchBulbs()) do
				expect(#bulb.size):toBe(3)
				for _, dimension in ipairs(bulb.size) do
					expect(dimension > 0):toBe(true)
				end
				for _, channel in ipairs({ bulb.color.r, bulb.color.g, bulb.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
				expect(bulb.color.r > bulb.color.g and bulb.color.g > bulb.color.b):toBe(true)
			end
			for _, pole in ipairs(Data.junctionPoles()) do
				for _, part in ipairs({ pole.pole, pole.head }) do
					expect(#part.size):toBe(3)
					for _, dimension in ipairs(part.size) do
						expect(dimension > 0):toBe(true)
					end
					for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("derives light Enabled from ClockTime in the applier", function()
			expect(applierSrc:find("ClockTime", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("setClockTime", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("isNight", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("light.Enabled = enabled", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Enabled = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Range = (Data :: any).LIGHT_RANGE", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Brightness = (Data :: any).LIGHT_BRIGHTNESS", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("roleAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("porchRole", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("headRole", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute((Data :: any).tagAttribute, true)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute((Data :: any).indexAttribute, index)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(FAMILY_ID", 1, true) ~= nil):toBe(true)
		end)

		t:it("stages a script-free baked model on thick poles", function()
			expect(applierSrc:find("13869743481", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDevAssetLoader", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ScaleTo", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("GetBoundingBox", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("modelAttribute", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("BaseScript", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("SpotLight")', 1, true) == nil):toBe(true)
			expect(applierSrc:find('Instance.new("Beam")', 1, true) == nil):toBe(true)
			expect(applierSrc:find('Instance.new("Script")', 1, true) == nil):toBe(true)
			expect(applierSrc:find('Instance.new("LocalScript")', 1, true) == nil):toBe(true)
			expect(applierSrc:find('Instance.new("ModuleScript")', 1, true) == nil):toBe(true)
		end)

		t:it("returns fresh, identical descriptors across requires", function()
			local fresh = Env.new():require("shared/ModelMapLampsR10")
			expect(serialize(fresh.porchBulbs())):toBe(serialize(Data.porchBulbs()))
			expect(serialize(fresh.junctionPoles())):toBe(serialize(Data.junctionPoles()))
			local first, second = Data.porchBulbs(), Data.porchBulbs()
			expect(first ~= second):toBe(true)
			expect(first[1] ~= second[1]):toBe(true)
			expect(first[1].position ~= second[1].position):toBe(true)
			first[1].position.x = -1
			first[1].color.r = -1
			expect(second[1].position.x ~= -1):toBe(true)
			expect(second[1].color.r >= 0):toBe(true)
			expect(Data.porchBulbs()[1].position.x ~= -1):toBe(true)
			local poles = Data.junctionPoles()
			poles[1].pole.size[1] = 0
			expect(Data.junctionPoles()[1].pole.size[1] >= Data.MIN_POLE_WIDTH):toBe(true)
		end)
	end)
end
