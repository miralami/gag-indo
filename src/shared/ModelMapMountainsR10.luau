--!strict
-- ModelMapMountainsR10: pure data for the OFF-BY-DEFAULT "mountains_r10" candidate
-- (WORK_QUEUE items 243 + 251 + 260, rebuilt after two designer rejections of the box wall:
-- "use actual mountain shapes, don't do boxes").
--
-- The mountains are TERRAIN, not parts. Three bands of overlapping peaks ring the whole playable
-- map outside the background forest (radii 260..460) and outside the dome-hill ring (to ~520):
--   near  640 studs  60..120 high, LeafyGrass/Grass slopes with a Rock crown (greenest)
--   mid   820 studs  120..190 high, Grass slopes, Rock and Slate crowns
--   far  1020 studs  170..260 high, Slate (bluest; the applier adds a mild haze while enabled)
-- Every peak is a stack of four balls (wide shoulder to narrow crown) over a flat apron cylinder,
-- plus an occasional wedge spur, so the skyline reads as terraced ridges and not as a wall. Each
-- band keeps the West sunset corridor open and one extra valley gap at a different bearing, so the
-- bands never close into one uniform wall. Everything is deterministic (Park-Miller generator, fixed
-- seeds). No engine calls and no asset IDs: the server applier turns these descriptors into
-- Terrain:FillBall / FillCylinder / FillWedge calls and undoes them by filling the same shapes with Air.
--
-- Shape descriptor fields:
--   kind "Ball"     x y z radius material band
--   kind "Cylinder" x y z radius height material band   (axis along Y)
--   kind "Wedge"    x y z sx sy sz yaw material band    (yaw in radians about Y)

local Data = {}

type Gap = { number }
type BandSpec = {
	id: string,
	distance: number,
	jitter: number,
	radiusMin: number,
	radiusMax: number,
	heightMin: number,
	heightMax: number,
	spacing: number,
	valley: Gap,
	seed: number,
	slope: string,
	mid: string,
	crown: string,
}
type Shape = {
	kind: string,
	x: number,
	y: number,
	z: number,
	radius: number?,
	height: number?,
	sx: number?,
	sy: number?,
	sz: number?,
	yaw: number?,
	material: string,
	band: string,
}
type Peak = {
	band: string,
	angle: number,
	x: number,
	z: number,
	radius: number,
	height: number,
	style: number,
	lean: number,
}

Data.id = "mountains_r10"
-- Kept for old tooling that looks the name up; the terrain candidate stages no Instance at all.
Data.folderName = "LookDevMountainsR10_mountains_r10"

Data.PERF_TARGET = 500
Data.PERF_RADIUS = 100

-- No ridge shape may reach inside this radius from the map centre (forest ring + dome hills end near 520).
Data.MIN_RADIUS = 480
Data.CLEAR_RADIUS = 520
-- Sampled by check_q260 as the nearest-ridge floor.
Data.MIN_DISTANCE = 480
-- Fills smaller than this per band chunk are yielded with task.wait by the applier.
Data.CHUNK = 40

-- Bearings follow the forest module: x = cos(a), z = sin(a), degrees. The West sunset corridor
-- (the forest clears 130..230) stays open; the ridge gap is the narrower middle of it.
Data.SUNSET_GAP = { 168, 192 }

local BANDS: { BandSpec } = {
	{
		id = "near",
		distance = 640,
		jitter = 24,
		radiusMin = 55,
		radiusMax = 72,
		heightMin = 60,
		heightMax = 120,
		spacing = 1.35,
		valley = { 70, 86 },
		seed = 1101,
		slope = "LeafyGrass",
		mid = "Grass",
		crown = "Rock",
	},
	{
		id = "mid",
		distance = 820,
		jitter = 30,
		radiusMin = 80,
		radiusMax = 104,
		heightMin = 120,
		heightMax = 190,
		spacing = 1.4,
		valley = { 300, 318 },
		seed = 2203,
		slope = "Grass",
		mid = "Rock",
		crown = "Slate",
	},
	{
		id = "far",
		distance = 1020,
		jitter = 36,
		radiusMin = 100,
		radiusMax = 130,
		heightMin = 170,
		heightMax = 260,
		spacing = 1.45,
		valley = { 20, 36 },
		seed = 3307,
		slope = "Slate",
		mid = "Slate",
		crown = "Rock",
	},
}

-- Four stacked balls per peak: { share of the peak height at the top of the ball, share of the
-- footprint radius }. Wide low shoulder first, narrow crown last.
local TIERS = {
	{ 0.35, 1.0 },
	{ 0.62, 0.78 },
	{ 0.84, 0.55 },
	{ 1.0, 0.34 },
}

Data.BANDS = BANDS
Data.TIERS = TIERS
Data.SPUR_EVERY = 3

-- Mild bluish haze applied only while the candidate is enabled (the applier stores and restores).
Data.ATMOSPHERE = {
	color = { r = 168, g = 192, b = 214 },
	density = 0.3,
	haze = 1.6,
}

local function newRandom(seed: number): () -> number
	local modulus = 2 ^ 31 - 1
	local state = seed
	return function(): number
		state = (state * 16807) % modulus
		return state / modulus
	end
end

local function inGap(angle: number, half: number, gap: Gap): boolean
	return angle + half > gap[1] and angle - half < gap[2]
end

local function buildBand(spec: BandSpec): { Peak }
	local random = newRandom(spec.seed)
	local peaks: { Peak } = {}
	local angle = 0.0
	local gaps = { Data.SUNSET_GAP, spec.valley }
	table.sort(gaps, function(a: Gap, b: Gap): boolean
		return a[1] < b[1]
	end)
	while true do
		local radius = spec.radiusMin + (spec.radiusMax - spec.radiusMin) * random()
		local height = spec.heightMin + (spec.heightMax - spec.heightMin) * random()
		local radial = spec.distance + (random() * 2 - 1) * spec.jitter
		local half = math.deg(math.asin(math.min(1, radius / spec.distance)))
		if angle == 0 then
			angle = half -- first footprint starts at bearing 0
		end
		for _, gap in ipairs(gaps) do
			if inGap(angle, half, gap) then
				angle = gap[2] + half
			end
		end
		local last = false
		if angle + half > 360 then
			angle = 360 - half -- closing peak: its footprint ends exactly at bearing 360
			last = true
		end
		local rad = math.rad(angle)
		peaks[#peaks + 1] = {
			band = spec.id,
			angle = angle,
			x = math.cos(rad) * radial,
			z = math.sin(rad) * radial,
			radius = radius,
			height = height,
			style = random(),
			lean = random() * 2 - 1,
		}
		if last then
			break
		end
		angle += math.deg(spec.spacing * radius / spec.distance)
	end
	return peaks
end

local PEAKS: { Peak } = {}
local BAND_PEAKS: { [string]: { Peak } } = {}
for _, spec in ipairs(BANDS) do
	local list = buildBand(spec)
	BAND_PEAKS[spec.id] = list
	for _, peak in ipairs(list) do
		PEAKS[#PEAKS + 1] = peak
	end
end

Data.PEAKS = PEAKS
Data.BAND_PEAKS = BAND_PEAKS

local SHAPES: { Shape } = {}
local BAND_SHAPES: { [string]: { Shape } } = {}

local function add(band: string, shape: Shape)
	SHAPES[#SHAPES + 1] = shape
	local list = BAND_SHAPES[band]
	if not list then
		list = {}
		BAND_SHAPES[band] = list
	end
	list[#list + 1] = shape
end

local function ballShape(spec: BandSpec, x: number, z: number, top: number, radius: number, material: string): Shape
	return {
		kind = "Ball",
		x = x,
		y = top - radius,
		z = z,
		radius = radius,
		material = material,
		band = spec.id,
	}
end

-- Far band first, near band last, so the nearer ridge overwrites the foot of the one behind it.
for bandIndex = #BANDS, 1, -1 do
	local spec = BANDS[bandIndex]
	local list = BAND_PEAKS[spec.id]
	for index, peak in ipairs(list) do
		-- Flat apron so the ridge sits on continuous ground and no peak floats above empty voxels.
		add(spec.id, {
			kind = "Cylinder",
			x = peak.x,
			y = -2,
			z = peak.z,
			radius = peak.radius * 1.25,
			height = 8,
			material = spec.slope,
			band = spec.id,
		})
		-- Tangent (along the band) and the peak's own lean, used to push crowns sideways.
		local tangent = math.rad(peak.angle + 90)
		local tx, tz = math.cos(tangent), math.sin(tangent)
		local R, H = peak.radius, peak.height
		-- Wide low shoulder (centre clamped so it never sinks deeper than half its radius).
		local shoulder = R
		local shoulderTop = H * 0.38
		local shoulderBall = ballShape(spec, peak.x, peak.z, shoulderTop, shoulder, spec.slope)
		shoulderBall.y = math.max(shoulderBall.y, -0.5 * shoulder)
		add(spec.id, shoulderBall)
		if peak.style < 0.4 then
			-- Sharp: a mid body, then a narrow crown pushed sideways plus a lower sub-peak the other way.
			add(spec.id, ballShape(spec, peak.x, peak.z, H * 0.66, R * 0.66, spec.mid))
			add(
				spec.id,
				ballShape(
					spec,
					peak.x + tx * R * 0.22 * peak.lean,
					peak.z + tz * R * 0.22 * peak.lean,
					H,
					R * 0.27,
					spec.crown
				)
			)
			add(
				spec.id,
				ballShape(
					spec,
					peak.x - tx * R * 0.4 * peak.lean,
					peak.z - tz * R * 0.4 * peak.lean,
					H * 0.8,
					R * 0.3,
					spec.crown
				)
			)
		elseif peak.style < 0.75 then
			-- Broad: a thick shoulder with a flatter, wider crown.
			add(spec.id, ballShape(spec, peak.x, peak.z, H * 0.74, R * 0.82, spec.mid))
			add(
				spec.id,
				ballShape(
					spec,
					peak.x + tx * R * 0.25 * peak.lean,
					peak.z + tz * R * 0.25 * peak.lean,
					H,
					R * 0.45,
					spec.crown
				)
			)
		else
			-- Twin: two crowns of unequal height side by side along the ridge.
			add(spec.id, ballShape(spec, peak.x, peak.z, H * 0.62, R * 0.72, spec.mid))
			add(spec.id, ballShape(spec, peak.x + tx * R * 0.35, peak.z + tz * R * 0.35, H, R * 0.34, spec.crown))
			add(spec.id, ballShape(spec, peak.x - tx * R * 0.35, peak.z - tz * R * 0.35, H * 0.82, R * 0.3, spec.crown))
		end
		if index % Data.SPUR_EVERY == 0 then
			-- A wedge spur along the ridge tangent breaks the round silhouette of the stack.
			local offset = R * 0.9
			add(spec.id, {
				kind = "Wedge",
				x = peak.x + tx * offset,
				y = H * 0.2,
				z = peak.z + tz * offset,
				sx = R * 0.45,
				sy = H * 0.4,
				sz = R * 1.0,
				yaw = -tangent,
				material = spec.mid,
				band = spec.id,
			})
		end
		-- Saddle to the next peak: a chain of smaller, lower balls along the segment joins the two
		-- peaks into one ridgeline. Skipped across the sunset and valley gaps (footprints do not touch).
		local nextPeak = list[index + 1]
		if nextPeak then
			local dx, dz = nextPeak.x - peak.x, nextPeak.z - peak.z
			local span = math.sqrt(dx * dx + dz * dz)
			if span <= (peak.radius + nextPeak.radius) * 1.15 then
				local low = math.min(peak.height, nextPeak.height)
				local saddleRadius = math.min(peak.radius, nextPeak.radius) * 0.55
				local steps = { 0.33, 0.67 }
				for stepIndex, along in ipairs(steps) do
					local top = low * (if stepIndex == 1 then 0.62 else 0.54) + (peak.lean * 6)
					add(
						spec.id,
						ballShape(
							spec,
							peak.x + dx * along,
							peak.z + dz * along,
							top,
							saddleRadius,
							if top > spec.heightMin * 0.8 then spec.mid else spec.slope
						)
					)
				end
			end
		end
	end
end

-- Foothills: two low rolling rings between the plateau edge and the first band, so the ground rises
-- into the mountains with no flat gap. Nothing here is taller than 25 studs inside radius 470 and the
-- footprint never starts inside radius 410. Filled last, so they overwrite the feet of the ridges.
local FOOTHILL_RINGS = {
	{
		distance = 500,
		jitter = 12,
		radius = 64,
		heightMin = 12,
		heightMax = 25,
		step = 78,
		material = "Grass",
		seed = 4409,
	},
	{
		distance = 565,
		jitter = 15,
		radius = 80,
		heightMin = 25,
		heightMax = 45,
		step = 100,
		material = "LeafyGrass",
		seed = 5521,
	},
}
Data.FOOTHILL_RINGS = FOOTHILL_RINGS
Data.FOOTHILL_MIN_RADIUS = 410
Data.FOOTHILL_INNER_LIMIT = 470
Data.FOOTHILL_INNER_MAX_HEIGHT = 25
local FOOTHILLS: { Shape } = {}
for _, ring in ipairs(FOOTHILL_RINGS) do
	local random = newRandom(ring.seed)
	local count = math.floor(2 * math.pi * ring.distance / ring.step + 0.5)
	for index = 0, count - 1 do
		local angle = math.rad((index + (random() - 0.5) * 0.5) * 360 / count)
		local radial = ring.distance + (random() * 2 - 1) * ring.jitter
		local top = ring.heightMin + (ring.heightMax - ring.heightMin) * random()
		local degrees = math.deg(angle)
		if degrees >= 130 and degrees <= 230 then
			top = math.min(top, 18) -- keep the sunset corridor low
		end
		local shape = ballShape(
			{ id = "foot" } :: any,
			math.cos(angle) * radial,
			math.sin(angle) * radial,
			top,
			ring.radius,
			ring.material
		)
		FOOTHILLS[#FOOTHILLS + 1] = shape
		add("foot", shape)
	end
end
Data.FOOTHILLS = FOOTHILLS

Data.SHAPES = SHAPES
Data.BAND_SHAPES = BAND_SHAPES

function Data.shapes(): { Shape }
	return Data.SHAPES
end

-- Old part-based tooling asks for these lists; the terrain candidate stages no parts, so both are empty.
function Data.mountainParts(): { any }
	return {}
end

function Data.smokeParts(): { any }
	return {}
end

-- Load-time contract check. Keeps the data honest before any applier or harness reads it.
do
	assert(#BANDS == 3, "mountains_r10: need exactly three ridge bands")
	local allowed: { [string]: boolean } = {
		Rock = true,
		Slate = true,
		Grass = true,
		LeafyGrass = true,
		Ground = true,
	}
	local previous = 0
	for _, spec in ipairs(BANDS) do
		assert(spec.distance > previous, "mountains_r10: band distances must increase")
		previous = spec.distance
		assert(
			spec.distance - spec.jitter - spec.radiusMax * 1.25 >= Data.CLEAR_RADIUS,
			"mountains_r10: band " .. spec.id .. " reaches inside the clear radius"
		)
	end
	for _, shape in ipairs(FOOTHILLS) do
		local radial = math.sqrt(shape.x * shape.x + shape.z * shape.z)
		local r = shape.radius :: number
		local groundCut = math.sqrt(math.max(0, r * r - shape.y * shape.y))
		assert(radial - groundCut >= Data.FOOTHILL_MIN_RADIUS, "mountains_r10: foothill reaches inside radius 410")
		local s = radial - Data.FOOTHILL_INNER_LIMIT
		if s < r then
			local height = shape.y + math.sqrt(r * r - math.max(0, s) * math.max(0, s))
			assert(height <= Data.FOOTHILL_INNER_MAX_HEIGHT, "mountains_r10: foothill too tall inside radius 470")
		end
	end
	for _, shape in ipairs(SHAPES) do
		assert(allowed[shape.material], "mountains_r10: unsupported terrain material " .. shape.material)
		assert(
			shape.kind == "Ball" or shape.kind == "Cylinder" or shape.kind == "Wedge",
			"mountains_r10: unknown shape kind " .. shape.kind
		)
	end
end

return Data
