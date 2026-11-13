--!nocheck
-- Greybox spec: terrain rebuild must clear every volume it owns before refilling, so repeated
-- builds do not stack water and terrace voxels.

return function(t, Env)
	local expect = t.expect
	local env, Greybox

	t:describe("Greybox terrain rebuild", function()
		t:beforeEach(function()
			env = Env.new()
			env:mock("server/World/Map", {
				TAGS = { Greybox = "GreyboxWorld" },
				all = function()
					return {}
				end,
				isDesignerWorld = function()
					return false
				end,
				add = function() end,
			})
			env:mock("server/World/Props", {
				palette = function()
					return { R = 0, G = 0, B = 0 }
				end,
				part = function()
					return {}
				end,
			})
			env:mock("server/World/NpcFactory", { build = function() end })
			env.globals.CFrame = {
				new = function(x, y, z)
					return { position = Env.Vector3.new(x, y, z) }
				end,
			}
			Greybox = env:require("server/World/Greybox")
		end)

		t:it("owns one river block and four terrace rows", function()
			local blocks = Greybox.terrainBlocks()
			expect(#blocks):toBe(5)
			expect(blocks[1].material):toBe("Material.Water")
			expect(blocks[1].size.X):toBe(220)
			expect(blocks[1].size.Y):toBe(8)
			expect(blocks[1].size.Z):toBe(100)
			for row = 0, 3 do
				local block = blocks[row + 2]
				expect(block.material):toBe("Material.Ground")
				expect(block.size.X):toBe(120 - row * 22)
				expect(block.size.Z):toBe(18)
				expect(block.cframe.position.Z):toBe(-100 + row * 14)
			end
		end)

		t:it("clears each owned volume with Air before filling it", function()
			local calls = {}
			local terrain = {
				FillBlock = function(_, cframe, size, material)
					table.insert(calls, { cframe = cframe, size = size, material = material })
				end,
			}
			Greybox.applyTerrain(terrain)

			local blocks = Greybox.terrainBlocks()
			expect(#calls):toBe(#blocks * 2)
			for index, block in blocks do
				local clear = calls[index]
				local fill = calls[index + #blocks]
				expect(clear.material):toBe("Material.Air")
				expect(fill.material):toBe(block.material)
				expect(clear.size.X):toBe(fill.size.X)
				expect(clear.size.Y):toBe(fill.size.Y)
				expect(clear.size.Z):toBe(fill.size.Z)
				expect(clear.cframe.position.X):toBe(fill.cframe.position.X)
				expect(clear.cframe.position.Y):toBe(fill.cframe.position.Y)
				expect(clear.cframe.position.Z):toBe(fill.cframe.position.Z)
			end
		end)
	end)
end
