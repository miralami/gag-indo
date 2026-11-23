--!nocheck
-- Item 215 data-only guard: one gubuk per sawah terrace, two scarecrows in the fields and ribbon
-- poles, all anchored, non-collidable, non-interactive, with no Ball or asset IDs. Live Studio
-- measurement stays in tools/studio/check_q215.luau. The main session must register this spec in
-- tests/run.luau and wire the recipe into Greybox; this file only reads source and pure data.

local fs = require("@lune/fs")

local DATA = "src/shared/ModelMapSawahDressingQ215.luau"
local CHECK = "tools/studio/check_q215.luau"
local PROPS = "src/server/World/Props.luau"

return function(t, Env)
	local expect = t.expect
	local dataSrc = fs.readFile(DATA)
	local checkSrc = fs.readFile(CHECK)
	local propsSrc = fs.readFile(PROPS)

	local env = Env.new()
	local Data = env:require("shared/ModelMapSawahDressingQ215")
	local Canonical = env:require("shared/ModelMapCanonicalR10")
	local Plots = env:require("shared/ModelMapPlotsR8")
	local Sawah = env:require("shared/ModelMapSawahR8")
	local MapSpec = env:require("server/World/MapSpec")
	local panes = MapSpec.paddyWater()
	local parts = Data.parts(panes)

	local function groupsOf(kind)
		local groups = {}
		for _, def in ipairs(parts) do
			if def.kind == kind then
				groups[def.group] = (groups[def.group] or 0) + 1
			end
		end
		return groups
	end

	t:describe("item 215 sawah dressing", function()
		t:it("places one gubuk per terrace, two scarecrows and one ribbon pole per terrace", function()
			local gubuk, scarecrows, ribbons = groupsOf("gubuk"), groupsOf("scarecrow"), groupsOf("ribbon")
			local function count(set)
				local n = 0
				for _ in pairs(set) do
					n += 1
				end
				return n
			end
			expect(Data.MIN_GUBUK):toBe(1)
			expect(Data.MIN_SCARECROWS):toBe(2)
			expect(count(gubuk)):toBe(#Sawah.TERRACE_TOPS)
			expect(count(scarecrows)):toBe(2)
			expect(count(ribbons)):toBe(#Sawah.TERRACE_TOPS)
			for terrace = 1, #Sawah.TERRACE_TOPS do
				expect(gubuk["GubukT" .. terrace]):toBe(if terrace % 2 == 1 then #Sawah.gubukParts() else #Canonical.gubukParts())
				expect(ribbons["RibbonT" .. terrace]):toBe(5)
			end
			expect(scarecrows.ScarecrowA_01):toBe(#Plots.scarecrowParts())
			expect(scarecrows.ScarecrowB_02):toBe(#Plots.scarecrowParts())
		end)

		t:it("reuses the Canonical, Sawah and Plots descriptors with existing palette keys", function()
			for _, token in ipairs({
				"ModelMapCanonicalR10",
				"ModelMapSawahR8",
				"ModelMapPlotsR8",
				"gubukPosition",
				"gubukParts()",
				"scarecrowParts()",
			}) do
				expect(dataSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			local allowed = {}
			for _, name in ipairs(Data.PALETTE_NAMES) do
				allowed[name] = true
				expect(propsSrc:find(name .. " = Color3.fromHex", 1, true) ~= nil):toBe(true)
			end
			for _, def in ipairs(parts) do
				expect(allowed[def.colour] == true):toBe(true)
				expect(def.shape == "Block" or def.shape == "Cylinder" or def.shape == "Wedge"):toBe(true)
				expect(def.shape ~= "Ball"):toBe(true)
				expect(def.group ~= nil and def.kind ~= nil and def.name ~= nil):toBe(true)
				expect(def.anchored):toBe(true)
				expect(def.canCollide):toBe(false)
				expect(def.interactive):toBe(false)
				expect(def.sx > 0 and def.sy > 0 and def.sz > 0):toBe(true)
			end
		end)

		t:it("is deterministic, ID-free and grounded inside its own terrace band", function()
			local again = Data.parts(panes)
			expect(#again):toBe(#parts)
			for index, def in ipairs(parts) do
				for key, value in pairs(def) do
					expect(again[index][key]):toBe(value)
				end
				local band
				for _, candidate in ipairs(MapSpec.TERRACES) do
					if def.z >= candidate.z0 and def.z <= candidate.z1 then
						band = candidate
						break
					end
				end
				expect(band ~= nil):toBe(true)
				expect(def.y - def.sy / 2 >= band.top - 0.5):toBe(true)
			end
			for _, src in ipairs({ dataSrc }) do
				for _, banned in ipairs({ "rbxassetid", "assetId", "ProximityPrompt", "ClickDetector", "Instance.new" }) do
					expect(src:find(banned, 1, true) == nil):toBe(true)
				end
				expect(src:find("%d%d%d%d%d%d%d") == nil):toBe(true)
			end
		end)

		t:it("studio check keeps three targets, three calibrations and the wiring note", function()
			for _, token in ipairs({
				'"GUBUK"',
				'"SCARECROWS"',
				'"NO_FLOATERS"',
				'"CAL_GUBUK_FAIL"',
				'"CAL_SCARECROWS_FAIL"',
				'"CAL_NO_FLOATERS_FAIL"',
				"MIN_GUBUK = 1",
				"MIN_SCARECROWS = 2",
				"FLOATER_TOL = 0.3",
				"SawahDressingKind",
				"SawahDressingGroup",
				"RaycastParams",
				"SawahDressingGroup attribute",
				"wire src/shared/ModelMapSawahDressingQ215.luau into Greybox",
			}) do
				expect(checkSrc:find(token, 1, true) ~= nil):toBe(true)
			end
			expect(checkSrc:find("enableAdditive", 1, true) == nil):toBe(true)
			expect(checkSrc:find("LookDevReview", 1, true) == nil):toBe(true)
		end)
	end)
end
