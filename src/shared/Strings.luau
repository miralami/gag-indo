-- All player-facing text (Indonesian first, English second).
-- Server sends string KEYS to clients; the client picks the language.
-- Params starting with "@" are looked up as keys too (e.g. "@crop_padi").

local S: { [string]: { id: string, en: string } } = {
	-- crops
	crop_padi = { id = "Padi", en = "Rice" },
	crop_jagung = { id = "Jagung", en = "Corn" },
	crop_cabai = { id = "Cabai", en = "Chili" },
	crop_durian = { id = "Durian", en = "Durian" },

	-- ranks
	rank_gurem = { id = "Petani Gurem", en = "Smallholder" },
	rank_petani = { id = "Petani", en = "Farmer" },
	rank_juragan = { id = "Juragan", en = "Juragan" },

	-- HUD
	hud_rank = { id = "Pangkat: %s", en = "Rank: %s" },
	hud_shop = { id = "Toko Bibit", en = "Seed Shop" },
	hud_close = { id = "Tutup", en = "Close" },
	hud_seed_count = { id = "%s x%s", en = "%s x%s" },
	hud_locked = { id = "🔒 %s", en = "🔒 %s" },
	hud_harvest_bag = { id = "Karung: %s hasil panen", en = "Sack: %s harvested" },
	shop_buy = { id = "Beli %s (Rp %s)", en = "Buy %s (Rp %s)" },
	shop_needs_rank = { id = "Butuh pangkat %s", en = "Needs rank %s" },

	-- prompts
	prompt_tile = { id = "Petak", en = "Plot tile" },
	prompt_plant = { id = "Tanam %s", en = "Plant %s" },
	prompt_harvest = { id = "Panen", en = "Harvest" },
	prompt_growing = { id = "Sedang tumbuh…", en = "Growing…" },
	prompt_buy_tile = { id = "Beli petak (Rp %s)", en = "Buy tile (Rp %s)" },
	prompt_pasar = { id = "Pasar", en = "Market" },
	prompt_sell = { id = "Jual hasil panen", en = "Sell harvest" },

	-- tile labels
	tile_ready = { id = "Siap panen!", en = "Ready!" },

	-- notifications
	n_planted = { id = "%s ditanam!", en = "%s planted!" },
	n_harvested = { id = "Panen %s! Bawa ke Pasar.", en = "Harvested %s! Take it to the market." },
	n_sold = { id = "Laku! +Rp %s", en = "Sold! +Rp %s" },
	n_nothing_to_sell = { id = "Karungmu kosong.", en = "Your sack is empty." },
	n_not_enough_cash = { id = "Uangmu kurang, Pak.", en = "Not enough cash." },
	n_no_seed = { id = "Bibit %s habis. Beli di Toko Bibit.", en = "Out of %s seeds. Buy more in the Seed Shop." },
	n_rank_locked = { id = "Butuh pangkat %s.", en = "Needs rank %s." },
	n_bought_seeds = { id = "Beli %s bibit %s.", en = "Bought %s %s seeds." },
	n_tile_bought = { id = "Petak baru dibeli!", en = "New tile bought!" },
	n_rank_up = { id = "Naik pangkat: %s!", en = "Rank up: %s!" },
	n_still_growing = { id = "Belum siap, sabar ya.", en = "Not ready yet." },
	n_welcome = { id = "Selamat datang di Desa Sukasogok!", en = "Welcome to Desa Sukasogok!" },
}

local Strings = {}

function Strings.langFor(localeId: string): string
	if string.sub(string.lower(localeId), 1, 2) == "id" then
		return "id"
	end
	return "en"
end

-- Format integers with thousands separators: 12500 -> "12.500" (id) / "12,500" (en)
function Strings.formatNumber(n: number, lang: string): string
	local s = tostring(math.floor(n))
	local sep = if lang == "id" then "." else ","
	local formatted = s
	while true do
		local replaced, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1" .. sep .. "%2")
		formatted = replaced
		if count == 0 then
			break
		end
	end
	return formatted
end

function Strings.get(lang: string, key: string, ...: any): string
	local entry = S[key]
	if not entry then
		return key
	end
	local template = if lang == "id" then entry.id else entry.en
	local n = select("#", ...)
	if n == 0 then
		return template
	end
	local args = table.create(n)
	for i = 1, n do
		local v = select(i, ...)
		if type(v) == "string" and string.sub(v, 1, 1) == "@" then
			v = Strings.get(lang, string.sub(v, 2))
		elseif type(v) == "number" then
			v = Strings.formatNumber(v, lang)
		end
		args[i] = tostring(v)
	end
	local ok, result = pcall(string.format, template, table.unpack(args))
	return if ok then result else template
end

return Strings
