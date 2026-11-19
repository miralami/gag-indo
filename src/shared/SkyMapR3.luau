--!strict
-- SkyMapR3: six real CC0 HDRI cube-face IDs and the pure LookDev "sky_r3" recipe
-- (WORK_QUEUE round 3 item 24). Uploaded via ROBLOX_API_KEY and recorded in
-- docs/v2/visual/art/sky_r3/upload_manifest.json. Source: Poly Haven fish_hoek_beach,
-- CC0, Greg Zaal + Rico Cilliers. No Roblox APIs, no instances, no ID construction here.
-- The client adapter builds the Sky/Atmosphere/ridge only while the candidate is enabled.

local SkyMapR3 = {}

-- Keyed by the exact Roblox Sky property name so the adapter can set them in one loop.
SkyMapR3.ids = {
	SkyboxImageBack = 102550480946849,
	SkyboxImageBottom = 129220381103008,
	SkyboxImageFront = 133281364333444,
	SkyboxImageLeft = 138405045926458,
	SkyboxImageRight = 102997698570968,
	SkyboxImageTop = 119387111356535,
}

-- README proposed Atmosphere values. Colour is a plain {r,g,b} array; the adapter
-- converts it at apply time. Keys are the real property names.
SkyMapR3.atmosphere = {
	Density = 0.22,
	Color = { 214, 223, 230 },
	Decay = 0.65,
	Offset = 0.55,
	Glare = 1.2,
	Haze = 2.4,
}

type Wedge = {
	name: string,
	position: { number },
	size: { number },
	yaw: number,
	shape: string,
	color: string,
}

-- Low silhouette ring around the 60x60 corner footprint (X/Z 470..530, centre 500,500).
-- Radius 27 + half-width 3 stays inside the footprint. Twelve dark wedges, y 10..14,
-- heights 8..20. Pure data: no engine value types or instances, no asset IDs.
local RIDGE: { Wedge } = {
	{
		name = "ridge_01",
		position = { 527, 11, 500 },
		size = { 6, 12, 2 },
		yaw = -90,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_02",
		position = { 523.4, 12, 513.5 },
		size = { 6, 16, 2 },
		yaw = -60,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_03",
		position = { 513.5, 13, 523.4 },
		size = { 6, 20, 2 },
		yaw = -30,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_04", position = { 500, 10, 527 }, size = { 6, 9, 2 }, yaw = 0, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_05",
		position = { 486.5, 11, 523.4 },
		size = { 6, 13, 2 },
		yaw = 30,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_06",
		position = { 476.6, 12, 513.5 },
		size = { 6, 17, 2 },
		yaw = 60,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_07", position = { 473, 13, 500 }, size = { 6, 10, 2 }, yaw = 90, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_08",
		position = { 476.6, 10, 486.5 },
		size = { 6, 14, 2 },
		yaw = 120,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_09",
		position = { 486.5, 11, 476.6 },
		size = { 6, 18, 2 },
		yaw = 150,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_10",
		position = { 500, 12, 473 },
		size = { 6, 11, 2 },
		yaw = 180,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_11",
		position = { 513.5, 13, 476.6 },
		size = { 6, 15, 2 },
		yaw = 210,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_12",
		position = { 523.4, 10, 486.5 },
		size = { 6, 19, 2 },
		yaw = 240,
		shape = "Wedge",
		color = "tinta",
	},
}
SkyMapR3.ridge = RIDGE

function SkyMapR3.faceCount(): number
	return 6
end

return SkyMapR3
