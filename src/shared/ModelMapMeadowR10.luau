--!strict
-- ModelMapMeadowR10: pure data for the OFF-BY-DEFAULT "meadow_r10" candidate (WORK_QUEUE item 194).
-- Real Creator Store flower and grass IDs live here only; the applier reads Data.ids by species key.
-- No engine APIs, no engine types, no ID URL literals. Plot centres come from Config.Game; every
-- other layout number is a conservative copy of MapSpec geometry so patches() runs unchanged under
-- Lune. The applier re-checks each accepted patch with live MapSpec zones and tagged plot anchors.

local Game = require(script.Parent.Config.Game)

local Data = {}

Data.id = "meadow_r10"
Data.folderName = "LookDevMeadowR10_meadow_r10"

Data.MIN_PATCHES = 20
Data.TARGET_PATCHES = 28
Data.MIN_ITEMS_PER_PATCH = 10
Data.MAX_ITEMS_PER_PATCH = 20
Data.MIN_VISIBLE = 6
Data.GATE_CLEAR = 6
Data.GROUND_Y = 0.5
Data.PLOT_RADIUS_FRACTION = 1 / 10

-- MapSpec-derived keep-outs. The radial band sits outside the 12-wide ring on r144 plus a road
-- half-width of 14; plot circles use the conservative 24-stud plot half-span plus the gate clear.
Data.ROAD_HALF = 14
Data.RING_CENTRE = 144
Data.RING_WIDTH = 12
Data.LINK_HALF = 8
Data.PLOT_RADIUS = 192
Data.PLOT_HALF = 24
Data.RING_CLEAR = 28
Data.BAND_MIN = 156
Data.BAND_MAX = 184
Data.BANK_Z_MIN = 164
Data.BANK_Z_MAX = 200
Data.BANK_X_MAX = 120
Data.PATCH_RADIUS = 7
Data.PATCH_SPACING = 15
Data.MAX_FOOTPRINT = 4
Data.CAMERA_CLEAR = 6

-- Five real free Creator Store assets sourced and baked by item 193. Keys are species, not labels.
Data.ids = {
	flower_a = 7974911801,
	flower_b = 13032768586,
	daisy = 70509679878841,
	tall_grass = 128368650541272,
	wild_grass = 8715139325,
}

Data.species = { "flower_a", "flower_b", "daisy", "tall_grass", "wild_grass" }

local HEIGHTS = {
	flower_a = { 1.5, 2.4 },
	flower_b = { 1.2, 2.1 },
	daisy = { 0.6, 1.1 },
	tall_grass = { 2.6, 3.8 },
	wild_grass = { 0.7, 1.2 },
}

-- Hub footprints copied from MapSpec, half-span plus the two-stud vegetation margin.
local HUB_RECTS = {
	{ x = -64, z = -64, hx = 34, hz = 28 },
	{ x = -80, z = -120, hx = 18, hz = 16 },
	{ x = 68, z = -68, hx = 28, hz = 24 },
	{ x = -108, z = 0, hx = 24, hz = 22 },
	{ x = -68, z = 68, hx = 26, hz = 24 },
	{ x = 68, z = 68, hx = 26, hz = 19 },
}

-- canonical_overview eye/lookAt from ReviewCameras, reduced to its horizontal projection.
local CAMERA_EYE_X, CAMERA_EYE_Z = 40, 392
local CAMERA_LOOK_X, CAMERA_LOOK_Z = 0, 56

local function lcg(seed: number): () -> number
	local state = seed
	return function()
		state = (state * 16807) % 65521
		return (state - 1) / 65520
	end
end

local function distanceToSegment(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
	local dx, dz = bx - ax, bz - az
	local lengthSq = dx * dx + dz * dz
	local t = lengthSq > 0 and math.clamp(((px - ax) * dx + (pz - az) * dz) / lengthSq, 0, 1) or 0
	local cx, cz = ax + dx * t, az + dz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

-- Conservative pure zone check. The applier still runs R5.pointAllowed with live MapSpec zones.
function Data.zoneClear(x: number, z: number): boolean
	local radius = math.sqrt(x * x + z * z)
	if math.abs(radius - Data.RING_CENTRE) <= Data.RING_CLEAR then
		return false
	end
	if math.abs(x) <= Data.ROAD_HALF + Data.GATE_CLEAR or math.abs(z) <= Data.ROAD_HALF + Data.GATE_CLEAR then
		return false
	end
	for index = 1, Game.plotCount do
		local px, pz = Game.plotCenter(index)
		local clear = Data.PLOT_HALF + Data.GATE_CLEAR + 4
		local dx, dz = x - px, z - pz
		if dx * dx + dz * dz <= clear * clear then
			return false
		end
	end
	for _, hub in ipairs(HUB_RECTS) do
		if math.abs(x - hub.x) <= hub.hx and math.abs(z - hub.z) <= hub.hz then
			return false
		end
	end
	if distanceToSegment(x, z, CAMERA_EYE_X, CAMERA_EYE_Z, CAMERA_LOOK_X, CAMERA_LOOK_Z) <= Data.CAMERA_CLEAR then
		return false
	end
	return true
end

local function buildPatches(): { any }
	local rand = lcg(194)
	local candidates = {}

	-- South-bank lawns first: these are the patches closest to the canonical overview.
	for x = -Data.BANK_X_MAX, Data.BANK_X_MAX, 24 do
		for z = Data.BANK_Z_MIN, Data.BANK_Z_MAX, 18 do
			local px = x + (rand() * 2 - 1) * 4
			local pz = z + (rand() * 2 - 1) * 3
			if Data.zoneClear(px, pz) then
				candidates[#candidates + 1] = { x = px, z = pz }
			end
		end
	end
	-- Deterministic polar lattice over the lawn band between ring and plots.
	for step = 1, 120 do
		local angle = math.pi / 2 + (step - 1) * math.pi * 2 / 120
		local radius = (Data.BAND_MIN + Data.BAND_MAX) / 2 + (rand() * 2 - 1) * ((Data.BAND_MAX - Data.BAND_MIN) / 2)
		local px, pz = math.cos(angle) * radius, math.sin(angle) * radius
		if Data.zoneClear(px, pz) then
			candidates[#candidates + 1] = { x = px, z = pz }
		end
	end

	local patches = {}
	for _, centre in ipairs(candidates) do
		if #patches >= Data.TARGET_PATCHES then
			break
		end
		local separated = true
		for _, patch in ipairs(patches) do
			if math.sqrt((centre.x - patch.x) ^ 2 + (centre.z - patch.z) ^ 2) < Data.PATCH_SPACING then
				separated = false
				break
			end
		end
		if not separated then
			continue
		end
		local patch = {
			index = #patches + 1,
			x = centre.x,
			z = centre.z,
			radius = Data.PATCH_RADIUS,
			items = {},
		}
		local count = Data.MIN_ITEMS_PER_PATCH
			+ math.floor(rand() * (Data.MAX_ITEMS_PER_PATCH - Data.MIN_ITEMS_PER_PATCH + 1))
		local attempts = 0
		while #patch.items < count and attempts < count * 12 do
			attempts += 1
			local itemIndex = #patch.items + 1
			local species = Data.species[((itemIndex - 1) % #Data.species) + 1]
			local band = HEIGHTS[species]
			local vx, vz, ox, oz, clear = 0, 0, 0, 0, false
			for _ = 1, 12 do
				local angle = rand() * math.pi * 2
				local spread = math.sqrt(rand()) * Data.PATCH_RADIUS
				ox, oz = math.cos(angle) * spread, math.sin(angle) * spread
				vx, vz = centre.x + ox, centre.z + oz
				if Data.zoneClear(vx, vz) then
					clear = true
					break
				end
			end
			if clear then
				patch.items[itemIndex] = {
					x = vx,
					z = vz,
					yaw = rand() * math.pi * 2,
					species = species,
					height = band[1] + rand() * (band[2] - band[1]),
					VegX = vx,
					VegZ = vz,
					PatchIndex = patch.index,
					ItemIndex = itemIndex,
					offsetX = ox,
					offsetZ = oz,
				}
			end
		end
		patches[#patches + 1] = patch
	end
	return patches
end

function Data.patches(): { any }
	return buildPatches()
end

do
	local patches = Data.patches()
	assert(#patches >= Data.MIN_PATCHES, "meadow_r10: fewer than 20 patch centres")
	for _, patch in ipairs(patches) do
		assert(
			#patch.items >= Data.MIN_ITEMS_PER_PATCH and #patch.items <= Data.MAX_ITEMS_PER_PATCH,
			"meadow_r10: patch item count outside 10..20"
		)
	end
end

return Data
