--!strict
-- ModelMapHorizonFillR10: pure data for the OFF-BY-DEFAULT "horizon_fill_r10" candidate
-- (WORK_QUEUE section Q item 197 lane 1). One huge flat sea-plane skirt and a pale haze pair with
-- the hill-ring horizon. No engine calls, no asset IDs: a server applier consumes these descriptors.

local Data = {}

type Vec3 = { number }
type RGB = { r: number, g: number, b: number }
type PartDescriptor = {
	name: string,
	size: { number },
	position: { number },
	color: RGB,
}
type Point = { x: number, y: number, z: number }
type HazeValues = { Haze: number, Color: RGB }

Data.id = "horizon_fill_r10"
Data.folderName = "LookDevHorizonFillR10_horizon_fill_r10"

Data.CAMERA_NAMES = { "canonical_overview", "spawn", "hill_ring_in" }
Data.HORIZON_DISTANCE = 1200
Data.YAW_OFFSETS = { -0.35, -0.175, 0, 0.175, 0.35 } -- 5 samples, about +/-20 degrees

-- Roblox clamps Part.Size to 2048 per axis; one 2048 tile centred at z=-128 covers every
-- horizon sample (spawn z~-1050 .. hill z~+792, all |x|<=484) while staying inside the engine cap.
Data.SKIRT_HALF = 1024
Data.SKIRT_Z = -128
Data.SKIRT_Y = -8
Data.SKIRT_THICKNESS = 1
Data.SKIRT_COLOR = { r = 128, g = 158, b = 150 } -- hazy blue-green matching the hill-ring horizon

Data.HAZE = 2.0
Data.HAZE_COLOR = { r = 214, g = 226, b = 220 } -- pale sky-horizon haze

Data.PERF_TARGET = 500
Data.PERF_RADIUS = 100

function Data.skirtParts(): { PartDescriptor }
	return {
		{
			name = "HorizonSkirt",
			size = { Data.SKIRT_HALF * 2, Data.SKIRT_THICKNESS, Data.SKIRT_HALF * 2 },
			position = { 0, Data.SKIRT_Y, Data.SKIRT_Z },
			color = {
				r = Data.SKIRT_COLOR.r,
				g = Data.SKIRT_COLOR.g,
				b = Data.SKIRT_COLOR.b,
			},
		},
	}
end

function Data.horizonPoint(eye: Vec3, look: Vec3, yaw: number): Point
	local fx, fz = look[1] - eye[1], look[3] - eye[3]
	local length = math.sqrt(fx * fx + fz * fz)
	if length <= 0 then
		fx, fz, length = 0, 1, 1
	end
	fx, fz = fx / length, fz / length
	local cosYaw, sinYaw = math.cos(yaw), math.sin(yaw)
	local rx = fx * cosYaw - fz * sinYaw
	local rz = fx * sinYaw + fz * cosYaw
	return {
		x = eye[1] + rx * Data.HORIZON_DISTANCE,
		y = eye[2],
		z = eye[3] + rz * Data.HORIZON_DISTANCE,
	}
end

function Data.horizonPoints(eye: Vec3, look: Vec3): { Point }
	local points: { Point } = {}
	for _, yaw in ipairs(Data.YAW_OFFSETS) do
		points[#points + 1] = Data.horizonPoint(eye, look, yaw)
	end
	return points
end

function Data.hazeValues(): HazeValues
	return {
		Haze = Data.HAZE,
		Color = {
			r = Data.HAZE_COLOR.r,
			g = Data.HAZE_COLOR.g,
			b = Data.HAZE_COLOR.b,
		},
	}
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	assert(#Data.CAMERA_NAMES == 3, "horizon_fill_r10: camera count is not 3")
	assert(#Data.YAW_OFFSETS == 5, "horizon_fill_r10: horizon sample count is not 5")
	assert(#Data.skirtParts() == 1, "horizon_fill_r10: skirt part count is not 1")
	assert(Data.SKIRT_HALF * 2 <= 2048, "horizon_fill_r10: skirt exceeds the 2048 stud Part size cap")
	assert(Data.SKIRT_Y < -3.5, "horizon_fill_r10: skirt is not below TERRAIN_BASE_Y")
	assert(Data.HAZE >= 1 and Data.HAZE <= 2.4, "horizon_fill_r10: haze outside 1.0..2.4")
	for _, channel in ipairs({
		Data.SKIRT_COLOR.r,
		Data.SKIRT_COLOR.g,
		Data.SKIRT_COLOR.b,
		Data.HAZE_COLOR.r,
		Data.HAZE_COLOR.g,
		Data.HAZE_COLOR.b,
	}) do
		assert(channel >= 0 and channel <= 255, "horizon_fill_r10: colour channel outside 0..255")
	end
	-- Representative eye/look pairs for the three review cameras. z is checked relative to the
	-- skirt centre because the single tile is offset to cover spawn's far -z samples.
	local views = {
		{ { 0, 100, 392 }, { 0, 10, 0 } },
		{ { 0, 20, 150 }, { 0, 8, 96 } },
		{ { 0, 100, -408 }, { 0, 10, 0 } },
	}
	for _, view in ipairs(views) do
		for _, point in ipairs(Data.horizonPoints(view[1], view[2])) do
			assert(math.abs(point.x) <= Data.SKIRT_HALF, "horizon_fill_r10: horizon sample x outside skirt")
			assert(
				math.abs(point.z - Data.SKIRT_Z) <= Data.SKIRT_HALF,
				"horizon_fill_r10: horizon sample z outside skirt"
			)
		end
	end
end

return Data
