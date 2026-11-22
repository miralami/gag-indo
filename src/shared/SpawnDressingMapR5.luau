--!strict
-- SpawnDressingMapR5: PURE DATA for the OFF-BY-DEFAULT "spawn_r5" LookDev candidate
-- (WORK_QUEUE item 41, spawn dressing pass). No Roblox APIs, no engine types, no instances and
-- no ID literals: every position and every numeric ID is read at require time from the four
-- already-approved / temporary source maps. The Env harness can require this module under Lune.
--
-- Composition: only buildings_r4 (temporary) gudang + warung, props_r5 (jemuran, the contextual
-- gudang karung stack, gerobak/sumur/lapak/pagar_bambu/alat_tani), the approved pisang + dense
-- bamboo slots from ModelMapVegetationR5, and the five R15 roles from ModelMapNpcsR5. No kelapa,
-- no pine and no mangga stand-in are placed. Triangle figures are planning ESTIMATES from
-- docs/v2/visual/SPAWN_DRESSING.md section 3, not measurements. Off by default; no verdict here.

local Buildings = require(script.Parent.ModelMapBuildingsR4)
local Props = require(script.Parent.ModelMapPropsR5)
local Vegetation = require(script.Parent.ModelMapVegetationR5)
local Npcs = require(script.Parent.ModelMapNpcsR5)

export type Entry = {
	slot: string, -- unique-ish staging name
	kind: "model" | "rig",
	source: "buildings" | "props" | "vegetation" | "npcs",
	key: string, -- slot / role key into the source module
	x: number,
	y: number,
	z: number,
	ry: number,
	rotX: number,
	targetHeight: number,
	scale: number?, -- props only; verbatim from the source slot
	footprint: { halfX: number, halfZ: number }?, -- trees only; verbatim from the source slot
	isTree: boolean?,
	landmark: boolean?, -- triangle estimate uses the landmark rate
	yOffset: number?, -- top karung sack lifted onto the stack
	tier: string, -- minimum tier at which this entry appears
	cluster: "A" | "B" | "C",
}

local SpawnDressingMapR5 = {}

SpawnDressingMapR5.id = "spawn_r5"
SpawnDressingMapR5.groundY = 0.5

-- Saved review camera: on +Z of SPAWN, inside MapSpec.TERRAIN_HALF, high enough to clear the
-- NPC row at z=8 and see the buildings row at z=20 plus the plaza apron in one frame.
SpawnDressingMapR5.camera = {
	position = { 0, 20, 72 },
	lookAt = { 0, 5, 14 },
	derivedFrom = "+Z of SPAWN, inside MapSpec.TERRAIN_HALF; sees buildings row z=20, NPC row z=8, plaza apron",
}

-- SPAWN_DRESSING.md section 3: a planning slice of the global draw / triangle cap, not a measurement.
SpawnDressingMapR5.budgets = {
	Rendah = { instances = 50, triangles = 50000 },
	Sedang = { instances = 100, triangles = 100000 },
	Tinggi = { instances = 150, triangles = 150000 },
}

SpawnDressingMapR5.TRI_PER_KIT = 2000
SpawnDressingMapR5.TRI_PER_LANDMARK = 8000
SpawnDressingMapR5.tiers = { "Rendah", "Sedang", "Tinggi" }

local TIER_RANK = { Rendah = 1, Sedang = 2, Tinggi = 3 }

function SpawnDressingMapR5.tierRank(tier: string?): number
	return if type(tier) == "string" and (TIER_RANK :: any)[tier] then (TIER_RANK :: any)[tier] else 0
end

-- The 28-wide north road (MapSpec north arm) must stay free of tree trunks: the first spawn frame
-- looks straight down it. Every tree entry below is passed through this test before it is kept.
function SpawnDressingMapR5.inNorthCorridor(x: number, z: number): boolean
	return x >= -14 and x <= 14 and z <= 42 and z >= -136
end

local GROUND = SpawnDressingMapR5.groundY
local entries: { Entry } = {}

local function addTree(entry: Entry)
	if SpawnDressingMapR5.inNorthCorridor(entry.x, entry.z) then
		return
	end
	entries[#entries + 1] = entry
end

-- Buildings: only the two temporary landmarks. Positions/rotation/height stay verbatim.
local BUILDING_PLAN = {
	gudang = { tier = "Rendah", cluster = "B" },
	warung = { tier = "Rendah", cluster = "C" },
}
for _, slot in ipairs(Buildings.families.buildings_r4.slots) do
	local plan = (BUILDING_PLAN :: any)[slot.slot]
	if plan then
		entries[#entries + 1] = {
			slot = slot.slot,
			kind = "model",
			source = "buildings",
			key = slot.slot,
			x = slot.x,
			y = GROUND,
			z = slot.z,
			ry = slot.ry,
			rotX = slot.rotX or 0,
			targetHeight = slot.targetHeight,
			landmark = true,
			tier = plan.tier,
			cluster = plan.cluster,
		}
	end
end

-- Props: jemuran stays exactly at its source scale; the rest keep their R5 source scales.
local propsFamily = Props.families.props_r5
local PROP_PLAN = {
	jemuran = { tier = "Rendah", cluster = "B" },
	gerobak = { tier = "Sedang", cluster = "B" },
	lapak = { tier = "Sedang", cluster = "C" },
	sumur = { tier = "Tinggi", cluster = "B" },
	pagar_bambu = { tier = "Tinggi", cluster = "B" },
	alat_tani = { tier = "Tinggi", cluster = "C" },
}
for _, slot in ipairs(propsFamily.slots) do
	local plan = (PROP_PLAN :: any)[slot.slot]
	if plan then
		entries[#entries + 1] = {
			slot = slot.slot,
			kind = "model",
			source = "props",
			key = slot.slot,
			x = slot.x,
			y = GROUND,
			z = slot.z,
			ry = slot.ry,
			rotX = slot.rotX,
			targetHeight = slot.targetHeight,
			scale = slot.scale,
			tier = plan.tier,
			cluster = plan.cluster,
		}
	end
end

-- Contextual karung: four sacks on the gudang's +Z apron, source dx/dz added to the group anchor
-- and source dy carried as yOffset. Same flat entry shape as every other model.
local karung = propsFamily.karung
for index, sack in ipairs(karung.stack) do
	entries[#entries + 1] = {
		slot = "karung_" .. index,
		kind = "model",
		source = "props",
		key = karung.slot,
		x = karung.x + sack.dx,
		y = GROUND,
		z = karung.z + sack.dz,
		ry = karung.ry + sack.ry,
		rotX = karung.rotX,
		targetHeight = karung.targetHeight,
		scale = karung.scale,
		yOffset = sack.dy,
		tier = "Rendah",
		cluster = "B",
	}
end

-- Vegetation: three pisang from the A cluster (Rendah) plus the C/A-edge stalk at (-30, 56)
-- (Sedang), and two FULL dense bamboo clumps (A at Sedang, C at Tinggi). mangga_standin and
-- the disabled kelapa reference are never iterated. Footprints are copied from the source slots.
local PISANG_TIER = { A = "Rendah", C = "Sedang" }
local PISANG_LIMIT = { A = 3, C = 1 }
local BAMBU_TIER = { A = "Sedang", C = "Tinggi" }
local pisangTaken = { A = 0, C = 0 }
for _, group in ipairs(Vegetation.groups) do
	if group.id == "pisang_clusters" then
		for index, slot in ipairs(group.slots) do
			local tier = (PISANG_TIER :: any)[slot.cluster]
			if tier and pisangTaken[slot.cluster] < (PISANG_LIMIT :: any)[slot.cluster] then
				pisangTaken[slot.cluster] += 1
				addTree({
					slot = slot.slot .. "_" .. slot.cluster .. "_" .. index,
					kind = "model",
					source = "vegetation",
					key = slot.slot,
					x = slot.x,
					y = GROUND,
					z = slot.z,
					ry = slot.ry,
					rotX = slot.rotX or 0,
					targetHeight = slot.targetHeight,
					footprint = {
						halfX = slot.footprint.halfX,
						halfZ = slot.footprint.halfZ,
					},
					isTree = true,
					tier = tier,
					cluster = slot.cluster,
				})
			end
		end
	elseif group.id == "bambu_clumps" then
		for index, slot in ipairs(group.slots) do
			local tier = (BAMBU_TIER :: any)[slot.cluster]
			if tier then
				addTree({
					slot = slot.slot .. "_" .. slot.cluster .. "_" .. index,
					kind = "model",
					source = "vegetation",
					key = slot.slot,
					x = slot.x,
					y = GROUND,
					z = slot.z,
					ry = slot.ry,
					rotX = slot.rotX or 0,
					targetHeight = slot.targetHeight,
					footprint = {
						halfX = slot.footprint.halfX,
						halfZ = slot.footprint.halfZ,
					},
					isTree = true,
					tier = tier,
					cluster = slot.cluster,
				})
			end
		end
	end
end

-- Characters: all five R15 roles. petani + polisi are the Rendah silhouettes; the other three
-- arrive at Sedang. Coordinates come verbatim from the npcs_r5 row, including its y.
local NPC_PLAN = {
	petani = { tier = "Rendah", cluster = "A" },
	pedagang = { tier = "Sedang", cluster = "A" },
	petani_wanita = { tier = "Sedang", cluster = "B" },
	tukang_peci = { tier = "Sedang", cluster = "B" },
	polisi = { tier = "Rendah", cluster = "C" },
}
for _, slot in ipairs(Npcs.families.npcs_r5.slots) do
	local plan = (NPC_PLAN :: any)[slot.slot]
	if plan then
		entries[#entries + 1] = {
			slot = slot.slot,
			kind = "rig",
			source = "npcs",
			key = slot.slot,
			x = slot.x,
			y = slot.y,
			z = slot.z,
			ry = slot.ry,
			rotX = 0, -- rigs are upright; the applier never tilts them
			targetHeight = slot.targetHeight,
			tier = plan.tier,
			cluster = plan.cluster,
		}
	end
end

SpawnDressingMapR5.entries = entries

function SpawnDressingMapR5.entriesForTier(tier: string?): { Entry }
	local limit = SpawnDressingMapR5.tierRank(tier)
	local out = {}
	for _, entry in ipairs(entries) do
		if SpawnDressingMapR5.tierRank(entry.tier) <= limit then
			out[#out + 1] = entry
		end
	end
	return out
end

function SpawnDressingMapR5.countForTier(tier: string?): number
	return #SpawnDressingMapR5.entriesForTier(tier)
end

function SpawnDressingMapR5.estimateTrianglesForTier(tier: string?): number
	local total = 0
	for _, entry in ipairs(SpawnDressingMapR5.entriesForTier(tier)) do
		total += if entry.landmark then SpawnDressingMapR5.TRI_PER_LANDMARK else SpawnDressingMapR5.TRI_PER_KIT
	end
	return total
end

-- Rigs have no model ID: their body comes from a HumanoidDescription. Unknown keys return nil.
function SpawnDressingMapR5.idFor(entry: Entry): number?
	if entry.kind ~= "model" then
		return nil
	end
	if entry.source == "buildings" then
		return Buildings.families.buildings_r4.ids[entry.key]
	elseif entry.source == "props" then
		return propsFamily.ids[entry.key]
	elseif entry.source == "vegetation" then
		return Vegetation.ids[entry.key]
	end
	return nil
end

-- Accept either a role table (the applier's form) or a role key (the spec's convenience form).
function SpawnDressingMapR5.accessoryFor(role: any): any?
	local roleTable = role
	if type(role) == "string" then
		roleTable = Npcs.families.npcs_r5.roles[role]
	end
	if type(roleTable) ~= "table" or not roleTable.hat then
		return nil
	end
	return Npcs.accessories[roleTable.hat]
end

-- Data-level enforcement: no tree in the first-frame north corridor, and every tier inside its
-- instance / triangle budget. The spec repeats both checks at runtime.
for _, entry in ipairs(entries) do
	assert(
		not entry.isTree or not SpawnDressingMapR5.inNorthCorridor(entry.x, entry.z),
		"spawn_r5: tree entry inside the north corridor: " .. entry.slot
	)
end
for _, tier in ipairs(SpawnDressingMapR5.tiers) do
	local budget = SpawnDressingMapR5.budgets[tier]
	assert(SpawnDressingMapR5.countForTier(tier) <= budget.instances, "spawn_r5: instance budget exceeded at " .. tier)
	assert(
		SpawnDressingMapR5.estimateTrianglesForTier(tier) <= budget.triangles,
		"spawn_r5: triangle budget exceeded at " .. tier
	)
end

return SpawnDressingMapR5
