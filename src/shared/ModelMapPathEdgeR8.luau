--!strict
-- ModelMapPathEdgeR8: pure data for the OFF-BY-DEFAULT "pathedge_r8" LookDev candidate
-- (WORK_QUEUE section M item 75). Dirt-path edge dressing: alternating grass tufts and pebbles with
-- a few flat puddles, along both edges of every road arm, ring segment and continuation.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. The applier passes
-- the real MapSpec.roadArms() / ringSegments() / roadContinuations() geometry in, so this module never
-- reimplements the road layout. Jitter is an integer hash of (seed, index, salt): deterministic.

local ModelMapPathEdgeR8 = {}

ModelMapPathEdgeR8.id = "pathedge_r8"
ModelMapPathEdgeR8.folderName = "LookDevPathEdgeR8_pathedge_r8"
ModelMapPathEdgeR8.MIN_EDGE_PIECES = 120
ModelMapPathEdgeR8.PUDDLE_TRANSPARENCY = 0.4
ModelMapPathEdgeR8.CENTRAL_CLEAR = 6
ModelMapPathEdgeR8.SPACING_MIN = 3
ModelMapPathEdgeR8.SPACING_MAX = 5

local INSET = 2 -- from the outer road edge, so every piece stays outside the 6-wide centre corridor
local END_MARGIN = 3
local RING_HALF = 6 -- MapSpec.ROAD.ringWidth / 2
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

-- Axis-aligned arms and continuations: step along the long axis, place on both outer edges.
function ModelMapPathEdgeR8.armPieces(arm: any, jitterSeed: number): { any }
	local horizontal = arm.sx > arm.sz
	local length = if horizontal then arm.sx else arm.sz
	local halfWidth = if horizontal then arm.sz / 2 else arm.sx / 2
	local edge = halfWidth - INSET
	local out = {}
	local t = -length / 2 + END_MARGIN
	local stepIndex = 0
	while t <= length / 2 - END_MARGIN do
		stepIndex += 1
		local along = (noise(jitterSeed, stepIndex, 1) - 0.5) * 0.8
		local perpendicular = (noise(jitterSeed, stepIndex, 2) - 0.5) * 0.4
		for sideIndex, side in ipairs(SIDES) do
			local index = (stepIndex - 1) * #SIDES + sideIndex
			local offset = side * (edge + perpendicular)
			out[#out + 1] = {
				x = if horizontal then arm.x + t + along else arm.x + offset,
				z = if horizontal then arm.z + offset else arm.z + t + along,
				offset = offset,
				kind = kindFor(index),
				side = sideName(side),
				path = arm.name,
			}
		end
		t += ModelMapPathEdgeR8.SPACING_MIN + noise(jitterSeed, stepIndex, 3) * (ModelMapPathEdgeR8.SPACING_MAX - ModelMapPathEdgeR8.SPACING_MIN)
	end
	return out
end

-- A rotated ring segment: local +X is the tangent, local +Z the perpendicular edge normal.
function ModelMapPathEdgeR8.ringPieces(piece: any, jitterSeed: number): { any }
	local yaw = math.rad(piece.yaw)
	local tx, tz = math.cos(yaw), -math.sin(yaw)
	local nx, nz = math.sin(yaw), math.cos(yaw)
	local edge = RING_HALF - INSET
	local out = {}
	local t = -piece.length / 2 + END_MARGIN
	local stepIndex = 0
	while t <= piece.length / 2 - END_MARGIN do
		stepIndex += 1
		local along = (noise(jitterSeed, stepIndex, 1) - 0.5) * 0.8
		local perpendicular = (noise(jitterSeed, stepIndex, 2) - 0.5) * 0.4
		for sideIndex, side in ipairs(SIDES) do
			local index = (stepIndex - 1) * #SIDES + sideIndex
			local offset = side * (edge + perpendicular)
			out[#out + 1] = {
				x = piece.x + (t + along) * tx + offset * nx,
				z = piece.z + (t + along) * tz + offset * nz,
				offset = offset,
				kind = kindFor(index),
				side = sideName(side),
				path = "RingRoad",
			}
		end
		t += ModelMapPathEdgeR8.SPACING_MIN + noise(jitterSeed, stepIndex, 3) * (ModelMapPathEdgeR8.SPACING_MAX - ModelMapPathEdgeR8.SPACING_MIN)
	end
	return out
end

-- Aggregate every real MapSpec path family. Distinct seeds per segment keep the pattern varied but
-- identical across requires and machines.
function ModelMapPathEdgeR8.allPieces(arms: any, ring: any, continuations: any): { any }
	local out = {}
	for index, arm in ipairs(arms) do
		for _, piece in ipairs(ModelMapPathEdgeR8.armPieces(arm, 17 + index)) do
			out[#out + 1] = piece
		end
	end
	for index, piece in ipairs(ring) do
		for _, item in ipairs(ModelMapPathEdgeR8.ringPieces(piece, 101 + index)) do
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

return ModelMapPathEdgeR8
