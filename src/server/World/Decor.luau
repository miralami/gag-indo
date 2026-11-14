-- Decor: cheap, readable set dressing for the greybox village (ART.md section 5, set dressing).
-- Everything lives in one Folder named `Decor` under the world, so a rebuild is one Destroy.
-- Positions are fixed (no random) so every server builds the same village.
-- Palette colours only (ART.md section 3). Anchored, no scripts, particles, textures or asset IDs.

local Props = require(script.Parent.Props)

local Decor = {}

local GROUND_Y = 0.5
local MAX_LIGHTS = 6

-- Hub headroom. Greybox puts the underside of every hub roof eave, awning, trim and spanduk on
-- EAVE_UNDERSIDE, which is at least HEADROOM studs above GROUND_Y (a player stands about 6.5 studs tall).
-- The quarter stud of slack keeps float rounding from ever dipping under the minimum.
Decor.HEADROOM = 9.5
Decor.EAVE_UNDERSIDE = GROUND_Y + Decor.HEADROOM + 0.25

-- Pitch of each hub roof: `rise` from eave to ridge, `halfDepth` the eave reach from the ridge along Z.
-- Greybox builds the roofs from these, and the lanterns below hang from them.
Decor.HUB_ROOFS = {
	pasar = { rise = 2, halfDepth = 5.5 },
	gelap = { rise = 2.2, halfDepth = 5.5 },
	pakRt = { rise = 3.5, halfDepth = 8 },
	posPolisi = { rise = 3, halfDepth = 7.5 },
	posRonda = { rise = 2.5, halfDepth = 6 },
	warung = { rise = 3, halfDepth = 7 },
}

-- Underside of a hub roof `depth` studs in from its ridge line. It falls straight from the ridge to the eave.
function Decor.undersideAt(roof: { rise: number, halfDepth: number }, depth: number): number
	return Decor.EAVE_UNDERSIDE + roof.rise * (1 - depth / roof.halfDepth)
end

-- A lantern ball hangs with its bottom on the eave line, so it never sits in a player's head.
local LANTERN_RADIUS = 0.7
local LANTERN_Y = Decor.EAVE_UNDERSIDE + LANTERN_RADIUS

local function colour(name: string): Color3
	return Props.palette(name)
end

-- Flowers get a small deterministic brightness shift so neighbouring beds do not match:
-- 0 to 8 percent toward kertas (lighter) or indigo (cooler). Both ends are palette colours.
local function tint(base: Color3, r: number): Color3
	if r < 0.5 then
		return base:Lerp(Props.palette("kertas"), r * 0.16)
	end
	return base:Lerp(Props.palette("indigo"), (r - 0.5) * 0.16)
end

-- Every Decor part goes through here so the shared rules live in one place.
local function piece(parent: Instance, className: string, props: { [string]: any }): Instance
	local p = Instance.new(className)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Wood
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	local size: Vector3 = (p :: any).Size
	if math.min(size.X, size.Y, size.Z) < 1 then
		(p :: any).CastShadow = false
	end
	p.Parent = parent
	return p
end

-- Bunting: two posts, one string, nine triangle flags, across the frontage of the Pasar.
local BUNTING_Z = -11
local BUNTING_COLOURS = { "merah", "kunyit", "padi", "kertas" }

local function bunting(folder: Instance)
	for _, x in { -10, 10 } do
		piece(folder, "Part", {
			Name = "BuntingPost",
			Size = Vector3.new(0.4, 8, 0.4),
			Position = Vector3.new(x, GROUND_Y + 4, BUNTING_Z),
			Color = colour("bambu"),
			Material = Enum.Material.Wood,
		})
	end
	piece(folder, "Part", {
		Name = "BuntingString",
		Size = Vector3.new(20, 0.12, 0.12),
		Position = Vector3.new(0, 8, BUNTING_Z),
		Color = colour("tintaLembut"),
		Material = Enum.Material.Fabric,
	})
	for i = 1, 9 do
		piece(folder, "WedgePart", {
			Name = "BuntingFlag",
			Size = Vector3.new(0.15, 1.3, 1.6),
			Position = Vector3.new(-8.4 + (i - 1) * 2.1, 7.25, BUNTING_Z),
			Orientation = Vector3.new(0, 90, 0),
			Color = colour(BUNTING_COLOURS[(i - 1) % #BUNTING_COLOURS + 1]),
			Material = Enum.Material.Fabric,
		})
	end
end

-- Hanging lantern: a rod up to the roof underside and a warm glowing ball. Returns the ball.
local function lantern(folder: Instance, x: number, z: number, roofUnderside: number): Instance
	local ballY = LANTERN_Y
	local ballRadius = LANTERN_RADIUS
	local rodBottom = ballY + ballRadius
	piece(folder, "Part", {
		Name = "LanternRod",
		Size = Vector3.new(0.12, roofUnderside - rodBottom, 0.12),
		Position = Vector3.new(x, (roofUnderside + rodBottom) / 2, z),
		Color = colour("tinta"),
		Material = Enum.Material.Metal,
	})
	return piece(folder, "Part", {
		Name = "Lantern",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Position = Vector3.new(x, ballY, z),
		Color = colour("senja"),
		Material = Enum.Material.SmoothPlastic,
	})
end

-- Crate stack with sacks: two crates on top of each other and sacks at their feet and on top.
local function stack(folder: Instance, origin: Vector3)
	for _, y in { GROUND_Y + 1.2, GROUND_Y + 3.6 } do
		piece(folder, "Part", {
			Name = "Crate",
			Size = Vector3.new(2.4, 2.4, 2.4),
			Position = Vector3.new(origin.X, y, origin.Z),
			Color = colour("bambu"),
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		})
	end
	local sacks = {
		{ Vector3.new(2.6, GROUND_Y + 0.55, 0.6), "kertas" },
		{ Vector3.new(-2.6, GROUND_Y + 0.55, 0.8), "bambu" },
		{ Vector3.new(0.2, GROUND_Y + 0.55, 2.7), "kertas" },
		{ Vector3.new(2.5, GROUND_Y + 1.6, 0.6), "bambu" },
	}
	for _, sack in sacks do
		local at: Vector3 = sack[1]
		piece(folder, "Part", {
			Name = "Sack",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.1, 1.3),
			Position = Vector3.new(origin.X + at.X, at.Y, origin.Z + at.Z),
			Color = colour(sack[2]),
			Material = Enum.Material.Fabric,
		})
	end
end

-- One straight bamboo run from a to b: posts every 4 studs and two rails.
local function fenceRun(folder: Instance, a: Vector3, b: Vector3)
	local delta = b - a
	local length = delta.Magnitude
	local count = math.max(1, math.ceil(length / 4))
	for i = 0, count do
		local t = i / count
		piece(folder, "Part", {
			Name = "FencePost",
			Size = Vector3.new(0.5, 2.5, 0.5),
			Position = Vector3.new(a.X + delta.X * t, GROUND_Y + 1.25, a.Z + delta.Z * t),
			Color = colour("bambu"),
			Material = Enum.Material.Wood,
			CanCollide = true,
		})
	end
	local alongX = math.abs(delta.X) > 0
	for _, height in { GROUND_Y + 0.9, GROUND_Y + 1.9 } do
		piece(folder, "Part", {
			Name = "FenceRail",
			Size = if alongX then Vector3.new(length, 0.25, 0.25) else Vector3.new(0.25, 0.25, length),
			Position = Vector3.new((a.X + b.X) / 2, height, (a.Z + b.Z) / 2),
			Color = colour("bambu"),
			Material = Enum.Material.Wood,
		})
	end
end

-- A yard fence around a hub. The north face (road side, low z) has a 6-stud gap centred on gapCenterX.
local function yardFence(folder: Instance, centerX: number, centerZ: number, halfW: number, halfD: number, gapCenterX: number)
	local x0, x1 = centerX - halfW, centerX + halfW
	local z0, z1 = centerZ - halfD, centerZ + halfD
	local gap0, gap1 = gapCenterX - 3, gapCenterX + 3
	fenceRun(folder, Vector3.new(x0, GROUND_Y, z0), Vector3.new(gap0, GROUND_Y, z0))
	fenceRun(folder, Vector3.new(gap1, GROUND_Y, z0), Vector3.new(x1, GROUND_Y, z0))
	fenceRun(folder, Vector3.new(x1, GROUND_Y, z0), Vector3.new(x1, GROUND_Y, z1))
	fenceRun(folder, Vector3.new(x1, GROUND_Y, z1), Vector3.new(x0, GROUND_Y, z1))
	fenceRun(folder, Vector3.new(x0, GROUND_Y, z1), Vector3.new(x0, GROUND_Y, z0))
end

-- Flower and shrub beds: a flat soil disc with a few coloured balls. A point is off the road cross
-- only when |x| and |z| are both at least 9, so every bed sits in a quadrant beside the road edges.
local BED_CENTRES = {
	Vector3.new(20, 0, 11.5),
	Vector3.new(11.5, 0, 20),
	Vector3.new(-20, 0, 11.5),
	Vector3.new(-11.5, 0, 20),
	Vector3.new(-20, 0, -11.5),
	Vector3.new(-11.5, 0, -20),
	Vector3.new(20, 0, -11.5),
	Vector3.new(11.5, 0, -20),
}
local BED_COLOURS = { "merah", "kunyit", "ungu" }
local BED_OFFSETS = {
	Vector3.new(-0.7, 0, 0.5),
	Vector3.new(0.6, 0, 0.6),
	Vector3.new(0.1, 0, -0.7),
	Vector3.new(-0.6, 0, -0.4),
}

local function flowerBeds(folder: Instance)
	for index, centre in BED_CENTRES do
		-- Cylinder axis is X, so rotating 90 degrees about Z lays the disc flat.
		piece(folder, "Part", {
			Name = "BedSoil",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 2.8, 2.8),
			Orientation = Vector3.new(0, 0, 90),
			Position = Vector3.new(centre.X, GROUND_Y + 0.15, centre.Z),
			Color = colour("tintaLembut"),
			Material = Enum.Material.Ground,
		})
		for i, offset in BED_OFFSETS do
			piece(folder, "Part", {
				Name = "Flower",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.7, 0.7, 0.7),
				Position = Vector3.new(centre.X + offset.X, GROUND_Y + 0.65, centre.Z + offset.Z),
				Color = tint(colour(BED_COLOURS[(index + i) % #BED_COLOURS + 1]), ((index * 5 + i * 3) % 7) / 7),
				Material = Enum.Material.Grass,
			})
		end
	end
end

-- Stepping stones leading from the road edge toward Pos Ronda.
local STONES = {
	Vector3.new(-13, 0, -14),
	Vector3.new(-14.5, 0, -16.5),
	Vector3.new(-16, 0, -19),
	Vector3.new(-17.5, 0, -21.5),
}

local function pathStones(folder: Instance)
	for _, at in STONES do
		piece(folder, "Part", {
			Name = "PathStone",
			Size = Vector3.new(1.8, 0.3, 1.5),
			Position = Vector3.new(at.X, GROUND_Y + 0.15, at.Z),
			Color = colour("kertas"),
			Material = Enum.Material.Slate,
		})
	end
end

-- Builds the Decor folder under world. Destroys a previous Decor first, so calling it again
-- leaves exactly one folder.
function Decor.build(world: Instance): Instance
	local old = world:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Decor"

	bunting(folder)

	local lights = 0
	local function addLantern(x: number, z: number, roofUnderside: number)
		local ball = lantern(folder, x, z, roofUnderside)
		if lights < MAX_LIGHTS then
			lights += 1
			local light = Instance.new("PointLight")
			light.Range = 14
			light.Brightness = 1.2
			light.Color = colour("senja")
			light.Shadows = false
			light.Parent = ball
		end
	end
	-- Each lantern hangs two studs in from its roof's ridge line, where the underside is high enough for a ball.
	addLantern(30, -24, Decor.undersideAt(Decor.HUB_ROOFS.warung, 2))
	addLantern(30, 24, Decor.undersideAt(Decor.HUB_ROOFS.pakRt, 2))

	stack(folder, Vector3.new(12, GROUND_Y, 12))
	stack(folder, Vector3.new(-12, GROUND_Y, 12))
	stack(folder, Vector3.new(38, GROUND_Y, -14))

	yardFence(folder, 30, 26, 11, 9, 30)
	yardFence(folder, -30, 26, 10, 9, -30)

	flowerBeds(folder)
	pathStones(folder)

	folder.Parent = world
	return folder
end

return Decor
