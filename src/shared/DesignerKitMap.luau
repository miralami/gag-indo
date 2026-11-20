--!strict
-- DesignerKitMap: pure data for WORK_QUEUE item 49 (designer kit, no spawn dressing).
-- Every id, target height and role colour is read by requiring an existing source map:
-- no engine API, no engine type, no asset ID literal, no world position. The Studio-only
-- builder (src/server/World/DesignerKitBuilder.luau) consumes this table after a manual
-- Command Bar call. Nothing here is a LookDev candidate and nothing is graded.

local VegetationR4 = require(script.Parent.ModelMapVegetationR4)
local PropsR4 = require(script.Parent.ModelMapPropsR4)
local BuildingsR4 = require(script.Parent.ModelMapBuildingsR4)
local NpcsR5 = require(script.Parent.ModelMapNpcsR5)

export type KitItem = {
	name: string, -- Indonesian label used as the instance name
	source: string, -- exact existing map/key that supplies the id or role body colours
	id: number?, -- nil for R15 rigs: they are assembled from role body colours
	targetHeight: number?, -- nil = keep native source scale
	role: any?, -- a roles entry from ModelMapNpcsR5, never a costume Image ID
	tier: string?,
	note: string,
}

local NOTE = "Anchored; base pivot at y=0; true to source scale."
local TEMPORARY = NOTE .. " Temporary buildings_r4 placeholder; no look verdict here."

local function slotHeight(map: any, family: string, key: string): number?
	for _, slot in ipairs(map.families[family].slots) do
		if slot.slot == key then
			return slot.targetHeight
		end
	end
	return nil
end

local veg = VegetationR4.families.vegetation_r4
local props = PropsR4.families.props_r4
local buildings = BuildingsR4.families.buildings_r4
local npcs = NpcsR5.families.npcs_r5

local DesignerKitMap = {}

DesignerKitMap.folderName = "DesignerKit"
DesignerKitMap.storage = "ServerStorage"
DesignerKitMap.storageNote = "Studio-only: build() defaults to ServerStorage; nothing is dressed, saved or published."

DesignerKitMap.items = {
	-- Vegetation: pisang, mangga (broadleaf stand-in) and bambu only. No kelapa (V-D4) and no pine.
	{
		name = "Pisang",
		source = "ModelMapVegetationR4.families.vegetation_r4.ids.pisang; slots.pisang.targetHeight",
		id = veg.ids.pisang,
		targetHeight = slotHeight(VegetationR4, "vegetation_r4", "pisang"),
		note = NOTE,
	},
	{
		name = "Mangga",
		source = "ModelMapVegetationR4.families.vegetation_r4.ids.mangga; slots.mangga.targetHeight",
		id = veg.ids.mangga,
		targetHeight = slotHeight(VegetationR4, "vegetation_r4", "mangga"),
		note = NOTE .. " Source is the documented broadleaf stand-in, not a true mango.",
	},
	{
		name = "Bambu",
		source = "ModelMapVegetationR4.families.vegetation_r4.ids.bambu; slots.bambu.targetHeight",
		id = veg.ids.bambu,
		targetHeight = slotHeight(VegetationR4, "vegetation_r4", "bambu"),
		note = NOTE,
	},

	-- Props: the drying line, the contextual karung stack, cart, well and hand tools.
	{
		name = "Jemuran",
		source = "ModelMapPropsR4.families.props_r4.ids.jemuran; slots.jemuran.targetHeight",
		id = props.ids.jemuran,
		targetHeight = slotHeight(PropsR4, "props_r4", "jemuran"),
		note = NOTE,
	},
	{
		name = "Karung semen",
		source = "ModelMapPropsR4.families.props_r4.ids.karung; slots.karung.targetHeight",
		id = props.ids.karung,
		targetHeight = slotHeight(PropsR4, "props_r4", "karung"),
		note = NOTE .. " Stack by the gudang or a renovation spot, not loose at spawn.",
	},
	{
		name = "Gerobak",
		source = "ModelMapPropsR4.families.props_r4.ids.gerobak; slots.gerobak.targetHeight",
		id = props.ids.gerobak,
		targetHeight = slotHeight(PropsR4, "props_r4", "gerobak"),
		note = NOTE,
	},
	{
		name = "Sumur",
		source = "ModelMapPropsR4.families.props_r4.ids.sumur; slots.sumur.targetHeight",
		id = props.ids.sumur,
		targetHeight = slotHeight(PropsR4, "props_r4", "sumur"),
		note = NOTE,
	},
	{
		name = "Alat tani",
		source = "ModelMapPropsR4.families.props_r4.ids.alat_tani; slots.alat_tani.targetHeight",
		id = props.ids.alat_tani,
		targetHeight = slotHeight(PropsR4, "props_r4", "alat_tani"),
		note = NOTE,
	},

	-- Buildings: all four temporary R4 placeholders.
	{
		name = "Rumah panggung",
		source = "ModelMapBuildingsR4.families.buildings_r4.ids.rumah; slots.rumah.targetHeight",
		id = buildings.ids.rumah,
		targetHeight = slotHeight(BuildingsR4, "buildings_r4", "rumah"),
		tier = "temporary",
		note = TEMPORARY,
	},
	{
		name = "Kandang ayam",
		source = "ModelMapBuildingsR4.families.buildings_r4.ids.kandang; slots.kandang.targetHeight",
		id = buildings.ids.kandang,
		targetHeight = slotHeight(BuildingsR4, "buildings_r4", "kandang"),
		tier = "temporary",
		note = TEMPORARY,
	},
	{
		name = "Gudang",
		source = "ModelMapBuildingsR4.families.buildings_r4.ids.gudang; slots.gudang.targetHeight",
		id = buildings.ids.gudang,
		targetHeight = slotHeight(BuildingsR4, "buildings_r4", "gudang"),
		tier = "temporary",
		note = TEMPORARY,
	},
	{
		name = "Warung",
		source = "ModelMapBuildingsR4.families.buildings_r4.ids.warung; slots.warung.targetHeight",
		id = buildings.ids.warung,
		targetHeight = slotHeight(BuildingsR4, "buildings_r4", "warung"),
		tier = "temporary",
		note = TEMPORARY,
	},

	-- Villagers: roles only. The builder assembles R15 rigs from these body colours;
	-- no costume Image ID, no hat ID and no imported body model is read here.
	{
		name = "Petani",
		source = "ModelMapNpcsR5.families.npcs_r5.roles.petani; body colours only, R15 rig",
		role = npcs.roles.petani,
		note = NOTE .. " Native R15 height, built from role body colours only.",
	},
	{
		name = "Pedagang",
		source = "ModelMapNpcsR5.families.npcs_r5.roles.pedagang; body colours only, R15 rig",
		role = npcs.roles.pedagang,
		note = NOTE .. " Native R15 height, built from role body colours only.",
	},
	{
		name = "Petani wanita",
		source = "ModelMapNpcsR5.families.npcs_r5.roles.petani_wanita; body colours only, R15 rig",
		role = npcs.roles.petani_wanita,
		note = NOTE .. " Native R15 height, built from role body colours only.",
	},
	{
		name = "Tukang peci",
		source = "ModelMapNpcsR5.families.npcs_r5.roles.tukang_peci; body colours only, R15 rig",
		role = npcs.roles.tukang_peci,
		note = NOTE .. " Native R15 height, built from role body colours only.",
	},
	{
		name = "Polisi",
		source = "ModelMapNpcsR5.families.npcs_r5.roles.polisi; body colours only, R15 rig",
		role = npcs.roles.polisi,
		note = NOTE .. " Native R15 height, built from role body colours only.",
	},
} :: { KitItem }

-- Advice for the designer's own sculpt. No sculpting, no world placement, no grade.
DesignerKitMap.terrain = {
	"Sawah: 1-2 studs lower than the yard.",
	"Yards: at grade with the main paths.",
	"Warung and pasar: a slight rise toward both.",
	"Drainage ditches: along the paths.",
	"Advice only: no agent sculpts terrain or places anything.",
}

return DesignerKitMap
