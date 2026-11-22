--!nocheck
-- WORK_QUEUE section P item 178 (UNREGISTERED): grassy, rounded terrace bunds. Pure-data contract
-- plus source wiring; the live Studio CHECK lines belong to tools/studio/check_p178.luau. Existing
-- PADI_ROWS / TUFT_SHAPE behaviour must stay untouched.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect

	local env = Env.new()
	local Data = env:require("shared/ModelMapSawahR8")
	local MapSpec = env:require("server/World/MapSpec")
	local panes = MapSpec.paddyWater()

	-- Terrain Grass is #6f8a3f (Landscape.COLOURS); the bund must match it, not the lime padi swatch.
	t:describe("sawah_r8 grassy bunds (item 178)", function()
		t:it("uses terrain-Grass colour and a sub-1.5-stud rounded cross-section", function()
			expect(type(Data.bunds)):toBe("function")
			expect(type(Data.BUND_COLOR)):toBe("table")
			local grass = Data.BUND_COLOR
			expect(#grass):toBe(3)
			expect(math.abs(grass[1] - 111)):toBeAtMost(Data.BUND_COLOR_TOL)
			expect(math.abs(grass[2] - 138)):toBeAtMost(Data.BUND_COLOR_TOL)
			expect(math.abs(grass[3] - 63)):toBeAtMost(Data.BUND_COLOR_TOL)
			expect(Data.BUND_RADIUS * 2):toBeLessThan(1.5)
			expect(Data.BUND_TUFT_RISE):toBeGreaterThan(0)
		end)

		t:it("covers both edges of all eight water panes outside the water rectangle", function()
			expect(type(Data.bunds)):toBe("function")
			local bunds = Data.bunds(panes)
			expect(#bunds):toBe(16)
			local perTerrace, edges = {}, {}
			for _, bund in ipairs(bunds) do
				expect(bund.shape == "cylinder" or bund.shape == "wedge"):toBe(true)
				expect(bund.radius * 2):toBeLessThan(1.5)
				expect(bund.length > 0 and bund.y > 0):toBe(true)
				perTerrace[bund.terrace] = (perTerrace[bund.terrace] or 0) + 1
				edges[bund.edge] = (edges[bund.edge] or 0) + 1
				local pane = bund.side == "west" and Data.waterPanes(panes, bund.terrace)[1]
					or Data.waterPanes(panes, bund.terrace)[2]
				local z0 = pane.centre[3] - pane.size[3] / 2
				local z1 = pane.centre[3] + pane.size[3] / 2
				expect(bund.z <= z0 or bund.z >= z1):toBe(true)
			end
			expect(edges.north):toBe(8)
			expect(edges.south):toBe(8)
			for _, terrace in ipairs(Data.terraceIndices()) do
				expect(perTerrace[terrace]):toBe(4)
			end
			expect(Data.bunds(panes)):toEqual(bunds)
		end)

		t:it("still derives ten-plus padi rows and small tufts per terrace", function()
			expect(Data.PADI_ROWS_MIN):toBe(10)
			expect(#Data.padiRows(panes) / 4):toBeAtLeast(Data.PADI_ROWS_MIN)
			expect(#Data.vergeTufts(panes)):toBeAtLeast(Data.MIN_VERGE_TUFTS)
			for _, blade in ipairs(Data.PADI_BLADES) do
				expect(blade.height):toBeAtMost(Data.PADI_MAX_PART)
			end
		end)

		t:it("stages rounded Grass bunds and lifts tufts onto them", function()
			local applier = fs.readFile("src/server/World/LookDevSawahR8.luau")
			for _, token in ipairs({
				"Data.bunds(panes)",
				'SetAttribute("Bund", true)',
				"Enum.PartType.Cylinder",
				"Enum.Material.Grass",
				"Data.BUND_COLOR",
				"Data.BUND_TUFT_RISE",
			}) do
				expect(string.find(applier, token, 1, true) ~= nil):toBe(true)
			end
			expect(string.find(applier, "rbxassetid://%d") ~= nil):toBe(false)
		end)
	end)
end
