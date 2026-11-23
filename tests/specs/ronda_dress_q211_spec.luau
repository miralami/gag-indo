--!nocheck
-- Item 211 data/source guard: the DEFAULT look has >=4 RondaDress props covering all four kinds
-- (kentongan, bench, gardu lamp, rack), inside the Ronda floor, clear of all six 6-stud hub door
-- lanes, with no prompts or asset IDs. This reads source and the pure recipe only; the live Studio
-- measurement (including the staged ronda_tower_r9 TOWER_HEIGHT guard) is tools/studio/check_q211.

local fs = require("@lune/fs")

local GREYBOX = "src/server/World/Greybox.luau"
local DATA = "src/server/World/RondaDressQ211.luau"
local CHECK = "tools/studio/check_q211.luau"
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

-- A Cylinder pitched 90 degrees about local X lies down: its sy (length) becomes local depth.
local function footprint(def)
	if def.pitch then
		return def.sx, def.sy
	end
	return def.sx, def.sz
end

return function(t, Env)
	local expect = t.expect
	local greyboxSrc = fs.readFile(GREYBOX)
	local dataSrc = fs.readFile(DATA)
	local checkSrc = fs.readFile(CHECK)
	local propsSrc = fs.readFile(PROPS)
	local rondaSrc = greyboxSrc:match("local function buildPosRonda%((.-)local TREE_XZ")
	expect(rondaSrc ~= nil):toBe(true)

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
	local Data = env:require("server/World/RondaDressQ211")
	local MapSpec = env:require("server/World/MapSpec")
	local hub = MapSpec.hub("ronda")
	local parts = Data.parts(hub)

	t:describe("item 211 Pos Ronda dressing", function()
		t:it("stages at least four props and all four kinds", function()
			expect(Data.MIN_PROPS):toBe(4)
			expect(#parts >= Data.MIN_PROPS):toBe(true)
			local found = {}
			for _, def in ipairs(parts) do
				found[def.kind] = (found[def.kind] or 0) + 1
				expect(def.shape == "Block" or def.shape == "Cylinder"):toBe(true)
				expect(def.shape ~= "Ball"):toBe(true)
			end
			for _, kind in ipairs(Data.KINDS) do
				expect(found[kind] ~= nil):toBe(true)
			end
			expect(#Data.KINDS):toBe(4)
			expect(rondaSrc:find("RondaDress.parts(hub)", 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find("SetAttribute(RondaDress.TAG, true)", 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find("SetAttribute(RondaDress.KIND_ATTR, def.kind)", 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find('"CellWall"', 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find('"TowerLeg"', 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find("hubAnchor(model, hub)", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps every prop on the floor and clear of all six door lanes", function()
			local lanes = {}
			for _, key in ipairs(MapSpec.HUB_ORDER) do
				local other = MapSpec.hub(key)
				lanes[#lanes + 1] = boxAt(MapSpec, other, 0, other.depth / 2 + 12, 6, 24)
			end
			expect(#lanes):toBe(6)
			local halfX, halfZ = hub.anchor.sx / 2, hub.anchor.sz / 2
			for _, def in ipairs(parts) do
				local width, depth = footprint(def)
				expect(math.abs(def.lx) + width / 2 <= halfX):toBe(true)
				expect(math.abs(def.lz) + depth / 2 <= halfZ):toBe(true)
				local box = boxAt(MapSpec, hub, def.lx, def.lz, width, depth)
				for _, lane in ipairs(lanes) do
					expect(rectHit(box, lane)):toBe(false)
				end
			end
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

		t:it("has no prompts, asset IDs or engine calls in recipe or staging", function()
			for _, src in ipairs({ dataSrc, rondaSrc }) do
				for _, banned in ipairs({ "ProximityPrompt", "ClickDetector", "rbxassetid", "assetId" }) do
					expect(src:find(banned, 1, true) == nil):toBe(true)
				end
			end
			expect(rondaSrc:find("hubPrompt", 1, true) == nil):toBe(true)
			expect(rondaSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(rondaSrc:find("CastShadow = false", 1, true) ~= nil):toBe(true)
			expect(dataSrc:find("Instance.new", 1, true) == nil):toBe(true)
		end)

		t:it("studio check keeps both targets, both anchors and the staged height source", function()
			for _, token in ipairs({
				'"RONDA_PROPS"',
				'"TOWER_HEIGHT"',
				'"CAL_RONDA_PROPS_FAIL"',
				'"CAL_TOWER_HEIGHT_FAIL"',
				'"28..32"',
				"RondaDressKind",
				"RondaTower",
				"GetBoundingBox",
				"enableAdditive",
				"disableAll",
				"MIN_PROPS = 4",
				"TOWER_MIN, TOWER_MAX = 28, 32",
				"synthetic = 36",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("LookDev", 1, true) ~= nil):toBe(true)
		end)
	end)
end
