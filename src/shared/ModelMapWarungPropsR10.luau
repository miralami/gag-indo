--!strict
-- ModelMapWarungPropsR10: pure data for the OFF-BY-DEFAULT "warung_props_r10" Warung dressing
-- overlay (WORK_QUEUE item 272). Descriptors mirror the warung hub from MapSpec.HUBS (server-only,
-- so it cannot be required here) and every position is a rotation and a fraction of that hub plus
-- the anchor / bench offsets. PURE: no services, Instances, Enum values or visual verdicts.
--
-- ponytail: the Indonesian House Props Kit is NOT baked into ServerStorage.LookDevAssets; the
-- numeric kit id is named in the server applier's ponytail note (this shared map must stay free of
-- unlisted numeric ids for the manifest-coverage guard). MODEL_IDS therefore use live-verified
-- baked substitutes. Upgrade path: the designer bakes the kit into ServerStorage.LookDevAssets,
-- then MODEL_IDS points at that single kit id and the substitute entries are deleted. No runtime
-- fetch, no invented id.

local Data = {}

type Vec3 = { x: number, y: number, z: number }
type RGB = { r: number, g: number, b: number }
type Prop = {
	name: string,
	index: number,
	kind: string,
	position: Vec3,
	size: { number },
	color: RGB,
	shape: string?,
	material: string?,
	centreY: number?, -- plain parts only; baked models use position.y as their bottom
	modelId: number?,
}

Data.id = "warung_props_r10"
Data.folderName = "LookDevWarungPropsR10_warung_props_r10"

-- Attribute names are data so the Studio harness reads exactly what the applier writes.
Data.tagAttribute = "WarungPropR10"
Data.indexAttribute = "warungProp"
Data.kindAttribute = "WarungPropKind"
Data.modelAttribute = "ModelAssetId"

-- Live-verified baked substitutes only. The House Props Kit id is deliberately absent.
Data.MODEL_IDS = {
	BENCH = 1158365955, -- baked bamboo fence: bench / rack frame
	SACK = 16098456067, -- baked stone: sack stand-in
	PLANT = 13286158859, -- baked padi: kendi / lantern-side greenery stand-in
}
Data.ALLOWED_IDS = { 1158365955, 16098456067, 5644862709, 53370997, 13286158859 }
Data.HOUSE_PROPS_KIT_NAME = "Indonesian House Props Kit" -- provenance only; never fetched, never staged

-- Top-level Workspace strays from item 183, visible on the right of canonical_overview. They are
-- saved-place / Play artifacts, not produced by game source; the harness only measures them.
Data.OVERVIEW_STRAY_NAMES = { "GiantyFrog" }

Data.GROUND_Y = 0.5 -- MapSpec.GROUND_Y
Data.MIN_MODEL_PARTS = 1

-- Palette mirrors src/server/World/Props.luau (same swatches, no new colours).
Data.PALETTE_NAMES = { "bambu", "genteng", "kunyit", "merah", "tintaLembut", "daun", "kertas" }
Data.PALETTE = {
	bambu = { r = 185, g = 138, b = 90 },
	genteng = { r = 168, g = 69, b = 47 },
	kunyit = { r = 201, g = 154, b = 46 },
	merah = { r = 168, g = 50, b = 38 },
	tintaLembut = { r = 91, g = 74, b = 56 },
	daun = { r = 111, g = 138, b = 63 },
	kertas = { r = 243, g = 233, b = 210 },
}

-- x, z, yaw, width, depth, anchor and benches copied from MapSpec.HUBS warung.
local HUB = {
	x = 68,
	z = -68,
	yaw = 0,
	width = 52,
	depth = 44,
	anchorLz = 10,
	benches = { -6.4, 6.4 },
}

local function rotate(lx: number, lz: number): Vec3
	local a = math.rad(HUB.yaw)
	local cos, sin = math.cos(a), math.sin(a)
	return {
		x = HUB.x + lx * cos + lz * sin,
		y = Data.GROUND_Y,
		z = HUB.z - lx * sin + lz * cos,
	}
end

local function rgb(value: RGB): RGB
	return { r = value.r, g = value.g, b = value.b }
end

local function sizeOf(value: { number }): { number }
	return { value[1], value[2], value[3] }
end

-- Four prop groups: bench (baked frame + plain seat), kendi (baked greenery + plain jug),
-- lantern (plain post + glow), sacks (two baked stones). Every local x is outboard of the 6-stud
-- door lane (|lx| >= 9.4) and every local z stays in front of the anchor but short of the lane
-- (12..16 < 22), so no prop enters the Warung's own or any other hub's door lane.
function Data.props(): { Prop }
	local benchX = -(math.abs(HUB.benches[1]) + 8)
	local kendiX = benchX + 5
	local lanternX = math.abs(HUB.benches[2]) + 8
	local sackX = lanternX - 3.9
	return {
		{
			name = "WarungPropBenchFrame",
			index = 1,
			kind = "bench",
			position = rotate(benchX, HUB.anchorLz + 3),
			size = sizeOf({ 8, 2.4, 2 }),
			color = rgb(Data.PALETTE.bambu),
			modelId = Data.MODEL_IDS.BENCH,
		},
		{
			name = "WarungPropBenchSeat",
			index = 2,
			kind = "bench",
			position = rotate(benchX, HUB.anchorLz + 3),
			size = sizeOf({ 8, 0.4, 2 }),
			color = rgb(Data.PALETTE.bambu),
			shape = "Block",
			material = "WoodPlanks",
			centreY = Data.GROUND_Y + 2.4 + 0.2,
		},
		{
			name = "WarungPropKendiStand",
			index = 3,
			kind = "kendi",
			position = rotate(kendiX, HUB.anchorLz + 6),
			size = sizeOf({ 2.4, 3, 2.4 }),
			color = rgb(Data.PALETTE.daun),
			modelId = Data.MODEL_IDS.PLANT,
		},
		{
			name = "WarungPropKendiBody",
			index = 4,
			kind = "kendi",
			position = rotate(kendiX, HUB.anchorLz + 6),
			size = sizeOf({ 1.6, 2, 1.6 }),
			color = rgb(Data.PALETTE.kunyit),
			shape = "Cylinder",
			material = "Metal",
			centreY = Data.GROUND_Y + 3 + 1,
		},
		{
			name = "WarungPropLanternPost",
			index = 5,
			kind = "lantern",
			position = rotate(lanternX, HUB.anchorLz + 5),
			size = sizeOf({ 0.5, 7, 0.5 }),
			color = rgb(Data.PALETTE.tintaLembut),
			shape = "Block",
			material = "Wood",
			centreY = Data.GROUND_Y + 7 / 2,
		},
		{
			name = "WarungPropLanternBody",
			index = 6,
			kind = "lantern",
			position = rotate(lanternX, HUB.anchorLz + 5),
			size = sizeOf({ 1.6, 1.6, 1.6 }),
			color = rgb(Data.PALETTE.kunyit),
			shape = "Ball",
			material = "Neon",
			centreY = Data.GROUND_Y + 7.4,
		},
		{
			name = "WarungPropSackL",
			index = 7,
			kind = "sacks",
			position = rotate(sackX - 1.2, HUB.anchorLz + 2),
			size = sizeOf({ 2, 1.6, 2 }),
			color = rgb(Data.PALETTE.kertas),
			modelId = Data.MODEL_IDS.SACK,
		},
		{
			name = "WarungPropSackR",
			index = 8,
			kind = "sacks",
			position = rotate(sackX + 1.2, HUB.anchorLz + 2),
			size = sizeOf({ 2, 1.6, 2 }),
			color = rgb(Data.PALETTE.kertas),
			modelId = Data.MODEL_IDS.SACK,
		},
	}
end

-- Load-time contract: keeps the recipe honest before any applier or harness reads it.
do
	local props = Data.props()
	local models, shapes = 0, 0
	local allowed = {}
	for _, id in ipairs(Data.ALLOWED_IDS) do
		allowed[id] = true
	end
	for _, prop in ipairs(props) do
		if prop.modelId then
			models += 1
			assert(allowed[prop.modelId] == true, "warung_props_r10: unbaked / invented model id")
			assert(type(prop.modelId) == "number", "warung_props_r10: un-baked kit id staged")
		else
			shapes += 1
			assert(
				prop.shape ~= nil and prop.material ~= nil and type(prop.centreY) == "number",
				"warung_props_r10: plain prop missing shape / height"
			)
		end
		for _, coordinate in ipairs({ prop.position.x, prop.position.y, prop.position.z }) do
			assert(coordinate == coordinate and math.abs(coordinate) < math.huge, "warung_props_r10: bad position")
		end
		for _, dimension in ipairs(prop.size) do
			assert(dimension > 0, "warung_props_r10: non-positive size")
		end
		for _, channel in ipairs({ prop.color.r, prop.color.g, prop.color.b }) do
			assert(channel >= 0 and channel <= 255, "warung_props_r10: colour channel outside 0..255")
		end
	end
	assert(models >= Data.MIN_MODEL_PARTS and shapes > 0, "warung_props_r10: missing model or plain props")
	assert(Data.OVERVIEW_STRAY_NAMES[1] == "GiantyFrog", "warung_props_r10: stray name contract changed")
end

return Data
