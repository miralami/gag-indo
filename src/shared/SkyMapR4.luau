--!strict
-- SkyMapR4: pure data for the three round-4 sky options (WORK_QUEUE item 30).
-- Three CC0 Poly Haven HDRIs, each converted to six 1024x1024 faces named after
-- the REAL Roblox Sky properties (SkyboxBk/Dn/Ft/Lf/Rt/Up). Every ID below came
-- from a completed Open Cloud upload; see docs/v2/visual/art/sky_r4/upload_manifest.json.
-- No Roblox APIs, no engine value types, no instances and no ID construction here:
-- the client appliers read these tables and convert colours only at apply time.

local SkyMapR4 = {}

-- The six exact Roblox Sky face property names, in stable iteration order.
SkyMapR4.faceKeys = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

type SkySet = {
	label: string,
	source: string,
	author: string,
	licence: string,
	ids: { [string]: number },
}

-- a = clear coastal afternoon, b = golden hour, c = light overcast.
-- Poly Haven has no "tropical" HDRI; the closest CC0 coastal/golden/pure-sky
-- options were chosen and the deviation is recorded in sky_r4/MANIFEST.md.
SkyMapR4.sets = {
	a = {
		label = "clear coastal afternoon",
		source = "Poly Haven spiaggia_di_mondello",
		author = "Andreas Mischok",
		licence = "CC0 1.0 Universal",
		ids = {
			SkyboxBk = 97940752286667,
			SkyboxDn = 109773465243137,
			SkyboxFt = 114018733428334,
			SkyboxLf = 86909076207815,
			SkyboxRt = 134258485393561,
			SkyboxUp = 70901206015036,
		},
	},
	b = {
		label = "golden hour",
		source = "Poly Haven umhlanga_sunrise",
		author = "Greg Zaal",
		licence = "CC0 1.0 Universal",
		ids = {
			SkyboxBk = 71419208335886,
			SkyboxDn = 103770664996498,
			SkyboxFt = 100700369015271,
			SkyboxLf = 130530246140479,
			SkyboxRt = 93833019968519,
			SkyboxUp = 74514704981621,
		},
	},
	c = {
		label = "light overcast",
		source = "Poly Haven overcast_soil_puresky",
		author = "Jarod Guest, Sergej Majboroda",
		licence = "CC0 1.0 Universal",
		ids = {
			SkyboxBk = 115782120788932,
			SkyboxDn = 115250718234620,
			SkyboxFt = 130580645341750,
			SkyboxLf = 90062986253718,
			SkyboxRt = 71301261657357,
			SkyboxUp = 124131521861721,
		},
	},
} :: { [string]: SkySet }

-- Same haze grade as SkyMapR3, with the round-3 bug fixed: Decay is a plain
-- {r,g,b} triple (a colour), not a number. Applied values are kept moderate so
-- the sky reads through the haze. The sun-toggle property is deliberately absent:
-- the day cycle must still move the real sun.
SkyMapR4.atmosphere = {
	Density = 0.22,
	Color = { 214, 223, 230 },
	Decay = { 32, 48, 64 },
	Offset = 0.55,
	Glare = 1.2,
	Haze = 2.4,
}

-- OFFSET SEAM. The round-4 staging-area bug fix landed while this lane ran:
-- LookDevCorner.ORIGIN, ModelMapR3.STAGING_ORIGIN and SkyMapR3.STAGING_ORIGIN
-- are all { x = -14, z = -12 }, on real MapSpec.PLAZA ground away from spawn.
-- The ridge uses that centre. If staging moves again, change ONLY this origin
-- (and the README cameras); the 12 relative offsets stay the same.
SkyMapR4.ridgeOrigin = { -14, 0, -12 }

type OffsetWedge = {
	name: string,
	offset: { number },
	size: { number },
	yaw: number,
	shape: string,
	color: string,
}

type PlacedWedge = {
	name: string,
	position: { number },
	size: { number },
	yaw: number,
	shape: string,
	color: string,
}

-- SkyMapR3's 12-wedge ring, re-expressed as offsets from the new centre.
-- Radius 27 plus half-width 3 keeps the ring inside the real terrain near spawn.
local RIDGE: { OffsetWedge } = {
	{ name = "ridge_01", offset = { 27, 11, 0 }, size = { 6, 12, 2 }, yaw = -90, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_02",
		offset = { 23.4, 12, 13.5 },
		size = { 6, 16, 2 },
		yaw = -60,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_03",
		offset = { 13.5, 13, 23.4 },
		size = { 6, 20, 2 },
		yaw = -30,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_04", offset = { 0, 10, 27 }, size = { 6, 9, 2 }, yaw = 0, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_05",
		offset = { -13.5, 11, 23.4 },
		size = { 6, 13, 2 },
		yaw = 30,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_06",
		offset = { -23.4, 12, 13.5 },
		size = { 6, 17, 2 },
		yaw = 60,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_07", offset = { -27, 13, 0 }, size = { 6, 10, 2 }, yaw = 90, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_08",
		offset = { -23.4, 10, -13.5 },
		size = { 6, 14, 2 },
		yaw = 120,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_09",
		offset = { -13.5, 11, -23.4 },
		size = { 6, 18, 2 },
		yaw = 150,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_10", offset = { 0, 12, -27 }, size = { 6, 11, 2 }, yaw = 180, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_11",
		offset = { 13.5, 13, -23.4 },
		size = { 6, 15, 2 },
		yaw = 210,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_12",
		offset = { 23.4, 10, -13.5 },
		size = { 6, 19, 2 },
		yaw = 240,
		shape = "Wedge",
		color = "tinta",
	},
}
SkyMapR4.ridge = RIDGE

-- Resolve the pure offsets into absolute world positions. No engine value types.
function SkyMapR4.ridgeAt(origin: { number }?): { PlacedWedge }
	local o = origin or SkyMapR4.ridgeOrigin
	local placed: { PlacedWedge } = {}
	for _, wedge in ipairs(RIDGE) do
		placed[#placed + 1] = {
			name = wedge.name,
			position = { o[1] + wedge.offset[1], o[2] + wedge.offset[2], o[3] + wedge.offset[3] },
			size = table.clone(wedge.size),
			yaw = wedge.yaw,
			shape = wedge.shape,
			color = wedge.color,
		}
	end
	return placed
end

function SkyMapR4.faceCount(): number
	return #SkyMapR4.faceKeys
end

return SkyMapR4
