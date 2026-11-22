--!strict
-- ModelMapStreetFurnR8: pure data for the OFF-BY-DEFAULT "streetfurn_r8" LookDev candidate
-- (WORK_QUEUE section M item 80). Lampu/obor posts every 40 studs along the MapSpec ring road verge,
-- three papan petunjuk (text keys live in Shared.Strings), one gapura at the south bridge approach,
-- one tiang listrik line with a sagging cable, and two bale-bale shelters.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. Every anchor is
-- derived from geometry passed in by the caller (MapSpec.ROAD / PLAZA / road arms / continuations),
-- never from a hand-typed world coordinate. The one function that returns text identifiers returns
-- Strings KEYS, never player-facing text.

local ModelMapStreetFurnR8 = {}

ModelMapStreetFurnR8.id = "streetfurn_r8"
ModelMapStreetFurnR8.familyId = "streetfurn_r8"
ModelMapStreetFurnR8.folderName = "LookDevStreetFurnR8_streetfurn_r8"
ModelMapStreetFurnR8.stageAttribute = "StreetFurnR8"
ModelMapStreetFurnR8.kindAttribute = "StreetFurnKind"
ModelMapStreetFurnR8.vergeAttribute = "VergePost"
ModelMapStreetFurnR8.keyAttribute = "StringsKey"

ModelMapStreetFurnR8.POST_SPACING = 40
ModelMapStreetFurnR8.MIN_POSTS = 18
ModelMapStreetFurnR8.VERGE_OFFSET = 2
ModelMapStreetFurnR8.SIGN_COUNT = 3
ModelMapStreetFurnR8.SIGN_KEYS = { "sign_pasar", "sign_sawah", "sign_balai" }
ModelMapStreetFurnR8.GAPURA_COUNT = 1
ModelMapStreetFurnR8.POLE_SPACING = 48
ModelMapStreetFurnR8.POLE_INSET = 8
ModelMapStreetFurnR8.MIN_POLES = 1
ModelMapStreetFurnR8.CABLE_SEGMENTS = 8
ModelMapStreetFurnR8.CABLE_SAG = 1.6
ModelMapStreetFurnR8.BALE_COUNT = 2
ModelMapStreetFurnR8.CLEAR_HALF = 6

-- Dimensionless offsets from the MapSpec geometry, in studs.
local SIGN_OFFSET = 10
local GAPURA_INSET = 10
local GAPURA_SPAN_EXTRA = 1
local GAPURA_HEIGHT = 16
local POLE_HEIGHT = 18
local BALE_OFFSET = 10
local RING_GAP_START = 222
local RING_GAP_END = 246
local RING_WIDTH = 12

-- Local part recipes. Colours are plain {r,g,b} arrays; sizes/offsets are {x,y,z} arrays. No IDs.
ModelMapStreetFurnR8.RECIPES = {
	lampu = {
		{
			name = "Base",
			shape = "Cylinder",
			size = { 1.8, 0.6, 1.8 },
			offset = { 0, 0.3, 0 },
			colour = { 132, 118, 96 },
			material = "Concrete",
		},
		{
			name = "Shaft",
			shape = "Cylinder",
			size = { 0.6, 10, 0.6 },
			offset = { 0, 5.3, 0 },
			colour = { 92, 74, 54 },
			material = "Wood",
		},
		{
			name = "Head",
			shape = "Block",
			size = { 1.8, 1.2, 1.6 },
			offset = { 0, 10.8, 0.35 },
			colour = { 255, 224, 132 },
			material = "SmoothPlastic",
		},
	},
	obor = {
		{
			name = "Base",
			shape = "Cylinder",
			size = { 1.6, 0.6, 1.6 },
			offset = { 0, 0.3, 0 },
			colour = { 132, 118, 96 },
			material = "Concrete",
		},
		{
			name = "Shaft",
			shape = "Cylinder",
			size = { 0.5, 8, 0.5 },
			offset = { 0, 4.3, 0 },
			colour = { 116, 82, 48 },
			material = "Wood",
		},
		{
			name = "Bowl",
			shape = "Cylinder",
			size = { 1.8, 0.7, 1.8 },
			offset = { 0, 8.5, 0 },
			colour = { 92, 62, 36 },
			material = "Wood",
		},
		{
			name = "Flame",
			shape = "Cylinder",
			size = { 0.7, 1.4, 0.7 },
			offset = { 0, 9.6, 0 },
			colour = { 255, 168, 62 },
			material = "SmoothPlastic",
		},
	},
	sign = {
		{
			name = "PostL",
			shape = "Cylinder",
			size = { 0.5, 9, 0.5 },
			offset = { -2.4, 4.5, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "PostR",
			shape = "Cylinder",
			size = { 0.5, 9, 0.5 },
			offset = { 2.4, 4.5, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
		{
			name = "Board",
			shape = "Block",
			size = { 6, 2.6, 0.5 },
			offset = { 0, 7.6, 0 },
			colour = { 206, 176, 118 },
			material = "WoodPlanks",
		},
	},
	gapura = {
		{
			name = "LegL",
			shape = "Cylinder",
			size = { 1.1, GAPURA_HEIGHT, 1.1 },
			offset = { 0, GAPURA_HEIGHT / 2, 0 },
			colour = { 150, 96, 48 },
			material = "Wood",
		},
		{
			name = "LegR",
			shape = "Cylinder",
			size = { 1.1, GAPURA_HEIGHT, 1.1 },
			offset = { 0, GAPURA_HEIGHT / 2, 0 },
			colour = { 150, 96, 48 },
			material = "Wood",
		},
		{
			name = "Lintel",
			shape = "Block",
			size = { 1, 1.6, 1.2 },
			offset = { 0, GAPURA_HEIGHT - 0.8, 0 },
			colour = { 178, 62, 48 },
			material = "WoodPlanks",
		},
		{
			name = "Roof",
			shape = "Block",
			size = { 1, 0.6, 3 },
			offset = { 0, GAPURA_HEIGHT + 0.4, 0 },
			colour = { 204, 158, 74 },
			material = "WoodPlanks",
		},
	},
	pole = {
		{
			name = "Base",
			shape = "Cylinder",
			size = { 1.6, 0.6, 1.6 },
			offset = { 0, 0.3, 0 },
			colour = { 110, 104, 94 },
			material = "Concrete",
		},
		{
			name = "Shaft",
			shape = "Cylinder",
			size = { 0.8, POLE_HEIGHT, 0.8 },
			offset = { 0, POLE_HEIGHT / 2 + 0.6, 0 },
			colour = { 96, 88, 78 },
			material = "Wood",
		},
		{
			name = "Crossarm",
			shape = "Block",
			size = { 4, 0.5, 0.6 },
			offset = { 0, POLE_HEIGHT + 0.2, 0 },
			colour = { 124, 88, 52 },
			material = "Wood",
		},
	},
	bale = {
		{
			name = "Deck",
			shape = "Block",
			size = { 9, 0.5, 6 },
			offset = { 0, 1.4, 0 },
			colour = { 168, 130, 78 },
			material = "WoodPlanks",
		},
		{
			name = "Bench",
			shape = "Block",
			size = { 8, 0.5, 2 },
			offset = { 0, 3.4, 0 },
			colour = { 176, 138, 84 },
			material = "WoodPlanks",
		},
		{
			name = "Back",
			shape = "Block",
			size = { 8, 2.6, 0.4 },
			offset = { 0, 4.6, -2.6 },
			colour = { 160, 122, 72 },
			material = "Wood",
		},
		{
			name = "Roof",
			shape = "Block",
			size = { 11, 0.6, 8 },
			offset = { 0, 8.6, 0 },
			colour = { 198, 166, 102 },
			material = "WoodPlanks",
		},
	},
}

-- Lampu/obor posts on the OUTSIDE verge of the ring chord (centreline r, ring half-width, plus a
-- small verge gap). The 222..246 gap stays open exactly as MapSpec.ringSegments keeps it open.
function ModelMapStreetFurnR8.ringPosts(
	ringRadius: number,
	spacing: number,
	gapStart: number?,
	gapEnd: number?,
	ringWidth: number?,
	vergeOffset: number?
): { any }
	if type(ringRadius) ~= "number" or ringRadius <= 0 or type(spacing) ~= "number" or spacing <= 0 then
		return {}
	end
	local startGap = gapStart or RING_GAP_START
	local endGap = gapEnd or RING_GAP_END
	local width = ringWidth or RING_WIDTH
	local verge = vergeOffset or ModelMapStreetFurnR8.VERGE_OFFSET
	local radius = ringRadius + width / 2 + verge
	local step = spacing / (2 * math.pi * ringRadius) * 360
	local out = {}
	local index = 0
	local angle = endGap + step / 2
	while angle <= startGap + 360 do
		local rad = math.rad(angle)
		index += 1
		out[index] = {
			x = math.cos(rad) * radius,
			z = math.sin(rad) * radius,
			yaw = -(angle + 90),
			angle = angle,
			kind = if index % 2 == 1 then "lampu" else "obor",
		}
		angle += step
	end
	return out
end

-- Three directional boards at the plaza corners, well clear of the four road arms.
function ModelMapStreetFurnR8.signs(plaza: any): { any }
	if type(plaza) ~= "table" or type(plaza.width) ~= "number" or type(plaza.depth) ~= "number" then
		return {}
	end
	local x = plaza.width / 2 + SIGN_OFFSET
	local z = plaza.depth / 2 + SIGN_OFFSET
	local corners = {
		{ x = x, z = z, yaw = 180 },
		{ x = -x, z = z, yaw = 180 },
		{ x = x, z = -z, yaw = 0 },
	}
	local out = {}
	for index, corner in ipairs(corners) do
		out[index] = {
			x = corner.x,
			z = corner.z,
			yaw = corner.yaw,
			key = ModelMapStreetFurnR8.SIGN_KEYS[index],
		}
	end
	return out
end

-- One gapura over the south bridge-approach road, inset from the ring end of the continuation.
function ModelMapStreetFurnR8.gapura(continuation: any, linkHalfWidth: number): { any }
	if
		type(continuation) ~= "table"
		or type(continuation.x) ~= "number"
		or type(continuation.z) ~= "number"
		or type(continuation.sz) ~= "number"
		or type(linkHalfWidth) ~= "number"
	then
		return {}
	end
	return {
		{
			x = continuation.x,
			z = continuation.z - continuation.sz / 2 + GAPURA_INSET,
			yaw = 0,
			halfSpan = linkHalfWidth + GAPURA_SPAN_EXTRA,
			height = GAPURA_HEIGHT,
		},
	}
end

-- Tiang listrik along the north verge of one road arm. Poles stay outside the arm's half width.
function ModelMapStreetFurnR8.poles(arm: any, vergeOffset: number?, spacing: number?): { any }
	if
		type(arm) ~= "table"
		or type(arm.x) ~= "number"
		or type(arm.z) ~= "number"
		or type(arm.sx) ~= "number"
		or type(arm.sz) ~= "number"
	then
		return {}
	end
	local gap = vergeOffset or ModelMapStreetFurnR8.VERGE_OFFSET
	local step = spacing or ModelMapStreetFurnR8.POLE_SPACING
	local edgeZ = arm.z - (arm.sz / 2 + gap)
	local first = arm.x - arm.sx / 2 + ModelMapStreetFurnR8.POLE_INSET
	local last = arm.x + arm.sx / 2 - ModelMapStreetFurnR8.POLE_INSET
	local out = {}
	local x = first
	while x <= last do
		out[#out + 1] = { x = x, z = edgeZ, height = POLE_HEIGHT }
		x += step
	end
	return out
end

-- Parabolic catenary stand-in: endpoints at the pole tops, maximum sag at the midpoint.
function ModelMapStreetFurnR8.cablePoints(a: any, b: any, segments: number?, sag: number?): { any }
	if
		type(a) ~= "table"
		or type(b) ~= "table"
		or type(a.x) ~= "number"
		or type(a.z) ~= "number"
		or type(b.x) ~= "number"
		or type(b.z) ~= "number"
	then
		return {}
	end
	local count = segments or ModelMapStreetFurnR8.CABLE_SEGMENTS
	local drop = sag or ModelMapStreetFurnR8.CABLE_SAG
	local ay, by = a.y or POLE_HEIGHT, b.y or POLE_HEIGHT
	local out = {}
	for index = 0, count do
		local t = index / count
		out[index + 1] = {
			x = a.x + (b.x - a.x) * t,
			y = ay + (by - ay) * t - drop * 4 * t * (1 - t),
			z = a.z + (b.z - a.z) * t,
		}
	end
	return out
end

-- Two open bamboo bale-bale shelters at plaza corners, clear of the road arms.
function ModelMapStreetFurnR8.bales(plaza: any): { any }
	if type(plaza) ~= "table" or type(plaza.width) ~= "number" or type(plaza.depth) ~= "number" then
		return {}
	end
	local x = plaza.width / 2 + BALE_OFFSET
	local z = -(plaza.depth / 2 + BALE_OFFSET)
	return {
		{ x = x, z = z, yaw = 0 },
		{ x = -x, z = z, yaw = 0 },
	}
end

-- Per-kind counts from the staged geometry, for specs and the harness detail.
function ModelMapStreetFurnR8.counts(groups: any): { [string]: number }
	local out = { lampu = 0, obor = 0, posts = 0, sign = 0, gapura = 0, pole = 0, cable = 0, bale = 0 }
	if type(groups) ~= "table" then
		return out
	end
	for _, post in ipairs(groups.posts or {}) do
		out.posts += 1
		if post.kind == "lampu" then
			out.lampu += 1
		elseif post.kind == "obor" then
			out.obor += 1
		end
	end
	out.sign = #(groups.signs or {})
	out.gapura = #(groups.gapura or {})
	out.pole = #(groups.poles or {})
	out.cable = #(groups.cable or {})
	out.bale = #(groups.bales or {})
	return out
end

return ModelMapStreetFurnR8
