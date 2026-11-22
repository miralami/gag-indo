--!nocheck
-- WORK_QUEUE section Q item 199: LUNE-ONLY pure-data contract for "hill_dressing_r10".
-- Studio staging (HILL_ROCKS / HILL_TREES / WALKABLE) belongs to check_q199.luau; LookDev IDS
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
	local Data = env:require("shared/ModelMapHillDressingR10")
	local pureSrc = fs.readFile("src/shared/ModelMapHillDressingR10.luau")

	t:describe("hill_dressing_r10 pure data", function()
		t:it("stays pure with the expected id and folder name", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("hill_dressing_r10")
			expect(Data.folderName):toBe("LookDevHillDressingR10_hill_dressing_r10")
		end)

		t:it("declares at least three positive-radius hill centres", function()
			expect(Data.HILL_COUNT):toBe(#Data.HILLS)
			expect(Data.HILL_COUNT >= 3):toBe(true)
			for _, hill in ipairs(Data.HILLS) do
				expect(type(hill.x)):toBe("number")
				expect(type(hill.z)):toBe("number")
				expect(hill.radius > 0):toBe(true)
			end
		end)

		t:it("emits at least four rocks and twelve palms per hill, plus terraces", function()
			local rocks, palms, terraces = {}, {}, {}
			for _, part in ipairs(Data.parts()) do
				expect(part.hill >= 1 and part.hill <= Data.HILL_COUNT):toBe(true)
				expect(type(part.name)):toBe("string")
				expect(#part.position == 3 and #part.size == 3):toBe(true)
				if part.kind == "rock" then
					expect(part.shape == "Ball" or part.shape == "Wedge"):toBe(true)
					rocks[part.hill] = (rocks[part.hill] or 0) + 1
				elseif part.kind == "palm" then
					expect(part.shape):toBe("Block")
					expect(#part.crownSize == 3):toBe(true)
					palms[part.hill] = (palms[part.hill] or 0) + 1
				elseif part.kind == "terrace" then
					terraces[part.hill] = (terraces[part.hill] or 0) + 1
				end
			end
			for hill = 1, Data.HILL_COUNT do
				expect((rocks[hill] or 0) >= 4):toBe(true)
				expect((palms[hill] or 0) >= 12):toBe(true)
			end
			expect((terraces[1] or 0) >= 1):toBe(true)
		end)

		t:it("keeps every colour channel in 0..255", function()
			for _, part in ipairs(Data.parts()) do
				for _, color in ipairs({ part.color, part.crownColor }) do
					if color then
						for _, channel in ipairs({ color.r, color.g, color.b }) do
							expect(channel >= 0 and channel <= 255):toBe(true)
						end
					end
				end
			end
		end)

		t:it("stays deterministic and fresh across requires", function()
			local first, second = Data.parts(), Data.parts()
			expect(serialize(first)):toBe(serialize(second))
			expect(first ~= second):toBe(true)
			expect(first[1] ~= second[1]):toBe(true)
			local fresh = Env.new():require("shared/ModelMapHillDressingR10")
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
		end)
	end)
end
