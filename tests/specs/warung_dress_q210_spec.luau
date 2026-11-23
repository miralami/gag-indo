--!nocheck
-- Item 210 data-only guard: the DEFAULT look has >=4 Warung seats (two existing benches plus two
-- new low stools), a stove, a hanging lantern, no prompts and no lane violations. This reads source
-- and the pure recipe only; live Studio measurement stays in tools/studio/check_q210.luau.

local fs = require("@lune/fs")

local GREYBOX = "src/server/World/Greybox.luau"
local DATA = "src/server/World/WarungDressQ210.luau"
local CHECK = "tools/studio/check_q210.luau"
local PROPS = "src/server/World/Props.luau"
local TOL = 0.05

local function boxAt(MapSpec, hub, lx, lz, width, depth)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, corner in ipairs({
		{ -width / 2, -depth / 2 },
		{ width / 2, -depth / 2 },
		{ width / 2, depth / 2 },
		{ -width / 2, depth / 2 },
	}) do
		local x, z = MapSpec.hubPoint(hub, lx + corner[1], lz + corner[2])
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
	local propsSrc = fs.readFile(PROPS)
	local warungSrc = greyboxSrc:match("local function buildWarung%((.-)local function buildPosPolisi")
	expect(warungSrc ~= nil):toBe(true)

	local env = Env.new()
	env.globals.Color3 = {
		fromHex = function(hex)
			return { hex = hex }
		end,
		fromRGB = function(r, g, b)
			return { R = r, G = g, B = b }
		end,
		new = function(r, g, b)
			return { R = r, G = g, B = b }
		end,
	}
	local Data = env:require("server/World/WarungDressQ210")
	local MapSpec = env:require("server/World/MapSpec")
	local hub = MapSpec.hub("warung")
	local parts = Data.parts(hub)

	t:describe("item 210 Warung seating dressing", function()
		t:it("has at least four tagged seats, derived from the MapSpec benches", function()
			local seats = #hub.benches
			for _, def in ipairs(parts) do
				if def.kind == "seat" then
					seats += 1
				end
			end
			expect(Data.MIN_SEATS):toBe(4)
			expect(seats >= Data.MIN_SEATS):toBe(true)
			expect(#hub.benches):toBe(2)
			expect(warungSrc:find("bench:SetAttribute(WarungDress.TAG, true)", 1, true) ~= nil):toBe(true)
			expect(warungSrc:find('"seat"', 1, true) ~= nil):toBe(true)
		end)

		t:it("places the stove and hanging lantern in front of the anchor", function()
			local stove, lantern = 0, 0
			for _, def in ipairs(parts) do
				expect(def.lz > hub.anchor.lz):toBe(true)
				expect(def.shape == "Block" or def.shape == "Cylinder"):toBe(true)
				if def.kind == "stove" then
					stove += 1
				elseif def.kind == "lantern" then
					lantern += 1
				end
			end
			expect(stove >= 1):toBe(true)
			expect(lantern >= 3):toBe(true)
			expect(warungSrc:find("SetAttribute(WarungDress.TAG, true)", 1, true) ~= nil):toBe(true)
			expect(warungSrc:find("SetAttribute(WarungDress.KIND_ATTR, def.kind)", 1, true) ~= nil):toBe(true)
		end)

		t:it("uses only existing palette colours and is deterministic", function()
			local allowed = {}
			for _, name in ipairs(Data.PALETTE_NAMES) do
				allowed[name] = true
				expect(propsSrc:find(name .. " = Color3.fromHex", 1, true) ~= nil):toBe(true)
			end
			local again = Data.parts(hub)
			expect(#again):toBe(#parts)
			for index, def in ipairs(parts) do
				expect(allowed[def.colour] == true):toBe(true)
				for key, value in pairs(def) do
					expect(again[index][key]):toBe(value)
				end
			end
			expect(dataSrc:find("%d%d%d%d%d%d%d%d") == nil):toBe(true)
		end)

		t:it("has no prompts, interactivity or asset IDs in recipe or staging", function()
			for _, src in ipairs({ dataSrc, warungSrc }) do
				for _, banned in ipairs({ "ProximityPrompt", "ClickDetector", "rbxassetid", "assetId" }) do
					expect(src:find(banned, 1, true) == nil):toBe(true)
				end
			end
			expect(warungSrc:find("hubPrompt(table, hub)", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("Instance.new", 1, true) == nil):toBe(true)
		end)

		t:it("clears all six hub door lanes", function()
			local lanes = {}
			for _, key in ipairs(MapSpec.HUB_ORDER) do
				local other = MapSpec.hub(key)
				lanes[#lanes + 1] = boxAt(MapSpec, other, 0, other.depth / 2 + 12, 6, 24)
			end
			expect(#lanes):toBe(6)
			local boxes = {}
			for _, x in ipairs(hub.benches) do
				boxes[#boxes + 1] = boxAt(MapSpec, hub, x, 10, 4, 1.6)
			end
			for _, def in ipairs(parts) do
				boxes[#boxes + 1] = boxAt(MapSpec, hub, def.lx, def.lz, def.sx, def.sz)
			end
			for _, box in ipairs(boxes) do
				for _, lane in ipairs(lanes) do
					expect(rectHit(box, lane)):toBe(false)
				end
			end
		end)

		t:it("studio check keeps the three targets, three anchors and the scope note", function()
			for _, token in ipairs({
				'"WARUNG_SEATS"',
				'"LANE_CLEAR"',
				'"NOT_INTERACTIVE"',
				'"CAL_WARUNG_SEATS_FAIL"',
				'"CAL_LANE_CLEAR_FAIL"',
				'"CAL_NOT_INTERACTIVE_FAIL"',
				"MIN_SEATS = 4",
				"OVERLAP_TOL = 0.05",
				"hubLanes(MapSpec)",
				"WarungDressKind",
				"ProximityPrompt",
				"ClickDetector",
				"WarungPrompt",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
			expect(checkSrc:find("LookDevReview", 1, true) == nil):toBe(true)
		end)
	end)
end
