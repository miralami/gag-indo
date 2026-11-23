--!nocheck
-- check_q269: WORK_QUEUE item 269, self-contained two-VM Studio check for the three view-corridor
-- hero cameras. Run the SAME file twice via execute_luau in one fresh Play session:
--   1. Server datamodel (no LocalPlayer) -> CAMERA_GRASS_hero_corridor_* lines
--   2. Client datamodel (LocalPlayer)   -> CAPTURE_POSE_hero_corridor_* and HUD_HIDDEN_* lines
-- The main session collects all nine lines and owns the captures/evidence. This file never
-- captures and never saves the place. Poses are literals because ReviewCameras requires the
-- Server-only MapSpec and cannot be required in the Client VM.
--
-- EXPECTED LINE FORMAT (one line per check):
--   CHECK CAPTURE_POSE_<name> PASS <posError>stud/<angle>deg <=0.5stud/<=2deg   (CapturePose.line)
--   CHECK CAMERA_GRASS_<name> PASS eyeClearance=<studs> lowGrassHits=0 samples=<n>
--   CHECK HUD_HIDDEN_<name> PASS <enabled> 0 tracked=<n> hidden=<n> after=<n>
--   SUMMARY_Q269 VM=<SERVER|CLIENT> ... <pass>/3 ...
--
-- CALIBRATION ANCHORS (inject one change, rerun, expect the named line to FAIL):
--   * CAPTURE_POSE: change one SHOTS.position/lookAt literal; CapturePose.measure sees >0.5 stud
--     or >2 deg. Leaving CurrentCamera on the character also FAILs.
--   * CAMERA_GRASS: lower an eye Y below surface+4 or point the ray through low grass; the
--     Terrain:ReadVoxels column read then reports lowEye / lowGrassHits.
--   * HUD_HIDDEN: enable one tracked ScreenGui after hideHud(game), before `during = countEnabled`;
--     the count sees 1 instead of 0.

local results = { vm = nil, checks = {}, byName = {}, passed = {}, failed = {}, error = nil }

local SHOTS = {
	{
		name = "hero_corridor_pasar",
		position = { 0, 14, 90 },
		lookAt = { -64, 8, -64 },
	},
	{
		name = "hero_corridor_sawah",
		position = { 60, 20, -182 },
		lookAt = { 190, 14, -344 },
	},
	{
		name = "hero_corridor_village",
		position = { 0, 14, 200 },
		lookAt = { 0, 6, 304 },
	},
}

local TOP_BAR = { RobloxGui = true, TopBarApp = true, TopBarScrim = true }
local impossible = { positionError = 1e12, angleDeg = 180, ok = false }

local function emit(kind, name, line, passed)
	local key = kind .. "_" .. name
	results.checks[#results.checks + 1] = line
	results.byName[key] = { line = line, passed = passed == true }
	results.passed[kind] = (results.passed[kind] or 0) + (passed == true and 1 or 0)
	results.failed[kind] = (results.failed[kind] or 0) + (passed == true and 0 or 1)
	print(line)
end

local function failLine(kind, name, reason)
	emit(kind, name, "CHECK " .. kind .. "_" .. name .. " FAIL " .. tostring(reason), false)
end

local function fmt(value)
	if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
		return string.format("%.2f", value)
	end
	return "nil"
end

-- CLIENT: CAPTURE_POSE

local function runPose(shot, CapturePose, cam)
	local key = "CAPTURE_POSE_" .. shot.name
	local prior, line, passed, err
	local ok, runErr = pcall(function()
		prior = { cameraType = cam.CameraType, cframe = cam.CFrame }
		cam.CameraType = Enum.CameraType.Scriptable
		local eye, look = shot.position, shot.lookAt
		cam.CFrame = CFrame.lookAt(
			Vector3.new(eye[1], eye[2], eye[3]),
			Vector3.new(look[1], look[2], look[3])
		)
		task.wait()
		task.wait()
		local pos, direction = cam.CFrame.Position, cam.CFrame.LookVector
		local result = CapturePose.measure(
			{ position = shot.position, lookAt = shot.lookAt },
			{ pos.X, pos.Y, pos.Z },
			{ direction.X, direction.Y, direction.Z }
		)
		line = CapturePose.line(shot.name, result)
		passed = result.ok == true
	end)
	pcall(function()
		if prior then
			cam.CFrame = prior.cframe
			cam.CameraType = prior.cameraType
		end
	end)
	if not ok then
		err = runErr
	end
	if not line then
		line = CapturePose.line(shot.name, impossible)
	end
	emit("CAPTURE_POSE", shot.name, line, passed == true)
	if not ok then
		print(key .. "_ERROR " .. tostring(err))
	end
end

-- CLIENT: HUD_HIDDEN

local function trackedGuis(playerGui, coreGui)
	local out = {}
	for _, d in ipairs(playerGui:GetDescendants()) do
		if d:IsA("ScreenGui") then
			out[#out + 1] = d
		end
	end
	for _, d in ipairs(coreGui:GetDescendants()) do
		if d:IsA("ScreenGui") and TOP_BAR[d.Name] then
			out[#out + 1] = d
		end
	end
	return out
end

local function countEnabled(playerGui, coreGui)
	local n = 0
	for _, gui in ipairs(trackedGuis(playerGui, coreGui)) do
		if gui.Enabled then
			n += 1
		end
	end
	return n
end

local function runHud(shot, review, localPlayer)
	local ok, err = pcall(function()
		local playerGui = localPlayer:WaitForChild("PlayerGui", 5)
		local coreGui = game:GetService("CoreGui")
		local guis = #trackedGuis(playerGui, coreGui)
		local hidden = review.hideHud(game)
		-- CALIBRATION ANCHOR (HIDDEN): enable one tracked ScreenGui here to force FAIL.
		local during = countEnabled(playerGui, coreGui)
		pcall(function()
			review.restoreHud()
		end)
		local after = countEnabled(playerGui, coreGui)
		local passed = during == 0
		emit(
			"HUD_HIDDEN",
			shot.name,
			"CHECK HUD_HIDDEN_"
				.. shot.name
				.. " "
				.. (passed and "PASS" or "FAIL")
				.. " "
				.. during
				.. " 0 tracked="
				.. guis
				.. " hidden="
				.. hidden
				.. " after="
				.. after,
			passed
		)
	end)
	if not ok then
		pcall(function()
			review.restoreHud()
		end)
		failLine("HUD_HIDDEN", shot.name, "harness error: " .. tostring(err))
	end
end

local function runClient(localPlayer)
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local okPose, CapturePose = pcall(function()
		return require(shared:WaitForChild("CapturePose"))
	end)
	if
		not okPose
		or type(CapturePose) ~= "table"
		or type(CapturePose.measure) ~= "function"
		or type(CapturePose.line) ~= "function"
	then
		for _, shot in ipairs(SHOTS) do
			failLine("CAPTURE_POSE", shot.name, "CapturePose require failed: " .. tostring(CapturePose))
		end
	else
		local cam = workspace.CurrentCamera
		if not cam then
			for _, shot in ipairs(SHOTS) do
				failLine("CAPTURE_POSE", shot.name, "no workspace.CurrentCamera")
			end
		else
			for _, shot in ipairs(SHOTS) do
				runPose(shot, CapturePose, cam)
			end
		end
	end

	local okReview, review = pcall(function()
		return require(shared:WaitForChild("LookDevReview"))
	end)
	if not okReview or type(review) ~= "table" or type(review.hideHud) ~= "function" then
		for _, shot in ipairs(SHOTS) do
			failLine("HUD_HIDDEN", shot.name, "LookDevReview.hideHud require failed: " .. tostring(review))
		end
	else
		for _, shot in ipairs(SHOTS) do
			runHud(shot, review, localPlayer)
		end
	end
end

-- SERVER: CAMERA_GRASS

local function runServer()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local okGrass, Grass = pcall(function()
		return require(shared:WaitForChild("CameraGrass"))
	end)
	if
		not okGrass
		or type(Grass) ~= "table"
		or type(Grass.evaluate) ~= "function"
		or type(Grass.regionFor) ~= "function"
		or type(Grass.column) ~= "function"
	then
		for _, shot in ipairs(SHOTS) do
			failLine("CAMERA_GRASS", shot.name, "CameraGrass require failed: " .. tostring(Grass))
		end
		return
	end
	-- Terrain is a child of workspace, not a service: game:GetService("Terrain") returns nil.
	local terrain = workspace:FindFirstChild("Terrain")
	if not terrain then
		for _, shot in ipairs(SHOTS) do
			failLine("CAMERA_GRASS", shot.name, "no workspace.Terrain")
		end
		return
	end

	local cache = {}
	local function readColumn(x, z)
		local x0, y0, z0, x1, y1, z1 = Grass.regionFor(x, z)
		local key = x0 .. ":" .. z0
		if cache[key] then
			return cache[key]
		end
		local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
		local okRead, materials, occupancies = pcall(function()
			return terrain:ReadVoxels(region, Grass.VOXEL)
		end)
		local column
		if okRead and type(materials) == "table" and type(occupancies) == "table" then
			column = Grass.column(materials, occupancies, x, z)
		else
			column = { ok = false, reason = "ReadVoxels failed: " .. tostring(occupancies) }
		end
		cache[key] = column
		return column
	end

	for _, shot in ipairs(SHOTS) do
		local ok, err = pcall(function()
			local result = Grass.evaluate(shot.position, shot.lookAt, readColumn)
			local passed = result.ok == true
			local detail = "eyeClearance="
				.. fmt(result.eyeClearance)
				.. " lowGrassHits="
				.. tostring(result.lowGrassHits)
				.. " samples="
				.. tostring(result.samples)
			if result.reason then
				detail = detail .. " reason=" .. tostring(result.reason)
			end
			emit(
				"CAMERA_GRASS",
				shot.name,
				"CHECK CAMERA_GRASS_" .. shot.name .. " " .. (passed and "PASS" or "FAIL") .. " " .. detail,
				passed
			)
		end)
		if not ok then
			failLine("CAMERA_GRASS", shot.name, "harness error: " .. tostring(err))
		end
	end
end

-- VM detection: LocalPlayer exists in the Client VM and is nil in the Server VM.
local okLocal, localPlayer = pcall(function()
	return game:GetService("Players").LocalPlayer
end)
results.vm = if okLocal and localPlayer then "CLIENT" else "SERVER"

local expected = if results.vm == "CLIENT" then { "CAPTURE_POSE", "HUD_HIDDEN" } else { "CAMERA_GRASS" }
local okRun, runErr = pcall(function()
	if results.vm == "CLIENT" then
		runClient(localPlayer)
	else
		runServer()
	end
end)
if not okRun then
	results.error = tostring(runErr)
	print("CHECK_Q269_RUN_ERROR " .. results.error)
	for _, kind in ipairs(expected) do
		for _, shot in ipairs(SHOTS) do
			local key = kind .. "_" .. shot.name
			if not results.byName[key] then
				failLine(kind, shot.name, "harness error: " .. results.error)
			end
		end
	end
end

if results.vm == "CLIENT" then
	print(
		"SUMMARY_Q269 VM=CLIENT CAPTURE_POSE "
			.. tostring(results.passed.CAPTURE_POSE or 0)
			.. "/3 HUD_HIDDEN "
			.. tostring(results.passed.HUD_HIDDEN or 0)
			.. "/3"
	)
else
	print(
		"SUMMARY_Q269 VM=SERVER CAMERA_GRASS "
			.. tostring(results.passed.CAMERA_GRASS or 0)
			.. "/3"
	)
end

return results
