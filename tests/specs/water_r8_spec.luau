--!nocheck
-- WORK_QUEUE section M item 76: the three OFF-BY-DEFAULT water_r8 CLIENT candidates. Locks the
-- exact safeRanges and palettes, the five-property Terrain save/restore round-trip, no ID literals,
-- and registry/review/bootstrap wiring. No visual verdict, no Studio claim, no screenshot claim.

local fs = require("@lune/fs")

local PROPERTIES = {
	"WaterColor",
	"WaterTransparency",
	"WaterReflectance",
	"WaterWaveSize",
	"WaterWaveSpeed",
}
local CANDIDATES = { "water_r8_a", "water_r8_b", "water_r8_c" }
local LABELS = {
	water_r8_a = "clear tropical green",
	water_r8_b = "murky brown after rain",
	water_r8_c = "bright turquoise",
}
local BASELINE = {
	WaterColor = { R = 0.21, G = 0.32, B = 0.43 },
	WaterTransparency = 0.33,
	WaterReflectance = 0.24,
	WaterWaveSize = 0.15,
	WaterWaveSpeed = -0.4,
}

return function(t, Env)
	local expect = t.expect

	local dataSrc = fs.readFile("src/shared/ModelMapWaterR8.luau")
	local applierSrc = fs.readFile("src/client/World/LookDevWaterR8.luau")
	local mainSrc = fs.readFile("src/client/Main.client.luau")

	local Data = Env.new():require("shared/ModelMapWaterR8")
	local LookDev = Env.new():require("shared/LookDev")
	local Review = Env.new():require("shared/LookDevReview")

	-- Fake Terrain whose five water properties are ordinary indexed reads/writes. The proxy records
	-- every write so the spec can prove the palette is applied and the prior value restored exactly.
	local function mount(withTerrain)
		local env = Env.new()
		local registered = {}
		local sets = {}
		local current = {}
		for property, value in pairs(BASELINE) do
			current[property] = value
		end

		env.globals.Color3 = {
			fromRGB = function(r, g, b)
				return { R = r / 255, G = g / 255, B = b / 255 }
			end,
		}
		env:mock("shared/LookDev", {
			register = function(id, applierTable)
				registered[id] = applierTable
			end,
		})

		local terrain = nil
		if withTerrain then
			terrain = {}
			setmetatable(terrain, {
				__index = function(_, key)
					return current[key]
				end,
				__newindex = function(_, key, value)
					table.insert(sets, { property = key, value = value })
					current[key] = value
				end,
			})
		end
		env.services.Workspace = {
			FindFirstChildOfClass = function(_, className)
				return if className == "Terrain" then terrain else nil
			end,
		}

		env:require("client/World/LookDevWaterR8")
		return env, { registered = registered, sets = sets, current = current }
	end

	t:describe("ModelMapWaterR8 pure data", function()
		t:it("exports the exact property contract and documented safeRanges", function()
			expect(Data.idPrefix):toBe("water_r8_")
			expect(Data.order):toEqual({ "a", "b", "c" })
			expect(Data.properties):toEqual(PROPERTIES)
			expect(Data.safeRanges.WaterColor.R):toEqual({ min = 0, max = 255 })
			expect(Data.safeRanges.WaterColor.G):toEqual({ min = 0, max = 255 })
			expect(Data.safeRanges.WaterColor.B):toEqual({ min = 0, max = 255 })
			expect(Data.safeRanges.WaterTransparency):toEqual({ min = 0.05, max = 0.75 })
			expect(Data.safeRanges.WaterReflectance):toEqual({ min = 0, max = 0.6 })
			expect(Data.safeRanges.WaterWaveSize):toEqual({ min = 0, max = 1 })
			expect(Data.safeRanges.WaterWaveSpeed):toEqual({ min = -2, max = 2 })
		end)

		t:it("keeps all three distinct palettes inside their safeRanges", function()
			local seenColors = {}
			for _, key in ipairs(Data.order) do
				local variant = Data.variants[key]
				expect(variant.id):toBe(CANDIDATES[table.find(Data.order, key)])
				expect(variant.label):toBe(LABELS[variant.id])
				local values = variant.values
				expect(values):toBe(Data.valuesFor(key))
				local color = values.WaterColor
				for _, channel in ipairs({ "r", "g", "b" }) do
					local range = Data.safeRanges.WaterColor[string.upper(channel)]
					expect(range):toBeTruthy()
					expect(color[channel] >= range.min and color[channel] <= range.max):toBe(true)
				end
				for _, property in ipairs(PROPERTIES) do
					if property ~= "WaterColor" then
						local value = values[property]
						local range = Data.safeRanges[property]
						expect(type(value)):toBe("number")
						expect(value >= range.min and value <= range.max):toBe(true)
					end
				end
				local signature = color.r .. ":" .. color.g .. ":" .. color.b
				expect(seenColors[signature]):toBe(nil)
				seenColors[signature] = true
			end
			expect(Data.valuesFor("missing")):toBe(nil)
		end)

		t:it("is deterministic and free of engine APIs and asset-ID literals", function()
			local other = Env.new():require("shared/ModelMapWaterR8")
			expect(other.variants):toEqual(Data.variants)
			expect(other.safeRanges):toEqual(Data.safeRanges)
			expect(other.properties):toEqual(Data.properties)
			expect(dataSrc:find("rbxassetid://%d") == nil):toBe(true)
			expect(dataSrc:find("%d%d%d%d%d%d%d") == nil):toBe(true)
			expect(dataSrc:find("game.", 1, true) == nil):toBe(true)
			expect(dataSrc:find("Instance.new", 1, true) == nil):toBe(true)
			expect(dataSrc:find("Enum.", 1, true) == nil):toBe(true)
		end)
	end)

	t:describe("LookDevWaterR8 client appliers", function()
		t:it("registers three appliers with no Part creation or ID literal", function()
			local _, f = mount(true)
			local count = 0
			for id, applierTable in f.registered do
				count += 1
				expect(CANDIDATES[table.find(CANDIDATES, id)]):toBe(id)
				expect(type(applierTable.apply)):toBe("function")
				expect(type(applierTable.restore)):toBe("function")
			end
			expect(count):toBe(3)
			expect(applierSrc:find("local function make(", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LookDev.register(ModelMapWaterR8.idPrefix .. key", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('Instance.new("Part"', 1, true) == nil):toBe(true)
			expect(applierSrc:find("rbxassetid://%d") == nil):toBe(true)
		end)

		t:it("applies all five properties and restores the exact prior values", function()
			local _, f = mount(true)
			for _, id in ipairs(CANDIDATES) do
				local applier = f.registered[id]
				applier.apply(nil)
				local values = Data.variants[string.sub(id, -1)].values
				local color = values.WaterColor
				expect(f.current.WaterColor):toEqual({ R = color.r / 255, G = color.g / 255, B = color.b / 255 })
				expect(f.current.WaterTransparency):toBe(values.WaterTransparency)
				expect(f.current.WaterReflectance):toBe(values.WaterReflectance)
				expect(f.current.WaterWaveSize):toBe(values.WaterWaveSize)
				expect(f.current.WaterWaveSpeed):toBe(values.WaterWaveSpeed)
				applier.restore()
				for property, baseline in pairs(BASELINE) do
					expect(f.current[property]):toEqual(baseline)
				end
				expect(pcall(applier.restore)):toBe(true)
			end
		end)

		t:it("warns but does not throw when Terrain is missing", function()
			local env, f = mount(false)
			local applier = f.registered.water_r8_a
			expect(pcall(applier.apply, nil)):toBe(true)
			expect(#env.warnings > 0):toBe(true)
			expect(pcall(applier.restore)):toBe(true)
		end)
	end)

	t:describe("water_r8 registry, review and handoff", function()
		t:it("ships candidates 52-54 with plans, client review paths and a boot require", function()
			expect(#LookDev.IDS):toBe(89)
			for index, id in ipairs(CANDIDATES) do
				expect(LookDev.IDS[51 + index]):toBe(id)
				expect(LookDev.candidates[id].status):toBe("candidate, awaiting designer yes")
				local plan = LookDev.plan(id)
				expect(plan ~= nil):toBe(true)
				expect(plan.id):toBe(id)
				expect(plan.idsSource):toBe("Shared.ModelMapWaterR8")
				local entry = Review.paths[id]
				expect(entry.datamodel):toBe("client")
				expect(entry.path):toEqual({ "World", "LookDevWaterR8" })
			end
			expect(mainSrc:find("pcall(require, script.Parent.World.LookDevWaterR8)", 1, true) ~= nil):toBe(true)
			local candidatesSrc = fs.readFile("docs/v2/visual/CANDIDATES.md")
			for _, id in ipairs(CANDIDATES) do
				local row
				for line in string.gmatch(candidatesSrc, "[^\n]+") do
					if string.find(line, "`" .. id .. "`", 1, true) then
						row = line
					end
				end
				expect(row ~= nil):toBe(true)
				expect(string.find(row, "fps", 1, true) ~= nil):toBe(true)
				expect(
					string.find(row, "pending", 1, true) ~= nil
						or string.find(row, "| **yes", 1, true) ~= nil
						or string.find(row, "| **no", 1, true) ~= nil
				):toBe(true)
			end
		end)
	end)
end
