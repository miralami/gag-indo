--!nocheck
-- Enum spec: every `Enum.Material.<Name>` written in src/ must be a real Roblox Enum.Material name.
-- Lune's mock Enum accepts any name, so this scan is the only guard against typos such as
-- CorrugatedMetal (the real name is CorrodedMetal), which aborted the world build in Studio.
-- Run from the repository root, like Env (paths are relative to it).

local fs = require("@lune/fs")

return function(t, Env, Fakes)
	local expect = t.expect

	local VALID_MATERIALS = {
		"Plastic", "Wood", "Slate", "Concrete", "CorrodedMetal", "DiamondPlate", "Foil", "Grass",
		"Ice", "Marble", "Granite", "Brick", "Pebble", "Sand", "Fabric", "SmoothPlastic", "Metal",
		"WoodPlanks", "Cobblestone", "Air", "Water", "Rock", "Glacier", "Snow", "Sandstone", "Mud",
		"Basalt", "Ground", "CrackedLava", "Asphalt", "LeafyGrass", "Salt", "Limestone", "Pavement",
		"Neon", "Glass", "ForceField", "Cardboard", "Carpet", "CeramicTiles", "ClayRoofTiles",
		"RoofShingles", "Leather", "Plaster", "Rubber",
	}

	local valid = {}
	for _, name in VALID_MATERIALS do
		valid[name] = true
	end

	-- Every Enum.Material.<Name> in `source` whose name is not in the valid list.
	-- Returns a list of { file = ..., material = ... }.
	local function findBadMaterials(source: string, file: string)
		local bad = {}
		for name in string.gmatch(source, "Enum%.Material%.([%w_]+)") do
			if not valid[name] then
				table.insert(bad, { file = file, material = name })
			end
		end
		return bad
	end

	-- Recursively collect the path of every .luau file under `path`.
	local function collectLuauFiles(path: string, out: { string })
		for _, entry in fs.readDir(path) do
			local full = path .. "/" .. entry
			if fs.isDir(full) then
				collectLuauFiles(full, out)
			elseif string.match(entry, "%.luau$") then
				table.insert(out, full)
			end
		end
		return out
	end

	t:describe("Enum.Material names", function()
		t:it("every Enum.Material name used under src/ is a valid Roblox material", function()
			local files = collectLuauFiles("src", {})
			expect(#files):toBeAtLeast(1)

			local problems = {}
			for _, file in files do
				local source = fs.readFile(file)
				for _, hit in findBadMaterials(source, file) do
					table.insert(problems, `{hit.file}: Enum.Material.{hit.material} is not a valid Roblox material`)
				end
			end

			if #problems > 0 then
				error("invalid Enum.Material names found:\n  " .. table.concat(problems, "\n  "), 0)
			end
		end)

		t:it("the matcher flags Enum.Material.CorrugatedMetal (self-check)", function()
			local bad = findBadMaterials("Enum.Material.CorrugatedMetal", "literal")
			expect(#bad):toBeAtLeast(1)
			expect(bad[1].material):toBe("CorrugatedMetal")
		end)
	end)
end
