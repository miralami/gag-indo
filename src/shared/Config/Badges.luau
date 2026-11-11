-- Badge registry (v2 PLAN §3.6).
--
-- Badge IDs default to 0 for local Studio dev. In production, real Roblox badge IDs replace them.
-- BadgeService.award(player, badgeKey) silently skips id <= 0 or already awarded badges.

local Badges = {}

Badges.list = {
	first_raid = { id = 0, name = "Pertama Kali Digerebek", description = "Rasakan grebekan polisi desa." },
	first_sultan = { id = 0, name = "Panen Sultan", description = "Dapatkan hasil panen tingkat Sultan." },
	debt_free = { id = 0, name = "Bebas Pinjol", description = "Lunasi seluruh pinjaman pinjol tepat waktu." },
	kades = { id = 0, name = "Juragan Nomor Satu", description = "Terpilih menjadi Kepala Desa." },
}

function Badges.exists(key: any): boolean
	return type(key) == "string" and Badges.list[key] ~= nil
end

return Badges
