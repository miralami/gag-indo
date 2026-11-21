--!strict
-- ModelMapLaundryR8: pure data for the OFF-BY-DEFAULT "laundry_r8" LookDev candidate
-- (WORK_QUEUE section N item 115). Washing lines with a sarung, a batik cloth and a kebaya strung
-- between posts BEHIND the Pasar and Tengkulak Gelap houses, plus a hammock and a tikar under each
-- house's +Z front porch. All geometry is ORIGINAL PARTS staged by src/server/World/LookDevLaundryR8.luau:
-- plain RGB colours, real built-in Wood/Fabric material tokens only, no asset IDs, no brand logos,
-- no decals, no terrain edit and no engine API in this module. CLOTH_SWAY is deliberately absent:
-- item 85 (wind_r8) already owns sway and candidates are single-active, so static cloth Parts only.
--
-- SITE derivation: this module copies only the hub footprint depth from MapSpec.HUBS so it stays
-- pure (the applier reads the live MapSpec.hub(key) for x/z/yaw and MapSpec.GROUND_Y). Both hubs
-- keep yaw 0, so local +Z is the door/porch front and local -Z is BEHIND. Each washing line sits at
-- lz = -(halfD + BEHIND_OFFSET) with BEHIND_OFFSET = 5; the two lines of a house are 2 studs apart,
-- so even the nearer cloth face is >4 studs clear of the BackWall plane (-halfD + 0.25). Each
-- hammock/tikar sits under the porch at lz = halfD - PORCH_OFFSET with PORCH_OFFSET = 4, well inside
-- the open +Z front. No new camera: review reuses the existing render path. Visual/designer verdict
-- stays pending.

local Data = {}

Data.id = "laundry_r8"
Data.familyId = "laundry_r8"
Data.folderName = "LookDevLaundryR8_laundry_r8"

Data.stageAttribute = "LookDevLaundryR8"
Data.kindAttribute = "LaundryKind"

Data.KINDS = { "post", "line", "sarung", "batik", "kebaya", "hammock", "tikar" }
Data.CLOTH_KINDS = { "sarung", "batik", "kebaya" }
Data.MIN_PARTS = 40

-- Footprint depth mirrors MapSpec.HUBS (pasar 52, gelap 28); the applier still reads the live hub.
Data.HUB_KEYS = { "pasar", "gelap" }
Data.HUB_MODELS = { pasar = "Pasar", gelap = "TengkulakGelap" }
Data.HUB_DEPTH = { pasar = 52, gelap = 28 }
Data.BEHIND_OFFSET = 5
Data.PORCH_OFFSET = 4
Data.LINE_SPACING = 2

-- Greybox wall names under workspace.World hub Models: BackWall, SideWall, LoftWall, FrontWall.
Data.WALL_NAMES = { "BackWall", "SideWall", "LoftWall", "FrontWall" }

-- Behind is negative local Z (strictly outside the half-depth); porch is positive local Z.
function Data.behindZ(hubKey: string): number
	return -(Data.HUB_DEPTH[hubKey] / 2 + Data.BEHIND_OFFSET)
end

function Data.porchZ(hubKey: string): number
	return Data.HUB_DEPTH[hubKey] / 2 - Data.PORCH_OFFSET
end

-- Plain {r,g,b} arrays; the applier calls Color3.fromRGB. Only real built-in material tokens.
Data.COLOURS = {
	post = { 104, 76, 48 },
	line = { 150, 130, 96 },
	sarung = { 176, 58, 54 },
	batik = { 132, 94, 52 },
	kebaya = { 234, 228, 214 },
	hammock = { 86, 132, 120 },
	rope = { 150, 130, 96 },
	bar = { 104, 76, 48 },
	pillow = { 226, 214, 190 },
	mat = { 196, 168, 108 },
	roller = { 120, 88, 54 },
}
Data.MATERIALS = {
	post = "Wood",
	line = "Wood",
	sarung = "Fabric",
	batik = "Fabric",
	kebaya = "Fabric",
	hammock = "Fabric",
	rope = "Wood",
	bar = "Wood",
	pillow = "Fabric",
	mat = "Fabric",
	roller = "Wood",
}

-- All offsets are site-local. lz is an absolute local hub Z computed from behindZ/porchZ so the
-- spec can prove the cloths sit outside the half-depth and the hammock/tikar sit on the porch.
-- `ly` is measured above MapSpec.GROUND_Y; roll tilts a rope/roller about local Z.
local function part(
	name: string,
	kind: string,
	hub: string,
	lx: number,
	ly: number,
	lz: number,
	size: { number },
	colour: string,
	material: string,
	shape: string?,
	roll: number?
): any
	return {
		name = name,
		kind = kind,
		hub = hub,
		lx = lx,
		ly = ly,
		lz = lz,
		size = size,
		colour = colour,
		material = material,
		shape = shape,
		roll = roll or 0,
	}
end

local recipes: { any } = {}
for _, hub in ipairs(Data.HUB_KEYS) do
	local behind = Data.behindZ(hub)
	local porch = Data.porchZ(hub)

	-- Two washing lines per house, each between two posts with a sarung, a batik cloth and a
	-- kebaya hanging from it. The three cloth colours are plain solid fills; no decals or logos.
	for lineIndex = 0, 1 do
		local lz = behind + lineIndex * Data.LINE_SPACING
		local tag = hub .. "_line" .. (lineIndex + 1)
		for _, side in ipairs({ -1, 1 }) do
			recipes[#recipes + 1] = part(
				tag .. "_post_" .. (side == -1 and "L" or "R"),
				"post",
				hub,
				side * 11,
				4.5,
				lz,
				{ 0.7, 9, 0.7 },
				"post",
				"post"
			)
		end
		recipes[#recipes + 1] = part(tag .. "_line", "line", hub, 0, 8.6, lz, { 22.4, 0.14, 0.14 }, "line", "line")
		recipes[#recipes + 1] =
			part(tag .. "_sarung", "sarung", hub, -6, 6.0, lz, { 3.2, 5.2, 0.12 }, "sarung", "sarung")
		recipes[#recipes + 1] = part(tag .. "_batik", "batik", hub, 0, 6.3, lz, { 3.6, 4.6, 0.12 }, "batik", "batik")
		recipes[#recipes + 1] =
			part(tag .. "_kebaya", "kebaya", hub, 6, 6.5, lz, { 2.6, 4.2, 0.12 }, "kebaya", "kebaya")
	end

	-- Hammock under the porch: a sling on two angled ropes, a spreader bar and a small pillow.
	recipes[#recipes + 1] =
		part(hub .. "_hammock_sling", "hammock", hub, -10, 2.6, porch, { 7, 0.3, 3 }, "hammock", "hammock")
	recipes[#recipes + 1] =
		part(hub .. "_hammock_rope_L", "hammock", hub, -13.2, 5.4, porch, { 0.14, 6, 0.14 }, "rope", "rope", nil, -22)
	recipes[#recipes + 1] =
		part(hub .. "_hammock_rope_R", "hammock", hub, -6.8, 5.4, porch, { 0.14, 6, 0.14 }, "rope", "rope", nil, 22)
	recipes[#recipes + 1] =
		part(hub .. "_hammock_bar", "hammock", hub, -10, 3.0, porch, { 7.4, 0.2, 0.2 }, "bar", "bar")
	recipes[#recipes + 1] =
		part(hub .. "_hammock_pillow", "hammock", hub, -10, 3.1, porch + 1.2, { 1.8, 0.4, 0.9 }, "pillow", "pillow")

	-- Tikar under the same porch: a woven mat with two wooden rollers and two tying cords.
	recipes[#recipes + 1] = part(hub .. "_tikar_mat", "tikar", hub, 10, 0.95, porch, { 7, 0.12, 5 }, "mat", "mat")
	recipes[#recipes + 1] = part(
		hub .. "_tikar_roller_L",
		"tikar",
		hub,
		6.6,
		0.95,
		porch,
		{ 0.5, 5.2, 0.5 },
		"roller",
		"roller",
		"cylinder",
		90
	)
	recipes[#recipes + 1] = part(
		hub .. "_tikar_roller_R",
		"tikar",
		hub,
		13.4,
		0.95,
		porch,
		{ 0.5, 5.2, 0.5 },
		"roller",
		"roller",
		"cylinder",
		90
	)
	recipes[#recipes + 1] =
		part(hub .. "_tikar_tie_L", "tikar", hub, 7.4, 1.1, porch, { 0.15, 0.15, 5.2 }, "rope", "rope")
	recipes[#recipes + 1] =
		part(hub .. "_tikar_tie_R", "tikar", hub, 12.6, 1.1, porch, { 0.15, 0.15, 5.2 }, "rope", "rope")
end

function Data.parts(): { any }
	return table.clone(recipes)
end

function Data.isCloth(recipe: any): boolean
	for _, kind in ipairs(Data.CLOTH_KINDS) do
		if recipe.kind == kind then
			return true
		end
	end
	return false
end

function Data.counts(): { [string]: number }
	local out: { [string]: number } = {}
	for _, kind in ipairs(Data.KINDS) do
		out[kind] = 0
	end
	for _, recipe in ipairs(recipes) do
		out[recipe.kind] = (out[recipe.kind] or 0) + 1
	end
	out.total = #recipes
	return out
end

return Data
