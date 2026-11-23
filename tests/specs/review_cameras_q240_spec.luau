--!nocheck
-- WORK_QUEUE item 240: LUNE-ONLY registry/doc contract for the six re-aimed sprint-1 cameras.
-- The Studio SUBJECT_COVERAGE / CAMERA_CLEAR measurements live in tools/studio/check_q240.luau;
-- this spec only guards the data the shooter reads. No visual verdict here.

local fs = require("@lune/fs")

local NAMES = {
	"kampung_view",
	"path_curve",
	"signpost_pasar",
	"lamp_night",
	"crop_stages_close",
	"ditch_water_close",
}

-- Items 218/247/250 add nine registry entries and re-aim five existing ones.
local NEW_218 = {
	"plaza_centre_golden",
	"plaza_centre_night",
	"pasar_awnings_golden",
	"pasar_awnings_night",
	"path_curve_golden",
	"path_curve_night",
	"lamp_night_golden",
	"lamp_night_night",
}
local VARIANT_BASES = {
	plaza_centre_golden = "plaza_centre",
	plaza_centre_night = "plaza_centre",
	pasar_awnings_golden = "pasar_awnings",
	pasar_awnings_night = "pasar_awnings",
	path_curve_golden = "path_curve",
	path_curve_night = "path_curve",
	lamp_night_golden = "lamp_night",
	lamp_night_night = "lamp_night",
	crop_stages_golden = "crop_stages_close",
}
local GOLDEN_CLOCK = 16.5
local NIGHT_CLOCK = 21

local function dist(a, b)
	return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end

local function validVec(value)
	if type(value) ~= "table" or #value ~= 3 then
		return false
	end
	for index = 1, 3 do
		local component = value[index]
		if type(component) ~= "number" or component ~= component or component == math.huge then
			return false
		end
	end
	return true
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Cameras = env:require("shared/ReviewCameras")
	local Grass = env:require("shared/CameraGrass")
	local Kampung = env:require("shared/ModelMapKampungR10")
	local Fence = env:require("shared/ModelMapRoadFenceR10")
	local Signs = env:require("shared/ModelMapSignpostsR10")
	local Lamps = env:require("shared/ModelMapLampsR10")
	local Crops = env:require("shared/ModelMapCropStagesR10")
	local Ditch = env:require("shared/ModelMapDitchWaterR10")
	local registrySource = fs.readFile("src/shared/ReviewCameras.luau")
	local doc = fs.readFile("docs/v2/visual/REVIEW_CAMERAS.md")

	local houses = Kampung.houses()
	local cluster = { 0, Kampung.GROUND_Y + Kampung.BODY_SIZE[2] / 2, 0 }
	for index = 1, Kampung.HOUSES_PER_CLUSTER do
		cluster[1] += houses[index].position.x / Kampung.HOUSES_PER_CLUSTER
		cluster[3] += houses[index].position.z / Kampung.HOUSES_PER_CLUSTER
	end
	local stretch = Fence.stretches()[1]
	local fenceRadius = (stretch.radiusFrom + stretch.radiusTo) / 2
	local fenceAngle = math.rad(stretch.angle)
	local fence = {
		math.cos(fenceAngle) * fenceRadius - math.sin(fenceAngle) * Fence.SIDE_OFFSET * stretch.side,
		Fence.GROUND_Y + Fence.FENCE_HEIGHT / 2,
		math.sin(fenceAngle) * fenceRadius + math.cos(fenceAngle) * Fence.SIDE_OFFSET * stretch.side,
	}
	local sign = Signs.SIGNS[1].position
	local lamp = Lamps.lamps()[1].position
	local ditchParts = Ditch.parts()
	local ditch = {
		(ditchParts[1].position[1] + ditchParts[2].position[1]) / 2,
		Ditch.WATER_Y,
		(ditchParts[1].position[3] + ditchParts[2].position[3]) / 2,
	}
	local subjects = {
		kampung_view = { cluster, 50 },
		path_curve = { fence, 20 },
		signpost_pasar = { { sign.x, Signs.GROUND_Y + Signs.POST_SIZE[2] / 2, sign.z }, 30 },
		lamp_night = { { lamp.x, lamp.y + Lamps.POLE_SIZE[2] / 2, lamp.z }, 30 },
		crop_stages_close = { Crops.demoCentre(), 35 },
		ditch_water_close = { ditch, 20 },
	}

	t:describe("item 240 re-aimed review cameras", function()
		t:it("keeps the 6-stud clear ray and adds exactly two registry entries", function()
			expect(Cameras.clearDistance):toBe(6)
			-- 78 after item 250, plus 28 item-255 hero_* cameras and 3 item-269 corridor heroes.
			expect(#Cameras.all()):toBe(109)
			expect(#Cameras.names()):toBe(109)
			expect(doc:find("69 named cameras after item 240", 1, true) ~= nil):toBe(true)
			expect(doc:find("78 named cameras after items 218, 247 and 250", 1, true) ~= nil):toBe(true)
		end)

		t:it("registers and documents every item-240 camera exactly once", function()
			local seen = {}
			for _, name in ipairs(Cameras.names()) do
				expect(seen[name] == nil):toBe(true)
				seen[name] = true
			end
			for _, name in ipairs(NAMES) do
				expect(seen[name]):toBe(true)
				local camera = Cameras.get(name)
				expect(type(camera)):toBe("table")
				expect(camera.name):toBe(name)
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(camera.datamodel):toBe("Server")
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
				expect(registrySource:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
				expect(doc:find("| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
				local reaimStart = doc:find("## Item 240 re-aim", 1, true)
				expect(reaimStart ~= nil):toBe(true)
				expect(doc:sub(reaimStart):find("`" .. name .. "`", 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("places each eye close to the subject it must frame", function()
			for _, name in ipairs(NAMES) do
				local camera = Cameras.get(name)
				local subject = subjects[name][1]
				local limit = subjects[name][2]
				expect(dist(camera.position, subject) < limit):toBe(true)
				expect(dist(camera.position, camera.lookAt) > 0):toBe(true)
			end
		end)

		t:it("makes lamp_night a real ClockTime 21 variant", function()
			expect(Cameras.get("lamp_night").clockTime):toBe(21)
			expect(registrySource:find("NIGHT_CLOCK = 21", 1, true) ~= nil):toBe(true)
			expect(doc:find("ClockTime 21", 1, true) ~= nil):toBe(true)
		end)

		t:it("registers items 218/247 variants once with unique names and exact base geometry", function()
			local seen = {}
			for _, name in ipairs(Cameras.names()) do
				expect(seen[name] == nil):toBe(true)
				seen[name] = true
			end
			for name, base in pairs(VARIANT_BASES) do
				expect(seen[name]):toBe(true)
				local camera, parent = Cameras.get(name), Cameras.get(base)
				expect(camera ~= nil and parent ~= nil):toBe(true)
				expect(camera.name):toBe(name)
				expect(validVec(camera.position) and validVec(camera.lookAt)):toBe(true)
				expect(camera.position[1]):toBe(parent.position[1])
				expect(camera.position[2]):toBe(parent.position[2])
				expect(camera.position[3]):toBe(parent.position[3])
				expect(camera.lookAt[1]):toBe(parent.lookAt[1])
				expect(camera.lookAt[2]):toBe(parent.lookAt[2])
				expect(camera.lookAt[3]):toBe(parent.lookAt[3])
				expect(camera.datamodel):toBe(parent.datamodel)
				expect(doc:find("| `" .. name .. "` | " .. camera.datamodel .. " |", 1, true) ~= nil):toBe(true)
			end
			for _, name in ipairs(NEW_218) do
				expect(Cameras.get(name).clockTime):toBe(name:find("_golden$") and GOLDEN_CLOCK or NIGHT_CLOCK)
			end
			expect(Cameras.get("crop_stages_golden").clockTime):toBe(GOLDEN_CLOCK)
			expect(registrySource:find("GOLDEN_HOUR.minClock + WorldConstants.GOLDEN_HOUR.maxClock", 1, true) ~= nil):toBe(
				true
			)
			expect(doc:find("16.5", 1, true) ~= nil):toBe(true)
		end)

		t:it("keeps CAMERA_GRASS thresholds and classifies synthetic voxel columns", function()
			expect(Grass.VOXEL):toBe(4)
			expect(Grass.MIN_EYE_CLEARANCE):toBe(4)
			expect(Grass.MIN_RAY_HEIGHT):toBe(3)
			expect(Grass.RAY_DISTANCE):toBe(12)
			expect(Grass.isGrass("Enum.Material.Grass")):toBe(true)
			expect(Grass.isGrass("Enum.Material.LeafyGrass")):toBe(true)
			expect(Grass.isGrass("Enum.Material.Ground")):toBe(false)

			local materials, occupancies = {}, {}
			for ix = 1, 3 do
				materials[ix], occupancies[ix] = {}, {}
				for iy = 1, 36 do
					materials[ix][iy], occupancies[ix][iy] = {}, {}
					for iz = 1, 3 do
						materials[ix][iy][iz] = "Enum.Material.Air"
						occupancies[ix][iy][iz] = 0
					end
				end
			end
			materials[2][5][2] = "Enum.Material.Grass"
			occupancies[2][5][2] = 1
			local column = Grass.column(materials, occupancies, 0, 0)
			expect(column.ok):toBe(true)
			expect(column.surface):toBe(4)
			expect(column.grass):toBe(true)

			local function read()
				return column
			end
			local good = Grass.evaluate({ 0, 12, 0 }, { 0, 8, 20 }, read)
			expect(good.ok):toBe(true)
			expect(good.eyeClearance):toBe(8)
			local lowEye = Grass.evaluate({ 0, 7.5, 0 }, { 0, 4, 20 }, read)
			expect(lowEye.ok):toBe(false)
			expect(lowEye.lowEye):toBe(true)
			local grazed = Grass.evaluate({ 0, 12, 0 }, { 0, 0, 12 }, read)
			expect(grazed.ok):toBe(false)
			expect(grazed.lowGrassHits > 0):toBe(true)
			-- sprint-2 path_curve eye 5.25 over a surface at 4 must FAIL the 4-stud floor.
			local oldEye = Grass.evaluate({ 90, 5.25, -26 }, { 90, 1.1, -10 }, read)
			expect(oldEye.ok):toBe(false)
			expect(oldEye.lowEye):toBe(true)
		end)
	end)
end
