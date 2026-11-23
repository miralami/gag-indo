--!nocheck
-- Item 208 data-only guard: the DEFAULT look has one tagged packed-earth pad under the five Pasar
-- stall counters and 30 tagged crates/baskets/sacks at the lapak. This spec reads source and the
-- pure Details recipe table only; live Studio measurement stays in tools/studio/check_q208.luau.

local fs = require("@lune/fs")

local GREYBOX = "src/server/World/Greybox.luau"
local DETAILS = "src/server/World/Details.luau"
local CHECK = "tools/studio/check_q208.luau"
local TOL = 0.05

local function field(block, key)
	return tonumber(block:match(key .. "%s*=%s*([%d%.%-]+)"))
end

return function(t, Env)
	local expect = t.expect
	local greyboxSrc = fs.readFile(GREYBOX)
	local detailsSrc = fs.readFile(DETAILS)
	local checkSrc = fs.readFile(CHECK)
	local env = Env.new()
	env.globals.Color3 = {
		fromHex = function(hex)
			return {
				hex = hex,
				Lerp = function(self)
					return self
				end,
			}
		end,
		fromRGB = function(r, g, b)
			return { R = r, G = g, B = b }
		end,
		new = function(r, g, b)
			return { R = r, G = g, B = b }
		end,
	}
	local MapSpec = env:require("server/World/MapSpec")
	local Details = env:require("server/World/Details")
	local hub = MapSpec.hub("pasar")

	local function boxIn(hubRef, lx, lz, width, depth)
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, corner in ipairs({
			{ -width / 2, -depth / 2 },
			{ width / 2, -depth / 2 },
			{ -width / 2, depth / 2 },
			{ width / 2, depth / 2 },
		}) do
			local x, z = MapSpec.hubPoint(hubRef, lx + corner[1], lz + corner[2])
			minX, maxX = math.min(minX, x), math.max(maxX, x)
			minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
		end
		return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
	end

	local function box(lx, lz, width, depth)
		return boxIn(hub, lx, lz, width, depth)
	end

	local function contains(outer, inner)
		return outer.minX - TOL <= inner.minX
			and outer.maxX + TOL >= inner.maxX
			and outer.minZ - TOL <= inner.minZ
			and outer.maxZ + TOL >= inner.maxZ
	end

	local function rectHit(a, b)
		return math.min(a.maxX, b.maxX) - math.max(a.minX, b.minX) > TOL
			and math.min(a.maxZ, b.maxZ) - math.max(a.minZ, b.minZ) > TOL
	end

	t:describe("item 208 pasar pad and spill", function()
		t:it("Greybox builds one tagged, non-collidable paved pad", function()
			local padDef = greyboxSrc:match("local PASAR_PAD = {(.-)}")
			expect(padDef ~= nil):toBe(true)
			expect(field(padDef, "width") == 64):toBe(true)
			expect(field(padDef, "depth") == 44):toBe(true)
			expect(field(padDef, "thickness") ~= nil):toBe(true)
			expect(greyboxSrc:find('Name = "PasarPad"', 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find('SetAttribute("PasarPad", true)', 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find("Enum.Material.Pavement", 1, true) ~= nil):toBe(true)
			local padBody = greyboxSrc:match('Name = "PasarPad"(.-)pad:SetAttribute')
			expect(padBody ~= nil):toBe(true)
			expect(padBody:find("CanCollide = false", 1, true) ~= nil):toBe(true)
		end)

		t:it("pad footprint covers every StallCounter from buildPasar", function()
			local padDef = greyboxSrc:match("local PASAR_PAD = {(.-)}")
			local padBox = box(field(padDef, "lx"), field(padDef, "lz"), field(padDef, "width"), field(padDef, "depth"))
			-- Greybox: `for booth = -2, 2 do local lx = booth * 11 ... StallCounter ... Vector3.new(9, 0.4, 4)`.
			expect(greyboxSrc:find("for booth = -2, 2 do", 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find('"StallCounter"', 1, true) ~= nil):toBe(true)
			expect(greyboxSrc:find("local lx = booth * 11", 1, true) ~= nil):toBe(true)
			for booth = -2, 2 do
				expect(contains(padBox, box(booth * 11, -6, 9, 4))):toBe(true)
			end
		end)

		t:it("pad clears all six hub door lanes", function()
			local padDef = greyboxSrc:match("local PASAR_PAD = {(.-)}")
			local padBox = box(field(padDef, "lx"), field(padDef, "lz"), field(padDef, "width"), field(padDef, "depth"))
			for _, key in ipairs(MapSpec.HUB_ORDER) do
				local other = MapSpec.hub(key)
				local lane = boxIn(other, 0, other.depth / 2 + 12, 6, 24)
				expect(rectHit(padBox, lane)):toBe(false)
			end
		end)

		t:it("Details carries at least 30 lapak crates, baskets and sacks", function()
			local recipes = Details.PASAR_SPILL
			expect(type(recipes) == "table"):toBe(true)
			expect(#recipes >= 30):toBe(true)
			local kinds = { Crate = 0, Basket = 0, Sack = 0 }
			local padDef = greyboxSrc:match("local PASAR_PAD = {(.-)}")
			local padBox = box(field(padDef, "lx"), field(padDef, "lz"), field(padDef, "width"), field(padDef, "depth"))
			local byBooth = {}
			for _, recipe in ipairs(recipes) do
				expect(recipe.shape == "Block" or recipe.shape == "Cylinder"):toBe(true)
				expect(recipe.shape == "Ball"):toBe(false)
				for kind in pairs(kinds) do
					if string.find(recipe.name, kind, 1, true) then
						kinds[kind] += 1
						byBooth[recipe.booth] = (byBooth[recipe.booth] or 0) + 1
					end
				end
				local halfX = math.max(recipe.size[1], recipe.size[2]) / 2
				expect(contains(padBox, box(recipe.lx, recipe.lz, halfX * 2, recipe.size[3]))):toBe(true)
			end
			for kind, count in pairs(kinds) do
				expect(count >= 5):toBe(true)
			end
			for booth = -2, 2 do
				expect(byBooth[booth] >= 6):toBe(true)
			end
		end)

		t:it("spill adds no prompts, clicks, asset IDs or Ball geometry", function()
			local spillBody = detailsSrc:match("local function pasarSpill%((.-)\nend")
			expect(spillBody ~= nil):toBe(true)
			expect(spillBody:find("ProximityPrompt", 1, true) == nil):toBe(true)
			expect(spillBody:find("ClickDetector", 1, true) == nil):toBe(true)
			expect(spillBody:find("rbxassetid", 1, true) == nil):toBe(true)
			expect(spillBody:find("assetId", 1, true) == nil):toBe(true)
			expect(spillBody:find('SetAttribute("PasarProp", true)', 1, true) ~= nil):toBe(true)
			expect(detailsSrc:find("pasarSpill(folder)", 1, true) ~= nil):toBe(true)
			-- Baked shrub IDs are unchanged: item 208 introduces no new asset ID anywhere.
			expect(#Details.SHRUB_ASSET_IDS == 3):toBe(true)
		end)

		t:it("studio check keeps all three targets and both failure anchors", function()
			for _, token in ipairs({
				'"PASAR_PAD"',
				'"PASAR_PROPS"',
				'"LANE_CLEAR"',
				'"CAL_PASAR_PAD_FAIL"',
				'"CAL_PASAR_PROPS_FAIL"',
				'"CAL_LANE_CLEAR_FAIL"',
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("hubLanes(MapSpec)", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("OVERLAP_TOL = 0.05", 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('inst.Name == "StallCounter"', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find('SetAttribute("PasarProp", true)', 1, true) ~= nil):toBe(true)
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
		end)
	end)
end
