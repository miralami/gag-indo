-- Decor: cheap, readable set dressing for the greybox village (ART.md section 5, set dressing).
-- Everything lives in one Folder named `Decor` under the world, so a rebuild is one Destroy.
-- Positions are fixed (no random) so every server builds the same village. Hub-relative points go
-- through MapSpec.hubPoint, so this file never keeps a second copy of the layout.
-- Palette colours only (ART.md section 3). Anchored, no scripts, particles, textures or asset IDs.

local Props = require(script.Parent.Props)
local MapSpec = require(script.Parent.MapSpec)

local Decor = {}

local GROUND_Y = MapSpec.GROUND_Y
local MAX_LIGHTS = 6

-- Hub headroom. Greybox puts the underside of every hub roof eave, awning, trim and spanduk on
-- EAVE_UNDERSIDE, which is MapSpec.HEADROOM studs above GROUND_Y (10.75: the scale reference,
-- Rumah Pak RT, gives a 7.25-stud avatar a 10.5-stud door). The quarter stud of slack keeps float
-- rounding from ever dipping under the minimum.
Decor.HEADROOM = MapSpec.HEADROOM
Decor.EAVE_UNDERSIDE = MapSpec.EAVE_UNDERSIDE

-- Pitch of each hub roof: `rise` from eave to ridge, `halfDepth` the eave reach from the ridge along
-- local Z. Greybox builds the roofs from these, and the lanterns below hang from them. Every hub but
-- the reference is derived in MapSpec: the eave sits ROOF_OVERHANG (3) outside the footprint centre
-- line, so halfDepth = depth / 2 + 3, and the rise is whatever puts the ridge on the height that
-- hub's silhouette needs.
Decor.HUB_ROOFS = MapSpec.hubRoofs()

-- Underside of a hub roof `depth` studs in from its ridge line. It falls straight from the ridge to the eave.
function Decor.undersideAt(roof: { rise: number, halfDepth: number }, depth: number): number
	return Decor.EAVE_UNDERSIDE + roof.rise * (1 - depth / roof.halfDepth)
end

-- A lantern hangs LANTERN_DROP studs under whatever underside it is given (eave, awning, porch), so its
-- rod always has a positive length and the ball is never in a player's head.
local LANTERN_RADIUS = 0.7
local LANTERN_DROP = 1.2

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

-- Bunting: two posts, one string, nine triangle flags, across the frontage of the Pasar. The Pasar's
-- front eave now stands 29 studs south of its centre (halfDepth 29: depth 52 / 2 + 3), so the line
-- hangs just clear of it, on the plaza side, where the spawn sees it. The posts stand 11 studs in
-- from the eave corners so they never graze the stall row.
local BUNTING_POST_HEIGHT = 12
local BUNTING_HALF = 26
local BUNTING_COLOURS = { "merah", "kunyit", "padi", "kertas" }

local function bunting(folder: Instance)
	local pasar = MapSpec.hub("pasar")
	local centre = BUNTING_HALF + 1
	local buntingZ = MapSpec.hubRoofs().pasar.halfDepth + 0.5
	local hub = { x = pasar.x, z = pasar.z, yaw = pasar.yaw }
	local leftX, leftZ = MapSpec.hubPoint(hub, -centre, buntingZ)
	local rightX, _rightZ = MapSpec.hubPoint(hub, centre, buntingZ)
	for _, x in { leftX, rightX } do
		piece(folder, "Part", {
			Name = "BuntingPost",
			Size = Vector3.new(0.4, BUNTING_POST_HEIGHT, 0.4),
			Position = Vector3.new(x, GROUND_Y + BUNTING_POST_HEIGHT / 2, leftZ),
			Color = colour("bambu"),
			Material = Enum.Material.Wood,
		})
	end
	piece(folder, "Part", {
		Name = "BuntingString",
		Size = Vector3.new(BUNTING_HALF * 2, 0.12, 0.12),
		Position = Vector3.new((leftX + rightX) / 2, GROUND_Y + BUNTING_POST_HEIGHT - 1, leftZ),
		Color = colour("tintaLembut"),
		Material = Enum.Material.Fabric,
	})
	for i = 1, 9 do
		piece(folder, "WedgePart", {
			Name = "BuntingFlag",
			Size = Vector3.new(0.15, 1.3, 1.6),
			Position = Vector3.new(leftX + 1.6 + (i - 1) * (BUNTING_HALF * 2 - 3.2) / 8, GROUND_Y + BUNTING_POST_HEIGHT - 1.75, leftZ),
			Orientation = Vector3.new(0, 90, 0),
			Color = colour(BUNTING_COLOURS[(i - 1) % #BUNTING_COLOURS + 1]),
			Material = Enum.Material.Fabric,
		})
	end
end

-- Hanging lantern: a rod down from the roof underside and a warm glowing ball under it. The ball
-- hangs just below whatever underside it is given (an eave, an awning, a porch), so a low roof such as
-- Rumah Pak RT's 11.0-stud porch still leaves a positive rod instead of inverting it.
local function lantern(folder: Instance, x: number, z: number, roofUnderside: number): Instance
	local ballRadius = LANTERN_RADIUS
	local ballY = roofUnderside - ballRadius - LANTERN_DROP
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

-- A yard fence around a hub. The north face (road side, low z) has a 12-stud gap centred on gapCenterX.
local function yardFence(folder: Instance, centerX: number, centerZ: number, halfW: number, halfD: number, gapCenterX: number)
	local x0, x1 = centerX - halfW, centerX + halfW
	local z0, z1 = centerZ - halfD, centerZ + halfD
	local gap0, gap1 = gapCenterX - 6, gapCenterX + 6
	fenceRun(folder, Vector3.new(x0, GROUND_Y, z0), Vector3.new(gap0, GROUND_Y, z0))
	fenceRun(folder, Vector3.new(gap1, GROUND_Y, z0), Vector3.new(x1, GROUND_Y, z0))
	fenceRun(folder, Vector3.new(x1, GROUND_Y, z0), Vector3.new(x1, GROUND_Y, z1))
	fenceRun(folder, Vector3.new(x1, GROUND_Y, z1), Vector3.new(x0, GROUND_Y, z1))
	fenceRun(folder, Vector3.new(x0, GROUND_Y, z1), Vector3.new(x0, GROUND_Y, z0))
end

-- Flower and shrub beds: a flat soil disc with a few coloured balls. A point is off the road cross
-- only when |x| and |z| are both at least 21 (the road arms are 28 wide now), so every bed sits in a
-- quadrant beside the road edges. Radii doubled with the world scale.
--
-- Six beds, not eight: the two north quadrants have no room for a 5.6-radius disc. Pasar reaches
-- z -38 on the west and Warung z -46 on the east, and the road-cross strip in front of them is only
-- about 14 studs deep, so a bed there would either clip a building or sit on the road. The plaza
-- quadrant in front of Pasar stays open for the bunting and the crate stacks instead.
local BED_RING_INNER = 30
local BED_RING_OUTER = 52
local BED_CENTRES = {
	Vector3.new(BED_RING_INNER, 0, BED_RING_OUTER),
	Vector3.new(BED_RING_OUTER, 0, BED_RING_INNER),
	Vector3.new(-BED_RING_INNER, 0, BED_RING_OUTER),
	Vector3.new(-BED_RING_OUTER, 0, BED_RING_INNER),
	Vector3.new(-BED_RING_OUTER, 0, -BED_RING_INNER),
	Vector3.new(BED_RING_OUTER, 0, -BED_RING_INNER),
}
local BED_RADIUS = 5.6
local BED_COLOURS = { "merah", "kunyit", "ungu" }
local BED_OFFSETS = {
	Vector3.new(-1.4, 0, 1.0),
	Vector3.new(1.2, 0, 1.2),
	Vector3.new(0.2, 0, -1.4),
	Vector3.new(-1.2, 0, -0.8),
}

local function flowerBeds(folder: Instance)
	for index, centre in BED_CENTRES do
		-- Cylinder axis is X, so rotating 90 degrees about Z lays the disc flat.
		piece(folder, "Part", {
			Name = "BedSoil",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, BED_RADIUS * 2, BED_RADIUS * 2),
			Orientation = Vector3.new(0, 0, 90),
			Position = Vector3.new(centre.X, GROUND_Y + 0.15, centre.Z),
			Color = colour("tintaLembut"),
			Material = Enum.Material.Ground,
		})
		for i, offset in BED_OFFSETS do
			piece(folder, "Part", {
				Name = "Flower",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.4, 1.4, 1.4),
				Position = Vector3.new(centre.X + offset.X, GROUND_Y + 0.65, centre.Z + offset.Z),
				Color = tint(colour(BED_COLOURS[(index + i) % #BED_COLOURS + 1]), ((index * 5 + i * 3) % 7) / 7),
				Material = Enum.Material.Grass,
			})
		end
	end
end

-- Stepping stones from the plaza's north side toward Rumah Pak RT's gate. Run north of the road
-- cross (|x|, |z| >= 21) and stop short of the house: the reference footprint is x 44..92 z 51..85,
-- so the run ends at z 46 rather than walking through its wall.
local STONES = {
	Vector3.new(40, 0, 30),
	Vector3.new(44, 0, 36),
	Vector3.new(48, 0, 42),
	Vector3.new(52, 0, 46),
}

local function pathStones(folder: Instance)
	for _, at in STONES do
		piece(folder, "Part", {
			Name = "PathStone",
			Size = Vector3.new(3.6, 0.3, 3.0),
			Position = Vector3.new(at.X, GROUND_Y + 0.15, at.Z),
			Color = colour("kertas"),
			Material = Enum.Material.Slate,
		})
	end
end

-- The plaza notice board: two posts, a board and pinned paper. It sits on the plaza's south-west
-- quadrant, off both road arms and off the Lapangan, facing the spawn.
local NOTICE = Vector3.new(-32, 0, 38)

local function noticeBoard(folder: Instance)
	for _, x in { NOTICE.X - 2.5, NOTICE.X + 2.5 } do
		piece(folder, "Part", {
			Name = "NoticePost",
			Size = Vector3.new(0.35, 4.4, 0.35),
			Position = Vector3.new(x, GROUND_Y + 2.2, NOTICE.Z),
			Color = colour("bambu"),
			Material = Enum.Material.Wood,
			CanCollide = true,
		})
	end
	piece(folder, "Part", {
		Name = "NoticeBoard",
		Size = Vector3.new(6.4, 3.0, 0.3),
		Position = Vector3.new(NOTICE.X, GROUND_Y + 4.1, NOTICE.Z),
		Color = colour("bambu"),
		Material = Enum.Material.WoodPlanks,
	})
	for i, offset in { Vector3.new(-1.3, 0.15, 0.2), Vector3.new(1.2, -0.2, 0.2) } do
		piece(folder, "Part", {
			Name = "NoticePaper",
			Size = Vector3.new(1.9, 1.7, 0.06),
			Position = Vector3.new(NOTICE.X + offset.X, GROUND_Y + 4.1 + offset.Y, NOTICE.Z + offset.Z),
			Color = colour(if i % 2 == 0 then "kertas" else "senja"),
			Material = Enum.Material.Fabric,
		})
	end
end

-- Lapangan: a stone well and the village flagpole, both on the open field east of the south road.
-- The field is 72 x 56 at (0, 96), so (34, 92) and (34, 106) keep the well off the road notch at
-- |x| < 21 and off the field's own edges.
local WELL = Vector3.new(34, 0, 92)
local FLAGPOLE = Vector3.new(34, 0, 106)

local function lapanganDetails(folder: Instance)
	piece(folder, "Part", {
		Name = "WellWall",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 5.6, 5.6),
		Orientation = Vector3.new(0, 0, 90),
		Position = Vector3.new(WELL.X, GROUND_Y + 0.6, WELL.Z),
		Color = colour("tintaLembut"),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	})
	piece(folder, "Part", {
		Name = "WellWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 4.2, 4.2),
		Orientation = Vector3.new(0, 0, 90),
		Position = Vector3.new(WELL.X, GROUND_Y + 1.1, WELL.Z),
		Color = colour("malam"),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.25,
	})
	piece(folder, "Part", {
		Name = "FlagPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(24, 0.35, 0.35),
		Orientation = Vector3.new(0, 0, 90),
		Position = Vector3.new(FLAGPOLE.X, GROUND_Y + 12, FLAGPOLE.Z),
		Color = colour("kertas"),
		Material = Enum.Material.Metal,
		CanCollide = true,
	})
	piece(folder, "Part", {
		Name = "Flag",
		Size = Vector3.new(5.2, 3.2, 0.08),
		Position = Vector3.new(FLAGPOLE.X + 2.8, GROUND_Y + 20.8, FLAGPOLE.Z),
		Color = colour("merah"),
		Material = Enum.Material.Fabric,
	})
	piece(folder, "Part", {
		Name = "FlagFinial",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.9, 0.9, 0.9),
		Position = Vector3.new(FLAGPOLE.X, GROUND_Y + 24.4, FLAGPOLE.Z),
		Color = colour("kunyit"),
		Material = Enum.Material.Metal,
	})
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
	local warung = MapSpec.hub("warung")
	local warungX, warungZ = MapSpec.hubPoint(warung, 0, 2)
	addLantern(warungX, warungZ, Decor.undersideAt(Decor.HUB_ROOFS.warung, 2))
	-- Rumah Pak RT is a two-storey house: the lantern hangs under its front porch. Greybox's
	-- buildPakRt dips the awning to y0 + 10.2 (y0 = PLINTH_TOP = GROUND_Y + 0.8), so the hang point is
	-- GROUND_Y + 11.0 -- the same height the approved reference uses, not a literal.
	local pakrt = MapSpec.hub("pakrt")
	local pakrtX, pakrtZ = MapSpec.hubPoint(pakrt, -13, 15)
	addLantern(pakrtX, pakrtZ, GROUND_Y + 11)
	local gelap = MapSpec.hub("gelap")
	local gelapX, gelapZ = MapSpec.hubPoint(gelap, 0, 1)
	addLantern(gelapX, gelapZ, Decor.undersideAt(Decor.HUB_ROOFS.gelap, 1))

	-- Crate stacks in the plaza quadrants: off both 28-wide road arms (|x| and |z| >= 21).
	for _, at in { { 40, 40 }, { -40, 40 }, { 56, -30 } } do
		stack(folder, Vector3.new(at[1], GROUND_Y, at[2]))
	end

	-- The yard fence now marks the Pos Polisi frontage rather than Pak RT's yard (the reference house
	-- is 48 x 34 and fills its own yard). Pos Polisi occupies x -92..-44 z 46..90, so the fence runs
	-- along its south face from its east edge eastward: x -44..-22, z 44.5..47.5. That keeps it off the
	-- building, just clear of the 28-wide north road arm (|x| >= 14 plus a margin) and off the plaza.
	yardFence(folder, -33, 46, 11, 1.5, -33)

	flowerBeds(folder)
	pathStones(folder)
	noticeBoard(folder)
	lapanganDetails(folder)

	folder.Parent = world
	return folder
end

return Decor
