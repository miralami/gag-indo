--!nocheck
-- WORK_QUEUE section O item 137: water_r8_a is the shipping default, written at client boot
-- independently of the LookDev candidate appliers. Pure Lune proof of the default values, their
-- copy semantics and the safeRanges; Env harness proof of the Terrain write path. No Studio claim.

local fs = require("@lune/fs")

local PROPERTIES = {
	"WaterColor",
	"WaterTransparency",
	"WaterReflectance",
	"WaterWaveSize",
	"WaterWaveSpeed",
}

return function(t, Env)
	local expect = t.expect

	local Data = Env.new():require("shared/ModelMapWaterR8")
	local waterSrc = fs.readFile("src/client/World/Water.luau")
	local mainSrc = fs.readFile("src/client/Main.client.luau")
	local harnessSrc = fs.readFile("tools/studio/review_check_r8.luau")

	local function mount(withTerrain)
		local env = Env.new()
		local current, sets = {}, {}
		local terrain = nil
		if withTerrain then
			terrain = setmetatable({}, {
				__index = function(_, key)
					return current[key]
				end,
				__newindex = function(_, key, value)
					sets[#sets + 1] = { property = key, value = value }
					current[key] = value
				end,
			})
		end
		env.services.Workspace = {
			FindFirstChildOfClass = function(_, className)
				return if className == "Terrain" then terrain else nil
			end,
		}
		return env, env:require("client/World/Water"), { current = current, sets = sets }
	end

	local function differs(a, b)
		for _, property in ipairs(PROPERTIES) do
			if property == "WaterColor" then
				for _, channel in ipairs({ "r", "g", "b" }) do
					if a.WaterColor[channel] ~= b.WaterColor[channel] then
						return true
					end
				end
			elseif a[property] ~= b[property] then
				return true
			end
		end
		return false
	end

	t:describe("Water shipping default (item 137)", function()
		t:it("returns exactly variant A's five values", function()
			local _, Water = mount(true)
			local values = Water.defaultValues()
			expect(values):toEqual(Data.valuesFor("a"))
			expect(values.WaterColor.r):toBe(48)
			expect(values.WaterColor.g):toBe(124)
			expect(values.WaterColor.b):toBe(104)
			expect(values.WaterTransparency):toBe(0.28)
			expect(values.WaterReflectance):toBe(0.35)
			expect(values.WaterWaveSize):toBe(0.42)
			expect(values.WaterWaveSpeed):toBe(0.9)
		end)

		t:it("returns a copy, not the shared map table", function()
			local _, Water = mount(true)
			local first = Water.defaultValues()
			expect(first ~= Data.valuesFor("a")):toBe(true)
			expect(first.WaterColor ~= Data.valuesFor("a").WaterColor):toBe(true)
			first.WaterColor.r = 999
			first.WaterTransparency = 0.99
			expect(Data.valuesFor("a").WaterColor.r):toBe(48)
			expect(Data.valuesFor("a").WaterTransparency):toBe(0.28)
			expect(Water.defaultValues()):toEqual(Data.valuesFor("a"))
		end)

		t:it("keeps A distinct from B and C, inside safeRanges", function()
			local _, Water = mount(true)
			local values = Water.defaultValues()
			for _, key in ipairs({ "b", "c" }) do
				expect(differs(values, Data.valuesFor(key))):toBe(true)
			end
			for _, channel in ipairs({ "r", "g", "b" }) do
				local range = Data.safeRanges.WaterColor[string.upper(channel)]
				expect(values.WaterColor[channel] >= range.min and values.WaterColor[channel] <= range.max):toBe(true)
			end
			for _, property in ipairs(PROPERTIES) do
				if property ~= "WaterColor" then
					local range = Data.safeRanges[property]
					expect(values[property] >= range.min and values[property] <= range.max):toBe(true)
				end
			end
		end)

		t:it("mount writes all five A properties, creates nothing and warns when Terrain is absent", function()
			local _, Water, f = mount(true)
			expect(pcall(Water.mount)):toBe(true)
			expect(#f.sets):toBe(5)
			for _, set in ipairs(f.sets) do
				expect(table.find(PROPERTIES, set.property) ~= nil):toBe(true)
			end
			expect(f.current.WaterColor):toEqual({ R = 48 / 255, G = 124 / 255, B = 104 / 255 })
			expect(f.current.WaterTransparency):toBe(0.28)
			expect(f.current.WaterReflectance):toBe(0.35)
			expect(f.current.WaterWaveSize):toBe(0.42)
			expect(f.current.WaterWaveSpeed):toBe(0.9)

			local noTerrainEnv, noTerrainWater = mount(false)
			expect(pcall(noTerrainWater.mount)):toBe(true)
			expect(#noTerrainEnv.warnings > 0):toBe(true)
			expect(waterSrc:find("Instance.new", 1, true) == nil):toBe(true)
			expect(waterSrc:find("rbxassetid://%d") == nil):toBe(true)
			expect(waterSrc:find("LookDev.enable", 1, true) == nil):toBe(true)
		end)

		t:it("boots next to the sky and ships a read-only harness line before WATER_SAFE", function()
			local skyAt = mainSrc:find('guarded("Sky.mount"', 1, true)
			local waterAt = mainSrc:find('guarded("Water.mount"', 1, true)
			expect(skyAt ~= nil and waterAt ~= nil and waterAt > skyAt):toBe(true)
			expect(mainSrc:find("local Water = require(script.Parent.World.Water)", 1, true) ~= nil):toBe(true)
			local defaultAt = harnessSrc:find('"WATER_DEFAULT"', 1, true)
			local safeAt = harnessSrc:find('"WATER_SAFE"', 1, true)
			expect(defaultAt ~= nil and safeAt ~= nil and defaultAt < safeAt):toBe(true)
		end)
	end)
end
