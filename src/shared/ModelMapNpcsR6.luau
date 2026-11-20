--!nocheck
-- ModelMapNpcsR6: PURE DATA for the OFF-BY-DEFAULT "npcs_r6" LookDev candidate
-- (WORK_QUEUE item 48, role-specific textured R15 villagers). No Roblox APIs, no
-- engine types: colours are plain { r, g, b } triples and every hat entry is
-- REQUIRED from ModelMapNpcsR5, so no hat ID is duplicated or invented here.
--
-- The ten costume Image IDs are copied EXACTLY from
-- docs/v2/visual/art/models_r6/npcs/upload_manifest.json (see costumeSource). They
-- are Image IDs, so the applier sets Shirt.ShirtTemplate / Pants.PantsTemplate:
-- HumanoidDescription.Shirt/Pants do not accept Image IDs.
--
-- Facing: the 2026-11-20 Studio review saw the R5 villagers' BACKS at ry = 0 while
-- the saved camera sits at z = 28 looking toward z = 8. Every slot therefore
-- starts from a 180-degree flip (math.pi) with a small per-role jitter; the group
-- faces the camera without reading as one uniform row.

local R5 = require(script.Parent.ModelMapNpcsR5)
local R5_FAMILY = R5.families.npcs_r5

local ModelMapNpcsR6 = {}

ModelMapNpcsR6.familyId = "npcs_r6"
ModelMapNpcsR6.costumeSource = "models_r6/npcs/upload_manifest.json"
ModelMapNpcsR6.groundY = R5.groundY
ModelMapNpcsR6.PLAYER_HEIGHT = R5.PLAYER_HEIGHT
ModelMapNpcsR6.facingFlip = math.pi

-- Image IDs from costumeSource: one shirt + one pants per role, ten in total.
local COSTUMES = {
	polisi = { shirt = 113212316103784, pants = 98102154190902 },
	pak_rt = { shirt = 117485364703264, pants = 127593796770640 },
	petani = { shirt = 112086829394587, pants = 130876277340560 },
	pedagang = { shirt = 71100897124673, pants = 139244403929211 },
	petani_wanita = { shirt = 105653588811968, pants = 76370296974052 },
}

-- R5 has no pak_rt role: its village-elder role tukang_peci supplies the body
-- colours. No new colour table is written here.
local ROLE_SOURCES = {
	polisi = "polisi",
	pak_rt = "tukang_peci",
	petani = "petani",
	pedagang = "pedagang",
	petani_wanita = "petani_wanita",
}

-- Only roles that genuinely had a real R5 hat Model get one. caping is a farmer's
-- conical hat, never a peci; pak_rt is batik-only (see designerBuilds).
local HATS = {
	polisi = "polisi_cap",
	petani = "caping",
	petani_wanita = "caping",
}

-- Small deviations from math.pi so the five figures do not look like one queue.
local YAW_JITTER = {
	petani = -0.06,
	pedagang = 0.03,
	petani_wanita = 0.07,
	pak_rt = -0.03,
	polisi = 0.05,
}

local function makeRole(id)
	local source = R5_FAMILY.roles[ROLE_SOURCES[id]]
	local costume = COSTUMES[id]
	return {
		id = id,
		sourceRole = ROLE_SOURCES[id],
		skin = source.skin,
		shirt = source.shirt,
		pants = source.pants,
		shirtId = costume.shirt,
		pantsId = costume.pants,
		hat = HATS[id],
	}
end

ModelMapNpcsR6.roles = {
	polisi = makeRole("polisi"),
	pak_rt = makeRole("pak_rt"),
	petani = makeRole("petani"),
	pedagang = makeRole("pedagang"),
	petani_wanita = makeRole("petani_wanita"),
}

ModelMapNpcsR6.roleIds = { "polisi", "pak_rt", "petani", "pedagang", "petani_wanita" }

-- Hat Models reused from R5. The applier calls InsertService:LoadAsset with hat.id
-- and uses the data-defined targetSize/offsetY only in the BasePart fallback.
ModelMapNpcsR6.hats = {
	caping = R5.accessories.caping,
	polisi_cap = R5.accessories.polisi_cap,
}

-- Same plaza row as R5, but every ry is flipped to face the saved camera.
ModelMapNpcsR6.slots = {
	{
		slot = "petani",
		x = -16,
		y = R5.groundY,
		z = 8,
		ry = ModelMapNpcsR6.facingFlip + YAW_JITTER.petani,
		targetHeight = ModelMapNpcsR6.PLAYER_HEIGHT,
	},
	{
		slot = "pedagang",
		x = -8,
		y = R5.groundY,
		z = 8,
		ry = ModelMapNpcsR6.facingFlip + YAW_JITTER.pedagang,
		targetHeight = ModelMapNpcsR6.PLAYER_HEIGHT,
	},
	{
		slot = "petani_wanita",
		x = 0,
		y = R5.groundY,
		z = 8,
		ry = ModelMapNpcsR6.facingFlip + YAW_JITTER.petani_wanita,
		targetHeight = ModelMapNpcsR6.PLAYER_HEIGHT,
	},
	{
		slot = "pak_rt",
		x = 8,
		y = R5.groundY,
		z = 8,
		ry = ModelMapNpcsR6.facingFlip + YAW_JITTER.pak_rt,
		targetHeight = ModelMapNpcsR6.PLAYER_HEIGHT,
	},
	{
		slot = "polisi",
		x = 16,
		y = R5.groundY,
		z = 8,
		ry = ModelMapNpcsR6.facingFlip + YAW_JITTER.polisi,
		targetHeight = ModelMapNpcsR6.PLAYER_HEIGHT,
	},
}

-- Unchanged from R5: the saved review camera looks down the row from +Z.
ModelMapNpcsR6.savedCamera = {
	position = { 0, 7, 28 },
	look = { 0, 2.5, 8 },
}

-- There is NO peci/kopiah hat Model anywhere in the repo, and the caping must
-- not be reused as one. pak_rt is batik fabric only; a real peci is a designer build.
ModelMapNpcsR6.designerBuilds = {
	note = "No peci/kopiah hat Model exists in the repo; pak_rt gets batik fabric only, no caping substitute and no invented ID. Designer build needed for a real peci.",
	roles = { "pak_rt" },
	missing = { "peci/kopiah" },
}

ModelMapNpcsR6.families = {
	npcs_r6 = {
		id = "npcs_r6",
		roles = ModelMapNpcsR6.roles,
		slots = ModelMapNpcsR6.slots,
		savedCamera = ModelMapNpcsR6.savedCamera,
	},
}

return ModelMapNpcsR6
