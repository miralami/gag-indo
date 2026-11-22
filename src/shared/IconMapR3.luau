--!strict
-- IconMapR3: real round-3 icon IDs for the OFF-BY-DEFAULT "icons_r3" LookDev candidate
-- (WORK_QUEUE round 3 item 22, icon half). All 27 IDs were returned by ROBLOX_API_KEY ->
-- Open Cloud POST /assets/v1/assets and recorded in
-- docs/v2/visual/art/icons/render_r3/upload_manifest.json. None is approved or shipped on by
-- default. The IDs live here, not in LookDev or its adapter, so the "no asset IDs" guard holds.
--
-- apply(visuals, true) captures each slot's existing id BEFORE the first enable and writes the
-- r3 id; apply(visuals, false) puts those captured values back (never a blind 0).

local ids: { [string]: number } = {
	cash = 138087600730726,
	cheat = 125589296242506,
	crop_bawang = 135178455685153,
	crop_cabai = 79919705592702,
	crop_cengkeh = 78132241141166,
	crop_durian = 101370699215855,
	crop_jagung = 90649184401740,
	crop_kakao = 125498435667984,
	crop_kopi = 138083843465081,
	crop_padi = 134033339407480,
	crop_sawit = 117040564851934,
	crop_singkong = 127244634432547,
	crop_tebu = 127292228714627,
	crop_tembakau = 78677113924306,
	currency_rupiah = 99150976838662,
	debt = 123701882589428,
	garden = 116123519007302,
	hat = 94710589109478,
	phone = 136621488738903,
	quest = 112252209152765,
	shop = 100422070142864,
	tier_bagus = 112466562604884,
	tier_biasa = 90695650673648,
	tier_langka = 101704450642324,
	tier_sultan = 104739847459422,
	tier_super = 86600499251030,
	trophy = 105377004669039,
}

local slots: { string } = {
	"cash",
	"cheat",
	"crop_bawang",
	"crop_cabai",
	"crop_cengkeh",
	"crop_durian",
	"crop_jagung",
	"crop_kakao",
	"crop_kopi",
	"crop_padi",
	"crop_sawit",
	"crop_singkong",
	"crop_tebu",
	"crop_tembakau",
	"currency_rupiah",
	"debt",
	"garden",
	"hat",
	"phone",
	"quest",
	"shop",
	"tier_bagus",
	"tier_biasa",
	"tier_langka",
	"tier_sultan",
	"tier_super",
	"trophy",
}

local IconMapR3 = {}

IconMapR3.ids = ids
IconMapR3.slots = slots

local useCandidates = false
local originals: { [string]: any } = {}

function IconMapR3.count(): number
	return #slots
end

function IconMapR3.usingCandidates(): boolean
	return useCandidates
end

-- Applier for the "icons_r3" LookDev candidate. Safe on malformed input; a missing icon entry is
-- created on enable and restored to its original (nil) id on disable.
function IconMapR3.apply(visuals: any, on: boolean)
	local want = on == true
	if type(visuals) ~= "table" or type(visuals.icons) ~= "table" then
		return
	end
	local icons = visuals.icons
	if want then
		if not useCandidates then
			originals = {}
			for _, slot in slots do
				local icon = icons[slot]
				originals[slot] = if type(icon) == "table" then icon.id else nil
			end
		end
		for _, slot in slots do
			local icon = icons[slot]
			if type(icon) ~= "table" then
				icon = { id = ids[slot] }
				icons[slot] = icon
			end
			icon.id = ids[slot]
		end
	else
		for _, slot in slots do
			local icon = icons[slot]
			if type(icon) == "table" then
				icon.id = originals[slot]
			end
		end
		originals = {}
	end
	useCandidates = want
end

return IconMapR3
