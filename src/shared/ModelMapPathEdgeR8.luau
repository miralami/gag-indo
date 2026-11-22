--!strict
-- ModelMapPathEdgeR8: pure data for the OFF-BY-DEFAULT "pathedge_r8" LookDev candidate
-- (WORK_QUEUE section M item 75, redone in section O item 142). Dirt-path edge dressing:
-- grass clumps, pebbles and a few flat puddles along BOTH edges of every road arm, ring segment
-- and continuation. Each piece records its nearest centreline point, the path's half-width and its
-- own signed lateral distance, so the applier and the harness never re-guess the geometry.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. The applier passes
-- the real MapSpec.roadArms() / ringSegments() / roadContinuations() / ROAD geometry in, so this
-- module never reimplements the road layout. Jitter is an integer hash of (seed, index, salt):
-- deterministic. Lateral = side * (halfWidth + extra), with extra in
-- [PATH_OFFSET_MIN, PATH_OFFSET_MAX]; a clump at most CLUMP_MAX_WIDTH wide therefore reaches the
-- road edge without entering the central corridor.
--
-- ponytail: no per-path curvature model — the ring is a set of 6-degree MapSpec chords, and each
-- chord's own centreline is exact. Upgrade only if MapSpec switches to a spline ring.

local ModelMapPathEdgeR8 = {}

ModelMapPathEdgeR8.id = "pathedge_r8"
ModelMapPathEdgeR8.folderName = "LookDevPathEdgeR8_pathedge_r8"
ModelMapPathEdgeR8.MIN_EDGE_PIECES = 120
ModelMapPathEdgeR8.PUDDLE_TRANSPARENCY = 0.4
ModelMapPathEdgeR8.CENTRAL_CLEAR = 6
ModelMapPathEdgeR8.SPACING_MIN = 3
ModelMapPathEdgeR8.SPACING_MAX = 5

-- Item 142: the offset band beyond the path edge and the check/grass geometry ceilings.
ModelMapPathEdgeR8.PATH_OFFSET_MIN = 0.3
ModelMapPathEdgeR8.PATH_OFFSET_MAX = 2.5
ModelMapPathEdgeR8.PATH_EDGE_GROW = 3
ModelMapPathEdgeR8.CLUMP_MAX_WIDTH = 1.5

-- Item 177: a denser, visible dressing sampled independently of the item-142 debris pieces. One
-- plant per PLANT_SPACING studs on EACH side of every road centreline, 1..2 studs tall, with exactly
-- two flower colours. PLANT_CLEAR keeps the whole footprint outside the road surface.
ModelMapPathEdgeR8.PLANT_SPACING = 3
ModelMapPathEdgeR8.PLANT_HEIGHT_MIN = 1.15
ModelMapPathEdgeR8.PLANT_HEIGHT_MAX = 1.95
ModelMapPathEdgeR8.PLANT_CLEAR = 0.9
ModelMapPathEdgeR8.FLOWER_COLOURS = {
	{ name = "white", rgb = { 246, 240, 214 } },
	{ name = "yellow", rgb = { 236, 186, 62 } },
}

local END_MARGIN = 3
local SIDES = { -1, 1 }

-- Buckets stay below 2^53, so the multiply is exact on both Lune and Roblox.
local function noise(seed: number, index: number, salt: number): number
	local n = (seed * 7919 + index * 104729 + salt * 129970) % 100003
	n = (n * n) % 100003
	return n / 100003
end

local function kindFor(index: number): string
	if index % 10 == 0 then
		return "puddle"
	end
	return if index % 2 == 0 then "pebble" else "grass_tuft"
end

local function sideName(side: number): string
	return if side < 0 then "-1" else "1"
end

-- The lateral push beyond the half-width, never negative. A clump is at most CLUMP_MAX_WIDTH
-- wide, so grass stops at half that width from the centreline and its inner edge touches the road
-- edge; pebbles and puddles may use the whole band.
local function edgeExtra(seed: number, stepIndex: number, kind: string): number
	local ceiling = ModelMapPathEdgeR8.PATH_OFFSET_MAX
	if kind == "grass_tuft" then
		ceiling = math.min(ceiling, ModelMapPathEdgeR8.CLUMP_MAX_WIDTH / 2)
	end
	return ModelMapPathEdgeR8.PATH_OFFSET_MIN
		+ noise(seed, stepIndex, 2) * (ceiling - ModelMapPathEdgeR8.PATH_OFFSET_MIN)
end

local function stepFor(seed: number, stepIndex: number): number
	return ModelMapPathEdgeR8.SPACING_MIN
		+ noise(seed, stepIndex, 1) * (ModelMapPathEdgeR8.SPACING_MAX - ModelMapPathEdgeR8.SPACING_MIN)
end

-- Axis-aligned arms and continuations. MapSpec gives the centre (arm.x, arm.z) and the full sizes;
-- the centreline is the long axis and halfWidth is the short dimension / 2. `along` is the exact
-- position on that centreline; consecutive steps differ by >= SPACING_MIN because only the step
-- length is jittered, never the position on the axis.
function ModelMapPathEdgeR8.armPieces(arm: any, jitterSeed: number): { any }
	local horizontal = arm.sx > arm.sz
	local length = if horizontal then arm.sx else arm.sz
	local halfWidth = math.min(arm.sx, arm.sz) / 2
	local out = {}
	local t = -length / 2 + END_MARGIN
	local stepIndex = 0
	while t <= length / 2 - END_MARGIN do
		stepIndex += 1
		for sideIndex, side in ipairs(SIDES) do
			local index = (stepIndex - 1) * #SIDES + sideIndex
			local kind = kindFor(index)
			local extra = edgeExtra(jitterSeed, stepIndex, kind)
			local cx = if horizontal then arm.x + t else arm.x
			local cz = if horizontal then arm.z else arm.z + t
			local lateral = side * (halfWidth + extra)
			out[#out + 1] = {
				x = if horizontal then cx else cx + lateral,
				z = if horizontal then cz + lateral else cz,
				centre = { cx, cz },
				halfWidth = halfWidth,
				lateral = lateral,
				offset = lateral, -- legacy alias: now the signed centreline distance
				along = t,
				kind = kind,
				side = sideName(side),
				segment = arm.name,
				path = arm.name,
			}
		end
		t += stepFor(jitterSeed, stepIndex)
	end
	return out
end

-- A rotated MapSpec ring chord. Local +X is the tangent, local +Z the perpendicular edge normal;
-- halfWidth comes from MapSpec.ROAD.ringWidth / 2, never from a literal here. The recorded centre
-- is the exact point on the chord that the piece grows out of.
function ModelMapPathEdgeR8.ringPieces(piece: any, jitterSeed: number, halfWidth: number, segmentId: any): { any }
	local yaw = math.rad(piece.yaw)
	local tx, tz = math.cos(yaw), -math.sin(yaw)
	local nx, nz = math.sin(yaw), math.cos(yaw)
	local out = {}
	local t = -piece.length / 2 + END_MARGIN
	local stepIndex = 0
	while t <= piece.length / 2 - END_MARGIN do
		stepIndex += 1
		for sideIndex, side in ipairs(SIDES) do
			local index = (stepIndex - 1) * #SIDES + sideIndex
			local kind = kindFor(index)
			local extra = edgeExtra(jitterSeed, stepIndex, kind)
			local cx = piece.x + t * tx
			local cz = piece.z + t * tz
			local lateral = side * (halfWidth + extra)
			out[#out + 1] = {
				x = cx + lateral * nx,
				z = cz + lateral * nz,
				centre = { cx, cz },
				halfWidth = halfWidth,
				lateral = lateral,
				offset = lateral,
				along = t,
				kind = kind,
				side = sideName(side),
				segment = "RingRoad:" .. tostring(segmentId),
				path = "RingRoad",
			}
		end
		t += stepFor(jitterSeed, stepIndex)
	end
	return out
end

-- Aggregate every real MapSpec path family. Distinct seeds per segment keep the pattern varied but
-- identical across requires and machines. `road` must be MapSpec.ROAD (its ringWidth sets the ring
-- half-width); failing loudly beats silently reintroducing a baked-in geometry constant.
function ModelMapPathEdgeR8.allPieces(arms: any, ring: any, continuations: any, road: any): { any }
	assert(
		type(road) == "table" and type(road.ringWidth) == "number" and road.ringWidth > 0,
		"MapSpec.ROAD.ringWidth required"
	)
	local ringHalf = road.ringWidth / 2
	local out = {}
	for index, arm in ipairs(arms) do
		for _, piece in ipairs(ModelMapPathEdgeR8.armPieces(arm, 17 + index)) do
			out[#out + 1] = piece
		end
	end
	for index, piece in ipairs(ring) do
		for _, item in ipairs(ModelMapPathEdgeR8.ringPieces(piece, 101 + index, ringHalf, index)) do
			out[#out + 1] = item
		end
	end
	for index, continuation in ipairs(continuations) do
		for _, piece in ipairs(ModelMapPathEdgeR8.armPieces(continuation, 211 + index)) do
			out[#out + 1] = piece
		end
	end
	return out
end

-- Item 177: deterministic plant rows. Every record carries the same centreline/lateral contract as
-- item 142 so the applier and the Studio check can reuse the road geometry without re-deriving it.
local function pushPlant(
	out: { any },
	seed: number,
	stepIndex: number,
	side: number,
	baseX: number,
	baseZ: number,
	normalX: number,
	normalZ: number,
	halfWidth: number,
	along: number,
	segment: string,
	path: string
)
	local extra = ModelMapPathEdgeR8.PLANT_CLEAR + noise(seed, stepIndex, 5) * 0.35
	local lateral = side * (halfWidth + extra)
	local isFlower = stepIndex % 3 == 0
	local colour = ModelMapPathEdgeR8.FLOWER_COLOURS[((stepIndex - 1) % #ModelMapPathEdgeR8.FLOWER_COLOURS) + 1]
	out[#out + 1] = {
		x = baseX + lateral * normalX,
		z = baseZ + lateral * normalZ,
		centre = { baseX, baseZ },
		halfWidth = halfWidth,
		lateral = lateral,
		along = along,
		kind = if isFlower then "flower" else "grass_tuft",
		flowerColour = if isFlower then colour.name else nil,
		flowerRgb = if isFlower then colour.rgb else nil,
		height = ModelMapPathEdgeR8.PLANT_HEIGHT_MIN
			+ noise(seed, stepIndex, if isFlower then 7 else 6)
				* (ModelMapPathEdgeR8.PLANT_HEIGHT_MAX - ModelMapPathEdgeR8.PLANT_HEIGHT_MIN),
		side = sideName(side),
		segment = segment,
		path = path,
	}
end

function ModelMapPathEdgeR8.plantPieces(arms: any, ring: any, continuations: any, road: any): { any }
	assert(
		type(road) == "table" and type(road.ringWidth) == "number" and road.ringWidth > 0,
		"MapSpec.ROAD.ringWidth required"
	)
	local out = {}
	local function sample(
		length: number,
		pointAt: (number) -> (number, number),
		normalX: number,
		normalZ: number,
		seed: number,
		segment: string,
		path: string,
		halfWidth: number
	)
		local t = -length / 2 + END_MARGIN
		local stepIndex = 0
		while t <= length / 2 - END_MARGIN do
			stepIndex += 1
			local baseX, baseZ = pointAt(t)
			for _, side in ipairs(SIDES) do
				pushPlant(out, seed, stepIndex, side, baseX, baseZ, normalX, normalZ, halfWidth, t, segment, path)
			end
			t += ModelMapPathEdgeR8.PLANT_SPACING
		end
	end
	for index, arm in ipairs(arms) do
		local horizontal = arm.sx > arm.sz
		local length = if horizontal then arm.sx else arm.sz
		sample(
			length,
			function(t)
				return if horizontal then arm.x + t else arm.x, if horizontal then arm.z else arm.z + t
			end,
			if horizontal then 0 else 1,
			if horizontal then 1 else 0,
			317 + index,
			arm.name,
			arm.name,
			math.min(arm.sx, arm.sz) / 2
		)
	end
	for index, piece in ipairs(ring) do
		local yaw = math.rad(piece.yaw)
		local tx, tz = math.cos(yaw), -math.sin(yaw)
		sample(piece.length, function(t)
			return piece.x + t * tx, piece.z + t * tz
		end, math.sin(yaw), math.cos(yaw), 419 + index, "RingRoad:" .. tostring(index), "RingRoad", road.ringWidth / 2)
	end
	for index, continuation in ipairs(continuations) do
		local horizontal = continuation.sx > continuation.sz
		local length = if horizontal then continuation.sx else continuation.sz
		sample(
			length,
			function(t)
				return if horizontal then continuation.x + t else continuation.x,
					if horizontal then continuation.z else continuation.z + t
			end,
			if horizontal then 0 else 1,
			if horizontal then 1 else 0,
			523 + index,
			continuation.name,
			continuation.name,
			math.min(continuation.sx, continuation.sz) / 2
		)
	end
	return out
end

return ModelMapPathEdgeR8
