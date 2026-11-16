-- IconMap: central icon slot map for crops, currency, tiers, and phone apps.
-- IDs stay 0 until real art is uploaded (TODO: NEEDS-ASSET). Fill `id` per slot when
-- asset IDs are recorded in docs/v2/visual/art/ASSET_MANIFEST.md.

local IconMap = {}

-- Crop icons, keyed by crop id. slot = Visuals.icons key.
IconMap.crops = {
	padi = { id = 0, slot = "crop_padi", fallback = "Pd", token = "padi" }, -- TODO: NEEDS-ASSET
	singkong = { id = 0, slot = "crop_singkong", fallback = "Sk", token = "bambu" }, -- TODO: NEEDS-ASSET
	jagung = { id = 0, slot = "crop_jagung", fallback = "Jg", token = "kunyit" }, -- TODO: NEEDS-ASSET
	bawang = { id = 0, slot = "crop_bawang", fallback = "Bw", token = "ungu" }, -- TODO: NEEDS-ASSET
	cabai = { id = 0, slot = "crop_cabai", fallback = "Cb", token = "merah" }, -- TODO: NEEDS-ASSET
	tembakau = { id = 0, slot = "crop_tembakau", fallback = "Tb", token = "bambu" }, -- TODO: NEEDS-ASSET
	kopi = { id = 0, slot = "crop_kopi", fallback = "Kp", token = "tinta" }, -- TODO: NEEDS-ASSET
	tebu = { id = 0, slot = "crop_tebu", fallback = "Tb", token = "daun" }, -- TODO: NEEDS-ASSET
	kakao = { id = 0, slot = "crop_kakao", fallback = "Kk", token = "bambu" }, -- TODO: NEEDS-ASSET
	cengkeh = { id = 0, slot = "crop_cengkeh", fallback = "Ck", token = "tinta_lembut" }, -- TODO: NEEDS-ASSET
	durian = { id = 0, slot = "crop_durian", fallback = "Dr", token = "daun" }, -- TODO: NEEDS-ASSET
	sawit = { id = 0, slot = "crop_sawit", fallback = "Sw", token = "genteng" }, -- TODO: NEEDS-ASSET
}

-- Currency icons.
IconMap.currency = {
	cash = { id = 0, slot = "cash", fallback = "Rp", token = "kunyit" }, -- TODO: NEEDS-ASSET
	rupiah = { id = 0, slot = "currency_rupiah", fallback = "Rp", token = "kunyit" }, -- TODO: NEEDS-ASSET
}

-- Tier icons, keyed by tier id.
IconMap.tiers = {
	biasa = { id = 0, slot = "tier_biasa", fallback = "B", token = "tinta_lembut" }, -- TODO: NEEDS-ASSET
	bagus = { id = 0, slot = "tier_bagus", fallback = "+", token = "daun" }, -- TODO: NEEDS-ASSET
	super = { id = 0, slot = "tier_super", fallback = "S", token = "malam" }, -- TODO: NEEDS-ASSET
	langka = { id = 0, slot = "tier_langka", fallback = "L", token = "ungu" }, -- TODO: NEEDS-ASSET
	sultan = { id = 0, slot = "tier_sultan", fallback = "$", token = "kunyit" }, -- TODO: NEEDS-ASSET
}

-- Phone app icons, keyed by app id as used in src/client/UI/Phone.luau.
IconMap.phoneApps = {
	phone = { id = 0, slot = "phone", fallback = "HP", token = "malam" }, -- TODO: NEEDS-ASSET
	kebun = { id = 0, slot = "garden", fallback = "K", token = "daun" }, -- TODO: NEEDS-ASSET
	pinjol = { id = 0, slot = "debt", fallback = "Rp", token = "genteng" }, -- TODO: NEEDS-ASSET
	tugas = { id = 0, slot = "quest", fallback = "=", token = "kunyit" }, -- TODO: NEEDS-ASSET
	cheat = { id = 0, slot = "cheat", fallback = "!", token = "merah" }, -- TODO: NEEDS-ASSET
	dekor = { id = 0, slot = "hat", fallback = "D", token = "indigo" }, -- TODO: NEEDS-ASSET
	shop = { id = 0, slot = "shop", fallback = "S", token = "padi" }, -- TODO: NEEDS-ASSET
	board = { id = 0, slot = "trophy", fallback = "1", token = "kunyit" }, -- TODO: NEEDS-ASSET
}

local function syncEntry(icons: { [string]: any }, slot: string, entry: { [string]: any })
	local icon = icons[slot]
	if not icon then
		icon = { id = 0, text = entry.fallback or "*", token = entry.token or "tinta_lembut" }
		icons[slot] = icon
	end
	if entry.id and entry.id > 0 then
		icon.id = entry.id
	end
	if icon.text == nil or icon.text == "*" then
		icon.text = entry.fallback or icon.text or "?"
	end
	if icon.token == nil then
		icon.token = entry.token or "tinta_lembut"
	end
end

-- Apply this map onto Visuals.icons so UI/Icons.luau resolves slots consistently.
function IconMap.apply(visuals: any)
	local icons = visuals.icons
	if type(icons) ~= "table" then
		return
	end
	for _, entry in IconMap.crops do
		syncEntry(icons, entry.slot, entry)
	end
	for _, entry in IconMap.currency do
		syncEntry(icons, entry.slot, entry)
	end
	for _, entry in IconMap.tiers do
		syncEntry(icons, entry.slot, entry)
	end
	for _, entry in IconMap.phoneApps do
		syncEntry(icons, entry.slot, entry)
	end
end

function IconMap.cropSlot(cropId: string): string
	local entry = IconMap.crops[cropId]
	return if entry then entry.slot else ("crop_" .. cropId)
end

function IconMap.phoneAppSlot(appId: string): string
	local entry = IconMap.phoneApps[appId]
	return if entry then entry.slot else appId
end

function IconMap.tierSlot(tierId: string): string
	local entry = IconMap.tiers[tierId]
	return if entry then entry.slot else ("tier_" .. tierId)
end

function IconMap.currencySlot(name: string): string
	local entry = IconMap.currency[name]
	return if entry then entry.slot else name
end

return IconMap
