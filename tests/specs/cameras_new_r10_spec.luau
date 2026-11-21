--!nocheck
-- WORK_QUEUE section N item 133: CAMERA_CLEAR_R10. Guards the nine new round-10 review cameras
-- plus the three crops_showcase_r8 cameras item 118 already added. LUNE-ONLY registry/doc contract;
-- the real Studio CAMERA_CLEAR run and any visual verdict belong to the main session/designer.
-- This spec is NOT registered here: the main session registers all new specs in one pass.

local fs = require("@lune/fs")

local NEW = {
	"lapangan_view",
	"musala_view",
	"lumbung_view",
	"perahu_view",
	"irrigation_view",
	"kincir_view",
	"laundry_view",
	"kite_sky",
	"warung_seated",
}
local CROPS = { "crop_bibit", "crop_tumbuh", "crop_siap" }
local EXPECTED = {}
for _, name in ipairs(NEW) do
	EXPECTED[#EXPECTED + 1] = name
end
for _, name in ipairs(CROPS) do
	EXPECTED[#EXPECTED + 1] = name
end

local PREVIOUS_COUNT = 45 -- registry size after item 118, before item 133
local TOTAL_COUNT = PREVIOUS_COUNT + #NEW -- 54

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
	local Cameras = Env.new():require("shared/ReviewCameras")
	local cameraSrc = fs.readFile("src/shared/ReviewCameras.luau")
	local cameraDoc = fs.readFile("docs/v2/visual/REVIEW_CAMERAS.md")

	t:describe("CAMERA_CLEAR_R10", function()
		t:it("keeps the 6-stud clear ray and the pre-item registry size", function()
			expect(Cameras.clearDistance):toBe(6)
			expect(#Cameras.all()):toBe(TOTAL_COUNT)
			expect(#Cameras.names()):toBe(TOTAL_COUNT)
		end)

		t:it("registers all 12 item-133 names with valid coords and a Server datamodel", function()
			for _, name in ipairs(EXPECTED) do
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.name):toBe(name)
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(sameVec(camera.position, camera.lookAt)):toBe(false)
				expect(camera.datamodel == "Server" or camera.datamodel == "Client"):toBe(true)
				expect(camera.datamodel):toBe("Server")
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
			end
		end)

		t:it("documents each expected name once, with no duplicate registry names", function()
			local seen = {}
			for _, name in ipairs(EXPECTED) do
				expect(seen[name] == nil):toBe(true)
				seen[name] = true
				expect(cameraSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
				expect(cameraDoc:find("| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
			end
			local registrySeen = {}
			for _, name in ipairs(Cameras.names()) do
				expect(registrySeen[name] == nil):toBe(true)
				registrySeen[name] = true
			end
			expect(cameraDoc:find("54 named cameras after item 133", 1, true) ~= nil):toBe(true)
		end)
	end)
end
