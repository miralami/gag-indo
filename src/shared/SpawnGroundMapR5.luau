--!nocheck
-- SpawnGroundMapR5: pure data for the OFF-BY-DEFAULT "spawn_ground_r5" look-dev candidate.
--
-- The existing Greybox roads (buildRoads) REMAIN THE DEFAULT and are deliberately untouched: this
-- module is the stored alternative behind the LookDev flag. Its dirt paths replace those strips
-- only while LookDev.enable("spawn_ground_r5") is active; restore() puts the originals back.
--
-- No asset IDs, no Roblox APIs: only colours, heights, margins and pure XZ rectangles derived from
-- MapSpec geometry. The SERVER applier turns these numbers into Parts.

local SpawnGroundMapR5 = {}

SpawnGroundMapR5.id = "spawn_ground_r5"
SpawnGroundMapR5.folderName = "LookDevSpawnGroundR5"

-- Tanah colours: warm earth core, paler dry-loam feather at each margin.
SpawnGroundMapR5.colours = {
	path = { 154, 120, 78 },
	feather = { 170, 141, 101 },
}

-- Built-in material names only (LookDev.isBuiltinMaterial allowlist). No Slate kerb.
SpawnGroundMapR5.materials = {
	path = "Ground",
	feather = "Mud",
}

-- All lifts are relative to MapSpec.GROUND_Y (the visible terrain top). MudPatch discs top out at
-- GROUND_Y + 0.17, so the feather underside (+0.19) and the path underside (+0.24) clear both
-- terrain and every old decal, and the two new layers never share a plane.
SpawnGroundMapR5.heights = {
	featherThickness = 0.04,
	featherLift = 0.21,
	pathThickness = 0.10,
	pathLift = 0.29,
}

-- Wider, thinner, low-opacity underlay: a soft tanah edge instead of the old 0.4-stud Slate kerb.
SpawnGroundMapR5.feather = {
	overhang = 2,
	transparency = 0.55,
}

-- Conservative rectangle slack. Plots use tagged PlotAnchor parts; hubs use MapSpec.hubBounds.
SpawnGroundMapR5.exclusionMargins = {
	plot = 3,
	hub = 2,
	mud = 1,
}

-- Axis-aligned XZ footprint plus the local dims/yaw needed to build the Part. halfX/halfZ are the
-- conservative AABB of the ROTATED piece, so ring chords are safely excluded/compared.
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

function SpawnGroundMapR5.pathRects(mapSpec)
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

-- Inclusive touch counts as overlap: margins already add slack, and a touching rectangle is the
-- z-fighting case we must not build.
function SpawnGroundMapR5.intersects(a, b)
	return math.abs(a.x - b.x) <= a.halfX + b.halfX and math.abs(a.z - b.z) <= a.halfZ + b.halfZ
end

function SpawnGroundMapR5.featherRect(path)
	local extra = SpawnGroundMapR5.feather.overhang
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

-- anchorRects are already XZ rectangles from the server applier (tagged PlotAnchor BaseParts).
function SpawnGroundMapR5.exclusionRects(mapSpec, anchorRects)
	local out = {}
	local margins = SpawnGroundMapR5.exclusionMargins
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

-- Skip the whole piece when its FEATHER footprint touches a plot/hub exclusion. Skipping (rather
-- than trimming) keeps the rectangle test conservative and never lays tanah over a plot surface.
function SpawnGroundMapR5.allowedRects(mapSpec, anchorRects)
	local excluded = SpawnGroundMapR5.exclusionRects(mapSpec, anchorRects)
	local out = {}
	for _, path in SpawnGroundMapR5.pathRects(mapSpec) do
		local feather = SpawnGroundMapR5.featherRect(path)
		local blocked = false
		for _, zone in ipairs(excluded) do
			if SpawnGroundMapR5.intersects(feather, zone) then
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

return SpawnGroundMapR5
