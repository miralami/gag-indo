--!nocheck
-- check_q264: WORK_QUEUE item 264, self-contained CLIENT-DM Studio check. Paste the whole file into
-- execute_luau in the CLIENT datamodel of a fresh Play session, immediately before each
-- screen_capture. This file NEVER captures and NEVER saves the place: it proves the client
-- CurrentCamera sits at the review camera (CAPTURE_POSE) and that leaving the camera on the
-- character fails the same measurement (non-vacuity). Camera state is restored on every path.
--
--   CAPTURE_POSE_<SHOT>            <=0.5stud/<=2deg PASS at the review camera
--   CAPTURE_POSE_<SHOT>_CAL_CHARACTER  FAIL with the camera left on the character
--   CAPTURE_VM FAIL                 wrong datamodel: rerun in Client

local results = { checks = {}, byName = {}, appliedPasses = 0, calibrationFails = 0, errors = {} }

-- Poses are literals read from ReviewCameras.get() in the SERVER VM on 2026-11-23. They are inlined
-- here on purpose: ReviewCameras requires ServerScriptService.Server.World.MapSpec, which does not
-- exist in the CLIENT VM, so requiring it from this check would infinite-yield and freeze Studio.
local SHOTS = {
	{
		name = "ROAD_FENCE_01",
		camera = "path_curve",
		position = { 90, 10, -26 },
		lookAt = { 90, 1.1, -10 },
	}, -- sprint-3 shot #01
	{
		name = "LAMPS_13",
		camera = "lamp_night",
		position = { 124, 10, -12 },
		lookAt = { 144, 5, 0 },
	}, -- sprint-3 shot #13
}

local CapturePose

local function emit(name, text)
	results.checks[#results.checks + 1] = text
	results.byName[name] = text
	print(text)
end

local function resultLine(name, result)
	emit(name, CapturePose.line(name, result))
end

local function resultLineOnce(name, result)
	if not results.byName[name] then
		resultLine(name, result)
	end
end

local impossible = { positionError = 1e12, angleDeg = 180, ok = false }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local isClient = false
pcall(function()
	isClient = RunService:IsClient()
end)

local function vmFail(reason)
	emit("CAPTURE_VM", "CAPTURE_VM FAIL " .. reason .. " — run this in Client datamodel, not Server")
	results.errors[#results.errors + 1] = reason
end

if not isClient or not localPlayer then
	vmFail("no LocalPlayer / not Client")
	return results
end

local cam
local okCamera, cameraValue = pcall(function()
	return workspace.CurrentCamera
end)
local usable = false
if okCamera and cameraValue then
	pcall(function()
		usable = cameraValue:IsA("Camera") and cameraValue.CameraType ~= nil
	end)
end
if not usable then
	vmFail("workspace.CurrentCamera is not a client camera")
	return results
end
cam = cameraValue

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local okPose, poseModule = pcall(function()
	return require(shared:WaitForChild("CapturePose"))
end)
if
	not okPose
	or type(poseModule) ~= "table"
	or type(poseModule.measure) ~= "function"
	or type(poseModule.line) ~= "function"
then
	vmFail("CapturePose require failed: " .. tostring(poseModule))
	return results
end
CapturePose = poseModule

local function readPose()
	local ok, position, look = pcall(function()
		local cframe = cam.CFrame
		local pos, direction = cframe.Position, cframe.LookVector
		return { pos.X, pos.Y, pos.Z }, { direction.X, direction.Y, direction.Z }
	end)
	if not ok then
		return nil, tostring(position)
	end
	return { position = position, look = look }
end

local function cameraEntry(shot)
	if type(shot.position) ~= "table" or type(shot.lookAt) ~= "table" then
		return nil
	end
	return { position = shot.position, lookAt = shot.lookAt }
end

local function restore(prior)
	if not prior then
		return
	end
	pcall(function()
		cam.CFrame = prior.cframe
	end)
	pcall(function()
		cam.CameraType = prior.cameraType
	end)
end

local function runShot(shot)
	local prior
	local appliedPass, calibrationFail = false, false
	local ok, err = pcall(function()
		local okSave, saveErr = pcall(function()
			prior = { cameraType = cam.CameraType, cframe = cam.CFrame }
		end)
		if not okSave or not prior then
			error("cannot save camera state: " .. tostring(saveErr))
		end

		local entry = cameraEntry(shot)
		if not entry then
			error("review camera pose missing: " .. tostring(shot.name))
		end

		-- (a) CALIBRATION: leave the camera on the character, wait two frames, measure. Must FAIL.
		local okCustom, customErr = pcall(function()
			cam.CameraType = Enum.CameraType.Custom
		end)
		if not okCustom then
			error("CameraType Custom write failed: " .. tostring(customErr))
		end
		task.wait()
		task.wait()
		local calibrationPose = readPose()
		if not calibrationPose then
			resultLine(shot.name .. "_CAL_CHARACTER", impossible)
		else
			local result = CapturePose.measure(entry, calibrationPose.position, calibrationPose.look)
			resultLine(shot.name .. "_CAL_CHARACTER", result)
			calibrationFail = result.ok ~= true
		end

		-- (b) APPLY: Scriptable at the review camera, wait two frames, measure. Must PASS. This is
		-- the position the main session captures before screen_capture runs.
		local okScriptable, scriptableErr = pcall(function()
			cam.CameraType = Enum.CameraType.Scriptable
		end)
		if not okScriptable then
			error("CameraType Scriptable write failed: " .. tostring(scriptableErr))
		end
		local eye, look = entry.position, entry.lookAt
		local okCFrame, cframeErr = pcall(function()
			cam.CFrame = CFrame.lookAt(Vector3.new(eye[1], eye[2], eye[3]), Vector3.new(look[1], look[2], look[3]))
		end)
		if not okCFrame then
			error("review CFrame write failed: " .. tostring(cframeErr))
		end
		task.wait()
		task.wait()
		local appliedPose = readPose()
		if not appliedPose then
			resultLine(shot.name, impossible)
		else
			local result = CapturePose.measure(entry, appliedPose.position, appliedPose.look)
			resultLine(shot.name, result)
			appliedPass = result.ok == true
		end
	end)

	-- (c) restore in every path, including a failed calibration/apply/read.
	restore(prior)
	if not ok then
		resultLineOnce(shot.name .. "_CAL_CHARACTER", impossible)
		resultLineOnce(shot.name, impossible)
		results.errors[#results.errors + 1] = shot.name .. ": " .. tostring(err)
		print("CAPTURE_SHOT_ERROR " .. shot.name .. " " .. tostring(err))
	end
	if appliedPass then
		results.appliedPasses += 1
	end
	if calibrationFail then
		results.calibrationFails += 1
	end
end

local okRun, runErr = pcall(function()
	for _, shot in ipairs(SHOTS) do
		runShot(shot)
	end
end)
if not okRun then
	results.errors[#results.errors + 1] = "loop: " .. tostring(runErr)
	print("CAPTURE_LOOP_ERROR " .. tostring(runErr))
end

local summaryOk = results.appliedPasses == #SHOTS and results.calibrationFails == #SHOTS
emit(
	"CAPTURE_POSE_SUMMARY",
	"CHECK CAPTURE_POSE_SUMMARY "
		.. (summaryOk and "PASS" or "FAIL")
		.. " applied_pass="
		.. results.appliedPasses
		.. "/"
		.. #SHOTS
		.. " calibration_fail="
		.. results.calibrationFails
		.. "/"
		.. #SHOTS
)

return results
