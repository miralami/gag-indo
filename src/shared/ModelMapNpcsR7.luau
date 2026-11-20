--!nocheck
-- ModelMapNpcsR7: PURE DATA for the OFF-BY-DEFAULT "npcs_r7" LookDev candidate
-- (WORK_QUEUE item 56). No Roblox APIs, no engine types; colours are plain
-- { r, g, b } triples. Body colours, hat Models, yaw jitter and saved camera come
-- from ModelMapNpcsR6/R5 so no verified asset ID is duplicated or invented here.
--
-- Six costume Image IDs are copied EXACTLY from ModelMapNpcsR6. Four were replaced
-- with the real R7 PNG uploads recorded in costumeUploads and in
-- docs/v2/visual/art/models_r7/npcs/upload_manifest.json. Never guess an ID.

local R6 = require(script.Parent.ModelMapNpcsR6)
local R5 = require(script.Parent.ModelMapNpcsR5)

local ModelMapNpcsR7 = {}

ModelMapNpcsR7.familyId = "npcs_r7"
ModelMapNpcsR7.lookDevId = "npcs_r7"
ModelMapNpcsR7.costumeSource = "Shared.ModelMapNpcsR6"
ModelMapNpcsR7.groundY = R5.groundY
ModelMapNpcsR7.PLAYER_HEIGHT = R5.PLAYER_HEIGHT
ModelMapNpcsR7.facingFlip = R6.facingFlip

-- Verified Image IDs from ModelMapNpcsR6. Shirt/Pants templates take Image IDs
-- directly; HumanoidDescription.Shirt/Pants do not, so they are never touched.
local COSTUMES = {
	polisi = { shirt = 133590758790821, pants = 98235919851901 },
	pak_rt = { shirt = 92996938301042, pants = 127593796770640 },
	petani = { shirt = 81581201405716, pants = 130876277340560 },
	pedagang = { shirt = 71100897124673, pants = 139244403929211 },
	petani_wanita = { shirt = 105653588811968, pants = 76370296974052 },
}

-- The four R7 PNGs uploaded as Images on 2026-11-20. Each assetId is the value
-- returned by a completed Open Cloud operation (see upload_manifest.json) and is
-- the value now used in COSTUMES above. replacedR6Id records the placeholder it
-- superseded. No ID is invented here.
ModelMapNpcsR7.costumeUploadNote = "Real R7 Image IDs from models_r7/npcs/upload_manifest.json; designer PASS on the costume sheet 2026-11-20."
ModelMapNpcsR7.costumeUploads = {
	{ role = "pak_rt", kind = "shirt", replacedR6Id = 117485364703264, assetId = 92996938301042, path = "docs/v2/visual/art/models_r7/npcs/templates/shirt_pak_rt.png" },
	{ role = "polisi", kind = "shirt", replacedR6Id = 113212316103784, assetId = 133590758790821, path = "docs/v2/visual/art/models_r7/npcs/templates/shirt_polisi.png" },
	{ role = "polisi", kind = "pants", replacedR6Id = 98102154190902, assetId = 98235919851901, path = "docs/v2/visual/art/models_r7/npcs/templates/pants_polisi.png" },
	{ role = "petani", kind = "shirt", replacedR6Id = 112086829394587, assetId = 81581201405716, path = "docs/v2/visual/art/models_r7/npcs/templates/shirt_petani.png" },
}

-- Real Creator Store hats only from R5 (which itself records the verified IDs).
-- pak_rt uses the original built peci below: no Creator Store ID exists for it.
local HATS = {
	polisi = "polisi_cap",
	petani = "caping",
	petani_wanita = "caping",
	pak_rt = "peci",
}

local function makeRole(id)
	local source = R6.roles[id]
	local costume = COSTUMES[id]
	return {
		id = id,
		skin = source.skin,
		shirt = source.shirt,
		pants = source.pants,
		shirtId = costume.shirt,
		pantsId = costume.pants,
		hat = HATS[id],
	}
end

ModelMapNpcsR7.roles = {
	petani = makeRole("petani"),
	pedagang = makeRole("pedagang"),
	petani_wanita = makeRole("petani_wanita"),
	pak_rt = makeRole("pak_rt"),
	polisi = makeRole("polisi"),
}

ModelMapNpcsR7.roleIds = { "petani", "pedagang", "petani_wanita", "pak_rt", "polisi" }

ModelMapNpcsR7.hats = {
	caping = R5.accessories.caping,
	polisi_cap = R5.accessories.polisi_cap,
	-- Original designer build. No asset ID: the applier constructs it in Studio.
	peci = {
		kind = "built",
		name = "PakRT_Peci",
		color = "#1A1A1A",
		size = { x = 1.1, y = 0.55, z = 0.95 },
		note = "Original black peci, woven Fabric, cylinder mesh, welded on top of the Head. No asset ID.",
	},
}

-- Same plaza row and camera-facing yaw as R6; spacing tightened to 4 studs.
local SPACING = 4
local function makeSlot(index)
	local source = R6.slots[index]
	return {
		slot = source.slot,
		x = (index - 3) * SPACING,
		y = source.y,
		z = source.z,
		ry = source.ry,
		targetHeight = source.targetHeight,
	}
end

ModelMapNpcsR7.slots = {
	makeSlot(1),
	makeSlot(2),
	makeSlot(3),
	makeSlot(4),
	makeSlot(5),
}

ModelMapNpcsR7.savedCamera = R6.savedCamera

ModelMapNpcsR7.designerBuilds = {
	note = "Pak RT peci is an original build (no asset ID). The four R7 costume PNGs are uploaded, recorded in upload_manifest.json, and wired into COSTUMES.",
	roles = { "pak_rt" },
	missing = {},
}

ModelMapNpcsR7.families = {
	npcs_r7 = {
		id = "npcs_r7",
		roles = ModelMapNpcsR7.roles,
		slots = ModelMapNpcsR7.slots,
		savedCamera = ModelMapNpcsR7.savedCamera,
	},
}

return ModelMapNpcsR7
