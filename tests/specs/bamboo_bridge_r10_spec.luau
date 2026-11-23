--!nocheck
-- WORK_QUEUE item 204 (SPRINT 1), item 245 (SPRINT 2), item 252 (SPRINT 3): LUNE-ONLY pure-data
-- contract for "bamboo_bridge_r10". Studio staging and the BRIDGE_* checks live in
-- check_q204/check_q245/check_q252; LookDev IDS and review wiring belong to the main session.

local fs = require("@lune/fs")

local APPLIER = "src/server/World/LookDevBambooBridgeR10.luau"
local CHECK = "tools/studio/check_q252.luau"

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
	local applierSrc = fs.readFile(APPLIER)
	local checkSrc = fs.readFile(CHECK)
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
			expect(string.find(pureSrc, "%d%d%d%d%d%d%d%d") == nil):toBe(true) -- no asset IDs
			expect(Data.id):toBe("bamboo_bridge_r10")
			expect(Data.folderName):toBe("LookDevBambooBridgeR10_bamboo_bridge_r10")
			expect(Data.BRIDGE_WIDTH):toBe(6)
			expect(Data.BRIDGE_START):toEqual({ x = 0, y = 1.5, z = 276 })
			expect(Data.BRIDGE_END):toEqual({ x = 0, y = 1.5, z = 332 })
			expect(Data.BRIDGE_END.z - Data.BRIDGE_START.z):toBe(56)
		end)

		t:it("builds fourteen Cylinder bamboo culms spanning the 6-stud lane", function()
			local deck = byKind("deck")
			expect(#deck >= 10):toBe(true)
			expect(#deck):toBe(Data.PLANK_COUNT)
			expect(Data.PLANK_COUNT):toBe(14)
			for _, culm in ipairs(deck) do
				expect(culm.shape):toBe("Cylinder")
				expect(culm.size[2]):toBe(6)
				expect(near(culm.size[1], Data.PLANK_THICKNESS, 1e-6)):toBe(true)
				expect(near(culm.size[3], culm.size[1], 1e-6)):toBe(true) -- round, not an ellipse
				expect(culm.position[1]):toBe(0)
				expect(culm.position[2] < Data.BRIDGE_START.y):toBe(true)
				expect(culm.position[3] > Data.BRIDGE_START.z):toBe(true)
				expect(culm.position[3] < Data.BRIDGE_END.z):toBe(true)
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

		t:it("rings every culm and rail with thin deterministic Cylinder nodes", function()
			local deckNodes, railNodes = byKind("node_deck"), byKind("node_rail")
			local span = Data.BRIDGE_END.z - Data.BRIDGE_START.z
			expect(#deckNodes):toBe(Data.PLANK_COUNT * Data.DECK_NODES_PER_CULM)
			expect(#railNodes):toBe(2 * math.floor(span / Data.RAIL_NODE_STEP))
			expect(#deckNodes):toBe(28)
			expect(#railNodes):toBe(14)
			local deckZ = {}
			for _, culm in ipairs(byKind("deck")) do
				deckZ[culm.position[3]] = true
			end
			for _, node in ipairs(deckNodes) do
				expect(node.shape):toBe("Cylinder")
				expect(node.size[2] <= 0.25):toBe(true)
				expect(node.size[1] > Data.PLANK_THICKNESS):toBe(true)
				expect(deckZ[node.position[3]]):toBe(true)
				expect(math.abs(node.position[1]) <= Data.BRIDGE_WIDTH / 2):toBe(true)
			end
			for _, node in ipairs(railNodes) do
				expect(node.shape):toBe("Cylinder")
				expect(node.size[2] <= 0.25):toBe(true)
				expect(node.size[1] > Data.RAIL_DIAMETER):toBe(true)
				expect(near(math.abs(node.position[1]), Data.RAIL_X, 1e-6)):toBe(true)
				expect(near(node.position[2], Data.RAIL_Y, 1e-6)):toBe(true)
				expect(node.position[3] > Data.BRIDGE_START.z):toBe(true)
				expect(node.position[3] < Data.BRIDGE_END.z):toBe(true)
			end
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

		t:it("uses only the bamboo, node and wood palette in every descriptor", function()
			local palettes = { Data.BAMBOO_COLOR, Data.BAMBOO_NODE_COLOR, Data.WOOD_COLOR }
			expect(Data.BAMBOO_COLOR):toEqual({ r = 186, g = 168, b = 96 })
			expect(Data.BAMBOO_NODE_COLOR):toEqual({ r = 160, g = 144, b = 82 })
			expect(Data.WOOD_COLOR):toEqual({ r = 150, g = 112, b = 64 })
			-- Straw spread: red > green > blue; nodes are a darker straw, not wood.
			expect(Data.BAMBOO_COLOR.r > Data.BAMBOO_COLOR.g):toBe(true)
			expect(Data.BAMBOO_COLOR.g > Data.BAMBOO_COLOR.b):toBe(true)
			expect(Data.BAMBOO_NODE_COLOR.r < Data.BAMBOO_COLOR.r):toBe(true)
			expect(Data.BAMBOO_NODE_COLOR.g < Data.BAMBOO_COLOR.g):toBe(true)
			expect(Data.BAMBOO_NODE_COLOR.b < Data.BAMBOO_COLOR.b):toBe(true)
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
			expect(#Data.parts()):toBe(69)
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.BRIDGE_START)):toBe(serialize(Data.BRIDGE_START))
			expect(serialize(fresh.BRIDGE_END)):toBe(serialize(Data.BRIDGE_END))
			local first = Data.parts()
			first[1].color.r = -1
			expect(Data.parts()[1].color.r):toBe(Data.BAMBOO_COLOR.r)
		end)
	end)

	t:describe("item 252 default bridge swap", function()
		t:it("hides the named Greybox bridge parts and saves their exact values for LIFO restore", function()
			for _, name in ipairs({ "BridgeDeck", "BridgePost", "BridgeRail", "BridgeRamp" }) do
				expect(applierSrc:find(name .. " = true", 1, true) ~= nil):toBe(true)
			end
			expect(applierSrc:find("hideDefaultBridge()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("GetDescendants()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('saveValue(instance, "Transparency"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('saveValue(instance, "CanCollide"', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.Transparency = 1", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("for index = #savedOrder, 1, -1 do", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("entry.target[entry.prop] = entry.value", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("entry.target:SetAttribute(entry.prop, entry.value)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("no default bridge parts found to swap", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps the exact SERVER-VM check lines, targets and FAIL calibrations", function()
			for _, name in ipairs({
				"BRIDGE_SWAP",
				"BRIDGE_RESTORE",
				"SUBJECT_COVERAGE_252",
				"BRIDGE_WALKABLE",
				"BRIDGE_BAMBOO",
				"LOOKDEV_LEAK",
				"CAL_BRIDGE_SWAP_FAIL",
				"CAL_COVERAGE_252_FAIL",
				"CAL_LOOKDEV_LEAK_FAIL",
				"CAL_BRIDGE_WALKABLE_FAIL",
				"CAL_BRIDGE_BAMBOO_FAIL",
			}) do
				expect(checkSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find('COVERAGE_CAMERA = "bridge_side"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('COVERAGE_AWAY_CAMERA = "horizon_north"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("COVERAGE_TARGET = 0.3", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('BAMBOO_TARGET_TEXT = "0.80"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("review.enableAdditive(CANDIDATE_ID, game)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("countTaggedLeftovers()", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('instance:GetAttribute("LookDevStage") == CANDIDATE_ID', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("measureRestore(snapshot)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("descendantCount", 1, true) == nil):toBe(true)
			expect(checkSrc:find('part.Name = "BridgeDeck"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('part:SetAttribute("LookDevStage", CANDIDATE_ID)', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("destroyInjected()", 1, true) ~= nil):toBe(true)
		end)
	end)
end
