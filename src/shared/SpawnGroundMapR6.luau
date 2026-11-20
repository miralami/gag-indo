--!nocheck
-- SpawnGroundMapR6: pure data for the OFF-BY-DEFAULT "spawn_ground_r6" look-dev candidate.
--
-- R5 hid the named road Parts but left the wider "Ground" Terrain corridors visible: those strips
-- read as asphalt-dark behind spawn, and its 12-wide ring path never covered the 30-wide ring
-- corridor. R6 keeps the default Greybox/MapSpec/Flora/Decor generators untouched. While the flag is
-- on, the SERVER applier lays warm tanah Parts over the FULL corridor footprint and masks grass
-- wedges whose XZ footprint touches a flower bed or a tagged plot. restore() puts everything back.
--
-- No asset IDs, no Roblox APIs: only colours, heights, margins and pure XZ rectangles. The SERVER
-- applier turns these numbers into Parts. Nothing here mutates SpawnGroundMapR5.

local SpawnGroundMapR6 = {}

SpawnGroundMapR6.id = "spawn_ground_r6"
SpawnGroundMapR6.folderName = "LookDevSpawnGroundR6"

-- Tanah colours: warm earth core, paler dry-loam feather, and the same earth for the corridor
-- underlay that covers the Terrain strip R5 could not hide.
SpawnGroundMapR6.colours = {
	path = { 154, 120, 78 },
	feather = { 170, 141, 101 },
	corridor = { 150, 116, 76 },
}

-- Built-in material names only (LookDev.isBuiltinMaterial allowlist). No asphalt, no Slate kerb.
SpawnGroundMapR6.materials = {
	path = "Ground",
	feather = "Mud",
	corridor = "Ground",
}

-- All lifts are relative to MapSpec.GROUND_Y. Old MudPatch discs top out at +0.17, so the corridor
-- underside (+0.18) clears them; every later layer clears the one below without a shared plane.
SpawnGroundMapR6.heights = {
	corridorThickness = 0.04,
	corridorLift = 0.20,
	-- Adjacent 30x30 ring blocks overlap; a tiny per-piece stagger avoids coplanar top faces.
	corridorStagger = 0.002,
	featherThickness = 0.04,
	featherLift = 0.26,
	pathThickness = 0.10,
	pathLift = 0.34,
}

SpawnGroundMapR6.feather = {
	overhang = 2,
	transparency = 0.55,
}

-- Conservative rectangle slack. Plots use tagged PlotAnchor parts; hubs use MapSpec.hubBounds.
SpawnGroundMapR6.exclusionMargins = {
	plot = 3,
	hub = 2,
	mud = 1,
	-- 5.6 bed radius plus 4 studs: a nearby tall wedge still visually covers the bed.
	flowerbed = 4,
	plotGrass = 2,
	grassFootprint = 0.5,
}

-- The 30-wide ring corridor from MapSpec.terrainBlocks(). Kept here as data; R6 never edits MapSpec.
SpawnGroundMapR6.corridor = {
	ringBlock = 30,
	ringFirstDeg = 3, -- terrainBlocks: ring gap ends at 246, first block centre is 249
	ringStepDeg = 12,
	ringBlocks = 29,
}

-- Decor BED_CENTRES and BED_RADIUS, copied as data so the mask stays independent of the default
-- generator. Nothing here changes the flower beds themselves.
SpawnGroundMapR6.flowerBedRadius = 5.6
SpawnGroundMapR6.flowerBeds = {
	{ x = 30, z = 52 },
	{ x = 52, z = 30 },
	{ x = -30, z = 52 },
	{ x = -52, z = 30 },
	{ x = -52, z = -30 },
	{ x = 52, z = -30 },
}

local function rect(name, x, z, sx, sz, yaw)
	local radians = math.rad(yaw or 0)
	local c, s = math.abs(math.cos(radians)), math.abs(math.sin(radians))
	return {
		name = name,
		x = x,
		z = z,
		yaw = yaw or 0,
		sx = sx,
		sz = sz,
		halfX = (math.abs(sx) * c + math.abs(sz) * s) / 2,
		halfZ = (math.abs(sx) * s + math.abs(sz) * c) / 2,
	}
end

-- Same road families as R5: arms, ring chords and continuations. These are the visible tanah core.
function SpawnGroundMapR6.pathRects(mapSpec)
	local out = {}
	for _, arm in mapSpec.roadArms() do
		table.insert(out, rect(arm.name, arm.x, arm.z, arm.sx, arm.sz, 0))
	end
	for _, piece in mapSpec.ringSegments() do
		table.insert(out, rect("RingRoad", piece.x, piece.z, piece.length, mapSpec.ROAD.ringWidth, piece.yaw))
	end
	for _, link in mapSpec.roadContinuations() do
		table.insert(out, rect(link.name, link.x, link.z, link.sx, link.sz, 0))
	end
	return out
end

-- The FULL corridor footprint, including the 30-wide Terrain ring blocks R5 never covered.
function SpawnGroundMapR6.corridorRects(mapSpec)
	local road = mapSpec.ROAD
	local out = {
		rect("CorridorEastWest", 0, 0, road.radius, road.halfWidth * 2, 0),
		rect("CorridorNorthSouth", 0, 0, road.halfWidth * 2, road.radius, 0),
	}
	for _, link in mapSpec.roadContinuations() do
		table.insert(out, rect("Corridor_" .. link.name, link.x, link.z, link.sx, link.sz, 0))
	end
	local size = SpawnGroundMapR6.corridor.ringBlock
	for i = 0, SpawnGroundMapR6.corridor.ringBlocks - 1 do
		local deg = road.gapEnd + SpawnGroundMapR6.corridor.ringFirstDeg + i * SpawnGroundMapR6.corridor.ringStepDeg
		local rad = math.rad(deg)
		table.insert(
			out,
			rect("CorridorRing", math.cos(rad) * road.ringCentre, math.sin(rad) * road.ringCentre, size, size, 0)
		)
	end
	return out
end

-- Inclusive touch counts as overlap: margins already add slack, and a touching rectangle is the
-- z-fighting case we must not build.
function SpawnGroundMapR6.intersects(a, b)
	return math.abs(a.x - b.x) <= a.halfX + b.halfX and math.abs(a.z - b.z) <= a.halfZ + b.halfZ
end

function SpawnGroundMapR6.featherRect(path)
	local extra = SpawnGroundMapR6.feather.overhang
	return {
		name = path.name,
		x = path.x,
		z = path.z,
		yaw = path.yaw,
		sx = path.sx + extra * 2,
		sz = path.sz + extra * 2,
		halfX = path.halfX + extra,
		halfZ = path.halfZ + extra,
	}
end

-- Hub footprints and tagged plot anchors: the same path exclusions R5 uses.
function SpawnGroundMapR6.exclusionRects(mapSpec, anchorRects)
	local out = {}
	local margins = SpawnGroundMapR6.exclusionMargins
	for _, hub in mapSpec.HUBS do
		local bounds = mapSpec.hubBounds(hub)
		table.insert(out, {
			name = "hub:" .. hub.key,
			x = (bounds.minX + bounds.maxX) / 2,
			z = (bounds.minZ + bounds.maxZ) / 2,
			halfX = (bounds.maxX - bounds.minX) / 2 + margins.hub,
			halfZ = (bounds.maxZ - bounds.minZ) / 2 + margins.hub,
		})
	end
	for _, anchor in ipairs(anchorRects or {}) do
		table.insert(out, {
			name = "plot",
			x = anchor.x,
			z = anchor.z,
			halfX = anchor.halfX + margins.plot,
			halfZ = anchor.halfZ + margins.plot,
		})
	end
	return out
end

function SpawnGroundMapR6.allowedRects(mapSpec, anchorRects)
	local excluded = SpawnGroundMapR6.exclusionRects(mapSpec, anchorRects)
	local out = {}
	for _, path in SpawnGroundMapR6.pathRects(mapSpec) do
		local feather = SpawnGroundMapR6.featherRect(path)
		local blocked = false
		for _, zone in ipairs(excluded) do
			if SpawnGroundMapR6.intersects(feather, zone) then
				blocked = true
				break
			end
		end
		if not blocked then
			table.insert(out, path)
		end
	end
	return out
end

-- Cover underlay must also miss the plaza, lapangan, hubs and future slots: MapSpec.keepOutRects
-- is the single source for those, and tagged anchors cover designer plots.
function SpawnGroundMapR6.coverExclusionRects(mapSpec, anchorRects)
	local out = {}
	for _, zone in ipairs(mapSpec.keepOutRects()) do
		table.insert(out, { name = "keepout", x = zone[1], z = zone[2], halfX = zone[3], halfZ = zone[4] })
	end
	for _, anchor in ipairs(anchorRects or {}) do
		local margin = SpawnGroundMapR6.exclusionMargins.plot
		table.insert(out, {
			name = "plot",
			x = anchor.x,
			z = anchor.z,
			halfX = anchor.halfX + margin,
			halfZ = anchor.halfZ + margin,
		})
	end
	return out
end

-- Axis-only subtraction: every corridor rect (and every exclusion zone) is an unrotated XZ rect.
-- Up to four fragments remain when a zone sits fully inside a corridor strip.
function SpawnGroundMapR6.subtractRect(box, zone)
	local boxHalfX = box.halfX or box.sx / 2
	local boxHalfZ = box.halfZ or box.sz / 2
	local x0, x1 = box.x - boxHalfX, box.x + boxHalfX
	local z0, z1 = box.z - boxHalfZ, box.z + boxHalfZ
	-- A hair of slack keeps the fragment edges off the protected footprint: intersects() treats a
	-- touch as overlap, and coplanar edges are exactly what must never be built.
	local pad = 0.01
	local ix0 = math.max(x0, zone.x - zone.halfX - pad)
	local ix1 = math.min(x1, zone.x + zone.halfX + pad)
	local iz0 = math.max(z0, zone.z - zone.halfZ - pad)
	local iz1 = math.min(z1, zone.z + zone.halfZ + pad)
	if ix0 >= ix1 or iz0 >= iz1 then
		return { box }
	end
	local out = {}
	local baseName = box.name or "rect"
	local function piece(name, ax, bx, az, bz)
		if bx - ax > 0 and bz - az > 0 then
			table.insert(out, rect(name, (ax + bx) / 2, (az + bz) / 2, bx - ax, bz - az, 0))
		end
	end
	piece(baseName .. "_L", x0, ix0, z0, z1)
	piece(baseName .. "_R", ix1, x1, z0, z1)
	piece(baseName .. "_B", ix0, ix1, z0, iz0)
	piece(baseName .. "_T", ix0, ix1, iz1, z1)
	return out
end

-- Full corridor coverage minus every protected footprint. Each surviving fragment is a real tanah
-- Part, so the dark strip behind spawn can no longer show through.
function SpawnGroundMapR6.coverRects(mapSpec, anchorRects)
	local excluded = SpawnGroundMapR6.coverExclusionRects(mapSpec, anchorRects)
	local out = {}
	for index, corridor in ipairs(SpawnGroundMapR6.corridorRects(mapSpec)) do
		local pieces = { corridor }
		for _, zone in ipairs(excluded) do
			local nextPieces = {}
			for _, box in ipairs(pieces) do
				for _, fragment in ipairs(SpawnGroundMapR6.subtractRect(box, zone)) do
					table.insert(nextPieces, fragment)
				end
			end
			pieces = nextPieces
		end
		for part, box in ipairs(pieces) do
			box.name = corridor.name .. "_" .. index .. "_" .. part
			table.insert(out, box)
		end
	end
	return out
end

-- Grass mask zones: flower beds (radius from Decor, widened so a nearby tall wedge cannot visually
-- cover them) plus tagged plot anchors. Hubs are already handled by Flora's own keep-outs.
function SpawnGroundMapR6.grassExclusionRects(_mapSpec, anchorRects)
	local out = {}
	for index, bed in ipairs(SpawnGroundMapR6.flowerBeds) do
		local radius = SpawnGroundMapR6.flowerBedRadius + SpawnGroundMapR6.exclusionMargins.flowerbed
		table.insert(out, { name = "flowerbed:" .. index, x = bed.x, z = bed.z, halfX = radius, halfZ = radius })
	end
	for index, anchor in ipairs(anchorRects or {}) do
		local margin = SpawnGroundMapR6.exclusionMargins.plotGrass
		table.insert(out, {
			name = "plot:" .. index,
			x = anchor.x,
			z = anchor.z,
			halfX = anchor.halfX + margin,
			halfZ = anchor.halfZ + margin,
		})
	end
	return out
end

-- Conservative square around a rotated FloraGrass WedgePart's XZ footprint.
function SpawnGroundMapR6.grassRect(x, z, sx, sz)
	local radius = math.max(sx, sz) / 2 + SpawnGroundMapR6.exclusionMargins.grassFootprint
	return { x = x, z = z, halfX = radius, halfZ = radius }
end

function SpawnGroundMapR6.grassBlocked(footprint, zones)
	for _, zone in ipairs(zones) do
		if SpawnGroundMapR6.intersects(footprint, zone) then
			return true
		end
	end
	return false
end

return SpawnGroundMapR6
