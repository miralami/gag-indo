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

-- WORK_QUEUE item 216: twelve named cameras; the two canonical overview flanks already exist in
-- P_ROUND_CAMERAS, so only ten new registry entries are added.
local SPRINT1 = {
	"canonical_overview_left",
	"canonical_overview_right",
	"path_curve",
	"kampung_view",
	"bridge_side",
	"meadow_view",
	"terrace_wall",
	"signpost_pasar",
	"lamp_night",
	"horizon_north",
	"horizon_south",
	"fountain_close",
}
local PREVIOUS_COUNT = 45 -- registry size after item 118, before item 133
local P_ROUND_CAMERAS = 3 -- items 180/182: ronda_tower_wide + canonical_overview_left/right
local SPRINT1_NEW_COUNT = 10 -- 12 names minus the 2 canonical overview flanks already counted above
local Q240_NEW_COUNT = 2 -- crop_stages_close + ditch_water_close
local Q250_NEW_COUNT = 9 -- eight item-218 lighting variants + crop_stages_golden (item 247)
local Q255_NEW_COUNT = 28 -- item-255 hero_* cameras (24 r10 + Warung, foam 212, walls 214, lamp night)
local Q269_NEW_COUNT = 3 -- item-269 hero_corridor_* view cameras
local BASE_COUNT = PREVIOUS_COUNT + #NEW + P_ROUND_CAMERAS + SPRINT1_NEW_COUNT + Q240_NEW_COUNT + Q250_NEW_COUNT -- 78
local TOTAL_COUNT = BASE_COUNT + Q255_NEW_COUNT + Q269_NEW_COUNT -- 109
local HERO_COUNT = Q255_NEW_COUNT + Q269_NEW_COUNT -- 31
local Q269_NAMES = { "hero_corridor_pasar", "hero_corridor_sawah", "hero_corridor_village" }

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
	local MapSpec = Env.new():require("server/World/MapSpec")
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

		t:it("registers all 12 item-216 names with valid coords, Server datamodel and doc rows", function()
			local seen = {}
			for _, name in ipairs(SPRINT1) do
				expect(seen[name] == nil):toBe(true)
				seen[name] = true
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.name):toBe(name)
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(sameVec(camera.position, camera.lookAt)):toBe(false)
				expect(camera.datamodel):toBe("Server")
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
				expect(cameraSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
				expect(cameraDoc:find("| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
			end
			expect(cameraDoc:find("ClockTime 21", 1, true) ~= nil):toBe(true)
			expect(cameraDoc:find("67 named cameras after item 216", 1, true) ~= nil):toBe(true)
		end)

		t:it("documents every registry name exactly once", function()
			local docSeen, documentedHeroes = {}, 0
			for name in cameraDoc:gmatch("| `([^`]+)` |") do
				expect(docSeen[name] == nil):toBe(true)
				docSeen[name] = true
				if name:find("hero_", 1, true) == 1 then
					documentedHeroes += 1
				end
			end
			local heroSeen = {}
			for _, name in ipairs(Cameras.names()) do
				if name:find("hero_", 1, true) == 1 then
					heroSeen[name] = true
				else
					expect(docSeen[name] == true):toBe(true)
				end
			end
			for name in pairs(docSeen) do
				if name:find("hero_", 1, true) == 1 then
					expect(heroSeen[name] == true):toBe(true)
				end
			end
			local docCount = 0
			for _ in pairs(docSeen) do
				docCount = docCount + 1
			end
			-- 28 item-255 hero rows + 3 item-269 corridor hero rows.
			expect(documentedHeroes):toBe(HERO_COUNT)
			expect(docCount):toBe(BASE_COUNT + documentedHeroes)
			for _, name in ipairs(Q269_NAMES) do
				expect(Cameras.get(name) ~= nil):toBe(true)
				expect(cameraSrc:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
				expect(cameraDoc:find("| `" .. name .. "` | Server |", 1, true) ~= nil):toBe(true)
			end
		end)

		t:it("item 252 bridge_side is a downward 3/4 view of the bamboo deck", function()
			local camera = Cameras.get("bridge_side")
			local bridge = MapSpec.BRIDGE
			local deckTop = MapSpec.GROUND_Y + bridge.top
			local bridgeZ = (bridge.z0 + bridge.z1) / 2
			expect(camera.datamodel):toBe("Server")
			expect(camera.position[1] > bridge.x):toBe(true)
			expect(camera.position[2] > deckTop + MapSpec.HEADROOM * 2):toBe(true)
			expect(camera.position[3] < bridge.z0):toBe(true)
			expect(math.abs(camera.lookAt[1] - bridge.x) < 1e-6):toBe(true)
			expect(math.abs(camera.lookAt[2] - deckTop) < 1e-6):toBe(true)
			expect(math.abs(camera.lookAt[3] - bridgeZ) < 1e-6):toBe(true)
			local drop = camera.position[2] - camera.lookAt[2]
			local run =
				math.sqrt((camera.position[1] - camera.lookAt[1]) ^ 2 + (camera.position[3] - camera.lookAt[3]) ^ 2)
			expect(drop / run > 0.5):toBe(true) -- steeper than ~27 degrees, not a side elevation
			expect(cameraSrc:find("MapSpec.HEADROOM * 3", 1, true) ~= nil):toBe(true)
			expect(cameraDoc:find("Item-252 downward 3/4 view", 1, true) ~= nil):toBe(true)
		end)
	end)
end
