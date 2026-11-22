--!nocheck
-- LookDevCorner spec (WORK_QUEUE round 3 item 2, item 28 bug 6): pure recipe + thin adapter for the
-- 60x60 warung / road bend / sawah edge corner staged on real PLAZA ground. Locks the new origin,
-- the three saved review cameras, the golden-hour clock, the palette/material allowlists, and V-D1
-- (no outlines) / no-asset-ID rules. No visual verdict here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local RECIPE = "src/shared/LookDevCorner.luau"
	local ADAPTER = "src/client/World/LookDevCorner.luau"
	local EXPECTED_CAMERAS = {
		warung = { position = { -34, 12, -12 }, lookAt = { -28, 4, -26 } },
		road_bend = { position = { -2, 10, 10 }, lookAt = { -2, 1, -9 } },
		sawah_edge = { position = { -14, 8, 16 }, lookAt = { -28, 1, 6 } },
	}

	t:describe("LookDevCorner recipe", function()
		local Corner, LookDev, WorldConstants, Visuals
		t:beforeEach(function()
			local env = Env.new()
			Corner = env:require("shared/LookDevCorner")
			LookDev = env:require("shared/LookDev")
			WorldConstants = env:require("shared/Config/WorldConstants")
			Visuals = env:require("shared/Config/Visuals")
		end)

		t:it("is a 60-stud corner staged on real MapSpec.PLAZA ground", function()
			expect(Corner.SIZE):toBe(60)
			expect(#Corner.ORIGIN):toBe(3)
			expect(Corner.ORIGIN[1]):toBe(-14)
			expect(Corner.ORIGIN[2]):toBe(0)
			expect(Corner.ORIGIN[3]):toBe(-12)
		end)

		t:it("shows the golden-hour midpoint from WorldConstants", function()
			expect(Corner.goldenHourClock):toBe(16.5)
			expect(Corner.goldenHourClock):toBe(
				(WorldConstants.GOLDEN_HOUR.minClock + WorldConstants.GOLDEN_HOUR.maxClock) / 2
			)
		end)

		t:it("has exactly three feature groups and three distinct review cameras", function()
			local groupCount, groups = 0, {}
			for key, value in Corner.groups do
				groupCount += 1
				groups[key] = value
			end
			expect(groupCount):toBe(3)
			expect(groups.warung):toBe("warung")
			expect(groups.road):toBe("road_bend")
			expect(groups.sawah):toBe("sawah_edge")

			expect(#Corner.cameras):toBe(3)
			local ids, seen = {}, {}
			for _, cam in Corner.cameras do
				expect(type(cam.id) == "string" and #cam.id > 0):toBe(true)
				expect(ids[cam.id]):toBe(nil)
				ids[cam.id] = true
				expect(#cam.position):toBe(3)
				expect(#cam.lookAt):toBe(3)
				for _, v in cam.position do
					expect(type(v) == "number"):toBe(true)
				end
				for _, v in cam.lookAt do
					expect(type(v) == "number"):toBe(true)
				end
				local key = table.concat(cam.position, ",")
				expect(seen[key]):toBe(nil)
				seen[key] = true
			end
			expect(ids.warung):toBe(true)
			expect(ids.road_bend):toBe(true)
			expect(ids.sawah_edge):toBe(true)
			for _, cam in Corner.cameras do
				local expected = EXPECTED_CAMERAS[cam.id]
				expect(expected ~= nil):toBe(true)
				expect(cam.position):toEqual(expected.position)
				expect(cam.lookAt):toEqual(expected.lookAt)
			end
		end)

		t:it("keeps every part in-bounds with a valid group, material and palette token", function()
			expect(#Corner.parts >= 15):toBe(true)
			expect(#Corner.parts <= 30):toBe(true)
			local validGroup = {}
			for _, name in Corner.groups do
				validGroup[name] = true
			end
			local half = Corner.SIZE / 2
			for _, part in Corner.parts do
				expect(type(part.name) == "string" and #part.name > 0):toBe(true)
				expect(validGroup[part.group]):toBe(true)
				expect(LookDev.isBuiltinMaterial(part.material)):toBe(true)
				expect(Visuals.palette[part.color] ~= nil):toBe(true)
				expect(#part.size):toBe(3)
				expect(#part.position):toBe(3)
				expect(part.position[1] >= Corner.ORIGIN[1] - half and part.position[1] <= Corner.ORIGIN[1] + half):toBe(
					true
				)
				expect(part.position[3] >= Corner.ORIGIN[3] - half and part.position[3] <= Corner.ORIGIN[3] + half):toBe(
					true
				)
			end
			expect(#Corner.partsInBounds()):toBe(#Corner.parts)
		end)

		t:it("uses no outlines, asset URLs, asset IDs or ID-shaped literals in either source", function()
			for _, path in { RECIPE, ADAPTER } do
				local src = fs.readFile(path)
				expect(string.find(src, "Highlight", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "rbxasset", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "assetId", 1, true) ~= nil):toBe(false)
				expect(string.find(src, "%d%d%d%d%d%d%d") ~= nil):toBe(false)
			end
		end)

		t:it("registers the corner candidate with the shared toggle", function()
			local adapter = fs.readFile(ADAPTER)
			expect(string.find(adapter, 'LookDev.register("corner"', 1, true) ~= nil):toBe(true)
			local c = LookDev.candidates.corner
			expect(c.id):toBe("corner")
			expect(type(c.title) == "string" and #c.title > 0):toBe(true)
			expect(c.status):toBe(LookDev.STATUS)
			expect(c.style):toBe(LookDev.STYLE)
		end)
	end)
end
