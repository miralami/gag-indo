--!nocheck
-- WORK_QUEUE item 243 redo: LUNE-ONLY pure-data contract for "mountains_r10".
-- Studio staging (SC243_MOUNTAINS / MF243_MOUNTAIN_FAR / NC243_NO_COLLISION / NB243_NO_GREY_BALL)
-- belongs to check_q243.luau; LookDev IDS wiring belongs to the main session. This spec asserts neither.

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
	local Data = env:require("shared/ModelMapMountainsR10")
	local pureSrc = fs.readFile("src/shared/ModelMapMountainsR10.luau")

	t:describe("mountains_r10 pure data", function()
		t:it("stays pure: no engine calls and no undeclared big ID", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new" }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("mountains_r10")
			expect(Data.folderName):toBe("LookDevMountainsR10_mountains_r10")
			expect(Data.PERF_TARGET):toBe(500)
			expect(Data.PERF_RADIUS):toBe(100)
		end)

		t:it("places at least eight layered silhouettes on the far ring", function()
			local mountains = Data.MOUNTAINS
			expect(type(mountains)):toBe("table")
			expect(#mountains >= 8):toBe(true)
			expect(#Data.mountainParts()):toBe(#mountains)
			local layers = {}
			for _, mountain in ipairs(mountains) do
				expect(type(mountain.name)):toBe("string")
				expect(#mountain.name > 0):toBe(true)
				expect(#mountain.size):toBe(3)
				expect(#mountain.position):toBe(3)
				expect(mountain.shape == "Wedge" or mountain.shape == "Cylinder"):toBe(true)
				expect(mountain.shape ~= "Ball"):toBe(true)
				expect(type(mountain.material) == "string" and #mountain.material > 0):toBe(true)
				local radius = math.sqrt(mountain.position[1] ^ 2 + mountain.position[3] ^ 2)
				expect(radius >= 450):toBe(true)
				expect(mountain.position[2] + mountain.size[2] / 2 >= 64):toBe(true)
				expect(mountain.position[3] <= -470):toBe(true)
				expect(mountain.size[2] <= 180):toBe(true)
				layers[mountain.position[3] <= -700 and "back" or mountain.position[3] <= -560 and "mid" or "front"] =
					true
			end
			expect(layers.back):toBe(true)
			expect(layers.mid):toBe(true)
			expect(layers.front):toBe(true)
		end)

		t:it("uses explicit blue-green materials, never a grey SmoothPlastic Ball", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					expect(type(descriptor.color)):toBe("table")
					expect(descriptor.shape ~= "Ball"):toBe(true)
					expect(type(descriptor.material) == "string" and #descriptor.material > 0):toBe(true)
					local spread = math.max(descriptor.color.r, descriptor.color.g, descriptor.color.b)
						- math.min(descriptor.color.r, descriptor.color.g, descriptor.color.b)
					expect(spread >= 18):toBe(true)
					expect(descriptor.color.b >= descriptor.color.r + 12):toBe(true)
					expect(descriptor.color.g >= descriptor.color.r + 12):toBe(true)
					for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
						expect(type(channel) == "number"):toBe(true)
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("keeps every colour channel in 0..255", function()
			for _, list in ipairs({ Data.mountainParts(), Data.smokeParts() }) do
				for _, descriptor in ipairs(list) do
					expect(type(descriptor.color)):toBe("table")
					for _, channel in ipairs({ descriptor.color.r, descriptor.color.g, descriptor.color.b }) do
						expect(type(channel) == "number")
						expect(channel >= 0 and channel <= 255):toBe(true)
					end
				end
			end
		end)

		t:it("stages a faint smoke Cylinder above the far crest", function()
			local smoke = Data.SMOKE
			expect(type(smoke)):toBe("table")
			expect(#smoke >= 1):toBe(true)
			expect(#Data.smokeParts()):toBe(#smoke)
			local puff = smoke[1]
			expect(puff.shape):toBe("Cylinder")
			expect(type(puff.transparency)):toBe("number")
			expect(puff.transparency > 0 and puff.transparency < 1):toBe(true)
			expect(math.sqrt(puff.position[1] ^ 2 + puff.position[3] ^ 2) >= 450):toBe(true)
			local peak = nil
			for _, mountain in ipairs(Data.MOUNTAINS) do
				if mountain.position[1] == puff.position[1] and mountain.position[3] == puff.position[3] then
					peak = mountain
				end
			end
			expect(peak ~= nil):toBe(true)
			expect(puff.position[2] > peak.position[2] + peak.size[2] / 2):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapMountainsR10")
			expect(serialize(fresh.mountainParts())):toBe(serialize(Data.mountainParts()))
			expect(serialize(fresh.smokeParts())):toBe(serialize(Data.smokeParts()))
		end)
	end)
end
