--!nocheck
-- Map layout v1: arranges the Edit-time world to match the illustrated map brief
-- (docs/v2/visual/art/MAP_LAYOUT_V1.md). Load it in Studio as a ModuleScript (Edit DataModel),
-- then call `require(module).steps.<name>()` in the order given by `.order`. Steps can be rerun.
--
-- Studs, X = east, -Z = north, ground Y = 0.5 (MapSpec). The drawing, not its coordinate labels,
-- is the source: its hub labels and plot labels use opposite Z signs.
--
-- Nothing is destroyed. Pieces that the map replaces (old road strips, the Jalan tile kit) are moved
-- into ServerStorage.ParkedLayout so the logic transfer can still read them.

local ServerStorage = game:GetService("ServerStorage")
local GROUND = 0.5

-- Layout ---------------------------------------------------------------------------------------

local L = {}

-- Octagonal ring road: half extents A (x) and B (z), chamfer c on every corner.
L.RING = { A = 228, B = 172, c = 80, width = 14 }
L.PLAZA = { x = 0, z = 0, half = 60 }

-- Hub 3D models. `scale` is uniform and was checked against the 5-stud avatar: Pasar stall counters
-- top out at 3.6 and the Pak RT table at 2.6 (waist height). `yaw` turns the model (0 = as
-- imported). A model whose door is not on local +Z says so with `front` (degrees added to yaw to get
-- the door direction: 0 = south, 90 = east, 180 = north); the pasar diorama's open side is local -Z.
-- `surface` names a part whose top must land on the ground (the model's own base slab); else the
-- bounding box bottom lands on it.
L.HUBS = {
	{ key = "plaza", model = "alun_alun_area", x = 0, z = 0, yaw = 0, scale = 1.2, surface = "AA_Cobble" },
	{ key = "pakrt", model = "rumah_pakrt", x = 80, z = -112, yaw = 0, scale = 2.0 },
	{
		key = "polisi",
		model = "R5_gudang",
		from = "LookDevSpawnDressingR5_spawn_r5",
		x = -80,
		z = -112,
		yaw = 0,
		scale = 2.6,
		standIn = true,
	},
	{ key = "ronda", model = "pos_ronda", x = -165, z = -45, yaw = 90, scale = 1.4 },
	{
		key = "pasar",
		model = "pasar_diorama",
		x = -82,
		z = 102,
		yaw = 0,
		front = 180,
		scale = 2.0,
		surface = "Ground_Soil",
	},
	{ key = "gelap", model = "TengkulakGelap_v1", x = -178, z = 62, yaw = 90, scale = 1.5, surface = "G_Slab" },
	{
		key = "warung",
		model = "R5_warung",
		from = "LookDevSpawnDressingR5_spawn_r5",
		x = 104,
		z = 84,
		yaw = 180,
		scale = 2.8,
		standIn = true,
	},
	{ key = "balai", model = "rumah_desa", x = 0, z = -246, yaw = 0, scale = 1.8, standIn = true },
	{ key = "kebun", model = "Lahan_v3", x = 345, z = -250, yaw = 0, scale = 1.0 },
}

-- Old hub centres (MapSpec.HUBS at the time of writing) and their door yaw. Dressing built around
-- them moves rigidly with the hub: rect = old footprint grown by GROW on each side.
L.GROW = 18
L.OLD_HUBS = {
	pasar = { x = -71, z = -86, w = 100, d = 84, yaw = 0 },
	gelap = { x = -103, z = -164, w = 36, d = 38, yaw = 0 },
	warung = { x = 68, z = -68, w = 52, d = 44, yaw = 0 },
	ronda = { x = -108, z = 0, w = 40, d = 44, yaw = 90 },
	polisi = { x = -68, z = 68, w = 48, d = 44, yaw = 180 },
	pakrt = { x = 68, z = 68, w = 48, d = 34, yaw = 180 },
}
-- New hub door yaw (the dressing turns by new - old).
L.NEW_HUB_YAW = { pasar = 180, gelap = 90, warung = 180, ronda = 90, polisi = 0, pakrt = 0 }

-- Open spaces that move as a block: { folder name patterns, old rect, new centre }.
L.BLOCKS = {
	{
		key = "lapangan",
		folders = { "LookDevLapanganR8", "LookDevLayanganR8" },
		old = { x = 0, z = 96, w = 90, d = 80 },
		x = 160,
		z = -48,
	},
	{ key = "musala", folders = { "LookDevMusalaR8" }, old = { x = 60, z = 104, w = 30, d = 30 }, x = 46, z = 140 },
	{
		key = "showcase",
		folders = { "LookDevCropsShowcaseR8" },
		old = { x = 0, z = 96, w = 60, d = 50 },
		x = 62,
		z = 232,
	},
}

-- Plots, numbered clockwise from the north as in the drawing (P4 is not drawn; it takes the
-- east-south-east slot between P3 and the Proyek Mangkrak reserve).
L.PLOTS = {
	{ 150, -235 },
	{ 300, -130 },
	{ 320, 5 },
	{ 300, 105 },
	{ 160, 228 },
	{ -160, 228 },
	{ -320, 120 },
	{ -325, 0 },
	{ -300, -130 },
	{ -150, -235 },
}

-- Reserved future slots (nothing built, kept clear of trees).
L.FUTURE = {
	{ key = "proyek", x = 312, z = 186, w = 68, d = 52 },
	{ key = "empang", x = 300, z = 246, w = 64, d = 40 },
}

-- Road pieces: straight strips { x0, z0, x1, z1, width }. Ring and plot spokes are generated.
L.ROAD_COLOR = Color3.fromRGB(138, 106, 70)
L.SHOULDER_COLOR = Color3.fromRGB(112, 104, 62)
L.STRAIGHTS = {
	{ 0, -L.PLAZA.half, 0, -172, 20, "SpineNorth" },
	{ 0, -172, 0, -222, 14, "RoadToBalai" },
	{ 0, L.PLAZA.half, 0, 172, 20, "SpineSouth" },
	{ 0, 172, 0, 278, 14, "RoadToBridge" },
	{ L.PLAZA.half, 0, 228, 0, 18, "RoadEast" },
	{ -L.PLAZA.half, 0, -228, 0, 18, "RoadWest" },
	-- hub doors to the axes
	{ 80, -86, 80, -9, 10, "LanePakRT" },
	{ -80, -95, -80, -9, 10, "LanePolisi" },
	{ -82, 60, -82, 9, 10, "LanePasar" },
	{ 104, 68, 104, 9, 10, "LaneWarung" },
	{ -147, -45, -110, -45, 8, "LaneRonda" },
	{ -110, -45, -110, -9, 8, "LaneRonda2" },
}

-- Helpers ----------------------------------------------------------------------------------------

local function parked()
	local f = ServerStorage:FindFirstChild("ParkedLayout")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ParkedLayout"
		f.Parent = ServerStorage
	end
	return f
end

local function mapRoot()
	local root = workspace:FindFirstChild("JuraganMap")
	if not root then
		root = Instance.new("Folder")
		root.Name = "JuraganMap"
		root.Parent = workspace
	end
	return root
end

local function sub(name)
	local root = mapRoot()
	local f = root:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
	end
	return f
end

local function find(name)
	return workspace:FindFirstChild(name, true) or ServerStorage:FindFirstChild(name, true)
end

-- A world folder by name, before or after unify() gathered it under JuraganMap.
local function findFolder(name)
	local f = workspace:FindFirstChild(name)
	if f then
		return f
	end
	local root = workspace:FindFirstChild("JuraganMap")
	return root and root:FindFirstChild(name, true)
end

local function centreOf(inst)
	if inst:IsA("BasePart") then
		return inst.Position, inst.Size
	end
	if inst:IsA("Model") then
		local ok, cf, size = pcall(function()
			return inst:GetBoundingBox()
		end)
		if ok then
			return cf.Position, size
		end
	end
	local min, max
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.Position
			min = min and Vector3.new(math.min(min.X, p.X), math.min(min.Y, p.Y), math.min(min.Z, p.Z)) or p
			max = max and Vector3.new(math.max(max.X, p.X), math.max(max.Y, p.Y), math.max(max.Z, p.Z)) or p
		end
	end
	if min then
		return (min + max) / 2, max - min
	end
	return nil
end

-- Rigid move of any instance (Model, BasePart, Folder of parts) by a CFrame transform.
local function transform(inst, T)
	if inst:IsA("Model") then
		inst:PivotTo(T * inst:GetPivot())
	elseif inst:IsA("BasePart") then
		inst.CFrame = T * inst.CFrame
	else
		for _, c in inst:GetChildren() do
			transform(c, T)
		end
	end
end

local function hubTransform(oldX, oldZ, oldYaw, newX, newZ, newYaw)
	return CFrame.new(newX, 0, newZ) * CFrame.Angles(0, math.rad(newYaw - oldYaw), 0) * CFrame.new(-oldX, 0, -oldZ)
end

local function inRect(p, r, grow)
	grow = grow or 0
	return math.abs(p.X - r.x) <= r.w / 2 + grow and math.abs(p.Z - r.z) <= r.d / 2 + grow
end

local function hasHumanoid(inst)
	return inst:FindFirstChildWhichIsA("Humanoid", true) ~= nil
end

-- Octagon: t at which a ray from the origin along (dx, dz) meets the ring centreline.
local function ringT(dx, dz)
	local R = L.RING
	local C = R.A + R.B - R.c
	local ax, az = math.abs(dx), math.abs(dz)
	local t = math.huge
	if ax > 1e-6 then
		t = math.min(t, R.A / ax)
	end
	if az > 1e-6 then
		t = math.min(t, R.B / az)
	end
	t = math.min(t, C / (ax + az))
	return t
end

local function ringVertices()
	local R = L.RING
	local A, B, c = R.A, R.B, R.c
	return {
		Vector3.new(A - c, 0, -B),
		Vector3.new(A, 0, -(B - c)),
		Vector3.new(A, 0, B - c),
		Vector3.new(A - c, 0, B),
		Vector3.new(-(A - c), 0, B),
		Vector3.new(-A, 0, B - c),
		Vector3.new(-A, 0, -(B - c)),
		Vector3.new(-(A - c), 0, -B),
	}
end

-- Every road segment as { a, b, width, name } in XZ (used for laying and for clearance).
local function roadSegments()
	local segs = {}
	for _, s in L.STRAIGHTS do
		table.insert(segs, { a = Vector3.new(s[1], 0, s[2]), b = Vector3.new(s[3], 0, s[4]), w = s[5], name = s[6] })
	end
	local v = ringVertices()
	for i = 1, #v do
		table.insert(segs, { a = v[i], b = v[i % #v + 1], w = L.RING.width, name = "Ring" .. i })
	end
	-- Spokes from the ring to every plot and to the kebun.
	local targets = {}
	for i, p in L.PLOTS do
		table.insert(targets, { x = p[1], z = p[2], half = 42, name = "SpokeP" .. i })
	end
	table.insert(targets, { x = 345, z = -250, half = 46, name = "SpokeKebun" })
	table.insert(targets, { x = 312, z = 186, half = 28, name = "SpokeProyek" })
	for _, t in targets do
		local len = math.sqrt(t.x * t.x + t.z * t.z)
		local dx, dz = t.x / len, t.z / len
		local tr = ringT(dx, dz)
		local stop = len - t.half
		if stop > tr + 2 then
			table.insert(segs, {
				a = Vector3.new(dx * tr, 0, dz * tr),
				b = Vector3.new(dx * stop, 0, dz * stop),
				w = 10,
				name = t.name,
			})
		end
	end
	return segs
end

local function distToSeg(p, a, b)
	local ab = b - a
	local ap = Vector3.new(p.X, 0, p.Z) - a
	local t = math.clamp(ap:Dot(ab) / ab:Dot(ab), 0, 1)
	return (a + ab * t - Vector3.new(p.X, 0, p.Z)).Magnitude
end

-- Steps --------------------------------------------------------------------------------------------

local steps = {}

-- 1. Terrain: grass slab to the ground plane, river, sawah terraces (from MapSpec data).
function steps.terrain()
	local MapSpec = require(game:GetService("ServerScriptService").Server.World.MapSpec)
	local T = workspace.Terrain
	local function fill(b, mat)
		T:FillBlock(
			CFrame.new(b.centre[1], b.centre[2], b.centre[3]),
			Vector3.new(b.size[1], b.size[2], b.size[3]),
			mat or Enum.Material[b.material]
		)
	end
	-- slab ±480 so it meets the hills, laid in 40-stud tiles.
	local cy, sy = MapSpec.volumeForTop(MapSpec.TERRAIN_BASE_Y, GROUND)
	local n = 0
	for x = -480, 440, 40 do
		for z = -480, 440, 40 do
			T:FillBlock(CFrame.new(x + 20, cy, z + 20), Vector3.new(40, sy, 40), Enum.Material.Grass)
			n += 1
			if n % 40 == 0 then
				task.wait()
			end
		end
	end
	-- the old flat top at -2 sits under the slab already; nothing else to clear.
	local river = MapSpec.river()
	for _, b in river.carves do
		fill(b, Enum.Material.Air)
	end
	task.wait()
	for _, b in river.beds do
		fill(b)
	end
	for _, b in river.banks do
		fill(b)
	end
	task.wait()
	for _, b in river.water do
		fill(b)
	end
	task.wait()
	for _, terrace in MapSpec.TERRACES do
		local z = (terrace.z0 + terrace.z1) / 2
		for _, side in MapSpec.TERRACE_SIDES do
			local tcy, tsy = MapSpec.volumeForTop(MapSpec.TERRAIN_BASE_Y, terrace.top)
			local blocks = MapSpec.splitWide({
				{
					centre = { (side.x0 + side.x1) / 2, tcy, z },
					size = { side.x1 - side.x0, tsy, terrace.z1 - terrace.z0 },
					material = "Ground",
				},
			})
			for _, b in blocks do
				fill(b, Enum.Material.Grass)
			end
		end
		task.wait()
	end
	return "terrain ok"
end

-- 2. Park what the map replaces: old road strips and the Jalan tile kit.
function steps.park()
	local p = parked()
	local moved = {}
	for _, name in
		{
			"LookDevSpawnGroundR5",
			"LookDevSpawnGroundR6",
			"LookDevPathEdgeR8_pathedge_r8",
			"Jalan_v3",
			"LookDevRoadFenceR10_road_fence_r10",
		}
	do
		for _, inst in workspace:GetChildren() do
			if inst.Name == name then
				inst.Parent = p
				table.insert(moved, name)
			end
		end
	end
	return "parked: " .. table.concat(moved, ", ")
end

-- 3. Place the hub 3D models: uniform scale about the base centre, yaw, ground.
function steps.hubs()
	local out = {}
	local hubs = sub("Hubs")
	for _, h in L.HUBS do
		local m
		for _, c in hubs:GetChildren() do
			if c:GetAttribute("MapHub") == h.key then
				m = c
			end
		end
		m = m
			or (h.from and workspace:FindFirstChild(h.from) and workspace[h.from]:FindFirstChild(h.model))
			or find(h.model)
		if not m then
			table.insert(out, h.key .. ": MISSING " .. h.model)
			continue
		end
		local have = m:GetAttribute("LayoutScaled")
		if have ~= h.scale then
			-- pivot at the bounding-box base centre, then scale relative to what was applied before
			local cf, size = m:GetBoundingBox()
			m.WorldPivot = CFrame.new(cf.X, cf.Y - size.Y / 2, cf.Z) * m:GetPivot().Rotation
			m:ScaleTo(m:GetScale() * h.scale / (have or 1))
			m:SetAttribute("LayoutScaled", h.scale)
		end
		m:PivotTo(CFrame.new(h.x, GROUND, h.z) * CFrame.Angles(0, math.rad(h.yaw), 0))
		-- land the named surface (or the base) on the ground
		local dy = 0
		local surf = h.surface and m:FindFirstChild(h.surface, true)
		if surf then
			dy = GROUND + 0.05 - (surf.Position.Y + surf.Size.Y / 2)
		else
			local cf, size = m:GetBoundingBox()
			dy = GROUND - (cf.Y - size.Y / 2)
		end
		m:PivotTo(m:GetPivot() + Vector3.new(0, dy, 0))
		if h.standIn and not m.Name:find("_as_") then
			m.Name = h.model .. "_as_" .. h.key
		end
		m:SetAttribute("MapHub", h.key)
		m.Parent = hubs
		local cf, size = m:GetBoundingBox()
		table.insert(
			out,
			string.format(
				"%s: %s at (%.0f,%.0f) size %.0fx%.0fx%.0f",
				h.key,
				m.Name,
				cf.X,
				cf.Z,
				size.X,
				size.Y,
				size.Z
			)
		)
	end
	return table.concat(out, "\n")
end

-- 4. Move hub dressing (everything built around the old hub sites) rigidly with its hub, and the
-- open-space blocks (lapangan, musala, crop showcase) to their new spots.
local SKIP_FOLDERS = {
	JuraganMap = true,
	Terrain = true,
	Camera = true,
	BackgroundForest = true,
	LookDevSawahR8_sawah_r8 = true,
	LookDevRiverR8_river_r8 = true,
	LookDevHorizonFillR10_horizon_fill_r10 = true,
	LookDevHillDressingR10_hill_dressing_r10 = true,
	LookDevPlotsR8_plots_r8 = true,
	LookDevFurrowsR10_furrows_r10 = true,
	LookDevCropStagesR10_crop_stages_r10 = true,
	LookDevCropStagesGoldenQ247_crop_stages_golden_247 = true,
	LookDevDitchWaterR10_ditch_water_r10 = true,
	LookDevBambooBridgeR10_bamboo_bridge_r10 = true,
	LookDevPerahuR8_perahu_r8 = true,
	LookDevKincirR8_kincir_r8 = true,
	LookDevIrrigationR8_irrigation_r8 = true,
	LookDevMeadowR10_meadow_r10 = true,
	LookDevStreetFurnR8_streetfurn_r8 = true,
	LookDevSignpostsR10_signposts_r10 = true,
	LookDevRocksR9_rocks_r9 = true,
	LookDevBlocksR9_blocks_r9 = true,
}

local function isNpcFolder(name)
	return name:find("Npcs") ~= nil or name:find("AmbientWalkers") ~= nil
end

local function matchesAny(name, pats)
	for _, p in pats do
		if name:find(p, 1, true) then
			return true
		end
	end
	return false
end

function steps.dressing()
	local counts = {}
	local done = {}
	-- blocks first (they are whole folders)
	for _, b in L.BLOCKS do
		local T = CFrame.new(b.x - b.old.x, 0, b.z - b.old.z)
		for _, f in workspace:GetChildren() do
			if f:IsA("Folder") and matchesAny(f.Name, b.folders) and not done[f] then
				transform(f, T)
				done[f] = true
				counts[b.key] = (counts[b.key] or 0) + #f:GetChildren()
			end
		end
	end
	-- hub dressing: per top-level child of every other LookDev folder
	for _, f in workspace:GetChildren() do
		if
			not f:IsA("Folder")
			or SKIP_FOLDERS[f.Name]
			or done[f]
			or isNpcFolder(f.Name)
			or not f.Name:find("^LookDev")
		then
			continue
		end
		local items = f:GetChildren()
		-- one level deeper for folders that group per hub (HubProps: pasar/gelap/...)
		local expanded = {}
		for _, c in items do
			if c:IsA("Folder") then
				for _, cc in c:GetChildren() do
					table.insert(expanded, cc)
				end
			else
				table.insert(expanded, c)
			end
		end
		for _, item in expanded do
			if hasHumanoid(item) and not f.Name:find("Seated") then
				continue
			end
			local p = centreOf(item)
			if not p then
				continue
			end
			-- Zones overlap (the old Pasar zone reaches the Ronda and Gelap ones), so of every zone that holds
			-- the item, the nearest old hub centre wins. A first-match over pairs() sent the ronda tower and
			-- the gelap lumbung dressing to the Pasar in the first Studio run.
			local key, best = nil, math.huge
			for k, o in L.OLD_HUBS do
				if inRect(p, o, L.GROW) then
					local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(o.x, 0, o.z)).Magnitude
					if d < best then
						key, best = k, d
					end
				end
			end
			if key then
				local o = L.OLD_HUBS[key]
				local h
				for _, hh in L.HUBS do
					if hh.key == key then
						h = hh
					end
				end
				transform(item, hubTransform(o.x, o.z, o.yaw, h.x, h.z, L.NEW_HUB_YAW[key]))
				counts[key] = (counts[key] or 0) + 1
			end
		end
		task.wait()
	end
	local out = {}
	for k, v in counts do
		table.insert(out, k .. "=" .. v)
	end
	return "dressing moved: " .. table.concat(out, ", ")
end

-- 5. Plots: each plot folder and the furrows, crop stages and ditches near it move to the new slot.
function steps.plots()
	local folder = workspace:FindFirstChild("LookDevPlotsR8_plots_r8")
	local out = {}
	local olds = {}
	for i = 1, 10 do
		local pf = folder and folder:FindFirstChild("Plot_" .. i .. "_plots_r8")
		if pf then
			local c, size = centreOf(pf)
			olds[i] = c
			table.insert(out, string.format("P%d old (%.0f,%.0f) %.0fx%.0f", i, c.X, c.Z, size.X, size.Z))
		end
	end
	local attached = {
		"LookDevFurrowsR10_furrows_r10",
		"LookDevCropStagesR10_crop_stages_r10",
		"LookDevCropStagesGoldenQ247_crop_stages_golden_247",
		"LookDevDitchWaterR10_ditch_water_r10",
	}
	-- collect attached parts by nearest old plot centre (within 70)
	local moves = {}
	for _, name in attached do
		local f = workspace:FindFirstChild(name)
		if f then
			for _, item in f:GetChildren() do
				local p = centreOf(item)
				if p then
					local best, bd = nil, 70
					for i, c in olds do
						local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude
						if d < bd then
							best, bd = i, d
						end
					end
					if best then
						table.insert(moves, { item, best })
					end
				end
			end
		end
	end
	for i, c in olds do
		local n = L.PLOTS[i]
		local T = CFrame.new(n[1] - c.X, 0, n[2] - c.Z)
		transform(folder:FindFirstChild("Plot_" .. i .. "_plots_r8"), T)
	end
	for _, mv in moves do
		local c = olds[mv[2]]
		local n = L.PLOTS[mv[2]]
		transform(mv[1], CFrame.new(n[1] - c.X, 0, n[2] - c.Z))
	end
	table.insert(out, "attached parts moved: " .. #moves)
	return table.concat(out, "\n")
end

-- 6. Roads: dirt strips with a soft shoulder, plus discs on every joint.
function steps.roads()
	local roads = sub("Roads")
	roads:ClearAllChildren()
	local function strip(a, b, w, name, y, color, extra)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude + (extra or 0)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.Material = Enum.Material.Ground
		p.Color = color
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(w, 0.2, len)
		p.CFrame = CFrame.lookAt(Vector3.new(mid.X, y - 0.1, mid.Z), Vector3.new(b.X, y - 0.1, b.Z))
		p.Parent = roads
		return p
	end
	local function disc(c, d, name, y, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.Material = Enum.Material.Ground
		p.Color = color
		p.Size = Vector3.new(0.2, d, d)
		p.CFrame = CFrame.new(c.X, y - 0.1, c.Z) * CFrame.Angles(0, 0, math.rad(90))
		p.Parent = roads
	end
	local segs = roadSegments()
	for _, s in segs do
		strip(s.a, s.b, s.w + 4, s.name .. "_Shoulder", GROUND + 0.12, L.SHOULDER_COLOR, 2)
	end
	for _, s in segs do
		strip(s.a, s.b, s.w, s.name, GROUND + 0.2, L.ROAD_COLOR, 0)
	end
	for i, v in ringVertices() do
		disc(v, L.RING.width + 4, "RingJoint" .. i .. "_Shoulder", GROUND + 0.12, L.SHOULDER_COLOR)
		disc(v, L.RING.width, "RingJoint" .. i, GROUND + 0.2, L.ROAD_COLOR)
	end
	for _, j in { Vector3.new(228, 0, 0), Vector3.new(-228, 0, 0), Vector3.new(0, 0, -172), Vector3.new(0, 0, 172) } do
		disc(j, 22, "Junction", GROUND + 0.21, L.ROAD_COLOR)
	end
	return "roads: " .. #roads:GetChildren() .. " parts"
end

-- 7. Street furniture onto the new ring and junctions.
function steps.furniture()
	local out = {}
	local lamps = workspace:FindFirstChild("LookDevStreetFurnR8_streetfurn_r8")
	if lamps then
		-- evenly along the octagon, 11 studs outside the centreline
		local v = ringVertices()
		local perim, lens = 0, {}
		for i = 1, #v do
			local l = (v[i % #v + 1] - v[i]).Magnitude
			lens[i] = l
			perim += l
		end
		local items = lamps:GetChildren()
		for k, item in items do
			local s = (k - 0.5) / #items * perim
			local i = 1
			while s > lens[i] do
				s -= lens[i]
				i += 1
			end
			local a, b = v[i], v[i % #v + 1]
			local dir = (b - a).Unit
			local p = a + dir * s
			local out2 = Vector3.new(p.X, 0, p.Z).Unit
			local target = p + out2 * (L.RING.width / 2 + 4)
			local c = centreOf(item)
			transform(item, CFrame.new(target.X - c.X, 0, target.Z - c.Z))
		end
		table.insert(out, "lamps " .. #items)
	end
	-- junction poles and signposts: cluster everything within 9 studs of an old junction
	local oldJ = { Vector3.new(144, 0, 0), Vector3.new(-144, 0, 0), Vector3.new(0, 0, 144), Vector3.new(0, 0, -144) }
	local newJ =
		{ Vector3.new(240, 0, 16), Vector3.new(-240, 0, -16), Vector3.new(16, 0, 184), Vector3.new(-16, 0, -184) }
	local moved = 0
	for _, name in { "LookDevSignpostsR10_signposts_r10", "LookDevLampsR10_lamps_r10" } do
		local f = workspace:FindFirstChild(name)
		if f then
			for _, item in f:GetChildren() do
				local c = centreOf(item)
				if c then
					for j, o in oldJ do
						if (Vector3.new(c.X, 0, c.Z) - o).Magnitude < 9 then
							transform(item, CFrame.new(newJ[j].X - o.X, 0, newJ[j].Z - o.Z))
							moved += 1
							break
						end
					end
				end
			end
		end
	end
	table.insert(out, "junction items " .. moved)
	return table.concat(out, ", ")
end

-- 8. Kit props as dressing at the hubs.
L.PROPS = {
	{ "prop_gerobak_v2", -40, 70, 200 },
	{ "prop_barrel_v2", -158, 44, 0 },
	{ "prop_crate_v2", -160, 80, 30 },
	{ "prop_karung_v2", -156, 50, 0 },
	{ "prop_motor_v2", 104, -86, 90 },
	{ "prop_pasar_stall_v2", 136, 70, 270 },
	{ "prop_sumur_v2", -190, -60, 0 },
	{ "kit_hut_v2", -366, 40, 90 },
	{ "kit_fence_v2", -128, -66, 0 },
	{ "kit_wall_v2", -200, 62, 90 },
}
function steps.props()
	local f = sub("Props")
	local out = {}
	for _, p in L.PROPS do
		local m = workspace:FindFirstChild(p[1]) or f:FindFirstChild(p[1])
		if m then
			m:PivotTo(CFrame.new(p[2], 0, p[3]) * CFrame.Angles(0, math.rad(p[4]), 0))
			local cf, size = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + Vector3.new(0, GROUND - (cf.Y - size.Y / 2), 0))
			m.Parent = f
			table.insert(out, p[1])
		end
	end
	-- the R5 karung sacks belong with the old gudang; they go to the pasar loading side
	local sd = workspace:FindFirstChild("LookDevSpawnDressingR5_spawn_r5")
	if sd then
		for i = 1, 4 do
			local k = sd:FindFirstChild("R5_karung_" .. i)
			if k then
				local c = centreOf(k)
				transform(k, CFrame.new(-124 + i * 2.5 - c.X, 0, 150 - c.Z))
			end
		end
	end
	return "props: " .. table.concat(out, ", ")
end

-- 9. NPCs: each to its role's spot, facing the road.
local function hubFront(key, along)
	for _, h in L.HUBS do
		if h.key == key then
			local m
			for _, c in sub("Hubs"):GetChildren() do
				if c:GetAttribute("MapHub") == key then
					m = c
				end
			end
			local depth = 30
			if m then
				local _, size = m:GetBoundingBox()
				depth = math.max(size.X, size.Z)
			end
			local a = math.rad(h.yaw + (h.front or 0))
			local fwd = Vector3.new(math.sin(a), 0, math.cos(a))
			local right = Vector3.new(math.cos(a), 0, -math.sin(a))
			return Vector3.new(h.x, 0, h.z) + fwd * (depth / 2 + 5) + right * along, fwd
		end
	end
end

L.ROLES = {
	{ "pak_rt", "pakrt" },
	{ "polisi", "polisi" },
	{ "pedagang", "pasar" },
	{ "tukang_peci", "pasar" },
	{ "tengkulak", "gelap" },
	{ "debt_collector", "gelap" },
	{ "ibu_warung", "warung" },
	{ "petani_wanita", "plot10" },
	{ "petani", "plot1" },
	{ "anak_anak", "lapangan" },
	{ "bapak_ojek", "spine" },
}

function steps.npcs()
	local slots = {}
	local out = {}
	local function spot(role)
		slots[role] = (slots[role] or 0) + 1
		local k = slots[role]
		local along = (k % 2 == 0 and 1 or -1) * math.ceil(k / 2) * 4.5
		if role == "plot1" or role == "plot10" then
			local p = L.PLOTS[role == "plot1" and 1 or 10]
			return Vector3.new(p[1] + along, 0, p[2] + 46), Vector3.new(0, 0, 1)
		elseif role == "lapangan" then
			return Vector3.new(150 + along * 2, 0, -48 + 20), Vector3.new(0, 0, -1)
		elseif role == "spine" then
			return Vector3.new(16, 0, 30 + k * 6), Vector3.new(-1, 0, 0)
		end
		return hubFront(role, along)
	end
	for _, f in workspace:GetChildren() do
		if f:IsA("Folder") and (isNpcFolder(f.Name) or f.Name == "LookDevSpawnDressingR5_spawn_r5") then
			for _, m in f:GetChildren() do
				if m:IsA("Model") and hasHumanoid(m) then
					local lname = m.Name:lower()
					local role
					for _, r in L.ROLES do
						if lname:find(r[1], 1, true) then
							role = r[2]
							break
						end
					end
					local hrp = m:FindFirstChild("HumanoidRootPart", true)
					if role and hrp then
						local pos, face = spot(role)
						if pos then
							local target = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
							local want = CFrame.lookAt(target, target + face)
							m:PivotTo(want * hrp.CFrame:Inverse() * m:GetPivot())
							table.insert(out, m.Name .. "->" .. role)
						end
					end
				end
			end
		end
	end
	return "npcs placed " .. #out
end

-- 10. Clearance: trees, bushes and rocks standing in a road, hub, plot, plaza or reserve are pushed
-- outward along their radius until clear (or parked).
function steps.clear()
	local segs = roadSegments()
	local rects = {}
	for _, h in L.HUBS do
		local m
		for _, c in sub("Hubs"):GetChildren() do
			if c:GetAttribute("MapHub") == h.key then
				m = c
			end
		end
		if m then
			local cf, size = m:GetBoundingBox()
			table.insert(rects, { x = cf.X, z = cf.Z, w = size.X + 8, d = size.Z + 8 })
		end
	end
	for _, p in L.PLOTS do
		table.insert(rects, { x = p[1], z = p[2], w = 92, d = 92 })
	end
	for _, b in L.BLOCKS do
		table.insert(rects, { x = b.x, z = b.z, w = b.old.w, d = b.old.d })
	end
	for _, r in L.FUTURE do
		table.insert(rects, r)
	end
	local function blocked(p, r)
		for _, rect in rects do
			if inRect(p, rect, r) then
				return true
			end
		end
		for _, s in segs do
			if distToSeg(p, s.a, s.b) < s.w / 2 + 2 + r then
				return true
			end
		end
		return false
	end
	local folders = {
		"LookDevModelsVegetationR7_vegetation_r7",
		"LookDevBlocksR9_blocks_r9",
		"LookDevModelsVegetationHubR8_hubveg_r8",
		"LookDevRocksR9_rocks_r9",
		"BackgroundForest",
		"LookDevSpawnDressingR5_spawn_r5",
		"LookDevKampungR10_kampung_r10",
		"VillageTrees",
	}
	local pushed, parkedN = 0, 0
	local p = parked()
	for _, name in folders do
		local f = findFolder(name)
		if not f then
			continue
		end
		for _, item in f:GetChildren() do
			if hasHumanoid(item) or item:GetAttribute("MapHub") then
				continue
			end
			local c, size = centreOf(item)
			if not c or (name == "LookDevRocksR9_rocks_r9" and item.Name:find("river")) then
				continue
			end
			local r = size and math.min(math.max(size.X, size.Z) / 2, 8) or 2
			if blocked(c, r) then
				local flat = Vector3.new(c.X, 0, c.Z)
				local dir = flat.Magnitude > 1 and flat.Unit or Vector3.new(1, 0, 0)
				local ok = false
				for step = 4, 80, 4 do
					local q = flat + dir * step
					if not blocked(q, r) then
						transform(item, CFrame.new(q.X - c.X, 0, q.Z - c.Z))
						ok = true
						pushed += 1
						break
					end
				end
				if not ok then
					item.Parent = p
					parkedN += 1
				end
			end
		end
		task.wait()
	end
	return string.format("clearance: pushed %d, parked %d", pushed, parkedN)
end

-- Shared helpers for the planting steps.
local function terrainY(q)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(q.X, 300, q.Z), Vector3.new(0, -600, 0), rp)
	if not hit or hit.Material == Enum.Material.Water then
		return nil
	end
	return hit.Position.Y
end

local function plant(m, q, y, yaw)
	local cf = m:GetBoundingBox()
	m:PivotTo(CFrame.new(q.X, 0, q.Z) * CFrame.Angles(0, yaw, 0) * CFrame.new(-cf.X, 0, -cf.Z) * m:GetPivot())
	local cf2, s2 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, (y - 0.4) - (cf2.Y - s2.Y / 2), 0))
end

local function riverZ(x)
	return 304 + 12 * math.sin(2 * math.pi * x / 320)
end

-- Everything a tree may not stand in: hubs, plot yards, open-space blocks, reserves, roads, the river
-- band and the sawah terraces, plus trees already planted (`placed`).
local function makeBlocked(placed)
	local rects = {}
	for _, m in sub("Hubs"):GetChildren() do
		local cf, s = m:GetBoundingBox()
		local w = math.max(s.X, s.Z) + 14
		table.insert(rects, { x = cf.X, z = cf.Z, w = w, d = w })
	end
	for _, p in L.PLOTS do
		table.insert(rects, { x = p[1], z = p[2], w = 84, d = 84 })
	end
	for _, b in L.BLOCKS do
		table.insert(rects, { x = b.x, z = b.z, w = b.old.w, d = b.old.d })
	end
	for _, r in L.FUTURE do
		table.insert(rects, r)
	end
	local segs = roadSegments()
	return function(q, r)
		if math.abs(q.Z - riverZ(q.X)) < 26 + r then
			return true
		end
		if q.Z < -296 and math.abs(q.X) < 352 then
			return true
		end
		for _, rc in rects do
			if inRect(q, rc, r) then
				return true
			end
		end
		for _, sg in segs do
			if distToSeg(q, sg.a, sg.b) < sg.w / 2 + 3 + r then
				return true
			end
		end
		for _, p in placed do
			if (p.q - q).Magnitude < p.r + r then
				return true
			end
		end
		return false
	end
end

-- 11. Forest: the old BackgroundForest pines stood in a ring on the village roads. They and clones of
-- the round mangga trees now form the edge belt the drawing shows, outside the ellipse that holds the
-- village and plots; the gaps inside get clusters of mangga, pisang, bambu and shrubs.
function steps.forest()
	local rng = Random.new(1125)
	local placed = {}
	local blocked = makeBlocked(placed)
	local nature = sub("Nature")
	local belt = nature:FindFirstChild("ForestBelt") or Instance.new("Folder")
	belt.Name = "ForestBelt"
	belt.Parent = nature
	local inner = nature:FindFirstChild("VillageTrees") or Instance.new("Folder")
	inner.Name = "VillageTrees"
	inner.Parent = nature
	local pines = findFolder("BackgroundForest"):GetChildren()
	local mangga, pisang, bambu, shrub = {}, {}, {}, {}
	for _, c in findFolder("LookDevModelsVegetationR7_vegetation_r7"):GetChildren() do
		if c.Name:find("mangga") then
			table.insert(mangga, c)
		end
	end
	for _, c in findFolder("LookDevBlocksR9_blocks_r9"):GetChildren() do
		if c.Name:find("pisang") then
			table.insert(pisang, c)
		elseif c.Name:find("bambu") then
			table.insert(bambu, c)
		elseif c.Name:find("shrub") then
			table.insert(shrub, c)
		end
	end
	local beltCount, tries = 0, 0
	while beltCount < 300 and tries < 4000 do
		tries += 1
		local q = Vector3.new(rng:NextNumber(-460, 460), 0, rng:NextNumber(-470, 470))
		if (q.X / 372) ^ 2 + (q.Z / 292) ^ 2 > 1 and not blocked(q, 9) then
			local y = terrainY(q)
			if y and y < 6 then
				local m
				if beltCount < #pines then
					m = pines[beltCount + 1]
				elseif beltCount % 3 == 0 then
					m = pines[rng:NextInteger(1, #pines)]:Clone()
				else
					m = mangga[rng:NextInteger(1, #mangga)]:Clone()
					m:ScaleTo(m:GetScale() * rng:NextNumber(1.1, 1.6))
				end
				m.Parent = belt
				plant(m, q, y, rng:NextNumber(0, 2 * math.pi))
				table.insert(placed, { q = q, r = 9 })
				beltCount += 1
				if beltCount % 40 == 0 then
					task.wait()
				end
			end
		end
	end
	local interior = 0
	tries = 0
	while interior < 170 and tries < 5000 do
		tries += 1
		local q = Vector3.new(rng:NextNumber(-372, 372), 0, rng:NextNumber(-292, 292))
		if (q.X / 372) ^ 2 + (q.Z / 292) ^ 2 <= 1 then
			local roll = rng:NextNumber()
			local src, r, sc
			if roll < 0.5 then
				src, r, sc = mangga, 9, rng:NextNumber(0.9, 1.3)
			elseif roll < 0.68 then
				src, r, sc = pisang, 5, rng:NextNumber(1.2, 1.5)
			elseif roll < 0.8 then
				src, r, sc = bambu, 3, rng:NextNumber(1.2, 1.6)
			else
				src, r, sc = shrub, 4, rng:NextNumber(1.2, 1.8)
			end
			if not blocked(q, r) then
				local y = terrainY(q)
				if y and y < 3 then
					local m = src[rng:NextInteger(1, #src)]:Clone()
					m.Parent = inner
					if m:IsA("Model") then
						m:ScaleTo(m:GetScale() * sc)
					end
					plant(m, q, y, rng:NextNumber(0, 2 * math.pi))
					table.insert(placed, { q = q, r = r })
					interior += 1
					if interior % 40 == 0 then
						task.wait()
					end
				end
			end
		end
	end
	return string.format("forest: belt %d, village trees %d", beltCount, interior)
end

-- 12. Plot yards: the drawing's plots are brown fenced fields. Each gameplay plot keeps its own size;
-- around it the terrain turns to Ground over 76 x 76 and a kit fence rings it, gate towards the village.
L.YARD_HALF = 38
function steps.yards()
	local T = workspace.Terrain
	local tmpl = sub("Props"):FindFirstChild("kit_fence_v2")
	local _, s0 = tmpl:GetBoundingBox()
	local seg = math.max(s0.X, s0.Z)
	local yards = sub("PlotYards")
	yards:ClearAllChildren()
	local HALF = L.YARD_HALF
	local n = 0
	for i, p in L.PLOTS do
		local cx, cz = p[1], p[2]
		local region = Region3.new(Vector3.new(cx - HALF, -4, cz - HALF), Vector3.new(cx + HALF, 2, cz + HALF))
			:ExpandToGrid(4)
		T:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
		local inward = -Vector3.new(cx, 0, cz).Unit
		local gateSide
		if math.abs(inward.X) > math.abs(inward.Z) then
			gateSide = inward.X > 0 and "E" or "W"
		else
			gateSide = inward.Z > 0 and "S" or "N"
		end
		local f = Instance.new("Folder")
		f.Name = "Yard_P" .. i
		f.Parent = yards
		local count = math.floor(HALF * 2 / seg)
		local span = count * seg
		for _, side in { "N", "S", "E", "W" } do
			for k = 0, count - 1 do
				local t = -span / 2 + seg * (k + 0.5)
				if not (side == gateSide and math.abs(t) < seg) then
					local pos, yaw
					if side == "N" then
						pos, yaw = Vector3.new(cx + t, 0, cz - HALF), 0
					elseif side == "S" then
						pos, yaw = Vector3.new(cx + t, 0, cz + HALF), 0
					elseif side == "E" then
						pos, yaw = Vector3.new(cx + HALF, 0, cz + t), 90
					else
						pos, yaw = Vector3.new(cx - HALF, 0, cz + t), 90
					end
					local c = tmpl:Clone()
					local ccf, cs = c:GetBoundingBox()
					local base = cs.X >= cs.Z and 0 or 90
					c:PivotTo(
						CFrame.new(pos)
							* CFrame.Angles(0, math.rad(yaw + base), 0)
							* (CFrame.new(ccf.Position):Inverse() * c:GetPivot())
					)
					local ccf2, cs2 = c:GetBoundingBox()
					c:PivotTo(c:GetPivot() + Vector3.new(0, GROUND - 0.05 - (ccf2.Y - cs2.Y / 2), 0))
					c.Parent = f
					n += 1
				end
			end
		end
		task.wait()
	end
	return "yards: fence pieces " .. n
end

-- 13. Edges and the Empang: grass where the slab met nothing (the west and east voids), pines on it,
-- and a 52 x 32 fish pond at the Empang reserve.
function steps.edges()
	local MapSpec = require(game:GetService("ServerScriptService").Server.World.MapSpec)
	local T = workspace.Terrain
	local cy, sy = MapSpec.volumeForTop(MapSpec.TERRAIN_BASE_Y, GROUND)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { T }
	local filled = 0
	for x = -720, 680, 40 do
		for z = -560, 520, 40 do
			if math.abs(x + 20) > 470 or math.abs(z + 20) > 470 then
				if not workspace:Raycast(Vector3.new(x + 20, 300, z + 20), Vector3.new(0, -600, 0), rp) then
					T:FillBlock(CFrame.new(x + 20, cy, z + 20), Vector3.new(40, sy, 40), Enum.Material.Grass)
					filled += 1
				end
			end
		end
		task.wait()
	end
	local e = L.FUTURE[2]
	T:FillBlock(CFrame.new(e.x, -1, e.z - 2), Vector3.new(60, 6, 40), Enum.Material.Mud)
	T:FillBlock(CFrame.new(e.x, -1.5, e.z - 2), Vector3.new(52, 5, 32), Enum.Material.Air)
	T:FillBlock(CFrame.new(e.x, -3.5, e.z - 2), Vector3.new(52, 3, 32), Enum.Material.Water)
	local belt = sub("Nature"):FindFirstChild("ForestBelt")
	local src = belt:GetChildren()
	local rng = Random.new(4242)
	local n, tries = 0, 0
	while n < 60 and tries < 2000 do
		tries += 1
		local q =
			Vector3.new(rng:NextNumber(470, 700) * (rng:NextNumber() < 0.5 and -1 or 1), 0, rng:NextNumber(-460, 460))
		local y = terrainY(q)
		if y and y < 3 and y > -1 then
			local m = src[rng:NextInteger(1, #src)]:Clone()
			m.Parent = belt
			plant(m, q, y, rng:NextNumber(0, 2 * math.pi))
			n += 1
		end
	end
	return string.format("edges: %d tiles, %d trees, empang dug", filled, n)
end

-- 14. Fix-ups found in review: kites back over their anchors at the lapangan, hub vegetation that a
-- shared dressing zone sent to the wrong hub re-planted round its own hub, and the ambient walkers and
-- the idle NPCs without a root part moved onto their hub lanes.
function steps.fixups()
	local out = {}
	local lay = findFolder("LookDevLayanganR8_layangan_r8")
	if lay then
		for k = 1, 4 do
			local root = lay:FindFirstChild("Layangan_k" .. k .. "_root")
			local anchor = lay:FindFirstChild("Layangan_k" .. k .. "_anchor")
			if root and anchor then
				local d = (anchor.Position + Vector3.new(3, 0, 3)) - root.Position
				d = Vector3.new(d.X, 0, d.Z)
				for _, p in lay:GetChildren() do
					if p:IsA("BasePart") and p ~= anchor and p.Name:find("^Layangan_k" .. k .. "_") then
						p.Anchored = true
						p.CFrame += d
					end
				end
			end
		end
		table.insert(out, "kites")
	end
	local H = {}
	for _, h in L.HUBS do
		H[h.key] = h
	end
	local reach = { gelap = 26, pakrt = 30, ronda = 26, polisi = 22, pasar = 48, warung = 26 }
	local segs = roadSegments()
	local rng = Random.new(77)
	local hv = findFolder("LookDevModelsVegetationHubR8_hubveg_r8")
	local n = 0
	if hv then
		for _, m in hv:GetChildren() do
			local ln = m.Name:lower()
			for key, r in reach do
				if ln:find(key, 1, true) then
					local h = H[key]
					local cf = m:GetBoundingBox()
					if (Vector3.new(cf.X, 0, cf.Z) - Vector3.new(h.x, 0, h.z)).Magnitude > r + 22 then
						for _ = 1, 40 do
							local a = rng:NextNumber(0, 2 * math.pi)
							local rr = r + rng:NextNumber(4, 14)
							local q = Vector3.new(h.x + math.cos(a) * rr, 0, h.z + math.sin(a) * rr)
							local onRoad = false
							for _, sg in segs do
								if distToSeg(q, sg.a, sg.b) < sg.w / 2 + 3 then
									onRoad = true
									break
								end
							end
							if not onRoad then
								plant(m, q, terrainY(q) or GROUND, 0)
								n += 1
								break
							end
						end
					end
					break
				end
			end
		end
	end
	table.insert(out, "hub vegetation " .. n)
	local function standAt(m, x, z)
		local hrp = m:FindFirstChild("HumanoidRootPart", true)
		local p = hrp and hrp.Position or m:GetPivot().Position
		m:PivotTo(m:GetPivot() + Vector3.new(x - p.X, 0, z - p.Z))
	end
	local walkerSpots = {
		pasar = { -76, 40 },
		warung = { 110, 40 },
		polisi = { -74, -60 },
		pakrt = { 86, -60 },
		ronda = { -120, -30 },
		gelap = { -150, 20 },
		cross_ew = { 120, -5 },
		cross_ns = { 6, -110 },
	}
	local aw = findFolder("LookDevAmbientWalkersR8_ambient_walkers_r8")
	if aw then
		for _, m in aw:GetChildren() do
			for key, s in walkerSpots do
				if m.Name:find(key, 1, true) then
					standAt(m, s[1], s[2])
					break
				end
			end
		end
	end
	local idle = findFolder("LookDevNpcsIdleR8_npcs_idle_r8")
	if idle then
		for _, m in idle:GetChildren() do
			if m:IsA("Model") and m.Name:find("polisi") then
				standAt(m, -72, -84)
			elseif m:IsA("Model") and m.Name:find("ibu_warung") then
				standAt(m, 96, 58)
			end
		end
	end
	table.insert(out, "walkers and idle NPCs")
	return "fixups: " .. table.concat(out, ", ")
end

-- 15. Gather every remaining world folder under JuraganMap.Village and anchor every part.
function steps.unify()
	local village = sub("Village")
	local n = 0
	for _, f in workspace:GetChildren() do
		if f:IsA("Folder") and f.Name ~= "JuraganMap" and (f.Name:find("^LookDev") or f.Name == "BackgroundForest") then
			f.Parent = village
			n += 1
		end
	end
	-- Every part is anchored, the display NPC rigs included: they stand or sit still in this layout.
	local anchored = 0
	for _, d in mapRoot():GetDescendants() do
		if d:IsA("BasePart") and not d.Anchored then
			d.Anchored = true
			anchored += 1
		end
	end
	return string.format("unified %d folders, anchored %d parts", n, anchored)
end

-- 17. Tidy pass (v1.1, 2026-11-25): the designer's second round.
-- The Gelap joins the Pasar through the back alley exactly as in pasar_gelap_blockout.blend; the
-- Roblox-built dressing made for the old hub walls is parked; roads and props make room for the
-- 3D models. Studio maps Blender (bx, by, bz) to (-bx, bz, by) about the Pasar's Ground_Dirt
-- (Blender -71, 86, -1), scaled by the Pasar's model scale. Run after unify().
local function findPart(model, name)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == name or d.Name == name .. ".001") then
			return d
		end
	end
	return nil
end

local function nudge(inst, delta)
	if inst:IsA("BasePart") then
		inst.Position += delta
	else
		inst:PivotTo(inst:GetPivot() + delta)
	end
end

local function where(inst)
	return if inst:IsA("BasePart") then inst.Position else inst:GetPivot().Position
end

-- Fit a road strip and its shoulder between two XZ points; with newName, a copy is made instead.
local function fitRoad(roads, name, a, b, newName)
	local road, sh = roads:FindFirstChild(name), roads:FindFirstChild(name .. "_Shoulder")
	if not road then
		return
	end
	local extra = if sh then sh.Size.Z - road.Size.Z else 0
	local r, s = road, sh
	if newName then
		r = road:Clone()
		r.Name = newName
		r.Parent = roads
		if sh then
			s = sh:Clone()
			s.Name = newName .. "_Shoulder"
			s.Parent = roads
		end
	end
	for _, pair in { { r, 0 }, { s, extra } } do
		local p = pair[1]
		if p then
			local y = p.Position.Y
			local A, B = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
			p.Size = Vector3.new(p.Size.X, p.Size.Y, (B - A).Magnitude + pair[2])
			p.CFrame = CFrame.lookAt((A + B) / 2, B)
		end
	end
end

function steps.tidy()
	local root = workspace.JuraganMap
	local V = root.Village
	local parkRoot = ServerStorage:FindFirstChild("ParkedLayout")
	local park = parkRoot:FindFirstChild("HubClearV1") or Instance.new("Folder")
	park.Name = "HubClearV1"
	park.Parent = parkRoot
	local function stash(inst)
		inst:SetAttribute("ParkedFrom", inst.Parent.Name)
		inst.Parent = park
	end

	-- Gelap behind the Pasar, joined by the alley: same scale as the Pasar, solved on G_WallNorth.
	-- Residuals in the Studio run: G_WallEast/West 0.06, Alley_Floor 0.03 studs.
	local pasar, gelap = root.Hubs.pasar_diorama, root.Hubs.TengkulakGelap_v1
	local s = pasar:GetScale()
	local p0 = findPart(pasar, "Ground_Dirt").Position
	local function fromBlender(bx, by, bz)
		return p0 + Vector3.new(-(bx + 71), bz + 1, by - 86) * s
	end
	gelap:ScaleTo(s)
	gelap:PivotTo(CFrame.new(gelap:GetPivot().Position))
	local wall = findPart(gelap, "G_WallNorth")
	gelap:PivotTo(gelap:GetPivot() + (fromBlender(-103, 183.2, 9.0) - wall.Position))

	-- Roblox-built pieces the 3D models replace: the old stall ring, its paving and the R9 plaza.
	for _, n in
		{
			"LookDevPasarAwningsR8_pasar_awnings_r8",
			"LookDevPasarGroundR8_pasar_ground_r8",
			"LookDevPlazaR9_plaza_r9",
		}
	do
		local f = V:FindFirstChild(n)
		if f then
			f.Parent = parkRoot
		end
	end
	-- Old wall glows (every night window), and the hub signs and bunting hung on the old walls.
	for _, c in V.LookDevNightR8_night_r8:GetChildren() do
		if c.Name:find("Window") or c.Name == "LookDevNightR8_Torch_2" or c.Name == "LookDevNightR8_Torch_6" then
			stash(c)
		end
	end
	for _, n in { "Spanduk_sign_01", "Spanduk_sign_02", "Spanduk_bunting_01", "Spanduk_bunting_02" } do
		local c = V.LookDevSpandukR8_spanduk_r8:FindFirstChild(n)
		if c then
			stash(c)
		end
	end
	local bulb = V.LookDevLampsR10_lamps_r10:FindFirstChild("PorchBulb_01")
	if bulb then
		stash(bulb)
	end
	-- Trees that the Gelap now stands on.
	local cf, size = gelap:GetBoundingBox()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { V.LookDevBlocksR9_blocks_r9, V.LookDevModelsVegetationHubR8_hubveg_r8 }
	for _, p in workspace:GetPartBoundsInBox(cf, size - Vector3.new(2, 0, 2), params) do
		local m = p:FindFirstAncestorWhichIsA("Model")
		while m and m.Parent and m.Parent:IsA("Model") do
			m = m.Parent
		end
		if m and m.Parent ~= park then
			stash(m)
		end
	end

	-- Dressing moved out of the footprints.
	local laundry = {
		pasar_line = Vector3.new(-35, 0, 8),
		pasar_hammock = Vector3.new(32, 0, 5),
		pasar_tikar = Vector3.new(50, 0, 20),
	}
	for _, c in V.LookDevLaundryR8_laundry_r8:GetChildren() do
		local g = c.Name:match("^Laundry_(%a+_%a+)")
		if g and laundry[g] then
			nudge(c, laundry[g])
		end
	end
	for _, c in V.LookDevLumbungR8_lumbung_r8:GetChildren() do
		if c.Name:find("^Lumbung_barn_") or c.Name == "Lumbung_LumbungDoorGauge" then
			nudge(c, Vector3.new(-120, 0, -10)) -- the barn takes the Gelap's old spot
		elseif c.Name:find("^Lumbung_pasar_") then
			nudge(c, Vector3.new(20, 0, -4))
		elseif c.Name:find("^Lumbung_pakrt_") then
			nudge(c, Vector3.new(-16, 0, 12))
		end
	end
	for _, c in V.LookDevSeatedR8_seated_r8:GetChildren() do
		local p = where(c)
		if p.X > 95 and p.Z > 65 then
			nudge(c, Vector3.new(22, 0, -9)) -- warung table out of the counter, beside the lane
		end
	end
	-- Hub prop rows split around each lane so the lane reaches the door ({ lane x, left, right, z }).
	local HP = V.LookDevHubPropsR8_hubprops_r8
	local rows = {
		pasar = { -81, -10, 8, 0 },
		polisi = { -80, -8, 6, 0 },
		warung = { 104, -6, 6, 0 },
		pakrt = { 80, -7, 7, 13 },
	}
	for key, rule in rows do
		for _, c in HP[key]:GetChildren() do
			nudge(c, Vector3.new(if where(c).X < rule[1] then rule[2] else rule[3], 0, rule[4]))
		end
	end
	local SD = V.LookDevSpawnDressingR5_spawn_r5
	nudge(SD.R5_pedagang, Vector3.new(-6, 0, 0))
	nudge(SD.R5_tukang_peci, Vector3.new(6, 0, 0))
	nudge(SD.R5_polisi, Vector3.new(-7, 0, -1))

	-- Roads make room for the models: the ring jogs south round the Gelap's back wall, the Ronda
	-- lane stops at its front, the Pasar lane runs to the market aisle, the Kebun spoke stops at the
	-- Lahan's edge, and every spoke opens a gate in its yard fence.
	local R = root.Roads
	fitRoad(R, "Ring4", Vector3.new(-30, 0, 178), Vector3.new(-90, 0, 178), "Ring4_Jog")
	fitRoad(R, "Ring4", Vector3.new(-90, 0, 178), Vector3.new(-148, 0, 172), "Ring4_West")
	fitRoad(R, "Ring4", Vector3.new(148, 0, 172), Vector3.new(-30, 0, 178))
	fitRoad(R, "LaneRonda", Vector3.new(-143, 0, -45), Vector3.new(-110, 0, -45))
	fitRoad(R, "LanePasar", Vector3.new(-82, 0, 9), Vector3.new(-82, 0, 72))
	fitRoad(R, "SpokeKebun", Vector3.new(185.5, 0, -134.5), Vector3.new(298.8, 0, -216.6))
	local yards = OverlapParams.new()
	yards.FilterType = Enum.RaycastFilterType.Include
	yards.FilterDescendantsInstances = { root.PlotYards }
	for _, r in R:GetChildren() do
		if r:IsA("BasePart") and r.Name:find("^Spoke") and not r.Name:find("Shoulder") then
			for _, p in
				workspace:GetPartBoundsInBox(
					r.CFrame + Vector3.new(0, 3, 0),
					Vector3.new(r.Size.X - 2, 4, r.Size.Z - 2),
					yards
				)
			do
				local m = p:FindFirstAncestorWhichIsA("Model")
				if m and m.Name == "kit_fence_v2" and m.Parent ~= park then
					stash(m)
				end
			end
		end
	end
	-- Street furniture and trees off the moved roads.
	local SF = V.LookDevStreetFurnR8_streetfurn_r8
	nudge(SF.StreetFurn_obor_12, Vector3.new(-9, 0, 7))
	nudge(SF.StreetFurn_lampu_13, Vector3.new(0, 0, 7))
	nudge(SF.StreetFurn_obor_14, Vector3.new(0, 0, 7))
	local bale = SF.StreetFurn_bale_02
	local bp = bale:GetPivot().Position
	bale:PivotTo(bale:GetPivot() + Vector3.new(150 - bp.X, 0, -187 - bp.Z))
	nudge(V.LookDevBlocksR9_blocks_r9.R9_shrub_shrubs_121, Vector3.new(0, 0, 8))
	nudge(V.LookDevModelsVegetationR7_vegetation_r7.R7_vegetation_r7_near_bed_mangga_31, Vector3.new(-8, 0, 0))
	nudge(root.Nature.VillageTrees.R7_vegetation_r7_camera_band_mangga_54, Vector3.new(19, 0, 19))
	print("[MapLayoutV1] tidy done")
end

local order = {
	"terrain",
	"park",
	"hubs",
	"dressing",
	"plots",
	"roads",
	"furniture",
	"props",
	"npcs",
	"forest",
	"yards",
	"edges",
	"clear",
	"fixups",
	"unify",
	"tidy",
}

return { steps = steps, order = order, L = L }
