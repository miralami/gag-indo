-- Details: the 'building tips' lane (docs/v2/visual/art/RESEARCH_VISUAL_TIPS.md, "fill shelves, break
-- sightlines, decorate floors"). One Folder named `Details` under the world, so a rebuild is one Destroy.
-- Positions are fixed and every variation comes from an item index (no random), so every server builds
-- the same village. Palette colours only (ART.md section 3). Anchored, unqueryable, no lights, no particles.
-- Hedge sightline breakers carry baked shrub meshes (item 241); the Breaker Part stays as an invisible
-- collider so the contour pass sees no new top-level Model.
--
-- Placement rules (checked by tests/specs/details_spec.luau):
-- * Shop goods read the counter and shelf geometry from MapSpec, so they always land on the board
--   Greybox built, whatever the hub position or yaw. `hubPoint` turns a stall-local point into world XZ.
-- * Road and ring: every ground-level piece keeps its whole footprint at least 9 studs off both road
--   axes, and nothing sits on the connector ring (r 68..76).
-- * Walkways: no breaker (hedge, wall, crate stack) lies in a keep-out strip from the road or plaza to
--   a prompt part. The strips are 3 studs wide and listed in the spec.
-- * Only breakers (hedges, walls, crate stacks) collide. Goods and floor detail do not.

local MapSpec = require(script.Parent.MapSpec)
local Props = require(script.Parent.Props)
local okLoader, Loader = pcall(function()
	return require(script.Parent.LookDevAssetLoader)
end)
local LookDevAssetLoader = if okLoader and Loader then Loader else {}

local Details = {}

local GROUND_Y = MapSpec.GROUND_Y

-- Item 241: verified baked shrub IDs from docs/v2/visual/art/ASSET_MANIFEST.md.
local SHRUB_ASSET_IDS = { 9953859659, 116666781655827, 5661660655 }
Details.SHRUB_ASSET_IDS = SHRUB_ASSET_IDS -- read-only, for the item-241 spec

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

-- Brightness shift in [0, 1) from an index, so repeated foliage balls do not look identical.
local function jitterOf(n: number): number
	return ((n * 17) % 13) / 13
end

-- Shifts a palette colour by 0 to 8 percent: toward kertas (lighter) or indigo (cooler). Palette only.
local function tint(base: Color3, r: number): Color3
	if r < 0.5 then
		return base:Lerp(Props.palette("kertas"), r * 0.16)
	end
	return base:Lerp(Props.palette("indigo"), (r - 0.5) * 0.16)
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

-- A block. With an index, its footprint is scaled; `yaw` overrides the index's random-looking turn.
local function box(folder: Instance, name: string, centre: Vector3, size: Vector3, colourName: string, material: Enum.Material, collide: boolean, n: number?, yaw: number?)
	local s = if n then scaleOf(n) else 1
	local turn = if yaw ~= nil then yaw else (if n then yawOf(n) else 0)
	piece(folder, "Part", {
		Name = name,
		Size = Vector3.new(size.X * s, size.Y, size.Z * s),
		Position = centre,
		Orientation = Vector3.new(0, turn, 0),
		Color = colour(colourName),
		Material = material,
		CanCollide = collide,
	})
end

local function ball(folder: Instance, name: string, centre: Vector3, diameter: number, colourName: string, material: Enum.Material, collide: boolean, jitter: number?)
	local base = colour(colourName)
	piece(folder, "Part", {
		Name = name,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		Position = centre,
		Color = if jitter then tint(base, jitter) else base,
		Material = material,
		CanCollide = collide,
	})
end

-- Item 241: clone a baked shrub under a breaker collider. `baked()` never calls InsertService, so
-- the default look stays offline-safe. A missing bake leaves only the invisible collider, never a
-- procedural Ball on the lawn.
local function addBakedShrub(breaker: Instance, position: Vector3, index: number)
	for offset = 0, #SHRUB_ASSET_IDS - 1 do
		local id = SHRUB_ASSET_IDS[(index + offset) % #SHRUB_ASSET_IDS + 1]
		local ok, source = pcall(function()
			return LookDevAssetLoader.baked(id)
		end)
		if ok and source then
			pcall(function()
				local doomed = {}
				for _, d in source:GetDescendants() do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
						doomed[#doomed + 1] = d
					end
				end
				for _, d in doomed do
					d:Destroy()
				end
				for _, d in source:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
						d.CastShadow = false
					end
				end
				if source:IsA("Model") then
					source:ScaleTo(3 / math.max(1, source:GetBoundingBox().Size.Y))
				elseif source:IsA("BasePart") then
					source.Size = source.Size * (3 / math.max(1, source.Size.Y))
				end
				source.Name = "HedgeShrubBaked"
				source:PivotTo(CFrame.new(position.X, GROUND_Y, position.Z))
				source.Parent = breaker
			end)
			return
		end
	end
end

-- A stall-local point in world space, at height y.
local function at(hub, lx: number, y: number, lz: number): Vector3
	local x, z = MapSpec.hubPoint(hub, lx, lz)
	return Vector3.new(x, y, z)
end

-- Item 208: spilled goods at each of the five lapak in Greybox's stall row (booth -2..2, 11 studs
-- apart). Pure data so the item-208 spec can count recipes without a DataModel. Sacks and baskets are
-- Cylinders, never Balls >=1.5, so item 241's NO_MELONS target stays intact. Six per stall = 30.
local PASAR_SPILL_RECIPES = {}
do
	local function spill(
		booth: number,
		name: string,
		lx: number,
		lz: number,
		size: { number },
		shape: string,
		colourName: string,
		material: string,
		tilt: number
	)
		PASAR_SPILL_RECIPES[#PASAR_SPILL_RECIPES + 1] = {
			booth = booth,
			name = name,
			lx = lx,
			lz = lz,
			size = size,
			shape = shape,
			colour = colourName,
			material = material,
			tilt = tilt,
			vertical = if tilt == 90 then size[1] else size[2],
		}
	end
	for booth = -2, 2 do
		local cx = booth * 11
		spill(booth, "PasarCrate", cx - 3.4, -2.4, { 2.4, 1.2, 1.6 }, "Block", "bambu", "WoodPlanks", 0)
		spill(booth, "PasarBasket", cx + 2.8, -2.2, { 1.4, 0.9, 1.4 }, "Cylinder", "kertas", "Fabric", 0)
		spill(booth, "PasarSack", cx - 0.8, -0.6, { 1.6, 2.2, 1.2 }, "Cylinder", "bambu", "Fabric", 90)
		spill(booth, "PasarCrate", cx + 4.4, 0.8, { 1.8, 1.0, 1.4 }, "Block", "bambu", "WoodPlanks", 0)
		spill(booth, "PasarBasket", cx - 4.6, 1.0, { 1.2, 0.8, 1.2 }, "Cylinder", "padi", "Fabric", 0)
		spill(booth, "PasarSack", cx + 1.4, 1.4, { 1.4, 1.8, 1.1 }, "Cylinder", "kertas", "Fabric", 90)
	end
end
Details.PASAR_SPILL = PASAR_SPILL_RECIPES -- read-only, for the item-208 spec

-- An upright cylinder (axis up, Size.X is the height), turned with its hub and tilted a few degrees.
local function upright(folder: Instance, hub, name: string, lx: number, bottom: number, lz: number, height: number, width: number, colourName: string, material: Enum.Material)
	local n = nextSerial()
	local s = scaleOf(n)
	local h = height * s
	local p = at(hub, lx, bottom + h / 2, lz)
	piece(folder, "Part", {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, width * s, width * s),
		Orientation = Vector3.new(0, hub.yaw, 90 + yawOf(n) * 0.5),
		Position = p,
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

-- Produce crate: a bambu crate with four coloured balls of produce on its top face. The balls follow
-- the crate's turn, so a rotated crate still carries its produce in the right corners.
local function produceCrate(folder: Instance, centre: Vector3, produce: { string }, yaw: number)
	local n = nextSerial()
	box(folder, "ProduceCrate", centre, Vector3.new(2.4, 1.2, 1.6), "bambu", Enum.Material.WoodPlanks, false, n, yaw)
	local d = 0.9 * scaleOf(n)
	local top = centre.Y + 0.6
	local cos, sin = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	for i, offset in { { -0.6, -0.35 }, { 0.6, -0.35 }, { -0.6, 0.35 }, { 0.6, 0.35 } } do
		local dx, dz = offset[1], offset[2]
		ball(folder, "Produce", Vector3.new(
			centre.X + dx * cos + dz * sin,
			top + d / 2 - 0.15,
			centre.Z - dx * sin + dz * cos
		), d, produce[i], Enum.Material.SmoothPlastic, false)
	end
end

-- A shelf board against the hub's back wall. Returns the board's top face, where the stock stands.
local function shelfBoard(folder: Instance, hub, level: number): number
	local width = hub.shelves.width
	local board = at(hub, 0, level, hub.shelves.lz)
	box(folder, "ShelfBoard", board, Vector3.new(width, 0.3, 1.0), "bambu", Enum.Material.WoodPlanks, false, nil, hub.yaw)
	return level + 0.15
end

-- Pasar: goods on the counter (top y = 3.5) and on two shelves against the back wall. The counter and
-- shelf lines come from MapSpec, so nothing can drift off the boards Greybox built.
local function pasarGoods(folder: Instance)
	local hub = MapSpec.hub("pasar")
	local deck = GROUND_Y + hub.anchor.sy
	produceCrate(folder, at(hub, -6, deck + 0.6, 2), { "merah", "kunyit", "merah", "kunyit" }, hub.yaw)
	produceCrate(folder, at(hub, 6, deck + 0.6, 2), { "padi", "daun", "padi", "daun" }, hub.yaw)
	upright(folder, hub, "Pot", -9.8, deck, 3.2, 0.9, 1.2, "tinta", Enum.Material.Metal)
	upright(folder, hub, "Jar", 9.4, deck, 3.4, 1.2, 0.9, "kertas", Enum.Material.SmoothPlastic)
	upright(folder, hub, "Jar", 10.8, deck, 1.2, 1.2, 0.9, "senja", Enum.Material.SmoothPlastic)

	-- Shelf 1 (board top 4.65): eight jars and three bottles.
	local low = shelfBoard(folder, hub, hub.shelves.levels[1])
	local jarX = { -12, -9.5, -7, -4.5, -2, 0.5, 3, 5.5 }
	for i, lx in jarX do
		upright(folder, hub, "Jar", lx, low, hub.shelves.lz, 1.2, 0.9, if i % 2 == 0 then "kertas" else "senja", Enum.Material.SmoothPlastic)
	end
	for _, lx in { -13.2, 7.4, 13.2 } do
		upright(folder, hub, "Bottle", lx, low, hub.shelves.lz, 1.4, 0.5, "malam", Enum.Material.SmoothPlastic)
	end

	-- Shelf 2 (board top 6.65): five snack packs in Fabric.
	local high = shelfBoard(folder, hub, hub.shelves.levels[2])
	local packs = { "kertas", "merah", "kunyit", "padi", "kertas" }
	for i, lx in { -8, -4, 0, 4, 8 } do
		local p = at(hub, lx, high + 0.6, hub.shelves.lz)
		box(folder, "SnackPack", p, Vector3.new(0.9, 1.2, 0.35), packs[i], Enum.Material.Fabric, false, nextSerial(), hub.yaw)
	end
end

-- Item 208: crates, baskets and sacks on the stall apron. The deck is Greybox's plinth top
-- (GROUND_Y + PLINTH_HEIGHT); every recipe carries its own vertical extent so each piece rests on it.
-- No prompts, no asset IDs, no Ball geometry and no collider: these are dressing, not obstacles.
local function pasarSpill(folder: Instance)
	local hub = MapSpec.hub("pasar")
	local deck = GROUND_Y + 0.8
	for _, recipe in ipairs(PASAR_SPILL_RECIPES) do
		local centre = at(hub, recipe.lx, deck + recipe.vertical / 2, recipe.lz)
		local prop = piece(folder, "Part", {
			Name = recipe.name,
			Shape = Enum.PartType[recipe.shape],
			Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3]),
			Orientation = Vector3.new(0, hub.yaw, recipe.tilt),
			Position = centre,
			Color = colour(recipe.colour),
			Material = Enum.Material[recipe.material],
		})
		if prop.SetAttribute then
			prop:SetAttribute("PasarProp", true)
		end
	end
end

-- Warung: a produce crate and a metal pot on the table (top y = 2.7), plus two shelves on the back
-- wall. The table and both shelf levels come from MapSpec.
local function warungGoods(folder: Instance)
	local hub = MapSpec.hub("warung")
	local deck = GROUND_Y + hub.anchor.sy
	produceCrate(folder, at(hub, -0.4, deck + 0.6, 0), { "merah", "kunyit", "daun", "padi" }, hub.yaw)
	upright(folder, hub, "Pot", 2.0, deck, 0.4, 0.9, 1.2, "tinta", Enum.Material.Metal)

	-- Shelf 1 (board top 3.15): five jars and three bottles.
	local low = shelfBoard(folder, hub, hub.shelves.levels[1])
	for _, lx in { -8, -5.5, -3, 3, 5.5 } do
		upright(folder, hub, "Jar", lx, low, hub.shelves.lz, 1.2, 0.9, if lx < 0 then "kertas" else "senja", Enum.Material.SmoothPlastic)
	end
	for _, lx in { -1, 0, 1 } do
		upright(folder, hub, "Bottle", lx, low, hub.shelves.lz, 1.4, 0.5, "daun", Enum.Material.SmoothPlastic)
	end

	-- Shelf 2 (board top 5.05): five snack packs in Fabric.
	local high = shelfBoard(folder, hub, hub.shelves.levels[2])
	local packs = { "merah", "kertas", "padi", "kunyit", "kertas" }
	for i, lx in { -7, -3.5, 0, 3.5, 7 } do
		local p = at(hub, lx, high + 0.6, hub.shelves.lz)
		box(folder, "SnackPack", p, Vector3.new(0.9, 1.2, 0.35), packs[i], Enum.Material.Fabric, false, nextSerial(), hub.yaw)
	end
end

-- A hedge row: baked shrubs stepping from (x, z) by (stepX, stepZ). The Part is an invisible
-- collider (the old green Ball read as a melon); the visible mesh is its baked child.
local function hedgeRow(folder: Instance, x: number, z: number, stepX: number, stepZ: number, count: number)
	for i = 0, count - 1 do
		local n = nextSerial()
		local colourName = if i % 3 == 2 then "padi" else "daun"
		local diameter = 2.4 * scaleOf(n)
		local position = Vector3.new(x + stepX * i, GROUND_Y + 1.3, z + stepZ * i)
		local breaker = piece(folder, "Part", {
			Name = "Hedge",
			Size = Vector3.new(diameter, diameter, diameter),
			Position = position,
			Color = tint(colour(colourName), jitterOf(n)),
			Material = Enum.Material.Grass,
			Transparency = 1,
			CanCollide = true,
		})
		addBakedShrub(breaker, position, n)
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

-- Ground-level sightline breakers. Every one sits in an open pocket between the hubs, at least 21
-- studs clear of both 28-wide road arms: the lane east of the Pasar, the pocket between the Gelap and
-- the alley mouth, and the strips beside the Lapangan and the Pak RT yard.
local function sightlines(folder: Instance)
	-- East lane of the north road, screening the Warung from the road.
	hedgeRow(folder, 36, -84, 0, 6, 5)
	-- West lane, between the Pasar's east wall and the road.
	breakerWall(folder, Vector3.new(24, GROUND_Y + 1.7, -78), Vector3.new(1.2, 3.4, 18))
	breakerWall(folder, Vector3.new(-24, GROUND_Y + 1.7, -78), Vector3.new(1.2, 3.4, 18))
	-- Between the Tengkulak Gelap and the alley mouth.
	hedgeRow(folder, -46, -96, 0, 6, 5)
	-- East and west strips beside the Lapangan, clear of the Pak RT and Pos Polisi footprints.
	hedgeRow(folder, 82, 44, 0, 6, 5)
	hedgeRow(folder, -82, 40, 0, 6, 5)

	crateStack(folder, 26, -50)
	crateStack(folder, 98, -66)
	crateStack(folder, -100, -66)
end

-- Floor details near the hubs, all clear of the road axes.
local function floorDetails(folder: Instance)
	-- Mud patches (flat, tintaLembut). Top about 0.67.
	flatDisc(folder, "MudPatch", 28, -92, 7, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", -26, -80, 6, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Ground, 0)
	flatDisc(folder, "MudPatch", -48, -98, 6.4, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", 102, -60, 6.4, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Mud, 0)
	flatDisc(folder, "MudPatch", 88, 40, 5.6, 0.15, GROUND_Y + 0.02, "tintaLembut", Enum.Material.Ground, 0)

	-- Shallow puddles (malam, SmoothPlastic, Transparency 0.35). Top about 0.65.
	flatDisc(folder, "Puddle", 26, -44, 4.8, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)
	flatDisc(folder, "Puddle", -26, -52, 4.4, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)
	flatDisc(folder, "Puddle", 84, -40, 4.8, 0.1, GROUND_Y + 0.05, "malam", Enum.Material.SmoothPlastic, 0.35)

	-- Stepping stones from the plaza's south-west corner to the Pos Polisi yard gate, west of the
	-- south road (|x| >= 21).
	for _, at2 in { { -30, 30 }, { -40, 34 }, { -50, 38 }, { -60, 42 } } do
		box(folder, "PathStone", Vector3.new(at2[1], GROUND_Y + 0.15, at2[2]), Vector3.new(3.6, 0.3, 3.0), "kertas", Enum.Material.Slate, false, nextSerial())
	end

	-- Scattered sacks: a sideways Cylinder reads as a tied sack without being a >=1.5-stud Ball
	-- on the open lawn (item 241).
	for i, spot in { { 44, -24 }, { -44, -24 }, { 52, -96 }, { 104, 44 } } do
		piece(folder, "Part", {
			Name = "Sack",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.8, 2.6, 2.2),
			Orientation = Vector3.new(0, 0, 90),
			Position = Vector3.new(spot[1], GROUND_Y + 0.9, spot[2]),
			Color = colour(if i % 2 == 0 then "kertas" else "bambu"),
			Material = Enum.Material.Fabric,
		})
	end

	-- Concrete troughs beside the east and west approaches.
	box(folder, "ConcreteTrough", Vector3.new(96, GROUND_Y + 0.8, -78), Vector3.new(3.2, 1.6, 2.0), "indigo", Enum.Material.Concrete, false, nextSerial())
	box(folder, "ConcreteTrough", Vector3.new(-100, GROUND_Y + 0.8, -60), Vector3.new(3.2, 1.6, 2.0), "indigo", Enum.Material.Concrete, false, nextSerial())
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
	pasarSpill(folder)
	warungGoods(folder)
	sightlines(folder)
	floorDetails(folder)

	folder.Parent = world
	return folder
end

return Details
