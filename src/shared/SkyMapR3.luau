--!strict
-- SkyMapR3: six real CC0 HDRI cube-face IDs and the pure LookDev "sky_r3" recipe
-- (WORK_QUEUE round 3 item 24, bug fixes item 28). Uploaded via ROBLOX_API_KEY and recorded in
-- docs/v2/visual/art/sky_r3/upload_manifest.json. Source: Poly Haven fish_hoek_beach,
-- CC0, Greg Zaal + Rico Cilliers. No Roblox APIs, no instances, no ID construction here.
-- The client adapter builds the Sky/Atmosphere/ridge only while the candidate is enabled.
--
-- ROUND-3 BUG 2: keys are the REAL Roblox Sky properties (SkyboxFt/Bk/Lf/Rt/Up/Dn), not the
-- invented SkyboxImage* names. Atmosphere.Decay is a plain {r,g,b} array, never a bare number:
-- the applier's resolve() turns it into a Color3 at apply time.

local SkyMapR3 = {}

-- Staging origin on real PLAZA ground (MapSpec.PLAZA spans X -48..48, Z -42..42). Kept as a
-- data seam so the regression spec can prove every coordinate uses the same offset.
SkyMapR3.STAGING_ORIGIN = { x = -14, z = -12 }

-- Keyed by the exact Roblox Sky property name so the adapter can set them in one loop.
-- Bk<-old Back, Dn<-old Bottom, Ft<-old Front, Lf<-old Left, Rt<-old Right, Up<-old Top.
-- The six real asset IDs are unchanged.
SkyMapR3.ids = {
	SkyboxBk = 102550480946849,
	SkyboxDn = 129220381103008,
	SkyboxFt = 133281364333444,
	SkyboxLf = 138405045926458,
	SkyboxRt = 102997698570968,
	SkyboxUp = 119387111356535,
}

-- README values. Colour is a plain {r,g,b} array; the adapter converts it at apply time.
-- Decay is a COLOUR, not a scalar: {120,150,160} becomes Color3.fromRGB(120,150,160).
SkyMapR3.atmosphere = {
	Density = 0.22,
	Color = { 214, 223, 230 },
	Decay = { 120, 150, 160 },
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

-- Low silhouette ring around the staged corner (centre X/Z -14,-12, radius 27 + half-width 3 =>
-- X -44..16, Z -42..18, all inside MapSpec.PLAZA). Twelve dark wedges, y 10..14, heights 8..20.
-- Pure data: no engine value types or instances, no asset IDs.
local RIDGE: { Wedge } = {
	{
		name = "ridge_01",
		position = { 13, 11, -12 },
		size = { 6, 12, 2 },
		yaw = -90,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_02",
		position = { 9.4, 12, 1.5 },
		size = { 6, 16, 2 },
		yaw = -60,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_03",
		position = { -0.5, 13, 11.4 },
		size = { 6, 20, 2 },
		yaw = -30,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_04", position = { -14, 10, 15 }, size = { 6, 9, 2 }, yaw = 0, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_05",
		position = { -27.5, 11, 11.4 },
		size = { 6, 13, 2 },
		yaw = 30,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_06",
		position = { -37.4, 12, 1.5 },
		size = { 6, 17, 2 },
		yaw = 60,
		shape = "Wedge",
		color = "tinta",
	},
	{ name = "ridge_07", position = { -41, 13, -12 }, size = { 6, 10, 2 }, yaw = 90, shape = "Wedge", color = "tinta" },
	{
		name = "ridge_08",
		position = { -37.4, 10, -25.5 },
		size = { 6, 14, 2 },
		yaw = 120,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_09",
		position = { -27.5, 11, -35.4 },
		size = { 6, 18, 2 },
		yaw = 150,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_10",
		position = { -14, 12, -39 },
		size = { 6, 11, 2 },
		yaw = 180,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_11",
		position = { -0.5, 13, -35.4 },
		size = { 6, 15, 2 },
		yaw = 210,
		shape = "Wedge",
		color = "tinta",
	},
	{
		name = "ridge_12",
		position = { 9.4, 10, -25.5 },
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
