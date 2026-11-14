-- Details: the 'building tips' lane (docs/v2/art/RESEARCH_VISUAL_TIPS.md, "fill shelves, break
-- sightlines, decorate floors"). One Folder named `Details` under the world, so a rebuild is one Destroy.
-- Positions are fixed and every variation comes from an item index (no random), so every server builds
-- the same village. Palette colours only (ART.md section 3). Anchored, unqueryable, no lights, no particles,
-- no asset IDs, no Models (so no Highlights are added by the contour pass).
--
-- Placement rules (checked by tests/specs/details_spec.luau):
-- * Road cross (|x| < 9 or |z| < 9): only raised goods. The Pasar (0,0) stands on the cross, so its
--   counter and shelves carry goods with their bottoms above 2 studs. Nothing else sits on the cross,
--   and every ground-level piece (floor patches, sacks, hedges, walls, crate stacks) is placed with
--   |x| >= 9 and |z| >= 9. No floor patch therefore needs the y < 0.7 exemption.
-- * Walkways: no breaker (hedge, wall, crate stack) lies in a keep-out strip from the road to a prompt
--   part. The strips are 3 studs wide, as listed in the spec.
-- * Only breakers (hedges, walls, crate stacks) collide. Goods and floor detail do not.

local Props = require(script.Parent.Props)

local Details = {}

local GROUND_Y = 0.5

-- Every colour name this file uses must be one of the 13 palette keys in Props (ART.md section 3).
local PALETTE_KEYS = {
	kertas = true, tinta = true, tintaLembut = true, senja = true, padi = true, daun = true,
	genteng = true, merah = true, bambu = true, kunyit = true, indigo = true, malam = true, ungu = true,
}

local function colour(name: string): Color3
	assert(PALETTE_KEYS[name], "Details: unknown palette colour " .. name)
	return Props.palette(name)
end

-- Item index. Reset at the start of every build so the layout is identical on each rebuild.
local serial = 0

local function nextSerial(): number
	serial += 1
	return serial
end

-- Deterministic variation from an index: yaw in degrees (-10..10) and footprint scale (0.9..1.1).
local function yawOf(n: number): number
	return (n * 37) % 21 - 10
end

local function scaleOf(n: number): number
	return 0.9 + ((n * 13) % 7) * (0.2 / 6)
end

-- Every Details part goes through here so the shared rules live in one place.
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

-- A block. With an index, its footprint is scaled and it is yawed; without one it is exact.
local function box(folder: Instance, name: string, centre: Vector3, size: Vector3, colourName: string, material: Enum.Material, collide: boolean, n: number?)
	local s = if n then scaleOf(n) else 1
	local yaw = if n then yawOf(n) else 0
	piece(folder, "Part", {
		Name = name,
		Size = Vector3.new(size.X * s, size.Y, size.Z * s),
		Position = centre,
		Orientation = Vector3.new(0, yaw, 0),
		Color = colour(colourName),
		Material = material,
		CanCollide = collide,
	})
end

local function ball(folder: Instance, name: string, centre: Vector3, diameter: number, colourName: string, material: Enum.Material, collide: boolean)
	piece(folder, "Part", {
		Name = name,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		Position = centre,
		Color = colour(colourName),
		Material = material,
		CanCollide = collide,
	})
end

-- An upright cylinder (axis up, Size.X is the height), tilted a few degrees by its index.
local function upright(folder: Instance, n: number, name: string, x: number, bottom: number, z: number, height: number, width: number, colourName: string, material: Enum.Material)
	local s = scaleOf(n)
	local h = height * s
	piece(folder, "Part", {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, width * s, width * s),
		Orientation = Vector3.new(0, 0, 90 + yawOf(n) * 0.5),
		Position = Vector3.new(x, bottom + h / 2, z),
		Color = colour(colourName),
		Material = material,
	})
end

-- A flat disc lying on the ground (Size.X is the thickness). Used for mud and puddles.
local function flatDisc(folder: Instance, name: string, x: number, z: number, diameter: number, thickness: number, bottom: number, colourName: string, material: Enum.Material, transparency: number)
	piece(folder, "Part", {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, diameter, diameter),
		Orientation = Vector3.new(0, 0, 90),
		Position = Vector3.new(x, bottom + thickness / 2, z),
		Color = colour(colourName),
		Material = material,
		Transparency = transparency,
	})
end

-- Produce crate: a bambu crate with four coloured balls of produce on its top face.
local function produceCrate(folder: Instance, centre: Vector3, produce: { string })
	local n = nextSerial()
	box(folder, "ProduceCrate", centre, Vector3.new(2.4, 1.2, 1.6), "bambu", Enum.Material.WoodPlanks, false, n)
	local d = 0.9 * scaleOf(n)
	local top = centre.Y + 0.6
	local offsets = { { -0.6, -0.35 }, { 0.6, -0.35 }, { -0.6, 0.35 }, { 0.6, 0.35 } }
	for i, offset in offsets do
		ball(folder, "Produce", Vector3.new(centre.X + offset[1], top + d / 2 - 0.15, centre.Z + offset[2]), d, produce[i], Enum.Material.SmoothPlastic, false)
	end
end

-- Pasar: goods on the counter (top y = 3.5) and on two shelves against the back wall (inner face z = -4.0).
-- The Pasar stands on the road cross, so every piece here is raised above 2 studs.
local function pasarGoods(folder: Instance)
	local counterTop = GROUND_Y + 3
	produceCrate(folder, Vector3.new(-4.2, counterTop + 0.6, -0.6), { "merah", "kunyit", "merah", "kunyit" })
	produceCrate(folder, Vector3.new(3.2, counterTop + 0.6, 0.6), { "padi", "daun", "padi", "daun" })
	upright(folder, nextSerial(), "Pot", 0, counterTop, -1.6, 0.9, 1.2, "tinta", Enum.Material.Metal)
	upright(folder, nextSerial(), "Jar", -6.4, counterTop, 1.7, 1.2, 0.9, "kertas", Enum.Material.SmoothPlastic)
	upright(folder, nextSerial(), "Jar", 6.2, counterTop, 1.7, 1.2, 0.9, "senja", Enum.Material.SmoothPlastic)

	-- Shelf 1 (board centre y 4.5, top 4.65): six jars and three bottles.
	box(folder, "ShelfBoard", Vector3.new(0, 4.5, -3.5), Vector3.new(12, 0.3, 1.0), "bambu", Enum.Material.WoodPlanks, false)
	for i, x in { -5.0, -3.4, -1.8, -0.2, 1.4, 3.0 } do
		upright(folder, nextSerial(), "Jar", x, 4.65, -3.5, 1.2, 0.9, if i % 2 == 0 then "kertas" else "senja", Enum.Material.SmoothPlastic)
	end
	for _, x in { -5.8, 4.6, 5.5 } do
		upright(folder, nextSerial(), "Bottle", x, 4.65, -3.5, 1.4, 0.5, "malam", Enum.Material.SmoothPlastic)
	end

	-- Shelf 2 (board centre y 6.5, top 6.65): five snack packs in Fabric.
	box(folder, "ShelfBoard", Vector3.new(0, 6.5, -3.5), Vector3.new(12, 0.3, 1.0), "bambu", Enum.Material.WoodPlanks, false)
	local packs = { "kertas", "merah", "kunyit", "padi", "kertas" }
	for i, x in { -4.5, -2.25, 0, 2.25, 4.5 } do
		box(folder, "SnackPack", Vector3.new(x, 7.25, -3.5), Vector3.new(0.9, 1.2, 0.35), packs[i], Enum.Material.Fabric, false, nextSerial())
	end
end

-- Warung: a produce crate, a metal pot on the table (top y = 2.7), and two shelves on the back wall
-- (inner face z = -31.25, between the side walls at x 23.75 and 36.25).
local function warungGoods(folder: Instance)
	local tableTop = GROUND_Y + 2.2
	produceCrate(folder, Vector3.new(30, tableTop + 0.6, -22.1), { "merah", "kunyit", "daun", "padi" })
	upright(folder, nextSerial(), "Pot", 28.2, tableTop, -22.0, 0.9, 1.2, "tinta", Enum.Material.Metal)

	-- Shelf 1 (board centre y 3.0, top 3.15): five jars and three bottles.
	box(folder, "ShelfBoard", Vector3.new(30, 3.0, -30.75), Vector3.new(11.6, 0.3, 1.0), "bambu", Enum.Material.WoodPlanks, false)
	for _, x in { 25.2, 26.7, 28.2, 33.0, 34.5 } do
		upright(folder, nextSerial(), "Jar", x, 3.15, -30.75, 1.2, 0.9, if x < 30 then "kertas" else "senja", Enum.Material.SmoothPlastic)
	end
	for _, x in { 29.6, 30.6, 31.6 } do
		upright(folder, nextSerial(), "Bottle", x, 3.15, -30.75, 1.4, 0.5, "daun", Enum.Material.SmoothPlastic)
	end

	-- Shelf 2 (board centre y 4.9, top 5.05): five snack packs in Fabric.
	box(folder, "ShelfBoard", Vector3.new(30, 4.9, -30.75), Vector3.new(11.6, 0.3, 1.0), "bambu", Enum.Material.WoodPlanks, false)
	local packs = { "merah", "kertas", "padi", "kunyit", "kertas" }
	for i, x in { 25.4, 27.0, 28.6, 30.2, 31.8 } do
		box(folder, "SnackPack", Vector3.new(x, 5.65, -30.75), Vector3.new(0.9, 1.2, 0.35), packs[i], Enum.Material.Fabric, false, nextSerial())
	end
end

-- A hedge row: balls of daun (every third padi) stepping from (x, z) by (stepX, stepZ). Collides.
local function hedgeRow(folder: Instance, x: number, z: number, stepX: number, stepZ: number, count: number)
	for i = 0, count - 1 do
		local n = nextSerial()
		local colourName = if i % 3 == 2 then "padi" else "daun"
		ball(folder, "Hedge", Vector3.new(x + stepX * i, GROUND_Y + 1.3, z + stepZ * i), 2.4 * scaleOf(n), colourName, Enum.Material.Grass, true)
	end
end

-- A crate stack: two bambu crates on top of each other. Collides.
local function crateStack(folder: Instance, x: number, z: number)
	local n = nextSerial()
	for _, y in { GROUND_Y + 1.2, GROUND_Y + 3.6 } do
		box(folder, "StackCrate", Vector3.new(x, y, z), Vector3.new(2.4, 2.4, 2.4), "bambu", Enum.Material.WoodPlanks, true, n)
	end
end

local function breakerWall(folder: Instance, centre: Vector3, size: Vector3)
	box(folder, "BreakerWall", centre, size, "bambu", Enum.Material.WoodPlanks, true, nextSerial())
end

-- Ground-level sightline breakers, all with |x| >= 9 and |z| >= 9 (off the road cross).
local function sightlines(folder: Instance)
	-- Behind the Warung, east of the Pasar corner, beside Pak RT, Pos Polisi and Pos Ronda.
	hedgeRow(folder, 24, -37, 3, 0, 5)
	hedgeRow(folder, 44, 22, 0, 3, 4)
	hedgeRow(folder, -44, 22, 0, 3, 4)
	hedgeRow(folder, -33, -36, 3, 0, 4)
	hedgeRow(folder, 12, -14, 2.5, 0, 3)

	crateStack(folder, 41, -22)
	crateStack(folder, -14, -10)
	crateStack(folder, 13, 25)

	breakerWall(folder, Vector3.new(18.5, GROUND_Y + 1.1, -27), Vector3.new(0.8, 2.2, 8))
	breakerWall(folder, Vector3.new(-14, GROUND_Y + 1.1, 27.5), Vector3.new(7, 2.2, 0.8))
	breakerWall(folder, Vector3.new(46.5, GROUND_Y + 1.1, 22), Vector3.new(0.8, 2.2, 7))
end

-- Floor details near the hubs, all off the road cross.
local function floorDetails(folder: Instance)
	-- Mud patches (flat, tintaLembut). Top about 0.67.
	flatDisc(folder, "MudPatch", 14, -31, 3.6, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", -17, -30, 3.0, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Ground, 0)
	flatDisc(folder, "MudPatch", 38, 30, 3.2, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", -38, 30, 2.8, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", 11, 33, 2.6, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Ground, 0)

	-- Shallow puddles (malam, SmoothPlastic, Transparency 0.35). Top about 0.65.
	flatDisc(folder, "Puddle", 42, -36, 2.4, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)
	flatDisc(folder, "Puddle", -24, -10, 2.2, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)
	flatDisc(folder, "Puddle", 22, 28, 2.4, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)
	flatDisc(folder, "Puddle", -44, -30, 2.0, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)

	-- Stepping stones leading from the road edge toward Pak RT.
	for _, at in { { 12, 30 }, { 13.5, 32 }, { 15, 34 }, { 16.5, 36 } } do
		box(folder, "PathStone", Vector3.new(at[1], GROUND_Y + 0.15, at[2]), Vector3.new(1.8, 0.3, 1.5), "kertas", Enum.Material.Slate, false, nextSerial())
	end

	-- Scattered sacks (Fabric ball, as Decor's sacks).
	for i, at in { { 24, -13 }, { -24, -14 }, { 34, -12 }, { -44, 12 } } do
		piece(folder, "Part", {
			Name = "Sack",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.1, 1.3),
			Position = Vector3.new(at[1], GROUND_Y + 0.55, at[2]),
			Color = colour(if i % 2 == 0 then "kertas" else "bambu"),
			Material = Enum.Material.Fabric,
		})
	end

	-- Concrete troughs by the corners of the village.
	box(folder, "ConcreteTrough", Vector3.new(-16, GROUND_Y + 0.6, 16), Vector3.new(2.0, 1.2, 1.2), "indigo", Enum.Material.Concrete, false, nextSerial())
	box(folder, "ConcreteTrough", Vector3.new(16, GROUND_Y + 0.6, -16), Vector3.new(2.0, 1.2, 1.2), "indigo", Enum.Material.Concrete, false, nextSerial())
end

-- Builds the Details folder under world. Destroys a previous Details first, so calling it again
-- leaves exactly one folder with the same parts.
function Details.build(world: Instance): Instance
	local old = world:FindFirstChild("Details")
	if old then
		old:Destroy()
	end
	serial = 0

	local folder = Instance.new("Folder")
	folder.Name = "Details"

	pasarGoods(folder)
	warungGoods(folder)
	sightlines(folder)
	floorDetails(folder)

	folder.Parent = world
	return folder
end

return Details
