--!nocheck
-- WORK_QUEUE section P items 180 + 182: LUNE-ONLY registry contract for the four new/moved
-- cameras. NOT registered in tests/run.luau here; the main session registers new specs in one pass.
-- Real Studio CAMERA_CLEAR / TOWER_RAY evidence belongs to tools/studio/check_p180.luau.
--
-- Pre-fix this spec FAILS: `ronda_tower_wide`, `canonical_overview_left` and
-- `canonical_overview_right` do not exist, and `ronda_tower` sits east of the tower centre instead
-- of on the open north-west side. Post-fix all cases pass.

local fs = require("@lune/fs")

local TOWER_NAMES = { "ronda_tower", "ronda_tower_wide" }
local OVERVIEW_NAMES = { "canonical_overview", "canonical_overview_left", "canonical_overview_right" }
local NEW_NAMES = { "ronda_tower_wide", "canonical_overview_left", "canonical_overview_right" }

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

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

local function distance(a, b)
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local Cameras = Env.new():require("shared/ReviewCameras")
	local MapSpec = env:require("server/World/MapSpec")
	local tower = MapSpec.RONDA_TOWER
	local names = Cameras.names()
	local seen = {}
	for _, name in ipairs(names) do
		seen[name] = (seen[name] or 0) + 1
	end
	local src = fs.readFile("src/shared/ReviewCameras.luau")

	t:describe("item 180 ronda tower cameras", function()
		t:it("registers the original and the wide camera exactly once with Server records", function()
			for _, name in ipairs(TOWER_NAMES) do
				expect(seen[name]):toBe(1)
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.name):toBe(name)
				expect(camera.datamodel):toBe("Server")
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
			end
		end)

		t:it("places both eyes on the open north-west side of the tower", function()
			local clearX = tower.x - tower.deck / 2
			local clearZ = tower.z - tower.deck / 2
			for _, name in ipairs(TOWER_NAMES) do
				local camera = Cameras.get(name)
				expect(camera.position[1] < clearX):toBe(true)
				expect(camera.position[3] < clearZ):toBe(true)
				expect(camera.position[2] > MapSpec.GROUND_Y + tower.height / 2):toBe(true)
				-- Both eyes look back at the tower centre, so base and roof stay in frame.
				expect(near(camera.lookAt[1], tower.x)):toBe(true)
				expect(near(camera.lookAt[3], tower.z)):toBe(true)
				expect(near(camera.lookAt[2], MapSpec.GROUND_Y + tower.height / 2)):toBe(true)
			end
		end)

		t:it("keeps the wide camera farther out than the close one", function()
			local close = Cameras.get("ronda_tower")
			local wide = Cameras.get("ronda_tower_wide")
			expect(math.sqrt(close.position[1] ^ 2 + close.position[3] ^ 2)):toBeLessThan(
				math.sqrt(wide.position[1] ^ 2 + wide.position[3] ^ 2)
			)
			expect(distance(wide.position, wide.lookAt)):toBeGreaterThan(distance(close.position, close.lookAt))
		end)
	end)

	t:describe("item 182 canonical overview cameras", function()
		t:it("registers left and right exactly once with Server records", function()
			for _, name in ipairs(OVERVIEW_NAMES) do
				expect(seen[name]):toBe(1)
				local camera = Cameras.get(name)
				expect(camera ~= nil):toBe(true)
				expect(camera.datamodel):toBe("Server")
				expect(validVec(camera.position)):toBe(true)
				expect(validVec(camera.lookAt)):toBe(true)
				expect(type(camera.purpose)):toBe("string")
				expect(#camera.purpose > 0):toBe(true)
			end
		end)

		t:it("flanks the original overview at the same height and looks at the ring", function()
			local base = Cameras.get("canonical_overview")
			local left = Cameras.get("canonical_overview_left")
			local right = Cameras.get("canonical_overview_right")
			expect(near(left.position[2], base.position[2])):toBe(true)
			expect(near(right.position[2], base.position[2])):toBe(true)
			expect(near(left.position[3], base.position[3])):toBe(true)
			expect(near(right.position[3], base.position[3])):toBe(true)
			expect(left.position[1] < base.position[1]):toBe(true)
			expect(right.position[1] > base.position[1]):toBe(true)
			expect(left.lookAt[1] < base.lookAt[1]):toBe(true)
			expect(right.lookAt[1] > base.lookAt[1]):toBe(true)
			expect(left.lookAt[3] > base.lookAt[3]):toBe(true)
			expect(right.lookAt[3] > base.lookAt[3]):toBe(true)
		end)
	end)

	t:describe("round-10 camera registry hygiene", function()
		t:it("keeps the 6-stud clear ray, unique names and literal-free source", function()
			expect(Cameras.clearDistance):toBe(6)
			for _, name in ipairs(names) do
				expect(seen[name]):toBe(1)
			end
			for _, name in ipairs(NEW_NAMES) do
				expect(src:find('"' .. name .. '"', 1, true) ~= nil):toBe(true)
			end
			expect(src:find("rbxassetid://", 1, true) == nil):toBe(true)
		end)
	end)
end
