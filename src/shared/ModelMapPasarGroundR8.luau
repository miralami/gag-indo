--!strict
-- ModelMapPasarGroundR8: pure data for the OFF-BY-DEFAULT "pasar_ground_r8" LookDev candidate
-- (WORK_QUEUE section N item 109). Flat paving stones, small cobble patches and shallow drainage
-- gutters around the Pasar. All geometry is original Parts staged by
-- src/server/World/LookDevPasarGroundR8.luau: no asset IDs, no brand marks, no game APIs here.
--
-- NO TERRAIN EDIT: nothing touches Terrain / voxels. Every slab is a flat Part whose BOTTOM sits on
-- MapSpec.GROUND_Y, i.e. centre Y = GROUND_Y + thickness / 2. PAVING_TOL = 0.15 studs is the
-- harness tolerance on that bbox bottom (the measured surface is the bottom face, not the centre or
-- the top), so a seam between two slabs cannot leave a trip lip.
--
-- Coordinates are PASAR-LOCAL (lx, lz) offsets from MapSpec.hub("pasar"); the applier resolves each
-- with MapSpec.hubPoint and the harness translates the lane's four local corners the same way. LANE
-- mirrors ModelMapPasarAwningsR8.LANE: local x -38..38, z 30..36. Every recipe stays outside it (the
-- south paving row stops at z = 29.8) and clear of the twelve awning stall footprints (front stalls
-- at lz 42, west/east stacks at lx +/-44 with depth 8).

local Data = {}

Data.id = "pasar_ground_r8"
Data.familyId = "pasar_ground_r8"
Data.folderName = "LookDevPasarGroundR8_pasar_ground_r8"

Data.stageAttribute = "LookDevPasarGroundR8"
Data.kindAttribute = "PasarGroundKind"
Data.pavingAttribute = "PasarGroundPaving"
Data.cobbleAttribute = "PasarGroundCobble"
Data.gutterAttribute = "PasarGroundGutter"

Data.KIND = {
	paving = "paving",
	cobble = "cobble",
	gutter = "gutter",
}
Data.KINDS = { "paving", "cobble", "gutter" }
Data.kindAttributes = {
	[Data.KIND.paving] = Data.pavingAttribute,
	[Data.KIND.cobble] = Data.cobbleAttribute,
	[Data.KIND.gutter] = Data.gutterAttribute,
}

-- Mirrors of the Pasar geometry; the applier always resolves the hub from MapSpec.hub("pasar").
Data.FOOTPRINT = { width = 64, depth = 52 }
local halfW, halfD = Data.FOOTPRINT.width / 2, Data.FOOTPRINT.depth / 2 -- 32, 26

-- The six-stud walking lane between the stalls, in Pasar-local coordinates.
Data.LANE = { lx = 0, lz = 33, width = 76, depth = 6 }
Data.PAVING_TOL = 0.15
Data.MIN_PAVING = 60

-- Built-in materials only. Plain {r,g,b} arrays; the applier calls Color3.fromRGB.
Data.COLOURS = {
	paving = { 176, 176, 168 },
	cobble = { 184, 186, 178 }, -- item 179: lifted off the old slate-dark 146/148/142
	gutter = { 156, 162, 166 },
}
Data.MATERIALS = {
	paving = "Cobblestone",
	cobble = "Slate",
	gutter = "Slate",
}
-- Item 179: MATERIALS keeps the item-109 recipe tokens, but those Slate pads read as asphalt under
-- the lapak. PAD_MATERIALS is the authoritative material at staging time: only Ground/Cobblestone/
-- Pavement, never SmoothPlastic black. The applier resolves through this map.
Data.PAD_MATERIALS = {
	paving = "Cobblestone",
	cobble = "Cobblestone",
	gutter = "Pavement",
}
Data.ALLOWED_PAD_MATERIALS = { Ground = true, Cobblestone = true, Pavement = true }

-- Thicknesses double as the bottom-to-centre offset: bottom = centre Y - size[2] / 2.
Data.SLAB = {
	pavingThickness = 0.18,
	cobbleThickness = 0.16,
	gutterThickness = 0.12,
	pavingStraight = { 4.4, 0.18, 2.6 }, -- north/south rows, long side along X
	pavingSide = { 2.6, 0.18, 4.4 }, -- west/east columns, long side along Z
	cobbleStraight = { 2.2, 0.16, 1.8 },
	cobbleSide = { 1.8, 0.16, 2.2 },
	gutterStraight = { 12, 0.12, 1 },
	gutterSide = { 1, 0.12, 12 },
}

local function range(from: number, to: number, step: number): { number }
	local out = {}
	for value = from, to, step do
		out[#out + 1] = value
	end
	return out
end

-- A ring of flat pieces just outside the building footprint. Rows at local z +/-28.5, columns at
-- local x +/-34.5; the southern row ends at 28.5 + 2.6 / 2 = 29.8, before the lane starts at 30.
local function makePaving(): { any }
	local out = {}
	for _, row in ipairs({ { name = "n", lz = -(halfD + 2.5) }, { name = "s", lz = halfD + 2.5 } }) do
		for index, lx in ipairs(range(-30, 30, 6)) do
			out[#out + 1] = {
				name = string.format("paving_%s_%02d", row.name, index),
				lx = lx,
				lz = row.lz,
				size = Data.SLAB.pavingStraight,
			}
		end
	end
	for _, column in ipairs({ { name = "w", lx = -(halfW + 2.5) }, { name = "e", lx = halfW + 2.5 } }) do
		for index, lz in ipairs(range(-24, 24, 6)) do
			out[#out + 1] = {
				name = string.format("paving_%s_%02d", column.name, index),
				lx = column.lx,
				lz = lz,
				size = Data.SLAB.pavingSide,
			}
		end
	end
	return out
end

-- Smaller slate patches sit in the gaps between the paving stones, same ring, same height rule.
local function makeCobble(): { any }
	local out = {}
	for _, row in ipairs({ { name = "n", lz = -(halfD + 2.5) }, { name = "s", lz = halfD + 2.5 } }) do
		for index, lx in ipairs(range(-27, 27, 6)) do
			out[#out + 1] = {
				name = string.format("cobble_%s_%02d", row.name, index),
				lx = lx,
				lz = row.lz,
				size = Data.SLAB.cobbleStraight,
			}
		end
	end
	for _, column in ipairs({ { name = "w", lx = -(halfW + 2.5) }, { name = "e", lx = halfW + 2.5 } }) do
		for index, lz in ipairs(range(-21, 21, 6)) do
			out[#out + 1] = {
				name = string.format("cobble_%s_%02d", column.name, index),
				lx = column.lx,
				lz = lz,
				size = Data.SLAB.cobbleSide,
			}
		end
	end
	return out
end

-- Drainage channels hug the four building edges one stud inside the footprint. They are flat and
-- shallow; no terrain is carved. Five segments per horizontal edge, four per vertical edge.
local function makeGutters(): { any }
	local out = {}
	for _, row in ipairs({ { name = "n", lz = -(halfD - 1) }, { name = "s", lz = halfD - 1 } }) do
		for index, lx in ipairs({ -24, -12, 0, 12, 24 }) do
			out[#out + 1] = {
				name = string.format("gutter_%s_%02d", row.name, index),
				lx = lx,
				lz = row.lz,
				size = Data.SLAB.gutterStraight,
			}
		end
	end
	for _, column in ipairs({ { name = "w", lx = -(halfW - 1) }, { name = "e", lx = halfW - 1 } }) do
		for index, lz in ipairs({ -18, -6, 6, 18 }) do
			out[#out + 1] = {
				name = string.format("gutter_%s_%02d", column.name, index),
				lx = column.lx,
				lz = lz,
				size = Data.SLAB.gutterSide,
			}
		end
	end
	return out
end

local pavingRecipes = makePaving()
local cobbleRecipes = makeCobble()
local gutterRecipes = makeGutters()

function Data.pavingStones(): { any }
	return table.clone(pavingRecipes)
end

function Data.cobblePatches(): { any }
	return table.clone(cobbleRecipes)
end

function Data.gutters(): { any }
	return table.clone(gutterRecipes)
end

-- The lane as a local rectangle; the harness maps each corner through MapSpec.hubPoint(hubPasar, ...)
-- before testing staged parts against the resulting world AABB.
function Data.lane(): { lx: number, lz: number, width: number, depth: number }
	return {
		lx = Data.LANE.lx,
		lz = Data.LANE.lz,
		width = Data.LANE.width,
		depth = Data.LANE.depth,
	}
end

function Data.laneCorners(): { { lx: number, lz: number } }
	local lane = Data.lane()
	local minX, maxX = lane.lx - lane.width / 2, lane.lx + lane.width / 2
	local minZ, maxZ = lane.lz - lane.depth / 2, lane.lz + lane.depth / 2
	return {
		{ lx = minX, lz = minZ },
		{ lx = maxX, lz = minZ },
		{ lx = minX, lz = maxZ },
		{ lx = maxX, lz = maxZ },
	}
end

function Data.counts(): { [string]: number }
	return {
		paving = #pavingRecipes,
		cobble = #cobbleRecipes,
		gutter = #gutterRecipes,
		pavingCount = #pavingRecipes + #cobbleRecipes,
		total = #pavingRecipes + #cobbleRecipes + #gutterRecipes,
	}
end

return Data
