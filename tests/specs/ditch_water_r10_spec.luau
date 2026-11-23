--!nocheck
-- WORK_QUEUE item 207: LUNE-ONLY pure-data contract for "ditch_water_r10". Studio checks
-- (DITCH_WATER / DITCH_COLOR) live in tools/studio/check_q207.luau; LookDev IDS and review wiring
-- belong to the main session. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapDitchWaterR10")
	local Water = Env.new():require("shared/ModelMapWaterR8")
	local Plots = Env.new():require("shared/ModelMapPlotsR8")
	local pureSrc = fs.readFile("src/shared/ModelMapDitchWaterR10.luau")
	local checkSrc = fs.readFile("tools/studio/check_q263.luau")
	local parts = Data.parts()
	local variantA = Water.variants.a.values.WaterColor

	t:describe("ditch_water_r10 pure data", function()
		t:it("stays pure and declares the 10-plot OFF-BY-DEFAULT contract", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("ditch_water_r10")
			expect(Data.folderName):toBe("LookDevDitchWaterR10_ditch_water_r10")
			expect(Data.PLOT_COUNT):toBe(10)
			expect(Data.DITCH_WIDTH):toBe(2)
			expect(Data.MIN_WATER_WIDTH):toBe(2)
			expect(Data.DITCH_WIDTH >= Data.MIN_WATER_WIDTH):toBe(true)
			expect(Data.SOIL_Y):toBe(0.5)
			expect(Data.WATER_Y > Data.SOIL_Y):toBe(true)
			expect(Data.STRIPS_PER_PLOT >= 1):toBe(true)
			expect(Data.STRIP_THICKNESS):toBe(0.12)
			expect(Data.TRANSPARENCY):toBeGreaterThan(0)
			expect(Data.TRANSPARENCY):toBeLessThan(1)
			expect(Data.COLOR_TOLERANCE):toBe(12)
		end)

		t:it("uses the exact variant-A teal from ModelMapWaterR8, not an invented colour", function()
			expect(variantA):toEqual({ r = 48, g = 124, b = 104 })
			expect(Water.variants.a.id):toBe("water_r8_a")
			expect(Data.WATER_COLOR):toEqual(variantA)
			for _, channel in ipairs({ Data.WATER_COLOR.r, Data.WATER_COLOR.g, Data.WATER_COLOR.b }) do
				expect(channel >= 0 and channel <= 255):toBe(true)
			end
			for _, part in ipairs(parts) do
				expect(part.color):toEqual(variantA)
			end
			expect(string.find(pureSrc, "ModelMapWaterR8", 1, true) ~= nil):toBe(true)
		end)

		t:it("places at least one thin glassy strip per plot over the 2-stud ditch", function()
			expect(#parts):toBe(Data.PLOT_COUNT * Data.STRIPS_PER_PLOT)
			local perPlot, names = {}, {}
			for _, part in ipairs(parts) do
				expect(part.kind):toBe("ditch_water")
				expect(part.plot >= 1 and part.plot <= Data.PLOT_COUNT):toBe(true)
				expect(type(part.name) == "string" and names[part.name] ~= true):toBe(true)
				names[part.name] = true
				perPlot[part.plot] = (perPlot[part.plot] or 0) + 1
				expect(#part.position):toBe(3)
				expect(#part.size):toBe(3)
				expect(part.size[2]):toBe(0.12)
				expect(part.size[3]):toBe(Data.DITCH_WIDTH)
				expect(part.size[1] > 0):toBe(true)
				expect(part.transparency):toBe(Data.TRANSPARENCY)
			end
			for index = 1, Data.PLOT_COUNT do
				expect(perPlot[index]):toBe(Data.STRIPS_PER_PLOT)
				expect(perPlot[index] >= 1):toBe(true)
			end
		end)

		t:it("matches the plots_r8 outer ditch cross-section and span", function()
			local ditch = Plots.ditchLayout(Plots.PLOT_WIDTH, Plots.PLOT_DEPTH)
			expect(Data.PLOT_WIDTH):toBe(Plots.PLOT_WIDTH)
			expect(Data.PLOT_DEPTH):toBe(Plots.PLOT_DEPTH)
			expect(Data.DITCH_WIDTH):toBe(Plots.DITCH_WIDTH)
			expect(ditch.water.depth):toBe(Data.DITCH_WIDTH)
			expect(ditch.water.thickness <= Data.STRIP_THICKNESS):toBe(true)
			local span = Data.PLOT_WIDTH - 2
			local covered = 0
			for _, part in ipairs(parts) do
				if part.plot == 1 then
					covered += part.size[1]
				end
			end
			expect(covered):toBe(span)
			expect(span):toBe(ditch.water.width)
		end)

		t:it("returns identical descriptors across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapDitchWaterR10")
			expect(serialize(fresh.parts())):toBe(serialize(parts))
			local first, second = Data.parts(), Data.parts()
			expect(first ~= second):toBe(true)
			expect(serialize(first)):toBe(serialize(second))
		end)

		t:it("stays >=2 studs wide and above the soil line at every staged strip", function()
			for _, part in ipairs(parts) do
				expect(part.size[3] >= Data.MIN_WATER_WIDTH):toBe(true)
				expect(part.position[2] > Data.SOIL_Y):toBe(true)
			end
		end)

		t:it("ships the item-263 DITCH_VISIBLE check and its FAIL calibration", function()
			for _, name in ipairs({
				"CROP_STAGE_HEIGHT",
				"CROP_STAGE_COLOR",
				"CROP_STAGE_WIDTH",
				"FURROW_RELIEF",
				"DITCH_VISIBLE",
				"CAL_FURROW_RELIEF_FAIL",
				"CAL_DITCH_VISIBLE_FAIL",
			}) do
				expect(string.find(checkSrc, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(checkSrc, "SUMMARY_Q263", 1, true) ~= nil):toBe(true)
		end)

		t:it("wires an additive applier and an unflattering Studio harness in source", function()
			local applier = fs.readFile("src/server/World/LookDevDitchWaterR10.luau")
			for _, token in ipairs({
				'SetAttribute("DitchWater", true)',
				'SetAttribute("plot", descriptor.plot)',
				'SetAttribute("colorTolerance", (Data :: any).COLOR_TOLERANCE)',
				'SetAttribute("LookDevStage", FAMILY_ID)',
				"CastShadow = false",
				"CanCollide = false",
				"Color3.fromRGB(descriptor.color.r, descriptor.color.g, descriptor.color.b)",
				"LookDev.register(FAMILY_ID",
				"LookDevFailures.set(FAMILY_ID, failures)",
			}) do
				expect(string.find(applier, token, 1, true) ~= nil):toBe(true)
			end
			local harness = fs.readFile("tools/studio/check_q207.luau")
			for _, token in ipairs({
				'emit("DITCH_WATER",',
				'emit("DITCH_COLOR",',
				"enableAdditive",
				"disableAll",
				"CALIBRATION",
				"DitchWater",
			}) do
				expect(string.find(harness, token, 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
