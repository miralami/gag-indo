--!nocheck
-- WORK_QUEUE item 204/245/252 (LUNE-ONLY contract) and item 258: the concrete village bridge.
-- Studio staging and the BRIDGE_* checks live in check_q204/check_q245/check_q252/check_q258;
-- LookDev IDs and review wiring belong to the main session.

local fs = require("@lune/fs")

local APPLIER = "src/server/World/LookDevBambooBridgeR10.luau"
local CHECK252 = "tools/studio/check_q252.luau"
local CHECK258 = "tools/studio/check_q258.luau"

local CHECK_NAMES = {
	"BRIDGE_WALKABLE",
	"BRIDGE_RAILS",
	"BRIDGE_SWAP",
	"LOOKDEV_LEAK",
	"BRIDGE_COLORS",
	"CAL_BRIDGE_COLORS_FAIL",
	"CAL_LOOKDEV_LEAK_FAIL",
}

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

local function quotedList(src, anchor)
	local body = string.match(src, "local " .. anchor .. " = {(.-)}")
	local out = {}
	if body then
		for value in string.gmatch(body, '"([^"]+)"') do
			out[#out + 1] = value
		end
	end
	return out
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapBambooBridgeR10")
	local pureSrc = fs.readFile("src/shared/ModelMapBambooBridgeR10.luau")
	local applierSrc = fs.readFile(APPLIER)
	local check252Src = fs.readFile(CHECK252)
	local check258Src = fs.readFile(CHECK258)
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

		t:it("keeps fourteen dark concrete deck slabs across the 6-stud lane", function()
			local deck = byKind("deck")
			expect(#deck):toBe(14)
			expect(#deck):toBe(Data.PLANK_COUNT)
			for _, slab in ipairs(deck) do
				expect(slab.shape):toBe("Block")
				expect(slab.material):toBe("Concrete")
				expect(slab.size[1]):toBe(6)
				expect(slab.size[2]):toBe(Data.PLANK_THICKNESS)
				expect(near(slab.size[1], Data.BRIDGE_WIDTH, 1e-6)):toBe(true)
				expect(slab.position[1]):toBe(0)
				expect(slab.position[2] < Data.BRIDGE_START.y):toBe(true)
				expect(slab.position[3] > Data.BRIDGE_START.z):toBe(true)
				expect(slab.position[3] < Data.BRIDGE_END.z):toBe(true)
				for _, channel in ipairs({ slab.color.r, slab.color.g, slab.color.b }) do
					expect(channel < 90):toBe(true)
				end
			end
		end)

		t:it("places two black Cylinder pipe rails per side at 0.85 and 1.7 studs above the deck", function()
			local left, right = byKind("rail_left"), byKind("rail_right")
			expect(#left):toBe(2)
			expect(#right):toBe(2)
			for _, group in ipairs({ left, right }) do
				local heights = {}
				for _, rail in ipairs(group) do
					expect(rail.shape):toBe("Cylinder")
					expect(rail.material):toBe("Metal")
					expect(near(rail.size[1], Data.RAIL_DIAMETER, 1e-6)):toBe(true)
					expect(near(rail.size[3], rail.size[1], 1e-6)):toBe(true)
					expect(near(rail.size[2], 56, 1e-6)):toBe(true)
					expect(rail.color.r < 60 and rail.color.g < 60 and rail.color.b < 60):toBe(true)
					heights[#heights + 1] = rail.position[2] - Data.BRIDGE_START.y
				end
				table.sort(heights)
				expect(near(heights[1], 0.85, 1e-6)):toBe(true)
				expect(near(heights[2], 1.7, 1e-6)):toBe(true)
			end
			expect(left[1].position[1] < 0):toBe(true)
			expect(right[1].position[1] > 0):toBe(true)
			expect(near(left[1].position[1], -Data.RAIL_X, 1e-6)):toBe(true)
			expect(near(right[1].position[1], Data.RAIL_X, 1e-6)):toBe(true)
		end)

		t:it("sets yellow Metal square posts every 4 studs along both edges", function()
			local posts = byKind("post")
			local perSide = { left = {}, right = {} }
			for _, post in ipairs(posts) do
				expect(post.shape):toBe("Block")
				expect(post.material):toBe("Metal")
				expect(post.size[1]):toBe(post.size[3])
				expect(near(post.size[1], 0.45, 1e-6)):toBe(true)
				expect(near(post.size[2], 1.9, 1e-6)):toBe(true)
				expect(post.color.r > post.color.g and post.color.g > post.color.b):toBe(true)
				expect(near(post.color.r, 230, 12) and near(post.color.g, 190, 12) and near(post.color.b, 30, 12)):toBe(
					true
				)
				expect(near(post.position[2] - post.size[2] / 2, Data.BRIDGE_START.y, 1e-6)):toBe(true)
				local list = perSide[if post.position[1] < 0 then "left" else "right"]
				list[#list + 1] = post.position[3]
			end
			for _, zs in pairs(perSide) do
				expect(#zs >= 4):toBe(true)
				table.sort(zs)
				for index = 2, #zs do
					expect(near(zs[index] - zs[index - 1], 4, 1e-6)):toBe(true)
				end
				expect(zs[1] > Data.BRIDGE_START.z):toBe(true)
				expect(zs[#zs] < Data.BRIDGE_END.z):toBe(true)
			end
			expect(#perSide.left):toBe(#perSide.right)
		end)

		t:it("keeps the walking lane clear of posts, rails, pillars and chips", function()
			for _, part in ipairs(parts) do
				if part.kind ~= "deck" and part.kind ~= "curb" and part.kind ~= "abutment" then
					local inner = math.abs(part.position[1]) - part.size[1] / 2
					expect(inner >= Data.LANE_HALF):toBe(true)
				end
			end
		end)

		t:it("builds four thicker white Cobblestone pillars with a Slate chip pattern", function()
			local pillars, stones = byKind("pillar"), byKind("pillar_stone")
			expect(#pillars):toBe(4)
			expect(#stones):toBe(4 * Data.STONE_CHIPS_PER_PILLAR)
			expect(#stones):toBe(16)
			local sides, ends = {}, {}
			for _, pillar in ipairs(pillars) do
				expect(pillar.shape):toBe("Block")
				expect(pillar.material):toBe("Cobblestone")
				expect(pillar.size[1] > 2 * byKind("post")[1].size[1]):toBe(true)
				for _, channel in ipairs({ pillar.color.r, pillar.color.g, pillar.color.b }) do
					expect(channel > 200):toBe(true)
				end
				sides[pillar.position[1] < 0 and "left" or "right"] = true
				ends[pillar.position[3] == Data.BRIDGE_START.z and "start" or "end"] = true
			end
			expect(sides.left):toBe(true)
			expect(sides.right):toBe(true)
			expect(ends.start):toBe(true)
			expect(ends["end"]):toBe(true)
			local stoneColors, stoneShades = {}, 0
			for _, stone in ipairs(stones) do
				expect(stone.material):toBe("Slate")
				expect(stone.size[3] < 0.25):toBe(true)
				stoneColors[stone.color.r .. "," .. stone.color.g .. "," .. stone.color.b] = true
			end
			for _ in pairs(stoneColors) do
				stoneShades += 1
			end
			expect(stoneShades >= 3):toBe(true)
		end)

		t:it("sets a stone abutment at each bank end of the deck", function()
			local abutments = byKind("abutment")
			expect(#abutments):toBe(2)
			local ends = {}
			for _, abutment in ipairs(abutments) do
				expect(abutment.material):toBe("Cobblestone")
				expect(abutment.position[2] + abutment.size[2] / 2 < Data.BRIDGE_START.y):toBe(true)
				ends[if abutment.position[3] < Data.BRIDGE_START.z + 8 then "start" else "end"] = true
			end
			expect(ends.start and ends["end"]):toBe(true)
		end)

		t:it("stripes both deck edges with alternating black and white curb blocks", function()
			local curbs = byKind("curb")
			expect(#curbs):toBe(2 * Data.CURB_SEGMENTS)
			expect(#curbs):toBe(112)
			local dark, light = 0, 0
			for _, curb in ipairs(curbs) do
				expect(curb.shape):toBe("Block")
				if serialize(curb.color) == serialize(Data.CURB_DARK_COLOR) then
					dark += 1
				elseif serialize(curb.color) == serialize(Data.CURB_LIGHT_COLOR) then
					light += 1
				end
			end
			expect(dark):toBe(56)
			expect(light):toBe(56)
		end)

		t:it("uses only the declared concrete palette and returns fresh deterministic data", function()
			local palettes = {
				Data.DECK_COLOR,
				Data.POST_COLOR,
				Data.RAIL_COLOR,
				Data.PILLAR_COLOR,
				Data.CURB_DARK_COLOR,
				Data.CURB_LIGHT_COLOR,
				Data.ABUTMENT_COLOR,
			}
			for _, stone in ipairs(Data.STONE_COLORS) do
				palettes[#palettes + 1] = stone
			end
			for _, part in ipairs(parts) do
				local match = false
				for _, palette in ipairs(palettes) do
					if serialize(part.color) == serialize(palette) then
						match = true
					end
				end
				expect(match):toBe(true)
				for _, channel in ipairs({ part.color.r, part.color.g, part.color.b }) do
					expect(channel >= 0 and channel <= 255):toBe(true)
				end
			end
			expect(#parts):toBe(178)
			local fresh = Env.new():require("shared/ModelMapBambooBridgeR10")
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.BRIDGE_START)):toBe(serialize(Data.BRIDGE_START))
			expect(serialize(fresh.BRIDGE_END)):toBe(serialize(Data.BRIDGE_END))
			local first = Data.parts()
			first[1].color.r = -1
			expect(Data.parts()[1].color.r):toBe(Data.DECK_COLOR.r)
		end)

		t:it("describes the baked model without embedding its asset id", function()
			expect(type(Data.model)):toBe("table")
			expect(Data.model.name):toBe("ConcreteBridgeSlab")
			expect(Data.model.role):toBe("model")
			expect(Data.model.targetWidth):toBe(6)
			expect(Data.model.position[1]):toBe(0)
			expect(Data.model.position[2]):toBe(1.2)
			expect(Data.model.position[3]):toBe(282)
			expect(serialize(Data.model.color)):toBe(serialize(Data.DECK_COLOR))
			expect(applierSrc:find("local ASSET_ID = 8029943234", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find(".baked(ASSET_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("require(script.Parent.LookDevAssetLoader)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("LuaSourceContainer", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("child.CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("child.CastShadow = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("SetAttribute(STAGE_ATTR, FAMILY_ID)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('IsA("UnionOperation")', 1, true) ~= nil):toBe(true)
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

		t:it("keeps the exact check_q252 SERVER-VM check lines, targets and FAIL calibrations", function()
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
				expect(check252Src:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(check252Src:find('COVERAGE_CAMERA = "bridge_side"', 1, true) ~= nil):toBe(true)
			expect(check252Src:find('COVERAGE_AWAY_CAMERA = "horizon_north"', 1, true) ~= nil):toBe(true)
			expect(check252Src:find("COVERAGE_TARGET = 0.3", 1, true) ~= nil):toBe(true)
			expect(check252Src:find('BAMBOO_TARGET_TEXT = "0.80"', 1, true) ~= nil):toBe(true)
			expect(check252Src:find("coverage.measure(CANDIDATE_ID, COVERAGE_CAMERA)", 1, true) ~= nil):toBe(true)
			expect(check252Src:find("review.enableAdditive(CANDIDATE_ID, game)", 1, true) ~= nil):toBe(true)
			expect(check252Src:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(check252Src:find("countTaggedLeftovers()", 1, true) ~= nil):toBe(true)
			expect(check252Src:find('instance:GetAttribute("LookDevStage") == CANDIDATE_ID', 1, true) ~= nil):toBe(true)
			expect(check252Src:find("measureRestore(snapshot)", 1, true) ~= nil):toBe(true)
			expect(check252Src:find("descendantCount", 1, true) == nil):toBe(true)
			expect(check252Src:find('part.Name = "BridgeDeck"', 1, true) ~= nil):toBe(true)
			expect(check252Src:find('part:SetAttribute("LookDevStage", CANDIDATE_ID)', 1, true) ~= nil):toBe(true)
			expect(check252Src:find("destroyInjected()", 1, true) ~= nil):toBe(true)
		end)
	end)

	t:describe("bamboo_bridge_r10 item 258 concrete village bridge", function()
		t:it("check_q258 declares the exact seven SERVER-VM CHECK_NAMES", function()
			expect(quotedList(check258Src, "CHECK_NAMES")):toEqual(CHECK_NAMES)
			expect(check258Src:find('CANDIDATE_ID = "bamboo_bridge_r10"', 1, true) ~= nil):toBe(true)
			expect(check258Src:find('BRIDGE_COLORS = "3/3"', 1, true) ~= nil):toBe(true)
			expect(check258Src:find("CHECK ", 1, true) ~= nil):toBe(true)
			expect(check258Src:find("SUMMARY_Q258 CHECKS %d/%d CAL %d/%d", 1, true) ~= nil):toBe(true)
			for _, token in ipairs({ "Players", "LocalPlayer", "IsClient", "OnClientEvent" }) do
				expect(check258Src:find(token, 1, true) == nil):toBe(true)
			end
		end)

		t:it("check_q258 measures the live lane, rails, swap, colours and leak", function()
			for _, token in ipairs({
				"RaycastParams.new()",
				"Enum.RaycastFilterType.Include",
				"workspace:Raycast(",
				"BRIDGE_WALKABLE",
				'GetAttribute("role")',
				'GetAttribute("BambooBridge")',
				'GetAttribute("LookDevStage")',
				"Enum.PartType.Cylinder",
				"color.r < 60",
				"color.r > 200",
				"transparency == 1",
				"canCollide == false",
				"measureRestore(snapshot)",
				"review.enableAdditive(CANDIDATE_ID, game)",
				"review.disableAll()",
			}) do
				expect(check258Src:find(token, 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("check_q258 measures two rails per side, their heights and a clear lane", function()
			for _, token in ipairs({
				"#walkAfter.roles[role] == 2",
				"deckTop + 0.85",
				"deckTop + 1.7",
				"laneIntrusions",
				"walkAfter.intrusions == 0",
			}) do
				expect(check258Src:find(token, 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("check_q258 calibrates both colour and leak failures without weakening targets", function()
			expect(check258Src:find("injectBluePost()", 1, true) ~= nil):toBe(true)
			expect(check258Src:find("Color3.fromRGB(40, 80, 200)", 1, true) ~= nil):toBe(true)
			expect(check258Src:find('part:SetAttribute("role", "post")', 1, true) ~= nil):toBe(true)
			expect(check258Src:find("CAL_BRIDGE_COLORS_FAIL", 1, true) ~= nil):toBe(true)
			expect(check258Src:find("injectTaggedLeak()", 1, true) ~= nil):toBe(true)
			expect(check258Src:find('part:SetAttribute("LookDevStage", CANDIDATE_ID)', 1, true) ~= nil):toBe(true)
			expect(check258Src:find("CAL_LOOKDEV_LEAK_FAIL", 1, true) ~= nil):toBe(true)
			expect(check258Src:find("destroyInjected()", 1, true) ~= nil):toBe(true)
		end)
	end)
end
