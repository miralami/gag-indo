--!nocheck
-- WORK_QUEUE section P item 174: river_r8 bank plants must be round/organic, not a cube hedge.
-- Pure-data spec: the real ModelMapRiverR8 and MapSpec are loaded through Env.require (no Studio
-- claim). The channel half-width is read from MapSpec's own source, not assumed.
-- Deliberately NOT registered in tests/run.luau; main session registers it.

local fs = require("@lune/fs")

local CUBE_RATIO = 1.2 -- "within 20% of each other" = largest <= 1.2 * smallest
local CUBE_MIN_SIZE = 1.5
local PLANT_MIN = 40
local CHANNEL_WIDTH = 28

local function isCubeBlock(recipe)
	if type(recipe) ~= "table" or recipe.Shape ~= "Block" then
		return false
	end
	local size = recipe.size
	if type(size) ~= "table" or #size < 3 then
		return true -- unreadable recipe geometry is an offender, never a skip
	end
	local smallest = math.min(size[1], size[2], size[3])
	local largest = math.max(size[1], size[2], size[3])
	if smallest < CUBE_MIN_SIZE then
		return false
	end
	return largest <= smallest * CUBE_RATIO
end

return function(t, Env)
	local expect = t.expect
	local Data = Env.new():require("shared/ModelMapRiverR8")
	local MapSpec = Env.new():require("server/World/MapSpec")
	local plants = Data.bankPlants(MapSpec.riverCentreZ)

	-- Read the real channel constant from MapSpec source; the shared map must mirror it.
	local mapSource = fs.readFile("src/server/World/MapSpec.luau")
	local halfText = string.match(mapSource, "local%s+RIVER_HALF%s*=%s*(%d+)")
	expect(halfText ~= nil):toBe(true)
	local waterHalf = tonumber(halfText or "") or 0
	expect(waterHalf * 2):toBe(CHANNEL_WIDTH)

	t:describe("river_r8 bank plants are organic, not cube hedges (item 174)", function()
		t:it("keeps the real 28-wide channel centreline", function()
			expect(Data.WATER_HALF):toBe(waterHalf)
			for _, x in ipairs({ -80, -36, -8, 0, 8, 36, 80 }) do
				local expectedZ = 304 + 12 * math.sin(2 * math.pi * x / 320)
				expect(math.abs(MapSpec.riverCentreZ(x) - expectedZ) < 1e-6):toBe(true)
				expect(math.abs(Data.RIVER_CENTRE(x) - expectedZ) < 1e-6):toBe(true)
			end
		end)

		t:it("has at least 40 bank plants on both banks", function()
			local south, north = 0, 0
			for _, plant in ipairs(plants) do
				expect(plant.Side == "south" or plant.Side == "north"):toBe(true)
				if plant.Side == "south" then
					south += 1
				else
					north += 1
				end
			end
			expect(#plants >= PLANT_MIN):toBe(true)
			expect(south > 0 and north > 0):toBe(true)
		end)

		t:it("has no near-cube Block recipe at size >= 1.5 studs", function()
			local forms = {}
			for index, plant in ipairs(plants) do
				local recipe = plant.Recipe
				expect(type(recipe) == "table"):toBe(true)
				if type(recipe) ~= "table" then
					return -- pre-fix data has no recipe; fail cleanly instead of indexing nil
				end
				expect(recipe.Shape == "Ball" or recipe.Shape == "Wedge"):toBe(true)
				expect(isCubeBlock(recipe)):toBe(false)
				expect(type(recipe.size) == "table" and #recipe.size >= 3):toBe(true)
				expect(type(recipe.offsets) == "table" and #recipe.offsets >= 1):toBe(true)
				for _, axis in ipairs(recipe.size) do
					expect(axis > 0 and axis <= 4):toBe(true)
				end
				forms[recipe.Form] = (forms[recipe.Form] or 0) + 1
				expect(index > 0):toBe(true)
			end
			-- Round mounds AND 3-blade reed/bamboo clumps must both be present.
			expect((forms.ball or 0) > 0):toBe(true)
			expect((forms.blades or 0) > 0):toBe(true)
		end)

		t:it("keeps every plant centre outside the water channel", function()
			for _, plant in ipairs(plants) do
				local centreZ = MapSpec.riverCentreZ(plant.x)
				expect(math.abs(plant.z - centreZ) > waterHalf):toBe(true)
				local recipe = plant.Recipe
				if type(recipe) == "table" and type(recipe.offsets) == "table" then
					for _, offset in ipairs(recipe.offsets) do
						expect(math.abs(plant.z + offset[2] - centreZ) > waterHalf):toBe(true)
					end
				end
			end
		end)

		t:it("stages the organic recipe through the server applier", function()
			local applier = fs.readFile("src/server/World/LookDevRiverR8.luau")
			expect(string.find(applier, "Enum.Shape[recipe.Shape]", 1, true) ~= nil):toBe(true)
			expect(string.find(applier, 'part:SetAttribute("BankPlant", true)', 1, true) ~= nil):toBe(true)
			expect(string.find(applier, "LookDevAssetLoader.get(assetId, FAMILY_ID)", 1, true) ~= nil):toBe(true)
		end)
	end)
end
