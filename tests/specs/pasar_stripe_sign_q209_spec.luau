--!nocheck
-- Item 209 data-only guard: the DEFAULT look has >=30 item-179-palette Pasar stripes and one
-- Strings-backed hanging PASAR board, both clear of the six hub door lanes. Reads source and pure
-- data only; live Studio measurement stays in tools/studio/check_q209.luau.

local fs = require("@lune/fs")

local GREYBOX = "src/server/World/Greybox.luau"
local DATA = "src/server/World/PasarDefaultQ209.luau"
local CHECK = "tools/studio/check_q209.luau"
local TOL = 0.05

local function boxIn(hubPoint, hub, lx, lz, width, depth)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, corner in ipairs({
		{ -width / 2, -depth / 2 },
		{ width / 2, -depth / 2 },
		{ -width / 2, depth / 2 },
		{ width / 2, depth / 2 },
	}) do
		local x, z = hubPoint(hub, lx + corner[1], lz + corner[2])
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end

local function rectHit(a, b)
	return math.min(a.maxX, b.maxX) - math.max(a.minX, b.minX) > TOL
		and math.min(a.maxZ, b.maxZ) - math.max(a.minZ, b.minZ) > TOL
end

return function(t, Env)
	local expect = t.expect
	local greyboxSrc = fs.readFile(GREYBOX)
	local dataSrc = fs.readFile(DATA)
	local checkSrc = fs.readFile(CHECK)
	local env = Env.new()
	env.globals.Color3 = {
		fromRGB = function(r, g, b)
			return { R = r / 255, G = g / 255, B = b / 255 }
		end,
	}
	local Data = env:require("server/World/PasarDefaultQ209")
	local Awning = env:require("shared/ModelMapPasarAwningsR8")
	local Strings = env:require("shared/Strings")
	local MapSpec = env:require("server/World/MapSpec")

	t:describe("item 209 Pasar stripes and sign", function()
		t:it("palette is the byte-exact item-179 palette", function()
			expect(#Data.ORDER):toBe(3)
			for _, name in ipairs(Data.ORDER) do
				expect(Awning.COLOURS[name] ~= nil):toBe(true)
				expect(#Data.COLOURS[name]):toBe(3)
				for index = 1, 3 do
					expect(Data.COLOURS[name][index]):toBe(Awning.COLOURS[name][index])
				end
			end
			expect(Data.MIN_STRIPES):toBe(Awning.MIN_STRIPES)
			expect(Data.MIN_STRIPES >= 30):toBe(true)
		end)

		t:it("has at least 30 stripe entries with V >= 0.6 and all three primaries", function()
			expect(#Data.STRIPES >= 30):toBe(true)
			local seen, minValue = {}, math.huge
			for _, stripe in ipairs(Data.STRIPES) do
				local rgb = Data.COLOURS[stripe.colour]
				expect(rgb ~= nil):toBe(true)
				expect(stripe.width > 0 and stripe.depth > 0):toBe(true)
				minValue = math.min(minValue, math.max(rgb[1], rgb[2], rgb[3]) / 255)
				seen[stripe.colour] = true
			end
			expect(minValue >= 0.6):toBe(true)
			expect(seen.red == true and seen.white == true and seen.blue == true):toBe(true)
		end)

		t:it("stripes and board clear all six hub door lanes", function()
			local lanes = {}
			for _, key in ipairs(MapSpec.HUB_ORDER) do
				local hub = MapSpec.hub(key)
				lanes[#lanes + 1] = boxIn(MapSpec.hubPoint, hub, 0, hub.depth / 2 + 12, 6, 24)
			end
			expect(#lanes):toBe(6)
			local hub = MapSpec.hub("pasar")
			for _, stripe in ipairs(Data.STRIPES) do
				local box = boxIn(MapSpec.hubPoint, hub, stripe.lx, stripe.lz, stripe.width, stripe.depth)
				for _, lane in ipairs(lanes) do
					expect(rectHit(box, lane)):toBe(false)
				end
			end
			local board = Data.BOARD
			local boardBox = boxIn(MapSpec.hubPoint, hub, board.lx, board.lz, board.width, board.thickness)
			for _, lane in ipairs(lanes) do
				expect(rectHit(boardBox, lane)):toBe(false)
			end
		end)

		t:it("board uses a Strings key with both variants and no baked text", function()
			local entry = Strings.raw[Data.boardKey]
			expect(entry ~= nil):toBe(true)
			expect(type(entry.id) == "string" and #entry.id > 0):toBe(true)
			expect(type(entry.en) == "string" and #entry.en > 0):toBe(true)
			expect(greyboxSrc:find("Strings.get(SIGN_LANG, key)", 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find('WaitForChild("Shared").Strings', 1, true) ~= nil):toBe(true)
			local block =
				greyboxSrc:match("for _, stripe in ipairs%(PasarDefault%.STRIPES%) do(.-)hubPrompt%(counter, hub%)")
			expect(block ~= nil):toBe(true)
			expect(block:find("SetAttribute(PasarDefault.stripeAttribute, true)", 1, true) ~= nil):toBe(true)
			expect(block:find("SetAttribute(PasarDefault.signAttribute, true)", 1, true) ~= nil):toBe(true)
			for _, banned in ipairs({ "ProximityPrompt", "ClickDetector", "rbxassetid", "assetId" }) do
				expect(block:find(banned, 1, true) == nil):toBe(true)
			end
			expect(dataSrc:find('"' .. Data.boardKey .. '"', 1, true) ~= nil):toBe(true)
		end)

		t:it("studio check keeps both targets, the lane regression and all three anchors", function()
			for _, token in ipairs({
				'"STRIPE_VALUE"',
				'"PASAR_SIGN"',
				'"LANE_CLEAR"',
				'"CAL_STRIPE_VALUE_FAIL"',
				'"CAL_PASAR_SIGN_FAIL"',
				'"CAL_LANE_CLEAR_FAIL"',
				"MIN_STRIPE_VALUE = 0.6",
				"MIN_STRIPES = 30",
				"COLOUR_TOL = 12",
				'VALUE_FORMAT = "%.4f"',
				"hubLanes(MapSpec)",
				"OVERLAP_TOL = 0.05",
				"Strings.raw[key]",
				"Color3.new(0.25, 0.25, 0.25)",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
			expect(checkSrc:find("LookDevReview", 1, true) == nil):toBe(true)
		end)
	end)
end
