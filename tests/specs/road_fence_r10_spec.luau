--!nocheck
-- selene: allow(incorrect_standard_library_use) -- Lune's @lune/fs uses a string require key.
-- WORK_QUEUE item 201, rebuilt by item 262: LUNE-ONLY data + source contract for "road_fence_r10".
-- Studio staging (ROAD_FENCE / JUNCTION_GAPS / PATH_REACH) stays in check_q201.luau; the item-262
-- model/lane/gate measurement and FAIL calibrations stay in check_q262.luau. LookDev IDS and review
-- wiring belong to the wiring lane. This spec asserts neither Studio state nor a visual verdict.

local fs = require("@lune/fs")

local DATA_SRC = "src/shared/ModelMapRoadFenceR10.luau"
local APPLIER_SRC = "src/server/World/LookDevRoadFenceR10.luau"
local CHECK_201_SRC = "tools/studio/check_q201.luau"
local CHECK_262_SRC = "tools/studio/check_q262.luau"

local function serialize(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local fields = {}
	for _, key in ipairs(keys) do
		fields[#fields + 1] = key .. "=" .. serialize(value[key])
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Data = env:require("shared/ModelMapRoadFenceR10")
	local pureSrc = fs.readFile(DATA_SRC)
	local applierSrc = fs.readFile(APPLIER_SRC)
	local check201Src = fs.readFile(CHECK_201_SRC)
	local check262Src = fs.readFile(CHECK_262_SRC)

	t:describe("road_fence_r10 pure data", function()
		t:it("stays pure: no engine calls, no asset IDs, exact id and folder", function()
			for _, token in ipairs({ "rbxassetid://", "game.", "Instance.new", "Enum." }) do
				expect(string.find(pureSrc, token, 1, true) == nil):toBe(true)
			end
			for run in string.gmatch(pureSrc, "%d%d%d%d%d%d%d+") do
				expect(#run <= 7):toBe(true)
			end
			expect(Data.id):toBe("road_fence_r10")
			expect(Data.folderName):toBe("LookDevRoadFenceR10_road_fence_r10")
			expect(Data.FENCE_HEIGHT):toBe(2.5)
			expect(Data.MODEL_ASSET_KEY):toBe("fence_bamboo")
			expect(Data.BAMBOO_COLOR):toEqual({ r = 180, g = 165, b = 90 })
			expect(Data.RING_CENTRE):toBe(144)
			expect(Data.GATE_RADIUS):toBe(152)
			expect(Data.GAP_MIN):toBe(8)
		end)

		t:it("declares at least six road stretches, all inside radius 60..120", function()
			local stretches = Data.stretches()
			expect(#stretches >= 6):toBe(true)
			for _, stretch in ipairs(stretches) do
				expect(type(stretch.name)):toBe("string")
				expect(stretch.side == 1 or stretch.side == -1):toBe(true)
				expect(stretch.radiusFrom >= 60):toBe(true)
				expect(stretch.radiusTo <= 120):toBe(true)
				expect(stretch.radiusTo > stretch.radiusFrom):toBe(true)
				expect(type(stretch.gaps)):toBe("table")
				expect(#stretch.gaps >= 1):toBe(true)
				for _, gap in ipairs(stretch.gaps) do
					expect(gap.from >= 120):toBe(true)
					expect(gap.to >= gap.from):toBe(true)
					expect(gap.from > stretch.radiusTo):toBe(true)
				end
			end
		end)

		t:it("emits baked-model descriptors 2.5 studs tall on six grouped stretches", function()
			local parts = Data.parts()
			expect(#parts > 6):toBe(true)
			local stretchesSeen, groupsSeen = {}, {}
			for _, part in ipairs(parts) do
				expect(part.asset):toBe(Data.MODEL_ASSET_KEY)
				expect(part.height):toBe(2.5)
				expect(part.footprint[2]):toBe(2.5)
				expect(part.footprint[1] > part.footprint[3]):toBe(true)
				expect(part.angle % 90):toBe(0)
				expect(part.position[2]):toBe(Data.GROUND_Y + Data.FENCE_HEIGHT / 2)
				expect(type(part.group)):toBe("string")
				expect(#part.group > 0):toBe(true)
				groupsSeen[part.group] = true
				stretchesSeen[part.stretch] = true
			end
			local stretchCount, groupCount = 0, 0
			for _ in pairs(stretchesSeen) do
				stretchCount += 1
			end
			for _ in pairs(groupsSeen) do
				groupCount += 1
			end
			expect(stretchCount >= 6):toBe(true)
			expect(groupCount >= 6):toBe(true)
		end)

		t:it("keeps every model at least 8 studs from every junction and plot gate", function()
			local violations = 0
			for _, part in ipairs(Data.parts()) do
				local x, z = part.position[1], part.position[3]
				for _, angle in ipairs({ 0, 90, 180, 270 }) do
					local radians = math.rad(angle)
					local dx, dz = x - math.cos(radians) * 144, z - math.sin(radians) * 144
					if dx * dx + dz * dz < 64 then
						violations += 1
					end
				end
				local radius = math.sqrt(x * x + z * z)
				expect(radius <= 121):toBe(true)
				expect(radius >= 60):toBe(true)
			end
			expect(violations):toBe(0)
		end)

		t:it("covers every stretch with a shoulder patch for the Grass -> Ground repaint", function()
			local patches = Data.shoulderPatches()
			expect(#patches >= 6):toBe(true)
			local seen = {}
			for _, patch in ipairs(patches) do
				expect(type(patch.name)):toBe("string")
				expect(seen[patch.stretch] == nil):toBe(true)
				seen[patch.stretch] = true
				expect(patch.minX < patch.maxX):toBe(true)
				expect(patch.minZ < patch.maxZ):toBe(true)
				expect(patch.maxX - patch.minX >= 2 * Data.SHOULDER_HALF_WIDTH):toBe(true)
				expect(patch.maxZ - patch.minZ >= 2 * Data.SHOULDER_HALF_WIDTH):toBe(true)
			end
			expect(#seen >= 6):toBe(true)
		end)

		t:it("stays identical across fresh requires", function()
			local fresh = Env.new():require("shared/ModelMapRoadFenceR10")
			expect(fresh.id):toBe(Data.id)
			expect(serialize(fresh.stretches())):toBe(serialize(Data.stretches()))
			expect(serialize(fresh.parts())):toBe(serialize(Data.parts()))
			expect(serialize(fresh.shoulderPatches())):toBe(serialize(Data.shoulderPatches()))
		end)
	end)

	t:describe("road_fence_r10 applier and check sources", function()
		t:it("uses baked pick 1, strips scripts, tags descendants and restores terrain LIFO", function()
			expect(applierSrc:find("1158365955", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("baked(assetId)", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find(".LoadAsset(", 1, true) == nil):toBe(true)
			expect(applierSrc:find("LuaSourceContainer", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ScaleTo", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CanCollide = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("CastShadow = false", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("LookDevStage", FAMILY_ID)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find('SetAttribute("RoadFenceAssetId", assetId)', 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("ReadVoxels", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("WriteVoxels", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Material.Grass", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("Enum.Material.Ground", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("restoreShoulder()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("instance:Destroy()", 1, true) ~= nil):toBe(true)
			expect(applierSrc:find("pcall", 1, true) ~= nil):toBe(true)
		end)

		t:it("check_q201 source assertions still match the model-backed set", function()
			expect(check201Src:find("ROAD_FENCE", 1, true) ~= nil):toBe(true)
			expect(check201Src:find("JUNCTION_GAPS", 1, true) ~= nil):toBe(true)
			expect(check201Src:find("PATH_REACH", 1, true) ~= nil):toBe(true)
			expect(check201Src:find("Data.parts", 1, true) ~= nil):toBe(true)
			expect(check201Src:find('GetAttribute("RoadFence") == true', 1, true) ~= nil):toBe(true)
			expect(check201Src:find("disableAll()", 1, true) ~= nil):toBe(true)
		end)

		t:it("check_q262 declares the exact five checks and emits SUMMARY_Q262", function()
			local order = {
				"MODEL_USED",
				"LANE_CLEAR",
				"GATE_CLEAR",
				"CAL_MODEL_USED_FAIL",
				"CAL_LANE_CLEAR_FAIL",
			}
			local previous = 0
			for _, name in ipairs(order) do
				local at = string.find(check262Src, '"' .. name .. '"', 1, true)
				expect(at ~= nil):toBe(true)
				if at then
					expect(at > previous):toBe(true)
					previous = at
				end
			end
			expect(check262Src:find("SUMMARY_Q262", 1, true) ~= nil):toBe(true)
			expect(check262Src:find("1158365955", 1, true) ~= nil):toBe(true)
			expect(check262Src:find("RoadFenceAssetId", 1, true) ~= nil):toBe(true)
			expect(check262Src:find("workspace:Raycast", 1, true) ~= nil):toBe(true)
			expect(check262Src:find('game:GetService("Players")', 1, true) ~= nil):toBe(true)
			expect(check262Src:find("review.disableAll()", 1, true) ~= nil):toBe(true)
			expect(check262Src:find("Client", 1, true) == nil):toBe(true)
		end)
	end)
end
