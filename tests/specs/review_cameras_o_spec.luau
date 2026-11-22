--!nocheck
-- WORK_QUEUE section O item 153: camera additions. Pure-data contract only. The CAMERA_CLEAR ray
-- check is a Studio check and belongs to the main session; no Studio claim is made here.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Cameras = Env.new():require("shared/ReviewCameras")
	local MapSpec = env:require("server/World/MapSpec")
	local Game = env:require("shared/Config/Game")

	local NEW = {
		"pasar_awnings",
		"plaza_centre",
		"ronda_tower",
		"river_rocks",
		"forest_wall",
		"canonical_overview",
	}

	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end

	local function finite(n)
		return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end

	-- Item 69/143 fix these review offsets; the coordinates themselves all come from MapSpec.
	local HUB_STANDOFF = 28
	local HUB_RISE = 9
	local DIAGONAL = 1 / math.sqrt(2)

	local names = Cameras.names()
	local seen = {}
	for _, name in ipairs(names) do
		seen[name] = (seen[name] or 0) + 1
	end

	t:describe("item 153 review camera registry", function()
		t:it("registers the six item-153 cameras and plot_aerial_01..10 exactly once", function()
			for _, name in ipairs(NEW) do
				expect(seen[name]):toBe(1)
			end
			for index = 1, Game.plotCount do
				expect(seen["plot_aerial_" .. string.format("%02d", index)]):toBe(1)
			end
		end)

		t:it("gives every new camera a finite, non-degenerate Server record with a purpose", function()
			for _, name in ipairs(NEW) do
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(type(camera.position)):toBe("table")
				expect(type(camera.lookAt)):toBe("table")
				expect(#camera.position):toBe(3)
				expect(#camera.lookAt):toBe(3)
				expect(camera.datamodel):toBe("Server")
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
				for index = 1, 3 do
					expect(finite(camera.position[index])):toBe(true)
					expect(finite(camera.lookAt[index])):toBe(true)
				end
				expect(
					camera.position[1] ~= camera.lookAt[1]
						or camera.position[2] ~= camera.lookAt[2]
						or camera.position[3] ~= camera.lookAt[3]
				):toBe(true)
			end
		end)

		t:it("derives every new eye and target from MapSpec, not literal world coordinates", function()
			local expected = {}

			local pasar = MapSpec.hub("pasar")
			local apronLz = pasar.depth / 2 + MapSpec.S * 8
			local ex, ez =
				MapSpec.hubPoint(pasar, pasar.width / 2 + HUB_STANDOFF * DIAGONAL, apronLz + HUB_STANDOFF * DIAGONAL)
			local lx, lz = MapSpec.hubPoint(pasar, 0, apronLz)
			expected.pasar_awnings = {
				{ ex, MapSpec.GROUND_Y + HUB_RISE + MapSpec.S * 2, ez },
				{ lx, MapSpec.GROUND_Y + MapSpec.S, lz },
			}

			expected.plaza_centre = {
				{
					MapSpec.PLAZA.x + MapSpec.S,
					MapSpec.GROUND_Y + MapSpec.HEADROOM * 2,
					MapSpec.PLAZA.z + MapSpec.S * 3,
				},
				{ MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM / 2, MapSpec.PLAZA.z },
			}

			local tower = MapSpec.RONDA_TOWER
			-- item 180: eye moved to the open north-west diagonal so the whole tower is clear.
			local towerEyeStandoff = HUB_STANDOFF * DIAGONAL
			expected.ronda_tower = {
				{
					tower.x - towerEyeStandoff,
					MapSpec.GROUND_Y + tower.height * 0.75 + MapSpec.S,
					tower.z - towerEyeStandoff,
				},
				{ tower.x, MapSpec.GROUND_Y + tower.height / 2, tower.z },
			}

			local bridge = MapSpec.BRIDGE
			local rockX = bridge.x + bridge.width * MapSpec.S * 2
			local lookX = rockX + bridge.width * MapSpec.S * 2
			local bankOffset = bridge.rampLength * MapSpec.S + MapSpec.S * 2
			expected.river_rocks = {
				{ rockX, MapSpec.GROUND_Y + MapSpec.HEADROOM * 2, MapSpec.riverCentreZ(rockX) - bankOffset },
				{ lookX, MapSpec.GROUND_Y + bridge.top, MapSpec.riverCentreZ(lookX) },
			}

			expected.forest_wall = {
				{
					MapSpec.PLAZA.x,
					MapSpec.GROUND_Y + MapSpec.HEADROOM * 4,
					-(MapSpec.TERRAIN_HALF - MapSpec.TERRAIN_VOXEL * 2),
				},
				{
					MapSpec.PLAZA.x,
					MapSpec.GROUND_Y + MapSpec.HEADROOM * 2,
					-(MapSpec.TERRAIN_HALF + MapSpec.TERRAIN_VOXEL * 4),
				},
			}

			expected.canonical_overview = {
				{
					bridge.x + bridge.width * MapSpec.S * 2,
					MapSpec.GROUND_Y + MapSpec.TERRAIN_HALF / (MapSpec.S * MapSpec.S),
					bridge.z1 + bridge.width * MapSpec.S * 3,
				},
				{ MapSpec.PLAZA.x, MapSpec.GROUND_Y + MapSpec.HEADROOM, MapSpec.PLAZA.z },
			}

			for _, name in ipairs(NEW) do
				local camera = Cameras.get(name)
				local pair = expected[name]
				for index = 1, 3 do
					expect(near(camera.position[index], pair[1][index])):toBe(true)
					expect(near(camera.lookAt[index], pair[2][index])):toBe(true)
				end
			end
		end)

		t:it("keeps the reviewed offset ladder and the 6-stud clear ray unchanged", function()
			expect(Cameras.clearDistance):toBe(MapSpec.TERRAIN_VOXEL + MapSpec.S)
			expect(Cameras.clearDistance):toBe(6)
		end)
	end)

	t:describe("item 153 camera documentation", function()
		t:it("lists every new camera as a Server row in REVIEW_CAMERAS.md", function()
			local doc = fs.readFile("docs/v2/visual/REVIEW_CAMERAS.md")
			for _, name in ipairs(NEW) do
				expect(string.find(doc, "| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
			end
			for index = 1, Game.plotCount do
				local name = "plot_aerial_" .. string.format("%02d", index)
				expect(string.find(doc, "| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("keeps the registry free of literal asset IDs", function()
			local src = fs.readFile("src/shared/ReviewCameras.luau")
			for _, name in ipairs(NEW) do
				expect(string.find(src, '"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(string.find(src, "rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
