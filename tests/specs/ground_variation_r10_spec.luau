--!nocheck
-- WORK_QUEUE section Q item 195 lane 1: LUNE-ONLY pure-data contract for "ground_variation_r10".
-- Studio staging (GROUND_TONES / ROAD_UNTOUCHED / PLOT_UNTOUCHED) belongs to check_q195.luau;
-- LookDev IDS and review wiring belong to lane 2. This spec asserts neither.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapGroundVariationR10")
	local Game = env:require("shared/Config/Game")
	local blobs = Data.blobs()
	local pureSrc = fs.readFile("src/shared/ModelMapGroundVariationR10.luau")

	t:describe("ground_variation_r10 pure data", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("ground_variation_r10")
			expect(Data.folderName):toBe("LookDevGroundVariationR10_ground_variation_r10")
			expect(#Data.TONES):toBe(4)
		end)

		t:it("builds deterministic irregular blobs with all four tones and rare Mud", function()
			expect(#blobs >= Data.MIN_BLOBS):toBe(true)
			local tones, mud = {}, 0
			for _, blob in ipairs(blobs) do
				expect(blob.radius >= Data.MIN_BLOB_RADIUS and blob.radius <= Data.MAX_BLOB_RADIUS):toBe(true)
				expect(Data.zoneClear(blob.x, blob.z)):toBe(true)
				expect(type(blob.tone) == "string"):toBe(true)
				expect(table.find(Data.TONES, blob.tone) ~= nil):toBe(true)
				tones[blob.tone] = true
				if blob.tone == "Mud" then
					mud += 1
				end
			end
			for _, tone in ipairs(Data.TONES) do
				expect(tones[tone] == true):toBe(true)
			end
			expect(mud <= #blobs / 10):toBe(true)
		end)

		t:it("never recolours a road, ring, plot footprint or plot gate", function()
			for _, cell in ipairs(Data.sampleGrid(Data.GRID_DEFAULT)) do
				if not cell.zoneClear then
					expect(Data.toneAt(cell.x, cell.z)):toBe("Grass")
				end
			end
			for _, point in ipairs({
				{ 0, 0 },
				{ 100, 0 },
				{ -100, 0 },
				{ 0, 100 },
				{ 0, -100 },
				{ 144, 0 },
				{ -144, 0 },
				{ 0, 144 },
				{ 0, -144 },
			}) do
				expect(Data.zoneClear(point[1], point[2])):toBe(false)
				expect(Data.toneAt(point[1], point[2])):toBe("Grass")
			end
			for index = 1, Game.plotCount do
				local px, pz = Game.plotCenter(index)
				expect(Data.zoneClear(px, pz)):toBe(false)
				expect(Data.toneAt(px, pz)):toBe("Grass")
			end
		end)

		t:it("returns identical tones and grids across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapGroundVariationR10")
			expect(fresh.blobs()):toEqual(blobs)
			for _, cell in ipairs(blobs) do
				expect(fresh.toneAt(cell.x, cell.z)):toBe(Data.toneAt(cell.x, cell.z))
			end
			expect(fresh.sampleGrid(40)):toEqual(Data.sampleGrid(40))
		end)

		t:it("yields at least three tones on the 40x40 grid, clear cells included", function()
			local cells = Data.sampleGrid(40)
			expect(#cells):toBe(1600)
			local all, clear = {}, {}
			for _, cell in ipairs(cells) do
				all[cell.tone] = true
				if cell.zoneClear then
					clear[cell.tone] = true
				end
			end
			local allCount, clearCount = 0, 0
			for _ in pairs(all) do
				allCount += 1
			end
			for _ in pairs(clear) do
				clearCount += 1
			end
			expect(allCount >= 3):toBe(true)
			expect(clearCount >= 3):toBe(true)
		end)
	end)
end
