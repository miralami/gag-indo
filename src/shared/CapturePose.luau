--!strict
-- CapturePose: pure pose comparison for item 264 review-camera captures.
-- PURE AT LOAD: no game/Instance/Vector3/CFrame/Enum lookup here. Callers supply plain
-- {x, y, z} arrays in the ReviewCameras convention; Lune specs use the same arrays.

export type Vec3 = { number }

type Camera = {
	position: Vec3,
	lookAt: Vec3,
}

export type Result = {
	positionError: number,
	angleDeg: number,
	ok: boolean,
}

local CapturePose = {}

CapturePose.POSITION_TOL = 0.5
CapturePose.ANGLE_TOL_DEG = 2

local function finiteOr(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

-- Returns a unit array and its original length; a zero/non-finite vector yields {0,0,0}, 0.
local function unit(x: number, y: number, z: number): (Vec3, number)
	local length = math.sqrt(x * x + y * y + z * z)
	if length <= 0 or length ~= length or length == math.huge then
		return { 0, 0, 0 }, 0
	end
	return { x / length, y / length, z / length }, length
end

function CapturePose.lookVector(camera: Camera): Vec3
	local eye, target = camera.position, camera.lookAt
	local x = finiteOr(target[1], 0) - finiteOr(eye[1], 0)
	local y = finiteOr(target[2], 0) - finiteOr(eye[2], 0)
	local z = finiteOr(target[3], 0) - finiteOr(eye[3], 0)
	local direction, _ = unit(x, y, z)
	return direction
end

function CapturePose.measure(camera: Camera, currentPos: Vec3, currentLook: Vec3): Result
	local eye = camera.position
	local dx = finiteOr(currentPos[1], 0) - finiteOr(eye[1], 0)
	local dy = finiteOr(currentPos[2], 0) - finiteOr(eye[2], 0)
	local dz = finiteOr(currentPos[3], 0) - finiteOr(eye[3], 0)
	local positionError = finiteOr(math.sqrt(dx * dx + dy * dy + dz * dz), 1e12)

	local currentDirection, currentLength =
		unit(finiteOr(currentLook[1], 0), finiteOr(currentLook[2], 0), finiteOr(currentLook[3], 0))
	local targetDirection = CapturePose.lookVector(camera)
	local angleDeg = 180 -- degenerate current look: finite, outside the tolerance
	if currentLength > 0 then
		local dot = currentDirection[1] * targetDirection[1]
			+ currentDirection[2] * targetDirection[2]
			+ currentDirection[3] * targetDirection[3]
		angleDeg = math.acos(math.clamp(dot, -1, 1)) * (180 / math.pi)
	end
	angleDeg = finiteOr(angleDeg, 180)

	return {
		positionError = positionError,
		angleDeg = angleDeg,
		ok = positionError <= CapturePose.POSITION_TOL and angleDeg <= CapturePose.ANGLE_TOL_DEG,
	}
end

function CapturePose.line(name: string, result: Result): string
	return "CHECK CAPTURE_POSE_"
		.. name
		.. " "
		.. (result.ok and "PASS" or "FAIL")
		.. " "
		.. string.format("%.4f", result.positionError)
		.. "stud/"
		.. string.format("%.2f", result.angleDeg)
		.. "deg <=0.5stud/<=2deg"
end

return CapturePose
