--!nocheck
-- WORK_QUEUE item 205: LUNE-ONLY pure-data contract for "furrows_r10". Studio staging and the
-- FURROWS / FURROW_VISIBLE / CROP_PLACEMENT_UNCHANGED checks belong to check_q205.luau; LookDev IDS
-- and review wiring belong to the main session. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapFurrowsR10")
	local Game = env:require("shared/Config/Game")
	local pureSrc = fs.readFile("src/shared/ModelMapFurrowsR10.luau")
	local cameraSrc = fs.readFile("src/shared/ReviewCameras.luau")

	t:describe("furrows_r10 pure data", function()
		t:it("stays pure, with the right id, folder and camera list", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("furrows_r10")
			expect(Data.folderName):toBe("LookDevFurrowsR10_furrows_r10")
			expect(Data.PLOT_COUNT):toBe(10)
			expect(Data.STRIPS_PER_PLOT >= 4):toBe(true)
			expect(Data.CAMERA_NAMES):toEqual({
				"plot_aerial_01",
				"plot_aerial_02",
				"plot_aerial_03",
				"plot_aerial_04",
				"plot_aerial_05",
				"plot_aerial_06",
				"plot_aerial_07",
				"plot_aerial_08",
				"plot_aerial_09",
				"plot_aerial_10",
			})
		end)

		t:it("names every plot_aerial_NN camera from the real registry", function()
			local generated = '`plot_aerial_{string.format("%02d", index)}`'
			expect(string.find(cameraSrc, generated, 1, true) ~= nil):toBe(true)
			for index, name in ipairs(Data.CAMERA_NAMES) do
				expect(name):toBe(string.format("plot_aerial_%02d", index))
			end
			expect(#Data.CAMERA_NAMES):toBe(Game.plotCount)
		end)

		t:it("builds at least four thin alternating strips in each of ten plots", function()
			local parts = Data.parts()
			expect(#parts):toBe(10 * Data.STRIPS_PER_PLOT)
			local perPlot, names = {}, {}
			for _, part in ipairs(parts) do
				perPlot[part.plot] = (perPlot[part.plot] or 0) + 1
				expect(names[part.name] == nil):toBe(true)
				names[part.name] = true
				expect(part.kind):toBe("furrow")
				expect(part.size):toEqual({ 1.2, 0.08, 32 })
				expect(part.size[2] < part.size[1]):toBe(true)
				expect(part.size[1] < part.size[3]):toBe(true)
				expect(part.color):toEqual(
					if tonumber(string.sub(part.name, -1)) % 2 == 1 then Data.DARK_SOIL else Data.LIGHT_SOIL
				)
			end
			for plot = 1, 10 do
				expect(perPlot[plot] >= 4):toBe(true)
				expect(perPlot[plot]):toBe(Data.STRIPS_PER_PLOT)
			end
		end)

		t:it("keeps every strip inside its own plot soil, clear of the ditch", function()
			for _, part in ipairs(Data.parts()) do
				local cx, cz = Game.plotCenter(part.plot)
				local x, y, z = part.position[1], part.position[2], part.position[3]
				expect(math.abs(x - cx) + part.size[1] / 2 <= Data.PLOT_WIDTH / 2):toBe(true)
				expect(math.abs(z - cz) + part.size[3] / 2 <= Data.PLOT_DEPTH / 2):toBe(true)
				expect(math.abs(z - cz) + part.size[3] / 2 <= Data.PLOT_DEPTH / 2 - Data.DITCH_WIDTH / 2):toBe(true)
				expect(y):toBe(Data.FURROW_Y)
				expect(y - part.size[2] / 2 > Data.GROUND_Y):toBe(true)
				expect(y < Data.GROUND_Y + 0.3):toBe(true)
				expect(math.abs(math.sqrt(x * x + z * z) - Game.plotRadius) < 20):toBe(true)
			end
		end)

		t:it("uses only valid 0..255 soil colours", function()
			expect(Data.DARK_SOIL):toEqual({ r = 72, g = 58, b = 40 })
			expect(Data.LIGHT_SOIL):toEqual({ r = 96, g = 78, b = 52 })
			for _, part in ipairs(Data.parts()) do
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(type(channel) == "number" and channel >= 0 and channel <= 255):toBe(true)
				end
			end
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapFurrowsR10")
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.CAMERA_NAMES)):toBe(serialize(Data.CAMERA_NAMES))
		end)
	end)
end
