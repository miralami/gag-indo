--!strict
-- ModelMapCanonicalR10: pure data for the ten OFF-BY-DEFAULT canonical-gap candidates
-- (WORK_QUEUE section P items 228-237). One id per gap, one Workspace folder per id:
-- balai_r10, hub_canopy_r10, blocks_shrubs_r10, pasar_roof_r10, warung_cluster_r10,
-- polisi_roof_r10, pakrt_roof_r10, sawah_gubuk_r10, plots_mailbox_r10, river_palms_r10.
--
-- No Roblox APIs, no instances, no enum lookups, no asset IDs, no engine text. Every recipe is a
-- plain table: shape name, local offset, size, rotation in degrees, built-in material name, plain
-- RGB triple, a Kind tag and `interactive = false`. World anchors come from the caller's MapSpec /
-- Config.Game values via anchorsFor(); the pure rotate helper mirrors MapSpec.rotatePoint exactly,
-- so the Lune harness can check fit without a Studio session.

local Data = {}

Data.familyId = "canonical_r10"
Data.id = "canonical_r10"
Data.stageAttribute = "LookDevStage"
Data.kindAttribute = "Kind"
Data.stringsKeyAttribute = "StringsKey"
Data.idTextAttribute = "IdText"
Data.enTextAttribute = "EnText"
Data.folderPrefix = "LookDev_"
Data.groundKind = "stage_ground"

Data.ids = {
	"balai_r10",
	"hub_canopy_r10",
	"blocks_shrubs_r10",
	"pasar_roof_r10",
	"warung_cluster_r10",
	"polisi_roof_r10",
	"pakrt_roof_r10",
	"sawah_gubuk_r10",
	"plots_mailbox_r10",
	"river_palms_r10",
}
Data.order = Data.ids

Data.SHAPES = { "Ball", "Cylinder", "Block", "Wedge" }
Data.ROUND_SHAPES = { "Ball", "Cylinder" }
Data.CANOPY_SPECIES = { "mangga", "banyan", "rambutan" }
Data.SHRUB_SPECIES = { "bunga_merah", "bunga_kuning", "daun_hijau", "lavender" }
Data.PALM_SPECIES = { "kelapa" }

-- Plain RGB triples. No 7-digit asset literals anywhere in this module.
Data.COLORS = {
	wood = { 138, 92, 48 },
	cream = { 226, 206, 164 },
	clay = { 176, 72, 52 },
	red = { 198, 54, 42 },
	blue = { 44, 96, 176 },
	tin = { 158, 164, 168 },
	yellow_orange = { 236, 150, 36 },
	leaf = { 48, 116, 58 },
	leaf_alt = { 72, 138, 68 },
	flower_red = { 198, 62, 74 },
	flower_yellow = { 232, 186, 62 },
	flower_purple = { 148, 96, 176 },
	trunk = { 112, 78, 46 },
	thatch = { 176, 142, 78 },
}

Data.SIGN_KEYS = {
	balai = "sign_balai",
	plot = "plot_empty",
}

-- Item contracts, kept in data so both the applier and the harness read one source.
Data.CONTRACT = {
	balai_r10 = { minParts = 20, slotScale = 0.5 },
	hub_canopy_r10 = { minPerHub = 2, maxPerHub = 3, canopyMin = 10, canopyMax = 12 },
	blocks_shrubs_r10 = { minShrubs = 60, minSpecies = 3 },
	pasar_roof_r10 = { minParts = 2, slopeMin = 0 },
	warung_cluster_r10 = { minStalls = 3, minTables = 2 },
	polisi_roof_r10 = { minParts = 2, slopeMin = 0 },
	pakrt_roof_r10 = { touchesRidges = false },
	sawah_gubuk_r10 = { huts = 1, terrace = 2 },
	plots_mailbox_r10 = { perPlot = 1 },
	river_palms_r10 = { minPalms = 20, minHeight = 14 },
}

Data.GATE_CLEAR = 6
Data.WATER_CLEAR = 6
Data.ROAD_CLEAR = 11
Data.SHRUB_RADIUS_STEPS = { 0, 6, 12 }
Data.SHRUB_SPECIES_SIZE = { 1.6, 2.1, 1.4, 1.8 }
Data.PALM_X = { -320, -160, -80, 80, 160, 240 }
Data.RIVER_HALF = 14

-- Mirrors MapSpec.rotatePoint. Callers pass live MapSpec values; this copy only makes the pure
-- layout functions usable from Lune without requiring a game-aware module.
local function rotate(cx: number, cz: number, yawDeg: number, lx: number, lz: number): (number, number)
	local a = math.rad(yawDeg)
	local c, s = math.cos(a), math.sin(a)
	return cx + lx * c + lz * s, cz - lx * s + lz * c
end

function Data.rotatePoint(cx: number, cz: number, yawDeg: number, lx: number, lz: number): (number, number)
	return rotate(cx, cz, yawDeg, lx, lz)
end

local function part(
	kind: string,
	shape: string,
	dx: number,
	dy: number,
	dz: number,
	sx: number,
	sy: number,
	sz: number,
	material: string,
	rgb: { number },
	rx: number?,
	ry: number?,
	rz: number?,
	extra: any?
): any
	local out = {
		kind = kind,
		shape = shape,
		dx = dx,
		dy = dy,
		dz = dz,
		size = { sx, sy, sz },
		material = material,
		rgb = rgb,
		rx = rx or 0,
		ry = ry or 0,
		rz = rz or 0,
		interactive = false,
	}
	if type(extra) == "table" then
		for key, value in pairs(extra) do
			out[key] = value
		end
	end
	return out
end

local function roofParts(hub: any?, roof: any?, rgb: { number }, eave: number?): { any }
	local width = hub and hub.width or 64
	local depth = hub and hub.depth or 52
	local rise = roof and roof.rise or 16
	local halfDepth = roof and roof.halfDepth or (depth / 2 + 3)
	local underside = eave or 10
	local pitch = math.deg(math.atan(rise / halfDepth))
	local slant = math.sqrt(halfDepth * halfDepth + rise * rise)
	local ridgeY = underside + rise
	return {
		part("roof_panel", "Block", 0, underside + rise / 2, halfDepth / 2, width + 2, 0.8, slant, "Slate", rgb, pitch),
		part(
			"roof_panel",
			"Block",
			0,
			underside + rise / 2,
			-halfDepth / 2,
			width + 2,
			0.8,
			slant,
			"Slate",
			rgb,
			-pitch
		),
		part("roof_ridge", "Cylinder", 0, ridgeY + 0.7, 0, 0.9, width + 3, 0.9, "Slate", rgb, 0, 0, 90),
	}
end

-- Every returned part is local to its anchor. `anchor` may carry a hub, roof, species or size;
-- omitting it yields the deterministic default recipe used by the pure spec.
function Data.partsFor(id: string, anchor: any?): { any }
	if id == "balai_r10" then
		local out = {
			part("balai_floor", "Block", 0, 0.5, 0, 40, 1, 26, "WoodPlanks", Data.COLORS.wood),
			part("balai_floor_trim", "Block", 0, 1.1, 0, 40, 0.4, 26, "WoodPlanks", Data.COLORS.cream),
		}
		for _, x in ipairs({ -17, -6, 6, 17 }) do
			for _, z in ipairs({ -10, 10 }) do
				out[#out + 1] = part("balai_post", "Cylinder", x, 6, z, 1, 10, 1, "WoodPlanks", Data.COLORS.wood)
			end
		end
		for _, z in ipairs({ -10, 10 }) do
			out[#out + 1] = part("balai_beam", "Block", 0, 11.2, z, 38, 0.8, 0.8, "WoodPlanks", Data.COLORS.wood)
		end
		for _, x in ipairs({ -17, 17 }) do
			out[#out + 1] = part("balai_beam", "Block", x, 11.2, 0, 0.8, 0.8, 20, "WoodPlanks", Data.COLORS.wood)
		end
		for _, side in ipairs({ -1, 1 }) do
			out[#out + 1] =
				part("balai_roof", "Block", 0, 14.8, side * 6.8, 40, 0.8, 15, "Slate", Data.COLORS.clay, side * 27)
		end
		out[#out + 1] = part("balai_ridge", "Cylinder", 0, 18.6, 0, 0.8, 41, 0.8, "Slate", Data.COLORS.wood, 0, 0, 90)
		for _, z in ipairs({ 11.9, 12.8 }) do
			out[#out + 1] = part("balai_step", "Block", 0, 0.4, z, 12, 0.8, 1.6, "WoodPlanks", Data.COLORS.wood)
		end
		out[#out + 1] = part("balai_sign_post", "Cylinder", 0, 3.5, 12, 0.6, 6, 0.6, "WoodPlanks", Data.COLORS.wood)
		out[#out + 1] =
			part("balai_sign", "Block", 0, 6.4, 12, 12, 2.8, 0.6, "WoodPlanks", Data.COLORS.cream, 0, 0, 0, {
				signKey = Data.SIGN_KEYS.balai,
			})
		return out
	elseif id == "hub_canopy_r10" then
		local species = anchor and anchor.species or Data.CANOPY_SPECIES[1]
		local diameter = anchor and anchor.canopy or Data.CONTRACT.hub_canopy_r10.canopyMin + 1
		return {
			part("canopy_trunk", "Cylinder", 0, 4.5, 0, 1.6, 9, 1.6, "WoodPlanks", Data.COLORS.trunk, 0, 0, 0, {
				species = species,
			}),
			part("canopy_crown", "Ball", 0, 12.5, 0, diameter, 8, diameter, "Grass", Data.COLORS.leaf, 0, 0, 0, {
				species = species,
			}),
		}
	elseif id == "blocks_shrubs_r10" then
		local species = anchor and anchor.species or Data.SHRUB_SPECIES[1]
		local size = anchor and anchor.size or Data.SHRUB_SPECIES_SIZE[1]
		local rgb = Data.COLORS.leaf
		local shape = "Ball"
		if species == "bunga_merah" then
			rgb, shape = Data.COLORS.flower_red, "Cylinder"
		elseif species == "bunga_kuning" then
			rgb, shape = Data.COLORS.flower_yellow, "Ball"
		elseif species == "lavender" then
			rgb, shape = Data.COLORS.flower_purple, "Cylinder"
		end
		return {
			part("shrub", shape, 0, size / 2, 0, size, size, size, "Grass", rgb, 0, 0, 0, { species = species }),
		}
	elseif id == "pasar_roof_r10" then
		return roofParts(
			anchor and anchor.hub or nil,
			anchor and anchor.roof or nil,
			Data.COLORS.red,
			anchor and anchor.eave or nil
		)
	elseif id == "warung_cluster_r10" then
		return Data.warungParts()
	elseif id == "polisi_roof_r10" then
		return roofParts(
			anchor and anchor.hub or nil,
			anchor and anchor.roof or nil,
			Data.COLORS.blue,
			anchor and anchor.eave or nil
		)
	elseif id == "pakrt_roof_r10" then
		return {}
	elseif id == "sawah_gubuk_r10" then
		return Data.gubukParts()
	elseif id == "plots_mailbox_r10" then
		return Data.mailboxParts()
	elseif id == "river_palms_r10" then
		return Data.palmParts(anchor)
	end
	return {}
end

function Data.warungParts(): { any }
	local out = {}
	-- ponytail: stall roofs (half-width 5) must clear the Warung door lane (local x [-3,3]);
	-- keep every stall at |lx| >= 9 so no roof/back/post enters the lane.
	local stallOffsets = { -18, -9, 9 }
	for stall = 1, Data.CONTRACT.warung_cluster_r10.minStalls do
		local lx = stallOffsets[stall]
		for _, x in ipairs({ -4.2, 4.2 }) do
			for _, z in ipairs({ -3.2, 3.2 }) do
				out[#out + 1] = part(
					"stall_post",
					"Cylinder",
					lx + x,
					3,
					30 + z,
					0.6,
					6,
					0.6,
					"WoodPlanks",
					Data.COLORS.wood,
					0,
					0,
					0,
					{
						stall = stall,
					}
				)
			end
		end
		out[#out + 1] = part("stall_tin_roof", "Wedge", lx, 6.8, 30, 10, 1.8, 8, "Metal", Data.COLORS.tin, 0, 0, 0, {
			stall = stall,
			tin = true,
		})
		out[#out + 1] = part("stall_back", "Block", lx, 2.4, 26.9, 9, 3, 0.5, "WoodPlanks", Data.COLORS.wood, 0, 0, 0, {
			stall = stall,
		})
	end
	for tableIndex = 1, Data.CONTRACT.warung_cluster_r10.minTables do
		local lx = (tableIndex - 1.5) * 18
		out[#out + 1] = part("table_top", "Block", lx, 3.2, 23, 6, 0.5, 3, "WoodPlanks", Data.COLORS.cream, 0, 0, 0, {
			table = tableIndex,
		})
		for _, x in ipairs({ -2.4, 2.4 }) do
			for _, z in ipairs({ -1, 1 }) do
				out[#out + 1] = part(
					"table_leg",
					"Cylinder",
					lx + x,
					1.5,
					23 + z,
					0.5,
					3,
					0.5,
					"WoodPlanks",
					Data.COLORS.wood,
					0,
					0,
					0,
					{
						table = tableIndex,
					}
				)
			end
		end
	end
	return out
end

function Data.gubukParts(): { any }
	local out = {
		part("gubuk_floor", "Block", 0, 0.3, 0, 10, 0.6, 8, "WoodPlanks", Data.COLORS.wood),
	}
	for _, x in ipairs({ -4.4, 4.4 }) do
		for _, z in ipairs({ -3.4, 3.4 }) do
			out[#out + 1] = part("gubuk_post", "Cylinder", x, 3.4, z, 0.5, 6, 0.5, "WoodPlanks", Data.COLORS.wood)
		end
	end
	for _, z in ipairs({ -3.6, 3.6 }) do
		out[#out + 1] = part("gubuk_wall", "Block", 0, 2.6, z, 9, 3, 0.4, "WoodPlanks", Data.COLORS.cream)
	end
	for _, x in ipairs({ -4.5, 4.5 }) do
		out[#out + 1] = part("gubuk_wall", "Block", x, 2.6, 0, 0.4, 3, 7, "WoodPlanks", Data.COLORS.cream)
	end
	for _, side in ipairs({ -1, 1 }) do
		out[#out + 1] =
			part("gubuk_roof", "Wedge", 0, 7, side * 1.9, 11, 2, 4.6, "WoodPlanks", Data.COLORS.thatch, side * 20)
	end
	return out
end

function Data.mailboxParts(): { any }
	return {
		part("mailbox_post", "Cylinder", 12, 1.5, -13, 0.5, 3, 0.5, "WoodPlanks", Data.COLORS.wood),
		part("mailbox", "Block", 12, 3.6, -13, 2.4, 1.6, 1.5, "Metal", Data.COLORS.blue),
		part("mailbox_sign", "Block", 12, 4.8, -13, 3.2, 1.2, 0.3, "WoodPlanks", Data.COLORS.cream, 0, 0, 0, {
			signKey = Data.SIGN_KEYS.plot,
		}),
	}
end

function Data.palmParts(anchor: any?): { any }
	local species = anchor and anchor.species or Data.PALM_SPECIES[1]
	return {
		part(
			"palm_trunk",
			"Cylinder",
			0,
			6.5,
			0,
			0.9,
			13,
			0.9,
			"WoodPlanks",
			Data.COLORS.trunk,
			0,
			0,
			0,
			{ species = species }
		),
		part(
			"palm_frond",
			"Ball",
			-2.4,
			14.3,
			0,
			5.2,
			1.4,
			2.4,
			"Grass",
			Data.COLORS.leaf,
			0,
			0,
			24,
			{ species = species }
		),
		part(
			"palm_frond",
			"Ball",
			2.4,
			14.3,
			0,
			5.2,
			1.4,
			2.4,
			"Grass",
			Data.COLORS.leaf_alt,
			0,
			0,
			-24,
			{ species = species }
		),
		part("palm_frond", "Ball", 0, 15, 0, 2.4, 1.4, 5.2, "Grass", Data.COLORS.leaf, 0, 0, 0, { species = species }),
	}
end

-- Conservative local XZ bounds; the rotation terms keep tilted roof panels honest.
function Data.boundsFor(id: string, anchor: any?): any
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, recipe in ipairs(Data.partsFor(id, anchor)) do
		local sx, sy, sz = recipe.size[1], recipe.size[2], recipe.size[3]
		local hx = math.abs(math.cos(math.rad(recipe.rz))) * sx / 2 + math.abs(math.sin(math.rad(recipe.rz))) * sy / 2
		local hz = math.abs(math.cos(math.rad(recipe.rx))) * sz / 2 + math.abs(math.sin(math.rad(recipe.rx))) * sy / 2
		minX, maxX = math.min(minX, recipe.dx - hx), math.max(maxX, recipe.dx + hx)
		minZ, maxZ = math.min(minZ, recipe.dz - hz), math.max(maxZ, recipe.dz + hz)
	end
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end

-- balai: half of MapSpec's reserved FUTURE_SLOTS[1], centred at half its authored Z.
function Data.balaiSlot(slot: any?): any
	local x, z, width, depth = 0, -137, 42, 28
	if type(slot) == "table" then
		local scale = Data.CONTRACT.balai_r10.slotScale
		x, z = (slot.x or x) * scale, (slot.z or z) * scale
		width, depth = (slot.width or width) * scale, (slot.depth or depth) * scale
	end
	return { x = x, z = z, width = width, depth = depth }
end

function Data.hubTreeAnchors(hubs: any?): { any }
	local out = {}
	for index, hub in ipairs(hubs or {}) do
		if type(hub) == "table" and type(hub.x) == "number" then
			local spots = {
				{ -(hub.width / 2 - 8), -(hub.depth / 2 - 8) },
				{ hub.width / 2 - 8, hub.depth / 2 - 8 },
			}
			if hub.key == "gelap" then
				-- The Gelap clearing straddles the connector ring (MapSpec's documented exception):
				-- pull both shade trees inward so their 11-stud crowns stay off the road chord.
				spots = {
					{ hub.width / 2 + 6, 6 },
					{ 8, hub.depth / 2 + 6 },
				}
			elseif hub.width >= 48 then
				spots[#spots + 1] = { -(hub.width / 2 - 14), hub.depth / 2 - 12 }
			end
			for spi, spot in ipairs(spots) do
				local x, z = rotate(hub.x, hub.z, hub.yaw or 0, spot[1], spot[2])
				out[#out + 1] = {
					hubKey = hub.key,
					hub = hub,
					x = x,
					z = z,
					lx = spot[1],
					lz = spot[2],
					yaw = hub.yaw or 0,
					species = Data.CANOPY_SPECIES[(index + spi - 1) % #Data.CANOPY_SPECIES + 1],
					canopy = Data.CONTRACT.hub_canopy_r10.canopyMin + 1,
				}
			end
		end
	end
	return out
end

local function nearGates(x: number, z: number, gates: any?): boolean
	for _, gate in ipairs(gates or {}) do
		if type(gate) == "table" and type(gate.x) == "number" and type(gate.z) == "number" then
			local dx, dz = x - gate.x, z - gate.z
			if dx * dx + dz * dz < Data.GATE_CLEAR * Data.GATE_CLEAR then
				return true
			end
		end
	end
	return false
end

function Data.shrubAnchors(ctx: any?): { any }
	local out = {}
	local ring = ctx and ctx.ringCentre or 144
	local ringWidth = ctx and ctx.ringWidth or 12
	local plotRadius = ctx and ctx.plotRadius or 192
	local plotHalf = ctx and ctx.plotHalf or 17
	local gates = ctx and ctx.gates or nil
	local inner = ring + ringWidth / 2 + 8
	local outer = plotRadius - plotHalf - 4
	local radii = {}
	for _, step in ipairs(Data.SHRUB_RADIUS_STEPS) do
		local r = inner + step
		if r <= outer then
			radii[#radii + 1] = r
		end
	end
	local index = 1
	for band, radius in ipairs(radii) do
		for deg = 0, 350, 10 do
			local a = math.rad(deg + (band % 2) * 5)
			local x, z = math.cos(a) * radius, math.sin(a) * radius
			-- The north/south road continuations run at x = 0 outside the ring.
			if math.abs(x) > Data.ROAD_CLEAR and not nearGates(x, z, gates) then
				out[#out + 1] = {
					x = x,
					z = z,
					band = band,
					species = Data.SHRUB_SPECIES[(index - 1) % #Data.SHRUB_SPECIES + 1],
					size = Data.SHRUB_SPECIES_SIZE[(index - 1) % #Data.SHRUB_SPECIES_SIZE + 1],
				}
			end
			index += 1
		end
	end
	return out
end

function Data.palmAnchors(centreZ: (number) -> number, ctx: any?): { any }
	local out = {}
	local half = (ctx and ctx.riverHalf or Data.RIVER_HALF) + Data.WATER_CLEAR
	local index = 1
	for _, x0 in ipairs(Data.PALM_X) do
		for _, side in ipairs({ -1, 1 }) do
			for _, dx in ipairs({ -3, 3 }) do
				local x = x0 + dx
				out[#out + 1] = {
					x = x,
					z = centreZ(x) + side * half,
					side = side,
					species = Data.PALM_SPECIES[1],
					height = Data.CONTRACT.river_palms_r10.minHeight + 2,
				}
				index += 1
			end
		end
	end
	return out
end

function Data.plotAnchors(ctx: any?): { any }
	local out = {}
	local plotCenter = ctx and ctx.plotCenter or nil
	local count = ctx and ctx.plotCount or 10
	if type(plotCenter) ~= "function" then
		return out
	end
	for index = 1, count do
		local ok, x, z = pcall(plotCenter, index)
		if ok and type(x) == "number" and type(z) == "number" then
			local yaw = math.deg(math.atan2(x, z))
			local wx, wz = rotate(x, z, yaw, 12, -13)
			out[#out + 1] = {
				index = index,
				x = wx,
				z = wz,
				cx = x,
				cz = z,
				yaw = yaw,
				lx = 12,
				lz = -13,
			}
		end
	end
	return out
end

function Data.gubukAnchor(ctx: any?): any?
	local terraces = ctx and ctx.terraces or nil
	local sideX = ctx and ctx.sideX or nil
	if type(terraces) ~= "table" or type(terraces[2]) ~= "table" then
		return nil
	end
	local terrace = terraces[2]
	local x, z =
		terraces and sideX and (sideX[2] + (ctx.terraceGap or 84) / 2) / 2 or 191, (terrace.z0 + terrace.z1) / 2
	return { x = x, z = z, y = terrace.top, terrace = 2 }
end

function Data.anchorsFor(id: string, ctx: any?): { any }
	local mapSpec = ctx and ctx.MapSpec or nil
	local game = ctx and ctx.Game or nil
	if id == "balai_r10" then
		local slot = Data.balaiSlot(mapSpec and mapSpec.FUTURE_SLOTS and mapSpec.FUTURE_SLOTS[1] or nil)
		return { { x = slot.x, z = slot.z, y = ctx and ctx.groundY or nil } }
	elseif id == "hub_canopy_r10" then
		return Data.hubTreeAnchors(mapSpec and mapSpec.HUBS or nil)
	elseif id == "blocks_shrubs_r10" then
		local road = mapSpec and mapSpec.ROAD or nil
		local gates = ctx and ctx.gateCentres or nil
		return Data.shrubAnchors({
			ringCentre = road and road.ringCentre or nil,
			ringWidth = road and road.ringWidth or nil,
			plotRadius = game and game.plotRadius or nil,
			plotHalf = ctx and ctx.plotHalf or nil,
			gates = gates,
		})
	elseif id == "pasar_roof_r10" or id == "polisi_roof_r10" then
		local key = id == "pasar_roof_r10" and "pasar" or "polisi"
		local hub = mapSpec and type(mapSpec.hub) == "function" and mapSpec.hub(key) or nil
		if not hub then
			return {}
		end
		local roof = mapSpec and type(mapSpec.hubRoofs) == "function" and mapSpec.hubRoofs()[mapSpec.roofKey(key)]
			or nil
		return {
			{
				hubKey = key,
				hub = hub,
				roof = roof,
				eave = mapSpec and mapSpec.EAVE_UNDERSIDE or nil,
				x = hub.x,
				z = hub.z,
				yaw = hub.yaw,
			},
		}
	elseif id == "warung_cluster_r10" then
		local hub = mapSpec and type(mapSpec.hub) == "function" and mapSpec.hub("warung") or nil
		if not hub then
			return {}
		end
		return { { hubKey = "warung", hub = hub, x = hub.x, z = hub.z, yaw = hub.yaw } }
	elseif id == "pakrt_roof_r10" then
		local hub = mapSpec and type(mapSpec.hub) == "function" and mapSpec.hub("pakrt") or nil
		if not hub then
			return {}
		end
		return { { hubKey = "pakrt", hub = hub, x = hub.x, z = hub.z, yaw = hub.yaw } }
	elseif id == "sawah_gubuk_r10" then
		local anchor = Data.gubukAnchor({
			terraces = mapSpec and mapSpec.TERRACES or nil,
			sideX = mapSpec and mapSpec.TERRACE_X or nil,
			terraceGap = mapSpec and mapSpec.TERRACE_GAP or nil,
		})
		return anchor and { anchor } or {}
	elseif id == "plots_mailbox_r10" then
		return Data.plotAnchors({
			plotCenter = game and game.plotCenter or nil,
			plotCount = game and game.plotCount or nil,
		})
	elseif id == "river_palms_r10" then
		if not mapSpec or type(mapSpec.riverCentreZ) ~= "function" then
			return {}
		end
		return Data.palmAnchors(mapSpec.riverCentreZ, { riverHalf = mapSpec and mapSpec.ROAD and 14 or nil })
	end
	return {}
end

function Data.counts(id: string, ctx: any?): any
	local parts = Data.partsFor(id)
	local anchors = Data.anchorsFor(id, ctx)
	local species, kinds = {}, {}
	for _, recipe in ipairs(parts) do
		kinds[recipe.kind] = true
		if recipe.species then
			species[recipe.species] = true
		end
	end
	for _, anchor in ipairs(anchors) do
		if anchor.species then
			species[anchor.species] = true
		end
	end
	local speciesCount, kindCount = 0, 0
	for _ in pairs(species) do
		speciesCount += 1
	end
	for _ in pairs(kinds) do
		kindCount += 1
	end
	return {
		parts = #parts,
		anchors = #anchors,
		species = speciesCount,
		kinds = kindCount,
		instances = #parts * #anchors,
	}
end

function Data.known(id: string): boolean
	for _, candidate in ipairs(Data.ids) do
		if candidate == id then
			return true
		end
	end
	return false
end

function Data.folderName(id: string): string
	return Data.folderPrefix .. id
end

return Data
