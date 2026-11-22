--!strict
-- ModelMapGroundVariationR10: pure data for the OFF-BY-DEFAULT "ground_variation_r10" candidate
-- (WORK_QUEUE item 195). Tone keys are STRINGS so this module needs no engine types. Layout numbers
-- are a conservative copy of MapSpec geometry, so blobs() and sampleGrid() run unchanged under Lune;
-- the server applier re-checks every painted cell with live MapSpec zones before writing voxels.

local Game = require(script.Parent.Config.Game)

local Data = {}

Data.id = "ground_variation_r10"
Data.folderName = "LookDevGroundVariationR10_ground_variation_r10"

Data.TONES = { "Grass", "LeafyGrass", "Ground", "Mud" }

Data.GATE_CLEAR = 6
Data.GROUND_Y = 0.5
Data.ROAD_HALF = 14
Data.RING_CENTRE = 144
Data.RING_WIDTH = 12
Data.LINK_HALF = 8
Data.PLOT_RADIUS = 192
Data.PLOT_HALF = 24
Data.RING_CLEAR = 28
Data.BAND_MIN = 156
Data.BAND_MAX = 184
Data.CAMERA_CLEAR = 6

Data.MIN_BLOB_RADIUS = 10
Data.MAX_BLOB_RADIUS = 30
Data.MIN_BLOBS = 20
Data.TARGET_BLOBS = 36
Data.BLOB_SPACING = 38
Data.WORLD_SPAN = 200
Data.GRID_DEFAULT = 40

-- MapSpec-derived keep-outs, copied from ModelMapMeadowR10. The radial band sits outside the
-- 12-wide ring on r144 plus a road half-width; plot circles use the conservative plot half-span
-- plus gate clearance; hub rects and the canonical camera sightline are rejected as well.
local HUB_RECTS = {
	{ x = -64, z = -64, hx = 34, hz = 28 },
	{ x = -80, z = -120, hx = 18, hz = 16 },
	{ x = 68, z = -68, hx = 28, hz = 24 },
	{ x = -108, z = 0, hx = 24, hz = 22 },
	{ x = -68, z = 68, hx = 26, hz = 24 },
	{ x = 68, z = 68, hx = 26, hz = 19 },
}

local CAMERA_EYE_X, CAMERA_EYE_Z = 40, 392
local CAMERA_LOOK_X, CAMERA_LOOK_Z = 0, 56

-- One Mud in twenty. Grass and LeafyGrass dominate; Mud stays rare (<= 10% for every blob count
-- in the 20..36 range this layout produces).
local TONE_CYCLE = {
	"Grass",
	"LeafyGrass",
	"Ground",
	"LeafyGrass",
	"Ground",
	"Grass",
	"Mud",
	"LeafyGrass",
	"Ground",
	"Grass",
	"LeafyGrass",
	"Ground",
	"Grass",
	"LeafyGrass",
	"Ground",
	"LeafyGrass",
	"Grass",
	"Ground",
	"LeafyGrass",
	"Ground",
}

local TONE_SET = {}
for _, tone in ipairs(Data.TONES) do
	TONE_SET[tone] = true
end

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

local function buildBlobs(): { any }
	local rand = lcg(195)
	local candidates = {}

	-- Jittered lattice over the sampled world square.
	for x = -Data.WORLD_SPAN, Data.WORLD_SPAN, 44 do
		for z = -Data.WORLD_SPAN, Data.WORLD_SPAN, 44 do
			local px = x + (rand() * 2 - 1) * 10
			local pz = z + (rand() * 2 - 1) * 10
			if Data.zoneClear(px, pz) then
				candidates[#candidates + 1] = { x = px, z = pz }
			end
		end
	end
	-- Deterministic polar lattice over the lawn band between ring and plots.
	for step = 1, 96 do
		local angle = (step - 1) * math.pi * 2 / 96
		local radius = (Data.BAND_MIN + Data.BAND_MAX) / 2 + (rand() * 2 - 1) * ((Data.BAND_MAX - Data.BAND_MIN) / 2)
		local px, pz = math.cos(angle) * radius, math.sin(angle) * radius
		if Data.zoneClear(px, pz) then
			candidates[#candidates + 1] = { x = px, z = pz }
		end
	end

	local blobs = {}
	for _, centre in ipairs(candidates) do
		if #blobs >= Data.TARGET_BLOBS then
			break
		end
		local separated = true
		for _, blob in ipairs(blobs) do
			if math.sqrt((centre.x - blob.x) ^ 2 + (centre.z - blob.z) ^ 2) < Data.BLOB_SPACING then
				separated = false
				break
			end
		end
		if separated then
			blobs[#blobs + 1] = {
				index = #blobs + 1,
				x = centre.x,
				z = centre.z,
				radius = Data.MIN_BLOB_RADIUS + rand() * (Data.MAX_BLOB_RADIUS - Data.MIN_BLOB_RADIUS),
				tone = TONE_CYCLE[(#blobs % #TONE_CYCLE) + 1],
			}
		end
	end
	return blobs
end

local BLOBS = buildBlobs()

function Data.blobs(): { any }
	return BLOBS
end

function Data.toneAt(x: number, z: number): string
	-- Roads, ring, plots and gates are never recoloured, even if a blob edge overlaps them.
	if not Data.zoneClear(x, z) then
		return "Grass"
	end
	for _, blob in ipairs(BLOBS) do
		local dx, dz = x - blob.x, z - blob.z
		local distance = math.sqrt(dx * dx + dz * dz)
		local wobble = 2.5 * math.sin(x * 0.18 + blob.index) * math.sin(z * 0.21 - blob.index)
		if distance <= blob.radius + wobble then
			return blob.tone
		end
	end
	return "Grass"
end

function Data.sampleGrid(n: number?): { any }
	local count = n or Data.GRID_DEFAULT
	local step = Data.WORLD_SPAN * 2 / count
	local cells = {}
	for iz = 1, count do
		for ix = 1, count do
			local x = -Data.WORLD_SPAN + (ix - 0.5) * step
			local z = -Data.WORLD_SPAN + (iz - 0.5) * step
			cells[#cells + 1] = {
				x = x,
				z = z,
				tone = Data.toneAt(x, z),
				zoneClear = Data.zoneClear(x, z),
			}
		end
	end
	return cells
end

do
	assert(#BLOBS >= Data.MIN_BLOBS, "ground_variation_r10: fewer than 20 blob centres")
	local tones, mud = {}, 0
	for _, blob in ipairs(BLOBS) do
		assert(
			blob.radius >= Data.MIN_BLOB_RADIUS and blob.radius <= Data.MAX_BLOB_RADIUS,
			"ground_variation_r10: blob radius outside 10..30"
		)
		assert(Data.zoneClear(blob.x, blob.z), "ground_variation_r10: blob centre fails zoneClear")
		assert(TONE_SET[blob.tone] == true, "ground_variation_r10: unknown tone key")
		tones[blob.tone] = true
		if blob.tone == "Mud" then
			mud += 1
		end
	end
	local toneCount = 0
	for _ in pairs(tones) do
		toneCount += 1
	end
	assert(toneCount >= #Data.TONES, "ground_variation_r10: not all four tone keys present")
	assert(mud <= math.floor(#BLOBS / 10 + 0.5), "ground_variation_r10: Mud exceeds 10% of blobs")
	local gridTones = {}
	for _, cell in ipairs(Data.sampleGrid(Data.GRID_DEFAULT)) do
		if cell.zoneClear then
			gridTones[cell.tone] = true
		end
	end
	local gridCount = 0
	for _ in pairs(gridTones) do
		gridCount += 1
	end
	assert(gridCount >= 3, "ground_variation_r10: grid shows fewer than three tones")
end

return Data
