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

	-- rarity tiers (Config/Tiers)
	tier_biasa = { id = "Biasa", en = "Common" },
	tier_bagus = { id = "Bagus", en = "Good" },
	tier_super = { id = "Super", en = "Super" },
	tier_langka = { id = "Langka", en = "Rare" },
	tier_sultan = { id = "Sultan", en = "Sultan" },

	-- produce traits (Config/Traits)
	trait_oplosan = { id = "Oplosan", en = "Cut" },
	trait_basah = { id = "Basah", en = "Rain-soaked" },
	trait_kering = { id = "Kering", en = "Drought-dry" },
	trait_organik = { id = "Organik", en = "Organic" },
	trait_bersertifikat = { id = "Bersertifikat", en = "Certified" },

	-- seasons (Config/Seasons)
	season_hujan = { id = "Musim Hujan", en = "Rainy season" },
	season_kemarau = { id = "Musim Kemarau", en = "Dry season" },
	season_pancaroba = { id = "Pancaroba", en = "Changing season" },

	-- admin panel (internal tool)
	admin_title = { id = "Admin — Juragan Desa", en = "Admin — Juragan Desa" },
	admin_season = { id = "Musim", en = "Season" },
	admin_anomaly = { id = "Anomali", en = "Anomaly" },
	admin_event = { id = "Event", en = "Event" },
	admin_inspect = { id = "Periksa", en = "Inspect" },
	admin_grant = { id = "Beri", en = "Grant" },
	admin_close = { id = "Tutup", en = "Close" },
	admin_idle = { id = "Belum ada aksi.", en = "No actions yet." },
	admin_offline = { id = "Pemain tidak online.", en = "Player is not online." },
	admin_no_access = { id = "Akses ditolak.", en = "Access denied." },
	admin_failed = { id = "Gagal: %s", en = "Failed: %s" },
	admin_ready = { id = "Siap.", en = "Ready." },
	admin_auto = { id = "Auto", en = "Auto" },
	admin_cabai = { id = "Harga Cabai", en = "Chili prices" },

	-- cheats
	cheat_oplosan = { id = "Pupuk Oplosan", en = "Dodgy Fertilizer" },
	cheat_gelap = { id = "Tengkulak Gelap", en = "Black Market" },
	cheat_curi_air = { id = "Curi Air", en = "Water Theft" },

	-- cosmetics
	cosmetic_caping = { id = "Caping", en = "Straw Hat" },
	cosmetic_peci = { id = "Peci Hitam", en = "Black Peci" },
	cosmetic_batik = { id = "Batik", en = "Batik Shirt" },

	-- HUD
	hud_rank = { id = "Pangkat: %s", en = "Rank: %s" },
	hud_sus = { id = "👀 %s", en = "👀 %s" },
	hud_namabaik = { id = "⭐ %s", en = "⭐ %s" },
	hud_shop = { id = "Toko Bibit", en = "Seed Shop" },
	hud_close = { id = "Tutup", en = "Close" },
	hud_seed_count = { id = "%s x%s", en = "%s x%s" },
	hud_locked = { id = "🔒 %s", en = "🔒 %s" },
	hud_harvest_bag = { id = "Karung: %s", en = "Sack: %s" },
	hud_phone = { id = "📱 HP", en = "📱 Phone" },
	hud_cheat = { id = "😈 Curang", en = "😈 Cheat" },
	hud_shop_button = { id = "🌱 Bibit", en = "🌱 Seeds" },
	shop_buy = { id = "Beli %s (Rp %s)", en = "Buy %s (Rp %s)" },
	shop_needs_rank = { id = "Butuh pangkat %s", en = "Needs rank %s" },
	shop_rank_badge = { id = "%s?", en = "%s?" },

	-- prompts
	prompt_tile = { id = "Petak", en = "Plot tile" },
	prompt_plant = { id = "Tanam %s", en = "Plant %s" },
	prompt_harvest = { id = "Panen", en = "Harvest" },
	prompt_growing = { id = "Sedang tumbuh…", en = "Growing…" },
	prompt_buy_tile = { id = "Beli petak (Rp %s)", en = "Buy tile (Rp %s)" },
	prompt_pasar = { id = "Pasar", en = "Market" },
	prompt_sell = { id = "Jual hasil panen", en = "Sell harvest" },
	prompt_gelap = { id = "Tengkulak Gelap", en = "Black Market" },
	prompt_sell_gelap = { id = "Jual (harga gelap)", en = "Sell (black market)" },
	prompt_pakrt = { id = "Pak RT", en = "Pak RT" },
	prompt_bribe = { id = "Kasih uang rokok (Rp %s)", en = "Cigarette money (Rp %s)" },
	prompt_polisi = { id = "Pos Polisi", en = "Police Post" },
	prompt_lapor = { id = "Lapor bukti", en = "Turn in evidence" },
	prompt_warung = { id = "Warung", en = "Warung" },
	prompt_warung_chat = { id = "Nongkrong", en = "Hang out" },

	-- Harga Cabai Meroket (Events/CabaiEvent)
	hud_event_cabai = { id = "🔥 Harga cabai meroket! x%s", en = "🔥 Chili prices are soaring! x%s" },
	event_cabai_start = { id = "📈 HARGA CABAI MEROKET! Cabai laku x%s selama 5 menit.", en = "📈 CHILI PRICES SOAR! Chili sells at x%s for 5 minutes." },
	event_cabai_end = { id = "📉 Harga cabai kembali normal.", en = "📉 Chili prices are back to normal." },

	-- warung flavor (World/WarungService)
	warung_rumor_1 = { id = "Kata orang, tengkulak gelap itu bayar pakai uang kotak sabun.", en = "They say the black market pays in soap-box money." },
	warung_rumor_2 = { id = "Kabar sore: panen Pak RT katanya nggak pernah kena hama. Kok bisa, ya?", en = "Evening news: Pak RT's harvest never gets pests. How, though?" },
	warung_rumor_3 = { id = "Anak muda sekarang panen pakai aplikasi. Zaman memang beda.", en = "Kids these days harvest with an app. Different times." },
	warung_rumor_4 = { id = "Kabar burung: ada yang jual hasil panen lewat jalan belakang.", en = "Rumor has it someone sells their harvest out the back." },
	warung_vip = { id = "Kursi VIP: kopi tubruk + dangdut. Hidup Juragan!", en = "VIP seat: strong coffee and dangdut. Long live the Juragan!" },

	-- tile labels
	tile_ready = { id = "Siap panen!", en = "Ready!" },
	tile_hot = { id = "⚠ %s", en = "⚠ %s" },

	-- notifications
	n_planted = { id = "%s ditanam!", en = "%s planted!" },
	n_harvested = { id = "Panen %s! Bawa ke Pasar.", en = "Harvested %s! Take it to the market." },
	n_sold = { id = "Laku! +Rp %s", en = "Sold! +Rp %s" },
	n_sold_gelap = { id = "Laku gelap! +Rp %s (+Sus)", en = "Sold black market! +Rp %s (+Sus)" },
	n_nothing_to_sell = { id = "Karungmu kosong.", en = "Your sack is empty." },
	n_hot_pasar = { id = "Hasil oplosan nggak berani dibeli Pasar. Coba tengkulak.", en = "The market won't touch oplosan produce. Try the black market." },
	n_not_enough_cash = { id = "Uangmu kurang, Pak.", en = "Not enough cash." },
	n_no_seed = { id = "Bibit %s habis. Beli di Toko Bibit.", en = "Out of %s seeds. Buy more in the Seed Shop." },
	n_rank_locked = { id = "Butuh pangkat %s.", en = "Needs rank %s." },
	n_bought_seeds = { id = "Beli %s bibit %s.", en = "Bought %s %s seeds." },
	n_tile_bought = { id = "Petak baru dibeli!", en = "New tile bought!" },
	n_rank_up = { id = "Naik pangkat: %s!", en = "Rank up: %s!" },
	n_still_growing = { id = "Belum siap, sabar ya.", en = "Not ready yet." },
	n_welcome = { id = "Selamat datang di Desa Sukasogok!", en = "Welcome to Desa Sukasogok!" },
	n_too_far = { id = "Kamu terlalu jauh.", en = "You're too far away." },
	n_busy = { id = "Tunggu sebentar ya.", en = "Hold on a moment." },

	-- cheats
	n_oplosan_ok = { id = "Pupuk oplosan! Panen lebih cepat, tapi jadi barang panas.", en = "Dodgy fertilizer! Faster harvest, but the crop is hot now." },
	n_oplosan_fail = { id = "Nggak bisa dioplos sekarang.", en = "Can't fertilize that right now." },
	n_steal_ok = { id = "Air tetangga dialirkan! (+%s Sus)", en = "Neighbor's water diverted! (+%s Sus)" },
	n_steal_fail = { id = "Nggak ada air yang bisa dicuri di situ.", en = "There's no water to steal there." },
	n_steal_cooldown = { id = "Tetangga itu sudah waspada. Tunggu dulu.", en = "That neighbor is watching now. Wait a bit." },
	n_not_neighbor = { id = "Itu bukan tetangga sebelahmu.", en = "That's not your neighbor." },

	-- law
	n_sus_up = { id = "Sus +%s", en = "Sus +%s" },
	n_gossip = { id = "Pak RT: “Kok cepet banget panennya ya…”", en = "Pak RT: “How is the harvest so fast…”" },
	n_letter = { id = "📨 Surat Panggilan! Pak RT mau ngobrol. (Sus %s)", en = "📨 Summons letter! Pak RT wants a word. (Sus %s)" },
	n_caught = { id = "Kena razia! Nama baik -%s.", en = "Raided! Reputation -%s." },
	n_confiscated = { id = "%s hasil oplosan disita!", en = "%s hot crops confiscated!" },
	n_raid_came = { id = "OPERASI SAPU BERSIH!", en = "OPERATION CLEAN SWEEP!" },
	n_raid_fine = { id = "Denda dibayar: Rp %s.", en = "Fine paid: Rp %s." },
	n_raid_amplop_ok = { id = "Amplop diterima. “Ya sudahlah, Pak RT baik.”", en = "Envelope accepted. “Fine, Pak RT is a nice guy.”" },
	n_raid_amplop_fail = { id = "“Amplop kurang tebal, Pak!” Denda x1,5: Rp %s", en = "“The envelope's too thin!” Fine x1.5: Rp %s" },
	n_raid_jail = { id = "Tidak bisa bayar. Pos Ronda %s detik.", en = "Can't pay. Guard post for %s seconds." },
	n_raid_over = { id = "Razia selesai. Sus turun ke %s.", en = "Raid over. Sus dropped to %s." },
	n_viral = { id = "🔥 VIRAL! Kamu dirazia. Amplop nggak bakal membantu.", en = "🔥 VIRAL! You're being raided. Bribes won't help." },
	n_viral_case = { id = "Kasusmu viral, amplop tidak bisa.", en = "Your case is viral, no envelope can help." },
	n_raid_active = { id = "Razia sedang berlangsung!", en = "A raid is already happening!" },

	-- bribe
	n_bribe_ok = { id = "Uang rokok diterima. Sus -%s. (Rp %s)", en = "Cigarette money accepted. Sus -%s. (Rp %s)" },
	n_bribe_cooldown = { id = "Pak RT lagi di belakang. Coba lagi nanti.", en = "Pak RT is busy. Try again later." },

	-- evidence / reports
	n_record_hint = { id = "📱 Rekam bukti? Buka HP.", en = "📱 Record evidence? Open your phone." },
	n_recorded = { id = "Bukti direkam. Antar ke Pos Polisi.", en = "Evidence recorded. Take it to the Police Post." },
	n_report_ok = { id = "Laporan diterima! +Rp %s, +%s Nama Baik.", en = "Report accepted! +Rp %s, +%s Reputation." },
	n_report_no_cash = { id = "Laporan diterima. Pelakunya sudah tidak punya uang.", en = "Report accepted. The cheater has no cash left." },
	n_report_cooldown = { id = "Lapor terlalu sering, tunggu sebentar.", en = "Reporting too often, wait a moment." },
	n_report_near = { id = "Lapor harus di Pos Polisi.", en = "Reports must be made at the Police Post." },
	n_token_expired = { id = "Bukti kedaluwarsa.", en = "Evidence expired." },
	n_token_gone = { id = "Bukti nggak valid.", en = "Invalid evidence." },
	n_got_token = { id = "📱 Bukti tersimpan di HP!", en = "📱 Evidence saved in your phone!" },

	-- items
	n_item_used = { id = "%s dipakai.", en = "%s used." },
	n_item_none = { id = "Kamu tidak punya %s.", en = "You don't have %s." },
	n_item_cooldown = { id = "%s masih cooldown.", en = "%s is still on cooldown." },
	n_item_blocked = { id = "%s tidak bisa dipakai sekarang.", en = "%s can't be used right now." },
	item_amplopPremium = { id = "Amplop Premium", en = "Premium Envelope" },
	item_jaminanKilat = { id = "Jaminan Kilat", en = "Express Bail" },
	item_karungBibit = { id = "Karung Bibit", en = "Seed Sack" },
	pass_ordal = { id = "Ordal", en = "Ordal" },
	pass_extraPlot = { id = "Extra Plot", en = "Extra Plot" },
	pass_vipWarung = { id = "VIP Warung", en = "VIP Warung" },
	n_purchase = { id = "%s diterima. Makasih, Juragan!", en = "%s received. Thanks, boss!" },

	-- jail
	jail_title = { id = "POS RONDA", en = "GUARD POST" },
	jail_time = { id = "Keluar dalam %s detik", en = "Out in %s seconds" },
	jail_out = { id = "Bebas! Jangan diulang ya.", en = "Free! Don't do it again." },

	-- phone
	phone_title = { id = "HP Juragan", en = "Juragan Phone" },
	phone_tab_phone = { id = "HP", en = "Phone" },
	phone_tab_cheat = { id = "Curang", en = "Cheat" },
	phone_tab_dekor = { id = "Dekorasi", en = "Decor" },
	phone_inventory = { id = "Isi Tas", en = "Inventory" },
	phone_empty = { id = "Kosong.", en = "Empty." },
	phone_bukti = { id = "Bukti", en = "Evidence" },
	phone_lapor = { id = "Lapor", en = "Report" },
	phone_use = { id = "Pakai", en = "Use" },
	phone_record = { id = "Rekam", en = "Record" },
	phone_cheat_title = { id = "Akal-akalan", en = "Shortcuts" },
	phone_oplosan = { id = "Oplos %s (Rp %s)", en = "Fertilize %s (Rp %s)" },
	phone_steal = { id = "Curi air dari %s", en = "Steal water from %s" },
	phone_steal_short = { id = "💧 Curi", en = "💧 Steal" },
	phone_water_short = { id = "🚿 Siram", en = "🚿 Water" },
	phone_water = { id = "Siram tanaman %s (+Nama Baik)", en = "Water %s's crops (+Reputation)" },
	phone_no_neighbors = { id = "Belum ada tetangga online.", en = "No neighbors online yet." },
	phone_no_growing = { id = "Tidak ada tanaman yang sedang tumbuh.", en = "No crops growing right now." },
	phone_cosmetic_buy = { id = "Beli (Rp %s)", en = "Buy (Rp %s)" },
	phone_cosmetic_equip = { id = "Pakai", en = "Equip" },
	phone_cosmetic_unequip = { id = "Lepas", en = "Remove" },
	phone_owned = { id = "Dimiliki", en = "Owned" },
	n_cosmetic_bought = { id = "%s dibeli!", en = "%s bought!" },
	n_cosmetic_equipped = { id = "%s dipakai.", en = "%s equipped." },
	n_cosmetic_removed = { id = "%s dilepas.", en = "%s removed." },
	n_water_ok = { id = "Tanaman %s disiram. +%s Nama Baik.", en = "Watered %s's crops. +%s Reputation." },
	phone_sus = { id = "Sus", en = "Sus" },
	phone_namabaik = { id = "Nama Baik", en = "Reputation" },
	phone_rank = { id = "Pangkat", en = "Rank" },
	phone_help = { id = "Tips: curang itu cepat, tapi tetangga bisa ngerekam.", en = "Tip: cheating is fast, but neighbors can record you." },

	-- minigames
	mg_mencangkul_title = { id = "MENCANGKUL", en = "HOEING" },
	mg_mencangkul_hint = { id = "Tap saat jarum di zona hijau", en = "Tap when the needle is in the green zone" },
	mg_babat_title = { id = "BABAT", en = "CUTTING" },
	mg_babat_hint = { id = "Tahan, lepas di zona hijau", en = "Hold, release in the green zone" },
	mg_taps = { id = "%s / %s", en = "%s / %s" },
	mg_auto = { id = "Auto", en = "Auto" },
	mg_score = { id = "Kualitas: %s", en = "Quality: %s" },
	mg_plant = { id = "Tanam %s", en = "Plant %s" },
	mg_harvest = { id = "Panen %s", en = "Harvest %s" },

	-- raid overlay
	raid_breaking = { id = "BREAKING NEWS", en = "BREAKING NEWS" },
	raid_title = { id = "OPERASI SAPU BERSIH", en = "OPERATION CLEAN SWEEP" },
	raid_subtitle = { id = "Polisi Desa datang ke ladangmu!", en = "The Village Police are at your farm!" },
	raid_viral_title = { id = "🔥 VIRAL 🔥", en = "🔥 VIRAL 🔥" },
	raid_viral_subtitle = { id = "Videonya sudah tersebar. Amplop tidak berlaku.", en = "The video is everywhere. No envelope will help." },
	raid_choose = { id = "Apa yang kamu lakukan?", en = "What do you do?" },
	raid_fine = { id = "Bayar Denda\nRp %s", en = "Pay the Fine\nRp %s" },
	raid_amplop = { id = "Kasih Amplop\nRp %s (75%)", en = "Slip an Envelope\nRp %s (75%)" },
	raid_amplop_blocked = { id = "Amplop ditolak (VIRAL)", en = "Envelope refused (VIRAL)" },
	raid_wait = { id = "Polisi Desa sedang menuju ladangmu…", en = "The Village Police are on their way…" },
	raid_jail_btn = { id = "Tidak bisa bayar", en = "Can't pay" },
	raid_timeout = { id = "Terlalu lama diam. Denda otomatis.", en = "You stayed silent. Automatic fine." },
	raid_outcome_denda = { id = "Denda lunas. Sus kembali ke 30.", en = "Fine paid. Sus is back to 30." },
	raid_outcome_amplop = { id = "Amplop berhasil. Razia bubar.", en = "Envelope worked. The raid disperses." },
	raid_outcome_amplop_fail = { id = "Amplop kurang tebal! Denda x1,5.", en = "Envelope too thin! Fine x1.5." },
	raid_outcome_jail = { id = "Kamu digelandang ke Pos Ronda.", en = "You're dragged to the Guard Post." },
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
