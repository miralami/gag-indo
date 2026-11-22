--!nocheck
-- ModelMapNpcsR8: PURE DATA for the OFF-BY-DEFAULT "npcs_r8" LookDev candidate
-- (WORK_QUEUE item 86). No Roblox APIs, no engine types; colours are plain
-- { r, g, b } triples. Body colours, ground, yaw and saved camera come from
-- ModelMapNpcsR6/R5 so no verified colour or ID is invented here.
--
-- The 15 catalog IDs below were sourced and verified by the main session via the
-- catalog search API + economy GET (name / AssetTypeId) on 2026-11-21. They are
-- recorded verbatim in docs/v2/visual/art/ASSET_MANIFEST.md. Never guess an ID.
-- shirt/pants are classic clothing IDs for HumanoidDescription.Shirt/Pants,
-- layeredShirt is a type-65 ShirtAccessory, hats are type-8 Hat accessories.

local R6 = require(script.Parent.ModelMapNpcsR6)
local R5 = require(script.Parent.ModelMapNpcsR5)

local ModelMapNpcsR8 = {}

ModelMapNpcsR8.familyId = "npcs_r8"
ModelMapNpcsR8.lookDevId = "npcs_r8"
ModelMapNpcsR8.catalogSource = "docs/v2/visual/art/ASSET_MANIFEST.md"
ModelMapNpcsR8.groundY = R5.groundY
ModelMapNpcsR8.PLAYER_HEIGHT = R5.PLAYER_HEIGHT
ModelMapNpcsR8.facingFlip = R6.facingFlip

-- Second plaza row: +6 studs in Z from the R6/R7 row so the five rigs never
-- overlap the npcs_r7 figures at z = 8. X spacing and camera-facing yaw are
-- copied from R6; only the Z offset is new.
local ROW_OFFSET_Z = 6
ModelMapNpcsR8.ROW_OFFSET_Z = ROW_OFFSET_Z

local CATALOG = {
	tengkulak = {
		shirt = 11755115818, -- "[+] Merchant" (type 11)
		pants = 121010548089939, -- "Petani" (type 12)
		hats = { 76392482317942 }, -- "Young Entrepreneur" (type 8)
	},
	debt_collector = {
		shirt = 5601091452, -- "Uniform" (type 11)
		pants = 104437888647181, -- "uniform" (type 12)
		hats = { 122870229188390 }, -- "Police Balaclava [Blood Debt]" (type 8)
	},
	ibu_warung = {
		layeredShirt = 135555867890569, -- "Batik modern Jawa Wanita V2" (type 65)
		pants = 94473038627675, -- "Petani" (type 12)
		hats = { 99279983172002 }, -- "Hijab" (type 8)
	},
	anak_anak = {
		shirt = 17550183186, -- "uniform" (type 11)
		pants = 14798718772, -- "basic pants" (type 12)
		hats = { 90295258026402 }, -- "Kid" (type 8)
	},
	bapak_ojek = {
		shirt = 129826976931984, -- "Petani" (type 11)
		pants = 79151443926768, -- "Petani" (type 12)
		hats = { 16100797199 }, -- "Classic Taxi Hat" (type 8)
	},
}
ModelMapNpcsR8.catalog = CATALOG

-- Base colours come from the existing R6 roles: no new colour table is written.
local ROLE_SOURCES = {
	tengkulak = "pedagang",
	debt_collector = "polisi",
	ibu_warung = "petani_wanita",
	anak_anak = "petani_wanita",
	bapak_ojek = "petani",
}
ModelMapNpcsR8.roleSources = ROLE_SOURCES

local function makeRole(id)
	local source = R6.roles[ROLE_SOURCES[id]]
	local role = {
		id = id,
		catalog = CATALOG[id],
		skin = source.skin,
		shirt = source.shirt,
		pants = source.pants,
	}
	if id == "anak_anak" then
		role.bodyHeightScale = 0.8
		role.headScale = 1.2
	end
	return role
end

ModelMapNpcsR8.roles = {
	tengkulak = makeRole("tengkulak"),
	debt_collector = makeRole("debt_collector"),
	ibu_warung = makeRole("ibu_warung"),
	anak_anak = makeRole("anak_anak"),
	bapak_ojek = makeRole("bapak_ojek"),
}

ModelMapNpcsR8.roleIds = {
	"tengkulak",
	"debt_collector",
	"ibu_warung",
	"anak_anak",
	"bapak_ojek",
}

-- True iff no two catalog entries share the same (shirt or layeredShirt, pants)
-- pair. Pure helper; the Lune spec locks it and the Studio harness reads live
-- rig attributes for the same rule.
function ModelMapNpcsR8.uniqueOutfits(catalog)
	local seen = {}
	for _, outfit in pairs(catalog or {}) do
		local shirtId = outfit.shirt or outfit.layeredShirt
		local key = tostring(shirtId) .. ":" .. tostring(outfit.pants)
		if seen[key] then
			return false
		end
		seen[key] = true
	end
	return true
end

local SPACING = 6
ModelMapNpcsR8.SPACING = SPACING

local function makeSlot(index)
	local source = R6.slots[index]
	return {
		slot = ModelMapNpcsR8.roleIds[index],
		x = (index - 3) * SPACING,
		y = source.y,
		z = source.z + ROW_OFFSET_Z,
		ry = source.ry,
		targetHeight = source.targetHeight,
	}
end

ModelMapNpcsR8.slots = {
	makeSlot(1),
	makeSlot(2),
	makeSlot(3),
	makeSlot(4),
	makeSlot(5),
}

ModelMapNpcsR8.savedCamera = R6.savedCamera

ModelMapNpcsR8.families = {
	npcs_r8 = {
		id = "npcs_r8",
		roles = ModelMapNpcsR8.roles,
		slots = ModelMapNpcsR8.slots,
		savedCamera = ModelMapNpcsR8.savedCamera,
	},
}

return ModelMapNpcsR8
