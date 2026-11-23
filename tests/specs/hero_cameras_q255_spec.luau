--!nocheck
-- WORK_QUEUE item 255 + item 269: LUNE-ONLY registry contract for the 31 `hero_*` review cameras.
-- Studio SUBJECT_COVERAGE / CAMERA_GRASS / HERO_CLEAR measurements live in tools/studio/check_q255.luau;
-- this spec only guards the data the shooter reads. No Studio claim, no visual verdict here.

local fs = require("@lune/fs")

local HERO_NAMES = {
	"hero_balai_r10",
	"hero_hub_canopy_r10",
	"hero_blocks_shrubs_r10",
	"hero_pasar_roof_r10",
	"hero_warung_cluster_r10",
	"hero_polisi_roof_r10",
	"hero_pakrt_roof_r10",
	"hero_sawah_gubuk_r10",
	"hero_plots_mailbox_r10",
	"hero_river_palms_r10",
	"hero_meadow_r10",
	"hero_ground_variation_r10",
	"hero_paths_curved_r10",
	"hero_horizon_fill_r10",
	"hero_mountains_r10",
	"hero_hill_dressing_r10",
	"hero_kampung_r10",
	"hero_road_fence_r10",
	"hero_lamps_r10",
	"hero_signposts_r10",
	"hero_bamboo_bridge_r10",
	"hero_furrows_r10",
	"hero_crop_stages_r10",
	"hero_ditch_water_r10",
	"hero_default_warung",
	"hero_river_foam_212",
	"hero_terrace_walls_214",
	"hero_lamps_r10_night",
	"hero_corridor_pasar",
	"hero_corridor_sawah",
	"hero_corridor_village",
}

local REUSED_GEOMETRY = {
	hero_road_fence_r10 = "path_curve",
	hero_ditch_water_r10 = "ditch_water_close",
	hero_crop_stages_r10 = "crop_stages_close",
	hero_default_warung = "hub_warung",
}

-- Item 269 corridor poses are literals, not MapSpec-derived; the shoot harness uses these numbers.
local CORRIDOR_POSES = {
	hero_corridor_pasar = { { 0, 14, 90 }, { -64, 8, -64 } },
	hero_corridor_sawah = { { 60, 20, -182 }, { 190, 14, -344 } },
	hero_corridor_village = { { 0, 14, 200 }, { 0, 6, 304 } },
}

local DAY_CLOCK = 13
local NIGHT_CLOCK = 21

local function validVec(value)
	if type(value) ~= "table" or #value ~= 3 then
		return false
	end
	for index = 1, 3 do
		local component = value[index]
		if
			type(component) ~= "number"
			or component ~= component
			or component == math.huge
			or component == -math.huge
		then
			return false
		end
	end
	return true
end

local function sameVec(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Cameras = env:require("shared/ReviewCameras")
	local MapSpec = env:require("server/World/MapSpec")
	local source = fs.readFile("src/shared/ReviewCameras.luau")

	t:describe("item 255 hero review cameras", function()
		t:it("registers all 31 hero cameras exactly once", function()
			expect(#HERO_NAMES):toBe(31)
			expect(#Cameras.names()):toBe(109)
			local counts = {}
			for _, name in ipairs(Cameras.names()) do
				counts[name] = (counts[name] or 0) + 1
			end
			for _, name in ipairs(HERO_NAMES) do
				expect(counts[name]):toBe(1)
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.name):toBe(name)
			end
		end)

		t:it("gives every hero camera honest Server data and an eye above grade", function()
			for _, name in ipairs(HERO_NAMES) do
				local camera = Cameras.get(name)
				expect(camera.datamodel):toBe("Server")
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(sameVec(camera.position, camera.lookAt)):toBe(false)
				expect(camera.position[2] >= MapSpec.GROUND_Y + 4):toBe(true)
			end
			for name, pose in pairs(CORRIDOR_POSES) do
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(sameVec(camera.position, pose[1])):toBe(true)
				expect(sameVec(camera.lookAt, pose[2])):toBe(true)
				expect(camera.clockTime):toBe(DAY_CLOCK)
			end
		end)

		t:it("keeps the day hero clock and the shared-geometry night lamp variant", function()
			for _, name in ipairs(HERO_NAMES) do
				expect(Cameras.get(name).clockTime):toBe(name == "hero_lamps_r10_night" and NIGHT_CLOCK or DAY_CLOCK)
			end
			local day, night = Cameras.get("hero_lamps_r10"), Cameras.get("hero_lamps_r10_night")
			expect(day.clockTime):toBe(DAY_CLOCK)
			expect(night.clockTime):toBe(NIGHT_CLOCK)
			expect(sameVec(day.position, night.position)):toBe(true)
			expect(sameVec(day.lookAt, night.lookAt)):toBe(true)
			expect(source:find("NIGHT_CLOCK = 21", 1, true) ~= nil):toBe(true)
		end)

		t:it("reuses the proven base geometry byte for byte where required", function()
			for name, base in pairs(REUSED_GEOMETRY) do
				local camera, parent = Cameras.get(name), Cameras.get(base)
				expect(camera ~= nil and parent ~= nil):toBe(true)
				expect(sameVec(camera.position, parent.position)):toBe(true)
				expect(sameVec(camera.lookAt, parent.lookAt)):toBe(true)
			end
		end)

		t:it("lifts the two hill hero eyes above the buried terrace_wall eye and aims at subject centre", function()
			local base = Cameras.get("terrace_wall")
			local HillDressing = env:require("shared/ModelMapHillDressingR10")
			local hill = HillDressing.HILLS[4]
			local sx, sy, sz, count = 0, 0, 0, 0
			for _, part in ipairs(HillDressing.parts()) do
				if part.hill == 4 and (part.kind == "rock" or part.kind == "palm") then
					sx += part.position[1]
					sy += part.position[2]
					sz += part.position[3]
					count += 1
				end
			end
			local cx, cy, cz = sx / count, sy / count, sz / count
			for _, name in ipairs({ "hero_hill_dressing_r10", "hero_terrace_walls_214" }) do
				local camera = Cameras.get(name)
				expect(camera.position[2]):toBeGreaterThan(base.position[2])
				expect(camera.position[2] - MapSpec.GROUND_Y):toBeGreaterThan(4)
				expect(math.abs(camera.lookAt[1] - cx) < 0.01):toBe(true)
				expect(math.abs(camera.lookAt[2] - cy) < 0.01):toBe(true)
				expect(math.abs(camera.lookAt[3] - cz) < 0.01):toBe(true)
				expect(math.abs(camera.lookAt[1] - hill.x) <= hill.radius):toBe(true)
			end
		end)

		t:it("brings the river palm hero eye to the dedicated closer standoff", function()
			local palm = Cameras.get("hero_river_palms_r10")
			local horizontal =
				math.sqrt((palm.position[1] - palm.lookAt[1]) ^ 2 + (palm.position[3] - palm.lookAt[3]) ^ 2)
			expect(horizontal):toBeNear(MapSpec.S * 3)
			expect(palm.position[2]):toBeNear(MapSpec.GROUND_Y + MapSpec.S * 5)
		end)

		t:it("adds no asset ID and writes every hero name literally in the registry", function()
			expect(source:find("rbxassetid://", 1, true)):toBeNil()
			for _, name in ipairs(HERO_NAMES) do
				expect(source:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
		end)
	end)
end
