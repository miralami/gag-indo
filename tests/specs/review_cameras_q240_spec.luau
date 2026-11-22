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
			expect(#Cameras.all()):toBe(69)
			expect(#Cameras.names()):toBe(69)
			expect(doc:find("69 named cameras after item 240", 1, true) ~= nil):toBe(true)
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
			expect(registrySource:find("clockTime = 21", 1, true) ~= nil):toBe(true)
			expect(doc:find("ClockTime 21", 1, true) ~= nil):toBe(true)
		end)
	end)
end
