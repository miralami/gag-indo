--!strict
-- ModelMapRondaTowerR9: pure data for the OFF-BY-DEFAULT "ronda_tower_r9" LookDev candidate
-- (WORK_QUEUE section O item 150). Pos Ronda watchtower at the MapSpec.RONDA_TOWER (x,z) position,
-- rebuilt to the brief height (28-32 studs) on an 8x8 bamboo base with a kentongan at the top and a
-- ladder up one side. No asset IDs, no brand, no engine APIs except the MapSpec require.
--
-- The staged candidate is built OVER the greybox tower; the greybox is left untouched. Every part
-- offset is relative to the tower base centre at MapSpec.GROUND_Y. The applier resolves the world
-- position, so no world-coordinate literals live here.

local MapSpec = require(game:GetService("ServerScriptService"):WaitForChild("Server").World.MapSpec)

local Data = {}

Data.id = "ronda_tower_r9"
Data.familyId = "ronda_tower_r9"
Data.folderName = "LookDevRondaTowerR9_ronda_tower_r9"

Data.stageAttribute = "LookDevRondaTowerR9"
Data.towerAttribute = "RondaTower"
Data.legAttribute = "TowerLeg"
Data.deckAttribute = "TowerDeck"
Data.roofAttribute = "TowerRoof"
Data.kentonganAttribute = "Kentongan"
Data.ladderAttribute = "Ladder"

-- RECONCILIATION.md row 6: MAP_SPEC position, brief height. MapSpec.RONDA_TOWER.height stays 36
-- for the greybox; the candidate uses the brief's 28-32 instead and never mutates MapSpec.
Data.HEIGHT = 30
Data.DECK = { width = 8, depth = 8, thickness = 0.5 }
Data.LEG = { size = 0.9, spread = 3.4 }
Data.ROOF = { rise = 2.5, overhang = 0.5, thickness = 0.25, eaveGap = 0.8 }
Data.KENTONGAN = { x = -1.8, z = -2.2, lift = 0.4, length = 3, diameter = 1 }
Data.LADDER = { z = 4.5, halfGap = 0.9, railSize = 0.35, rungCount = 13, rungSize = { 2.1, 0.25, 0.3 } }

Data.COLOURS = {
	bamboo = { 176, 158, 94 },
	bambooDark = { 112, 96, 52 },
	deck = { 156, 132, 76 },
	roof = { 86, 124, 72 },
	kentongan = { 150, 118, 62 },
	slit = { 42, 30, 18 },
	ladder = { 168, 148, 86 },
}

Data.MATERIALS = {
	bamboo = "Wood",
	deck = "WoodPlanks",
	roof = "Grass",
	kentongan = "Wood",
	slit = "SmoothPlastic",
	ladder = "Wood",
}

function Data.config()
	return {
		id = Data.id,
		folderName = Data.folderName,
		stageAttribute = Data.stageAttribute,
		towerAttribute = Data.towerAttribute,
		x = MapSpec.RONDA_TOWER.x,
		z = MapSpec.RONDA_TOWER.z,
		baseY = MapSpec.GROUND_Y,
		height = Data.HEIGHT,
	}
end

function Data.height(): number
	return Data.HEIGHT
end

-- The four-leg collective footprint. Spread is centre-to-centre; leg size adds one half on each
-- side: 3.4 * 2 + 0.9 = 7.7, under the 8x8 brief (and well under the harness +1 tolerance).
function Data.baseSize()
	return {
		width = Data.LEG.spread * 2 + Data.LEG.size,
		depth = Data.LEG.spread * 2 + Data.LEG.size,
		spread = Data.LEG.spread,
		legSize = Data.LEG.size,
	}
end

-- Roof geometry: a two-panel pitched cap. The eave is set back by the panel's projected
-- half-thickness so the world bbox top lands on `height` instead of a fraction above it.
local roofHalfDepth = Data.DECK.depth / 2 + Data.ROOF.overhang
local roofSlope = math.sqrt(roofHalfDepth ^ 2 + Data.ROOF.rise ^ 2)
local roofAngle = math.deg(math.atan2(Data.ROOF.rise, roofHalfDepth))
local roofThicknessLift = Data.ROOF.thickness / 2 * (roofHalfDepth / roofSlope)
local eaveY = Data.HEIGHT - Data.ROOF.rise - roofThicknessLift
local deckTopY = eaveY - Data.ROOF.eaveGap
local deckBottomY = deckTopY - Data.DECK.thickness

local function part(name, attribute, size, x, y, z, colour, material, rotation, shape)
	return {
		name = name,
		attribute = attribute,
		size = size,
		x = x,
		y = y,
		z = z,
		colour = colour,
		material = material,
		rotation = rotation or { 0, 0, 0 },
		shape = shape or "Block",
	}
end

-- One flat list of original-Part recipes. The applier only walks this list; it holds no geometry
-- literals of its own. Kentongan and ladder sit below the roof, so the model bbox top is the roof.
function Data.parts()
	local out = {}

	for _, dx in ipairs({ -Data.LEG.spread, Data.LEG.spread }) do
		for _, dz in ipairs({ -Data.LEG.spread, Data.LEG.spread }) do
			out[#out + 1] = part(
				"TowerLeg",
				Data.legAttribute,
				{ Data.LEG.size, deckBottomY, Data.LEG.size },
				dx,
				deckBottomY / 2,
				dz,
				"bamboo",
				"bamboo"
			)
		end
	end

	out[#out + 1] = part(
		"TowerDeck",
		Data.deckAttribute,
		{ Data.DECK.width, Data.DECK.thickness, Data.DECK.depth },
		0,
		deckBottomY + Data.DECK.thickness / 2,
		0,
		"deck",
		"deck"
	)

	for index, sign in ipairs({ -1, 1 }) do
		out[#out + 1] = part(
			string.format("TowerRoof_%02d", index),
			Data.roofAttribute,
			{ Data.DECK.width + Data.ROOF.overhang * 2, Data.ROOF.thickness, roofSlope },
			0,
			eaveY + Data.ROOF.rise / 2,
			sign * roofHalfDepth / 2,
			"roof",
			"roof",
			{ sign * roofAngle, 0, 0 }
		)
	end

	local k = Data.KENTONGAN
	out[#out + 1] = part(
		"Kentongan",
		Data.kentonganAttribute,
		{ k.length, k.diameter, k.diameter },
		k.x,
		eaveY + k.lift,
		k.z,
		"kentongan",
		"kentongan",
		{ 0, 0, 90 },
		"Cylinder"
	)
	out[#out + 1] = part(
		"KentonganSlit",
		Data.kentonganAttribute,
		{ k.length * 0.8, 0.08, 0.16 },
		k.x,
		eaveY + k.lift + k.diameter / 2 + 0.03,
		k.z,
		"slit",
		"slit"
	)

	local ladder = Data.LADDER
	for _, side in ipairs({ -1, 1 }) do
		out[#out + 1] = part(
			"LadderRail",
			Data.ladderAttribute,
			{ ladder.railSize, deckTopY, ladder.railSize },
			side * ladder.halfGap,
			deckTopY / 2,
			ladder.z,
			"ladder",
			"ladder"
		)
	end
	for index = 1, ladder.rungCount do
		local y = 1.8 + (index - 1) * ((deckTopY - 0.8 - 1.8) / math.max(ladder.rungCount - 1, 1))
		out[#out + 1] = part(
			string.format("LadderRung_%02d", index),
			Data.ladderAttribute,
			ladder.rungSize,
			0,
			y,
			ladder.z,
			"ladder",
			"ladder"
		)
	end

	return out
end

function Data.counts()
	local byAttribute = {}
	for _, recipe in ipairs(Data.parts()) do
		byAttribute[recipe.attribute] = (byAttribute[recipe.attribute] or 0) + 1
	end
	return {
		legs = byAttribute[Data.legAttribute] or 0,
		deck = byAttribute[Data.deckAttribute] or 0,
		roof = byAttribute[Data.roofAttribute] or 0,
		kentongan = byAttribute[Data.kentonganAttribute] or 0,
		ladder = byAttribute[Data.ladderAttribute] or 0,
		total = #Data.parts(),
	}
end

return Data
