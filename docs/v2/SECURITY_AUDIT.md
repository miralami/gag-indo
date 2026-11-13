# Security Audit Report — Juragan Desa v2

Tanggal: 2026-11-12
Auditor: Antigravity Automated Server-Authority & Security Reviewer
Status: PASS (Semua 23 remote client->server diaudit, divalidasi, dan dilindungi rate limit).

---

## 1. Prinsip Keamanan & Otoritas Server

1. **Client is Compromised**: Client Roblox tidak pernah dipercaya untuk state uang, inventaris, posisi panen, harga bibit, rating minigame yang tidak masuk akal, atau status kepemilikan.
2. **Server Authority**:
   - Seluruh mutasi `Cash`, `NamaBaik`, `Sus`, dan item hanya dapat dilakukan oleh service server (`EconomyService`, `PlayerData`, `SusService`, `RankService`).
   - Client hanya mengirim *request* (niat tindakan). Server memverifikasi tipe data, batas jangkauan (range/clamp), jarak fisik 3D (`EconomyService.near`), kepemilikan plot (`PlotService.getPlotOf`), serta rate limit token-bucket (`RateLimit.luau`).
3. **DataStore Session Locking**: Dilindungi oleh session lock ProfileStore / session token di `PlayerData.luau` dengan migrasi skema otomatis.

---

## 2. Matriks Audit Remote (Client -> Server)

| # | Nama Remote | Payload Parameter | Validasi Server | Jarak / Context | Rate Limit | Status |
|---|---|---|---|---|---|---|
| 1 | `Farm_SelectSeed` | `cropId: string` | `type == "string"`, `Crops.list[cropId] ~= nil` | Attribute sync | 8 req/detik | PASS |
| 2 | `Farm_Complete` | `score: number` | `type == "number"`, bukan NaN/Inf, clamp `[0, 1]`, verifikasi durasi elapsed `[minigameMin, minigameMax]` | Validasi attempt aktif | 4 req/detik | PASS |
| 3 | `Farm_Auto` | `tile: number`, `action: string`, `cropId: string?` | `type == "number"`, integer tile `[1..tilesBuilt]`, action `"plant"\|"harvest"` | Validasi attempt aktif | 4 req/detik | PASS |
| 4 | `Shop_BuySeed` | `cropId: string`, `amount: number` | `type == "string"`, `crop` exists, `amount == floor(amount)`, `1 <= amount <= maxSeedBuy`, rank check, stock check, saldo check | Server shop state | 4 req/detik | PASS |
| 5 | `Storage_Deposit` | (kosong) | Mengecek isi sack produce, kapasitas gudang (`StorageService.capacity`) | Server state | 2 req/detik | PASS |
| 6 | `Storage_Withdraw` | (kosong) | Mengecek isi gudang, kapasitas sack produce | Server state | 2 req/detik | PASS |
| 7 | `Tool_Buy` | `lineId: string` | `Tools.exists(lineId)`, rank requirement, tier berikutnya tersedia, saldo check (`trySpend`) | Server state | 2 req/detik | PASS |
| 8 | `Worker_Hire` | (kosong) | Cek pass `Pass_AutoPanen`, cek status buruh aktif, cek saldo sewa (`trySpend`) | Server state | 1 req/detik | PASS |
| 9 | `Market_Sell` | `channel: "pasar"\|"gelap"` | Normalisasi channel string, kalkulasi multiplier & supply/demand server-side, reset sack bersih | Jarak NPC Pasar/Gelap (`GameConfig.interactDistance`) | 2 req/detik | PASS |
| 10 | `Cheat_Apply` | `cheatId: string`, `tile: number?`, `targetUserId: number?` | `cheatId == "oplosan"`: tile integer bounds, tile state growing; `cheatId == "curi_air"`: neighbor plot check, cooldown check | Jarak tetangga & status lahan | 1 req/detik | PASS |
| 11 | `Bribe_RT` | (kosong) | Cek cooldown sogok, harga dinamis server, saldo check (`trySpend`), reduksi Sus | Jarak NPC Pak RT (`GameConfig.npcDistance`) | 1 req/detik | PASS |
| 12 | `Raid_Choose` | `choice: "denda"\|"amplop"` | `choice` valid, status raid aktif pada fase `"choosing"`, blokir amplop jika kasus `isViral` | State machine raid server | 2 req/detik | PASS |
| 13 | `Evidence_Record` | `eventId: string` | `type == "string"`, event valid pada offer bucket player, belum kadaluarsa | Bucket tawaran server | 2 req/detik | PASS |
| 14 | `Evidence_Report` | `tokenId: string` | Token milik player, belum kadaluarsa, cooldown lapor | Jarak NPC Polisi Desa (`GameConfig.npcDistance`) | 1 req/detik | PASS |
| 15 | `Item_Use` | `item: string` | Item ada di inventaris player (`Inventory.get >= 1`), jail state check untuk jaminanKilat | Server inventory | 1 req/detik | PASS |
| 16 | `Cosmetic_Buy` | `itemId: string` | `CosmeticsConfig.list[itemId] ~= nil`, belum dimiliki, saldo check (`trySpend`) | Server inventory | 2 req/detik | PASS |
| 17 | `Cosmetic_Equip` | `itemId: string?` | Kepemilikan kosmetik diverifikasi sebelum equip | Server inventory | 4 req/detik | PASS |
| 18 | `Water_Neighbor` | `targetUserId: number` | `target` online, tetangga bersebelahan (`PlotService.isNeighbor`), cooldown check | Jarak plot tetangga (40 studs) | 1 req/detik | PASS |
| 19 | `Debt_Borrow` | `amount: number` | `amount == floor(amount)`, `amount > 0`, `amount <= calcLimit`, tidak ada hutang aktif, tidak sedang digerebek | Server limit & state | 1 req/detik | PASS |
| 20 | `Debt_Repay` | `amount: number?` | Hutang aktif > 0, akumulasi bunga server, bayar via `trySpend`, reset jika lunas | Server debt state | 1 req/detik | PASS |
| 21 | `Quest_ClaimDaily`| (kosong) | Cek status klaim hari ini, hitung streak harian berdasar waktu server | Server quest state | 1 req/detik | PASS |
| 22 | `Quest_ClaimTask` | `taskId: string` | Task terdaftar, progress >= target, belum diklaim (`not task.done`) | Server quest state | 1 req/detik | PASS |
| 23 | `Admin_Command` | `payload: table` | Cek `Admins.isAdmin(player.UserId)` (allowlist integer UserId), aksi masuk `ACTIONS` allowlist, validasi tipe nilai per sub-perintah | Server admin allowlist | 4 req/detik | PASS |

---

## 3. Temuan & Mitigasi

1. **Market_Sell Argument Normalization**:
   - *Temuan*: Signature remote `Market_Sell` sebelumnya mendokumentasikan `(cropId, channel)`. Bila client lama memanggil dengan 1 argumen `("pasar")`, argumen channel bisa menjadi `nil`.
   - *Mitigasi*: Telah dinormalisasi di `EconomyService.luau` menjadi `local resolved = if arg1 == "gelap" or arg2 == "gelap" then "gelap" else "pasar"`.
2. **Minigame Timing Verification**:
   - `Farm_Complete` memvalidasi window waktu minimum (`GameConfig.minigameMinSeconds = 0.4s`) dan maksimum (`GameConfig.minigameMaxSeconds = 12.0s`) antara prompt dibuka dan hasil dikirim, mencegah eksploit auto-instant-perfect.
3. **Admin Privilege Isolation**:
   - `AdminService` memeriksa `Admins.isAdmin(player.UserId)` pada setiap pemanggilan remote, bukan mengandalkan atribut client `IsAdmin`. Attribut `IsAdmin` hanya digunakan untuk menyembunyikan tombol UI di client.
