--!nocheck
-- WORK_QUEUE item 204 (SPRINT 1): LUNE-ONLY pure-data contract for "bamboo_bridge_r10".
-- Studio staging and the BRIDGE_* checks live in tools/studio/check_q204.luau; LookDev IDS and
-- review wiring belong to the main session. This spec asserts neither.

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

local function near(a, b, tolerance)
	return math.abs(a - b) <= tolerance
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapBambooBridgeR10")
	local pureSrc = fs.readFile("src/shared/ModelMapBambooBridgeR10.luau")
	local parts = Data.parts()

	local function byKind(kind)
		local out = {}
		for _, part in ipairs(parts) do
			if part.kind == kind then
				out[#out + 1] = part
			end
		end
		return out
	end

	t:describe("bamboo_bridge_r10 pure data", function()
		t:it("stays pure and carries the exact stage identity", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			expect(Data.id):toBe("bamboo_bridge_r10")
			expect(Data.folderName):toBe("LookDevBambooBridgeR10_bamboo_bridge_r10")
			expect(Data.BRIDGE_WIDTH):toBe(6)
			expect(Data.BRIDGE_START):toEqual({ x = 0, y = 1.5, z = 276 })
			expect(Data.BRIDGE_END):toEqual({ x = 0, y = 1.5, z = 332 })
			expect(Data.BRIDGE_END.z - Data.BRIDGE_START.z):toBe(56)
		end)

		t:it("builds at least ten bamboo planks spanning the 6-stud lane", function()
			local deck = byKind("deck")
			expect(#deck >= 10):toBe(true)
			expect(#deck):toBe(Data.PLANK_COUNT)
			for _, plank in ipairs(deck) do
				expect(plank.shape):toBe("Block")
				expect(plank.size[1]):toBe(6)
				expect(near(plank.size[2], 0.5, 1e-6)):toBe(true)
				expect(plank.position[1]):toBe(0)
				expect(plank.position[2] < Data.BRIDGE_START.y):toBe(true)
				expect(plank.position[3] > Data.BRIDGE_START.z):toBe(true)
				expect(plank.position[3] < Data.BRIDGE_END.z):toBe(true)
			end
		end)

		t:it("places exactly two round rails on opposite sides", function()
			local left, right = byKind("rail_left"), byKind("rail_right")
			expect(#left):toBe(1)
			expect(#right):toBe(1)
			expect(#left + #right):toBe(2)
			expect(left[1].shape):toBe("Cylinder")
			expect(right[1].shape):toBe("Cylinder")
			expect(left[1].position[1] < 0):toBe(true)
			expect(right[1].position[1] > 0):toBe(true)
			expect(near(left[1].position[1], -Data.RAIL_X, 1e-6)):toBe(true)
			expect(near(right[1].position[1], Data.RAIL_X, 1e-6)):toBe(true)
			expect(near(left[1].position[2], 2.0, 1e-6)):toBe(true)
			expect(near(right[1].position[2], 2.0, 1e-6)):toBe(true)
			expect(near(left[1].size[2], 56, 1e-6)):toBe(true)
			expect(near(right[1].size[2], 56, 1e-6)):toBe(true)
		end)

		t:it("crosses the rails with rope and sets two posts at each end", function()
			local ropes, posts = byKind("rope"), byKind("post")
			expect(#ropes):toBe(Data.ROPE_COUNT)
			expect(#ropes > 0):toBe(true)
			for _, rope in ipairs(ropes) do
				expect(rope.shape):toBe("Block")
				expect(rope.size[1] >= Data.RAIL_X * 2):toBe(true)
			end
			expect(#posts >= 4):toBe(true)
			local corners = {}
			for _, post in ipairs(posts) do
				expect(post.shape):toBe("Cylinder")
				local side = if post.position[1] < 0 then "left" else "right"
				local endpoint = if near(post.position[3], Data.BRIDGE_START.z, 1e-6)
					then "start"
					elseif near(post.position[3], Data.BRIDGE_END.z, 1e-6) then "end"
					else "other"
				expect(endpoint ~= "other"):toBe(true)
				corners[side .. "_" .. endpoint] = true
			end
			for _, key in ipairs({ "left_start", "right_start", "left_end", "right_end" }) do
				expect(corners[key]):toBe(true)
			end
		end)

		t:it("uses only the bamboo and wood palette in every descriptor", function()
			local palettes = { Data.BAMBOO_COLOR, Data.WOOD_COLOR }
			expect(Data.BAMBOO_COLOR):toEqual({ r = 186, g = 168, b = 96 })
			expect(Data.WOOD_COLOR):toEqual({ r = 150, g = 112, b = 64 })
			for _, part in ipairs(parts) do
				local match = false
				for _, palette in ipairs(palettes) do
					if
						near(part.color.r, palette.r, 0)
						and near(part.color.g, palette.g, 0)
						and near(part.color.b, palette.b, 0)
					then
						match = true
					end
				end
				expect(match):toBe(true)
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
		end)

		t:it("returns the same descriptors from fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapBambooBridgeR10")
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.BRIDGE_START)):toBe(serialize(Data.BRIDGE_START))
			expect(serialize(fresh.BRIDGE_END)):toBe(serialize(Data.BRIDGE_END))
			local first = Data.parts()
			first[1].color.r = -1
			expect(Data.parts()[1].color.r):toBe(Data.BAMBOO_COLOR.r)
		end)
	end)
end
