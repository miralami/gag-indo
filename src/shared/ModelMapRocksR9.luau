--!strict
-- ModelMapRocksR9: pure data for the OFF-BY-DEFAULT "rocks_r9" LookDev candidate
-- (WORK_QUEUE section O item 151). At least 25 half-buried rocks (1-4 studs, three procedural
-- shapes) along the river banks, the hill foot and the sawah field edges. No path or plot gate.
--
-- Pure data/functions only: no Roblox APIs, no Instances, no Enums, no asset IDs. NO verified rock
-- MODEL id exists in any shared ModelMap* module (only Rock textures and procedural FloraRock), so
-- three original-Part shapes are the documented stand-ins; the applier invents no asset id.
-- The caller supplies MapSpec.riverCentreZ, terrainHalf, terraces and road geometry, so this module
-- never reimplements the map. RIVER_CENTRE mirrors MapSpec.riverCentreZ for pure specs.

local ModelMapRocksR9 = {}

ModelMapRocksR9.id = "rocks_r9"
ModelMapRocksR9.familyId = "rocks_r9"
ModelMapRocksR9.folderName = "LookDevRocksR9_rocks_r9"
ModelMapRocksR9.stageAttribute = "LookDevRocksR9"
ModelMapRocksR9.rockAttribute = "RockR9"
ModelMapRocksR9.kindAttribute = "RockKind"

ModelMapRocksR9.MIN_ROCKS = 25
ModelMapRocksR9.MIN_SPECIES = 2
ModelMapRocksR9.GATE_CLEAR = 2
ModelMapRocksR9.BURY_FRACTION = 0.4 -- centre sits 40% of the part height below the surface
ModelMapRocksR9.SIZE_MIN = 1
ModelMapRocksR9.SIZE_MAX = 4
ModelMapRocksR9.PATH_MARGIN = 0.5

ModelMapRocksR9.KINDS = { "boulder_round", "boulder_wedge", "boulder_cluster" }
ModelMapRocksR9.BANDS = { "river", "hill", "field" }

-- Offsets from the MapSpec geometry, never world-coordinate literals.
local RIVER_HALF = 14
local RIVER_BANK = 8
local HILL_INSET = 12
local FIELD_INSET = 6
local RIVER_STEP = 40
local RIVER_X_LIMIT = 220
local HILL_STEP = 220
local BRIDGE_CLEAR_X = 12 -- bridge width 10 + one rock half-width
local FORD_CLEAR_X = 18 -- ford width 24, west end

-- Mirrors MapSpec.riverCentreZ(x) = 304 + 12 sin(2 pi x / 320). Kept pure for specs.
function ModelMapRocksR9.RIVER_CENTRE(x: number): number
	return 304 + 12 * math.sin(2 * math.pi * x / 320)
end

local SIZES = {
	{ 3.2, 2.2, 2.8 },
	{ 3.4, 1.8, 2.6 },
	{ 2.8, 2.4, 3.0 },
	{ 3.6, 1.6, 2.4 },
	{ 3.0, 2.0, 2.6 },
	{ 2.6, 1.8, 3.2 },
}

local function anchor(index: number, x: number, z: number, band: string): any
	local size = SIZES[((index - 1) % #SIZES) + 1]
	return {
		x = x,
		z = z,
		band = band,
		kind = ModelMapRocksR9.KINDS[((index - 1) % #ModelMapRocksR9.KINDS) + 1],
		size = { size[1], size[2], size[3] },
		bury = ModelMapRocksR9.BURY_FRACTION,
	}
end

-- River bank shelves: z = centreZ(x) -/+ (channel half + bank half). Both banks, stepping along X.
-- The bridge and ford crossings are skipped by construction; no rock lands in either opening.
function ModelMapRocksR9.riverBankAnchors(
	centreZFn: (number) -> number,
	riverHalf: number?,
	bankWidth: number?
): { any }
	local half = riverHalf or RIVER_HALF
	local bank = bankWidth or RIVER_BANK
	local out = {}
	local index = 0
	for x = -RIVER_X_LIMIT, RIVER_X_LIMIT, RIVER_STEP do
		if math.abs(x) > BRIDGE_CLEAR_X and math.abs(x - -250) > FORD_CLEAR_X then
			local centre = centreZFn(x)
			if type(centre) == "number" then
				for _, side in ipairs({ -1, 1 }) do
					index += 1
					out[index] = anchor(index, x, centre + side * (half + bank / 2), "river")
				end
			end
		end
	end
	return out
end

-- Four runs of three just inside the terrain edge where the hills start.
function ModelMapRocksR9.hillFootAnchors(terrainHalf: number): { any }
	local out = {}
	local index = 0
	local edge = terrainHalf - HILL_INSET
	for _, along in ipairs({ -HILL_STEP, 0, HILL_STEP }) do
		for _, side in ipairs({ -1, 1 }) do
			index += 1
			out[index] = anchor(index, along, side * edge, "hill")
			index += 1
			out[index] = anchor(index, side * edge, along, "hill")
		end
	end
	return out
end

-- Sawah terrace bunds: outer corners of all four terraces plus the two Balai-gap bund ends.
function ModelMapRocksR9.fieldEdgeAnchors(terraces: any, terraceX: any, terraceGap: number): { any }
	if type(terraces) ~= "table" or type(terraceX) ~= "table" then
		return {}
	end
	local out = {}
	local index = 0
	local outer = math.max(math.abs(terraceX[1] or 0), math.abs(terraceX[2] or 0)) - FIELD_INSET
	local inner = terraceGap / 2 + FIELD_INSET
	for _, terrace in ipairs(terraces) do
		if type(terrace) == "table" and type(terrace.z0) == "number" and type(terrace.z1) == "number" then
			local midZ = (terrace.z0 + terrace.z1) / 2
			for _, side in ipairs({ -1, 1 }) do
				index += 1
				out[index] = anchor(index, side * outer, midZ, "field")
			end
		end
	end
	for _, z in ipairs({
		terraces[1] and (terraces[1].z0 + terraces[1].z1) / 2,
		terraces[#terraces] and (terraces[#terraces].z0 + terraces[#terraces].z1) / 2,
	}) do
		if type(z) == "number" then
			for _, side in ipairs({ -1, 1 }) do
				index += 1
				out[index] = anchor(index, side * inner, z, "field")
			end
		end
	end
	return out
end

-- ctx: { centreZ = MapSpec.riverCentreZ, terrainHalf = MapSpec.TERRAIN_HALF,
--        terraces = MapSpec.TERRACES, terraceX = MapSpec.TERRACE_X,
--        terraceGap = MapSpec.TERRACE_GAP, riverHalf, riverBank }.
function ModelMapRocksR9.rocks(ctx: any): { any }
	if type(ctx) ~= "table" or type(ctx.centreZ) ~= "function" or type(ctx.terrainHalf) ~= "number" then
		return {}
	end
	local out = {}
	for _, rock in ipairs(ModelMapRocksR9.riverBankAnchors(ctx.centreZ, ctx.riverHalf, ctx.riverBank)) do
		out[#out + 1] = rock
	end
	for _, rock in ipairs(ModelMapRocksR9.hillFootAnchors(ctx.terrainHalf)) do
		out[#out + 1] = rock
	end
	for _, rock in ipairs(ModelMapRocksR9.fieldEdgeAnchors(ctx.terraces, ctx.terraceX, ctx.terraceGap or 84)) do
		out[#out + 1] = rock
	end
	return out
end

function ModelMapRocksR9.count(rocks: any): number
	return type(rocks) == "table" and #rocks or 0
end

function ModelMapRocksR9.kinds(rocks: any): { string }
	local seen, out = {}, {}
	if type(rocks) ~= "table" then
		return out
	end
	for _, rock in ipairs(rocks) do
		local kind = type(rock) == "table" and rock.kind or nil
		if type(kind) == "string" and not seen[kind] then
			seen[kind] = true
			out[#out + 1] = kind
		end
	end
	return out
end

function ModelMapRocksR9.bandCounts(rocks: any): { [string]: number }
	local out = { river = 0, hill = 0, field = 0 }
	if type(rocks) ~= "table" then
		return out
	end
	for _, rock in ipairs(rocks) do
		local band = type(rock) == "table" and rock.band or nil
		if out[band] ~= nil then
			out[band] += 1
		end
	end
	return out
end

-- Original-Part recipe for one rock. Three documented stand-ins; no asset id and no engine enum.
-- Cluster sub-parts stay inside the rock's declared 1-4 stud footprint.
function ModelMapRocksR9.partsFor(rock: any): { any }
	local size = rock.size
	if rock.kind == "boulder_wedge" then
		return { { shape = "Wedge", size = { size[1], size[2], size[3] }, dx = 0, dz = 0 } }
	elseif rock.kind == "boulder_cluster" then
		return {
			{ shape = "Ball", size = { size[1] * 0.45, size[2] * 0.62, size[3] * 0.48 }, dx = -size[1] * 0.25, dz = 0 },
			{ shape = "Ball", size = { size[1] * 0.48, size[2] * 0.7, size[3] * 0.46 }, dx = 0, dz = size[3] * 0.2 },
			{
				shape = "Ball",
				size = { size[1] * 0.42, size[2] * 0.58, size[3] * 0.5 },
				dx = size[1] * 0.25,
				dz = -size[3] * 0.16,
			},
		}
	end
	return { { shape = "Ball", size = { size[1], size[2], size[3] }, dx = 0, dz = 0 } }
end

-- Exclusion: drop rocks whose centre is closer than `clear` studs to any gate centre (XZ).
-- An empty gate list is valid here; the applier and harness refuse to read zero gates separately.
function ModelMapRocksR9.gateExcluded(rocks: any, gates: any, clear: number?): { any }
	local limit = (clear or ModelMapRocksR9.GATE_CLEAR) ^ 2
	local out = {}
	if type(gates) ~= "table" or #gates == 0 then
		if type(rocks) == "table" then
			for _, rock in ipairs(rocks) do
				out[#out + 1] = rock
			end
		end
		return out
	end
	for _, rock in ipairs(rocks or {}) do
		local blocked = false
		for _, gate in ipairs(gates) do
			if type(gate) == "table" and type(gate.x) == "number" and type(gate.z) == "number" then
				local dx, dz = rock.x - gate.x, rock.z - gate.z
				if dx * dx + dz * dz < limit then
					blocked = true
					break
				end
			end
		end
		if not blocked then
			out[#out + 1] = rock
		end
	end
	return out
end

-- Exclusion: drop rocks whose padded XZ footprint intersects any road rectangle or ring chord.
-- Mirrors the harness's pathRects/pathSegments shapes; the caller passes the live MapSpec tables.
function ModelMapRocksR9.pathExcluded(rocks: any, rects: any, segments: any): { any }
	local out = {}
	local margin = ModelMapRocksR9.PATH_MARGIN
	for _, rock in ipairs(rocks or {}) do
		local halfX = rock.size[1] / 2 + margin
		local halfZ = rock.size[3] / 2 + margin
		local blocked = false
		for _, rect in ipairs(rects or {}) do
			local rx, rz = rect.x, rect.z
			local rhx = rect.halfX or (type(rect.sx) == "number" and rect.sx / 2 or 0)
			local rhz = rect.halfZ or (type(rect.sz) == "number" and rect.sz / 2 or 0)
			if
				type(rx) == "number"
				and type(rz) == "number"
				and math.abs(rock.x - rx) < rhx + halfX
				and math.abs(rock.z - rz) < rhz + halfZ
			then
				blocked = true
				break
			end
		end
		if not blocked then
			for _, seg in ipairs(segments or {}) do
				local a = math.rad(seg.yaw or 0)
				local tx, tz = seg.tx or math.cos(a), seg.tz or -math.sin(a)
				local nx, nz = seg.nx or math.sin(a), seg.nz or math.cos(a)
				local dx, dz = rock.x - seg.x, rock.z - seg.z
				local tangent = dx * tx + dz * tz
				local normal = dx * nx + dz * nz
				local halfLen = seg.halfLen or ((seg.length or 0) / 2)
				local extentT = math.abs(tx) * halfX + math.abs(tz) * halfZ
				local extentN = math.abs(nx) * halfX + math.abs(nz) * halfZ
				if math.abs(tangent) < halfLen + extentT and math.abs(normal) < 3 + extentN then
					blocked = true
					break
				end
			end
		end
		if not blocked then
			out[#out + 1] = rock
		end
	end
	return out
end

return ModelMapRocksR9
