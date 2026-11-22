--!nocheck
-- WORK_QUEUE section Q item 196 lane 1: LUNE-ONLY pure-data contract for "paths_curved_r10".
-- Studio staging (PATH_REACH / PATH_CURVE / GATE_CLEAR / NO_CROSS) belongs to check_q196.luau;
-- LookDev IDS and review wiring belong to lane 2. This spec asserts neither.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapPathsCurvedR10")
	local Game = env:require("shared/Config/Game")
	local paths = Data.paths()
	local pureSrc = fs.readFile("src/shared/ModelMapPathsCurvedR10.luau")

	t:describe("paths_curved_r10 pure data", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("paths_curved_r10")
			expect(Data.PATH_COUNT):toBe(10)
			expect(Data.CORE_HALF):toBe(4)
			expect(Data.SHOULDER):toBe(1.5)
			expect(Data.TONE_CORE):toBe("Mud")
			expect(Data.TONE_SHOULDER):toBe("Ground")
			expect(Data.GATE_RADIUS):toBe(152)
			expect(Data.PLOT_HALF):toBe(24)
		end)

		t:it("builds 10 curved spokes with 6..10 clear control points and >=4 stud deviation", function()
			expect(#paths):toBe(Data.PATH_COUNT)
			local curved = 0
			for _, path in ipairs(paths) do
				expect(path.index >= 1 and path.index <= 10):toBe(true)
				expect(path.plotIndex == path.index):toBe(true)
				expect(#path.points >= 6 and #path.points <= 10):toBe(true)
				expect(type(path.straight.ax) == "number" and type(path.straight.bz) == "number"):toBe(true)
				for _, point in ipairs(path.points) do
					expect(Data.zoneClear(point.x, point.z)):toBe(true)
				end
				local deviation = Data.maxDeviation(path.index)
				expect(deviation >= Data.DEVIATION_MIN and deviation <= Data.DEVIATION_MAX):toBe(true)
				if deviation >= 4 then
					curved += 1
				end
			end
			expect(curved >= 6):toBe(true)
		end)

		t:it("paints only Mud/Ground and never in a plot, gate box or river channel", function()
			local tones = {}
			for _, cell in ipairs(Data.sampleGrid(40)) do
				local tone = cell.tone
				expect(tone == nil or tone == "Mud" or tone == "Ground"):toBe(true)
				if tone ~= nil then
					tones[tone] = true
				end
				if cell.clear == false then
					expect(tone):toBe(nil)
				end
			end
			for index = 1, Game.plotCount do
				local px, pz = Game.plotCenter(index)
				expect(Data.paintAt(px, pz)):toBe(nil)
				for _, point in ipairs({
					{ px - 20, pz - 20 },
					{ px + 20, pz + 20 },
					{ 152 * math.cos((index - 3) / 10 * math.pi * 2), 152 * math.sin((index - 3) / 10 * math.pi * 2) },
				}) do
					expect(Data.paintAt(point[1], point[2])):toBe(nil)
				end
			end
			for x = -200, 200, 8 do
				local riverZ = Data.riverCentreZ(x)
				if not (x >= -5 and x <= 5 and riverZ >= 276 and riverZ <= 332) then
					expect(Data.paintAt(x, riverZ)):toBe(nil)
				end
			end
			expect(tones.Mud == true):toBe(true)
			expect(tones.Ground == true):toBe(true)
		end)

		t:it("returns identical paths, paints and grids across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapPathsCurvedR10")
			expect(fresh.paths()):toEqual(paths)
			for _, path in ipairs(paths) do
				expect(fresh.maxDeviation(path.index)):toBe(Data.maxDeviation(path.index))
			end
			for _, cell in ipairs(paths[1].points) do
				expect(fresh.paintAt(cell.x, cell.z)):toBe(Data.paintAt(cell.x, cell.z))
			end
			expect(fresh.sampleGrid(40)):toEqual(Data.sampleGrid(40))
		end)

		t:it("shows painted Mud/Ground cells and >=6 path deviations on the 40x40 grid", function()
			local cells = Data.sampleGrid(40)
			expect(#cells):toBe(1600)
			local mud, ground, curved = 0, 0, 0
			for _, cell in ipairs(cells) do
				if cell.tone == "Mud" then
					mud += 1
				elseif cell.tone == "Ground" then
					ground += 1
				end
			end
			for _, path in ipairs(paths) do
				if Data.paintedDeviation(cells, path) >= 4 then
					curved += 1
				end
			end
			expect(mud > 0):toBe(true)
			expect(ground > 0):toBe(true)
			expect(curved >= 6):toBe(true)
		end)
	end)
end
