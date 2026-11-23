--!strict
-- CameraGrass: pure-data rules for the review CAMERA_GRASS check (WORK_QUEUE item 250).
-- No Instance, Region3 or Enum lookup at load. The Studio harness supplies voxel columns read from
-- Terrain:ReadVoxels(region, 4); Lune specs supply synthetic columns. Thresholds stay 4 / 3 / 12.

export type Column = {
	ok: boolean,
	surface: number?, -- top face, in studs, of the highest solid voxel in this XZ cell
	grass: boolean?,
	reason: string?,
}

export type Result = {
	ok: boolean,
	eyeClearance: number?,
	lowEye: boolean,
	lowGrassHits: number,
	samples: number,
	reason: string?,
}

local CameraGrass = {}

CameraGrass.VOXEL = 4
CameraGrass.MIN_EYE_CLEARANCE = 4
CameraGrass.MIN_RAY_HEIGHT = 3
CameraGrass.RAY_DISTANCE = 12
-- Multiples of VOXEL, so every harness Region3 is grid-aligned like ShippingLookR7 / GroundVariationR10.
CameraGrass.Y_MIN = -16
CameraGrass.Y_MAX = 128

local function named(material: any, token: string): boolean
	return string.find(tostring(material), "Material." .. token, 1, true) ~= nil
end

function CameraGrass.isGrass(material: any): boolean
	return named(material, "Grass") or named(material, "LeafyGrass")
end

function CameraGrass.cellOrigin(value: number): number
	return math.floor(value / CameraGrass.VOXEL) * CameraGrass.VOXEL
end

-- Grid-aligned region bounds for one XZ point: three 4-stud cells centred on the point's own cell.
function CameraGrass.regionFor(x: number, z: number): (number, number, number, number, number, number)
	local x0 = CameraGrass.cellOrigin(x) - CameraGrass.VOXEL
	local z0 = CameraGrass.cellOrigin(z) - CameraGrass.VOXEL
	return x0, CameraGrass.Y_MIN, z0, x0 + CameraGrass.VOXEL * 3, CameraGrass.Y_MAX, z0 + CameraGrass.VOXEL * 3
end

-- Classify the column under one XZ point from a ReadVoxels sample of regionFor(x, z).
function CameraGrass.column(materials: any, occupancies: any, x: number, z: number): Column
	local x0, _, z0 = CameraGrass.regionFor(x, z)
	local ix = math.floor((x - x0) / CameraGrass.VOXEL) + 1
	local iz = math.floor((z - z0) / CameraGrass.VOXEL) + 1
	local slab = type(materials) == "table" and materials[ix] or nil
	local occSlab = type(occupancies) == "table" and occupancies[ix] or nil
	if type(slab) ~= "table" or type(occSlab) ~= "table" then
		return { ok = false, reason = "voxel sample missing" }
	end
	for iy = #slab, 1, -1 do
		local row, occRow = slab[iy], occSlab[iy]
		local material = type(row) == "table" and row[iz] or nil
		local occupancy = type(occRow) == "table" and occRow[iz] or nil
		if
			material ~= nil
			and not named(material, "Air")
			and type(occupancy) == "number"
			and occupancy > 0
		then
			return {
				ok = true,
				surface = CameraGrass.Y_MIN + iy * CameraGrass.VOXEL,
				grass = CameraGrass.isGrass(material),
			}
		end
	end
	return { ok = false, reason = "no solid terrain column" }
end

-- `read(x, z)` returns Column. Sample every half stud along the finite eye->lookAt ray.
function CameraGrass.evaluate(eye: { number }, look: { number }, read: (number, number) -> Column): Result
	local dx, dy, dz = look[1] - eye[1], look[2] - eye[2], look[3] - eye[3]
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	if length <= 0 then
		return { ok = false, lowEye = false, lowGrassHits = 0, samples = 0, reason = "degenerate ray" }
	end
	local underEye = read(eye[1], eye[3])
	if not underEye.ok or type(underEye.surface) ~= "number" then
		return {
			ok = false,
			lowEye = false,
			lowGrassHits = 0,
			samples = 0,
			reason = underEye.reason or "no terrain under eye",
		}
	end
	local clearance = eye[2] - underEye.surface
	local lowEye = clearance < CameraGrass.MIN_EYE_CLEARANCE
	local lowGrassHits, samples = 0, 0
	local step = 0.5
	while step <= CameraGrass.RAY_DISTANCE and step <= length do
		local t = step / length
		local px, py, pz = eye[1] + dx * t, eye[2] + dy * t, eye[3] + dz * t
		local column = read(px, pz)
		samples += 1
		if not column.ok or type(column.surface) ~= "number" then
			return {
				ok = false,
				eyeClearance = clearance,
				lowEye = lowEye,
				lowGrassHits = lowGrassHits,
				samples = samples,
				reason = column.reason or "no terrain under ray",
			}
		end
		if column.grass == true and py - column.surface < CameraGrass.MIN_RAY_HEIGHT then
			lowGrassHits += 1
		end
		step += 0.5
	end
	return {
		ok = not lowEye and lowGrassHits == 0 and samples > 0,
		eyeClearance = clearance,
		lowEye = lowEye,
		lowGrassHits = lowGrassHits,
		samples = samples,
	}
end

return CameraGrass
